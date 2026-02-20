"""API router combining all endpoint modules."""

from fastapi import APIRouter

from app.api.endpoints import (
    costs,
    budgets,
    recommendations,
    azure,
    health,
    notifications,
    advisor,
    metrics,
)

api_router = APIRouter()

# Include all endpoint routers
api_router.include_router(health.router, tags=["Health"])
api_router.include_router(azure.router, prefix="/azure", tags=["Azure"])
api_router.include_router(costs.router, prefix="/costs", tags=["Costs"])
api_router.include_router(budgets.router, prefix="/budgets", tags=["Budgets"])
api_router.include_router(recommendations.router, prefix="/recommendations", tags=["Recommendations"])
api_router.include_router(notifications.router, prefix="/notifications", tags=["Notifications"])
api_router.include_router(advisor.router, prefix="/advisor", tags=["Azure Advisor"])
api_router.include_router(metrics.router, prefix="/metrics", tags=["Azure Monitor Metrics"])
