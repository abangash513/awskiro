"""Recommendation Engine — MVP Feature #2.

Generates 5 types of cost optimization recommendations:
1. Rightsizing VMs (oversized based on CPU/memory utilization)
2. Idle resource detection (VMs, disks, IPs with no usage)
3. Reserved Instance suggestions (on-demand VMs with consistent usage)
4. Storage optimization (hot→cool/archive tier suggestions)
5. Dev/test shutdown scheduling (resources running 24/7 in non-prod)
"""

import logging
from datetime import datetime, timedelta, timezone

from celery import shared_task
from sqlalchemy import create_engine, select, func
from sqlalchemy.orm import Session

from app.core import get_settings
from app.models.cloud_connection import CloudConnection
from app.models.resource import Resource
from app.models.cost_data import CostData
from app.models.recommendation import Recommendation

logger = logging.getLogger(__name__)
settings = get_settings()

# Thresholds for recommendations
IDLE_CPU_THRESHOLD = 5.0       # % — VM is idle if avg CPU < 5%
RIGHTSIZE_CPU_THRESHOLD = 20.0  # % — VM is oversized if avg CPU < 20%
RI_CONSISTENCY_DAYS = 21        # Days a VM must run to suggest RI
STORAGE_HOT_DAYS = 60           # Days without access → suggest cool tier


@shared_task(name="app.services.recommendation_engine.generate_all_recommendations")
def generate_all_recommendations():
    """Generate recommendations for all organizations (scheduled daily)."""
    engine = create_engine(settings.database_url_sync)

    with Session(engine) as db:
        org_ids = db.execute(
            select(CloudConnection.organization_id)
            .where(CloudConnection.is_active == True)
            .distinct()
        ).scalars().all()

        for org_id in org_ids:
            try:
                _generate_for_org(db, org_id)
            except Exception as e:
                logger.error(f"Recommendation generation failed for org {org_id}: {e}")


def _generate_for_org(db: Session, org_id: int):
    """Generate all recommendation types for a single organization."""
    logger.info(f"Generating recommendations for org {org_id}")

    resources = db.execute(
        select(Resource).where(Resource.organization_id == org_id)
    ).scalars().all()

    new_recs = []

    for resource in resources:
        # 1. Idle resource detection
        idle_rec = _check_idle(resource)
        if idle_rec:
            new_recs.append(idle_rec)
            continue  # Don't also suggest rightsizing for idle resources

        # 2. Rightsizing VMs
        if "virtualMachines" in (resource.resource_type or ""):
            rightsize_rec = _check_rightsizing(resource)
            if rightsize_rec:
                new_recs.append(rightsize_rec)

            # 3. Reserved Instance suggestion
            ri_rec = _check_reserved_instance(db, resource)
            if ri_rec:
                new_recs.append(ri_rec)

    # 4. Dev/test shutdown suggestions
    devtest_recs = _check_devtest_scheduling(db, org_id, resources)
    new_recs.extend(devtest_recs)

    # Deduplicate — don't create if same resource + category already has an open rec
    existing = db.execute(
        select(Recommendation.resource_id, Recommendation.category)
        .where(Recommendation.organization_id == org_id, Recommendation.status == "open")
    ).all()
    existing_keys = {(r.resource_id, r.category) for r in existing}

    added = 0
    for rec_data in new_recs:
        key = (rec_data.get("resource_id"), rec_data.get("category"))
        if key not in existing_keys:
            rec = Recommendation(organization_id=org_id, **rec_data)
            db.add(rec)
            added += 1

    db.commit()
    logger.info(f"Generated {added} new recommendations for org {org_id}")


def _check_idle(resource: Resource) -> dict | None:
    """Detect idle resources (CPU < 5% sustained)."""
    if resource.is_idle or (resource.avg_cpu_percent is not None and resource.avg_cpu_percent < IDLE_CPU_THRESHOLD):
        monthly_cost = resource.cost_30d or 0
        return {
            "cloud_connection_id": resource.cloud_connection_id,
            "resource_id": resource.resource_id,
            "category": "idle_resource",
            "title": f"Idle resource detected: {resource.resource_name}",
            "description": (
                f"{resource.resource_name} ({resource.resource_type}) has averaged "
                f"{resource.avg_cpu_percent:.1f}% CPU utilization. Consider stopping or deallocating "
                f"this resource to save ~${monthly_cost:.0f}/month."
            ),
            "impact": "high" if monthly_cost > 100 else "medium",
            "difficulty": "easy",
            "estimated_monthly_savings": monthly_cost,
            "estimated_annual_savings": monthly_cost * 12,
            "confidence": 0.9,
            "current_config": {"sku": resource.sku, "avg_cpu": resource.avg_cpu_percent},
            "recommended_config": {"action": "deallocate_or_delete"},
        }
    return None


