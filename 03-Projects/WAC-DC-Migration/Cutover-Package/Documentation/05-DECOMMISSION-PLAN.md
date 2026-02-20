# DECOMMISSIONING ALL ON-PREM DCs - CRITICAL ANALYSIS

**Date**: February 7, 2026  
**Question**: What happens when we decommission ALL on-premises domain controllers?  
**Answer**: MAJOR IMPACT - Requires careful planning

---

## CURRENT STATE

**Total DCs**: 10
- **AWS**: 2 DCs (WACPRODDC01, WACPRODDC02)
- **On-Prem**: 8 DCs (AD01, AD02, W09MVMPADDC01, W09MVMPADDC02, WACHFDC01, WACHFDC02, WAC-DC01, WAC-DC02)

**After FSMO Transfer**:
- AWS DCs hold all 5 FSMO roles
- On-prem DCs are replica DCs (no FSMO roles)

---

## SCENARIO: DECOMMISSION ALL 8 ON-PREM DCs

### What Would Remain
- **Only 2 DCs**: WACPRODDC01 and WACPRODDC02 (both in AWS)
- **All services**: Authentication, DNS, LDAP, Kerberos, Group Policy

### CRITICAL IMPACTS

---

## IMPACT 1: ON-PREM USERS LOSE LOCAL AUTHENTICATION

### Problem
**On-premises users and computers would authenticate over VPN/Direct Connect to AWS**

**Current Flow** (with on-prem DCs):
```
On-Prem User → Nearest On-Prem DC (local network)
   ↓
Fast authentication (< 50ms)
```

**After Removing All On-Prem DCs**:
```
On-Prem User → VPN/Direct Connect → AWS DC
   ↓
Slow authentication (100-500ms depending on connection)
```

### Consequences
- **Slower logins** for on-prem users (2-10x slower)
- **VPN dependency** - If VPN/Direct Connect fails, NO authentication
- **Increased latency** for all AD operations
- **Network bandwidth** - All AD traffic goes over WAN link

### Risk Level: **HIGH**

---

## IMPACT 2: ON-PREM DNS RESOLUTION FAILS

### Problem
**On-premises clients would lose local DNS servers**

**Current Setup**:
- On-prem clients use on-prem DCs for DNS (10.1.220.8, 10.1.220.9, etc.)
- Fast DNS resolution (< 10ms)
- Local DNS cache

**After Removing All On-Prem DCs**:
```
On-Prem Client → VPN/Direct Connect → AWS DC for DNS
   ↓
Slow DNS resolution (50-200ms per query)
```

### Consequences
- **Every DNS query** goes over WAN link
- **Slow application performance** (DNS lookups for every connection)
- **VPN dependency** - If VPN fails, NO DNS resolution
- **Client reconfiguration** - Must update DNS settings on ALL clients

### Required Actions
1. Update DHCP to point to AWS DCs (10.70.10.10, 10.70.11.10)
2. Manually update static IP clients
3. Update router/firewall DNS forwarders
4. Test DNS resolution from on-prem

### Risk Level: **HIGH**

---

## IMPACT 3: SINGLE POINT OF FAILURE

### Problem
**Only 2 DCs for entire domain**

**Current Redundancy**:
- 10 DCs across 2 locations (on-prem + AWS)
- If AWS fails: On-prem DCs continue working
- If on-prem fails: AWS DCs continue working

**After Removing All On-Prem DCs**:
- 2 DCs in single location (AWS)
- If AWS region fails: **ENTIRE DOMAIN DOWN**
- If both AWS DCs fail: **ENTIRE DOMAIN DOWN**

### Consequences
- **No geographic redundancy**
- **AWS dependency** - 100% reliant on AWS availability
- **Disaster recovery** - Longer recovery time
- **Business continuity** - Higher risk

### Risk Level: **CRITICAL**

---

## IMPACT 4: ON-PREM APPLICATIONS BREAK

### Problem
**Applications hardcoded to on-prem DC IPs or hostnames**

**Common Issues**:
- Applications with hardcoded DC IPs (10.1.220.8, 10.1.220.9)
- LDAP queries to specific DCs
- Kerberos SPNs pointing to on-prem DCs
- Monitoring systems expecting on-prem DCs
- Backup systems authenticating to on-prem DCs
- Scripts with hardcoded DC names

### Consequences
- **Application failures** until reconfigured
- **Service outages** for dependent systems
- **Manual remediation** for each application

### Required Actions
1. Inventory all applications using AD
2. Identify hardcoded DC references
3. Update configurations to use AWS DCs
4. Test each application

### Risk Level: **HIGH**

---

## IMPACT 5: NETWORK BANDWIDTH INCREASE

### Problem
**All AD traffic flows over VPN/Direct Connect**

**Current Traffic Distribution**:
- On-prem clients → On-prem DCs (local network, no WAN usage)
- AWS clients → AWS DCs (local network, no WAN usage)
- Only replication traffic crosses WAN

