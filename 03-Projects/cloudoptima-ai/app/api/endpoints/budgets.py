"""Budget management endpoints."""

from typing import Annotated, Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.auth import APIKeyInfo, get_api_key_optional, require_scope, Scopes
from app.core.config import get_settings
from app.core.database import get_db
from app.core.exceptions import AlertNotFoundError, BudgetNotFoundError
from app.core.logging import get_logger
from app.models.budget import BudgetTimeGrain
from app.schemas.budget import (
    BudgetCreate,
    BudgetUpdate,
    BudgetResponse,
    BudgetAlertResponse,
    AlertAcknowledge,
)
from app.services.budget_service import BudgetService

router = APIRouter()
logger = get_logger(__name__)


def get_auth_dependency():
    """Get authentication dependency based on settings."""
    settings = get_settings()
    if settings.auth_enabled and settings.api_key:
        return require_scope(Scopes.BUDGETS_WRITE)
    return get_api_key_optional


def get_read_auth_dependency():
    """Get read-only authentication dependency."""
    settings = get_settings()
    if settings.auth_enabled and settings.api_key:
        return require_scope(Scopes.BUDGETS_READ)
    return get_api_key_optional


@router.post("/", response_model=BudgetResponse, status_code=201)
async def create_budget(
    request: BudgetCreate,
    db: AsyncSession = Depends(get_db),
    _auth: Optional[APIKeyInfo] = Depends(get_auth_dependency()),
) -> BudgetResponse:
    """
    Create a new budget.
    
    Creates a budget with optional resource group scope and alert thresholds.
    
    **Requires scope:** `budgets:write` or `*`
    """
    service = BudgetService(db)
    budget = await service.create_budget(
        name=request.name,
        amount=request.amount,
        subscription_id=request.subscription_id,
        resource_group=request.resource_group,
        time_grain=BudgetTimeGrain(request.time_grain),
        alert_thresholds=request.alert_thresholds,
        description=request.description,
        start_date=request.start_date,
        end_date=request.end_date,
    )
    
    logger.info("Budget created via API", budget_id=budget.id, name=budget.name)
    return _budget_to_response(budget)


@router.get("/", response_model=list[BudgetResponse])
async def list_budgets(
    subscription_id: Optional[str] = Query(default=None),
    active_only: bool = Query(default=True),
    db: AsyncSession = Depends(get_db),
    _auth: Optional[APIKeyInfo] = Depends(get_read_auth_dependency()),
) -> list[BudgetResponse]:
    """
    List all budgets.
    
    Returns budgets for the specified subscription.
    
    **Requires scope:** `budgets:read` or `*`
    """
    service = BudgetService(db)
    budgets = await service.list_budgets(
        subscription_id=subscription_id,
        active_only=active_only,
    )
    return [_budget_to_response(b) for b in budgets]


@router.get("/{budget_id}", response_model=BudgetResponse)
async def get_budget(
    budget_id: int,
    db: AsyncSession = Depends(get_db),
    _auth: Optional[APIKeyInfo] = Depends(get_read_auth_dependency()),
) -> BudgetResponse:
    """
    Get a specific budget.
    
    Returns budget details including associated alerts.
    
    **Requires scope:** `budgets:read` or `*`
    """
    service = BudgetService(db)
    budget = await service.get_budget(budget_id)
    
    if not budget:
        raise BudgetNotFoundError(budget_id)
    
    return _budget_to_response(budget)


@router.patch("/{budget_id}", response_model=BudgetResponse)
async def update_budget(
    budget_id: int,
    request: BudgetUpdate,
    db: AsyncSession = Depends(get_db),
    _auth: Optional[APIKeyInfo] = Depends(get_auth_dependency()),
) -> BudgetResponse:
    """
    Update a budget.
    
    Allows partial updates to budget properties.
    
    **Requires scope:** `budgets:write` or `*`
    """
    service = BudgetService(db)
    updates = request.model_dump(exclude_unset=True)
    budget = await service.update_budget(budget_id, **updates)
    
    if not budget:
        raise BudgetNotFoundError(budget_id)
    
    logger.info("Budget updated via API", budget_id=budget_id, updates=list(updates.keys()))
    return _budget_to_response(budget)


