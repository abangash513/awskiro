---
title: CloudOptima AI - Technical Design Document
version: 1.0.0
status: draft
created: 2026-02-13
---

# CloudOptima AI - Technical Design Document

## 1. Executive Summary

This document provides the technical architecture and design for CloudOptima AI, an AI-powered multi-cloud FinOps and Well-Architected Framework assessment platform.

## 2. System Architecture Overview

### 2.1 Architecture Principles

- **Microservices-ready monolith**: Start as modular monolith, split into microservices as needed
- **Cloud-native**: Designed for containerized deployment
- **API-first**: All functionality exposed via APIs
- **Event-driven**: Asynchronous processing for scalability
- **Multi-tenant**: Isolated data per organization
- **Stateless services**: Enable horizontal scaling

### 2.2 High-Level Component Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    Client Layer                          │
│  [Web App] [Mobile] [CLI] [VS Code] [API Clients]      │
└─────────────────────────────────────────────────────────┘
                         ↓ HTTPS/WSS
┌─────────────────────────────────────────────────────────┐
│                  API Gateway (FastAPI)                   │
│  • Authentication/Authorization                          │
│  • Rate Limiting                                         │
│  • Request Routing                                       │
│  • API Versioning                                        │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│                   Core Services                          │
├─────────────────────────────────────────────────────────┤
│  Discovery Service  │  Analysis Service                 │
│  AI Service         │  Policy Service                   │
│  Remediation Svc    │  Report Service                   │
│  Notification Svc   │  Integration Service              │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│                   Data Layer                             │
│  [PostgreSQL] [TimescaleDB] [Redis] [MongoDB] [S3]     │
└─────────────────────────────────────────────────────────┘
```

## 3. Detailed Component Design

### 3.1 API Gateway Layer

**Technology**: FastAPI with Uvicorn

**Responsibilities**:
- Request authentication and authorization
- Rate limiting and throttling
- API versioning (v1, v2, etc.)
- Request validation
- Response formatting
- CORS handling
- WebSocket connection management

**Key Endpoints**:
```python
# Authentication
POST   /api/v1/auth/login
POST   /api/v1/auth/refresh
POST   /api/v1/auth/logout

# Cloud Connections
POST   /api/v1/connections/azure
GET    /api/v1/connections
DELETE /api/v1/connections/{id}

# Discovery
POST   /api/v1/discovery/scan
GET    /api/v1/discovery/status/{scan_id}
GET    /api/v1/resources

# Analysis
POST   /api/v1/analysis/finops
GET    /api/v1/analysis/recommendations
GET    /api/v1/analysis/forecast

# AI Queries
POST   /api/v1/ai/query
GET    /api/v1/ai/conversations

# Reports
POST   /api/v1/reports/generate
GET    /api/v1/reports/{report_id}
```

### 3.2 Discovery Service

**Purpose**: Discover and inventory cloud resources

**Components**:

1. **Cloud Connectors**
   - Azure Connector (MVP)
   - AWS Connector (Phase 2)
   - GCP Connector (Phase 3)

2. **Resource Scanner**
   - Parallel resource discovery
   - Incremental updates
   - Change detection

3. **Resource Normalizer**
   - Unified resource model across clouds
   - Metadata extraction
   - Relationship mapping

**Azure Connector Design**:
```python
class AzureConnector:
    def __init__(self, credentials, subscription_id):
        self.credential = credentials
        self.subscription_id = subscription_id
        self.clients = self._initialize_clients()
    
    def discover_all_resources(self) -> List[Resource]:
        """Discover all resources in subscription"""
        
    def discover_by_type(self, resource_type: str) -> List[Resource]:
        """Discover specific resource type"""
        
    def get_resource_metrics(self, resource_id: str) -> Metrics:
        """Get performance metrics for resource"""
        
    def get_cost_data(self, timeframe: str) -> CostData:
        """Get cost data from Cost Management API"""
```

**Resource Types Supported (MVP)**:
- Virtual Machines
- Disks (Managed, Unmanaged)
- Storage Accounts
- SQL Databases
- App Services
- Load Balancers
- Public IP Addresses
- Virtual Networks
- Network Security Groups
- Key Vaults
- Container Instances
- Kubernetes Services (AKS)

### 3.3 Analysis Service

**Purpose**: Analyze resources and generate recommendations

**Sub-Components**:

1. **FinOps Analyzer**
   - Cost analysis engine
   - Waste detection
   - Right-sizing calculator
   - Savings estimator

2. **WAF Analyzers** (5 Pillars)
   - Cost Optimization (integrated with FinOps)
   - Reliability Analyzer
   - Security Analyzer
   - Performance Analyzer
   - Operational Excellence Analyzer

3. **Recommendation Engine**
   - Rule-based recommendations
   - ML-based recommendations
   - Priority scoring
   - Impact calculation

**FinOps Analysis Flow**:
```
1. Fetch resources from database
2. Fetch cost data from Cost Management API
3. Fetch metrics from Azure Monitor
4. Apply analysis rules
5. Calculate savings potential
6. Generate recommendations
7. Store results in database
```

**Recommendation Types**:

```python
class RecommendationType(Enum):
    # Compute
    IDLE_VM = "idle_vm"
    UNDERUTILIZED_VM = "underutilized_vm"
    VM_RIGHTSIZING = "vm_rightsizing"
    SPOT_INSTANCE_CANDIDATE = "spot_instance"
    RESERVED_INSTANCE = "reserved_instance"
    AUTO_SHUTDOWN = "auto_shutdown"
    
    # Storage
    UNATTACHED_DISK = "unattached_disk"
    STORAGE_TIER_OPTIMIZATION = "storage_tier"
    SNAPSHOT_CLEANUP = "snapshot_cleanup"
    
    # Network
    UNUSED_PUBLIC_IP = "unused_public_ip"
    IDLE_LOAD_BALANCER = "idle_load_balancer"
    
    # Database
    DATABASE_RIGHTSIZING = "database_rightsizing"
    SERVERLESS_CANDIDATE = "serverless_candidate"

