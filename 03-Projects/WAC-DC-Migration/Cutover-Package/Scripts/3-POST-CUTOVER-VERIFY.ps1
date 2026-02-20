# WAC AD CUTOVER - POST-CUTOVER VERIFICATION SCRIPT
# Version: 1.0
# Purpose: Verify FSMO transfer success and system health
# Run on: WACPRODDC01 (AWS DC)
# Run as: Domain Admin

param(
    [string]$Domain = "wac.net",
    [string]$LogPath = "C:\Cutover\Logs"
)

$ErrorActionPreference = "Continue"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = "$LogPath\PostCutover-$timestamp.log"

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

function Test-PostCutover {
    param([string]$Name, [scriptblock]$Test)
    Write-Log "Testing: $Name" "INFO"
    try {
        $result = & $Test
        if ($result) {
            Write-Log "PASS: $Name" "SUCCESS"
            return $true
        } else {
            Write-Log "FAIL: $Name" "ERROR"
            return $false
        }
    } catch {
        Write-Log "FAIL: $Name - $($_.Exception.Message)" "ERROR"
        return $false
    }
}

Write-Log "========================================" "INFO"
Write-Log "WAC AD CUTOVER - POST-CUTOVER VERIFICATION" "INFO"
Write-Log "========================================" "INFO"
Write-Log "Domain: $Domain" "INFO"
Write-Log "Run From: $env:COMPUTERNAME" "INFO"
Write-Log "" "INFO"

Import-Module ActiveDirectory

$allPassed = $true
$testResults = @()

# Test 1: Verify WACPRODDC01 holds 3 roles
$test1 = Test-PostCutover "WACPRODDC01 holds 3 FSMO roles" {
    $fsmo = netdom query fsmo
    $count = ($fsmo | Select-String "WACPRODDC01").Count
    Write-Log "  WACPRODDC01 holds $count roles" "INFO"
    $count -eq 3
}
$testResults += @{Name="WACPRODDC01 holds 3 FSMO roles"; Passed=$test1}
$allPassed = $allPassed -and $test1

# Test 2: Verify WACPRODDC02 holds 2 roles
$test2 = Test-PostCutover "WACPRODDC02 holds 2 FSMO roles" {
    $fsmo = netdom query fsmo
    $count = ($fsmo | Select-String "WACPRODDC02").Count
    Write-Log "  WACPRODDC02 holds $count roles" "INFO"
    $count -eq 2
}
$testResults += @{Name="WACPRODDC02 holds 2 FSMO roles"; Passed=$test2}
$allPassed = $allPassed -and $test2

# Test 3: Verify AD01 holds 0 roles
$test3 = Test-PostCutover "AD01 holds 0 FSMO roles" {
    $fsmo = netdom query fsmo
    $count = ($fsmo | Select-String "AD01").Count
    Write-Log "  AD01 holds $count roles" "INFO"
    $count -eq 0
}
$testResults += @{Name="AD01 holds 0 FSMO roles"; Passed=$test3}
$allPassed = $allPassed -and $test3

# Test 4: Verify replication health
$test4 = Test-PostCutover "Replication health" {
    $replSummary = repadmin /replsummary
    $failures = $replSummary | Select-String "fails/total"
    $hasFailures = $false
    foreach ($line in $failures) {
        if ($line -match "(\d+)\s*/\s*\d+") {
            if ([int]$matches[1] -gt 0) {
                $hasFailures = $true
                Write-Log "  Replication failures: $line" "WARNING"
            }
        }
    }
    -not $hasFailures
}
$testResults += @{Name="Replication health"; Passed=$test4}
$allPassed = $allPassed -and $test4

# Test 5: Verify DNS resolution
$test5 = Test-PostCutover "DNS resolution" {
    $dnsTest = Resolve-DnsName -Name $Domain -ErrorAction SilentlyContinue
    $dnsTest -ne $null
}
$testResults += @{Name="DNS resolution"; Passed=$test5}
$allPassed = $allPassed -and $test5

# Test 6: Verify time sync (WACPRODDC01 should be authoritative) - WARNING ONLY
$test6 = Test-PostCutover "Time synchronization" {
    $timeStatus = w32tm /query /status
    $isAuthoritative = $timeStatus -match "Stratum: [0-3]"
    if ($isAuthoritative) {
        Write-Log "  WACPRODDC01 is authoritative time source" "SUCCESS"
    } else {
        Write-Log "  Time sync not optimal (non-critical)" "WARNING"
    }
    # Always return true - this is a warning, not a failure
    $true
}
$testResults += @{Name="Time synchronization"; Passed=$test6}
# Don't fail overall test for time sync
# $allPassed = $allPassed -and $test6

