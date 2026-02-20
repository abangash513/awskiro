"""Cost-related database models."""

from datetime import datetime
from decimal import Decimal
from typing import Optional

from sqlalchemy import DateTime, Index, Numeric, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class CostRecord(Base):
    """Individual cost record from Azure Cost Management."""

    __tablename__ = "cost_records"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    subscription_id: Mapped[str] = mapped_column(String(36), nullable=False, index=True)
    account_name: Mapped[Optional[str]] = mapped_column(String(255), nullable=True, index=True)
    business_unit: Mapped[Optional[str]] = mapped_column(String(255), nullable=True, index=True)
    resource_group: Mapped[Optional[str]] = mapped_column(String(255), nullable=True, index=True)
    resource_id: Mapped[Optional[str]] = mapped_column(String(500), nullable=True)
    resource_name: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    resource_type: Mapped[Optional[str]] = mapped_column(String(255), nullable=True, index=True)
    service_name: Mapped[Optional[str]] = mapped_column(String(255), nullable=True, index=True)
    meter_category: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    meter_subcategory: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    
    # Cost data
    cost: Mapped[Decimal] = mapped_column(Numeric(18, 6), nullable=False)
    currency: Mapped[str] = mapped_column(String(10), nullable=False, default="USD")
    quantity: Mapped[Optional[Decimal]] = mapped_column(Numeric(18, 6), nullable=True)
    unit_price: Mapped[Optional[Decimal]] = mapped_column(Numeric(18, 6), nullable=True)
    
    # Time
    usage_date: Mapped[datetime] = mapped_column(DateTime, nullable=False, index=True)
    billing_period: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)
    
    # Tags (stored as JSON string)
    tags: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    
    # Metadata
    created_at: Mapped[datetime] = mapped_column(
        DateTime, nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, nullable=False, server_default=func.now(), onupdate=func.now()
    )

    __table_args__ = (
        Index("ix_cost_subscription_date", "subscription_id", "usage_date"),
        Index("ix_cost_service_date", "service_name", "usage_date"),
    )

    def __repr__(self) -> str:
        return f"<CostRecord(id={self.id}, resource={self.resource_name}, cost={self.cost})>"


class CostSummary(Base):
    """Aggregated cost summary by subscription/resource group."""

    __tablename__ = "cost_summaries"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    subscription_id: Mapped[str] = mapped_column(String(36), nullable=False, index=True)
    resource_group: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    
    # Summary period
    period_start: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    period_end: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    granularity: Mapped[str] = mapped_column(String(20), nullable=False, default="daily")
    
    # Aggregated costs
    total_cost: Mapped[Decimal] = mapped_column(Numeric(18, 6), nullable=False)
    currency: Mapped[str] = mapped_column(String(10), nullable=False, default="USD")
    
    # Cost breakdown (top services as JSON)
    cost_by_service: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    cost_by_resource_type: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    
    # Trends
    previous_period_cost: Mapped[Optional[Decimal]] = mapped_column(Numeric(18, 6), nullable=True)
    cost_change_percent: Mapped[Optional[Decimal]] = mapped_column(Numeric(8, 2), nullable=True)
    
    # Metadata
    created_at: Mapped[datetime] = mapped_column(
        DateTime, nullable=False, server_default=func.now()
    )

    __table_args__ = (
        Index("ix_summary_subscription_period", "subscription_id", "period_start"),
    )

    def __repr__(self) -> str:
        return f"<CostSummary(id={self.id}, total={self.total_cost}, period={self.period_start})>"
