import pytest
from unittest.mock import patch, MagicMock
from app.providers.osm_provider import OsmOverpassProvider, map_osm_category, format_osm_address
from app.services.wikimedia_service import WikimediaPhotoService, clean_html_tags
from app.services.osrm_routing_service import OSRMRoutingService, haversine_distance_km
from app.providers.hybrid_provider import OpenDataDestinationProvider
from app.ml.recommendation import ContentBasedRecommender
from app.main import app
from fastapi.testclient import TestClient

client = TestClient(app)

MOCK_OVERPASS_RESPONSE = {
    "elements": [
        {
            "type": "node",
            "id": 1001,
            "lat": 15.4920,
            "lon": 73.7737,
            "tags": {
                "name": "Aguada Lighthouse",
                "historic": "lighthouse",
                "tourism": "attraction",
                "addr:street": "Sinquerim",
                "addr:city": "Candolim",
                "opening_hours": "09:30-18:00"
            }
        },
        # Duplicate of Aguada Lighthouse with same name to test name deduplication
        {
            "type": "node",
            "id": 1002,
            "lat": 15.4921,
            "lon": 73.7738,
            "tags": {
                "name": "Aguada Lighthouse",
                "tourism": "attraction"
            }
        },
        # Way element with center coordinates to test center extraction
        {
            "type": "way",
            "id": 2001,
            "center": {"lat": 15.5553, "lon": 73.7517},
            "tags": {
                "name": "Baga Seashore",
                "natural": "beach",
                "tourism": "attraction"
            }
        },
        # Element without name (must be safely skipped)
        {
            "type": "node",
            "id": 3001,
            "lat": 15.5000,
            "lon": 73.7600,
            "tags": {"tourism": "viewpoint"}
        }
    ]
}

MOCK_WIKIMEDIA_RESPONSE = {
    "query": {
        "pages": {
            "45678": {
                "pageid": 45678,
                "title": "File:Fort Aguada Goa 2021.jpg",
                "imageinfo": [
                    {
                        "url": "https://upload.wikimedia.org/wikipedia/commons/1/12/Fort_Aguada_Goa_2021.jpg",
                        "thumburl": "https://thumb.wikimedia.org/wikipedia/commons/thumb/1/12/Fort_Aguada_Goa_2021.jpg/800px-Fort_Aguada_Goa_2021.jpg",
                        "mime": "image/jpeg",
                        "extmetadata": {
                            "Artist": {"value": "<a href=\"//commons.wikimedia.org/wiki/User:Traveler\">Rohan Sharma</a>"},
                            "LicenseShortName": {"value": "CC BY-SA 4.0"}
                        }
                    }
                ]
            }
        }
    }
}

MOCK_OSRM_SUCCESS_RESPONSE = {
    "code": "Ok",
    "routes": [
        {
            "distance": 9394.8,  # meters
            "duration": 701.4,   # seconds
            "weight": 701.4,
            "weight_name": "routability"
        }
    ],
    "waypoints": [{"location": [73.7554, 15.5442]}, {"location": [73.7737, 15.4920]}]
}

# ==========================================
# 1. OpenStreetMap Overpass Provider Tests
# ==========================================

def test_osm_parsing_and_normalization():
    provider = OsmOverpassProvider()

    with patch.object(provider, "_execute_overpass_query", return_value=MOCK_OVERPASS_RESPONSE["elements"]):
        attractions = provider.get_attractions("goa")

        # Deduplication verified: 4 elements -> 2 valid unique attractions (1 duplicate dropped, 1 unnamed dropped)
        assert len(attractions) == 2

        # Node parsing verified
        first = attractions[0]
        assert first.id == "osm_node_1001"
        assert first.name == "Aguada Lighthouse"
        assert first.category == "History"
        assert first.latitude == 15.4920
        assert first.longitude == 73.7737
        assert "Sinquerim" in first.formatted_address
        assert first.opening_hours == "09:30-18:00"

        # Truthful data: Ratings & review counts MUST be None (never fabricated)
        assert first.rating is None
        assert first.review_count is None
        assert first.provider == "openstreetmap"
        assert first.is_live_data is True

        # Way with center coordinates parsing verified
        second = attractions[1]
        assert second.id == "osm_way_2001"
        assert second.name == "Baga Seashore"
        assert second.category == "Beaches"
        assert second.latitude == 15.5553
        assert second.longitude == 73.7517
        assert second.rating is None

def test_osm_category_mapping():
    assert map_osm_category({"natural": "beach"}, "Candolim Beach") == "Beaches"
    assert map_osm_category({"historic": "fort"}, "Chapora Fort") == "History"
    assert map_osm_category({"tourism": "museum"}, "Goa State Museum") == "Culture"
    assert map_osm_category({"tourism": "viewpoint"}, "Sunset Point") == "Nature"
    assert map_osm_category({"tourism": "theme_park"}, "Splashdown Waterpark") == "Adventure"
    assert map_osm_category({"amenity": "restaurant"}, "Local Seafood Shack") == "Food"

def test_osm_format_address():
    tags = {
        "addr:housenumber": "42",
        "addr:street": "Beach Road",
        "addr:city": "Calangute",
        "addr:postcode": "403516"
    }
    address = format_osm_address(tags, "Goa")
    assert "42 Beach Road" in address
    assert "Calangute" in address
    assert "403516" in address

