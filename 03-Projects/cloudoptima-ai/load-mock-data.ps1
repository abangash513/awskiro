# Load Mock Data into CloudOptima AI Database

$VM_IP = "52.179.209.239"
$VM_USER = "azureuser"
$VM_PASS = "zJsjfxP80cmn!WeU"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CloudOptima AI - Load Mock Data" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Step 1: Copying SQL script to VM..." -ForegroundColor Yellow
wsl bash -c "sshpass -p '$VM_PASS' scp -o StrictHostKeyChecking=no add-mock-data.sql ${VM_USER}@${VM_IP}:/tmp/"
Write-Host "  SQL script copied" -ForegroundColor Green
Write-Host ""

Write-Host "Step 2: Loading data into database..." -ForegroundColor Yellow
wsl bash -c "sshpass -p '$VM_PASS' ssh -o StrictHostKeyChecking=no ${VM_USER}@${VM_IP} 'cd /opt/cloudoptima && docker-compose exec -T db psql -U cloudoptima -d cloudoptima < /tmp/add-mock-data.sql'"
Write-Host "  Data loaded successfully" -ForegroundColor Green
Write-Host ""

Write-Host "Step 3: Verifying data..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

# Test cost summary
$costs = Invoke-RestMethod -Uri "http://${VM_IP}:8000/api/v1/costs/summary" -TimeoutSec 10
Write-Host "  Total Cost: $($costs.total_cost) $($costs.currency)" -ForegroundColor Green
Write-Host "  Top Services: $($costs.top_services.Count)" -ForegroundColor Green

# Test recommendations
$recs = Invoke-RestMethod -Uri "http://${VM_IP}:8000/api/v1/recommendations/summary" -TimeoutSec 10
Write-Host "  Recommendations: $($recs.total_recommendations)" -ForegroundColor Green
Write-Host "  Monthly Savings: $($recs.potential_monthly_savings)" -ForegroundColor Green
Write-Host "  Annual Savings: $($recs.potential_annual_savings)" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Mock Data Loaded Successfully" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "You can now test the application with real data" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Run: .\run-demo-tests.ps1" -ForegroundColor Gray
Write-Host "  2. Open: http://${VM_IP}:8000/docs" -ForegroundColor Gray
Write-Host "  3. Try the API endpoints with data" -ForegroundColor Gray
Write-Host ""
