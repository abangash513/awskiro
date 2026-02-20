# Daily Health Check Script for WAC DC Migration
# Run this daily to monitor AD health

$ErrorActionPreference = "Continue"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$reportFile = "C:\Logs\HealthCheck-$(Get-Date -Format yyyyMMdd).txt"

# Create log directory
New-Item -Path "C:\Logs" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

Start-Transcript -Path $reportFile

Write-Host "========================================" -ForegroundColor Green
Write-Host "WAC DC Migration - Daily Health Check" -ForegroundColor Green
Write-Host "Timestamp: $timestamp" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# 1. FSMO Role Holders
Write-Host "=== FSMO Role Holders ===" -ForegroundColor Yellow
netdom query fsmo
Write-Host ""

# 2. Domain Controller List
Write-Host "=== Domain Controllers ===" -ForegroundColor Yellow
Get-ADDomainController -Filter * | Select Name,IPv4Address,Site,OperatingSystem,IsGlobalCatalog | Format-Table -AutoSize
Write-Host ""

# 3. Replication Health
Write-Host "=== Replication Summary ===" -ForegroundColor Yellow
repadmin /replsummary
Write-Host ""

# 4. Replication Failures
Write-Host "=== Replication Failures ===" -ForegroundColor Yellow
$failures = Get-ADReplicationFailure -Target * -Scope Domain -ErrorAction SilentlyContinue
if ($failures) {
    $failures | Format-Table -AutoSize
    Write-Host "⚠️ REPLICATION FAILURES DETECTED!" -ForegroundColor Red
} else {
    Write-Host "✅ No replication failures" -ForegroundColor Green
}
Write-Host ""

# 5. DC Diagnostics
Write-Host "=== DC Diagnostics (Replication Test) ===" -ForegroundColor Yellow
dcdiag /test:replications
Write-Host ""

# 6. Event Log Errors (Last 24 hours)
Write-Host "=== Event Log Errors (Last 24 hours) ===" -ForegroundColor Yellow
$errors = Get-EventLog -LogName "Directory Service" -After (Get-Date).AddHours(-24) -EntryType Error -ErrorAction SilentlyContinue
if ($errors) {
    $errors | Select TimeGenerated,Source,EventID,Message | Format-Table -AutoSize
    Write-Host "⚠️ $($errors.Count) errors found in last 24 hours" -ForegroundColor Red
} else {
    Write-Host "✅ No errors in last 24 hours" -ForegroundColor Green
}
Write-Host ""

# 7. AWS DC Status
Write-Host "=== AWS DC Status ===" -ForegroundColor Yellow
$awsDCs = @("WACPRODDC01", "WACPRODDC02")
foreach ($dc in $awsDCs) {
    try {
        $dcInfo = Get-ADDomainController -Identity $dc
        Write-Host "✅ $dc : Online" -ForegroundColor Green
        Write-Host "   IP: $($dcInfo.IPv4Address)" -ForegroundColor Cyan
        Write-Host "   GC: $($dcInfo.IsGlobalCatalog)" -ForegroundColor Cyan
    } catch {
        Write-Host "❌ $dc : Offline or unreachable" -ForegroundColor Red
    }
}
Write-Host ""

# 8. VPN Status (if accessible)
Write-Host "=== Network Connectivity ===" -ForegroundColor Yellow
$testIPs = @("10.70.10.10", "10.70.11.10", "10.1.220.5", "10.1.220.6")
foreach ($ip in $testIPs) {
    $result = Test-Connection -ComputerName $ip -Count 1 -Quiet
    if ($result) {
        Write-Host "✅ $ip : Reachable" -ForegroundColor Green
    } else {
        Write-Host "❌ $ip : Unreachable" -ForegroundColor Red
    }
}
Write-Host ""

# 9. Time Sync Status
Write-Host "=== Time Sync Status ===" -ForegroundColor Yellow
w32tm /query /status
Write-Host ""

# 10. Summary
Write-Host "========================================" -ForegroundColor Green
Write-Host "Health Check Complete" -ForegroundColor Green
Write-Host "Report saved to: $reportFile" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Green

Stop-Transcript

# Return summary
$summary = @{
    Timestamp = $timestamp
    ReplicationFailures = if ($failures) { $failures.Count } else { 0 }
    EventLogErrors = if ($errors) { $errors.Count } else { 0 }
    ReportFile = $reportFile
}

return $summary
