# Identify Low Utilization EC2 Instances
# Analyzes CloudWatch metrics to find candidates for stopping/downsizing

Write-Host "========================================" -ForegroundColor Green
Write-Host "LOW UTILIZATION INSTANCE ANALYSIS" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

# Import EC2 instances
$instances = Import-Csv "charles-mount-ec2-instances.csv"
$runningInstances = $instances | Where-Object State -eq 'running'

Write-Host "Analyzing $($runningInstances.Count) running instances..." -ForegroundColor Cyan
Write-Host "This will take a few minutes...`n" -ForegroundColor Yellow

$utilizationResults = @()
$endTime = Get-Date
$startTime = $endTime.AddDays(-7)

foreach ($instance in $runningInstances) {
    Write-Host "Checking $($instance.InstanceId) ($($instance.InstanceType))..." -ForegroundColor Gray
    
    try {
        # Get CPU utilization for last 7 days
        $cpuStats = aws cloudwatch get-metric-statistics `
            --namespace AWS/EC2 `
            --metric-name CPUUtilization `
            --dimensions Name=InstanceId,Value=$($instance.InstanceId) `
            --start-time $startTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss") `
            --end-time $endTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss") `
            --period 3600 `
            --statistics Average,Maximum `
            --region $($instance.Region) `
            --output json 2>$null | ConvertFrom-Json
        
        if ($cpuStats.Datapoints -and $cpuStats.Datapoints.Count -gt 0) {
            $avgCPU = [math]::Round(($cpuStats.Datapoints | Measure-Object Average -Average).Average, 2)
            $maxCPU = [math]::Round(($cpuStats.Datapoints | Measure-Object Maximum -Maximum).Maximum, 2)
            
            # Determine recommendation
            $recommendation = ""
            $priority = ""
            $estimatedSavings = 0
            
            # Get approximate hourly cost
            $hourlyCost = switch -Wildcard ($instance.InstanceType) {
                "c4.4xlarge" { 0.796; break }
                "c4.2xlarge" { 0.398; break }
                "c4.xlarge" { 0.199; break }
                "c4.large" { 0.100; break }
                "m4.2xlarge" { 0.400; break }
                "m4.xlarge" { 0.200; break }
                "m4.large" { 0.100; break }
                "m3.xlarge" { 0.266; break }
                "m3.large" { 0.133; break }
                "m3.medium" { 0.067; break }
                "t3.large" { 0.083; break }
                "t3.medium" { 0.042; break }
                "t3.small" { 0.021; break }
                "t2.medium" { 0.047; break }
                "t2.micro" { 0.012; break }
                default { 0.100 }
            }
            
            $monthlyCost = [math]::Round($hourlyCost * 730, 2)
            
            if ($avgCPU -lt 5) {
                $recommendation = "STOP - Extremely low utilization"
                $priority = "CRITICAL"
                $estimatedSavings = $monthlyCost
            }
            elseif ($avgCPU -lt 10) {
                $recommendation = "STOP or investigate - Very low utilization"
                $priority = "HIGH"
                $estimatedSavings = $monthlyCost
            }
            elseif ($avgCPU -lt 20 -and $instance.InstanceType -match "4xlarge|2xlarge") {
                $recommendation = "Downsize to smaller instance"
                $priority = "HIGH"
                $estimatedSavings = $monthlyCost * 0.5
            }
            elseif ($avgCPU -lt 30 -and $instance.InstanceType -match "4xlarge") {
                $recommendation = "Downsize from 4xlarge to 2xlarge"
                $priority = "MEDIUM"
                $estimatedSavings = $monthlyCost * 0.5
            }
            elseif ($avgCPU -lt 40 -and $instance.InstanceType -match "xlarge") {
                $recommendation = "Consider downsizing"
                $priority = "MEDIUM"
                $estimatedSavings = $monthlyCost * 0.3
            }
            elseif ($avgCPU -lt 50) {
                $recommendation = "Monitor - Moderate utilization"
                $priority = "LOW"
                $estimatedSavings = 0
            }
            else {
                $recommendation = "OK - Good utilization"
                $priority = "NONE"
                $estimatedSavings = 0
            }
            
            $utilizationResults += [PSCustomObject]@{
                Priority = $priority
                InstanceId = $instance.InstanceId
                InstanceType = $instance.InstanceType
                Region = $instance.Region
                AvgCPU = $avgCPU
                MaxCPU = $maxCPU
                MonthlyCost = $monthlyCost
                EstimatedSavings = [math]::Round($estimatedSavings, 2)
                Recommendation = $recommendation
                LaunchTime = $instance.LaunchTime
                PrivateIP = $instance.PrivateIP
            }
            
            Write-Host "  Avg CPU: $avgCPU% | Max CPU: $maxCPU% | $recommendation" -ForegroundColor $(
                if ($priority -eq "CRITICAL") { "Red" }
                elseif ($priority -eq "HIGH") { "Yellow" }
                elseif ($priority -eq "MEDIUM") { "Cyan" }
                else { "Green" }
            )
        }
        else {
            Write-Host "  No metrics available" -ForegroundColor Gray
            $utilizationResults += [PSCustomObject]@{
                Priority = "UNKNOWN"
                InstanceId = $instance.InstanceId
                InstanceType = $instance.InstanceType
                Region = $instance.Region
                AvgCPU = "N/A"
                MaxCPU = "N/A"
                MonthlyCost = 0
                EstimatedSavings = 0
                Recommendation = "No metrics - investigate"
                LaunchTime = $instance.LaunchTime
                PrivateIP = $instance.PrivateIP
            }
        }
    }
    catch {
        Write-Host "  Error: $_" -ForegroundColor Red
    }
}

# Export results
$utilizationResults | Sort-Object Priority, EstimatedSavings -Descending | Export-Csv -Path "low-utilization-instances.csv" -NoTypeInformation

# Summary
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "UTILIZATION ANALYSIS SUMMARY" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

$critical = $utilizationResults | Where-Object Priority -eq "CRITICAL"
$high = $utilizationResults | Where-Object Priority -eq "HIGH"
$medium = $utilizationResults | Where-Object Priority -eq "MEDIUM"

Write-Host "CRITICAL Priority (< 5% CPU):" -ForegroundColor Red
Write-Host "  Count: $($critical.Count) instances" -ForegroundColor White
Write-Host "  Potential Savings: `$$([math]::Round(($critical | Measure-Object EstimatedSavings -Sum).Sum, 2))/month" -ForegroundColor White

Write-Host "`nHIGH Priority (< 10% CPU or oversized):" -ForegroundColor Yellow
Write-Host "  Count: $($high.Count) instances" -ForegroundColor White
Write-Host "  Potential Savings: `$$([math]::Round(($high | Measure-Object EstimatedSavings -Sum).Sum, 2))/month" -ForegroundColor White

Write-Host "`nMEDIUM Priority (< 40% CPU):" -ForegroundColor Cyan
Write-Host "  Count: $($medium.Count) instances" -ForegroundColor White
Write-Host "  Potential Savings: `$$([math]::Round(($medium | Measure-Object EstimatedSavings -Sum).Sum, 2))/month" -ForegroundColor White

$totalSavings = ($utilizationResults | Where-Object {$_.Priority -in @("CRITICAL","HIGH","MEDIUM")} | Measure-Object EstimatedSavings -Sum).Sum
Write-Host "`nTOTAL POTENTIAL SAVINGS: `$$([math]::Round($totalSavings, 2))/month" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "TOP 10 CANDIDATES FOR IMMEDIATE ACTION" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

$utilizationResults | Where-Object {$_.Priority -in @("CRITICAL","HIGH")} | Sort-Object EstimatedSavings -Descending | Select-Object -First 10 | Format-Table -AutoSize

Write-Host "`nDetailed results saved to: low-utilization-instances.csv" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Green