def test_osm_error_and_timeout_resilience():
    provider = OsmOverpassProvider()

    with patch("requests.post") as mock_post:
        # Simulate 504 Gateway Timeout from public server
        mock_resp = MagicMock()
        mock_resp.status_code = 504
        mock_post.return_value = mock_resp

        elements = provider._execute_overpass_query("test query")
        assert elements == []
        assert "504" in provider.last_error

# ==========================================
# 2. Wikimedia Commons Photo Service Tests
# ==========================================

def test_clean_html_tags():
    raw = '<a href="//commons.wikimedia.org/wiki/User:Photographer">John Doe</a>'
    assert clean_html_tags(raw) == "John Doe"
    assert clean_html_tags("Jane Smith") == "Jane Smith"
    assert clean_html_tags("") == ""

def test_wikimedia_search_success():
    service = WikimediaPhotoService()

    with patch("requests.get") as mock_get:
        mock_resp = MagicMock()
        mock_resp.status_code = 200
        mock_resp.json.return_value = MOCK_WIKIMEDIA_RESPONSE
        mock_get.return_value = mock_resp

        result = service.search_photo("Fort Aguada")
        assert result is not None
        assert "thumb.wikimedia.org" in result["image_url"]
        assert result["artist"] == "Rohan Sharma"
        assert result["license"] == "CC BY-SA 4.0"
        assert "Photo by Rohan Sharma via Wikimedia Commons (CC BY-SA 4.0)" in result["attribution"]
        assert result["is_live_wikimedia"] is True

def test_wikimedia_fallback_on_timeout():
    service = WikimediaPhotoService()

    with patch("requests.get", side_effect=Exception("Connection timed out")):
        result = service.get_photo_with_fallback("Unknown Remote Temple", "Culture")
        assert result is not None
        assert result["is_live_wikimedia"] is False
        assert "Unsplash Free License" in result["license"]
        assert len(result["image_url"]) > 0

# ==========================================
# 3. OSRM Routing Service Tests
# ==========================================

def test_haversine_distance():
    # Distance between Baga (15.5553, 73.7517) and Fort Aguada (15.4920, 73.7737) ~ 7.4 km straight-line
    dist = haversine_distance_km(15.5553, 73.7517, 15.4920, 73.7737)
    assert 6.0 <= dist <= 9.0

def test_osrm_routing_success():
    service = OSRMRoutingService()

    with patch("requests.get") as mock_get:
        mock_resp = MagicMock()
        mock_resp.status_code = 200
        mock_resp.json.return_value = MOCK_OSRM_SUCCESS_RESPONSE
        mock_get.return_value = mock_resp

        route = service.get_route(15.5442, 73.7554, 15.4920, 73.7737)
        assert route["is_routed"] is True
        assert route["distance_km"] == 9.39
        assert route["duration_minutes"] == 11.7
        assert "OSRM" in route["provider"]
        assert "9.39 km" in route["summary"]

def test_osrm_routing_fallback_on_unreachable():
    service = OSRMRoutingService()

    with patch("requests.get", side_effect=Exception("Network unreachable")):
        route = service.get_route(15.5442, 73.7554, 15.4920, 73.7737)
        assert route["is_routed"] is False
        assert route["distance_km"] > 0
        assert route["duration_minutes"] > 0
        assert "Haversine Estimate" in route["provider"]

# ==========================================
# 4. Open-Data Provider Stack & Status Endpoint
# ==========================================

def test_provider_status_endpoint():
    response = client.get("/api/v1/providers/status")
    assert response.status_code == 200
    data = response.json()

    assert "OpenStreetMap" in data["active_place_provider"] or "Verified" in data["active_place_provider"]
    assert "Wikimedia" in data["active_photo_provider"]
    assert "OSRM" in data["active_routing_provider"]
    assert data["has_api_key_required"] is False
    assert "attribution" in data
    assert "osm_overpass_url" in data["provider_endpoints"]

def test_photo_proxy_endpoint_redirects():
    response = client.get(
        "/api/v1/places/photo?photo_name=Fort Aguada",
        follow_redirects=False
    )
    # Redirects (307 Temporary Redirect) to Wikimedia or open-access photo URL
    assert response.status_code == 307
    assert "location" in response.headers

def test_route_transit_endpoint():
    response = client.get("/api/v1/routes/transit?lat1=15.5442&lon1=73.7554&lat2=15.4920&lon2=73.7737")
    assert response.status_code == 200
    data = response.json()
    assert "distance_km" in data
    assert "duration_minutes" in data
    assert "is_routed" in data

# ==========================================
# 5. ML Recommendations with OSM Places
# ==========================================

def test_recommender_with_normalized_osm_places():
    osm_provider = OsmOverpassProvider()
    with patch.object(osm_provider, "_execute_overpass_query", return_value=MOCK_OVERPASS_RESPONSE["elements"]):
        attractions = osm_provider.get_attractions("goa")

    recommender = ContentBasedRecommender(attractions=attractions)

    # Missing ratings must be handled safely without NaN or crash
    recs = recommender.recommend(interests=["Beaches"], top_k=2)
    assert len(recs) > 0
    top_place, score = recs[0]
    assert top_place.name == "Baga Seashore"  # Matched category & keyword
    assert top_place.rating is None           # Untampered null rating preserved
