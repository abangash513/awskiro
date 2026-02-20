# CloudOptima AI - Azure Deployment Guide

Complete guide to deploy the CloudOptima AI MVP to your Azure account using Terraform.

## Deployment Options

### Option 1: Azure Container Instances (Recommended for MVP)
- Fully managed containers, no VM management
- Fastest deployment, simplest setup
- Cost: ~$50-120/month for MVP workload

### Option 2: Azure VM with Docker Compose
- Single VM running all containers
- Simplest migration from local development
- Cost: ~$40-90/month (Standard_B2s or Standard_B2ms)

### Option 3: Azure Container Apps
- Serverless containers with auto-scaling
- Built-in ingress and HTTPS
- Cost: ~$60-150/month

---

## Option 1: Azure Container Instances with Terraform (Recommended)

### Prerequisites
- Azure account with appropriate permissions
- Azure CLI installed and configured
- Terraform installed (1.0+)
- Domain name (optional, for custom domain)

### Architecture
```
Internet → Azure Front Door (optional) → Container Instances:
  - Frontend (React)
  - Backend (FastAPI)
  - Celery Worker
  - Celery Beat
  ↓
Azure Database for PostgreSQL Flexible Server (with TimescaleDB)
Azure Cache for Redis
```

### Step 1: Install Prerequisites

```bash
# Install Azure CLI
# Windows (PowerShell)
winget install Microsoft.AzureCLI

# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Mac
brew install azure-cli

# Install Terraform
# Windows (PowerShell)
winget install Hashicorp.Terraform

# Linux
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Mac
brew install terraform
```

### Step 2: Login to Azure

```bash
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### Step 3: Configure Terraform Variables

```bash
cd 03-Projects/cloudoptima-ai/terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Edit with your values
```

### Step 4: Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy
terraform apply
```

This creates:
- Resource Group
- Virtual Network with subnets
- Azure Database for PostgreSQL Flexible Server (with TimescaleDB extension)
- Azure Cache for Redis
- Azure Container Registry
- Azure Container Instances (4 containers)
- Azure Key Vault for secrets
- Application Gateway (optional)
- Log Analytics Workspace

### Step 5: Build and Push Docker Images

```bash
# Get ACR login server
ACR_NAME=$(terraform output -raw acr_name)
az acr login --name $ACR_NAME

# Build and push backend
docker build -f docker/Dockerfile.backend -t $ACR_NAME.azurecr.io/cloudoptima-backend:latest .
docker push $ACR_NAME.azurecr.io/cloudoptima-backend:latest

# Build and push frontend
docker build -f docker/Dockerfile.frontend -t $ACR_NAME.azurecr.io/cloudoptima-frontend:latest .
docker push $ACR_NAME.azurecr.io/cloudoptima-frontend:latest
```

### Step 6: Update Container Instances

```bash
# Restart container instances with new images
az container restart --resource-group $(terraform output -raw resource_group_name) --name cloudoptima-backend
az container restart --resource-group $(terraform output -raw resource_group_name) --name cloudoptima-frontend
az container restart --resource-group $(terraform output -raw resource_group_name) --name cloudoptima-celery-worker
az container restart --resource-group $(terraform output -raw resource_group_name) --name cloudoptima-celery-beat
```

---

## Option 2: Single Azure VM with Docker Compose (Fastest)

### Step 1: Deploy VM with Terraform

```bash
cd 03-Projects/cloudoptima-ai/terraform/vm-deployment
terraform init
terraform apply
```

### Step 2: Connect and Deploy Application

```bash
# SSH to VM (use IP from Terraform output)
ssh azureuser@<PUBLIC_IP>

# Clone repository
git clone https://github.com/your-org/cloudoptima-ai.git
cd cloudoptima-ai

# Configure environment
cp .env.example .env
nano .env  # Add your Azure credentials

# Generate secure secrets
export SECRET_KEY=$(openssl rand -hex 32)
export DB_PASSWORD=$(openssl rand -hex 16)
sed -i "s/SECRET_KEY=change-me.*/SECRET_KEY=$SECRET_KEY/" .env
sed -i "s/POSTGRES_PASSWORD=cloudoptima/POSTGRES_PASSWORD=$DB_PASSWORD/" .env
sed -i "s/:cloudoptima@/:$DB_PASSWORD@/" .env

# Start services
docker compose up -d

# Check status
docker compose ps
docker compose logs -f
```

