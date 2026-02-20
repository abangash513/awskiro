# FSMO Migration Plan - 2 Day Execution

## Overview
Migrate all 5 FSMO roles from on-premises domain controllers to AWS WACPRODDC01

**Timeline:** 2 Days  
**Target:** WACPRODDC01.WAC.NET (10.70.10.10)  
**Impact:** Minimal to none  

---

## Current FSMO Role Holders

| Role | Current Holder | Target Holder |
|------|----------------|---------------|
| Schema Master | AD01.WAC.NET | WACPRODDC01.WAC.NET |
| Domain Naming Master | AD01.WAC.NET | WACPRODDC01.WAC.NET |
| PDC Emulator | AD01.WAC.NET | WACPRODDC01.WAC.NET |
| RID Master | AD02.WAC.NET | WACPRODDC01.WAC.NET |
| Infrastructure Master | AD02.WAC.NET | WACPRODDC01.WAC.NET |

---

## DAY 1: FSMO Migration

### Hour 1: 8:00 AM - Pre-Flight Checks

```powershell
# Verify current FSMO holders
netdom query fsmo

# Check replication health
repadmin /replsummary

# Verify all DCs healthy
dcdiag /v /c /e

# Check AWS DCs
Get-ADDomainController WACPRODDC01,WACPRODDC02 | Select Name,IPv4Address,IsGlobalCatalog

# Verify VPN status (both tunnels must be UP)
```

**Go/No-Go Decision Point**

---

### Hour 2: 9:00 AM - Move Infrastructure Master

```powershell
# On WACPRODDC01
Move-ADDirectoryServerOperationMasterRole -Identity WACPRODDC01 -OperationMasterRole InfrastructureMaster -Force

# Verify
netdom query fsmo
repadmin /syncall /AdeP

# Wait 15 minutes, monitor
```

**Impact:** None (single domain)

---

### Hour 3: 9:30 AM - Move RID Master

```powershell
# On WACPRODDC01
Move-ADDirectoryServerOperationMasterRole -Identity WACPRODDC01 -OperationMasterRole RIDMaster -Force

# Verify
netdom query fsmo

# Test RID allocation
New-ADUser -Name "TestRID" -SamAccountName "testrid" -Enabled $false

# Wait 15 minutes, monitor
```

**Impact:** Low (only affects new object creation)

---

### Hour 4: 10:00 AM - Move Domain Naming Master

```powershell
# On WACPRODDC01
Move-ADDirectoryServerOperationMasterRole -Identity WACPRODDC01 -OperationMasterRole DomainNamingMaster -Force

# Verify
netdom query fsmo
repadmin /syncall /AdeP

# Wait 15 minutes, monitor
```

**Impact:** Low (rarely used)

---

### Hour 5: 10:30 AM - Move Schema Master

```powershell
# On WACPRODDC01
Move-ADDirectoryServerOperationMasterRole -Identity WACPRODDC01 -OperationMasterRole SchemaMaster -Force

# Verify
netdom query fsmo
repadmin /syncall /AdeP

# Wait 30 minutes, monitor closely
```

**Impact:** Low (rarely used)

---

### Hour 6: 11:30 AM - Move PDC Emulator ⚠️ CRITICAL

```powershell
# Final pre-check
netdom query fsmo
repadmin /replsummary
w32tm /query /status

# Move PDC Emulator
Move-ADDirectoryServerOperationMasterRole -Identity WACPRODDC01 -OperationMasterRole PDCEmulator -Force

# Immediate verification
netdom query fsmo
repadmin /syncall /AdeP
w32tm /resync /rediscover

# Test authentication
Test-ComputerSecureChannel -Server WACPRODDC01

# Test password change
Set-ADAccountPassword -Identity testuser -Reset -NewPassword (ConvertTo-SecureString "TempPass123!" -AsPlainText -Force)

# Monitor for 1 hour
```

**Impact:** HIGH - Monitor closely

---

### Hour 7-8: 12:30 PM - 2:00 PM - Verification

```powershell
# Verify all 5 roles on WACPRODDC01
netdom query fsmo

# Expected output:
# Schema master: WACPRODDC01.WAC.NET
# Domain naming master: WACPRODDC01.WAC.NET
# PDC: WACPRODDC01.WAC.NET
# RID pool manager: WACPRODDC01.WAC.NET
# Infrastructure master: WACPRODDC01.WAC.NET

# Replication health
repadmin /replsummary

# Event logs
Get-EventLog -LogName "Directory Service" -Newest 50 | Where-Object {$_.EntryType -eq "Error"}

# Test applications
# Test user authentication
# Test Group Policy updates
```

**If all checks pass → Proceed to decommissioning**

---

## Rollback Procedure

If critical issues occur:

```powershell
# Move roles back to original holders
Move-ADDirectoryServerOperationMasterRole -Identity AD01 -OperationMasterRole PDCEmulator -Force
Move-ADDirectoryServerOperationMasterRole -Identity AD01 -OperationMasterRole SchemaMaster -Force
Move-ADDirectoryServerOperationMasterRole -Identity AD01 -OperationMasterRole DomainNamingMaster -Force
Move-ADDirectoryServerOperationMasterRole -Identity AD02 -OperationMasterRole RIDMaster -Force
Move-ADDirectoryServerOperationMasterRole -Identity AD02 -OperationMasterRole InfrastructureMaster -Force

# Force replication
repadmin /syncall /AdeP
```

---

## Success Criteria

- ✅ All 5 FSMO roles on WACPRODDC01
- ✅ 0 replication failures
- ✅ 0 authentication failures
- ✅ No user complaints
- ✅ All applications working
- ✅ Event logs clean

---

## Monitoring Schedule

**Hour 1-6 (During migration):** Every 15 minutes  
**Hour 7-12:** Every 30 minutes  
**Day 2:** Every hour  
**Week 1:** Every 4 hours  

---

## Communication Plan

**8:00 AM - Start notification**
```
Subject: FSMO Migration Starting Now
All 5 FSMO roles being migrated to AWS.
Expected completion: 12:00 PM
Impact: Minimal to none
```

**12:00 PM - Completion notification**
```
Subject: FSMO Migration Complete
All roles successfully migrated to WACPRODDC01 (AWS)
Status: Monitoring
```

---

**Last Updated:** 2025-11-24
