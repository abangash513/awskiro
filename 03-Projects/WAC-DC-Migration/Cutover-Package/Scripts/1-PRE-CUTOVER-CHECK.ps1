# WAC AD CUTOVER - PRE-CUTOVER CHECK SCRIPT
# Version: 1.0
# Purpose: Verify all prerequisites before FSMO transfer
# Run on: WACPRODDC01 (AWS DC)
# Run as: Domain Admin

param(
    [string]$Domain = "wac.net",
    [string]$LogPath = "C:\Cutover\Logs"
)

$ErrorActionPreference = "Continue"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = "$LogPath\PreCutover-$timestamp.log"

# Create log directory
New-Item -ItemType Directory -Path $LogPath -Force | Out-Null

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    Write-Host $logMessage
    Add-Content -Path $logFile -Value $logMessage
}

function Test-Prerequisite {
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
Write-Log "WAC AD CUTOVER - PRE-CUTOVER CHECK" "INFO"
Write-Log "========================================" "INFO"
Write-Log "Domain: $Domain" "INFO"
Write-Log "Run From: $env:COMPUTERNAME" "INFO"
Write-Log "Run By: $env:USERNAME" "INFO"
Write-Log "" "INFO"

$allPassed = $true
$testResults = @()

# Test 1: Verify running on WACPRODDC01
$test1 = Test-Prerequisite "Running on WACPRODDC01" {
    $env:COMPUTERNAME -eq "WACPRODDC01"
}
$testResults += @{Name="Running on WACPRODDC01"; Passed=$test1}
$allPassed = $allPassed -and $test1

# Test 2: Verify Domain Admin privileges

$test2 = Test-Prerequisite "Domain Admin privileges" {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($user)
    $adminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
    $principal.IsInRole($adminRole)
}
$testResults += @{Name="Domain Admin privileges"; Passed=$test2}
$allPassed = $allPassed -and $test2

# Test 3: Verify AD PowerShell module
$test3 = Test-Prerequisite "AD PowerShell module" {
    Import-Module ActiveDirectory -ErrorAction SilentlyContinue
    Get-Module ActiveDirectory -ErrorAction SilentlyContinue
}
$testResults += @{Name="AD PowerShell module"; Passed=$test3}
$allPassed = $allPassed -and $test3

# Test 4: Verify all DCs are online (using AD queries instead of ping)
$test4 = Test-Prerequisite "All DCs online" {
    $dcs = @("AD01", "AD02", "WACPRODDC01", "WACPRODDC02")
    $allOnline = $true
    foreach ($dc in $dcs) {
        try {
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
$testResults += @{Name="All DCs online"; Passed=$test4}
$allPassed = $allPassed -and $test4

# Test 5: Verify replication health
$test5 = Test-Prerequisite "Replication health" {
    $replSummary = repadmin /replsummary
    $failures = $replSummary | Select-String "fails/total"
    $hasFailures = $false
    foreach ($line in $failures) {
        if ($line -match "(\d+)\s*/\s*\d+") {
            if ([int]$matches[1] -gt 0) {
                $hasFailures = $true
                Write-Log "  Replication failures detected: $line" "ERROR"
            }
        }
    }
    -not $hasFailures
}
$testResults += @{Name="Replication health"; Passed=$test5}
$allPassed = $allPassed -and $test5

# Test 6: Verify current FSMO holders
$test6 = Test-Prerequisite "Current FSMO holders" {
    $fsmo = netdom query fsmo
    $ad01Count = ($fsmo | Select-String "AD01").Count
    $ad02Count = ($fsmo | Select-String "AD02").Count
    Write-Log "  AD01 holds $ad01Count roles" "INFO"
    Write-Log "  AD02 holds $ad02Count roles" "INFO"
    ($ad01Count -eq 3) -and ($ad02Count -eq 2)
}
$testResults += @{Name="Current FSMO holders"; Passed=$test6}
$allPassed = $allPassed -and $test6

# Test 7: Verify DNS resolution
$test7 = Test-Prerequisite "DNS resolution" {
    $dnsTest = Resolve-DnsName -Name $Domain -ErrorAction SilentlyContinue
    $dnsTest -ne $null
}
$testResults += @{Name="DNS resolution"; Passed=$test7}
$allPassed = $allPassed -and $test7

# Test 8: Verify time sync
$test8 = Test-Prerequisite "Time synchronization" {
    $timeStatus = w32tm /query /status
    $timeStatus -match "Leap Indicator: 0"
}
$testResults += @{Name="Time synchronization"; Passed=$test8}
$allPassed = $allPassed -and $test8

# Test 9: Verify WACPRODDC01 is Global Catalog
$test9 = Test-Prerequisite "WACPRODDC01 is Global Catalog" {
    $dc = Get-ADDomainController -Identity "WACPRODDC01"
    $dc.IsGlobalCatalog
}
$testResults += @{Name="WACPRODDC01 is Global Catalog"; Passed=$test9}
$allPassed = $allPassed -and $test9

# Test 10: Verify WACPRODDC02 is Global Catalog
$test10 = Test-Prerequisite "WACPRODDC02 is Global Catalog" {
    $dc = Get-ADDomainController -Identity "WACPRODDC02"
    $dc.IsGlobalCatalog
}
$testResults += @{Name="WACPRODDC02 is Global Catalog"; Passed=$test10}
$allPassed = $allPassed -and $test10

# Summary
Write-Log "" "INFO"
Write-Log "========================================" "INFO"
Write-Log "PRE-CUTOVER CHECK SUMMARY" "INFO"
Write-Log "========================================" "INFO"

$passCount = ($testResults | Where-Object {$_.Passed}).Count
$totalCount = $testResults.Count

Write-Log "Tests Passed: $passCount / $totalCount" "INFO"

foreach ($result in $testResults) {
    $status = if ($result.Passed) { "PASS" } else { "FAIL" }
    Write-Log "  [$status] $($result.Name)" "INFO"
}

Write-Log "" "INFO"

if ($allPassed) {
    Write-Log "========================================" "SUCCESS"
    Write-Log "GO DECISION: PROCEED WITH CUTOVER" "SUCCESS"
    Write-Log "========================================" "SUCCESS"
    Write-Log "" "INFO"
    Write-Log "Next Step: Run 2-EXECUTE-CUTOVER.ps1" "INFO"
    exit 0
} else {
    Write-Log "========================================" "ERROR"
    Write-Log "NO-GO DECISION: DO NOT PROCEED" "ERROR"
    Write-Log "========================================" "ERROR"
    Write-Log "" "INFO"
    Write-Log "Fix the failed tests before proceeding" "ERROR"
    exit 1
}
