"""Cost data ingestion and analysis service."""

import json
from datetime import datetime, timedelta
from decimal import Decimal
from typing import Any, Optional

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.logging import get_logger
from app.models.cost import CostRecord, CostSummary
from app.services.azure_client import get_azure_client

logger = get_logger(__name__)


class CostService:
    """Service for managing cost data."""

    def __init__(self, session: AsyncSession) -> None:
        """Initialize cost service."""
        self._session = session
        self._azure = get_azure_client()
        self._settings = get_settings()

    async def ingest_cost_data(
        self,
        subscription_id: Optional[str] = None,
        resource_group: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ) -> dict[str, Any]:
        """
        Ingest cost data from Azure into the database.

        Args:
            subscription_id: Target subscription
            resource_group: Optional resource group filter
            start_date: Start date for data ingestion
            end_date: End date for data ingestion

        Returns:
            Ingestion summary
        """
        subscription_id = subscription_id or self._settings.azure_subscription_id

        logger.info(
            "Starting cost data ingestion",
            subscription_id=subscription_id,
            resource_group=resource_group,
        )

        try:
            # Fetch cost data from Azure
            result = await self._azure.get_cost_data(
                subscription_id=subscription_id,
                resource_group=resource_group,
                start_date=start_date,
                end_date=end_date,
            )

            records_created = 0
            records_updated = 0

            for row in result.get("rows", []):
                # Parse the row based on expected columns
                service_name = row.get("ServiceName")
                rg = row.get("ResourceGroup") or resource_group
                resource_type = row.get("ResourceType")
                cost = Decimal(str(row.get("Cost", 0)))
                cost_usd = Decimal(str(row.get("CostUSD", cost)))
                usage_date_str = row.get("UsageDate")

                # Parse usage date
                if usage_date_str:
                    if isinstance(usage_date_str, int):
                        usage_date = datetime.strptime(str(usage_date_str), "%Y%m%d")
                    else:
                        usage_date = datetime.fromisoformat(str(usage_date_str).replace("Z", "+00:00"))
                else:
                    usage_date = datetime.utcnow()

                # Create cost record
                record = CostRecord(
                    subscription_id=subscription_id,
                    resource_group=rg,
                    service_name=service_name,
                    resource_type=resource_type,
                    cost=cost_usd,
                    currency="USD",
                    usage_date=usage_date,
                )

                self._session.add(record)
                records_created += 1

            await self._session.commit()

            logger.info(
                "Cost data ingestion completed",
                records_created=records_created,
                records_updated=records_updated,
            )

            return {
                "status": "success",
                "records_created": records_created,
                "records_updated": records_updated,
                "subscription_id": subscription_id,
            }

        except Exception as e:
            logger.error("Cost data ingestion failed", error=str(e))
            raise

    async def get_cost_summary(
        self,
        subscription_id: Optional[str] = None,
        resource_group: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
    ) -> dict[str, Any]:
        """
        Get aggregated cost summary.

        Args:
            subscription_id: Target subscription
            resource_group: Optional resource group filter
            start_date: Start date
            end_date: End date

        Returns:
            Cost summary
        """
        subscription_id = subscription_id or self._settings.azure_subscription_id

        if end_date is None:
            end_date = datetime.utcnow()
        if start_date is None:
            start_date = end_date - timedelta(days=self._settings.cost_lookback_days)

        # Build query
        query = select(
            CostRecord.service_name,
            func.sum(CostRecord.cost).label("total_cost"),
            func.count(CostRecord.id).label("record_count"),
        ).where(
            CostRecord.subscription_id == subscription_id,
            CostRecord.usage_date >= start_date,
            CostRecord.usage_date <= end_date,
        )

        if resource_group:
            query = query.where(CostRecord.resource_group == resource_group)

        query = query.group_by(CostRecord.service_name).order_by(
            func.sum(CostRecord.cost).desc()
        )

        result = await self._session.execute(query)
        rows = result.fetchall()

        # Calculate totals
        total_cost = sum(row.total_cost for row in rows)
        cost_by_service = [
            {
                "service_name": row.service_name or "Unknown",
                "total_cost": float(row.total_cost),
                "percentage": float(row.total_cost / total_cost * 100) if total_cost else 0,
            }
            for row in rows
        ]

        return {
            "subscription_id": subscription_id,
            "resource_group": resource_group,
            "period_start": start_date.isoformat(),
            "period_end": end_date.isoformat(),
            "total_cost": float(total_cost),
            "currency": "USD",
            "cost_by_service": cost_by_service,
            "service_count": len(cost_by_service),
        }

    async def get_daily_costs(
        self,
        subscription_id: Optional[str] = None,
        days: int = 30,
    ) -> list[dict[str, Any]]:
        """
        Get daily cost breakdown.

        Args:
            subscription_id: Target subscription
            days: Number of days to look back

        Returns:
            Daily cost list
        """
        subscription_id = subscription_id or self._settings.azure_subscription_id
        end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=days)

        query = select(
            func.date(CostRecord.usage_date).label("date"),
            func.sum(CostRecord.cost).label("daily_cost"),
        ).where(
            CostRecord.subscription_id == subscription_id,
            CostRecord.usage_date >= start_date,
            CostRecord.usage_date <= end_date,
        ).group_by(
            func.date(CostRecord.usage_date)
        ).order_by(
            func.date(CostRecord.usage_date)
        )

        result = await self._session.execute(query)
        rows = result.fetchall()

        return [
            {
                "date": str(row.date),
                "cost": float(row.daily_cost),
            }
            for row in rows
        ]

    async def get_top_spending_resources(
        self,
        subscription_id: Optional[str] = None,
        limit: int = 10,
        days: int = 30,
    ) -> list[dict[str, Any]]:
        """
        Get top spending resources.

        Args:
            subscription_id: Target subscription
            limit: Number of results
            days: Number of days to look back

        Returns:
            Top resources by cost
        """
        subscription_id = subscription_id or self._settings.azure_subscription_id
        end_date = datetime.utcnow()
        start_date = end_date - timedelta(days=days)

        query = select(
            CostRecord.resource_name,
            CostRecord.resource_type,
            CostRecord.resource_group,
            func.sum(CostRecord.cost).label("total_cost"),
        ).where(
            CostRecord.subscription_id == subscription_id,
            CostRecord.usage_date >= start_date,
            CostRecord.usage_date <= end_date,
            CostRecord.resource_name.isnot(None),
        ).group_by(
            CostRecord.resource_name,
            CostRecord.resource_type,
            CostRecord.resource_group,
        ).order_by(
            func.sum(CostRecord.cost).desc()
        ).limit(limit)

        result = await self._session.execute(query)
        rows = result.fetchall()

        return [
            {
                "resource_name": row.resource_name,
                "resource_type": row.resource_type,
                "resource_group": row.resource_group,
                "total_cost": float(row.total_cost),
            }
            for row in rows
        ]

    async def calculate_cost_trends(
        self,
        subscription_id: Optional[str] = None,
    ) -> dict[str, Any]:
        """
        Calculate cost trends (week-over-week, month-over-month).

        Args:
            subscription_id: Target subscription

        Returns:
            Trend analysis
        """
        subscription_id = subscription_id or self._settings.azure_subscription_id
        now = datetime.utcnow()

        # Current week
        current_week_start = now - timedelta(days=7)
        previous_week_start = current_week_start - timedelta(days=7)

        # Current month
        current_month_start = now - timedelta(days=30)
        previous_month_start = current_month_start - timedelta(days=30)

        async def get_period_cost(start: datetime, end: datetime) -> Decimal:
            query = select(func.sum(CostRecord.cost)).where(
                CostRecord.subscription_id == subscription_id,
                CostRecord.usage_date >= start,
                CostRecord.usage_date <= end,
            )
            result = await self._session.execute(query)
            return result.scalar() or Decimal(0)

        current_week_cost = await get_period_cost(current_week_start, now)
        previous_week_cost = await get_period_cost(previous_week_start, current_week_start)
        current_month_cost = await get_period_cost(current_month_start, now)
        previous_month_cost = await get_period_cost(previous_month_start, current_month_start)

        # Calculate changes
        def calc_change(current: Decimal, previous: Decimal) -> float:
            if previous == 0:
                return 100.0 if current > 0 else 0.0
            return float((current - previous) / previous * 100)

        return {
            "subscription_id": subscription_id,
            "current_week_cost": float(current_week_cost),
            "previous_week_cost": float(previous_week_cost),
            "week_over_week_change": calc_change(current_week_cost, previous_week_cost),
            "current_month_cost": float(current_month_cost),
            "previous_month_cost": float(previous_month_cost),
            "month_over_month_change": calc_change(current_month_cost, previous_month_cost),
        }
