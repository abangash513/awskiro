# Production VPN Connectivity Diagnostic Script
# Troubleshooting ping timeout to 10.70.10.10 (WACPRODDC01)

$endpointId = "cvpn-endpoint-0bbd2f9ca471fa45e"
$region = "us-west-2"
$dcIP = "10.70.10.10"
$dcInstanceId = "i-0745579f46a34da2e"

Write-Host "=== Production VPN Connectivity Diagnostics ===" -ForegroundColor Green
Write-Host "Target: WACPRODDC01 ($dcIP)" -ForegroundColor Yellow
Write-Host ""

# Check 1: VPN Endpoint Status
Write-Host "[1] Checking VPN Endpoint Status..." -ForegroundColor Cyan
$endpointStatus = aws ec2 describe-client-vpn-endpoints --client-vpn-endpoint-ids $endpointId --region $region --query 'ClientVpnEndpoints[0].Status.Code' --output text
Write-Host "  Status: $endpointStatus" -ForegroundColor $(if ($endpointStatus -eq "available") { "Green" } else { "Red" })
if ($endpointStatus -ne "available") {
    Write-Host "  ❌ ISSUE: Endpoint is not available. Wait for it to become 'available'." -ForegroundColor Red
}
Write-Host ""

# Check 2: Subnet Associations
Write-Host "[2] Checking Subnet Associations..." -ForegroundColor Cyan
aws ec2 describe-client-vpn-target-networks --client-vpn-endpoint-id $endpointId --region $region --query 'ClientVpnTargetNetworks[*].[TargetNetworkId,Status.Code]' --output table
Write-Host ""

# Check 3: Authorization Rules
Write-Host "[3] Checking Authorization Rules..." -ForegroundColor Cyan
aws ec2 describe-client-vpn-authorization-rules --client-vpn-endpoint-id $endpointId --region $region --query 'AuthorizationRules[*].[DestinationCidr,Status.Code,AccessAll]' --output table
Write-Host ""

# Check 4: Routes
Write-Host "[4] Checking Route Table..." -ForegroundColor Cyan
aws ec2 describe-client-vpn-routes --client-vpn-endpoint-id $endpointId --region $region --query 'Routes[*].[DestinationCidr,TargetSubnet,Status.Code]' --output table
Write-Host ""

# Check 5: Domain Controller Instance Status
Write-Host "[5] Checking Domain Controller Instance..." -ForegroundColor Cyan
$instanceState = aws ec2 describe-instances --instance-ids $dcInstanceId --region $region --query 'Reservations[0].Instances[0].State.Name' --output text
Write-Host "  Instance State: $instanceState" -ForegroundColor $(if ($instanceState -eq "running") { "Green" } else { "Red" })
if ($instanceState -ne "running") {
    Write-Host "  ❌ ISSUE: Domain Controller is not running!" -ForegroundColor Red
}
Write-Host ""

# Check 6: Security Group Rules
Write-Host "[6] Checking Security Group Rules..." -ForegroundColor Cyan
$sgIds = aws ec2 describe-instances --instance-ids $dcInstanceId --region $region --query 'Reservations[0].Instances[0].SecurityGroups[*].GroupId' --output text
Write-Host "  Security Groups: $sgIds" -ForegroundColor Yellow
foreach ($sg in $sgIds -split '\s+') {
    Write-Host "  Checking SG: $sg" -ForegroundColor Yellow
    aws ec2 describe-security-groups --group-ids $sg --region $region --query 'SecurityGroups[0].IpPermissions[?IpProtocol==`icmp` || IpProtocol==`-1`].[IpProtocol,FromPort,ToPort,IpRanges[0].CidrIp]' --output table
}
Write-Host ""

# Check 7: Network ACLs
Write-Host "[7] Checking Network ACLs..." -ForegroundColor Cyan
$subnetId = aws ec2 describe-instances --instance-ids $dcInstanceId --region $region --query 'Reservations[0].Instances[0].SubnetId' --output text
Write-Host "  DC Subnet: $subnetId" -ForegroundColor Yellow
$naclId = aws ec2 describe-network-acls --filters "Name=association.subnet-id,Values=$subnetId" --region $region --query 'NetworkAcls[0].NetworkAclId' --output text
Write-Host "  Network ACL: $naclId" -ForegroundColor Yellow
Write-Host ""