---

## Option 3: Azure Container Apps (Serverless)

### Step 1: Deploy with Terraform

```bash
cd 03-Projects/cloudoptima-ai/terraform/container-apps
terraform init
terraform apply
```

This creates:
- Container Apps Environment
- 4 Container Apps (frontend, backend, celery-worker, celery-beat)
- Azure Database for PostgreSQL
- Azure Cache for Redis
- Built-in ingress with HTTPS
- Auto-scaling configuration

---

## Post-Deployment Steps

### 1. Initialize Database

```bash
# Get database connection details
DB_HOST=$(terraform output -raw postgres_host)
DB_NAME=$(terraform output -raw postgres_database)
DB_USER=$(terraform output -raw postgres_user)
DB_PASSWORD=$(terraform output -raw postgres_password)

# Connect and enable TimescaleDB
psql "host=$DB_HOST port=5432 dbname=$DB_NAME user=$DB_USER password=$DB_PASSWORD sslmode=require"
```

```sql
CREATE EXTENSION IF NOT EXISTS timescaledb;
SELECT create_hypertable('cost_data', 'billing_period_start', if_not_exists => TRUE);
```

### 2. Create First Admin User

```bash
# Get frontend URL
FRONTEND_URL=$(terraform output -raw frontend_url)

# Via API
curl -X POST $FRONTEND_URL/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "SecurePassword123!",
    "full_name": "Admin User",
    "organization_name": "My Company"
  }'
```

### 3. Connect Azure Subscription

Credentials are already configured via Terraform (using Managed Identity or Service Principal).

### 4. Trigger Initial Cost Ingestion

```bash
# Via API
curl -X POST $FRONTEND_URL/api/costs/ingest \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## Monitoring and Maintenance

### Azure Monitor Logs
```bash
# View container logs
az container logs --resource-group cloudoptima-rg --name cloudoptima-backend --follow

# View all container groups
az container list --resource-group cloudoptima-rg --output table
```

### Database Backups

#### Azure Database for PostgreSQL
- Automated daily backups enabled by default
- Point-in-time recovery available (7-35 days)
- Geo-redundant backups optional

### Scaling

#### Container Instances
```bash
# Update container resources
az container create --resource-group cloudoptima-rg --name cloudoptima-backend \
  --cpu 2 --memory 4
```

#### Azure VM
- Resize VM via Azure Portal or CLI
- Add more VMs with load balancer

---

## Cost Estimates

### Container Instances (Recommended)
- Container Instances (4 containers): $40-70/month
- Azure Database for PostgreSQL (Burstable B2s): $30-50/month
- Azure Cache for Redis (Basic C0): $15/month
- Container Registry: $5/month
- Networking: $10-20/month
- **Total: ~$100-160/month**

### Single Azure VM
- VM Standard_B2ms: $60/month
- Managed Disk 50GB: $5/month
- Networking: $10/month
- **Total: ~$75/month**

### Container Apps (Serverless)
- Container Apps: $50-100/month
- Azure Database for PostgreSQL: $30-50/month
- Azure Cache for Redis: $15/month
- **Total: ~$95-165/month**

---

## Troubleshooting

### Backend won't start
```bash
# Check container logs
az container logs --resource-group cloudoptima-rg --name cloudoptima-backend

# Check database connection
az postgres flexible-server show --resource-group cloudoptima-rg --name cloudoptima-db
```

### Celery tasks not running
```bash
# Check Redis connection
az redis show --resource-group cloudoptima-rg --name cloudoptima-redis

# Restart workers
az container restart --resource-group cloudoptima-rg --name cloudoptima-celery-worker
az container restart --resource-group cloudoptima-rg --name cloudoptima-celery-beat
```

### Frontend can't reach backend
- Check Network Security Group rules
- Verify CORS_ORIGINS in Key Vault secrets
- Check container networking configuration

---

## Next Steps

1. Set up Azure DevOps or GitHub Actions for CI/CD
2. Configure custom domain with Azure DNS
3. Enable Azure Front Door for CDN and WAF
4. Set up Azure Monitor alerts for cost anomalies
5. Configure Azure Backup for additional protection

