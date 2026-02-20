# Azure WAF Test - Module Installation Script
# This script installs required Azure PowerShell modules

Write-Host "=== Azure Module Installation ===" -ForegroundColor Cyan
Write-Host ""

# Check PowerShell version
$psVersion = $PSVersionTable.PSVersion
Write-Host "PowerShell Version: $psVersion" -ForegroundColor Yellow

if ($psVersion.Major -lt 7) {
    Write-Warning "PowerShell 7+ is recommended. Current version: $psVersion"
    $continue = Read-Host "Continue anyway? (Y/N)"
    if ($continue -ne 'Y') {
        exit
    }
}

# Install NuGet provider if needed
Write-Host "Installing NuGet provider..." -ForegroundColor Green
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null

# Set PSGallery as trusted
Write-Host "Setting PSGallery as trusted repository..." -ForegroundColor Green
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

# Install Az modules
$modules = @(
    'Az.Accounts',
    'Az.Advisor',
    'Az.Resources',
    'Az.Storage',
    'Az.Network',
    'Az.Websites',
    'Az.Monitor'
)

foreach ($module in $modules) {
    Write-Host "Installing $module..." -ForegroundColor Green
    try {
        Install-Module -Name $module -Force -AllowClobber -Scope CurrentUser -ErrorAction Stop
        Write-Host "  Success: $module installed" -ForegroundColor Green
    }
    catch {
        Write-Host "  Failed to install $module" -ForegroundColor Red
        Write-Host "    Error: $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Installation Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next step: Run .\02-connect-azure.ps1 to connect to Azure" -ForegroundColor Yellow
