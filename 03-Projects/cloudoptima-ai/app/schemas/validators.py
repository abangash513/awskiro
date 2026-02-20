"""Common validators for API schemas."""

import re
from datetime import datetime
from typing import Optional

from pydantic import field_validator, model_validator


# Azure subscription ID pattern (GUID format)
AZURE_SUBSCRIPTION_PATTERN = re.compile(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
    re.IGNORECASE,
)

# Azure resource group name pattern
# 1-90 chars, alphanumeric, underscores, hyphens, periods, parentheses
# Cannot end with a period
RESOURCE_GROUP_PATTERN = re.compile(
    r"^[-\w\._\(\)]{1,89}[^.]$",
    re.UNICODE,
)


def validate_subscription_id(v: Optional[str]) -> Optional[str]:
    """
    Validate Azure subscription ID format.
    
    Args:
        v: Subscription ID string (or None)
        
    Returns:
        Validated subscription ID in lowercase
        
    Raises:
        ValueError: If format is invalid
    """
    if v is None:
        return None
    
    v = v.strip().lower()
    if not AZURE_SUBSCRIPTION_PATTERN.match(v):
        raise ValueError(
            f"Invalid subscription ID format. Expected UUID format "
            f"(e.g., '12345678-1234-1234-1234-123456789abc'), got: '{v}'"
        )
    return v


def validate_resource_group(v: Optional[str]) -> Optional[str]:
    """
    Validate Azure resource group name format.
    
    Args:
        v: Resource group name (or None)
        
    Returns:
        Validated resource group name
        
    Raises:
        ValueError: If format is invalid
    """
    if v is None:
        return None
    
    v = v.strip()
    
    if len(v) < 1:
        raise ValueError("Resource group name cannot be empty")
    
    if len(v) > 90:
        raise ValueError(
            f"Resource group name too long ({len(v)} chars). Maximum is 90 characters."
        )
    
    if not RESOURCE_GROUP_PATTERN.match(v):
        raise ValueError(
            f"Invalid resource group name format. "
            f"Name must be 1-90 characters, containing only alphanumeric, "
            f"underscores, hyphens, periods, or parentheses. Cannot end with a period."
        )
    
    return v


def validate_date_range(
    start_date: Optional[datetime],
    end_date: Optional[datetime],
    max_days: int = 365,
) -> tuple[Optional[datetime], Optional[datetime]]:
    """
    Validate date range constraints.
    
    Args:
        start_date: Start of date range
        end_date: End of date range
        max_days: Maximum allowed days in range
        
    Returns:
        Tuple of (start_date, end_date)
        
    Raises:
        ValueError: If date range is invalid
    """
    if start_date is None and end_date is None:
        return start_date, end_date
    
    now = datetime.utcnow()
    
    if start_date and start_date > now:
        raise ValueError(
            f"Start date cannot be in the future. Got: {start_date.isoformat()}"
        )
    
    if end_date and end_date > now:
        raise ValueError(
            f"End date cannot be in the future. Got: {end_date.isoformat()}"
        )
    
    if start_date and end_date:
        if start_date > end_date:
            raise ValueError(
                f"Start date ({start_date.isoformat()}) must be before "
                f"end date ({end_date.isoformat()})"
            )
        
        delta = (end_date - start_date).days
        if delta > max_days:
            raise ValueError(
                f"Date range too large ({delta} days). Maximum is {max_days} days."
            )
    
    return start_date, end_date


def validate_percentage(v: float, field_name: str = "value") -> float:
    """
    Validate percentage value.
    
    Args:
        v: Percentage value
        field_name: Name of field for error messages
        
    Returns:
        Validated percentage
        
    Raises:
        ValueError: If percentage is invalid
    """
    if v < 0:
        raise ValueError(f"{field_name} cannot be negative")
    if v > 100:
        raise ValueError(f"{field_name} cannot exceed 100%")
    return round(v, 2)


def validate_positive_amount(v: float, field_name: str = "amount") -> float:
    """
    Validate positive monetary amount.
    
    Args:
        v: Amount value
        field_name: Name of field for error messages
        
    Returns:
        Validated amount
        
    Raises:
        ValueError: If amount is not positive
    """
    if v <= 0:
        raise ValueError(f"{field_name} must be positive")
    return round(v, 2)
