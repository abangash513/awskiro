<#
.SYNOPSIS
    Simple Time Sync Fix for WAC Domain Controllers

.DESCRIPTION
    Simplified script to fix time synchronization with better error handling

.NOTES
    Run as Domain Admin
#>

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "WAC Time Synchronization Fix" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERROR: Must run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "[OK] Running with Administrator privileges" -ForegroundColor Green
Write-Host ""

# Determine if this is the PDC
Write-Host "Checking FSMO roles..." -ForegroundColor Yellow
try {
    $netdomOutput = netdom query fsmo 2>&1 | Out-String
    Write-Host $netdomOutput
    
    $isPDC = $netdomOutput -match "PDC.*$env:COMPUTERNAME"
    
    if ($isPDC) {
        Write-Host "[OK] This DC is the PDC Emulator" -ForegroundColor Green
    } else {
        Write-Host "[OK] This DC is NOT the PDC Emulator" -ForegroundColor Green
    }
} catch {
    Write-Host "[WARN] Could not determine PDC role, assuming NOT PDC" -ForegroundColor Yellow
    $isPDC = $false
}

Write-Host ""
Write-Host "Stopping Windows Time service..." -ForegroundColor Yellow
Stop-Service W32Time -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Write-Host "[OK] Service stopped" -ForegroundColor Green
Write-Host ""

if ($isPDC) {
    Write-Host "Configuring as PDC (external time source)..." -ForegroundColor Yellow
    w32tm /config /manualpeerlist:"time.windows.com,0x9 time.nist.gov,0x9" /syncfromflags:manual /reliable:yes /update
} else {
    Write-Host "Configuring as non-PDC (domain hierarchy)..." -ForegroundColor Yellow
    w32tm /config /syncfromflags:domhier /update
}

Write-Host "[OK] Configuration updated" -ForegroundColor Green
Write-Host ""

Write-Host "Starting Windows Time service..." -ForegroundColor Yellow
Start-Service W32Time
Start-Sleep -Seconds 3
Write-Host "[OK] Service started" -ForegroundColor Green
Write-Host ""

Write-Host "Forcing time synchronization..." -ForegroundColor Yellow
w32tm /resync /rediscover
Start-Sleep -Seconds 5
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Current Time Status:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
w32tm /query /status
Write-Host ""

Write-Host "Time Source:" -ForegroundColor Cyan
w32tm /query /source
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "[SUCCESS] Time sync configuration complete!" -ForegroundColor Green
Write-Host "Wait 5-10 minutes and check status again with:" -ForegroundColor Yellow
Write-Host "  w32tm /query /status" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

pause