class Recommendation:
    id: str
    type: RecommendationType
    resource_id: str
    title: str
    description: str
    impact: str  # High, Medium, Low
    effort: str  # Easy, Medium, Hard
    monthly_savings: float
    annual_savings: float
    risk_level: str
    remediation_steps: List[str]
    auto_remediable: bool
```

### 3.4 AI Service

**Purpose**: Provide AI-powered insights and natural language interface

**Components**:

1. **NLP Query Engine**
   - Parse natural language queries
   - Convert to database queries
   - Generate natural language responses

2. **Forecasting Engine**
   - Time-series forecasting
   - Anomaly detection
   - Trend analysis

3. **Recommendation Explainer**
   - Generate human-readable explanations
   - Provide context and reasoning

**NLP Query Processing**:
```python
class NLPQueryEngine:
    def __init__(self, llm_client):
        self.llm = llm_client
        self.query_history = []
    
    async def process_query(self, query: str, context: dict) -> QueryResult:
        # 1. Understand intent
        intent = await self._classify_intent(query)
        
        # 2. Extract entities (resources, time ranges, metrics)
        entities = await self._extract_entities(query)
        
        # 3. Generate database query
        db_query = self._generate_query(intent, entities)
        
        # 4. Execute query
        data = await self._execute_query(db_query)
        
        # 5. Generate natural language response
        response = await self._generate_response(query, data)
        
        return QueryResult(response=response, data=data)
```

**Forecasting Models**:
- Prophet (Facebook) for time-series
- ARIMA for seasonal patterns
- XGBoost for complex patterns
- Ensemble methods for accuracy

### 3.5 Policy Engine

**Purpose**: Define and enforce cloud governance policies

**Policy Structure**:
```yaml
policy:
  id: "pol-001"
  name: "Require tags on all VMs"
  version: "1.0"
  severity: "medium"
  category: "governance"
  
  scope:
    resource_types:
      - "Microsoft.Compute/virtualMachines"
    subscriptions:
      - "*"
  
  condition:
    required_tags:
      - "Environment"
      - "CostCenter"
      - "Owner"
  
  actions:
    on_violation:
      - type: "notify"
        channels: ["email", "slack"]
      - type: "create_ticket"
        system: "jira"
    
    remediation:
      auto_remediate: false
      approval_required: true
```

**Policy Evaluation Engine**:
```python
class PolicyEngine:
    def evaluate_resource(self, resource: Resource, policies: List[Policy]) -> List[Violation]:
        violations = []
        for policy in policies:
            if self._is_applicable(resource, policy):
                if not self._check_compliance(resource, policy):
                    violation = self._create_violation(resource, policy)
                    violations.append(violation)
        return violations
    
    def enforce_policy(self, violation: Violation):
        # Execute actions defined in policy
        for action in violation.policy.actions:
            self._execute_action(action, violation)
```

### 3.6 Remediation Service

**Purpose**: Automate fixing of issues

**Remediation Actions**:
```python
class RemediationAction:
    # VM Actions
    STOP_VM = "stop_vm"
    RESIZE_VM = "resize_vm"
    DELETE_VM = "delete_vm"
    
    # Disk Actions
    DELETE_DISK = "delete_disk"
    CHANGE_DISK_TIER = "change_disk_tier"
    
    # Storage Actions
    CHANGE_STORAGE_TIER = "change_storage_tier"
    DELETE_BLOB = "delete_blob"
    
    # Network Actions
    DELETE_PUBLIC_IP = "delete_public_ip"
    DELETE_LOAD_BALANCER = "delete_load_balancer"
    
    # Tagging
    ADD_TAGS = "add_tags"
```

**Remediation Workflow**:
```
1. User selects recommendation
2. System generates remediation plan
3. Dry-run simulation (optional)
4. Approval workflow (if required)
5. Execute remediation
6. Verify success
7. Create rollback point
8. Log action to audit trail
```

### 3.7 Report Service

**Purpose**: Generate reports and visualizations

**Report Types**:
- Executive Summary (PDF)
- Detailed Technical Report (PDF/HTML)
- Cost Analysis Report
- WAF Assessment Report
- Compliance Report
- Custom Reports

**Report Generation**:
```python
class ReportGenerator:
    def generate_executive_summary(self, org_id: str, timeframe: str) -> Report:
        # Aggregate data
        data = self._aggregate_data(org_id, timeframe)
        
        # Generate visualizations
        charts = self._generate_charts(data)
        
        # Render template
        html = self._render_template("executive_summary.html", data, charts)
        
        # Convert to PDF
        pdf = self._html_to_pdf(html)
        
        return Report(format="pdf", content=pdf)
```

## 4. Data Model Design

### 4.1 Core Entities

**Organization**
```python
class Organization:
    id: UUID
    name: str
    created_at: datetime
    settings: dict
    subscription_tier: str  # free, pro, business, enterprise
```

**User**
```python
class User:
    id: UUID
    email: str
    name: str
    organization_id: UUID
    role: str  # admin, member, viewer
    created_at: datetime
    last_login: datetime
```

**CloudConnection**
```python
class CloudConnection:
    id: UUID
    organization_id: UUID
    cloud_provider: str  # azure, aws, gcp
    connection_name: str
    credentials: dict  # encrypted
    subscription_id: str  # Azure
    account_id: str  # AWS
    project_id: str  # GCP
    status: str  # active, error, disconnected
    last_sync: datetime
    created_at: datetime
```

**Resource**
```python
class Resource:
    id: UUID
    organization_id: UUID
    connection_id: UUID
    cloud_provider: str
    resource_type: str
    resource_id: str  # Cloud provider's ID
    name: str
    region: str
    resource_group: str
    tags: dict
    properties: dict
    cost_monthly: float
    discovered_at: datetime
    last_updated: datetime
