# CloudOptima AI - Azure Quick Start

Get CloudOptima AI running on Azure in 15 minutes using Terraform.

## Prerequisites

- Azure account with appropriate permissions
- Azure CLI installed
- Terraform installed (1.0+)
- Docker installed (for building images)

## Quick Start (15 minutes)

### Step 1: Install Prerequisites

```powershell
# Windows (PowerShell as Administrator)
winget install Microsoft.AzureCLI
winget install Hashicorp.Terraform
winget install Docker.DockerDesktop

# Verify installations
az --version
terraform --version
docker --version
```

```bash
# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Mac
brew install azure-cli terraform docker
```

### Step 2: Run Deployment Script

```powershell
# Windows
cd 03-Projects\cloudoptima-ai
.\deploy-azure.ps1
```

```bash
# Linux/Mac
cd 03-Projects/cloudoptima-ai
chmod +x deploy-azure.sh
./deploy-azure.sh
```

The script will:
1. Login to Azure
2. Create Service Principal for Cost Management API
3. Generate terraform.tfvars with your credentials
4. Deploy all infrastructure with Terraform
5. Output access URLs and credentials

### Step 3: Build and Push Docker Images

```bash
# Get ACR name from Terraform output
cd terraform
ACR_NAME=$(terraform output -raw acr_name)
cd ..

# Login to Azure Container Registry
az acr login --name $ACR_NAME

# Build and push backend image
docker build -f docker/Dockerfile.backend -t $ACR_NAME.azurecr.io/cloudoptima-backend:latest .
docker push $ACR_NAME.azurecr.io/cloudoptima-backend:latest

# Build and push frontend image
docker build -f docker/Dockerfile.frontend -t $ACR_NAME.azurecr.io/cloudoptima-frontend:latest .
docker push $ACR_NAME.azurecr.io/cloudoptima-frontend:latest
```

### Step 4: Restart Container Instances

```bash
# Restart all containers to use new images
az container restart --resource-group cloudoptima-rg --name cloudoptima-backend
az container restart --resource-group cloudoptima-rg --name cloudoptima-frontend
az container restart --resource-group cloudoptima-rg --name cloudoptima-celery-worker
az container restart --resource-group cloudoptima-rg --name cloudoptima-celery-beat

# Check status
az container list --resource-group cloudoptima-rg --output table
```

### Step 5: Initialize Database

```bash
# Get database credentials
cd terraform
DB_HOST=$(terraform output -raw postgres_host)
DB_NAME=$(terraform output -raw postgres_database)
DB_USER=$(terraform output -raw postgres_user)
DB_PASSWORD=$(terraform output -raw postgres_password)

# Connect to database
psql "host=$DB_HOST port=5432 dbname=$DB_NAME user=$DB_USER password=$DB_PASSWORD sslmode=require"
```

```sql
-- Enable TimescaleDB extension
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Create hypertable for cost data
SELECT create_hypertable('cost_data', 'billing_period_start', if_not_exists => TRUE);

-- Verify
\dx timescaledb
```

### Step 6: Access Application

```bash
# Get URLs from Terraform
cd terraform
terraform output frontend_url
terraform output backend_url
terraform output backend_api_docs
```

Open the frontend URL in your browser and register a new account!

---

## What Gets Deployed

### Infrastructure
- **Resource Group**: cloudoptima-rg
- **Virtual Network**: 10.0.0.0/16 with subnets
- **Azure Database for PostgreSQL**: Flexible Server with TimescaleDB
- **Azure Cache for Redis**: Basic tier
- **Azure Container Registry**: For Docker images
- **Azure Container Instances**: 4 containers (frontend, backend, celery-worker, celery-beat)
- **Azure Key Vault**: For secrets management
- **Log Analytics Workspace**: For monitoring

### Cost Estimate
- Container Instances: $40-70/month
- PostgreSQL Flexible Server: $30-50/month
- Redis Cache: $15/month
- Container Registry: $5/month
- Networking: $10-20/month
- **Total: ~$100-160/month**

---

## Manual Deployment (Alternative)

If you prefer manual control:

### 1. Configure Terraform Variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Edit with your values
```

### 2. Create Service Principal

```bash
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Create service principal
az ad sp create-for-rbac \
  --name cloudoptima-reader \
  --role "Cost Management Reader" \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID

