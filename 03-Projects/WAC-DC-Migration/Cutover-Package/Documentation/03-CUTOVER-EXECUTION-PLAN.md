# WAC AD CUTOVER - COMPLETE EXECUTION PLAN
**Version**: 1.0  
**Date**: February 7, 2026  
**Cutover Type**: FSMO Role Transfer from On-Prem to AWS  
**Estimated Duration**: 3 hours (including testing)  
**Difficulty**: EASY - Fully Automated with Scripts

---

## QUICK START GUIDE

**For the impatient**: Run these 3 scripts in order:
1. `1-PRE-CUTOVER-CHECK.ps1` - Verify readiness (15 min)
2. `2-EXECUTE-CUTOVER.ps1` - Transfer FSMO roles (30 min)
3. `3-POST-CUTOVER-VERIFY.ps1` - Verify success (15 min)

Each script has GO/NO-GO gates and will STOP if anything fails.

---

## OVERVIEW

This plan transfers all 5 FSMO roles from legacy on-prem DCs to AWS DCs:

**FROM** (On-Prem - Windows Server 2008 R2):
- AD01: PDC Emulator, Schema Master, Domain Naming Master
- AD02: RID Pool Manager, Infrastructure Master

**TO** (AWS - Windows Server 2019):
- WACPRODDC01: PDC Emulator, Schema Master, Domain Naming Master
- WACPRODDC02: RID Pool Manager, Infrastructure Master

---

## PREREQUISITES

**Required Access**:
- Domain Admin credentials
- RDP access to WACPRODDC01 (10.70.10.10)
- RDP access to AD01 (10.1.220.8) - for rollback only

**Required Time**:
- Maintenance Window: 3 hours
- Recommended: Saturday 2:00 AM - 5:00 AM

**Required Tools** (already on DCs):
- PowerShell 5.1+
- Active Directory PowerShell Module
- netdom.exe
- repadmin.exe

---

## CUTOVER PHASES


### Phase 1: Pre-Cutover Checks (30 minutes)
- Verify all DCs online
- Check replication health
- Verify DNS resolution
- Take snapshots/backups
- Document current state

### Phase 2: FSMO Transfer (30 minutes)
- Transfer roles to WACPRODDC01 (3 roles)
- Transfer roles to WACPRODDC02 (2 roles)
- Force replication
- Verify transfer success

### Phase 3: Post-Cutover Verification (30 minutes)
- Verify FSMO roles on new holders
- Test replication
- Test authentication
- Test time sync
- Check event logs

### Phase 4: Monitoring (2 hours)
- Monitor replication every 15 minutes
- Monitor authentication
- Monitor time sync
- Check for errors

---

## AUTOMATED SCRIPTS

All scripts are located in: `03-Projects/WAC-DC-Migration/Scripts/Cutover/`

**Script 1**: `1-PRE-CUTOVER-CHECK.ps1`
- Checks all prerequisites
- GO/NO-GO gate before proceeding

**Script 2**: `2-EXECUTE-CUTOVER.ps1`
- Transfers all FSMO roles
- Automatic rollback on failure

**Script 3**: `3-POST-CUTOVER-VERIFY.ps1`
- Verifies success
- Generates report

**Script 4**: `4-ROLLBACK.ps1`
- Emergency rollback script
- Use only if cutover fails

---

## DETAILED EXECUTION STEPS



### STEP 1: Pre-Cutover Preparation (30 minutes before)

**Location**: WACPRODDC01 (AWS DC)  
**User**: Domain Admin

1. **Copy scripts to WACPRODDC01**:
   ```
   Copy all files from: 03-Projects/WAC-DC-Migration/Scripts/Cutover/
   To: C:\Cutover\ on WACPRODDC01
   ```

2. **Verify files copied**:
   ```
   dir C:\Cutover
   ```
   
   You should see:
   - 1-PRE-CUTOVER-CHECK.ps1
   - 2-EXECUTE-CUTOVER.ps1
   - 3-POST-CUTOVER-VERIFY.ps1
   - 4-ROLLBACK.ps1
   - RUN-CUTOVER.bat
   - RUN-ROLLBACK.bat

3. **Take AWS snapshots** (via AWS Console):
   - Snapshot WACPRODDC01 (i-xxxxxxxxx)
   - Snapshot WACPRODDC02 (i-xxxxxxxxx)
   - Label: "Pre-FSMO-Transfer-YYYYMMDD"

