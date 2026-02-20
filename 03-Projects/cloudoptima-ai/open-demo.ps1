# Quick Demo Launcher - Opens all CloudOptima AI URLs in browser

$VM_IP = "52.179.209.239"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CloudOptima AI - Demo Launcher" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Opening CloudOptima AI in your browser..." -ForegroundColor Yellow
Write-Host ""

# Open Frontend
Write-Host "1. Opening Frontend..." -ForegroundColor Green
Start-Process "http://${VM_IP}:3000"
Start-Sleep -Seconds 2

# Open API Documentation
Write-Host "2. Opening API Documentation..." -ForegroundColor Green
Start-Process "http://${VM_IP}:8000/docs"
Start-Sleep -Seconds 2

# Open Health Check
Write-Host "3. Opening Health Check..." -ForegroundColor Green
Start-Process "http://${VM_IP}:8000/health"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Demo URLs Opened!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Available URLs:" -ForegroundColor White
Write-Host "  Frontend:        http://${VM_IP}:3000" -ForegroundColor Cyan
Write-Host "  API Docs:        http://${VM_IP}:8000/docs" -ForegroundColor Cyan
Write-Host "  Health Check:    http://${VM_IP}:8000/health" -ForegroundColor Cyan
Write-Host "  Cost Summary:    http://${VM_IP}:8000/api/v1/costs/summary" -ForegroundColor Cyan
Write-Host "  Recommendations: http://${VM_IP}:8000/api/v1/recommendations/summary" -ForegroundColor Cyan
Write-Host ""
Write-Host "To run automated tests:" -ForegroundColor White
Write-Host "  .\run-demo-tests.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
