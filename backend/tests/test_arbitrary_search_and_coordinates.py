import pytest
from app.models.schemas import DestinationModel, AttractionModel, GenerateItineraryRequest, RecommendationRequest
from app.providers.osm_provider import OsmOverpassProvider
from app.providers.hybrid_provider import destination_provider
from app.providers.mock_verified_provider import DESTINATIONS_DATA, ATTRACTIONS_DATA
from app.ml.itinerary_optimizer import itinerary_optimizer
from app.ml.recommendation import recommender

def test_existing_destinations_preserved_with_coordinates():
    dest_names = [d.name.lower() for d in DESTINATIONS_DATA]
    assert "goa" in dest_names
    assert "pune" in dest_names
    assert "mumbai" in dest_names

    goa = next(d for d in DESTINATIONS_DATA if d.id == "goa")
    assert goa.latitude is not None and goa.longitude is not None
    assert 15.0 <= goa.latitude <= 16.0
    assert 73.0 <= goa.longitude <= 75.0

    pune = next(d for d in DESTINATIONS_DATA if d.id == "pune")
    assert pune.latitude is not None and pune.longitude is not None
    assert 18.0 <= pune.latitude <= 19.0

    mumbai = next(d for d in DESTINATIONS_DATA if d.id == "mumbai")
    assert mumbai.latitude is not None and mumbai.longitude is not None
    assert 18.5 <= mumbai.latitude <= 19.5

def test_arbitrary_destination_search():
    results = destination_provider.search_destinations("Nashik")
    assert len(results) > 0
    top = results[0]
    assert "nashik" in top.name.lower() or "nashik" in top.id.lower()
    assert top.latitude is not None and top.longitude is not None
    assert 19.0 <= top.latitude <= 21.0
    assert 73.0 <= top.longitude <= 75.0

def test_arbitrary_destination_attractions_isolation():
    # Calling attractions for Nashik must NOT return Goa or Mumbai places
    nashik_places = destination_provider.get_attractions(
        destination_id="nashik",
        lat=20.0112,
        lon=73.7902,
    )
    assert len(nashik_places) > 0
    for p in nashik_places:
        assert p.destination_id.lower() == "nashik"
        assert "goa" not in p.name.lower()
        assert "mumbai" not in p.name.lower()
        assert 19.0 <= p.latitude <= 21.0
        assert 73.0 <= p.longitude <= 75.0

def test_arbitrary_destination_itinerary_generation():
    req = GenerateItineraryRequest(
        destination="Nashik, Maharashtra",
        start_date="Nov 1, 2026",
        end_date="Nov 3, 2026",
        travelers=2,
        budget_per_person=15000.0,
        interests=["History", "Nature"],
        latitude=20.0112,
        longitude=73.7902,
    )
    itinerary = itinerary_optimizer.generate(req)
    assert itinerary.destination == "Nashik, Maharashtra"
    assert len(itinerary.days) >= 2
    all_stops = [s for d in itinerary.days for s in d.stops]
    assert len(all_stops) > 0
    for s in all_stops:
        assert s.attraction.destination_id.lower() == "nashik"
        assert "baga" not in s.attraction.name.lower()
        assert "shaniwar" not in s.attraction.name.lower()

def test_personalized_recommendations_with_coordinates():
    req = RecommendationRequest(
        destination="Nashik",
        duration_days=3,
        interests=["History"],
        latitude=20.0112,
        longitude=73.7902,
    )
    rec_resp = recommender.recommend_personalized(req)
    assert rec_resp.destination == "Nashik"
    assert len(rec_resp.items) > 0
    for item in rec_resp.items:
        assert item.attraction.destination_id.lower() == "nashik"