4. **Notify stakeholders**:
   - Email: "FSMO cutover starting at [TIME]"
   - Expected duration: 2 hours
   - Expected impact: None (transparent to users)

---

### STEP 2: Execute Pre-Cutover Checks (15 minutes)

**Location**: WACPRODDC01  
**Method**: Automated Script

**Option A - Use Batch File (EASIEST)**:
```
Right-click C:\Cutover\RUN-CUTOVER.bat
Select "Run as Administrator"
```

**Option B - Run PowerShell Manually**:
```powershell
cd C:\Cutover
powershell -ExecutionPolicy Bypass -File .\1-PRE-CUTOVER-CHECK.ps1
```

**Expected Output**:
```
========================================
PRE-CUTOVER CHECK SUMMARY
========================================
Tests Passed: 10 / 10

  [PASS] Running on WACPRODDC01
  [PASS] Domain Admin privileges
  [PASS] AD PowerShell module
  [PASS] All DCs online
  [PASS] Replication health
  [PASS] Current FSMO holders
  [PASS] DNS resolution
  [PASS] Time synchronization
  [PASS] WACPRODDC01 is Global Catalog
  [PASS] WACPRODDC02 is Global Catalog

========================================
GO DECISION: PROCEED WITH CUTOVER
========================================
```

**GO/NO-GO GATE #1**:
- If all tests PASS: Proceed to Step 3
- If any test FAILS: STOP - Fix issues before proceeding

---

### STEP 3: Execute FSMO Transfer (30 minutes)

**Location**: WACPRODDC01  
**Method**: Automated Script

**If using RUN-CUTOVER.bat**: It will automatically proceed to this step

**If running manually**:
```powershell
cd C:\Cutover
powershell -ExecutionPolicy Bypass -File .\2-EXECUTE-CUTOVER.ps1
```

**What the script does**:
1. Documents current FSMO holders
2. Creates backup file
3. Transfers PDC Emulator to WACPRODDC01
4. Transfers Schema Master to WACPRODDC01
5. Transfers Domain Naming Master to WACPRODDC01
6. Transfers RID Master to WACPRODDC02
7. Transfers Infrastructure Master to WACPRODDC02
8. Forces replication across domain
9. Verifies all transfers

**Expected Output**:
```
========================================
PHASE 1: Transfer roles to WACPRODDC01
========================================

========================================
Transferring: PDC Emulator
Target DC: WACPRODDC01
========================================
Executing transfer...
SUCCESS: PDC Emulator transferred to WACPRODDC01

[... similar output for other roles ...]

========================================
CUTOVER SUMMARY
========================================
Result: ALL TRANSFERS SUCCESSFUL

Next Step: Run 3-POST-CUTOVER-VERIFY.ps1
```

**GO/NO-GO GATE #2**:
- If all transfers SUCCESS: Proceed to Step 4
- If any transfer FAILS: Run ROLLBACK (Step 6)

---

### STEP 4: Post-Cutover Verification (15 minutes)

**Location**: WACPRODDC01  
**Method**: Automated Script

**If using RUN-CUTOVER.bat**: It will automatically proceed to this step

**If running manually**:
```powershell
cd C:\Cutover
powershell -ExecutionPolicy Bypass -File .\3-POST-CUTOVER-VERIFY.ps1
```

**What the script does**:
1. Verifies WACPRODDC01 holds 3 roles
2. Verifies WACPRODDC02 holds 2 roles
3. Verifies AD01 holds 0 roles
4. Checks replication health
5. Tests DNS resolution
6. Tests time synchronization
7. Tests authentication
8. Checks all DCs online
9. Reviews event logs
10. Confirms PDC Emulator location

**Expected Output**:
```
========================================
POST-CUTOVER VERIFICATION SUMMARY
========================================
Tests Passed: 10 / 10

  [PASS] WACPRODDC01 holds 3 FSMO roles
  [PASS] WACPRODDC02 holds 2 FSMO roles
  [PASS] AD01 holds 0 FSMO roles
  [PASS] Replication health
  [PASS] DNS resolution
  [PASS] Time synchronization
  [PASS] Authentication test
  [PASS] All DCs online
  [PASS] No critical errors
  [PASS] PDC Emulator on WACPRODDC01

========================================
CURRENT FSMO ROLE HOLDERS
========================================
  Schema master               WACPRODDC01.WAC.NET
  Domain naming master        WACPRODDC01.WAC.NET
  PDC                         WACPRODDC01.WAC.NET
  RID pool manager            WACPRODDC02.WAC.NET
  Infrastructure master       WACPRODDC02.WAC.NET

========================================
CUTOVER SUCCESSFUL
========================================
```

