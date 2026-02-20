"""CloudOptima AI - FastAPI Application Entry Point."""

import os
import time
import uuid
from contextlib import asynccontextmanager
from pathlib import Path
from typing import AsyncGenerator

from fastapi import Depends, FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from starlette.middleware.base import BaseHTTPMiddleware

from app import __version__
from app.api import api_router
from app.core.auth import (
    APIKeyInfo,
    get_api_key_optional,
    get_rate_limiter,
)
from app.core.config import get_settings
from app.core.database import close_db, init_db
from app.core.error_handlers import register_exception_handlers
from app.core.exceptions import InvalidAPIKeyError
from app.core.logging import get_logger, setup_logging

# Initialize logging
setup_logging()
logger = get_logger(__name__)


class RequestIDMiddleware(BaseHTTPMiddleware):
    """Middleware to add unique request ID to each request for tracing."""

    async def dispatch(self, request: Request, call_next):
        request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))
        request.state.request_id = request_id
        
        # Add timing
        start_time = time.time()
        
        response = await call_next(request)
        
        # Calculate request duration
        duration_ms = (time.time() - start_time) * 1000
        
        response.headers["X-Request-ID"] = request_id
        response.headers["X-Response-Time"] = f"{duration_ms:.2f}ms"
        
        # Log request (skip health checks to reduce noise)
        if not request.url.path.endswith("/health"):
            logger.info(
                "Request completed",
                method=request.method,
                path=request.url.path,
                status_code=response.status_code,
                duration_ms=round(duration_ms, 2),
                request_id=request_id,
            )
        
        return response


class AuthenticationMiddleware(BaseHTTPMiddleware):
    """
    Middleware to enforce API key authentication.
    
    Skips authentication for:
    - Health check endpoints
    - OpenAPI documentation
    - OPTIONS requests (CORS preflight)
    """
    
    # Paths that don't require authentication
    PUBLIC_PATHS = {
        "/health",
        "/api/v1/health",
        "/docs",
        "/redoc",
        "/openapi.json",
    }

    async def dispatch(self, request: Request, call_next):
        settings = get_settings()
        
        # Skip auth if disabled
        if not settings.auth_enabled:
            return await call_next(request)
        
        # Skip auth for OPTIONS (CORS preflight)
        if request.method == "OPTIONS":
            return await call_next(request)
        
        # Skip auth for public paths
        if request.url.path in self.PUBLIC_PATHS:
            return await call_next(request)
        
        # Skip auth if no API key is configured (open mode)
        if not settings.api_key:
            return await call_next(request)
        
        # Validate API key
        api_key = request.headers.get("X-API-Key")
        
        if not api_key:
            return JSONResponse(
                status_code=status.HTTP_401_UNAUTHORIZED,
                content={
                    "error": {
                        "code": "MISSING_API_KEY",
                        "message": "API key is required. Provide it via X-API-Key header.",
                    }
                },
                headers={"WWW-Authenticate": "ApiKey"},
            )
        
        # Import here to avoid circular imports
        from app.core.auth import get_key_store
        
        key_store = get_key_store()
        key_info = key_store.validate_key(api_key)
        
        if not key_info:
            logger.warning(
                "Invalid API key attempt",
                path=request.url.path,
                key_prefix=api_key[:8] + "..." if len(api_key) > 8 else "***",
            )
            return JSONResponse(
                status_code=status.HTTP_401_UNAUTHORIZED,
                content={
                    "error": {
                        "code": "INVALID_API_KEY",
                        "message": "Invalid API key provided.",
                    }
                },
            )
        
        if key_info.is_expired():
            return JSONResponse(
                status_code=status.HTTP_401_UNAUTHORIZED,
                content={
                    "error": {
                        "code": "EXPIRED_API_KEY",
                        "message": "API key has expired.",
                    }
                },
            )
        
        # Store key info in request state for use in endpoints
        request.state.api_key_info = key_info
        
        return await call_next(request)


