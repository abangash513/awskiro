# WAC DC02 Connectivity Diagnostic Script
# Run on WACPRODDC01 to diagnose connectivity issues with WACPRODDC02

$DC02_IP = "10.70.11.10"
$DC02_FQDN = "WACPRODDC02.wac.net"
$DC02_SHORT = "WACPRODDC02"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "WACPRODDC02 Connectivity Diagnostics" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Test 1: DNS Resolution
Write-Host "[1] Testing DNS Resolution..." -ForegroundColor Yellow
Write-Host "  Short name (WACPRODDC02):" -NoNewline
try {
    $shortResolve = Resolve-DnsName -Name $DC02_SHORT -ErrorAction Stop
    Write-Host " OK - $($shortResolve.IPAddress)" -ForegroundColor Green
} catch {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "  FQDN (WACPRODDC02.wac.net):" -NoNewline
try {
    $fqdnResolve = Resolve-DnsName -Name $DC02_FQDN -ErrorAction Stop
    Write-Host " OK - $($fqdnResolve.IPAddress)" -ForegroundColor Green
} catch {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Network Connectivity
Write-Host "`n[2] Testing Network Connectivity..." -ForegroundColor Yellow
$ports = @(
    @{Port=389; Name="LDAP"},
    @{Port=636; Name="LDAPS"},
    @{Port=3268; Name="Global Catalog"},
    @{Port=3269; Name="Global Catalog SSL"},
    @{Port=9389; Name="ADWS"},
    @{Port=135; Name="RPC"},
    @{Port=445; Name="SMB"},
    @{Port=53; Name="DNS"},
    @{Port=88; Name="Kerberos"}
)

foreach ($portTest in $ports) {
    Write-Host "  Port $($portTest.Port) ($($portTest.Name)):" -NoNewline
    $result = Test-NetConnection -ComputerName $DC02_IP -Port $portTest.Port -WarningAction SilentlyContinue
    if ($result.TcpTestSucceeded) {
        Write-Host " OK" -ForegroundColor Green
    } else {
        Write-Host " FAILED" -ForegroundColor Red
    }
}

# Test 3: ADWS Service Status
Write-Host "`n[3] Testing ADWS Service on WACPRODDC02..." -ForegroundColor Yellow
try {
    $adwsService = Get-Service -Name ADWS -ComputerName $DC02_FQDN -ErrorAction Stop
    Write-Host "  Service Status: $($adwsService.Status)" -ForegroundColor $(if ($adwsService.Status -eq "Running") {"Green"} else {"Red"})
    Write-Host "  Startup Type: $($adwsService.StartType)" -ForegroundColor $(if ($adwsService.StartType -eq "Automatic") {"Green"} else {"Yellow"})
} catch {
    Write-Host "  FAILED to query service" -ForegroundColor Red
    Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: AD Connectivity
Write-Host "`n[4] Testing Active Directory Connectivity..." -ForegroundColor Yellow
Write-Host "  Get-ADDomainController:" -NoNewline
try {
    $dc = Get-ADDomainController -Identity $DC02_FQDN -ErrorAction Stop
    Write-Host " OK" -ForegroundColor Green
    Write-Host "    Hostname: $($dc.HostName)" -ForegroundColor Gray
    Write-Host "    IPv4: $($dc.IPv4Address)" -ForegroundColor Gray
    Write-Host "    IsGlobalCatalog: $($dc.IsGlobalCatalog)" -ForegroundColor Gray
} catch {
    Write-Host " FAILED" -ForegroundColor Red
    Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Current FSMO Roles
Write-Host "`n[5] Current FSMO Role Distribution..." -ForegroundColor Yellow
$fsmo = netdom query fsmo
$dc01Count = ($fsmo | Select-String "WACPRODDC01").Count
$dc02Count = ($fsmo | Select-String "WACPRODDC02").Count
Write-Host "  WACPRODDC01: $dc01Count roles" -ForegroundColor $(if ($dc01Count -eq 5) {"Yellow"} else {"Green"})
Write-Host "  WACPRODDC02: $dc02Count roles" -ForegroundColor $(if ($dc02Count -eq 0) {"Red"} else {"Green"})

# Test 6: Replication Status
Write-Host "`n[6] Replication Status..." -ForegroundColor Yellow
try {
    $replPartner = Get-ADReplicationPartnerMetadata -Target $DC02_FQDN -ErrorAction Stop
    Write-Host "  Replication partners: $($replPartner.Count)" -ForegroundColor Green
    $lastRepl = $replPartner | Sort-Object LastReplicationSuccess | Select-Object -First 1
    Write-Host "  Last successful replication: $($lastRepl.LastReplicationSuccess)" -ForegroundColor Gray
} catch {
    Write-Host "  FAILED to query replication" -ForegroundColor Red
    Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Summary and Recommendations
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Summary and Recommendations" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Issues Found:" -ForegroundColor Yellow
$issues = @()

# Check DNS
try {
    $null = Resolve-DnsName -Name $DC02_SHORT -ErrorAction Stop
} catch {
    $issues += "DNS short name resolution failed"
    Write-Host "  [!] DNS short name 'WACPRODDC02' doesn't resolve" -ForegroundColor Red
}

# Check ADWS port
$adwsTest = Test-NetConnection -ComputerName $DC02_IP -Port 9389 -WarningAction SilentlyContinue
if (-not $adwsTest.TcpTestSucceeded) {
    $issues += "ADWS port 9389 not accessible"
    Write-Host "  [!] ADWS port 9389 is not accessible" -ForegroundColor Red
}

# Check role distribution
if ($dc01Count -eq 5 -and $dc02Count -eq 0) {
    $issues += "All FSMO roles on DC01"
    Write-Host "  [!] All 5 FSMO roles are on WACPRODDC01 (should be split 3/2)" -ForegroundColor Red
}

if ($issues.Count -eq 0) {
    Write-Host "  No issues found! Ready to transfer roles." -ForegroundColor Green
} else {
    Write-Host "`nRecommended Actions:" -ForegroundColor Yellow
    Write-Host "  1. RDP to WACPRODDC02 and run:" -ForegroundColor White
    Write-Host "     Start-Service ADWS" -ForegroundColor Gray
    Write-Host "     Set-Service ADWS -StartupType Automatic" -ForegroundColor Gray
    Write-Host "     Enable-NetFirewallRule -DisplayName 'Active Directory Web Services (TCP-In)'" -ForegroundColor Gray
    Write-Host "`n  2. Check AWS Security Group for WACPRODDC02:" -ForegroundColor White
    Write-Host "     Ensure port 9389 is allowed from WACPRODDC01 (10.70.11.11)" -ForegroundColor Gray
    Write-Host "`n  3. Fix DNS resolution on WACPRODDC01:" -ForegroundColor White
    Write-Host "     Add-DnsServerResourceRecordA -ZoneName 'wac.net' -Name 'WACPRODDC02' -IPv4Address '10.70.11.10'" -ForegroundColor Gray
    Write-Host "     Clear-DnsClientCache" -ForegroundColor Gray
    Write-Host "`n  4. After fixes, transfer roles:" -ForegroundColor White
    Write-Host "     Move-ADDirectoryServerOperationMasterRole -Identity WACPRODDC02.wac.net -OperationMasterRole RIDMaster,InfrastructureMaster -Force" -ForegroundColor Gray
}

Write-Host "`n========================================`n" -ForegroundColor Cyan
