import numpy as np
from typing import List, Dict, Any, Tuple, Optional
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from ..models.schemas import (
    AttractionModel,
    RecommendationRequest,
    RecommendationResponse,
    RecommendationItem,
)
from ..providers.mock_verified_provider import ATTRACTIONS_DATA

class ContentBasedRecommender:
    def __init__(self, attractions: Optional[List[AttractionModel]] = None):
        raw_attractions = attractions if attractions is not None else ATTRACTIONS_DATA
        # Deduplicate attractions by ID
        seen_ids = set()
        self.attractions: List[AttractionModel] = []
        for a in raw_attractions:
            if a.id not in seen_ids:
                seen_ids.add(a.id)
                self.attractions.append(a)

        self.vectorizer = TfidfVectorizer(stop_words='english', token_pattern=r'(?u)\b\w+\b')
        self._corpus = [
            f"{a.name} {a.category} {' '.join(a.tags)} {a.description}"
            for a in self.attractions
        ]
        if self._corpus:
            self.tfidf_matrix = self.vectorizer.fit_transform(self._corpus)
        else:
            self.tfidf_matrix = None

    def recommend(
        self,
        interests: List[str],
        user_budget_per_person: float = 15000.0,
        max_duration_hours: float = 12.0,
        top_k: int = 5,
    ) -> List[Tuple[AttractionModel, float]]:
        """
        Multi-factor transparent content ranking:
        1. TF-IDF Interest / Tag Similarity (weight 0.40)
        2. Category exact match (weight 0.25)
        3. Quality Rating Score (weight 0.20)
        4. Budget Compatibility Score (weight 0.15)
        """
        if not self.attractions:
            return []

        cleaned_interests = [i.strip() for i in interests if i and i.strip()]
        if not cleaned_interests:
            query = "tourist attraction beach nature history food adventure"
        else:
            query = " ".join(cleaned_interests)

        query_vec = self.vectorizer.transform([query])
        text_sims = cosine_similarity(query_vec, self.tfidf_matrix)[0]

        scored: List[Tuple[AttractionModel, float]] = []

        for i, a in enumerate(self.attractions):
            sim_score = float(text_sims[i])

            # Category & Tag semantic match bonus (primary category match is heavily prioritized)
            cat_match = 0.1
            for item in cleaned_interests:
                item_lower = item.lower()
                if item_lower in a.category.lower():
                    cat_match = max(cat_match, 1.25)
                elif any(item_lower in t.lower() for t in a.tags):
                    cat_match = max(cat_match, 0.40)
                elif item_lower in a.description.lower():
                    cat_match = max(cat_match, 0.20)

            # Rating score normalized safely in [0.0 .. 1.0]
            # Unrated places from open data receive neutral 0.5 score without penalty
            if a.rating is not None and a.rating > 0:
                rating_score = max(0.0, min(1.0, (a.rating - 3.0) / 2.0))
            else:
                rating_score = 0.5

            # Budget compatibility score
            if a.entry_fee_max is None:
                budget_score = 0.8  # Neutral when fee is not reported in open data
            elif a.entry_fee_max == 0:
                budget_score = 1.0
            elif a.entry_fee_max <= (user_budget_per_person * 0.05):
                budget_score = 0.9
            elif a.entry_fee_max <= (user_budget_per_person * 0.15):
                budget_score = 0.6
            else:
                budget_score = 0.2

            # Duration constraint filter
            if a.estimated_duration_hours > max_duration_hours:
                continue

            final_score = (
                0.40 * sim_score +
                0.25 * cat_match +
                0.20 * rating_score +
                0.15 * budget_score
            )
            scored.append((a, round(final_score, 4)))

        scored.sort(key=lambda x: x[1], reverse=True)
        return scored[:top_k]

    def baseline_popularity_recommend(self, top_k: int = 5) -> List[Tuple[AttractionModel, float]]:
        """
        Unpersonalized baseline: rating * log10(review count)
        """
        scored = []
        for a in self.attractions:
            score = (a.rating or 4.0) * np.log10(max(10, a.review_count or 100))
            scored.append((a, round(float(score), 4)))
        scored.sort(key=lambda x: x[1], reverse=True)
        return scored[:top_k]

    def recommend_personalized(
        self,
        req: RecommendationRequest,
        candidates: Optional[List[AttractionModel]] = None,
        weights: Optional[Dict[str, float]] = None,
    ) -> RecommendationResponse:
        """
        Stage 5: Personalized Trip Intelligence Ranking
        Multi-criteria normalized scoring with configurable weights, explicit uncertainty
        disclosures, exclusion filtering, and transparent explanations.
        """
        if weights:
            w = weights
        elif req.budget_per_person <= 3000:
            # Economical budget: heavily prioritize budget suitability
            w = {
                "semantic": 0.25,
                "category": 0.20,
                "budget": 0.35,
                "intensity": 0.10,
                "family": 0.10,
            }
        else:
            w = {
                "semantic": 0.35,
                "category": 0.25,
                "budget": 0.20,
                "intensity": 0.10,
                "family": 0.10,
            }

        # Select candidate attraction pool strictly for the requested destination
        if candidates is not None:
            pool = candidates
        elif req.destination:
            from ..providers.hybrid_provider import destination_provider
            pool = destination_provider.get_attractions(
                req.destination,
                lat=req.latitude,
                lon=req.longitude,
            )
        else:
            pool = self.attractions

        # Exclusion filter
        exclusions_lower = [e.lower().strip() for e in req.exclusions if e.strip()]
        eligible: List[AttractionModel] = []
        seen_ids = set()
        for a in pool:
            if a.id in seen_ids:
                continue
            if a.id.lower() in exclusions_lower or a.name.lower() in exclusions_lower:
                continue
            seen_ids.add(a.id)
            eligible.append(a)

        if not eligible:
            return RecommendationResponse(
                destination=req.destination or "Unspecified",
                items=[],
                scoring_weights=w,
                total_candidates_analyzed=0,
            )

        # 1. Semantic TF-IDF Vectorization
        cleaned_interests = [i.strip() for i in req.interests if i and i.strip()]
        query_text = " ".join(cleaned_interests) if cleaned_interests else "sightseeing culture leisure travel"
        if req.destination:
            query_text += f" {req.destination}"

        corpus = [f"{a.name} {a.category} {' '.join(a.tags)} {a.description}" for a in eligible]
        temp_vectorizer = TfidfVectorizer(stop_words='english', token_pattern=r'(?u)\b\w+\b')
        tfidf_mat = temp_vectorizer.fit_transform(corpus)
        query_vec = temp_vectorizer.transform([query_text])
        semantic_sims = cosine_similarity(query_vec, tfidf_mat)[0]

        items: List[RecommendationItem] = []

        for i, a in enumerate(eligible):
            s_semantic = max(0.0, min(1.0, float(semantic_sims[i])))

            # 2. Category & Tag Match
            matched_interest_names = []
            s_category = 0.1
            for interest in cleaned_interests:
                int_l = interest.lower()
                if int_l in a.category.lower():
                    s_category = max(s_category, 1.0)
                    matched_interest_names.append(interest)
                elif any(int_l in t.lower() for t in a.tags):
                    s_category = max(s_category, 0.95)
                    matched_interest_names.append(interest)
                elif int_l in a.description.lower():
                    s_category = max(s_category, 0.70)
                    matched_interest_names.append(interest)

            # 3. Budget Suitability
            uncertainties: List[str] = []
            if a.entry_fee_max is None:
                s_budget = 0.8  # Disclosed neutral
                uncertainties.append("Entry fee not reported in open data catalog")
                budget_desc = "entry fee is unstated in open data"
            elif a.entry_fee_max == 0:
                s_budget = 1.0
                budget_desc = "free entry fits your budget"
            elif a.entry_fee_max <= (req.budget_per_person * 0.05):
                s_budget = 0.95
                budget_desc = f"affordable entry (₹{int(a.entry_fee_max)}) fits your budget"
            elif a.entry_fee_max <= (req.budget_per_person * 0.15):
                s_budget = 0.65
                budget_desc = f"moderate entry (₹{int(a.entry_fee_max)}) within budget limits"
            else:
                s_budget = 0.30
                budget_desc = f"higher entry fee (₹{int(a.entry_fee_max)}) relative to budget"

            # 4. Travel Intensity Compatibility
            intensity = req.travel_intensity.lower()
            if intensity == "relaxed":
                # Prefers visits <= 2.0 hrs
                if a.estimated_duration_hours <= 2.0:
                    s_intensity = 1.0
                    int_desc = "ideal for a relaxed travel pace"
                elif a.estimated_duration_hours <= 3.0:
                    s_intensity = 0.7
                    int_desc = "moderate duration for relaxed pace"
                else:
                    s_intensity = 0.35
                    int_desc = "longer duration requiring active time"
            elif intensity == "intense":
                # Rewards substantive attractions (2.5 - 5 hrs)
                if a.estimated_duration_hours >= 2.5:
                    s_intensity = 1.0
                    int_desc = "substantial activity for high-intensity itinerary"
                else:
                    s_intensity = 0.75
                    int_desc = "quick stop suited for packed days"
            else:  # moderate
                if 1.5 <= a.estimated_duration_hours <= 3.0:
                    s_intensity = 1.0
                    int_desc = "balanced visit duration"
                else:
                    s_intensity = 0.8
                    int_desc = "compatible with moderate pacing"

            # 5. Family-Friendly Compatibility
            if req.family_friendly:
                is_night = a.category == "Nightlife" or "night" in a.name.lower() or any("night" in t.lower() for t in a.tags)
                is_extreme = "trek" in a.description.lower() or "safari" in a.description.lower()
                if is_night:
                    s_family = 0.1
                    family_desc = "primarily nightlife-focused (less suited for families)"
                elif is_extreme:
                    s_family = 0.5
                    family_desc = "involves rugged outdoor activity"
                else:
                    s_family = 1.0
                    family_desc = "family-friendly accessible attraction"
            else:
                s_family = 0.5
                family_desc = "general attraction"

            # Check accessibility constraint
            if req.accessibility_required:
                uncertainties.append("Wheelchair accessibility is unconfirmed in open data records")

            if a.opening_hours is None:
                uncertainties.append("Opening hours are unconfirmed in open data records")

            # Final Combined Weighted Score
            total_score = (
                w["semantic"] * s_semantic +
                w["category"] * s_category +
                w["budget"] * s_budget +
                w["intensity"] * s_intensity +
                w["family"] * s_family
            )
            total_score = round(max(0.0, min(1.0, total_score)), 4)

            # Generate natural explanation
            exp_parts = []
            if matched_interest_names:
                exp_parts.append(f"Matches your interest in {', '.join(set(matched_interest_names))}")
            else:
                exp_parts.append(f"Prominent {a.category} attraction")
            exp_parts.append(budget_desc)
            exp_parts.append(int_desc)
            explanation = ". ".join(exp_parts) + "."

            items.append(
                RecommendationItem(
                    attraction=a,
                    score=total_score,
                    source_id=a.id,
                    explanation=explanation,
                    match_factors={
                        "semantic": round(s_semantic, 3),
                        "category": round(s_category, 3),
                        "budget": round(s_budget, 3),
                        "intensity": round(s_intensity, 3),
                        "family": round(s_family, 3),
                    },
                    uncertainties=uncertainties,
                )
            )

        # Sort order (deterministic if requested, breaking score ties by attraction name)
        if req.deterministic:
            items.sort(key=lambda item: (-item.score, item.attraction.name))
        else:
            items.sort(key=lambda item: item.score, reverse=True)

        return RecommendationResponse(
            destination=req.destination or "Multi-Destination",
            items=items[:req.top_k],
            scoring_weights=w,
            total_candidates_analyzed=len(eligible),
        )

recommender = ContentBasedRecommender()
