# WACPRODDC02 Connectivity Fix Summary
**Date:** February 8, 2026 10:30 AM  
**Status:** Migration 60% Complete - Action Required

---

## Current State

### FSMO Roles Distribution
| Role | Current Holder | Target Holder | Status |
|------|---------------|---------------|--------|
| PDC Emulator | WACPRODDC01 | WACPRODDC01 | ✅ Complete |
| Schema Master | WACPRODDC01 | WACPRODDC01 | ✅ Complete |
| Domain Naming Master | WACPRODDC01 | WACPRODDC01 | ✅ Complete |
| RID Master | AD02 (on-prem) | WACPRODDC02 | ❌ Pending |
| Infrastructure Master | AD02 (on-prem) | WACPRODDC02 | ❌ Pending |

### What Worked
- ✅ Phase 1 transfers to WACPRODDC01: **100% successful**
- ✅ PDC Emulator, Schema Master, Domain Naming Master all on AWS
- ✅ AD replication healthy
- ✅ Authentication working
- ✅ User has Enterprise Admin and Schema Admin permissions

### What Failed
- ❌ Phase 2 transfers to WACPRODDC02: **0% successful**
- ❌ RID Master transfer failed
- ❌ Infrastructure Master transfer failed

---

## Root Cause Analysis

### Error Message
```
Unable to contact the server. This may be because this server does not exist, 
it is currently down, or it does not have the Active Directory Web Services running.
```

### Root Cause
**ADWS (Active Directory Web Services) is not running or not accessible on WACPRODDC02**

The `Move-ADDirectoryServerOperationMasterRole` cmdlet requires ADWS (port 9389) to be running on the target DC. The log shows:
- WACPRODDC02 is reachable via AD cmdlets ✓
- ADWS service cannot be accessed ✗

### Why This Happened
Possible reasons:
1. ADWS service is stopped on WACPRODDC02
2. ADWS service doesn't exist (Server Core without RSAT)
3. Windows Firewall blocking port 9389 on WACPRODDC02
4. AWS Security Group not allowing port 9389 inbound

---

## Solution Steps

### Step 1: Fix ADWS on WACPRODDC02

**Log into WACPRODDC02** (10.70.11.10) and run:

```powershell
# Check if ADWS exists
Get-Service ADWS

# If it exists, start it
Start-Service ADWS
Set-Service ADWS -StartupType Automatic

# Verify it's running
Get-Service ADWS
```

**If ADWS doesn't exist** (Server Core):
```powershell
# Install RSAT-AD-PowerShell (includes ADWS)
Install-WindowsFeature RSAT-AD-PowerShell -IncludeManagementTools

# Start ADWS
Start-Service ADWS
Set-Service ADWS -StartupType Automatic
```

**Check Windows Firewall:**
```powershell
# Check for ADWS firewall rules
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*ADWS*"}

# Create rule if missing
New-NetFirewallRule -DisplayName "Active Directory Web Services (TCP-In)" `
    -Direction Inbound -Protocol TCP -LocalPort 9389 -Action Allow -Profile Domain
```

### Step 2: Verify Connectivity from WACPRODDC01

**On WACPRODDC01**, run:

```powershell
# Test ADWS port
Test-NetConnection 10.70.11.10 -Port 9389

# Should show: TcpTestSucceeded : True

# Test AD cmdlet access
Get-ADDomainController -Identity WACPRODDC02
```

### Step 3: Transfer Remaining Roles

**On WACPRODDC01**, run:

```powershell
# Transfer both roles at once
Move-ADDirectoryServerOperationMasterRole -Identity WACPRODDC02 `
    -OperationMasterRole RIDMaster,InfrastructureMaster -Force

# Verify transfer
netdom query fsmo

# Force replication
repadmin /syncall /AdeP
```

### Step 4: Verify Final State

```powershell
# Check FSMO roles
netdom query fsmo

# Expected output:
# Schema master               WACPRODDC01.WAC.NET
# Domain naming master        WACPRODDC01.WAC.NET
# PDC                         WACPRODDC01.WAC.NET
# RID pool manager            WACPRODDC02.WAC.NET  ← Should be DC02
# Infrastructure master       WACPRODDC02.WAC.NET  ← Should be DC02

# Run post-cutover verification
.\3-POST-CUTOVER-VERIFY.ps1
```

---

## Alternative Method (If ADWS Still Fails)

If ADWS cannot be started, use **ntdsutil** on WACPRODDC02:

```cmd
ntdsutil
roles
connections
connect to server WACPRODDC02
quit
transfer rid master
transfer infrastructure master
quit
quit
```

This method doesn't require ADWS but is more manual.

---

## Risk Assessment

### Current Risk Level: **LOW**

**Why Low Risk:**
- 60% of migration complete (3 of 5 roles)
- Most critical role (PDC Emulator) is on AWS ✓
- AD replication is healthy ✓
- Authentication is working ✓
- Domain is fully functional ✓

**Remaining Risks:**
- RID Master still on-prem (AD02)
  - **Impact if AD02 fails:** Cannot create new AD objects (users, computers, groups)
  - **Likelihood:** Low (AD02 is still operational)
  - **Mitigation:** Complete transfer ASAP

- Infrastructure Master still on-prem (AD02)
  - **Impact if AD02 fails:** Cross-domain reference updates may fail
  - **Likelihood:** Low (single domain environment)
  - **Mitigation:** Complete transfer ASAP

### Time Sensitivity
- **Not urgent** - Domain is fully functional
- **Recommended:** Complete within 24-48 hours
- **Critical:** Complete before decommissioning AD01/AD02

---

## Scripts Created

Three new scripts have been created to help complete the migration:

1. **FIX-WACPRODDC02-CONNECTIVITY.ps1**
   - Run on WACPRODDC02
   - Checks and fixes ADWS service
   - Checks and creates firewall rules
   - Verifies connectivity

2. **TRANSFER-REMAINING-ROLES.ps1**
   - Run on WACPRODDC01
   - Tests connectivity to WACPRODDC02
   - Transfers RID Master and Infrastructure Master
   - Verifies transfer success
   - Forces replication

3. **COPY-PASTE-INSTRUCTIONS.txt**
   - Quick reference guide
   - Copy/paste commands for each step
   - Troubleshooting tips

---

## Next Steps

1. **Immediate:** Log into WACPRODDC02 and run `FIX-WACPRODDC02-CONNECTIVITY.ps1`
2. **After fix:** From WACPRODDC01, run `TRANSFER-REMAINING-ROLES.ps1`
3. **Verify:** Run `3-POST-CUTOVER-VERIFY.ps1`
4. **Document:** Update cutover log with final results

---

## Support Information

**Scripts Location:**
- `03-Projects/WAC-DC-Migration/Scripts/FIX-WACPRODDC02-CONNECTIVITY.ps1`
- `03-Projects/WAC-DC-Migration/Scripts/TRANSFER-REMAINING-ROLES.ps1`
- `03-Projects/WAC-DC-Migration/Scripts/COPY-PASTE-INSTRUCTIONS.txt`

**Logs Location:**
- `C:\Cutover\Logs\` (on WACPRODDC01)

**Latest Cutover Log:**
- `03-Projects/WAC-DC-Migration/Reports/Cutover-20260208-095053.log`

---

**Document Version:** 1.0  
**Created By:** Kiro AI Assistant  
**Last Updated:** February 8, 2026 10:30 AM
