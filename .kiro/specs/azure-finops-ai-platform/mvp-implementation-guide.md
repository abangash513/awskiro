---
title: CloudOptima AI - MVP Implementation Guide
version: 1.0.0
created: 2026-02-13
---

# CloudOptima AI - MVP Implementation Guide

## Overview

This guide provides step-by-step instructions for building the MVP (Minimum Viable Product) of CloudOptima AI.

## MVP Scope

The MVP focuses on core FinOps functionality for Azure:
- Azure resource discovery
- Cost analysis and forecasting
- Basic recommendations (idle VMs, unattached disks, storage optimization)
- Simple web UI with dashboards
- PDF report generation
- Basic AI-powered natural language queries

## Project Structure

```
cloudoptima-ai/
├── backend/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py                    # FastAPI application
│   │   ├── config.py                  # Configuration
│   │   ├── database.py                # Database connection
│   │   ├── models/                    # SQLAlchemy models
│   │   │   ├── __init__.py
│   │   │   ├── organization.py
│   │   │   ├── user.py
│   │   │   ├── connection.py
│   │   │   ├── resource.py
│   │   │   ├── recommendation.py
│   │   │   └── cost.py
│   │   ├── schemas/                   # Pydantic schemas
│   │   │   ├── __init__.py
│   │   │   ├── auth.py
│   │   │   ├── connection.py
│   │   │   ├── resource.py
│   │   │   └── recommendation.py
│   │   ├── api/                       # API routes
│   │   │   ├── __init__.py
│   │   │   ├── auth.py
│   │   │   ├── connections.py
│   │   │   ├── resources.py
│   │   │   ├── recommendations.py
│   │   │   ├── analysis.py
│   │   │   └── ai.py
│   │   ├── services/                  # Business logic
│   │   │   ├── __init__.py
│   │   │   ├── azure_connector.py
│   │   │   ├── discovery_service.py
│   │   │   ├── finops_analyzer.py
│   │   │   ├── forecasting_service.py
│   │   │   ├── ai_service.py
│   │   │   └── report_service.py
│   │   ├── core/                      # Core utilities
│   │   │   ├── __init__.py
│   │   │   ├── security.py
│   │   │   ├── dependencies.py
│   │   │   └── exceptions.py
│   │   └── utils/
│   │       ├── __init__.py
│   │       ├── encryption.py
│   │       └── formatters.py
│   ├── tests/
│   │   ├── __init__.py
│   │   ├── conftest.py
│   │   ├── test_api/
│   │   ├── test_services/
│   │   └── test_models/
│   ├── alembic/                       # Database migrations
│   │   ├── versions/
│   │   └── env.py
│   ├── requirements.txt
│   ├── requirements-dev.txt
│   ├── Dockerfile
│   └── .env.example
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── ui/                    # shadcn/ui components
│   │   │   ├── layout/
│   │   │   │   ├── Header.tsx
│   │   │   │   ├── Sidebar.tsx
│   │   │   │   └── Layout.tsx
│   │   │   ├── dashboard/
│   │   │   │   ├── CostChart.tsx
│   │   │   │   ├── MetricCard.tsx
│   │   │   │   └── RecommendationList.tsx
│   │   │   ├── resources/
│   │   │   │   └── ResourceTable.tsx
│   │   │   └── ai/
│   │   │       └── ChatInterface.tsx
│   │   ├── pages/
│   │   │   ├── Dashboard.tsx
│   │   │   ├── Resources.tsx
│   │   │   ├── Recommendations.tsx
│   │   │   └── Settings.tsx
│   │   ├── hooks/
│   │   │   ├── useAuth.ts
│   │   │   ├── useResources.ts
│   │   │   └── useRecommendations.ts
│   │   ├── services/
│   │   │   └── api.ts
│   │   ├── stores/
│   │   │   └── authStore.ts
│   │   ├── utils/
│   │   │   └── formatters.ts
│   │   ├── App.tsx
│   │   └── main.tsx
│   ├── public/
│   ├── package.json
│   ├── tsconfig.json
│   ├── vite.config.ts
│   └── Dockerfile
├── docker-compose.yml
├── .gitignore
└── README.md
```

## Phase 1: Backend Setup (Week 1)

### Step 1.1: Initialize Project

