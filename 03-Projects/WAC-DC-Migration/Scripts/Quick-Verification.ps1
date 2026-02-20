<#
.SYNOPSIS
    Quick WAC DC Verification - Essential Tests Only

.DESCRIPTION
    Simplified verification with better error handling
#>

param([string]$Domain = "wac.net")

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logDir = "C:\Setup\Logs\QuickVerify-$timestamp"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "WAC DC Quick Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor White
Write-Host "Domain: $Domain" -ForegroundColor White
Write-Host "User: $env:USERNAME" -ForegroundColor White
Write-Host "Log Dir: $logDir" -ForegroundColor White
Write-Host ""

$results = @()

function Test-Item {
    param([string]$Name, [scriptblock]$Test, [string]$File)
    
    Write-Host "Testing: $Name..." -ForegroundColor Yellow -NoNewline
    try {
        $output = & $Test 2>&1
        $output | Out-File "$logDir\$File" -Encoding UTF8
        Write-Host " [OK]" -ForegroundColor Green
        return @{Name=$Name; Status="PASS"; File=$File}
    } catch {
        Write-Host " [FAIL]" -ForegroundColor Red
        $_.Exception.Message | Out-File "$logDir\$File" -Encoding UTF8
        return @{Name=$Name; Status="FAIL"; File=$File; Error=$_.Exception.Message}
    }
}

# Test 1: DC List
$results += Test-Item -Name "DC List" -File "01-dclist.txt" -Test {
    nltest /dclist:$Domain
}

# Test 2: DC Locator
$results += Test-Item -Name "DC Locator" -File "02-dsgetdc.txt" -Test {
    nltest /dsgetdc:$Domain
}

# Test 3: DNS - Domain
$results += Test-Item -Name "DNS Domain Resolution" -File "03-dns-domain.txt" -Test {
    Resolve-DnsName -Name $Domain -Type A
}

# Test 4: DNS - LDAP SRV
$results += Test-Item -Name "DNS LDAP SRV Records" -File "04-dns-ldap-srv.txt" -Test {
    Resolve-DnsName -Name "_ldap._tcp.dc._msdcs.$Domain" -Type SRV
}

# Test 5: Time Status
$results += Test-Item -Name "Time Service Status" -File "05-time-status.txt" -Test {
    w32tm /query /status
}

# Test 6: Time Source
$results += Test-Item -Name "Time Source" -File "06-time-source.txt" -Test {
    w32tm /query /source
}

# Test 7: Replication Summary
$results += Test-Item -Name "Replication Summary" -File "07-replication.txt" -Test {
    repadmin /replsummary
}

# Test 8: FSMO Roles
$results += Test-Item -Name "FSMO Roles" -File "08-fsmo.txt" -Test {
    netdom query fsmo
}

# Test 9: AD DCs
$results += Test-Item -Name "AD Domain Controllers" -File "09-ad-dcs.txt" -Test {
    Get-ADDomainController -Filter * | Select-Object Name, IPv4Address, Site, OperatingSystem | Format-Table -AutoSize
}

# Test 10: Event Logs - Directory Service
$results += Test-Item -Name "Directory Service Errors" -File "10-ds-errors.txt" -Test {
    Get-EventLog -LogName "Directory Service" -EntryType Error -Newest 20 -ErrorAction SilentlyContinue | Format-List
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$passed = ($results | Where-Object {$_.Status -eq "PASS"}).Count
$failed = ($results | Where-Object {$_.Status -eq "FAIL"}).Count

Write-Host "Total Tests: $($results.Count)" -ForegroundColor White
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor $(if($failed -gt 0){"Red"}else{"Green"})
Write-Host ""

if ($failed -gt 0) {
    Write-Host "Failed Tests:" -ForegroundColor Red
    $results | Where-Object {$_.Status -eq "FAIL"} | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor Red
        if ($_.Error) {
            Write-Host "    Error: $($_.Error)" -ForegroundColor Yellow
        }
    }
    Write-Host ""
}

# Check critical issues
$timeTest = $results | Where-Object {$_.Name -like "*Time*"}
$replTest = $results | Where-Object {$_.Name -like "*Replication*"}

if ($timeTest.Status -contains "FAIL") {
    Write-Host "[CRITICAL] Time synchronization issue detected!" -ForegroundColor Red
    Write-Host "  Run: .\Fix-TimeSync-Simple.ps1" -ForegroundColor Yellow
    Write-Host ""
}

if ($replTest.Status -contains "FAIL") {
    Write-Host "[CRITICAL] Replication issue detected!" -ForegroundColor Red
    Write-Host "  Check: repadmin /showrepl" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "All logs saved to:" -ForegroundColor White
Write-Host $logDir -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Export summary
$results | Export-Csv "$logDir\summary.csv" -NoTypeInformation
$results | ConvertTo-Json | Out-File "$logDir\summary.json" -Encoding UTF8

Write-Host "Copy this folder to your local machine:" -ForegroundColor Yellow
Write-Host "  copy `"$logDir`" -Recurse -Destination `"\\tsclient\C\Users\YourUsername\Desktop\`"" -ForegroundColor White
Write-Host ""

pause
