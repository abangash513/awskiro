"""Azure Advisor client for retrieving cost optimization recommendations."""

from datetime import datetime
from decimal import Decimal
from typing import Any, Optional

from azure.identity import ClientSecretCredential
from azure.mgmt.advisor import AdvisorManagementClient
from azure.mgmt.advisor.models import ResourceRecommendationBase
from tenacity import retry, stop_after_attempt, wait_exponential

from app.core.config import get_settings
from app.core.exceptions import (
    AzureAuthenticationError,
    AzureCredentialsNotConfiguredError,
    AzureError,
    AzureRateLimitError,
    AzureServiceUnavailableError,
)
from app.core.logging import get_logger

logger = get_logger(__name__)


# Mapping of Azure Advisor categories to our categories
CATEGORY_MAP = {
    "Cost": "cost_optimization",
    "HighAvailability": "reliability",
    "Performance": "performance",
    "Security": "security",
    "OperationalExcellence": "operational",
}

# Mapping of impact levels
IMPACT_MAP = {
    "High": "high",
    "Medium": "medium",
    "Low": "low",
}


class AzureAdvisorClient:
    """
    Azure Advisor client for retrieving and managing recommendations.
    
    Azure Advisor provides personalized cloud consultant recommendations
    for cost, security, reliability, operational excellence, and performance.
    """

    def __init__(self) -> None:
        """Initialize Azure Advisor client."""
        self._settings = get_settings()
        self._credential: Optional[ClientSecretCredential] = None
        self._advisor_client: Optional[AdvisorManagementClient] = None

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
    def advisor_client(self) -> AdvisorManagementClient:
        """Get Advisor Management client."""
        if self._advisor_client is None:
            self._advisor_client = AdvisorManagementClient(
                credential=self._get_credential(),
                subscription_id=self._settings.azure_subscription_id,
            )
        return self._advisor_client

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        reraise=True,
    )
    async def get_cost_recommendations(
        self,
        subscription_id: Optional[str] = None,
        resource_group: Optional[str] = None,
    ) -> list[dict[str, Any]]:
        """
        Get cost optimization recommendations from Azure Advisor.

        Args:
            subscription_id: Target subscription (defaults to configured)
            resource_group: Optional resource group filter

        Returns:
            List of recommendation dictionaries
        """
        subscription_id = subscription_id or self._settings.azure_subscription_id

        logger.info(
            "Fetching Azure Advisor cost recommendations",
            subscription_id=subscription_id,
            resource_group=resource_group,
        )

        try:
            # List all recommendations and filter by category
            recommendations = []
            
            # Use the recommendations operations to list recommendations
            advisor_recs = self.advisor_client.recommendations.list(
                filter="Category eq 'Cost'"
            )

            for rec in advisor_recs:
                # Filter by resource group if specified
                if resource_group:
                    if not rec.resource_metadata or resource_group.lower() not in (
                        rec.resource_metadata.resource_id or ""
                    ).lower():
                        continue

                recommendation = self._parse_recommendation(rec)
                if recommendation:
                    recommendations.append(recommendation)

            logger.info(
                "Azure Advisor recommendations retrieved",
                count=len(recommendations),
                subscription_id=subscription_id,
            )

            return recommendations

        except Exception as e:
            self._handle_azure_exception(e, "cost recommendations")

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        reraise=True,
    )
    async def get_all_recommendations(
        self,
        subscription_id: Optional[str] = None,
        categories: Optional[list[str]] = None,
    ) -> list[dict[str, Any]]:
        """
        Get all recommendations from Azure Advisor.

        Args:
            subscription_id: Target subscription (defaults to configured)
            categories: Optional list of categories to filter (Cost, Security, etc.)

        Returns:
            List of recommendation dictionaries
        """
        subscription_id = subscription_id or self._settings.azure_subscription_id

        logger.info(
            "Fetching all Azure Advisor recommendations",
            subscription_id=subscription_id,
            categories=categories,
        )

        try:
            recommendations = []
            
            # Build filter if categories specified
            filter_str = None
            if categories:
                category_filters = [f"Category eq '{cat}'" for cat in categories]
                filter_str = " or ".join(category_filters)

            advisor_recs = self.advisor_client.recommendations.list(
                filter=filter_str
            )

            for rec in advisor_recs:
                recommendation = self._parse_recommendation(rec)
                if recommendation:
                    recommendations.append(recommendation)

            logger.info(
                "Azure Advisor recommendations retrieved",
                count=len(recommendations),
            )

            return recommendations

        except Exception as e:
            self._handle_azure_exception(e, "all recommendations")

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        reraise=True,
    )
    async def get_recommendation_details(
        self,
        recommendation_id: str,
        resource_uri: str,
    ) -> Optional[dict[str, Any]]:
        """
        Get detailed information about a specific recommendation.

        Args:
            recommendation_id: The recommendation ID (GUID)
            resource_uri: The resource URI for the recommendation

        Returns:
            Detailed recommendation dictionary or None
        """
        logger.info(
            "Fetching recommendation details",
            recommendation_id=recommendation_id,
        )

        try:
            rec = self.advisor_client.recommendations.get(
                resource_uri=resource_uri,
                recommendation_id=recommendation_id,
            )

            return self._parse_recommendation(rec, include_details=True)

        except Exception as e:
            self._handle_azure_exception(e, f"recommendation {recommendation_id}")

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        reraise=True,
    )
    async def suppress_recommendation(
        self,
        recommendation_id: str,
        resource_uri: str,
        suppression_name: str,
        duration: Optional[str] = None,
    ) -> bool:
        """
        Suppress (snooze) a recommendation.

        Args:
            recommendation_id: The recommendation ID
            resource_uri: The resource URI
            suppression_name: Name for the suppression
            duration: Optional duration (e.g., "7.00:00:00" for 7 days)

        Returns:
            True if suppression was successful
        """
        logger.info(
            "Suppressing recommendation",
            recommendation_id=recommendation_id,
            suppression_name=suppression_name,
        )

        try:
            self.advisor_client.suppressions.create(
                resource_uri=resource_uri,
                recommendation_id=recommendation_id,
                name=suppression_name,
                ttl=duration,
            )
            
            logger.info(
                "Recommendation suppressed",
                recommendation_id=recommendation_id,
            )
            return True

        except Exception as e:
            logger.error(
                "Failed to suppress recommendation",
                recommendation_id=recommendation_id,
                error=str(e),
            )
            return False

    async def generate_recommendations_refresh(self) -> bool:
        """
        Trigger a refresh of Azure Advisor recommendations.
        
        Note: Recommendations are typically refreshed every 24 hours automatically.
        This triggers an immediate refresh.

        Returns:
            True if refresh was triggered successfully
        """
        logger.info("Triggering Advisor recommendations refresh")

        try:
            # Generate recommendations refresh
            self.advisor_client.recommendations.generate()
            logger.info("Advisor recommendations refresh triggered")
            return True
        except Exception as e:
            logger.error("Failed to trigger recommendations refresh", error=str(e))
            return False

    def _parse_recommendation(
        self,
        rec: ResourceRecommendationBase,
        include_details: bool = False,
    ) -> Optional[dict[str, Any]]:
        """Parse Azure Advisor recommendation into standardized format."""
        try:
            # Extract resource information
            resource_id = None
            resource_name = None
            resource_group = None
            resource_type = None

            if rec.resource_metadata:
                resource_id = rec.resource_metadata.resource_id
                if resource_id:
                    # Parse resource ID components
                    parts = resource_id.split("/")
                    for i, part in enumerate(parts):
                        if part.lower() == "resourcegroups" and i + 1 < len(parts):
                            resource_group = parts[i + 1]
                        if part.lower() == "providers" and i + 2 < len(parts):
                            resource_type = f"{parts[i + 1]}/{parts[i + 2]}"
                    resource_name = parts[-1] if parts else None

            # Extract impact and savings information
            impact = IMPACT_MAP.get(rec.impact, "medium") if rec.impact else "medium"
            category = CATEGORY_MAP.get(rec.category, "cost_optimization") if rec.category else "cost_optimization"

            # Parse extended properties for savings estimates
            monthly_savings = None
            annual_savings = None
            currency = "USD"

            if rec.extended_properties:
                props = rec.extended_properties
                
                # Different recommendations have different property names
                savings_amount = (
                    props.get("savingsAmount") or
                    props.get("annualSavingsAmount") or
                    props.get("estimatedAnnualSavings")
                )
                
                if savings_amount:
                    try:
                        annual_savings = Decimal(str(savings_amount))
                        monthly_savings = annual_savings / 12
                    except (ValueError, TypeError):
                        pass

                currency = props.get("savingsCurrency", "USD")

            # Build recommendation dictionary
            recommendation = {
                "id": rec.id,
                "name": rec.name,
                "type": rec.type,
                "category": category,
                "impact": impact,
                "impacted_field": rec.impacted_field,
                "impacted_value": rec.impacted_value,
                "resource_id": resource_id,
                "resource_name": resource_name,
                "resource_group": resource_group,
                "resource_type": resource_type,
                "short_description": None,
                "description": None,
                "remediation_steps": None,
                "estimated_monthly_savings": float(monthly_savings) if monthly_savings else None,
                "estimated_annual_savings": float(annual_savings) if annual_savings else None,
                "currency": currency,
                "last_updated": rec.last_updated.isoformat() if rec.last_updated else None,
            }

            # Parse short description
            if rec.short_description:
                recommendation["short_description"] = rec.short_description.problem
                if rec.short_description.solution:
                    recommendation["description"] = rec.short_description.solution

            # Include extended details if requested
            if include_details and rec.extended_properties:
                recommendation["extended_properties"] = dict(rec.extended_properties)

            return recommendation

        except Exception as e:
            logger.warning(
                "Failed to parse recommendation",
                error=str(e),
                rec_id=getattr(rec, "id", "unknown"),
            )
            return None

    def _handle_azure_exception(
        self,
        exc: Exception,
        operation: str,
    ) -> None:
        """Handle Azure exceptions and convert to appropriate CloudOptima exceptions."""
        error_str = str(exc).lower()
        
        if "rate limit" in error_str or "429" in str(exc):
            raise AzureRateLimitError(
                retry_after=60,
                details={"operation": operation},
            )
        
        if "authentication" in error_str or "401" in str(exc):
            raise AzureAuthenticationError(
                details={"operation": operation},
            )
        
        if "unavailable" in error_str or "503" in str(exc):
            raise AzureServiceUnavailableError(
                service="Azure Advisor",
                details={"operation": operation},
            )
        
        logger.error(
            "Azure Advisor error",
            error=str(exc),
            operation=operation,
        )
        raise AzureError(
            f"Failed to retrieve {operation}: {exc}",
            details={"operation": operation},
        )

    def close(self) -> None:
        """Close client connections."""
        self._credential = None
        self._advisor_client = None
        logger.info("Azure Advisor client closed")


# Singleton instance
_advisor_client: Optional[AzureAdvisorClient] = None


def get_azure_advisor_client() -> AzureAdvisorClient:
    """Get or create singleton Azure Advisor client instance."""
    global _advisor_client
    if _advisor_client is None:
        _advisor_client = AzureAdvisorClient()
    return _advisor_client
