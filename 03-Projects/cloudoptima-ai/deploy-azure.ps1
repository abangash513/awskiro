# CloudOptima AI - Azure Deployment Script (Windows)
# This script automates the deployment to Azure using Terraform

Write-Host "=== CloudOptima AI - Azure Deployment ===" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

$azInstalled = Get-Command az -ErrorAction SilentlyContinue
if (-not $azInstalled) {
    Write-Host "❌ Azure CLI is not installed. Please install it first." -ForegroundColor Red
    Write-Host "   Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Yellow
    exit 1
}

$terraformInstalled = Get-Command terraform -ErrorAction SilentlyContinue
if (-not $terraformInstalled) {
    Write-Host "❌ Terraform is not installed. Please install it first." -ForegroundColor Red
    Write-Host "   Visit: https://www.terraform.io/downloads" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Azure CLI and Terraform are installed" -ForegroundColor Green
Write-Host ""

# Login to Azure
Write-Host "Logging in to Azure..." -ForegroundColor Yellow
az login

# Select subscription
Write-Host ""
Write-Host "Available subscriptions:" -ForegroundColor Cyan
az account list --output table

Write-Host ""
$SubscriptionId = Read-Host "Enter subscription ID to use"
az account set --subscription $SubscriptionId

$SubName = az account show --query name -o tsv
Write-Host "✅ Using subscription: $SubName" -ForegroundColor Green
Write-Host ""

# Get Azure credentials for service principal
Write-Host "Creating Azure Service Principal for Cost Management API..." -ForegroundColor Yellow
Write-Host ""
$SpName = Read-Host "Enter a name for the service principal [cloudoptima-reader]"
if ([string]::IsNullOrWhiteSpace($SpName)) {
    $SpName = "cloudoptima-reader"
}

# Create service principal
$SpOutput = az ad sp create-for-rbac `
  --name $SpName `
  --role "Cost Management Reader" `
  --scopes "/subscriptions/$SubscriptionId" `
  --output json | ConvertFrom-Json

$AzureTenantId = $SpOutput.tenant
$AzureClientId = $SpOutput.appId
$AzureClientSecret = $SpOutput.password

Write-Host "✅ Service Principal created" -ForegroundColor Green
Write-Host ""

# Navigate to terraform directory
Set-Location terraform

# Create terraform.tfvars if it doesn't exist
if (-not (Test-Path terraform.tfvars)) {
    Write-Host "Creating terraform.tfvars..." -ForegroundColor Yellow
    
    $tfvarsContent = @"
# CloudOptima AI - Terraform Variables

prefix              = "cloudoptima"
resource_group_name = "cloudoptima-rg"
location            = "eastus"

db_admin_username = "cloudoptima"
db_name           = "cloudoptima"
db_sku_name       = "B_Standard_B2s"

azure_tenant_id     = "$AzureTenantId"
azure_client_id     = "$AzureClientId"
azure_client_secret = "$AzureClientSecret"

tags = {
  Environment = "Production"
  Project     = "CloudOptima AI"
  ManagedBy   = "Terraform"
}
"@
    
    Set-Content -Path terraform.tfvars -Value $tfvarsContent
    Write-Host "✅ terraform.tfvars created" -ForegroundColor Green
} else {
    Write-Host "⚠️  terraform.tfvars already exists, skipping creation" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  Subscription: $SubName"
Write-Host "  Location: eastus"
Write-Host "  Service Principal: $SpName"
Write-Host ""

$Confirm = Read-Host "Proceed with deployment? (y/n)"
if ($Confirm -ne "y") {
    Write-Host "Deployment cancelled." -ForegroundColor Yellow
    exit 0
}

# Initialize Terraform
Write-Host ""
Write-Host "Initializing Terraform..." -ForegroundColor Yellow
terraform init

# Plan deployment
Write-Host ""
Write-Host "Planning deployment..." -ForegroundColor Yellow
terraform plan -out=tfplan

# Apply deployment
Write-Host ""
Write-Host "Deploying infrastructure..." -ForegroundColor Yellow
terraform apply tfplan

# Get outputs
Write-Host ""
Write-Host "=== Deployment Complete ===" -ForegroundColor Green
Write-Host ""
terraform output deployment_summary

# Save credentials
Write-Host ""
Write-Host "Saving deployment information..." -ForegroundColor Yellow

$ResourceGroupName = terraform output -raw resource_group_name
$FrontendUrl = terraform output -raw frontend_url
$BackendUrl = terraform output -raw backend_url
$ApiDocsUrl = terraform output -raw backend_api_docs
$AcrName = terraform output -raw acr_name
$AcrLoginServer = terraform output -raw acr_login_server
$PostgresHost = terraform output -raw postgres_host
$PostgresDatabase = terraform output -raw postgres_database
$PostgresUser = terraform output -raw postgres_user

$deploymentInfo = @"
CloudOptima AI - Azure Deployment Information
==============================================

Subscription ID: $SubscriptionId
Resource Group: $ResourceGroupName
Location: eastus

Service Principal:
  Name: $SpName
  Tenant ID: $AzureTenantId
  Client ID: $AzureClientId
  Client Secret: $AzureClientSecret

Access URLs:
  Frontend: $FrontendUrl
  Backend: $BackendUrl
  API Docs: $ApiDocsUrl

Container Registry:
  Name: $AcrName
  Login Server: $AcrLoginServer

Database:
  Host: $PostgresHost
  Database: $PostgresDatabase
  Username: $PostgresUser

Deployment Date: $(Get-Date)

Next Steps:
1. Build and push Docker images to ACR
2. Initialize database with TimescaleDB extension
3. Create admin user via API
4. Trigger initial cost data ingestion

View sensitive outputs:
  terraform output postgres_password
  terraform output redis_primary_key
  terraform output acr_admin_password
"@

Set-Content -Path ..\azure-deployment-info.txt -Value $deploymentInfo

Write-Host "✅ Deployment information saved to: azure-deployment-info.txt" -ForegroundColor Green
Write-Host ""

# Build and push images
Write-Host "=== Next: Build and Push Docker Images ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Run these commands to build and push your Docker images:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  cd .."
Write-Host "  `$AcrName = (cd terraform; terraform output -raw acr_name)"
Write-Host "  az acr login --name `$AcrName"
Write-Host ""
Write-Host "  # Build and push backend"
Write-Host "  docker build -f docker/Dockerfile.backend -t `${AcrName}.azurecr.io/cloudoptima-backend:latest ."
Write-Host "  docker push `${AcrName}.azurecr.io/cloudoptima-backend:latest"
Write-Host ""
Write-Host "  # Build and push frontend"
Write-Host "  docker build -f docker/Dockerfile.frontend -t `${AcrName}.azurecr.io/cloudoptima-frontend:latest ."
Write-Host "  docker push `${AcrName}.azurecr.io/cloudoptima-frontend:latest"
Write-Host ""
Write-Host "  # Restart containers"
Write-Host "  az container restart --resource-group cloudoptima-rg --name cloudoptima-backend"
Write-Host "  az container restart --resource-group cloudoptima-rg --name cloudoptima-frontend"
Write-Host "  az container restart --resource-group cloudoptima-rg --name cloudoptima-celery-worker"
Write-Host "  az container restart --resource-group cloudoptima-rg --name cloudoptima-celery-beat"
Write-Host ""
