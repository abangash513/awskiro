"""Budget and alert database models."""

from datetime import datetime
from decimal import Decimal
from enum import Enum
from typing import Optional

from sqlalchemy import Boolean, DateTime, Enum as SQLEnum, ForeignKey, Numeric, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class BudgetTimeGrain(str, Enum):
    """Budget time granularity."""
    MONTHLY = "monthly"
    QUARTERLY = "quarterly"
    ANNUALLY = "annually"


class AlertSeverity(str, Enum):
    """Alert severity levels."""
    INFO = "info"
    WARNING = "warning"
    CRITICAL = "critical"


class Budget(Base):
    """Budget configuration and tracking."""

    __tablename__ = "budgets"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    
    # Scope
    subscription_id: Mapped[str] = mapped_column(String(36), nullable=False, index=True)
    resource_group: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    
    # Budget settings
    amount: Mapped[Decimal] = mapped_column(Numeric(18, 2), nullable=False)
    currency: Mapped[str] = mapped_column(String(10), nullable=False, default="USD")
    time_grain: Mapped[BudgetTimeGrain] = mapped_column(
        SQLEnum(BudgetTimeGrain), nullable=False, default=BudgetTimeGrain.MONTHLY
    )
    
    # Alert thresholds (comma-separated percentages, e.g., "50,80,100")
    alert_thresholds: Mapped[str] = mapped_column(
        String(100), nullable=False, default="50,80,100"
    )
    
    # Current spend tracking
    current_spend: Mapped[Decimal] = mapped_column(
        Numeric(18, 2), nullable=False, default=Decimal("0")
    )
    spend_percentage: Mapped[Decimal] = mapped_column(
        Numeric(5, 2), nullable=False, default=Decimal("0")
    )
    
    # Time bounds
    start_date: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    end_date: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    
    # Status
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    
    # Metadata
    created_at: Mapped[datetime] = mapped_column(
        DateTime, nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, nullable=False, server_default=func.now(), onupdate=func.now()
    )

    # Relationships
    alerts: Mapped[list["BudgetAlert"]] = relationship(
        "BudgetAlert", back_populates="budget", cascade="all, delete-orphan"
    )

    def __repr__(self) -> str:
        return f"<Budget(id={self.id}, name={self.name}, amount={self.amount})>"

    @property
    def thresholds_list(self) -> list[int]:
        """Get alert thresholds as a list of integers."""
        return [int(t) for t in self.alert_thresholds.split(",")]


class BudgetAlert(Base):
    """Budget alert records."""

    __tablename__ = "budget_alerts"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    budget_id: Mapped[int] = mapped_column(
        ForeignKey("budgets.id", ondelete="CASCADE"), nullable=False, index=True
    )
    
    # Alert details
    threshold_percent: Mapped[int] = mapped_column(nullable=False)
    actual_percent: Mapped[Decimal] = mapped_column(Numeric(5, 2), nullable=False)
    actual_amount: Mapped[Decimal] = mapped_column(Numeric(18, 2), nullable=False)
    severity: Mapped[AlertSeverity] = mapped_column(
        SQLEnum(AlertSeverity), nullable=False
    )
    
    # Message
    message: Mapped[str] = mapped_column(Text, nullable=False)
    
    # Status
    is_acknowledged: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    acknowledged_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    acknowledged_by: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    
    # Metadata
    created_at: Mapped[datetime] = mapped_column(
        DateTime, nullable=False, server_default=func.now()
    )

    # Relationships
    budget: Mapped["Budget"] = relationship("Budget", back_populates="alerts")

    def __repr__(self) -> str:
        return f"<BudgetAlert(id={self.id}, threshold={self.threshold_percent}%)>"
