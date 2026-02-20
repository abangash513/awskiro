# CloudOptima AI - Demo Guide

## 🎯 Quick Demo Overview

This guide will walk you through testing the CloudOptima AI application deployed on Azure.

**Application URLs:**
- Frontend: http://52.179.209.239:3000
- Backend API: http://52.179.209.239:8000
- API Docs: http://52.179.209.239:8000/docs

---

## 📋 Demo Steps

### Step 1: Test the Frontend

1. Open your web browser
2. Navigate to: **http://52.179.209.239:3000**
3. You should see the CloudOptima AI React application
4. The page should load without errors

**Expected Result:** React application loads successfully

---

### Step 2: Test Backend Health

Open a new browser tab or use curl/PowerShell:

**Browser:**
- Navigate to: **http://52.179.209.239:8000/health**

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://52.179.209.239:8000/health"
```

**Expected Response:**
```json
{
  "status": "healthy",
  "service": "cloudoptima-ai-poc",
  "version": "0.1.0-poc"
}
```

---

### Step 3: Explore API Documentation

1. Navigate to: **http://52.179.209.239:8000/docs**
2. You'll see the interactive Swagger UI
3. Browse available endpoints:
   - Health endpoints
   - Cost endpoints
   - Recommendation endpoints

**Try it out:**
- Click on any endpoint (e.g., `GET /api/v1/costs/summary`)
- Click "Try it out"
- Click "Execute"
- See the response below

---

### Step 4: Test Cost Endpoints

#### 4.1 Get Cost Summary

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://52.179.209.239:8000/api/v1/costs/summary"
```

**Browser:**
- http://52.179.209.239:8000/api/v1/costs/summary

**Expected Response:**
```json
{
  "total_cost": 0,
  "currency": "USD",
  "period_start": "2026-01-17",
  "period_end": "2026-02-16",
  "top_services": []
}
```

#### 4.2 Get Cost Trend

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://52.179.209.239:8000/api/v1/costs/trend"
```

**Expected Response:** Empty array (no data yet)
```json
[]
```

#### 4.3 Get Cost by Service

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://52.179.209.239:8000/api/v1/costs/by-service"
```

---

### Step 5: Test Recommendation Endpoints

#### 5.1 Get Recommendations Summary

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://52.179.209.239:8000/api/v1/recommendations/summary"
```

**Browser:**
- http://52.179.209.239:8000/api/v1/recommendations/summary

**Expected Response:**
```json
{
  "total_recommendations": 0,
  "by_status": {},
  "potential_monthly_savings": 0.0,
  "potential_annual_savings": 0.0,
  "by_category": []
}
```

#### 5.2 List All Recommendations

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://52.179.209.239:8000/api/v1/recommendations/"
```

**Expected Response:** Empty array
```json
[]
```

#### 5.3 List Recommendation Categories

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://52.179.209.239:8000/api/v1/recommendations/categories/list"
```

**Expected Response:**
```json
{
  "categories": [
    {"value": "rightsizing", "name": "Rightsizing"},
    {"value": "reserved_instances", "name": "Reserved Instances"},
    {"value": "savings_plans", "name": "Savings Plans"},
    ...
  ]
}
```

---

### Step 6: Add Sample Data (Optional)

To make the demo more interesting, you can add sample data to the database.

#### 6.1 Connect to the VM

**PowerShell (using WSL):**
```powershell
wsl ssh azureuser@52.179.209.239
# Password: zJsjfxP80cmn!WeU
```

#### 6.2 Access PostgreSQL

```bash
cd /opt/cloudoptima
docker-compose exec db psql -U cloudoptima -d cloudoptima
```

#### 6.3 Insert Sample Cost Data

```sql
-- Insert sample cost records
INSERT INTO cost_records (
    subscription_id, resource_group, resource_name, service_name,
    cost, currency, usage_date, created_at, updated_at
) VALUES
    ('sub-001', 'production-rg', 'web-vm-01', 'Virtual Machines', 150.50, 'USD', '2026-02-15', NOW(), NOW()),
    ('sub-001', 'production-rg', 'db-sql-01', 'SQL Database', 320.75, 'USD', '2026-02-15', NOW(), NOW()),
    ('sub-001', 'production-rg', 'storage-01', 'Storage', 45.20, 'USD', '2026-02-15', NOW(), NOW()),
    ('sub-001', 'development-rg', 'dev-vm-01', 'Virtual Machines', 85.30, 'USD', '2026-02-15', NOW(), NOW()),
    ('sub-001', 'production-rg', 'web-vm-01', 'Virtual Machines', 148.20, 'USD', '2026-02-14', NOW(), NOW()),
    ('sub-001', 'production-rg', 'db-sql-01', 'SQL Database', 318.50, 'USD', '2026-02-14', NOW(), NOW());

