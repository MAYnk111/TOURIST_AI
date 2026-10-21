from typing import List, Optional
from pydantic import BaseModel, Field

class DestinationModel(BaseModel):
    id: str
    name: str
    country: str = "India"
    state: str = ""
    description: str = ""
    image_url: str = ""
    rating: float = 4.5
    review_count: int = 1000
    tags: List[str] = Field(default_factory=list)
    is_trending: bool = False
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class AttractionModel(BaseModel):
    id: str
    name: str
    destination_id: str
    destination_name: str
    category: str
    description: str = ""
    image_url: str = ""
    photos: List[str] = Field(default_factory=list)
    rating: Optional[float] = None
    review_count: Optional[int] = None
    tags: List[str] = Field(default_factory=list)
    estimated_duration_hours: float = 2.0
    entry_fee_min: Optional[float] = None
    entry_fee_max: Optional[float] = None
    latitude: float = 0.0
    longitude: float = 0.0
    opening_hours: Optional[str] = None
    formatted_address: Optional[str] = None
    price_level: Optional[str] = None
    photo_attributions: List[str] = Field(default_factory=list)
    provider: str = "curated"
    is_live_data: bool = False
    is_saved: bool = False

    @property
    def formattedDuration(self) -> str:
        return f"{self.estimated_duration_hours:.1f} hrs"

    @property
    def formattedEntryFee(self) -> str:
        if self.entry_fee_min is None or self.entry_fee_max is None:
            return "Price not reported"
        if self.entry_fee_min == 0 and self.entry_fee_max == 0:
            return "Free"
        return f"₹{int(self.entry_fee_min)}-₹{int(self.entry_fee_max)}"

    @property
    def formattedOpeningHours(self) -> str:
        return self.opening_hours if self.opening_hours else "Opening hours not reported"

class CostEstimateRequest(BaseModel):
    destination: str = "Goa"
    days: int = Field(ge=1, le=30, default=3)
    travelers: int = Field(ge=1, le=20, default=2)
    travel_style: str = "balanced"  # budget, balanced, luxury
    user_budget: float = 15000.0
    budget_per_person: Optional[float] = None

class CostEstimateResponse(BaseModel):
    accommodation: float
    food_drinks: float
    transport: float
    activities: float
    miscellaneous: float
    total_estimated: float
    user_budget: float
    is_within_budget: bool
    cost_per_person: float = 0.0
    group_budget: float = 0.0
    budget_per_person: float = 0.0
    budget_difference: float = 0.0
    days: int = 3
    nights: int = 2
    travelers: int = 2
    model_basis: str = "ML Random Forest / Verified Category Pricing"
    is_experimental: bool = True
    known_fees_total: float = 0.0
    unknown_fees_count: int = 0
    calculation_assumptions: List[str] = Field(default_factory=list)

class RecommendationRequest(BaseModel):
    destination: Optional[str] = None
    duration_days: int = Field(ge=1, le=30, default=3)
    interests: List[str] = Field(default_factory=list)
    budget_category: str = "moderate"  # budget, moderate, luxury
    budget_per_person: float = 15000.0
    travelers_count: int = Field(ge=1, le=20, default=2)
    family_friendly: bool = False
    travel_intensity: str = "moderate"  # relaxed (2/day), moderate (3/day), intense (4+/day)
    daily_activity_count: Optional[int] = None
    accessibility_required: bool = False
    exclusions: List[str] = Field(default_factory=list)
    deterministic: bool = False
    top_k: int = 6
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class RecommendationItem(BaseModel):
    attraction: AttractionModel
    score: float
    source_id: str
    explanation: str
    match_factors: dict = Field(default_factory=dict)
    uncertainties: List[str] = Field(default_factory=list)

class RecommendationResponse(BaseModel):
    destination: str
    items: List[RecommendationItem]
    scoring_weights: dict = Field(default_factory=dict)
    total_candidates_analyzed: int

class GenerateItineraryRequest(BaseModel):
    destination: str
    start_date: str
    end_date: str
    travelers: int = Field(ge=1, le=20, default=2)
    budget_per_person: float = 15000.0
    interests: List[str] = Field(default_factory=lambda: ["Beaches", "Food"])
    travel_intensity: str = "moderate"  # relaxed, moderate, intense
    exclusions: List[str] = Field(default_factory=list)
    selected_attraction_ids: Optional[List[str]] = None
    family_friendly: bool = False
    accessibility_required: bool = False
    meal_breaks: bool = True
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class TimelineStopModel(BaseModel):
    id: str
    time: str
    attraction: AttractionModel
    notes: str
    duration_hours: float
    is_meal_break: bool = False

class ItineraryDayModel(BaseModel):
    day_number: int
    date: str
    stops: List[TimelineStopModel]
    day_route_distance_km: float = 0.0
    day_route_duration_minutes: float = 0.0

class ItineraryResponse(BaseModel):
    id: str
    title: str
    destination: str
    start_date: str
    end_date: str
    travelers_count: int
    budget_per_person: float
    total_budget: float
    interests: List[str]
    days: List[ItineraryDayModel]
    budget: CostEstimateResponse
    is_saved: bool = False
    constraint_warnings: List[str] = Field(default_factory=list)
    data_provenance: dict = Field(default_factory=dict)
    assumptions: List[str] = Field(default_factory=list)
    total_route_distance_km: float = 0.0
    total_route_duration_minutes: float = 0.0
    created_at: Optional[str] = None
    updated_at: Optional[str] = None
    user_id: Optional[str] = None

class ChatRequest(BaseModel):
    message: str
    history: List[dict] = Field(default_factory=list)
    destination: Optional[str] = None
    travelers: Optional[int] = None
    budget_per_person: Optional[float] = None
    interests: Optional[List[str]] = None
    dates: Optional[str] = None

class ChatResponse(BaseModel):
    reply: str
    attractions: Optional[List[AttractionModel]] = None
    cost_summary_text: Optional[str] = None
    show_view_itinerary: bool = False
    grounded_sources: List[str] = Field(default_factory=list)
