"""Budget management and alerting service."""

from datetime import datetime
from decimal import Decimal
from typing import Any, Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.config import get_settings
from app.core.logging import get_logger
from app.models.budget import AlertSeverity, Budget, BudgetAlert, BudgetTimeGrain
from app.services.cost_service import CostService
from app.services.notification_service import get_notification_service

logger = get_logger(__name__)


class BudgetService:
    """Service for budget management and alerts."""

    def __init__(self, session: AsyncSession) -> None:
        """Initialize budget service."""
        self._session = session
        self._settings = get_settings()

    async def create_budget(
        self,
        name: str,
        amount: Decimal,
        subscription_id: Optional[str] = None,
        resource_group: Optional[str] = None,
        time_grain: BudgetTimeGrain = BudgetTimeGrain.MONTHLY,
        alert_thresholds: str = "50,80,100",
        description: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ) -> Budget:
        """
        Create a new budget.

        Args:
            name: Budget name
            amount: Budget amount
            subscription_id: Target subscription
            resource_group: Optional resource group
            time_grain: Time granularity
            alert_thresholds: Comma-separated threshold percentages
            description: Optional description
            start_date: Budget start date
            end_date: Budget end date

        Returns:
            Created budget
        """
        subscription_id = subscription_id or self._settings.azure_subscription_id

        if start_date is None:
            start_date = datetime.utcnow()

        budget = Budget(
            name=name,
            description=description,
            subscription_id=subscription_id,
            resource_group=resource_group,
            amount=amount,
            time_grain=time_grain,
            alert_thresholds=alert_thresholds,
            start_date=start_date,
            end_date=end_date,
        )

        self._session.add(budget)
        await self._session.commit()
        await self._session.refresh(budget)

        logger.info(
            "Budget created",
            budget_id=budget.id,
            name=budget.name,
            amount=float(budget.amount),
        )

        return budget

    async def get_budget(self, budget_id: int) -> Optional[Budget]:
        """Get budget by ID."""
        query = select(Budget).where(Budget.id == budget_id).options(
            selectinload(Budget.alerts)
        )
        result = await self._session.execute(query)
        return result.scalar_one_or_none()

    async def list_budgets(
        self,
        subscription_id: Optional[str] = None,
        active_only: bool = True,
    ) -> list[Budget]:
        """List budgets for a subscription."""
        subscription_id = subscription_id or self._settings.azure_subscription_id

        query = select(Budget).where(
            Budget.subscription_id == subscription_id
        ).options(selectinload(Budget.alerts))

        if active_only:
            query = query.where(Budget.is_active == True)

        query = query.order_by(Budget.created_at.desc())

        result = await self._session.execute(query)
        return list(result.scalars().all())

    async def update_budget(
        self,
        budget_id: int,
        **updates: Any,
    ) -> Optional[Budget]:
        """Update budget properties."""
        budget = await self.get_budget(budget_id)
        if not budget:
            return None

        allowed_fields = {
            "name", "description", "amount", "time_grain",
            "alert_thresholds", "is_active", "end_date"
        }

        for field, value in updates.items():
            if field in allowed_fields:
                setattr(budget, field, value)

        await self._session.commit()
        await self._session.refresh(budget)

        logger.info("Budget updated", budget_id=budget_id, updates=list(updates.keys()))
        return budget

    async def delete_budget(self, budget_id: int) -> bool:
        """Delete a budget."""
        budget = await self.get_budget(budget_id)
        if not budget:
            return False

        await self._session.delete(budget)
        await self._session.commit()

        logger.info("Budget deleted", budget_id=budget_id)
        return True

    async def check_budget_thresholds(
        self,
        budget_id: int,
    ) -> list[BudgetAlert]:
        """
        Check budget against thresholds and create alerts.

        Args:
            budget_id: Budget to check

        Returns:
            List of new alerts created
        """
        budget = await self.get_budget(budget_id)
        if not budget or not budget.is_active:
            return []

        # Calculate current spend using cost service
        cost_service = CostService(self._session)
        summary = await cost_service.get_cost_summary(
            subscription_id=budget.subscription_id,
            resource_group=budget.resource_group,
            start_date=budget.start_date,
            end_date=datetime.utcnow(),
        )

        current_spend = Decimal(str(summary["total_cost"]))
        spend_percentage = (current_spend / budget.amount * 100) if budget.amount > 0 else Decimal(0)

        # Update budget tracking
        budget.current_spend = current_spend
        budget.spend_percentage = spend_percentage

        # Check thresholds
        new_alerts = []
        thresholds = budget.thresholds_list

        for threshold in thresholds:
            if spend_percentage >= threshold:
                # Check if we already have an alert for this threshold
                existing_query = select(BudgetAlert).where(
                    BudgetAlert.budget_id == budget_id,
                    BudgetAlert.threshold_percent == threshold,
                )
                existing = await self._session.execute(existing_query)
                if existing.scalar_one_or_none():
                    continue

                # Determine severity
                if threshold >= 100:
                    severity = AlertSeverity.CRITICAL
                elif threshold >= 80:
                    severity = AlertSeverity.WARNING
                else:
                    severity = AlertSeverity.INFO

                # Create alert
                alert = BudgetAlert(
                    budget_id=budget_id,
                    threshold_percent=threshold,
                    actual_percent=spend_percentage,
                    actual_amount=current_spend,
                    severity=severity,
                    message=f"Budget '{budget.name}' has reached {spend_percentage:.1f}% "
                            f"(${current_spend:.2f} of ${budget.amount:.2f})",
                )
                self._session.add(alert)
                new_alerts.append(alert)

                logger.warning(
                    "Budget threshold exceeded",
                    budget_id=budget_id,
                    threshold=threshold,
                    actual=float(spend_percentage),
                    severity=severity.value,
                )

        await self._session.commit()
        
        # Send notifications for new alerts
        if new_alerts and self._settings.notifications_enabled:
            await self._send_alert_notifications(budget, new_alerts)
        
        return new_alerts
    
    async def _send_alert_notifications(
        self,
        budget: Budget,
        alerts: list[BudgetAlert],
    ) -> None:
        """
        Send notifications for budget alerts.
        
        Args:
            budget: The budget that triggered alerts
            alerts: List of new alerts to notify about
        """
        notification_service = get_notification_service()
        
        for alert in alerts:
            try:
                results = await notification_service.send_budget_alert(
                    budget_id=budget.id,
                    budget_name=budget.name,
                    threshold_percent=alert.threshold_percent,
                    actual_percent=float(alert.actual_percent),
                    actual_amount=float(alert.actual_amount),
                    budget_amount=float(budget.amount),
                    currency=budget.currency,
                )
                
                # Log notification results
                for channel, success in results.items():
                    if success:
                        logger.info(
                            "Budget alert notification sent",
                            budget_id=budget.id,
                            alert_id=alert.id,
                            channel=channel.value,
                        )
                    else:
                        logger.warning(
                            "Budget alert notification failed",
                            budget_id=budget.id,
                            alert_id=alert.id,
                            channel=channel.value,
                        )
                        
            except Exception as e:
                # Don't fail budget operations if notification fails
                logger.error(
                    "Failed to send budget alert notification",
                    budget_id=budget.id,
                    alert_id=alert.id,
                    error=str(e),
                )

    async def acknowledge_alert(
        self,
        alert_id: int,
        acknowledged_by: str,
    ) -> Optional[BudgetAlert]:
        """Acknowledge a budget alert."""
        query = select(BudgetAlert).where(BudgetAlert.id == alert_id)
        result = await self._session.execute(query)
        alert = result.scalar_one_or_none()

        if not alert:
            return None

        alert.is_acknowledged = True
        alert.acknowledged_at = datetime.utcnow()
        alert.acknowledged_by = acknowledged_by

        await self._session.commit()
        await self._session.refresh(alert)

        logger.info("Alert acknowledged", alert_id=alert_id, by=acknowledged_by)
        return alert

    async def get_unacknowledged_alerts(
        self,
        subscription_id: Optional[str] = None,
    ) -> list[BudgetAlert]:
        """Get all unacknowledged alerts."""
        subscription_id = subscription_id or self._settings.azure_subscription_id

        query = (
            select(BudgetAlert)
            .join(Budget)
            .where(
                Budget.subscription_id == subscription_id,
                BudgetAlert.is_acknowledged == False,
            )
            .order_by(BudgetAlert.created_at.desc())
        )

        result = await self._session.execute(query)
        return list(result.scalars().all())
