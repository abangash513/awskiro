# Complete deployment script for Windows: test, fix, package, and deploy via WSL

$VM_IP = "52.179.209.239"
$VM_USER = "azureuser"
$VM_PASS = "zJsjfxP80cmn!WeU"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "CloudOptima AI - Complete Deployment" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Step 1: Test models locally
Write-Host ""
Write-Host "Step 1: Testing models locally..." -ForegroundColor Yellow
Write-Host "----------------------------------------"
python test_models_standalone.py
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Model tests failed. Aborting deployment." -ForegroundColor Red
    exit 1
}
Write-Host "✓ Model tests passed" -ForegroundColor Green

# Step 2: Fix backend imports using WSL
Write-Host ""
Write-Host "Step 2: Fixing backend imports..." -ForegroundColor Yellow
Write-Host "----------------------------------------"
wsl bash fix-backend-models.sh
if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to fix backend imports" -ForegroundColor Red
    exit 1
}

# Step 3: Create deployment package using WSL
Write-Host ""
Write-Host "Step 3: Creating deployment package..." -ForegroundColor Yellow
Write-Host "----------------------------------------"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$packageName = "cloudoptima-fixed-$timestamp.tar.gz"

wsl bash -c "tar -czf $packageName backend/ docker/ docker-compose.yml .env --exclude='backend/__pycache__' --exclude='backend/**/__pycache__' --exclude='backend/**/*.pyc'"
Write-Host "✓ Created package: $packageName" -ForegroundColor Green

# Step 4: Copy to VM using WSL
Write-Host ""
Write-Host "Step 4: Copying to VM..." -ForegroundColor Yellow
Write-Host "----------------------------------------"
wsl bash -c "sshpass -p '$VM_PASS' scp -o StrictHostKeyChecking=no $packageName ${VM_USER}@${VM_IP}:/tmp/"
Write-Host "✓ Package copied to VM" -ForegroundColor Green

# Step 5: Deploy on VM using WSL
Write-Host ""
Write-Host "Step 5: Deploying on VM..." -ForegroundColor Yellow
Write-Host "----------------------------------------"

$deployScript = @'
set -e
echo "Extracting package..."
cd /opt/cloudoptima
tar -xzf /tmp/cloudoptima-fixed-*.tar.gz

echo "Stopping containers..."
docker-compose down

echo "Removing old backend image..."
docker rmi cloudoptima-backend:latest || true

echo "Rebuilding backend..."
docker-compose build --no-cache backend

echo "Starting services..."
docker-compose up -d

echo "Waiting for services to start..."
sleep 10

echo "Checking backend status..."
docker-compose ps backend
docker-compose logs --tail=50 backend

echo ""
echo "✓ Deployment complete!"
'@

wsl bash -c "sshpass -p '$VM_PASS' ssh -o StrictHostKeyChecking=no ${VM_USER}@${VM_IP} '$deployScript'"

# Step 6: Verify deployment
Write-Host ""
Write-Host "Step 6: Verifying deployment..." -ForegroundColor Yellow
Write-Host "----------------------------------------"
Start-Sleep -Seconds 5

try {
    $response = Invoke-WebRequest -Uri "http://${VM_IP}:8000/health" -TimeoutSec 10
    if ($response.Content -match "healthy") {
        Write-Host "✓ Backend is healthy!" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠ Backend health check failed. Checking logs..." -ForegroundColor Yellow
    wsl bash -c "sshpass -p '$VM_PASS' ssh -o StrictHostKeyChecking=no ${VM_USER}@${VM_IP} 'docker-compose -f /opt/cloudoptima/docker-compose.yml logs --tail=100 backend'"
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Deployment Summary" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Package: $packageName"
Write-Host "VM: $VM_IP"
Write-Host "Frontend: http://${VM_IP}:3000" -ForegroundColor Green
Write-Host "Backend: http://${VM_IP}:8000" -ForegroundColor Green
Write-Host "Backend Health: http://${VM_IP}:8000/health"
Write-Host "Backend Docs: http://${VM_IP}:8000/docs"
Write-Host ""
Write-Host "To check logs:"
Write-Host "  wsl ssh ${VM_USER}@${VM_IP}"
Write-Host "  cd /opt/cloudoptima"
Write-Host "  docker-compose logs -f backend"
Write-Host "==========================================" -ForegroundColor Cyan