```

**ResourceMetrics** (TimescaleDB)
```python
class ResourceMetrics:
    time: datetime
    resource_id: UUID
    metric_name: str  # cpu_percent, memory_percent, etc.
    value: float
    unit: str
```

**CostData** (TimescaleDB)
```python
class CostData:
    time: datetime  # Daily granularity
    organization_id: UUID
    connection_id: UUID
    resource_id: UUID
    service_name: str
    cost: float
    currency: str
    tags: dict
```

**Recommendation**
```python
class Recommendation:
    id: UUID
    organization_id: UUID
    resource_id: UUID
    type: str
    title: str
    description: str
    impact: str  # high, medium, low
    effort: str  # easy, medium, hard
    monthly_savings: float
    annual_savings: float
    risk_level: str
    status: str  # open, in_progress, implemented, dismissed
    created_at: datetime
    updated_at: datetime
```

**Policy**
```python
class Policy:
    id: UUID
    organization_id: UUID
    name: str
    description: str
    policy_yaml: str
    enabled: bool
    created_at: datetime
    updated_at: datetime
```

**PolicyViolation**
```python
class PolicyViolation:
    id: UUID
    organization_id: UUID
    policy_id: UUID
    resource_id: UUID
    severity: str
    status: str  # open, resolved, ignored
    detected_at: datetime
    resolved_at: datetime
```

**RemediationAction**
```python
class RemediationAction:
    id: UUID
    recommendation_id: UUID
    action_type: str
    parameters: dict
    status: str  # pending, approved, executing, completed, failed, rolled_back
    executed_by: UUID
    executed_at: datetime
    result: dict
```

## 5. Database Schema (PostgreSQL + TimescaleDB)

### 5.1 Schema Diagram

```sql
-- Organizations and Users
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    subscription_tier VARCHAR(50) NOT NULL DEFAULT 'free',
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255),
    role VARCHAR(50) NOT NULL DEFAULT 'member',
    created_at TIMESTAMP DEFAULT NOW(),
    last_login TIMESTAMP
);

-- Cloud Connections
CREATE TABLE cloud_connections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    cloud_provider VARCHAR(50) NOT NULL,
    connection_name VARCHAR(255) NOT NULL,
    credentials_encrypted TEXT NOT NULL,
    subscription_id VARCHAR(255),
    account_id VARCHAR(255),
    project_id VARCHAR(255),
    status VARCHAR(50) DEFAULT 'active',
    last_sync TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(organization_id, connection_name)
);

-- Resources
CREATE TABLE resources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    connection_id UUID REFERENCES cloud_connections(id) ON DELETE CASCADE,
    cloud_provider VARCHAR(50) NOT NULL,
    resource_type VARCHAR(255) NOT NULL,
    resource_id VARCHAR(500) NOT NULL,
    name VARCHAR(500),
    region VARCHAR(100),
    resource_group VARCHAR(255),
    tags JSONB DEFAULT '{}',
    properties JSONB DEFAULT '{}',
    cost_monthly DECIMAL(12,2),
    discovered_at TIMESTAMP DEFAULT NOW(),
    last_updated TIMESTAMP DEFAULT NOW(),
    UNIQUE(organization_id, resource_id)
);

CREATE INDEX idx_resources_org ON resources(organization_id);
CREATE INDEX idx_resources_type ON resources(resource_type);
CREATE INDEX idx_resources_tags ON resources USING GIN(tags);
```

-- Time-series data (TimescaleDB hypertables)
CREATE TABLE resource_metrics (
    time TIMESTAMPTZ NOT NULL,
    resource_id UUID NOT NULL,
    metric_name VARCHAR(100) NOT NULL,
    value DOUBLE PRECISION NOT NULL,
    unit VARCHAR(50),
    FOREIGN KEY (resource_id) REFERENCES resources(id) ON DELETE CASCADE
);

SELECT create_hypertable('resource_metrics', 'time');
CREATE INDEX idx_metrics_resource ON resource_metrics(resource_id, time DESC);

CREATE TABLE cost_data (
    time TIMESTAMPTZ NOT NULL,
    organization_id UUID NOT NULL,
    connection_id UUID NOT NULL,
    resource_id UUID,
    service_name VARCHAR(255),
    cost DECIMAL(12,4) NOT NULL,
    currency VARCHAR(10) DEFAULT 'USD',
    tags JSONB DEFAULT '{}',
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE
);

SELECT create_hypertable('cost_data', 'time');
CREATE INDEX idx_cost_org_time ON cost_data(organization_id, time DESC);
CREATE INDEX idx_cost_resource ON cost_data(resource_id, time DESC);

-- Recommendations
CREATE TABLE recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    resource_id UUID REFERENCES resources(id) ON DELETE CASCADE,
    type VARCHAR(100) NOT NULL,
    title VARCHAR(500) NOT NULL,
    description TEXT,
    impact VARCHAR(20) NOT NULL,
    effort VARCHAR(20) NOT NULL,
    monthly_savings DECIMAL(12,2),
    annual_savings DECIMAL(12,2),
    risk_level VARCHAR(20),
    status VARCHAR(50) DEFAULT 'open',
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_recommendations_org ON recommendations(organization_id);
CREATE INDEX idx_recommendations_status ON recommendations(status);
CREATE INDEX idx_recommendations_savings ON recommendations(annual_savings DESC);
```

-- Policies
CREATE TABLE policies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    policy_yaml TEXT NOT NULL,
    enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE policy_violations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    policy_id UUID REFERENCES policies(id) ON DELETE CASCADE,
    resource_id UUID REFERENCES resources(id) ON DELETE CASCADE,
    severity VARCHAR(20) NOT NULL,
    status VARCHAR(50) DEFAULT 'open',
    details JSONB DEFAULT '{}',
    detected_at TIMESTAMP DEFAULT NOW(),
    resolved_at TIMESTAMP
);

