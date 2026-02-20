# Setup AD Health Monitoring Scheduled Task
# Run this ON each DC (WACPRODDC01 and WACPRODDC02)

$scriptPath = "C:\AWSKiro\ad-health-monitor.ps1"
$taskName = "WAC-AD-Health-Monitor"

# Create scheduled task to run every 5 minutes
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration ([TimeSpan]::MaxValue)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force

Write-Host "AD health monitoring scheduled task created: $taskName" -ForegroundColor Green
Write-Host "Runs every 5 minutes to check AD services, replication, SYSVOL, and DNS" -ForegroundColor Cyan
