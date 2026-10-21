import pytest
from app.ml.recommendation import ContentBasedRecommender
from app.ml.cost_estimation import TravelCostEstimationService
from app.ml.itinerary_optimizer import ItineraryOptimizer, haversine_distance, estimate_road_travel_time_hours
from app.models.schemas import GenerateItineraryRequest, AttractionModel

def test_recommendation_ranking():
    rec = ContentBasedRecommender()
    results = rec.recommend(interests=["Beaches", "Water Sports"], top_k=3)
    assert len(results) > 0
    top_attraction, score = results[0]
    assert score > 0
    assert "beach" in top_attraction.name.lower() or "beach" in top_attraction.category.lower()

def test_recommendation_sensitivity_to_interests():
    """Deterministic test: changing user interests must change the ranked order."""
    rec = ContentBasedRecommender()
    beach_recs = rec.recommend(interests=["Beaches"], top_k=3)
    history_recs = rec.recommend(interests=["History"], top_k=3)
    food_recs = rec.recommend(interests=["Food"], top_k=3)

    assert beach_recs[0][0].id != history_recs[0][0].id
    assert "beach" in beach_recs[0][0].name.lower() or "beach" in beach_recs[0][0].category.lower()
    assert "fort" in history_recs[0][0].name.lower() or "history" in history_recs[0][0].category.lower()
    assert "britto" in food_recs[0][0].name.lower() or "food" in food_recs[0][0].category.lower()

def test_recommendation_sensitivity_to_budget():
    """Deterministic test: strict budget penalizes expensive attractions and promotes free ones."""
    rec = ContentBasedRecommender()
    # Luxury budget
    rich_recs = rec.recommend(interests=["Adventure"], user_budget_per_person=50000.0, top_k=5)
    # Extremely tight budget (₹200)
    poor_recs = rec.recommend(interests=["Adventure"], user_budget_per_person=200.0, top_k=5)

    # Expensive paid attractions should have lower rank/score on tiny budget
    paid_attraction = next((a for a, _ in rich_recs if a.entry_fee_max >= 500), None)
    if paid_attraction:
        poor_rank = [a.id for a, _ in poor_recs].index(paid_attraction.id) if paid_attraction.id in [a.id for a, _ in poor_recs] else 99
        rich_rank = [a.id for a, _ in rich_recs].index(paid_attraction.id)
        assert poor_rank >= rich_rank

def test_recommendation_deduplication():
    dup_attraction = AttractionModel(
        id="baga_beach",
        name="Baga Beach Duplicate",
        destination_id="goa",
        destination_name="Goa",
        category="Beaches",
        description="Duplicate record",
        image_url="",
        rating=4.5,
        review_count=100,
        estimated_duration_hours=2.0,
        entry_fee_min=0,
        entry_fee_max=0,
    )
    rec = ContentBasedRecommender([dup_attraction, dup_attraction])
    assert len(rec.attractions) == 1

def test_recommendation_baseline_comparison():
    rec = ContentBasedRecommender()
    baseline = rec.baseline_popularity_recommend(top_k=3)
    assert len(baseline) == 3
    assert baseline[0][1] >= baseline[1][1]

def test_cost_estimation_metrics():
    service = TravelCostEstimationService()
    assert "random_forest" in service.metrics

    rf_mae = service.metrics["random_forest"]["MAE"]
    assert rf_mae > 0
    assert service.metrics["random_forest"]["R2"] > 0.90

    res = service.estimate_cost(
        destination="Goa",
        days=3,
        travelers=2,
        user_budget=15000.0,
    )
    assert res.total_estimated > 0
    assert res.accommodation > 0
    assert res.food_drinks > 0
    assert res.transport > 0
    assert res.activities > 0
    assert res.miscellaneous >= 0

def test_distance_and_transit_calculation():
    # Baga Beach (15.5553, 73.7517) to Fort Aguada (15.4920, 73.7737)
    dist = haversine_distance(15.5553, 73.7517, 15.4920, 73.7737)
    assert 6.0 <= dist <= 10.0  # Approx 7.4 km straight line
    travel_time = estimate_road_travel_time_hours(dist)
    assert 0.25 <= travel_time <= 0.6  # Approx 20-30 mins road time

def test_itinerary_optimizer_clustering_and_duration():
    optimizer = ItineraryOptimizer()
    req = GenerateItineraryRequest(
        destination="Goa, India",
        start_date="Jan 10",
        end_date="Jan 12",
        travelers=2,
        budget_per_person=15000.0,
        interests=["Beaches", "Food"],
    )
    itinerary = optimizer.generate(req)
    assert len(itinerary.days) == 3
    assert len(itinerary.days[0].stops) > 0
    assert itinerary.budget.total_estimated > 0
