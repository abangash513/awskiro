"""Pydantic schemas for API request/response validation."""

from datetime import datetime, date
from typing import Optional
from pydantic import BaseModel, EmailStr, Field


# ── Auth ────────────────────────────────────────────────────────────

class UserCreate(BaseModel):
    email: str = Field(..., max_length=255)
    password: str = Field(..., min_length=8)
    full_name: str = Field(..., max_length=255)
    organization_name: str = Field(..., max_length=255)

class UserLogin(BaseModel):
    email: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"

class UserResponse(BaseModel):
    id: int
    email: str
    full_name: str
    role: str
    organization_id: int
    class Config:
        from_attributes = True


# ── Organizations ───────────────────────────────────────────────────

class OrganizationResponse(BaseModel):
    id: int
    name: str
    slug: str
    plan: str
    is_active: bool
    created_at: datetime
    class Config:
        from_attributes = True


# ── Cloud Connections ───────────────────────────────────────────────

class CloudConnectionCreate(BaseModel):
    provider: str = Field(default="azure", pattern="^(azure|aws)$")
    display_name: str = Field(..., max_length=255)
    subscription_id: str = Field(..., max_length=100)
    tenant_id: str = Field(..., max_length=100)

class CloudConnectionResponse(BaseModel):
    id: int
    provider: str
    display_name: str
    subscription_id: Optional[str]
    is_active: bool
    last_ingestion_at: Optional[datetime]
    ingestion_status: str
    created_at: datetime
    class Config:
        from_attributes = True


# ── Cost Data ───────────────────────────────────────────────────────

class CostSummary(BaseModel):
    """Aggregated cost summary for a time period."""
    total_billed_cost: float
    total_effective_cost: float
    period_start: date
    period_end: date
    cost_change_percent: Optional[float] = None  # vs prior period
    top_services: list[dict] = []
    top_resource_groups: list[dict] = []

class CostTrend(BaseModel):
    """Daily cost data point for trend charts."""
    date: date
    billed_cost: float
    effective_cost: float
    service_name: Optional[str] = None

class CostByDimension(BaseModel):
    """Cost grouped by a dimension (service, resource group, tag, region)."""
    dimension: str
    value: str
    billed_cost: float
    effective_cost: float
    percent_of_total: float


# ── Recommendations ─────────────────────────────────────────────────

class RecommendationResponse(BaseModel):
    id: int
    category: str
    title: str
    description: str
    impact: str
    difficulty: str
    estimated_monthly_savings: float
    estimated_annual_savings: float
    confidence: float
    current_config: Optional[dict] = None
    recommended_config: Optional[dict] = None
    status: str
    resource_id: Optional[str] = None
    created_at: datetime
    class Config:
        from_attributes = True

class RecommendationUpdate(BaseModel):
    status: str = Field(..., pattern="^(accepted|dismissed|implemented)$")
    dismissed_reason: Optional[str] = None

class RecommendationSummary(BaseModel):
    total_open: int
    total_monthly_savings: float
    total_annual_savings: float
    by_category: dict[str, int]
    by_impact: dict[str, int]


# ── AI Workloads ────────────────────────────────────────────────────

class AIWorkloadSummary(BaseModel):
    """Summary of AI/ML spending and usage."""
    total_ai_cost: float
    total_ai_cost_change_percent: Optional[float] = None
    total_tokens: Optional[int] = None
    total_gpu_hours: Optional[float] = None
    cost_per_1k_tokens_avg: Optional[float] = None
    avg_gpu_utilization: Optional[float] = None
    by_service_type: list[dict] = []
    by_model: list[dict] = []
    daily_trend: list[dict] = []

class AIWorkloadResponse(BaseModel):
    id: int
    service_type: str
    resource_name: Optional[str]
    deployment_name: Optional[str]
    model_name: Optional[str]
    total_cost: float
    total_tokens: Optional[int]
    avg_gpu_utilization: Optional[float]
    cost_per_1k_tokens: Optional[float]
    cost_per_gpu_hour: Optional[float]
    period_start: date
    period_end: date
    class Config:
        from_attributes = True


# ── FOCUS Export ────────────────────────────────────────────────────

class FOCUSExportRequest(BaseModel):
    start_date: date
    end_date: date
    format: str = Field(default="csv", pattern="^(csv|parquet|json)$")
    cloud_connection_id: Optional[int] = None


# ── Budgets ─────────────────────────────────────────────────────────

class BudgetCreate(BaseModel):
    name: str = Field(..., max_length=255)
    amount: float = Field(..., gt=0)
    period: str = Field(default="monthly", pattern="^(monthly|quarterly|annual)$")
    scope: Optional[str] = None
    alert_thresholds: str = Field(default="50,80,100")

class BudgetResponse(BaseModel):
    id: int
    name: str
    amount: float
    period: str
    current_spend: float
    alert_thresholds: str
    is_active: bool
    created_at: datetime
    class Config:
        from_attributes = True


# ── Dashboard ───────────────────────────────────────────────────────

class DashboardData(BaseModel):
    """All data needed for the main dashboard view."""
    cost_summary: CostSummary
    cost_trend: list[CostTrend]
    top_services: list[CostByDimension]
    top_resources: list[dict]
    recommendation_summary: RecommendationSummary
    ai_summary: Optional[AIWorkloadSummary] = None
    alerts: list[dict] = []
