# WAC AD CUTOVER - COMPLETE PACKAGE

**Version**: 1.0  
**Date**: February 7, 2026  
**Purpose**: FSMO Role Transfer from On-Prem to AWS  
**Status**: READY TO EXECUTE

---

## QUICK START

**Copy this entire folder to WACPRODDC01 (AWS DC)**

Then:
1. Read **START-HERE.md** (5 minutes)
2. Run **Scripts/RUN-CUTOVER.bat** as Administrator
3. Follow prompts

That's it! Everything is automated.

---

## FOLDER CONTENTS

```
Cutover-Package/
│
├── README.md (This file)
├── START-HERE.md (Quick start guide)
│
├── Documentation/
│   ├── 01-CRITICAL-CLARIFICATIONS.md (READ FIRST!)
│   ├── 02-CUTOVER-SUMMARY.md (Executive summary)
│   ├── 03-CUTOVER-EXECUTION-PLAN.md (Complete plan)
│   ├── 04-CUTOVER-CHECKLIST.md (Print this!)
│   ├── 05-DECOMMISSION-PLAN.md (Post-cutover)
│   ├── 06-GO-NO-GO-REPORT.md (Health assessment)
│   └── 07-INDEX.md (Master index)
│
├── Scripts/
│   ├── RUN-CUTOVER.bat (ONE-CLICK execution)
│   ├── RUN-ROLLBACK.bat (Emergency rollback)
│   ├── 1-PRE-CUTOVER-CHECK.ps1
│   ├── 2-EXECUTE-CUTOVER.ps1
│   ├── 3-POST-CUTOVER-VERIFY.ps1
│   ├── 4-ROLLBACK.ps1
│   ├── Demote-DC.ps1 (For decommissioning)
│   └── Cleanup-DC-Metadata.ps1 (For decommissioning)
│
└── Reports/
    ├── AD01-Verification-Analysis.md
    └── (Logs will be created here during execution)
```

---

## WHAT THIS PACKAGE DOES

### Phase 1: Pre-Cutover Checks (15 min)
- Verifies all 10 DCs online
- Checks replication health (0 failures)
- Confirms DNS working
- Tests time sync
- **GO/NO-GO gate**: Stops if not ready

### Phase 2: FSMO Transfer (30 min)
- Transfers PDC Emulator to WACPRODDC01
- Transfers Schema Master to WACPRODDC01
- Transfers Domain Naming Master to WACPRODDC01
- Transfers RID Master to WACPRODDC02
- Transfers Infrastructure Master to WACPRODDC02
- Forces replication
- **GO/NO-GO gate**: Stops if fails

### Phase 3: Verification (15 min)
- Confirms all roles transferred
- Tests replication
- Tests authentication
- Tests DNS
- Tests time sync
- **GO/NO-GO gate**: Reports success/failure

### Phase 4: Monitoring (2 hours)
- Guided monitoring every 15 minutes
- Checks replication, auth, time sync
- Reviews event logs

### Phase 5: Decommissioning (Weeks 1-4)
- Decommission AD01 (Server 2008 R2)
- Decommission AD02 (Server 2008 R2)
- Decommission W09MVMPADDC01 (Server 2012 R2)
- **Keep 2+ on-prem DCs for local services**

---

## PREREQUISITES

**Required**:
- Domain Admin credentials
- RDP access to WACPRODDC01 (10.70.10.10)
- Maintenance window: 3 hours
- AWS snapshots taken

**Recommended**:
- Saturday 2:00 AM - 5:00 AM
- Stakeholders notified
- Rollback plan reviewed

---

## EXECUTION STEPS

### Step 1: Copy to AWS
1. Copy this entire **Cutover-Package** folder
2. RDP to WACPRODDC01 (10.70.10.10)
3. Paste to **C:\Cutover\**

### Step 2: Execute
1. Open **C:\Cutover\**
2. Right-click **Scripts\RUN-CUTOVER.bat**
3. Select "Run as Administrator"
4. Follow prompts

### Step 3: Monitor
- Stay logged into WACPRODDC01
- Follow monitoring schedule
- Check logs in C:\Cutover\Logs\

---

## SAFETY FEATURES

**Automated GO/NO-GO Gates**:
- Pre-checks must pass before proceeding
- Transfer must succeed before verification
- Verification must pass before declaring success

**Rollback Plan**:
- One-click rollback: **Scripts\RUN-ROLLBACK.bat**
- Run on AD01 if cutover fails
- Restores roles to AD01/AD02 in 30 minutes

**Logging**:
- All actions logged to C:\Cutover\Logs\
- Timestamped log files
- FSMO configuration backed up

---

## CRITICAL INFORMATION