@router.delete("/{budget_id}", status_code=204)
async def delete_budget(
    budget_id: int,
    db: AsyncSession = Depends(get_db),
    _auth: Optional[APIKeyInfo] = Depends(get_auth_dependency()),
) -> None:
    """
    Delete a budget.
    
    Removes the budget and all associated alerts.
    
    **Requires scope:** `budgets:write` or `*`
    """
    service = BudgetService(db)
    deleted = await service.delete_budget(budget_id)
    
    if not deleted:
        raise BudgetNotFoundError(budget_id)
    
    logger.info("Budget deleted via API", budget_id=budget_id)


@router.post("/{budget_id}/check", response_model=list[BudgetAlertResponse])
async def check_budget_thresholds(
    budget_id: int,
    db: AsyncSession = Depends(get_db),
    _auth: Optional[APIKeyInfo] = Depends(get_auth_dependency()),
) -> list[BudgetAlertResponse]:
    """
    Check budget against thresholds.
    
    Compares current spend against budget thresholds and creates alerts
    for any newly exceeded thresholds.
    
    **Requires scope:** `budgets:write` or `*`
    """
    service = BudgetService(db)
    
    # First verify budget exists
    budget = await service.get_budget(budget_id)
    if not budget:
        raise BudgetNotFoundError(budget_id)
    
    alerts = await service.check_budget_thresholds(budget_id)
    
    logger.info(
        "Budget threshold check completed",
        budget_id=budget_id,
        new_alerts=len(alerts),
    )
    
    return [_alert_to_response(a) for a in alerts]


@router.get("/alerts/unacknowledged", response_model=list[BudgetAlertResponse])
async def get_unacknowledged_alerts(
    subscription_id: Optional[str] = Query(default=None),
    db: AsyncSession = Depends(get_db),
    _auth: Optional[APIKeyInfo] = Depends(get_read_auth_dependency()),
) -> list[BudgetAlertResponse]:
    """
    Get all unacknowledged alerts.
    
    Returns alerts that have not been acknowledged yet.
    
    **Requires scope:** `budgets:read` or `*`
    """
    service = BudgetService(db)
    alerts = await service.get_unacknowledged_alerts(subscription_id)
    return [_alert_to_response(a) for a in alerts]


@router.post("/alerts/{alert_id}/acknowledge", response_model=BudgetAlertResponse)
async def acknowledge_alert(
    alert_id: int,
    request: AlertAcknowledge,
    db: AsyncSession = Depends(get_db),
    _auth: Optional[APIKeyInfo] = Depends(get_auth_dependency()),
) -> BudgetAlertResponse:
    """
    Acknowledge a budget alert.
    
    Marks the alert as acknowledged by the specified user.
    
    **Requires scope:** `budgets:write` or `*`
    """
    service = BudgetService(db)
    alert = await service.acknowledge_alert(alert_id, request.acknowledged_by)
    
    if not alert:
        raise AlertNotFoundError(alert_id)
    
    logger.info(
        "Alert acknowledged via API",
        alert_id=alert_id,
        acknowledged_by=request.acknowledged_by,
    )
    
    return _alert_to_response(alert)


def _budget_to_response(budget) -> BudgetResponse:
    """Convert budget model to response schema."""
    return BudgetResponse(
        id=budget.id,
        name=budget.name,
        description=budget.description,
        subscription_id=budget.subscription_id,
        resource_group=budget.resource_group,
        amount=float(budget.amount),
        currency=budget.currency,
        time_grain=budget.time_grain.value,
        alert_thresholds=budget.alert_thresholds,
        current_spend=float(budget.current_spend),
        spend_percentage=float(budget.spend_percentage),
        start_date=budget.start_date,
        end_date=budget.end_date,
        is_active=budget.is_active,
        alerts=[_alert_to_response(a) for a in budget.alerts],
        created_at=budget.created_at,
        updated_at=budget.updated_at,
    )


def _alert_to_response(alert) -> BudgetAlertResponse:
    """Convert alert model to response schema."""
    return BudgetAlertResponse(
        id=alert.id,
        budget_id=alert.budget_id,
        threshold_percent=alert.threshold_percent,
        actual_percent=float(alert.actual_percent),
        actual_amount=float(alert.actual_amount),
        severity=alert.severity.value,
        message=alert.message,
        is_acknowledged=alert.is_acknowledged,
        acknowledged_at=alert.acknowledged_at,
        acknowledged_by=alert.acknowledged_by,
        created_at=alert.created_at,
    )
