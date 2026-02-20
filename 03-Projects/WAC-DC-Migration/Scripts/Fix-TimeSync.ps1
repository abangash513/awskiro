<#
.SYNOPSIS
    Fix Windows Time Service synchronization on WAC Domain Controllers

.DESCRIPTION
    This script:
    - Checks if this DC holds the PDC Emulator role
    - Configures time sync appropriately (external source for PDC, domain hierarchy for others)
    - Forces synchronization
    - Validates the configuration

.NOTES
    Author: Generated for WAC DC Migration
    Date: 2026-02-07
    Requirements: Run as Domain Admin
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logPath = "C:\Setup\Logs\TimeSync-Fix-$timestamp.log"

# Ensure log directory exists
$logDir = Split-Path $logPath -Parent
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $logMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    Write-Host $logMessage
    Add-Content -Path $logPath -Value $logMessage
}

Write-Log "========================================" "INFO"
Write-Log "WAC Time Synchronization Fix Script" "INFO"
Write-Log "========================================" "INFO"
Write-Log "Computer: $env:COMPUTERNAME" "INFO"
Write-Log "Domain: $env:USERDNSDOMAIN" "INFO"
Write-Log "User: $env:USERNAME" "INFO"
Write-Log "" "INFO"

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Log "ERROR: This script must be run as Administrator!" "ERROR"
    Write-Host "`nPlease run PowerShell as Administrator and try again." -ForegroundColor Red
    exit 1
}

Write-Log "Running with Administrator privileges" "INFO"
Write-Log "" "INFO"

# Step 1: Check FSMO roles
Write-Log "Step 1: Checking FSMO role locations..." "INFO"
try {
    $pdcEmulator = (Get-ADDomain).PDCEmulator
    $currentDC = "$env:COMPUTERNAME.$env:USERDNSDOMAIN"
    
    Write-Log "PDC Emulator: $pdcEmulator" "INFO"
    Write-Log "Current DC: $currentDC" "INFO"
    
    $isPDC = $pdcEmulator -eq $currentDC
    Write-Log "Is this DC the PDC Emulator? $isPDC" "INFO"
} catch {
    Write-Log "ERROR: Failed to query FSMO roles: $_" "ERROR"
    Write-Log "Attempting fallback method..." "WARN"
    
    try {
        $netdomOutput = netdom query fsmo 2>&1
        $isPDC = $netdomOutput -match $env:COMPUTERNAME
        Write-Log "Fallback check - Is PDC: $isPDC" "INFO"
    } catch {
        Write-Log "ERROR: Could not determine PDC role. Assuming NOT PDC." "ERROR"
        $isPDC = $false
    }
}

Write-Log "" "INFO"

# Step 2: Stop Windows Time service
Write-Log "Step 2: Stopping Windows Time service..." "INFO"
try {
    Stop-Service W32Time -Force -ErrorAction Stop
    Write-Log "Windows Time service stopped" "INFO"
} catch {
    Write-Log "WARNING: Could not stop W32Time service: $_" "WARN"
}

Start-Sleep -Seconds 2
Write-Log "" "INFO"

# Step 3: Configure time synchronization
Write-Log "Step 3: Configuring time synchronization..." "INFO"

if ($isPDC) {
    Write-Log "Configuring as PDC Emulator (external time source)..." "INFO"
    
    # Configure external time sources (multiple for redundancy)
    $timeServers = "time.windows.com,0x9 time.nist.gov,0x9 pool.ntp.org,0x9"
    
    try {
        w32tm /config /manualpeerlist:$timeServers /syncfromflags:manual /reliable:yes /update 2>&1 | Out-Null
        Write-Log "Configured external time sources: $timeServers" "INFO"
    } catch {
        Write-Log "ERROR: Failed to configure external time sources: $_" "ERROR"
    }
    
} else {
    Write-Log "Configuring as non-PDC DC (domain hierarchy sync)..." "INFO"
    
    try {
        w32tm /config /syncfromflags:domhier /update 2>&1 | Out-Null
        Write-Log "Configured to sync from domain hierarchy" "INFO"
    } catch {
        Write-Log "ERROR: Failed to configure domain hierarchy sync: $_" "ERROR"
    }
}

Write-Log "" "INFO"

# Step 4: Start Windows Time service
Write-Log "Step 4: Starting Windows Time service..." "INFO"
try {
    Start-Service W32Time -ErrorAction Stop
    Write-Log "Windows Time service started" "INFO"
} catch {
    Write-Log "ERROR: Failed to start W32Time service: $_" "ERROR"
    exit 1
}

Start-Sleep -Seconds 3
Write-Log "" "INFO"

# Step 5: Force time synchronization
Write-Log "Step 5: Forcing time synchronization..." "INFO"
try {
    $resyncOutput = w32tm /resync /rediscover 2>&1
    Write-Log "Resync output: $resyncOutput" "INFO"
} catch {
    Write-Log "WARNING: Resync command returned error (may be normal): $_" "WARN"
}

Start-Sleep -Seconds 5
Write-Log "" "INFO"

# Step 6: Verify configuration
Write-Log "Step 6: Verifying time synchronization status..." "INFO"
Write-Log "========================================" "INFO"

try {
    Write-Log "`nTime Service Status:" "INFO"
    $statusOutput = w32tm /query /status 2>&1
    $statusOutput | ForEach-Object { Write-Log $_ "INFO" }
    
    Write-Log "`nTime Configuration:" "INFO"
    $configOutput = w32tm /query /configuration 2>&1
    $configOutput | ForEach-Object { Write-Log $_ "INFO" }
    
    Write-Log "`nTime Source:" "INFO"
    $sourceOutput = w32tm /query /source 2>&1
    Write-Log $sourceOutput "INFO"
    
    Write-Log "`nPeers:" "INFO"
    $peersOutput = w32tm /query /peers 2>&1
    $peersOutput | ForEach-Object { Write-Log $_ "INFO" }
    
} catch {
    Write-Log "ERROR: Failed to query time service: $_" "ERROR"
}

Write-Log "" "INFO"
Write-Log "========================================" "INFO"

# Step 7: Check if sync is working
Write-Log "Step 7: Checking synchronization status..." "INFO"

$statusCheck = w32tm /query /status 2>&1 | Out-String
if ($statusCheck -match "Leap Indicator: 0\(no warning\)" -or $statusCheck -match "Stratum: [1-9]") {
    Write-Log "SUCCESS: Time synchronization is working!" "INFO"
    Write-Host "`n✅ Time synchronization fixed successfully!" -ForegroundColor Green
} else {
    Write-Log "WARNING: Time may not be fully synchronized yet. Wait 5-10 minutes and check again." "WARN"
    Write-Host "`n⚠️  Time sync configured but not fully synchronized yet." -ForegroundColor Yellow
    Write-Host "Wait 5-10 minutes and run: w32tm /query /status" -ForegroundColor Yellow
}

Write-Log "" "INFO"
Write-Log "========================================" "INFO"
Write-Log "Log file saved to: $logPath" "INFO"
Write-Log "========================================" "INFO"

Write-Host "`nLog file: $logPath" -ForegroundColor Cyan
