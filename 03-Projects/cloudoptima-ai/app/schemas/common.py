"""Common schema definitions."""

from datetime import datetime
from typing import Any, Optional

from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    """API health check response."""

    status: str = Field(description="Service status")
    version: str = Field(description="API version")
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    azure_configured: bool = Field(description="Whether Azure credentials are configured")
    database_connected: bool = Field(default=True, description="Database connection status")


class ErrorResponse(BaseModel):
    """Standard error response."""

    error: str = Field(description="Error type")
    message: str = Field(description="Error message")
    details: Optional[dict[str, Any]] = Field(default=None, description="Additional details")
    timestamp: datetime = Field(default_factory=datetime.utcnow)


class PaginationParams(BaseModel):
    """Pagination parameters."""

    page: int = Field(default=1, ge=1, description="Page number")
    page_size: int = Field(default=20, ge=1, le=100, description="Items per page")


class SubscriptionInfo(BaseModel):
    """Azure subscription information."""

    id: str = Field(description="Subscription ID")
    name: str = Field(description="Subscription display name")
    state: Optional[str] = Field(default=None, description="Subscription state")
    tenant_id: Optional[str] = Field(default=None, description="Tenant ID")


class ResourceGroupInfo(BaseModel):
    """Azure resource group information."""

    name: str = Field(description="Resource group name")
    location: str = Field(description="Azure region")
    tags: dict[str, str] = Field(default_factory=dict, description="Resource group tags")
    provisioning_state: Optional[str] = Field(default=None, description="Provisioning state")
