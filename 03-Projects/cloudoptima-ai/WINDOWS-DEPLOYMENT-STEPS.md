# CloudOptima AI - Windows Deployment Steps

Complete step-by-step guide for deploying to Azure from Windows.

## ✅ Prerequisites Status

- [x] Azure CLI - Installed (v2.83.0)
- [x] Terraform - Installed (v1.11.4)
- [x] Azure Login - Completed
- [ ] Docker Desktop - **REQUIRED FOR IMAGE BUILD**

## 🚀 Deployment Steps

### Step 1: Install Docker Desktop (Required)

Docker is needed to build and push container images.

**Download and Install:**
1. Download from: https://www.docker.com/products/docker-desktop/
2. Install Docker Desktop
3. Start Docker Desktop
4. Verify: `docker --version`

### Step 2: Set Azure Subscription

```powershell
# List subscriptions
az account list --output table

# Set subscription (use your subscription ID)
az account set --subscription "3a6cc9a1-adf7-49fe-a02f-f6db16ced2a1"

# Verify
az account show
```

### Step 3: Create Service Principal

```powershell
# Create service principal for Cost Management API
$subscriptionId = "3a6cc9a1-adf7-49fe-a02f-f6db16ced2a1"

$sp = az ad sp create-for-rbac `
  --name "cloudoptima-reader" `
  --role "Cost Management Reader" `
  --scopes "/subscriptions/$subscriptionId" `
  --output json | ConvertFrom-Json

# Save these values - you'll need them
Write-Host "Tenant ID: $($sp.tenant)"
Write-Host "Client ID: $($sp.appId)"
Write-Host "Client Secret: $($sp.password)"
```

### Step 4: Configure Terraform

```powershell
cd 03-Projects\cloudoptima-ai\terraform

# Copy example file
Copy-Item terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
notepad terraform.tfvars
```

**Edit terraform.tfvars with:**
```hcl
prefix              = "cloudoptima"
resource_group_name = "cloudoptima-rg"
location            = "eastus"

db_admin_username = "cloudoptima"
db_name           = "cloudoptima"
db_sku_name       = "B_Standard_B2s"

# Use values from Step 3
azure_tenant_id     = "YOUR_TENANT_ID"
azure_client_id     = "YOUR_CLIENT_ID"
azure_client_secret = "YOUR_CLIENT_SECRET"

tags = {
  Environment = "Production"
  Project     = "CloudOptima AI"
  ManagedBy   = "Terraform"
}
```

### Step 5: Deploy Infrastructure with Terraform

```powershell
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy (type 'yes' when prompted)
terraform apply

# Save outputs
terraform output > ..\terraform-outputs.txt
```

### Step 6: Build and Push Docker Images

```powershell
# Go back to project root
cd ..

# Get ACR name from Terraform
$acrName = (cd terraform; terraform output -raw acr_name; cd ..)

# Login to Azure Container Registry
az acr login --name $acrName

# Build and push backend image
docker build -f docker\Dockerfile.backend -t "${acrName}.azurecr.io/cloudoptima-backend:latest" .
docker push "${acrName}.azurecr.io/cloudoptima-backend:latest"

# Build and push frontend image
docker build -f docker\Dockerfile.frontend -t "${acrName}.azurecr.io/cloudoptima-frontend:latest" .
docker push "${acrName}.azurecr.io/cloudoptima-frontend:latest"
```

### Step 7: Restart Container Instances

```powershell
# Restart all containers to use new images
az container restart --resource-group cloudoptima-rg --name cloudoptima-backend
az container restart --resource-group cloudoptima-rg --name cloudoptima-frontend
az container restart --resource-group cloudoptima-rg --name cloudoptima-celery-worker
az container restart --resource-group cloudoptima-rg --name cloudoptima-celery-beat

# Check status
az container list --resource-group cloudoptima-rg --output table
```

### Step 8: Initialize Database

```powershell
cd terraform

# Get database credentials
$dbHost = terraform output -raw postgres_host
$dbName = terraform output -raw postgres_database
$dbUser = terraform output -raw postgres_user
$dbPassword = terraform output -raw postgres_password

# Connect to database (requires psql client)
# Download from: https://www.postgresql.org/download/windows/
psql "host=$dbHost port=5432 dbname=$dbName user=$dbUser password=$dbPassword sslmode=require"
```

**In psql, run:**
```sql
CREATE EXTENSION IF NOT EXISTS timescaledb;
SELECT create_hypertable('cost_data', 'billing_period_start', if_not_exists => TRUE);
\q
```

### Step 9: Access Application

```powershell
# Get URLs
cd terraform
terraform output frontend_url
terraform output backend_url
terraform output backend_api_docs
```

Open the frontend URL in your browser!

## 📋 Quick Commands Reference

```powershell
# View all Terraform outputs
cd 03-Projects\cloudoptima-ai\terraform
terraform output

# View container logs
az container logs --resource-group cloudoptima-rg --name cloudoptima-backend --follow

# Restart a container
az container restart --resource-group cloudoptima-rg --name cloudoptima-backend

# Check container status
az container list --resource-group cloudoptima-rg --output table

# Update and redeploy
docker build -f docker\Dockerfile.backend -t "${acrName}.azurecr.io/cloudoptima-backend:latest" .
docker push "${acrName}.azurecr.io/cloudoptima-backend:latest"
az container restart --resource-group cloudoptima-rg --name cloudoptima-backend
```

## 🐛 Troubleshooting

### Docker not installed
Download from: https://www.docker.com/products/docker-desktop/

### psql not installed
Download from: https://www.postgresql.org/download/windows/
Or use Azure Cloud Shell

### Container won't start
```powershell
az container logs --resource-group cloudoptima-rg --name cloudoptima-backend
az container show --resource-group cloudoptima-rg --name cloudoptima-backend
```

### Terraform errors
```powershell
terraform validate
terraform refresh
terraform plan
```

## 🗑️ Cleanup

```powershell
cd 03-Projects\cloudoptima-ai\terraform
terraform destroy
```

## ✅ Success Checklist

- [ ] Docker Desktop installed and running
- [ ] Azure CLI logged in
- [ ] Service Principal created
- [ ] terraform.tfvars configured
- [ ] Terraform infrastructure deployed
- [ ] Docker images built and pushed
- [ ] Containers restarted
- [ ] Database initialized with TimescaleDB
- [ ] Application accessible via browser

