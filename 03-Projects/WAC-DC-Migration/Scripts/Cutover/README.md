# WAC AD CUTOVER - AUTOMATED SCRIPTS

## QUICK START

**For novice users - Just run this ONE file**:
```
Right-click: RUN-CUTOVER.bat
Select: "Run as Administrator"
```

That's it! The script will:
1. Check if you're ready (15 min)
2. Transfer FSMO roles (30 min)
3. Verify success (15 min)

Total time: ~1 hour

---

## FILES IN THIS FOLDER

**Automated Execution**:
- `RUN-CUTOVER.bat` - Master script (runs all 3 steps)
- `RUN-ROLLBACK.bat` - Emergency rollback (only if cutover fails)

**PowerShell Scripts** (called by batch files):
- `1-PRE-CUTOVER-CHECK.ps1` - Verify readiness
- `2-EXECUTE-CUTOVER.ps1` - Transfer FSMO roles
- `3-POST-CUTOVER-VERIFY.ps1` - Verify success
- `4-ROLLBACK.ps1` - Rollback to AD01/AD02

---

## PREREQUISITES

**Before running**:
1. Copy all files to `C:\Cutover\` on WACPRODDC01
2. Log in as Domain Admin
3. Take AWS snapshots of WACPRODDC01 and WACPRODDC02

**Required access**:
- Domain Admin credentials
- RDP to WACPRODDC01 (10.70.10.10)

---

## STEP-BY-STEP INSTRUCTIONS

### Step 1: Copy Files to WACPRODDC01

On your local machine:
```
1. Open File Explorer
2. Navigate to: 03-Projects\WAC-DC-Migration\Scripts\Cutover\
3. Select all files (Ctrl+A)
4. Copy (Ctrl+C)
```

On WACPRODDC01 (via RDP):
```
1. Create folder: C:\Cutover
2. Paste files (Ctrl+V)
3. Verify all 6 files copied
```

### Step 2: Run Cutover

On WACPRODDC01:
```
1. Open: C:\Cutover
2. Right-click: RUN-CUTOVER.bat
3. Select: "Run as Administrator"
4. Follow prompts
```

### Step 3: Monitor

The script will:
- Show progress in real-time
- Stop if any issues detected
- Create logs in C:\Cutover\Logs\

---

## WHAT IF SOMETHING FAILS?

**If pre-cutover check fails**:
- Script will STOP automatically
- Fix the issue shown
- Re-run RUN-CUTOVER.bat

**If FSMO transfer fails**:
- Script will STOP automatically
- Run RUN-ROLLBACK.bat on AD01
- Investigate issue
- Reschedule cutover

**If verification fails**:
- Review logs in C:\Cutover\Logs\
- Consider running RUN-ROLLBACK.bat
- Contact support if needed

---

## ROLLBACK PROCEDURE

**Only if cutover fails!**

1. RDP to AD01 (10.1.220.8)
2. Copy 4-ROLLBACK.ps1 to C:\Cutover\ on AD01
3. Right-click: RUN-ROLLBACK.bat
4. Select: "Run as Administrator"
5. Type "ROLLBACK" to confirm

Roles will be transferred back to AD01/AD02.

---

## LOGS

All logs saved to: `C:\Cutover\Logs\`

**Log files**:
- PreCutover-YYYYMMDD-HHMMSS.log
- Cutover-YYYYMMDD-HHMMSS.log
- PostCutover-YYYYMMDD-HHMMSS.log
- FSMO-Backup-YYYYMMDD-HHMMSS.txt

Review logs if any issues occur.

---

## SUPPORT

**Documentation**:
- Full plan: `03-Projects/WAC-DC-Migration/CUTOVER-EXECUTION-PLAN.md`
- GO/NO-GO report: `03-Projects/WAC-DC-Migration/Reports/CUTOVER-GO-NO-GO-REPORT.md`

**Troubleshooting**:
- See CUTOVER-EXECUTION-PLAN.md section "TROUBLESHOOTING GUIDE"

**Emergency**:
- Run RUN-ROLLBACK.bat on AD01
- Contact IT Director
- Open Microsoft Support case

---

## SUCCESS CRITERIA

Cutover is successful when:
- WACPRODDC01 holds 3 FSMO roles
- WACPRODDC02 holds 2 FSMO roles
- AD01 holds 0 FSMO roles
- Replication shows 0 failures
- All DCs online
- Authentication working

Script will confirm success automatically.

---

## NEXT STEPS AFTER SUCCESS

1. Monitor for 2 hours (script will guide you)
2. Test user authentication
3. Review event logs
4. Schedule AD01/AD02 decommissioning in 2-4 weeks

---

**Questions?** Review the full execution plan document.

**Ready?** Run RUN-CUTOVER.bat and follow the prompts!
