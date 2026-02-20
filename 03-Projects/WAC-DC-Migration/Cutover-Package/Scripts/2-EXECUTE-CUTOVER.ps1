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
        Move-ADDirectoryServerOperationMasterRole -Identity $TargetDC -OperationMasterRole $Role -Force -Confirm:$false -ErrorAction Stop
        
        Start-Sleep -Seconds 5
        
        # Verify transfer using proper method for each role type
        $verified = $false
        switch ($Role) {
            "PDCEmulator" {
                $currentHolder = (Get-ADDomain).PDCEmulator
                $verified = $currentHolder -like "*$TargetDC*"
            }
            "RIDMaster" {
                $currentHolder = (Get-ADDomain).RIDMaster
                $verified = $currentHolder -like "*$TargetDC*"
            }
            "InfrastructureMaster" {
                $currentHolder = (Get-ADDomain).InfrastructureMaster
                $verified = $currentHolder -like "*$TargetDC*"
            }
            "SchemaMaster" {
                $currentHolder = (Get-ADForest).SchemaMaster
                $verified = $currentHolder -like "*$TargetDC*"
            }
            "DomainNamingMaster" {
                $currentHolder = (Get-ADForest).DomainNamingMaster
                $verified = $currentHolder -like "*$TargetDC*"
            }
        }
        
        if ($verified) {
            Write-Log "SUCCESS: $RoleName transferred to $TargetDC" "SUCCESS"
            Write-Log "  Verified: Now held by $currentHolder" "INFO"
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

# Check permissions - Must be Enterprise Admin and Schema Admin
Write-Log "Checking permissions..." "INFO"
$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$userGroups = $currentUser.Groups | ForEach-Object { $_.Translate([System.Security.Principal.NTAccount]).Value }

$isEnterpriseAdmin = $userGroups -match "Enterprise Admins"
$isSchemaAdmin = $userGroups -match "Schema Admins"

if (-not $isEnterpriseAdmin) {
    Write-Log "ERROR: User must be a member of Enterprise Admins group" "ERROR"
    Write-Log "Current user: $($currentUser.Name)" "ERROR"
    Write-Log "" "ERROR"
    Write-Log "To fix: Add-ADGroupMember -Identity 'Enterprise Admins' -Members '$env:USERNAME'" "ERROR"
    exit 1
}

if (-not $isSchemaAdmin) {
    Write-Log "ERROR: User must be a member of Schema Admins group" "ERROR"
    Write-Log "Schema Master transfer will fail without this membership" "ERROR"
    Write-Log "" "ERROR"
    Write-Log "To fix: Add-ADGroupMember -Identity 'Schema Admins' -Members '$env:USERNAME'" "ERROR"
    Write-Log "Then log out and back in for group membership to take effect" "ERROR"
    exit 1
}

Write-Log "Permission check passed: User is Enterprise Admin and Schema Admin" "SUCCESS"

# Check ADWS on WACPRODDC02
Write-Log "Checking Active Directory Web Services on WACPRODDC02..." "INFO"
$adwsOk = $false
try {
    # Try to get the service
    $adwsService = Get-Service -Name ADWS -ComputerName WACPRODDC02 -ErrorAction Stop
    
    if ($adwsService.Status -eq "Running") {
        Write-Log "ADWS is running on WACPRODDC02" "SUCCESS"
        $adwsOk = $true
    } else {
        Write-Log "WARNING: ADWS is not running on WACPRODDC02 (Status: $($adwsService.Status))" "WARNING"
        Write-Log "Attempting to start ADWS..." "INFO"
        try {
            Start-Service -Name ADWS -ComputerName WACPRODDC02 -ErrorAction Stop
            Start-Sleep -Seconds 5
            $adwsService = Get-Service -Name ADWS -ComputerName WACPRODDC02
            if ($adwsService.Status -eq "Running") {
                Write-Log "ADWS started successfully" "SUCCESS"
                $adwsOk = $true
            }
        } catch {
            Write-Log "ERROR: Failed to start ADWS: $($_.Exception.Message)" "ERROR"
        }
    }
} catch {
    Write-Log "ERROR: Cannot access ADWS on WACPRODDC02: $($_.Exception.Message)" "ERROR"
    Write-Log "This may be Windows Server Core without ADWS installed" "WARNING"
    
    # Try alternative check - can we reach the DC via AD cmdlets?
    try {
        $dc = Get-ADDomainController -Identity WACPRODDC02 -ErrorAction Stop
        if ($dc) {
            Write-Log "WACPRODDC02 is reachable via AD cmdlets" "INFO"
            Write-Log "Transfers may still work despite ADWS warning" "INFO"
            $adwsOk = $true
        }
    } catch {
        Write-Log "ERROR: Cannot reach WACPRODDC02 via AD cmdlets either" "ERROR"
    }
}

if (-not $adwsOk) {
    Write-Log "ERROR: WACPRODDC02 is not ready for FSMO transfers" "ERROR"
    Write-Log "Please ensure WACPRODDC02 is online and ADWS is running" "ERROR"
    Write-Log "" "ERROR"
    Write-Log "To fix on WACPRODDC02:" "ERROR"
    Write-Log "  Get-Service ADWS" "ERROR"
    Write-Log "  Start-Service ADWS" "ERROR"
    Write-Log "  Set-Service ADWS -StartupType Automatic" "ERROR"
    exit 1
}

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
