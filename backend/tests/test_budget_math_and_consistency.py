import pytest
from app.ml.cost_estimation import cost_service
from app.ml.itinerary_optimizer import itinerary_optimizer
from app.models.schemas import CostEstimateResponse, GenerateItineraryRequest

def test_pune_budget_scenarios_2k_5k_15k():
    """
    Verify the 3 Pune trip planning constraints:
    - 4 days, 4 travelers (group budget = bpp * 4)
    - ₹2,000/person: Economical plan, fits within ₹8,000 group budget.
    - ₹5,000/person: Moderate plan, fits within ₹20,000 group budget.
    - ₹15,000/person: Premium/luxury plan, fits within ₹60,000 group budget.
    - Exact category sum equality for each.
    - Unit consistency: 4 days = 3 nights accommodation.
    """
    for bpp in [2000.0, 5000.0, 15000.0]:
        resp = cost_service.estimate_cost(
            destination="Pune",
            days=4,
            travelers=4,
            budget_per_person=bpp,
        )
        assert resp.travelers == 4
        assert resp.days == 4
        assert resp.nights == 3
        assert resp.budget_per_person == bpp
        assert resp.group_budget == bpp * 4
        assert resp.cost_per_person == round(resp.total_estimated / 4, 2)
        assert resp.is_within_budget is True, f"Budget ₹{bpp}/person should fit within group budget ₹{bpp*4}!"
        assert resp.total_estimated <= resp.group_budget
        assert resp.budget_difference == round(resp.group_budget - resp.total_estimated, 2)

        # Exact category breakdown sum
        cat_sum = round(
            resp.accommodation +
            resp.food_drinks +
            resp.transport +
            resp.activities +
            resp.miscellaneous,
            0
        )
        assert cat_sum == resp.total_estimated, f"Category sum ({cat_sum}) != total ({resp.total_estimated})"

def test_impossible_budget_flags_over_budget_with_shortfall():
    """
    When an impossibly low budget is entered (e.g. ₹1,000 total for 4 people / 4 days),
    the system must NOT artificially clamp to ₹1,000 and claim it's within budget.
    It must flag OVER BUDGET with is_within_budget=False and report the true shortfall.
    """
    resp = cost_service.estimate_cost(
        destination="Pune",
        days=4,
        travelers=4,
        user_budget=1000.0,
    )
    assert resp.travelers == 4
    assert resp.days == 4
    assert resp.nights == 3
    assert resp.group_budget == 1000.0
    assert resp.is_within_budget is False, "₹1,000 total cannot realistically cover 4 people for 4 days!"
    assert resp.total_estimated >= 7000.0
    assert resp.budget_difference == round(resp.total_estimated - 1000.0, 2)
    assert resp.total_estimated == round(
        resp.accommodation + resp.food_drinks + resp.transport + resp.activities + resp.miscellaneous, 0
    )

def test_itinerary_generation_changes_with_budget():
    """
    Changing budget from ₹2,000 to ₹15,000 must actively drive itinerary optimization:
    - ₹2,000/person prefers free/low-cost sights and affordable meal breaks.
    - ₹15,000/person incorporates richer attractions and fine dining.
    """
    req_2k = GenerateItineraryRequest(
        destination="Pune, Maharashtra",
        start_date="Oct 28",
        end_date="Oct 31",
        travelers=4,
        budget_per_person=2000.0,
        interests=["History", "Nature"],
    )
    itin_2k = itinerary_optimizer.generate(req_2k)
    assert len(itin_2k.days) == 4
    assert itin_2k.budget.total_estimated <= itin_2k.total_budget
    assert itin_2k.budget.is_within_budget is True

    req_15k = GenerateItineraryRequest(
        destination="Pune, Maharashtra",
        start_date="Oct 28",
        end_date="Oct 31",
        travelers=4,
        budget_per_person=15000.0,
        interests=["History", "Nature"],
    )
    itin_15k = itinerary_optimizer.generate(req_15k)
    assert len(itin_15k.days) == 4
    assert itin_15k.budget.total_estimated <= itin_15k.total_budget
    assert itin_15k.budget.is_within_budget is True

    # Higher budget allows higher quality accommodations & activities
    assert itin_15k.budget.total_estimated > itin_2k.budget.total_estimated
    assert itin_15k.budget.accommodation > itin_2k.budget.accommodation

def test_goa_and_jaipur_budget_scenarios():
    """Verify budget optimization works across multiple destinations (Goa, Jaipur)."""
    # Goa 3 days, 2 travelers with ₹5,000/person
    resp_goa = cost_service.estimate_cost(
        destination="Goa",
        days=3,
        travelers=2,
        budget_per_person=5000.0,
    )
    assert resp_goa.days == 3
    assert resp_goa.nights == 2
    assert resp_goa.group_budget == 10000.0
    assert resp_goa.total_estimated <= 10000.0
    assert resp_goa.is_within_budget is True

    # Jaipur 3 days, 2 travelers with ₹15,000/person
    resp_jaipur = cost_service.estimate_cost(
        destination="Jaipur",
        days=3,
        travelers=2,
        budget_per_person=15000.0,
    )
    assert resp_jaipur.days == 3
    assert resp_jaipur.nights == 2
    assert resp_jaipur.group_budget == 30000.0
    assert resp_jaipur.total_estimated <= 30000.0
    assert resp_jaipur.is_within_budget is True

def test_one_traveler_vs_multiple_travelers():
    """
    Verify costs scale logically with travelers.
    Single traveler has 1 person, 4 travelers benefit from room/cab sharing.
    """
    resp_solo = cost_service.estimate_cost("Pune", days=3, travelers=1, user_budget=15000.0)
    resp_group = cost_service.estimate_cost("Pune", days=3, travelers=4, user_budget=60000.0)

    assert resp_solo.travelers == 1
    assert resp_group.travelers == 4
    assert resp_solo.nights == 2
    assert resp_group.nights == 2
    assert resp_group.total_estimated > resp_solo.total_estimated
    assert resp_group.cost_per_person < resp_solo.total_estimated

def test_four_calendar_dates_and_three_accommodation_nights():
    """
    Oct 28–31 represents 4 calendar dates and 3 accommodation nights.
    """
    resp = cost_service.estimate_cost("Pune", days=4, travelers=2)
    assert resp.days == 4
    assert resp.nights == 3

def test_costs_that_exactly_equal_the_budget():
    """
    When total estimated cost equals budget exactly, is_within_budget must be True.
    """
    resp = cost_service.estimate_cost("Goa", days=3, travelers=2, travel_style="balanced", user_budget=14200.0)
    assert resp.total_estimated == 14200.0
    assert resp.user_budget == 14200.0
    assert resp.is_within_budget is True
    assert resp.budget_difference == 0.0

def test_category_total_consistency():
    """
    Category components (accommodation + food + transport + activities + misc)
    must add up EXACTLY to total_estimated.
    """
    for days in [1, 2, 4, 7]:
        for travelers in [1, 2, 5]:
            resp = cost_service.estimate_cost("Pune", days=days, travelers=travelers)
            category_sum = round(
                resp.accommodation +
                resp.food_drinks +
                resp.transport +
                resp.activities +
                resp.miscellaneous,
                0
            )
            assert category_sum == resp.total_estimated
