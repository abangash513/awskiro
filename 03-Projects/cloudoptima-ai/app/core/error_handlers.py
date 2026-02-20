"""Global exception handlers for FastAPI."""

import traceback
from typing import Any

from fastapi import FastAPI, Request, status
from fastapi.responses import JSONResponse
from azure.core.exceptions import (
    ClientAuthenticationError,
    HttpResponseError,
    ResourceNotFoundError as AzureResourceNotFound,
    ServiceRequestError,
)

from app.core.exceptions import (
    AuthenticationError,
    AzureAuthenticationError,
    AzureError,
    AzureRateLimitError,
    AzureResourceNotFoundError,
    AzureServiceUnavailableError,
    BusinessLogicError,
    CloudOptimaError,
    DatabaseError,
    ResourceNotFoundError,
    ValidationError,
)
from app.core.logging import get_logger

logger = get_logger(__name__)


def create_error_response(
    status_code: int,
    error_code: str,
    message: str,
    details: dict[str, Any] | None = None,
    request_id: str | None = None,
) -> JSONResponse:
    """Create a standardized error response."""
    content = {
        "error": {
            "code": error_code,
            "message": message,
        }
    }
    
    if details:
        content["error"]["details"] = details
    
    if request_id:
        content["error"]["request_id"] = request_id
    
    return JSONResponse(status_code=status_code, content=content)


def register_exception_handlers(app: FastAPI) -> None:
    """Register all exception handlers on the FastAPI app."""

    @app.exception_handler(CloudOptimaError)
    async def cloudoptima_error_handler(
        request: Request, exc: CloudOptimaError
    ) -> JSONResponse:
        """Handle CloudOptima custom exceptions."""
        request_id = getattr(request.state, "request_id", None)
        
        # Determine appropriate status code
        if isinstance(exc, AuthenticationError):
            status_code = status.HTTP_401_UNAUTHORIZED
        elif isinstance(exc, ValidationError):
            status_code = status.HTTP_400_BAD_REQUEST
        elif isinstance(exc, ResourceNotFoundError):
            status_code = status.HTTP_404_NOT_FOUND
        elif isinstance(exc, AzureRateLimitError):
            status_code = status.HTTP_429_TOO_MANY_REQUESTS
        elif isinstance(exc, (AzureServiceUnavailableError, AzureError)):
            status_code = status.HTTP_503_SERVICE_UNAVAILABLE
        elif isinstance(exc, BusinessLogicError):
            status_code = status.HTTP_422_UNPROCESSABLE_ENTITY
        elif isinstance(exc, DatabaseError):
            status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
        else:
            status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
        
        logger.error(
            "CloudOptima error",
            error_code=exc.error_code,
            message=exc.message,
            status_code=status_code,
            request_id=request_id,
        )
        
        return create_error_response(
            status_code=status_code,
            error_code=exc.error_code,
            message=exc.message,
            details=exc.details,
            request_id=request_id,
        )

    @app.exception_handler(ClientAuthenticationError)
    async def azure_auth_error_handler(
        request: Request, exc: ClientAuthenticationError
    ) -> JSONResponse:
        """Handle Azure authentication errors."""
        request_id = getattr(request.state, "request_id", None)
        
        logger.error(
            "Azure authentication failed",
            error=str(exc),
            request_id=request_id,
        )
        
        return create_error_response(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            error_code="AZURE_AUTH_ERROR",
            message="Azure authentication failed. Please check service credentials.",
            request_id=request_id,
        )

    @app.exception_handler(HttpResponseError)
    async def azure_http_error_handler(
        request: Request, exc: HttpResponseError
    ) -> JSONResponse:
        """Handle Azure HTTP response errors."""
        request_id = getattr(request.state, "request_id", None)
        
        # Check for rate limiting
        if exc.status_code == 429:
            retry_after = None
            if hasattr(exc, "response") and exc.response:
                retry_after = exc.response.headers.get("Retry-After")
            
            logger.warning(
                "Azure rate limit hit",
                retry_after=retry_after,
                request_id=request_id,
            )
            
            return create_error_response(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                error_code="AZURE_RATE_LIMITED",
                message="Azure API rate limit exceeded. Please retry later.",
                details={"retry_after_seconds": int(retry_after) if retry_after else 60},
                request_id=request_id,
            )
        
        # Check for not found
        if exc.status_code == 404:
            return create_error_response(
                status_code=status.HTTP_404_NOT_FOUND,
                error_code="AZURE_RESOURCE_NOT_FOUND",
                message="Requested Azure resource was not found.",
                request_id=request_id,
            )
        
        # Check for quota exceeded
        if exc.status_code == 403 and "quota" in str(exc).lower():
            return create_error_response(
                status_code=status.HTTP_403_FORBIDDEN,
                error_code="AZURE_QUOTA_EXCEEDED",
                message="Azure quota has been exceeded.",
                request_id=request_id,
            )
        
        logger.error(
            "Azure HTTP error",
            status_code=exc.status_code,
            error=str(exc),
            request_id=request_id,
        )
        
        return create_error_response(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            error_code="AZURE_ERROR",
            message=f"Azure service error: {exc.message if hasattr(exc, 'message') else str(exc)}",
            request_id=request_id,
        )

    @app.exception_handler(ServiceRequestError)
    async def azure_service_error_handler(
        request: Request, exc: ServiceRequestError
    ) -> JSONResponse:
        """Handle Azure service connection errors."""
        request_id = getattr(request.state, "request_id", None)
        
        logger.error(
            "Azure service unavailable",
            error=str(exc),
            request_id=request_id,
        )
        
        return create_error_response(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            error_code="AZURE_SERVICE_UNAVAILABLE",
            message="Unable to connect to Azure services. Please try again later.",
            request_id=request_id,
        )

    @app.exception_handler(AzureResourceNotFound)
    async def azure_notfound_handler(
        request: Request, exc: AzureResourceNotFound
    ) -> JSONResponse:
        """Handle Azure resource not found errors."""
        request_id = getattr(request.state, "request_id", None)
        
        return create_error_response(
            status_code=status.HTTP_404_NOT_FOUND,
            error_code="AZURE_RESOURCE_NOT_FOUND",
            message=str(exc),
            request_id=request_id,
        )

    @app.exception_handler(ValueError)
    async def value_error_handler(
        request: Request, exc: ValueError
    ) -> JSONResponse:
        """Handle value errors as validation errors."""
        request_id = getattr(request.state, "request_id", None)
        
        return create_error_response(
            status_code=status.HTTP_400_BAD_REQUEST,
            error_code="VALIDATION_ERROR",
            message=str(exc),
            request_id=request_id,
        )

    @app.exception_handler(Exception)
    async def general_exception_handler(
        request: Request, exc: Exception
    ) -> JSONResponse:
        """Handle any unhandled exceptions."""
        request_id = getattr(request.state, "request_id", None)
        
        # Log the full traceback for debugging
        logger.error(
            "Unhandled exception",
            error=str(exc),
            error_type=type(exc).__name__,
            request_id=request_id,
            traceback=traceback.format_exc(),
        )
        
        # Don't expose internal details in production
        return create_error_response(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            error_code="INTERNAL_ERROR",
            message="An unexpected error occurred. Please try again later.",
            request_id=request_id,
        )