**GO/NO-GO GATE #3**:
- If all tests PASS: Proceed to Step 5 (Monitoring)
- If any test FAILS: Consider ROLLBACK (Step 6)

---

### STEP 5: Post-Cutover Monitoring (2 hours)

**Location**: WACPRODDC01  
**Method**: Manual monitoring

**Hour 1 - Every 15 minutes**:

1. **Check replication**:
   ```powershell
   repadmin /replsummary
   ```
   Expected: 0 failures

2. **Check FSMO roles**:
   ```powershell
   netdom query fsmo
   ```
   Expected: WACPRODDC01 (3 roles), WACPRODDC02 (2 roles)

3. **Test authentication**:
   ```powershell
   nltest /sc_query:wac.net
   ```
   Expected: Success

**Hour 2 - Every 30 minutes**:

1. **Check event logs**:
   ```powershell
   Get-WinEvent -LogName "Directory Service" -MaxEvents 20 | Where-Object {$_.LevelDisplayName -eq "Error"}
   ```
   Expected: No errors

2. **Check time sync**:
   ```powershell
   w32tm /query /status
   ```
   Expected: Stratum 1-3, syncing

3. **Test user login** (from workstation):
   - Have a test user log in
   - Verify group policy applies
   - Verify network drives map

**Monitoring Checklist**:
- [ ] Hour 0: Cutover complete
- [ ] Hour 0:15: Replication check
- [ ] Hour 0:30: Replication check
- [ ] Hour 0:45: Replication check
- [ ] Hour 1:00: Full health check
- [ ] Hour 1:30: Full health check
- [ ] Hour 2:00: Final health check

**GO/NO-GO GATE #4**:
- If monitoring shows no issues: Declare SUCCESS
- If issues detected: Investigate and consider ROLLBACK

---

### STEP 6: ROLLBACK PROCEDURE (Emergency Only)

**When to use**: Only if cutover fails or critical issues detected

**Location**: AD01 (On-Prem DC)  
**Method**: Automated Script

**WARNING**: This reverses the cutover and puts FSMO roles back on AD01/AD02

**Execution**:

1. **RDP to AD01** (10.1.220.8)

2. **Copy rollback script to AD01**:
   ```
   Copy: 03-Projects/WAC-DC-Migration/Scripts/Cutover/4-ROLLBACK.ps1
   To: C:\Cutover\ on AD01
   ```

3. **Run rollback**:
   ```
   Right-click C:\Cutover\RUN-ROLLBACK.bat
   Select "Run as Administrator"
   ```

   Or manually:
   ```powershell
   cd C:\Cutover
   powershell -ExecutionPolicy Bypass -File .\4-ROLLBACK.ps1
   ```

4. **Confirm rollback**:
   - Type "ROLLBACK" when prompted
   - Script will transfer all roles back to AD01/AD02

**Expected Output**:
```
========================================
PHASE 1: Transfer roles back to AD01
========================================
SUCCESS: PDC Emulator transferred to AD01
SUCCESS: Schema Master transferred to AD01
SUCCESS: Domain Naming Master transferred to AD01

========================================
PHASE 2: Transfer roles back to AD02
========================================
SUCCESS: RID Master transferred to AD02
SUCCESS: Infrastructure Master transferred to AD02

========================================
ROLLBACK SUCCESSFUL
========================================
FSMO roles restored to AD01/AD02
```

**After Rollback**:
1. Verify FSMO roles: `netdom query fsmo`
2. Check replication: `repadmin /replsummary`
3. Investigate root cause of failure
4. Fix issues
5. Reschedule cutover

---

## TROUBLESHOOTING GUIDE

### Issue: Pre-cutover check fails - "All DCs online"

**Cause**: One or more DCs not responding

