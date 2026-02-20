"""Cost data routes — Simplified stub version."""

from datetime import date, timedelta
from typing import List

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, func, distinct
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.models.cost import CostRecord, CostSummary
from app.services.azure_multi_account_import import import_all_accounts, ACCOUNT_MAPPING

router = APIRouter()


@router.get("/summary")
async def get_cost_summary(
    start_date: date = Query(default=None),
    end_date: date = Query(default=None),
    account_name: str = Query(default=None),
    business_unit: str = Query(default=None),
    cloud_provider: str = Query(default=None),
    db: AsyncSession = Depends(get_db),
):
    """Get aggregated cost summary for a time period."""
    if not end_date:
        end_date = date.today()
    if not start_date:
        start_date = end_date - timedelta(days=30)

    # Build query with optional filters
    query = select(func.sum(CostRecord.cost)).where(
        CostRecord.usage_date >= start_date,
        CostRecord.usage_date <= end_date,
    )
    
    if account_name:
        query = query.where(CostRecord.account_name == account_name)
    if business_unit:
        query = query.where(CostRecord.business_unit == business_unit)
    
    # Filter by cloud provider based on subscription_id prefix
    if cloud_provider:
        if cloud_provider.lower() == 'aws':
            query = query.where(CostRecord.subscription_id.like('aws-%'))
        elif cloud_provider.lower() == 'azure':
            # Azure uses GUID format (not starting with aws-, gcp-, oci-)
            query = query.where(
                ~CostRecord.subscription_id.like('aws-%'),
                ~CostRecord.subscription_id.like('gcp-%'),
                ~CostRecord.subscription_id.like('oci-%')
            )
        elif cloud_provider.lower() == 'gcp':
            query = query.where(CostRecord.subscription_id.like('gcp-%'))
        elif cloud_provider.lower() == 'oci':
            query = query.where(CostRecord.subscription_id.like('oci-%'))
    
    result = await db.execute(query)
    total_cost = result.scalar() or 0

    # Get top services
    svc_query = (
        select(
            CostRecord.service_name,
            func.sum(CostRecord.cost).label("total"),
        )
        .where(
            CostRecord.usage_date >= start_date,
            CostRecord.usage_date <= end_date,
        )
    )
    
    if account_name:
        svc_query = svc_query.where(CostRecord.account_name == account_name)
    if business_unit:
        svc_query = svc_query.where(CostRecord.business_unit == business_unit)
    
    # Filter by cloud provider for top services
    if cloud_provider:
        if cloud_provider.lower() == 'aws':
            svc_query = svc_query.where(CostRecord.subscription_id.like('aws-%'))
        elif cloud_provider.lower() == 'azure':
            svc_query = svc_query.where(
                ~CostRecord.subscription_id.like('aws-%'),
                ~CostRecord.subscription_id.like('gcp-%'),
                ~CostRecord.subscription_id.like('oci-%')
            )
        elif cloud_provider.lower() == 'gcp':
            svc_query = svc_query.where(CostRecord.subscription_id.like('gcp-%'))
        elif cloud_provider.lower() == 'oci':
            svc_query = svc_query.where(CostRecord.subscription_id.like('oci-%'))
    
    svc_query = svc_query.group_by(CostRecord.service_name).order_by(func.sum(CostRecord.cost).desc()).limit(10)
    
    svc_result = await db.execute(svc_query)
    top_services = [
        {"service": r.service_name or "Unknown", "cost": round(r.total, 2)}
        for r in svc_result.all()
    ]

    return {
        "total_cost": round(total_cost, 2),
        "currency": "USD",
        "period_start": start_date.isoformat(),
        "period_end": end_date.isoformat(),
        "top_services": top_services,
    }