-- Remediation
CREATE TABLE remediation_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recommendation_id UUID REFERENCES recommendations(id) ON DELETE CASCADE,
    action_type VARCHAR(100) NOT NULL,
    parameters JSONB DEFAULT '{}',
    status VARCHAR(50) DEFAULT 'pending',
    executed_by UUID REFERENCES users(id),
    executed_at TIMESTAMP,
    result JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW()
);

-- Audit Trail
CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100),
    resource_id VARCHAR(500),
    details JSONB DEFAULT '{}',
    ip_address INET,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_audit_org_time ON audit_log(organization_id, created_at DESC);
```

-- AI Conversations
CREATE TABLE ai_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(500),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE ai_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES ai_conversations(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL,  -- user, assistant
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW()
);

-- Reports
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    report_type VARCHAR(100) NOT NULL,
    title VARCHAR(500) NOT NULL,
    format VARCHAR(20) NOT NULL,  -- pdf, html, excel
    file_path VARCHAR(1000),
    parameters JSONB DEFAULT '{}',
    generated_by UUID REFERENCES users(id),
    generated_at TIMESTAMP DEFAULT NOW()
);
```

### 5.2 Data Retention Policies

```sql
-- Retention policies for time-series data
SELECT add_retention_policy('resource_metrics', INTERVAL '90 days');
SELECT add_retention_policy('cost_data', INTERVAL '13 months');

-- Continuous aggregates for performance
CREATE MATERIALIZED VIEW daily_cost_summary
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 day', time) AS day,
    organization_id,
    service_name,
    SUM(cost) as total_cost,
    COUNT(*) as resource_count
FROM cost_data
GROUP BY day, organization_id, service_name;

SELECT add_continuous_aggregate_policy('daily_cost_summary',
    start_offset => INTERVAL '3 days',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour');
```

## 6. API Design

### 6.1 RESTful API Endpoints

**Authentication**
```
POST   /api/v1/auth/register
POST   /api/v1/auth/login
POST   /api/v1/auth/refresh
POST   /api/v1/auth/logout
GET    /api/v1/auth/me
```

**Cloud Connections**
```
POST   /api/v1/connections              # Create connection
GET    /api/v1/connections              # List connections
GET    /api/v1/connections/{id}         # Get connection
PUT    /api/v1/connections/{id}         # Update connection
DELETE /api/v1/connections/{id}         # Delete connection
POST   /api/v1/connections/{id}/test    # Test connection
POST   /api/v1/connections/{id}/sync    # Trigger sync
```

**Resources**
```
GET    /api/v1/resources                # List resources
GET    /api/v1/resources/{id}           # Get resource details
GET    /api/v1/resources/{id}/metrics   # Get resource metrics
GET    /api/v1/resources/{id}/costs     # Get resource costs
GET    /api/v1/resources/search         # Search resources
```

**Analysis**
```
POST   /api/v1/analysis/scan            # Trigger full analysis
GET    /api/v1/analysis/status/{id}     # Get analysis status
GET    /api/v1/recommendations          # List recommendations
GET    /api/v1/recommendations/{id}     # Get recommendation
PUT    /api/v1/recommendations/{id}     # Update status
DELETE /api/v1/recommendations/{id}     # Dismiss recommendation
```

**Forecasting**
```
GET    /api/v1/forecast/cost            # Cost forecast
GET    /api/v1/forecast/usage           # Usage forecast
POST   /api/v1/forecast/custom          # Custom forecast
```

**AI Queries**
```
POST   /api/v1/ai/query                 # Ask question
GET    /api/v1/ai/conversations         # List conversations
GET    /api/v1/ai/conversations/{id}    # Get conversation
DELETE /api/v1/ai/conversations/{id}    # Delete conversation
```

**Policies**
```
GET    /api/v1/policies                 # List policies
POST   /api/v1/policies                 # Create policy
GET    /api/v1/policies/{id}            # Get policy
PUT    /api/v1/policies/{id}            # Update policy
DELETE /api/v1/policies/{id}            # Delete policy
GET    /api/v1/policies/violations      # List violations
```

**Remediation**
```
POST   /api/v1/remediation/execute      # Execute remediation
POST   /api/v1/remediation/simulate     # Dry-run simulation
GET    /api/v1/remediation/actions      # List actions
GET    /api/v1/remediation/actions/{id} # Get action status
POST   /api/v1/remediation/rollback     # Rollback action
```

**Reports**
```
POST   /api/v1/reports/generate         # Generate report
GET    /api/v1/reports                  # List reports
GET    /api/v1/reports/{id}             # Get report
GET    /api/v1/reports/{id}/download    # Download report
DELETE /api/v1/reports/{id}             # Delete report
```

**Dashboards**
```
GET    /api/v1/dashboards/executive     # Executive dashboard data
GET    /api/v1/dashboards/finops        # FinOps dashboard data
GET    /api/v1/dashboards/waf           # WAF dashboard data
GET    /api/v1/dashboards/custom/{id}   # Custom dashboard
```

### 6.2 WebSocket API

**Real-time Updates**
```
WS     /ws/v1/updates                   # Subscribe to updates

# Message format
{
    "type": "resource_discovered",
    "data": { ... }
}

{
    "type": "recommendation_created",
    "data": { ... }
}

{
    "type": "cost_alert",
    "data": { ... }
}
```

### 6.3 GraphQL API (Optional - Phase 2)

```graphql
type Query {
  resources(filter: ResourceFilter): [Resource!]!
  recommendations(status: String): [Recommendation!]!
  costForecast(days: Int!): CostForecast!
}

type Mutation {
  createConnection(input: ConnectionInput!): Connection!
  executeRemediation(id: ID!): RemediationResult!
}

type Subscription {
  resourceUpdates: Resource!
  costAlerts: CostAlert!
}
```

## 7. Security Design

### 7.1 Authentication

