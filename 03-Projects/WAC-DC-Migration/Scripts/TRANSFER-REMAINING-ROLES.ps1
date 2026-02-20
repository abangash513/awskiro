# TRANSFER REMAINING FSMO ROLES TO WACPRODDC02
# Run this script ON WACPRODDC01 after fixing WACPRODDC02 connectivity
# This will transfer RID Master and Infrastructure Master to WACPRODDC02

param(
    [string]$LogPath = "C:\Cutover\Logs",
    [switch]$WhatIf = $false
)

$ErrorActionPreference = "Stop"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = "$LogPath\Transfer-Remaining-$timestamp.log"

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

Write-Log "========================================" "INFO"
Write-Log "TRANSFER REMAINING FSMO ROLES" "INFO"
Write-Log "========================================" "INFO"
Write-Log "Target: WACPRODDC02" "INFO"
Write-Log "Roles: RID Master, Infrastructure Master" "INFO"
Write-Log "" "INFO"

# Verify running on WACPRODDC01
if ($env:COMPUTERNAME -ne "WACPRODDC01") {
    Write-Log "ERROR: This script must run on WACPRODDC01" "ERROR"
    exit 1
}

# Import AD module
Import-Module ActiveDirectory

# Step 1: Test connectivity to WACPRODDC02
Write-Log "Step 1: Testing connectivity to WACPRODDC02..." "INFO"

# Test ADWS port (9389)
Write-Log "  Testing port 9389 (ADWS)..." "INFO"
$adwsTest = Test-NetConnection -ComputerName 10.70.11.10 -Port 9389 -WarningAction SilentlyContinue
if ($adwsTest.TcpTestSucceeded) {
    Write-Log "  Port 9389 is accessible!" "SUCCESS"
} else {
    Write-Log "  Port 9389 is NOT accessible" "ERROR"
    Write-Log "" "ERROR"
    Write-Log "ACTION REQUIRED:" "ERROR"
    Write-Log "1. Log into WACPRODDC02" "ERROR"
    Write-Log "2. Run: Start-Service ADWS" "ERROR"
    Write-Log "3. Run: Set-Service ADWS -StartupType Automatic" "ERROR"
    Write-Log "4. Check AWS Security Group allows port 9389 inbound" "ERROR"
    exit 1
}

# Test AD cmdlet access
Write-Log "  Testing AD cmdlet access..." "INFO"
try {
    $dc = Get-ADDomainController -Identity WACPRODDC02 -ErrorAction Stop
    Write-Log "  AD cmdlet access successful!" "SUCCESS"
    Write-Log "    DC Name: $($dc.Name)" "INFO"
    Write-Log "    IP: $($dc.IPv4Address)" "INFO"
} catch {
    Write-Log "  AD cmdlet access failed: $($_.Exception.Message)" "ERROR"
    exit 1
}

Write-Log "" "INFO"

# Step 2: Check current FSMO holders
Write-Log "Step 2: Checking current FSMO holders..." "INFO"
$domain = Get-ADDomain
$forest = Get-ADForest

Write-Log "  Current FSMO roles:" "INFO"
Write-Log "    PDC Emulator: $($domain.PDCEmulator)" "INFO"
Write-Log "    RID Master: $($domain.RIDMaster)" "INFO"
Write-Log "    Infrastructure Master: $($domain.InfrastructureMaster)" "INFO"
Write-Log "    Schema Master: $($forest.SchemaMaster)" "INFO"
Write-Log "    Domain Naming Master: $($forest.DomainNamingMaster)" "INFO"
Write-Log "" "INFO"

# Check if roles are already on WACPRODDC02
$ridOnDC02 = $domain.RIDMaster -like "*WACPRODDC02*"
$infraOnDC02 = $domain.InfrastructureMaster -like "*WACPRODDC02*"

if ($ridOnDC02 -and $infraOnDC02) {
    Write-Log "Both roles are already on WACPRODDC02!" "SUCCESS"
    Write-Log "No transfer needed." "INFO"
    exit 0
}

