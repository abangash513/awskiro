# Fix VPN Endpoint - Delete old and create new with proper certificates

Write-Host "=== Fixing VPN Endpoint with Proper Certificates ===" -ForegroundColor Green
Write-Host ""

$region = "us-west-2"
$vpcId = "vpc-014ec3818a5b2940e"
$vpcCidr = "10.60.0.0/16"
$vpnClientCidr = "10.100.0.0/16"
$adSubnetA = "subnet-06888c11ff940086d"
$adSubnetB = "subnet-0aebef249b6787cba"
$logGroupName = "/aws/clientvpn/dev-admin-vpn"
$oldEndpointId = "cvpn-endpoint-0f3409fb7606460cf"
$certDir = "vpn-certs-fixed-20260119-212059"

# Step 1: Delete old VPN endpoint
Write-Host "[Step 1] Deleting old VPN endpoint..." -ForegroundColor Cyan
Write-Host "  Endpoint ID: $oldEndpointId" -ForegroundColor Gray

# Get associations
Write-Host "  [1.1] Getting subnet associations..." -ForegroundColor Gray
$associations = aws ec2 describe-client-vpn-target-networks --client-vpn-endpoint-id $oldEndpointId --region $region --query 'ClientVpnTargetNetworks[*].AssociationId' --output text

if ($associations) {
    $assocList = $associations -split '\s+'
    foreach ($assoc in $assocList) {
        Write-Host "    Disassociating: $assoc" -ForegroundColor Gray
        aws ec2 disassociate-client-vpn-target-network --client-vpn-endpoint-id $oldEndpointId --association-id $assoc --region $region 2>&1 | Out-Null
    }
    Write-Host "    Waiting for disassociation (30 seconds)..." -ForegroundColor Gray
    Start-Sleep -Seconds 30
}

Write-Host "  [1.2] Deleting VPN endpoint..." -ForegroundColor Gray
aws ec2 delete-client-vpn-endpoint --client-vpn-endpoint-id $oldEndpointId --region $region 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "    Old VPN endpoint deleted" -ForegroundColor Green
} else {
    Write-Host "    Failed to delete (may already be deleted)" -ForegroundColor Yellow
}
Write-Host ""

# Step 2: Delete old certificates from ACM
Write-Host "[Step 2] Cleaning up old certificates..." -ForegroundColor Cyan
$oldCerts = aws acm list-certificates --region $region --query 'CertificateSummaryList[?contains(DomainName,`wac-vpn`)].CertificateArn' --output text

if ($oldCerts) {
    $certList = $oldCerts -split '\s+'
    foreach ($cert in $certList) {
        Write-Host "  Deleting certificate: $cert" -ForegroundColor Gray
        aws acm delete-certificate --certificate-arn $cert --region $region 2>&1 | Out-Null
    }
    Write-Host "  Old certificates deleted" -ForegroundColor Green
} else {
    Write-Host "  No old certificates to delete" -ForegroundColor Yellow
}
Write-Host ""

# Step 3: Import new certificates
Write-Host "[Step 3] Importing new certificates to ACM..." -ForegroundColor Cyan
Push-Location $certDir

Write-Host "  [3.1] Importing server certificate..." -ForegroundColor Gray
$serverCertArn = aws acm import-certificate `
    --certificate "fileb://server.crt" `
    --private-key "fileb://server.key" `
    --certificate-chain "fileb://ca.crt" `
    --region $region `
    --query 'CertificateArn' `
    --output text

if ($LASTEXITCODE -ne 0) {
    Write-Host "    Failed to import server certificate" -ForegroundColor Red
    Pop-Location
    exit 1
}
Write-Host "    Server certificate imported" -ForegroundColor Green
Write-Host "    ARN: $serverCertArn" -ForegroundColor Yellow

Write-Host "  [3.2] Importing client certificate..." -ForegroundColor Gray
$clientCertArn = aws acm import-certificate `
    --certificate "fileb://client1.crt" `
    --private-key "fileb://client1.key" `
    --certificate-chain "fileb://ca.crt" `
    --region $region `
    --query 'CertificateArn' `
    --output text

if ($LASTEXITCODE -ne 0) {
    Write-Host "    Failed to import client certificate" -ForegroundColor Red
    Pop-Location
    exit 1
}
Write-Host "    Client certificate imported" -ForegroundColor Green
Write-Host "    ARN: $clientCertArn" -ForegroundColor Yellow

Pop-Location
Write-Host ""

# Step 4: Create new VPN endpoint
Write-Host "[Step 4] Creating new VPN endpoint..." -ForegroundColor Cyan
Write-Host "  This may take 5-10 minutes..." -ForegroundColor Yellow

