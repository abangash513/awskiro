"""Recommendation management endpoints."""

from typing import Annotated, Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import APIKeyInfo, get_api_key_optional, require_scope, Scopes
from app.core.config import get_settings
from app.core.database import get_db
from app.core.exceptions import RecommendationNotFoundError, ValidationError
from app.core.logging import get_logger
from app.models.recommendation import RecommendationCategory, RecommendationStatus
from app.schemas.recommendation import (
    RecommendationResponse,
    RecommendationStatusUpdate,
    SavingsSummaryResponse,
)
from app.services.recommendation_service import RecommendationService

router = APIRouter()
logger = get_logger(__name__)


def get_write_auth():
    """Get write authentication dependency."""
    settings = get_settings()
    if settings.auth_enabled and settings.api_key:
        return require_scope(Scopes.RECOMMENDATIONS_WRITE)
    return get_api_key_optional


def get_read_auth():
    """Get read authentication dependency."""
    settings = get_settings()
    if settings.auth_enabled and settings.api_key:
        return require_scope(Scopes.RECOMMENDATIONS_READ)
    return get_api_key_optional


@router.post("/generate", response_model=list[RecommendationResponse])
async def generate_recommendations(
    subscription_id: Optional[str] = Query(default=None),
    db: AsyncSession = Depends(get_db),
    _auth: Optional[APIKeyInfo] = Depends(get_write_auth()),
) -> list[RecommendationResponse]:
    """
    Generate cost optimization recommendations.
    
    Analyzes cost data and generates actionable recommendations
    for cost savings opportunities.
    
    **Requires scope:** `recommendations:write` or `*`
    """
    service = RecommendationService(db)
    recommendations = await service.generate_recommendations(subscription_id)
    
    logger.info(
        "Recommendations generated via API",
        count=len(recommendations),
        subscription_id=subscription_id,
    )
    
    return [_rec_to_response(r) for r in recommendations]


@router.get("/", response_model=list[RecommendationResponse])
async def list_recommendations(
    subscription_id: Optional[str] = Query(default=None),
    category: Optional[str] = Query(default=None, description="Filter by category"),
    status: Optional[str] = Query(default=None, description="Filter by status"),
    min_savings: Optional[float] = Query(default=None, ge=0, description="Minimum monthly savings"),
    db: AsyncSession = Depends(get_db),
    _auth: Optional[APIKeyInfo] = Depends(get_read_auth()),
) -> list[RecommendationResponse]:
    """
    List recommendations with optional filters.
    
    Returns recommendations sorted by estimated monthly savings.
    
    **Requires scope:** `recommendations:read` or `*`
    
    **Categories:** idle_resources, rightsizing, reserved_instances, storage_optimization, 
    network_optimization, licensing, other
    
    **Statuses:** new, in_review, accepted, rejected, implemented
    """
    service = RecommendationService(db)
    
    # Parse enums if provided
    category_enum = None
    status_enum = None
    
    if category:
        try:
            category_enum = RecommendationCategory(category)
        except ValueError:
            valid_categories = [c.value for c in RecommendationCategory]
            raise ValidationError(
                f"Invalid category '{category}'. Must be one of: {valid_categories}",
                field="category",
            )
    
    if status:
        try:
            status_enum = RecommendationStatus(status)
        except ValueError:
            valid_statuses = [s.value for s in RecommendationStatus]
            raise ValidationError(
                f"Invalid status '{status}'. Must be one of: {valid_statuses}",
                field="status",
            )
    
    recommendations = await service.list_recommendations(
        subscription_id=subscription_id,
        category=category_enum,
        status=status_enum,
        min_savings=min_savings,
    )
    return [_rec_to_response(r) for r in recommendations]


@router.get("/savings-summary", response_model=SavingsSummaryResponse)
async def get_savings_summary(
    subscription_id: Optional[str] = Query(default=None),
    db: AsyncSession = Depends(get_db),
    _auth: Optional[APIKeyInfo] = Depends(get_read_auth()),
) -> SavingsSummaryResponse:
    """
    Get summary of potential savings.
    
    Returns aggregated savings broken down by category and status.
    
    **Requires scope:** `recommendations:read` or `*`
    """
    service = RecommendationService(db)
    result = await service.get_savings_summary(subscription_id)
    return SavingsSummaryResponse(**result)


@router.get("/{recommendation_id}", response_model=RecommendationResponse)
async def get_recommendation(
    recommendation_id: int,
    db: AsyncSession = Depends(get_db),
    _auth: Optional[APIKeyInfo] = Depends(get_read_auth()),
) -> RecommendationResponse:
    """
    Get a specific recommendation.
    
    Returns detailed recommendation including implementation steps.
    
    **Requires scope:** `recommendations:read` or `*`
    """
    service = RecommendationService(db)
    rec = await service.get_recommendation(recommendation_id)
    
    if not rec:
        raise RecommendationNotFoundError(recommendation_id)
    
    return _rec_to_response(rec)


@router.patch("/{recommendation_id}/status", response_model=RecommendationResponse)
async def update_recommendation_status(
    recommendation_id: int,
    request: RecommendationStatusUpdate,
    db: AsyncSession = Depends(get_db),
    _auth: Optional[APIKeyInfo] = Depends(get_write_auth()),
) -> RecommendationResponse:
    """
    Update recommendation status.
    
    Changes the status (new, in_review, accepted, rejected, implemented).
    For rejections, include a rejection_reason.
    
    **Requires scope:** `recommendations:write` or `*`
    """
    service = RecommendationService(db)
    
    # Validate status enum
    try:
        status_enum = RecommendationStatus(request.status)
    except ValueError:
        valid_statuses = [s.value for s in RecommendationStatus]
        raise ValidationError(
            f"Invalid status '{request.status}'. Must be one of: {valid_statuses}",
            field="status",
        )
    
    rec = await service.update_recommendation_status(
        recommendation_id=recommendation_id,
        status=status_enum,
        changed_by=request.changed_by,
        rejection_reason=request.rejection_reason,
    )
    
    if not rec:
        raise RecommendationNotFoundError(recommendation_id)
    
    logger.info(
        "Recommendation status updated via API",
        recommendation_id=recommendation_id,
        status=request.status,
        changed_by=request.changed_by,
    )
    
    return _rec_to_response(rec)


def _rec_to_response(rec) -> RecommendationResponse:
    """Convert recommendation model to response schema."""
    return RecommendationResponse(
        id=rec.id,
        subscription_id=rec.subscription_id,
        resource_group=rec.resource_group,
        resource_id=rec.resource_id,
        resource_name=rec.resource_name,
        resource_type=rec.resource_type,
        title=rec.title,
        description=rec.description,
        category=rec.category.value,
        impact=rec.impact.value,
        estimated_monthly_savings=float(rec.estimated_monthly_savings),
        estimated_annual_savings=float(rec.estimated_annual_savings),
        currency=rec.currency,
        confidence_score=float(rec.confidence_score),
        current_config=rec.current_config,
        recommended_config=rec.recommended_config,
        implementation_effort=rec.implementation_effort,
        implementation_steps=rec.implementation_steps,
        risk_level=rec.risk_level,
        status=rec.status.value,
        status_changed_at=rec.status_changed_at,
        status_changed_by=rec.status_changed_by,
        rejection_reason=rec.rejection_reason,
        source=rec.source,
        valid_from=rec.valid_from,
        valid_until=rec.valid_until,
        created_at=rec.created_at,
        updated_at=rec.updated_at,
    )