**After Removing All On-Prem DCs**:
- On-prem clients → AWS DCs (ALL traffic over WAN)
- Authentication, DNS, LDAP, Group Policy, etc.
- Continuous traffic (not just replication)

### Bandwidth Requirements
**Typical AD traffic per user**:
- Login: 1-5 MB
- Group Policy refresh: 0.5-2 MB every 90 minutes
- DNS queries: 100-500 KB per day
- LDAP queries: Variable (depends on applications)

**Example**: 100 on-prem users
- Daily traffic: 100-500 MB per day
- Peak traffic: 50-100 Mbps during login storms (8-9 AM)

### Consequences
- **Increased WAN costs** (if metered)
- **Slower performance** during peak times
- **VPN capacity** may need upgrade
- **Direct Connect** may need higher bandwidth

### Risk Level: **MEDIUM**

---

## IMPACT 6: SITE TOPOLOGY CHANGES

### Problem
**Active Directory Sites and Services needs reconfiguration**

**Current Setup**:
- Default-First-Site-Name (all DCs in one site)
- No site links configured
- No site-aware authentication

**After Removing All On-Prem DCs**:
- Should create separate sites for on-prem and AWS
- Configure site links with costs
- Enable site-aware authentication

### Required Actions
1. Create "OnPrem" site
2. Create "AWS" site  
3. Create site link between them
4. Configure site link cost and replication schedule
5. Move subnets to appropriate sites
6. Test site-aware authentication

### Risk Level: **MEDIUM**

---

## IMPACT 7: DISASTER RECOVERY COMPLEXITY

### Problem
**Harder to recover from AWS outage**

**Current DR**:
- If AWS fails: On-prem DCs continue serving users
- If on-prem fails: AWS DCs continue serving users
- Easy failover (automatic)

**After Removing All On-Prem DCs**:
- If AWS fails: **NO DCs available**
- Must restore from backup or rebuild
- Longer recovery time (hours vs minutes)
- More complex DR procedures

### Consequences
- **Higher RTO** (Recovery Time Objective)
- **Higher RPO** (Recovery Point Objective)
- **More expensive DR** (need standby DCs in another region)

### Risk Level: **HIGH**

---

## RECOMMENDED APPROACH

### OPTION 1: Keep Minimum On-Prem DCs (RECOMMENDED)

**Keep**: 2-4 on-prem DCs for local authentication and DNS

**Recommended DCs to Keep**:
1. **WAC-DC01** (Server 2022) - Primary on-prem DC
2. **WAC-DC02** (Server 2022) - Secondary on-prem DC
3. **WACHFDC01** (Server 2019) - Optional tertiary
4. **WACHFDC02** (Server 2019) - Optional quaternary

**Decommission**:
- AD01 (Server 2008 R2) - EOL
- AD02 (Server 2008 R2) - EOL
- W09MVMPADDC01 (Server 2012 R2) - Older
- W09MVMPADDC02 (Server 2016) - Optional

**Result**: 4-6 DCs total (2 AWS + 2-4 on-prem)

**Benefits**:
- ✅ Local authentication for on-prem users
- ✅ Local DNS resolution
- ✅ Geographic redundancy
- ✅ No client reconfiguration needed
- ✅ Lower WAN bandwidth usage
- ✅ Better disaster recovery

**Drawbacks**:
- ❌ Must maintain on-prem DCs
- ❌ Higher infrastructure costs

---

### OPTION 2: Decommission All On-Prem DCs (HIGH RISK)

**Only if**:
- All users are in AWS (no on-prem users)
- All applications are in AWS
- No on-prem infrastructure remaining
- Acceptable to lose geographic redundancy
- VPN/Direct Connect is highly reliable

**Required Actions**:
1. **Migrate all users to AWS** (VDI, WorkSpaces, etc.)
2. **Migrate all applications to AWS**
3. **Update all DNS configurations**
4. **Reconfigure DHCP**
5. **Update firewall rules**
6. **Test extensively**
7. **Plan for AWS region failure**
8. **Consider multi-region AWS DCs**

**Timeline**: 6-12 months (not 2-4 weeks)

**Benefits**:
- ✅ No on-prem infrastructure
- ✅ Lower maintenance costs
- ✅ Simplified management

**Drawbacks**:
- ❌ Single point of failure (AWS)
- ❌ Slower for on-prem users (if any remain)
- ❌ Higher WAN bandwidth usage
- ❌ Complex migration
- ❌ Higher risk

---

### OPTION 3: Hybrid Approach (BALANCED)

**Phase 1** (Weeks 1-4): Decommission EOL DCs
- Remove AD01, AD02 (Server 2008 R2)
- Remove W09MVMPADDC01 (Server 2012 R2)
- Keep 7 DCs (2 AWS + 5 on-prem)

**Phase 2** (Months 2-6): Assess on-prem usage
- Monitor on-prem authentication traffic
- Identify on-prem applications
- Plan application migrations