**JWT-based Authentication**
```python
# Token structure
{
    "sub": "user_id",
    "org_id": "organization_id",
    "role": "admin",
    "exp": 1234567890,
    "iat": 1234567890
}

# Token types
- Access Token: 15 minutes expiry
- Refresh Token: 7 days expiry
```

**Supported Auth Methods**:
- Email/Password
- OAuth 2.0 (Google, Microsoft)
- SAML 2.0 (Enterprise)
- API Keys (for programmatic access)

### 7.2 Authorization

**Role-Based Access Control (RBAC)**
```python
class Role(Enum):
    ADMIN = "admin"          # Full access
    MEMBER = "member"        # Read/write access
    VIEWER = "viewer"        # Read-only access
    AUDITOR = "auditor"      # Audit logs only

# Permission matrix
PERMISSIONS = {
    "admin": ["*"],
    "member": [
        "resources:read",
        "recommendations:read",
        "recommendations:update",
        "reports:create",
        "policies:read"
    ],
    "viewer": [
        "resources:read",
        "recommendations:read",
        "reports:read"
    ],
    "auditor": [
        "audit:read"
    ]
}
```

### 7.3 Data Encryption

**At Rest**:
- Database: Transparent Data Encryption (TDE)
- Cloud credentials: AES-256 encryption
- Secrets: Azure Key Vault / AWS Secrets Manager

**In Transit**:
- TLS 1.3 for all API communication
- Certificate pinning for mobile apps

### 7.4 Secrets Management

```python
class SecretsManager:
    def encrypt_credentials(self, credentials: dict) -> str:
        # Use Fernet (symmetric encryption)
        key = self._get_encryption_key()
        f = Fernet(key)
        return f.encrypt(json.dumps(credentials).encode())
    
    def decrypt_credentials(self, encrypted: str) -> dict:
        key = self._get_encryption_key()
        f = Fernet(key)
        return json.loads(f.decrypt(encrypted.encode()))
```

## 8. Scalability & Performance

### 8.1 Caching Strategy

**Redis Cache Layers**:
```python
# L1: API Response Cache (5 minutes)
@cache(ttl=300)
def get_resources(org_id: str):
    pass

# L2: Computed Results Cache (1 hour)
@cache(ttl=3600)
def get_recommendations(org_id: str):
    pass

# L3: Static Data Cache (24 hours)
@cache(ttl=86400)
def get_azure_pricing():
    pass
```

**Cache Invalidation**:
- Event-driven invalidation on resource changes
- TTL-based expiration
- Manual invalidation via admin API

### 8.2 Database Optimization

**Indexing Strategy**:
```sql
-- Composite indexes for common queries
CREATE INDEX idx_resources_org_type ON resources(organization_id, resource_type);
CREATE INDEX idx_recommendations_org_status ON recommendations(organization_id, status);

-- Partial indexes for active data
CREATE INDEX idx_active_recommendations ON recommendations(organization_id) 
WHERE status IN ('open', 'in_progress');

-- GIN indexes for JSONB
CREATE INDEX idx_resources_tags_gin ON resources USING GIN(tags);
```

**Query Optimization**:
- Use prepared statements
- Batch inserts for bulk operations
- Connection pooling (PgBouncer)
- Read replicas for reporting queries

### 8.3 Async Processing

**Celery Task Queue**:
```python
# Background tasks
@celery.task
def discover_resources(connection_id: str):
    # Long-running discovery task
    pass

@celery.task
def generate_report(report_id: str):
    # Report generation
    pass

@celery.task
def send_notifications(alert_id: str):
    # Send alerts
    pass
```

**Task Priorities**:
- High: User-initiated actions
- Medium: Scheduled scans
- Low: Report generation

### 8.4 Horizontal Scaling

**Stateless Services**:
- API servers: Scale based on CPU/memory
- Worker nodes: Scale based on queue depth
- Load balancer: Distribute traffic

**Database Scaling**:
- Read replicas for read-heavy workloads
- Partitioning by organization_id
- TimescaleDB automatic chunking

## 9. Monitoring & Observability

### 9.1 Logging

**Structured Logging**:
```python
import structlog

logger = structlog.get_logger()

logger.info(
    "resource_discovered",
    resource_id=resource.id,
    resource_type=resource.type,
    organization_id=org_id,
    duration_ms=duration
)
```

**Log Levels**:
- ERROR: System errors, exceptions
- WARNING: Degraded performance, retries
- INFO: Business events, API calls
- DEBUG: Detailed debugging info

### 9.2 Metrics

**Key Metrics to Track**:
```python
# Application metrics
- api_request_duration_seconds
- api_request_total
- discovery_duration_seconds
- recommendations_generated_total
- cost_savings_identified_total

# Business metrics
- active_organizations
- resources_discovered_total
- recommendations_implemented_total
- monthly_savings_realized

# Infrastructure metrics
- cpu_usage_percent
- memory_usage_percent
- database_connections
- cache_hit_rate
- queue_depth
```

### 9.3 Distributed Tracing

**OpenTelemetry Integration**:
```python
from opentelemetry import trace

tracer = trace.get_tracer(__name__)

@tracer.start_as_current_span("discover_resources")
def discover_resources(connection_id: str):
    with tracer.start_as_current_span("fetch_vms"):
        vms = azure_client.get_vms()
    
    with tracer.start_as_current_span("save_to_db"):
        db.save(vms)
```

### 9.4 Health Checks

```python
@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "timestamp": datetime.now(),
        "version": "1.0.0"
    }

@app.get("/health/ready")
def readiness_check():
    # Check dependencies
    db_healthy = check_database()
    redis_healthy = check_redis()
    
    if db_healthy and redis_healthy:
        return {"status": "ready"}
    else:
        raise HTTPException(status_code=503)
```

## 10. Deployment Architecture

### 10.1 Container Architecture

