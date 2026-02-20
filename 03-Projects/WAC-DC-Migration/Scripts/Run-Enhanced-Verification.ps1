<#
.SYNOPSIS
    Enhanced WAC Domain Controller Verification Script

.DESCRIPTION
    Comprehensive verification of AD health including:
    - Domain Controller discovery and status
    - DNS resolution and SRV records
    - Secure channel verification
    - Time synchronization
    - Replication health
    - FSMO role locations
    - Event log errors
    - Network connectivity

.PARAMETER Domain
    The domain to verify (default: wac.net)

.NOTES
    Author: Generated for WAC DC Migration
    Date: 2026-02-07
    Requirements: Run as Domain Admin on a Domain Controller
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Domain = "wac.net"
)

$ErrorActionPreference = "Continue"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logDir = "C:\Setup\Logs\Verification-$timestamp"

# Create log directory
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$summaryLog = "$logDir\VERIFICATION-SUMMARY.txt"
$jsonSummary = "$logDir\verification-summary.json"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    Write-Host $logMessage
    Add-Content -Path $summaryLog -Value $logMessage
}

function Run-Test {
    param(
        [string]$TestName,
        [scriptblock]$TestScript,
        [string]$OutputFile
    )
    
    Write-Log "Running: $TestName" "INFO"
    try {
        $output = & $TestScript 2>&1
        $output | Out-File -FilePath "$logDir\$OutputFile" -Encoding UTF8
        Write-Log "✅ $TestName - Completed" "INFO"
        return @{ Status = "Success"; Output = $output }
    } catch {
        Write-Log "❌ $TestName - Failed: $_" "ERROR"
        return @{ Status = "Failed"; Error = $_.Exception.Message }
    }
}

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Write-Log "========================================" "INFO"
Write-Log "WAC DOMAIN CONTROLLER VERIFICATION" "INFO"
Write-Log "========================================" "INFO"
Write-Log "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" "INFO"
Write-Log "Computer: $env:COMPUTERNAME" "INFO"
Write-Log "Domain: $Domain" "INFO"
Write-Log "User: $env:USERNAME" "INFO"
Write-Log "Admin Rights: $isAdmin" "INFO"
Write-Log "Log Directory: $logDir" "INFO"
Write-Log "" "INFO"

if (-not $isAdmin) {
    Write-Log "WARNING: Not running as Administrator. Some tests may fail." "WARN"
    Write-Host "`n⚠️  WARNING: Run as Administrator for full verification!" -ForegroundColor Yellow
    Write-Log "" "INFO"
}

$results = @{}

# Test 1: DC List
$results.DCList = Run-Test -TestName "Domain Controller List" `
    -TestScript { nltest /dclist:$Domain } `
    -OutputFile "01-dclist.txt"

# Test 2: DC Locator
$results.DCLocator = Run-Test -TestName "DC Locator (dsgetdc)" `
    -TestScript { nltest /dsgetdc:$Domain } `
    -OutputFile "02-dsgetdc.txt"

# Test 3: Secure Channel Verify
$results.SecureChannel = Run-Test -TestName "Secure Channel Verification" `
    -TestScript { nltest /sc_verify:$Domain } `
    -OutputFile "03-sc_verify.txt"

# Test 4: DNS Resolution - Domain
$results.DNSDomain = Run-Test -TestName "DNS Resolution - Domain" `
    -TestScript { Resolve-DnsName -Name $Domain -Type A } `
    -OutputFile "04-dns_domain.txt"

# Test 5: DNS Resolution - LDAP SRV
$results.DNSLDAP = Run-Test -TestName "DNS Resolution - LDAP SRV Records" `
    -TestScript { Resolve-DnsName -Name "_ldap._tcp.dc._msdcs.$Domain" -Type SRV } `
    -OutputFile "05-dns_ldap_srv.txt"

# Test 6: DNS Resolution - Kerberos SRV
$results.DNSKerberos = Run-Test -TestName "DNS Resolution - Kerberos SRV Records" `
    -TestScript { Resolve-DnsName -Name "_kerberos._tcp.dc._msdcs.$Domain" -Type SRV } `
    -OutputFile "06-dns_kerberos_srv.txt"

# Test 7: Time Service Status
$results.TimeStatus = Run-Test -TestName "Time Service Status" `
    -TestScript { w32tm /query /status /verbose } `
    -OutputFile "07-time_status.txt"

# Test 8: Time Source
$results.TimeSource = Run-Test -TestName "Time Source" `
    -TestScript { w32tm /query /source } `
    -OutputFile "08-time_source.txt"

# Test 9: Time Configuration
$results.TimeConfig = Run-Test -TestName "Time Configuration" `
    -TestScript { w32tm /query /configuration } `
    -OutputFile "09-time_config.txt"

# Test 10: Replication Summary
$results.ReplSummary = Run-Test -TestName "Replication Summary" `
    -TestScript { repadmin /replsummary } `
    -OutputFile "10-replication_summary.txt"

# Test 11: Replication Status (detailed)
$results.ReplStatus = Run-Test -TestName "Replication Status (Detailed)" `
    -TestScript { repadmin /showrepl } `
    -OutputFile "11-replication_detailed.txt"

# Test 12: FSMO Roles
$results.FSMO = Run-Test -TestName "FSMO Role Locations" `
    -TestScript { netdom query fsmo } `
    -OutputFile "12-fsmo_roles.txt"

