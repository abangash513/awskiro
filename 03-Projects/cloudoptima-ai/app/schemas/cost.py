"""Cost-related schemas."""

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field, field_validator, model_validator

from app.schemas.validators import (
    validate_subscription_id,
    validate_resource_group,
    validate_date_range,
)


class CostByService(BaseModel):
    """Cost breakdown by service."""

    service_name: str = Field(description="Azure service name")
    total_cost: float = Field(description="Total cost for this service")
    percentage: float = Field(description="Percentage of total cost")


class CostSummaryResponse(BaseModel):
    """Cost summary response."""

    subscription_id: str = Field(description="Azure subscription ID")
    resource_group: Optional[str] = Field(default=None, description="Resource group filter")
    period_start: str = Field(description="Summary period start date")
    period_end: str = Field(description="Summary period end date")
    total_cost: float = Field(description="Total cost for the period")
    currency: str = Field(default="USD", description="Currency")
    cost_by_service: list[CostByService] = Field(
        default_factory=list, description="Cost breakdown by service"
    )
    service_count: int = Field(description="Number of services with costs")


class DailyCostItem(BaseModel):
    """Single day cost item."""

    date: str = Field(description="Date (YYYY-MM-DD)")
    cost: float = Field(description="Cost for this day")


class DailyCostResponse(BaseModel):
    """Daily cost breakdown response."""

    subscription_id: str = Field(description="Azure subscription ID")
    days: int = Field(description="Number of days queried")
    costs: list[DailyCostItem] = Field(description="Daily costs")
    total_cost: float = Field(description="Total cost for the period")


class TopResourceResponse(BaseModel):
    """Top spending resource."""

    resource_name: Optional[str] = Field(description="Resource name")
    resource_type: Optional[str] = Field(description="Resource type")
    resource_group: Optional[str] = Field(description="Resource group")
    total_cost: float = Field(description="Total cost")


class CostTrendResponse(BaseModel):
    """Cost trend analysis response."""

    subscription_id: str = Field(description="Azure subscription ID")
    current_week_cost: float = Field(description="Current week cost")
    previous_week_cost: float = Field(description="Previous week cost")
    week_over_week_change: float = Field(description="Week-over-week change percentage")
    current_month_cost: float = Field(description="Current month cost")
    previous_month_cost: float = Field(description="Previous month cost")
    month_over_month_change: float = Field(description="Month-over-month change percentage")


class CostIngestionRequest(BaseModel):
    """Request to ingest cost data."""

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
    start_date: Optional[datetime] = Field(
        default=None,
        description="Start date for ingestion (max 365 days ago)",
        json_schema_extra={"example": "2024-01-01T00:00:00Z"},
    )
    end_date: Optional[datetime] = Field(
        default=None,
        description="End date for ingestion (cannot be in the future)",
        json_schema_extra={"example": "2024-01-31T23:59:59Z"},
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

    @model_validator(mode="after")
    def validate_dates(self) -> "CostIngestionRequest":
        """Validate date range is valid."""
        self.start_date, self.end_date = validate_date_range(
            self.start_date,
            self.end_date,
            max_days=365,
        )
        return self


class CostIngestionResponse(BaseModel):
    """Cost ingestion result."""

    status: str = Field(description="Ingestion status")
    records_created: int = Field(description="Number of records created")
    records_updated: int = Field(description="Number of records updated")
    subscription_id: str = Field(description="Subscription processed")
