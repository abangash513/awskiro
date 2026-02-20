# Phase 3: AWS Client VPN Implementation Script
# Account: AWS_Dev (749006369142)
# Region: us-west-2
# VPC: vpc-014ec3818a5b2940e (Dev-VPC, 10.60.0.0/16)

Write-Host "=== Phase 3: AWS Client VPN Implementation ===" -ForegroundColor Green
Write-Host ""
Write-Host "This script will guide you through setting up AWS Client VPN" -ForegroundColor Yellow
Write-Host ""

# Configuration
$region = "us-west-2"
$vpcId = "vpc-014ec3818a5b2940e"
$vpcCidr = "10.60.0.0/16"
$vpnClientCidr = "10.100.0.0/16"  # VPN clients will get IPs from this range
$adSubnetA = "subnet-06888c11ff940086d"  # AD-A (us-west-2a)
$adSubnetB = "subnet-0aebef249b6787cba"  # AD-B (us-west-2b)
$logGroupName = "/aws/clientvpn/dev-admin-vpn"

Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  Region: $region"
Write-Host "  VPC: $vpcId ($vpcCidr)"
Write-Host "  VPN Client CIDR: $vpnClientCidr"
Write-Host "  Subnets: AD-A (us-west-2a), AD-B (us-west-2b)"
Write-Host ""

# Step 1: Check OpenSSL
Write-Host "[Step 1] Checking for OpenSSL..." -ForegroundColor Cyan
$opensslPath = Get-Command openssl -ErrorAction SilentlyContinue
if (-not $opensslPath) {
    Write-Host "  ❌ OpenSSL not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Please install OpenSSL:" -ForegroundColor Yellow
    Write-Host "  Option 1: Download from https://slproweb.com/products/Win32OpenSSL.html"
    Write-Host "  Option 2: Install via Chocolatey: choco install openssl"
    Write-Host "  Option 3: Install via Git for Windows (includes OpenSSL)"
    Write-Host ""
    Write-Host "  After installation, restart PowerShell and run this script again."
    Write-Host ""
    exit 1
} else {
    Write-Host "  ✅ OpenSSL found: $($opensslPath.Source)" -ForegroundColor Green
    & openssl version
}
Write-Host ""

# Step 2: Generate Certificates
Write-Host "[Step 2] Generating VPN Certificates..." -ForegroundColor Cyan
Write-Host "  This will create a new directory with all certificates" -ForegroundColor Yellow
Write-Host ""

$certDir = "vpn-certs-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $certDir -Force | Out-Null
Push-Location $certDir

