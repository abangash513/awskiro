# CloudOptima AI - Deploy to Azure VM
# This script deploys the application to the Azure VM

param(
    [string]$VMName = "cloudoptima-vm",
    [string]$ResourceGroup = "cloudoptima-rg"
)

Write-Host "=== CloudOptima AI - VM Deployment ===" -ForegroundColor Cyan
Write-Host ""

# Get VM details
Write-Host "Getting VM details..." -ForegroundColor Yellow
$vmInfo = az vm show --name $VMName --resource-group $ResourceGroup | ConvertFrom-Json
$vmFqdn = az vm show --name $VMName --resource-group $ResourceGroup --show-details --query "fqdns" -o tsv

Write-Host "✅ VM: $vmFqdn" -ForegroundColor Green
Write-Host ""

# Create deployment package
Write-Host "Creating deployment package..." -ForegroundColor Yellow

# Create a temporary directory for deployment files
$tempDir = New-Item -ItemType Directory -Path "$env:TEMP\cloudoptima-deploy-$(Get-Date -Format 'yyyyMMddHHmmss')" -Force

# Copy necessary files
$filesToCopy = @(
    "app",
    "docker",
    "docker-compose.yml",
    ".env.example",
    "requirements.txt",
    "alembic"
)

foreach ($file in $filesToCopy) {
    if (Test-Path $file) {
        Copy-Item -Path $file -Destination $tempDir -Recurse -Force
    }
}

# Create .env file with actual values
$envContent = @"
# CloudOptima AI - Environment Variables

# Azure Authentication
AZURE_TENANT_ID=d2449d27-d175-4648-90c3-04288acd1837
AZURE_CLIENT_ID=b3aa0768-ba45-4fb8-bae9-e5af46a60d35
AZURE_CLIENT_SECRET=ZmA8Q~PjdbSYKOs7rGjgzSwOKwuEfu0DBH_Gnbb-
AZURE_SUBSCRIPTION_ID=3a6cc9a1-adf7-49fe-a02f-f6db16ced2a1

# Database (using Docker Compose PostgreSQL)
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
SECRET_KEY=$(openssl rand -hex 32)
API_KEY=co_$(openssl rand -hex 16)
AUTH_ENABLED=false
CORS_ORIGINS=["http://localhost:3000","http://$vmFqdn:3000","http://$vmFqdn:8000"]

# Cost Analysis Settings
COST_LOOKBACK_DAYS=30
BUDGET_ALERT_THRESHOLD=0.8

# Logging
LOG_LEVEL=INFO
"@

Set-Content -Path "$tempDir\.env" -Value $envContent

Write-Host "✅ Deployment package created" -ForegroundColor Green
Write-Host ""

# Create deployment script for VM
$vmDeployScript = @'
#!/bin/bash
set -e

echo "=== CloudOptima AI - VM Setup ==="
echo ""

# Navigate to app directory
cd /opt/cloudoptima

# Stop existing containers
echo "Stopping existing containers..."
docker-compose down || true

# Pull latest images
echo "Pulling Docker images..."
docker-compose pull || true

# Build images
echo "Building Docker images..."
docker-compose build

# Start services
echo "Starting services..."
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 10

# Check status
echo ""
echo "=== Service Status ==="
docker-compose ps

# Check backend health
echo ""
echo "=== Health Check ==="
curl -f http://localhost:8000/health || echo "Backend not ready yet"

echo ""
echo "=== Deployment Complete ==="
echo "Frontend: http://$(hostname -f):3000"
echo "Backend: http://$(hostname -f):8000"
echo "API Docs: http://$(hostname -f):8000/docs"
echo ""
echo "View logs: docker-compose logs -f"
'@

Set-Content -Path "$tempDir\deploy.sh" -Value $vmDeployScript

Write-Host "Uploading files to VM..." -ForegroundColor Yellow

# Create tarball
$tarballPath = "$env:TEMP\cloudoptima-deploy.tar.gz"
tar -czf $tarballPath -C $tempDir .

Write-Host "✅ Created tarball: $tarballPath" -ForegroundColor Green

# Upload tarball to VM using Azure CLI
Write-Host "Uploading to VM..." -ForegroundColor Yellow

# Create directory on VM
az vm run-command invoke `
    --resource-group $ResourceGroup `
    --name $VMName `
    --command-id RunShellScript `
    --scripts "sudo mkdir -p /opt/cloudoptima && sudo chown azureuser:azureuser /opt/cloudoptima"

# Convert tarball to base64 and upload in chunks
$tarballBytes = [System.IO.File]::ReadAllBytes($tarballPath)
$tarballBase64 = [Convert]::ToBase64String($tarballBytes)

# Upload in chunks (Azure run-command has size limits)
$chunkSize = 50000
$chunks = [Math]::Ceiling($tarballBase64.Length / $chunkSize)

Write-Host "Uploading in $chunks chunks..." -ForegroundColor Yellow

for ($i = 0; $i -lt $chunks; $i++) {
    $start = $i * $chunkSize
    $length = [Math]::Min($chunkSize, $tarballBase64.Length - $start)
    $chunk = $tarballBase64.Substring($start, $length)
    
    $script = if ($i -eq 0) {
        "echo '$chunk' > /tmp/cloudoptima.tar.gz.b64"
    } else {
        "echo '$chunk' >> /tmp/cloudoptima.tar.gz.b64"
    }
    
    az vm run-command invoke `
        --resource-group $ResourceGroup `
        --name $VMName `
        --command-id RunShellScript `
        --scripts $script | Out-Null
    
    Write-Host "  Chunk $($i + 1)/$chunks uploaded" -ForegroundColor Gray
}

Write-Host "✅ Files uploaded" -ForegroundColor Green
Write-Host ""

# Extract and deploy on VM
Write-Host "Extracting and deploying on VM..." -ForegroundColor Yellow

$deployScript = @"
cd /tmp
base64 -d /tmp/cloudoptima.tar.gz.b64 > /tmp/cloudoptima.tar.gz
cd /opt/cloudoptima
tar -xzf /tmp/cloudoptima.tar.gz
chmod +x deploy.sh
./deploy.sh
"@

$result = az vm run-command invoke `
    --resource-group $ResourceGroup `
    --name $VMName `
    --command-id RunShellScript `
    --scripts $deployScript | ConvertFrom-Json

Write-Host ""
Write-Host "=== Deployment Output ===" -ForegroundColor Cyan
$result.value[0].message
Write-Host ""

# Cleanup
Remove-Item -Path $tempDir -Recurse -Force
Remove-Item -Path $tarballPath -Force

Write-Host "=== Deployment Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Access URLs:" -ForegroundColor Cyan
Write-Host "  Frontend:  http://$vmFqdn:3000" -ForegroundColor White
Write-Host "  Backend:   http://$vmFqdn:8000" -ForegroundColor White
Write-Host "  API Docs:  http://$vmFqdn:8000/docs" -ForegroundColor White
Write-Host ""
Write-Host "Check logs:" -ForegroundColor Cyan
Write-Host "  az vm run-command invoke --resource-group $ResourceGroup --name $VMName --command-id RunShellScript --scripts 'cd /opt/cloudoptima && docker-compose logs -f backend'" -ForegroundColor Gray
Write-Host ""
