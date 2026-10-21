from typing import List, Optional
from fastapi import APIRouter, HTTPException, Query, Header, Depends
from fastapi.responses import RedirectResponse
from ...core.security import verify_firebase_token
from ...models.schemas import (
    DestinationModel,
    AttractionModel,
    RecommendationRequest,
    RecommendationResponse,
    CostEstimateRequest,
    CostEstimateResponse,
    GenerateItineraryRequest,
    ItineraryResponse,
    ChatRequest,
    ChatResponse,
)
from ...providers.hybrid_provider import destination_provider
from ...services.wikimedia_service import wikimedia_service
from ...services.osrm_routing_service import osrm_service
from ...ml.recommendation import recommender
from ...ml.cost_estimation import cost_service
from ...ml.itinerary_optimizer import itinerary_optimizer
from ...services.hf_assistant import assistant_service
from ...core.firebase import firebase_manager

router = APIRouter()

@router.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": "AI Tourist Backend",
        "firebase_connected": firebase_manager.is_live,
        "ml_cost_model": "RandomForestRegressor (Loaded)",
        "hf_model": assistant_service.model_id,
        "provider_status": destination_provider.get_provider_status(),
    }

@router.get("/providers/status")
def provider_status():
    return destination_provider.get_provider_status()

@router.get("/destinations", response_model=List[DestinationModel])
def get_destinations():
    return destination_provider.get_destinations()

@router.get("/destinations/search", response_model=List[DestinationModel])
def search_destinations(q: str = Query(..., min_length=1)):
    return destination_provider.search_destinations(q)

@router.get("/attractions/search", response_model=List[AttractionModel])
def search_attractions(q: str = Query(..., min_length=1)):
    return destination_provider.search_attractions(q)

@router.get("/destinations/{dest_id}", response_model=DestinationModel)
def get_destination(dest_id: str):
    dest = destination_provider.get_destination(dest_id)
    if not dest:
        raise HTTPException(status_code=404, detail="Destination not found")
    return dest

@router.get("/destinations/{dest_id}/attractions", response_model=List[AttractionModel])
def get_attractions(
    dest_id: str,
    category: Optional[str] = None,
    lat: Optional[float] = None,
    lon: Optional[float] = None,
):
    return destination_provider.get_attractions(
        destination_id=dest_id,
        category=category,
        lat=lat,
        lon=lon,
    )

@router.get("/attractions", response_model=List[AttractionModel])
def get_attractions_query(
    destination_id: str = Query("goa"),
    category: Optional[str] = None,
    lat: Optional[float] = None,
    lon: Optional[float] = None,
):
    return destination_provider.get_attractions(
        destination_id=destination_id,
        category=category,
        lat=lat,
        lon=lon,
    )

@router.get("/attractions/{place_id}", response_model=AttractionModel)
def get_attraction_details(place_id: str):
    attr = destination_provider.get_attraction_details(place_id)
    if not attr:
        raise HTTPException(status_code=404, detail="Attraction not found")
    return attr

@router.get("/places/photo")
def get_place_photo(photo_name: str = Query(...), max_height: int = 800, max_width: int = 1200):
    """
    Open-Access Tourist Photo Proxy:
    Resolves photos via Wikimedia Commons API and verified open-access archives with 24h caching.
    """
    photo_info = wikimedia_service.get_photo_with_fallback(photo_name)
    return RedirectResponse(
        url=photo_info["image_url"],
        status_code=307,
        headers={"Cache-Control": "public, max-age=86400"},
    )

@router.get("/routes/transit")
def calculate_transit(
    lat1: float = Query(...),
    lon1: float = Query(...),
    lat2: float = Query(...),
    lon2: float = Query(...)
):
    """
    Calculates road transit using Open Source Routing Machine (OSRM) with Haversine fallback.
    """
    return osrm_service.get_route(lat1, lon1, lat2, lon2)

@router.post("/recommendations", response_model=List[AttractionModel])
def get_recommendations(interests: List[str], budget_per_person: float = 15000.0, top_k: int = 5):
    recs = recommender.recommend(interests=interests, user_budget_per_person=budget_per_person, top_k=top_k)
    return [r[0] for r in recs]

@router.post("/recommendations/personalized", response_model=RecommendationResponse)
def get_personalized_recommendations(req: RecommendationRequest):
    return recommender.recommend_personalized(req)

@router.post("/trips/estimate-cost", response_model=CostEstimateResponse)
def estimate_cost(req: CostEstimateRequest):
    return cost_service.estimate_cost(
        destination=req.destination,
        days=req.days,
        travelers=req.travelers,
        travel_style=req.travel_style,
        user_budget=req.user_budget,
        budget_per_person=req.budget_per_person,
    )

@router.post("/trips/generate-itinerary", response_model=ItineraryResponse)
def generate_itinerary(req: GenerateItineraryRequest):
    return itinerary_optimizer.generate(req)

@router.post("/assistant/chat", response_model=ChatResponse)
def assistant_chat(req: ChatRequest):
    return assistant_service.chat(
        user_message=req.message,
        history=req.history,
        destination=req.destination,
        travelers=req.travelers,
        budget_per_person=req.budget_per_person,
        interests=req.interests,
        dates=req.dates,
    )

@router.post("/trips")
def save_trip(trip: dict, user: dict = Depends(verify_firebase_token)):
    user_id = user.get("uid", "usr_mayank")
    trip_id = firebase_manager.save_trip(user_id=user_id, trip_data=trip)
    return {"status": "saved", "trip_id": trip_id, "user_id": user_id}

@router.get("/trips")
def get_user_trips(user: dict = Depends(verify_firebase_token)):
    user_id = user.get("uid", "usr_mayank")
    return firebase_manager.get_user_trips(user_id=user_id)

@router.get("/trips/{trip_id}")
def get_trip_by_id(trip_id: str, user: dict = Depends(verify_firebase_token)):
    user_id = user.get("uid", "usr_mayank")
    trip = firebase_manager.get_trip(trip_id, caller_user_id=user_id)
    if not trip:
        raise HTTPException(status_code=404, detail="Trip not found")
    return trip

@router.put("/trips/{trip_id}")
def update_trip_by_id(trip_id: str, trip: dict, user: dict = Depends(verify_firebase_token)):
    user_id = user.get("uid", "usr_mayank")
    firebase_manager.update_trip(user_id=user_id, trip_id=trip_id, trip_data=trip)
    return {"status": "updated", "trip_id": trip_id, "user_id": user_id}

@router.delete("/trips/{trip_id}")
def delete_trip_by_id(trip_id: str, user: dict = Depends(verify_firebase_token)):
    user_id = user.get("uid", "usr_mayank")
    firebase_manager.delete_trip(user_id=user_id, trip_id=trip_id)
    return {"status": "deleted", "trip_id": trip_id}
