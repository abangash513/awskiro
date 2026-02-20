# WAC Production Client VPN Setup Script
# Purpose: Create Client VPN endpoint for remote administration access to Production VPC and Domain Controllers
# Date: January 31, 2026

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "WAC Production Client VPN Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$region = "us-west-2"
$vpcId = "vpc-014b66d7ca2309134"
$vpcCidr = "10.70.0.0/16"
$clientCidrBlock = "10.200.0.0/16"
$dnsServer = "10.70.0.2"

# Subnets for VPN association
$subnet1 = "subnet-02c8f0d7d48510db0"
$subnet2 = "subnet-02582cf0ad3fa857b"

# Domain Controllers
$dc1Ip = "10.70.10.10"
$dc2Ip = "10.70.11.10"

# Certificate ARNs
$serverCertArn = "arn:aws:acm:us-west-2:466090007609:certificate/fc6b385c-1d75-49de-91a2-93fae977030a"
$clientCertArn = "arn:aws:acm:us-west-2:466090007609:certificate/e3437609-1535-4ed7-b6e8-dceb076f67df"

# Certificate directory
$certDir = "vpn-certs-prod-20260119-220611"

Write-Host "Configuration Summary:" -ForegroundColor Yellow
Write-Host "  VPC ID: $vpcId" -ForegroundColor White
Write-Host "  VPC CIDR: $vpcCidr" -ForegroundColor White
Write-Host "  Client CIDR: $clientCidrBlock" -ForegroundColor White
Write-Host "  DNS Server: $dnsServer" -ForegroundColor White
Write-Host "  Subnet 1: $subnet1 (Private-2a)" -ForegroundColor White
Write-Host "  Subnet 2: $subnet2 (Private-2b)" -ForegroundColor White
Write-Host "  DC1: $dc1Ip (WACPRODDC01)" -ForegroundColor White
Write-Host "  DC2: $dc2Ip (WACPRODDC02)" -ForegroundColor White
Write-Host ""

# Step 1: Create CloudWatch log group
Write-Host "[Step 1/8] Creating CloudWatch log group..." -ForegroundColor Yellow
try {
    aws logs create-log-group --log-group-name /aws/clientvpn/prod-admin-vpn --region $region 2>&1 | Out-Null
    Write-Host "  Log group created" -ForegroundColor Green
} catch {
    Write-Host "  Log group may already exist (continuing)" -ForegroundColor Cyan
}

aws logs put-retention-policy --log-group-name /aws/clientvpn/prod-admin-vpn --retention-in-days 180 --region $region
Write-Host "  Retention policy set to 180 days" -ForegroundColor Green
Write-Host ""

# Step 2: Create VPN endpoint
Write-Host "[Step 2/8] Creating Client VPN endpoint..." -ForegroundColor Yellow
Write-Host "  This may take 5-10 minutes..." -ForegroundColor Cyan

$vpnEndpointId = aws ec2 create-client-vpn-endpoint `
  --client-cidr-block $clientCidrBlock `
  --server-certificate-arn $serverCertArn `
  --authentication-options Type=certificate-authentication,MutualAuthentication={ClientRootCertificateChainArn=$clientCertArn} `
  --connection-log-options Enabled=true,CloudwatchLogGroup=/aws/clientvpn/prod-admin-vpn `
  --dns-servers $dnsServer `
  --vpc-id $vpcId `
  --description "WAC Production Admin VPN - Remote access to Domain Controllers" `
  --split-tunnel `
  --transport-protocol udp `
  --vpn-port 443 `
  --region $region `
  --tag-specifications 'ResourceType=client-vpn-endpoint,Tags=[{Key=Name,Value=WAC-Prod-Admin-VPN},{Key=Environment,Value=Production},{Key=Purpose,Value=DomainControllerAccess}]' `
  --query 'ClientVpnEndpointId' `
  --output text

if ($LASTEXITCODE -ne 0) {
    Write-Host "  Failed to create VPN endpoint" -ForegroundColor Red
    exit 1
}

Write-Host "  VPN endpoint created: $vpnEndpointId" -ForegroundColor Green
Write-Host ""

# Step 3: Wait for endpoint to become available
Write-Host "[Step 3/8] Waiting for VPN endpoint to become available..." -ForegroundColor Yellow
$maxWait = 600
$waited = 0
$interval = 15

while ($waited -lt $maxWait) {
    $status = aws ec2 describe-client-vpn-endpoints `
      --client-vpn-endpoint-ids $vpnEndpointId `
      --region $region `
      --query 'ClientVpnEndpoints[0].Status.Code' `
      --output text
    
    if ($status -eq "available") {
        Write-Host "  VPN endpoint is available" -ForegroundColor Green
        break
    }
    
    Write-Host "  Status: $status (waiting...)" -ForegroundColor Cyan
    Start-Sleep -Seconds $interval
    $waited += $interval
}

