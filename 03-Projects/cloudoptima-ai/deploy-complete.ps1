# CloudOptima AI - Complete Automated Deployment Script
# This script handles everything from prerequisites to full deployment

param(
    [string]$SubscriptionId = "3a6cc9a1-adf7-49fe-a02f-f6db16ced2a1",
    [switch]$SkipDocker
)

Write-Host "=== CloudOptima AI - Complete Deployment ===" -ForegroundColor Cyan
Write-Host ""

# Check Azure CLI
Write-Host "Checking Azure CLI..." -ForegroundColor Yellow
try {
    $azVersion = az --version 2>$null
    Write-Host "✅ Azure CLI is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Azure CLI is not installed" -ForegroundColor Red
    Write-Host "Installing Azure CLI..." -ForegroundColor Yellow
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
    Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'
    Remove-Item .\AzureCLI.msi
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-Host "✅ Azure CLI installed" -ForegroundColor Green
}

# Check Terraform
Write-Host "Checking Terraform..." -ForegroundColor Yellow
try {
    $tfVersion = terraform --version 2>$null
    Write-Host "✅ Terraform is installed" -ForegroundColor Green
} catch {
    Write-Host "❌ Terraform is not installed" -ForegroundColor Red
    Write-Host "Please install Terraform from: https://www.terraform.io/downloads" -ForegroundColor Yellow
    exit 1
}

# Check Docker
if (-not $SkipDocker) {
    Write-Host "Checking Docker..." -ForegroundColor Yellow
    try {
        $dockerVersion = docker --version 2>$null
        Write-Host "✅ Docker is installed" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Docker is not installed" -ForegroundColor Yellow
        Write-Host "Docker is required to build and push container images." -ForegroundColor Yellow
        Write-Host "Download from: https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
        Write-Host ""
        $continue = Read-Host "Continue without Docker? (Infrastructure will be deployed but containers won't have images) [y/N]"
        if ($continue -ne "y") {
            exit 1
        }
        $SkipDocker = $true
    }
}

Write-Host ""
Write-Host "=== Azure Login ===" -ForegroundColor Cyan

# Check if already logged in
$currentAccount = az account show 2>$null | ConvertFrom-Json
if ($currentAccount) {
    Write-Host "✅ Already logged in to Azure" -ForegroundColor Green
    Write-Host "Account: $($currentAccount.user.name)" -ForegroundColor Gray
    Write-Host "Subscription: $($currentAccount.name)" -ForegroundColor Gray
} else {
    Write-Host "Logging in to Azure..." -ForegroundColor Yellow
    az login
}

# Set subscription
Write-Host ""
Write-Host "Setting subscription..." -ForegroundColor Yellow
az account set --subscription $SubscriptionId
$sub = az account show | ConvertFrom-Json
Write-Host "✅ Using subscription: $($sub.name)" -ForegroundColor Green

Write-Host ""
Write-Host "=== Creating Service Principal ===" -ForegroundColor Cyan

# Check if service principal already exists
$spName = "cloudoptima-reader"
$existingSp = az ad sp list --display-name $spName 2>$null | ConvertFrom-Json

if ($existingSp -and $existingSp.Count -gt 0) {
    Write-Host "⚠️  Service Principal '$spName' already exists" -ForegroundColor Yellow
    $useExisting = Read-Host "Use existing Service Principal? [Y/n]"
    if ($useExisting -eq "" -or $useExisting -eq "y" -or $useExisting -eq "Y") {
        $azureTenantId = $sub.tenantId
        $azureClientId = $existingSp[0].appId
        Write-Host "✅ Using existing Service Principal" -ForegroundColor Green
        Write-Host "⚠️  You'll need to provide the client secret manually in terraform.tfvars" -ForegroundColor Yellow
        $azureClientSecret = Read-Host "Enter the client secret for existing Service Principal" -AsSecureString
        $azureClientSecret = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($azureClientSecret))
    } else {
        # Delete and recreate
        Write-Host "Deleting existing Service Principal..." -ForegroundColor Yellow
        az ad sp delete --id $existingSp[0].appId
        $existingSp = $null
    }
}

if (-not $existingSp -or $existingSp.Count -eq 0) {
    Write-Host "Creating new Service Principal..." -ForegroundColor Yellow
    $sp = az ad sp create-for-rbac `
        --name $spName `
        --role "Cost Management Reader" `
        --scopes "/subscriptions/$SubscriptionId" `
        --output json | ConvertFrom-Json

    $azureTenantId = $sp.tenant
    $azureClientId = $sp.appId
    $azureClientSecret = $sp.password

    Write-Host "✅ Service Principal created" -ForegroundColor Green
    Write-Host "Tenant ID: $azureTenantId" -ForegroundColor Gray
    Write-Host "Client ID: $azureClientId" -ForegroundColor Gray
}

Write-Host ""
Write-Host "=== Configuring Terraform ===" -ForegroundColor Cyan

Set-Location terraform

if (Test-Path terraform.tfvars) {
    Write-Host "⚠️  terraform.tfvars already exists" -ForegroundColor Yellow
    $overwrite = Read-Host "Overwrite? [y/N]"
    if ($overwrite -ne "y") {
        Write-Host "Using existing terraform.tfvars" -ForegroundColor Yellow
    } else {
        Remove-Item terraform.tfvars
    }
}

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

azure_tenant_id     = "$azureTenantId"
azure_client_id     = "$azureClientId"
azure_client_secret = "$azureClientSecret"