class RateLimitMiddleware(BaseHTTPMiddleware):
    """
    Middleware to enforce rate limiting.
    
    Limits are based on API key (if authenticated) or client IP.
    """

    async def dispatch(self, request: Request, call_next):
        settings = get_settings()
        limiter = get_rate_limiter()
        
        # Determine identifier and limit
        key_info = getattr(request.state, "api_key_info", None)
        
        if key_info:
            identifier = f"key:{key_info.key_id}"
            limit = key_info.rate_limit
        else:
            # Use client IP for unauthenticated requests
            client_ip = request.client.host if request.client else "unknown"
            identifier = f"ip:{client_ip}"
            limit = 100  # Lower limit for unauthenticated
        
        # Check rate limit
        allowed, remaining = limiter.is_allowed(identifier, limit)
        reset_seconds = limiter.get_reset_time(identifier)
        
        # Store for response headers
        request.state.rate_limit_limit = limit
        request.state.rate_limit_remaining = remaining
        request.state.rate_limit_reset = reset_seconds
        
        if not allowed:
            logger.warning(
                "Rate limit exceeded",
                identifier=identifier,
                path=request.url.path,
            )
            return JSONResponse(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                content={
                    "error": {
                        "code": "RATE_LIMITED",
                        "message": "Rate limit exceeded. Please retry later.",
                        "retry_after_seconds": reset_seconds,
                    }
                },
                headers={
                    "Retry-After": str(reset_seconds),
                    "X-RateLimit-Limit": str(limit),
                    "X-RateLimit-Remaining": "0",
                    "X-RateLimit-Reset": str(reset_seconds),
                },
            )
        
        response = await call_next(request)
        
        # Add rate limit headers to all responses
        response.headers["X-RateLimit-Limit"] = str(limit)
        response.headers["X-RateLimit-Remaining"] = str(remaining)
        response.headers["X-RateLimit-Reset"] = str(reset_seconds)
        
        return response


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator:
    """Application lifespan context manager."""
    from app.core.azure_auth import get_credential_manager
    
    settings = get_settings()
    credential_manager = None
    
    # Startup
    logger.info(
        "Starting CloudOptima AI",
        version=__version__,
        auth_enabled=settings.auth_enabled,
        debug=settings.api_debug,
    )
    await init_db()
    
    # Initialize Azure credential manager with background refresh
    if settings.is_azure_configured:
        try:
            credential_manager = get_credential_manager()
            # Validate credentials on startup
            await credential_manager.get_token()
            # Start background refresh
            await credential_manager.start_background_refresh()
            logger.info("Azure credential manager initialized with background refresh")
        except Exception as e:
            logger.warning(
                "Azure credential initialization failed - will retry on first request",
                error=str(e),
            )
    else:
        logger.info("Azure credentials not configured - skipping initialization")
    
    logger.info("Application startup complete")
    
    yield
    
    # Shutdown
    logger.info("Shutting down CloudOptima AI")
    
    # Stop background token refresh
    if credential_manager:
        try:
            await credential_manager.stop_background_refresh()
            credential_manager.close()
        except Exception as e:
            logger.warning("Error during credential manager shutdown", error=str(e))
    
    await close_db()
    logger.info("Application shutdown complete")


def create_app() -> FastAPI:
    """Create and configure the FastAPI application."""
    settings = get_settings()
    
    app = FastAPI(
        title=settings.api_title,
        description="Azure FinOps Cost Optimization Platform - Analyze, optimize, and manage Azure costs",
        version=settings.api_version,
        lifespan=lifespan,
        docs_url="/docs",
        redoc_url="/redoc",
        openapi_url="/openapi.json",
    )
    
    # Register exception handlers
    register_exception_handlers(app)
    
    # ==========================================================================
    # Middleware stack (order matters - first added is outermost/last executed)
    # Request flow: CORS -> RequestID -> Auth -> RateLimit -> Route Handler
    # ==========================================================================
    
    # 4. Rate limiting (innermost - runs after auth)
    app.add_middleware(RateLimitMiddleware)
    
    # 3. Authentication
    app.add_middleware(AuthenticationMiddleware)
    
    # 2. Request ID and timing
    app.add_middleware(RequestIDMiddleware)
    
    # 1. CORS (outermost - must handle preflight before other middleware)
    # SECURITY: Never allow "*" origins in production
    allowed_origins = settings.cors_origins
    
    # Validate CORS origins
    if "*" in allowed_origins:
        if settings.api_debug:
            logger.warning(
                "CORS wildcard origin detected in debug mode - "
                "this is insecure and should not be used in production"
            )
        else:
            # Remove wildcard in production
            allowed_origins = [o for o in allowed_origins if o != "*"]
            logger.warning(
                "Removed CORS wildcard origin for security. "
                "Configure specific origins in CORS_ORIGINS."
            )
    
    if not allowed_origins:
        # Default to localhost only if no origins configured
        allowed_origins = ["http://localhost:3000", "http://localhost:8080"]
        logger.info("Using default CORS origins", origins=allowed_origins)
    
    app.add_middleware(
        CORSMiddleware,
        allow_origins=allowed_origins,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
        allow_headers=[
            "Authorization",
            "Content-Type",
            "X-API-Key",
            "X-Request-ID",
        ],
        expose_headers=[
            "X-Request-ID",
            "X-Response-Time",
            "X-RateLimit-Limit",
            "X-RateLimit-Remaining",
            "X-RateLimit-Reset",
        ],
        max_age=600,  # Cache preflight for 10 minutes
    )
    
    # Include API routes
    app.include_router(api_router, prefix="/api/v1")
    
    # Serve static files for dashboard
    static_dir = Path(__file__).parent / "static"
    if static_dir.exists():
        app.mount("/static", StaticFiles(directory=str(static_dir)), name="static")
        
        # Dashboard route
        @app.get("/", include_in_schema=False)
        async def dashboard():
            """Serve the dashboard."""
            index_path = static_dir / "index.html"
            if index_path.exists():
                return FileResponse(str(index_path))
            return JSONResponse(
                {"message": "Dashboard not found. Visit /docs for API documentation."},
                status_code=404,
            )
        
        logger.info("Dashboard and static files configured", static_dir=str(static_dir))
    
    logger.info(
        "Application configured",
        auth_enabled=settings.auth_enabled,
        cors_origins=allowed_origins,
        api_key_configured=bool(settings.api_key),
    )
    
    return app


# Create application instance
app = create_app()


if __name__ == "__main__":
    import uvicorn
    
    settings = get_settings()
    uvicorn.run(
        "app.main:app",
        host=settings.api_host,
        port=settings.api_port,
        reload=settings.api_debug,
    )