-- Verify data
SELECT service_name, SUM(cost) as total_cost 
FROM cost_records 
GROUP BY service_name 
ORDER BY total_cost DESC;
```

#### 6.4 Insert Sample Recommendations

```sql
-- Insert sample recommendations
INSERT INTO recommendations (
    subscription_id, resource_group, resource_name, resource_type,
    title, description, category, impact,
    estimated_monthly_savings, estimated_annual_savings, currency,
    confidence_score, implementation_effort, risk_level,
    status, source, valid_from, is_stale, created_at, updated_at
) VALUES
    ('sub-001', 'production-rg', 'web-vm-01', 'Microsoft.Compute/virtualMachines',
     'Rightsize VM: Standard_D4s_v3 to Standard_D2s_v3',
     'This VM is underutilized. CPU usage averages 15% over the past 30 days. Consider downsizing to save costs.',
     'rightsizing', 'high',
     75.25, 903.00, 'USD', 0.85, 'low', 'low',
     'new', 'cloudoptima', '2026-02-16', false, NOW(), NOW()),
    
    ('sub-001', 'production-rg', 'db-sql-01', 'Microsoft.Sql/servers/databases',
     'Consider Reserved Instance for SQL Database',
     'This database runs 24/7. A 1-year reserved instance could save 40% on costs.',
     'reserved_instances', 'high',
     128.30, 1539.60, 'USD', 0.90, 'medium', 'low',
     'new', 'cloudoptima', '2026-02-16', false, NOW(), NOW()),
    
    ('sub-001', 'production-rg', 'storage-01', 'Microsoft.Storage/storageAccounts',
     'Optimize Storage Tier',
     'Move infrequently accessed data to Cool tier to reduce storage costs.',
     'storage_optimization', 'medium',
     12.50, 150.00, 'USD', 0.75, 'low', 'low',
     'new', 'cloudoptima', '2026-02-16', false, NOW(), NOW());

-- Verify data
SELECT title, estimated_monthly_savings, category, status 
FROM recommendations 
ORDER BY estimated_monthly_savings DESC;
```

#### 6.5 Exit PostgreSQL

```sql
\q
```

Then exit SSH:
```bash
exit
```

---

### Step 7: Test with Sample Data

After adding sample data, test the endpoints again:

#### 7.1 Cost Summary (with data)

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://52.179.209.239:8000/api/v1/costs/summary"
```

**Expected Response:**
```json
{
  "total_cost": 1068.45,
  "currency": "USD",
  "period_start": "2026-01-17",
  "period_end": "2026-02-16",
  "top_services": [
    {"service": "SQL Database", "cost": 639.25},
    {"service": "Virtual Machines", "cost": 384.00},
    {"service": "Storage", "cost": 45.20}
  ]
}
```

#### 7.2 Recommendations Summary (with data)

**PowerShell:**
```powershell
Invoke-RestMethod -Uri "http://52.179.209.239:8000/api/v1/recommendations/summary"
```

**Expected Response:**
```json
{
  "total_recommendations": 3,
  "by_status": {"new": 3},
  "potential_monthly_savings": 216.05,
  "potential_annual_savings": 2592.60,
  "by_category": [
    {"category": "reserved_instances", "count": 1, "potential_monthly_savings": 128.30},
    {"category": "rightsizing", "count": 1, "potential_monthly_savings": 75.25},
    {"category": "storage_optimization", "count": 1, "potential_monthly_savings": 12.50}
  ]
}
```

#### 7.3 List Recommendations (with data)

**PowerShell:**
```powershell
$recs = Invoke-RestMethod -Uri "http://52.179.209.239:8000/api/v1/recommendations/"
$recs | Format-Table id, title, estimated_monthly_savings, category
```

---

### Step 8: Test API Documentation Interface

1. Go to: **http://52.179.209.239:8000/docs**
2. Try the interactive features:
   - Expand any endpoint
   - Click "Try it out"
   - Modify parameters if needed
   - Click "Execute"
   - View the response

**Endpoints to try:**
- `GET /api/v1/costs/summary` - See cost overview
- `GET /api/v1/costs/by-service` - See breakdown by service
- `GET /api/v1/recommendations/` - List all recommendations
- `GET /api/v1/recommendations/summary` - See savings potential

---

### Step 9: Check Service Status

**PowerShell:**
```powershell
wsl ssh azureuser@52.179.209.239 "cd /opt/cloudoptima && docker-compose ps"
```

**Expected Output:**
```
NAME                          STATUS    PORTS
cloudoptima_backend_1         Up        0.0.0.0:8000->8000/tcp
cloudoptima_db_1              Up        0.0.0.0:5432->5432/tcp
cloudoptima_frontend_1        Up        0.0.0.0:3000->3000/tcp
cloudoptima_redis_1           Up        0.0.0.0:6379->6379/tcp
```

