"""Celery application for async task processing."""

from celery import Celery
from celery.schedules import crontab

from app.core import get_settings

settings = get_settings()

celery_app = Celery(
    "cloudoptima",
    broker=settings.redis_url,
    backend=settings.redis_url,
    include=[
        "app.services.azure_cost_ingestion",
        "app.services.recommendation_engine",
    ],
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    task_track_started=True,
    task_acks_late=True,
    worker_prefetch_multiplier=1,
)

# Scheduled tasks — ingest costs daily, generate recommendations after ingestion
celery_app.conf.beat_schedule = {
    "ingest-azure-costs-daily": {
        "task": "app.services.azure_cost_ingestion.ingest_all_connections",
        "schedule": crontab(hour=2, minute=0),  # 2 AM UTC daily
    },
    "generate-recommendations-daily": {
        "task": "app.services.recommendation_engine.generate_all_recommendations",
        "schedule": crontab(hour=3, minute=0),  # 3 AM UTC daily (after ingestion)
    },
}
