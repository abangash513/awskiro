# COMPREHENSIVE DC01 TO DC02 CONNECTIVITY DIAGNOSTIC AND FIX SCRIPT
# Run this script ON WACPRODDC01
# This will diagnose all connectivity issues between DC01 and DC02

param(
    [string]$DC01_IP = "10.70.10.10",
    [string]$DC02_IP = "10.70.11.10",
    [string]$LogPath = "C:\Cutover\Logs",
    [switch]$AutoFix = $false
)

$ErrorActionPreference = "Continue"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = "$LogPath\Connectivity-Diagnostic-$timestamp.log"

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
Write-Log "DC01 TO DC02 CONNECTIVITY DIAGNOSTIC" "INFO"
Write-Log "========================================" "INFO"
Write-Log "Source: WACPRODDC01 ($DC01_IP)" "INFO"
Write-Log "Target: WACPRODDC02 ($DC02_IP)" "INFO"
Write-Log "Auto-Fix: $AutoFix" "INFO"
Write-Log "" "INFO"

$issues = @()
$fixes = @()

# TEST 1: Basic Network Connectivity
Write-Log "========================================" "TEST"
Write-Log "TEST 1: Basic Network Connectivity" "TEST"
Write-Log "========================================" "TEST"

Write-Log "Testing ICMP (Ping)..." "INFO"
$pingTest = Test-Connection -ComputerName $DC02_IP -Count 2 -Quiet
if ($pingTest) {
    Write-Log "  ICMP: SUCCESS" "SUCCESS"
} else {
    Write-Log "  ICMP: FAILED (This is expected if ICMP is blocked)" "WARNING"
    $issues += "ICMP blocked (not critical)"
}

Write-Log "" "INFO"

# TEST 2: DNS Resolution
Write-Log "========================================" "TEST"
Write-Log "TEST 2: DNS Resolution" "TEST"
Write-Log "========================================" "TEST"

Write-Log "Testing DNS resolution for WACPRODDC02..." "INFO"
try {
    $dnsShort = Resolve-DnsName "WACPRODDC02" -ErrorAction Stop
    Write-Log "  Short name (WACPRODDC02): SUCCESS - $($dnsShort.IPAddress)" "SUCCESS"
} catch {
    Write-Log "  Short name (WACPRODDC02): FAILED" "ERROR"
    $issues += "DNS short name resolution failed"
}

try {
    $dnsFqdn = Resolve-DnsName "WACPRODDC02.wac.net" -ErrorAction Stop
    Write-Log "  FQDN (WACPRODDC02.wac.net): SUCCESS - $($dnsFqdn.IPAddress)" "SUCCESS"
} catch {
    Write-Log "  FQDN (WACPRODDC02.wac.net): FAILED" "ERROR"
    $issues += "DNS FQDN resolution failed"
}

Write-Log "" "INFO"

# TEST 3: Critical AD Ports
Write-Log "========================================" "TEST"
Write-Log "TEST 3: Active Directory Ports" "TEST"
Write-Log "========================================" "TEST"

$adPorts = @{
    "53" = "DNS"
    "88" = "Kerberos"
    "135" = "RPC Endpoint Mapper"
    "389" = "LDAP"
    "445" = "SMB"
    "464" = "Kerberos Password Change"
    "636" = "LDAPS"
    "3268" = "Global Catalog"
    "3269" = "Global Catalog SSL"
    "9389" = "ADWS (Active Directory Web Services)"
    "3389" = "RDP"
    "5985" = "WinRM HTTP"
}

$portResults = @{}
foreach ($port in $adPorts.Keys) {
    Write-Log "Testing port $port ($($adPorts[$port]))..." "INFO"
    $test = Test-NetConnection -ComputerName $DC02_IP -Port $port -WarningAction SilentlyContinue
    $portResults[$port] = $test.TcpTestSucceeded
    
    if ($test.TcpTestSucceeded) {
        Write-Log "  Port $port ($($adPorts[$port])): SUCCESS" "SUCCESS"
    } else {
        Write-Log "  Port $port ($($adPorts[$port])): FAILED" "ERROR"
        $issues += "Port $port ($($adPorts[$port])) blocked"
    }
}

