"""Azure Monitor metrics endpoints."""

from datetime import datetime, timedelta
from typing import Optional

from fastapi import APIRouter, Depends, Query, HTTPException, status
from pydantic import BaseModel, Field

from app.core.auth import APIKeyInfo, get_api_key_optional, require_scope, Scopes
from app.core.config import get_settings
from app.core.exceptions import AzureCredentialsNotConfiguredError, AzureResourceNotFoundError
from app.core.logging import get_logger
from app.services.azure_monitor import get_azure_monitor_client

router = APIRouter()
logger = get_logger(__name__)


def get_auth_dependency():
    """Get authentication dependency based on settings."""
    settings = get_settings()
    if settings.auth_enabled and settings.api_key:
        return require_scope(Scopes.COSTS_READ)
    return get_api_key_optional


# =============================================================================
# Response Schemas
# =============================================================================

class MetricDataPoint(BaseModel):
    """Single metric data point."""

    timestamp: str = Field(description="ISO timestamp")
    average: Optional[float] = Field(default=None, description="Average value")
    maximum: Optional[float] = Field(default=None, description="Maximum value")
    minimum: Optional[float] = Field(default=None, description="Minimum value")
    total: Optional[float] = Field(default=None, description="Total value")


class CPUMetricsResponse(BaseModel):
    """CPU utilization metrics response."""

    resource_id: str = Field(description="Resource ID")
    metric: str = Field(description="Metric name")
    period_start: str = Field(description="Period start timestamp")
    period_end: str = Field(description="Period end timestamp")
    average_utilization: float = Field(description="Average CPU percentage")
    max_utilization: float = Field(description="Maximum CPU percentage")
    min_utilization: float = Field(description="Minimum CPU percentage")
    data_points: int = Field(description="Number of data points")
    time_series: list[dict] = Field(description="Time series data")
    utilization_status: str = Field(description="Status (idle, underutilized, optimal, overutilized)")
    recommendation: Optional[str] = Field(default=None, description="Optimization recommendation")


class MemoryMetricsResponse(BaseModel):
    """Memory utilization metrics response."""

    resource_id: str = Field(description="Resource ID")
    metric: str = Field(description="Metric name")
    period_start: str = Field(description="Period start timestamp")
    period_end: str = Field(description="Period end timestamp")
    average_available_gb: Optional[float] = Field(description="Average available memory in GB")
    data_points: int = Field(description="Number of data points")
    time_series: list[dict] = Field(description="Time series data")
    note: Optional[str] = Field(default=None, description="Additional notes")


class StorageMetricsResponse(BaseModel):
    """Storage account metrics response."""

    resource_id: str = Field(description="Resource ID")
    metric: str = Field(description="Metric name")
    period_start: str = Field(description="Period start timestamp")
    period_end: str = Field(description="Period end timestamp")
    total_transactions: int = Field(description="Total transactions")
    average_daily_transactions: float = Field(description="Average daily transactions")
    time_series: list[dict] = Field(description="Time series data")
    activity_status: str = Field(description="Activity level (low_activity, active)")
    recommendation: Optional[str] = Field(default=None, description="Optimization recommendation")


class ResourceUtilizationResponse(BaseModel):
    """Resource utilization summary response."""

    resource_id: str = Field(description="Resource ID")
    resource_type: str = Field(description="Resource type")
    status: str = Field(description="Utilization status")
    recommendation: Optional[str] = Field(default=None, description="Recommendation")
    metrics: dict = Field(description="Detailed metrics")


# =============================================================================
# Endpoints
# =============================================================================

@router.get("/vm/{resource_id:path}/cpu", response_model=CPUMetricsResponse)
async def get_vm_cpu_metrics(
    resource_id: str,
    days: int = Query(default=7, ge=1, le=30, description="Days of history"),
    interval: str = Query(default="PT1H", description="Metric interval (PT1H, PT15M, etc.)"),
    _auth: Optional[APIKeyInfo] = Depends(get_auth_dependency()),
) -> CPUMetricsResponse:
    """
    Get CPU utilization metrics for a virtual machine.
    
    Returns average, min, max CPU percentages and utilization status.
    
    **Resource ID format:** `/subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Compute/virtualMachines/{vm}`
    
    **Requires scope:** `costs:read` or `*`
    """
    settings = get_settings()
    
    if not settings.is_azure_configured:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Azure credentials not configured",
        )

    # Ensure resource_id starts with /
    if not resource_id.startswith("/"):
        resource_id = "/" + resource_id

    monitor_client = get_azure_monitor_client()

    try:
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(days=days)

        result = await monitor_client.get_vm_cpu_utilization(
            resource_id=resource_id,
            start_time=start_time,
            end_time=end_time,
            interval=interval,
        )

        # Determine utilization status
        avg_cpu = result.get("average_utilization", 0)
        if avg_cpu < 5:
            status_str = "idle"
            recommendation = "Consider shutting down or deallocating this VM when not in use"
        elif avg_cpu < 20:
            status_str = "underutilized"
            recommendation = "Consider rightsizing to a smaller VM SKU to reduce costs"
        elif avg_cpu > 90:
            status_str = "overutilized"
            recommendation = "Consider upgrading to a larger VM SKU for better performance"
        else:
            status_str = "optimal"
            recommendation = None

        return CPUMetricsResponse(
            **result,
            utilization_status=status_str,
            recommendation=recommendation,
        )

    except AzureResourceNotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"VM not found: {resource_id}",
        )
    except Exception as e:
        logger.error("Failed to fetch CPU metrics", error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch CPU metrics: {str(e)}",
        )