$vpnEndpointId = aws ec2 create-client-vpn-endpoint `
    --client-cidr-block $vpnClientCidr `
    --server-certificate-arn $serverCertArn `
    --authentication-options "Type=certificate-authentication,MutualAuthentication={ClientRootCertificateChainArn=$clientCertArn}" `
    --connection-log-options "Enabled=true,CloudwatchLogGroup=$logGroupName" `
    --dns-servers "10.60.0.2" `
    --vpc-id $vpcId `
    --description "WAC Dev Admin VPN (Fixed)" `
    --split-tunnel `
    --tag-specifications "ResourceType=client-vpn-endpoint,Tags=[{Key=Name,Value=WAC-Dev-Admin-VPN-Fixed},{Key=Environment,Value=Development},{Key=Phase,Value=3}]" `
    --region $region `
    --query 'ClientVpnEndpointId' `
    --output text

if ($LASTEXITCODE -ne 0) {
    Write-Host "  Failed to create VPN endpoint" -ForegroundColor Red
    exit 1
}

Write-Host "  VPN Endpoint created: $vpnEndpointId" -ForegroundColor Green
Write-Host ""

# Wait for endpoint
Write-Host "  Waiting for endpoint to become available..." -ForegroundColor Gray
$maxWait = 600
$waited = 0
$interval = 15

while ($waited -lt $maxWait) {
    $state = aws ec2 describe-client-vpn-endpoints `
        --client-vpn-endpoint-ids $vpnEndpointId `
        --region $region `
        --query 'ClientVpnEndpoints[0].Status.Code' `
        --output text

    if ($state -eq "available") {
        Write-Host "  VPN Endpoint is available!" -ForegroundColor Green
        break
    }

    Write-Host "    Status: $state (waited $waited seconds)" -ForegroundColor Gray
    Start-Sleep -Seconds $interval
    $waited += $interval
}
Write-Host ""

# Step 5: Associate subnets
Write-Host "[Step 5] Associating subnets..." -ForegroundColor Cyan

Write-Host "  [5.1] Associating AD-A subnet..." -ForegroundColor Gray
aws ec2 associate-client-vpn-target-network --client-vpn-endpoint-id $vpnEndpointId --subnet-id $adSubnetA --region $region 2>&1 | Out-Null
Write-Host "    AD-A associated" -ForegroundColor Green

Write-Host "  [5.2] Associating AD-B subnet..." -ForegroundColor Gray
aws ec2 associate-client-vpn-target-network --client-vpn-endpoint-id $vpnEndpointId --subnet-id $adSubnetB --region $region 2>&1 | Out-Null
Write-Host "    AD-B associated" -ForegroundColor Green
Write-Host ""

# Step 6: Add authorization rules
Write-Host "[Step 6] Adding authorization rules..." -ForegroundColor Cyan
aws ec2 authorize-client-vpn-ingress --client-vpn-endpoint-id $vpnEndpointId --target-network-cidr $vpcCidr --authorize-all-groups --description "Allow access to VPC" --region $region 2>&1 | Out-Null
Write-Host "  Authorization rules added" -ForegroundColor Green
Write-Host ""

# Step 7: Add routes
Write-Host "[Step 7] Adding routes..." -ForegroundColor Cyan
aws ec2 create-client-vpn-route --client-vpn-endpoint-id $vpnEndpointId --destination-cidr-block $vpcCidr --target-vpc-subnet-id $adSubnetA --description "Route to VPC" --region $region 2>&1 | Out-Null
Write-Host "  Routes added" -ForegroundColor Green
Write-Host ""

# Step 8: Download new config
Write-Host "[Step 8] Downloading new VPN configuration..." -ForegroundColor Cyan
$configFile = "wac-dev-admin-vpn-FIXED.ovpn"
aws ec2 export-client-vpn-client-configuration --client-vpn-endpoint-id $vpnEndpointId --region $region --output text | Out-File -FilePath $configFile -Encoding ASCII

# Add certificates
$certContent = Get-Content "$certDir\client1.crt" -Raw
$keyContent = Get-Content "$certDir\client1.key" -Raw

Add-Content -Path $configFile -Value "`n<cert>"
Add-Content -Path $configFile -Value $certContent
Add-Content -Path $configFile -Value "</cert>"
Add-Content -Path $configFile -Value "`n<key>"
Add-Content -Path $configFile -Value $keyContent
Add-Content -Path $configFile -Value "</key>"

Write-Host "  Configuration file created: $configFile" -ForegroundColor Green
Write-Host ""

# Summary
Write-Host "=== VPN Endpoint Fixed! ===" -ForegroundColor Green
Write-Host ""
Write-Host "New VPN Endpoint ID: $vpnEndpointId" -ForegroundColor Yellow
Write-Host "New Configuration File: $configFile" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Open AWS VPN Client"
Write-Host "2. Delete old profile (if exists)"
Write-Host "3. Add new profile using: $configFile"
Write-Host "4. Connect and test"
Write-Host ""
