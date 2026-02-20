# Azure WAF Test - Get Recommendations
# This script retrieves Azure Advisor recommendations for WAF assessment

Write-Host "=== Azure Well-Architected Framework Assessment ===" -ForegroundColor Cyan
Write-Host ""

$outputDir = ".\Reports"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

# Get all recommendations
Write-Host "Retrieving Azure Advisor recommendations..." -ForegroundColor Green
Write-Host ""

try {
    $allRecommendations = Get-AzAdvisorRecommendation
    
    if ($allRecommendations.Count -eq 0) {
        Write-Host "No recommendations found." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Possible reasons:" -ForegroundColor Yellow
        Write-Host "  1. Resources were recently created (Advisor needs 24 hours)" -ForegroundColor White
        Write-Host "  2. All resources are optimally configured" -ForegroundColor White
        Write-Host "  3. No resources exist in the subscription" -ForegroundColor White
        Write-Host ""
    }
    else {
        Write-Host "Found $($allRecommendations.Count) recommendations" -ForegroundColor Green
        Write-Host ""
    }
}
catch {
    Write-Host "Failed to retrieve recommendations" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

# Group by category
$categories = @('Security', 'Performance', 'Cost', 'OperationalExcellence', 'Reliability')
$summary = @{}

foreach ($category in $categories) {
    Write-Host "Category: $category" -ForegroundColor Cyan
    $categoryRecs = $allRecommendations | Where-Object { $_.Category -eq $category }
    $summary[$category] = $categoryRecs.Count
    
    if ($categoryRecs.Count -gt 0) {
        $categoryRecs | ForEach-Object {
            Write-Host "  - $($_.ShortDescriptionProblem)" -ForegroundColor White
            Write-Host "    Impact: $($_.Impact)" -ForegroundColor Gray
        }
    }
    else {
        Write-Host "  No recommendations" -ForegroundColor Gray
    }
    Write-Host ""
}

# Export to CSV
$csvPath = Join-Path $outputDir "azure-advisor-recommendations-$timestamp.csv"
if ($allRecommendations.Count -gt 0) {
    $allRecommendations | Select-Object Category, Impact, ShortDescriptionProblem, ShortDescriptionSolution, ImpactedField, ImpactedValue | Export-Csv -Path $csvPath -NoTypeInformation
    Write-Host "Detailed recommendations exported to: $csvPath" -ForegroundColor Green
}

# Export summary to JSON
$summaryPath = Join-Path $outputDir "waf-summary-$timestamp.json"
$summaryObject = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TotalRecommendations = $allRecommendations.Count
    ByCategory = $summary
    Subscription = (Get-AzContext).Subscription.Name
}
$summaryObject | ConvertTo-Json | Out-File -FilePath $summaryPath
Write-Host "Summary exported to: $summaryPath" -ForegroundColor Green

Write-Host ""
Write-Host "=== Assessment Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Total Recommendations: $($allRecommendations.Count)" -ForegroundColor White
foreach ($cat in $categories) {
    Write-Host "  $cat : $($summary[$cat])" -ForegroundColor White
}

Write-Host ""
Write-Host "Next step: Run .\06-generate-waf-report.ps1 to create detailed report" -ForegroundColor Yellow
