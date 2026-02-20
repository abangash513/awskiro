"""Application configuration — loaded from environment variables."""

from functools import lru_cache
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # App
    app_name: str = "CloudOptima AI"
    app_env: str = "development"
    log_level: str = "INFO"
    cors_origins: str = "http://localhost:3000,http://52.179.209.239:3000"

    # Database
    database_url: str = "postgresql+asyncpg://cloudoptima:cloudoptima@db:5432/cloudoptima"
    database_url_sync: str = "postgresql://cloudoptima:cloudoptima@db:5432/cloudoptima"

    # Redis
    redis_url: str = "redis://redis:6379/0"

    # Security
    secret_key: str = "change-me-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60

    # Azure
    azure_tenant_id: str = ""
    azure_client_id: str = ""
    azure_client_secret: str = ""

    # Azure OpenAI (Phase 2+)
    azure_openai_endpoint: str = ""
    azure_openai_key: str = ""
    azure_openai_deployment: str = ""

    class Config:
        env_file = ".env"
        case_sensitive = False


@lru_cache()
def get_settings() -> Settings:
    return Settings()
