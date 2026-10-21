import socket
import logging
from typing import Dict

logger = logging.getLogger("ai_tourist.network")

# Force IPv4 in urllib3 to avoid Windows/ISP IPv6 handshake resets on public APIs
try:
    import urllib3.util.connection as urllib_conn
    def _force_ipv4():
        return socket.AF_INET
    urllib_conn.allowed_gai_family = _force_ipv4
    logger.debug("Configured urllib3 with AF_INET (IPv4 forced)")
except Exception as e:
    logger.debug(f"urllib3 IPv4 patch note: {e}")

COMMON_HEADERS: Dict[str, str] = {
    "User-Agent": "AITouristApp/1.0 (https://github.com/ai-tourist; contact@aitourist.local)"
}
