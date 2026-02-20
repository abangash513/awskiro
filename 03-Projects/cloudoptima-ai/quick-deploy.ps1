# CloudOptima AI - Quick Deploy to Azure VM
# This script deploys the application using Azure run-command

param(
    [string]$VMName = "cloudoptima-vm",
    [string]$ResourceGroup = "cloudoptima-rg"
)

Write-Host "=== CloudOptima AI - Quick VM Deployment ===" -ForegroundColor Cyan
Write-Host ""

# Get VM FQDN
$vmFqdn = az vm show --name $VMName --resource-group $ResourceGroup --show-details --query "fqdns" -o tsv
Write-Host "VM: $vmFqdn" -ForegroundColor Green
Write-Host ""

# Step 1: Clone repository on VM
Write-Host "Step 1: Setting up application directory..." -ForegroundColor Yellow
$setupScript = @'
#!/bin/bash
set -e

# Create directory
sudo mkdir -p /opt/cloudoptima
sudo chown azureuser:azureuser /opt/cloudoptima
cd /opt/cloudoptima

# Install git if not present
which git || sudo apt-get install -y git

echo "Directory ready"
'@

az vm run-command invoke `
    --resource-group $ResourceGroup `
    --name $VMName `
    --command-id RunShellScript `
    --scripts $setupScript | Out-Null

Write-Host "✅ Directory created" -ForegroundColor Green
Write-Host ""

# Step 2: Create docker-compose.yml
Write-Host "Step 2: Creating docker-compose.yml..." -ForegroundColor Yellow
$dockerCompose = Get-Content "docker-compose.yml" -Raw
$createDockerCompose = @"
cat > /opt/cloudoptima/docker-compose.yml << 'EOFDC'
$dockerCompose
EOFDC
"@

az vm run-command invoke `
    --resource-group $ResourceGroup `
    --name $VMName `
    --command-id RunShellScript `
    --scripts $createDockerCompose | Out-Null

Write-Host "✅ docker-compose.yml created" -ForegroundColor Green
Write-Host ""

# Step 3: Create .env file
Write-Host "Step 3: Creating .env file..." -ForegroundColor Yellow
$envContent = @"
# CloudOptima AI - Environment Variables

# Azure Authentication
AZURE_TENANT_ID=d2449d27-d175-4648-90c3-04288acd1837
AZURE_CLIENT_ID=b3aa0768-ba45-4fb8-bae9-e5af46a60d35
AZURE_CLIENT_SECRET=ZmA8Q~PjdbSYKOs7rGjgzSwOKwuEfu0DBH_Gnbb-
AZURE_SUBSCRIPTION_ID=3a6cc9a1-adf7-49fe-a02f-f6db16ced2a1

# Database
DATABASE_URL=postgresql+asyncpg://cloudoptima:cloudoptima@db:5432/cloudoptima
POSTGRES_USER=cloudoptima
POSTGRES_PASSWORD=cloudoptima
POSTGRES_DB=cloudoptima

# Redis
REDIS_URL=redis://redis:6379/0

# API Settings
API_HOST=0.0.0.0
API_PORT=8000
API_DEBUG=false

# Authentication
SECRET_KEY=\$(openssl rand -hex 32)
API_KEY=co_\$(openssl rand -hex 16)
AUTH_ENABLED=false
CORS_ORIGINS=[\"http://localhost:3000\",\"http://$vmFqdn:3000\",\"http://$vmFqdn:8000\"]

# Cost Analysis Settings
COST_LOOKBACK_DAYS=30
BUDGET_ALERT_THRESHOLD=0.8

# Logging
LOG_LEVEL=INFO
"@

$createEnv = @"
cat > /opt/cloudoptima/.env << 'EOFENV'
$envContent
EOFENV
"@

az vm run-command invoke `
    --resource-group $ResourceGroup `
    --name $VMName `
    --command-id RunShellScript `
    --scripts $createEnv | Out-Null

Write-Host "✅ .env file created" -ForegroundColor Green
Write-Host ""

# Step 4: Copy application files
Write-Host "Step 4: Copying application files to VM..." -ForegroundColor Yellow
Write-Host "This may take a few minutes..." -ForegroundColor Gray

# We'll create the app directory structure and copy files
# For now, let's use a simpler approach - create a minimal working version

$createAppStructure = @'
#!/bin/bash
cd /opt/cloudoptima

# Create app directory structure
mkdir -p app/api/endpoints
mkdir -p app/core
mkdir -p app/models
mkdir -p app/schemas
mkdir -p app/services
mkdir -p app/static/css
mkdir -p app/static/js
mkdir -p docker
mkdir -p tests

echo "App structure created"
'@

az vm run-command invoke `
    --resource-group $ResourceGroup `
    --name $VMName `
    --command-id RunShellScript `
    --scripts $createAppStructure | Out-Null

Write-Host "✅ App structure created" -ForegroundColor Green
Write-Host ""

Write-Host "⚠️  Note: Application code needs to be copied manually" -ForegroundColor Yellow
Write-Host "The VM is ready, but you need to copy the application code." -ForegroundColor Yellow
Write-Host ""
Write-Host "Options:" -ForegroundColor Cyan
Write-Host "1. Use SCP to copy files (requires SSH key setup)" -ForegroundColor White
Write-Host "2. Clone from Git repository" -ForegroundColor White
Write-Host "3. Use Azure File Share" -ForegroundColor White
Write-Host ""

Write-Host "=== VM is Ready ===" -ForegroundColor Green
Write-Host "VM FQDN: $vmFqdn" -ForegroundColor White
Write-Host ""
