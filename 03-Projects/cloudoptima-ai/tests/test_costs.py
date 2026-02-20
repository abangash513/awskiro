"""Cost endpoint tests."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_get_cost_summary(client: AsyncClient):
    """Test cost summary endpoint (empty database)."""
    response = await client.get("/api/v1/costs/summary")
    assert response.status_code == 200
    
    data = response.json()
    assert "total_cost" in data
    assert "cost_by_service" in data
    assert data["currency"] == "USD"


@pytest.mark.asyncio
async def test_get_daily_costs(client: AsyncClient):
    """Test daily costs endpoint."""
    response = await client.get("/api/v1/costs/daily?days=7")
    assert response.status_code == 200
    
    data = response.json()
    assert "costs" in data
    assert "total_cost" in data
    assert data["days"] == 7


@pytest.mark.asyncio
async def test_get_top_resources(client: AsyncClient):
    """Test top resources endpoint."""
    response = await client.get("/api/v1/costs/top-resources?limit=5")
    assert response.status_code == 200
    
    data = response.json()
    assert isinstance(data, list)


@pytest.mark.asyncio
async def test_get_cost_trends(client: AsyncClient):
    """Test cost trends endpoint."""
    response = await client.get("/api/v1/costs/trends")
    assert response.status_code == 200
    
    data = response.json()
    assert "current_week_cost" in data
    assert "previous_week_cost" in data
    assert "week_over_week_change" in data
    assert "month_over_month_change" in data


@pytest.mark.asyncio
async def test_daily_costs_validation(client: AsyncClient):
    """Test daily costs with invalid days parameter."""
    # Days too high
    response = await client.get("/api/v1/costs/daily?days=500")
    assert response.status_code == 422  # Validation error
    
    # Days too low
    response = await client.get("/api/v1/costs/daily?days=0")
    assert response.status_code == 422
