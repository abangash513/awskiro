"""Recommendation routes — Simplified stub version."""

from datetime import date, datetime, timedelta
from typing import List, Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.models.recommendation import Recommendation, RecommendationCategory, RecommendationStatus
from app.services.azure_advisor_import import import_advisor_recommendations

router = APIRouter()


@router.get("/")
async def list_recommendations(
    category: Optional[str] = Query(default=None),
    status: Optional[str] = Query(default=None),
    account_name: Optional[str] = Query(default=None),
    business_unit: Optional[str] = Query(default=None),
    limit: int = Query(default=50, le=100),
    db: AsyncSession = Depends(get_db),
):
    """List all recommendations with optional filtering."""
    query = select(Recommendation).order_by(Recommendation.created_at.desc())
    
    if category:
        query = query.where(Recommendation.category == category)
    if status:
        query = query.where(Recommendation.status == status)
    if account_name:
        query = query.where(Recommendation.account_name == account_name)
    if business_unit:
        query = query.where(Recommendation.business_unit == business_unit)
    
    query = query.limit(limit)
    result = await db.execute(query)
    recommendations = result.scalars().all()

    return [
        {
            "id": rec.id,
            "title": rec.title,
            "description": rec.description,
            "category": rec.category.value,
            "impact": rec.impact.value,
            "status": rec.status.value,
            "estimated_monthly_savings": float(rec.estimated_monthly_savings),
            "estimated_annual_savings": float(rec.estimated_annual_savings),
            "currency": rec.currency,
            "subscription_id": rec.subscription_id,
            "account_name": rec.account_name,
            "business_unit": rec.business_unit,
            "resource_group": rec.resource_group,
            "resource_name": rec.resource_name,
            "source": rec.source,
            "created_at": rec.created_at.isoformat(),
        }
        for rec in recommendations
    ]


@router.get("/summary")
async def get_recommendations_summary(
    db: AsyncSession = Depends(get_db),
):
    """Get summary statistics for recommendations."""
    # Total count
    total_query = select(func.count(Recommendation.id))
    total_result = await db.execute(total_query)
    total_count = total_result.scalar() or 0

    # Count by status
    status_query = (
        select(
            Recommendation.status,
            func.count(Recommendation.id).label("count"),
        )
        .group_by(Recommendation.status)
    )
    status_result = await db.execute(status_query)
    by_status = {r.status.value: r.count for r in status_result.all()}

    # Total potential savings
    savings_query = select(
        func.sum(Recommendation.estimated_monthly_savings),
        func.sum(Recommendation.estimated_annual_savings),
    ).where(Recommendation.status == RecommendationStatus.NEW)
    savings_result = await db.execute(savings_query)
    savings_row = savings_result.one()

    # Count by category
    category_query = (
        select(
            Recommendation.category,
            func.count(Recommendation.id).label("count"),
            func.sum(Recommendation.estimated_monthly_savings).label("savings"),
        )
        .group_by(Recommendation.category)
    )
    category_result = await db.execute(category_query)
    by_category = [
        {
            "category": r.category.value,
            "count": r.count,
            "potential_monthly_savings": float(r.savings or 0),
        }
        for r in category_result.all()
    ]

    return {
        "total_recommendations": total_count,
        "by_status": by_status,
        "potential_monthly_savings": float(savings_row[0] or 0),
        "potential_annual_savings": float(savings_row[1] or 0),
        "by_category": by_category,
    }


@router.get("/{recommendation_id}")
async def get_recommendation(
    recommendation_id: int,
    db: AsyncSession = Depends(get_db),
):
    """Get a specific recommendation by ID."""
    query = select(Recommendation).where(Recommendation.id == recommendation_id)
    result = await db.execute(query)
    rec = result.scalar_one_or_none()

    if not rec:
        return {"error": "Recommendation not found"}, 404

    return {
        "id": rec.id,
        "title": rec.title,
        "description": rec.description,
        "category": rec.category.value,
        "impact": rec.impact.value,
        "status": rec.status.value,
        "estimated_monthly_savings": float(rec.estimated_monthly_savings),
        "estimated_annual_savings": float(rec.estimated_annual_savings),
        "currency": rec.currency,
        "confidence_score": float(rec.confidence_score),
        "subscription_id": rec.subscription_id,
        "resource_group": rec.resource_group,
        "resource_id": rec.resource_id,
        "resource_name": rec.resource_name,
        "resource_type": rec.resource_type,
        "current_config": rec.current_config,
        "recommended_config": rec.recommended_config,
        "implementation_effort": rec.implementation_effort,
        "implementation_steps": rec.implementation_steps,
        "risk_level": rec.risk_level,
        "source": rec.source,
        "valid_from": rec.valid_from.isoformat(),
        "valid_until": rec.valid_until.isoformat() if rec.valid_until else None,
        "is_stale": rec.is_stale,
        "created_at": rec.created_at.isoformat(),
        "updated_at": rec.updated_at.isoformat(),
    }


@router.patch("/{recommendation_id}")
async def update_recommendation(
    recommendation_id: int,
    status: Optional[str] = None,
    dismissed_reason: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
):
    """Update a recommendation status."""
    query = select(Recommendation).where(Recommendation.id == recommendation_id)
    result = await db.execute(query)
    rec = result.scalar_one_or_none()

    if not rec:
        return {"error": "Recommendation not found"}, 404

    if status:
        # Map frontend status to backend enum
        status_map = {
            "implemented": RecommendationStatus.IMPLEMENTED,
            "accepted": RecommendationStatus.ACCEPTED,
            "rejected": RecommendationStatus.REJECTED,
            "dismissed": RecommendationStatus.REJECTED,
            "in_review": RecommendationStatus.IN_REVIEW,
            "new": RecommendationStatus.NEW,
        }
        
        if status in status_map:
            rec.status = status_map[status]
            rec.status_changed_at = datetime.utcnow()
        
    if dismissed_reason:
        rec.rejection_reason = dismissed_reason

    await db.commit()
    await db.refresh(rec)

    return {
        "id": rec.id,
        "status": rec.status.value,
        "message": "Recommendation updated successfully"
    }


@router.get("/categories/list")
async def list_categories():
    """List all available recommendation categories."""
    return {
        "categories": [
            {
                "value": cat.value,
                "name": cat.value.replace("_", " ").title(),
            }
            for cat in RecommendationCategory
        ]
    }


@router.post("/import-advisor")
async def import_azure_advisor(
    db: AsyncSession = Depends(get_db),
):
    """Import recommendations from Azure Advisor for all configured accounts."""
    try:
        stats = await import_advisor_recommendations(db)
        return {
            "status": "success",
            "message": f"Imported Azure Advisor recommendations for {len(stats)} accounts",
            "details": stats
        }
    except Exception as e:
        return {
            "status": "error",
            "message": str(e)
        }
