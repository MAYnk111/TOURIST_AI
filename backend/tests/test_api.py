from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health():
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "ml_cost_model" in data
    assert "provider_status" in data

def test_providers_status():
    response = client.get("/api/v1/providers/status")
    assert response.status_code == 200
    data = response.json()
    assert "active_provider" in data
    assert "attribution" in data

def test_destinations():
    response = client.get("/api/v1/destinations")
    assert response.status_code == 200
    data = response.json()
    assert len(data) >= 3
    assert any(d["id"] == "goa" for d in data)

def test_get_attractions():
    response = client.get("/api/v1/destinations/goa/attractions")
    assert response.status_code == 200
    data = response.json()
    assert len(data) >= 5
    assert any(a["id"] == "baga_beach" for a in data)

def test_get_attraction_details():
    response = client.get("/api/v1/attractions/baga_beach")
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Baga Beach"
    assert data["category"] == "Beaches"
    assert data["rating"] == 4.5

def test_estimate_cost():
    response = client.post(
        "/api/v1/trips/estimate-cost",
        json={
            "destination": "Goa",
            "days": 3,
            "travelers": 2,
            "travel_style": "balanced",
            "user_budget": 15000.0,
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["total_estimated"] > 0
    assert data["accommodation"] > 0

def test_generate_itinerary():
    response = client.post(
        "/api/v1/trips/generate-itinerary",
        json={
            "destination": "Goa, India",
            "start_date": "Jan 10",
            "end_date": "Jan 12",
            "travelers": 2,
            "budget_per_person": 15000.0,
            "interests": ["Beaches", "Food"],
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert len(data["days"]) == 3
    assert "budget" in data

def test_assistant_chat():
    response = client.post(
        "/api/v1/assistant/chat",
        json={
            "message": "Plan a 3-day Goa trip for 2 people under ₹15,000",
            "history": [],
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert "reply" in data
    assert len(data["reply"]) > 0
    assert data["attractions"] is not None

def test_save_and_get_trips():
    trip_payload = {
        "id": "trip_test_01",
        "title": "Audit Test Goa Trip",
        "destination": "Goa, India",
    }
    post_res = client.post("/api/v1/trips", json=trip_payload)
    assert post_res.status_code == 200
    assert post_res.json()["status"] == "saved"

    get_res = client.get("/api/v1/trips")
    assert get_res.status_code == 200
    assert any(t["id"] == "trip_test_01" for t in get_res.json())
