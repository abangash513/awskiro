# Generate VPN Certificates with Proper TLS Extensions
# This fixes the TLS handshake error

Write-Host "=== Generating VPN Certificates with TLS Extensions ===" -ForegroundColor Green
Write-Host ""

$certDir = "vpn-certs-fixed-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -ItemType Directory -Path $certDir -Force | Out-Null
Push-Location $certDir

try {
    # Create OpenSSL config file for server certificate
    $serverConfig = @"
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = California
L = SanFrancisco
O = WAC
OU = IT
CN = server.wac-vpn.local

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = server.wac-vpn.local
DNS.2 = *.wac-vpn.local
"@
    $serverConfig | Out-File -FilePath "server.conf" -Encoding ASCII

    # Create OpenSSL config file for client certificate
    $clientConfig = @"
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = California
L = SanFrancisco
O = WAC
OU = IT
CN = client1.wac-vpn.local

[v3_req]
keyUsage = digitalSignature
extendedKeyUsage = clientAuth
"@
    $clientConfig | Out-File -FilePath "client.conf" -Encoding ASCII

    Write-Host "[1/8] Generating CA private key..." -ForegroundColor Cyan
    & openssl genrsa -out ca.key 2048 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failed to generate CA key" }
    Write-Host "  CA key created" -ForegroundColor Green

    Write-Host "[2/8] Generating CA certificate..." -ForegroundColor Cyan
    & openssl req -new -x509 -days 3650 -key ca.key -out ca.crt -subj "/C=US/ST=California/L=SanFrancisco/O=WAC/OU=IT/CN=wac-vpn-ca.local" 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failed to generate CA certificate" }
    Write-Host "  CA certificate created" -ForegroundColor Green

    Write-Host "[3/8] Generating server private key..." -ForegroundColor Cyan
    & openssl genrsa -out server.key 2048 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failed to generate server key" }
    Write-Host "  Server key created" -ForegroundColor Green

    Write-Host "[4/8] Generating server CSR with extensions..." -ForegroundColor Cyan
    & openssl req -new -key server.key -out server.csr -config server.conf 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failed to generate server CSR" }
    Write-Host "  Server CSR created" -ForegroundColor Green

    Write-Host "[5/8] Signing server certificate with extensions..." -ForegroundColor Cyan
    & openssl x509 -req -days 3650 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -extensions v3_req -extfile server.conf 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failed to sign server certificate" }
    Write-Host "  Server certificate signed" -ForegroundColor Green

    Write-Host "[6/8] Generating client private key..." -ForegroundColor Cyan
    & openssl genrsa -out client1.key 2048 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failed to generate client key" }
    Write-Host "  Client key created" -ForegroundColor Green

    Write-Host "[7/8] Generating client CSR with extensions..." -ForegroundColor Cyan
    & openssl req -new -key client1.key -out client1.csr -config client.conf 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failed to generate client CSR" }
    Write-Host "  Client CSR created" -ForegroundColor Green

    Write-Host "[8/8] Signing client certificate with extensions..." -ForegroundColor Cyan
    & openssl x509 -req -days 3650 -in client1.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client1.crt -extensions v3_req -extfile client.conf 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Failed to sign client certificate" }
    Write-Host "  Client certificate signed" -ForegroundColor Green

    Write-Host ""
    Write-Host "=== Certificate Generation Complete! ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Verifying certificates..." -ForegroundColor Cyan
    
    # Verify server certificate
    Write-Host ""
    Write-Host "Server Certificate Details:" -ForegroundColor Yellow
    & openssl x509 -in server.crt -text -noout | Select-String -Pattern "Subject:|Issuer:|Not Before|Not After|Key Usage|Extended Key Usage"
    
    Write-Host ""
    Write-Host "Client Certificate Details:" -ForegroundColor Yellow
    & openssl x509 -in client1.crt -text -noout | Select-String -Pattern "Subject:|Issuer:|Not Before|Not After|Key Usage|Extended Key Usage"
    
    Write-Host ""
    Write-Host "Certificates saved to: $((Get-Location).Path)" -ForegroundColor Green
    Write-Host ""

} catch {
    Write-Host "ERROR: $_" -ForegroundColor Red
    Pop-Location
    exit 1
}

Pop-Location

Write-Host "Certificate directory: $certDir" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Delete old VPN endpoint (has old certificates)"
Write-Host "2. Import new certificates to ACM"
Write-Host "3. Create new VPN endpoint with new certificates"
Write-Host ""

# Return the directory name for use in next script
return $certDir
