# VPN Connection Testing Script
# Run this AFTER connecting to AWS Client VPN

Write-Host "=== AWS Client VPN Connection Test ===" -ForegroundColor Green
Write-Host ""

# Test 1: Check for VPN IP
Write-Host "[Test 1] Checking VPN IP Address..." -ForegroundColor Cyan
$vpnAdapter = Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*AWS*" -or $_.InterfaceDescription -like "*VPN*" }

if ($vpnAdapter) {
    Write-Host "  VPN Adapter found: $($vpnAdapter.Name)" -ForegroundColor Green
    
    $ipConfig = Get-NetIPAddress -InterfaceIndex $vpnAdapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
    if ($ipConfig) {
        Write-Host "  VPN IP Address: $($ipConfig.IPAddress)" -ForegroundColor Green
        
        if ($ipConfig.IPAddress -like "10.100.*") {
            Write-Host "  IP is in correct range (10.100.0.0/16)" -ForegroundColor Green
        } else {
            Write-Host "  WARNING: IP not in expected range" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "  VPN adapter not found" -ForegroundColor Red
    Write-Host "  Are you connected to AWS Client VPN?" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To connect:" -ForegroundColor Yellow
    Write-Host "  1. Open AWS VPN Client" -ForegroundColor White
    Write-Host "  2. Select 'WAC Dev Admin VPN' profile" -ForegroundColor White
    Write-Host "  3. Click 'Connect'" -ForegroundColor White
    Write-Host ""
    exit 1
}
Write-Host ""

# Test 2: Ping AWS DNS
Write-Host "[Test 2] Testing connectivity to AWS DNS (10.60.0.2)..." -ForegroundColor Cyan
$dnsTest = Test-Connection -ComputerName 10.60.0.2 -Count 2 -Quiet
if ($dnsTest) {
    Write-Host "  SUCCESS: Can reach AWS DNS" -ForegroundColor Green
} else {
    Write-Host "  FAILED: Cannot reach AWS DNS" -ForegroundColor Red
    Write-Host "  Check VPN connection and authorization rules" -ForegroundColor Yellow
}
Write-Host ""

# Test 3: Ping AD-A subnet gateway
Write-Host "[Test 3] Testing connectivity to AD-A subnet (10.60.1.1)..." -ForegroundColor Cyan
$adATest = Test-Connection -ComputerName 10.60.1.1 -Count 2 -Quiet
if ($adATest) {
    Write-Host "  SUCCESS: Can reach AD-A subnet" -ForegroundColor Green
} else {
    Write-Host "  FAILED: Cannot reach AD-A subnet" -ForegroundColor Red
}
Write-Host ""

# Test 4: Ping AD-B subnet gateway
Write-Host "[Test 4] Testing connectivity to AD-B subnet (10.60.2.1)..." -ForegroundColor Cyan
$adBTest = Test-Connection -ComputerName 10.60.2.1 -Count 2 -Quiet
if ($adBTest) {
    Write-Host "  SUCCESS: Can reach AD-B subnet" -ForegroundColor Green
} else {
    Write-Host "  FAILED: Cannot reach AD-B subnet" -ForegroundColor Red
}
Write-Host ""

# Test 5: Check for Domain Controllers
Write-Host "[Test 5] Checking for Domain Controllers..." -ForegroundColor Cyan
Write-Host "  Note: This will only work if DCs are deployed" -ForegroundColor Gray

$dc1Test = Test-Connection -ComputerName 10.60.1.10 -Count 1 -Quiet -ErrorAction SilentlyContinue
if ($dc1Test) {
    Write-Host "  DC1 (10.60.1.10): ONLINE" -ForegroundColor Green
} else {
    Write-Host "  DC1 (10.60.1.10): Not responding (may not be deployed yet)" -ForegroundColor Yellow
}

$dc2Test = Test-Connection -ComputerName 10.60.2.10 -Count 1 -Quiet -ErrorAction SilentlyContinue
if ($dc2Test) {
    Write-Host "  DC2 (10.60.2.10): ONLINE" -ForegroundColor Green
} else {
    Write-Host "  DC2 (10.60.2.10): Not responding (may not be deployed yet)" -ForegroundColor Yellow
}
Write-Host ""

# Test 6: DNS Resolution
Write-Host "[Test 6] Testing DNS resolution..." -ForegroundColor Cyan
try {
    $dnsResult = Resolve-DnsName -Name "wac.local" -Server 10.60.0.2 -ErrorAction Stop
    Write-Host "  SUCCESS: DNS resolution working" -ForegroundColor Green
    Write-Host "  Domain: wac.local" -ForegroundColor Gray
} catch {
    Write-Host "  DNS resolution failed (domain may not be configured yet)" -ForegroundColor Yellow
}
Write-Host ""

# Summary
Write-Host "=== Test Summary ===" -ForegroundColor Green
Write-Host ""

$allTests = @(
    @{Name="VPN Connection"; Result=$vpnAdapter -ne $null},
    @{Name="AWS DNS"; Result=$dnsTest},
    @{Name="AD-A Subnet"; Result=$adATest},
    @{Name="AD-B Subnet"; Result=$adBTest}
)

$passedTests = ($allTests | Where-Object { $_.Result }).Count
$totalTests = $allTests.Count

Write-Host "Tests Passed: $passedTests / $totalTests" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Yellow" })
Write-Host ""

if ($passedTests -eq $totalTests) {
    Write-Host "VPN is working correctly!" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now:" -ForegroundColor Cyan
    Write-Host "  - RDP to Domain Controllers (when deployed)" -ForegroundColor White
    Write-Host "  - Access resources in Dev VPC (10.60.0.0/16)" -ForegroundColor White
    Write-Host "  - Use AWS services via VPN" -ForegroundColor White
} else {
    Write-Host "Some tests failed. Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  1. Verify VPN is connected in AWS VPN Client" -ForegroundColor White
    Write-Host "  2. Check VPN endpoint status in AWS Console" -ForegroundColor White
    Write-Host "  3. Verify authorization rules are configured" -ForegroundColor White
    Write-Host "  4. Check security groups allow traffic from 10.100.0.0/16" -ForegroundColor White
}
Write-Host ""

# RDP Instructions
if ($dc1Test -or $dc2Test) {
    Write-Host "=== RDP to Domain Controllers ===" -ForegroundColor Green
    Write-Host ""
    if ($dc1Test) {
        Write-Host "Connect to DC1:" -ForegroundColor Cyan
        Write-Host "  mstsc /v:10.60.1.10" -ForegroundColor White
        Write-Host ""
    }
    if ($dc2Test) {
        Write-Host "Connect to DC2:" -ForegroundColor Cyan
        Write-Host "  mstsc /v:10.60.2.10" -ForegroundColor White
        Write-Host ""
    }
}
