"""Dashboard route — single endpoint that powers the main dashboard view."""

from datetime import date, timedelta

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.cost_data import CostData
from app.models.recommendation import Recommendation
from app.models.ai_workload import AIWorkload
from app.models.alert import Alert
from app.schemas import DashboardData, CostSummary, CostTrend, CostByDimension, RecommendationSummary, AIWorkloadSummary

router = APIRouter()


@router.get("/", response_model=DashboardData)
async def get_dashboard(
    days: int = Query(default=30, le=90),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get all dashboard data in a single call for fast UI rendering."""
    end_date = date.today()
    start_date = end_date - timedelta(days=days)
    org_id = current_user.organization_id

    # ── Cost Summary ────────────────────────────────────────────
    cost_totals = await db.execute(
        select(
            func.sum(CostData.BilledCost).label("billed"),
            func.sum(CostData.EffectiveCost).label("effective"),
        ).where(
            CostData.organization_id == org_id,
            CostData.BillingPeriodStart >= start_date,
            CostData.BillingPeriodStart <= end_date,
        )
    )
    ct = cost_totals.one()

    # Prior period
    prior_start = start_date - timedelta(days=days)
    prior_end = start_date - timedelta(days=1)
    prior = await db.execute(
        select(func.sum(CostData.BilledCost)).where(
            CostData.organization_id == org_id,
            CostData.BillingPeriodStart >= prior_start,
            CostData.BillingPeriodStart <= prior_end,
        )
    )
    prior_cost = prior.scalar() or 0
    current_cost = ct.billed or 0
    change_pct = round(((current_cost - prior_cost) / prior_cost) * 100, 1) if prior_cost > 0 else None

    cost_summary = CostSummary(
        total_billed_cost=round(current_cost, 2),
        total_effective_cost=round(ct.effective or 0, 2),
        period_start=start_date,
        period_end=end_date,
        cost_change_percent=change_pct,
    )

    # ── Cost Trend ──────────────────────────────────────────────
    trend_result = await db.execute(
        select(
            CostData.BillingPeriodStart,
            func.sum(CostData.BilledCost).label("billed"),
            func.sum(CostData.EffectiveCost).label("effective"),
        )
        .where(
            CostData.organization_id == org_id,
            CostData.BillingPeriodStart >= start_date,
            CostData.BillingPeriodStart <= end_date,
        )
        .group_by(CostData.BillingPeriodStart)
        .order_by(CostData.BillingPeriodStart)
    )
    cost_trend = [
        CostTrend(date=r.BillingPeriodStart, billed_cost=round(r.billed, 2), effective_cost=round(r.effective, 2))
        for r in trend_result.all()
    ]

    # ── Top Services ────────────────────────────────────────────
    svc_result = await db.execute(
        select(CostData.ServiceName, func.sum(CostData.BilledCost).label("cost"))
        .where(CostData.organization_id == org_id, CostData.BillingPeriodStart >= start_date)
        .group_by(CostData.ServiceName)
        .order_by(func.sum(CostData.BilledCost).desc())
        .limit(8)
    )
    svcs = svc_result.all()
    svc_total = sum(s.cost or 0 for s in svcs)
    top_services = [
        CostByDimension(
            dimension="service", value=s.ServiceName or "Unknown",
            billed_cost=round(s.cost, 2), effective_cost=0,
            percent_of_total=round((s.cost / svc_total) * 100, 1) if svc_total > 0 else 0,
        )
        for s in svcs
    ]

    # ── Top Resources ───────────────────────────────────────────
    res_result = await db.execute(
        select(
            CostData.ResourceName, CostData.ResourceType, CostData.ServiceName,
            func.sum(CostData.BilledCost).label("cost"),
        )
        .where(CostData.organization_id == org_id, CostData.BillingPeriodStart >= start_date)
        .group_by(CostData.ResourceName, CostData.ResourceType, CostData.ServiceName)
        .order_by(func.sum(CostData.BilledCost).desc())
        .limit(10)
    )
    top_resources = [
        {"name": r.ResourceName, "type": r.ResourceType, "service": r.ServiceName, "cost": round(r.cost, 2)}
        for r in res_result.all()
    ]

    # ── Recommendation Summary ──────────────────────────────────
    rec_totals = await db.execute(
        select(
            func.count(Recommendation.id),
            func.coalesce(func.sum(Recommendation.estimated_monthly_savings), 0),
            func.coalesce(func.sum(Recommendation.estimated_annual_savings), 0),
        ).where(Recommendation.organization_id == org_id, Recommendation.status == "open")
    )
    rt = rec_totals.one()
    rec_summary = RecommendationSummary(
        total_open=rt[0], total_monthly_savings=round(rt[1], 2),
        total_annual_savings=round(rt[2], 2), by_category={}, by_impact={},
    )

    # ── AI Cost Summary ─────────────────────────────────────────
    ai_totals = await db.execute(
        select(
            func.sum(AIWorkload.total_cost).label("cost"),
            func.sum(AIWorkload.total_tokens).label("tokens"),
            func.avg(AIWorkload.avg_gpu_utilization).label("gpu_util"),
        ).where(
            AIWorkload.organization_id == org_id,
            AIWorkload.period_start >= start_date,
        )
    )
    ai = ai_totals.one()
    ai_summary = AIWorkloadSummary(
        total_ai_cost=round(ai.cost or 0, 2),
        total_tokens=ai.tokens,
        avg_gpu_utilization=round(ai.gpu_util, 1) if ai.gpu_util else None,
    ) if ai.cost else None

    # ── Recent Alerts ───────────────────────────────────────────
    alert_result = await db.execute(
        select(Alert)
        .where(Alert.organization_id == org_id, Alert.is_resolved == False)
        .order_by(Alert.created_at.desc())
        .limit(5)
    )
    alerts = [
        {"id": a.id, "type": a.alert_type, "severity": a.severity, "title": a.title, "created_at": str(a.created_at)}
        for a in alert_result.scalars().all()
    ]

    return DashboardData(
        cost_summary=cost_summary,
        cost_trend=cost_trend,
        top_services=top_services,
        top_resources=top_resources,
        recommendation_summary=rec_summary,
        ai_summary=ai_summary,
        alerts=alerts,
    )