**Docker Compose (Development)**:
```yaml
version: '3.8'

services:
  api:
    build: ./backend
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/cloudoptima
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis

  worker:
    build: ./backend
    command: celery -A app.celery worker
    depends_on:
      - db
      - redis

  db:
    image: timescale/timescaledb:latest-pg15
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=cloudoptima
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    depends_on:
      - api
```

### 10.2 Kubernetes Deployment (Production)

**Architecture**:
```
┌─────────────────────────────────────────┐
│         Ingress Controller              │
│         (NGINX/Traefik)                 │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│         API Service (3 replicas)        │
│         [Pod: FastAPI + Gunicorn]       │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│      Worker Service (5 replicas)        │
│      [Pod: Celery Worker]               │
└─────────────────────────────────────────┘
                  ↓
┌──────────────┬──────────────┬───────────┐
│  PostgreSQL  │    Redis     │  MongoDB  │
│  (StatefulSet)│ (StatefulSet)│(StatefulSet)│
└──────────────┴──────────────┴───────────┘
```

**Kubernetes Manifests**:
```yaml
# api-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloudoptima-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: cloudoptima-api
  template:
    metadata:
      labels:
        app: cloudoptima-api
    spec:
      containers:
      - name: api
        image: cloudoptima/api:latest
        ports:
        - containerPort: 8000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: url
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8000
          initialDelaySeconds: 10
          periodSeconds: 5
```

### 10.3 Infrastructure as Code (Terraform)

```hcl
# main.tf
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = "cloudoptima-aks"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "cloudoptima"

  default_node_pool {
    name       = "default"
    node_count = 3
    vm_size    = "Standard_D4s_v3"
  }

  identity {
    type = "SystemAssigned"
  }
}

# PostgreSQL Flexible Server
resource "azurerm_postgresql_flexible_server" "main" {
  name                = "cloudoptima-db"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  version             = "15"
  
  storage_mb = 32768
  sku_name   = "GP_Standard_D4s_v3"
}

# Redis Cache
resource "azurerm_redis_cache" "main" {
  name                = "cloudoptima-redis"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  capacity            = 2
  family              = "C"
  sku_name            = "Standard"
}
```

## 11. AI/ML Model Design

### 11.1 Cost Forecasting Model

**Model Architecture**:
```python
class CostForecaster:
    def __init__(self):
        self.prophet_model = Prophet(
            yearly_seasonality=True,
            weekly_seasonality=True,
            daily_seasonality=False
        )
        self.xgboost_model = XGBRegressor()
    
    def train(self, historical_data: pd.DataFrame):
        # Prepare data
        df = self._prepare_data(historical_data)
        
        # Train Prophet for trend and seasonality
        self.prophet_model.fit(df)
        
        # Train XGBoost for residuals
        prophet_pred = self.prophet_model.predict(df)
        residuals = df['y'] - prophet_pred['yhat']
        
        features = self._extract_features(df)
        self.xgboost_model.fit(features, residuals)
    
    def forecast(self, days: int) -> pd.DataFrame:
        # Prophet forecast
        future = self.prophet_model.make_future_dataframe(periods=days)
        prophet_forecast = self.prophet_model.predict(future)
        
        # XGBoost adjustment
        features = self._extract_features(future)
        xgb_adjustment = self.xgboost_model.predict(features)
        
        # Combine predictions
        final_forecast = prophet_forecast['yhat'] + xgb_adjustment
        
        return pd.DataFrame({
            'date': future['ds'],
            'forecast': final_forecast,
            'lower_bound': prophet_forecast['yhat_lower'],
            'upper_bound': prophet_forecast['yhat_upper']
        })
```

### 11.2 Anomaly Detection Model

**Isolation Forest + Statistical Methods**:
```python
class AnomalyDetector:
    def __init__(self):
        self.isolation_forest = IsolationForest(
            contamination=0.1,
            random_state=42
        )
        self.scaler = StandardScaler()
    
    def detect_anomalies(self, cost_data: pd.DataFrame) -> List[Anomaly]:
        # Feature engineering
        features = self._create_features(cost_data)
        features_scaled = self.scaler.fit_transform(features)
        
        # ML-based detection
        ml_anomalies = self.isolation_forest.fit_predict(features_scaled)
        
        # Statistical detection (Z-score)
        z_scores = np.abs(stats.zscore(cost_data['cost']))
        stat_anomalies = z_scores > 3
        
        # Combine results
        anomalies = []
        for idx, (ml_anom, stat_anom) in enumerate(zip(ml_anomalies, stat_anomalies)):
            if ml_anom == -1 or stat_anom:
                anomaly = Anomaly(
                    date=cost_data.iloc[idx]['date'],
                    actual_cost=cost_data.iloc[idx]['cost'],
                    expected_cost=self._calculate_expected(cost_data, idx),
                    severity=self._calculate_severity(ml_anom, stat_anom),
                    confidence=self._calculate_confidence(ml_anom, stat_anom)
                )
                anomalies.append(anomaly)
        
        return anomalies
```

### 11.3 NLP Query Understanding

**LangChain Integration**:
```python
from langchain.chat_models import ChatOpenAI
from langchain.prompts import ChatPromptTemplate
from langchain.output_parsers import PydanticOutputParser

class NLPQueryEngine:
    def __init__(self, openai_api_key: str):
        self.llm = ChatOpenAI(
            model="gpt-4",
            temperature=0,
            api_key=openai_api_key
        )
        self.parser = PydanticOutputParser(pydantic_object=QueryIntent)
    
    async def parse_query(self, query: str, context: dict) -> QueryIntent:
        prompt = ChatPromptTemplate.from_messages([
            ("system", """You are a cloud cost optimization assistant.
            Parse the user's query and extract:
            - Intent (cost_analysis, resource_search, recommendation, forecast)
            - Entities (resource types, time ranges, metrics)
            - Filters (tags, regions, resource groups)
            
            Context: {context}
            """),
            ("user", "{query}")
        ])
        
        chain = prompt | self.llm | self.parser
        result = await chain.ainvoke({
            "query": query,
            "context": json.dumps(context)
        })
        
        return result
    
    async def generate_response(self, query: str, data: dict) -> str:
        prompt = ChatPromptTemplate.from_messages([
            ("system", """You are a cloud cost optimization assistant.
            Generate a natural language response based on the data.
            Be concise, actionable, and include specific numbers.
            """),
            ("user", "Query: {query}\n\nData: {data}")
        ])
        
        chain = prompt | self.llm
        response = await chain.ainvoke({
            "query": query,
            "data": json.dumps(data)
        })
        
        return response.content
```

