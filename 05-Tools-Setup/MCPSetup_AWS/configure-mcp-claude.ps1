# Configure MCP Servers for Claude Desktop
# This script creates the configuration file for Claude Desktop

Write-Host "=== Claude Desktop MCP Configuration ===" -ForegroundColor Green
Write-Host ""

$claudeConfigDir = Join-Path $env:APPDATA "Claude"
$claudeConfigFile = Join-Path $claudeConfigDir "claude_desktop_config.json"
$serversDir = Join-Path $PSScriptRoot "mcp-servers"

# Check if servers are installed
if (-not (Test-Path $serversDir)) {
    Write-Host "✗ MCP servers not found. Please run install-aws-mcp-servers.ps1 first" -ForegroundColor Red
    exit 1
}

# Create Claude config directory if it doesn't exist
if (-not (Test-Path $claudeConfigDir)) {
    New-Item -ItemType Directory -Path $claudeConfigDir | Out-Null
    Write-Host "Created Claude config directory" -ForegroundColor Gray
}

# Backup existing config
if (Test-Path $claudeConfigFile) {
    $backupFile = "$claudeConfigFile.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $claudeConfigFile $backupFile
    Write-Host "Backed up existing config to: $backupFile" -ForegroundColor Yellow
}

# Create configuration
$config = @{
    mcpServers = @{
        "aws-kb-retrieval" = @{
            command = "node"
            args = @(
                (Join-Path $serversDir "mcp-server-aws-kb-retrieval\build\index.js")
            )
        }
        "aws" = @{
            command = "node"
            args = @(
                (Join-Path $serversDir "mcp-servers-official\src\aws\dist\index.js")
            )
        }
        "aws-diagram" = @{
            command = "node"
            args = @(
                (Join-Path $serversDir "mcp-server-diagram-as-code\build\index.js")
            )
        }
    }
}

# Convert to JSON and save
$jsonConfig = $config | ConvertTo-Json -Depth 10
$jsonConfig | Out-File -FilePath $claudeConfigFile -Encoding UTF8

Write-Host "✓ Claude Desktop configuration created" -ForegroundColor Green
Write-Host ""
Write-Host "Configuration file: $claudeConfigFile" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configured MCP Servers:" -ForegroundColor Yellow
Write-Host "  • aws-kb-retrieval - AWS documentation queries" -ForegroundColor White
Write-Host "  • aws - AWS service interactions" -ForegroundColor White
Write-Host "  • aws-diagram - Architecture diagram design" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Restart Claude Desktop if it's running" -ForegroundColor White
Write-Host "  2. MCP servers will be available in Claude Desktop" -ForegroundColor White
Write-Host ""
