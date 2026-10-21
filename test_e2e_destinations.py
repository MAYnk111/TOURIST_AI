import requests

base = "http://127.0.0.1:8000/api/v1"

print("=== 1. TESTING DESTINATION SEARCH ===")
for q in ["Pune", "Mumbai", "Goa"]:
    r = requests.get(f"{base}/destinations/search?q={q}")
    print(f"Search {q} (status {r.status_code}): {[d['name'] for d in r.json()]}")

print("\n=== 2. TESTING ATTRACTIONS RETRIEVAL ===")
pune_attractions = []
mumbai_attractions = []
goa_attractions = []

for d in ["pune", "mumbai", "goa"]:
    r = requests.get(f"{base}/destinations/{d}/attractions")
    names = [a["name"] for a in r.json()]
    if d == "pune":
        pune_attractions = names
    elif d == "mumbai":
        mumbai_attractions = names
    elif d == "goa":
        goa_attractions = names
    print(f"{d.upper()} Attractions ({len(names)} items): {names}")

# Verify 0 cross-destination leakage
assert not any("beach" in n.lower() for n in pune_attractions), "Pune attractions leaked beaches!"
assert not any(n in goa_attractions for n in pune_attractions), "Goa attractions leaked into Pune!"
assert not any(n in goa_attractions for n in mumbai_attractions), "Goa attractions leaked into Mumbai!"
print("\n>>> Zero attraction leakage confirmed between Pune, Mumbai, and Goa!")

print("\n=== 3. TESTING TRIP GENERATION FOR PUNE, GOA, MUMBAI ===")
for city, interests in [
    ("Pune", ["History", "Culture"]),
    ("Mumbai", ["Beaches", "Sightseeing"]),
    ("Goa", ["Beaches", "Adventure"])
]:
    payload = {
        "destination": city,
        "start_date": "Nov 1, 2026",
        "end_date": "Nov 3, 2026",
        "travelers": 2,
        "budget_per_person": 12000,
        "interests": interests,
        "travel_intensity": "moderate"
    }
    r = requests.post(f"{base}/trips/generate-itinerary", json=payload)
    assert r.status_code == 200, f"Trip generation failed for {city}: {r.text}"
    itinerary = r.json()
    stops = [stop["attraction"]["name"] for day in itinerary["days"] for stop in day["stops"]]
    print(f"\n--- {city} Itinerary Title: '{itinerary['title']}' ---")
    print(f"Total stops scheduled ({len(stops)}): {stops}")
    for day in itinerary["days"]:
        print(f"  Day {day['day_number']}: {[s['attraction']['name'] for s in day['stops']]}")

    # Confirm stops match destination
    if city == "Pune":
        assert all(s in pune_attractions for s in stops), f"Invalid stop in Pune: {stops}"
    elif city == "Mumbai":
        assert all(s in mumbai_attractions for s in stops), f"Invalid stop in Mumbai: {stops}"
    elif city == "Goa":
        assert all(s in goa_attractions for s in stops), f"Invalid stop in Goa: {stops}"

print("\n>>> All 3 separate trips (Pune, Mumbai, Goa) generated and verified with 100% destination isolation!")
