# Active Directory Health Monitoring Script
# Deploy this on WACPRODDC01 and WACPRODDC02
# Run as scheduled task every 5 minutes

$region = "us-west-2"
$topicArn = (aws sns list-topics --region $region --query "Topics[?contains(TopicArn, 'WACAWSPROD_Monitoring')].TopicArn" --output text)
$hostname = $env:COMPUTERNAME

# Check AD Services
$adServices = @('NTDS', 'DNS', 'Netlogon', 'kdc', 'W32Time')
$failedServices = @()

foreach ($service in $adServices) {
    $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
    if ($svc.Status -ne 'Running') {
        $failedServices += "$service is $($svc.Status)"
    }
}

# Check AD Replication
$replStatus = repadmin /showrepl 2>&1
if ($LASTEXITCODE -ne 0) {
    $failedServices += "AD Replication Failed"
}

# Check for replication errors
$replErrors = repadmin /showrepl | Select-String -Pattern "last error"
if ($replErrors) {
    $failedServices += "AD Replication errors detected"
}

# Check replication partners
$replPartners = Get-ADReplicationPartnerMetadata -Target $hostname -Scope Server
foreach ($partner in $replPartners) {
    if ($partner.LastReplicationResult -ne 0) {
        $failedServices += "Replication failed with $($partner.Partner) - Error: $($partner.LastReplicationResult)"
    }
    $timeSinceLastRepl = (Get-Date) - $partner.LastReplicationSuccess
    if ($timeSinceLastRepl.TotalMinutes -gt 60) {
        $failedServices += "No replication from $($partner.Partner) for $([math]::Round($timeSinceLastRepl.TotalMinutes)) minutes"
    }
}

# Check replication queue
$replQueue = repadmin /queue
if ($replQueue -match "(\d+) item\(s\) in queue") {
    $queueCount = [int]$matches[1]
    if ($queueCount -gt 50) {
        $failedServices += "High replication queue: $queueCount items"
    }
}

# Check SYSVOL Share
if (!(Test-Path "\\$hostname\SYSVOL")) {
    $failedServices += "SYSVOL share not accessible"
}

# Check DNS Resolution
$dnsTest = Resolve-DnsName -Name $env:USERDNSDOMAIN -ErrorAction SilentlyContinue
if (!$dnsTest) {
    $failedServices += "DNS resolution failed"
}

# Send alert if issues found
if ($failedServices.Count -gt 0) {
    $message = "AD Health Alert on $hostname`n`nIssues:`n" + ($failedServices -join "`n")
    aws sns publish --topic-arn $topicArn --subject "AD Health Alert - $hostname" --message $message --region $region
    Write-Host "Alert sent: $message" -ForegroundColor Red
} else {
    Write-Host "AD health check passed on $hostname" -ForegroundColor Green
}