Write-Log "" "INFO"

# TEST 4: AD Cmdlet Connectivity
Write-Log "========================================" "TEST"
Write-Log "TEST 4: Active Directory Cmdlet Access" "TEST"
Write-Log "========================================" "TEST"

Write-Log "Testing Get-ADDomainController..." "INFO"
try {
    $dc = Get-ADDomainController -Identity WACPRODDC02 -ErrorAction Stop
    Write-Log "  AD Cmdlet Access: SUCCESS" "SUCCESS"
    Write-Log "    Name: $($dc.Name)" "INFO"
    Write-Log "    IP: $($dc.IPv4Address)" "INFO"
    Write-Log "    Site: $($dc.Site)" "INFO"
    Write-Log "    IsGlobalCatalog: $($dc.IsGlobalCatalog)" "INFO"
} catch {
    Write-Log "  AD Cmdlet Access: FAILED - $($_.Exception.Message)" "ERROR"
    $issues += "Cannot access DC02 via AD cmdlets"
}

Write-Log "" "INFO"

# TEST 5: ADWS Service Status (Remote)
Write-Log "========================================" "TEST"
Write-Log "TEST 5: ADWS Service Status on DC02" "TEST"
Write-Log "========================================" "TEST"

Write-Log "Checking ADWS service on WACPRODDC02..." "INFO"
try {
    $adwsService = Get-Service -Name ADWS -ComputerName WACPRODDC02 -ErrorAction Stop
    Write-Log "  ADWS Service Found: SUCCESS" "SUCCESS"
    Write-Log "    Status: $($adwsService.Status)" "INFO"
    Write-Log "    StartType: $($adwsService.StartType)" "INFO"
    
    if ($adwsService.Status -ne "Running") {
        Write-Log "  ADWS is NOT running!" "ERROR"
        $issues += "ADWS service not running on DC02"
        $fixes += "Start ADWS service on DC02"
    }
} catch {
    Write-Log "  ADWS Service Check: FAILED - $($_.Exception.Message)" "ERROR"
    $issues += "Cannot check ADWS service on DC02 (access denied or service doesn't exist)"
    $fixes += "Install/start ADWS on DC02 or check Windows Firewall"
}

Write-Log "" "INFO"

# TEST 6: Windows Firewall Status (Local)
Write-Log "========================================" "TEST"
Write-Log "TEST 6: Local Windows Firewall (DC01)" "TEST"
Write-Log "========================================" "TEST"

Write-Log "Checking Windows Firewall profiles..." "INFO"
$firewallProfiles = Get-NetFirewallProfile
foreach ($profile in $firewallProfiles) {
    Write-Log "  $($profile.Name): $($profile.Enabled)" "INFO"
}

Write-Log "" "INFO"

# TEST 7: Network Interface Information
Write-Log "========================================" "TEST"
Write-Log "TEST 7: Network Configuration" "TEST"
Write-Log "========================================" "TEST"

Write-Log "Local network interfaces:" "INFO"
$interfaces = Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" -and $_.IPAddress -notlike "127.*" }
foreach ($int in $interfaces) {
    Write-Log "  Interface: $($int.InterfaceAlias)" "INFO"
    Write-Log "    IP: $($int.IPAddress)" "INFO"
    Write-Log "    Prefix: $($int.PrefixLength)" "INFO"
}

Write-Log "" "INFO"

# TEST 8: Route to DC02
Write-Log "========================================" "TEST"
Write-Log "TEST 8: Routing to DC02" "TEST"
Write-Log "========================================" "TEST"

Write-Log "Finding route to $DC02_IP..." "INFO"
$route = Find-NetRoute -RemoteIPAddress $DC02_IP
Write-Log "  Next Hop: $($route.NextHop)" "INFO"
Write-Log "  Interface: $($route.InterfaceAlias)" "INFO"
Write-Log "  Route Metric: $($route.RouteMetric)" "INFO"