tags = {
  Environment = "Production"
  Project     = "CloudOptima AI"
  ManagedBy   = "Terraform"
}
"@
    
    Set-Content -Path terraform.tfvars -Value $tfvarsContent
    Write-Host "✅ terraform.tfvars created" -ForegroundColor Green
}

Write-Host ""
Write-Host "=== Deploying Infrastructure ===" -ForegroundColor Cyan

# Initialize Terraform
Write-Host "Initializing Terraform..." -ForegroundColor Yellow
terraform init

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform initialization failed" -ForegroundColor Red
    exit 1
}

# Plan
Write-Host ""
Write-Host "Planning deployment..." -ForegroundColor Yellow
terraform plan -out=tfplan

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform plan failed" -ForegroundColor Red
    exit 1
}

# Apply
Write-Host ""
Write-Host "Applying deployment..." -ForegroundColor Yellow
Write-Host "This will create Azure resources and may take 10-15 minutes..." -ForegroundColor Gray
terraform apply tfplan

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Terraform apply failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Infrastructure deployed successfully!" -ForegroundColor Green

# Get outputs
Write-Host ""
Write-Host "=== Deployment Information ===" -ForegroundColor Cyan
terraform output deployment_summary

# Save outputs to file
terraform output > ..\terraform-outputs.txt
Write-Host ""
Write-Host "✅ Outputs saved to terraform-outputs.txt" -ForegroundColor Green

if (-not $SkipDocker) {
    Write-Host ""
    Write-Host "=== Building and Pushing Docker Images ===" -ForegroundColor Cyan
    
    Set-Location ..
    
    Push-Location terraform
    $acrName = terraform output -raw acr_name
    Pop-Location
    
    Write-Host "Logging in to Azure Container Registry..." -ForegroundColor Yellow
    az acr login --name $acrName
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ ACR login failed" -ForegroundColor Red
        exit 1
    }
    
    # Build and push backend
    Write-Host ""
    Write-Host "Building backend image..." -ForegroundColor Yellow
    docker build -f docker\Dockerfile.backend -t "${acrName}.azurecr.io/cloudoptima-backend:latest" .
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Backend image build failed" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Pushing backend image..." -ForegroundColor Yellow
    docker push "${acrName}.azurecr.io/cloudoptima-backend:latest"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Backend image push failed" -ForegroundColor Red
        exit 1
    }
    
    # Build and push frontend
    Write-Host ""
    Write-Host "Building frontend image..." -ForegroundColor Yellow
    docker build -f docker\Dockerfile.frontend -t "${acrName}.azurecr.io/cloudoptima-frontend:latest" .
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Frontend image build failed" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Pushing frontend image..." -ForegroundColor Yellow
    docker push "${acrName}.azurecr.io/cloudoptima-frontend:latest"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Frontend image push failed" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "✅ Docker images built and pushed successfully!" -ForegroundColor Green
    
    # Restart containers
    Write-Host ""
    Write-Host "=== Restarting Container Instances ===" -ForegroundColor Cyan
    
    Write-Host "Restarting backend..." -ForegroundColor Yellow
    az container restart --resource-group cloudoptima-rg --name cloudoptima-backend
    
    Write-Host "Restarting frontend..." -ForegroundColor Yellow
    az container restart --resource-group cloudoptima-rg --name cloudoptima-frontend
    
    Write-Host "Restarting celery-worker..." -ForegroundColor Yellow
    az container restart --resource-group cloudoptima-rg --name cloudoptima-celery-worker
    
    Write-Host "Restarting celery-beat..." -ForegroundColor Yellow
    az container restart --resource-group cloudoptima-rg --name cloudoptima-celery-beat
    
    Write-Host ""
    Write-Host "✅ All containers restarted!" -ForegroundColor Green
    
    # Check status
    Write-Host ""
    Write-Host "Container status:" -ForegroundColor Cyan
    az container list --resource-group cloudoptima-rg --output table
}

Write-Host ""
Write-Host "=== Deployment Complete! ===" -ForegroundColor Green
Write-Host ""

Push-Location terraform
$frontendUrl = terraform output -raw frontend_url
$backendUrl = terraform output -raw backend_url
$apiDocsUrl = terraform output -raw backend_api_docs
Pop-Location

Write-Host "Access URLs:" -ForegroundColor Cyan
Write-Host "  Frontend:  $frontendUrl" -ForegroundColor White
Write-Host "  Backend:   $backendUrl" -ForegroundColor White
Write-Host "  API Docs:  $apiDocsUrl" -ForegroundColor White
Write-Host ""

if ($SkipDocker) {
    Write-Host "⚠️  Docker images were not built. You need to:" -ForegroundColor Yellow
    Write-Host "  1. Install Docker Desktop" -ForegroundColor Yellow
    Write-Host "  2. Run: .\deploy-complete.ps1 -SubscriptionId $SubscriptionId" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Initialize database with TimescaleDB (see WINDOWS-DEPLOYMENT-STEPS.md)" -ForegroundColor White
Write-Host "  2. Open $frontendUrl in your browser" -ForegroundColor White
Write-Host "  3. Register a new admin account" -ForegroundColor White
Write-Host "  4. Connect your Azure subscription" -ForegroundColor White
Write-Host ""

Write-Host "For detailed instructions, see: WINDOWS-DEPLOYMENT-STEPS.md" -ForegroundColor Gray
Write-Host ""
