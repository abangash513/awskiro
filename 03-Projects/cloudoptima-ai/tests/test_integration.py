"""Integration tests for CloudOptima AI API.

These tests verify the complete request/response flow through the API,
including authentication, validation, and database operations.
"""

import pytest
from datetime import datetime, timedelta
from decimal import Decimal
from httpx import AsyncClient


# ============================================================================
# Health Check Tests
# ============================================================================

class TestHealthEndpoints:
    """Integration tests for health check endpoints."""

    @pytest.mark.asyncio
    async def test_health_check_returns_200(self, client: AsyncClient):
        """Health endpoint should return 200 OK."""
        response = await client.get("/api/v1/health")
        assert response.status_code == 200
        
        data = response.json()
        assert data["status"] == "healthy"
        assert "version" in data
        assert "timestamp" in data

    @pytest.mark.asyncio
    async def test_health_check_no_auth_required(self, client: AsyncClient):
        """Health endpoint should not require authentication."""
        # Even without API key header, should succeed
        response = await client.get("/api/v1/health")
        assert response.status_code == 200


# ============================================================================
# Cost Endpoint Tests
# ============================================================================

class TestCostEndpoints:
    """Integration tests for cost management endpoints."""

    @pytest.mark.asyncio
    async def test_get_cost_summary(self, client: AsyncClient):
        """Cost summary should return valid structure."""
        response = await client.get("/api/v1/costs/summary")
        assert response.status_code == 200
        
        data = response.json()
        assert "total_cost" in data
        assert "cost_by_service" in data
        assert "currency" in data
        assert data["currency"] == "USD"

    @pytest.mark.asyncio
    async def test_get_daily_costs_default(self, client: AsyncClient):
        """Daily costs with default parameters."""
        response = await client.get("/api/v1/costs/daily")
        assert response.status_code == 200
        
        data = response.json()
        assert "costs" in data
        assert "total_cost" in data
        assert data["days"] == 30  # Default

    @pytest.mark.asyncio
    async def test_get_daily_costs_custom_days(self, client: AsyncClient):
        """Daily costs with custom day range."""
        response = await client.get("/api/v1/costs/daily?days=7")
        assert response.status_code == 200
        
        data = response.json()
        assert data["days"] == 7

    @pytest.mark.asyncio
    async def test_daily_costs_validation_error(self, client: AsyncClient):
        """Should reject invalid days parameter."""
        # Days too high
        response = await client.get("/api/v1/costs/daily?days=500")
        assert response.status_code == 422
        
        # Days too low
        response = await client.get("/api/v1/costs/daily?days=0")
        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_get_top_resources(self, client: AsyncClient):
        """Top resources endpoint returns list."""
        response = await client.get("/api/v1/costs/top-resources")
        assert response.status_code == 200
        
        data = response.json()
        assert isinstance(data, list)

    @pytest.mark.asyncio
    async def test_get_cost_trends(self, client: AsyncClient):
        """Cost trends returns week/month comparisons."""
        response = await client.get("/api/v1/costs/trends")
        assert response.status_code == 200
        
        data = response.json()
        assert "current_week_cost" in data
        assert "previous_week_cost" in data
        assert "week_over_week_change" in data
        assert "month_over_month_change" in data


# ============================================================================
# Budget Endpoint Tests
# ============================================================================

