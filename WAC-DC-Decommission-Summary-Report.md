# WAC Domain Controller Decommission Summary Report
## On-Premises Server Decommissioning Plan

**Report Date**: February 8, 2026  
**Project**: WAC DC Migration to AWS  
**Status**: Post-FSMO Transfer Planning  
**Classification**: Internal Use

---

## Executive Summary

This report provides a comprehensive analysis of the on-premises domain controllers that need to be decommissioned following the successful migration of FSMO roles to AWS. The decommissioning will be executed in phases to minimize risk and maintain business continuity.

**Key Findings**:
- **Total DCs**: 10 (2 AWS + 8 On-Premises)
- **Immediate Decommission**: 3 servers (EOL/Older OS)
- **Keep for Operations**: 2-5 servers (Modern OS, local services)
- **Timeline**: 4-6 weeks for Phase 1, ongoing assessment for Phase 2

---

## Current Environment Overview

### All Domain Controllers (10 Total)

#### AWS Domain Controllers (2)
| Server Name | OS Version | IP Address | Location | FSMO Roles | Status |
|-------------|------------|------------|----------|------------|--------|
| WACPRODDC01 | Server 2019 | 10.70.10.10 | AWS us-west-2 | PDC Emulator, Schema Master, Domain Naming Master | ✅ Active |
| WACPRODDC02 | Server 2019 | 10.70.11.10 | AWS us-west-2 | RID Master, Infrastructure Master | ✅ Active |

#### On-Premises Domain Controllers (8)
| Server Name | OS Version | IP Address | Location | FSMO Roles | Decommission Priority |
|-------------|------------|------------|----------|------------|----------------------|
| AD01 | Server 2008 R2 | 10.1.220.8 | On-Prem | None (transferred) | 🔴 HIGH - Week 1 |
| AD02 | Server 2008 R2 | 10.1.220.9 | On-Prem | None (transferred) | 🔴 HIGH - Week 2 |
| W09MVMPADDC01 | Server 2012 R2 | Unknown | On-Prem | None | 🟡 MEDIUM - Week 3 |
| W09MVMPADDC02 | Server 2016 | Unknown | On-Prem | None | 🟢 LOW - Optional |
| WACHFDC01 | Server 2019 | 10.1.220.5 | On-Prem | None | 🟢 LOW - Keep |
| WACHFDC02 | Server 2019 | Unknown | On-Prem | None | 🟢 LOW - Keep |
| WAC-DC01 | Server 2022 | Unknown | On-Prem | None | ✅ KEEP - Primary |
| WAC-DC02 | Server 2022 | Unknown | On-Prem | None | ✅ KEEP - Primary |

---


## Decommissioning Strategy

### Phase 1: Immediate Decommission (Weeks 1-4)
**Target**: End-of-Life and Older Operating Systems

#### Priority 1: AD01 (Week 1)
**Server Details**:
- **Name**: AD01
- **OS**: Windows Server 2008 R2 (END OF LIFE)
- **IP**: 10.1.220.8
- **Previous FSMO Roles**: PDC Emulator, Schema Master, Domain Naming Master (transferred to WACPRODDC01)
- **Current Role**: Replica DC only

**Decommission Reason**:
- ❌ End of Life (EOL) - No security updates since January 2020
- ❌ Security risk - Vulnerable to exploits
- ❌ No FSMO roles after migration
- ❌ Outdated OS (14+ years old)

**Impact**: LOW
- 9 DCs remain after decommission
- No FSMO roles to transfer
- DNS and authentication services available on other DCs

**Dependencies**:
- Primary DNS server for many on-prem clients (10.1.220.8)
- Must update DHCP and client DNS settings before decommission

---

#### Priority 2: AD02 (Week 2)
**Server Details**:
- **Name**: AD02
- **OS**: Windows Server 2008 R2 (END OF LIFE)
- **IP**: 10.1.220.9
- **Previous FSMO Roles**: RID Master, Infrastructure Master (transferred to WACPRODDC02)
- **Current Role**: Replica DC only

**Decommission Reason**:
- ❌ End of Life (EOL) - No security updates since January 2020
- ❌ Security risk - Vulnerable to exploits
- ❌ No FSMO roles after migration
- ❌ Outdated OS (14+ years old)

