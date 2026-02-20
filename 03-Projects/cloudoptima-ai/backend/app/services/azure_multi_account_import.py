"""Azure Multi-Account Cost Import Service.

Imports cost data from multiple Azure subscriptions under a single payer account.
"""

import logging
from datetime import date, timedelta, datetime, timezone
from decimal import Decimal
from typing import List, Dict

from azure.identity import ClientSecretCredential
from azure.mgmt.costmanagement import CostManagementClient
from azure.mgmt.costmanagement.models import (
    QueryDefinition,
    QueryTimePeriod,
    QueryDataset,
    QueryAggregation,
    QueryGrouping,
)
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core import get_settings
from app.models.cost import CostRecord

logger = logging.getLogger(__name__)
settings = get_settings()


# Map of subscription IDs to account names and business units
ACCOUNT_MAPPING = {
    "3a6cc9a1-adf7-49fe-a02f-f6db16ced2a1": {
        "account_name": "Production Account 1",
        "business_unit": "Engineering"
    },
    "7b8dd2e3-5cf8-4a1e-b93c-8f2a1d4e6b9f": {
        "account_name": "Production Account 2",
        "business_unit": "Marketing"
    },
    "9c4ee5f7-2ab9-4d3f-a84e-1c5b3f8d2a7e": {
        "account_name": "Production Account 3",
        "business_unit": "Sales"
    }
}


def get_azure_credential():
    """Create Azure credential from service principal."""
    return ClientSecretCredential(
        tenant_id=settings.azure_tenant_id,
        client_id=settings.azure_client_id,
        client_secret=settings.azure_client_secret,
    )


async def import_costs_for_account(
    db: AsyncSession,
    subscription_id: str,
    account_name: str,
    business_unit: str,
    days_back: int = 30
) -> int:
    """Import cost data for a single Azure subscription.
    
    Args:
        db: Database session
        subscription_id: Azure subscription ID
        account_name: Friendly account name
        business_unit: Business unit name
        days_back: Number of days to look back
    
    Returns:
        Number of records imported
    """
    try:
        credential = get_azure_credential()
        client = CostManagementClient(credential)
        
        end_date = date.today() - timedelta(days=1)
        start_date = end_date - timedelta(days=days_back)
        
        scope = f"/subscriptions/{subscription_id}"
        
        # Query cost data
        query_def = QueryDefinition(
            type="ActualCost",
            timeframe="Custom",
            time_period=QueryTimePeriod(
                from_property=datetime(start_date.year, start_date.month, start_date.day),
                to=datetime(end_date.year, end_date.month, end_date.day),
            ),
            dataset=QueryDataset(
                granularity="Daily",
                aggregation={
                    "PreTaxCost": QueryAggregation(name="PreTaxCost", function="Sum"),
                },
                grouping=[
                    QueryGrouping(type="Dimension", name="ServiceName"),
                    QueryGrouping(type="Dimension", name="ResourceGroupName"),
                    QueryGrouping(type="Dimension", name="ResourceId"),
                    QueryGrouping(type="Dimension", name="MeterCategory"),
                    QueryGrouping(type="Dimension", name="ResourceLocation"),
                ],
            ),
        )
        
        result = client.query.usage(scope=scope, parameters=query_def)
        
        # Parse response
        columns = [col.name for col in result.columns]
        row_count = 0
        
        for row_data in result.rows:
            row = dict(zip(columns, row_data))
            
            # Extract usage date
            usage_date = row.get("UsageDate")
            if usage_date:
                if isinstance(usage_date, int):
                    usage_date = date(usage_date // 10000, (usage_date % 10000) // 100, usage_date % 100)
            else:
                usage_date = start_date
            
            # Create cost record
            cost_record = CostRecord(
                subscription_id=subscription_id,
                account_name=account_name,
                business_unit=business_unit,
                resource_group=row.get("ResourceGroupName"),
                resource_id=row.get("ResourceId"),
                resource_name=row.get("ResourceId", "").split("/")[-1] if row.get("ResourceId") else None,
                resource_type=row.get("ResourceType"),
                service_name=row.get("ServiceName"),
                meter_category=row.get("MeterCategory"),
                meter_subcategory=row.get("MeterSubCategory"),
                cost=Decimal(str(row.get("PreTaxCost", 0) or row.get("Cost", 0))),
                currency=row.get("Currency", "USD"),
                quantity=Decimal(str(row.get("Quantity", 0))) if row.get("Quantity") else None,
                usage_date=datetime.combine(usage_date, datetime.min.time()),
                billing_period=f"{usage_date.year}-{usage_date.month:02d}",
            )
            
            db.add(cost_record)
            row_count += 1
            
            # Batch commit every 500 rows
            if row_count % 500 == 0:
                await db.commit()
        
        await db.commit()
        logger.info(f"Imported {row_count} cost records for {account_name} ({subscription_id})")
        return row_count
        
    except Exception as e:
        logger.error(f"Failed to import costs for {account_name} ({subscription_id}): {e}")
        return 0


async def import_all_accounts(
    db: AsyncSession,
    subscription_ids: List[str] = None,
    days_back: int = 30
) -> Dict[str, int]:
    """Import cost data for all configured accounts.
    
    Args:
        db: Database session
        subscription_ids: List of subscription IDs to import. If None, imports all from ACCOUNT_MAPPING.
        days_back: Number of days to look back
    
    Returns:
        Dictionary with import statistics per account
    """
    if subscription_ids is None:
        subscription_ids = list(ACCOUNT_MAPPING.keys())
    
    stats = {}
    
    for subscription_id in subscription_ids:
        account_info = ACCOUNT_MAPPING.get(subscription_id, {
            "account_name": "Unknown Account",
            "business_unit": "Unknown"
        })
        
        count = await import_costs_for_account(
            db=db,
            subscription_id=subscription_id,
            account_name=account_info["account_name"],
            business_unit=account_info["business_unit"],
            days_back=days_back
        )
        
        stats[account_info["account_name"]] = count
    
    return stats
