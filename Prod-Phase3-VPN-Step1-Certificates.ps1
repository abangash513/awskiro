# Production Phase 3 - Step 1: Generate Certificates
# This script generates VPN certificates with proper TLS extensions

$opensslPath = "C:\Program Files\OpenSSL-Win64\bin\openssl.exe"

if (-not (Test-Path $opensslPath)) {
    Write-Host "Error: OpenSSL not found at $opensslPath" -ForegroundColor Red
    exit 1
}

Write-Host "=== Generating VPN Certificates for Production ===" -ForegroundColor Green
Write-Host ""

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$certDir = "vpn-certs-prod-$timestamp"
New-Item -ItemType Directory -Path $certDir -Force | Out-Null

Write-Host "Certificate directory: $certDir" -ForegroundColor Cyan
Write-Host ""

# Create server config
$serverConf = @'
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = California
L = SanFrancisco
O = WAC
OU = IT
CN = server.wac-prod-vpn.local

[v3_req]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = server.wac-prod-vpn.local
DNS.2 = *.wac-prod-vpn.local
'@

$serverConf | Out-File -FilePath "$certDir\server.conf" -Encoding ASCII

# Create client config
$clientConf = @'
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = California
L = SanFrancisco
O = WAC
OU = IT
CN = client1.wac-prod-vpn.local

[v3_req]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
'@

$clientConf | Out-File -FilePath "$certDir\client.conf" -Encoding ASCII

Write-Host "[1/7] Generating CA..." -ForegroundColor Yellow
& $opensslPath genrsa -out "$certDir\ca.key" 2048 2>&1 | Out-Null
& $opensslPath req -new -x509 -days 3650 -key "$certDir\ca.key" -out "$certDir\ca.crt" -subj "/C=US/ST=California/L=SanFrancisco/O=WAC/OU=IT/CN=wac-prod-vpn-ca.local"
Write-Host "Success: CA generated" -ForegroundColor Green

Write-Host "[2/7] Generating server key..." -ForegroundColor Yellow
& $opensslPath genrsa -out "$certDir\server.key" 2048 2>&1 | Out-Null
Write-Host "Success: Server key generated" -ForegroundColor Green

Write-Host "[3/7] Generating server CSR..." -ForegroundColor Yellow
& $opensslPath req -new -key "$certDir\server.key" -out "$certDir\server.csr" -config "$certDir\server.conf"
Write-Host "Success: Server CSR generated" -ForegroundColor Green

Write-Host "[4/7] Signing server certificate..." -ForegroundColor Yellow
& $opensslPath x509 -req -days 3650 -in "$certDir\server.csr" -CA "$certDir\ca.crt" -CAkey "$certDir\ca.key" -CAcreateserial -out "$certDir\server.crt" -extensions v3_req -extfile "$certDir\server.conf"
Write-Host "Success: Server certificate signed" -ForegroundColor Green

Write-Host "[5/7] Generating client key..." -ForegroundColor Yellow
& $opensslPath genrsa -out "$certDir\client1.key" 2048 2>&1 | Out-Null
Write-Host "Success: Client key generated" -ForegroundColor Green

Write-Host "[6/7] Generating client CSR..." -ForegroundColor Yellow
& $opensslPath req -new -key "$certDir\client1.key" -out "$certDir\client1.csr" -config "$certDir\client.conf"
Write-Host "Success: Client CSR generated" -ForegroundColor Green

Write-Host "[7/7] Signing client certificate..." -ForegroundColor Yellow
& $opensslPath x509 -req -days 3650 -in "$certDir\client1.csr" -CA "$certDir\ca.crt" -CAkey "$certDir\ca.key" -CAcreateserial -out "$certDir\client1.crt" -extensions v3_req -extfile "$certDir\client.conf"
Write-Host "Success: Client certificate signed" -ForegroundColor Green

Write-Host ""
Write-Host "=== Certificates Generated Successfully! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Certificate directory: $certDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Files created:" -ForegroundColor Yellow
Write-Host "  ca.crt, ca.key - Certificate Authority" -ForegroundColor White
Write-Host "  server.crt, server.key - Server certificate" -ForegroundColor White
Write-Host "  client1.crt, client1.key - Client certificate" -ForegroundColor White
Write-Host ""
Write-Host "Next: Run Prod-Phase3-VPN-Step2-Import.ps1" -ForegroundColor Yellow
Write-Host ""

# Save cert dir for next script
$certDir | Out-File -FilePath "prod-cert-dir.txt" -Encoding ASCII