**Impact**: LOW
- 8 DCs remain after decommission
- No FSMO roles to transfer
- DNS and authentication services available on other DCs

**Dependencies**:
- Secondary DNS server for many on-prem clients (10.1.220.9)
- Must update DHCP and client DNS settings before decommission

---

#### Priority 3: W09MVMPADDC01 (Week 3-4)
**Server Details**:
- **Name**: W09MVMPADDC01
- **OS**: Windows Server 2012 R2 (Mainstream support ended 2018)
- **IP**: Unknown (needs verification)
- **FSMO Roles**: None
- **Current Role**: Replica DC only

**Decommission Reason**:
- ⚠️ Older OS - Extended support ends October 2023
- ⚠️ Can be replaced by newer DCs
- ✅ No FSMO roles
- ✅ Newer DCs available (Server 2019, 2022)

**Impact**: LOW
- 7 DCs remain after decommission
- Sufficient redundancy with remaining DCs

**Dependencies**:
- Verify no applications hardcoded to this DC
- Check DNS client configurations

---

### Phase 2: Assessment & Optional Decommission (Months 2-6)
**Target**: Evaluate remaining on-prem DCs based on usage

#### Optional Decommission: W09MVMPADDC02
**Server Details**:
- **Name**: W09MVMPADDC02
- **OS**: Windows Server 2016
- **IP**: Unknown (needs verification)
- **FSMO Roles**: None
- **Current Role**: Replica DC only

**Decommission Decision**: CONDITIONAL
- ✅ Modern OS (supported until 2027)
- ⚠️ May be redundant if other DCs sufficient
- 📊 Requires usage assessment

**Assessment Criteria**:
- Monitor authentication traffic
- Check application dependencies
- Evaluate WAN bandwidth usage
- Review disaster recovery requirements

**Impact**: MEDIUM
- 6 DCs remain if decommissioned
- Still adequate redundancy

---

### Phase 3: Keep for Operations (Permanent)
**Target**: Modern DCs for local services and redundancy

#### Keep: WAC-DC01 (Primary On-Prem DC)
**Server Details**:
- **Name**: WAC-DC01
- **OS**: Windows Server 2022 (Latest, supported until 2031)
- **IP**: Unknown (needs verification)
- **FSMO Roles**: None
- **Current Role**: Replica DC, Local authentication, DNS

**Keep Reason**:
- ✅ Newest OS (Server 2022)
- ✅ Long-term support (until 2031)
- ✅ Local authentication for on-prem users
- ✅ Local DNS resolution
- ✅ Geographic redundancy
- ✅ Disaster recovery capability

**Services Provided**:
- Local authentication (< 50ms latency)
- Local DNS resolution (< 10ms latency)
- LDAP queries
- Kerberos authentication
- Group Policy distribution

---

#### Keep: WAC-DC02 (Secondary On-Prem DC)
**Server Details**:
- **Name**: WAC-DC02
- **OS**: Windows Server 2022 (Latest, supported until 2031)
- **IP**: Unknown (needs verification)
- **FSMO Roles**: None
- **Current Role**: Replica DC, Local authentication, DNS

**Keep Reason**:
- ✅ Newest OS (Server 2022)
- ✅ Long-term support (until 2031)
- ✅ Redundancy for WAC-DC01
- ✅ High availability for on-prem services
- ✅ Load balancing for authentication

**Services Provided**:
- Redundant local authentication
- Redundant local DNS resolution
- Failover for WAC-DC01
- Load distribution

---

#### Optional Keep: WACHFDC01
**Server Details**:
- **Name**: WACHFDC01
- **OS**: Windows Server 2019 (Supported until 2029)
- **IP**: 10.1.220.5
- **FSMO Roles**: None
- **Current Role**: Replica DC, DNS server

**Keep Decision**: OPTIONAL
- ✅ Modern OS (Server 2019)
- ✅ Currently used as DNS server
- ⚠️ May be redundant with WAC-DC01/02

**Assessment Needed**:
- Check if clients use 10.1.220.5 for DNS
- Evaluate authentication load
- Consider cost vs. benefit

---