```bash
# Create project structure
mkdir -p cloudoptima-ai/backend/app/{models,schemas,api,services,core,utils}
mkdir -p cloudoptima-ai/backend/tests
mkdir -p cloudoptima-ai/frontend/src

cd cloudoptima-ai/backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Create requirements.txt
cat > requirements.txt << EOF
fastapi==0.109.0
uvicorn[standard]==0.27.0
sqlalchemy==2.0.25
psycopg2-binary==2.9.9
alembic==1.13.1
pydantic==2.5.3
pydantic-settings==2.1.0
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6
azure-identity==1.15.0
azure-mgmt-resource==23.0.1
azure-mgmt-compute==30.5.0
azure-mgmt-storage==21.1.0
azure-mgmt-costmanagement==4.0.1
azure-mgmt-monitor==6.0.2
redis==5.0.1
celery==5.3.6
pandas==2.2.0
numpy==1.26.3
scikit-learn==1.4.0
prophet==1.1.5
openai==1.10.0
langchain==0.1.4
reportlab==4.0.9
jinja2==3.1.3
python-dotenv==1.0.0
httpx==0.26.0
tenacity==8.2.3
structlog==24.1.0
EOF

pip install -r requirements.txt
```

### Step 1.2: Configuration Setup

```python
# app/config.py
from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    # Application
    APP_NAME: str = "CloudOptima AI"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False
    
    # Database
    DATABASE_URL: str
    
    # Redis
    REDIS_URL: str = "redis://localhost:6379"
    
    # Security
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 15
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    
    # Azure (optional for testing)
    AZURE_TENANT_ID: Optional[str] = None
    AZURE_CLIENT_ID: Optional[str] = None
    AZURE_CLIENT_SECRET: Optional[str] = None
    
    # OpenAI
    OPENAI_API_KEY: Optional[str] = None
    OPENAI_MODEL: str = "gpt-4"
    
    # CORS
    CORS_ORIGINS: list = ["http://localhost:3000"]
    
    class Config:
        env_file = ".env"
        case_sensitive = True

settings = Settings()
```

```bash
# Create .env.example
cat > .env.example << EOF
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/cloudoptima

# Redis
REDIS_URL=redis://localhost:6379

# Security
SECRET_KEY=your-secret-key-here-change-in-production
ALGORITHM=HS256

# OpenAI (optional for MVP)
OPENAI_API_KEY=sk-...

# CORS
CORS_ORIGINS=["http://localhost:3000"]
EOF
```

### Step 1.3: Database Models

```python
# app/models/base.py
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy import Column, DateTime
from datetime import datetime
import uuid

Base = declarative_base()

class TimestampMixin:
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
```

```python
# app/models/organization.py
from sqlalchemy import Column, String, JSON
from sqlalchemy.dialects.postgresql import UUID
from .base import Base, TimestampMixin
import uuid

class Organization(Base, TimestampMixin):
    __tablename__ = "organizations"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    subscription_tier = Column(String(50), default="free")
    settings = Column(JSON, default={})
```

```python
# app/models/user.py
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from .base import Base, TimestampMixin
import uuid

class User(Base, TimestampMixin):
    __tablename__ = "users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="CASCADE"))
    email = Column(String(255), unique=True, nullable=False)
    name = Column(String(255), nullable=False)
    password_hash = Column(String(255))
    role = Column(String(50), default="member")
    last_login = Column(DateTime)
    
    organization = relationship("Organization", backref="users")
```

```python
# app/models/resource.py
from sqlalchemy import Column, String, Numeric, DateTime, ForeignKey, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from .base import Base, TimestampMixin
import uuid

class Resource(Base, TimestampMixin):
    __tablename__ = "resources"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="CASCADE"))
    connection_id = Column(UUID(as_uuid=True), ForeignKey("cloud_connections.id", ondelete="CASCADE"))
    cloud_provider = Column(String(50), nullable=False)
    resource_type = Column(String(255), nullable=False)
    resource_id = Column(String(500), nullable=False)
    name = Column(String(500))
    region = Column(String(100))
    resource_group = Column(String(255))
    tags = Column(JSON, default={})
    properties = Column(JSON, default={})
    cost_monthly = Column(Numeric(12, 2))
    discovered_at = Column(DateTime)
    
    organization = relationship("Organization")
    connection = relationship("CloudConnection")
```