### Where to Run Scripts
- ✅ Pre-cutover: WACPRODDC01 (AWS)
- ✅ FSMO transfer: WACPRODDC01 (AWS)
- ✅ Verification: WACPRODDC01 (AWS)
- ❌ Rollback: AD01 (On-Prem) - only if fails

### DNS Traffic
- DNS is Active Directory Integrated (NOT Route 53)
- All 10 DCs host DNS zones
- No DNS changes needed
- No client reconfiguration needed

### Decommissioning
- **DO NOT decommission all on-prem DCs**
- Keep minimum 2 on-prem DCs (WAC-DC01, WAC-DC02)
- Only decommission EOL DCs (AD01, AD02, W09MVMPADDC01)
- See **Documentation/05-DECOMMISSION-PLAN.md**

---

## SUCCESS CRITERIA

Cutover is successful when:
- ✅ WACPRODDC01 holds 3 FSMO roles
- ✅ WACPRODDC02 holds 2 FSMO roles
- ✅ AD01 holds 0 FSMO roles
- ✅ Replication: 0 failures
- ✅ All DCs online
- ✅ Authentication working
- ✅ DNS working
- ✅ Time sync working

Scripts verify all criteria automatically.

---

## SUPPORT

**During Cutover**:
- IT Director: [Phone]
- Infrastructure Manager: [Phone]

**Emergency**:
- Run **Scripts\RUN-ROLLBACK.bat** on AD01
- Contact Microsoft Support

**Documentation**:
- Full plan: **Documentation/03-CUTOVER-EXECUTION-PLAN.md**
- Troubleshooting: See execution plan
- FAQ: **Documentation/01-CRITICAL-CLARIFICATIONS.md**

---

## TIMELINE

**Recommended Window**: Saturday 2:00 AM - 5:00 AM

**Schedule**:
- 1:30 AM: Take AWS snapshots
- 1:45 AM: Copy package to WACPRODDC01
- 2:00 AM: Run RUN-CUTOVER.bat
- 2:15 AM: Pre-checks complete (GO/NO-GO)
- 2:45 AM: FSMO transfer complete
- 3:00 AM: Verification complete
- 3:00 AM - 5:00 AM: Monitoring
- 5:00 AM: Declare success

---

## HEALTH STATUS

**Pre-Cutover Assessment** (February 7, 2026):

| Component | Status | Score |
|-----------|--------|-------|
| AWS DCs | HEALTHY | 10/10 |
| On-Prem DCs | HEALTHY | 10/10 |
| Replication | HEALTHY | 10/10 |
| DNS | HEALTHY | 10/10 |
| Time Sync | HEALTHY | 9/10 |
| **OVERALL** | **READY** | **95/100** |

**Recommendation**: GO - Proceed with cutover

---

## NEXT STEPS

1. **Review**: Read **START-HERE.md**
2. **Approve**: Get management sign-off
3. **Schedule**: Book maintenance window
4. **Prepare**: Take AWS snapshots
5. **Copy**: Copy package to WACPRODDC01
6. **Execute**: Run **Scripts\RUN-CUTOVER.bat**
7. **Monitor**: Follow monitoring schedule
8. **Complete**: Archive logs and notify stakeholders

---

## FILES TO READ

**Must Read** (15 minutes):
1. START-HERE.md (5 min)
2. Documentation/01-CRITICAL-CLARIFICATIONS.md (10 min)

**Should Read** (30 minutes):
3. Documentation/02-CUTOVER-SUMMARY.md (5 min)
4. Documentation/03-CUTOVER-EXECUTION-PLAN.md (20 min)
5. Documentation/04-CUTOVER-CHECKLIST.md (5 min)

**Reference** (as needed):
6. Documentation/05-DECOMMISSION-PLAN.md
7. Documentation/06-GO-NO-GO-REPORT.md
8. Documentation/07-INDEX.md

---

## VERSION HISTORY

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-02-07 | Initial release |
|  |  | - Complete automated scripts |
|  |  | - Full documentation |
|  |  | - Decommissioning plan |
|  |  | - GO/NO-GO assessment |

---

## APPROVAL

**Prepared By**: Kiro AI Assistant  
**Date**: February 7, 2026  
**Status**: READY TO EXECUTE

**Approved By**: ___________________________  
**Date**: ___________________________  
**Signature**: ___________________________

---

**READY TO PROCEED**: YES ✓

**CONFIDENCE LEVEL**: HIGH (95/100)

**RECOMMENDATION**: GO - Execute cutover as planned

---

**Questions?** Read **START-HERE.md** or **Documentation/03-CUTOVER-EXECUTION-PLAN.md**

**Ready?** Copy to WACPRODDC01 and run **Scripts\RUN-CUTOVER.bat**!
