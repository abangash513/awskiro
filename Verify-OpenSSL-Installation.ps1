# Verify OpenSSL Installation Script
# Run this after installing OpenSSL manually

Write-Host "=== OpenSSL Installation Verification ===" -ForegroundColor Green
Write-Host ""

# Check if installation directory exists
$opensslPath = "C:\Users\Minip\OpenSSL\bin"
$opensslExe = "$opensslPath\openssl.exe"

Write-Host "[1/4] Checking installation directory..." -ForegroundColor Cyan
if (Test-Path $opensslPath) {
    Write-Host "  ✅ Directory exists: $opensslPath" -ForegroundColor Green
} else {
    Write-Host "  ❌ Directory not found: $opensslPath" -ForegroundColor Red
    Write-Host "  Please install OpenSSL to C:\Users\Minip\OpenSSL" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "[2/4] Checking OpenSSL executable..." -ForegroundColor Cyan
if (Test-Path $opensslExe) {
    Write-Host "  ✅ OpenSSL executable found" -ForegroundColor Green
} else {
    Write-Host "  ❌ OpenSSL executable not found" -ForegroundColor Red
    Write-Host "  Expected location: $opensslExe" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "[3/4] Adding OpenSSL to PATH..." -ForegroundColor Cyan
$env:Path += ";$opensslPath"
Write-Host "  ✅ Added to PATH for this session" -ForegroundColor Green

Write-Host ""
Write-Host "[4/4] Testing OpenSSL command..." -ForegroundColor Cyan
try {
    $version = & openssl version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ OpenSSL is working!" -ForegroundColor Green
        Write-Host "  Version: $version" -ForegroundColor Yellow
    } else {
        Write-Host "  ❌ OpenSSL command failed" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "  ❌ Error running OpenSSL: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== Verification Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "OpenSSL is ready to use!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Keep this PowerShell window open (PATH is set for this session)"
Write-Host "2. Run: cd C:\AWSKiro"
Write-Host "3. Run: .\Phase3-Implementation-Steps.ps1"
Write-Host ""
Write-Host "Or to make PATH permanent, run:" -ForegroundColor Yellow
Write-Host '$currentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)'
Write-Host '$newPath = $currentPath + ";C:\Users\Minip\OpenSSL\bin"'
Write-Host '[Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::User)'
Write-Host ""