try {
    Write-Host "  [2.1] Generating CA private key..." -ForegroundColor Gray
    & openssl genrsa -out ca.key 2048 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failed to generate CA key" }
    Write-Host "    ✅ ca.key created" -ForegroundColor Green

    Write-Host "  [2.2] Generating CA certificate..." -ForegroundColor Gray
    & openssl req -new -x509 -days 3650 -key ca.key -out ca.crt -subj "/C=US/ST=California/L=SanFrancisco/O=WAC/OU=IT/CN=WAC-VPN-CA" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failed to generate CA certificate" }
    Write-Host "    ✅ ca.crt created" -ForegroundColor Green

    Write-Host "  [2.3] Generating server private key..." -ForegroundColor Gray
    & openssl genrsa -out server.key 2048 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failed to generate server key" }
    Write-Host "    ✅ server.key created" -ForegroundColor Green

    Write-Host "  [2.4] Generating server CSR..." -ForegroundColor Gray
    & openssl req -new -key server.key -out server.csr -subj "/C=US/ST=California/L=SanFrancisco/O=WAC/OU=IT/CN=server" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failed to generate server CSR" }
    Write-Host "    ✅ server.csr created" -ForegroundColor Green

    Write-Host "  [2.5] Signing server certificate..." -ForegroundColor Gray
    & openssl x509 -req -days 3650 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failed to sign server certificate" }
    Write-Host "    ✅ server.crt created" -ForegroundColor Green

    Write-Host "  [2.6] Generating client private key..." -ForegroundColor Gray
    & openssl genrsa -out client1.key 2048 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failed to generate client key" }
    Write-Host "    ✅ client1.key created" -ForegroundColor Green

    Write-Host "  [2.7] Generating client CSR..." -ForegroundColor Gray
    & openssl req -new -key client1.key -out client1.csr -subj "/C=US/ST=California/L=SanFrancisco/O=WAC/OU=IT/CN=client1.wac.net" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failed to generate client CSR" }
    Write-Host "    ✅ client1.csr created" -ForegroundColor Green

    Write-Host "  [2.8] Signing client certificate..." -ForegroundColor Gray
    & openssl x509 -req -days 3650 -in client1.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client1.crt 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failed to sign client certificate" }
    Write-Host "    ✅ client1.crt created" -ForegroundColor Green

    Write-Host ""
    Write-Host "  All certificates generated successfully!" -ForegroundColor Green
    Write-Host "  Location: $((Get-Location).Path)" -ForegroundColor Yellow
    Write-Host ""

} catch {
    Write-Host "  ❌ Error: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}

Pop-Location
Write-Host ""

# Step 3: Import Certificates to ACM
Write-Host "[Step 3] Importing Certificates to AWS Certificate Manager..." -ForegroundColor Cyan
Write-Host ""

Push-Location $certDir

try {
    Write-Host "  [3.1] Importing server certificate..." -ForegroundColor Gray
    $serverCertArn = aws acm import-certificate `
        --certificate "fileb://server.crt" `
        --private-key "fileb://server.key" `
        --certificate-chain "fileb://ca.crt" `
        --region $region `
        --query 'CertificateArn' `
        --output text

    if ($LASTEXITCODE -ne 0) { throw "Failed to import server certificate" }
    Write-Host "    ✅ Server certificate imported" -ForegroundColor Green
    Write-Host "    ARN: $serverCertArn" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "  [3.2] Importing client certificate..." -ForegroundColor Gray
    $clientCertArn = aws acm import-certificate `
        --certificate "fileb://client1.crt" `
        --private-key "fileb://client1.key" `
        --certificate-chain "fileb://ca.crt" `
        --region $region `
        --query 'CertificateArn' `
        --output text

    if ($LASTEXITCODE -ne 0) { throw "Failed to import client certificate" }
    Write-Host "    ✅ Client certificate imported" -ForegroundColor Green
    Write-Host "    ARN: $clientCertArn" -ForegroundColor Yellow
    Write-Host ""

    # Save ARNs for later use
    @{
        ServerCertificateArn = $serverCertArn
        ClientCertificateArn = $clientCertArn
        VpcId = $vpcId
        VpcCidr = $vpcCidr
        VpnClientCidr = $vpnClientCidr
        SubnetA = $adSubnetA
        SubnetB = $adSubnetB
        Region = $region
    } | ConvertTo-Json | Out-File "vpn-config.json"

    Write-Host "  ✅ Configuration saved to vpn-config.json" -ForegroundColor Green
    Write-Host ""

} catch {
    Write-Host "  ❌ Error: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}

Pop-Location
Write-Host ""

# Step 4: Create CloudWatch Log Group
Write-Host "[Step 4] Creating CloudWatch Log Group..." -ForegroundColor Cyan
$logGroupExists = aws logs describe-log-groups --log-group-name-prefix $logGroupName --region $region --query "logGroups[?logGroupName=='$logGroupName']" --output text

if ($logGroupExists) {
    Write-Host "  Log group already exists: $logGroupName" -ForegroundColor Yellow
} else {
    aws logs create-log-group --log-group-name $logGroupName --region $region
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Log group created: $logGroupName" -ForegroundColor Green
        
        # Set retention to 90 days
        aws logs put-retention-policy --log-group-name $logGroupName --retention-in-days 90 --region $region
        Write-Host "  ✅ Log retention set to 90 days" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Failed to create log group" -ForegroundColor Red
    }
}
Write-Host ""

# Step 5: Create Client VPN Endpoint
Write-Host "[Step 5] Creating Client VPN Endpoint..." -ForegroundColor Cyan
Write-Host "  This may take 5-10 minutes..." -ForegroundColor Yellow
Write-Host ""

$vpnEndpointId = aws ec2 create-client-vpn-endpoint `
    --client-cidr-block $vpnClientCidr `
    --server-certificate-arn $serverCertArn `
    --authentication-options "Type=certificate-authentication,MutualAuthentication={ClientRootCertificateChainArn=$clientCertArn}" `
    --connection-log-options "Enabled=true,CloudwatchLogGroup=$logGroupName" `
    --dns-servers "10.60.0.2" `
    --vpc-id $vpcId `
    --description "WAC Dev Admin VPN" `
    --split-tunnel `
    --tag-specifications "ResourceType=client-vpn-endpoint,Tags=[{Key=Name,Value=WAC-Dev-Admin-VPN},{Key=Environment,Value=Development},{Key=Phase,Value=3}]" `
    --region $region `
    --query 'ClientVpnEndpointId' `
    --output text

if ($LASTEXITCODE -ne 0) {
    Write-Host "  ❌ Failed to create VPN endpoint" -ForegroundColor Red
    exit 1
}

Write-Host "  ✅ VPN Endpoint created: $vpnEndpointId" -ForegroundColor Green
Write-Host ""

# Wait for endpoint to become available
Write-Host "  Waiting for endpoint to become available..." -ForegroundColor Gray
$maxWait = 600  # 10 minutes
$waited = 0
$interval = 15

while ($waited -lt $maxWait) {
    $state = aws ec2 describe-client-vpn-endpoints `
        --client-vpn-endpoint-ids $vpnEndpointId `
        --region $region `
        --query 'ClientVpnEndpoints[0].Status.Code' `
        --output text

    if ($state -eq "available") {
        Write-Host "  ✅ VPN Endpoint is now available!" -ForegroundColor Green
        break
    }

    Write-Host "    Status: $state (waited $waited seconds)" -ForegroundColor Gray
    Start-Sleep -Seconds $interval
    $waited += $interval
}

if ($waited -ge $maxWait) {
    Write-Host "  Timeout waiting for endpoint. Check AWS Console." -ForegroundColor Yellow
}
Write-Host ""

# Step 6: Associate VPN Endpoint with Subnets
Write-Host "[Step 6] Associating VPN Endpoint with Subnets..." -ForegroundColor Cyan
Write-Host ""

Write-Host "  [6.1] Associating with AD-A subnet (us-west-2a)..." -ForegroundColor Gray
$assocA = aws ec2 associate-client-vpn-target-network `
    --client-vpn-endpoint-id $vpnEndpointId `
    --subnet-id $adSubnetA `
    --region $region `
    --query 'AssociationId' `
    --output text

if ($LASTEXITCODE -eq 0) {
    Write-Host "    ✅ Associated with AD-A: $assocA" -ForegroundColor Green
} else {
    Write-Host "    ❌ Failed to associate with AD-A" -ForegroundColor Red
}
Write-Host ""

Write-Host "  [6.2] Associating with AD-B subnet (us-west-2b)..." -ForegroundColor Gray
$assocB = aws ec2 associate-client-vpn-target-network `
    --client-vpn-endpoint-id $vpnEndpointId `
    --subnet-id $adSubnetB `
    --region $region `
    --query 'AssociationId' `
    --output text

if ($LASTEXITCODE -eq 0) {
    Write-Host "    ✅ Associated with AD-B: $assocB" -ForegroundColor Green
} else {
    Write-Host "    ❌ Failed to associate with AD-B" -ForegroundColor Red
}
Write-Host ""

# Step 7: Add Authorization Rules
Write-Host "[Step 7] Adding Authorization Rules..." -ForegroundColor Cyan
Write-Host ""

Write-Host "  [7.1] Authorizing access to VPC CIDR ($vpcCidr)..." -ForegroundColor Gray
aws ec2 authorize-client-vpn-ingress `
    --client-vpn-endpoint-id $vpnEndpointId `
    --target-network-cidr $vpcCidr `
    --authorize-all-groups `
    --description "Allow access to entire VPC" `
    --region $region | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "    ✅ Authorization rule added for VPC" -ForegroundColor Green
} else {
    Write-Host "    ❌ Failed to add authorization rule" -ForegroundColor Red
}
Write-Host ""

# Step 8: Add Routes
Write-Host "[Step 8] Adding Routes to VPC..." -ForegroundColor Cyan
Write-Host ""

Write-Host "  [8.1] Adding route to VPC CIDR..." -ForegroundColor Gray
aws ec2 create-client-vpn-route `
    --client-vpn-endpoint-id $vpnEndpointId `
    --destination-cidr-block $vpcCidr `
    --target-vpc-subnet-id $adSubnetA `
    --description "Route to VPC" `
    --region $region | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "    ✅ Route added to VPC" -ForegroundColor Green
} else {
    Write-Host "    ❌ Failed to add route" -ForegroundColor Red
}
Write-Host ""

