# WAC AD CUTOVER - ROLLBACK SCRIPT
# Version: 1.0
# Purpose: Rollback FSMO roles to AD01/AD02 if cutover fails
# Run on: AD01 (On-Prem DC) - ONLY IF CUTOVER FAILS
# Run as: Domain Admin

param(
    [string]$Domain = "wac.net",
    [string]$LogPath = "C:\Cutover\Logs",
    [switch]$Force = $false
)

$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = "$LogPath\Rollback-$timestamp.log"

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

Write-Log "========================================" "ERROR"
Write-Log "WAC AD CUTOVER - EMERGENCY ROLLBACK" "ERROR"
Write-Log "========================================" "ERROR"
Write-Log "Domain: $Domain" "INFO"
Write-Log "Run From: $env:COMPUTERNAME" "INFO"
Write-Log "Run By: $env:USERNAME" "INFO"
Write-Log "" "INFO"

# Verify running on AD01
if ($env:COMPUTERNAME -ne "AD01" -and -not $Force) {
    Write-Log "ERROR: This script should run on AD01" "ERROR"
    Write-Log "Use -Force to run from another DC" "WARNING"
    exit 1
}

# Warning
Write-Log "========================================" "WARNING"
Write-Log "WARNING: ROLLBACK OPERATION" "WARNING"
Write-Log "========================================" "WARNING"
Write-Log "This will transfer FSMO roles BACK to AD01/AD02" "WARNING"
Write-Log "Only run this if the cutover failed!" "WARNING"
Write-Log "" "WARNING"

if (-not $Force) {
    Write-Host "Type 'ROLLBACK' to confirm: " -ForegroundColor Red -NoNewline
    $confirmation = Read-Host
    if ($confirmation -ne "ROLLBACK") {
        Write-Log "Rollback cancelled" "INFO"
        exit 0
    }
}

Import-Module ActiveDirectory

Write-Log "Starting rollback..." "INFO"
Write-Log "" "INFO"

$allSuccess = $true

# Rollback Phase 1: Transfer roles back to AD01
Write-Log "========================================" "INFO"
Write-Log "PHASE 1: Transfer roles back to AD01" "INFO"
Write-Log "========================================" "INFO"

try {
    Write-Log "Transferring PDC Emulator to AD01..." "INFO"
    Move-ADDirectoryServerOperationMasterRole -Identity "AD01" -OperationMasterRole PDCEmulator -Force -Confirm:$false
    Write-Log "SUCCESS: PDC Emulator transferred to AD01" "SUCCESS"
    Start-Sleep -Seconds 10
} catch {
    Write-Log "ERROR: Failed to transfer PDC Emulator - $($_.Exception.Message)" "ERROR"
    $allSuccess = $false
}

try {
    Write-Log "Transferring Schema Master to AD01..." "INFO"
    Move-ADDirectoryServerOperationMasterRole -Identity "AD01" -OperationMasterRole SchemaMaster -Force -Confirm:$false
    Write-Log "SUCCESS: Schema Master transferred to AD01" "SUCCESS"
    Start-Sleep -Seconds 10
} catch {
    Write-Log "ERROR: Failed to transfer Schema Master - $($_.Exception.Message)" "ERROR"
    $allSuccess = $false
}

try {
    Write-Log "Transferring Domain Naming Master to AD01..." "INFO"
    Move-ADDirectoryServerOperationMasterRole -Identity "AD01" -OperationMasterRole DomainNamingMaster -Force -Confirm:$false
    Write-Log "SUCCESS: Domain Naming Master transferred to AD01" "SUCCESS"
    Start-Sleep -Seconds 10
} catch {
    Write-Log "ERROR: Failed to transfer Domain Naming Master - $($_.Exception.Message)" "ERROR"
    $allSuccess = $false
}

# Rollback Phase 2: Transfer roles back to AD02
Write-Log "========================================" "INFO"
Write-Log "PHASE 2: Transfer roles back to AD02" "INFO"
Write-Log "========================================" "INFO"

try {
    Write-Log "Transferring RID Master to AD02..." "INFO"
    Move-ADDirectoryServerOperationMasterRole -Identity "AD02" -OperationMasterRole RIDMaster -Force -Confirm:$false
    Write-Log "SUCCESS: RID Master transferred to AD02" "SUCCESS"
    Start-Sleep -Seconds 10
} catch {
    Write-Log "ERROR: Failed to transfer RID Master - $($_.Exception.Message)" "ERROR"
    $allSuccess = $false
}

try {
    Write-Log "Transferring Infrastructure Master to AD02..." "INFO"
    Move-ADDirectoryServerOperationMasterRole -Identity "AD02" -OperationMasterRole InfrastructureMaster -Force -Confirm:$false
    Write-Log "SUCCESS: Infrastructure Master transferred to AD02" "SUCCESS"
    Start-Sleep -Seconds 10
} catch {
    Write-Log "ERROR: Failed to transfer Infrastructure Master - $($_.Exception.Message)" "ERROR"
    $allSuccess = $false
}

# Force replication
Write-Log "========================================" "INFO"
Write-Log "Forcing replication..." "INFO"
Write-Log "========================================" "INFO"
repadmin /syncall /AdeP
Start-Sleep -Seconds 30

# Verify rollback
Write-Log "========================================" "INFO"
Write-Log "Verifying rollback..." "INFO"
Write-Log "========================================" "INFO"

$fsmo = netdom query fsmo
$fsmo | ForEach-Object { Write-Log "  $_" "INFO" }

$ad01Count = ($fsmo | Select-String "AD01").Count
$ad02Count = ($fsmo | Select-String "AD02").Count

Write-Log "" "INFO"
Write-Log "AD01 holds $ad01Count roles (expected: 3)" "INFO"
Write-Log "AD02 holds $ad02Count roles (expected: 2)" "INFO"
Write-Log "" "INFO"

if ($ad01Count -eq 3 -and $ad02Count -eq 2) {
    Write-Log "========================================" "SUCCESS"
    Write-Log "ROLLBACK SUCCESSFUL" "SUCCESS"
    Write-Log "========================================" "SUCCESS"
    Write-Log "FSMO roles restored to AD01/AD02" "SUCCESS"
    exit 0
} else {
    Write-Log "========================================" "ERROR"
    Write-Log "ROLLBACK INCOMPLETE" "ERROR"
    Write-Log "========================================" "ERROR"
    Write-Log "Manual intervention required" "ERROR"
    exit 1
}
