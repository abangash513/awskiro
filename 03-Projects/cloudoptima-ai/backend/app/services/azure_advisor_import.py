"""Azure Advisor Recommendations Import Service.

Imports cost optimization recommendations from Azure Advisor for multiple subscriptions.
"""

import logging
from datetime import datetime, timezone
from decimal import Decimal
from typing import List, Dict

from azure.identity import ClientSecretCredential
from azure.mgmt.advisor import AdvisorManagementClient
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core import get_settings
from app.models.recommendation import (
    Recommendation,
    RecommendationCategory,
    RecommendationImpact,
    RecommendationStatus,
)

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


def map_advisor_category(advisor_category: str) -> RecommendationCategory:
    """Map Azure Advisor category to our category enum."""
    category_map = {
        "Cost": RecommendationCategory.OTHER,
        "HighAvailability": RecommendationCategory.OTHER,
        "Performance": RecommendationCategory.OTHER,
        "Security": RecommendationCategory.OTHER,
        "OperationalExcellence": RecommendationCategory.OTHER,
    }
    return category_map.get(advisor_category, RecommendationCategory.OTHER)


def map_advisor_impact(advisor_impact: str) -> RecommendationImpact:
    """Map Azure Advisor impact to our impact enum."""
    impact_map = {
        "High": RecommendationImpact.HIGH,
        "Medium": RecommendationImpact.MEDIUM,
        "Low": RecommendationImpact.LOW,
    }
    return impact_map.get(advisor_impact, RecommendationImpact.MEDIUM)


def extract_savings_from_properties(properties: dict) -> tuple:
    """Extract savings estimates from Azure Advisor recommendation properties.
    
    Real Azure Advisor API format:
    {
      "properties": {
        "extendedProperties": {
          "savingsAmount": "450.00",
          "savingsCurrency": "USD"
        }
      }
    }
    """
    monthly_savings = Decimal("0.00")
    annual_savings = Decimal("0.00")
    currency = "USD"
    
    if properties and "extendedProperties" in properties:
        props = properties["extendedProperties"]
        if "savingsAmount" in props:
            try:
                monthly_savings = Decimal(str(props["savingsAmount"]))
                annual_savings = monthly_savings * 12
            except:
                pass
        if "savingsCurrency" in props:
            currency = props["savingsCurrency"]
    
    return monthly_savings, annual_savings, currency


async def import_advisor_recommendations(
    db: AsyncSession,
    subscription_ids: List[str] = None
) -> Dict[str, int]:
    """Import Azure Advisor recommendations for specified subscriptions.
    
    Parses real Azure Advisor API response format:
    {
      "id": "/subscriptions/{id}/resourceGroups/{rg}/providers/{provider}/{type}/{name}/providers/Microsoft.Advisor/recommendations/{rec-id}",
      "name": "{recommendation-id}",
      "properties": {
        "category": "Cost",
        "impact": "High",
        "impactedField": "Microsoft.Compute/virtualMachines",
        "impactedValue": "vm-prod-001",
        "lastUpdated": "2017-02-24T22:24:43.3216408Z",
        "risk": "Warning",
        "shortDescription": {
          "problem": "Right-size or shutdown underutilized virtual machines",
          "solution": "Right-size or shutdown underutilized virtual machines to optimize costs"
        },
        "extendedProperties": {
          "savingsAmount": "450.00",
          "savingsCurrency": "USD"
        },
        "description": "We've analyzed your virtual machine usage...",
        "potentialBenefits": "Save up to $450/month by optimizing VM sizes"
      }
    }
    
    Args:
        db: Database session
        subscription_ids: List of subscription IDs to import. If None, imports all from ACCOUNT_MAPPING.
    
    Returns:
        Dictionary with import statistics per subscription
    """
    if subscription_ids is None:
        subscription_ids = list(ACCOUNT_MAPPING.keys())
    
    credential = get_azure_credential()
    stats = {}
    
    for subscription_id in subscription_ids:
        account_info = ACCOUNT_MAPPING.get(subscription_id, {
            "account_name": "Unknown Account",
            "business_unit": "Unknown"
        })
        
        try:
            client = AdvisorManagementClient(credential, subscription_id)
            
            # Get cost recommendations only
            recommendations = client.recommendations.list(filter="Category eq 'Cost'")
            
            imported_count = 0
            for rec in recommendations:
                # Check if recommendation already exists
                existing_query = select(Recommendation).where(
                    Recommendation.azure_recommendation_id == rec.id
                )
                result = await db.execute(existing_query)
                existing = result.scalar_one_or_none()
                
                if existing:
                    continue  # Skip duplicates
                
                # Parse properties from real Azure Advisor format
                properties = rec.properties if hasattr(rec, 'properties') else {}
                
                # Extract savings from extendedProperties
                monthly_savings, annual_savings, currency = extract_savings_from_properties(properties)
                
                # Extract resource information from impactedField and impactedValue
                resource_type = properties.get("impactedField", "Unknown")
                resource_name = properties.get("impactedValue", "Unknown")
                
                # Extract descriptions from shortDescription
                short_desc = properties.get("shortDescription", {})
                title = short_desc.get("problem", "Azure Advisor Recommendation")
                solution = short_desc.get("solution", "")
                
                # Get full description and potential benefits
                description = properties.get("description", solution)
                potential_benefits = properties.get("potentialBenefits", "")
                if potential_benefits:
                    description = f"{description}\n\nPotential Benefits: {potential_benefits}"
                
                # Determine category based on recommendation type
                category = RecommendationCategory.OTHER
                problem_lower = title.lower()
                if "right size" in problem_lower or "resize" in problem_lower or "underutilized" in problem_lower:
                    category = RecommendationCategory.RIGHTSIZING
                elif "reserved" in problem_lower or "reservation" in problem_lower:
                    category = RecommendationCategory.RESERVED_INSTANCES
                elif "idle" in problem_lower or "unused" in problem_lower or "shutdown" in problem_lower:
                    category = RecommendationCategory.IDLE_RESOURCES
                elif "storage" in problem_lower or "tier" in problem_lower:
                    category = RecommendationCategory.STORAGE_OPTIMIZATION
                
                # Map impact from properties
                impact_str = properties.get("impact", "Medium")
                impact = map_advisor_impact(impact_str)
                
                # Create recommendation record
                recommendation = Recommendation(
                    subscription_id=subscription_id,
                    account_name=account_info["account_name"],
                    business_unit=account_info["business_unit"],
                    resource_group=rec.id.split("/resourceGroups/")[1].split("/")[0] if "/resourceGroups/" in rec.id else None,
                    resource_id=rec.id,
                    resource_name=resource_name,
                    resource_type=resource_type,
                    title=title,
                    description=description,
                    category=category,
                    impact=impact,
                    estimated_monthly_savings=monthly_savings,
                    estimated_annual_savings=annual_savings,
                    currency=currency,
                    confidence_score=Decimal("0.90"),  # Azure Advisor recommendations are high confidence
                    implementation_effort="medium",
                    risk_level="low",
                    status=RecommendationStatus.NEW,
                    source="azure_advisor",
                    azure_recommendation_id=rec.id,
                    valid_from=datetime.now(timezone.utc),
                )
                
                db.add(recommendation)
                imported_count += 1
            
            await db.commit()
            stats[subscription_id] = imported_count
            logger.info(f"Imported {imported_count} recommendations for subscription {subscription_id}")
            
        except Exception as e:
            logger.error(f"Failed to import recommendations for subscription {subscription_id}: {e}")
            stats[subscription_id] = 0
    
    return stats
