# WAC AD CUTOVER - EXECUTION CHECKLIST

**Date**: _______________  
**Executed By**: _______________  
**Start Time**: _______________  
**End Time**: _______________

---

## PRE-CUTOVER (1 hour before)

### Preparation
- [ ] Maintenance window scheduled
- [ ] Stakeholders notified
- [ ] Domain Admin credentials verified
- [ ] RDP access to WACPRODDC01 confirmed
- [ ] RDP access to AD01 confirmed (for rollback)

### AWS Snapshots
- [ ] Snapshot WACPRODDC01 created
- [ ] Snapshot WACPRODDC02 created
- [ ] Snapshots labeled: "Pre-FSMO-Transfer-YYYYMMDD"

### Script Deployment
- [ ] Scripts copied to C:\Cutover\ on WACPRODDC01
- [ ] Verified all 6 files present:
  - [ ] RUN-CUTOVER.bat
  - [ ] RUN-ROLLBACK.bat
  - [ ] 1-PRE-CUTOVER-CHECK.ps1
  - [ ] 2-EXECUTE-CUTOVER.ps1
  - [ ] 3-POST-CUTOVER-VERIFY.ps1
  - [ ] 4-ROLLBACK.ps1

### Rollback Preparation
- [ ] 4-ROLLBACK.ps1 copied to C:\Cutover\ on AD01
- [ ] RUN-ROLLBACK.bat copied to C:\Cutover\ on AD01
- [ ] Rollback procedure reviewed

---

## CUTOVER EXECUTION

### Phase 1: Pre-Cutover Checks (15 minutes)
- [ ] Logged into WACPRODDC01 as Domain Admin
- [ ] Opened C:\Cutover\
- [ ] Right-clicked RUN-CUTOVER.bat
- [ ] Selected "Run as Administrator"
- [ ] Pre-cutover checks started

**Pre-Cutover Check Results**:
- [ ] Running on WACPRODDC01: PASS / FAIL
- [ ] Domain Admin privileges: PASS / FAIL
- [ ] AD PowerShell module: PASS / FAIL
- [ ] All DCs online: PASS / FAIL
- [ ] Replication health: PASS / FAIL
- [ ] Current FSMO holders: PASS / FAIL
- [ ] DNS resolution: PASS / FAIL
- [ ] Time synchronization: PASS / FAIL
- [ ] WACPRODDC01 is Global Catalog: PASS / FAIL
- [ ] WACPRODDC02 is Global Catalog: PASS / FAIL

**GO/NO-GO GATE #1**:
- [ ] All checks PASSED - Proceed to Phase 2
- [ ] One or more checks FAILED - STOP, fix issues

**If FAILED, issues identified**:
_______________________________________________
_______________________________________________

---

### Phase 2: FSMO Transfer (30 minutes)
- [ ] Confirmed ready to proceed
- [ ] Pressed key to continue
- [ ] FSMO transfer started

**Transfer Results**:
- [ ] PDC Emulator to WACPRODDC01: SUCCESS / FAIL
- [ ] Schema Master to WACPRODDC01: SUCCESS / FAIL
- [ ] Domain Naming Master to WACPRODDC01: SUCCESS / FAIL
- [ ] RID Master to WACPRODDC02: SUCCESS / FAIL
- [ ] Infrastructure Master to WACPRODDC02: SUCCESS / FAIL
- [ ] Replication forced: SUCCESS / FAIL

**GO/NO-GO GATE #2**:
- [ ] All transfers SUCCESSFUL - Proceed to Phase 3
- [ ] One or more transfers FAILED - Run ROLLBACK

**If FAILED, run rollback**:
- [ ] RDP to AD01
- [ ] Run RUN-ROLLBACK.bat
- [ ] Rollback completed: SUCCESS / FAIL

---

### Phase 3: Post-Cutover Verification (15 minutes)
- [ ] Verification script started automatically
- [ ] Verification running

**Verification Results**:
- [ ] WACPRODDC01 holds 3 FSMO roles: PASS / FAIL
- [ ] WACPRODDC02 holds 2 FSMO roles: PASS / FAIL
- [ ] AD01 holds 0 FSMO roles: PASS / FAIL
- [ ] Replication health: PASS / FAIL
- [ ] DNS resolution: PASS / FAIL
- [ ] Time synchronization: PASS / FAIL
- [ ] Authentication test: PASS / FAIL
- [ ] All DCs online: PASS / FAIL
- [ ] No critical errors: PASS / FAIL
- [ ] PDC Emulator on WACPRODDC01: PASS / FAIL

