"""Azure Advisor integration endpoints."""

from typing import Optional

from fastapi import APIRouter, Depends, Query, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import APIKeyInfo, get_api_key_optional, require_scope, Scopes
from app.core.config import get_settings
from app.core.database import get_db
from app.core.exceptions import AzureCredentialsNotConfiguredError
from app.core.logging import get_logger
from app.services.azure_advisor import get_azure_advisor_client

router = APIRouter()
logger = get_logger(__name__)


def get_auth_dependency():
    """Get authentication dependency based on settings."""
    settings = get_settings()
    if settings.auth_enabled and settings.api_key:
        return require_scope(Scopes.RECOMMENDATIONS_READ)
    return get_api_key_optional


def get_write_auth():
    """Get write authentication dependency."""
    settings = get_settings()
    if settings.auth_enabled and settings.api_key:
        return require_scope(Scopes.RECOMMENDATIONS_WRITE)
    return get_api_key_optional


# =============================================================================
# Response Schemas
# =============================================================================

class AdvisorRecommendation(BaseModel):
    """Azure Advisor recommendation."""

    id: Optional[str] = Field(description="Recommendation ID")
    name: Optional[str] = Field(description="Recommendation name")
    category: str = Field(description="Category (cost_optimization, security, etc.)")
    impact: str = Field(description="Impact level (high, medium, low)")
    resource_id: Optional[str] = Field(description="Affected resource ID")
    resource_name: Optional[str] = Field(description="Affected resource name")
    resource_group: Optional[str] = Field(description="Resource group")
    resource_type: Optional[str] = Field(description="Resource type")
    short_description: Optional[str] = Field(description="Problem summary")
    description: Optional[str] = Field(description="Detailed description/solution")
    estimated_monthly_savings: Optional[float] = Field(description="Estimated monthly savings")
    estimated_annual_savings: Optional[float] = Field(description="Estimated annual savings")
    currency: str = Field(default="USD", description="Currency")
    last_updated: Optional[str] = Field(description="Last update timestamp")


class AdvisorRecommendationsResponse(BaseModel):
    """Response containing Advisor recommendations."""

    recommendations: list[AdvisorRecommendation] = Field(description="List of recommendations")
    total_count: int = Field(description="Total number of recommendations")
    total_potential_monthly_savings: float = Field(description="Sum of potential monthly savings")
    total_potential_annual_savings: float = Field(description="Sum of potential annual savings")
    by_impact: dict[str, int] = Field(description="Count by impact level")
    by_category: dict[str, int] = Field(description="Count by category")


class RefreshResponse(BaseModel):
    """Response from refresh operation."""

    success: bool = Field(description="Whether refresh was triggered")
    message: str = Field(description="Status message")


class SuppressRequest(BaseModel):
    """Request to suppress a recommendation."""

    recommendation_id: str = Field(description="Recommendation ID to suppress")
    resource_uri: str = Field(description="Resource URI for the recommendation")
    suppression_name: str = Field(
        default="cloudoptima-suppression",
        description="Name for the suppression",
    )
    duration_days: Optional[int] = Field(
        default=None,
        ge=1,
        le=365,
        description="Days to suppress (None = permanent)",
    )


# =============================================================================
# Endpoints
# =============================================================================

@router.get("/recommendations", response_model=AdvisorRecommendationsResponse)
async def get_advisor_recommendations(
    category: Optional[str] = Query(
        default=None,
        description="Filter by category (Cost, Security, Performance, HighAvailability, OperationalExcellence)",
    ),
    resource_group: Optional[str] = Query(
        default=None,
        description="Filter by resource group",
    ),
    min_savings: Optional[float] = Query(
        default=None,
        ge=0,
        description="Minimum monthly savings to include",
    ),
    _auth: Optional[APIKeyInfo] = Depends(get_auth_dependency()),
) -> AdvisorRecommendationsResponse:
    """
    Get recommendations from Azure Advisor.
    
    Returns cost optimization and other recommendations directly from Azure Advisor.
    These are Azure's built-in recommendations based on resource usage patterns.
    
    **Requires scope:** `recommendations:read` or `*`
    """
    settings = get_settings()
    
    if not settings.is_azure_configured:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Azure credentials not configured",
        )

    advisor_client = get_azure_advisor_client()

    try:
        # Determine categories to fetch
        categories = None
        if category:
            categories = [category]

        # Get recommendations
        raw_recs = await advisor_client.get_all_recommendations(categories=categories)

        # Filter by resource group if specified
        if resource_group:
            raw_recs = [
                r for r in raw_recs
                if r.get("resource_group", "").lower() == resource_group.lower()
            ]

        # Filter by minimum savings if specified
        if min_savings is not None:
            raw_recs = [
                r for r in raw_recs
                if (r.get("estimated_monthly_savings") or 0) >= min_savings
            ]

        # Calculate aggregates
        total_monthly = sum(r.get("estimated_monthly_savings") or 0 for r in raw_recs)
        total_annual = sum(r.get("estimated_annual_savings") or 0 for r in raw_recs)

        by_impact = {}
        by_category = {}
        for rec in raw_recs:
            impact = rec.get("impact", "medium")
            cat = rec.get("category", "unknown")
            by_impact[impact] = by_impact.get(impact, 0) + 1
            by_category[cat] = by_category.get(cat, 0) + 1

        # Convert to response models
        recommendations = [AdvisorRecommendation(**r) for r in raw_recs]

        logger.info(
            "Advisor recommendations retrieved",
            count=len(recommendations),
            total_savings=total_monthly,
        )

        return AdvisorRecommendationsResponse(
            recommendations=recommendations,
            total_count=len(recommendations),
            total_potential_monthly_savings=round(total_monthly, 2),
            total_potential_annual_savings=round(total_annual, 2),
            by_impact=by_impact,
            by_category=by_category,
        )

    except AzureCredentialsNotConfiguredError:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Azure credentials not configured",
        )
    except Exception as e:
        logger.error("Failed to fetch Advisor recommendations", error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch recommendations: {str(e)}",
        )


