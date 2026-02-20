"""Application configuration using Pydantic Settings."""

from functools import lru_cache
from typing import Optional

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # Azure Authentication
    azure_tenant_id: str = Field(default="", description="Azure AD Tenant ID")
    azure_client_id: str = Field(default="", description="Azure AD Client ID")
    azure_client_secret: str = Field(default="", description="Azure AD Client Secret")
    azure_subscription_id: str = Field(default="", description="Default Azure Subscription ID")

    # Database
    database_url: str = Field(
        default="sqlite+aiosqlite:///./cloudoptima.db",
        description="Database connection URL",
    )

    # API Settings
    api_host: str = Field(default="0.0.0.0", description="API host address")
    api_port: int = Field(default=8000, description="API port")
    api_debug: bool = Field(default=False, description="Enable debug mode")
    api_title: str = Field(default="CloudOptima AI", description="API title")
    api_version: str = Field(default="0.1.0", description="API version")

    # Cost Analysis Settings
    cost_lookback_days: int = Field(default=30, description="Days to look back for cost data")
    budget_alert_threshold: float = Field(
        default=0.8, description="Budget alert threshold (0.0-1.0)"
    )

    # Logging
    log_level: str = Field(default="INFO", description="Logging level")

    # Authentication
    api_key: str = Field(default="", description="Primary API key (optional, enables auth)")
    auth_enabled: bool = Field(default=True, description="Enable API key authentication")
    
    # CORS - SECURITY: Always specify explicit origins, never use "*" in production
    cors_origins: list[str] = Field(
        default=["http://localhost:3000", "http://localhost:8080"],
        description="Allowed CORS origins (explicit list, no wildcards in production)",
    )

    # Notification Settings
    notification_webhook_url: Optional[str] = Field(
        default=None,
        description="Generic webhook URL for notifications",
    )
    slack_webhook_url: Optional[str] = Field(
        default=None,
        description="Slack incoming webhook URL for notifications",
    )
    teams_webhook_url: Optional[str] = Field(
        default=None,
        description="Microsoft Teams incoming webhook URL for notifications",
    )
    notifications_enabled: bool = Field(
        default=True,
        description="Enable/disable notification sending globally",
    )

    @field_validator("cors_origins")
    @classmethod
    def validate_cors_origins(cls, v: list[str]) -> list[str]:
        """Validate CORS origins for security."""
        if not v:
            return ["http://localhost:3000", "http://localhost:8080"]
        
        # Warn about wildcard (but don't remove - let main.py handle based on debug mode)
        if "*" in v:
            import warnings
            warnings.warn(
                "CORS wildcard '*' is insecure. Use explicit origins in production.",
                UserWarning,
            )
        
        return v

    @field_validator("budget_alert_threshold")
    @classmethod
    def validate_threshold(cls, v: float) -> float:
        """Ensure threshold is between 0 and 1."""
        if not 0.0 <= v <= 1.0:
            raise ValueError("budget_alert_threshold must be between 0.0 and 1.0")
        return v

    @property
    def is_azure_configured(self) -> bool:
        """Check if Azure credentials are configured."""
        return all([
            self.azure_tenant_id,
            self.azure_client_id,
            self.azure_client_secret,
            self.azure_subscription_id,
        ])


@lru_cache
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