if ($waited -ge $maxWait) {
    Write-Host "  Timeout waiting for VPN endpoint" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 4: Associate with subnet 1
Write-Host "[Step 4/8] Associating VPN with subnet 1 (Private-2a)..." -ForegroundColor Yellow
$assoc1 = aws ec2 associate-client-vpn-target-network `
  --client-vpn-endpoint-id $vpnEndpointId `
  --subnet-id $subnet1 `
  --region $region `
  --query 'AssociationId' `
  --output text

Write-Host "  Associated with subnet 1: $assoc1" -ForegroundColor Green
Write-Host ""

# Step 5: Associate with subnet 2
Write-Host "[Step 5/8] Associating VPN with subnet 2 (Private-2b)..." -ForegroundColor Yellow
$assoc2 = aws ec2 associate-client-vpn-target-network `
  --client-vpn-endpoint-id $vpnEndpointId `
  --subnet-id $subnet2 `
  --region $region `
  --query 'AssociationId' `
  --output text

Write-Host "  Associated with subnet 2: $assoc2" -ForegroundColor Green
Write-Host ""

# Step 6: Add authorization rule
Write-Host "[Step 6/8] Adding authorization rule for VPC access..." -ForegroundColor Yellow
aws ec2 authorize-client-vpn-ingress `
  --client-vpn-endpoint-id $vpnEndpointId `
  --target-network-cidr $vpcCidr `
  --authorize-all-groups `
  --description "Allow access to entire Production VPC" `
  --region $region | Out-Null

Write-Host "  Authorization rule added for $vpcCidr" -ForegroundColor Green
Write-Host ""

# Step 7: Add routes
Write-Host "[Step 7/8] Adding routes to VPC..." -ForegroundColor Yellow

aws ec2 create-client-vpn-route `
  --client-vpn-endpoint-id $vpnEndpointId `
  --destination-cidr-block $vpcCidr `
  --target-vpc-subnet-id $subnet1 `
  --description "Route to Production VPC via Private-2a" `
  --region $region | Out-Null

Write-Host "  Route added via subnet 1" -ForegroundColor Green
Write-Host ""

# Step 8: Generate OVPN configuration file
Write-Host "[Step 8/8] Generating VPN client configuration file..." -ForegroundColor Yellow

$vpnConfig = aws ec2 export-client-vpn-client-configuration `
  --client-vpn-endpoint-id $vpnEndpointId `
  --region $region `
  --output text

$caCert = Get-Content "$certDir/ca.crt" -Raw
$clientCert = Get-Content "$certDir/client1.crt" -Raw
$clientKey = Get-Content "$certDir/client1.key" -Raw

$completeConfig = $vpnConfig + "`n`n<ca>`n$caCert`n</ca>`n`n<cert>`n$clientCert`n</cert>`n`n<key>`n$clientKey`n</key>`n"
$completeConfig | Out-File -FilePath "wac-prod-admin-vpn.ovpn" -Encoding ASCII

Write-Host "  VPN configuration file created: wac-prod-admin-vpn.ovpn" -ForegroundColor Green
Write-Host ""

# Update configuration file
$config = @{
    Region = $region
    VpcId = $vpcId
    VpcCidr = $vpcCidr
    ClientCidr = $clientCidrBlock
    DnsServer = $dnsServer
    Subnet1 = $subnet1
    Subnet2 = $subnet2
    DC1 = $dc1Ip
    DC2 = $dc2Ip
    ServerCertArn = $serverCertArn
    ClientCertArn = $clientCertArn
    CertDir = $certDir
    EndpointId = $vpnEndpointId
    Association1 = $assoc1
    Association2 = $assoc2
}

$config | ConvertTo-Json | Out-File -FilePath "prod-vpn-config.json" -Encoding ASCII

Write-Host "========================================" -ForegroundColor Green
Write-Host "Production VPN Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "VPN Endpoint Details:" -ForegroundColor Cyan
Write-Host "  Endpoint ID: $vpnEndpointId" -ForegroundColor White
Write-Host "  VPC: $vpcId ($vpcCidr)" -ForegroundColor White
Write-Host "  Client CIDR: $clientCidrBlock" -ForegroundColor White
Write-Host "  DNS Server: $dnsServer" -ForegroundColor White
Write-Host ""
Write-Host "Domain Controllers Accessible:" -ForegroundColor Cyan
Write-Host "  WACPRODDC01: $dc1Ip (us-west-2a)" -ForegroundColor White
Write-Host "  WACPRODDC02: $dc2Ip (us-west-2b)" -ForegroundColor White
Write-Host ""
Write-Host "Configuration Files:" -ForegroundColor Cyan
Write-Host "  VPN Config: wac-prod-admin-vpn.ovpn" -ForegroundColor White
Write-Host "  Settings: prod-vpn-config.json" -ForegroundColor White
Write-Host "  Certificates: $certDir/" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Download AWS VPN Client from:" -ForegroundColor White
Write-Host "     https://aws.amazon.com/vpn/client-vpn-download/" -ForegroundColor Cyan
Write-Host "  2. Import wac-prod-admin-vpn.ovpn into AWS VPN Client" -ForegroundColor White
Write-Host "  3. Connect to WAC Prod Admin VPN" -ForegroundColor White
Write-Host "  4. Test access to Domain Controllers:" -ForegroundColor White
Write-Host "     - RDP to $dc1Ip (WACPRODDC01)" -ForegroundColor Cyan
Write-Host "     - RDP to $dc2Ip (WACPRODDC02)" -ForegroundColor Cyan
Write-Host ""
Write-Host "CloudWatch Logs:" -ForegroundColor Yellow
Write-Host "  Log Group: /aws/clientvpn/prod-admin-vpn" -ForegroundColor White
Write-Host "  Retention: 180 days" -ForegroundColor White
Write-Host ""
Write-Host "Security Reminder:" -ForegroundColor Red
Write-Host "  Keep wac-prod-admin-vpn.ovpn file secure" -ForegroundColor White
Write-Host "  Do not commit to version control" -ForegroundColor White
Write-Host "  Distribute only to authorized administrators" -ForegroundColor White
Write-Host ""
