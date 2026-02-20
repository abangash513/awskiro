# Organize Cutover Package Script
# This script copies all necessary files into the Cutover-Package folder
# Run this from: 03-Projects/WAC-DC-Migration/

$ErrorActionPreference = "Continue"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ORGANIZING CUTOVER PACKAGE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Define paths
$baseDir = $PSScriptRoot
$packageDir = Join-Path $baseDir "Cutover-Package"
$docDir = Join-Path $packageDir "Documentation"
$scriptDir = Join-Path $packageDir "Scripts"
$reportDir = Join-Path $packageDir "Reports"

# Create directories
Write-Host "Creating directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Path $packageDir -Force | Out-Null
New-Item -ItemType Directory -Path $docDir -Force | Out-Null
New-Item -ItemType Directory -Path $scriptDir -Force | Out-Null
New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
Write-Host "Directories created" -ForegroundColor Green
Write-Host ""

# Copy Documentation
Write-Host "Copying documentation..." -ForegroundColor Yellow

$docs = @{
    "CRITICAL-CLARIFICATIONS.md" = "01-CRITICAL-CLARIFICATIONS.md"
    "CUTOVER-SUMMARY.md" = "02-CUTOVER-SUMMARY.md"
    "CUTOVER-EXECUTION-PLAN.md" = "03-CUTOVER-EXECUTION-PLAN.md"
    "CUTOVER-CHECKLIST.md" = "04-CUTOVER-CHECKLIST.md"
    "DECOMMISSION-ALL-ONPREM-ANALYSIS.md" = "05-DECOMMISSION-PLAN.md"
    "Reports\CUTOVER-GO-NO-GO-REPORT.md" = "06-GO-NO-GO-REPORT.md"
    "INDEX.md" = "07-INDEX.md"
}

foreach ($source in $docs.Keys) {
    $sourcePath = Join-Path $baseDir $source
    $destPath = Join-Path $docDir $docs[$source]
    
    if (Test-Path $sourcePath) {
        Copy-Item $sourcePath $destPath -Force
        Write-Host "  Copied: $($docs[$source])" -ForegroundColor Green
    } else {
        Write-Host "  Missing: $source" -ForegroundColor Red
    }
}

Write-Host ""

# Copy Scripts
Write-Host "Copying scripts..." -ForegroundColor Yellow

$scripts = @(
    "Scripts\Cutover\RUN-CUTOVER.bat"
    "Scripts\Cutover\RUN-ROLLBACK.bat"
    "Scripts\Cutover\1-PRE-CUTOVER-CHECK.ps1"
    "Scripts\Cutover\2-EXECUTE-CUTOVER.ps1"
    "Scripts\Cutover\3-POST-CUTOVER-VERIFY.ps1"
    "Scripts\Cutover\4-ROLLBACK.ps1"
)

foreach ($script in $scripts) {
    $sourcePath = Join-Path $baseDir $script
    $fileName = Split-Path $script -Leaf
    $destPath = Join-Path $scriptDir $fileName
    
    if (Test-Path $sourcePath) {
        Copy-Item $sourcePath $destPath -Force
        Write-Host "  Copied: $fileName" -ForegroundColor Green
    } else {
        Write-Host "  Missing: $script" -ForegroundColor Red
    }
}

# Create decommissioning scripts inline
Write-Host "  Creating: Demote-DC.ps1" -ForegroundColor Green
$demoteScript = @'
# Demote Domain Controller Script
# Run on the DC to be decommissioned

param(
    [Parameter(Mandatory=$true)]
    [string]$DCName,
    [string]$LocalAdminPassword = "TempPass123!"
)

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "DECOMMISSIONING DC: $DCName" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

# Verify no FSMO roles
Write-Host "Checking FSMO roles..." -ForegroundColor Cyan
$fsmo = netdom query fsmo
if ($fsmo -match $DCName) {
    Write-Host "ERROR: DC still holds FSMO roles!" -ForegroundColor Red
    Write-Host "Transfer FSMO roles before decommissioning" -ForegroundColor Red
    exit 1
}

Write-Host "PASS: No FSMO roles on this DC" -ForegroundColor Green

# Confirm
Write-Host ""
Write-Host "WARNING: About to demote $DCName" -ForegroundColor Yellow
$confirm = Read-Host "Type 'DEMOTE' to confirm"

if ($confirm -ne "DEMOTE") {
    Write-Host "Decommission cancelled" -ForegroundColor Yellow
    exit 0
}

# Demote
Write-Host "Demoting DC..." -ForegroundColor Cyan
$securePassword = ConvertTo-SecureString $LocalAdminPassword -AsPlainText -Force
Uninstall-ADDSDomainController -LocalAdministratorPassword $securePassword -Force