# Copy the output values to terraform.tfvars:
# - appId → azure_client_id
# - password → azure_client_secret
# - tenant → azure_tenant_id
```

### 3. Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

### 4. Build and Push Images

Follow Step 3 from Quick Start above.

---

## Post-Deployment Configuration

### Create Admin User

```bash
# Get frontend URL
FRONTEND_URL=$(cd terraform && terraform output -raw frontend_url)

# Register admin user
curl -X POST $FRONTEND_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "SecurePassword123!",
    "full_name": "Admin User",
    "organization_name": "My Company"
  }'
```

### Trigger Cost Ingestion

```bash
# Login to get JWT token
TOKEN=$(curl -X POST $FRONTEND_URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"SecurePassword123!"}' \
  | jq -r '.access_token')

# Trigger ingestion
curl -X POST $FRONTEND_URL/api/costs/ingest \
  -H "Authorization: Bearer $TOKEN"
```

---

## Monitoring and Logs

### View Container Logs

```bash
# Backend logs
az container logs --resource-group cloudoptima-rg --name cloudoptima-backend --follow

# Frontend logs
az container logs --resource-group cloudoptima-rg --name cloudoptima-frontend --follow

# Celery worker logs
az container logs --resource-group cloudoptima-rg --name cloudoptima-celery-worker --follow

# Celery beat logs
az container logs --resource-group cloudoptima-rg --name cloudoptima-celery-beat --follow
```

### Check Container Status

```bash
# List all containers
az container list --resource-group cloudoptima-rg --output table

# Show specific container
az container show --resource-group cloudoptima-rg --name cloudoptima-backend --output table
```

### View Metrics in Azure Portal

1. Go to Azure Portal
2. Navigate to Resource Group: cloudoptima-rg
3. Click on Log Analytics Workspace
4. View container logs and metrics

---

## Troubleshooting

### Containers won't start

```bash
# Check container logs
az container logs --resource-group cloudoptima-rg --name cloudoptima-backend

# Check container events
az container show --resource-group cloudoptima-rg --name cloudoptima-backend --query "containers[0].instanceView.events"

# Restart container
az container restart --resource-group cloudoptima-rg --name cloudoptima-backend
```

### Database connection issues

```bash
# Check database status
az postgres flexible-server show --resource-group cloudoptima-rg --name cloudoptima-db

# Check firewall rules
az postgres flexible-server firewall-rule list --resource-group cloudoptima-rg --name cloudoptima-db

# Test connection
psql "host=$(cd terraform && terraform output -raw postgres_host) port=5432 dbname=cloudoptima user=cloudoptima password=$(cd terraform && terraform output -raw postgres_password) sslmode=require"
```

### Redis connection issues

```bash
# Check Redis status
az redis show --resource-group cloudoptima-rg --name cloudoptima-redis

# Get Redis keys
az redis list-keys --resource-group cloudoptima-rg --name cloudoptima-redis
```

---

## Updating the Application

### Update Docker Images

```bash
# Build new images
docker build -f docker/Dockerfile.backend -t $ACR_NAME.azurecr.io/cloudoptima-backend:latest .
docker push $ACR_NAME.azurecr.io/cloudoptima-backend:latest

# Restart containers
az container restart --resource-group cloudoptima-rg --name cloudoptima-backend
az container restart --resource-group cloudoptima-rg --name cloudoptima-celery-worker
az container restart --resource-group cloudoptima-rg --name cloudoptima-celery-beat
```

### Update Infrastructure

```bash
cd terraform

# Make changes to .tf files
nano main.tf

# Apply changes
terraform plan
terraform apply
```

---

## Cleanup

### Destroy All Resources

```bash
cd terraform
terraform destroy

# Or delete resource group
az group delete --name cloudoptima-rg --yes --no-wait
```

### Delete Service Principal

```bash
az ad sp delete --id YOUR_CLIENT_ID
```

---

## Next Steps

1. ✅ Infrastructure deployed
2. ✅ Application running
3. ⏭️ Set up custom domain with Azure DNS
4. ⏭️ Enable Azure Front Door for CDN and WAF
5. ⏭️ Configure Azure DevOps or GitHub Actions for CI/CD
6. ⏭️ Set up Azure Monitor alerts
7. ⏭️ Enable Azure Backup for additional protection

---

## Support

For issues or questions:
- Check logs: `az container logs --resource-group cloudoptima-rg --name cloudoptima-backend --follow`
- Review [AZURE-DEPLOYMENT-GUIDE.md](AZURE-DEPLOYMENT-GUIDE.md)
- Check API docs at your backend URL + `/docs`
- Review Terraform state: `cd terraform && terraform show`

