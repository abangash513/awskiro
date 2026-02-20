"""Azure Cost Ingestion Service.

Connects to Azure Cost Management API, pulls billing data,
and maps it to the FOCUS 1.3 schema stored in cost_data table.

Uses the Azure Cost Management Query API:
https://learn.microsoft.com/en-us/rest/api/cost-management/query
"""

import logging
from datetime import date, timedelta, datetime, timezone

from celery import shared_task
from azure.identity import ClientSecretCredential
from azure.mgmt.costmanagement import CostManagementClient
from azure.mgmt.costmanagement.models import (
    QueryDefinition,
    QueryTimePeriod,
    QueryDataset,
    QueryAggregation,
    QueryGrouping,
)
from sqlalchemy import create_engine
from sqlalchemy.orm import Session

from app.core import get_settings
from app.models.cloud_connection import CloudConnection
from app.models.cost_data import CostData
from app.models.ai_workload import AIWorkload

logger = logging.getLogger(__name__)
settings = get_settings()

# Azure AI/ML service names for AI cost dashboard
AI_SERVICE_NAMES = {
    "Azure OpenAI",
    "Cognitive Services",
    "Azure Machine Learning",
    "Azure AI services",
    "Azure AI Search",
}

GPU_VM_PREFIXES = ("Standard_NC", "Standard_ND", "Standard_NV", "Standard_A100")


def get_azure_credential(connection: CloudConnection):
    """Create Azure credential from service principal."""
    return ClientSecretCredential(
        tenant_id=connection.tenant_id or settings.azure_tenant_id,
        client_id=settings.azure_client_id,
        client_secret=settings.azure_client_secret,
    )


def map_to_focus(row: dict, connection: CloudConnection, billing_date: date) -> dict:
    """Map Azure Cost Management API response to FOCUS 1.3 columns."""
    return {
        "organization_id": connection.organization_id,
        "cloud_connection_id": connection.id,
        "BillingPeriodStart": billing_date,
        "BillingPeriodEnd": billing_date,
        "ChargePeriodStart": datetime(billing_date.year, billing_date.month, billing_date.day, tzinfo=timezone.utc),
        "ChargePeriodEnd": datetime(billing_date.year, billing_date.month, billing_date.day, 23, 59, 59, tzinfo=timezone.utc),
        "BillingAccountId": connection.subscription_id,
        "BillingAccountName": connection.display_name,
        "SubAccountId": row.get("ResourceGroupName", ""),
        "SubAccountName": row.get("ResourceGroupName", ""),
        "ResourceId": row.get("ResourceId", ""),
        "ResourceName": _extract_resource_name(row.get("ResourceId", "")),
        "ResourceType": row.get("ResourceType", ""),
        "Region": row.get("ResourceLocation", ""),
        "ServiceName": row.get("ServiceName", ""),
        "ServiceCategory": row.get("MeterCategory", ""),
        "PublisherName": row.get("PublisherName", "Microsoft"),
        "PricingCategory": _map_pricing_category(row),
        "PricingUnit": row.get("UnitOfMeasure", ""),
        "PricingQuantity": row.get("Quantity", 0),
        "BilledCost": row.get("PreTaxCost", 0) or row.get("Cost", 0),
        "EffectiveCost": row.get("PreTaxCost", 0) or row.get("Cost", 0),
        "ListCost": row.get("PreTaxCost", 0) or row.get("Cost", 0),
        "BillingCurrency": row.get("Currency", "USD"),
        "UsageQuantity": row.get("Quantity", 0),
        "UsageUnit": row.get("UnitOfMeasure", ""),
        "ChargeCategory": "Usage",
        "ChargeFrequency": "Usage-Based",
        "ChargeDescription": row.get("MeterSubCategory", ""),
        "Tags": _format_tags(row.get("Tags", {})),
        "Provider": "Azure",
    }


def _extract_resource_name(resource_id: str) -> str:
    """Extract the resource name from an Azure ARM resource ID."""
    if resource_id:
        return resource_id.split("/")[-1]
    return ""


