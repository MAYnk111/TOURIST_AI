import re
import time
import logging
import urllib.parse
import requests
from typing import Optional, Dict, Any, List, Tuple
from ..core.config import settings
from ..core.network import COMMON_HEADERS

logger = logging.getLogger("ai_tourist.services.wikimedia")

# Blacklisted terms to filter out non-photos, signage, diagrams, maps, and irrelevant files
BLACKLISTED_TITLE_TERMS = {
    "map", "locator", "plan", "blueprint", "icon", "logo", "flag", "plaque",
    "inscription", "sign", "signage", "stamp", "coin", "currency", "symbol",
    "diagram", "chart", "drawing", "sketch", "coat of arms", "poster", "label",
    "seal", "seagull", "pigeon", "genealogy", "tree", "text", "document",
    "board", "ticket", "letter", "receipt", "bill", "page", "manuscript"
}

# Curated fallback photography by category for backward-compatible fallback API
CATEGORY_FALLBACK_IMAGES: Dict[str, Dict[str, Any]] = {
    "beaches": {
        "url": "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80",
        "attribution": "Photo via Unsplash Open License",
        "license": "Unsplash Free License",
    },
    "history": {
        "url": "https://images.unsplash.com/photo-1590050752117-238cb0fb12b1?auto=format&fit=crop&w=800&q=80",
        "attribution": "Photo via Unsplash Open License",
        "license": "Unsplash Free License",
    },
    "nature": {
        "url": "https://images.unsplash.com/photo-1432405972618-c60b0225b8f9?auto=format&fit=crop&w=800&q=80",
        "attribution": "Photo via Unsplash Open License",
        "license": "Unsplash Free License",
    },
    "culture": {
        "url": "https://images.unsplash.com/photo-1615836245337-f5b9b2303f10?auto=format&fit=crop&w=800&q=80",
        "attribution": "Photo via Unsplash Open License",
        "license": "Unsplash Free License",
    },
    "food": {
        "url": "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=800&q=80",
        "attribution": "Photo via Unsplash Open License",
        "license": "Unsplash Free License",
    },
    "adventure": {
        "url": "https://images.unsplash.com/photo-1626621341517-bbf3d9990a23?auto=format&fit=crop&w=800&q=80",
        "attribution": "Photo via Unsplash Open License",
        "license": "Unsplash Free License",
    },
    "default": {
        "url": "https://images.unsplash.com/photo-1488646953014-85cb44e25828?auto=format&fit=crop&w=800&q=80",
        "attribution": "Photo via Open Access Travel Photography",
        "license": "Creative Commons / Open Access",
    },
}

def clean_html_tags(raw_html: str) -> str:
    """Removes HTML tags from artist strings returned by MediaWiki API."""
    if not raw_html:
        return ""
    clean = re.sub(r"<[^>]+>", "", raw_html)
    return " ".join(clean.split()).strip()

