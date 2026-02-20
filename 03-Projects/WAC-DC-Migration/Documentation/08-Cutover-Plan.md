# Cutover Plan & Post-Cutover Expectations

## What is Cutover?

**Cutover** = The moment AWS becomes the PRIMARY Active Directory infrastructure

**Cutover occurs when:**
1. All FSMO roles move to AWS (WACPRODDC01)
2. Old DCs are decommissioned
3. AWS DCs handle all critical AD operations

---

## Cutover Timeline

### Before Cutover (Current State)
```
PRIMARY: On-Prem DCs (AD01, AD02 hold FSMO roles)
SECONDARY: AWS DCs (WACPRODDC01, WACPRODDC02 are replicas)

Users authenticate to: Closest DC (on-prem or AWS)
FSMO operations go to: On-prem (AD01, AD02)
```

### During Cutover (2-Day Plan)
```
Day 1 Hour 1-6: Moving FSMO roles one by one
Day 1 Hour 7-12: Decommissioning AD01, AD02
Day 2: Decommissioning W09MVMPADDC01
```

### After Cutover (Final State)
```
PRIMARY: AWS DCs (WACPRODDC01 holds all FSMO roles)
SECONDARY: On-prem DCs (replicas for local auth)

Users authenticate to: Closest DC (AWS or on-prem)
FSMO operations go to: AWS (WACPRODDC01)
```

---

## The Critical Moment: Moving PDC Emulator

### Before (10:29 AM)
```
User changes password → Goes to AD01 (on-prem PDC)
Computer authenticates → Uses closest DC
Time sync → From AD01
Group Policy updates → From AD01
```

### During (10:30 AM - 10:32 AM)
```
10:30:00 - Command starts
10:30:15 - AD01 releases PDC role
10:30:30 - WACPRODDC01 assumes PDC role
10:30:45 - Replication propagates to all DCs
10:31:00 - All DCs know WACPRODDC01 is new PDC
10:32:00 - Complete
```

### After (10:33 AM)
```
User changes password → Goes to WACPRODDC01 (AWS PDC) ✅
Computer authenticates → Uses closest DC (no change)
Time sync → From WACPRODDC01 (AWS)
Group Policy updates → From WACPRODDC01 (AWS)
```

---

## What Users Experience

### ✅ What Users WILL Notice
**NOTHING** (if done correctly)

- No logoff required
- No password re-entry
- No application restarts
- No network interruption
- No file share disruption

### ❌ What Users MIGHT Notice (Rare)

**Scenario 1: Password Change During Cutover**
```
User tries to change password at 10:30:15 AM (exact cutover moment)
→ Might get "Domain controller unavailable" for 5-10 seconds
→ Retry succeeds immediately
```

**Scenario 2: Computer Authentication**
```
Computer tries to authenticate at exact cutover moment
→ Might fail first attempt
→ Automatically retries and succeeds
→ User doesn't notice
```

---

## Post-Cutover Expectations

### Immediate (First Hour)

**What's Normal:**
```
✅ Replication traffic spike (10-15 minutes)
✅ Event logs showing FSMO changes
✅ Time sync adjustments across DCs
✅ DNS cache updates
✅ Kerberos ticket renewals
```

**Monitoring Commands:**
```powershell
# Every 15 minutes for first hour
repadmin /replsummary
netdom query fsmo
Get-EventLog -LogName "Directory Service" -Newest 20 | Where-Object {$_.EntryType -eq "Error"}
```

**Expected Metrics:**
- Replication latency: 2-5 minutes (normal)
- Authentication success rate: 99.9%+
- LDAP query response time: <100ms
- No failed logins

---

### First 24 Hours

**What's Normal:**
```
✅ Gradual shift of authentication to AWS DCs
✅ DNS records propagating
✅ Kerberos tickets renewing with AWS DCs
✅ Group Policy updates from AWS
✅ Time sync stabilizing
```

**Monitoring Schedule:**
- Hour 1: Every 15 minutes
- Hours 2-8: Every hour
- Hours 9-24: Every 4 hours

---

### First Week

**What's Normal:**
```
✅ AWS DCs handling 50-70% of authentication
✅ On-prem DCs handling local authentication
✅ All FSMO operations going to AWS
✅ Replication stable and healthy
✅ No user complaints
```

**Daily Checks:**
```powershell
repadmin /replsummary
dcdiag /test:replications
Get-ADReplicationFailure -Target * -Scope Domain
```

---

## Potential Issues & Solutions

### Issue 1: VPN Failure During Cutover

**Symptom:**
```
On-prem users can't authenticate
"Domain controller unavailable" errors
```

**Impact:**
- On-prem users: Can't login (cached credentials work)
- AWS workloads: Unaffected
- Duration: Until VPN restored