```python
# app/models/recommendation.py
from sqlalchemy import Column, String, Numeric, DateTime, ForeignKey, JSON, Boolean, Integer
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from .base import Base, TimestampMixin
import uuid

class Recommendation(Base, TimestampMixin):
    __tablename__ = "recommendations"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id", ondelete="CASCADE"))
    resource_id = Column(UUID(as_uuid=True), ForeignKey("resources.id", ondelete="CASCADE"))
    type = Column(String(100), nullable=False)
    category = Column(String(50), nullable=False)
    title = Column(String(500), nullable=False)
    description = Column(String)
    impact = Column(String(20), nullable=False)
    effort = Column(String(20), nullable=False)
    monthly_savings = Column(Numeric(12, 2))
    annual_savings = Column(Numeric(12, 2))
    risk_level = Column(String(20))
    status = Column(String(50), default="open")
    priority_score = Column(Integer)
    metadata = Column(JSON, default={})
    auto_remediable = Column(Boolean, default=False)
    
    organization = relationship("Organization")
    resource = relationship("Resource")
```

### Step 1.4: FastAPI Application

```python
# app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.api import auth, connections, resources, recommendations, analysis, ai

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    docs_url="/api/docs",
    redoc_url="/api/redoc"
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/api/v1/auth", tags=["Authentication"])
app.include_router(connections.router, prefix="/api/v1/connections", tags=["Connections"])
app.include_router(resources.router, prefix="/api/v1/resources", tags=["Resources"])
app.include_router(recommendations.router, prefix="/api/v1/recommendations", tags=["Recommendations"])
app.include_router(analysis.router, prefix="/api/v1/analysis", tags=["Analysis"])
app.include_router(ai.router, prefix="/api/v1/ai", tags=["AI"])

@app.get("/")
def root():
    return {
        "name": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "status": "running"
    }

@app.get("/health")
def health_check():
    return {"status": "healthy"}
```

### Step 1.5: Azure Connector Service

```python
# app/services/azure_connector.py
from azure.identity import ClientSecretCredential
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.compute import ComputeManagementClient
from azure.mgmt.storage import StorageManagementClient
from azure.mgmt.monitor import MonitorManagementClient
from azure.mgmt.costmanagement import CostManagementClient
from typing import List, Dict
import logging

logger = logging.getLogger(__name__)

class AzureConnector:
    def __init__(self, tenant_id: str, client_id: str, client_secret: str, subscription_id: str):
        self.subscription_id = subscription_id
        self.credential = ClientSecretCredential(
            tenant_id=tenant_id,
            client_id=client_id,
            client_secret=client_secret
        )
        
        # Initialize clients
        self.resource_client = ResourceManagementClient(self.credential, subscription_id)
        self.compute_client = ComputeManagementClient(self.credential, subscription_id)
        self.storage_client = StorageManagementClient(self.credential, subscription_id)
        self.monitor_client = MonitorManagementClient(self.credential, subscription_id)
        self.cost_client = CostManagementClient(self.credential)
    
    def discover_all_resources(self) -> List[Dict]:
        """Discover all resources in the subscription"""
        resources = []
        
        try:
            # Get all resources
            for resource in self.resource_client.resources.list():
                resources.append({
                    "resource_id": resource.id,
                    "name": resource.name,
                    "type": resource.type,
                    "location": resource.location,
                    "resource_group": resource.id.split("/")[4] if len(resource.id.split("/")) > 4 else None,
                    "tags": resource.tags or {},
                    "properties": {}
                })
            
            logger.info(f"Discovered {len(resources)} resources")
            return resources
            
        except Exception as e:
            logger.error(f"Error discovering resources: {e}")
            raise
    
    def get_virtual_machines(self) -> List[Dict]:
        """Get all virtual machines with details"""
        vms = []
        
        try:
            for vm in self.compute_client.virtual_machines.list_all():
                vm_details = {
                    "resource_id": vm.id,
                    "name": vm.name,
                    "type": "Microsoft.Compute/virtualMachines",
                    "location": vm.location,
                    "resource_group": vm.id.split("/")[4],
                    "tags": vm.tags or {},
                    "properties": {
                        "vm_size": vm.hardware_profile.vm_size,
                        "os_type": vm.storage_profile.os_disk.os_type,
                        "provisioning_state": vm.provisioning_state
                    }
                }
                vms.append(vm_details)
            
            return vms
            
        except Exception as e:
            logger.error(f"Error getting VMs: {e}")
            raise
    
    def get_disks(self) -> List[Dict]:
        """Get all managed disks"""
        disks = []
        
        try:
            for disk in self.compute_client.disks.list():
                disk_details = {
                    "resource_id": disk.id,
                    "name": disk.name,
                    "type": "Microsoft.Compute/disks",
                    "location": disk.location,
                    "resource_group": disk.id.split("/")[4],
                    "tags": disk.tags or {},
                    "properties": {
                        "disk_size_gb": disk.disk_size_gb,
                        "disk_state": disk.disk_state,
                        "sku": disk.sku.name if disk.sku else None,
                        "managed_by": disk.managed_by
                    }
                }
                disks.append(disk_details)
            
            return disks
            
        except Exception as e:
            logger.error(f"Error getting disks: {e}")
            raise
    
    def get_resource_metrics(self, resource_id: str, metric_names: List[str], timespan: str = "PT1H") -> Dict:
        """Get metrics for a specific resource"""
        try:
            metrics_data = self.monitor_client.metrics.list(
                resource_id,
                timespan=timespan,
                interval='PT1M',
                metricnames=','.join(metric_names),
                aggregation='Average'
            )
            
            result = {}
            for metric in metrics_data.value:
                if metric.timeseries:
                    values = [data.average for data in metric.timeseries[0].data if data.average is not None]
                    if values:
                        result[metric.name.value] = {
                            "average": sum(values) / len(values),
                            "min": min(values),
                            "max": max(values)
                        }
            
            return result
            
        except Exception as e:
            logger.error(f"Error getting metrics for {resource_id}: {e}")
            return {}
    
    def test_connection(self) -> bool:
        """Test if the connection is valid"""
        try:
            # Try to list resource groups
            list(self.resource_client.resource_groups.list())
            return True
        except Exception as e:
            logger.error(f"Connection test failed: {e}")
            return False
```

