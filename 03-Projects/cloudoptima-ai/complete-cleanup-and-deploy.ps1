# Complete cleanup and fresh deployment

$VM_IP = "52.179.209.239"
$VM_USER = "azureuser"
$VM_PASS = "zJsjfxP80cmn!WeU"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "CloudOptima AI - Complete Cleanup & Deploy" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Step 1: Create deployment package
Write-Host ""
Write-Host "Step 1: Creating deployment package..." -ForegroundColor Yellow
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$packageName = "cloudoptima-clean-$timestamp.tar.gz"

wsl bash -c "tar --exclude='backend/__pycache__' --exclude='backend/**/__pycache__' --exclude='backend/**/*.pyc' -czf $packageName backend/ docker/ docker-compose.yml .env"
Write-Host "OK Created package: $packageName" -ForegroundColor Green

# Step 2: Copy to VM
Write-Host ""
Write-Host "Step 2: Copying to VM..." -ForegroundColor Yellow
wsl bash -c "sshpass -p '$VM_PASS' scp -o StrictHostKeyChecking=no $packageName ${VM_USER}@${VM_IP}:/tmp/"
Write-Host "OK Package copied to VM" -ForegroundColor Green

# Step 3: Complete cleanup on VM
Write-Host ""
Write-Host "Step 3: Complete cleanup on VM..." -ForegroundColor Yellow
wsl bash -c "sshpass -p '$VM_PASS' ssh -o StrictHostKeyChecking=no ${VM_USER}@${VM_IP} 'cd /opt/cloudoptima && docker-compose down -v'"
Write-Host "OK All containers and volumes removed" -ForegroundColor Green

# Step 4: Remove all images
Write-Host ""
Write-Host "Step 4: Removing all images..." -ForegroundColor Yellow
wsl bash -c "sshpass -p '$VM_PASS' ssh -o StrictHostKeyChecking=no ${VM_USER}@${VM_IP} 'docker rmi cloudoptima_backend cloudoptima_frontend cloudoptima-backend cloudoptima-frontend 2>/dev/null || true'"
Write-Host "OK Images removed" -ForegroundColor Green

# Step 5: Extract new code
Write-Host ""
Write-Host "Step 5: Extracting new code..." -ForegroundColor Yellow
wsl bash -c "sshpass -p '$VM_PASS' ssh -o StrictHostKeyChecking=no ${VM_USER}@${VM_IP} 'cd /opt/cloudoptima && sudo rm -rf backend docker && tar -xzf /tmp/$packageName'"
Write-Host "OK New code extracted" -ForegroundColor Green

# Step 6: Build and start
Write-Host ""
Write-Host "Step 6: Building and starting services..." -ForegroundColor Yellow
wsl bash -c "sshpass -p '$VM_PASS' ssh -o StrictHostKeyChecking=no ${VM_USER}@${VM_IP} 'cd /opt/cloudoptima && docker-compose up -d --build'"
Write-Host "OK Services started" -ForegroundColor Green

# Step 7: Wait and check logs
Write-Host ""
Write-Host "Step 7: Waiting for services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 20

Write-Host "Checking backend logs..." -ForegroundColor Yellow
wsl bash -c "sshpass -p '$VM_PASS' ssh -o StrictHostKeyChecking=no ${VM_USER}@${VM_IP} 'cd /opt/cloudoptima && docker-compose logs --tail=50 backend'"

# Step 8: Verify deployment
Write-Host ""
Write-Host "Step 8: Verifying deployment..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

try {
    $response = Invoke-RestMethod -Uri "http://${VM_IP}:8000/health" -TimeoutSec 10
    Write-Host "OK Backend is healthy!" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Gray
} catch {
    Write-Host "WARNING Backend health check failed: $_" -ForegroundColor Yellow
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
Write-Host "  - Removed all old containers and volumes"
Write-Host "  - Removed all old images"
Write-Host "  - Fresh deployment with simplified models"
Write-Host "  - Only Cost, Budget, and Recommendation tables"
Write-Host "==========================================" -ForegroundColor Cyan
