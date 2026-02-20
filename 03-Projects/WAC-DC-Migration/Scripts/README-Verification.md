# WAC Domain Controller Verification Scripts

## Overview

These scripts help diagnose and fix issues with your AWS domain controllers.

## Scripts

### 1. Fix-TimeSync.ps1
Fixes Windows Time Service synchronization issues.

**What it does:**
- Detects if the DC is the PDC Emulator
- Configures appropriate time source (external for PDC, domain hierarchy for others)
- Forces time synchronization
- Validates the configuration

**Usage:**
```powershell
# Run as Domain Admin
cd "C:\Monitoring\WAC DC Cutover"
.\Fix-TimeSync.ps1
```

### 2. Run-Enhanced-Verification.ps1
Comprehensive AD health verification with 20+ tests.

**What it does:**
- Domain Controller discovery
- DNS resolution (A records, SRV records)
- Secure channel verification
- Time synchronization status
- Replication health (summary and detailed)
- FSMO role locations
- Event log analysis (Directory Service, DNS, System)
- DCDiag tests (connectivity, DNS, replication)
- Network connectivity to PDC

**Usage:**
```powershell
# Run as Domain Admin
cd "C:\Monitoring\WAC DC Cutover"
.\Run-Enhanced-Verification.ps1 -Domain wac.net
```

## Step-by-Step Instructions

### Step 1: Copy Scripts to WACPRODDC01

**Option A: Via RDP with drive sharing**
1. Connect to WACPRODDC01 via RDP with local drives enabled
2. Inside RDP session:
```powershell
# Create directory if it doesn't exist
New-Item -ItemType Directory -Path "C:\Monitoring\WAC DC Cutover" -Force

# Copy from your local machine
copy "\\tsclient\C\path\to\workspace\03-Projects\WAC-DC-Migration\Scripts\*.ps1" "C:\Monitoring\WAC DC Cutover\"
```

**Option B: Via AWS Systems Manager**
```powershell
# From your local machine
aws s3 cp "03-Projects/WAC-DC-Migration/Scripts/" s3://your-bucket/scripts/ --recursive --include "*.ps1"

# Then on the DC via SSM
aws ssm send-command --instance-ids "i-0745579f46a34da2e" --document-name "AWS-RunPowerShellScript" --parameters "commands=['Read-S3Object -BucketName your-bucket -KeyPrefix scripts/ -Folder C:\Monitoring\WAC DC Cutover\']"
```

### Step 2: Fix Time Synchronization

```powershell
# On WACPRODDC01, run PowerShell as Administrator
cd "C:\Monitoring\WAC DC Cutover"

# Run the fix script
.\Fix-TimeSync.ps1

# Wait 5 minutes, then verify
w32tm /query /status
```

**Expected output after fix:**
```
Leap Indicator: 0(no warning)
Stratum: 2 or 3 (not 0)
Last Successful Sync Time: <recent timestamp>
Source: <PDC name or external time server>
```

### Step 3: Run Enhanced Verification

```powershell
# On WACPRODDC01, run PowerShell as Administrator
cd "C:\Monitoring\WAC DC Cutover"

# Run the verification script
.\Run-Enhanced-Verification.ps1 -Domain wac.net
```

**Output location:**
- All results: `C:\Setup\Logs\Verification-<timestamp>\`
- Summary: `C:\Setup\Logs\Verification-<timestamp>\VERIFICATION-SUMMARY.txt`
- JSON: `C:\Setup\Logs\Verification-<timestamp>\verification-summary.json`

### Step 4: Copy Results Back to Your Machine

**Via RDP:**
```powershell
# Inside RDP session
$timestamp = Get-ChildItem "C:\Setup\Logs" | Where-Object { $_.Name -like "Verification-*" } | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty Name

Copy-Item "C:\Setup\Logs\$timestamp" -Recurse -Destination "\\tsclient\C\Users\YourUsername\Desktop\WAC-Verification-Results\"
```

**Via S3:**
```powershell
# On the DC
$timestamp = Get-ChildItem "C:\Setup\Logs" | Where-Object { $_.Name -like "Verification-*" } | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty Name

Write-S3Object -BucketName your-bucket -KeyPrefix "verification-results/$timestamp/" -Folder "C:\Setup\Logs\$timestamp" -Recurse

# Then from your local machine
aws s3 sync s3://your-bucket/verification-results/$timestamp/ ./verification-results/
```

## Troubleshooting

### "Access Denied" errors
**Solution:** Run PowerShell as Administrator and ensure you're logged in as a Domain Admin.

### Time sync still not working after fix
**Possible causes:**
1. Firewall blocking NTP (UDP 123) - check security groups
2. PDC Emulator is unreachable - verify network connectivity
3. External time servers blocked - try different time sources

**Check:**
```powershell
# Test NTP connectivity
Test-NetConnection -ComputerName time.windows.com -Port 123

# Check firewall rules
Get-NetFirewallRule | Where-Object { $_.DisplayName -like "*time*" }

# Force resync
w32tm /resync /rediscover
```

### Replication failures
**Check:**
```powershell
# Detailed replication status
repadmin /showrepl

# Force replication from all partners
repadmin /syncall /AdeP

# Check for replication errors
repadmin /replsummary
```

### DNS issues
**Check:**
```powershell
# Verify DNS server is running
Get-Service DNS

# Check DNS zones
Get-DnsServerZone

# Verify SRV records
nslookup -type=srv _ldap._tcp.dc._msdcs.wac.net
```

## Next Steps After Verification

1. **If all tests pass:**
   - Monitor for 24-48 hours
   - Run verification daily for a week
   - Document baseline health metrics

2. **If critical failures remain:**
   - Review detailed logs in the verification output folder
   - Check event logs for specific errors
   - Contact Microsoft support if needed

3. **Long-term monitoring:**
   - Schedule weekly verification runs
   - Set up CloudWatch alarms for replication failures
   - Monitor time drift (should be < 1 second)

## Files Generated

### Fix-TimeSync.ps1 Output
- `C:\Setup\Logs\TimeSync-Fix-<timestamp>.log`

### Run-Enhanced-Verification.ps1 Output
- `C:\Setup\Logs\Verification-<timestamp>\VERIFICATION-SUMMARY.txt` - Overall summary
- `C:\Setup\Logs\Verification-<timestamp>\verification-summary.json` - Machine-readable results
- `C:\Setup\Logs\Verification-<timestamp>\01-dclist.txt` through `20-network_pdc.txt` - Individual test results

## Support

For issues or questions:
1. Review the logs in `C:\Setup\Logs\`
2. Check Windows Event Viewer (Directory Service, DNS Server, System logs)
3. Run `dcdiag /v` for comprehensive diagnostics
4. Contact your AD team or AWS support

---

**Last Updated:** 2026-02-07
**Version:** 1.0