class TestBudgetEndpoints:
    """Integration tests for budget management endpoints."""

    @pytest.mark.asyncio
    async def test_list_budgets_empty(self, client: AsyncClient):
        """List budgets returns empty list initially."""
        response = await client.get("/api/v1/budgets/")
        assert response.status_code == 200
        
        data = response.json()
        assert isinstance(data, list)

    @pytest.mark.asyncio
    async def test_create_budget(self, client: AsyncClient):
        """Create budget with valid data."""
        budget_data = {
            "name": "Test Budget",
            "amount": 1000.00,
            "time_grain": "monthly",
            "alert_thresholds": "50,80,100",
        }
        
        response = await client.post("/api/v1/budgets/", json=budget_data)
        assert response.status_code == 201
        
        data = response.json()
        assert data["name"] == "Test Budget"
        assert data["amount"] == 1000.00
        assert data["is_active"] is True
        assert "id" in data

    @pytest.mark.asyncio
    async def test_create_budget_validation_error(self, client: AsyncClient):
        """Should reject invalid budget data."""
        # Missing required field
        response = await client.post("/api/v1/budgets/", json={"amount": 1000})
        assert response.status_code == 422
        
        # Invalid amount
        response = await client.post("/api/v1/budgets/", json={
            "name": "Test",
            "amount": -100,
        })
        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_get_budget_not_found(self, client: AsyncClient):
        """Should return 404 for non-existent budget."""
        response = await client.get("/api/v1/budgets/99999")
        assert response.status_code == 404

    @pytest.mark.asyncio
    async def test_budget_crud_flow(self, client: AsyncClient):
        """Test complete CRUD flow for budgets."""
        # Create
        create_response = await client.post("/api/v1/budgets/", json={
            "name": "CRUD Test Budget",
            "amount": 5000.00,
            "time_grain": "monthly",
        })
        assert create_response.status_code == 201
        budget_id = create_response.json()["id"]
        
        # Read
        get_response = await client.get(f"/api/v1/budgets/{budget_id}")
        assert get_response.status_code == 200
        assert get_response.json()["name"] == "CRUD Test Budget"
        
        # Update
        update_response = await client.patch(f"/api/v1/budgets/{budget_id}", json={
            "name": "Updated Budget Name",
            "amount": 7500.00,
        })
        assert update_response.status_code == 200
        assert update_response.json()["name"] == "Updated Budget Name"
        assert update_response.json()["amount"] == 7500.00
        
        # Delete
        delete_response = await client.delete(f"/api/v1/budgets/{budget_id}")
        assert delete_response.status_code == 204
        
        # Verify deleted
        verify_response = await client.get(f"/api/v1/budgets/{budget_id}")
        assert verify_response.status_code == 404


# ============================================================================
# Recommendation Endpoint Tests
# ============================================================================

class TestRecommendationEndpoints:
    """Integration tests for recommendation endpoints."""

    @pytest.mark.asyncio
    async def test_list_recommendations(self, client: AsyncClient):
        """List recommendations returns valid structure."""
        response = await client.get("/api/v1/recommendations/")
        assert response.status_code == 200
        
        data = response.json()
        assert isinstance(data, list)

    @pytest.mark.asyncio
    async def test_get_savings_summary(self, client: AsyncClient):
        """Savings summary returns aggregated data."""
        response = await client.get("/api/v1/recommendations/savings")
        assert response.status_code == 200
        
        data = response.json()
        assert "total_potential_monthly_savings" in data
        assert "total_accepted_monthly_savings" in data
        assert "by_category" in data
        assert "by_status" in data


# ============================================================================
# Notification Endpoint Tests
# ============================================================================

class TestNotificationEndpoints:
    """Integration tests for notification endpoints."""

    @pytest.mark.asyncio
    async def test_get_notification_status(self, client: AsyncClient):
        """Notification status returns configuration info."""
        response = await client.get("/api/v1/notifications/status")
        assert response.status_code == 200
        
        data = response.json()
        assert "enabled" in data
        assert "configured_channels" in data
        assert "webhook_configured" in data
        assert "slack_configured" in data
        assert "teams_configured" in data


# ============================================================================
# Input Validation Tests
# ============================================================================