### Step 1.6: FinOps Analyzer Service

```python
# app/services/finops_analyzer.py
from typing import List, Dict
from app.models.resource import Resource
from app.models.recommendation import Recommendation
from datetime import datetime, timedelta
import logging

logger = logging.getLogger(__name__)

class FinOpsAnalyzer:
    def __init__(self, azure_connector):
        self.azure = azure_connector
    
    def analyze_idle_vms(self, vms: List[Resource]) -> List[Dict]:
        """Detect idle VMs based on CPU utilization"""
        recommendations = []
        
        for vm in vms:
            if vm.properties.get("provisioning_state") != "Succeeded":
                continue
            
            # Get CPU metrics for last 7 days
            metrics = self.azure.get_resource_metrics(
                vm.resource_id,
                ["Percentage CPU"],
                timespan="P7D"
            )
            
            if "Percentage CPU" in metrics:
                avg_cpu = metrics["Percentage CPU"]["average"]
                
                # If CPU < 5% for 7 days, consider it idle
                if avg_cpu < 5.0:
                    monthly_savings = vm.cost_monthly or 0
                    
                    recommendations.append({
                        "resource_id": vm.id,
                        "type": "idle_vm",
                        "category": "cost",
                        "title": f"Idle VM: {vm.name}",
                        "description": f"VM has been running with {avg_cpu:.1f}% average CPU for 7 days. Consider stopping or deleting it.",
                        "impact": "high" if monthly_savings > 500 else "medium",
                        "effort": "easy",
                        "monthly_savings": monthly_savings,
                        "annual_savings": monthly_savings * 12,
                        "risk_level": "low",
                        "metadata": {
                            "avg_cpu": avg_cpu,
                            "vm_size": vm.properties.get("vm_size")
                        }
                    })
        
        return recommendations
    
    def analyze_unattached_disks(self, disks: List[Resource]) -> List[Dict]:
        """Detect unattached managed disks"""
        recommendations = []
        
        for disk in disks:
            if not disk.properties.get("managed_by"):
                # Disk is not attached to any VM
                monthly_cost = disk.cost_monthly or 0
                
                recommendations.append({
                    "resource_id": disk.id,
                    "type": "unattached_disk",
                    "category": "cost",
                    "title": f"Unattached Disk: {disk.name}",
                    "description": f"Disk is not attached to any VM. Consider deleting if not needed.",
                    "impact": "medium" if monthly_cost > 50 else "low",
                    "effort": "easy",
                    "monthly_savings": monthly_cost,
                    "annual_savings": monthly_cost * 12,
                    "risk_level": "medium",
                    "metadata": {
                        "disk_size_gb": disk.properties.get("disk_size_gb"),
                        "sku": disk.properties.get("sku")
                    }
                })
        
        return recommendations
    
    def analyze_storage_tiers(self, storage_accounts: List[Resource]) -> List[Dict]:
        """Analyze storage account tier optimization opportunities"""
        recommendations = []
        
        # This would require analyzing blob access patterns
        # Simplified for MVP
        
        return recommendations
    
    def generate_all_recommendations(self, resources: List[Resource]) -> List[Dict]:
        """Generate all recommendations for given resources"""
        all_recommendations = []
        
        # Separate resources by type
        vms = [r for r in resources if r.resource_type == "Microsoft.Compute/virtualMachines"]
        disks = [r for r in resources if r.resource_type == "Microsoft.Compute/disks"]
        
        # Run analyzers
        all_recommendations.extend(self.analyze_idle_vms(vms))
        all_recommendations.extend(self.analyze_unattached_disks(disks))
        
        logger.info(f"Generated {len(all_recommendations)} recommendations")
        return all_recommendations
```

