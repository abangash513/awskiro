# Demote Domain Controller Script
# Run on the DC to be decommissioned

param(
    [Parameter(Mandatory=$true)]
    [string]$DCName,
    [string]$LocalAdminPassword = "TempPass123!"
)

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "DECOMMISSIONING DC: $DCName" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

# Verify no FSMO roles
Write-Host "Checking FSMO roles..." -ForegroundColor Cyan
$fsmo = netdom query fsmo
if ($fsmo -match $DCName) {
    Write-Host "ERROR: DC still holds FSMO roles!" -ForegroundColor Red
    Write-Host "Transfer FSMO roles before decommissioning" -ForegroundColor Red
    exit 1
}

Write-Host "PASS: No FSMO roles on this DC" -ForegroundColor Green

# Confirm
Write-Host ""
Write-Host "WARNING: About to demote $DCName" -ForegroundColor Yellow
$confirm = Read-Host "Type 'DEMOTE' to confirm"

if ($confirm -ne "DEMOTE") {
    Write-Host "Decommission cancelled" -ForegroundColor Yellow
    exit 0
}

# Demote
Write-Host "Demoting DC..." -ForegroundColor Cyan
$securePassword = ConvertTo-SecureString $LocalAdminPassword -AsPlainText -Force
Uninstall-ADDSDomainController -LocalAdministratorPassword $securePassword -Force

Write-Host "DC demotion initiated. Server will reboot." -ForegroundColor Green
