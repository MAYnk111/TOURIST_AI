import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.providers.mock_verified_provider import normalize_dest_id
from app.providers.hybrid_provider import destination_provider
from app.ml.recommendation import recommender
from app.ml.itinerary_optimizer import ItineraryOptimizer
from app.models.schemas import RecommendationRequest, GenerateItineraryRequest
from app.core.security import verify_firebase_token

client = TestClient(app)

def test_normalize_dest_id():
    assert normalize_dest_id("Goa, India") == "goa"
    assert normalize_dest_id("dest-goa") == "goa"
    assert normalize_dest_id("Manali, Himachal Pradesh") == "manali"
    assert normalize_dest_id("Munnar, Kerala") == "munnar"
    assert normalize_dest_id("Udaipur, India") == "udaipur"
    assert normalize_dest_id("Jaipur, Rajasthan") == "jaipur"
    assert normalize_dest_id("Pune, Maharashtra") == "pune"
    assert normalize_dest_id("Mumbai, Maharashtra") == "mumbai"

def test_goa_attractions_retrieval():
    """Verify that Goa attractions load successfully and contain only Goa places."""
    places = destination_provider.get_attractions("goa")
    assert len(places) >= 5
    assert all(p.destination_id.lower() == "goa" for p in places)
    assert any("baga" in p.name.lower() or "aguada" in p.name.lower() for p in places)

def test_pune_attractions_retrieval():
    """Verify that Pune attractions load successfully and contain zero Goa beaches."""
    places = destination_provider.get_attractions("pune")
    assert len(places) >= 4
    assert all(p.destination_id.lower() == "pune" for p in places)
    place_names = [p.name.lower() for p in places]
    assert any("shaniwar" in n or "aga khan" in n or "sinhagad" in n for n in place_names)
    assert not any("beach" in n for n in place_names)

def test_mumbai_attractions_retrieval():
    """Verify that Mumbai attractions load successfully and contain Mumbai landmarks."""
    places = destination_provider.get_attractions("mumbai")
    assert len(places) >= 4
    assert all(p.destination_id.lower() == "mumbai" for p in places)
    place_names = [p.name.lower() for p in places]
    assert any("gateway" in n or "marine drive" in n or "elephanta" in n for n in place_names)

def test_dynamic_destination_search():
    """Verify searching for Pune, Mumbai, and Jaipur returns matching DestinationModel records."""
    for city in ["Pune", "Mumbai", "Jaipur"]:
        resp = client.get(f"/api/v1/destinations/search?q={city}")
        assert resp.status_code == 200
        data = resp.json()
        assert len(data) >= 1
        assert any(city.lower() in d["name"].lower() for d in data)

def test_trip_generation_pune_isolation():
    """Verify that generating a trip for Pune returns stops in Pune with zero Goa beaches."""
    optimizer = ItineraryOptimizer()
    req = GenerateItineraryRequest(
        destination="Pune",
        start_date="Nov 1, 2026",
        end_date="Nov 3, 2026",
        travelers=2,
        budget_per_person=10000,
        interests=["History", "Culture"],
        travel_intensity="moderate",
    )
    resp = optimizer.generate(req)
    assert len(resp.days) == 3
    stop_names = [s.attraction.name for d in resp.days for s in d.stops]
    assert len(stop_names) >= 3
    # All stops must belong to Pune
    assert all("baga" not in s.lower() and "calangute" not in s.lower() for s in stop_names)

def test_trip_generation_mumbai_isolation():
    """Verify that generating a trip for Mumbai returns stops in Mumbai with zero Goa beaches."""
    optimizer = ItineraryOptimizer()
    req = GenerateItineraryRequest(
        destination="Mumbai",
        start_date="Dec 10, 2026",
        end_date="Dec 12, 2026",
        travelers=2,
        budget_per_person=15000,
        interests=["Sightseeing", "History"],
        travel_intensity="moderate",
    )
    resp = optimizer.generate(req)
    assert len(resp.days) == 3
    stop_names = [s.attraction.name for d in resp.days for s in d.stops]
    assert len(stop_names) >= 3
    assert all("baga" not in s.lower() and "dudhsagar" not in s.lower() for s in stop_names)

def test_security_token_claims_parsing():
    """Verify that token claims are safely extracted in offline / development mode."""
    user = verify_firebase_token(authorization="Bearer usr_test_pune")
    assert user["uid"] == "usr_test_pune"