**Solution**:
1. Check which DC is offline:
   ```powershell
   Test-Connection AD01.wac.net
   Test-Connection AD02.wac.net
   Test-Connection WACPRODDC01.wac.net
   Test-Connection WACPRODDC02.wac.net
   ```
2. Bring offline DC online
3. Re-run pre-cutover check

---

### Issue: Pre-cutover check fails - "Replication health"

**Cause**: Replication failures detected

**Solution**:
1. Check replication details:
   ```powershell
   repadmin /showrepl
   ```
2. Force replication:
   ```powershell
   repadmin /syncall /AdeP
   ```
3. Wait 15 minutes
4. Re-run pre-cutover check

---

### Issue: FSMO transfer fails - "Access Denied"

**Cause**: Not running as Domain Admin

**Solution**:
1. Verify you're logged in as Domain Admin
2. Right-click PowerShell and "Run as Administrator"
3. Re-run cutover script

---

### Issue: FSMO transfer fails - "RPC Server Unavailable"

**Cause**: Network connectivity issue

**Solution**:
1. Check firewall rules between on-prem and AWS
2. Verify RPC ports open (135, 49152-65535)
3. Test connectivity:
   ```powershell
   Test-NetConnection AD01.wac.net -Port 135
   ```
4. Fix network issue
5. Re-run cutover or ROLLBACK

---

### Issue: Post-cutover verification fails - "Replication health"

**Cause**: Replication lag after transfer

**Solution**:
1. Wait 15 minutes for replication to catch up
2. Force replication:
   ```powershell
   repadmin /syncall /AdeP
   ```
3. Re-run verification
4. If still failing after 30 minutes, consider ROLLBACK

---

### Issue: Authentication fails after cutover

**Cause**: Kerberos ticket cache

**Solution**:
1. Clear Kerberos tickets on client:
   ```cmd
   klist purge
   ```
2. Restart workstation
3. Test login again
4. If still failing, ROLLBACK immediately

---

## SUCCESS CRITERIA

**Cutover is successful when ALL of the following are true**:

1. WACPRODDC01 holds 3 FSMO roles (PDC, Schema, Domain Naming)
2. WACPRODDC02 holds 2 FSMO roles (RID, Infrastructure)
3. AD01 holds 0 FSMO roles
4. AD02 holds 0 FSMO roles
5. Replication shows 0 failures
6. All 10 DCs are online and replicating
7. DNS resolution working
8. Time sync working (WACPRODDC01 is authoritative)
9. User authentication working
10. No critical errors in event logs

---

## POST-CUTOVER TASKS

### Immediate (Day 1)
- [ ] Notify stakeholders: Cutover complete
- [ ] Document final FSMO configuration
- [ ] Archive cutover logs
- [ ] Update documentation

### Week 1
- [ ] Daily replication monitoring
- [ ] Daily event log review
- [ ] Monitor user authentication
- [ ] Monitor time sync

### Week 2-4
- [ ] Weekly health checks
- [ ] Monitor AD01/AD02 (should be idle)
- [ ] Verify no applications depend on AD01/AD02 as PDC

### Week 4-6 (Decommissioning)
- [ ] Demote AD01 from domain controller
- [ ] Demote AD02 from domain controller
- [ ] Remove AD01/AD02 from DNS
- [ ] Clean up AD metadata
- [ ] Decommission servers
- [ ] Update network documentation

---

## CONTACT INFORMATION

**During Cutover**:
- IT Director: [Phone]
- Infrastructure Manager: [Phone]
- AWS Support: [Case Number]

**Escalation**:
- If cutover fails: Run ROLLBACK immediately
- If rollback fails: Contact Microsoft Support
- If critical outage: Activate incident response team

---

## APPENDIX A: Manual FSMO Transfer Commands

If automated scripts fail, use these manual commands:

**Transfer to WACPRODDC01**:
```powershell
Move-ADDirectoryServerOperationMasterRole -Identity "WACPRODDC01" -OperationMasterRole PDCEmulator -Force
Move-ADDirectoryServerOperationMasterRole -Identity "WACPRODDC01" -OperationMasterRole SchemaMaster -Force
Move-ADDirectoryServerOperationMasterRole -Identity "WACPRODDC01" -OperationMasterRole DomainNamingMaster -Force
```

