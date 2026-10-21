import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .core.config import settings
from .api.v1.endpoints import router as api_v1_router

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ai_tourist")

app = FastAPI(
    title=settings.PROJECT_NAME,
    version="1.0.0",
    description="Production-minded AI-powered travel backend with Scikit-learn, Hugging Face LLM, and Firestore.",
    docs_url="/docs",
    redoc_url="/redoc",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_v1_router, prefix=settings.API_V1_STR)

@app.get("/")
def root():
    return {
        "message": "Welcome to AI Tourist API. See /docs for interactive OpenAPI documentation.",
        "version": "1.0.0",
    }