#### Optional Keep: WACHFDC02
**Server Details**:
- **Name**: WACHFDC02
- **OS**: Windows Server 2019 (Supported until 2029)
- **IP**: Unknown (needs verification)
- **FSMO Roles**: None
- **Current Role**: Replica DC

**Keep Decision**: OPTIONAL
- ✅ Modern OS (Server 2019)
- ⚠️ May be redundant with other DCs

**Assessment Needed**:
- Check authentication load
- Evaluate cost vs. benefit
- Consider decommissioning if usage is low

---

## Decommissioning Order & Timeline

### Week 1: AD01 Decommission
**Day 1-2: Pre-Decommission**
1. ✅ Verify FSMO roles transferred (already complete)
2. ✅ Verify AD replication healthy
3. ✅ Document current DNS client configurations
4. ✅ Identify applications using AD01 (10.1.220.8)
5. ✅ Create backup/snapshot

**Day 3-4: DNS Migration**
1. Update DHCP scope to remove 10.1.220.8 from DNS servers
2. Update static IP clients to use alternative DNS servers:
   - Primary: 10.1.220.5 (WACHFDC01) or WAC-DC01
   - Secondary: 10.70.10.10 (WACPRODDC01)
3. Verify DNS resolution working
4. Monitor for 24-48 hours

**Day 5: Demotion**
1. Run dcpromo on AD01 to demote from DC
2. Verify demotion successful
3. Remove from DNS records
4. Clean up AD metadata (if needed)

**Day 6-7: Verification**
1. Verify AD replication healthy
2. Verify no authentication failures
3. Verify DNS resolution working
4. Monitor for issues

---

### Week 2: AD02 Decommission
**Day 1-2: Pre-Decommission**
1. ✅ Verify FSMO roles transferred (already complete)
2. ✅ Verify AD replication healthy
3. ✅ Document current DNS client configurations
4. ✅ Identify applications using AD02 (10.1.220.9)
5. ✅ Create backup/snapshot

**Day 3-4: DNS Migration**
1. Update DHCP scope to remove 10.1.220.9 from DNS servers
2. Update static IP clients to use alternative DNS servers
3. Verify DNS resolution working
4. Monitor for 24-48 hours

**Day 5: Demotion**
1. Run dcpromo on AD02 to demote from DC
2. Verify demotion successful
3. Remove from DNS records
4. Clean up AD metadata (if needed)

**Day 6-7: Verification**
1. Verify AD replication healthy
2. Verify no authentication failures
3. Verify DNS resolution working
4. Monitor for issues

---

### Week 3-4: W09MVMPADDC01 Decommission
**Day 1-2: Pre-Decommission**
1. Verify AD replication healthy
2. Identify applications using W09MVMPADDC01
3. Document DNS client configurations
4. Create backup/snapshot

**Day 3-4: Application Migration**
1. Update applications to use alternative DCs
2. Test application connectivity
3. Monitor for 24-48 hours

**Day 5: Demotion**
1. Run dcpromo to demote from DC
2. Verify demotion successful
3. Remove from DNS records
4. Clean up AD metadata (if needed)

**Day 6-7: Verification**
1. Verify AD replication healthy
2. Verify no authentication failures
3. Monitor for issues

---

## Post-Decommission Environment

### Final State After Phase 1 (Week 4)
**Total DCs**: 7 (2 AWS + 5 On-Prem)

**AWS DCs**:
- ✅ WACPRODDC01 (Server 2019) - FSMO holder
- ✅ WACPRODDC02 (Server 2019) - FSMO holder

**On-Prem DCs**:
- ✅ WAC-DC01 (Server 2022) - Primary local DC
- ✅ WAC-DC02 (Server 2022) - Secondary local DC
- ✅ WACHFDC01 (Server 2019) - Optional
- ✅ WACHFDC02 (Server 2019) - Optional
- ✅ W09MVMPADDC02 (Server 2016) - Optional

---

### Recommended Minimum State (Long-Term)
**Total DCs**: 4 (2 AWS + 2 On-Prem)

**AWS DCs**:
- ✅ WACPRODDC01 (Server 2019) - FSMO holder
- ✅ WACPRODDC02 (Server 2019) - FSMO holder

