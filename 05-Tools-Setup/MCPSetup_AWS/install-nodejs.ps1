# Download and Install Node.js

Write-Host "=== Node.js Installation ===" -ForegroundColor Green
Write-Host ""

$nodeVersion = "v20.18.1"
$installerUrl = "https://nodejs.org/dist/$nodeVersion/node-$nodeVersion-x64.msi"
$installerPath = Join-Path $env:TEMP "nodejs-installer.msi"

Write-Host "Downloading Node.js $nodeVersion..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath

Write-Host "Installing Node.js..." -ForegroundColor Cyan
Write-Host "This will open the installer. Follow the prompts." -ForegroundColor Yellow
Write-Host ""

Start-Process msiexec.exe -ArgumentList "/i `"$installerPath`" /qn /norestart" -Wait

Write-Host ""
Write-Host "Node.js installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANT: Close and reopen PowerShell, then run:" -ForegroundColor Yellow
Write-Host "  .\install-mcp-servers.ps1" -ForegroundColor Cyan
Write-Host ""