## 12. Frontend Design

### 12.1 Technology Stack

- **Framework**: React 18 with TypeScript
- **State Management**: Zustand
- **UI Components**: shadcn/ui + Radix UI
- **Styling**: TailwindCSS
- **Charts**: Recharts + D3.js
- **Forms**: React Hook Form + Zod
- **API Client**: TanStack Query (React Query)
- **Routing**: React Router v6

### 12.2 Component Architecture

```
src/
├── components/
│   ├── ui/                    # shadcn/ui components
│   ├── layout/
│   │   ├── Header.tsx
│   │   ├── Sidebar.tsx
│   │   └── Layout.tsx
│   ├── dashboard/
│   │   ├── CostChart.tsx
│   │   ├── SavingsCard.tsx
│   │   └── RecommendationList.tsx
│   ├── resources/
│   │   ├── ResourceTable.tsx
│   │   └── ResourceDetails.tsx
│   └── ai/
│       ├── ChatInterface.tsx
│       └── QueryInput.tsx
├── pages/
│   ├── Dashboard.tsx
│   ├── Resources.tsx
│   ├── Recommendations.tsx
│   ├── Reports.tsx
│   └── Settings.tsx
├── hooks/
│   ├── useResources.ts
│   ├── useRecommendations.ts
│   └── useCostData.ts
├── stores/
│   ├── authStore.ts
│   └── uiStore.ts
├── services/
│   └── api.ts
└── utils/
    ├── formatters.ts
    └── validators.ts
```

### 12.3 Key UI Components

**Dashboard Component**:
```typescript
export function Dashboard() {
  const { data: costData } = useCostData({ days: 30 });
  const { data: recommendations } = useRecommendations();
  const { data: forecast } = useForecast({ days: 90 });

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <MetricCard
          title="Monthly Cost"
          value={costData?.currentMonth}
          change={costData?.percentChange}
        />
        <MetricCard
          title="Potential Savings"
          value={recommendations?.totalSavings}
          trend="up"
        />
        <MetricCard
          title="Resources"
          value={costData?.resourceCount}
        />
      </div>

      <CostTrendChart data={costData?.history} forecast={forecast} />
      
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <TopCostResources data={costData?.topResources} />
        <RecommendationList recommendations={recommendations?.items} />
      </div>
    </div>
  );
}
```

**AI Chat Interface**:
```typescript
export function AIChatInterface() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const { mutate: sendQuery, isLoading } = useMutation(api.ai.query);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    const userMessage = { role: 'user', content: input };
    setMessages(prev => [...prev, userMessage]);
    setInput('');

    sendQuery({ query: input }, {
      onSuccess: (response) => {
        const aiMessage = { role: 'assistant', content: response.answer };
        setMessages(prev => [...prev, aiMessage]);
      }
    });
  };

  return (
    <div className="flex flex-col h-full">
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((msg, idx) => (
          <ChatMessage key={idx} message={msg} />
        ))}
        {isLoading && <LoadingIndicator />}
      </div>
      
      <form onSubmit={handleSubmit} className="p-4 border-t">
        <div className="flex gap-2">
          <Input
            value={input}
            onChange={(e) => setInput(e.target.value)}
            placeholder="Ask about your cloud costs..."
            disabled={isLoading}
          />
          <Button type="submit" disabled={isLoading}>
            Send
          </Button>
        </div>
      </form>
    </div>
  );
}
```

## 13. Testing Strategy

### 13.1 Backend Testing

**Unit Tests (pytest)**:
```python
# tests/test_analyzers.py
def test_idle_vm_detection():
    analyzer = FinOpsAnalyzer()
    
    # Mock resource with low CPU
    resource = Resource(
        id="vm-123",
        type="Microsoft.Compute/virtualMachines",
        metrics=[
            Metric(name="cpu_percent", value=2.0, timestamp=now())
            for _ in range(168)  # 7 days
        ]
    )
    
    recommendations = analyzer.analyze_compute([resource])
    
    assert len(recommendations) == 1
    assert recommendations[0].type == RecommendationType.IDLE_VM
    assert recommendations[0].monthly_savings > 0
```

**Integration Tests**:
```python
# tests/test_api.py
@pytest.mark.asyncio
async def test_create_connection(client, auth_headers):
    response = await client.post(
        "/api/v1/connections",
        json={
            "cloud_provider": "azure",
            "connection_name": "Test Connection",
            "credentials": {...}
        },
        headers=auth_headers
    )
    
    assert response.status_code == 201
    data = response.json()
    assert data["cloud_provider"] == "azure"
```

### 13.2 Frontend Testing

**Component Tests (Vitest + React Testing Library)**:
```typescript
// tests/Dashboard.test.tsx
describe('Dashboard', () => {
  it('displays cost metrics', async () => {
    const mockData = {
      currentMonth: 5000,
      percentChange: 15,
      resourceCount: 150
    };
    
    server.use(
      rest.get('/api/v1/dashboards/finops', (req, res, ctx) => {
        return res(ctx.json(mockData));
      })
    );

    render(<Dashboard />);
    
    await waitFor(() => {
      expect(screen.getByText('$5,000')).toBeInTheDocument();
      expect(screen.getByText('150')).toBeInTheDocument();
    });
  });
});
```

