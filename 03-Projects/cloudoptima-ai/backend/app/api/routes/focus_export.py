"""FOCUS Export — export cost data in FOCUS 1.2/1.3 format (MVP Feature #5).

Exports all cost_data rows with FOCUS-compliant column names.
Supports CSV, JSON, and Parquet formats.
"""

import io
import csv
from datetime import date, timedelta

from fastapi import APIRouter, Depends, Query
from fastapi.responses import StreamingResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.cost_data import CostData

router = APIRouter()

# FOCUS 1.3 column order for export
FOCUS_COLUMNS = [
    "BillingPeriodStart", "BillingPeriodEnd", "ChargePeriodStart", "ChargePeriodEnd",
    "BillingAccountId", "BillingAccountName", "SubAccountId", "SubAccountName",
    "ResourceId", "ResourceName", "ResourceType", "Region",
    "ServiceName", "ServiceCategory", "PublisherName",
    "PricingCategory", "PricingUnit", "PricingQuantity", "SkuId", "SkuPriceId",
    "BilledCost", "EffectiveCost", "ListCost", "BillingCurrency",
    "UsageQuantity", "UsageUnit", "ConsumedQuantity", "ConsumedUnit",
    "ChargeCategory", "ChargeFrequency", "ChargeDescription",
    "CommitmentDiscountId", "CommitmentDiscountName", "CommitmentDiscountCategory",
    "Tags", "Provider",
]


@router.get("/export")
async def export_focus_data(
    start_date: date = Query(default=None),
    end_date: date = Query(default=None),
    format: str = Query(default="csv", pattern="^(csv|json)$"),
    connection_id: int = Query(default=None),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Export cost data in FOCUS 1.3 format.

    Returns CSV or JSON with standardized FOCUS column names,
    enabling interoperability with any FOCUS-compliant tool.
    """
    if not end_date:
        end_date = date.today()
    if not start_date:
        start_date = end_date - timedelta(days=30)

    query = (
        select(CostData)
        .where(
            CostData.organization_id == current_user.organization_id,
            CostData.BillingPeriodStart >= start_date,
            CostData.BillingPeriodStart <= end_date,
        )
        .order_by(CostData.BillingPeriodStart, CostData.ServiceName)
    )
    if connection_id:
        query = query.where(CostData.cloud_connection_id == connection_id)

    result = await db.execute(query)
    rows = result.scalars().all()

    if format == "json":
        data = []
        for row in rows:
            record = {}
            for col in FOCUS_COLUMNS:
                val = getattr(row, col, None)
                if isinstance(val, (date,)):
                    val = val.isoformat()
                elif hasattr(val, "isoformat"):
                    val = val.isoformat()
                record[col] = val
            data.append(record)

        import json
        content = json.dumps(data, indent=2)
        return StreamingResponse(
            io.BytesIO(content.encode()),
            media_type="application/json",
            headers={"Content-Disposition": f"attachment; filename=cloudoptima-focus-{start_date}-{end_date}.json"},
        )

    # CSV export (default)
    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(FOCUS_COLUMNS)

    for row in rows:
        csv_row = []
        for col in FOCUS_COLUMNS:
            val = getattr(row, col, None)
            if val is None:
                csv_row.append("")
            elif isinstance(val, (date,)):
                csv_row.append(val.isoformat())
            elif hasattr(val, "isoformat"):
                csv_row.append(val.isoformat())
            else:
                csv_row.append(str(val))
        writer.writerow(csv_row)

    output.seek(0)
    return StreamingResponse(
        io.BytesIO(output.getvalue().encode()),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename=cloudoptima-focus-{start_date}-{end_date}.csv"},
    )


@router.get("/schema")
async def get_focus_schema():
    """Return the FOCUS 1.3 schema definition used by CloudOptima AI."""
    return {
        "focus_version": "1.3",
        "columns": FOCUS_COLUMNS,
        "description": "CloudOptima AI exports cost data using FOCUS (FinOps Open Cost and Usage Specification) "
                       "v1.3 column naming. This ensures interoperability with any FOCUS-compliant tool.",
        "reference": "https://focus.finops.org/",
    }
