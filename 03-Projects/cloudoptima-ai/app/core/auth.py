"""Authentication middleware and utilities for CloudOptima AI."""

import hashlib
import hmac
import secrets
import time
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Annotated, Optional

from fastapi import Depends, Header, Request
from fastapi.security import APIKeyHeader

from app.core.config import get_settings
from app.core.exceptions import (
    ExpiredAPIKeyError,
    InsufficientPermissionsError,
    InvalidAPIKeyError,
)
from app.core.logging import get_logger

logger = get_logger(__name__)

# API Key header scheme
api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)


@dataclass
class APIKeyInfo:
    """Information about an authenticated API key."""

    key_id: str
    name: str
    scopes: list[str]
    created_at: datetime
    expires_at: Optional[datetime] = None
    rate_limit: int = 1000  # requests per hour
    is_active: bool = True

    def has_scope(self, scope: str) -> bool:
        """Check if key has a specific scope."""
        return "*" in self.scopes or scope in self.scopes

    def is_expired(self) -> bool:
        """Check if key has expired."""
        if self.expires_at is None:
            return False
        return datetime.utcnow() > self.expires_at


# =============================================================================
# API Key Storage (In-memory for now, replace with DB in production)
# =============================================================================

class APIKeyStore:
    """
    API Key storage and validation.
    
    In production, replace this with database-backed storage.
    Keys are stored as hashed values for security.
    """

    def __init__(self) -> None:
        self._keys: dict[str, APIKeyInfo] = {}
        self._key_hashes: dict[str, str] = {}  # hash -> key_id
        self._initialize_default_keys()

    def _hash_key(self, api_key: str) -> str:
        """Hash an API key for secure storage."""
        return hashlib.sha256(api_key.encode()).hexdigest()

    def _initialize_default_keys(self) -> None:
        """Initialize default API keys from settings."""
        settings = get_settings()
        
        # Create a default admin key if configured
        if hasattr(settings, 'api_key') and settings.api_key:
            self.register_key(
                api_key=settings.api_key,
                key_id="default-admin",
                name="Default Admin Key",
                scopes=["*"],  # Full access
            )
        
        # Development key (only if debug mode)
        if settings.api_debug:
            dev_key = "dev-key-cloudoptima-2024"
            self.register_key(
                api_key=dev_key,
                key_id="dev-key",
                name="Development Key",
                scopes=["*"],
            )
            logger.warning(
                "Development API key enabled",
                key_prefix=dev_key[:8],
            )

    def register_key(
        self,
        api_key: str,
        key_id: str,
        name: str,
        scopes: list[str],
        expires_at: Optional[datetime] = None,
        rate_limit: int = 1000,
    ) -> APIKeyInfo:
        """Register a new API key."""
        key_hash = self._hash_key(api_key)
        
        info = APIKeyInfo(
            key_id=key_id,
            name=name,
            scopes=scopes,
            created_at=datetime.utcnow(),
            expires_at=expires_at,
            rate_limit=rate_limit,
        )
        
        self._keys[key_id] = info
        self._key_hashes[key_hash] = key_id
        
        logger.info("API key registered", key_id=key_id, name=name)
        return info

    def validate_key(self, api_key: str) -> Optional[APIKeyInfo]:
        """Validate an API key and return its info."""
        key_hash = self._hash_key(api_key)
        key_id = self._key_hashes.get(key_hash)
        
        if key_id is None:
            return None
        
        info = self._keys.get(key_id)
        if info is None or not info.is_active:
            return None
        
        return info

    def revoke_key(self, key_id: str) -> bool:
        """Revoke an API key."""
        if key_id in self._keys:
            self._keys[key_id].is_active = False
            logger.info("API key revoked", key_id=key_id)
            return True
        return False

    @staticmethod
    def generate_api_key() -> str:
        """Generate a new secure API key."""
        return f"co_{secrets.token_urlsafe(32)}"


# Singleton key store
_key_store: Optional[APIKeyStore] = None


def get_key_store() -> APIKeyStore:
    """Get or create the API key store singleton."""
    global _key_store
    if _key_store is None:
        _key_store = APIKeyStore()
    return _key_store


# =============================================================================
# Rate Limiting
# =============================================================================

class RateLimiter:
    """Simple in-memory rate limiter."""

    def __init__(self) -> None:
        # key_id -> list of request timestamps
        self._requests: dict[str, list[float]] = {}
        self._window_seconds = 3600  # 1 hour window

    def is_allowed(self, key_id: str, limit: int) -> tuple[bool, int]:
        """
        Check if request is allowed under rate limit.
        
        Returns:
            Tuple of (is_allowed, remaining_requests)
        """
        now = time.time()
        window_start = now - self._window_seconds
        
        # Get and clean up old requests
        requests = self._requests.get(key_id, [])
        requests = [ts for ts in requests if ts > window_start]
        
        remaining = limit - len(requests)
        
        if remaining <= 0:
            self._requests[key_id] = requests
            return False, 0
        
        # Record this request
        requests.append(now)
        self._requests[key_id] = requests
        
        return True, remaining - 1

    def get_reset_time(self, key_id: str) -> int:
        """Get seconds until rate limit resets."""
        requests = self._requests.get(key_id, [])
        if not requests:
            return 0
        
        oldest = min(requests)
        reset_at = oldest + self._window_seconds
        return max(0, int(reset_at - time.time()))


