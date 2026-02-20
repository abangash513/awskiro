"""Custom exception hierarchy for CloudOptima AI."""

from typing import Any, Optional


class CloudOptimaError(Exception):
    """Base exception for all CloudOptima errors."""

    def __init__(
        self,
        message: str,
        error_code: Optional[str] = None,
        details: Optional[dict[str, Any]] = None,
    ) -> None:
        self.message = message
        self.error_code = error_code or "CLOUDOPTIMA_ERROR"
        self.details = details or {}
        super().__init__(self.message)

    def to_dict(self) -> dict[str, Any]:
        """Convert exception to dict for API responses."""
        return {
            "error_code": self.error_code,
            "message": self.message,
            "details": self.details,
        }


# =============================================================================
# Authentication Errors
# =============================================================================

class AuthenticationError(CloudOptimaError):
    """Authentication-related errors."""

    def __init__(
        self,
        message: str = "Authentication failed",
        error_code: str = "AUTH_ERROR",
        details: Optional[dict[str, Any]] = None,
    ) -> None:
        super().__init__(message, error_code, details)


class InvalidAPIKeyError(AuthenticationError):
    """Invalid or missing API key."""

    def __init__(self, message: str = "Invalid or missing API key") -> None:
        super().__init__(message, "INVALID_API_KEY")


class ExpiredAPIKeyError(AuthenticationError):
    """Expired API key."""

    def __init__(self, message: str = "API key has expired") -> None:
        super().__init__(message, "EXPIRED_API_KEY")


class InsufficientPermissionsError(AuthenticationError):
    """User lacks required permissions."""

    def __init__(self, message: str = "Insufficient permissions for this operation") -> None:
        super().__init__(message, "INSUFFICIENT_PERMISSIONS")


# =============================================================================
# Azure Errors
# =============================================================================

class AzureError(CloudOptimaError):
    """Azure-related errors."""

    def __init__(
        self,
        message: str,
        error_code: str = "AZURE_ERROR",
        details: Optional[dict[str, Any]] = None,
    ) -> None:
        super().__init__(message, error_code, details)


class AzureAuthenticationError(AzureError):
    """Azure authentication failure."""

    def __init__(
        self,
        message: str = "Azure authentication failed",
        details: Optional[dict[str, Any]] = None,
    ) -> None:
        super().__init__(message, "AZURE_AUTH_ERROR", details)


class AzureCredentialsNotConfiguredError(AzureError):
    """Azure credentials not configured."""

    def __init__(self) -> None:
        super().__init__(
            "Azure credentials not configured. Set AZURE_TENANT_ID, "
            "AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, and AZURE_SUBSCRIPTION_ID.",
            "AZURE_NOT_CONFIGURED",
        )


class AzureRateLimitError(AzureError):
    """Azure API rate limit exceeded."""

    def __init__(
        self,
        retry_after: Optional[int] = None,
        details: Optional[dict[str, Any]] = None,
    ) -> None:
        details = details or {}
        if retry_after:
            details["retry_after_seconds"] = retry_after
        super().__init__(
            f"Azure API rate limit exceeded. Retry after {retry_after or 'unknown'} seconds.",
            "AZURE_RATE_LIMITED",
            details,
        )
        self.retry_after = retry_after


class AzureQuotaExceededError(AzureError):
    """Azure quota exceeded."""

    def __init__(
        self,
        quota_type: str,
        message: Optional[str] = None,
    ) -> None:
        super().__init__(
            message or f"Azure quota exceeded: {quota_type}",
            "AZURE_QUOTA_EXCEEDED",
            {"quota_type": quota_type},
        )


class AzureResourceNotFoundError(AzureError):
    """Azure resource not found."""

    def __init__(
        self,
        resource_type: str,
        resource_id: str,
    ) -> None:
        super().__init__(
            f"{resource_type} not found: {resource_id}",
            "AZURE_RESOURCE_NOT_FOUND",
            {"resource_type": resource_type, "resource_id": resource_id},
        )


