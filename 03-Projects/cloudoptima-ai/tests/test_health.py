"""Health endpoint tests."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_health_check(client: AsyncClient):
    """Test health check endpoint."""
    response = await client.get("/api/v1/health")
    assert response.status_code == 200
    
    data = response.json()
    assert data["status"] in ["healthy", "degraded"]
    assert "version" in data
    assert "azure_configured" in data
    assert "database_connected" in data


@pytest.mark.asyncio
async def test_root_endpoint(client: AsyncClient):
    """Test root endpoint."""
    response = await client.get("/api/v1/")
    assert response.status_code == 200
    
    data = response.json()
    assert data["name"] == "CloudOptima AI"
    assert "version" in data
    assert "docs_url" in data