# Singleton rate limiter
_rate_limiter: Optional[RateLimiter] = None


def get_rate_limiter() -> RateLimiter:
    """Get or create the rate limiter singleton."""
    global _rate_limiter
    if _rate_limiter is None:
        _rate_limiter = RateLimiter()
    return _rate_limiter


# =============================================================================
# Authentication Dependencies
# =============================================================================

async def get_api_key_optional(
    api_key: Annotated[Optional[str], Depends(api_key_header)],
) -> Optional[APIKeyInfo]:
    """
    Optional API key validation.
    
    Returns None if no key provided, raises if invalid key provided.
    """
    if api_key is None:
        return None
    
    store = get_key_store()
    key_info = store.validate_key(api_key)
    
    if key_info is None:
        logger.warning("Invalid API key attempt", key_prefix=api_key[:8] if len(api_key) > 8 else "***")
        raise InvalidAPIKeyError()
    
    if key_info.is_expired():
        logger.warning("Expired API key used", key_id=key_info.key_id)
        raise ExpiredAPIKeyError()
    
    return key_info


async def get_api_key_required(
    api_key: Annotated[Optional[str], Depends(api_key_header)],
) -> APIKeyInfo:
    """
    Required API key validation.
    
    Raises InvalidAPIKeyError if no key or invalid key provided.
    """
    if api_key is None:
        raise InvalidAPIKeyError("API key is required")
    
    key_info = await get_api_key_optional(api_key)
    
    if key_info is None:
        raise InvalidAPIKeyError()
    
    return key_info


def require_scope(scope: str):
    """
    Dependency factory for scope-based authorization.
    
    Usage:
        @router.post("/admin/action")
        async def admin_action(
            key: APIKeyInfo = Depends(require_scope("admin"))
        ):
            ...
    """
    async def check_scope(
        key_info: Annotated[APIKeyInfo, Depends(get_api_key_required)],
    ) -> APIKeyInfo:
        if not key_info.has_scope(scope):
            logger.warning(
                "Insufficient permissions",
                key_id=key_info.key_id,
                required_scope=scope,
                has_scopes=key_info.scopes,
            )
            raise InsufficientPermissionsError(
                f"Scope '{scope}' is required for this operation"
            )
        return key_info
    
    return check_scope


async def rate_limit_check(
    request: Request,
    key_info: Annotated[Optional[APIKeyInfo], Depends(get_api_key_optional)],
) -> None:
    """
    Rate limiting dependency.
    
    Checks rate limit based on API key or client IP.
    """
    limiter = get_rate_limiter()
    
    if key_info:
        identifier = key_info.key_id
        limit = key_info.rate_limit
    else:
        # Use client IP for unauthenticated requests
        identifier = f"ip:{request.client.host}" if request.client else "ip:unknown"
        limit = 100  # Lower limit for unauthenticated requests
    
    allowed, remaining = limiter.is_allowed(identifier, limit)
    
    # Set rate limit headers
    request.state.rate_limit_remaining = remaining
    request.state.rate_limit_limit = limit
    request.state.rate_limit_reset = limiter.get_reset_time(identifier)
    
    if not allowed:
        from fastapi import HTTPException
        raise HTTPException(
            status_code=429,
            detail={
                "error_code": "RATE_LIMITED",
                "message": "Rate limit exceeded",
                "retry_after_seconds": request.state.rate_limit_reset,
            },
            headers={
                "Retry-After": str(request.state.rate_limit_reset),
                "X-RateLimit-Limit": str(limit),
                "X-RateLimit-Remaining": "0",
                "X-RateLimit-Reset": str(request.state.rate_limit_reset),
            },
        )


# =============================================================================
# Scopes
# =============================================================================

class Scopes:
    """Available API scopes."""
    
    # Full access
    ADMIN = "*"
    
    # Cost management
    COSTS_READ = "costs:read"
    COSTS_WRITE = "costs:write"
    
    # Budget management
    BUDGETS_READ = "budgets:read"
    BUDGETS_WRITE = "budgets:write"
    
    # Recommendations
    RECOMMENDATIONS_READ = "recommendations:read"
    RECOMMENDATIONS_WRITE = "recommendations:write"
    
    # Azure resources
    AZURE_READ = "azure:read"