**On-Prem DCs**:
- ✅ WAC-DC01 (Server 2022) - Primary local DC
- ✅ WAC-DC02 (Server 2022) - Secondary local DC

**Benefits**:
- Modern OS on all DCs (Server 2019, 2022)
- Long-term support (until 2029-2031)
- Geographic redundancy (AWS + On-Prem)
- Local authentication for on-prem users
- Local DNS resolution
- Disaster recovery capability

---

## Decommission Procedures

### Standard DC Demotion Process

#### Step 1: Pre-Demotion Checks
```powershell
# Run on DC to be decommissioned

# Check FSMO roles (should be 0)
netdom query fsmo

# Check replication health
repadmin /replsummary

# Check for errors
dcdiag /v

# List all DCs
Get-ADDomainController -Filter *

# Check DNS records
nslookup wac.net
```

#### Step 2: Transfer Any Remaining Roles
```powershell
# If DC still holds FSMO roles (shouldn't after migration)
# Transfer to WACPRODDC01 or WACPRODDC02

Move-ADDirectoryServerOperationMasterRole -Identity WACPRODDC01 `
  -OperationMasterRole PDCEmulator,RIDMaster,InfrastructureMaster,SchemaMaster,DomainNamingMaster
```

#### Step 3: Demote DC
```powershell
# Option 1: GUI Method
# Run: dcpromo
# Follow wizard to demote

# Option 2: PowerShell Method (Server 2012+)
Uninstall-ADDSDomainController -DemoteOperationMasterRole -RemoveApplicationPartitions

# For last DC in domain (NOT our case):
# Uninstall-ADDSDomainController -LastDomainControllerInDomain
```

#### Step 4: Clean Up DNS
```powershell
# Run on remaining DC (e.g., WACPRODDC01)

# Remove DNS records for decommissioned DC
# Check DNS zones
Get-DnsServerZone

# Remove A records
Remove-DnsServerResourceRecord -ZoneName "wac.net" -Name "AD01" -RRType A

# Remove SRV records
Get-DnsServerResourceRecord -ZoneName "_msdcs.wac.net" | Where-Object {$_.RecordData.DomainName -like "*AD01*"}
```

#### Step 5: Clean Up AD Metadata (If Needed)
```powershell
# Only if demotion failed or DC is offline

# Run on remaining DC
ntdsutil
metadata cleanup
connections
connect to server WACPRODDC01
quit
select operation target
list sites
select site 0
list servers in site
select server <number>
remove selected server
quit
quit
```

#### Step 6: Remove from DHCP
```powershell
# Update DHCP scope options
# Remove decommissioned DC IP from DNS server list

Set-DhcpServerv4OptionValue -ScopeId <scope-id> -DnsServer <new-dns-ips>
```

#### Step 7: Verification
```powershell
# Run on remaining DCs

# Verify replication
repadmin /replsummary

# Verify FSMO roles
netdom query fsmo

# Verify DNS
nslookup wac.net

# Check for errors
dcdiag /v

