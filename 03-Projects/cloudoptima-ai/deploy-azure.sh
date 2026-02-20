#!/bin/bash
# CloudOptima AI - Azure Deployment Script
# This script automates the deployment to Azure using Terraform

set -e

echo "=== CloudOptima AI - Azure Deployment ==="
echo ""

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed. Please install it first."
    echo "   Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install it first."
    echo "   Visit: https://www.terraform.io/downloads"
    exit 1
fi

echo "✅ Azure CLI and Terraform are installed"
echo ""

# Login to Azure
echo "Logging in to Azure..."
az login

# Select subscription
echo ""
echo "Available subscriptions:"
az account list --output table

echo ""
read -p "Enter subscription ID to use: " SUBSCRIPTION_ID
az account set --subscription "$SUBSCRIPTION_ID"

echo "✅ Using subscription: $(az account show --query name -o tsv)"
echo ""

# Get Azure credentials for service principal
echo "Creating Azure Service Principal for Cost Management API..."
echo ""
read -p "Enter a name for the service principal [cloudoptima-reader]: " SP_NAME
SP_NAME=${SP_NAME:-cloudoptima-reader}

# Create service principal
SP_OUTPUT=$(az ad sp create-for-rbac \
  --name "$SP_NAME" \
  --role "Cost Management Reader" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID" \
  --output json)

AZURE_TENANT_ID=$(echo $SP_OUTPUT | jq -r '.tenant')
AZURE_CLIENT_ID=$(echo $SP_OUTPUT | jq -r '.appId')
AZURE_CLIENT_SECRET=$(echo $SP_OUTPUT | jq -r '.password')

echo "✅ Service Principal created"
echo ""

# Navigate to terraform directory
cd terraform

# Create terraform.tfvars if it doesn't exist
if [ ! -f terraform.tfvars ]; then
    echo "Creating terraform.tfvars..."
    cat > terraform.tfvars <<EOF
# CloudOptima AI - Terraform Variables

prefix              = "cloudoptima"
resource_group_name = "cloudoptima-rg"
location            = "eastus"

db_admin_username = "cloudoptima"
db_name           = "cloudoptima"
db_sku_name       = "B_Standard_B2s"

azure_tenant_id     = "$AZURE_TENANT_ID"
azure_client_id     = "$AZURE_CLIENT_ID"
azure_client_secret = "$AZURE_CLIENT_SECRET"

tags = {
  Environment = "Production"
  Project     = "CloudOptima AI"
  ManagedBy   = "Terraform"
}
EOF
    echo "✅ terraform.tfvars created"
else
    echo "⚠️  terraform.tfvars already exists, skipping creation"
fi

echo ""
echo "Configuration:"
echo "  Subscription: $(az account show --query name -o tsv)"
echo "  Location: eastus"
echo "  Service Principal: $SP_NAME"
echo ""

read -p "Proceed with deployment? (y/n): " CONFIRM
if [ "$CONFIRM" != "y" ]; then
    echo "Deployment cancelled."
    exit 0
fi

# Initialize Terraform
echo ""
echo "Initializing Terraform..."
terraform init

# Plan deployment
echo ""
echo "Planning deployment..."
terraform plan -out=tfplan

# Apply deployment
echo ""
echo "Deploying infrastructure..."
terraform apply tfplan

# Get outputs
echo ""
echo "=== Deployment Complete ==="
echo ""
terraform output deployment_summary

# Save credentials
echo ""
echo "Saving deployment information..."
cat > ../azure-deployment-info.txt <<EOF
CloudOptima AI - Azure Deployment Information
==============================================

Subscription ID: $SUBSCRIPTION_ID
Resource Group: $(terraform output -raw resource_group_name)
Location: eastus

Service Principal:
  Name: $SP_NAME
  Tenant ID: $AZURE_TENANT_ID
  Client ID: $AZURE_CLIENT_ID
  Client Secret: $AZURE_CLIENT_SECRET

Access URLs:
  Frontend: $(terraform output -raw frontend_url)
  Backend: $(terraform output -raw backend_url)
  API Docs: $(terraform output -raw backend_api_docs)

Container Registry:
  Name: $(terraform output -raw acr_name)
  Login Server: $(terraform output -raw acr_login_server)

Database:
  Host: $(terraform output -raw postgres_host)
  Database: $(terraform output -raw postgres_database)
  Username: $(terraform output -raw postgres_user)

Deployment Date: $(date)

Next Steps:
1. Build and push Docker images to ACR
2. Initialize database with TimescaleDB extension
3. Create admin user via API
4. Trigger initial cost data ingestion

View sensitive outputs:
  terraform output postgres_password
  terraform output redis_primary_key
  terraform output acr_admin_password
EOF

echo "✅ Deployment information saved to: azure-deployment-info.txt"
echo ""

# Build and push images
echo "=== Next: Build and Push Docker Images ==="
echo ""
echo "Run these commands to build and push your Docker images:"
echo ""
echo "  cd .."
echo "  ACR_NAME=\$(cd terraform && terraform output -raw acr_name)"
echo "  az acr login --name \$ACR_NAME"
echo ""
echo "  # Build and push backend"
echo "  docker build -f docker/Dockerfile.backend -t \$ACR_NAME.azurecr.io/cloudoptima-backend:latest ."
echo "  docker push \$ACR_NAME.azurecr.io/cloudoptima-backend:latest"
echo ""
echo "  # Build and push frontend"
echo "  docker build -f docker/Dockerfile.frontend -t \$ACR_NAME.azurecr.io/cloudoptima-frontend:latest ."
echo "  docker push \$ACR_NAME.azurecr.io/cloudoptima-frontend:latest"
echo ""
echo "  # Restart containers"
echo "  az container restart --resource-group cloudoptima-rg --name cloudoptima-backend"
echo "  az container restart --resource-group cloudoptima-rg --name cloudoptima-frontend"
echo "  az container restart --resource-group cloudoptima-rg --name cloudoptima-celery-worker"
echo "  az container restart --resource-group cloudoptima-rg --name cloudoptima-celery-beat"
echo ""
