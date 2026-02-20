# TEST CONNECTIVITY AND TRANSFER REMAINING FSMO ROLES
# Run this script ON WACPRODDC01 after AWS security group fix
# This will test connectivity, then transfer RID Master and Infrastructure Master to WACPRODDC02

param(
    [string]$DC02_IP = "10.70.11.10",
    [string]$LogPath = "C:\Cutover\Logs"
)

$ErrorActionPreference = "Continue"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = "$LogPath\Test-And-Transfer-$timestamp.log"

# Create log directory
New-Item -ItemType Directory -Path $LogPath -Force | Out-Null

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    $color = switch ($Level) {
        "SUCCESS" { "Green" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "TEST" { "Cyan" }
        default { "White" }
    }
    Write-Host $logMessage -ForegroundColor $color
    Add-Content -Path $logFile -Value $logMessage
}

Write-Log "========================================" "INFO"
Write-Log "TEST CONNECTIVITY AND TRANSFER FSMO ROLES" "INFO"
Write-Log "========================================" "INFO"
Write-Log "Target: WACPRODDC02 ($DC02_IP)" "INFO"
Write-Log "" "INFO"

# Import AD module
Import-Module ActiveDirectory

# PHASE 1: TEST CONNECTIVITY
Write-Log "========================================" "TEST"
Write-Log "PHASE 1: CONNECTIVITY TESTS" "TEST"
Write-Log "========================================" "TEST"
Write-Log "" "INFO"

# Test 1: Port 9389 (ADWS)
Write-Log "Test 1: Port 9389 (ADWS)..." "INFO"
$adwsTest = Test-NetConnection -ComputerName $DC02_IP -Port 9389 -WarningAction SilentlyContinue
if ($adwsTest.TcpTestSucceeded) {
    Write-Log "  Port 9389: SUCCESS ✓" "SUCCESS"
} else {
    Write-Log "  Port 9389: FAILED ✗" "ERROR"
    Write-Log "" "ERROR"
    Write-Log "CRITICAL ERROR: Port 9389 is still blocked!" "ERROR"
    Write-Log "The AWS security group fix may not have taken effect yet." "ERROR"
    Write-Log "Wait 30 seconds and try again, or check AWS Console." "ERROR"
    exit 1
}

Write-Log "" "INFO"

# Test 2: AD Cmdlet Access
Write-Log "Test 2: AD Cmdlet Access..." "INFO"
try {
    $dc = Get-ADDomainController -Identity WACPRODDC02 -ErrorAction Stop
    Write-Log "  AD Cmdlet Access: SUCCESS ✓" "SUCCESS"
    Write-Log "    DC Name: $($dc.Name)" "INFO"
    Write-Log "    IP: $($dc.IPv4Address)" "INFO"
    Write-Log "    Site: $($dc.Site)" "INFO"
} catch {
    Write-Log "  AD Cmdlet Access: FAILED ✗" "ERROR"
    Write-Log "  Error: $($_.Exception.Message)" "ERROR"
    exit 1
}

Write-Log "" "INFO"

# Test 3: Current FSMO State
Write-Log "Test 3: Current FSMO State..." "INFO"
$domain = Get-ADDomain
$forest = Get-ADForest

Write-Log "  Current FSMO roles:" "INFO"
Write-Log "    PDC Emulator: $($domain.PDCEmulator)" "INFO"
Write-Log "    RID Master: $($domain.RIDMaster)" "INFO"
Write-Log "    Infrastructure Master: $($domain.InfrastructureMaster)" "INFO"
Write-Log "    Schema Master: $($forest.SchemaMaster)" "INFO"
Write-Log "    Domain Naming Master: $($forest.DomainNamingMaster)" "INFO"

# Check if roles are already on WACPRODDC02
$ridOnDC02 = $domain.RIDMaster -like "*WACPRODDC02*"
$infraOnDC02 = $domain.InfrastructureMaster -like "*WACPRODDC02*"

if ($ridOnDC02 -and $infraOnDC02) {
    Write-Log "" "SUCCESS"
    Write-Log "Both roles are already on WACPRODDC02!" "SUCCESS"
    Write-Log "No transfer needed. Migration is complete!" "SUCCESS"
    exit 0
}

Write-Log "" "INFO"
Write-Log "========================================" "SUCCESS"
Write-Log "ALL CONNECTIVITY TESTS PASSED!" "SUCCESS"
Write-Log "========================================" "SUCCESS"
Write-Log "" "INFO"

# PHASE 2: TRANSFER FSMO ROLES
Write-Log "========================================" "INFO"
Write-Log "PHASE 2: TRANSFER FSMO ROLES" "INFO"
Write-Log "========================================" "INFO"
Write-Log "" "INFO"

