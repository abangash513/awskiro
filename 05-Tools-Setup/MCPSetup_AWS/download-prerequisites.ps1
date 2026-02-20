# Download Prerequisites for AWS MCP Setup
# This script provides links and checks for required software

Write-Host "=== AWS MCP Prerequisites Checker ===" -ForegroundColor Green
Write-Host ""

$allInstalled = $true

# Check Node.js
Write-Host "Checking Node.js..." -ForegroundColor Cyan
$nodeCheck = Get-Command node -ErrorAction SilentlyContinue
if ($nodeCheck) {
    $nodeVersion = node --version
    Write-Host "  ✓ Node.js installed: $nodeVersion" -ForegroundColor Green
} else {
    Write-Host "  ✗ Node.js NOT installed" -ForegroundColor Red
    Write-Host "    Download from: https://nodejs.org/" -ForegroundColor Yellow
    $allInstalled = $false
}

# Check npm
Write-Host "Checking npm..." -ForegroundColor Cyan
$npmCheck = Get-Command npm -ErrorAction SilentlyContinue
if ($npmCheck) {
    $npmVersion = npm --version
    Write-Host "  ✓ npm installed: $npmVersion" -ForegroundColor Green
} else {
    Write-Host "  ✗ npm NOT installed" -ForegroundColor Red
    $allInstalled = $false
}

# Check Git
Write-Host "Checking Git..." -ForegroundColor Cyan
$gitCheck = Get-Command git -ErrorAction SilentlyContinue
if ($gitCheck) {
    $gitVersion = git --version
    Write-Host "  ✓ Git installed: $gitVersion" -ForegroundColor Green
} else {
    Write-Host "  ✗ Git NOT installed" -ForegroundColor Red
    Write-Host "    Download from: https://git-scm.com/" -ForegroundColor Yellow
    $allInstalled = $false
}

# Check Python
Write-Host "Checking Python..." -ForegroundColor Cyan
$pythonCheck = Get-Command python -ErrorAction SilentlyContinue
if ($pythonCheck) {
    $pythonVersion = python --version 2>&1
    Write-Host "  ✓ Python installed: $pythonVersion" -ForegroundColor Green
} else {
    Write-Host "  ⚠ Python NOT installed (optional for some MCP servers)" -ForegroundColor Yellow
    Write-Host "    Download from: https://www.python.org/downloads/" -ForegroundColor Yellow
}

# Check AWS CLI
Write-Host "Checking AWS CLI..." -ForegroundColor Cyan
$awsCheck = Get-Command aws -ErrorAction SilentlyContinue
if ($awsCheck) {
    $awsVersion = aws --version 2>&1
    Write-Host "  ✓ AWS CLI installed: $awsVersion" -ForegroundColor Green
} else {
    Write-Host "  ✗ AWS CLI NOT installed" -ForegroundColor Red
    Write-Host "    Download from: https://aws.amazon.com/cli/" -ForegroundColor Yellow
    $allInstalled = $false
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Green

if ($allInstalled) {
    Write-Host "✓ All required prerequisites are installed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now run: .\install-aws-mcp-servers.ps1" -ForegroundColor Cyan
} else {
    Write-Host "✗ Some prerequisites are missing" -ForegroundColor Red
    Write-Host ""
    Write-Host "Download Links:" -ForegroundColor Yellow
    Write-Host "  • Node.js: https://nodejs.org/" -ForegroundColor White
    Write-Host "  • Git: https://git-scm.com/" -ForegroundColor White
    Write-Host "  • AWS CLI: https://aws.amazon.com/cli/" -ForegroundColor White
    Write-Host "  • Python (optional): https://www.python.org/downloads/" -ForegroundColor White
    Write-Host ""
    Write-Host "After installing, restart PowerShell and run this script again" -ForegroundColor Yellow
}

Write-Host ""
