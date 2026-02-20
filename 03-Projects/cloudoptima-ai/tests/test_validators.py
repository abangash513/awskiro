"""Unit tests for API schema validators."""

import pytest
from datetime import datetime, timedelta

from app.schemas.validators import (
    validate_subscription_id,
    validate_resource_group,
    validate_date_range,
    validate_percentage,
    validate_positive_amount,
)


class TestValidateSubscriptionId:
    """Tests for subscription ID validation."""

    def test_valid_subscription_id(self):
        """Should accept valid UUID format."""
        valid_ids = [
            "12345678-1234-1234-1234-123456789abc",
            "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE",
            "00000000-0000-0000-0000-000000000000",
        ]
        
        for sub_id in valid_ids:
            result = validate_subscription_id(sub_id)
            assert result == sub_id.lower()

    def test_returns_none_for_none(self):
        """Should return None when input is None."""
        result = validate_subscription_id(None)
        assert result is None

    def test_strips_whitespace(self):
        """Should strip leading/trailing whitespace."""
        result = validate_subscription_id("  12345678-1234-1234-1234-123456789abc  ")
        assert result == "12345678-1234-1234-1234-123456789abc"

    def test_rejects_invalid_format(self):
        """Should reject non-UUID formats."""
        invalid_ids = [
            "not-a-uuid",
            "12345678-1234-1234-1234",  # Too short
            "12345678-1234-1234-1234-123456789abcdef",  # Too long
            "1234567g-1234-1234-1234-123456789abc",  # Invalid char 'g'
            "",  # Empty
        ]
        
        for invalid_id in invalid_ids:
            with pytest.raises(ValueError) as exc_info:
                validate_subscription_id(invalid_id)
            assert "Invalid subscription ID format" in str(exc_info.value)


class TestValidateResourceGroup:
    """Tests for resource group name validation."""

    def test_valid_resource_group_names(self):
        """Should accept valid resource group names."""
        valid_names = [
            "my-resource-group",
            "MyResourceGroup",
            "rg_production_01",
            "rg.app(v2)",
            "a",  # Minimum length
            "a" * 90,  # Maximum length
        ]
        
        for name in valid_names:
            result = validate_resource_group(name)
            assert result == name

    def test_returns_none_for_none(self):
        """Should return None when input is None."""
        result = validate_resource_group(None)
        assert result is None

    def test_strips_whitespace(self):
        """Should strip leading/trailing whitespace."""
        result = validate_resource_group("  my-group  ")
        assert result == "my-group"

    def test_rejects_empty_string(self):
        """Should reject empty string."""
        with pytest.raises(ValueError) as exc_info:
            validate_resource_group("")
        assert "cannot be empty" in str(exc_info.value)

    def test_rejects_too_long(self):
        """Should reject names over 90 characters."""
        long_name = "a" * 91
        with pytest.raises(ValueError) as exc_info:
            validate_resource_group(long_name)
        assert "too long" in str(exc_info.value)

    def test_rejects_ending_with_period(self):
        """Should reject names ending with a period."""
        with pytest.raises(ValueError) as exc_info:
            validate_resource_group("my-group.")
        assert "Invalid resource group name" in str(exc_info.value)


class TestValidateDateRange:
    """Tests for date range validation."""

    def test_returns_none_for_both_none(self):
        """Should return (None, None) when both dates are None."""
        result = validate_date_range(None, None)
        assert result == (None, None)

    def test_accepts_valid_range(self):
        """Should accept valid date range."""
        start = datetime(2024, 1, 1)
        end = datetime(2024, 1, 31)
        
        result = validate_date_range(start, end)
        
        assert result == (start, end)

    def test_rejects_start_after_end(self):
        """Should reject when start is after end."""
        start = datetime(2024, 2, 1)
        end = datetime(2024, 1, 1)
        
        with pytest.raises(ValueError) as exc_info:
            validate_date_range(start, end)
        assert "must be before" in str(exc_info.value)

    def test_rejects_future_start_date(self):
        """Should reject future start date."""
        future = datetime.utcnow() + timedelta(days=30)
        
        with pytest.raises(ValueError) as exc_info:
            validate_date_range(future, None)
        assert "cannot be in the future" in str(exc_info.value)

    def test_rejects_future_end_date(self):
        """Should reject future end date."""
        future = datetime.utcnow() + timedelta(days=30)
        
        with pytest.raises(ValueError) as exc_info:
            validate_date_range(None, future)
        assert "cannot be in the future" in str(exc_info.value)

    def test_rejects_range_too_large(self):
        """Should reject range exceeding max_days."""
        start = datetime(2023, 1, 1)
        end = datetime(2024, 6, 1)  # > 365 days
        
        with pytest.raises(ValueError) as exc_info:
            validate_date_range(start, end, max_days=365)
        assert "too large" in str(exc_info.value)

    def test_accepts_max_range(self):
        """Should accept range exactly at max_days."""
        end = datetime.utcnow() - timedelta(days=1)
        start = end - timedelta(days=365)
        
        result = validate_date_range(start, end, max_days=365)
        
        assert result == (start, end)


class TestValidatePercentage:
    """Tests for percentage validation."""

    def test_accepts_valid_percentages(self):
        """Should accept percentages between 0 and 100."""
        valid = [0, 0.0, 50, 50.5, 99.99, 100]
        
        for pct in valid:
            result = validate_percentage(pct)
            assert 0 <= result <= 100

    def test_rounds_to_two_decimals(self):
        """Should round to 2 decimal places."""
        result = validate_percentage(50.12345)
        assert result == 50.12

    def test_rejects_negative(self):
        """Should reject negative percentages."""
        with pytest.raises(ValueError) as exc_info:
            validate_percentage(-1)
        assert "cannot be negative" in str(exc_info.value)

    def test_rejects_over_100(self):
        """Should reject percentages over 100."""
        with pytest.raises(ValueError) as exc_info:
            validate_percentage(101)
        assert "cannot exceed 100" in str(exc_info.value)


class TestValidatePositiveAmount:
    """Tests for positive amount validation."""

    def test_accepts_positive_amounts(self):
        """Should accept positive amounts."""
        valid = [0.01, 1, 100, 1000000]
        
        for amount in valid:
            result = validate_positive_amount(amount)
            assert result > 0

    def test_rounds_to_two_decimals(self):
        """Should round to 2 decimal places."""
        result = validate_positive_amount(123.456789)
        assert result == 123.46

    def test_rejects_zero(self):
        """Should reject zero."""
        with pytest.raises(ValueError) as exc_info:
            validate_positive_amount(0)
        assert "must be positive" in str(exc_info.value)

    def test_rejects_negative(self):
        """Should reject negative amounts."""
        with pytest.raises(ValueError) as exc_info:
            validate_positive_amount(-100)
        assert "must be positive" in str(exc_info.value)

    def test_uses_custom_field_name(self):
        """Should use custom field name in error message."""
        with pytest.raises(ValueError) as exc_info:
            validate_positive_amount(0, field_name="budget_amount")
        assert "budget_amount" in str(exc_info.value)
