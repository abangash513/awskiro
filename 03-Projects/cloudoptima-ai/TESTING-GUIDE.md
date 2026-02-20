# CloudOptima AI - Testing Guide

## Important: No Login Required

This is a POC (Proof of Concept) version with **NO AUTHENTICATION**. All API endpoints are publicly accessible without login credentials. This was designed for quick demonstration purposes.

## Mock Data Overview

The application now contains realistic mock data:

### Cost Data
- **20 cost records** across 5 Azure services
- **Total costs**: $2,878.60 USD
- **Services included**:
  - SQL Database: $965.15
  - Virtual Machines: $807.35
  - Azure Kubernetes Service: $565.70
  - App Service: $375.00
  - Storage: $165.40

### Recommendations
- **5 optimization recommendations**
- **Total potential savings**: $627.85/month ($7,534.20/year)
- **Categories**:
  1. VM Rightsizing: $75.25/month
  2. Reserved Instances: $128.30/month
  3. Storage Optimization: $24.50/month
  4. Idle Resources: $85.30/month
  5. Savings Plans: $314.50/month

### Budgets
- **3 budget configurations**:
  - Production Monthly: $5,000 (64.92% spent)
  - Development Monthly: $1,000 (28.74% spent)
  - Annual Infrastructure: $50,000 (16.47% spent)

## How to Test

### Option 1: Quick Browser Test

1. Open the API documentation:
   ```powershell
   Start-Process 'http://52.179.209.239:8000/docs'
   ```

2. Try these endpoints directly in the browser:
   - Cost Summary: http://52.179.209.239:8000/api/v1/costs/summary
   - Recommendations: http://52.179.209.239:8000/api/v1/recommendations/
   - Recommendations Summary: http://52.179.209.239:8000/api/v1/recommendations/summary

### Option 2: Automated Test Script

Run the comprehensive test suite:
```powershell
cd 03-Projects/cloudoptima-ai
.\run-demo-tests.ps1
```

This tests all 10 endpoints and verifies the data.

### Option 3: Manual API Testing

Use PowerShell to test individual endpoints:

```powershell
# Get cost summary
Invoke-RestMethod -Uri "http://52.179.209.239:8000/api/v1/costs/summary"

# Get all recommendations
Invoke-RestMethod -Uri "http://52.179.209.239:8000/api/v1/recommendations/"

# Get recommendations summary
Invoke-RestMethod -Uri "http://52.179.209.239:8000/api/v1/recommendations/summary"

# Get cost by service
Invoke-RestMethod -Uri "http://52.179.209.239:8000/api/v1/costs/by-service"

# Get cost trend
Invoke-RestMethod -Uri "http://52.179.209.239:8000/api/v1/costs/trend"
```

### Option 4: Frontend Testing

Open the frontend application:
```powershell
Start-Process 'http://52.179.209.239:3000'
```

Note: The frontend is a basic React app that may need additional configuration to display the data.

## API Endpoints Reference

### Cost Endpoints
- `GET /api/v1/costs/summary` - Aggregated cost summary
- `GET /api/v1/costs/trend` - Daily cost trend
- `GET /api/v1/costs/by-service` - Cost breakdown by service
- `GET /api/v1/costs/by-resource-group` - Cost breakdown by resource group

### Recommendation Endpoints
- `GET /api/v1/recommendations/` - List all recommendations
- `GET /api/v1/recommendations/summary` - Summary statistics
- `GET /api/v1/recommendations/{id}` - Get specific recommendation
- `GET /api/v1/recommendations/categories/list` - List categories

### Health Check
- `GET /health` - Application health status

## Expected Results

When you test the endpoints, you should see:

1. **Cost Summary**: Total of $2,878.60 with 5 services listed
2. **Recommendations**: 5 recommendations with detailed savings information
3. **Recommendations Summary**: 
   - Total: 5 recommendations
   - Monthly savings: $627.85
   - Annual savings: $7,534.20

## Troubleshooting

### If you see empty data:
```powershell
# Reload the mock data
cd 03-Projects/cloudoptima-ai
.\load-mock-data.ps1
```

### If services are not running:
```powershell
# SSH to VM and check status
wsl bash -c "sshpass -p 'zJsjfxP80cmn!WeU' ssh azureuser@52.179.209.239 'cd /opt/cloudoptima && docker-compose ps'"
```

### If you need to restart services:
```powershell
# Restart all services
wsl bash -c "sshpass -p 'zJsjfxP80cmn!WeU' ssh azureuser@52.179.209.239 'cd /opt/cloudoptima && docker-compose restart'"
```

## Next Steps for Production

If you want to add authentication for a production version:

1. Add back User and Organization models
2. Implement JWT token authentication
3. Add login/register endpoints
4. Protect all endpoints with auth middleware
5. Add role-based access control (RBAC)
6. Implement Azure AD integration

For now, this POC demonstrates the core functionality without the complexity of authentication.
