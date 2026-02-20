"""Azure resource endpoints."""

from typing import Any, Optional

from fastapi import APIRouter, Depends

from app.core.auth import APIKeyInfo, get_api_key_optional, require_scope, Scopes
from app.core.config import get_settings
from app.core.logging import get_logger
from app.schemas.common import SubscriptionInfo, ResourceGroupInfo
from app.services.azure_client import get_azure_client

router = APIRouter()
logger = get_logger(__name__)


def get_read_auth():
    """Get read authentication dependency."""
    settings = get_settings()
    if settings.auth_enabled and settings.api_key:
        return require_scope(Scopes.AZURE_READ)
    return get_api_key_optional


@router.get("/health")
async def get_azure_health(
    _auth: Optional[APIKeyInfo] = Depends(get_read_auth()),
) -> dict[str, Any]:
    """
    Check Azure credential health status.
    
    Returns information about credential validity, token status,
    and any authentication issues.
    
    **Requires scope:** `azure:read` or `*`
    """
    azure = get_azure_client()
    health = await azure.get_credential_health()
    
    return {
        "status": "healthy" if health.get("is_healthy") else "unhealthy",
        "credentials": health,
    }


@router.get("/subscriptions", response_model=list[SubscriptionInfo])
async def list_subscriptions(
    _auth: Optional[APIKeyInfo] = Depends(get_read_auth()),
) -> list[SubscriptionInfo]:
    """
    List all accessible Azure subscriptions.
    
    Returns list of subscriptions the service principal has access to.
    
    **Requires scope:** `azure:read` or `*`
    """
    azure = get_azure_client()
    subscriptions = await azure.list_subscriptions()
    
    logger.info("Listed Azure subscriptions via API", count=len(subscriptions))
    
    return [SubscriptionInfo(**sub) for sub in subscriptions]


@router.get("/subscriptions/{subscription_id}/resource-groups", response_model=list[ResourceGroupInfo])
async def list_resource_groups(
    subscription_id: str,
    _auth: Optional[APIKeyInfo] = Depends(get_read_auth()),
) -> list[ResourceGroupInfo]:
    """
    List resource groups in a subscription.
    
    Args:
        subscription_id: Azure subscription ID
        
    Returns list of resource groups.
    
    **Requires scope:** `azure:read` or `*`
    """
    azure = get_azure_client()
    resource_groups = await azure.list_resource_groups(subscription_id)
    
    logger.info(
        "Listed resource groups via API",
        subscription_id=subscription_id,
        count=len(resource_groups),
    )
    
    return [ResourceGroupInfo(**rg) for rg in resource_groups]


@router.post("/token/refresh")
async def refresh_azure_token(
    _auth: Optional[APIKeyInfo] = Depends(require_scope(Scopes.ADMIN)),
) -> dict[str, Any]:
    """
    Force refresh of Azure authentication token.
    
    Invalidates cached tokens and obtains fresh credentials.
    Useful after credential rotation or when troubleshooting auth issues.
    
    **Requires scope:** `*` (admin only)
    """
    from app.core.azure_auth import get_credential_manager
    
    manager = get_credential_manager()
    
    # Invalidate existing cache
    manager.invalidate_cache()
    
    # Get fresh token
    token_info = await manager.get_token(force_refresh=True)
    
    logger.info(
        "Azure token refreshed via API",
        expires_in=str(token_info.time_until_expiry),
    )
    
    return {
        "status": "refreshed",
        "expires_at": token_info.expires_at.isoformat(),
        "expires_in_seconds": int(token_info.time_until_expiry.total_seconds()),
    }