# Step 3: Transfer roles
Write-Log "Step 3: Transferring FSMO roles to WACPRODDC02..." "INFO"

if ($WhatIf) {
    Write-Log "WHATIF: Would transfer RID Master and Infrastructure Master to WACPRODDC02" "WARNING"
} else {
    Write-Log "" "WARNING"
    Write-Log "========================================" "WARNING"
    Write-Log "READY TO TRANSFER ROLES" "WARNING"
    Write-Log "========================================" "WARNING"
    Write-Log "Press CTRL+C to cancel, or" "WARNING"
    Write-Host "Press any key to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Write-Log "" "INFO"
    
    try {
        Write-Log "Transferring RID Master and Infrastructure Master..." "INFO"
        Move-ADDirectoryServerOperationMasterRole -Identity WACPRODDC02 `
            -OperationMasterRole RIDMaster,InfrastructureMaster `
            -Force -Confirm:$false -ErrorAction Stop
        
        Write-Log "Transfer command completed!" "SUCCESS"
        Start-Sleep -Seconds 5
    } catch {
        Write-Log "ERROR: Transfer failed: $($_.Exception.Message)" "ERROR"
        exit 1
    }
}

Write-Log "" "INFO"

# Step 4: Verify transfer
Write-Log "Step 4: Verifying transfer..." "INFO"
Start-Sleep -Seconds 3

$domain = Get-ADDomain
$ridMaster = $domain.RIDMaster
$infraMaster = $domain.InfrastructureMaster

Write-Log "  RID Master: $ridMaster" "INFO"
Write-Log "  Infrastructure Master: $infraMaster" "INFO"

$ridSuccess = $ridMaster -like "*WACPRODDC02*"
$infraSuccess = $infraMaster -like "*WACPRODDC02*"

if ($ridSuccess -and $infraSuccess) {
    Write-Log "" "SUCCESS"
    Write-Log "========================================" "SUCCESS"
    Write-Log "TRANSFER SUCCESSFUL!" "SUCCESS"
    Write-Log "========================================" "SUCCESS"
} else {
    Write-Log "" "ERROR"
    Write-Log "========================================" "ERROR"
    Write-Log "TRANSFER VERIFICATION FAILED" "ERROR"
    Write-Log "========================================" "ERROR"
    if (-not $ridSuccess) {
        Write-Log "  RID Master NOT on WACPRODDC02" "ERROR"
    }
    if (-not $infraSuccess) {
        Write-Log "  Infrastructure Master NOT on WACPRODDC02" "ERROR"
    }
    exit 1
}

Write-Log "" "INFO"

# Step 5: Force replication
Write-Log "Step 5: Forcing AD replication..." "INFO"
if (-not $WhatIf) {
    repadmin /syncall /AdeP
    Start-Sleep -Seconds 10
    Write-Log "Replication forced" "SUCCESS"
}

Write-Log "" "INFO"

# Step 6: Final verification
Write-Log "Step 6: Final FSMO verification..." "INFO"
$fsmo = netdom query fsmo
Write-Log "Final FSMO roles:" "INFO"
$fsmo | ForEach-Object { Write-Log "  $_" "INFO" }

Write-Log "" "INFO"
Write-Log "========================================" "SUCCESS"
Write-Log "MIGRATION COMPLETE!" "SUCCESS"
Write-Log "========================================" "SUCCESS"
Write-Log "" "INFO"
Write-Log "WACPRODDC01 holds:" "INFO"
Write-Log "  - PDC Emulator" "INFO"
Write-Log "  - Schema Master" "INFO"
Write-Log "  - Domain Naming Master" "INFO"
Write-Log "" "INFO"
Write-Log "WACPRODDC02 holds:" "INFO"
Write-Log "  - RID Master" "INFO"
Write-Log "  - Infrastructure Master" "INFO"
Write-Log "" "INFO"
Write-Log "Next Step: Run 3-POST-CUTOVER-VERIFY.ps1" "INFO"