**E2E Tests (Playwright)**:
```typescript
// e2e/cost-analysis.spec.ts
test('user can view cost analysis', async ({ page }) => {
  await page.goto('/login');
  await page.fill('[name="email"]', 'test@example.com');
  await page.fill('[name="password"]', 'password');
  await page.click('button[type="submit"]');
  
  await page.waitForURL('/dashboard');
  
  await expect(page.locator('h1')).toContainText('Dashboard');
  await expect(page.locator('[data-testid="cost-chart"]')).toBeVisible();
});
```

### 13.3 Load Testing

**Locust Configuration**:
```python
# locustfile.py
from locust import HttpUser, task, between

class CloudOptimaUser(HttpUser):
    wait_time = between(1, 3)
    
    def on_start(self):
        # Login
        response = self.client.post("/api/v1/auth/login", json={
            "email": "test@example.com",
            "password": "password"
        })
        self.token = response.json()["access_token"]
        self.headers = {"Authorization": f"Bearer {self.token}"}
    
    @task(3)
    def view_dashboard(self):
        self.client.get("/api/v1/dashboards/finops", headers=self.headers)
    
    @task(2)
    def list_resources(self):
        self.client.get("/api/v1/resources", headers=self.headers)
    
    @task(1)
    def get_recommendations(self):
        self.client.get("/api/v1/recommendations", headers=self.headers)
```

## 14. CI/CD Pipeline

### 14.1 GitHub Actions Workflow

```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.12'
      
      - name: Install dependencies
        run: |
          pip install -r requirements.txt
          pip install -r requirements-dev.txt
      
      - name: Run tests
        run: pytest --cov=app tests/
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3

  test-frontend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run tests
        run: npm test
      
      - name: Build
        run: npm run build

  deploy:
    needs: [test-backend, test-frontend]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to production
        run: |
          # Deploy logic here
```

## 15. Error Handling & Resilience

### 15.1 Error Handling Strategy

**API Error Responses**:
```python
class APIError(Exception):
    def __init__(self, status_code: int, message: str, details: dict = None):
        self.status_code = status_code
        self.message = message
        self.details = details or {}

@app.exception_handler(APIError)
async def api_error_handler(request: Request, exc: APIError):
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": {
                "message": exc.message,
                "details": exc.details,
                "timestamp": datetime.now().isoformat(),
                "path": str(request.url)
            }
        }
    )
```

### 15.2 Retry Logic

**Exponential Backoff**:
```python
from tenacity import retry, stop_after_attempt, wait_exponential

@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=4, max=10)
)
async def fetch_azure_resources(client):
    try:
        return await client.get_resources()
    except AzureError as e:
        logger.warning(f"Azure API error: {e}, retrying...")
        raise
```

### 15.3 Circuit Breaker

```python
from circuitbreaker import circuit

@circuit(failure_threshold=5, recovery_timeout=60)
async def call_external_api(url: str):
    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        response.raise_for_status()
        return response.json()
```

## 16. Documentation

### 16.1 API Documentation (OpenAPI/Swagger)

```python
from fastapi import FastAPI
from fastapi.openapi.utils import get_openapi

app = FastAPI(
    title="CloudOptima AI API",
    description="AI-powered cloud optimization platform",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema
    
    openapi_schema = get_openapi(
        title="CloudOptima AI API",
        version="1.0.0",
        description="Complete API documentation",
        routes=app.routes,
    )
    
    app.openapi_schema = openapi_schema
    return app.openapi_schema

app.openapi = custom_openapi
```

### 16.2 Code Documentation

**Docstring Standards**:
```python
def analyze_vm_utilization(
    resource: Resource,
    metrics: List[Metric],
    threshold: float = 5.0
) -> Optional[Recommendation]:
    """
    Analyze VM utilization and generate recommendations.
    
    Args:
        resource: The VM resource to analyze
        metrics: List of CPU/memory metrics for the VM
        threshold: CPU utilization threshold for idle detection (default: 5%)
    
    Returns:
        Recommendation object if VM is underutilized, None otherwise
    
    Raises:
        ValueError: If metrics list is empty
        
    Example:
        >>> resource = Resource(id="vm-123", type="VM")
        >>> metrics = [Metric(name="cpu", value=2.0)]
        >>> rec = analyze_vm_utilization(resource, metrics)
        >>> print(rec.monthly_savings)
        450.00
    """
    pass
```

## 17. Correctness Properties

### Property 1: Cost Data Consistency
**Description**: Total cost across all resources must equal the sum from Cost Management API

**Test**:
```python
def test_cost_consistency(org_id: str, date: datetime):
    # Get cost from our database
    db_total = db.query(CostData).filter(
        CostData.organization_id == org_id,
        CostData.time == date
    ).sum(CostData.cost)
    
    # Get cost from Azure API
    azure_total = azure_client.get_total_cost(date)
    
    # Allow 1% variance for rounding
    assert abs(db_total - azure_total) / azure_total < 0.01
```

### Property 2: Recommendation Savings Accuracy
**Description**: Calculated savings must be based on actual resource costs

**Test**:
```python
def test_savings_calculation(recommendation: Recommendation):
    resource = db.get_resource(recommendation.resource_id)
    
    # Verify savings calculation
    if recommendation.type == RecommendationType.IDLE_VM:
        expected_savings = resource.cost_monthly
        assert recommendation.monthly_savings == expected_savings
```

### Property 3: No Duplicate Recommendations
**Description**: System should not generate duplicate recommendations for the same resource

**Test**:
```python
def test_no_duplicate_recommendations(org_id: str):
    recommendations = db.query(Recommendation).filter(
        Recommendation.organization_id == org_id,
        Recommendation.status == 'open'
    ).all()
    
    # Check for duplicates
    seen = set()
    for rec in recommendations:
        key = (rec.resource_id, rec.type)
        assert key not in seen, f"Duplicate recommendation: {key}"
        seen.add(key)
```

---

**Document Version**: 1.0.0  
**Last Updated**: 2026-02-13  
**Next Review**: 2026-03-13
