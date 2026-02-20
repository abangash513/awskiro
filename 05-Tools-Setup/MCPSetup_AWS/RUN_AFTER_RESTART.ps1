# Run this after restarting PowerShell

Write-Host "=== AWS MCP Complete Setup ===" -ForegroundColor Green
Write-Host ""

# Check prerequisites
Write-Host "Step 1: Checking prerequisites..." -ForegroundColor Cyan
$nodeCheck = Get-Command node -ErrorAction SilentlyContinue
if (-not $nodeCheck) {
    Write-Host "ERROR: Node.js still not found. Please install manually from https://nodejs.org/" -ForegroundColor Red
    exit 1
}
Write-Host "OK Node.js found" -ForegroundColor Green

# Install MCP servers
Write-Host ""
Write-Host "Step 2: Installing MCP servers..." -ForegroundColor Cyan
& "$PSScriptRoot\install-mcp-servers.ps1"

# Configure Claude
Write-Host ""
Write-Host "Step 3: Configuring Claude Desktop..." -ForegroundColor Cyan
& "$PSScriptRoot\configure-mcp-claude.ps1"

Write-Host ""
Write-Host "=== COMPLETE ===" -ForegroundColor Green
Write-Host "Restart Claude Desktop to use the MCP servers" -ForegroundColor Yellow