# Step 9: Download VPN Client Configuration
Write-Host "[Step 9] Downloading VPN Client Configuration..." -ForegroundColor Cyan
Write-Host ""

$configFile = "wac-dev-admin-vpn.ovpn"
aws ec2 export-client-vpn-client-configuration `
    --client-vpn-endpoint-id $vpnEndpointId `
    --region $region `
    --output text | Out-File -FilePath $configFile -Encoding ASCII

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✅ Configuration downloaded: $configFile" -ForegroundColor Green
    Write-Host ""

    # Add client certificate and key to config file
    Write-Host "  [9.1] Adding client certificate to config..." -ForegroundColor Gray
    
    $certContent = Get-Content "$certDir\client1.crt" -Raw
    $keyContent = Get-Content "$certDir\client1.key" -Raw
    
    Add-Content -Path $configFile -Value "`n<cert>"
    Add-Content -Path $configFile -Value $certContent
    Add-Content -Path $configFile -Value "</cert>"
    Add-Content -Path $configFile -Value "`n<key>"
    Add-Content -Path $configFile -Value $keyContent
    Add-Content -Path $configFile -Value "</key>"
    
    Write-Host "    ✅ Client certificate and key added to config" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "  ❌ Failed to download configuration" -ForegroundColor Red
}

# Summary
Write-Host ""
Write-Host "=== Phase 3 Implementation Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  ✅ Certificates generated and imported to ACM"
Write-Host "  ✅ CloudWatch log group created"
Write-Host "  ✅ Client VPN endpoint created: $vpnEndpointId"
Write-Host "  ✅ Subnets associated (AD-A, AD-B)"
Write-Host "  ✅ Authorization rules configured"
Write-Host "  ✅ Routes added to VPC"
Write-Host "  ✅ Client configuration file ready: $configFile"
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Download AWS VPN Client from: https://aws.amazon.com/vpn/client-vpn-download/"
Write-Host "  2. Install the client on your computer"
Write-Host "  3. Import the configuration file: $configFile"
Write-Host "  4. Connect to the VPN"
Write-Host "  5. Test RDP access to Domain Controllers"
Write-Host ""
Write-Host "Configuration Files:" -ForegroundColor Yellow
Write-Host "  Certificates: $certDir\"
Write-Host "  VPN Config: $configFile"
Write-Host "  Settings: $certDir\vpn-config.json"
Write-Host ""
Write-Host "Cost Estimate:" -ForegroundColor Yellow
Write-Host "  VPN Endpoint: ~`$73/month (24/7)"
Write-Host "  Per Connection: `$0.05/hour"
Write-Host "  Data Transfer: `$0.09/GB"
Write-Host ""
Write-Host "WARNING: Keep the certificates in $certDir\ secure!" -ForegroundColor Red
Write-Host "    These contain private keys for VPN authentication." -ForegroundColor Red
Write-Host ""