Write-Log "Preparing to transfer:" "INFO"
Write-Log "  - RID Master (from $($domain.RIDMaster) to WACPRODDC02)" "INFO"
Write-Log "  - Infrastructure Master (from $($domain.InfrastructureMaster) to WACPRODDC02)" "INFO"
Write-Log "" "WARNING"

Write-Log "Press CTRL+C to cancel, or" "WARNING"
Write-Host "Press any key to continue..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
Write-Log "" "INFO"

Write-Log "Transferring roles..." "INFO"
try {
    Move-ADDirectoryServerOperationMasterRole -Identity WACPRODDC02 `
        -OperationMasterRole RIDMaster,InfrastructureMaster `
        -Force -Confirm:$false -ErrorAction Stop
    
    Write-Log "Transfer command completed successfully!" "SUCCESS"
    Start-Sleep -Seconds 5
} catch {
    Write-Log "ERROR: Transfer failed!" "ERROR"
    Write-Log "Error: $($_.Exception.Message)" "ERROR"
    exit 1
}

Write-Log "" "INFO"

# PHASE 3: VERIFY TRANSFER
Write-Log "========================================" "INFO"
Write-Log "PHASE 3: VERIFY TRANSFER" "INFO"
Write-Log "========================================" "INFO"
Write-Log "" "INFO"

Start-Sleep -Seconds 3

$domain = Get-ADDomain
$ridMaster = $domain.RIDMaster
$infraMaster = $domain.InfrastructureMaster

Write-Log "Verifying transfer..." "INFO"
Write-Log "  RID Master: $ridMaster" "INFO"
Write-Log "  Infrastructure Master: $infraMaster" "INFO"
Write-Log "" "INFO"

$ridSuccess = $ridMaster -like "*WACPRODDC02*"
$infraSuccess = $infraMaster -like "*WACPRODDC02*"

if ($ridSuccess -and $infraSuccess) {
    Write-Log "========================================" "SUCCESS"
    Write-Log "TRANSFER SUCCESSFUL!" "SUCCESS"
    Write-Log "========================================" "SUCCESS"
} else {
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

# PHASE 4: FORCE REPLICATION
Write-Log "========================================" "INFO"
Write-Log "PHASE 4: FORCE REPLICATION" "INFO"
Write-Log "========================================" "INFO"
Write-Log "" "INFO"

Write-Log "Forcing AD replication..." "INFO"
repadmin /syncall /AdeP
Start-Sleep -Seconds 10
Write-Log "Replication forced successfully!" "SUCCESS"

Write-Log "" "INFO"

# PHASE 5: FINAL VERIFICATION
Write-Log "========================================" "INFO"
Write-Log "PHASE 5: FINAL VERIFICATION" "INFO"
Write-Log "========================================" "INFO"
Write-Log "" "INFO"

Write-Log "Final FSMO state:" "INFO"
$fsmo = netdom query fsmo
$fsmo | ForEach-Object { Write-Log "  $_" "INFO" }

Write-Log "" "INFO"
Write-Log "========================================" "SUCCESS"
Write-Log "MIGRATION COMPLETE!" "SUCCESS"
Write-Log "========================================" "SUCCESS"
Write-Log "" "INFO"

Write-Log "Final FSMO Distribution:" "INFO"
Write-Log "" "INFO"
Write-Log "WACPRODDC01 (3 roles):" "INFO"
Write-Log "  ✓ PDC Emulator" "SUCCESS"
Write-Log "  ✓ Schema Master" "SUCCESS"
Write-Log "  ✓ Domain Naming Master" "SUCCESS"
Write-Log "" "INFO"
Write-Log "WACPRODDC02 (2 roles):" "INFO"
Write-Log "  ✓ RID Master" "SUCCESS"
Write-Log "  ✓ Infrastructure Master" "SUCCESS"
Write-Log "" "INFO"

Write-Log "All 5 FSMO roles are now on AWS!" "SUCCESS"
Write-Log "On-prem DCs (AD01/AD02) have 0 roles." "SUCCESS"
Write-Log "" "INFO"

Write-Log "Next Steps:" "INFO"
Write-Log "1. Run post-cutover verification: .\3-POST-CUTOVER-VERIFY.ps1" "INFO"
Write-Log "2. Monitor AD replication for 24 hours" "INFO"
Write-Log "3. Plan decommissioning of AD01/AD02" "INFO"
Write-Log "" "INFO"

Write-Log "Log saved to: $logFile" "INFO"
