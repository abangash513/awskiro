"""Budget-related schemas."""

from datetime import datetime
from decimal import Decimal
from typing import Optional

from pydantic import BaseModel, Field, field_validator, model_validator

from app.schemas.validators import (
    validate_subscription_id,
    validate_resource_group,
)


class BudgetCreate(BaseModel):
    """Request to create a budget."""

    name: str = Field(
        min_length=1,
        max_length=255,
        description="Budget name",
        json_schema_extra={"example": "Production Monthly Budget"},
    )
    description: Optional[str] = Field(
        default=None,
        max_length=1000,
        description="Budget description",
        json_schema_extra={"example": "Monthly budget for production workloads"},
    )
    amount: Decimal = Field(
        gt=0,
        le=1_000_000_000,  # Max 1 billion
        description="Budget amount (must be positive)",
        json_schema_extra={"example": 10000.00},
    )
    subscription_id: Optional[str] = Field(
        default=None,
        description="Target subscription (uses default if not specified)",
        json_schema_extra={"example": "12345678-1234-1234-1234-123456789abc"},
    )
    resource_group: Optional[str] = Field(
        default=None,
        description="Filter to specific resource group",
        json_schema_extra={"example": "my-resource-group"},
    )
    time_grain: str = Field(
        default="monthly",
        description="Time granularity (monthly, quarterly, annually)",
        json_schema_extra={"example": "monthly"},
    )
    alert_thresholds: str = Field(
        default="50,80,100",
        description="Comma-separated alert threshold percentages (0-200)",
        json_schema_extra={"example": "50,80,100"},
    )
    start_date: Optional[datetime] = Field(
        default=None,
        description="Budget start date",
        json_schema_extra={"example": "2024-01-01T00:00:00Z"},
    )
    end_date: Optional[datetime] = Field(
        default=None,
        description="Budget end date (must be after start_date)",
        json_schema_extra={"example": "2024-12-31T23:59:59Z"},
    )

    @field_validator("subscription_id")
    @classmethod
    def validate_subscription(cls, v: Optional[str]) -> Optional[str]:
        """Validate subscription ID format."""
        return validate_subscription_id(v)

    @field_validator("resource_group")
    @classmethod
    def validate_rg(cls, v: Optional[str]) -> Optional[str]:
        """Validate resource group name."""
        return validate_resource_group(v)

    @field_validator("time_grain")
    @classmethod
    def validate_time_grain(cls, v: str) -> str:
        """Validate time grain value."""
        allowed = {"monthly", "quarterly", "annually"}
        v = v.strip().lower()
        if v not in allowed:
            raise ValueError(
                f"time_grain must be one of: {', '.join(sorted(allowed))}. Got: '{v}'"
            )
        return v

    @field_validator("alert_thresholds")
    @classmethod
    def validate_thresholds(cls, v: str) -> str:
        """Validate alert thresholds format."""
        try:
            raw_thresholds = [t.strip() for t in v.split(",")]
            if not raw_thresholds:
                raise ValueError("At least one threshold is required")
            
            thresholds = []
            for t in raw_thresholds:
                val = int(t)
                if not 0 <= val <= 200:
                    raise ValueError(f"Threshold {val} out of range (0-200)")
                thresholds.append(val)
            
            # Sort and dedupe for consistency
            thresholds = sorted(set(thresholds))
            return ",".join(str(t) for t in thresholds)
            
        except ValueError as e:
            if "invalid literal" in str(e):
                raise ValueError(
                    f"Invalid threshold format. Expected comma-separated integers (e.g., '50,80,100')"
                )
            raise

    @model_validator(mode="after")
    def validate_dates(self) -> "BudgetCreate":
        """Validate that end_date is after start_date if both provided."""
        if self.start_date and self.end_date:
            if self.start_date >= self.end_date:
                raise ValueError(
                    f"end_date ({self.end_date.isoformat()}) must be after "
                    f"start_date ({self.start_date.isoformat()})"
                )
        return self


class BudgetUpdate(BaseModel):
    """Request to update a budget."""

    name: Optional[str] = Field(default=None, min_length=1, max_length=255)
    description: Optional[str] = Field(default=None)
    amount: Optional[Decimal] = Field(default=None, gt=0)
    time_grain: Optional[str] = Field(default=None)
    alert_thresholds: Optional[str] = Field(default=None)
    is_active: Optional[bool] = Field(default=None)
    end_date: Optional[datetime] = Field(default=None)


class BudgetAlertResponse(BaseModel):
    """Budget alert response."""

    id: int = Field(description="Alert ID")
    budget_id: int = Field(description="Associated budget ID")
    threshold_percent: int = Field(description="Threshold that triggered the alert")
    actual_percent: float = Field(description="Actual spend percentage")
    actual_amount: float = Field(description="Actual spend amount")
    severity: str = Field(description="Alert severity (info, warning, critical)")
    message: str = Field(description="Alert message")
    is_acknowledged: bool = Field(description="Whether alert has been acknowledged")
    acknowledged_at: Optional[datetime] = Field(default=None)
    acknowledged_by: Optional[str] = Field(default=None)
    created_at: datetime = Field(description="Alert creation time")


class BudgetResponse(BaseModel):
    """Budget response."""

    id: int = Field(description="Budget ID")
    name: str = Field(description="Budget name")
    description: Optional[str] = Field(default=None)
    subscription_id: str = Field(description="Azure subscription ID")
    resource_group: Optional[str] = Field(default=None)
    amount: float = Field(description="Budget amount")
    currency: str = Field(description="Currency")
    time_grain: str = Field(description="Time granularity")
    alert_thresholds: str = Field(description="Alert thresholds")
    current_spend: float = Field(description="Current spend amount")
    spend_percentage: float = Field(description="Current spend percentage")
    start_date: datetime = Field(description="Budget start date")
    end_date: Optional[datetime] = Field(default=None)
    is_active: bool = Field(description="Whether budget is active")
    alerts: list[BudgetAlertResponse] = Field(
        default_factory=list, description="Associated alerts"
    )
    created_at: datetime = Field(description="Creation timestamp")
    updated_at: datetime = Field(description="Last update timestamp")

    class Config:
        from_attributes = True


class AlertAcknowledge(BaseModel):
    """Request to acknowledge an alert."""

    acknowledged_by: str = Field(
        min_length=1, max_length=255, description="User acknowledging the alert"
    )
