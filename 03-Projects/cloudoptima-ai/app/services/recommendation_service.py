"""Cost optimization recommendation service."""

from datetime import datetime, timedelta
from decimal import Decimal
from typing import Any, Optional

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.core.logging import get_logger
from app.models.recommendation import (
    Recommendation,
    RecommendationCategory,
    RecommendationImpact,
    RecommendationStatus,
)
from app.models.cost import CostRecord

logger = get_logger(__name__)


class RecommendationService:
    """Service for generating and managing cost recommendations."""

    def __init__(self, session: AsyncSession) -> None:
        """Initialize recommendation service."""
        self._session = session
        self._settings = get_settings()

    async def generate_recommendations(
        self,
        subscription_id: Optional[str] = None,
    ) -> list[Recommendation]:
        """
        Analyze costs and generate optimization recommendations.

        Args:
            subscription_id: Target subscription

        Returns:
            List of generated recommendations
        """
        subscription_id = subscription_id or self._settings.azure_subscription_id

        logger.info("Generating recommendations", subscription_id=subscription_id)

        recommendations = []

        # Analyze idle/unused resources
        idle_recs = await self._analyze_idle_resources(subscription_id)
        recommendations.extend(idle_recs)

        # Analyze rightsizing opportunities
        rightsize_recs = await self._analyze_rightsizing(subscription_id)
        recommendations.extend(rightsize_recs)

        # Analyze reserved instance opportunities
        ri_recs = await self._analyze_reserved_instances(subscription_id)
        recommendations.extend(ri_recs)

        # Persist recommendations
        for rec in recommendations:
            self._session.add(rec)

        await self._session.commit()

        logger.info(
            "Recommendations generated",
            count=len(recommendations),
            subscription_id=subscription_id,
        )

        return recommendations

    async def _analyze_idle_resources(
        self,
        subscription_id: str,
    ) -> list[Recommendation]:
        """Identify potentially idle resources based on cost patterns."""
        recommendations = []
        now = datetime.utcnow()
        threshold_date = now - timedelta(days=30)

        # Find resources with consistent low utilization
        # (In practice, this would integrate with Azure Monitor metrics)
        query = select(
            CostRecord.resource_name,
            CostRecord.resource_type,
            CostRecord.resource_group,
            func.sum(CostRecord.cost).label("total_cost"),
            func.count(CostRecord.id).label("day_count"),
        ).where(
            CostRecord.subscription_id == subscription_id,
            CostRecord.usage_date >= threshold_date,
            CostRecord.resource_name.isnot(None),
        ).group_by(
            CostRecord.resource_name,
            CostRecord.resource_type,
            CostRecord.resource_group,
        ).having(
            func.sum(CostRecord.cost) > 0
        ).order_by(func.sum(CostRecord.cost).desc()).limit(20)

        result = await self._session.execute(query)
        resources = result.fetchall()

        # Look for VM-related resources that might be idle
        for resource in resources:
            if resource.resource_type and "virtualMachines" in resource.resource_type.lower():
                # Check if this is a candidate for rightsizing/shutdown
                monthly_cost = float(resource.total_cost)
                
                if monthly_cost > 50:  # Minimum threshold
                    rec = Recommendation(
                        subscription_id=subscription_id,
                        resource_group=resource.resource_group,
                        resource_name=resource.resource_name,
                        resource_type=resource.resource_type,
                        title=f"Review VM '{resource.resource_name}' for idle/shutdown",
                        description=(
                            f"This VM has consistent costs of ${monthly_cost:.2f}/month. "
                            "Review utilization metrics to determine if it can be shut down "
                            "during off-hours or deallocated when not in use."
                        ),
                        category=RecommendationCategory.IDLE_RESOURCES,
                        impact=RecommendationImpact.MEDIUM if monthly_cost > 100 else RecommendationImpact.LOW,
                        estimated_monthly_savings=Decimal(str(monthly_cost * 0.3)),  # Assume 30% savings
                        estimated_annual_savings=Decimal(str(monthly_cost * 0.3 * 12)),
                        implementation_effort="low",
                        implementation_steps=(
                            "1. Review Azure Monitor CPU/Memory metrics\n"
                            "2. Identify off-peak hours\n"
                            "3. Set up auto-shutdown schedule\n"
                            "4. Consider Azure Reserved VM Instances for always-on VMs"
                        ),
                        valid_from=now,
                        valid_until=now + timedelta(days=90),
                    )
                    recommendations.append(rec)

        return recommendations[:5]  # Limit to top 5

    async def _analyze_rightsizing(
        self,
        subscription_id: str,
    ) -> list[Recommendation]:
        """Analyze resources for rightsizing opportunities."""
        recommendations = []
        now = datetime.utcnow()

        # Query high-cost resources by type
        query = select(
            CostRecord.resource_type,
            func.sum(CostRecord.cost).label("total_cost"),
            func.count(func.distinct(CostRecord.resource_name)).label("resource_count"),
        ).where(
            CostRecord.subscription_id == subscription_id,
            CostRecord.usage_date >= now - timedelta(days=30),
            CostRecord.resource_type.isnot(None),
        ).group_by(
            CostRecord.resource_type
        ).having(
            func.sum(CostRecord.cost) > 100
        ).order_by(func.sum(CostRecord.cost).desc()).limit(10)

        result = await self._session.execute(query)
        resource_types = result.fetchall()

        for rt in resource_types:
            if "storageAccounts" in (rt.resource_type or "").lower():
                monthly_cost = float(rt.total_cost)
                rec = Recommendation(
                    subscription_id=subscription_id,
                    resource_type=rt.resource_type,
                    title=f"Optimize storage tier for {rt.resource_count} storage accounts",
                    description=(
                        f"Review {rt.resource_count} storage account(s) spending "
                        f"${monthly_cost:.2f}/month. Consider moving infrequently accessed "
                        "data to Cool or Archive tiers."
                    ),
                    category=RecommendationCategory.STORAGE_OPTIMIZATION,
                    impact=RecommendationImpact.MEDIUM,
                    estimated_monthly_savings=Decimal(str(monthly_cost * 0.4)),
                    estimated_annual_savings=Decimal(str(monthly_cost * 0.4 * 12)),
                    implementation_effort="medium",
                    implementation_steps=(
                        "1. Analyze blob access patterns using Storage Analytics\n"
                        "2. Identify candidates for Cool/Archive tier\n"
                        "3. Set up lifecycle management policies\n"
                        "4. Monitor access tier transitions"
                    ),
                    valid_from=now,
                    valid_until=now + timedelta(days=90),
                )
                recommendations.append(rec)

        return recommendations[:3]

    async def _analyze_reserved_instances(
        self,
        subscription_id: str,
    ) -> list[Recommendation]:
        """Identify reserved instance opportunities."""
        recommendations = []
        now = datetime.utcnow()

        # Find consistently running compute resources
        query = select(
            CostRecord.service_name,
            func.sum(CostRecord.cost).label("total_cost"),
            func.count(func.distinct(func.date(CostRecord.usage_date))).label("active_days"),
        ).where(
            CostRecord.subscription_id == subscription_id,
            CostRecord.usage_date >= now - timedelta(days=30),
            CostRecord.service_name.isnot(None),
        ).group_by(
            CostRecord.service_name
        ).having(
            func.sum(CostRecord.cost) > 500
        ).order_by(func.sum(CostRecord.cost).desc())

        result = await self._session.execute(query)
        services = result.fetchall()

        for service in services:
            if service.service_name and "virtual machines" in service.service_name.lower():
                monthly_cost = float(service.total_cost)
                active_days = service.active_days

                # If running most days, recommend RI
                if active_days >= 25:
                    rec = Recommendation(
                        subscription_id=subscription_id,
                        title="Consider Azure Reserved VM Instances",
                        description=(
                            f"Your VM workloads cost ${monthly_cost:.2f}/month with "
                            f"{active_days} active days. Reserved Instances could save "
                            "up to 72% compared to pay-as-you-go pricing."
                        ),
                        category=RecommendationCategory.RESERVED_INSTANCES,
                        impact=RecommendationImpact.HIGH,
                        estimated_monthly_savings=Decimal(str(monthly_cost * 0.4)),  # ~40% savings
                        estimated_annual_savings=Decimal(str(monthly_cost * 0.4 * 12)),
                        implementation_effort="medium",
                        implementation_steps=(
                            "1. Review Azure Advisor RI recommendations\n"
                            "2. Analyze VM size and region requirements\n"
                            "3. Compare 1-year vs 3-year commitment savings\n"
                            "4. Purchase RIs through Azure portal or API\n"
                            "5. Monitor RI utilization regularly"
                        ),
                        risk_level="medium",
                        valid_from=now,
                        valid_until=now + timedelta(days=90),
                    )
                    recommendations.append(rec)

        return recommendations[:2]

    async def get_recommendation(self, recommendation_id: int) -> Optional[Recommendation]:
        """Get recommendation by ID."""
        query = select(Recommendation).where(Recommendation.id == recommendation_id)
        result = await self._session.execute(query)
        return result.scalar_one_or_none()

    async def list_recommendations(
        self,
        subscription_id: Optional[str] = None,
        category: Optional[RecommendationCategory] = None,
        status: Optional[RecommendationStatus] = None,
        min_savings: Optional[float] = None,
    ) -> list[Recommendation]:
        """List recommendations with filters."""
        subscription_id = subscription_id or self._settings.azure_subscription_id

        query = select(Recommendation).where(
            Recommendation.subscription_id == subscription_id,
            Recommendation.is_stale == False,
        )

        if category:
            query = query.where(Recommendation.category == category)
        if status:
            query = query.where(Recommendation.status == status)
        if min_savings:
            query = query.where(
                Recommendation.estimated_monthly_savings >= Decimal(str(min_savings))
            )

        query = query.order_by(Recommendation.estimated_monthly_savings.desc())

        result = await self._session.execute(query)
        return list(result.scalars().all())

    async def update_recommendation_status(
        self,
        recommendation_id: int,
        status: RecommendationStatus,
        changed_by: str,
        rejection_reason: Optional[str] = None,
    ) -> Optional[Recommendation]:
        """Update recommendation status."""
        rec = await self.get_recommendation(recommendation_id)
        if not rec:
            return None

        rec.status = status
        rec.status_changed_at = datetime.utcnow()
        rec.status_changed_by = changed_by

        if status == RecommendationStatus.REJECTED and rejection_reason:
            rec.rejection_reason = rejection_reason

        await self._session.commit()
        await self._session.refresh(rec)

        logger.info(
            "Recommendation status updated",
            recommendation_id=recommendation_id,
            status=status.value,
        )

        return rec

    async def get_savings_summary(
        self,
        subscription_id: Optional[str] = None,
    ) -> dict[str, Any]:
        """Get summary of potential savings from recommendations."""
        subscription_id = subscription_id or self._settings.azure_subscription_id

        query = select(
            Recommendation.status,
            Recommendation.category,
            func.sum(Recommendation.estimated_monthly_savings).label("monthly_savings"),
            func.count(Recommendation.id).label("count"),
        ).where(
            Recommendation.subscription_id == subscription_id,
            Recommendation.is_stale == False,
        ).group_by(
            Recommendation.status,
            Recommendation.category,
        )

        result = await self._session.execute(query)
        rows = result.fetchall()

        total_potential = Decimal(0)
        total_accepted = Decimal(0)
        total_implemented = Decimal(0)
        by_category = {}
        by_status = {}

        for row in rows:
            savings = row.monthly_savings or Decimal(0)
            status = row.status.value if row.status else "unknown"
            category = row.category.value if row.category else "unknown"

            # Totals by status
            if status == "new" or status == "in_review":
                total_potential += savings
            elif status == "accepted":
                total_accepted += savings
            elif status == "implemented":
                total_implemented += savings

            # Group by category
            if category not in by_category:
                by_category[category] = {"count": 0, "monthly_savings": 0}
            by_category[category]["count"] += row.count
            by_category[category]["monthly_savings"] += float(savings)

            # Group by status
            if status not in by_status:
                by_status[status] = {"count": 0, "monthly_savings": 0}
            by_status[status]["count"] += row.count
            by_status[status]["monthly_savings"] += float(savings)

        return {
            "subscription_id": subscription_id,
            "total_potential_monthly_savings": float(total_potential),
            "total_accepted_monthly_savings": float(total_accepted),
            "total_implemented_monthly_savings": float(total_implemented),
            "by_category": by_category,
            "by_status": by_status,
        }
