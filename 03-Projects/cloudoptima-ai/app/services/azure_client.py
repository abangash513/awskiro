"""Azure SDK client wrapper with connection management and token refresh."""

from datetime import datetime, timedelta
from typing import Any, Optional

from azure.core.exceptions import (
    ClientAuthenticationError,
    HttpResponseError,
    ResourceExistsError,
    ResourceNotFoundError as AzureResourceNotFound,
    ServiceRequestError,
    ServiceResponseError,
)
from azure.identity import ClientSecretCredential
from azure.mgmt.costmanagement import CostManagementClient
from azure.mgmt.costmanagement.models import (
    QueryDefinition,
    QueryDataset,
    QueryAggregation,
    QueryGrouping,
    QueryTimePeriod,
    TimeframeType,
    GranularityType,
    ExportType,
)
from azure.mgmt.subscription import SubscriptionClient
from azure.mgmt.resource import ResourceManagementClient
from tenacity import (
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential,
)

from app.core.config import get_settings
from app.core.exceptions import (
    AzureAuthenticationError,
    AzureCredentialsNotConfiguredError,
    AzureError,
    AzureQuotaExceededError,
    AzureRateLimitError,
    AzureResourceNotFoundError,
    AzureServiceUnavailableError,
)
from app.core.logging import get_logger

logger = get_logger(__name__)


# Retry configuration for transient failures
RETRY_CONFIG = {
    "stop": stop_after_attempt(3),
    "wait": wait_exponential(multiplier=1, min=2, max=30),
    "retry": retry_if_exception_type((ServiceRequestError, ServiceResponseError)),
    "reraise": True,
}


def _extract_retry_after(response) -> int:
    """Extract Retry-After header from Azure response."""
    try:
        if hasattr(response, "headers"):
            retry_after = response.headers.get("Retry-After", "60")
            return int(retry_after)
    except (ValueError, AttributeError):
        pass
    return 60


def _handle_azure_error(
    error: Exception,
    operation: str,
    resource_context: Optional[dict[str, Any]] = None,
) -> None:
    """
    Convert Azure SDK exceptions to CloudOptima exceptions.
    
    Args:
        error: The caught exception
        operation: Description of the operation being performed
        resource_context: Optional context about the resource being accessed
    """
    context = resource_context or {}
    
    # Authentication errors
    if isinstance(error, ClientAuthenticationError):
        logger.error(
            "Azure authentication failed",
            operation=operation,
            error=str(error),
        )
        raise AzureAuthenticationError(
            f"Authentication failed during {operation}",
            details=context,
        ) from error
    
    # HTTP response errors (most common)
    if isinstance(error, HttpResponseError):
        status_code = getattr(error, "status_code", None)
        error_code = getattr(error, "error", {})
        if hasattr(error_code, "code"):
            error_code = error_code.code
        
        logger.error(
            "Azure HTTP error",
            operation=operation,
            status_code=status_code,
            error_code=error_code,
            error=str(error),
        )
        
        # Rate limiting (429)
        if status_code == 429:
            retry_after = _extract_retry_after(getattr(error, "response", None))
            raise AzureRateLimitError(
                retry_after=retry_after,
                details={**context, "operation": operation},
            ) from error
        
        # Not found (404)
        if status_code == 404:
            raise AzureResourceNotFoundError(
                resource_type=context.get("resource_type", "Resource"),
                resource_id=context.get("resource_id", "unknown"),
            ) from error
        
        # Forbidden - often quota exceeded (403)
        if status_code == 403:
            error_str = str(error).lower()
            if "quota" in error_str or "limit" in error_str:
                raise AzureQuotaExceededError(
                    quota_type=context.get("resource_type", "unknown"),
                    message=f"Quota exceeded during {operation}",
                ) from error
            raise AzureAuthenticationError(
                f"Access denied during {operation}. Check service principal permissions.",
                details=context,
            ) from error
        
        # Bad request (400)
        if status_code == 400:
            raise AzureError(
                f"Invalid request during {operation}: {error}",
                error_code="AZURE_BAD_REQUEST",
                details={**context, "status_code": status_code},
            ) from error
        
        # Service unavailable (503) or other server errors
        if status_code and status_code >= 500:
            raise AzureServiceUnavailableError(
                service=context.get("service", "Azure"),
                details={**context, "status_code": status_code},
            ) from error
        
        # Generic HTTP error
        raise AzureError(
            f"Azure API error during {operation}: {error}",
            details={**context, "status_code": status_code},
        ) from error
    
    # Connection/network errors
    if isinstance(error, ServiceRequestError):
        logger.error(
            "Azure service connection failed",
            operation=operation,
            error=str(error),
        )
        raise AzureServiceUnavailableError(
            service=context.get("service", "Azure"),
            details={**context, "error_type": "connection_error"},
        ) from error
    
    # Response parsing errors
    if isinstance(error, ServiceResponseError):
        logger.error(
            "Azure response parsing failed",
            operation=operation,
            error=str(error),
        )
        raise AzureError(
            f"Failed to parse Azure response during {operation}",
            error_code="AZURE_RESPONSE_ERROR",
            details=context,
        ) from error
    
    # Resource already exists
    if isinstance(error, ResourceExistsError):
        raise AzureError(
            f"Resource already exists: {operation}",
            error_code="AZURE_RESOURCE_EXISTS",
            details=context,
        ) from error
    
    # Azure SDK ResourceNotFoundError
    if isinstance(error, AzureResourceNotFound):
        raise AzureResourceNotFoundError(
            resource_type=context.get("resource_type", "Resource"),
            resource_id=context.get("resource_id", "unknown"),
        ) from error
    
    # Unknown error - wrap it
    logger.error(
        "Unexpected Azure error",
        operation=operation,
        error_type=type(error).__name__,
        error=str(error),
    )
    raise AzureError(
        f"Unexpected error during {operation}: {error}",
        details={**context, "error_type": type(error).__name__},
    ) from error


