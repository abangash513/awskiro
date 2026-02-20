# CloudOptima AI - Deployment Status & Next Steps

## Current Status ✅

### Infrastructure Deployed (Azure - East US 2)
- ✅ Resource Group: `cloudoptima-rg`
- ✅ Virtual Network with subnets
- ✅ Network Security Group
- ✅ Public IPs (Frontend: 20.110.64.59, Backend: 20.69.252.116)
- ✅ Azure Container Registry: `cloudoptimaacro6p4mr44.azurecr.io`
- ✅ Azure SQL Server: `cloudoptima-sql-o6p4mr44.database.windows.net`
- ✅ Azure SQL Database: `cloudoptima` (Basic tier, 2GB)
- ✅ Redis Cache: `cloudoptima-redis.redis.cache.windows.net`
- ✅ Key Vault: `cloudoptima-kv-o6p4mr44`
- ✅ Log Analytics Workspace
- ✅ Network Profile for containers

### Pending Items ⏳
- ❌ Docker Desktop NOT installed (required for building images)
- ⏳ Container Instances (waiting for Docker images)
- ⏳ Backend code needs SQL Server compatibility updates

### Database Change
- **Changed from PostgreSQL to Azure SQL Database** to avoid quota restrictions
- Connection string format: `mssql+pyodbc://...`
- Basic tier with 2GB max size
- TimescaleDB features need to be removed from code

## Next Steps

### 1. Install Docker Desktop (REQUIRED - Currently Missing)

**CRITICAL**: Docker Desktop is NOT installed. You must install it before proceeding.

Download and install Docker Desktop for Windows:
https://www.docker.com/products/docker-desktop/

**After installation:**
1. Restart your computer if prompted
2. Start Docker Desktop
3. Wait for Docker to fully start (check system tray icon)

### 2. Update Backend Code for SQL Server (5 minutes)

The backend needs updates to work with Azure SQL instead of PostgreSQL:

**Add SQL Server driver to requirements.txt:**

```powershell
# Add pyodbc to backend/requirements.txt
Add-Content -Path "03-Projects\cloudoptima-ai\backend\requirements.txt" -Value "pyodbc==5.2.0"
```

**Update database.py to remove TimescaleDB:**

Edit `backend/app/core/database.py` and remove the TimescaleDB extension code from `init_db()` function.

### 3. Build and Push Docker Images (10 minutes)

**IMPORTANT**: Ensure Docker Desktop is running before executing these commands.

```powershell
cd 03-Projects\cloudoptima-ai

# Login to Azure Container Registry
az acr login --name cloudoptimaacro6p4mr44

# Build and push backend image
docker build -t cloudoptimaacro6p4mr44.azurecr.io/cloudoptima-backend:latest -f docker/Dockerfile.backend .
docker push cloudoptimaacro6p4mr44.azurecr.io/cloudoptima-backend:latest

# Build and push frontend image
docker build -t cloudoptimaacro6p4mr44.azurecr.io/cloudoptima-frontend:latest -f docker/Dockerfile.frontend .
docker push cloudoptimaacro6p4mr44.azurecr.io/cloudoptima-frontend:latest
```

### 4. Deploy Container Instances (5 minutes)

```powershell
cd 03-Projects\cloudoptima-ai\terraform
terraform apply -auto-approve
```

This will create:
- Backend API container
- Frontend container
- Celery worker container
- Celery beat container

### 5. Initialize Database Schema (2 minutes)

```powershell
# Get backend container IP
$backendUrl = terraform output -raw backend_url

# Run database migrations (if using Alembic)
# Or manually create tables using SQL scripts
```

### 6. Create Admin User

```powershell
# Access the API docs
$apiDocs = terraform output -raw backend_api_docs
Start-Process $apiDocs

# Use the /auth/register endpoint to create an admin user
```

### 7. Access the Application

```powershell
# Get URLs
terraform output frontend_url
terraform output backend_url
terraform output backend_api_docs
```

## Important Notes

### Azure SQL vs PostgreSQL
The application was originally designed for PostgreSQL with TimescaleDB. Since we switched to Azure SQL:

1. **TimescaleDB features won't work** - hypertables, time-series optimizations
2. **Need to update backend code** to:
   - Install `pyodbc` and SQL Server ODBC Driver 18
   - Update SQLAlchemy models (remove TimescaleDB-specific features)
   - Update connection string handling

### Backend Code Changes Needed

Add to `requirements.txt`:
```
pyodbc
```

Update database connection in `app/core/database.py`:
```python
# Remove TimescaleDB-specific code
# Use standard SQLAlchemy with SQL Server dialect
```

### Alternative: Use Standard Tier SQL Database

If you need more than 2GB:
```hcl
# In database.tf
sku_name    = "S0"  # Standard tier
max_size_gb = 250   # Up to 1TB available
```

Cost: ~$15/month for S0 (10 DTUs, 250GB)

## Troubleshooting

### Container Images Not Found
- Ensure Docker Desktop is installed and running
- Build and push images before deploying containers

### Key Vault Already Exists
- Wait 30 seconds for purge to complete
- Or use a different suffix in variables.tf

### SQL Database Size Error
- Basic tier max is 2GB
- Use Standard (S0+) or Premium tier for larger databases

## Cost Estimate

Monthly costs (East US 2):
- Azure SQL Basic: ~$5
- Redis Cache Basic C0: ~$17
- Container Instances: ~$30-50
- Container Registry Basic: ~$5
- Storage & Networking: ~$5

**Total: ~$62-82/month**

## Support

For issues:
1. Check Azure Portal for resource status
2. View container logs: `az container logs --name <container-name> --resource-group cloudoptima-rg`
3. Check terraform state: `terraform state list`
