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
