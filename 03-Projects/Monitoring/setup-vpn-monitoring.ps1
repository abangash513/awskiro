# Setup VPN Monitoring with CloudWatch Alarms
$region = "us-west-2"
$profile = "WACPROD"
$vpnId = "vpn-025a12d4214e767b7"
$topicArn = "arn:aws:sns:us-west-2:466090007609:WACAWSPROD_Monitoring"

Write-Host "Creating CloudWatch alarms for VPN tunnels..." -ForegroundColor Cyan

# Alarm for Tunnel 1 Down
aws cloudwatch put-metric-alarm --alarm-name "VPN-Prod-Tunnel1-Down" --alarm-description "Alert when VPN Tunnel 1 is down" --metric-name TunnelState --namespace AWS/VPN --statistic Maximum --period 60 --threshold 0 --comparison-operator LessThanOrEqualToThreshold --evaluation-periods 2 --dimensions Name=VpnId,Value=$vpnId Name=TunnelIpAddress,Value=44.252.167.140 --alarm-actions $topicArn --profile $profile --region $region

# Alarm for Tunnel 2 Down
aws cloudwatch put-metric-alarm --alarm-name "VPN-Prod-Tunnel2-Down" --alarm-description "Alert when VPN Tunnel 2 is down" --metric-name TunnelState --namespace AWS/VPN --statistic Maximum --period 60 --threshold 0 --comparison-operator LessThanOrEqualToThreshold --evaluation-periods 2 --dimensions Name=VpnId,Value=$vpnId Name=TunnelIpAddress,Value=52.24.69.66 --alarm-actions $topicArn --profile $profile --region $region

# Alarm for low traffic volume (Tunnel 1)
aws cloudwatch put-metric-alarm --alarm-name "VPN-Prod-Tunnel1-LowTraffic" --alarm-description "Alert when VPN Tunnel 1 traffic is low" --metric-name TunnelDataIn --namespace AWS/VPN --statistic Sum --period 300 --threshold 1000 --comparison-operator LessThanThreshold --evaluation-periods 3 --dimensions Name=VpnId,Value=$vpnId Name=TunnelIpAddress,Value=44.252.167.140 --alarm-actions $topicArn --profile $profile --region $region

# Alarm for high traffic volume (Tunnel 1)
aws cloudwatch put-metric-alarm --alarm-name "VPN-Prod-Tunnel1-HighTraffic" --alarm-description "Alert when VPN Tunnel 1 traffic is high" --metric-name TunnelDataIn --namespace AWS/VPN --statistic Sum --period 300 --threshold 100000000 --comparison-operator GreaterThanThreshold --evaluation-periods 2 --dimensions Name=VpnId,Value=$vpnId Name=TunnelIpAddress,Value=44.252.167.140 --alarm-actions $topicArn --profile $profile --region $region

Write-Host "`nCloudWatch alarms created!" -ForegroundColor Green
Write-Host "`nCreating Lambda function for auto-reset..." -ForegroundColor Cyan

# Upload VPN monitor script to S3
aws s3 cp vpn-monitor-reset.ps1 s3://wac-prod-scripts/vpn-monitor-reset.ps1 --profile $profile --region $region

Write-Host "`nSetup complete!" -ForegroundColor Green
Write-Host "VPN monitoring alarms created for: Prod-VPN-Meraki-Static" -ForegroundColor Cyan
