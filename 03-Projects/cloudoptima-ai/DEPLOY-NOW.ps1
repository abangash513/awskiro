# CloudOptima AI - Deploy Now via WSL
# This script uses WSL to copy files and deploy to Azure VM

Write-Host "=== CloudOptima AI - Deployment via WSL ===" -ForegroundColor Cyan
Write-Host ""

# Check if WSL is available
try {
    wsl --version | Out-Null
    Write-Host "✅ WSL is available" -ForegroundColor Green
} catch {
    Write-Host "❌ WSL is not available" -ForegroundColor Red
    Write-Host "Please install WSL first: wsl --install" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Starting deployment..." -ForegroundColor Yellow
Write-Host "This will:" -ForegroundColor White
Write-Host "  1. Install sshpass and rsync in WSL (if needed)" -ForegroundColor Gray
Write-Host "  2. Create .env file with Azure credentials" -ForegroundColor Gray
Write-Host "  3. Copy all application files to VM (~2-3 minutes)" -ForegroundColor Gray
Write-Host "  4. Start Docker Compose services on VM" -ForegroundColor Gray
Write-Host "  5. Verify deployment" -ForegroundColor Gray
Write-Host ""

$confirm = Read-Host "Continue? (y/n)"
if ($confirm -ne "y") {
    Write-Host "Deployment cancelled" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Running deployment script in WSL..." -ForegroundColor Yellow
Write-Host ""

# Navigate to the project directory in WSL and run the script
$wslPath = wsl wslpath -a (Get-Location).Path
wsl -d Ubuntu -- bash -c "cd '$wslPath' && chmod +x deploy-via-wsl.sh && ./deploy-via-wsl.sh"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=== 🎉 Deployment Complete! ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your application is now running on Azure!" -ForegroundColor White
    Write-Host ""
    Write-Host "Access URLs:" -ForegroundColor Cyan
    Write-Host "  Frontend:  http://cloudoptima-vm-e7ng1ocf.eastus2.cloudapp.azure.com:3000" -ForegroundColor White
    Write-Host "  Backend:   http://cloudoptima-vm-e7ng1ocf.eastus2.cloudapp.azure.com:8000" -ForegroundColor White
    Write-Host "  API Docs:  http://cloudoptima-vm-e7ng1ocf.eastus2.cloudapp.azure.com:8000/docs" -ForegroundColor White
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Open the frontend URL in your browser" -ForegroundColor White
    Write-Host "  2. Check the API docs to explore available endpoints" -ForegroundColor White
    Write-Host "  3. The application will start collecting Azure cost data automatically" -ForegroundColor White
    Write-Host ""
    Write-Host "View logs:" -ForegroundColor Cyan
    Write-Host "  wsl -d Ubuntu -- ssh azureuser@cloudoptima-vm-e7ng1ocf.eastus2.cloudapp.azure.com 'cd /opt/cloudoptima && docker-compose logs -f backend'" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "❌ Deployment failed" -ForegroundColor Red
    Write-Host "Check the error messages above for details" -ForegroundColor Yellow
    Write-Host ""
}