**GO/NO-GO GATE #3**:
- [ ] All verifications PASSED - Proceed to Monitoring
- [ ] One or more verifications FAILED - Consider ROLLBACK

**If FAILED, action taken**:
_______________________________________________
_______________________________________________

---

## POST-CUTOVER MONITORING

### Hour 1 (Every 15 minutes)

**Time: ___:___ (15 min after cutover)**
- [ ] Replication check: 0 failures
- [ ] FSMO roles verified
- [ ] Authentication test: SUCCESS
- [ ] Notes: ___________________________________

**Time: ___:___ (30 min after cutover)**
- [ ] Replication check: 0 failures
- [ ] FSMO roles verified
- [ ] Authentication test: SUCCESS
- [ ] Notes: ___________________________________

**Time: ___:___ (45 min after cutover)**
- [ ] Replication check: 0 failures
- [ ] FSMO roles verified
- [ ] Authentication test: SUCCESS
- [ ] Notes: ___________________________________

**Time: ___:___ (60 min after cutover)**
- [ ] Replication check: 0 failures
- [ ] Event log check: No errors
- [ ] Time sync check: Working
- [ ] User login test: SUCCESS
- [ ] Notes: ___________________________________

### Hour 2 (Every 30 minutes)

**Time: ___:___ (90 min after cutover)**
- [ ] Replication check: 0 failures
- [ ] Event log check: No errors
- [ ] Time sync check: Working
- [ ] Notes: ___________________________________

**Time: ___:___ (120 min after cutover)**
- [ ] Final replication check: 0 failures
- [ ] Final event log check: No errors
- [ ] Final time sync check: Working
- [ ] Final user login test: SUCCESS
- [ ] Notes: ___________________________________

---

## FINAL STATUS

### Cutover Result
- [ ] SUCCESS - All phases completed, all tests passed
- [ ] PARTIAL SUCCESS - Completed with minor issues
- [ ] FAILED - Rollback executed

**Final FSMO Configuration**:
- WACPRODDC01 roles: _____ (expected: 3)
- WACPRODDC02 roles: _____ (expected: 2)
- AD01 roles: _____ (expected: 0)
- AD02 roles: _____ (expected: 0)

**Issues Encountered**:
_______________________________________________
_______________________________________________
_______________________________________________

**Resolution**:
_______________________________________________
_______________________________________________
_______________________________________________

---

## POST-CUTOVER TASKS

### Immediate (Day 1)
- [ ] Stakeholders notified: Cutover complete
- [ ] Logs archived to: 03-Projects/WAC-DC-Migration/Reports/Cutover-Logs/
- [ ] Documentation updated
- [ ] Incident report created (if issues occurred)

### Week 1
- [ ] Day 1: Replication monitoring
- [ ] Day 2: Replication monitoring
- [ ] Day 3: Replication monitoring
- [ ] Day 4: Replication monitoring
- [ ] Day 5: Replication monitoring
- [ ] Day 6: Replication monitoring
- [ ] Day 7: Weekly health check

### Week 2-4
- [ ] Week 2: Weekly health check
- [ ] Week 3: Weekly health check
- [ ] Week 4: Weekly health check
- [ ] Verify no applications depend on AD01/AD02

### Decommissioning (Week 4-6)
- [ ] Demote AD01 from domain controller
- [ ] Demote AD02 from domain controller
- [ ] Remove AD01 from DNS
- [ ] Remove AD02 from DNS
- [ ] Clean up AD metadata
- [ ] Decommission AD01 server
- [ ] Decommission AD02 server
- [ ] Update network documentation

---

## SIGN-OFF

### Cutover Execution
**Executed By**: ___________________________  
**Date**: ___________________________  
**Time**: ___________________________  
**Result**: SUCCESS / FAILED  
**Signature**: ___________________________

### Verification
**Verified By**: ___________________________  
**Date**: ___________________________  
**Time**: ___________________________  
**Result**: VERIFIED / ISSUES FOUND  
**Signature**: ___________________________

### Approval
**Approved By**: ___________________________  
**Title**: ___________________________  
**Date**: ___________________________  
**Signature**: ___________________________

---

## NOTES

**Additional Comments**:
_______________________________________________
_______________________________________________
_______________________________________________
_______________________________________________
_______________________________________________

**Lessons Learned**:
_______________________________________________
_______________________________________________
_______________________________________________
_______________________________________________
_______________________________________________

---

**END OF CHECKLIST**

**Archive this completed checklist to**: 03-Projects/WAC-DC-Migration/Reports/