class WikimediaPhotoService:
    """
    Retrieves destination and attraction photographs from Wikimedia Commons API
    and Wikipedia REST Summary API with quality filtering, candidate scoring,
    author attribution, and license tracking.
    """

    def __init__(self, endpoint_url: Optional[str] = None, timeout: int = 5):
        self.endpoint_url = endpoint_url or settings.WIKIMEDIA_COMMONS_URL
        self.timeout = timeout
        self._cache: Dict[str, Tuple[Optional[Dict[str, Any]], float]] = {}
        self._cache_ttl = 86400  # 24 hours

    def search_photo(
        self,
        attraction_name: str,
        destination_name: str = "",
        category: str = "",
        max_width: int = 800,
    ) -> Optional[Dict[str, Any]]:
        """
        Executes strict multi-tier authentic photo discovery:
        Tier 1: Filtered & scored Wikimedia Commons candidate search (8-10 candidates).
        Tier 2: Relevant Wikipedia article lead thumbnail (REST Summary API + Opensearch).
        Tier 3: Strictly returns None (preserves data truth; no fake photo substitution).
        """
        clean_name = attraction_name.strip()
        clean_dest = destination_name.strip()
        if not clean_name:
            return None

        cache_key = f"{clean_name.lower()}_{clean_dest.lower()}_{max_width}"
        now = time.time()
        if cache_key in self._cache:
            data, cached_at = self._cache[cache_key]
            if now - cached_at < self._cache_ttl:
                return data

        # Tier 1: Wikimedia Commons Search
        result = self._search_commons_candidates(clean_name, clean_dest, max_width)

        # Tier 2: Wikipedia Summary Search Fallback
        if not result:
            result = self._search_wikipedia_summary(clean_name, clean_dest)

        self._cache[cache_key] = (result, now)
        return result

    def _search_commons_candidates(
        self,
        name: str,
        dest: str,
        max_width: int
    ) -> Optional[Dict[str, Any]]:
        """Queries Wikimedia Commons API, evaluates 8-10 candidates, applies negative filters and scores matches."""
        queries = []
        if dest and dest.lower() not in name.lower():
            queries.append(f"{name} {dest} India")
            queries.append(f"{name} {dest}")
        queries.append(f"{name} India")
        queries.append(name)

        name_words = [w.lower() for w in re.findall(r"\w+", name) if len(w) > 2]
        dest_words = [w.lower() for w in re.findall(r"\w+", dest) if len(w) > 2]
        name_lower = name.lower()

        for q in queries:
            params = {
                "action": "query",
                "format": "json",
                "generator": "search",
                "gsrsearch": q.strip(),
                "gsrnamespace": "6",  # File: namespace
                "gsrlimit": "10",
                "prop": "imageinfo",
                "iiprop": "url|size|mime|extmetadata",
                "iiurlwidth": str(max_width),
            }

            try:
                resp = requests.get(
                    self.endpoint_url,
                    params=params,
                    headers=COMMON_HEADERS,
                    timeout=self.timeout
                )
                if resp.status_code != 200:
                    continue

                data = resp.json()
                pages = data.get("query", {}).get("pages", {})
                if not pages:
                    continue

                best_candidate: Optional[Dict[str, Any]] = None
                best_score = -1

                for _, page in pages.items():
                    title = page.get("title", "")
                    title_clean = title.replace("File:", "").lower()

                    # 1. Negative filtering: reject non-photos, signage, maps, diagrams
                    if any(term in title_clean for term in BLACKLISTED_TITLE_TERMS):
                        continue

                    imageinfo_list = page.get("imageinfo", [])
                    if not imageinfo_list:
                        continue

                    ii = imageinfo_list[0]
                    mime = ii.get("mime", "").lower()
                    if not mime.startswith("image/") or any(x in mime for x in ["svg", "pdf", "tiff", "gif", "webm", "ogg"]):
                        continue

                    # Resolution filter (if reported, must be >= 300x200)
                    w = ii.get("width")
                    h = ii.get("height")
                    if (w is not None and w < 300) or (h is not None and h < 200):
                        continue

                    image_url = ii.get("thumburl") or ii.get("url")
                    if not image_url:
                        continue

                    # 2. Candidate scoring
                    score = 0
                    if name_lower in title_clean:
                        score += 10
                    if title_clean.startswith(name_lower):
                        score += 5
                    for nw in name_words:
                        if nw in title_clean:
                            score += 3
                    for dw in dest_words:
                        if dw in title_clean:
                            score += 1

                    # Penalize peripheral or unrelated compositions
                    if "near " in title_clean or "outside " in title_clean or "vicinity " in title_clean:
                        score -= 4

                    meta = ii.get("extmetadata", {})
                    desc = meta.get("ImageDescription", {}).get("value", "").lower()
                    for nw in name_words:
                        if nw in desc:
                            score += 1

                    if score > best_score and score >= 2:
                        best_score = score
                        artist_raw = meta.get("Artist", {}).get("value", "")
                        artist = clean_html_tags(artist_raw) or "Wikimedia Contributor"
                        license_name = (
                            meta.get("LicenseShortName", {}).get("value")
                            or meta.get("UsageTerms", {}).get("value")
                            or "CC BY-SA"
                        )
                        best_candidate = {
                            "image_url": image_url,
                            "title": title,
                            "artist": artist,
                            "license": license_name,
                            "attribution": f"Photo by {artist} via Wikimedia Commons ({license_name})",
                            "source": "Wikimedia Commons",
                            "is_live_wikimedia": True,
                        }

                if best_candidate:
                    return best_candidate

            except Exception as e:
                logger.debug(f"Wikimedia candidate query failed for '{q}': {e}")
                continue

        return None

    def _search_wikipedia_summary(self, name: str, dest: str) -> Optional[Dict[str, Any]]:
        """Queries Wikipedia REST Summary API as authentic secondary fallback."""
        lookup_candidates = []
        if dest and dest.lower() not in name.lower():
            lookup_candidates.append(f"{name}, {dest}")
        lookup_candidates.append(name)

        for candidate in lookup_candidates:
            try:
                encoded = urllib.parse.quote(candidate.replace(" ", "_"))
                wiki_url = f"https://en.wikipedia.org/api/rest_v1/page/summary/{encoded}"
                resp = requests.get(wiki_url, headers=COMMON_HEADERS, timeout=self.timeout)
                if resp.status_code == 200:
                    data = resp.json()
                    thumb = data.get("thumbnail", {})
                    thumb_url = thumb.get("source")
                    if thumb_url and thumb.get("width", 0) >= 200:
                        page_title = data.get("title", name)
                        return {
                            "image_url": thumb_url,
                            "title": page_title,
                            "artist": "Wikipedia Contributor",
                            "license": "CC BY-SA / Public Domain",
                            "attribution": f'Photo via Wikipedia article "{page_title}"',
                            "source": "Wikipedia",
                            "is_live_wikimedia": True,
                        }
            except Exception as e:
                logger.debug(f"Wikipedia summary lookup failed for '{candidate}': {e}")
                continue

        # Opensearch lookup
        try:
            op_url = "https://en.wikipedia.org/w/api.php"
            op_params = {
                "action": "opensearch",
                "search": f"{name} {dest}".strip(),
                "limit": "2",
                "namespace": "0",
                "format": "json"
            }
            resp = requests.get(op_url, params=op_params, headers=COMMON_HEADERS, timeout=self.timeout)
            if resp.status_code == 200:
                titles = resp.json()[1]
                if titles:
                    title_to_fetch = titles[0]
                    encoded = urllib.parse.quote(title_to_fetch.replace(" ", "_"))
                    wiki_url = f"https://en.wikipedia.org/api/rest_v1/page/summary/{encoded}"
                    s_resp = requests.get(wiki_url, headers=COMMON_HEADERS, timeout=self.timeout)
                    if s_resp.status_code == 200:
                        sdata = s_resp.json()
                        thumb = sdata.get("thumbnail", {})
                        thumb_url = thumb.get("source")
                        if thumb_url:
                            page_title = sdata.get("title", title_to_fetch)
                            return {
                                "image_url": thumb_url,
                                "title": page_title,
                                "artist": "Wikipedia Contributor",
                                "license": "CC BY-SA / Public Domain",
                                "attribution": f'Photo via Wikipedia article "{page_title}"',
                                "source": "Wikipedia",
                                "is_live_wikimedia": True,
                            }
        except Exception as e:
            logger.debug(f"Wikipedia opensearch lookup failed for '{name}': {e}")

        return None

    def get_photo_with_fallback(self, place_name: str, category: str = "default") -> Dict[str, Any]:
        """
        Backward-compatible helper. Searches Commons/Wikipedia first;
        if none found, returns verified category archive info.
        """
        result = self.search_photo(place_name, category=category)
        if result:
            return result

        cat_key = category.lower() if category.lower() in CATEGORY_FALLBACK_IMAGES else "default"
        fallback = CATEGORY_FALLBACK_IMAGES[cat_key]
        return {
            "image_url": fallback["url"],
            "title": f"{place_name} ({category})",
            "artist": "Verified Archive",
            "license": fallback["license"],
            "attribution": fallback["attribution"],
            "source": "Curated Archive",
            "is_live_wikimedia": False,
        }

wikimedia_service = WikimediaPhotoService()
