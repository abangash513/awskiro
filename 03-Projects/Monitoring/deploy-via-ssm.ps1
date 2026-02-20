# Deploy CloudWatch Agent and AD Monitoring via SSM
$region = "us-west-2"
$profile = "WACPROD"
$dc01 = "i-0745579f46a34da2e"
$dc02 = "i-08c78db5cfc6eb412"

# Create monitoring folder and deploy files
$setupCommands = @"
New-Item -Path C:\Monitoring -ItemType Directory -Force
Set-Location C:\Monitoring

# Download CloudWatch Agent
`$url = 'https://s3.amazonaws.com/amazoncloudwatch-agent/windows/amd64/latest/amazon-cloudwatch-agent.msi'
Invoke-WebRequest -Uri `$url -OutFile C:\Monitoring\amazon-cloudwatch-agent.msi

# Install CloudWatch Agent
Start-Process msiexec.exe -ArgumentList '/i C:\Monitoring\amazon-cloudwatch-agent.msi /qn' -Wait

# Create CloudWatch Agent Config
`$config = @'
{
  \"metrics\": {
    \"namespace\": \"CWAgent\",
    \"metrics_collected\": {
      \"LogicalDisk\": {
        \"measurement\": [{\"name\": \"% Free Space\",\"rename\": \"DiskFreePercent\",\"unit\": \"Percent\"}],
        \"metrics_collection_interval\": 60,
        \"resources\": [\"*\"]
      },
      \"Memory\": {
        \"measurement\": [{\"name\": \"% Committed Bytes In Use\",\"rename\": \"MemoryUtilization\",\"unit\": \"Percent\"}],
        \"metrics_collection_interval\": 60
      },
      \"Processor\": {
        \"measurement\": [{\"name\": \"% Processor Time\",\"rename\": \"CPUUtilization\",\"unit\": \"Percent\"}],
        \"metrics_collection_interval\": 60,
        \"resources\": [\"_Total\"]
      }
    }
  },
  \"logs\": {
    \"logs_collected\": {
      \"windows_events\": {
        \"collect_list\": [
          {\"event_name\": \"System\",\"event_levels\": [\"ERROR\", \"CRITICAL\"],\"log_group_name\": \"/aws/ec2/wac-prod-dc/system\",\"log_stream_name\": \"{instance_id}\"},
          {\"event_name\": \"Directory Service\",\"event_levels\": [\"ERROR\", \"CRITICAL\", \"WARNING\"],\"log_group_name\": \"/aws/ec2/wac-prod-dc/ad\",\"log_stream_name\": \"{instance_id}\"},
          {\"event_name\": \"DNS Server\",\"event_levels\": [\"ERROR\", \"CRITICAL\"],\"log_group_name\": \"/aws/ec2/wac-prod-dc/dns\",\"log_stream_name\": \"{instance_id}\"}
        ]
      }
    }
  }
}
'@
`$config | Out-File -FilePath C:\Monitoring\cloudwatch-agent-config.json -Encoding UTF8

# Start CloudWatch Agent
& 'C:\Program Files\Amazon\AmazonCloudWatchAgent\amazon-cloudwatch-agent-ctl.ps1' -a fetch-config -m ec2 -s -c file:C:\Monitoring\cloudwatch-agent-config.json

# Create AD Health Monitor Script
`$adScript = @'
`$region = \"us-west-2\"
`$topicArn = (aws sns list-topics --region `$region --query \"Topics[?contains(TopicArn, 'WACAWSPROD_Monitoring')].TopicArn\" --output text)
`$hostname = `$env:COMPUTERNAME
`$adServices = @('NTDS', 'DNS', 'Netlogon', 'kdc', 'W32Time')
`$failedServices = @()
foreach (`$service in `$adServices) {
    `$svc = Get-Service -Name `$service -ErrorAction SilentlyContinue
    if (`$svc.Status -ne 'Running') {
        `$failedServices += \"`$service is `$(`$svc.Status)\"
    }
}
`$replStatus = repadmin /showrepl 2>&1
if (`$LASTEXITCODE -ne 0) {
    `$failedServices += \"AD Replication Failed\"
}
`$replErrors = repadmin /showrepl | Select-String -Pattern \"last error\"
if (`$replErrors) {
    `$failedServices += \"AD Replication errors detected\"
}
`$replPartners = Get-ADReplicationPartnerMetadata -Target `$hostname -Scope Server
foreach (`$partner in `$replPartners) {
    if (`$partner.LastReplicationResult -ne 0) {
        `$failedServices += \"Replication failed with `$(`$partner.Partner) - Error: `$(`$partner.LastReplicationResult)\"
    }
    `$timeSinceLastRepl = (Get-Date) - `$partner.LastReplicationSuccess
    if (`$timeSinceLastRepl.TotalMinutes -gt 60) {
        `$failedServices += \"No replication from `$(`$partner.Partner) for `$([math]::Round(`$timeSinceLastRepl.TotalMinutes)) minutes\"
    }
}
`$replQueue = repadmin /queue
if (`$replQueue -match \"(\\d+) item\\(s\\) in queue\") {
    `$queueCount = [int]`$matches[1]
    if (`$queueCount -gt 50) {
        `$failedServices += \"High replication queue: `$queueCount items\"
    }
}
if (!(Test-Path \"\\\\`$hostname\\SYSVOL\")) {
    `$failedServices += \"SYSVOL share not accessible\"
}
`$dnsTest = Resolve-DnsName -Name `$env:USERDNSDOMAIN -ErrorAction SilentlyContinue
if (!`$dnsTest) {
    `$failedServices += \"DNS resolution failed\"
}
if (`$failedServices.Count -gt 0) {
    `$message = \"AD Health Alert on `$hostname``n``nIssues:``n\" + (`$failedServices -join \"``n\")
    aws sns publish --topic-arn `$topicArn --subject \"AD Health Alert - `$hostname\" --message `$message --region `$region
}
'@
`$adScript | Out-File -FilePath C:\Monitoring\ad-health-monitor.ps1 -Encoding UTF8

# Create Scheduled Task
`$action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument '-NoProfile -ExecutionPolicy Bypass -File C:\Monitoring\ad-health-monitor.ps1'
`$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration ([TimeSpan]::MaxValue)
`$principal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType ServiceAccount -RunLevel Highest
`$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName 'WACAWSPROD_AD_Health_Monitor' -Action `$action -Trigger `$trigger -Principal `$principal -Settings `$settings -Force

Write-Output 'Monitoring setup complete on' `$env:COMPUTERNAME
"@

Write-Host "Deploying to WACPRODDC01..." -ForegroundColor Cyan
aws ssm send-command --instance-ids $dc01 --document-name "AWS-RunPowerShellScript" --parameters "commands=`"$setupCommands`"" --profile $profile --region $region

Write-Host "`nDeploying to WACPRODDC02..." -ForegroundColor Cyan
aws ssm send-command --instance-ids $dc02 --document-name "AWS-RunPowerShellScript" --parameters "commands=`"$setupCommands`"" --profile $profile --region $region

Write-Host "`nDeployment commands sent! Check SSM Run Command console for status." -ForegroundColor Green
