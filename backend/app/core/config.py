import os
from typing import List
from dotenv import load_dotenv

# Load environment variables from backend/.env if present
env_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), ".env")
if os.path.exists(env_path):
    load_dotenv(env_path)
else:
    load_dotenv()

class Settings:
    PROJECT_NAME: str = "AI Tourist Backend"
    API_V1_STR: str = "/api/v1"
    DEBUG: bool = os.getenv("DEBUG", "True").lower() in ("true", "1")
    
    # Hugging Face Settings
    HF_API_TOKEN: str = os.getenv("HF_API_TOKEN", "")
    HF_MODEL_ID: str = os.getenv("HF_MODEL_ID", "meta-llama/Llama-3.2-3B-Instruct")
    
    # Firebase
    FIREBASE_CREDENTIALS_PATH: str = os.getenv("FIREBASE_CREDENTIALS_PATH", "")
    FIREBASE_PROJECT_ID: str = os.getenv("FIREBASE_PROJECT_ID", "ai-tourist-demo")
    
    # Open-Data Providers (Free / No Paid Key Required)
    OSM_OVERPASS_URL: str = os.getenv(
        "OSM_OVERPASS_URL",
        "https://overpass-api.de/api/interpreter"
    )
    OSM_OVERPASS_BACKUP_URL: str = os.getenv(
        "OSM_OVERPASS_BACKUP_URL",
        "https://overpass.kumi.systems/api/interpreter"
    )
    WIKIMEDIA_COMMONS_URL: str = os.getenv(
        "WIKIMEDIA_COMMONS_URL",
        "https://commons.wikimedia.org/w/api.php"
    )
    OSRM_ROUTING_URL: str = os.getenv(
        "OSRM_ROUTING_URL",
        "https://router.project-osrm.org"
    )

    # Legacy / Optional
    GOOGLE_PLACES_API_KEY: str = os.getenv("GOOGLE_PLACES_API_KEY", "")
    OPENTRIPMAP_API_KEY: str = os.getenv("OPENTRIPMAP_API_KEY", "")

    # CORS
    ALLOWED_ORIGINS: List[str] = ["*"]

settings = Settings()