@router.get("/trend")
async def get_cost_trend(
    start_date: date = Query(default=None),
    end_date: date = Query(default=None),
    account_name: str = Query(default=None),
    business_unit: str = Query(default=None),
    cloud_provider: str = Query(default=None),
    db: AsyncSession = Depends(get_db),
):
    """Get daily cost trend for charting."""
    if not end_date:
        end_date = date.today()
    if not start_date:
        start_date = end_date - timedelta(days=30)

    query = (
        select(
            CostRecord.usage_date,
            func.sum(CostRecord.cost).label("total_cost"),
        )
        .where(
            CostRecord.usage_date >= start_date,
            CostRecord.usage_date <= end_date,
        )
    )
    
    if account_name:
        query = query.where(CostRecord.account_name == account_name)
    if business_unit:
        query = query.where(CostRecord.business_unit == business_unit)
    
    # Filter by cloud provider
    if cloud_provider:
        if cloud_provider.lower() == 'aws':
            query = query.where(CostRecord.subscription_id.like('aws-%'))
        elif cloud_provider.lower() == 'azure':
            query = query.where(
                ~CostRecord.subscription_id.like('aws-%'),
                ~CostRecord.subscription_id.like('gcp-%'),
                ~CostRecord.subscription_id.like('oci-%')
            )
        elif cloud_provider.lower() == 'gcp':
            query = query.where(CostRecord.subscription_id.like('gcp-%'))
        elif cloud_provider.lower() == 'oci':
            query = query.where(CostRecord.subscription_id.like('oci-%'))
    
    query = query.group_by(CostRecord.usage_date).order_by(CostRecord.usage_date)
    
    result = await db.execute(query)

    return [
        {
            "date": r.usage_date.isoformat(),
            "cost": round(r.total_cost, 2),
        }
        for r in result.all()
    ]


@router.get("/by-service")
async def get_cost_by_service(
    start_date: date = Query(default=None),
    end_date: date = Query(default=None),
    account_name: str = Query(default=None),
    business_unit: str = Query(default=None),
    cloud_provider: str = Query(default=None),
    db: AsyncSession = Depends(get_db),
):
    """Get cost breakdown by service."""
    if not end_date:
        end_date = date.today()
    if not start_date:
        start_date = end_date - timedelta(days=30)

    query = (
        select(
            CostRecord.service_name,
            func.sum(CostRecord.cost).label("total"),
        )
        .where(
            CostRecord.usage_date >= start_date,
            CostRecord.usage_date <= end_date,
        )
    )
    
    if account_name:
        query = query.where(CostRecord.account_name == account_name)
    if business_unit:
        query = query.where(CostRecord.business_unit == business_unit)
    
    # Filter by cloud provider
    if cloud_provider:
        if cloud_provider.lower() == 'aws':
            query = query.where(CostRecord.subscription_id.like('aws-%'))
        elif cloud_provider.lower() == 'azure':
            query = query.where(
                ~CostRecord.subscription_id.like('aws-%'),
                ~CostRecord.subscription_id.like('gcp-%'),
                ~CostRecord.subscription_id.like('oci-%')
            )
        elif cloud_provider.lower() == 'gcp':
            query = query.where(CostRecord.subscription_id.like('gcp-%'))
        elif cloud_provider.lower() == 'oci':
            query = query.where(CostRecord.subscription_id.like('oci-%'))
    
    query = query.group_by(CostRecord.service_name).order_by(func.sum(CostRecord.cost).desc()).limit(20)
    result = await db.execute(query)
    rows = result.all()

    total = sum(r.total or 0 for r in rows)
    return [
        {
            "service": r.service_name or "Unknown",
            "cost": round(r.total or 0, 2),
            "percent": round((r.total or 0) / total * 100, 1) if total > 0 else 0,
        }
        for r in rows
    ]