**Phase 3** (Months 6-12): Gradual decommissioning
- Migrate applications to AWS
- Reduce on-prem DCs one at a time
- Keep minimum 2 on-prem DCs for redundancy

**Phase 4** (Year 2+): Final decision
- If all users/apps in AWS: Remove remaining on-prem DCs
- If on-prem presence remains: Keep 2 on-prem DCs

---

## DECISION MATRIX

| Scenario | On-Prem Users | On-Prem Apps | Recommended DCs | Risk |
|----------|---------------|--------------|-----------------|------|
| All in AWS | 0 | 0 | 2 AWS only | Medium |
| Some on-prem | 1-50 | Few | 2 AWS + 2 on-prem | Low |
| Many on-prem | 50+ | Many | 2 AWS + 4 on-prem | Low |
| Hybrid | Mixed | Mixed | 2 AWS + 2-4 on-prem | Low |

---

## CRITICAL QUESTIONS TO ANSWER

Before decommissioning all on-prem DCs, answer these:

1. **How many on-premises users do you have?**
   - If > 0: Keep on-prem DCs

2. **How many on-premises applications use AD?**
   - If > 0: Keep on-prem DCs

3. **What is your VPN/Direct Connect reliability?**
   - If < 99.9%: Keep on-prem DCs

4. **Do you have a disaster recovery plan for AWS region failure?**
   - If No: Keep on-prem DCs

5. **Can you tolerate slower authentication for on-prem users?**
   - If No: Keep on-prem DCs

6. **What is your budget for WAN bandwidth?**
   - If Limited: Keep on-prem DCs

7. **Do you plan to close on-prem data center?**
   - If No: Keep on-prem DCs
   - If Yes: Plan 6-12 month migration

---

## RECOMMENDED DECOMMISSIONING PLAN

### Phase 1: Immediate (Weeks 1-4)
**Decommission EOL DCs only**:
- ❌ AD01 (Server 2008 R2) - EOL, security risk
- ❌ AD02 (Server 2008 R2) - EOL, security risk
- ❌ W09MVMPADDC01 (Server 2012 R2) - Older OS

**Keep**:
- ✅ WACPRODDC01 (AWS) - FSMO holder
- ✅ WACPRODDC02 (AWS) - FSMO holder
- ✅ W09MVMPADDC02 (On-prem) - Server 2016
- ✅ WACHFDC01 (On-prem) - Server 2019
- ✅ WACHFDC02 (On-prem) - Server 2019
- ✅ WAC-DC01 (On-prem) - Server 2022
- ✅ WAC-DC02 (On-prem) - Server 2022

**Result**: 7 DCs (2 AWS + 5 on-prem)

---

### Phase 2: Assessment (Months 2-3)
**Monitor and analyze**:
- Track on-prem authentication traffic
- Identify applications using on-prem DCs
- Measure WAN bandwidth usage
- Review disaster recovery requirements
- Assess business continuity needs

---

### Phase 3: Optional Reduction (Months 4-6)
**If assessment shows low on-prem usage**:
- ❌ W09MVMPADDC02 (Server 2016) - Optional removal
- ❌ WACHFDC01 or WACHFDC02 - Optional removal

**Keep minimum**:
- ✅ WACPRODDC01 (AWS)
- ✅ WACPRODDC02 (AWS)
- ✅ WAC-DC01 (On-prem) - Newest, Server 2022
- ✅ WAC-DC02 (On-prem) - Newest, Server 2022

**Result**: 4 DCs (2 AWS + 2 on-prem) - RECOMMENDED MINIMUM

---

## FINAL RECOMMENDATION

**DO NOT decommission all on-prem DCs unless**:
1. You have ZERO on-premises users
2. You have ZERO on-premises applications
3. You have multi-region AWS DCs for redundancy
4. You have completed a full migration plan

**RECOMMENDED FINAL STATE**:
- **2 AWS DCs**: WACPRODDC01, WACPRODDC02 (hold FSMO roles)
- **2 On-Prem DCs**: WAC-DC01, WAC-DC02 (local auth/DNS)
- **Total**: 4 DCs (minimum for production)

**Benefits of keeping 2 on-prem DCs**:
- Local authentication for on-prem users
- Local DNS resolution
- Geographic redundancy
- Disaster recovery capability
- No client reconfiguration
- Lower WAN bandwidth
- Better user experience

---

## SUMMARY

| Question | Answer |
|----------|--------|
| Can we decommission all on-prem DCs? | Technically yes, but NOT recommended |
| What happens to on-prem users? | Slower authentication over WAN |
| What happens to DNS? | Must reconfigure all clients |
| What about redundancy? | Lost - single point of failure |
| What about disaster recovery? | More complex, longer RTO |
| Recommended approach? | Keep 2 on-prem DCs minimum |
| When to remove all on-prem DCs? | Only after full AWS migration (6-12 months) |

---

**CRITICAL**: Do NOT decommission all on-prem DCs immediately after FSMO transfer. Keep minimum 2 on-prem DCs for local services and redundancy.