### Step 1.7: AI Service (Basic NLP)

```python
# app/services/ai_service.py
from openai import OpenAI
from typing import Dict, List
import json
import logging

logger = logging.getLogger(__name__)

class AIService:
    def __init__(self, api_key: str, model: str = "gpt-4"):
        self.client = OpenAI(api_key=api_key)
        self.model = model
    
    async def process_query(self, query: str, context: Dict) -> Dict:
        """Process natural language query about cloud costs"""
        
        system_prompt = """You are a cloud cost optimization assistant.
        You help users understand their cloud spending and provide actionable recommendations.
        
        Available data context:
        - Total monthly cost
        - Top cost resources
        - Recent recommendations
        - Cost trends
        
        Provide concise, actionable responses with specific numbers when available.
        """
        
        user_prompt = f"""
        User query: {query}
        
        Context:
        {json.dumps(context, indent=2)}
        
        Provide a helpful response based on the available data.
        """
        
        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                temperature=0.7,
                max_tokens=500
            )
            
            answer = response.choices[0].message.content
            
            return {
                "query": query,
                "answer": answer,
                "tokens_used": response.usage.total_tokens
            }
            
        except Exception as e:
            logger.error(f"Error processing AI query: {e}")
            return {
                "query": query,
                "answer": "I'm sorry, I encountered an error processing your query. Please try again.",
                "error": str(e)
            }
    
    def generate_report_summary(self, data: Dict) -> str:
        """Generate executive summary for reports"""
        
        prompt = f"""
        Generate a concise executive summary (3-4 sentences) for a cloud cost optimization report.
        
        Data:
        - Total monthly cost: ${data.get('total_cost', 0):,.2f}
        - Number of resources: {data.get('resource_count', 0)}
        - Potential monthly savings: ${data.get('potential_savings', 0):,.2f}
        - Number of recommendations: {data.get('recommendation_count', 0)}
        
        Focus on key insights and actionable items.
        """
        
        try:
            response = self.client.chat.completions.create(
                model=self.model,
                messages=[{"role": "user", "content": prompt}],
                temperature=0.7,
                max_tokens=200
            )
            
            return response.choices[0].message.content
            
        except Exception as e:
            logger.error(f"Error generating summary: {e}")
            return "Unable to generate summary at this time."
```

## Phase 2: Frontend Setup (Week 2)

### Step 2.1: Initialize React Project

```bash
cd ../frontend

# Create Vite + React + TypeScript project
npm create vite@latest . -- --template react-ts

# Install dependencies
npm install

# Install additional packages
npm install @tanstack/react-query axios zustand
npm install react-router-dom
npm install recharts
npm install @radix-ui/react-dialog @radix-ui/react-dropdown-menu
npm install tailwindcss postcss autoprefixer
npm install -D @types/node

# Initialize Tailwind
npx tailwindcss init -p
```

### Step 2.2: Basic Dashboard Component

```typescript
// src/pages/Dashboard.tsx
import { useQuery } from '@tanstack/react-query';
import { api } from '../services/api';
import { MetricCard } from '../components/dashboard/MetricCard';
import { CostChart } from '../components/dashboard/CostChart';
import { RecommendationList } from '../components/dashboard/RecommendationList';

export function Dashboard() {
  const { data: dashboardData, isLoading } = useQuery({
    queryKey: ['dashboard'],
    queryFn: () => api.get('/dashboards/finops')
  });

  if (isLoading) {
    return <div>Loading...</div>;
  }

  return (
    <div className="p-6 space-y-6">
      <h1 className="text-3xl font-bold">Dashboard</h1>
      
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <MetricCard
          title="Monthly Cost"
          value={`$${dashboardData?.currentCost?.toLocaleString()}`}
          change={dashboardData?.costChange}
        />
        <MetricCard
          title="Potential Savings"
          value={`$${dashboardData?.potentialSavings?.toLocaleString()}`}
          trend="up"
        />
        <MetricCard
          title="Resources"
          value={dashboardData?.resourceCount}
        />
      </div>

      <CostChart data={dashboardData?.costHistory} />
      
      <RecommendationList recommendations={dashboardData?.topRecommendations} />
    </div>
  );
}
```
