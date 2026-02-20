"""Notification management endpoints."""

from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from app.core.auth import APIKeyInfo, get_api_key_optional, require_scope, Scopes
from app.core.config import get_settings
from app.core.logging import get_logger
from app.services.notification_service import (
    NotificationChannel,
    NotificationService,
    NotificationSeverity,
    get_notification_service,
)

router = APIRouter()
logger = get_logger(__name__)


def get_auth_dependency():
    """Get authentication dependency based on settings."""
    settings = get_settings()
    if settings.auth_enabled and settings.api_key:
        return require_scope(Scopes.BUDGETS_WRITE)  # Reuse budgets scope for notifications
    return get_api_key_optional


# =============================================================================
# Request/Response Schemas
# =============================================================================

class NotificationStatusResponse(BaseModel):
    """Notification service status response."""

    enabled: bool = Field(description="Whether notifications are enabled globally")
    configured_channels: list[str] = Field(
        description="List of configured notification channels"
    )
    webhook_configured: bool = Field(description="Whether webhook is configured")
    slack_configured: bool = Field(description="Whether Slack is configured")
    teams_configured: bool = Field(description="Whether Teams is configured")


class TestNotificationRequest(BaseModel):
    """Request to send a test notification."""

    title: str = Field(
        default="CloudOptima Test Notification",
        description="Notification title",
    )
    message: str = Field(
        default="This is a test notification from CloudOptima AI.",
        description="Notification message",
    )
    severity: str = Field(
        default="info",
        description="Notification severity (info, warning, critical)",
    )
    channel: Optional[str] = Field(
        default=None,
        description="Specific channel to test (webhook, slack, teams). Omit to test all.",
    )


class TestNotificationResponse(BaseModel):
    """Response from test notification."""

    success: bool = Field(description="Whether at least one notification was sent")
    results: dict[str, bool] = Field(
        description="Results per channel (channel -> success)"
    )
    message: str = Field(description="Summary message")


class TestBudgetAlertRequest(BaseModel):
    """Request to send a test budget alert notification."""

    budget_name: str = Field(
        default="Test Budget",
        description="Budget name for the test alert",
    )
    threshold_percent: int = Field(
        default=80,
        ge=0,
        le=200,
        description="Threshold percentage for the test",
    )
    actual_percent: float = Field(
        default=85.0,
        ge=0,
        description="Actual spend percentage for the test",
    )
    budget_amount: float = Field(
        default=10000.0,
        gt=0,
        description="Budget amount for the test",
    )
    channel: Optional[str] = Field(
        default=None,
        description="Specific channel to test (webhook, slack, teams). Omit to test all.",
    )


# =============================================================================
# Endpoints
# =============================================================================

@router.get("/status", response_model=NotificationStatusResponse)
async def get_notification_status(
    _auth: Optional[APIKeyInfo] = Depends(get_api_key_optional),
) -> NotificationStatusResponse:
    """
    Get notification service status.
    
    Returns information about which notification channels are configured.
    """
    settings = get_settings()
    service = get_notification_service()
    
    configured = service.configured_channels
    
    return NotificationStatusResponse(
        enabled=settings.notifications_enabled,
        configured_channels=[c.value for c in configured],
        webhook_configured=NotificationChannel.WEBHOOK in configured,
        slack_configured=NotificationChannel.SLACK in configured,
        teams_configured=NotificationChannel.TEAMS in configured,
    )


@router.post("/test", response_model=TestNotificationResponse)
async def send_test_notification(
    request: TestNotificationRequest,
    _auth: Optional[APIKeyInfo] = Depends(get_auth_dependency()),
) -> TestNotificationResponse:
    """
    Send a test notification.
    
    Use this to verify that your notification channels are configured correctly.
    
    **Requires scope:** `budgets:write` or `*`
    """
    settings = get_settings()
    
    if not settings.notifications_enabled:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Notifications are disabled globally. Set NOTIFICATIONS_ENABLED=true.",
        )
    
    # Validate severity
    try:
        severity = NotificationSeverity(request.severity.lower())
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Invalid severity '{request.severity}'. Must be one of: info, warning, critical",
        )
    
    # Validate channel if specified
    channels = None
    if request.channel:
        try:
            channels = [NotificationChannel(request.channel.lower())]
        except ValueError:
            valid = [c.value for c in NotificationChannel]
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Invalid channel '{request.channel}'. Must be one of: {', '.join(valid)}",
            )
    
    service = get_notification_service()
    
    # Send test notification
    results = await service.send_system_alert(
        title=request.title,
        message=request.message,
        severity=severity,
        metadata={"test": True},
        channels=channels,
    )
    
    # Convert enum keys to strings
    results_str = {k.value: v for k, v in results.items()}
    
    success = any(results.values())
    
    if not results_str:
        message = "No notification channels configured"
    elif success:
        successful = [k for k, v in results_str.items() if v]
        message = f"Test notification sent to: {', '.join(successful)}"
    else:
        message = "Failed to send test notification to any channel"
    
    logger.info(
        "Test notification sent",
        results=results_str,
        success=success,
    )
    
    return TestNotificationResponse(
        success=success,
        results=results_str,
        message=message,
    )


@router.post("/test-budget-alert", response_model=TestNotificationResponse)
async def send_test_budget_alert(
    request: TestBudgetAlertRequest,
    _auth: Optional[APIKeyInfo] = Depends(get_auth_dependency()),
) -> TestNotificationResponse:
    """
    Send a test budget alert notification.
    
    Use this to verify budget alert formatting and delivery.
    
    **Requires scope:** `budgets:write` or `*`
    """
    settings = get_settings()
    
    if not settings.notifications_enabled:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Notifications are disabled globally. Set NOTIFICATIONS_ENABLED=true.",
        )
    
    # Validate channel if specified
    channels = None
    if request.channel:
        try:
            channels = [NotificationChannel(request.channel.lower())]
        except ValueError:
            valid = [c.value for c in NotificationChannel]
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Invalid channel '{request.channel}'. Must be one of: {', '.join(valid)}",
            )
    
    service = get_notification_service()
    
    # Calculate actual amount from percentage
    actual_amount = (request.actual_percent / 100) * request.budget_amount
    
    # Send test budget alert
    results = await service.send_budget_alert(
        budget_id=0,  # Test ID
        budget_name=request.budget_name,
        threshold_percent=request.threshold_percent,
        actual_percent=request.actual_percent,
        actual_amount=actual_amount,
        budget_amount=request.budget_amount,
        channels=channels,
    )
    
    # Convert enum keys to strings
    results_str = {k.value: v for k, v in results.items()}
    
    success = any(results.values())
    
    if not results_str:
        message = "No notification channels configured"
    elif success:
        successful = [k for k, v in results_str.items() if v]
        message = f"Test budget alert sent to: {', '.join(successful)}"
    else:
        message = "Failed to send test budget alert to any channel"
    
    logger.info(
        "Test budget alert sent",
        budget_name=request.budget_name,
        results=results_str,
        success=success,
    )
    
    return TestNotificationResponse(
        success=success,
        results=results_str,
        message=message,
    )