**Transfer to WACPRODDC02**:
```powershell
Move-ADDirectoryServerOperationMasterRole -Identity "WACPRODDC02" -OperationMasterRole RIDMaster -Force
Move-ADDirectoryServerOperationMasterRole -Identity "WACPRODDC02" -OperationMasterRole InfrastructureMaster -Force
```

**Force Replication**:
```powershell
repadmin /syncall /AdeP
```

**Verify FSMO Roles**:
```powershell
netdom query fsmo
```

---

## APPENDIX B: Log File Locations

All logs are saved to: `C:\Cutover\Logs\` on WACPRODDC01

**Log Files**:
- `PreCutover-YYYYMMDD-HHMMSS.log` - Pre-cutover check results
- `Cutover-YYYYMMDD-HHMMSS.log` - FSMO transfer log
- `PostCutover-YYYYMMDD-HHMMSS.log` - Verification results
- `FSMO-Backup-YYYYMMDD-HHMMSS.txt` - Backup of original FSMO config
- `Rollback-YYYYMMDD-HHMMSS.log` - Rollback log (if used)

**Archive logs after cutover** to: `03-Projects/WAC-DC-Migration/Reports/Cutover-Logs/`

---

## APPENDIX C: Quick Reference Commands

**Check FSMO Roles**:
```powershell
netdom query fsmo
```

**Check Replication**:
```powershell
repadmin /replsummary
```

**Force Replication**:
```powershell
repadmin /syncall /AdeP
```

**Check Time Sync**:
```powershell
w32tm /query /status
```

**Test Authentication**:
```powershell
nltest /sc_query:wac.net
```

**Check DNS**:
```powershell
nslookup wac.net
nslookup -type=srv _ldap._tcp.dc._msdcs.wac.net
```

**Check Event Logs**:
```powershell
Get-WinEvent -LogName "Directory Service" -MaxEvents 20 | Where-Object {$_.LevelDisplayName -eq "Error"}
```

---

**END OF CUTOVER EXECUTION PLAN**

**REMEMBER**: 
- Run all scripts as Domain Admin
- Run from WACPRODDC01 (except rollback)
- Have rollback plan ready
- Monitor for 2 hours after cutover
- Document everything

**GOOD LUCK!**


---

## PHASE 5: DECOMMISSIONING ON-PREM DCs (Weeks 1-4 After Cutover)

**IMPORTANT**: Do NOT decommission all on-prem DCs! Keep minimum 2 for local services.

### Recommended Decommissioning Plan

**Week 1-2: Decommission AD01**
- Target: AD01 (Windows Server 2008 R2) - EOL, security risk
- Reason: End of life, holds no FSMO roles after cutover
- Impact: Low (7 DCs remain)

**Week 2-3: Decommission AD02**
- Target: AD02 (Windows Server 2008 R2) - EOL, security risk
- Reason: End of life, holds no FSMO roles after cutover
- Impact: Low (6 DCs remain)

**Week 3-4: Decommission W09MVMPADDC01**
- Target: W09MVMPADDC01 (Windows Server 2012 R2) - Older OS
- Reason: Older OS, can be replaced by newer DCs
- Impact: Low (5 DCs remain)

**Final State After Phase 5**:
- WACPRODDC01 (AWS, Server 2019) - FSMO holder
- WACPRODDC02 (AWS, Server 2019) - FSMO holder
- WAC-DC01 (On-prem, Server 2022) - Local auth/DNS
- WAC-DC02 (On-prem, Server 2022) - Local auth/DNS
- WACHFDC01 (On-prem, Server 2019) - Optional
- WACHFDC02 (On-prem, Server 2019) - Optional
- W09MVMPADDC02 (On-prem, Server 2016) - Optional

**Total**: 7 DCs (2 AWS + 5 on-prem) or 4 DCs minimum (2 AWS + 2 on-prem)

---

### Decommissioning Procedure (Per DC)

**Step 1: Pre-Decommission Checks** (15 minutes)

On the DC to be decommissioned:
```powershell
# Verify no FSMO roles
netdom query fsmo

# Check replication partners
repadmin /showrepl

# Check for hardcoded references
# - Review application configs
# - Check DNS settings
# - Check DHCP options
# - Check monitoring systems
```

**Step 2: Graceful Demotion** (30 minutes)

On the DC to be decommissioned:
```powershell
# Demote the DC
Uninstall-ADDSDomainController -LocalAdministratorPassword (ConvertTo-SecureString "TempPass123!" -AsPlainText -Force) -Force

