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
Write-Host "OK main.py replaced" -ForegroundColor Green

# Step 2: Create deployment package
Write-Host ""
Write-Host "Step 2: Creating deployment package..." -ForegroundColor Yellow
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$packageName = "cloudoptima-simple-fix-$timestamp.tar.gz"

wsl bash -c "tar -czf $packageName backend/app/main.py backend/app/models/ --exclude='**/__pycache__' --exclude='**/*.pyc'"
Write-Host "OK Created package: $packageName" -ForegroundColor Green

# Step 3: Copy to VM
Write-Host ""
Write-Host "Step 3: Copying to VM..." -ForegroundColor Yellow
wsl bash -c "sshpass -p '$VM_PASS' scp -o StrictHostKeyChecking=no $packageName ${VM_USER}@${VM_IP}:/tmp/"
Write-Host "OK Package copied to VM" -ForegroundColor Green

# Step 4: Extract on VM
Write-Host ""
Write-Host "Step 4: Extracting on VM..." -ForegroundColor Yellow
wsl bash -c "sshpass -p '$VM_PASS' ssh -o StrictHostKeyChecking=no ${VM_USER}@${VM_IP} 'cd /opt/cloudoptima && tar -xzf /tmp/$packageName'"
Write-Host "OK Extracted" -ForegroundColor Green

# Step 5: Stop backend
Write-Host ""
Write-Host "Step 5: Stopping backend..." -ForegroundColor Yellow
wsl bash -c "sshpass -p '$VM_PASS' ssh -o StrictHostKeyChecking=no ${VM_USER}@${VM_IP} 'cd /opt/cloudoptima && docker-compose stop backend'"
Write-Host "OK Backend stopped" -ForegroundColor Green

# Step 6: Remove old image
Write-Host ""
Write-Host "Step 6: Removing old backend image..." -ForegroundColor Yellow
wsl bash -c "sshpass -p '$VM_PASS' ssh -o StrictHostKeyChecking=no ${VM_USER}@${VM_IP} 'docker rmi cloudoptima-backend:latest 2>/dev/null || true'"
Write-Host "OK Old image removed" -ForegroundColor Green

# Step 7: Rebuild backend
Write-Host ""
Write-Host "Step 7: Rebuilding backend..." -ForegroundColor Yellow
wsl bash -c "sshpass -p '$VM_PASS' ssh -o StrictHostKeyChecking=no ${VM_USER}@${VM_IP} 'cd /opt/cloudoptima && docker-compose build --no-cache backend'"
Write-Host "OK Backend rebuilt" -ForegroundColor Green

# Step 8: Start backend
Write-Host ""
Write-Host "Step 8: Starting backend..." -ForegroundColor Yellow
wsl bash -c "sshpass -p '$VM_PASS' ssh -o StrictHostKeyChecking=no ${VM_USER}@${VM_IP} 'cd /opt/cloudoptima && docker-compose up -d backend'"
Write-Host "OK Backend started" -ForegroundColor Green

# Step 9: Wait and check logs
Write-Host ""
Write-Host "Step 9: Waiting for backend to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

Write-Host "Checking backend logs..." -ForegroundColor Yellow
wsl bash -c "sshpass -p '$VM_PASS' ssh -o StrictHostKeyChecking=no ${VM_USER}@${VM_IP} 'cd /opt/cloudoptima && docker-compose logs --tail=50 backend'"

# Step 10: Verify deployment
Write-Host ""
Write-Host "Step 10: Verifying deployment..." -ForegroundColor Yellow
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
Write-Host "  - Simplified main.py to only load Cost and Recommendation routes"
Write-Host "  - Removed dependencies on Organization, CloudConnection, AIWorkload models"
Write-Host "  - Database will only create tables without foreign key dependencies"
Write-Host "==========================================" -ForegroundColor Cyan
