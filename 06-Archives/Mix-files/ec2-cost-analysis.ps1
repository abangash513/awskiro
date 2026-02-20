# Enhanced EC2 Cost Analysis with Pricing
# Adds estimated monthly costs based on instance types

# Import the CSV
$instances = Import-Csv "ec2-inventory-all-accounts.csv"

# Pricing data for us-west-1 (approximate on-demand rates per hour)
$pricing = @{
    't2.micro' = @{Linux=0.0116; Windows=0.0162}
    't2.medium' = @{Linux=0.0464; Windows=0.0650}
}

# Calculate costs
$enhancedResults = @()
$totalMonthlyCost = 0

foreach ($instance in $instances) {
    $hourlyRate = 0
    $platform = if ($instance.Platform -eq 'windows') { 'Windows' } else { 'Linux' }
    
    if ($pricing.ContainsKey($instance.InstanceType)) {
        $hourlyRate = $pricing[$instance.InstanceType][$platform]
    }
    
    # Monthly cost (730 hours per month) - only if running
    $monthlyCost = if ($instance.State -eq 'running') { $hourlyRate * 730 } else { 0 }
    $totalMonthlyCost += $monthlyCost
    
    $enhancedResults += [PSCustomObject]@{
        AccountId = $instance.AccountId
        AccountName = $instance.AccountName
        Region = $instance.Region
        InstanceId = $instance.InstanceId
        InstanceType = $instance.InstanceType
        State = $instance.State
        Platform = $instance.Platform
        Name = $instance.Name
        Lifecycle = $instance.Lifecycle
        HourlyRate = [math]::Round($hourlyRate, 4)
        MonthlyCost = [math]::Round($monthlyCost, 2)
        PotentialMonthlyCost = [math]::Round($hourlyRate * 730, 2)
    }
}

# Export enhanced report
$enhancedResults | Export-Csv -Path "ec2-cost-analysis-detailed.csv" -NoTypeInformation

# Create summary report
$summary = $enhancedResults | Group-Object AccountName | ForEach-Object {
    $accountInstances = $_.Group
    [PSCustomObject]@{
        AccountName = $_.Name
        AccountId = $accountInstances[0].AccountId
        TotalInstances = $accountInstances.Count
        RunningInstances = ($accountInstances | Where-Object State -eq 'running').Count
        StoppedInstances = ($accountInstances | Where-Object State -eq 'stopped').Count
        CurrentMonthlyCost = [math]::Round(($accountInstances | Measure-Object MonthlyCost -Sum).Sum, 2)
        PotentialMonthlyCost = [math]::Round(($accountInstances | Measure-Object PotentialMonthlyCost -Sum).Sum, 2)
    }
}

$summary | Export-Csv -Path "ec2-cost-summary-by-account.csv" -NoTypeInformation

# Create instance type summary
$typeSummary = $enhancedResults | Group-Object InstanceType | ForEach-Object {
    $typeInstances = $_.Group
    [PSCustomObject]@{
        InstanceType = $_.Name
        TotalCount = $typeInstances.Count
        RunningCount = ($typeInstances | Where-Object State -eq 'running').Count
        StoppedCount = ($typeInstances | Where-Object State -eq 'stopped').Count
        CurrentMonthlyCost = [math]::Round(($typeInstances | Measure-Object MonthlyCost -Sum).Sum, 2)
        PotentialMonthlyCost = [math]::Round(($typeInstances | Measure-Object PotentialMonthlyCost -Sum).Sum, 2)
    }
}

$typeSummary | Export-Csv -Path "ec2-cost-summary-by-type.csv" -NoTypeInformation

Write-Host "`n========== EC2 COST ANALYSIS SUMMARY ==========" -ForegroundColor Green
Write-Host "Total Instances Found: $($instances.Count)" -ForegroundColor Cyan
Write-Host "Running Instances: $(($enhancedResults | Where-Object State -eq 'running').Count)" -ForegroundColor Yellow
Write-Host "Stopped Instances: $(($enhancedResults | Where-Object State -eq 'stopped').Count)" -ForegroundColor Gray
Write-Host "`nCurrent Monthly Cost (Running Only): `$$totalMonthlyCost" -ForegroundColor Green
Write-Host "Potential Monthly Cost (If All Running): `$$([math]::Round(($enhancedResults | Measure-Object PotentialMonthlyCost -Sum).Sum, 2))" -ForegroundColor Yellow
Write-Host "`nFiles Generated:" -ForegroundColor Cyan
Write-Host "  1. ec2-cost-analysis-detailed.csv - Full instance details with costs"
Write-Host "  2. ec2-cost-summary-by-account.csv - Summary by account"
Write-Host "  3. ec2-cost-summary-by-type.csv - Summary by instance type"
Write-Host "===============================================`n" -ForegroundColor Green
