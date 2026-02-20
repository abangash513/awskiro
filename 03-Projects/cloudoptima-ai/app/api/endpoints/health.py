"""Health check endpoints."""

from datetime import datetime
from typing import Any

from fastapi import APIRouter

from app import __version__
from app.core.config import get_settings
from app.core.logging import get_logger

router = APIRouter()
logger = get_logger(__name__)


@router.get("/")
async def health_check() -> dict[str, Any]:
    """
    Basic health check endpoint.
    
    Returns application status and version information.
    No authentication required.
    """
    settings = get_settings()
    
    return {
        "status": "healthy",
        "version": __version__,
        "timestamp": datetime.utcnow().isoformat(),
        "environment": {
            "debug": settings.api_debug,
            "auth_enabled": settings.auth_enabled,
        },
    }


@router.get("/ready")
async def readiness_check() -> dict[str, Any]:
    """
    Readiness check for Kubernetes/container orchestration.
    
    Verifies the application is ready to receive traffic.
    Checks database connectivity and Azure credentials.
    """
    from sqlalchemy import text
    
    from app.core.database import get_session
    from app.core.azure_auth import get_credential_manager
    
    checks = {
        "database": False,
        "azure_credentials": False,
    }
    errors = []
    
    # Check database
    try:
        async with get_session() as session:
            await session.execute(text("SELECT 1"))
        checks["database"] = True
    except Exception as e:
        errors.append(f"Database: {str(e)}")
        logger.warning("Readiness check: database failed", error=str(e))
    
    # Check Azure credentials
    try:
        settings = get_settings()
        if settings.is_azure_configured:
            manager = get_credential_manager()
            health = manager.get_health()
            
            # Consider healthy if we've had a successful auth recently
            # or if we haven't tried yet (first startup)
            if health.last_successful_auth is not None or health.consecutive_failures == 0:
                checks["azure_credentials"] = True
            else:
                errors.append(f"Azure: {health.last_error or 'Authentication failed'}")
        else:
            # Not configured is acceptable for readiness
            checks["azure_credentials"] = True
    except Exception as e:
        errors.append(f"Azure credentials: {str(e)}")
        logger.warning("Readiness check: Azure credentials failed", error=str(e))
    
    all_healthy = all(checks.values())
    
    return {
        "status": "ready" if all_healthy else "not_ready",
        "timestamp": datetime.utcnow().isoformat(),
        "checks": checks,
        "errors": errors if errors else None,
    }


@router.get("/live")
async def liveness_check() -> dict[str, str]:
    """
    Liveness check for Kubernetes/container orchestration.
    
    Simple check to verify the application is running.
    If this fails, the container should be restarted.
    """
    return {
        "status": "alive",
        "timestamp": datetime.utcnow().isoformat(),
    }