# Test 13: AD Domain Controllers
$results.ADDCs = Run-Test -TestName "AD Domain Controllers (PowerShell)" `
    -TestScript { Get-ADDomainController -Filter * | Select-Object Name, IPv4Address, Site, OperatingSystem, IsGlobalCatalog | Format-Table -AutoSize } `
    -OutputFile "13-ad_domain_controllers.txt"

# Test 14: Directory Service Event Log
$results.DSEventLog = Run-Test -TestName "Directory Service Event Log (Errors/Warnings)" `
    -TestScript { Get-EventLog -LogName "Directory Service" -EntryType Error,Warning -Newest 50 -ErrorAction SilentlyContinue | Format-List } `
    -OutputFile "14-ds_event_log.txt"

# Test 15: DNS Server Event Log
$results.DNSEventLog = Run-Test -TestName "DNS Server Event Log (Errors/Warnings)" `
    -TestScript { Get-EventLog -LogName "DNS Server" -EntryType Error,Warning -Newest 50 -ErrorAction SilentlyContinue | Format-List } `
    -OutputFile "15-dns_event_log.txt"

# Test 16: System Event Log
$results.SystemEventLog = Run-Test -TestName "System Event Log (Errors)" `
    -TestScript { Get-EventLog -LogName "System" -EntryType Error -Newest 50 -ErrorAction SilentlyContinue | Format-List } `
    -OutputFile "16-system_event_log.txt"

# Test 17: DCDiag - Connectivity
$results.DCDiagConn = Run-Test -TestName "DCDiag - Connectivity Test" `
    -TestScript { dcdiag /test:connectivity /v } `
    -OutputFile "17-dcdiag_connectivity.txt"

# Test 18: DCDiag - DNS
$results.DCDiagDNS = Run-Test -TestName "DCDiag - DNS Test" `
    -TestScript { dcdiag /test:dns /v } `
    -OutputFile "18-dcdiag_dns.txt"

# Test 19: DCDiag - Replication
$results.DCDiagRepl = Run-Test -TestName "DCDiag - Replication Test" `
    -TestScript { dcdiag /test:replications /v } `
    -OutputFile "19-dcdiag_replication.txt"

# Test 20: Network Connectivity to PDC
Write-Log "Running: Network Connectivity to PDC" "INFO"
try {
    $pdcEmulator = (Get-ADDomain).PDCEmulator
    $pdcIP = (Resolve-DnsName $pdcEmulator -Type A).IPAddress
    $pingResult = Test-Connection -ComputerName $pdcIP -Count 4 -ErrorAction Stop
    $pingResult | Out-File -FilePath "$logDir\20-network_pdc.txt" -Encoding UTF8
    Write-Log "✅ Network Connectivity to PDC - Completed" "INFO"
    $results.NetworkPDC = @{ Status = "Success"; PDC = $pdcEmulator; IP = $pdcIP }
} catch {
    Write-Log "❌ Network Connectivity to PDC - Failed: $_" "ERROR"
    $results.NetworkPDC = @{ Status = "Failed"; Error = $_.Exception.Message }
}

Write-Log "" "INFO"
Write-Log "========================================" "INFO"
Write-Log "VERIFICATION SUMMARY" "INFO"
Write-Log "========================================" "INFO"

# Count successes and failures
$successCount = ($results.Values | Where-Object { $_.Status -eq "Success" }).Count
$failCount = ($results.Values | Where-Object { $_.Status -eq "Failed" }).Count
$totalTests = $results.Count

Write-Log "Total Tests: $totalTests" "INFO"
Write-Log "Passed: $successCount" "INFO"
Write-Log "Failed: $failCount" "INFO"
Write-Log "" "INFO"

# Identify critical failures
$criticalTests = @("SecureChannel", "TimeStatus", "ReplSummary", "FSMO")
$criticalFailures = $criticalTests | Where-Object { $results[$_].Status -eq "Failed" }

if ($criticalFailures.Count -gt 0) {
    Write-Log "⚠️  CRITICAL FAILURES DETECTED:" "ERROR"
    $criticalFailures | ForEach-Object {
        Write-Log "   - $_" "ERROR"
    }
    Write-Host "`n❌ CRITICAL ISSUES FOUND - Review logs in $logDir" -ForegroundColor Red
} elseif ($failCount -gt 0) {
    Write-Log "⚠️  Some non-critical tests failed. Review logs for details." "WARN"
    Write-Host "`n⚠️  Some tests failed - Review logs in $logDir" -ForegroundColor Yellow
} else {
    Write-Log "✅ ALL TESTS PASSED!" "INFO"
    Write-Host "`n✅ All verification tests passed!" -ForegroundColor Green
}

Write-Log "" "INFO"
Write-Log "========================================" "INFO"
Write-Log "All results saved to: $logDir" "INFO"
Write-Log "Summary log: $summaryLog" "INFO"
Write-Log "========================================" "INFO"

# Export JSON summary
$jsonOutput = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Computer = $env:COMPUTERNAME
    Domain = $Domain
    User = $env:USERNAME
    AdminRights = $isAdmin
    TotalTests = $totalTests
    Passed = $successCount
    Failed = $failCount
    CriticalFailures = $criticalFailures
    Results = $results
} | ConvertTo-Json -Depth 10

$jsonOutput | Out-File -FilePath $jsonSummary -Encoding UTF8
Write-Log "JSON summary: $jsonSummary" "INFO"

Write-Host "`nLog directory: $logDir" -ForegroundColor Cyan
Write-Host "Copy this folder to your local machine for analysis." -ForegroundColor Cyan
