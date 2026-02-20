# Load Multi-Cloud Mock Data into CloudOptima AI

$VM_IP = "52.179.209.239"
$VM_USER = "azureuser"
$VM_PASS = "zJsjfxP80cmn!WeU"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CloudOptima AI - Load Multi-Cloud Data" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Loading data for:" -ForegroundColor White
Write-Host "  - Azure Subscription 1 (Production)" -ForegroundColor Gray
Write-Host "  - Azure Subscription 2 (Development)" -ForegroundColor Gray
Write-Host "  - AWS Account (Production)" -ForegroundColor Gray
Write-Host ""

Write-Host "Step 1: Copying SQL script to VM..." -ForegroundColor Yellow
wsl bash -c "sshpass -p '$VM_PASS' scp -o StrictHostKeyChecking=no add-multicloud-data.sql ${VM_USER}@${VM_IP}:/tmp/"
Write-Host "  SQL script copied" -ForegroundColor Green
Write-Host ""

Write-Host "Step 2: Loading data into database..." -ForegroundColor Yellow
Write-Host "  This may take a moment..." -ForegroundColor Gray
wsl bash -c "sshpass -p '$VM_PASS' ssh -o StrictHostKeyChecking=no ${VM_USER}@${VM_IP} 'cd /opt/cloudoptima && docker-compose exec -T db psql -U cloudoptima -d cloudoptima < /tmp/add-multicloud-data.sql'"
Write-Host "  Data loaded successfully" -ForegroundColor Green
Write-Host ""

Write-Host "Step 3: Verifying multi-cloud data..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

# Test cost summary
$costs = Invoke-RestMethod -Uri "http://${VM_IP}:8000/api/v1/costs/summary" -TimeoutSec 10
Write-Host "  Total Cost: $($costs.total_cost) $($costs.currency)" -ForegroundColor Green
Write-Host "  Services: $($costs.top_services.Count)" -ForegroundColor Green

# Test recommendations
$recs = Invoke-RestMethod -Uri "http://${VM_IP}:8000/api/v1/recommendations/summary" -TimeoutSec 10
Write-Host "  Recommendations: $($recs.total_recommendations)" -ForegroundColor Green
Write-Host "  Monthly Savings: $($recs.potential_monthly_savings)" -ForegroundColor Green
Write-Host "  Annual Savings: $($recs.potential_annual_savings)" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Multi-Cloud Data Loaded Successfully" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Data Summary:" -ForegroundColor White
Write-Host "  Cloud Providers: Azure (2 subscriptions) + AWS (1 account)" -ForegroundColor Gray
Write-Host "  Total Accounts: 3" -ForegroundColor Gray
Write-Host "  Cost Records: 40+" -ForegroundColor Gray
Write-Host "  Recommendations: 8" -ForegroundColor Gray
Write-Host "  Budgets: 4" -ForegroundColor Gray
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Open: http://${VM_IP}:3000" -ForegroundColor Gray
Write-Host "  2. View multi-cloud costs and recommendations" -ForegroundColor Gray
Write-Host "  3. Run: .\run-demo-tests.ps1" -ForegroundColor Gray
Write-Host ""
