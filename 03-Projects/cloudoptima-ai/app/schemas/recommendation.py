"""Recommendation-related schemas."""

from datetime import datetime
from typing import Any, Optional

from pydantic import BaseModel, Field


class RecommendationResponse(BaseModel):
    """Recommendation response."""

    id: int = Field(description="Recommendation ID")
    subscription_id: str = Field(description="Azure subscription ID")
    resource_group: Optional[str] = Field(default=None)
    resource_id: Optional[str] = Field(default=None)
    resource_name: Optional[str] = Field(default=None)
    resource_type: Optional[str] = Field(default=None)
    
    title: str = Field(description="Recommendation title")
    description: str = Field(description="Detailed description")
    category: str = Field(description="Recommendation category")
    impact: str = Field(description="Expected impact level")
    
    estimated_monthly_savings: float = Field(description="Estimated monthly savings")
    estimated_annual_savings: float = Field(description="Estimated annual savings")
    currency: str = Field(description="Currency")
    confidence_score: float = Field(description="Confidence score (0-1)")
    
    current_config: Optional[str] = Field(default=None)
    recommended_config: Optional[str] = Field(default=None)
    
    implementation_effort: str = Field(description="Implementation effort level")
    implementation_steps: Optional[str] = Field(default=None)
    risk_level: str = Field(description="Risk level")
    
    status: str = Field(description="Recommendation status")
    status_changed_at: Optional[datetime] = Field(default=None)
    status_changed_by: Optional[str] = Field(default=None)
    rejection_reason: Optional[str] = Field(default=None)
    
    source: str = Field(description="Recommendation source")
    valid_from: datetime = Field(description="Valid from date")
    valid_until: Optional[datetime] = Field(default=None)
    
    created_at: datetime = Field(description="Creation timestamp")
    updated_at: datetime = Field(description="Last update timestamp")

    class Config:
        from_attributes = True


class RecommendationStatusUpdate(BaseModel):
    """Request to update recommendation status."""

    status: str = Field(
        description="New status (new, in_review, accepted, rejected, implemented)"
    )
    changed_by: str = Field(min_length=1, max_length=255, description="User making the change")
    rejection_reason: Optional[str] = Field(
        default=None, description="Reason for rejection (if status is rejected)"
    )


class CategorySavings(BaseModel):
    """Savings by category."""

    count: int = Field(description="Number of recommendations")
    monthly_savings: float = Field(description="Total monthly savings")


class StatusSavings(BaseModel):
    """Savings by status."""

    count: int = Field(description="Number of recommendations")
    monthly_savings: float = Field(description="Total monthly savings")


class SavingsSummaryResponse(BaseModel):
    """Summary of potential savings."""

    subscription_id: str = Field(description="Azure subscription ID")
    total_potential_monthly_savings: float = Field(
        description="Total potential monthly savings (new + in_review)"
    )
    total_accepted_monthly_savings: float = Field(
        description="Total accepted monthly savings"
    )
    total_implemented_monthly_savings: float = Field(
        description="Total implemented monthly savings"
    )
    by_category: dict[str, CategorySavings] = Field(
        default_factory=dict, description="Savings breakdown by category"
    )
    by_status: dict[str, StatusSavings] = Field(
        default_factory=dict, description="Savings breakdown by status"
    )