@router.get("/recommendations/cost", response_model=AdvisorRecommendationsResponse)
async def get_cost_recommendations(
    resource_group: Optional[str] = Query(default=None),
    min_savings: Optional[float] = Query(default=None, ge=0),
    _auth: Optional[APIKeyInfo] = Depends(get_auth_dependency()),
) -> AdvisorRecommendationsResponse:
    """
    Get cost optimization recommendations from Azure Advisor.
    
    Returns only cost-related recommendations for identifying savings opportunities.
    
    **Requires scope:** `recommendations:read` or `*`
    """
    settings = get_settings()
    
    if not settings.is_azure_configured:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Azure credentials not configured",
        )

    advisor_client = get_azure_advisor_client()

    try:
        raw_recs = await advisor_client.get_cost_recommendations(
            resource_group=resource_group,
        )

        # Filter by minimum savings
        if min_savings is not None:
            raw_recs = [
                r for r in raw_recs
                if (r.get("estimated_monthly_savings") or 0) >= min_savings
            ]

        # Sort by savings (highest first)
        raw_recs.sort(
            key=lambda r: r.get("estimated_monthly_savings") or 0,
            reverse=True,
        )

        total_monthly = sum(r.get("estimated_monthly_savings") or 0 for r in raw_recs)
        total_annual = sum(r.get("estimated_annual_savings") or 0 for r in raw_recs)

        by_impact = {}
        for rec in raw_recs:
            impact = rec.get("impact", "medium")
            by_impact[impact] = by_impact.get(impact, 0) + 1

        recommendations = [AdvisorRecommendation(**r) for r in raw_recs]

        return AdvisorRecommendationsResponse(
            recommendations=recommendations,
            total_count=len(recommendations),
            total_potential_monthly_savings=round(total_monthly, 2),
            total_potential_annual_savings=round(total_annual, 2),
            by_impact=by_impact,
            by_category={"cost_optimization": len(recommendations)},
        )

    except Exception as e:
        logger.error("Failed to fetch cost recommendations", error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch cost recommendations: {str(e)}",
        )


@router.post("/refresh", response_model=RefreshResponse)
async def refresh_recommendations(
    _auth: Optional[APIKeyInfo] = Depends(get_write_auth()),
) -> RefreshResponse:
    """
    Trigger a refresh of Azure Advisor recommendations.
    
    Note: Azure Advisor recommendations are typically updated every 24 hours.
    This endpoint triggers an immediate refresh.
    
    **Requires scope:** `recommendations:write` or `*`
    """
    settings = get_settings()
    
    if not settings.is_azure_configured:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Azure credentials not configured",
        )

    advisor_client = get_azure_advisor_client()

    try:
        success = await advisor_client.generate_recommendations_refresh()
        
        if success:
            return RefreshResponse(
                success=True,
                message="Advisor recommendations refresh triggered. New recommendations may take several minutes to appear.",
            )
        else:
            return RefreshResponse(
                success=False,
                message="Failed to trigger recommendations refresh",
            )

    except Exception as e:
        logger.error("Failed to refresh recommendations", error=str(e))
        return RefreshResponse(
            success=False,
            message=f"Failed to refresh: {str(e)}",
        )


@router.post("/suppress", response_model=RefreshResponse)
async def suppress_recommendation(
    request: SuppressRequest,
    _auth: Optional[APIKeyInfo] = Depends(get_write_auth()),
) -> RefreshResponse:
    """
    Suppress (snooze) an Azure Advisor recommendation.
    
    Suppressed recommendations won't appear in the list until the suppression expires.
    
    **Requires scope:** `recommendations:write` or `*`
    """
    settings = get_settings()
    
    if not settings.is_azure_configured:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Azure credentials not configured",
        )

    advisor_client = get_azure_advisor_client()

    # Convert days to duration string
    duration = None
    if request.duration_days:
        duration = f"{request.duration_days}.00:00:00"

    try:
        success = await advisor_client.suppress_recommendation(
            recommendation_id=request.recommendation_id,
            resource_uri=request.resource_uri,
            suppression_name=request.suppression_name,
            duration=duration,
        )
        
        if success:
            return RefreshResponse(
                success=True,
                message=f"Recommendation suppressed for {request.duration_days or 'unlimited'} days",
            )
        else:
            return RefreshResponse(
                success=False,
                message="Failed to suppress recommendation",
            )

    except Exception as e:
        logger.error("Failed to suppress recommendation", error=str(e))
        return RefreshResponse(
            success=False,
            message=f"Failed to suppress: {str(e)}",
        )