def _map_pricing_category(row: dict) -> str:
    """Map Azure pricing model to FOCUS PricingCategory."""
    pricing = row.get("PricingModel", "")
    if "Reservation" in pricing or "Reserved" in pricing:
        return "Commitment"
    elif "Spot" in pricing:
        return "Spot"
    return "On-Demand"


def _format_tags(tags: dict) -> str:
    """Format tags dict as semicolon-separated key:value pairs."""
    if not tags:
        return ""
    return ";".join(f"{k}:{v}" for k, v in tags.items())


@shared_task(name="app.services.azure_cost_ingestion.ingest_connection_costs")
def ingest_connection_costs(connection_id: int, days_back: int = 7):
    """Ingest cost data for a single Azure connection (Celery task)."""
    engine = create_engine(settings.database_url_sync)

    with Session(engine) as db:
        connection = db.get(CloudConnection, connection_id)
        if not connection or not connection.is_active:
            logger.warning(f"Connection {connection_id} not found or inactive")
            return

        try:
            connection.ingestion_status = "running"
            db.commit()

            credential = get_azure_credential(connection)
            client = CostManagementClient(credential)

            end_date = date.today() - timedelta(days=1)
            start_date = end_date - timedelta(days=days_back)

            scope = f"/subscriptions/{connection.subscription_id}"

            # Query cost data grouped by key dimensions
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

            # Parse response columns
            columns = [col.name for col in result.columns]
            row_count = 0

            for row_data in result.rows:
                row = dict(zip(columns, row_data))

                # Extract billing date from the UsageDate column
                usage_date = row.get("UsageDate")
                if usage_date:
                    if isinstance(usage_date, int):
                        # Azure returns dates as YYYYMMDD integers
                        usage_date = date(usage_date // 10000, (usage_date % 10000) // 100, usage_date % 100)
                    billing_date = usage_date
                else:
                    billing_date = start_date

                # Map to FOCUS and insert
                focus_row = map_to_focus(row, connection, billing_date)
                cost_record = CostData(**focus_row)
                db.add(cost_record)

                # Track AI workloads separately for the AI cost dashboard
                service_name = row.get("ServiceName", "")
                if service_name in AI_SERVICE_NAMES:
                    _track_ai_workload(db, connection, row, billing_date, "azure_openai" if "OpenAI" in service_name else "cognitive_services")

                row_count += 1

                # Batch commit every 500 rows
                if row_count % 500 == 0:
                    db.commit()

            db.commit()

            connection.ingestion_status = "completed"
            connection.last_ingestion_at = datetime.now(timezone.utc)
            connection.ingestion_error = None
            db.commit()

            logger.info(f"Ingested {row_count} cost records for connection {connection_id}")

        except Exception as e:
            logger.error(f"Ingestion failed for connection {connection_id}: {e}")
            connection.ingestion_status = "failed"
            connection.ingestion_error = str(e)[:1000]
            db.commit()
            raise


def _track_ai_workload(db: Session, connection: CloudConnection, row: dict, billing_date: date, service_type: str):
    """Create/update AI workload record for the AI cost dashboard."""
    workload = AIWorkload(
        organization_id=connection.organization_id,
        cloud_connection_id=connection.id,
        service_type=service_type,
        resource_id=row.get("ResourceId", ""),
        resource_name=_extract_resource_name(row.get("ResourceId", "")),
        total_cost=row.get("PreTaxCost", 0) or row.get("Cost", 0),
        period_start=billing_date,
        period_end=billing_date,
    )
    db.add(workload)


@shared_task(name="app.services.azure_cost_ingestion.ingest_all_connections")
def ingest_all_connections():
    """Ingest costs for all active connections (scheduled daily by Celery Beat)."""
    engine = create_engine(settings.database_url_sync)

    with Session(engine) as db:
        connections = db.query(CloudConnection).filter(
            CloudConnection.is_active == True
        ).all()

        for conn in connections:
            try:
                ingest_connection_costs.delay(conn.id)
            except Exception as e:
                logger.error(f"Failed to queue ingestion for connection {conn.id}: {e}")
