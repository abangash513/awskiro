# START HERE - WAC AD CUTOVER

**Welcome!** This is your complete cutover package.

---

## 🚀 QUICK START (3 Steps)

### Step 1: Copy to AWS (5 minutes)
```
1. Copy this entire "Cutover-Package" folder
2. RDP to WACPRODDC01 (10.70.10.10)
3. Paste to C:\Cutover\
4. Verify all files copied
```

### Step 2: Execute (1 hour)
```
1. Open C:\Cutover\Scripts\
2. Right-click RUN-CUTOVER.bat
3. Select "Run as Administrator"
4. Follow prompts (script does everything)
```

### Step 3: Monitor (2 hours)
```
1. Stay logged into WACPRODDC01
2. Follow monitoring schedule
3. Check logs in C:\Cutover\Logs\
```

**Total Time**: 3 hours  
**Your Effort**: 10 minutes (rest is automated)

---

## 📋 WHAT YOU NEED

**Before Starting**:
- [ ] Domain Admin credentials
- [ ] RDP access to WACPRODDC01 (10.70.10.10)
- [ ] 3-hour maintenance window scheduled
- [ ] AWS snapshots taken (WACPRODDC01 and WACPRODDC02)
- [ ] Stakeholders notified

**Nice to Have**:
- [ ] Printed copy of Documentation/04-CUTOVER-CHECKLIST.md
- [ ] RDP access to AD01 (for rollback if needed)
- [ ] Phone numbers for IT Director and Infrastructure Manager

---

## 🎯 WHAT THIS DOES

**Transfers FSMO roles from old on-prem DCs to new AWS DCs**:

**FROM** (On-Prem):
- AD01 (Server 2008 R2) - Holds 3 FSMO roles
- AD02 (Server 2008 R2) - Holds 2 FSMO roles

**TO** (AWS):
- WACPRODDC01 (Server 2019) - Will hold 3 FSMO roles
- WACPRODDC02 (Server 2019) - Will hold 2 FSMO roles

**Impact on Users**: ZERO (transparent, no downtime)

---

## ⚡ EXECUTION FLOW

```
RUN-CUTOVER.bat
    ↓
Phase 1: Pre-Checks (15 min)
    ├─ Check all DCs online
    ├─ Check replication
    ├─ Check DNS
    └─ GO/NO-GO gate → If PASS, continue
    ↓
Phase 2: FSMO Transfer (30 min)
    ├─ Transfer PDC Emulator
    ├─ Transfer Schema Master
    ├─ Transfer Domain Naming Master
    ├─ Transfer RID Master
    ├─ Transfer Infrastructure Master
    └─ GO/NO-GO gate → If SUCCESS, continue
    ↓
Phase 3: Verification (15 min)
    ├─ Verify all roles transferred
    ├─ Test replication
    ├─ Test authentication
    └─ GO/NO-GO gate → If PASS, SUCCESS!
    ↓
Phase 4: Monitoring (2 hours)
    └─ Guided monitoring every 15 minutes
```

---

## ✅ SUCCESS CRITERIA

Script automatically checks:
- ✅ WACPRODDC01 holds 3 FSMO roles
- ✅ WACPRODDC02 holds 2 FSMO roles
- ✅ AD01 holds 0 FSMO roles
- ✅ Replication: 0 failures
- ✅ All DCs online
- ✅ Authentication working
- ✅ DNS working
- ✅ Time sync working

If all pass: **CUTOVER SUCCESSFUL!**

---

## 🛡️ SAFETY FEATURES

**Automated GO/NO-GO Gates**:
- Script stops if prerequisites not met
- Script stops if transfer fails
- Script stops if verification fails

**Rollback Plan**:
- If anything fails: Run **Scripts\RUN-ROLLBACK.bat** on AD01
- Restores roles to AD01/AD02 in 30 minutes
- Fully automated

**Logging**:
- All actions logged to C:\Cutover\Logs\
- Review logs if issues occur

---

## ⚠️ CRITICAL INFORMATION

### Where to Run
- ✅ **Run cutover on**: WACPRODDC01 (AWS)
- ❌ **Run rollback on**: AD01 (On-Prem) - only if fails

### DNS Traffic
- DNS is Active Directory Integrated (NOT Route 53)
- No DNS changes needed
- No client reconfiguration needed
- All DCs continue hosting DNS

### Decommissioning
- **DO NOT decommission all on-prem DCs**
- Only decommission: AD01, AD02, W09MVMPADDC01 (EOL servers)
- **Keep**: WAC-DC01, WAC-DC02 (for local auth/DNS)
- See **Documentation/05-DECOMMISSION-PLAN.md**

