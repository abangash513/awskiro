"""Service layer for Azure and business logic."""

from app.services.azure_client import AzureClient
from app.services.azure_monitor import AzureMonitorClient, get_azure_monitor_client
from app.services.azure_advisor import AzureAdvisorClient, get_azure_advisor_client
from app.services.cost_service import CostService
from app.services.budget_service import BudgetService
from app.services.recommendation_service import RecommendationService
from app.services.notification_service import (
    NotificationService,
    NotificationPayload,
    BudgetAlertPayload,
    NotificationChannel,
    NotificationSeverity,
    WebhookProvider,
    SlackProvider,
    TeamsProvider,
    get_notification_service,
)

__all__ = [
    # Azure services
    "AzureClient",
    "AzureMonitorClient",
    "get_azure_monitor_client",
    "AzureAdvisorClient",
    "get_azure_advisor_client",
    # Business services
    "CostService",
    "BudgetService",
    "RecommendationService",
    # Notification services
    "NotificationService",
    "NotificationPayload",
    "BudgetAlertPayload",
    "NotificationChannel",
    "NotificationSeverity",
    "WebhookProvider",
    "SlackProvider",
    "TeamsProvider",
    "get_notification_service",
]