# Server will reboot automatically
```

**Step 3: Metadata Cleanup** (15 minutes)

On WACPRODDC01 (after DC reboots):
```powershell
# Clean up AD metadata
ntdsutil
metadata cleanup
connections
connect to server WACPRODDC01
quit
select operation target
list domains
select domain 0
list sites
select site 0
list servers in site
select server [NUMBER]  # Find the demoted DC number
quit
remove selected server
quit
quit

# Verify removal
Get-ADDomainController -Filter * | Select Name

# Check replication
repadmin /replsummary
```

**Step 4: DNS Cleanup** (10 minutes)

On WACPRODDC01:
```powershell
# Remove DNS records for demoted DC
# Open DNS Manager
# Delete A records for demoted DC
# Delete SRV records for demoted DC
# Or use PowerShell:
Remove-DnsServerResourceRecord -ZoneName "wac.net" -Name "AD01" -RRType "A" -Force
```

**Step 5: Verification** (15 minutes)

On WACPRODDC01:
```powershell
# Verify DC count
Get-ADDomainController -Filter * | Measure-Object

# Check replication
repadmin /replsummary

# Verify no errors
dcdiag /v /c /e

# Check event logs
Get-WinEvent -LogName "Directory Service" -MaxEvents 20 | Where-Object {$_.LevelDisplayName -eq "Error"}
```

**Step 6: Server Disposition** (7 days)

1. Power off server (don't delete)
2. Monitor for 7 days for any issues
3. If no issues, delete server
4. Update documentation

---

### Decommissioning Checklist

**Before Each Decommission**:
- [ ] Verify no FSMO roles on DC
- [ ] Check no applications hardcoded to DC IP
- [ ] Review DNS SRV records
- [ ] Check DHCP scope options
- [ ] Verify no scheduled tasks pointing to DC
- [ ] Check monitoring/backup systems
- [ ] Document all dependencies
- [ ] Notify stakeholders

**During Decommissioning**:
- [ ] Run dcdiag before demotion
- [ ] Gracefully demote (don't force)
- [ ] Clean up metadata
- [ ] Remove DNS records
- [ ] Update documentation
- [ ] Notify users/teams

**After Decommissioning**:
- [ ] Monitor replication for 7 days
- [ ] Check event logs for errors
- [ ] Verify application functionality
- [ ] Keep powered off for 7 days (rollback option)
- [ ] Final deletion after 7 days

---

### CRITICAL: Why Keep On-Prem DCs?

**DO NOT decommission all on-prem DCs!**

**Keep minimum 2 on-prem DCs** (WAC-DC01 and WAC-DC02) for:

1. **Local Authentication**: Fast logins for on-prem users (< 50ms vs 100-500ms over WAN)
2. **Local DNS**: No client reconfiguration needed
3. **Geographic Redundancy**: If AWS fails, on-prem still works
4. **Disaster Recovery**: Can restore from either location
5. **No WAN Dependency**: On-prem users don't need VPN for AD
6. **Better Performance**: Lower latency for on-prem services

**Only remove all on-prem DCs if**:
- ZERO on-premises users
- ZERO on-premises applications
- Multi-region AWS DCs deployed
- Completed 6-12 month migration plan

See **DECOMMISSION-ALL-ONPREM-ANALYSIS.md** for complete details.

---

## APPENDIX D: Decommissioning Scripts

### Script: Demote-DC.ps1

```powershell
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

# Check replication
Write-Host "Checking replication..." -ForegroundColor Cyan
$repl = repadmin /showrepl
Write-Host "Replication partners:" -ForegroundColor Cyan
$repl | Select-String "DC="

# Confirm
Write-Host ""
Write-Host "WARNING: About to demote $DCName" -ForegroundColor Yellow
Write-Host "This action cannot be undone easily" -ForegroundColor Yellow
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
```

### Script: Cleanup-DC-Metadata.ps1

```powershell
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
    Write-Host "Ensure DC is fully demoted before cleanup" -ForegroundColor Red
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

# Check replication
Write-Host "Checking replication..." -ForegroundColor Cyan
repadmin /replsummary

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "CLEANUP COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "DC $DemotedDCName successfully removed" -ForegroundColor Green
```

---

**END OF CUTOVER EXECUTION PLAN**