---

## 📖 DOCUMENTATION

**Must Read** (15 min):
1. **Documentation/01-CRITICAL-CLARIFICATIONS.md** - Where to run, DNS explained
2. **Documentation/02-CUTOVER-SUMMARY.md** - Executive summary

**Should Read** (30 min):
3. **Documentation/03-CUTOVER-EXECUTION-PLAN.md** - Complete step-by-step
4. **Documentation/04-CUTOVER-CHECKLIST.md** - Print this!

**Reference**:
5. **Documentation/05-DECOMMISSION-PLAN.md** - Post-cutover decommissioning
6. **Documentation/06-GO-NO-GO-REPORT.md** - Health assessment
7. **Documentation/07-INDEX.md** - Master index

---

## 🔧 TROUBLESHOOTING

**If pre-checks fail**:
- Script will tell you what's wrong
- Fix the issue
- Re-run RUN-CUTOVER.bat

**If FSMO transfer fails**:
- Script will stop automatically
- RDP to AD01
- Run **Scripts\RUN-ROLLBACK.bat**
- Investigate issue
- Reschedule cutover

**If verification fails**:
- Review logs in C:\Cutover\Logs\
- Consider running rollback
- Contact support

---

## 📞 SUPPORT

**During Cutover**:
- IT Director: [Phone]
- Infrastructure Manager: [Phone]

**Emergency**:
- Run **Scripts\RUN-ROLLBACK.bat** on AD01
- Contact Microsoft Support

**Documentation**:
- Troubleshooting: **Documentation/03-CUTOVER-EXECUTION-PLAN.md** (search "TROUBLESHOOTING")
- FAQ: **Documentation/01-CRITICAL-CLARIFICATIONS.md**

---

## 📅 RECOMMENDED TIMELINE

**Maintenance Window**: Saturday 2:00 AM - 5:00 AM

**Schedule**:
```
1:30 AM - Take AWS snapshots
1:45 AM - Copy package to WACPRODDC01
2:00 AM - Run RUN-CUTOVER.bat
2:15 AM - Pre-checks complete
2:45 AM - FSMO transfer complete
3:00 AM - Verification complete
3:00 AM - 5:00 AM - Monitoring
5:00 AM - Declare success
```

---

## ✨ WHAT MAKES THIS EASY

**Fully Automated**:
- Just run ONE batch file
- Script does all the work
- No PowerShell knowledge needed

**Novice-Friendly**:
- Clear prompts and instructions
- Color-coded output (green=success, red=error)
- Automatic error detection
- Stops if anything wrong

**Safe**:
- GO/NO-GO gates prevent proceeding with issues
- One-click rollback if needed
- All actions logged
- AWS snapshots for recovery

---

## 🎯 READY TO START?

### Pre-Flight Checklist
- [ ] Read this document (5 min)
- [ ] Read **Documentation/01-CRITICAL-CLARIFICATIONS.md** (10 min)
- [ ] Take AWS snapshots
- [ ] Copy package to WACPRODDC01
- [ ] Verify Domain Admin access
- [ ] Notify stakeholders

### Execute
```
1. RDP to WACPRODDC01 (10.70.10.10)
2. Open C:\Cutover\Scripts\
3. Right-click RUN-CUTOVER.bat
4. Select "Run as Administrator"
5. Follow prompts
```

### Monitor
```
1. Stay logged into WACPRODDC01
2. Check replication every 15 minutes (first hour)
3. Check replication every 30 minutes (second hour)
4. Review logs in C:\Cutover\Logs\
```

---

## 🏆 SUCCESS!

When script shows:
```
========================================
CUTOVER SUCCESSFUL
========================================
```

You're done! Next steps:
1. Monitor for 2 hours (script will guide you)
2. Archive logs
3. Notify stakeholders
4. Schedule decommissioning (weeks 1-4)

---

## 📦 PACKAGE CONTENTS

```
Cutover-Package/
├── README.md
├── START-HERE.md (You are here!)
├── Documentation/ (7 files)
├── Scripts/ (8 files)
└── Reports/ (1 file + logs created during execution)
```

---

## 🚨 REMEMBER

1. **Run on WACPRODDC01** (AWS), not on-prem
2. **Keep 2+ on-prem DCs** after decommissioning
3. **Rollback available** if anything fails
4. **Everything is logged** for review

---

**Questions?** Read **Documentation/03-CUTOVER-EXECUTION-PLAN.md**

**Ready?** Copy to WACPRODDC01 and run **Scripts\RUN-CUTOVER.bat**!

**Good luck!** 🚀
