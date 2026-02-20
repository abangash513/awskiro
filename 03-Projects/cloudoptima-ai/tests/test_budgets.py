"""Budget endpoint tests."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_create_budget(client: AsyncClient):
    """Test budget creation."""
    budget_data = {
        "name": "Test Budget",
        "amount": 1000.00,
        "subscription_id": "test-subscription-id",
        "time_grain": "monthly",
        "alert_thresholds": "50,80,100",
        "description": "Test budget description",
    }
    
    response = await client.post("/api/v1/budgets/", json=budget_data)
    assert response.status_code == 201
    
    data = response.json()
    assert data["name"] == "Test Budget"
    assert data["amount"] == 1000.00
    assert data["currency"] == "USD"
    assert data["is_active"] is True


@pytest.mark.asyncio
async def test_list_budgets(client: AsyncClient):
    """Test listing budgets."""
    # Create a budget first
    budget_data = {
        "name": "List Test Budget",
        "amount": 500.00,
        "subscription_id": "test-sub-id",
    }
    await client.post("/api/v1/budgets/", json=budget_data)
    
    # List budgets
    response = await client.get("/api/v1/budgets/?subscription_id=test-sub-id")
    assert response.status_code == 200
    
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 1


@pytest.mark.asyncio
async def test_get_budget(client: AsyncClient):
    """Test getting a specific budget."""
    # Create a budget
    budget_data = {
        "name": "Get Test Budget",
        "amount": 750.00,
        "subscription_id": "test-sub-id",
    }
    create_response = await client.post("/api/v1/budgets/", json=budget_data)
    budget_id = create_response.json()["id"]
    
    # Get the budget
    response = await client.get(f"/api/v1/budgets/{budget_id}")
    assert response.status_code == 200
    
    data = response.json()
    assert data["id"] == budget_id
    assert data["name"] == "Get Test Budget"


@pytest.mark.asyncio
async def test_update_budget(client: AsyncClient):
    """Test updating a budget."""
    # Create a budget
    budget_data = {
        "name": "Update Test Budget",
        "amount": 1000.00,
        "subscription_id": "test-sub-id",
    }
    create_response = await client.post("/api/v1/budgets/", json=budget_data)
    budget_id = create_response.json()["id"]
    
    # Update the budget
    update_data = {
        "name": "Updated Budget Name",
        "amount": 1500.00,
    }
    response = await client.patch(f"/api/v1/budgets/{budget_id}", json=update_data)
    assert response.status_code == 200
    
    data = response.json()
    assert data["name"] == "Updated Budget Name"
    assert data["amount"] == 1500.00


@pytest.mark.asyncio
async def test_delete_budget(client: AsyncClient):
    """Test deleting a budget."""
    # Create a budget
    budget_data = {
        "name": "Delete Test Budget",
        "amount": 500.00,
        "subscription_id": "test-sub-id",
    }
    create_response = await client.post("/api/v1/budgets/", json=budget_data)
    budget_id = create_response.json()["id"]
    
    # Delete the budget
    response = await client.delete(f"/api/v1/budgets/{budget_id}")
    assert response.status_code == 204
    
    # Verify it's deleted
    get_response = await client.get(f"/api/v1/budgets/{budget_id}")
    assert get_response.status_code == 404


@pytest.mark.asyncio
async def test_budget_not_found(client: AsyncClient):
    """Test getting a non-existent budget."""
    response = await client.get("/api/v1/budgets/99999")
    assert response.status_code == 404