# Check 8: Local Network Routing
Write-Host "[8] Checking Local Network Routes..." -ForegroundColor Cyan
Write-Host "  Looking for route to 10.70.0.0/16..." -ForegroundColor Yellow
route print | findstr "10.70"
Write-Host ""

# Check 9: Test Connectivity
Write-Host "[9] Testing Connectivity..." -ForegroundColor Cyan
Write-Host "  Pinging $dcIP..." -ForegroundColor Yellow
$pingResult = Test-Connection -ComputerName $dcIP -Count 2 -Quiet
if ($pingResult) {
    Write-Host "  ✅ Ping successful!" -ForegroundColor Green
} else {
    Write-Host "  ❌ Ping failed!" -ForegroundColor Red
}
Write-Host ""

Write-Host "  Testing RDP port (3389)..." -ForegroundColor Yellow
$rdpTest = Test-NetConnection -ComputerName $dcIP -Port 3389 -WarningAction SilentlyContinue
if ($rdpTest.TcpTestSucceeded) {
    Write-Host "  ✅ RDP port is open!" -ForegroundColor Green
} else {
    Write-Host "  ❌ RDP port is not accessible!" -ForegroundColor Red
}
Write-Host ""

# Summary and Recommendations
Write-Host "=== Summary and Recommendations ===" -ForegroundColor Green
Write-Host ""

if ($endpointStatus -ne "available") {
    Write-Host "❌ VPN Endpoint Issue:" -ForegroundColor Red
    Write-Host "   The VPN endpoint is not in 'available' state." -ForegroundColor Yellow
    Write-Host "   Action: Wait 5-10 minutes after deployment, then try again." -ForegroundColor Yellow
    Write-Host ""
}

if ($instanceState -ne "running") {
    Write-Host "❌ Domain Controller Issue:" -ForegroundColor Red
    Write-Host "   The Domain Controller instance is not running." -ForegroundColor Yellow
    Write-Host "   Action: Start the instance using AWS Console or CLI." -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "Common Issues and Solutions:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. VPN Not Connected:" -ForegroundColor Yellow
Write-Host "   - Open AWS VPN Client" -ForegroundColor White
Write-Host "   - Verify 'Connected' status (green)" -ForegroundColor White
Write-Host "   - Check your IP is in 10.200.x.x range" -ForegroundColor White
Write-Host ""

Write-Host "2. Security Group Blocking ICMP:" -ForegroundColor Yellow
Write-Host "   - Security groups may block ping (ICMP)" -ForegroundColor White
Write-Host "   - Try RDP instead: mstsc /v:$dcIP" -ForegroundColor White
Write-Host "   - If RDP works, ping is just blocked by security rules" -ForegroundColor White
Write-Host ""

Write-Host "3. Subnet Association Pending:" -ForegroundColor Yellow
Write-Host "   - Check if associations show 'associated' (not 'associating')" -ForegroundColor White
Write-Host "   - Wait 5-10 minutes if still associating" -ForegroundColor White
Write-Host "   - Disconnect and reconnect VPN" -ForegroundColor White
Write-Host ""

Write-Host "4. Missing Authorization Rules:" -ForegroundColor Yellow
Write-Host "   - Check if 10.70.0.0/16 is authorized above" -ForegroundColor White
Write-Host "   - If missing, run Setup-Prod-Client-VPN.ps1 again" -ForegroundColor White
Write-Host ""

Write-Host "Quick Test Commands:" -ForegroundColor Cyan
Write-Host "  # Try RDP (may work even if ping doesn't)" -ForegroundColor White
Write-Host "  mstsc /v:$dcIP" -ForegroundColor Green
Write-Host ""
Write-Host "  # Test RDP port" -ForegroundColor White
Write-Host "  Test-NetConnection -ComputerName $dcIP -Port 3389" -ForegroundColor Green
Write-Host ""
Write-Host "  # Check VPN client IP" -ForegroundColor White
Write-Host "  ipconfig | findstr '10.200'" -ForegroundColor Green
Write-Host ""

Write-Host "=== Diagnostic Complete ===" -ForegroundColor Green
