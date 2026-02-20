"""CloudOptima AI — FastAPI application entry point (SIMPLIFIED FOR POC)."""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core import get_settings
from app.core.database import init_db
# Only import routes that don't depend on Organization/CloudConnection/AIWorkload models
from app.api.routes import costs, recommendations

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialize database on startup."""
    if settings.app_env == "development":
        await init_db()
    yield


app = FastAPI(
    title="CloudOptima AI",
    description="The FinOps platform built for the AI era — multi-cloud cost intelligence, "
                "automated Well-Architected reviews, and AI workload optimization.",
    version="0.1.0-poc",
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS - Allow frontend from VM IP
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://52.179.209.239:3000", "*"],  # Allow all for POC
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routes - Only simplified routes without foreign key dependencies
# Commented out routes that depend on Organization/CloudConnection/AIWorkload:
# - auth (depends on Organization, User)
# - dashboard (depends on AIWorkload, Alert)
# - ai_costs (depends on AIWorkload)
# - connections (depends on CloudConnection)
# - focus_export (may depend on CloudConnection)

app.include_router(costs.router, prefix="/api/v1/costs", tags=["Cost Data"])
app.include_router(recommendations.router, prefix="/api/v1/recommendations", tags=["Recommendations"])


@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "cloudoptima-ai-poc", "version": "0.1.0-poc"}


@app.get("/")
async def root():
    return {
        "message": "CloudOptima AI - POC Version",
        "status": "running",
        "available_endpoints": [
            "/health",
            "/docs",
            "/api/v1/costs",
            "/api/v1/recommendations"
        ],
        "note": "This is a simplified POC version with core cost and recommendation features only."
    }