@router.get("/vm/{resource_id:path}/memory", response_model=MemoryMetricsResponse)
async def get_vm_memory_metrics(
    resource_id: str,
    days: int = Query(default=7, ge=1, le=30),
    interval: str = Query(default="PT1H"),
    _auth: Optional[APIKeyInfo] = Depends(get_auth_dependency()),
) -> MemoryMetricsResponse:
    """
    Get memory utilization metrics for a virtual machine.
    
    Note: Requires Azure Monitor Agent or VM Insights enabled on the VM.
    
    **Requires scope:** `costs:read` or `*`
    """
    settings = get_settings()
    
    if not settings.is_azure_configured:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Azure credentials not configured",
        )

    if not resource_id.startswith("/"):
        resource_id = "/" + resource_id

    monitor_client = get_azure_monitor_client()

    try:
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(days=days)

        result = await monitor_client.get_vm_memory_utilization(
            resource_id=resource_id,
            start_time=start_time,
            end_time=end_time,
            interval=interval,
        )

        return MemoryMetricsResponse(**result)

    except AzureResourceNotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"VM not found: {resource_id}",
        )
    except Exception as e:
        logger.error("Failed to fetch memory metrics", error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch memory metrics: {str(e)}",
        )


@router.get("/storage/{resource_id:path}/transactions", response_model=StorageMetricsResponse)
async def get_storage_metrics(
    resource_id: str,
    days: int = Query(default=7, ge=1, le=30),
    interval: str = Query(default="PT1H"),
    _auth: Optional[APIKeyInfo] = Depends(get_auth_dependency()),
) -> StorageMetricsResponse:
    """
    Get transaction metrics for a storage account.
    
    Returns transaction counts and activity level to identify candidates for
    archive tier or lifecycle policies.
    
    **Resource ID format:** `/subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Storage/storageAccounts/{name}`
    
    **Requires scope:** `costs:read` or `*`
    """
    settings = get_settings()
    
    if not settings.is_azure_configured:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Azure credentials not configured",
        )

    if not resource_id.startswith("/"):
        resource_id = "/" + resource_id

    monitor_client = get_azure_monitor_client()

    try:
        end_time = datetime.utcnow()
        start_time = end_time - timedelta(days=days)

        result = await monitor_client.get_storage_transactions(
            resource_id=resource_id,
            start_time=start_time,
            end_time=end_time,
            interval=interval,
        )

        # Determine activity status
        avg_daily = result.get("average_daily_transactions", 0)
        if avg_daily < 100:
            activity_status = "low_activity"
            recommendation = "Consider moving infrequently accessed data to Cool or Archive tier"
        elif avg_daily < 1000:
            activity_status = "moderate"
            recommendation = "Review blob access patterns for optimization opportunities"
        else:
            activity_status = "active"
            recommendation = None

        return StorageMetricsResponse(
            **result,
            activity_status=activity_status,
            recommendation=recommendation,
        )

    except AzureResourceNotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Storage account not found: {resource_id}",
        )
    except Exception as e:
        logger.error("Failed to fetch storage metrics", error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch storage metrics: {str(e)}",
        )


@router.get("/utilization/{resource_id:path}", response_model=ResourceUtilizationResponse)
async def get_resource_utilization(
    resource_id: str,
    resource_type: str = Query(description="Azure resource type (e.g., Microsoft.Compute/virtualMachines)"),
    _auth: Optional[APIKeyInfo] = Depends(get_auth_dependency()),
) -> ResourceUtilizationResponse:
    """
    Get utilization summary for any supported resource type.
    
    Automatically selects appropriate metrics based on resource type.
    
    **Requires scope:** `costs:read` or `*`
    """
    settings = get_settings()
    
    if not settings.is_azure_configured:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Azure credentials not configured",
        )

    if not resource_id.startswith("/"):
        resource_id = "/" + resource_id

    monitor_client = get_azure_monitor_client()

    try:
        result = await monitor_client.get_resource_utilization_summary(
            resource_id=resource_id,
            resource_type=resource_type,
        )

        return ResourceUtilizationResponse(
            resource_id=result["resource_id"],
            resource_type=result["resource_type"],
            status=result["status"],
            recommendation=result.get("recommendation"),
            metrics={k: v for k, v in result.items() if k not in ["resource_id", "resource_type", "status", "recommendation"]},
        )

    except AzureResourceNotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Resource not found: {resource_id}",
        )
    except Exception as e:
        logger.error("Failed to fetch utilization", error=str(e))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch utilization: {str(e)}",
        )
