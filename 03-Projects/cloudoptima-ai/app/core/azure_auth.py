"""Azure authentication with automatic token refresh and health monitoring."""

import asyncio
import time
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from typing import Any, Optional

from azure.core.credentials import AccessToken, TokenCredential
from azure.identity import ClientSecretCredential, DefaultAzureCredential
from tenacity import retry, stop_after_attempt, wait_exponential

from app.core.config import get_settings
from app.core.exceptions import (
    AzureAuthenticationError,
    AzureCredentialsNotConfiguredError,
)
from app.core.logging import get_logger

logger = get_logger(__name__)

# Azure Management scope
AZURE_MANAGEMENT_SCOPE = "https://management.azure.com/.default"

# Token refresh buffer (refresh 5 minutes before expiry)
TOKEN_REFRESH_BUFFER_SECONDS = 300

# Health check interval
HEALTH_CHECK_INTERVAL_SECONDS = 60


@dataclass
class TokenInfo:
    """Information about a cached token."""
    
    token: str
    expires_on: float  # Unix timestamp
    scope: str
    obtained_at: datetime = field(default_factory=datetime.utcnow)
    refresh_count: int = 0
    
    @property
    def expires_at(self) -> datetime:
        """Get expiration as datetime."""
        return datetime.utcfromtimestamp(self.expires_on)
    
    @property
    def is_expired(self) -> bool:
        """Check if token is expired."""
        return time.time() >= self.expires_on
    
    @property
    def needs_refresh(self) -> bool:
        """Check if token should be refreshed (before buffer)."""
        return time.time() >= (self.expires_on - TOKEN_REFRESH_BUFFER_SECONDS)
    
    @property
    def time_until_expiry(self) -> timedelta:
        """Get time remaining until token expires."""
        remaining = self.expires_on - time.time()
        return timedelta(seconds=max(0, remaining))


@dataclass
class CredentialHealth:
    """Health status of Azure credentials."""
    
    is_healthy: bool
    last_check: datetime
    last_successful_auth: Optional[datetime] = None
    last_error: Optional[str] = None
    consecutive_failures: int = 0
    total_tokens_issued: int = 0
    
    def to_dict(self) -> dict[str, Any]:
        """Convert to dictionary for API response."""
        return {
            "is_healthy": self.is_healthy,
            "last_check": self.last_check.isoformat(),
            "last_successful_auth": self.last_successful_auth.isoformat() if self.last_successful_auth else None,
            "last_error": self.last_error,
            "consecutive_failures": self.consecutive_failures,
            "total_tokens_issued": self.total_tokens_issued,
        }