---

## 🎬 Complete Demo Script

Here's a complete demo script you can follow:

### Demo Script (5-10 minutes)

**1. Introduction (1 min)**
- "CloudOptima AI is a FinOps platform for cloud cost optimization"
- "Deployed on Azure VM with Docker containers"
- "Backend: FastAPI + PostgreSQL, Frontend: React"

**2. Show Frontend (1 min)**
- Open: http://52.179.209.239:3000
- "React application successfully deployed and running"

**3. Show API Health (1 min)**
- Open: http://52.179.209.239:8000/health
- "Backend API is healthy and responding"

**4. Explore API Documentation (2 min)**
- Open: http://52.179.209.239:8000/docs
- "Interactive Swagger UI for all endpoints"
- Demonstrate one endpoint (e.g., costs/summary)

**5. Show Cost Data (2 min)**
```powershell
# Get cost summary
Invoke-RestMethod -Uri "http://52.179.209.239:8000/api/v1/costs/summary"

# Get cost by service
Invoke-RestMethod -Uri "http://52.179.209.239:8000/api/v1/costs/by-service"
```

**6. Show Recommendations (2 min)**
```powershell
# Get recommendations summary
Invoke-RestMethod -Uri "http://52.179.209.239:8000/api/v1/recommendations/summary"

# List all recommendations
Invoke-RestMethod -Uri "http://52.179.209.239:8000/api/v1/recommendations/"
```

**7. Show Infrastructure (1 min)**
```powershell
# Show running containers
wsl ssh azureuser@52.179.209.239 "docker-compose -f /opt/cloudoptima/docker-compose.yml ps"
```

**8. Conclusion (1 min)**
- "All services running successfully"
- "API endpoints responding correctly"
- "Database tables created and operational"
- "Ready for further development"

---

## 🧪 Quick Test Commands

Copy and paste these commands for quick testing:

```powershell
# Test 1: Health Check
Invoke-RestMethod -Uri "http://52.179.209.239:8000/health"

# Test 2: API Info
Invoke-RestMethod -Uri "http://52.179.209.239:8000/"

# Test 3: Cost Summary
Invoke-RestMethod -Uri "http://52.179.209.239:8000/api/v1/costs/summary"

# Test 4: Recommendations Summary
Invoke-RestMethod -Uri "http://52.179.209.239:8000/api/v1/recommendations/summary"

# Test 5: List Categories
Invoke-RestMethod -Uri "http://52.179.209.239:8000/api/v1/recommendations/categories/list"

# Test 6: Frontend (opens in browser)
Start-Process "http://52.179.209.239:3000"

# Test 7: API Docs (opens in browser)
Start-Process "http://52.179.209.239:8000/docs"
```

---

## 📊 Sample Data Queries

If you added sample data, use these queries:

```powershell
# Get detailed cost breakdown
$costs = Invoke-RestMethod -Uri "http://52.179.209.239:8000/api/v1/costs/by-service"
$costs | Format-Table service, cost, percent

# Get all recommendations with details
$recs = Invoke-RestMethod -Uri "http://52.179.209.239:8000/api/v1/recommendations/"
$recs | Format-Table id, title, @{L='Savings';E={$_.estimated_monthly_savings}}, category

# Get specific recommendation
Invoke-RestMethod -Uri "http://52.179.209.239:8000/api/v1/recommendations/1"
```

---

## 🔍 Troubleshooting

### If services are not responding:

**Check service status:**
```powershell
wsl ssh azureuser@52.179.209.239 "cd /opt/cloudoptima && docker-compose ps"
```

**Restart services:**
```powershell
wsl ssh azureuser@52.179.209.239 "cd /opt/cloudoptima && docker-compose restart"
```

**Check logs:**
```powershell
# Backend logs
wsl ssh azureuser@52.179.209.239 "cd /opt/cloudoptima && docker-compose logs --tail=50 backend"

# All services
wsl ssh azureuser@52.179.209.239 "cd /opt/cloudoptima && docker-compose logs --tail=20"
```

---

## 📝 Notes

- **No Authentication:** This is a POC version without authentication
- **Empty Data:** Initially, all endpoints return empty data
- **Sample Data:** Follow Step 6 to add sample data for a better demo
- **API Documentation:** The Swagger UI at /docs is the best way to explore all endpoints

---

## 🎯 Key Demo Points

1. ✅ **Infrastructure:** Successfully deployed on Azure VM
2. ✅ **Services:** All containers running (Frontend, Backend, DB, Redis)
3. ✅ **Database:** Tables created, schema working
4. ✅ **API:** All endpoints responding correctly
5. ✅ **Frontend:** React application accessible
6. ✅ **Documentation:** Interactive API docs available

**Deployment Status: SUCCESSFUL** 🎉