Write-Log "" "INFO"

# SUMMARY
Write-Log "========================================" "INFO"
Write-Log "DIAGNOSTIC SUMMARY" "INFO"
Write-Log "========================================" "INFO"

if ($issues.Count -eq 0) {
    Write-Log "No issues found! All tests passed." "SUCCESS"
} else {
    Write-Log "Found $($issues.Count) issue(s):" "ERROR"
    foreach ($issue in $issues) {
        Write-Log "  - $issue" "ERROR"
    }
}

Write-Log "" "INFO"

# Port Summary
Write-Log "Port Test Summary:" "INFO"
$criticalPorts = @("389", "445", "3268", "9389")
$criticalFailed = $false
foreach ($port in $criticalPorts) {
    if (-not $portResults[$port]) {
        Write-Log "  CRITICAL: Port $port ($($adPorts[$port])) is blocked!" "ERROR"
        $criticalFailed = $true
    }
}

if (-not $criticalFailed) {
    Write-Log "  All critical AD ports are accessible" "SUCCESS"
}

Write-Log "" "INFO"

# RECOMMENDATIONS
Write-Log "========================================" "INFO"
Write-Log "RECOMMENDATIONS" "INFO"
Write-Log "========================================" "INFO"

if ($portResults["9389"] -eq $false) {
    Write-Log "1. Port 9389 (ADWS) is blocked - This is the main issue!" "ERROR"
    Write-Log "   Possible causes:" "INFO"
    Write-Log "   a) AWS Security Group not allowing port 9389" "INFO"
    Write-Log "   b) ADWS service not running on DC02" "INFO"
    Write-Log "   c) Windows Firewall on DC02 blocking port 9389" "INFO"
    Write-Log "" "INFO"
    Write-Log "   Recommended fixes:" "INFO"
    Write-Log "   - Check AWS Security Group for WACPRODDC02" "INFO"
    Write-Log "   - Add inbound rule: TCP port 9389 from 10.70.0.0/16" "INFO"
    Write-Log "   - Log into DC02 and run: Start-Service ADWS" "INFO"
}

if ($portResults["3389"] -eq $false) {
    Write-Log "2. Port 3389 (RDP) is blocked - Cannot RDP to DC02" "ERROR"
    Write-Log "   - Use AWS Systems Manager Session Manager instead" "INFO"
    Write-Log "   - Or fix AWS Security Group to allow RDP" "INFO"
}

if ($portResults["5985"] -eq $false) {
    Write-Log "3. Port 5985 (WinRM) is blocked - Cannot use remote PowerShell" "WARNING"
    Write-Log "   - This limits remote management options" "INFO"
}

Write-Log "" "INFO"

# ALTERNATIVE SOLUTION
Write-Log "========================================" "INFO"
Write-Log "ALTERNATIVE SOLUTION" "INFO"
Write-Log "========================================" "INFO"
Write-Log "If ADWS cannot be fixed, use ntdsutil on DC02:" "INFO"
Write-Log "  1. Log into WACPRODDC02 (via Session Manager)" "INFO"
Write-Log "  2. Run: ntdsutil" "INFO"
Write-Log "  3. Run: roles" "INFO"
Write-Log "  4. Run: connections" "INFO"
Write-Log "  5. Run: connect to server WACPRODDC02" "INFO"
Write-Log "  6. Run: quit" "INFO"
Write-Log "  7. Run: transfer rid master" "INFO"
Write-Log "  8. Run: transfer infrastructure master" "INFO"
Write-Log "  9. Run: quit" "INFO"
Write-Log "  10. Run: quit" "INFO"

Write-Log "" "INFO"
Write-Log "========================================" "INFO"
Write-Log "DIAGNOSTIC COMPLETE" "INFO"
Write-Log "========================================" "INFO"
Write-Log "Log saved to: $logFile" "INFO"
Write-Log "" "INFO"

# Return results
return @{
    Issues = $issues
    PortResults = $portResults
    CriticalPortsFailed = $criticalFailed
    LogFile = $logFile
}
