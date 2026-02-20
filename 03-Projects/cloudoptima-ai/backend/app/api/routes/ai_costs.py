"""AI Cost Intelligence routes — MVP Feature #3 (the differentiator).

Tracks Azure OpenAI, Cognitive Services, Azure ML, and GPU VM costs
with purpose-built metrics no other Azure FinOps tool provides.
"""

from datetime import date, timedelta

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.ai_workload import AIWorkload
from app.schemas import AIWorkloadSummary, AIWorkloadResponse

router = APIRouter()


@router.get("/summary", response_model=AIWorkloadSummary)
async def get_ai_cost_summary(
    start_date: date = Query(default=None),
    end_date: date = Query(default=None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get AI/ML cost summary — total spend, tokens, GPU hours, utilization."""
    if not end_date:
        end_date = date.today()
    if not start_date:
        start_date = end_date - timedelta(days=30)

    # Current period
    query = (
        select(
            func.sum(AIWorkload.total_cost).label("total_cost"),
            func.sum(AIWorkload.total_tokens).label("total_tokens"),
            func.sum(AIWorkload.gpu_hours).label("total_gpu_hours"),
            func.avg(AIWorkload.avg_gpu_utilization).label("avg_gpu_util"),
            func.avg(AIWorkload.cost_per_1k_tokens).label("avg_cost_per_1k"),
        )
        .where(
            AIWorkload.organization_id == current_user.organization_id,
            AIWorkload.period_start >= start_date,
            AIWorkload.period_start <= end_date,
        )
    )
    result = await db.execute(query)
    r = result.one()

    # Prior period for change %
    period_days = (end_date - start_date).days
    prior_start = start_date - timedelta(days=period_days)
    prior_end = start_date - timedelta(days=1)
    prior = await db.execute(
        select(func.sum(AIWorkload.total_cost))
        .where(
            AIWorkload.organization_id == current_user.organization_id,
            AIWorkload.period_start >= prior_start,
            AIWorkload.period_start <= prior_end,
        )
    )
    prior_cost = prior.scalar() or 0
    current_cost = r.total_cost or 0
    change_pct = None
    if prior_cost > 0:
        change_pct = round(((current_cost - prior_cost) / prior_cost) * 100, 1)

    # By service type
    svc_result = await db.execute(
        select(
            AIWorkload.service_type,
            func.sum(AIWorkload.total_cost).label("cost"),
            func.sum(AIWorkload.total_tokens).label("tokens"),
        )
        .where(
            AIWorkload.organization_id == current_user.organization_id,
            AIWorkload.period_start >= start_date,
            AIWorkload.period_start <= end_date,
        )
        .group_by(AIWorkload.service_type)
        .order_by(func.sum(AIWorkload.total_cost).desc())
    )
    by_service = [
        {"service_type": s.service_type, "cost": round(s.cost, 2), "tokens": s.tokens}
        for s in svc_result.all()
    ]

    # By model
    model_result = await db.execute(
        select(
            AIWorkload.model_name,
            func.sum(AIWorkload.total_cost).label("cost"),
            func.sum(AIWorkload.total_tokens).label("tokens"),
            func.avg(AIWorkload.cost_per_1k_tokens).label("cost_per_1k"),
        )
        .where(
            AIWorkload.organization_id == current_user.organization_id,
            AIWorkload.period_start >= start_date,
            AIWorkload.period_start <= end_date,
            AIWorkload.model_name.isnot(None),
        )
        .group_by(AIWorkload.model_name)
        .order_by(func.sum(AIWorkload.total_cost).desc())
    )
    by_model = [
        {
            "model": m.model_name,
            "cost": round(m.cost, 2),
            "tokens": m.tokens,
            "cost_per_1k_tokens": round(m.cost_per_1k, 4) if m.cost_per_1k else None,
        }
        for m in model_result.all()
    ]

    # Daily trend
    daily = await db.execute(
        select(
            AIWorkload.period_start,
            func.sum(AIWorkload.total_cost).label("cost"),
        )
        .where(
            AIWorkload.organization_id == current_user.organization_id,
            AIWorkload.period_start >= start_date,
            AIWorkload.period_start <= end_date,
        )
        .group_by(AIWorkload.period_start)
        .order_by(AIWorkload.period_start)
    )
    daily_trend = [
        {"date": str(d.period_start), "cost": round(d.cost, 2)}
        for d in daily.all()
    ]

    return AIWorkloadSummary(
        total_ai_cost=round(current_cost, 2),
        total_ai_cost_change_percent=change_pct,
        total_tokens=r.total_tokens,
        total_gpu_hours=round(r.total_gpu_hours, 1) if r.total_gpu_hours else None,
        cost_per_1k_tokens_avg=round(r.avg_cost_per_1k, 4) if r.avg_cost_per_1k else None,
        avg_gpu_utilization=round(r.avg_gpu_util, 1) if r.avg_gpu_util else None,
        by_service_type=by_service,
        by_model=by_model,
        daily_trend=daily_trend,
    )


@router.get("/workloads", response_model=list[AIWorkloadResponse])
async def list_ai_workloads(
    service_type: str = Query(default=None),
    start_date: date = Query(default=None),
    end_date: date = Query(default=None),
    limit: int = Query(default=50, le=200),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """List individual AI workloads with detailed metrics."""
    if not end_date:
        end_date = date.today()
    if not start_date:
        start_date = end_date - timedelta(days=30)

    query = (
        select(AIWorkload)
        .where(
            AIWorkload.organization_id == current_user.organization_id,
            AIWorkload.period_start >= start_date,
            AIWorkload.period_start <= end_date,
        )
        .order_by(AIWorkload.total_cost.desc())
        .limit(limit)
    )
    if service_type:
        query = query.where(AIWorkload.service_type == service_type)

    result = await db.execute(query)
    return result.scalars().all()
