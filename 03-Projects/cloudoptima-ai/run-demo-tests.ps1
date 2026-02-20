# CloudOptima AI - Automated Demo Test Script

$VM_IP = "52.179.209.239"
$BASE_URL = "http://${VM_IP}:8000"
$FRONTEND_URL = "http://${VM_IP}:3000"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CloudOptima AI - Demo Test Suite" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Health Check
Write-Host "Test 1: Health Check" -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "$BASE_URL/health" -TimeoutSec 10
    Write-Host "  Status: $($health.status)" -ForegroundColor Green
    Write-Host "  Service: $($health.service)" -ForegroundColor Green
    Write-Host "  Version: $($health.version)" -ForegroundColor Green
    Write-Host "  ✓ PASS" -ForegroundColor Green
} catch {
    Write-Host "  ✗ FAIL: $_" -ForegroundColor Red
}
Write-Host ""

# Test 2: API Root
Write-Host "Test 2: API Root Endpoint" -ForegroundColor Yellow
try {
    $root = Invoke-RestMethod -Uri "$BASE_URL/" -TimeoutSec 10
    Write-Host "  Message: $($root.message)" -ForegroundColor Green
    Write-Host "  Status: $($root.status)" -ForegroundColor Green
    Write-Host "  ✓ PASS" -ForegroundColor Green
} catch {
    Write-Host "  ✗ FAIL: $_" -ForegroundColor Red
}
Write-Host ""

# Test 3: Cost Summary
Write-Host "Test 3: Cost Summary Endpoint" -ForegroundColor Yellow
try {
    $costs = Invoke-RestMethod -Uri "$BASE_URL/api/v1/costs/summary" -TimeoutSec 10
    Write-Host "  Total Cost: $($costs.total_cost) $($costs.currency)" -ForegroundColor Green
    Write-Host "  Period: $($costs.period_start) to $($costs.period_end)" -ForegroundColor Green
    Write-Host "  Top Services: $($costs.top_services.Count)" -ForegroundColor Green
    Write-Host "  ✓ PASS" -ForegroundColor Green
} catch {
    Write-Host "  ✗ FAIL: $_" -ForegroundColor Red
}
Write-Host ""

# Test 4: Cost Trend
Write-Host "Test 4: Cost Trend Endpoint" -ForegroundColor Yellow
try {
    $trend = Invoke-RestMethod -Uri "$BASE_URL/api/v1/costs/trend" -TimeoutSec 10
    Write-Host "  Data Points: $($trend.Count)" -ForegroundColor Green
    Write-Host "  ✓ PASS" -ForegroundColor Green
} catch {
    Write-Host "  ✗ FAIL: $_" -ForegroundColor Red
}
Write-Host ""

# Test 5: Cost by Service
Write-Host "Test 5: Cost by Service Endpoint" -ForegroundColor Yellow
try {
    $byService = Invoke-RestMethod -Uri "$BASE_URL/api/v1/costs/by-service" -TimeoutSec 10
    Write-Host "  Services: $($byService.Count)" -ForegroundColor Green
    if ($byService.Count -gt 0) {
        Write-Host "  Top Service: $($byService[0].service) - $($byService[0].cost)" -ForegroundColor Green
    }
    Write-Host "  ✓ PASS" -ForegroundColor Green
} catch {
    Write-Host "  ✗ FAIL: $_" -ForegroundColor Red
}
Write-Host ""

# Test 6: Recommendations Summary
Write-Host "Test 6: Recommendations Summary" -ForegroundColor Yellow
try {
    $recSummary = Invoke-RestMethod -Uri "$BASE_URL/api/v1/recommendations/summary" -TimeoutSec 10
    Write-Host "  Total Recommendations: $($recSummary.total_recommendations)" -ForegroundColor Green
    Write-Host "  Monthly Savings Potential: $($recSummary.potential_monthly_savings)" -ForegroundColor Green
    Write-Host "  Annual Savings Potential: $($recSummary.potential_annual_savings)" -ForegroundColor Green
    Write-Host "  ✓ PASS" -ForegroundColor Green
} catch {
    Write-Host "  ✗ FAIL: $_" -ForegroundColor Red
}
Write-Host ""

# Test 7: List Recommendations
Write-Host "Test 7: List Recommendations" -ForegroundColor Yellow
try {
    $recs = Invoke-RestMethod -Uri "$BASE_URL/api/v1/recommendations/" -TimeoutSec 10
    Write-Host "  Recommendations Found: $($recs.Count)" -ForegroundColor Green
    if ($recs.Count -gt 0) {
        Write-Host "  First Recommendation: $($recs[0].title)" -ForegroundColor Green
    }
    Write-Host "  ✓ PASS" -ForegroundColor Green
} catch {
    Write-Host "  ✗ FAIL: $_" -ForegroundColor Red
}
Write-Host ""

# Test 8: Recommendation Categories
Write-Host "Test 8: Recommendation Categories" -ForegroundColor Yellow
try {
    $categories = Invoke-RestMethod -Uri "$BASE_URL/api/v1/recommendations/categories/list" -TimeoutSec 10
    Write-Host "  Categories Available: $($categories.categories.Count)" -ForegroundColor Green
    Write-Host "  ✓ PASS" -ForegroundColor Green
} catch {
    Write-Host "  ✗ FAIL: $_" -ForegroundColor Red
}
Write-Host ""

# Test 9: Frontend
Write-Host "Test 9: Frontend Accessibility" -ForegroundColor Yellow
try {
    $frontend = Invoke-WebRequest -Uri $FRONTEND_URL -TimeoutSec 10 -UseBasicParsing
    Write-Host "  Status Code: $($frontend.StatusCode)" -ForegroundColor Green
    Write-Host "  Content Length: $($frontend.Content.Length) bytes" -ForegroundColor Green
    Write-Host "  ✓ PASS" -ForegroundColor Green
} catch {
    Write-Host "  ✗ FAIL: $_" -ForegroundColor Red
}
Write-Host ""

# Test 10: API Documentation
Write-Host "Test 10: API Documentation" -ForegroundColor Yellow
try {
    $docs = Invoke-WebRequest -Uri "$BASE_URL/docs" -TimeoutSec 10 -UseBasicParsing
    Write-Host "  Status Code: $($docs.StatusCode)" -ForegroundColor Green
    Write-Host "  ✓ PASS" -ForegroundColor Green
} catch {
    Write-Host "  ✗ FAIL: $_" -ForegroundColor Red
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Demo Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Application URLs:" -ForegroundColor White
Write-Host "  Frontend:  $FRONTEND_URL" -ForegroundColor Cyan
Write-Host "  Backend:   $BASE_URL" -ForegroundColor Cyan
Write-Host "  API Docs:  $BASE_URL/docs" -ForegroundColor Cyan
Write-Host ""
Write-Host "To open in browser:" -ForegroundColor White
Write-Host "  Start-Process '$FRONTEND_URL'" -ForegroundColor Gray
Write-Host "  Start-Process '$BASE_URL/docs'" -ForegroundColor Gray
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
