"""Cloud connection routes — manage Azure (and later AWS) subscriptions."""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.cloud_connection import CloudConnection
from app.schemas import CloudConnectionCreate, CloudConnectionResponse

router = APIRouter()


@router.get("/", response_model=list[CloudConnectionResponse])
async def list_connections(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """List all cloud connections for the user's organization."""
    result = await db.execute(
        select(CloudConnection)
        .where(CloudConnection.organization_id == current_user.organization_id)
        .order_by(CloudConnection.created_at.desc())
    )
    return result.scalars().all()


@router.post("/", response_model=CloudConnectionResponse, status_code=status.HTTP_201_CREATED)
async def create_connection(
    data: CloudConnectionCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Add a new Azure subscription connection."""
    connection = CloudConnection(
        organization_id=current_user.organization_id,
        provider=data.provider,
        display_name=data.display_name,
        subscription_id=data.subscription_id,
        tenant_id=data.tenant_id,
    )
    db.add(connection)
    await db.flush()
    return connection


@router.delete("/{connection_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_connection(
    connection_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Remove a cloud connection."""
    result = await db.execute(
        select(CloudConnection).where(
            CloudConnection.id == connection_id,
            CloudConnection.organization_id == current_user.organization_id,
        )
    )
    connection = result.scalar_one_or_none()
    if not connection:
        raise HTTPException(status_code=404, detail="Connection not found")
    await db.delete(connection)


@router.post("/{connection_id}/sync", response_model=dict)
async def trigger_sync(
    connection_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Trigger a manual cost data sync for a connection."""
    result = await db.execute(
        select(CloudConnection).where(
            CloudConnection.id == connection_id,
            CloudConnection.organization_id == current_user.organization_id,
        )
    )
    connection = result.scalar_one_or_none()
    if not connection:
        raise HTTPException(status_code=404, detail="Connection not found")

    # Queue Celery task
    from app.services.azure_cost_ingestion import ingest_connection_costs
    ingest_connection_costs.delay(connection_id)

    connection.ingestion_status = "running"
    return {"status": "sync_queued", "connection_id": connection_id}
