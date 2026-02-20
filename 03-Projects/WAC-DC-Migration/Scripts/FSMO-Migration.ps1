# FSMO Migration Script
# Migrates all 5 FSMO roles to WACPRODDC01

param(
    [Parameter(Mandatory=$false)]
    [string]$TargetDC = "WACPRODDC01",
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"
$logFile = "C:\Logs\FSMO-Migration-$(Get-Date -Format yyyyMMddHHmmss).log"

# Create log directory
New-Item -Path "C:\Logs" -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

Start-Transcript -Path $logFile

Write-Host "=== FSMO Migration Script ===" -ForegroundColor Green
Write-Host "Target DC: $TargetDC" -ForegroundColor Cyan
Write-Host "WhatIf Mode: $WhatIf" -ForegroundColor Yellow
Write-Host ""

# Function to verify FSMO role
function Verify-FSMORole {
    param([string]$Role)
    
    Write-Host "Verifying $Role..." -ForegroundColor Yellow
    $fsmo = netdom query fsmo
    Write-Host $fsmo
    Write-Host ""
}

# Function to move FSMO role
function Move-FSMORole {
    param(
        [string]$Role,
        [string]$Target
    )
    
    Write-Host "Moving $Role to $Target..." -ForegroundColor Yellow
    
    if ($WhatIf) {
        Write-Host "[WHATIF] Would move $Role to $Target" -ForegroundColor Cyan
    } else {
        try {
            Move-ADDirectoryServerOperationMasterRole -Identity $Target -OperationMasterRole $Role -Force -Confirm:$false
            Write-Host "✅ Successfully moved $Role" -ForegroundColor Green
            
            # Force replication
            repadmin /syncall /AdeP
            
            # Wait 30 seconds
            Start-Sleep -Seconds 30
            
        } catch {
            Write-Host "❌ Failed to move $Role : $($_.Exception.Message)" -ForegroundColor Red
            throw
        }
    }
}

# Pre-flight checks
Write-Host "=== Pre-Flight Checks ===" -ForegroundColor Green

Write-Host "Current FSMO role holders:" -ForegroundColor Yellow
Verify-FSMORole

Write-Host "Checking replication health..." -ForegroundColor Yellow
repadmin /replsummary

Write-Host "Checking target DC health..." -ForegroundColor Yellow
Get-ADDomainController -Identity $TargetDC | Select Name,IPv4Address,IsGlobalCatalog,OperatingSystem

Write-Host ""
Write-Host "=== Starting FSMO Migration ===" -ForegroundColor Green
Write-Host ""

# Migration order (least critical to most critical)
$roles = @(
    "InfrastructureMaster",
    "RIDMaster",
    "DomainNamingMaster",
    "SchemaMaster",
    "PDCEmulator"
)

foreach ($role in $roles) {
    Write-Host "--- Step: $role ---" -ForegroundColor Cyan
    Move-FSMORole -Role $role -Target $TargetDC
    Write-Host ""
}

# Post-migration verification
Write-Host "=== Post-Migration Verification ===" -ForegroundColor Green

Write-Host "New FSMO role holders:" -ForegroundColor Yellow
Verify-FSMORole

Write-Host "Checking replication health..." -ForegroundColor Yellow
repadmin /replsummary

Write-Host "Checking event logs..." -ForegroundColor Yellow
Get-EventLog -LogName "Directory Service" -Newest 20 | Where-Object {$_.EntryType -eq "Error"} | Format-Table -AutoSize

Write-Host ""
Write-Host "=== FSMO Migration Complete ===" -ForegroundColor Green
Write-Host "Log file: $logFile" -ForegroundColor Cyan

Stop-Transcript
