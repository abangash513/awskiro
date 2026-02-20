# Production Phase 3 - Step 3: Generate VPN Client Configuration

$region = "us-west-2"

# Load configuration
$config = Get-Content "prod-vpn-config.json" | ConvertFrom-Json
$endpointId = $config.EndpointId
$certDir = $config.CertDir

Write-Host "=== Generating VPN Client Configuration ===" -ForegroundColor Green
Write-Host ""
Write-Host "Endpoint ID: $endpointId" -ForegroundColor Cyan
Write-Host "Certificate Directory: $certDir" -ForegroundColor Cyan
Write-Host ""

# Export VPN configuration
Write-Host "[1/2] Exporting VPN configuration from AWS..." -ForegroundColor Yellow
$vpnConfig = aws ec2 export-client-vpn-client-configuration `
  --client-vpn-endpoint-id $endpointId `
  --region $region `
  --query 'ClientConfiguration' `
  --output text

Write-Host "Success: Configuration exported" -ForegroundColor Green

# Read certificates
Write-Host "[2/2] Embedding certificates..." -ForegroundColor Yellow
$caCert = Get-Content "$certDir\ca.crt" -Raw
$clientCert = Get-Content "$certDir\client1.crt" -Raw
$clientKey = Get-Content "$certDir\client1.key" -Raw

# Create complete OVPN file
$completeConfig = $vpnConfig + "`n`n<ca>`n$caCert`n</ca>`n`n<cert>`n$clientCert`n</cert>`n`n<key>`n$clientKey`n</key>`n"
$completeConfig | Out-File -FilePath "wac-prod-admin-vpn.ovpn" -Encoding ASCII

Write-Host "Success: VPN configuration file created" -ForegroundColor Green

Write-Host ""
Write-Host "=== Phase 3 Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "VPN Configuration File: wac-prod-admin-vpn.ovpn" -ForegroundColor Cyan
Write-Host "Certificate Directory: $certDir" -ForegroundColor Cyan
Write-Host "Endpoint ID: $endpointId" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Download AWS VPN Client from https://aws.amazon.com/vpn/client-vpn-download/" -ForegroundColor White
Write-Host "  2. Import wac-prod-admin-vpn.ovpn into AWS VPN Client" -ForegroundColor White
Write-Host "  3. Connect and test access to Domain Controllers" -ForegroundColor White
Write-Host "  4. Secure certificate files in $certDir" -ForegroundColor White
Write-Host ""
Write-Host "SECURITY REMINDER:" -ForegroundColor Red
Write-Host "  - Move certificate files to encrypted storage" -ForegroundColor White
Write-Host "  - Never commit certificates to Git" -ForegroundColor White
Write-Host "  - Distribute VPN config securely to authorized users only" -ForegroundColor White
Write-Host ""
