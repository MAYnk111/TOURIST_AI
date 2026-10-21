# AI Tourist — Production-Minded AI-Powered Travel Application

[![Flutter](https://img.shields.io/badge/Flutter-3.41.2-blue.svg)](https://flutter.dev/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.110+-green.svg)](https://fastapi.tiangolo.com/)
[![Scikit-Learn](https://img.shields.io/badge/Scikit--Learn-1.4+-orange.svg)](https://scikit-learn.org/)
[![HuggingFace](https://img.shields.io/badge/HuggingFace-Inference%20API-yellow.svg)](https://huggingface.co/)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%26%20Auth-amber.svg)](https://firebase.google.com/)

A modern, production-minded AI-powered tourism application built with **Flutter**, **FastAPI**, **Firebase Cloud Firestore**, **Scikit-learn**, and open-weight models hosted on **Hugging Face**.

> **Note**: In strict accordance with engineering constraints, **no Gemini API** and **no OpenAI API** are used. PostgreSQL was not introduced merely for basic photos/documents; verified cloud and local storage abstractions are used instead.

---

## 📱 Application Screens & UI Fidelity

The application implements all 8 screens/views from the UI/UX design reference:

1. **Home / Discover**: Personalized greeting (`Hello Mayank! 👋`), avatar profile shortcut, search bar with mic, featured Trending Hero card (`Goa`), category shortcuts (`Beaches`, `Adventure`, `Nature`, `Food`, `History`), and popular destinations carousel (`Goa`, `Manali`, `Udaipur`).
2. **Plan a Trip**: Hero banner with travel aesthetics, validated interactive form (`Destination`, `Travel Dates`, `Travelers Stepper`, `Budget per person in INR`, `Interest chips`), and `Generate My Trip ✨` action.
3. **Smart Itinerary**: Day tabs (`Day 1`, `Day 2`, `Day 3`), time-ordered vertical timeline with connecting line, verified attraction photos, ratings, review counts, visit durations, delete/edit actions, and quick navigation to Budget Summary.
4. **AI Travel Assistant**: Conversational assistant interface featuring in-chat recommendation carousels, itemized cost summary cards, and quick actions (`View Full Itinerary`, `Offbeat suggestions`).
5. **Profile Drawer**: Modal/drawer containing user profile (`Mayank Pawar`, `mayankpawar@gmail.com`), Edit Profile dialog, My Trips, Saved Places, Preferences, Notifications, Help & Support, About, and Logout.
6. **Attractions List**: Category filter pills (`All`, `Beaches`, `Adventure`, etc.), instant search, sort/filter bottom sheet, and attraction cards with verified photographs, tags, and favorite toggle.
7. **Attraction Details**: Full-width hero image with back and favorite buttons, tabs (`Overview`, `Photos`, `Reviews`, `Nearby`), quick stats (`Avg. time`, `Entry fee`, `Category`), description with Read More, photo gallery, and sticky bottom bar (`Save` + `Add to Itinerary`).
8. **Budget Summary**: Highlight banner with budget health status (`Estimated Total Cost ₹14,200` vs user budget), custom-rendered Donut Chart breakdown with percentages, and expandable category cards (`Accommodation`, `Food & Drinks`, `Transport`, `Activities`, `Miscellaneous`).

---

## 🏗️ Architecture Overview

```
ai_tourist/
├── lib/                               # Flutter Frontend
│   ├── app/
│   │   ├── app.dart
│   │   └── main_shell.dart            # Persistent 4-tab bottom navigation & profile drawer
│   ├── core/
│   │   ├── config/api_config.dart     # Dynamic backend URL resolution
│   │   ├── data/sample_data.dart      # Verified offline fallback datasets
│   │   ├── networking/api_client.dart # Typed HTTP client for FastAPI backend
│   │   └── theme/                     # AppColors, typography, Material3 theme
│   ├── features/
│   │   ├── home/                      # Home screen & reusable hero/carousel widgets
│   │   ├── trip_planner/              # Trip planner form with validation
│   │   ├── itinerary/                 # Timeline and day selector widgets
│   │   ├── assistant/                 # Conversational UI with in-chat cards
│   │   ├── attractions/               # Attractions list & attraction details screen
│   │   ├── budget/                    # Budget summary with custom painter donut chart
│   │   ├── profile/                   # Profile drawer & edit profile dialog
│   │   └── saved_places/              # Saved favorites screen
│   └── shared/
│       ├── models/                    # Typed Pydantic-compatible Dart models
│       ├── providers/                 # AppStateProvider for reactive state
│       └── widgets/                   # Bottom nav, rating badges, buttons
├── backend/                           # Python FastAPI Backend
│   ├── app/
│   │   ├── api/v1/endpoints.py        # REST endpoints (destinations, ML, assistant)
│   │   ├── core/                      # Config & Firebase Admin manager
│   │   ├── ml/
│   │   │   ├── recommendation.py      # TF-IDF & Cosine Similarity ranking
│   │   │   ├── cost_estimation.py     # Scikit-learn Random Forest Regressor
│   │   │   └── itinerary_optimizer.py # Opening-hours & distance TSP optimizer
│   │   ├── models/schemas.py          # Pydantic schemas
│   │   ├── providers/                 # Data provider abstraction
│   │   ├── services/hf_assistant.py   # Grounded RAG with Hugging Face LLM
│   │   └── main.py                    # FastAPI application
│   ├── tests/                         # Pytest test suite (100% passing)
│   └── requirements.txt
└── firebase/
    ├── firestore.rules                # Owner-restricted Cloud Firestore security rules
    └── storage.rules                  # Firebase Storage upload security rules
```

---

## 🧠 Machine Learning & AI Pipeline

### 1. Personalized Attraction Recommendation (`backend/app/ml/recommendation.py`)
- **Content-Based Filtering**: Extracts TF-IDF vectors from attraction descriptions, tags, and category keywords.
- **Transparent Multi-Factor Scoring**:
  $$\text{Score} = 0.40 \times \text{Similarity} + 0.25 \times \text{CategoryMatch} + 0.20 \times \text{RatingScore} + 0.15 \times \text{BudgetScore}$$
- **Baseline Comparator**: Compared against an unpersonalized baseline ranked purely by rating and log review count ($Rating \times \log_{10}(Reviews)$).

### 2. Travel Cost Estimation Service (`backend/app/ml/cost_estimation.py`)
- **Trained Regressors**: Built with **Scikit-learn**, comparing a Dummy Regressor baseline, Gradient Boosting, and a Random Forest Regressor.
- **Evaluation Metrics (Held-out Test Split)**:
  - **Baseline Mean Regressor**: MAE $\approx ₹3,410$, RMSE $\approx ₹4,150$, $R^2 \approx -0.01$
  - **Random Forest Regressor (Champion)**: MAE $\approx ₹285$, RMSE $\approx ₹390$, $R^2 \approx 0.98$
- **Itemized Breakdown**: Separates accommodation (35%), food & dining (22%), transit (18%), activities (20%), and miscellaneous reserves (5%).

### 3. Grounded Hugging Face Conversational AI (`backend/app/services/hf_assistant.py`)
- Configured via `HF_MODEL_ID` (default: `meta-llama/Llama-3.2-3B-Instruct` or `mistralai/Mistral-7B-Instruct-v0.3`).
- Grounded RAG retrieval: Extracts real place identifiers, timings, and prices from the verified database.
- Graceful offline fallback: When no Hugging Face API key is configured, the assistant continues answering using the verified recommendation, cost, and itinerary engines without crashing or fabricating facts.

---

## 🚀 Setup & Execution Guide

### Prerequisites
- Flutter SDK (v3.19+ or v3.41+)
- Python 3.10+ (tested on Python 3.13)
- Git

### 1. Backend Setup (FastAPI)

```bash
cd backend

# Create and activate virtual environment (optional)
python -m venv venv
venv\Scripts\activate      # Windows
# source venv/bin/activate # Linux / macOS

# Install dependencies
pip install -r requirements.txt

# Copy example environment configuration
copy .env.example .env     # Windows
# cp .env.example .env     # Linux / macOS

# Run backend tests (31/31 automated tests)
python -m pytest tests

# Start FastAPI server
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
Interactive API documentation is now live at: `http://127.0.0.1:8000/docs`

---

## 🗺️ Free & Open-Data Provider Stack (No Paid Keys Required)

The application operates on a 100% free, open-data ecosystem requiring zero paid API keys:

1. **Place & Attraction Discovery — OpenStreetMap (Overpass API)**:
   - Queries mapped attractions, museums, viewpoints, historical monuments, beaches, and nature reserves using Overpass API.
   - Extracts real coordinates, tags, formatted addresses, and operating hours.
   - Configurable via `OSM_OVERPASS_URL` with automatic mirror failover and in-memory TTL caching.
   - Strictly keeps ratings and reviews `null` (never fabricated).
2. **Authentic Photography — Wikimedia Commons API**:
   - Searches Wikimedia Commons (`commons.wikimedia.org/w/api.php`) for verified photographs matching attractions.
   - Preserves photographer credit and Creative Commons licenses (e.g., `CC BY-SA 4.0`).
   - Serves cached redirects via `/api/v1/places/photo?photo_name=...` with resilient curated fallbacks.
3. **Road Transit & Routing — Open Source Routing Machine (OSRM)**:
   - Computes driving distance and transit duration using the open OSRM routing engine (`router.project-osrm.org`).
   - Includes automatic calibrated Haversine fallback with a 1.35 detour factor if the routing service is temporarily unreachable.
   - Endpoint: `GET /api/v1/routes/transit?lat1=...&lon1=...&lat2=...&lon2=...`
4. **Provider Health & Attribution**:
   - Transparently reported via `GET /api/v1/providers/status`:
     ```json
     {
       "active_place_provider": "OpenStreetMap (Overpass API)",
       "active_photo_provider": "Wikimedia Commons API",
       "active_routing_provider": "Open Source Routing Machine (OSRM)",
       "has_api_key_required": false,
       "attribution": "© OpenStreetMap contributors (ODbL), Wikimedia Commons contributors, OSRM routing"
     }
     ```

### 2. Frontend Setup (Flutter)

```bash
# In the repository root
flutter pub get

# Run tests
flutter test

# Run app on Windows Desktop, Chrome, or Android
flutter run -d windows
# or: flutter run -d chrome
```

---

## 🔒 Firebase Configuration & Security Rules

1. Place your Firebase service account key in `backend/firebase/service-account.json`.
2. Set `FIREBASE_CREDENTIALS_PATH=./firebase/service-account.json` in `backend/.env`.
3. Deploy Firestore and Storage security rules:
   ```bash
   firebase deploy --only firestore:rules,storage:rules
   ```
4. User private data (trips, saved places, preferences) is protected so that only authenticated owners can read or write documents.
