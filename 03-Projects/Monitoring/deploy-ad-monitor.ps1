$region = "us-west-2"
$profile = "WACPROD"
$instances = @("i-0745579f46a34da2e", "i-08c78db5cfc6eb412")

# Read the AD monitor script
$adScript = Get-Content C:\AWSKiro\ad-health-monitor.ps1 -Raw
$encodedScript = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($adScript))

# Deploy script to both DCs
Write-Host "Deploying AD Health Monitor to both DCs..." -ForegroundColor Cyan
foreach ($instance in $instances) {
    $deployCmd = "[System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String('$encodedScript')) | Out-File -FilePath C:\Monitoring\ad-health-monitor.ps1 -Encoding UTF8"
    $cmdId = aws ssm send-command --instance-ids $instance --document-name AWS-RunPowerShellScript --parameters "commands=$deployCmd" --profile $profile --region $region --query Command.CommandId --output text
    Write-Host "  Script deployed to $instance - Command ID: $cmdId"
}

Start-Sleep -Seconds 5

# Create scheduled task on both DCs
Write-Host "`nCreating scheduled tasks..." -ForegroundColor Cyan
$taskCmd = @"
`$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -File C:\Monitoring\ad-health-monitor.ps1'
`$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration ([TimeSpan]::MaxValue)
`$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
`$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName 'WACAWSPROD_AD_Health_Monitor' -Action `$action -Trigger `$trigger -Principal `$principal -Settings `$settings -Force
Write-Output 'Scheduled task created'
"@

foreach ($instance in $instances) {
    $cmdId = aws ssm send-command --instance-ids $instance --document-name AWS-RunPowerShellScript --parameters "commands=$taskCmd" --profile $profile --region $region --query Command.CommandId --output text
    Write-Host "  Task created on $instance - Command ID: $cmdId"
}

Write-Host "`nAD Health Monitoring deployed successfully!" -ForegroundColor Green
