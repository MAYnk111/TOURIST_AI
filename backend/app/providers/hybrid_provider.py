import logging
from typing import List, Optional, Dict, Any
from .base import BaseDestinationProvider
from .osm_provider import OsmOverpassProvider
from .mock_verified_provider import DestinationProvider as MockProvider, ATTRACTIONS_DATA, DESTINATIONS_DATA, normalize_dest_id
from ..models.schemas import DestinationModel, AttractionModel
from ..services.wikimedia_service import wikimedia_service
from ..services.osrm_routing_service import osrm_service

logger = logging.getLogger("ai_tourist.provider.open_data")

class OpenDataDestinationProvider(BaseDestinationProvider):
    """
    Open-data destination and attraction provider stack:
    1. OpenStreetMap (Overpass API) for geo-spatial POI discovery
    2. Wikimedia Commons API for authentic tourist photography & CC licensing
    3. Open Source Routing Machine (OSRM) for road transit estimation
    4. Verified Curated Offline Fallback for 100% resilient operation
    """

    def __init__(self):
        self.osm_provider = OsmOverpassProvider()
        self._last_live_success = False

    @property
    def provider_name(self) -> str:
        return "OpenStreetMap & Wikimedia Open-Data Stack"

    @property
    def is_configured(self) -> bool:
        return True  # 100% free / open data, no paid API key required

    def get_provider_status(self) -> Dict[str, Any]:
        has_error = self.osm_provider.last_error is not None
        is_live = self._last_live_success and not has_error

        place_provider = (
            "OpenStreetMap (Overpass API)"
            if is_live
            else "Verified Tourist Catalog (Resilient Fallback)"
        )

        return {
            # Primary Open-Data Provider Fields
            "active_place_provider": place_provider,
            "active_photo_provider": "Wikimedia Commons API",
            "active_routing_provider": "Open Source Routing Machine (OSRM)",
            "data_source_mode": "Live OpenStreetMap" if is_live else "Curated Verified Fallback",
            "is_live_data": is_live,
            "is_fallback": not is_live,
            "has_api_key_required": False,
            "status_message": (
                "Operational (Live OpenStreetMap & Wikimedia active)"
                if is_live
                else (
                    f"Resilient fallback active ({self.osm_provider.last_error})"
                    if has_error
                    else "Operational (Free Open-Data stack active, no paid API keys required)"
                )
            ),
            "attribution": "© OpenStreetMap contributors (ODbL), Wikimedia Commons contributors, OSRM routing",
            "provider_endpoints": {
                "osm_overpass_url": self.osm_provider.endpoint_url,
                "wikimedia_commons_url": wikimedia_service.endpoint_url,
                "osrm_routing_url": osrm_service.endpoint_url,
            },
            "last_error": self.osm_provider.last_error,

            # Backwards-compatible legacy fields
            "configured_provider": "OpenStreetMap & Open Data Stack",
            "active_provider": place_provider,
            "has_api_key": False,
        }

    def get_destinations(self) -> List[DestinationModel]:
        return MockProvider.get_destinations()

    def get_destination(self, dest_id: str) -> Optional[DestinationModel]:
        return self.osm_provider.get_destination(dest_id) or MockProvider.get_destination(dest_id)

    def search_destinations(self, query: str) -> List[DestinationModel]:
        return self.osm_provider.search_destinations(query)

    def get_attractions(
        self,
        destination_id: str = "goa",
        category: Optional[str] = None,
        lat: Optional[float] = None,
        lon: Optional[float] = None,
    ) -> List[AttractionModel]:
        norm_id = normalize_dest_id(destination_id)
        # 1. Attempt OpenStreetMap Overpass query
        try:
            osm_places = self.osm_provider.get_attractions(norm_id, category, lat=lat, lon=lon)
            if osm_places and len(osm_places) > 0:
                self._last_live_success = True
                return osm_places
        except Exception as e:
            logger.warning(f"OSM fetch failed: {e}. Falling back to curated catalog.")

        # 2. Resilient fallback to verified catalog for known destinations
        self._last_live_success = False
        mock_places = MockProvider.get_attractions(norm_id, category)
        if mock_places and len(mock_places) > 0:
            return mock_places

        # 3. For newly searched arbitrary destinations, dynamically generate destination-specific attractions
        return self.osm_provider.generate_fallback_attractions(norm_id, category, lat=lat, lon=lon)

    def search_attractions(self, query: str) -> List[AttractionModel]:
        # 1. Search cached/live OSM attractions first
        osm_matches = self.osm_provider.search_attractions(query)
        if osm_matches:
            return osm_matches

        # 2. Search curated catalog
        return MockProvider.search_attractions(query)

    def get_attraction_details(self, place_id: str) -> Optional[AttractionModel]:
        # 1. Check OSM provider
        osm_place = self.osm_provider.get_attraction_details(place_id)
        if osm_place:
            return osm_place

        # 2. Check verified catalog
        for a in ATTRACTIONS_DATA:
            if a.id == place_id:
                return a
        return None

destination_provider = OpenDataDestinationProvider()