Write-Host "DC demotion initiated. Server will reboot." -ForegroundColor Green
'@
$demoteScript | Out-File -FilePath (Join-Path $scriptDir "Demote-DC.ps1") -Encoding UTF8

Write-Host "  Creating: Cleanup-DC-Metadata.ps1" -ForegroundColor Green
$cleanupScript = @'
# Cleanup DC Metadata Script
# Run on WACPRODDC01 after DC is demoted

param(
    [Parameter(Mandatory=$true)]
    [string]$DemotedDCName
)

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "CLEANING UP METADATA: $DemotedDCName" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

Import-Module ActiveDirectory

# Verify DC is demoted
Write-Host "Verifying DC is demoted..." -ForegroundColor Cyan
$dc = Get-ADDomainController -Filter {Name -eq $DemotedDCName} -ErrorAction SilentlyContinue
if ($dc) {
    Write-Host "ERROR: DC still appears in AD!" -ForegroundColor Red
    exit 1
}

Write-Host "PASS: DC not found in AD (demoted)" -ForegroundColor Green

# Remove DNS records
Write-Host "Removing DNS records..." -ForegroundColor Cyan
Remove-DnsServerResourceRecord -ZoneName "wac.net" -Name $DemotedDCName -RRType "A" -Force -ErrorAction SilentlyContinue
Write-Host "DNS A records removed" -ForegroundColor Green

# Force replication
Write-Host "Forcing replication..." -ForegroundColor Cyan
repadmin /syncall /AdeP

# Verify
Write-Host "Verifying cleanup..." -ForegroundColor Cyan
$dcCount = (Get-ADDomainController -Filter *).Count
Write-Host "Remaining DCs: $dcCount" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "CLEANUP COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
'@
$cleanupScript | Out-File -FilePath (Join-Path $scriptDir "Cleanup-DC-Metadata.ps1") -Encoding UTF8

Write-Host ""

# Copy Reports
Write-Host "Copying reports..." -ForegroundColor Yellow

$reports = @(
    "Reports\AD01-Verification-Analysis.md"
)

foreach ($report in $reports) {
    $sourcePath = Join-Path $baseDir $report
    $fileName = Split-Path $report -Leaf
    $destPath = Join-Path $reportDir $fileName
    
    if (Test-Path $sourcePath) {
        Copy-Item $sourcePath $destPath -Force
        Write-Host "  Copied: $fileName" -ForegroundColor Green
    } else {
        Write-Host "  Missing: $report" -ForegroundColor Yellow
    }
}

Write-Host ""

# Create README for Reports folder
$reportsReadme = @"
# Reports Folder

This folder contains:
- AD01-Verification-Analysis.md (Pre-cutover analysis)
- Logs will be created here during cutover execution

## Log Files (Created During Execution)

After running RUN-CUTOVER.bat, you'll find:
- PreCutover-YYYYMMDD-HHMMSS.log
- Cutover-YYYYMMDD-HHMMSS.log
- PostCutover-YYYYMMDD-HHMMSS.log
- FSMO-Backup-YYYYMMDD-HHMMSS.txt

All logs are saved to C:\Cutover\Logs\ on WACPRODDC01.
"@
$reportsReadme | Out-File -FilePath (Join-Path $reportDir "README.md") -Encoding UTF8
Write-Host "  Created: Reports\README.md" -ForegroundColor Green

Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PACKAGE ORGANIZATION COMPLETE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$fileCount = (Get-ChildItem $packageDir -Recurse -File).Count
Write-Host "Total files in package: $fileCount" -ForegroundColor Green
Write-Host "Package location: $packageDir" -ForegroundColor Green
Write-Host ""

Write-Host "Package structure:" -ForegroundColor Yellow
Get-ChildItem $packageDir -Recurse | Select-Object FullName | ForEach-Object {
    $relativePath = $_.FullName.Replace($packageDir, "Cutover-Package")
    Write-Host "  $relativePath" -ForegroundColor White
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "READY TO COPY TO AWS" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Copy the entire 'Cutover-Package' folder to WACPRODDC01" -ForegroundColor White
Write-Host "2. Place it at C:\Cutover\ on WACPRODDC01" -ForegroundColor White
Write-Host "3. Read START-HERE.md" -ForegroundColor White
Write-Host "4. Run Scripts\RUN-CUTOVER.bat" -ForegroundColor White
Write-Host ""
Write-Host "See COPY-TO-AWS-INSTRUCTIONS.md for detailed copy instructions" -ForegroundColor Cyan
