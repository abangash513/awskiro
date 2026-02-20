# Daily AWS Cost Monitor Script
# Run this script daily to track your cost optimization progress

param(
    [switch]$Detailed,
    [switch]$SendEmail
)

Write-Host "📊 AWS Daily Cost Monitor - $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

# Get current date ranges
$today = Get-Date -Format "yyyy-MM-dd"
$yesterday = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")
$monthStart = Get-Date -Format "yyyy-MM-01"
$nextMonth = (Get-Date).AddMonths(1).ToString("yyyy-MM-01")

# Function to get cost data
function Get-AWSCost {
    param($StartDate, $EndDate, $Granularity = "DAILY")
    
    try {
        $result = aws ce get-cost-and-usage --time-period Start=$StartDate,End=$EndDate --granularity $Granularity --metrics BlendedCost --query "ResultsByTime[0].Total.BlendedCost.Amount" --output text
        return [decimal]$result
    }
    catch {
        Write-Host "❌ Error getting cost data: $($_.Exception.Message)" -ForegroundColor Red
        return 0
    }
}

# Get yesterday's cost
Write-Host "`n💰 DAILY COST ANALYSIS" -ForegroundColor Yellow
Write-Host "======================" -ForegroundColor Yellow

$yesterdayCost = Get-AWSCost -StartDate $yesterday -EndDate $today
Write-Host "Yesterday ($yesterday): `$$([math]::Round($yesterdayCost, 2))" -ForegroundColor White

# Get month-to-date cost
$monthToDateCost = Get-AWSCost -StartDate $monthStart -EndDate $today -Granularity "MONTHLY"
Write-Host "Month-to-date: `$$([math]::Round($monthToDateCost, 2))" -ForegroundColor White

# Calculate projections
$daysInMonth = [DateTime]::DaysInMonth((Get-Date).Year, (Get-Date).Month)
$dayOfMonth = (Get-Date).Day
$projectedMonthlyCost = ($monthToDateCost / $dayOfMonth) * $daysInMonth

Write-Host "Projected monthly cost: `$$([math]::Round($projectedMonthlyCost, 2))" -ForegroundColor $(if ($projectedMonthlyCost -lt 200) { "Green" } elseif ($projectedMonthlyCost -lt 250) { "Yellow" } else { "Red" })

# Cost optimization tracking
Write-Host "`n🎯 OPTIMIZATION TRACKING" -ForegroundColor Yellow
Write-Host "========================" -ForegroundColor Yellow

$targetMonthlyCost = 177.82
$originalMonthlyCost = 294.47
$targetSavings = $originalMonthlyCost - $targetMonthlyCost

$currentSavings = $originalMonthlyCost - $projectedMonthlyCost
$savingsPercentage = ($currentSavings / $originalMonthlyCost) * 100

Write-Host "Original monthly cost: `$$originalMonthlyCost" -ForegroundColor Gray
Write-Host "Target monthly cost: `$$targetMonthlyCost" -ForegroundColor Gray
Write-Host "Current projected cost: `$$([math]::Round($projectedMonthlyCost, 2))" -ForegroundColor White
Write-Host "Savings achieved: `$$([math]::Round($currentSavings, 2)) ($([math]::Round($savingsPercentage, 1))%)" -ForegroundColor $(if ($currentSavings -gt $targetSavings * 0.8) { "Green" } elseif ($currentSavings -gt $targetSavings * 0.5) { "Yellow" } else { "Red" })

if ($currentSavings -ge $targetSavings) {
    Write-Host "🎉 OPTIMIZATION TARGET ACHIEVED!" -ForegroundColor Green
} elseif ($currentSavings -ge $targetSavings * 0.8) {
    Write-Host "✅ Close to optimization target (80%+)" -ForegroundColor Yellow
} else {
    Write-Host "⏳ Still waiting for full optimization impact" -ForegroundColor Red
}

# Service-specific cost tracking
if ($Detailed) {
    Write-Host "`n🔍 SERVICE BREAKDOWN" -ForegroundColor Yellow
    Write-Host "====================" -ForegroundColor Yellow
    
    # Get service breakdown for yesterday
    $serviceBreakdown = aws ce get-cost-and-usage --time-period Start=$yesterday,End=$today --granularity DAILY --metrics BlendedCost --group-by Type=DIMENSION,Key=SERVICE --query "ResultsByTime[0].Groups[?Metrics.BlendedCost.Amount > '0'].{Service:Keys[0],Cost:Metrics.BlendedCost.Amount}" --output json | ConvertFrom-Json
    
    if ($serviceBreakdown) {
        $serviceBreakdown | Sort-Object {[decimal]$_.Cost} -Descending | ForEach-Object {
            $cost = [math]::Round([decimal]$_.Cost, 2)
            $color = if ($_.Service -match "SageMaker|Directory") { "Red" } else { "White" }
            Write-Host "  $($_.Service): `$$cost" -ForegroundColor $color
        }
        
        # Check for SageMaker and Directory Service costs
        $sagemakerCost = ($serviceBreakdown | Where-Object { $_.Service -match "SageMaker" } | Measure-Object -Property Cost -Sum).Sum
        $directoryCost = ($serviceBreakdown | Where-Object { $_.Service -match "Directory" } | Measure-Object -Property Cost -Sum).Sum
        
        if ($sagemakerCost -gt 0 -or $directoryCost -gt 0) {
            Write-Host "`n⚠️ OPTIMIZATION ALERT:" -ForegroundColor Red
            if ($sagemakerCost -gt 0) {
                Write-Host "  SageMaker still incurring costs: `$$([math]::Round($sagemakerCost, 2))" -ForegroundColor Red
            }
            if ($directoryCost -gt 0) {
                Write-Host "  Directory Service still incurring costs: `$$([math]::Round($directoryCost, 2))" -ForegroundColor Red
            }
            Write-Host "  This may be normal billing lag (24-48 hours)" -ForegroundColor Yellow
        } else {
            Write-Host "`n✅ No SageMaker or Directory Service costs detected!" -ForegroundColor Green
        }
    }
}

