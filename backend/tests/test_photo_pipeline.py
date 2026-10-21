import pytest
from unittest.mock import patch, MagicMock
from app.services.wikimedia_service import WikimediaPhotoService, BLACKLISTED_TITLE_TERMS
from app.providers.mock_verified_provider import ATTRACTIONS_DATA

def test_no_duplicate_attraction_photos():
    """Verify that no two curated attractions share the same photo URL."""
    seen_urls = {}
    for a in ATTRACTIONS_DATA:
        if a.image_url:
            assert a.image_url not in seen_urls, (
                f"Attraction '{a.name}' ({a.id}) shares duplicate image URL with '{seen_urls[a.image_url]}': {a.image_url}"
            )
            seen_urls[a.image_url] = a.name

def test_negative_filtering_blacklisted_terms():
    """Verify that titles containing blacklisted non-photo keywords are rejected."""
    service = WikimediaPhotoService()

    blacklisted_examples = [
        "File:Map of Gateway of India Mumbai.png",
        "File:Floor plan of Shaniwar Wada.jpg",
        "File:Commemorative Inscription on Gateway of India.jpg",
        "File:Plaque at Fort Aguada Goa.jpg",
        "File:A seagull near Elephanta Caves.jpg",
        "File:Signboard at Baga Beach.jpg",
        "File:Diagram of Aga Khan Palace.svg",
    ]

    for title in blacklisted_examples:
        title_clean = title.replace("File:", "").lower()
        has_blacklisted = any(b in title_clean for b in BLACKLISTED_TITLE_TERMS)
        assert has_blacklisted is True, f"'{title}' should be caught by blacklist filter"

def test_scoring_prefers_exact_attraction_name():
    """Verify that scoring prioritizes direct landmark photographs over peripheral items."""
    service = WikimediaPhotoService()

    mock_resp = {
        "query": {
            "pages": {
                "1": {
                    "title": "File:A child playing near Shaniwar Wada, Pune.jpg",
                    "imageinfo": [{
                        "url": "https://example.com/child.jpg",
                        "thumburl": "https://example.com/child_thumb.jpg",
                        "mime": "image/jpeg",
                        "width": 1200, "height": 800,
                        "extmetadata": {"Artist": {"value": "Photographer A"}}
                    }]
                },
                "2": {
                    "title": "File:Shaniwar Wada pune, maharashtra.jpg",
                    "imageinfo": [{
                        "url": "https://example.com/fort.jpg",
                        "thumburl": "https://example.com/fort_thumb.jpg",
                        "mime": "image/jpeg",
                        "width": 1600, "height": 1200,
                        "extmetadata": {"Artist": {"value": "Photographer B"}}
                    }]
                }
            }
        }
    }

    with patch("requests.get") as mock_get:
        r = MagicMock()
        r.status_code = 200
        r.json.return_value = mock_resp
        mock_get.return_value = r

        result = service.search_photo("Shaniwar Wada", "Pune")
        assert result is not None
        assert result["title"] == "File:Shaniwar Wada pune, maharashtra.jpg"
        assert result["image_url"] == "https://example.com/fort_thumb.jpg"

def test_wikipedia_summary_secondary_fallback():
    """Verify fallback to Wikipedia article summary when Commons returns no results."""
    service = WikimediaPhotoService()

    # Empty Commons response
    empty_commons = {"query": {"pages": {}}}
    # Valid Wikipedia summary response
    wiki_summary = {
        "title": "Elephanta Caves",
        "thumbnail": {
            "source": "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d9/Elephanta_Trimurti.jpg/800px-Elephanta_Trimurti.jpg",
            "width": 800,
            "height": 600
        }
    }

    def mock_requests_get(url, *args, **kwargs):
        r = MagicMock()
        r.status_code = 200
        if "commons.wikimedia.org" in url:
            r.json.return_value = empty_commons
        elif "en.wikipedia.org" in url:
            r.json.return_value = wiki_summary
        return r

    with patch("requests.get", side_effect=mock_requests_get):
        result = service.search_photo("Elephanta Caves", "Mumbai")
        assert result is not None
        assert result["source"] == "Wikipedia"
        assert "Elephanta_Trimurti.jpg" in result["image_url"]
        assert 'Photo via Wikipedia article "Elephanta Caves"' in result["attribution"]

def test_unknown_attraction_strictly_returns_none():
    """Verify that when no photo is found on Commons or Wikipedia, None is returned without fake substitution."""
    service = WikimediaPhotoService()

    def mock_requests_get(url, *args, **kwargs):
        r = MagicMock()
        if "commons.wikimedia.org" in url:
            r.status_code = 200
            r.json.return_value = {"query": {"pages": {}}}
        else:
            r.status_code = 404
            r.json.return_value = {}
        return r

    with patch("requests.get", side_effect=mock_requests_get):
        result = service.search_photo("TotallyNonExistentAttraction12345", "Nowhere")
        assert result is None
