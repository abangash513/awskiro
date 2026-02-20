# Simple deployment: Replace main.py and redeploy

$VM_IP = "52.179.209.239"
$VM_USER = "azureuser"
$VM_PASS = "zJsjfxP80cmn!WeU"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "CloudOptima AI - Simple Fix Deployment" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Step 1: Replace main.py with fixed version
Write-Host ""
Write-Host "Step 1: Replacing main.py with fixed version..." -ForegroundColor Yellow
Copy-Item "backend-main-fixed.py" "backend/app/main.py" -Force
Write-Host "✓ main.py replaced" -ForegroundColor Green

# Step 2: Create deployment package
Write-Host ""
Write-Host "Step 2: Creating deployment package..." -ForegroundColor Yellow
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$packageName = "cloudoptima-simple-fix-$timestamp.tar.gz"

wsl bash -c "tar -czf $packageName backend/app/main.py backend/app/models/ --exclude='**/__pycache__' --exclude='**/*.pyc'"
Write-Host "✓ Created package: $packageName" -ForegroundColor Green

# Step 3: Copy to VM
Write-Host ""
Write-Host "Step 3: Copying to VM..." -ForegroundColor Yellow
wsl bash -c "sshpass -p '$VM_PASS' scp -o StrictHostKeyChecking=no $packageName ${VM_USER}@${VM_IP}:/tmp/"
Write-Host "✓ Package copied to VM" -ForegroundColor Green

# Step 4: Deploy on VM
Write-Host ""
Write-Host "Step 4: Deploying on VM..." -ForegroundColor Yellow

# Create a temporary script file
$deployScript = @"
set -e
cd /opt/cloudoptima

echo 'Extracting package...'
tar -xzf /tmp/cloudoptima-simple-fix-*.tar.gz

echo 'Stopping backend...'
docker-compose stop backend

echo 'Removing old backend image...'
docker rmi cloudoptima-backend:latest || true

echo 'Rebuilding backend...'
docker-compose build --no-cache backend

echo 'Starting backend...'
docker-compose up -d backend

echo 'Waiting for backend to start...'
sleep 15

echo 'Checking backend status...'
docker-compose ps backend

echo 'Backend logs:'
docker-compose logs --tail=100 backend

echo ''
echo 'Deployment complete!'
"@

$deployScript | Out-File -FilePath "deploy-temp.sh" -Encoding ASCII
wsl bash -c "sshpass -p '$VM_PASS' scp -o StrictHostKeyChecking=no deploy-temp.sh ${VM_USER}@${VM_IP}:/tmp/"
wsl bash -c "sshpass -p '$VM_PASS' ssh -o StrictHostKeyChecking=no ${VM_USER}@${VM_IP} 'bash /tmp/deploy-temp.sh'"
Remove-Item "deploy-temp.sh" -Force

# Step 5: Verify deployment
Write-Host ""
Write-Host "Step 5: Verifying deployment..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

try {
    $response = Invoke-RestMethod -Uri "http://${VM_IP}:8000/health" -TimeoutSec 10
    Write-Host "✓ Backend is healthy!" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Gray
} catch {
    Write-Host "⚠ Backend health check failed: $_" -ForegroundColor Yellow
    Write-Host "Checking logs..." -ForegroundColor Yellow
    $logCmd = "docker-compose -f /opt/cloudoptima/docker-compose.yml logs --tail=100 backend"
    wsl bash -c "sshpass -p '$VM_PASS' ssh -o StrictHostKeyChecking=no ${VM_USER}@${VM_IP} '$logCmd'"
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
Write-Host "Changes made:"
Write-Host "  - Simplified main.py to only load Cost and Recommendation routes"
Write-Host "  - Removed dependencies on Organization, CloudConnection, AIWorkload models"
Write-Host "  - Database will only create tables without foreign key dependencies"
Write-Host "==========================================" -ForegroundColor Cyan
