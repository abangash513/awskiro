# AWS MCP Servers Installation Script
# This script downloads and installs AWS MCP servers

Write-Host "=== AWS MCP Servers Installation ===" -ForegroundColor Green
Write-Host ""

$setupDir = $PSScriptRoot
$serversDir = Join-Path $setupDir "mcp-servers"

# Create servers directory
if (-not (Test-Path $serversDir)) {
    New-Item -ItemType Directory -Path $serversDir | Out-Null
}

Set-Location $serversDir

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Cyan

# Check Git
try {
    $gitVersion = git --version
    Write-Host "✓ Git installed: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Git not found. Please install from https://git-scm.com/" -ForegroundColor Red
    exit 1
}

# Check Node.js
try {
    $nodeVersion = node --version
    Write-Host "✓ Node.js installed: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Node.js not found. Please install from https://nodejs.org/" -ForegroundColor Red
    exit 1
}

# Check npm
try {
    $npmVersion = npm --version
    Write-Host "✓ npm installed: $npmVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ npm not found. Please install Node.js from https://nodejs.org/" -ForegroundColor Red
    exit 1
}

Write-Host ""

# 1. Install AWS KB Retrieval MCP Server
Write-Host "Installing AWS KB Retrieval MCP Server..." -ForegroundColor Yellow
if (Test-Path "mcp-server-aws-kb-retrieval") {
    Write-Host "  Already exists, pulling latest..." -ForegroundColor Gray
    Set-Location "mcp-server-aws-kb-retrieval"
    git pull
    Set-Location ..
} else {
    git clone https://github.com/aws-samples/mcp-server-aws-kb-retrieval.git
}
Set-Location "mcp-server-aws-kb-retrieval"
npm install
Write-Host "✓ AWS KB Retrieval MCP Server installed" -ForegroundColor Green
Set-Location ..

Write-Host ""

# 2. Install Official MCP Servers (includes AWS)
Write-Host "Installing Official MCP Servers..." -ForegroundColor Yellow
if (Test-Path "mcp-servers-official") {
    Write-Host "  Already exists, pulling latest..." -ForegroundColor Gray
    Set-Location "mcp-servers-official"
    git pull
    Set-Location ..
} else {
    git clone https://github.com/modelcontextprotocol/servers.git mcp-servers-official
}
Set-Location "mcp-servers-official/src/aws"
npm install
Write-Host "✓ Official AWS MCP Server installed" -ForegroundColor Green
Set-Location ../..

Write-Host ""

# 3. Install AWS Diagram as Code MCP Server
Write-Host "Installing AWS Diagram as Code MCP Server..." -ForegroundColor Yellow
if (Test-Path "mcp-server-diagram-as-code") {
    Write-Host "  Already exists, pulling latest..." -ForegroundColor Gray
    Set-Location "mcp-server-diagram-as-code"
    git pull
    Set-Location ..
} else {
    git clone https://github.com/aws-samples/mcp-server-diagram-as-code.git
}
Set-Location "mcp-server-diagram-as-code"
npm install
Write-Host "✓ AWS Diagram as Code MCP Server installed" -ForegroundColor Green
Set-Location ..

Write-Host ""
Write-Host "=== Installation Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Installed MCP Servers:" -ForegroundColor Cyan
Write-Host "  1. AWS KB Retrieval - Query AWS documentation" -ForegroundColor White
Write-Host "  2. AWS MCP Server - Interact with AWS services" -ForegroundColor White
Write-Host "  3. AWS Diagram as Code - Design AWS architectures" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Run configure-mcp-claude.ps1 to set up Claude Desktop" -ForegroundColor White
Write-Host "  2. Or manually configure your MCP client" -ForegroundColor White
Write-Host ""