class AzureClient:
    """
    Azure SDK client wrapper with retry logic, connection management,
    and comprehensive error handling.
    """

    def __init__(self) -> None:
        """Initialize Azure client."""
        self._settings = get_settings()
        self._credential: Optional[ClientSecretCredential] = None
        self._credential_created_at: Optional[datetime] = None
        self._cost_client: Optional[CostManagementClient] = None
        self._subscription_client: Optional[SubscriptionClient] = None
        self._resource_client: Optional[ResourceManagementClient] = None

    def _get_credential(self, force_refresh: bool = False) -> ClientSecretCredential:
        """
        Get or create Azure credential with automatic refresh.
        
        Args:
            force_refresh: Force recreation of credential object
        """
        # Check if we need to refresh (credentials older than 45 minutes)
        should_refresh = (
            self._credential is None
            or force_refresh
            or (
                self._credential_created_at
                and datetime.utcnow() - self._credential_created_at > timedelta(minutes=45)
            )
        )
        
        if should_refresh:
            if not self._settings.is_azure_configured:
                raise AzureCredentialsNotConfiguredError()
            
            try:
                logger.debug("Creating/refreshing Azure credential")
                
                self._credential = ClientSecretCredential(
                    tenant_id=self._settings.azure_tenant_id,
                    client_id=self._settings.azure_client_id,
                    client_secret=self._settings.azure_client_secret,
                )
                self._credential_created_at = datetime.utcnow()
                
                # Clear cached clients to use new credential
                if force_refresh:
                    self._cost_client = None
                    self._subscription_client = None
                    self._resource_client = None
                
                logger.info("Azure credential created/refreshed")
                
            except Exception as e:
                logger.error("Failed to create Azure credential", error=str(e))
                raise AzureAuthenticationError(
                    f"Failed to create Azure credentials: {e}",
                    details={"tenant_id": self._settings.azure_tenant_id[:8] + "..."},
                ) from e
        
        return self._credential

    def refresh_credential(self) -> None:
        """Force refresh of the Azure credential."""
        self._get_credential(force_refresh=True)

    @property
    def cost_client(self) -> CostManagementClient:
        """Get Cost Management client."""
        if self._cost_client is None:
            self._cost_client = CostManagementClient(
                credential=self._get_credential(),
                subscription_id=self._settings.azure_subscription_id,
            )
        return self._cost_client

    @property
    def subscription_client(self) -> SubscriptionClient:
        """Get Subscription client."""
        if self._subscription_client is None:
            self._subscription_client = SubscriptionClient(
                credential=self._get_credential(),
            )
        return self._subscription_client

    @property
    def resource_client(self) -> ResourceManagementClient:
        """Get Resource Management client."""
        if self._resource_client is None:
            self._resource_client = ResourceManagementClient(
                credential=self._get_credential(),
                subscription_id=self._settings.azure_subscription_id,
            )
        return self._resource_client

    @retry(**RETRY_CONFIG)
    async def get_cost_data(
        self,
        subscription_id: Optional[str] = None,
        resource_group: Optional[str] = None,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        granularity: str = "Daily",
    ) -> dict[str, Any]:
        """
        Query cost data from Azure Cost Management.

        Args:
            subscription_id: Target subscription (defaults to configured)
            resource_group: Optional resource group filter
            start_date: Start date for cost query
            end_date: End date for cost query
            granularity: Data granularity (Daily, Monthly)

        Returns:
            Cost query results

        Raises:
            AzureAuthenticationError: If authentication fails
            AzureRateLimitError: If rate limited by Azure
            AzureResourceNotFoundError: If subscription/resource group not found
            AzureError: For other Azure API errors
        """
        subscription_id = subscription_id or self._settings.azure_subscription_id
        
        # Default to last 30 days
        if end_date is None:
            end_date = datetime.utcnow()
        if start_date is None:
            start_date = end_date - timedelta(days=self._settings.cost_lookback_days)

        # Build scope
        if resource_group:
            scope = f"/subscriptions/{subscription_id}/resourceGroups/{resource_group}"
        else:
            scope = f"/subscriptions/{subscription_id}"

        logger.info(
            "Querying Azure cost data",
            scope=scope,
            start_date=start_date.isoformat(),
            end_date=end_date.isoformat(),
        )

        try:
            # Build query
            query = QueryDefinition(
                type=ExportType.ACTUAL_COST,
                timeframe=TimeframeType.CUSTOM,
                time_period=QueryTimePeriod(
                    from_property=start_date,
                    to=end_date,
                ),
                dataset=QueryDataset(
                    granularity=GranularityType(granularity.upper()),
                    aggregation={
                        "totalCost": QueryAggregation(
                            name="Cost",
                            function="Sum",
                        ),
                        "totalCostUSD": QueryAggregation(
                            name="CostUSD",
                            function="Sum",
                        ),
                    },
                    grouping=[
                        QueryGrouping(type="Dimension", name="ServiceName"),
                        QueryGrouping(type="Dimension", name="ResourceGroup"),
                        QueryGrouping(type="Dimension", name="ResourceType"),
                    ],
                ),
            )

            # Execute query
            result = self.cost_client.query.usage(scope=scope, parameters=query)

            # Process results
            columns = [col.name for col in result.columns]
            rows = []
            for row in result.rows:
                rows.append(dict(zip(columns, row)))

            logger.info(
                "Cost query completed",
                row_count=len(rows),
                scope=scope,
            )

            return {
                "columns": columns,
                "rows": rows,
                "scope": scope,
                "start_date": start_date.isoformat(),
                "end_date": end_date.isoformat(),
            }

        except Exception as e:
            _handle_azure_error(
                e,
                operation="cost data query",
                resource_context={
                    "service": "Cost Management",
                    "resource_type": "Subscription/ResourceGroup",
                    "resource_id": scope,
                },
            )

    @retry(**RETRY_CONFIG)
    async def list_subscriptions(self) -> list[dict[str, Any]]:
        """
        List all accessible Azure subscriptions.

        Returns:
            List of subscription details

        Raises:
            AzureAuthenticationError: If authentication fails
            AzureError: For other Azure API errors
        """
        try:
            subscriptions = []
            for sub in self.subscription_client.subscriptions.list():
                subscriptions.append({
                    "id": sub.subscription_id,
                    "name": sub.display_name,
                    "state": sub.state,
                    "tenant_id": sub.tenant_id,
                })
            
            logger.info("Listed subscriptions", count=len(subscriptions))
            return subscriptions

        except Exception as e:
            _handle_azure_error(
                e,
                operation="list subscriptions",
                resource_context={"service": "Subscription Management"},
            )

    @retry(**RETRY_CONFIG)
    async def list_resource_groups(
        self, subscription_id: Optional[str] = None
    ) -> list[dict[str, Any]]:
        """
        List resource groups in a subscription.

        Args:
            subscription_id: Target subscription (defaults to configured)

        Returns:
            List of resource group details

        Raises:
            AzureAuthenticationError: If authentication fails
            AzureResourceNotFoundError: If subscription not found
            AzureError: For other Azure API errors
        """
        subscription_id = subscription_id or self._settings.azure_subscription_id
        
        try:
            # Use different client for different subscription
            if subscription_id != self._settings.azure_subscription_id:
                client = ResourceManagementClient(
                    credential=self._get_credential(),
                    subscription_id=subscription_id,
                )
            else:
                client = self.resource_client

            resource_groups = []
            for rg in client.resource_groups.list():
                resource_groups.append({
                    "name": rg.name,
                    "location": rg.location,
                    "tags": rg.tags or {},
                    "provisioning_state": rg.properties.provisioning_state if rg.properties else None,
                })

            logger.info("Listed resource groups", count=len(resource_groups))
            return resource_groups

        except Exception as e:
            _handle_azure_error(
                e,
                operation="list resource groups",
                resource_context={
                    "service": "Resource Management",
                    "resource_type": "Subscription",
                    "resource_id": subscription_id,
                },
            )

    async def test_connection(self) -> dict[str, Any]:
        """
        Test Azure connection and credential validity.

        Returns:
            Connection test results including subscription info
        """
        try:
            # Force credential refresh and test
            self._get_credential(force_refresh=True)
            
            # Try to list subscriptions as a connection test
            subscriptions = await self.list_subscriptions()
            
            return {
                "status": "connected",
                "subscription_count": len(subscriptions),
                "default_subscription": self._settings.azure_subscription_id,
                "credential_age_seconds": (
                    datetime.utcnow() - self._credential_created_at
                ).total_seconds() if self._credential_created_at else 0,
            }
        except Exception as e:
            return {
                "status": "error",
                "error": str(e),
                "error_type": type(e).__name__,
            }

    def close(self) -> None:
        """Close client connections and cleanup."""
        self._credential = None
        self._credential_created_at = None
        self._cost_client = None
        self._subscription_client = None
        self._resource_client = None
        logger.info("Azure client connections closed")


# Singleton instance
_azure_client: Optional[AzureClient] = None


def get_azure_client() -> AzureClient:
    """Get or create singleton Azure client instance."""
    global _azure_client
    if _azure_client is None:
        _azure_client = AzureClient()
    return _azure_client