**Solution:**
```powershell
# If VPN can't be restored quickly:
# Move PDC role back to on-prem temporarily
Move-ADDirectoryServerOperationMasterRole -Identity WACHFDC01 -OperationMasterRole PDCEmulator -Force

# Fix VPN
# Re-attempt cutover
```

---

### Issue 2: Replication Failures

**Symptom:**
```
repadmin /replsummary shows failures
Event ID 2042: Replication errors
```

**Solution:**
```powershell
# Force replication
repadmin /syncall /AdeP

# Check replication topology
repadmin /showrepl

# Rebuild replication links if needed
repadmin /kcc
```

---

### Issue 3: Authentication Slowness

**Symptom:**
```
Users report slow logins
Applications timeout connecting to AD
```

**Solution:**
```
1. Check VPN latency (should be <50ms)
2. Verify DNS pointing to correct DCs
3. Check LDAP query performance
4. Verify site links configured correctly
```

---

### Issue 4: Time Sync Issues

**Symptom:**
```
Kerberos authentication failures
"Time skew too great" errors
```

**Solution:**
```powershell
# On all DCs
w32tm /resync /rediscover

# Verify time source
w32tm /query /status

# Check time difference
w32tm /stripchart /computer:WACPRODDC01
```

---

## Success Indicators

### Day 1 (Cutover Day)
```
✅ All FSMO roles on WACPRODDC01
✅ 0 replication failures
✅ 0 authentication failures
✅ 0 user complaints
✅ All applications working
✅ Event logs clean
```

### Week 1
```
✅ Replication stable
✅ Authentication load balanced
✅ No VPN issues
✅ No application issues
✅ Team comfortable with new setup
```

### Month 1
```
✅ AWS DCs fully operational
✅ On-prem DCs as backup
✅ All metrics normal
✅ No incidents
✅ Ready for next phase
```

---

## Rollback Scenarios

### Critical Issue During Cutover

**When to Rollback:**
- Multiple authentication failures
- VPN complete failure
- Replication broken
- Critical application down

**How to Rollback:**
```powershell
# Move FSMO roles back to on-prem
Move-ADDirectoryServerOperationMasterRole -Identity AD01 -OperationMasterRole PDCEmulator -Force
Move-ADDirectoryServerOperationMasterRole -Identity AD01 -OperationMasterRole SchemaMaster -Force
Move-ADDirectoryServerOperationMasterRole -Identity AD01 -OperationMasterRole DomainNamingMaster -Force
Move-ADDirectoryServerOperationMasterRole -Identity AD02 -OperationMasterRole RIDMaster -Force
Move-ADDirectoryServerOperationMasterRole -Identity AD02 -OperationMasterRole InfrastructureMaster -Force

# Force replication
repadmin /syncall /AdeP
```

**Time to Rollback:** 10-15 minutes

---

## Communication Plan

### Before Cutover (Day -1)
```
Subject: AD Cutover Tomorrow - What to Expect

Tomorrow we migrate AD to AWS.
Expected impact: NONE for users
Time: 8 AM - 4 PM
What to do: Nothing, work normally
If issues: Contact [your info]
```

### During Cutover (Real-time)
```
8:00 AM - "Cutover started"
10:30 AM - "PDC role moved to AWS (critical moment)"
12:00 PM - "FSMO migration complete"
3:00 PM - "Decommissioning old DCs"
4:00 PM - "Cutover complete, monitoring"
```

### After Cutover (Day +1)
```
Subject: AD Cutover Complete - Success

✅ All FSMO roles now on AWS
✅ Old DCs decommissioned
✅ 0 issues reported
✅ All systems operational

Monitoring continues for 1 week.
```

---

## What Success Looks Like

**Perfect Cutover:**
```
- Users don't notice anything
- No help desk tickets
- No application errors
- Replication healthy
- Event logs clean
- Team confident
```

**Realistic Cutover:**
```
- 1-2 users report brief slowness (5 seconds)
- 1-2 monitoring alerts (informational)
- Minor replication delay (2-3 minutes)
- All resolved within 1 hour
- No lasting impact
```

---

## Final Checklist

### Before Cutover
- [ ] Both AWS DCs healthy for 2+ weeks
- [ ] VPN both tunnels UP
- [ ] Backups completed
- [ ] Rollback plan ready
- [ ] Team on standby
- [ ] Stakeholders notified

### During Cutover
- [ ] Monitor every 15 minutes
- [ ] Check replication after each FSMO move
- [ ] Verify authentication working
- [ ] Watch event logs
- [ ] Test applications

### After Cutover
- [ ] All FSMO roles on AWS
- [ ] 0 replication failures
- [ ] 0 authentication issues
- [ ] Documentation updated
- [ ] Team debriefed

---

**Bottom Line:** Cutover should be **boring and uneventful**. If users notice, something went wrong!

---

**Last Updated:** 2025-11-24