class AzureServiceUnavailableError(AzureError):
    """Azure service temporarily unavailable."""

    def __init__(
        self,
        service: str = "Azure",
        details: Optional[dict[str, Any]] = None,
    ) -> None:
        super().__init__(
            f"{service} is temporarily unavailable. Please try again later.",
            "AZURE_SERVICE_UNAVAILABLE",
            details,
        )


# =============================================================================
# Validation Errors
# =============================================================================

class ValidationError(CloudOptimaError):
    """Input validation errors."""

    def __init__(
        self,
        message: str,
        field: Optional[str] = None,
        details: Optional[dict[str, Any]] = None,
    ) -> None:
        details = details or {}
        if field:
            details["field"] = field
        super().__init__(message, "VALIDATION_ERROR", details)


class InvalidDateRangeError(ValidationError):
    """Invalid date range specified."""

    def __init__(self, message: str = "Invalid date range") -> None:
        super().__init__(message, "date_range")


class InvalidSubscriptionError(ValidationError):
    """Invalid subscription ID."""

    def __init__(self, subscription_id: str) -> None:
        super().__init__(
            f"Invalid subscription ID: {subscription_id}",
            "subscription_id",
            {"subscription_id": subscription_id},
        )


# =============================================================================
# Resource Errors
# =============================================================================

class ResourceNotFoundError(CloudOptimaError):
    """Requested resource not found."""

    def __init__(
        self,
        resource_type: str,
        resource_id: Any,
    ) -> None:
        super().__init__(
            f"{resource_type} not found: {resource_id}",
            "RESOURCE_NOT_FOUND",
            {"resource_type": resource_type, "resource_id": str(resource_id)},
        )


class BudgetNotFoundError(ResourceNotFoundError):
    """Budget not found."""

    def __init__(self, budget_id: int) -> None:
        super().__init__("Budget", budget_id)


class RecommendationNotFoundError(ResourceNotFoundError):
    """Recommendation not found."""

    def __init__(self, recommendation_id: int) -> None:
        super().__init__("Recommendation", recommendation_id)


class AlertNotFoundError(ResourceNotFoundError):
    """Alert not found."""

    def __init__(self, alert_id: int) -> None:
        super().__init__("Alert", alert_id)


# =============================================================================
# Database Errors
# =============================================================================

class DatabaseError(CloudOptimaError):
    """Database-related errors."""

    def __init__(
        self,
        message: str = "Database operation failed",
        details: Optional[dict[str, Any]] = None,
    ) -> None:
        super().__init__(message, "DATABASE_ERROR", details)


class DatabaseConnectionError(DatabaseError):
    """Failed to connect to database."""

    def __init__(self) -> None:
        super().__init__("Failed to connect to database", "DATABASE_CONNECTION_ERROR")


class DataIntegrityError(DatabaseError):
    """Data integrity constraint violation."""

    def __init__(self, message: str) -> None:
        super().__init__(message, "DATA_INTEGRITY_ERROR")


# =============================================================================
# Business Logic Errors
# =============================================================================

class BusinessLogicError(CloudOptimaError):
    """Business logic violations."""

    def __init__(
        self,
        message: str,
        error_code: str = "BUSINESS_LOGIC_ERROR",
        details: Optional[dict[str, Any]] = None,
    ) -> None:
        super().__init__(message, error_code, details)


class DuplicateBudgetError(BusinessLogicError):
    """Budget with same name already exists."""

    def __init__(self, budget_name: str) -> None:
        super().__init__(
            f"Budget with name '{budget_name}' already exists",
            "DUPLICATE_BUDGET",
            {"budget_name": budget_name},
        )


class BudgetInactiveError(BusinessLogicError):
    """Operation not allowed on inactive budget."""

    def __init__(self, budget_id: int) -> None:
        super().__init__(
            f"Budget {budget_id} is inactive",
            "BUDGET_INACTIVE",
            {"budget_id": budget_id},
        )
