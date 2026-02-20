# WAC AD CUTOVER - FSMO TRANSFER SCRIPT
# Version: 1.0
# Purpose: Transfer all FSMO roles from AD01/AD02 to WACPRODDC01/02
# Run on: WACPRODDC01 (AWS DC)
# Run as: Domain Admin

param(
    [string]$Domain = "wac.net",
    [string]$LogPath = "C:\Cutover\Logs",
    [switch]$WhatIf = $false
)

$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = "$LogPath\Cutover-$timestamp.log"

# Create log directory
New-Item -ItemType Directory -Path $LogPath -Force | Out-Null

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    $color = switch ($Level) {
        "SUCCESS" { "Green" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        default { "White" }
    }
    Write-Host $logMessage -ForegroundColor $color
    Add-Content -Path $logFile -Value $logMessage
}

function Get-CurrentFSMO {
    Write-Log "Getting current FSMO role holders..." "INFO"
    $fsmo = netdom query fsmo
    Write-Log "Current FSMO roles:" "INFO"
    $fsmo | ForEach-Object { Write-Log "  $_" "INFO" }
    return $fsmo
}

function Transfer-FSMORole {
    param(
        [string]$Role,
        [string]$TargetDC,
        [string]$RoleName
    )
    
    Write-Log "========================================" "INFO"
    Write-Log "Transferring: $RoleName" "INFO"
    Write-Log "Target DC: $TargetDC" "INFO"
    Write-Log "========================================" "INFO"
    
    if ($WhatIf) {
        Write-Log "WHATIF: Would transfer $RoleName to $TargetDC" "WARNING"
        return $true
    }
    
    try {
        # Transfer using Move-ADDirectoryServerOperationMasterRole
        Write-Log "Executing transfer..." "INFO"
        Move-ADDirectoryServerOperationMasterRole -Identity $TargetDC -OperationMasterRole $Role -Force -Confirm:$false
        
        Start-Sleep -Seconds 5
        
        # Verify transfer
        $currentHolder = Get-ADDomain | Select-Object -ExpandProperty $Role
        if ($currentHolder -like "*$TargetDC*") {
            Write-Log "SUCCESS: $RoleName transferred to $TargetDC" "SUCCESS"
            return $true
        } else {
            Write-Log "FAILED: $RoleName NOT transferred (still on $currentHolder)" "ERROR"
            return $false
        }
    } catch {
        Write-Log "ERROR: Failed to transfer $RoleName - $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Main execution
Write-Log "========================================" "INFO"
Write-Log "WAC AD CUTOVER - FSMO TRANSFER" "INFO"
Write-Log "========================================" "INFO"
Write-Log "Domain: $Domain" "INFO"
Write-Log "Run From: $env:COMPUTERNAME" "INFO"
Write-Log "Run By: $env:USERNAME" "INFO"
Write-Log "WhatIf Mode: $WhatIf" "INFO"
Write-Log "" "INFO"

# Verify running on WACPRODDC01
if ($env:COMPUTERNAME -ne "WACPRODDC01") {
    Write-Log "ERROR: This script must run on WACPRODDC01" "ERROR"
    exit 1
}

# Import AD module
Import-Module ActiveDirectory

# Document current state
Write-Log "STEP 1: Document current FSMO holders" "INFO"
$beforeFSMO = Get-CurrentFSMO
Write-Log "" "INFO"

# Create backup of current state
$backupFile = "$LogPath\FSMO-Backup-$timestamp.txt"
$beforeFSMO | Out-File -FilePath $backupFile
Write-Log "Backup saved to: $backupFile" "INFO"
Write-Log "" "INFO"

# Pause for confirmation
if (-not $WhatIf) {
    Write-Log "========================================" "WARNING"
    Write-Log "READY TO BEGIN FSMO TRANSFER" "WARNING"
    Write-Log "========================================" "WARNING"
    Write-Log "Press CTRL+C to cancel, or" "WARNING"
    Write-Host "Press any key to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Write-Log "" "INFO"
}

$allSuccess = $true

# PHASE 1: Transfer roles to WACPRODDC01
Write-Log "========================================" "INFO"
Write-Log "PHASE 1: Transfer roles to WACPRODDC01" "INFO"
Write-Log "========================================" "INFO"
Write-Log "" "INFO"

# Transfer PDC Emulator
$success1 = Transfer-FSMORole -Role "PDCEmulator" -TargetDC "WACPRODDC01" -RoleName "PDC Emulator"
$allSuccess = $allSuccess -and $success1
Start-Sleep -Seconds 10

# Transfer Schema Master
$success2 = Transfer-FSMORole -Role "SchemaMaster" -TargetDC "WACPRODDC01" -RoleName "Schema Master"
$allSuccess = $allSuccess -and $success2
Start-Sleep -Seconds 10

# Transfer Domain Naming Master
$success3 = Transfer-FSMORole -Role "DomainNamingMaster" -TargetDC "WACPRODDC01" -RoleName "Domain Naming Master"
$allSuccess = $allSuccess -and $success3
Start-Sleep -Seconds 10

Write-Log "" "INFO"
Write-Log "PHASE 1 Complete: WACPRODDC01 roles transferred" "INFO"
Write-Log "" "INFO"

# PHASE 2: Transfer roles to WACPRODDC02
Write-Log "========================================" "INFO"
Write-Log "PHASE 2: Transfer roles to WACPRODDC02" "INFO"
Write-Log "========================================" "INFO"
Write-Log "" "INFO"

# Transfer RID Master
$success4 = Transfer-FSMORole -Role "RIDMaster" -TargetDC "WACPRODDC02" -RoleName "RID Pool Manager"
$allSuccess = $allSuccess -and $success4
Start-Sleep -Seconds 10

# Transfer Infrastructure Master
$success5 = Transfer-FSMORole -Role "InfrastructureMaster" -TargetDC "WACPRODDC02" -RoleName "Infrastructure Master"
$allSuccess = $allSuccess -and $success5
Start-Sleep -Seconds 10

Write-Log "" "INFO"
Write-Log "PHASE 2 Complete: WACPRODDC02 roles transferred" "INFO"
Write-Log "" "INFO"

# Force replication
Write-Log "========================================" "INFO"
Write-Log "STEP 2: Force replication across domain" "INFO"
Write-Log "========================================" "INFO"

if (-not $WhatIf) {
    repadmin /syncall /AdeP
    Start-Sleep -Seconds 30
    Write-Log "Replication forced" "SUCCESS"
} else {
    Write-Log "WHATIF: Would force replication" "WARNING"
}

Write-Log "" "INFO"

# Verify final state
Write-Log "========================================" "INFO"
Write-Log "STEP 3: Verify new FSMO holders" "INFO"
Write-Log "========================================" "INFO"

$afterFSMO = Get-CurrentFSMO
Write-Log "" "INFO"

# Summary
Write-Log "========================================" "INFO"
Write-Log "CUTOVER SUMMARY" "INFO"
Write-Log "========================================" "INFO"

if ($allSuccess) {
    Write-Log "Result: ALL TRANSFERS SUCCESSFUL" "SUCCESS"
    Write-Log "" "INFO"
    Write-Log "Next Step: Run 3-POST-CUTOVER-VERIFY.ps1" "INFO"
    exit 0
} else {
    Write-Log "Result: SOME TRANSFERS FAILED" "ERROR"
    Write-Log "" "INFO"
    Write-Log "Action Required: Run 4-ROLLBACK.ps1" "ERROR"
    exit 1
}