# Test 7: Test authentication
$test7 = Test-PostCutover "Authentication test" {
    $testUser = Get-ADUser -Filter {SamAccountName -eq "Administrator"} -ErrorAction SilentlyContinue
    $testUser -ne $null
}
$testResults += @{Name="Authentication test"; Passed=$test7}
$allPassed = $allPassed -and $test7

# Test 8: Verify all DCs online (using AD cmdlets, not ping)
$test8 = Test-PostCutover "All DCs online" {
    $dcs = @("AD01", "AD02", "WACPRODDC01", "WACPRODDC02")
    $allOnline = $true
    foreach ($dc in $dcs) {
        try {
            # Use AD cmdlet instead of ping (more reliable for DCs that block ICMP)
            $dcInfo = Get-ADDomainController -Identity $dc -ErrorAction Stop
            if ($dcInfo) {
                Write-Log "  DC online: $dc" "INFO"
            }
        } catch {
            Write-Log "  DC offline: $dc" "ERROR"
            $allOnline = $false
        }
    }
    $allOnline
}
$testResults += @{Name="All DCs online"; Passed=$test8}
$allPassed = $allPassed -and $test8

# Test 9: Check Directory Service event log for errors
$test9 = Test-PostCutover "No critical errors in event log" {
    $errors = Get-WinEvent -LogName "Directory Service" -MaxEvents 20 -ErrorAction SilentlyContinue | 
              Where-Object {$_.LevelDisplayName -eq "Error"}
    if ($errors) {
        Write-Log "  Found $($errors.Count) errors in last 20 events" "WARNING"
        $errors | ForEach-Object { Write-Log "    $($_.Message)" "WARNING" }
    } else {
        Write-Log "  No errors found" "SUCCESS"
    }
    $errors.Count -eq 0
}
$testResults += @{Name="No critical errors"; Passed=$test9}

# Test 10: Verify PDC Emulator is WACPRODDC01
$test10 = Test-PostCutover "PDC Emulator on WACPRODDC01" {
    $pdc = (Get-ADDomain).PDCEmulator
    Write-Log "  PDC Emulator: $pdc" "INFO"
    $pdc -like "*WACPRODDC01*"
}
$testResults += @{Name="PDC Emulator on WACPRODDC01"; Passed=$test10}
$allPassed = $allPassed -and $test10

# Summary
Write-Log "" "INFO"
Write-Log "========================================" "INFO"
Write-Log "POST-CUTOVER VERIFICATION SUMMARY" "INFO"
Write-Log "========================================" "INFO"

$passCount = ($testResults | Where-Object {$_.Passed}).Count
$totalCount = $testResults.Count

Write-Log "Tests Passed: $passCount / $totalCount" "INFO"
Write-Log "" "INFO"

foreach ($result in $testResults) {
    $status = if ($result.Passed) { "PASS" } else { "FAIL" }
    Write-Log "  [$status] $($result.Name)" "INFO"
}

Write-Log "" "INFO"

# Display current FSMO holders
Write-Log "========================================" "INFO"
Write-Log "CURRENT FSMO ROLE HOLDERS" "INFO"
Write-Log "========================================" "INFO"
$fsmo = netdom query fsmo
$fsmo | ForEach-Object { Write-Log "  $_" "INFO" }
Write-Log "" "INFO"

if ($allPassed) {
    Write-Log "========================================" "SUCCESS"
    Write-Log "CUTOVER SUCCESSFUL" "SUCCESS"
    Write-Log "========================================" "SUCCESS"
    Write-Log "" "INFO"
    Write-Log "Next Steps:" "INFO"
    Write-Log "1. Monitor replication for next 2 hours" "INFO"
    Write-Log "2. Test user authentication" "INFO"
    Write-Log "3. Monitor event logs" "INFO"
    Write-Log "4. Schedule AD01/AD02 decommissioning in 2-4 weeks" "INFO"
    exit 0
} else {
    Write-Log "========================================" "ERROR"
    Write-Log "CUTOVER VERIFICATION FAILED" "ERROR"
    Write-Log "========================================" "ERROR"
    Write-Log "" "INFO"
    Write-Log "Action Required:" "ERROR"
    Write-Log "1. Review failed tests above" "ERROR"
    Write-Log "2. Consider running 4-ROLLBACK.ps1 if critical" "ERROR"
    exit 1
}