class TestInputValidation:
    """Integration tests for input validation."""

    @pytest.mark.asyncio
    async def test_invalid_subscription_id_format(self, client: AsyncClient):
        """Should reject invalid subscription ID format."""
        response = await client.post("/api/v1/costs/ingest", json={
            "subscription_id": "invalid-not-a-uuid",
        })
        assert response.status_code == 422
        
        error = response.json()
        assert "subscription" in str(error).lower()

    @pytest.mark.asyncio
    async def test_valid_subscription_id_format(self, client: AsyncClient):
        """Should accept valid UUID subscription ID."""
        # This will likely fail due to Azure not being configured,
        # but validation should pass
        response = await client.post("/api/v1/costs/ingest", json={
            "subscription_id": "12345678-1234-1234-1234-123456789abc",
        })
        # Either 200 (success) or 503 (Azure not configured) - not 422
        assert response.status_code in [200, 503]

    @pytest.mark.asyncio
    async def test_budget_threshold_validation(self, client: AsyncClient):
        """Should validate budget threshold values."""
        # Threshold too high (> 200)
        response = await client.post("/api/v1/budgets/", json={
            "name": "Test",
            "amount": 1000,
            "alert_thresholds": "50,80,250",  # 250 > 200
        })
        assert response.status_code == 422

    @pytest.mark.asyncio
    async def test_budget_time_grain_validation(self, client: AsyncClient):
        """Should validate time grain enum values."""
        response = await client.post("/api/v1/budgets/", json={
            "name": "Test",
            "amount": 1000,
            "time_grain": "weekly",  # Invalid
        })
        assert response.status_code == 422


# ============================================================================
# Error Response Tests
# ============================================================================

class TestErrorResponses:
    """Integration tests for error response format."""

    @pytest.mark.asyncio
    async def test_404_returns_proper_error(self, client: AsyncClient):
        """404 errors should have proper format."""
        response = await client.get("/api/v1/budgets/99999")
        assert response.status_code == 404
        
        data = response.json()
        assert "error" in data or "detail" in data

    @pytest.mark.asyncio
    async def test_422_returns_validation_details(self, client: AsyncClient):
        """Validation errors should include field details."""
        response = await client.post("/api/v1/budgets/", json={
            "name": "",  # Invalid: too short
            "amount": -1,  # Invalid: negative
        })
        assert response.status_code == 422
        
        data = response.json()
        assert "detail" in data
        # Should have multiple validation errors
        assert len(data["detail"]) >= 1


# ============================================================================
# Rate Limit Header Tests
# ============================================================================

class TestRateLimitHeaders:
    """Integration tests for rate limit headers."""

    @pytest.mark.asyncio
    async def test_rate_limit_headers_present(self, client: AsyncClient):
        """Rate limit headers should be present in responses."""
        response = await client.get("/api/v1/costs/summary")
        
        # Check rate limit headers
        assert "X-RateLimit-Limit" in response.headers
        assert "X-RateLimit-Remaining" in response.headers
        assert "X-RateLimit-Reset" in response.headers


# ============================================================================
# Request ID Tests
# ============================================================================

class TestRequestId:
    """Integration tests for request ID tracking."""

    @pytest.mark.asyncio
    async def test_request_id_returned(self, client: AsyncClient):
        """Response should include X-Request-ID header."""
        response = await client.get("/api/v1/health")
        
        assert "X-Request-ID" in response.headers
        assert len(response.headers["X-Request-ID"]) > 0

    @pytest.mark.asyncio
    async def test_request_id_preserved(self, client: AsyncClient):
        """Custom X-Request-ID should be preserved."""
        custom_id = "test-request-12345"
        response = await client.get(
            "/api/v1/health",
            headers={"X-Request-ID": custom_id}
        )
        
        assert response.headers["X-Request-ID"] == custom_id


# ============================================================================
# Response Time Tests
# ============================================================================

class TestResponseTime:
    """Integration tests for response time headers."""

    @pytest.mark.asyncio
    async def test_response_time_header(self, client: AsyncClient):
        """Response should include X-Response-Time header."""
        response = await client.get("/api/v1/health")
        
        assert "X-Response-Time" in response.headers
        # Should be in format "X.XXms"
        assert "ms" in response.headers["X-Response-Time"]