@router.get("/by-resource-group")
async def get_cost_by_resource_group(
    start_date: date = Query(default=None),
    end_date: date = Query(default=None),
    account_name: str = Query(default=None),
    business_unit: str = Query(default=None),
    cloud_provider: str = Query(default=None),
    db: AsyncSession = Depends(get_db),
):
    """Get cost breakdown by resource group."""
    if not end_date:
        end_date = date.today()
    if not start_date:
        start_date = end_date - timedelta(days=30)

    query = (
        select(
            CostRecord.resource_group,
            func.sum(CostRecord.cost).label("total"),
        )
        .where(
            CostRecord.usage_date >= start_date,
            CostRecord.usage_date <= end_date,
        )
    )
    
    if account_name:
        query = query.where(CostRecord.account_name == account_name)
    if business_unit:
        query = query.where(CostRecord.business_unit == business_unit)
    
    # Filter by cloud provider
    if cloud_provider:
        if cloud_provider.lower() == 'aws':
            query = query.where(CostRecord.subscription_id.like('aws-%'))
        elif cloud_provider.lower() == 'azure':
            query = query.where(
                ~CostRecord.subscription_id.like('aws-%'),
                ~CostRecord.subscription_id.like('gcp-%'),
                ~CostRecord.subscription_id.like('oci-%')
            )
        elif cloud_provider.lower() == 'gcp':
            query = query.where(CostRecord.subscription_id.like('gcp-%'))
        elif cloud_provider.lower() == 'oci':
            query = query.where(CostRecord.subscription_id.like('oci-%'))
    
    query = query.group_by(CostRecord.resource_group).order_by(func.sum(CostRecord.cost).desc()).limit(20)
    result = await db.execute(query)
    rows = result.all()

    total = sum(r.total or 0 for r in rows)
    return [
        {
            "resource_group": r.resource_group or "Unknown",
            "cost": round(r.total or 0, 2),
            "percent": round((r.total or 0) / total * 100, 1) if total > 0 else 0,
        }
        for r in rows
    ]


@router.get("/accounts")
async def list_accounts(db: AsyncSession = Depends(get_db)):
    """List all available accounts and business units."""
    # Get distinct accounts from database
    query = select(
        CostRecord.account_name,
        CostRecord.business_unit,
        CostRecord.subscription_id
    ).where(
        CostRecord.account_name.isnot(None)
    ).distinct()
    result = await db.execute(query)
    
    accounts = []
    seen = set()
    for row in result.all():
        account_name = row[0]
        business_unit = row[1]
        subscription_id = row[2]
        
        if account_name and account_name not in seen:
            accounts.append({
                "account_name": account_name,
                "business_unit": business_unit,
                "subscription_id": subscription_id
            })
            seen.add(account_name)
    
    # If no data in DB, return configured accounts
    if not accounts:
        accounts = [
            {
                "account_name": info["account_name"],
                "business_unit": info["business_unit"],
                "subscription_id": sub_id
            }
            for sub_id, info in ACCOUNT_MAPPING.items()
        ]
    
    return {"accounts": accounts}


@router.get("/by-account")
async def get_cost_by_account(
    start_date: date = Query(default=None),
    end_date: date = Query(default=None),
    db: AsyncSession = Depends(get_db),
):
    """Get cost breakdown by account."""
    if not end_date:
        end_date = date.today()
    if not start_date:
        start_date = end_date - timedelta(days=30)

    query = (
        select(
            CostRecord.account_name,
            CostRecord.business_unit,
            func.sum(CostRecord.cost).label("total"),
        )
        .where(
            CostRecord.usage_date >= start_date,
            CostRecord.usage_date <= end_date,
        )
        .group_by(CostRecord.account_name, CostRecord.business_unit)
        .order_by(func.sum(CostRecord.cost).desc())
    )
    result = await db.execute(query)
    rows = result.all()

    total = sum(r.total or 0 for r in rows)
    return [
        {
            "account_name": r.account_name or "Unknown",
            "business_unit": r.business_unit or "Unknown",
            "cost": round(r.total or 0, 2),
            "percent": round((r.total or 0) / total * 100, 1) if total > 0 else 0,
        }
        for r in rows
    ]


@router.post("/import")
async def import_cost_data(
    days_back: int = Query(default=30, le=90),
    db: AsyncSession = Depends(get_db),
):
    """Import cost data from Azure for all configured accounts."""
    try:
        stats = await import_all_accounts(db, days_back=days_back)
        return {
            "status": "success",
            "message": f"Imported cost data for {len(stats)} accounts",
            "details": stats
        }
    except Exception as e:
        return {
            "status": "error",
            "message": str(e)
        }
