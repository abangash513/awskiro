"""Pydantic schemas for API request/response models."""

from app.schemas.cost import (
    CostSummaryResponse,
    DailyCostResponse,
    TopResourceResponse,
    CostTrendResponse,
    CostIngestionRequest,
    CostIngestionResponse,
)
from app.schemas.budget import (
    BudgetCreate,
    BudgetUpdate,
    BudgetResponse,
    BudgetAlertResponse,
    AlertAcknowledge,
)
from app.schemas.recommendation import (
    RecommendationResponse,
    RecommendationStatusUpdate,
    SavingsSummaryResponse,
)
from app.schemas.common import HealthResponse, ErrorResponse
from app.schemas.validators import (
    validate_subscription_id,
    validate_resource_group,
    validate_date_range,
    validate_percentage,
    validate_positive_amount,
)

__all__ = [
    # Cost schemas
    "CostSummaryResponse",
    "DailyCostResponse",
    "TopResourceResponse",
    "CostTrendResponse",
    "CostIngestionRequest",
    "CostIngestionResponse",
    # Budget schemas
    "BudgetCreate",
    "BudgetUpdate",
    "BudgetResponse",
    "BudgetAlertResponse",
    "AlertAcknowledge",
    # Recommendation schemas
    "RecommendationResponse",
    "RecommendationStatusUpdate",
    "SavingsSummaryResponse",
    # Common schemas
    "HealthResponse",
    "ErrorResponse",
    # Validators
    "validate_subscription_id",
    "validate_resource_group",
    "validate_date_range",
    "validate_percentage",
    "validate_positive_amount",
]
