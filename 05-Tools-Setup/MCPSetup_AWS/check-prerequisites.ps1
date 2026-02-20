# Check Prerequisites for AWS MCP Setup

Write-Host "=== AWS MCP Prerequisites Checker ===" -ForegroundColor Green
Write-Host ""

$allInstalled = $true

# Check Node.js
Write-Host "Checking Node.js..." -ForegroundColor Cyan
$nodeCheck = Get-Command node -ErrorAction SilentlyContinue
if ($nodeCheck) {
    $nodeVersion = & node --version 2>&1
    Write-Host "  OK Node.js: $nodeVersion" -ForegroundColor Green
} else {
    Write-Host "  MISSING Node.js" -ForegroundColor Red
    Write-Host "    Download: https://nodejs.org/" -ForegroundColor Yellow
    $allInstalled = $false
}

# Check npm
Write-Host "Checking npm..." -ForegroundColor Cyan
$npmCheck = Get-Command npm -ErrorAction SilentlyContinue
if ($npmCheck) {
    $npmVersion = & npm --version 2>&1
    Write-Host "  OK npm: $npmVersion" -ForegroundColor Green
} else {
    Write-Host "  MISSING npm" -ForegroundColor Red
    $allInstalled = $false
}

# Check Git
Write-Host "Checking Git..." -ForegroundColor Cyan
$gitCheck = Get-Command git -ErrorAction SilentlyContinue
if ($gitCheck) {
    $gitVersion = & git --version 2>&1
    Write-Host "  OK Git: $gitVersion" -ForegroundColor Green
} else {
    Write-Host "  MISSING Git" -ForegroundColor Red
    Write-Host "    Download: https://git-scm.com/" -ForegroundColor Yellow
    $allInstalled = $false
}

# Check AWS CLI
Write-Host "Checking AWS CLI..." -ForegroundColor Cyan
$awsCheck = Get-Command aws -ErrorAction SilentlyContinue
if ($awsCheck) {
    $awsVersion = & aws --version 2>&1
    Write-Host "  OK AWS CLI: $awsVersion" -ForegroundColor Green
} else {
    Write-Host "  MISSING AWS CLI" -ForegroundColor Red
    Write-Host "    Download: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    $allInstalled = $false
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Green

if ($allInstalled) {
    Write-Host "All required prerequisites installed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next: Run .\install-aws-mcp-servers.ps1" -ForegroundColor Cyan
} else {
    Write-Host "Some prerequisites missing. Install them first." -ForegroundColor Red
    Write-Host ""
    Write-Host "Download Links:" -ForegroundColor Yellow
    Write-Host "  Node.js: https://nodejs.org/" -ForegroundColor White
    Write-Host "  Git: https://git-scm.com/" -ForegroundColor White
    Write-Host "  AWS CLI: https://aws.amazon.com/cli/" -ForegroundColor White
}

Write-Host ""
