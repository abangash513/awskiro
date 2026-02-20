# VPN Tunnel Monitor and Auto-Reset Script
$region = "us-west-2"
$profile = "WACPROD"
$vpnId = "vpn-025a12d4214e767b7"
$topicArn = "arn:aws:sns:us-west-2:466090007609:WACAWSPROD_Monitoring"
$maxRetries = 3
$retryInterval = 180 # 3 minutes

# Get VPN tunnel status (Tunnel 1 only)
$vpnStatus = aws ec2 describe-vpn-connections --vpn-connection-ids $vpnId --profile $profile --region $region | ConvertFrom-Json
$tunnel1 = $vpnStatus.VpnConnections[0].VgwTelemetry | Where-Object { $_.OutsideIpAddress -eq "44.252.167.140" }

$downTunnels = @()
if ($tunnel1.Status -ne "UP") {
    $downTunnels += $tunnel1.OutsideIpAddress
}

if ($downTunnels.Count -gt 0) {
    Write-Host "VPN Tunnels DOWN: $($downTunnels -join ', ')" -ForegroundColor Red
    
    # Attempt to reset tunnels
    $resetAttempts = 0
    $resetSuccess = $false
    
    while ($resetAttempts -lt $maxRetries -and !$resetSuccess) {
        $resetAttempts++
        Write-Host "Reset attempt $resetAttempts of $maxRetries..." -ForegroundColor Yellow
        
        # Reset VPN connection
        aws ec2 reset-vpn-connection --vpn-connection-id $vpnId --profile $profile --region $region
        
        # Wait for reset interval
        Start-Sleep -Seconds $retryInterval
        
        # Check status again (Tunnel 1 only)
        $vpnStatus = aws ec2 describe-vpn-connections --vpn-connection-ids $vpnId --profile $profile --region $region | ConvertFrom-Json
        $tunnel1 = $vpnStatus.VpnConnections[0].VgwTelemetry | Where-Object { $_.OutsideIpAddress -eq "44.252.167.140" }
        
        $stillDown = @()
        if ($tunnel1.Status -ne "UP") {
            $stillDown += $tunnel1.OutsideIpAddress
        }
        
        if ($stillDown.Count -eq 0) {
            $resetSuccess = $true
            $message = "VPN TUNNEL RECOVERY SUCCESS`n`nVPN Connection: Prod-VPN-Meraki-Static ($vpnId)`n`nTunnels that were down: $($downTunnels -join ', ')`nReset attempts: $resetAttempts`nStatus: ALL TUNNELS NOW UP`n`nTimestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
            aws sns publish --topic-arn $topicArn --subject "VPN Recovery - Tunnels Restored" --message $message --profile $profile --region $region
            Write-Host "VPN tunnels restored successfully" -ForegroundColor Green
        }
    }
    
    # If still down after all retries, send alert
    if (!$resetSuccess) {
        $message = "CRITICAL: VPN TUNNEL FAILURE`n`nVPN Connection: Prod-VPN-Meraki-Static ($vpnId)`n`nTunnels DOWN: $($stillDown -join ', ')`nReset attempts: $resetAttempts`nStatus: FAILED TO RESTORE`n`nAction Required: Manual intervention needed`n`nTimestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        aws sns publish --topic-arn $topicArn --subject "CRITICAL: VPN Tunnel Down - Manual Action Required" --message $message --profile $profile --region $region
        Write-Host "Failed to restore VPN tunnels after $maxRetries attempts" -ForegroundColor Red
    }
} else {
    Write-Host "All VPN tunnels are UP" -ForegroundColor Green
}
