import math
import logging
import requests
from typing import Optional, Dict, Any, Tuple
from ..core.config import settings
from ..core.network import COMMON_HEADERS

logger = logging.getLogger("ai_tourist.services.osrm")

def haversine_distance_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculates straight-line great-circle distance in kilometers."""
    if lat1 == 0.0 or lat2 == 0.0 or (lat1 == lat2 and lon1 == lon2):
        return 0.0
    R = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (
        math.sin(dlat / 2) ** 2
        + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return round(R * c, 2)

class OSRMRoutingService:
    """
    Open Source Routing Machine (OSRM) integration for road transit calculation.
    Provides driving distance and duration with guaranteed straight-line fallback.
    """

    def __init__(self, endpoint_url: Optional[str] = None, timeout: float = 3.5):
        self.endpoint_url = (endpoint_url or settings.OSRM_ROUTING_URL).rstrip("/")
        self.timeout = timeout
        self._cache: Dict[str, Dict[str, Any]] = {}

    def get_route(
        self,
        lat1: float,
        lon1: float,
        lat2: float,
        lon2: float
    ) -> Dict[str, Any]:
        """
        Calculates road transit between two coordinates.
        Coordinates are passed as (lat, lon); OSRM expects {lon},{lat}.
        """
        # If coordinates are identical or missing, return immediate zero distance
        if (lat1 == 0.0 and lon1 == 0.0) or (lat2 == 0.0 and lon2 == 0.0):
            return self._build_approximate_fallback(lat1, lon1, lat2, lon2, reason="Coordinates missing")

        if abs(lat1 - lat2) < 0.0001 and abs(lon1 - lon2) < 0.0001:
            return {
                "distance_km": 0.0,
                "duration_minutes": 0.0,
                "duration_hours": 0.0,
                "is_routed": True,
                "provider": "OSRM (Same Location)",
                "summary": "Same location",
            }

        cache_key = f"{round(lat1, 4)},{round(lon1, 4)}_{round(lat2, 4)},{round(lon2, 4)}"
        if cache_key in self._cache:
            return self._cache[cache_key]

        # OSRM format: /route/v1/driving/{lon1},{lat1};{lon2},{lat2}?overview=false
        url = f"{self.endpoint_url}/route/v1/driving/{lon1},{lat1};{lon2},{lat2}?overview=false"

        try:
            resp = requests.get(url, headers=COMMON_HEADERS, timeout=self.timeout)
            if resp.status_code == 200:
                data = resp.json()
                if data.get("code") == "Ok" and data.get("routes"):
                    route = data["routes"][0]
                    distance_m = route.get("distance", 0.0)
                    duration_s = route.get("duration", 0.0)

                    dist_km = round(distance_m / 1000.0, 2)
                    dur_mins = round(duration_s / 60.0, 1)
                    dur_hours = round(dur_mins / 60.0, 2)

                    result = {
                        "distance_km": dist_km,
                        "duration_minutes": dur_mins,
                        "duration_hours": dur_hours,
                        "is_routed": True,
                        "provider": "OSRM (Open Source Routing Machine)",
                        "summary": f"Road transit ~{int(dur_mins)} mins ({dist_km} km) via OSRM",
                    }
                    self._cache[cache_key] = result
                    return result
                else:
                    reason = f"OSRM code: {data.get('code', 'Unknown')}"
                    return self._build_approximate_fallback(lat1, lon1, lat2, lon2, reason=reason)
            else:
                reason = f"OSRM HTTP {resp.status_code}"
                return self._build_approximate_fallback(lat1, lon1, lat2, lon2, reason=reason)

        except Exception as e:
            logger.debug(f"OSRM transit lookup error: {e}. Falling back to calibrated straight-line estimate.")
            return self._build_approximate_fallback(lat1, lon1, lat2, lon2, reason=str(e))

    def _build_approximate_fallback(
        self,
        lat1: float,
        lon1: float,
        lat2: float,
        lon2: float,
        reason: str = "Fallback"
    ) -> Dict[str, Any]:
        """
        Calibrated straight-line Haversine fallback:
        - Detour factor: 1.35x for realistic road curvature
        - Urban/scenic transit speed: 30 km/h
        Clearly flags is_routed: False.
        """
        straight_km = haversine_distance_km(lat1, lon1, lat2, lon2)
        if straight_km == 0.0 and (lat1 != 0.0 or lat2 != 0.0):
            straight_km = 5.0  # reasonable default between local attractions

        estimated_road_km = round(straight_km * 1.35, 2)
        estimated_hours = round(estimated_road_km / 30.0, 2)
        estimated_minutes = round(estimated_hours * 60.0, 1)

        return {
            "distance_km": estimated_road_km,
            "duration_minutes": estimated_minutes,
            "duration_hours": estimated_hours,
            "is_routed": False,
            "provider": f"Haversine Estimate (1.35x Detour Factor) [{reason}]",
            "summary": f"Approx. transit ~{int(estimated_minutes)} mins ({estimated_road_km} km, straight-line estimate)",
        }

osrm_service = OSRMRoutingService()
