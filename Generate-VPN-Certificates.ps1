# Generate VPN Certificates using OpenSSL
# Run this script on a machine with OpenSSL installed

Write-Host "=== WAC Dev Client VPN Certificate Generation ===" -ForegroundColor Green
Write-Host ""

# Create working directory
$certDir = "vpn-certs-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $certDir -Force | Out-Null
Set-Location $certDir

Write-Host "Working directory: $((Get-Location).Path)" -ForegroundColor Yellow
Write-Host ""

# 1. Generate CA private key
Write-Host "[1/8] Generating CA private key..." -ForegroundColor Cyan
openssl genrsa -out ca.key 2048
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to generate CA key"; exit 1 }

# 2. Generate CA certificate
Write-Host "[2/8] Generating CA certificate..." -ForegroundColor Cyan
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt -subj "/C=US/ST=California/L=SanFrancisco/O=WAC/OU=IT/CN=WAC-VPN-CA"
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to generate CA certificate"; exit 1 }

# 3. Generate server private key
Write-Host "[3/8] Generating server private key..." -ForegroundColor Cyan
openssl genrsa -out server.key 2048
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to generate server key"; exit 1 }

# 4. Generate server certificate signing request
Write-Host "[4/8] Generating server CSR..." -ForegroundColor Cyan
openssl req -new -key server.key -out server.csr -subj "/C=US/ST=California/L=SanFrancisco/O=WAC/OU=IT/CN=server"
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to generate server CSR"; exit 1 }

# 5. Sign server certificate with CA
Write-Host "[5/8] Signing server certificate..." -ForegroundColor Cyan
openssl x509 -req -days 3650 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to sign server certificate"; exit 1 }

# 6. Generate client private key
Write-Host "[6/8] Generating client private key..." -ForegroundColor Cyan
openssl genrsa -out client1.key 2048
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to generate client key"; exit 1 }

# 7. Generate client certificate signing request
Write-Host "[7/8] Generating client CSR..." -ForegroundColor Cyan
openssl req -new -key client1.key -out client1.csr -subj "/C=US/ST=California/L=SanFrancisco/O=WAC/OU=IT/CN=client1.wac.net"
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to generate client CSR"; exit 1 }

# 8. Sign client certificate with CA
Write-Host "[8/8] Signing client certificate..." -ForegroundColor Cyan
openssl x509 -req -days 3650 -in client1.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client1.crt
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to sign client certificate"; exit 1 }

Write-Host ""
Write-Host "=== Certificate Generation Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Generated files:" -ForegroundColor Yellow
Get-ChildItem -File | Format-Table Name, Length, LastWriteTime

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Import server certificate to ACM"
Write-Host "2. Import client certificate to ACM"
Write-Host "3. Create Client VPN endpoint"
Write-Host ""
Write-Host "Keep these files secure! They contain private keys." -ForegroundColor Red