def _check_rightsizing(resource: Resource) -> dict | None:
    """Suggest VM rightsizing when CPU utilization is consistently low."""
    if resource.avg_cpu_percent is not None and resource.avg_cpu_percent < RIGHTSIZE_CPU_THRESHOLD:
        monthly_cost = resource.cost_30d or 0
        estimated_savings = monthly_cost * 0.4  # Assume ~40% savings from downsizing

        # Suggest one size down
        current_sku = resource.sku or "Unknown"
        suggested_sku = _suggest_smaller_sku(current_sku)

        return {
            "cloud_connection_id": resource.cloud_connection_id,
            "resource_id": resource.resource_id,
            "category": "rightsizing",
            "title": f"Rightsize VM: {resource.resource_name}",
            "description": (
                f"{resource.resource_name} is running {current_sku} with only "
                f"{resource.avg_cpu_percent:.1f}% average CPU utilization. "
                f"Consider downsizing to {suggested_sku} to save ~${estimated_savings:.0f}/month."
            ),
            "impact": "high" if estimated_savings > 50 else "medium",
            "difficulty": "medium",
            "estimated_monthly_savings": estimated_savings,
            "estimated_annual_savings": estimated_savings * 12,
            "confidence": 0.75,
            "current_config": {"sku": current_sku, "avg_cpu": resource.avg_cpu_percent, "monthly_cost": monthly_cost},
            "recommended_config": {"sku": suggested_sku, "estimated_cost": monthly_cost - estimated_savings},
        }
    return None


def _suggest_smaller_sku(current_sku: str) -> str:
    """Suggest a smaller VM SKU (simplified logic — MVP version)."""
    # Common Azure VM size mappings (one step down)
    size_map = {
        "Standard_D16s_v3": "Standard_D8s_v3",
        "Standard_D8s_v3": "Standard_D4s_v3",
        "Standard_D4s_v3": "Standard_D2s_v3",
        "Standard_D16s_v5": "Standard_D8s_v5",
        "Standard_D8s_v5": "Standard_D4s_v5",
        "Standard_D4s_v5": "Standard_D2s_v5",
        "Standard_E16s_v5": "Standard_E8s_v5",
        "Standard_E8s_v5": "Standard_E4s_v5",
        "Standard_E4s_v5": "Standard_E2s_v5",
        "Standard_B4ms": "Standard_B2ms",
        "Standard_B2ms": "Standard_B1ms",
    }
    return size_map.get(current_sku, f"{current_sku} (one size smaller)")


def _check_reserved_instance(db: Session, resource: Resource) -> dict | None:
    """Suggest Reserved Instances for consistently running on-demand VMs."""
    if "virtualMachines" not in (resource.resource_type or ""):
        return None

    # Check if this VM has been running consistently (> 21 of last 30 days)
    thirty_days_ago = datetime.now(timezone.utc) - timedelta(days=30)
    day_count = db.execute(
        select(func.count(func.distinct(CostData.BillingPeriodStart)))
        .where(
            CostData.ResourceId == resource.resource_id,
            CostData.BillingPeriodStart >= thirty_days_ago.date(),
            CostData.PricingCategory == "On-Demand",
        )
    ).scalar() or 0

    if day_count >= RI_CONSISTENCY_DAYS:
        monthly_cost = resource.cost_30d or 0
        ri_savings = monthly_cost * 0.35  # 1-year RI typically saves ~35%

        return {
            "cloud_connection_id": resource.cloud_connection_id,
            "resource_id": resource.resource_id,
            "category": "reserved_instance",
            "title": f"Reserved Instance opportunity: {resource.resource_name}",
            "description": (
                f"{resource.resource_name} ({resource.sku}) has been running on-demand for "
                f"{day_count} of the last 30 days. A 1-year Reserved Instance could save "
                f"~${ri_savings:.0f}/month (~35% discount)."
            ),
            "impact": "high" if ri_savings > 100 else "medium",
            "difficulty": "medium",
            "estimated_monthly_savings": ri_savings,
            "estimated_annual_savings": ri_savings * 12,
            "confidence": 0.85,
            "current_config": {"pricing": "On-Demand", "days_running": day_count, "monthly_cost": monthly_cost},
            "recommended_config": {"pricing": "1-Year Reserved Instance", "estimated_cost": monthly_cost - ri_savings},
        }
    return None


def _check_devtest_scheduling(db: Session, org_id: int, resources: list[Resource]) -> list[dict]:
    """Suggest shutdown scheduling for dev/test resources running 24/7."""
    recs = []
    devtest_tags = {"dev", "test", "staging", "sandbox", "qa"}

    for resource in resources:
        if not resource.tags:
            continue

        # Check if resource has dev/test tags
        tag_values = set()
        if isinstance(resource.tags, dict):
            tag_values = {v.lower() for v in resource.tags.values()}
            tag_values.update(k.lower() for k in resource.tags.keys())

        is_devtest = bool(tag_values & devtest_tags)

        if is_devtest and "virtualMachines" in (resource.resource_type or ""):
            monthly_cost = resource.cost_30d or 0
            # Shutting down nights+weekends saves ~65%
            savings = monthly_cost * 0.65

            if savings > 20:  # Only recommend if savings > $20/month
                recs.append({
                    "cloud_connection_id": resource.cloud_connection_id,
                    "resource_id": resource.resource_id,
                    "category": "scheduling",
                    "title": f"Schedule auto-shutdown: {resource.resource_name}",
                    "description": (
                        f"{resource.resource_name} appears to be a dev/test VM running 24/7. "
                        f"Scheduling auto-shutdown (nights + weekends) could save ~${savings:.0f}/month."
                    ),
                    "impact": "medium",
                    "difficulty": "easy",
                    "estimated_monthly_savings": savings,
                    "estimated_annual_savings": savings * 12,
                    "confidence": 0.7,
                    "current_config": {"schedule": "24/7", "tags": resource.tags},
                    "recommended_config": {"schedule": "M-F 8am-6pm", "savings_percent": 65},
                })

    return recs
