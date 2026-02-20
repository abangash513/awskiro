"""Cost management endpoints."""

from typing import Annotated, Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import APIKeyInfo, get_api_key_optional, require_scope, Scopes
from app.core.config import get_settings
from app.core.database import get_db
from app.core.logging import get_logger
from app.schemas.cost import (
    CostSummaryResponse,
    DailyCostResponse,
    DailyCostItem,
    TopResourceResponse,
    CostTrendResponse,
    CostIngestionRequest,
    CostIngestionResponse,
)
from app.services.cost_service import CostService

router = APIRouter()
logger = get_logger(__name__)


def get_write_auth():
    """Get write authentication dependency."""
    settings = get_settings()
    if settings.auth_enabled and settings.api_key:
        return require_scope(Scopes.COSTS_WRITE)
    return get_api_key_optional


def get_read_auth():
    """Get read authentication dependency."""
    settings = get_settings()
    if settings.auth_enabled and settings.api_key:
        return require_scope(Scopes.COSTS_READ)
    return get_api_key_optional


@router.post("/ingest", response_model=CostIngestionResponse)
async def ingest_cost_data(
    request: CostIngestionRequest,
    db: AsyncSession = Depends(get_db),
    _auth: Optional[APIKeyInfo] = Depends(get_write_auth()),
) -> CostIngestionResponse:
    """
    Ingest cost data from Azure Cost Management.
    
    Fetches cost data from Azure and stores it in the database for analysis.
    This operation may take several minutes depending on the date range.
    
    **Requires scope:** `costs:write` or `*`
    """
    service = CostService(db)
    result = await service.ingest_cost_data(
        subscription_id=request.subscription_id,
        resource_group=request.resource_group,
        start_date=request.start_date,
        end_date=request.end_date,
    )
    
    logger.info(
        "Cost ingestion completed via API",
        records_created=result.get("records_created"),
        subscription_id=request.subscription_id,
    )
    
    return CostIngestionResponse(**result)


@router.get("/summary", response_model=CostSummaryResponse)
async def get_cost_summary(
    subscription_id: Optional[str] = Query(default=None),
    resource_group: Optional[str] = Query(default=None),
    db: AsyncSession = Depends(get_db),
    _auth: Optional[APIKeyInfo] = Depends(get_read_auth()),
) -> CostSummaryResponse:
    """
    Get aggregated cost summary.
    
    Returns total costs broken down by service for the default lookback period.
    
    **Requires scope:** `costs:read` or `*`
    """
    service = CostService(db)
    result = await service.get_cost_summary(
        subscription_id=subscription_id,
        resource_group=resource_group,
    )
    return CostSummaryResponse(**result)


@router.get("/daily", response_model=DailyCostResponse)
async def get_daily_costs(
    subscription_id: Optional[str] = Query(default=None),
    days: int = Query(default=30, ge=1, le=365),
    db: AsyncSession = Depends(get_db),
    _auth: Optional[APIKeyInfo] = Depends(get_read_auth()),
) -> DailyCostResponse:
    """
    Get daily cost breakdown.
    
    Returns cost data for each day in the specified period.
    
    **Requires scope:** `costs:read` or `*`
    """
    service = CostService(db)
    costs = await service.get_daily_costs(
        subscription_id=subscription_id,
        days=days,
    )
    
    total_cost = sum(c["cost"] for c in costs)
    settings = get_settings()
    
    return DailyCostResponse(
        subscription_id=subscription_id or settings.azure_subscription_id,
        days=days,
        costs=[DailyCostItem(**c) for c in costs],
        total_cost=total_cost,
    )


@router.get("/top-resources", response_model=list[TopResourceResponse])
async def get_top_resources(
    subscription_id: Optional[str] = Query(default=None),
    limit: int = Query(default=10, ge=1, le=50),
    days: int = Query(default=30, ge=1, le=365),
    db: AsyncSession = Depends(get_db),
    _auth: Optional[APIKeyInfo] = Depends(get_read_auth()),
) -> list[TopResourceResponse]:
    """
    Get top spending resources.
    
    Returns the highest cost resources for the specified period.
    
    **Requires scope:** `costs:read` or `*`
    """
    service = CostService(db)
    resources = await service.get_top_spending_resources(
        subscription_id=subscription_id,
        limit=limit,
        days=days,
    )
    return [TopResourceResponse(**r) for r in resources]


@router.get("/trends", response_model=CostTrendResponse)
async def get_cost_trends(
    subscription_id: Optional[str] = Query(default=None),
    db: AsyncSession = Depends(get_db),
    _auth: Optional[APIKeyInfo] = Depends(get_read_auth()),
) -> CostTrendResponse:
    """
    Get cost trend analysis.
    
    Returns week-over-week and month-over-month cost changes.
    
    **Requires scope:** `costs:read` or `*`
    """
    service = CostService(db)
    result = await service.calculate_cost_trends(
        subscription_id=subscription_id,
    )
    return CostTrendResponse(**result)
