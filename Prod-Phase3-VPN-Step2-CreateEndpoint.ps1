# Production Phase 3 - Step 2: Import Certificates and Create VPN Endpoint

$region = "us-west-2"
$vpcId = "vpc-014b66d7ca2309134"
$subnetA = "subnet-02c8f0d7d48510db0"  # Private-2a (DC/AD)
$subnetB = "subnet-02582cf0ad3fa857b"  # Private-2b (DC/AD)
$clientCidr = "10.200.0.0/16"
$vpcCidr = "10.70.0.0/16"
$dnsServer = "10.70.0.2"

# Get cert directory from previous step
$certDir = Get-Content "prod-cert-dir.txt"

Write-Host "=== Production Phase 3: Creating VPN Endpoint ===" -ForegroundColor Green
Write-Host ""
Write-Host "Using certificates from: $certDir" -ForegroundColor Cyan
Write-Host ""

# Step 1: Import server certificate to ACM
Write-Host "[1/7] Importing server certificate to ACM..." -ForegroundColor Yellow
$serverCertArn = aws acm import-certificate `
  --certificate fileb://$certDir/server.crt `
  --private-key fileb://$certDir/server.key `
  --certificate-chain fileb://$certDir/ca.crt `
  --region $region `
  --tags Key=Name,Value=WAC-Prod-VPN-Server Key=Environment,Value=Production `
  --query 'CertificateArn' `
  --output text

Write-Host "Success: Server certificate imported" -ForegroundColor Green
Write-Host "  ARN: $serverCertArn" -ForegroundColor White

# Step 2: Import client certificate to ACM
Write-Host "[2/7] Importing client certificate to ACM..." -ForegroundColor Yellow
$clientCertArn = aws acm import-certificate `
  --certificate fileb://$certDir/client1.crt `
  --private-key fileb://$certDir/client1.key `
  --certificate-chain fileb://$certDir/ca.crt `
  --region $region `
  --tags Key=Name,Value=WAC-Prod-VPN-Client Key=Environment,Value=Production `
  --query 'CertificateArn' `
  --output text

Write-Host "Success: Client certificate imported" -ForegroundColor Green
Write-Host "  ARN: $clientCertArn" -ForegroundColor White

# Step 3: Create CloudWatch log group
Write-Host "[3/7] Creating CloudWatch log group..." -ForegroundColor Yellow
aws logs create-log-group --log-group-name /aws/clientvpn/prod-admin-vpn --region $region 2>&1 | Out-Null
aws logs put-retention-policy --log-group-name /aws/clientvpn/prod-admin-vpn --retention-in-days 180 --region $region
Write-Host "Success: Log group created with 180-day retention" -ForegroundColor Green

# Step 4: Create Client VPN endpoint
Write-Host "[4/7] Creating Client VPN endpoint..." -ForegroundColor Yellow
$endpointId = aws ec2 create-client-vpn-endpoint `
  --client-cidr-block $clientCidr `
  --server-certificate-arn $serverCertArn `
  --authentication-options Type=certificate-authentication,MutualAuthentication={ClientRootCertificateChainArn=$clientCertArn} `
  --connection-log-options Enabled=true,CloudwatchLogGroup=/aws/clientvpn/prod-admin-vpn `
  --dns-servers $dnsServer `
  --vpc-id $vpcId `
  --split-tunnel `
  --region $region `
  --tag-specifications 'ResourceType=client-vpn-endpoint,Tags=[{Key=Name,Value=WAC-Prod-Admin-VPN},{Key=Environment,Value=Production}]' `
  --query 'ClientVpnEndpointId' `
  --output text

Write-Host "Success: VPN endpoint created" -ForegroundColor Green
Write-Host "  Endpoint ID: $endpointId" -ForegroundColor White
Write-Host "  Waiting 30 seconds for endpoint to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Step 5: Associate subnets
Write-Host "[5/7] Associating subnets..." -ForegroundColor Yellow
aws ec2 associate-client-vpn-target-network --client-vpn-endpoint-id $endpointId --subnet-id $subnetA --region $region 2>&1 | Out-Null
Write-Host "Success: Associated Private-2a (DC/AD subnet)" -ForegroundColor Green

aws ec2 associate-client-vpn-target-network --client-vpn-endpoint-id $endpointId --subnet-id $subnetB --region $region 2>&1 | Out-Null
Write-Host "Success: Associated Private-2b (DC/AD subnet)" -ForegroundColor Green

Write-Host "  Waiting 30 seconds for associations to complete..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Step 6: Add authorization rule
Write-Host "[6/7] Adding authorization rule..." -ForegroundColor Yellow
aws ec2 authorize-client-vpn-ingress --client-vpn-endpoint-id $endpointId --target-network-cidr $vpcCidr --authorize-all-groups --region $region 2>&1 | Out-Null
Write-Host "Success: Authorization rule added for $vpcCidr" -ForegroundColor Green

# Step 7: Add route
Write-Host "[7/7] Adding route..." -ForegroundColor Yellow
aws ec2 create-client-vpn-route --client-vpn-endpoint-id $endpointId --destination-cidr-block $vpcCidr --target-vpc-subnet-id $subnetA --region $region 2>&1 | Out-Null
Write-Host "Success: Route added to VPC" -ForegroundColor Green

# Save configuration
$config = @{
    EndpointId = $endpointId
    ServerCertArn = $serverCertArn
    ClientCertArn = $clientCertArn
    CertDir = $certDir
    Region = $region
} | ConvertTo-Json

$config | Out-File -FilePath "prod-vpn-config.json" -Encoding ASCII

Write-Host ""
Write-Host "=== VPN Endpoint Created Successfully! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Endpoint ID: $endpointId" -ForegroundColor Cyan
Write-Host "Certificate Directory: $certDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next: Run Prod-Phase3-VPN-Step3-GenerateConfig.ps1" -ForegroundColor Yellow
Write-Host ""
