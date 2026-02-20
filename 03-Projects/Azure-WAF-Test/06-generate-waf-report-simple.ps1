# Azure WAF Test - Generate Simple Report

Write-Host "=== Generating WAF Assessment Report ===" -ForegroundColor Cyan
Write-Host ""

$outputDir = ".\Reports"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reportPath = Join-Path $outputDir "waf-assessment-report-$timestamp.html"

# Get recommendations
$recommendations = Get-AzAdvisorRecommendation
$context = Get-AzContext

# Generate simple HTML report
$html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Azure WAF Assessment Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; }
        h1 { color: #0078d4; }
        .summary { background: #e7f3ff; padding: 20px; margin: 20px 0; }
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
            <p><strong>Status:</strong> Resources created. Wait 24 hours for full analysis.</p>
        </div>
    </div>
</body>
</html>
"@

# Save report
$html | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "Report generated: $reportPath" -ForegroundColor Green
Write-Host ""
Write-Host "Opening report in browser..." -ForegroundColor Yellow
Start-Process $reportPath

Write-Host ""
Write-Host "=== Report Generation Complete ===" -ForegroundColor Cyan
