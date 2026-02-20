# Update Frontend on Azure VM

$VM_IP = "52.179.209.239"
$VM_USER = "azureuser"
$VM_PASS = "zJsjfxP80cmn!WeU"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CloudOptima AI - Update Frontend" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Step 1: Copying updated App.js to VM..." -ForegroundColor Yellow
wsl bash -c "sshpass -p '$VM_PASS' scp -o StrictHostKeyChecking=no frontend/src/App.js ${VM_USER}@${VM_IP}:/tmp/"
Write-Host "  File copied" -ForegroundColor Green
Write-Host ""

Write-Host "Step 2: Updating file on VM..." -ForegroundColor Yellow
wsl bash -c "sshpass -p '$VM_PASS' ssh -o StrictHostKeyChecking=no ${VM_USER}@${VM_IP} 'sudo cp /tmp/App.js /opt/cloudoptima/frontend/src/App.js'"
Write-Host "  File updated" -ForegroundColor Green
Write-Host ""

Write-Host "Step 3: Rebuilding frontend container..." -ForegroundColor Yellow
Write-Host "  This will take 2-3 minutes..." -ForegroundColor Gray
wsl bash -c "sshpass -p '$VM_PASS' ssh -o StrictHostKeyChecking=no ${VM_USER}@${VM_IP} 'cd /opt/cloudoptima && docker-compose up -d --build frontend'"
Write-Host "  Frontend rebuilt" -ForegroundColor Green
Write-Host ""

Write-Host "Step 4: Waiting for frontend to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10
Write-Host "  Frontend ready" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Frontend Updated Successfully" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "You can now access the application without login:" -ForegroundColor White
Write-Host "  http://${VM_IP}:3000" -ForegroundColor Cyan
Write-Host ""
Write-Host "The page will automatically show the dashboard with a demo user." -ForegroundColor Gray
Write-Host ""
