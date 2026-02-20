# AWS MCP Servers Installation Script

Write-Host "=== AWS MCP Servers Installation ===" -ForegroundColor Green
Write-Host ""

$setupDir = $PSScriptRoot
$serversDir = Join-Path $setupDir "mcp-servers"

if (-not (Test-Path $serversDir)) {
    New-Item -ItemType Directory -Path $serversDir | Out-Null
}

Set-Location $serversDir

Write-Host "Checking prerequisites..." -ForegroundColor Cyan

$gitCheck = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitCheck) {
    Write-Host "ERROR: Git not found. Install from https://git-scm.com/" -ForegroundColor Red
    exit 1
}
Write-Host "OK Git installed" -ForegroundColor Green

$nodeCheck = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeCheck) {
    Write-Host "ERROR: Node.js not found. Install from https://nodejs.org/" -ForegroundColor Red
    exit 1
}
Write-Host "OK Node.js installed" -ForegroundColor Green

$npmCheck = Get-Command npm -ErrorAction SilentlyContinue
if (-not $npmCheck) {
    Write-Host "ERROR: npm not found. Install Node.js from https://nodejs.org/" -ForegroundColor Red
    exit 1
}
Write-Host "OK npm installed" -ForegroundColor Green

Write-Host ""

# 1. AWS KB Retrieval
Write-Host "Installing AWS KB Retrieval MCP Server..." -ForegroundColor Yellow
if (Test-Path "mcp-server-aws-kb-retrieval") {
    Write-Host "  Already exists, updating..." -ForegroundColor Gray
    Set-Location "mcp-server-aws-kb-retrieval"
    & git pull
    Set-Location ..
} else {
    & git clone https://github.com/aws-samples/mcp-server-aws-kb-retrieval.git
}
Set-Location "mcp-server-aws-kb-retrieval"
& npm install
Write-Host "OK AWS KB Retrieval installed" -ForegroundColor Green
Set-Location ..

Write-Host ""

# 2. Official MCP Servers
Write-Host "Installing Official AWS MCP Server..." -ForegroundColor Yellow
if (Test-Path "mcp-servers-official") {
    Write-Host "  Already exists, updating..." -ForegroundColor Gray
    Set-Location "mcp-servers-official"
    & git pull
    Set-Location ..
} else {
    & git clone https://github.com/modelcontextprotocol/servers.git mcp-servers-official
}
Set-Location "mcp-servers-official/src/aws"
& npm install
Write-Host "OK Official AWS MCP Server installed" -ForegroundColor Green
Set-Location ../..

Write-Host ""

# 3. AWS Diagram as Code
Write-Host "Installing AWS Diagram as Code MCP Server..." -ForegroundColor Yellow
if (Test-Path "mcp-server-diagram-as-code") {
    Write-Host "  Already exists, updating..." -ForegroundColor Gray
    Set-Location "mcp-server-diagram-as-code"
    & git pull
    Set-Location ..
} else {
    & git clone https://github.com/aws-samples/mcp-server-diagram-as-code.git
}
Set-Location "mcp-server-diagram-as-code"
& npm install
Write-Host "OK AWS Diagram as Code installed" -ForegroundColor Green
Set-Location ..

Write-Host ""
Write-Host "=== Installation Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Installed MCP Servers:" -ForegroundColor Cyan
Write-Host "  1. AWS KB Retrieval" -ForegroundColor White
Write-Host "  2. AWS MCP Server" -ForegroundColor White
Write-Host "  3. AWS Diagram as Code" -ForegroundColor White
Write-Host ""
Write-Host "Next: Run .\configure-mcp-claude.ps1" -ForegroundColor Yellow
Write-Host ""