# Verify client authentication
# Test from client workstation
nltest /dsgetdc:wac.net
```

---

## Risk Assessment & Mitigation

### High-Risk Items

#### Risk 1: DNS Resolution Failures
**Probability**: MEDIUM  
**Impact**: HIGH  
**Mitigation**:
- Update DHCP before decommissioning
- Update static IP clients
- Monitor DNS queries for 48 hours
- Keep alternative DNS servers available
- Document rollback procedure

#### Risk 2: Application Dependencies
**Probability**: MEDIUM  
**Impact**: MEDIUM  
**Mitigation**:
- Inventory applications using AD
- Identify hardcoded DC references
- Update application configurations
- Test applications before decommission
- Have rollback plan ready

#### Risk 3: Authentication Failures
**Probability**: LOW  
**Impact**: HIGH  
**Mitigation**:
- Verify AD replication before decommission
- Keep sufficient DCs online (minimum 4)
- Monitor authentication logs
- Test from multiple client locations
- Have rollback plan ready

---

### Medium-Risk Items

#### Risk 4: Replication Issues
**Probability**: LOW  
**Impact**: MEDIUM  
**Mitigation**:
- Run repadmin /replsummary before decommission
- Force replication before demotion
- Monitor replication after decommission
- Keep backups of AD database

#### Risk 5: Client Connectivity
**Probability**: LOW  
**Impact**: MEDIUM  
**Mitigation**:
- Test from multiple client locations
- Verify site topology
- Check network connectivity
- Monitor for 48 hours post-decommission

---

## Critical Success Factors

### Before Decommissioning ANY DC

✅ **FSMO Roles Transferred**: All 5 roles on AWS DCs  
✅ **AD Replication Healthy**: No errors in repadmin /replsummary  
✅ **DNS Updated**: DHCP and clients point to remaining DCs  
✅ **Applications Identified**: No hardcoded references to DC being decommissioned  
✅ **Backups Created**: AD database and system state backed up  
✅ **Rollback Plan**: Documented and tested  
✅ **Stakeholder Approval**: Change management approval obtained  
✅ **Maintenance Window**: Scheduled during low-usage period  

---

### After Decommissioning Each DC

✅ **AD Replication**: Verify healthy replication  
✅ **FSMO Roles**: Verify all 5 roles still on AWS DCs  
✅ **DNS Resolution**: Test from multiple clients  
✅ **Authentication**: Test user logins  
✅ **Applications**: Verify critical apps working  
✅ **Monitoring**: Check for errors in event logs  
✅ **Documentation**: Update network diagrams  

---

## Rollback Procedures

### If Decommission Causes Issues

#### Immediate Rollback (Within 24 Hours)
1. **Stop demotion** if in progress
2. **Restore from backup** if demotion complete
3. **Verify AD replication** after restore
4. **Update DNS** to include restored DC
5. **Test authentication** from clients
6. **Investigate root cause** before retrying

#### Delayed Issues (After 24 Hours)
1. **Assess impact** - Is DC needed?
2. **Promote new DC** if needed (don't restore old one)
3. **Use modern OS** (Server 2019 or 2022)
4. **Update DNS** to include new DC
5. **Test thoroughly** before decommissioning again

---

## Monitoring & Validation

### Daily Monitoring (First Week After Each Decommission)

**AD Health**:
```powershell
# Run daily on WACPRODDC01
repadmin /replsummary
dcdiag /v
Get-ADReplicationFailure -Target * -Scope Domain
```

**DNS Health**:
```powershell
# Test DNS resolution
nslookup wac.net
nslookup WACPRODDC01.wac.net
nslookup WACPRODDC02.wac.net
```

**Authentication**:
```powershell
# Test from client
nltest /dsgetdc:wac.net
nltest /sc_query:wac.net
```

**Event Logs**:
- Check Directory Services log for errors
- Check DNS Server log for failures
- Check System log for warnings

---

### Weekly Monitoring (Weeks 2-4)

**Replication Status**:
```powershell
repadmin /showrepl
repadmin /replsummary
```

**FSMO Role Verification**:
```powershell
netdom query fsmo
```

**DC List**:
```powershell
Get-ADDomainController -Filter * | Select-Object Name, IPv4Address, OperatingSystem, IsGlobalCatalog
```

---

## Documentation Requirements

### Update After Each Decommission

1. **Network Diagrams**:
   - Remove decommissioned DC
   - Update IP addresses
   - Update DNS server lists

2. **DNS Documentation**:
   - Update DNS server inventory
   - Update client DNS configurations
   - Update DHCP scope options

3. **AD Documentation**:
   - Update DC inventory
   - Update FSMO role holders
   - Update site topology

4. **Application Documentation**:
   - Update application dependencies
   - Update connection strings
   - Update monitoring configurations

5. **Disaster Recovery Plans**:
   - Update DC restore procedures
   - Update backup schedules
   - Update recovery time objectives

---

## Cost-Benefit Analysis

### Decommissioning AD01, AD02, W09MVMPADDC01

**Benefits**:
- ✅ Eliminate security risk (EOL OS)
- ✅ Reduce maintenance overhead
- ✅ Reduce licensing costs (3 servers)
- ✅ Reduce power/cooling costs
- ✅ Simplify environment
- ✅ Modern OS only (Server 2016+)

**Costs**:
- ⚠️ Migration effort (3-4 weeks)
- ⚠️ DNS client updates
- ⚠️ Application testing
- ⚠️ Risk of issues during transition

**Net Benefit**: POSITIVE
- Security improvement outweighs migration effort
- Cost savings over time
- Simplified management

---

### Keeping WAC-DC01, WAC-DC02 On-Premises

**Benefits**:
- ✅ Local authentication (< 50ms vs 100-500ms over WAN)
- ✅ Local DNS resolution (< 10ms vs 50-200ms over WAN)
- ✅ Geographic redundancy
- ✅ Disaster recovery capability
- ✅ No client reconfiguration needed
- ✅ Lower WAN bandwidth usage
- ✅ Better user experience

**Costs**:
- ⚠️ Maintain 2 on-prem servers
- ⚠️ Power/cooling costs
- ⚠️ Licensing costs (2 servers)

**Net Benefit**: POSITIVE
- User experience improvement
- Business continuity
- Disaster recovery
- Costs justified by benefits

---

## Recommendations

### Immediate Actions (Weeks 1-4)

1. ✅ **Decommission AD01** (Week 1)
   - End of Life OS
   - Security risk
   - No FSMO roles

2. ✅ **Decommission AD02** (Week 2)
   - End of Life OS
   - Security risk
   - No FSMO roles

3. ✅ **Decommission W09MVMPADDC01** (Week 3-4)
   - Older OS
   - Can be replaced by newer DCs

4. ✅ **Update DNS configurations**
   - DHCP scope options
   - Static IP clients
   - Application configurations

5. ✅ **Monitor closely**
   - AD replication
   - DNS resolution
   - Authentication
   - Application connectivity

---

### Long-Term Strategy (Months 2-6)

1. 📊 **Assess remaining on-prem DCs**
   - Monitor authentication traffic
   - Check application dependencies
   - Evaluate WAN bandwidth usage
   - Review disaster recovery requirements

2. 🎯 **Target final state: 4 DCs**
   - 2 AWS: WACPRODDC01, WACPRODDC02
   - 2 On-Prem: WAC-DC01, WAC-DC02

3. 📋 **Optional decommissions**
   - W09MVMPADDC02 (if usage low)
   - WACHFDC01 or WACHFDC02 (if redundant)

4. 📝 **Document everything**
   - Update network diagrams
   - Update DR plans
   - Update application documentation

---

### Critical Don'ts

❌ **DO NOT decommission all on-prem DCs**
- Causes authentication delays for on-prem users
- Requires DNS reconfiguration for all clients
- Eliminates geographic redundancy
- Increases disaster recovery complexity

❌ **DO NOT decommission without testing**
- Test DNS resolution
- Test authentication
- Test applications
- Monitor for 48 hours

❌ **DO NOT skip backups**
- Backup AD database before each decommission
- Create system state backup
- Document rollback procedure

❌ **DO NOT rush the process**
- One DC per week maximum
- Monitor between decommissions
- Verify health before proceeding

---

## Conclusion

The decommissioning of on-premises domain controllers should be executed in a phased approach:

**Phase 1 (Immediate - Weeks 1-4)**:
- Decommission 3 servers (AD01, AD02, W09MVMPADDC01)
- Eliminate EOL and older OS security risks
- Reduce from 10 DCs to 7 DCs

**Phase 2 (Assessment - Months 2-6)**:
- Monitor usage and assess remaining DCs
- Optionally decommission 1-3 additional servers
- Target final state: 4 DCs (2 AWS + 2 On-Prem)

**Final State**:
- 2 AWS DCs (FSMO holders, modern OS)
- 2 On-Prem DCs (local services, modern OS)
- Geographic redundancy maintained
- Disaster recovery capability preserved
- User experience optimized

**Success Criteria**:
- ✅ All EOL servers decommissioned
- ✅ Modern OS only (Server 2019, 2022)
- ✅ AD replication healthy
- ✅ No authentication failures
- ✅ No DNS resolution issues
- ✅ Applications working correctly
- ✅ Documentation updated

---

**Report Prepared By**: Kiro AI Assistant  
**Review Date**: February 8, 2026  
**Next Review**: After Phase 1 completion (Week 4)  
**Approval Required**: IT Management, Change Advisory Board

---

**END OF REPORT**
