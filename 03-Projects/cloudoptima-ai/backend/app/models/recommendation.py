"""Cost optimization recommendation models."""

from datetime import datetime
from decimal import Decimal
from enum import Enum
from typing import Optional

from sqlalchemy import Boolean, DateTime, Enum as SQLEnum, Numeric, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class RecommendationCategory(str, Enum):
    """Recommendation categories."""
    RIGHTSIZING = "rightsizing"
    RESERVED_INSTANCES = "reserved_instances"
    SAVINGS_PLANS = "savings_plans"
    IDLE_RESOURCES = "idle_resources"
    STORAGE_OPTIMIZATION = "storage_optimization"
    NETWORK_OPTIMIZATION = "network_optimization"
    LICENSE_OPTIMIZATION = "license_optimization"
    OTHER = "other"


class RecommendationImpact(str, Enum):
    """Expected impact level."""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


class RecommendationStatus(str, Enum):
    """Recommendation status."""
    NEW = "new"
    IN_REVIEW = "in_review"
    ACCEPTED = "accepted"
    REJECTED = "rejected"
    IMPLEMENTED = "implemented"


class Recommendation(Base):
    """Cost optimization recommendation."""

    __tablename__ = "recommendations"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    
    # Scope
    subscription_id: Mapped[str] = mapped_column(String(36), nullable=False, index=True)
    account_name: Mapped[Optional[str]] = mapped_column(String(255), nullable=True, index=True)
    business_unit: Mapped[Optional[str]] = mapped_column(String(255), nullable=True, index=True)
    resource_group: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    resource_id: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    resource_name: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    resource_type: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    
    # Recommendation details
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    category: Mapped[RecommendationCategory] = mapped_column(
        SQLEnum(RecommendationCategory), nullable=False, index=True
    )
    impact: Mapped[RecommendationImpact] = mapped_column(
        SQLEnum(RecommendationImpact), nullable=False
    )
    
    # Savings estimate
    estimated_monthly_savings: Mapped[Decimal] = mapped_column(
        Numeric(18, 2), nullable=False
    )
    estimated_annual_savings: Mapped[Decimal] = mapped_column(
        Numeric(18, 2), nullable=False
    )
    currency: Mapped[str] = mapped_column(String(10), nullable=False, default="USD")
    confidence_score: Mapped[Decimal] = mapped_column(
        Numeric(3, 2), nullable=False, default=Decimal("0.80")
    )
    
    # Current vs recommended
    current_config: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    recommended_config: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    
    # Implementation
    implementation_effort: Mapped[str] = mapped_column(
        String(50), nullable=False, default="medium"
    )
    implementation_steps: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    risk_level: Mapped[str] = mapped_column(String(50), nullable=False, default="low")
    
    # Status
    status: Mapped[RecommendationStatus] = mapped_column(
        SQLEnum(RecommendationStatus), nullable=False, default=RecommendationStatus.NEW
    )
    status_changed_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    status_changed_by: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    rejection_reason: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    
    # Source
    source: Mapped[str] = mapped_column(
        String(50), nullable=False, default="cloudoptima"
    )
    azure_recommendation_id: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    
    # Validity
    valid_from: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    valid_until: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    is_stale: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    
    # Metadata
    created_at: Mapped[datetime] = mapped_column(
        DateTime, nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, nullable=False, server_default=func.now(), onupdate=func.now()
    )

    def __repr__(self) -> str:
        return f"<Recommendation(id={self.id}, title={self.title}, savings=${self.estimated_monthly_savings}/mo)>"
