"""Azure Monitor client for resource utilization metrics."""

from datetime import datetime, timedelta
from typing import Any, Optional

from azure.identity import ClientSecretCredential
from azure.mgmt.monitor import MonitorManagementClient
from azure.mgmt.monitor.models import MetricAggregationType
from tenacity import retry, stop_after_attempt, wait_exponential

from app.core.config import get_settings
from app.core.exceptions import (
    AzureAuthenticationError,
    AzureCredentialsNotConfiguredError,
    AzureError,
    AzureRateLimitError,
    AzureResourceNotFoundError,
    AzureServiceUnavailableError,
)
from app.core.logging import get_logger

logger = get_logger(__name__)


class AzureMonitorClient:
    """
    Azure Monitor client for retrieving resource metrics.
    
    Used for analyzing resource utilization to generate accurate
    cost optimization recommendations.
    """

    def __init__(self) -> None:
        """Initialize Azure Monitor client."""
        self._settings = get_settings()
        self._credential: Optional[ClientSecretCredential] = None
        self._monitor_client: Optional[MonitorManagementClient] = None

    def _get_credential(self) -> ClientSecretCredential:
        """Get or create Azure credential."""
        if self._credential is None:
            if not self._settings.is_azure_configured:
                raise AzureCredentialsNotConfiguredError()
            
            try:
                self._credential = ClientSecretCredential(
                    tenant_id=self._settings.azure_tenant_id,
                    client_id=self._settings.azure_client_id,
                    client_secret=self._settings.azure_client_secret,
                )
            except Exception as e:
                raise AzureAuthenticationError(
                    f"Failed to create Azure credentials: {e}",
                    details={"tenant_id": self._settings.azure_tenant_id},
                )
        return self._credential

    @property
    def monitor_client(self) -> MonitorManagementClient:
        """Get Monitor Management client."""
        if self._monitor_client is None:
            self._monitor_client = MonitorManagementClient(
                credential=self._get_credential(),
                subscription_id=self._settings.azure_subscription_id,
            )
        return self._monitor_client

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        reraise=True,
    )
    async def get_vm_cpu_utilization(
        self,
        resource_id: str,
        start_time: Optional[datetime] = None,
        end_time: Optional[datetime] = None,
        interval: str = "PT1H",  # 1-hour intervals
    ) -> dict[str, Any]:
        """
        Get CPU utilization metrics for a virtual machine.

        Args:
            resource_id: Full ARM resource ID of the VM
            start_time: Start of time range (defaults to 7 days ago)
            end_time: End of time range (defaults to now)
            interval: Metric granularity (ISO 8601 duration format)

        Returns:
            Dictionary with average, max, min CPU percentages and time series
        """
        if end_time is None:
            end_time = datetime.utcnow()
        if start_time is None:
            start_time = end_time - timedelta(days=7)

        logger.info(
            "Fetching VM CPU metrics",
            resource_id=resource_id,
            start_time=start_time.isoformat(),
            end_time=end_time.isoformat(),
        )

        try:
            metrics = self.monitor_client.metrics.list(
                resource_uri=resource_id,
                timespan=f"{start_time.isoformat()}/{end_time.isoformat()}",
                interval=interval,
                metricnames="Percentage CPU",
                aggregation="Average,Maximum,Minimum",
            )

            time_series = []
            total_avg = 0.0
            max_value = 0.0
            min_value = 100.0
            data_points = 0

            for metric in metrics.value:
                for ts in metric.timeseries:
                    for data in ts.data:
                        if data.average is not None:
                            time_series.append({
                                "timestamp": data.time_stamp.isoformat(),
                                "average": data.average,
                                "maximum": data.maximum,
                                "minimum": data.minimum,
                            })
                            total_avg += data.average
                            max_value = max(max_value, data.maximum or 0)
                            min_value = min(min_value, data.minimum or 100)
                            data_points += 1

            result = {
                "resource_id": resource_id,
                "metric": "Percentage CPU",
                "period_start": start_time.isoformat(),
                "period_end": end_time.isoformat(),
                "average_utilization": round(total_avg / data_points, 2) if data_points > 0 else 0,
                "max_utilization": round(max_value, 2),
                "min_utilization": round(min_value, 2),
                "data_points": data_points,
                "time_series": time_series[-24:],  # Last 24 data points
            }

            logger.info(
                "VM CPU metrics retrieved",
                resource_id=resource_id,
                average=result["average_utilization"],
            )

            return result

        except Exception as e:
            self._handle_azure_exception(e, resource_id, "CPU metrics")

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        reraise=True,
    )
    async def get_vm_memory_utilization(
        self,
        resource_id: str,
        start_time: Optional[datetime] = None,
        end_time: Optional[datetime] = None,
        interval: str = "PT1H",
    ) -> dict[str, Any]:
        """
        Get memory utilization metrics for a virtual machine.
        
        Note: Requires Azure Monitor Agent or VM Insights enabled on the VM.

        Args:
            resource_id: Full ARM resource ID of the VM
            start_time: Start of time range
            end_time: End of time range
            interval: Metric granularity

        Returns:
            Dictionary with memory utilization data
        """
        if end_time is None:
            end_time = datetime.utcnow()
        if start_time is None:
            start_time = end_time - timedelta(days=7)

        logger.info(
            "Fetching VM memory metrics",
            resource_id=resource_id,
        )

        try:
            # Memory metrics require Azure Monitor Agent
            metrics = self.monitor_client.metrics.list(
                resource_uri=resource_id,
                timespan=f"{start_time.isoformat()}/{end_time.isoformat()}",
                interval=interval,
                metricnames="Available Memory Bytes",
                aggregation="Average,Maximum,Minimum",
            )

            time_series = []
            total_available = 0.0
            data_points = 0

            for metric in metrics.value:
                for ts in metric.timeseries:
                    for data in ts.data:
                        if data.average is not None:
                            # Convert bytes to GB
                            available_gb = data.average / (1024**3)
                            time_series.append({
                                "timestamp": data.time_stamp.isoformat(),
                                "available_gb": round(available_gb, 2),
                            })
                            total_available += available_gb
                            data_points += 1

            return {
                "resource_id": resource_id,
                "metric": "Available Memory",
                "period_start": start_time.isoformat(),
                "period_end": end_time.isoformat(),
                "average_available_gb": round(total_available / data_points, 2) if data_points > 0 else None,
                "data_points": data_points,
                "time_series": time_series[-24:],
                "note": "Memory utilization requires Azure Monitor Agent or VM Insights",
            }

        except Exception as e:
            self._handle_azure_exception(e, resource_id, "memory metrics")

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        reraise=True,
    )
    async def get_storage_transactions(
        self,
        resource_id: str,
        start_time: Optional[datetime] = None,
        end_time: Optional[datetime] = None,
        interval: str = "PT1H",
    ) -> dict[str, Any]:
        """
        Get transaction metrics for a storage account.

        Args:
            resource_id: Full ARM resource ID of the storage account
            start_time: Start of time range
            end_time: End of time range
            interval: Metric granularity

        Returns:
            Dictionary with transaction counts and patterns
        """
        if end_time is None:
            end_time = datetime.utcnow()
        if start_time is None:
            start_time = end_time - timedelta(days=7)

        logger.info("Fetching storage metrics", resource_id=resource_id)

        try:
            metrics = self.monitor_client.metrics.list(
                resource_uri=resource_id,
                timespan=f"{start_time.isoformat()}/{end_time.isoformat()}",
                interval=interval,
                metricnames="Transactions",
                aggregation="Total",
            )

            time_series = []
            total_transactions = 0

            for metric in metrics.value:
                for ts in metric.timeseries:
                    for data in ts.data:
                        if data.total is not None:
                            time_series.append({
                                "timestamp": data.time_stamp.isoformat(),
                                "transactions": int(data.total),
                            })
                            total_transactions += int(data.total)

            # Calculate average daily transactions
            days = (end_time - start_time).days or 1
            avg_daily = total_transactions / days

            return {
                "resource_id": resource_id,
                "metric": "Transactions",
                "period_start": start_time.isoformat(),
                "period_end": end_time.isoformat(),
                "total_transactions": total_transactions,
                "average_daily_transactions": round(avg_daily, 0),
                "time_series": time_series[-24:],
            }

        except Exception as e:
            self._handle_azure_exception(e, resource_id, "storage metrics")

    async def get_resource_utilization_summary(
        self,
        resource_id: str,
        resource_type: str,
    ) -> dict[str, Any]:
        """
        Get a utilization summary appropriate for the resource type.

        Args:
            resource_id: Full ARM resource ID
            resource_type: Azure resource type

        Returns:
            Dictionary with utilization metrics and recommendations
        """
        resource_type_lower = resource_type.lower()
        
        if "virtualmachines" in resource_type_lower:
            cpu_data = await self.get_vm_cpu_utilization(resource_id)
            
            # Determine utilization status
            avg_cpu = cpu_data.get("average_utilization", 0)
            
            if avg_cpu < 5:
                status = "idle"
                recommendation = "Consider shutting down or deallocating this VM"
            elif avg_cpu < 20:
                status = "underutilized"
                recommendation = "Consider rightsizing to a smaller VM SKU"
            elif avg_cpu > 90:
                status = "overutilized"
                recommendation = "Consider upgrading to a larger VM SKU"
            else:
                status = "optimal"
                recommendation = None
            
            return {
                "resource_id": resource_id,
                "resource_type": resource_type,
                "status": status,
                "cpu_utilization": cpu_data,
                "recommendation": recommendation,
            }
        
        elif "storageaccounts" in resource_type_lower:
            tx_data = await self.get_storage_transactions(resource_id)
            
            avg_daily = tx_data.get("average_daily_transactions", 0)
            
            if avg_daily < 100:
                status = "low_activity"
                recommendation = "Consider archive tier for infrequently accessed data"
            else:
                status = "active"
                recommendation = None
            
            return {
                "resource_id": resource_id,
                "resource_type": resource_type,
                "status": status,
                "transactions": tx_data,
                "recommendation": recommendation,
            }
        
        else:
            return {
                "resource_id": resource_id,
                "resource_type": resource_type,
                "status": "unknown",
                "message": f"Utilization analysis not available for {resource_type}",
            }

    def _handle_azure_exception(
        self,
        exc: Exception,
        resource_id: str,
        operation: str,
    ) -> None:
        """Handle Azure exceptions and convert to appropriate CloudOptima exceptions."""
        error_str = str(exc).lower()
        
        if "rate limit" in error_str or "429" in str(exc):
            raise AzureRateLimitError(
                retry_after=60,
                details={"resource_id": resource_id, "operation": operation},
            )
        
        if "not found" in error_str or "404" in str(exc):
            raise AzureResourceNotFoundError(
                resource_type="Resource",
                resource_id=resource_id,
            )
        
        if "authentication" in error_str or "401" in str(exc):
            raise AzureAuthenticationError(
                details={"operation": operation},
            )
        
        if "unavailable" in error_str or "503" in str(exc):
            raise AzureServiceUnavailableError(
                service="Azure Monitor",
                details={"resource_id": resource_id},
            )
        
        logger.error(
            "Azure Monitor error",
            error=str(exc),
            resource_id=resource_id,
            operation=operation,
        )
        raise AzureError(
            f"Failed to retrieve {operation}: {exc}",
            details={"resource_id": resource_id},
        )

    def close(self) -> None:
        """Close client connections."""
        self._credential = None
        self._monitor_client = None
        logger.info("Azure Monitor client closed")


# Singleton instance
_monitor_client: Optional[AzureMonitorClient] = None


def get_azure_monitor_client() -> AzureMonitorClient:
    """Get or create singleton Azure Monitor client instance."""
    global _monitor_client
    if _monitor_client is None:
        _monitor_client = AzureMonitorClient()
    return _monitor_client
