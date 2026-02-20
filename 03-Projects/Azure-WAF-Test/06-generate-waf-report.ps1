# Azure WAF Test - Generate Report
# This script creates a formatted HTML report of WAF assessment

Write-Host "=== Generating WAF Assessment Report ===" -ForegroundColor Cyan
Write-Host ""

$outputDir = ".\Reports"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportPath = Join-Path $outputDir "waf-assessment-report-$timestamp.html"

# Get recommendations
$recommendations = Get-AzAdvisorRecommendation
$context = Get-AzContext

# Generate HTML report
$html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Azure Well-Architected Framework Assessment Report</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #0078d4; border-bottom: 3px solid #0078d4; padding-bottom: 10px; }
        h2 { color: #106ebe; margin-top: 30px; }
        .summary { background: #e7f3ff; padding: 20px; border-radius: 5px; margin: 20px 0; }
        .category { margin: 20px 0; padding: 15px; border-left: 4px solid #0078d4; background: #f9f9f9; }
        .recommendation { margin: 10px 0; padding: 10px; background: white; border: 1px solid #ddd; border-radius: 3px; }
        .impact-high { color: #d13438; font-weight: bold; }
        .impact-medium { color: #ff8c00; font-weight: bold; }
        .impact-low { color: #107c10; font-weight: bold; }
        .metadata { color: #666; font-size: 0.9em; margin-top: 20px; padding-top: 20px; border-top: 1px solid #ddd; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #0078d4; color: white; }
        tr:hover { background: #f5f5f5; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Azure Well-Architected Framework Assessment Report</h1>
        
        <div class="summary">
            <h2>Assessment Summary</h2>
            <p><strong>Subscription:</strong> $($context.Subscription.Name)</p>
            <p><strong>Assessment Date:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
            <p><strong>Total Recommendations:</strong> $($recommendations.Count)</p>
        </div>

        <h2>Recommendations by Category</h2>
        <table>
            <tr>
                <th>Category</th>
                <th>Count</th>
                <th>High Impact</th>
                <th>Medium Impact</th>
                <th>Low Impact</th>
            </tr>
"@

# Add category summary
$categories = @('Security', 'Performance', 'Cost', 'OperationalExcellence', 'Reliability')
foreach ($category in $categories) {
    $catRecs = $recommendations | Where-Object { $_.Category -eq $category }
    $high = ($catRecs | Where-Object { $_.Impact -eq 'High' }).Count
    $medium = ($catRecs | Where-Object { $_.Impact -eq 'Medium' }).Count
    $low = ($catRecs | Where-Object { $_.Impact -eq 'Low' }).Count
    
    $html += @"
            <tr>
                <td><strong>$category</strong></td>
                <td>$($catRecs.Count)</td>
                <td class="impact-high">$high</td>
                <td class="impact-medium">$medium</td>
                <td class="impact-low">$low</td>
            </tr>
"@
}

$html += @"
        </table>

        <h2>Detailed Recommendations</h2>
"@

# Add detailed recommendations by category
foreach ($category in $categories) {
    $catRecs = $recommendations | Where-Object { $_.Category -eq $category }
    
    if ($catRecs.Count -gt 0) {
        $html += "<div class='category'><h3>$category ($($catRecs.Count) recommendations)</h3>"
        
        foreach ($rec in $catRecs) {
            $impactClass = "impact-$($rec.Impact.ToLower())"
            $html += @"
            <div class='recommendation'>
                <p><strong>Problem:</strong> $($rec.ShortDescriptionProblem)</p>
                <p><strong>Solution:</strong> $($rec.ShortDescriptionSolution)</p>
                <p><strong>Impact:</strong> <span class='$impactClass'>$($rec.Impact)</span></p>
                <p><strong>Affected Resource:</strong> $($rec.ImpactedField) - $($rec.ImpactedValue)</p>
            </div>
"@
        }
        
        $html += "</div>"
    }
}

$html += @"
        <div class="metadata">
            <p><strong>Report Generated:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
            <p><strong>Azure Subscription:</strong> $($context.Subscription.Id)</p>
            <p><strong>Tenant:</strong> $($context.Tenant.Id)</p>
        </div>
    </div>
</body>
</html>
"@

# Save report
$html | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "✓ Report generated: $reportPath" -ForegroundColor Green
Write-Host ""
Write-Host "Opening report in default browser..." -ForegroundColor Yellow
Start-Process $reportPath

Write-Host ""
Write-Host "=== Report Generation Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Files created:" -ForegroundColor Yellow
Write-Host "  • $reportPath" -ForegroundColor White
Write-Host ""
Write-Host "To cleanup resources: Run .\07-cleanup-resources.ps1" -ForegroundColor Yellow
