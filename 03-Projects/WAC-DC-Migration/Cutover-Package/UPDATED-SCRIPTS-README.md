# Updated Cutover Scripts - February 8, 2026

## Changes Made

### 1. Pre-Cutover Check Script (1-PRE-CUTOVER-CHECK.ps1)
**Fixed:** DC connectivity check now uses AD queries instead of ping
- **Old behavior:** Used `Test-Connection` (ping/ICMP) which failed when ICMP was blocked
- **New behavior:** Uses `Get-ADDomainController` to verify DCs are reachable via AD services
- **Result:** Will now pass even if ICMP/ping is blocked by firewalls

### 2. Execute Cutover Script (2-EXECUTE-CUTOVER.ps1)
**Added:** Permission validation and ADWS checks
- **Permission Check:** Verifies user is in Enterprise Admins group (exits if not)
- **Schema Admin Warning:** Warns if user is not in Schema Admins group
- **ADWS Check:** Verifies Active Directory Web Services is running on WACPRODDC02
- **Auto-Start:** Attempts to start ADWS automatically if it's stopped

## Prerequisites Before Running

### 1. Add User to Required Groups
Run on any DC as Domain Admin:
```powershell
Add-ADGroupMember -Identity "Enterprise Admins" -Members "arifb"
Add-ADGroupMember -Identity "Schema Admins" -Members "arifb"
```

### 2. Verify ADWS on WACPRODDC02
Run on WACPRODDC02:
```powershell
Get-Service ADWS
Start-Service ADWS
Set-Service ADWS -StartupType Automatic
```

### 3. Log Out and Back In
After adding to groups, log out and back in for group membership to take effect.

## Execution Steps

### Step 1: Copy to WACPRODDC01
Copy the entire `Cutover-Package` folder to WACPRODDC01

### Step 2: Run Pre-Cutover Check
```powershell
cd C:\Users\[YourUser]\Desktop\Cutover-Package\Scripts
.\1-PRE-CUTOVER-CHECK.ps1
```

Expected result: All 10 tests should pass

### Step 3: Run Cutover
```powershell
.\2-EXECUTE-CUTOVER.ps1
```

The script will:
1. Check permissions (will exit if insufficient)
2. Check ADWS on WACPRODDC02 (will attempt to start if needed)
3. Document current FSMO holders
4. Pause for confirmation
5. Transfer roles to WACPRODDC01 (PDC, Schema Master, Domain Naming Master)
6. Transfer roles to WACPRODDC02 (RID Master, Infrastructure Master)
7. Force replication
8. Verify new FSMO holders

### Step 4: Post-Cutover Verification
```powershell
.\3-POST-CUTOVER-VERIFY.ps1
```

## Logs Location
All logs are saved to: `C:\Cutover\Logs\`

## Rollback (If Needed)
If something goes wrong:
```powershell
.\4-ROLLBACK.ps1
```

## Previous Cutover Attempt
**Date:** 2026-02-08 08:54:06
**Result:** FAILED - All transfers failed
**Reason:** 
- Permission issues (Access Denied)
- ADWS not running on WACPRODDC02

**Current Status:** All FSMO roles still on AD01/AD02 (no changes made)

## Support
If issues persist, check:
1. User group membership: `whoami /groups`
2. ADWS status: `Get-Service ADWS -ComputerName WACPRODDC02`
3. AD replication: `repadmin /replsummary`
4. Logs in C:\Cutover\Logs\

---
**Updated:** February 8, 2026
**Updated By:** Kiro AI Assistant