# Cost trend analysis
Write-Host "`n📈 COST TREND (Last 7 Days)" -ForegroundColor Yellow
Write-Host "============================" -ForegroundColor Yellow

for ($i = 7; $i -ge 1; $i--) {
    $date = (Get-Date).AddDays(-$i).ToString("yyyy-MM-dd")
    $nextDate = (Get-Date).AddDays(-$i + 1).ToString("yyyy-MM-dd")
    $cost = Get-AWSCost -StartDate $date -EndDate $nextDate
    
    $indicator = if ($cost -lt 15) { "🟢" } elseif ($cost -lt 25) { "🟡" } else { "🔴" }
    Write-Host "  $date: $indicator `$$([math]::Round($cost, 2))" -ForegroundColor White
}

# Recommendations
Write-Host "`n💡 RECOMMENDATIONS" -ForegroundColor Yellow
Write-Host "==================" -ForegroundColor Yellow

if ($projectedMonthlyCost -gt $targetMonthlyCost * 1.2) {
    Write-Host "🔍 Costs are higher than expected. Consider:" -ForegroundColor Red
    Write-Host "  - Check for new resources that may have been created" -ForegroundColor White
    Write-Host "  - Verify SageMaker and Directory Service are fully terminated" -ForegroundColor White
    Write-Host "  - Review detailed service breakdown" -ForegroundColor White
} elseif ($projectedMonthlyCost -gt $targetMonthlyCost) {
    Write-Host "⏳ Costs are decreasing but not at target yet:" -ForegroundColor Yellow
    Write-Host "  - This may be normal billing lag" -ForegroundColor White
    Write-Host "  - Monitor for another 24-48 hours" -ForegroundColor White
} else {
    Write-Host "🎉 Excellent! Costs are at or below target:" -ForegroundColor Green
    Write-Host "  - Optimization successful" -ForegroundColor White
    Write-Host "  - Ready to proceed with Nuri deployment" -ForegroundColor White
}

# Nuri deployment readiness
Write-Host "`n🤖 NURI DEPLOYMENT READINESS" -ForegroundColor Yellow
Write-Host "=============================" -ForegroundColor Yellow

$availableBudget = $targetMonthlyCost - $projectedMonthlyCost
$nuriEstimatedCost = 75  # Estimated monthly cost for Nuri

if ($availableBudget -ge $nuriEstimatedCost) {
    Write-Host "✅ Ready for Nuri deployment!" -ForegroundColor Green
    Write-Host "  Available budget: `$$([math]::Round($availableBudget, 2))" -ForegroundColor White
    Write-Host "  Nuri estimated cost: `$$nuriEstimatedCost" -ForegroundColor White
    Write-Host "  Remaining buffer: `$$([math]::Round($availableBudget - $nuriEstimatedCost, 2))" -ForegroundColor White
} else {
    Write-Host "⏳ Wait for further cost optimization" -ForegroundColor Yellow
    Write-Host "  Available budget: `$$([math]::Round($availableBudget, 2))" -ForegroundColor White
    Write-Host "  Nuri estimated cost: `$$nuriEstimatedCost" -ForegroundColor White
    Write-Host "  Additional savings needed: `$$([math]::Round($nuriEstimatedCost - $availableBudget, 2))" -ForegroundColor Red
}

# Save results to log file
$logEntry = @{
    Date = $today
    YesterdayCost = $yesterdayCost
    MonthToDateCost = $monthToDateCost
    ProjectedMonthlyCost = $projectedMonthlyCost
    SavingsAchieved = $currentSavings
    SavingsPercentage = $savingsPercentage
    OptimizationTarget = ($currentSavings -ge $targetSavings)
    NuriReady = ($availableBudget -ge $nuriEstimatedCost)
}

$logEntry | ConvertTo-Json | Out-File -FilePath "cost_monitoring_log.json" -Append

Write-Host "`n📝 Results logged to cost_monitoring_log.json" -ForegroundColor Gray
Write-Host "Run with -Detailed flag for service breakdown" -ForegroundColor Gray
Write-Host "`n✅ Cost monitoring complete!" -ForegroundColor Green