class AzureCredentialManager:
    """
    Manages Azure credentials with automatic token refresh.
    
    Features:
    - Automatic token caching and refresh before expiry
    - Health monitoring with failure tracking
    - Thread-safe token access
    - Support for multiple scopes
    - Graceful degradation on auth failures
    """
    
    def __init__(self) -> None:
        """Initialize credential manager."""
        self._settings = get_settings()
        self._credential: Optional[TokenCredential] = None
        self._token_cache: dict[str, TokenInfo] = {}
        self._lock = asyncio.Lock()
        self._health = CredentialHealth(
            is_healthy=False,
            last_check=datetime.utcnow(),
        )
        self._refresh_task: Optional[asyncio.Task] = None
        
    def _create_credential(self) -> TokenCredential:
        """Create Azure credential based on configuration."""
        if not self._settings.is_azure_configured:
            raise AzureCredentialsNotConfiguredError()
        
        try:
            credential = ClientSecretCredential(
                tenant_id=self._settings.azure_tenant_id,
                client_id=self._settings.azure_client_id,
                client_secret=self._settings.azure_client_secret,
            )
            
            logger.info(
                "Azure credential created",
                tenant_id=self._settings.azure_tenant_id[:8] + "...",
                client_id=self._settings.azure_client_id[:8] + "...",
            )
            
            return credential
            
        except Exception as e:
            logger.error("Failed to create Azure credential", error=str(e))
            raise AzureAuthenticationError(
                f"Failed to create Azure credentials: {e}",
                details={"tenant_id": self._settings.azure_tenant_id},
            ) from e
    
    @property
    def credential(self) -> TokenCredential:
        """Get the underlying credential object."""
        if self._credential is None:
            self._credential = self._create_credential()
        return self._credential
    
    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=1, max=10),
        reraise=True,
    )
    async def get_token(
        self,
        scope: str = AZURE_MANAGEMENT_SCOPE,
        force_refresh: bool = False,
    ) -> TokenInfo:
        """
        Get a valid access token, refreshing if necessary.
        
        Args:
            scope: OAuth scope for the token
            force_refresh: Force token refresh even if cached token is valid
            
        Returns:
            TokenInfo with the access token and metadata
        """
        async with self._lock:
            # Check cache first
            cached = self._token_cache.get(scope)
            
            if cached and not cached.needs_refresh and not force_refresh:
                logger.debug(
                    "Using cached token",
                    scope=scope,
                    expires_in=str(cached.time_until_expiry),
                )
                return cached
            
            # Need to refresh
            try:
                logger.info(
                    "Refreshing Azure token",
                    scope=scope,
                    reason="force" if force_refresh else ("expired" if (cached and cached.is_expired) else "proactive"),
                )
                
                # Get new token (run in executor since it's sync)
                loop = asyncio.get_event_loop()
                access_token: AccessToken = await loop.run_in_executor(
                    None,
                    lambda: self.credential.get_token(scope),
                )
                
                # Create token info
                refresh_count = (cached.refresh_count + 1) if cached else 0
                token_info = TokenInfo(
                    token=access_token.token,
                    expires_on=access_token.expires_on,
                    scope=scope,
                    refresh_count=refresh_count,
                )
                
                # Update cache
                self._token_cache[scope] = token_info
                
                # Update health
                self._health.is_healthy = True
                self._health.last_successful_auth = datetime.utcnow()
                self._health.last_error = None
                self._health.consecutive_failures = 0
                self._health.total_tokens_issued += 1
                
                logger.info(
                    "Token refreshed successfully",
                    scope=scope,
                    expires_in=str(token_info.time_until_expiry),
                    refresh_count=refresh_count,
                )
                
                return token_info
                
            except Exception as e:
                # Update health on failure
                self._health.is_healthy = False
                self._health.last_error = str(e)
                self._health.consecutive_failures += 1
                self._health.last_check = datetime.utcnow()
                
                logger.error(
                    "Token refresh failed",
                    scope=scope,
                    error=str(e),
                    consecutive_failures=self._health.consecutive_failures,
                )
                
                # Return cached token if still valid (graceful degradation)
                if cached and not cached.is_expired:
                    logger.warning(
                        "Using cached token despite refresh failure",
                        expires_in=str(cached.time_until_expiry),
                    )
                    return cached
                
                raise AzureAuthenticationError(
                    f"Failed to obtain Azure token: {e}",
                    details={"scope": scope},
                ) from e
    
    async def get_access_token(self, scope: str = AZURE_MANAGEMENT_SCOPE) -> str:
        """Get just the access token string."""
        token_info = await self.get_token(scope)
        return token_info.token
    
    async def check_health(self) -> CredentialHealth:
        """
        Perform a health check on Azure credentials.
        
        Returns:
            CredentialHealth with current status
        """
        self._health.last_check = datetime.utcnow()
        
        try:
            # Try to get a token
            await self.get_token(force_refresh=True)
            return self._health
            
        except Exception as e:
            logger.warning("Health check failed", error=str(e))
            return self._health
    
    def get_cached_token_info(self, scope: str = AZURE_MANAGEMENT_SCOPE) -> Optional[TokenInfo]:
        """Get cached token info without refreshing."""
        return self._token_cache.get(scope)
    
    def get_health(self) -> CredentialHealth:
        """Get current health status without checking."""
        return self._health
    
    async def start_background_refresh(self) -> None:
        """Start background token refresh task."""
        if self._refresh_task is not None:
            return
        
        async def refresh_loop():
            while True:
                try:
                    await asyncio.sleep(HEALTH_CHECK_INTERVAL_SECONDS)
                    
                    # Check each cached token
                    for scope in list(self._token_cache.keys()):
                        token_info = self._token_cache.get(scope)
                        if token_info and token_info.needs_refresh:
                            try:
                                await self.get_token(scope)
                            except Exception as e:
                                logger.warning(
                                    "Background refresh failed",
                                    scope=scope,
                                    error=str(e),
                                )
                                
                except asyncio.CancelledError:
                    logger.info("Background refresh task cancelled")
                    break
                except Exception as e:
                    logger.error("Background refresh error", error=str(e))
        
        self._refresh_task = asyncio.create_task(refresh_loop())
        logger.info("Background token refresh started")
    
    async def stop_background_refresh(self) -> None:
        """Stop background token refresh task."""
        if self._refresh_task is not None:
            self._refresh_task.cancel()
            try:
                await self._refresh_task
            except asyncio.CancelledError:
                pass
            self._refresh_task = None
            logger.info("Background token refresh stopped")
    
    def invalidate_cache(self, scope: Optional[str] = None) -> None:
        """
        Invalidate cached tokens.
        
        Args:
            scope: Specific scope to invalidate, or None for all
        """
        if scope:
            self._token_cache.pop(scope, None)
            logger.info("Token cache invalidated", scope=scope)
        else:
            self._token_cache.clear()
            logger.info("All token caches invalidated")
    
    def close(self) -> None:
        """Close credential manager and cleanup."""
        self._token_cache.clear()
        self._credential = None
        logger.info("Azure credential manager closed")


# Singleton instance
_credential_manager: Optional[AzureCredentialManager] = None


def get_credential_manager() -> AzureCredentialManager:
    """Get or create singleton credential manager."""
    global _credential_manager
    if _credential_manager is None:
        _credential_manager = AzureCredentialManager()
    return _credential_manager


async def get_azure_token(scope: str = AZURE_MANAGEMENT_SCOPE) -> str:
    """Convenience function to get an Azure access token."""
    manager = get_credential_manager()
    return await manager.get_access_token(scope)
