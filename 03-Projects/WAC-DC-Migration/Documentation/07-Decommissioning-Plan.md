# Domain Controller Decommissioning Plan

## Overview
Decommission 3 old domain controllers after FSMO migration to AWS

**Timeline:** Day 1-2 (concurrent with FSMO migration)  
**Target DCs:** AD01, AD02, W09MVMPADDC01  

---

## DCs to Decommission

| DC | OS | IP | Reason | Priority |
|----|----|----|--------|----------|
| AD01 | Server 2008 R2 | 10.1.220.8 | EOL, holds FSMO roles | HIGH |
| AD02 | Server 2008 R2 | 10.1.220.9 | EOL, holds FSMO roles | HIGH |
| W09MVMPADDC01 | Server 2012 R2 | 10.1.220.20 | Older OS | MEDIUM |

---

## DAY 1: Decommission AD01 & AD02

### Hour 9: 2:00 PM - Prepare AD01

```powershell
# On AD01 - Verify no FSMO roles
netdom query fsmo

# Check replication partners
repadmin /showrepl AD01

# Verify metadata
repadmin /showreps

# Document dependencies
# - Check DNS references
# - Check DHCP configurations
# - Check application configs
# - Check monitoring systems
```

---

### Hour 10: 3:00 PM - Demote AD01

```powershell
# On AD01
Uninstall-ADDSDomainController -LocalAdministratorPassword (ConvertTo-SecureString "TempPass123!" -AsPlainText -Force) -Force

# This will:
# - Remove AD DS role
# - Remove DNS if last DNS server (it's not)
# - Reboot automatically (~10 minutes)
```

**Post-Demotion (After reboot):**

```powershell
# On WACPRODDC01 - Clean metadata
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
select server 0  # AD01
quit
remove selected server
quit
quit

# Verify removal
Get-ADDomainController -Filter * | Select Name

# Check replication
repadmin /replsummary

# Verify 9 DCs remaining
Get-ADDomainController -Filter * | Measure-Object
```

---

### Hour 11: 4:00 PM - Demote AD02

```powershell
# Same process as AD01

# On AD02
Uninstall-ADDSDomainController -LocalAdministratorPassword (ConvertTo-SecureString "TempPass123!" -AsPlainText -Force) -Force

# Clean metadata after reboot
# Verify 8 DCs remaining
```

---

### Hour 12: 5:00 PM - Day 1 Verification

```powershell
# Verify FSMO roles
netdom query fsmo

# Check replication
repadmin /replsummary

# Verify 8 DCs healthy
dcdiag /v /c /e

# Check event logs
Get-EventLog -LogName "Directory Service" -Newest 50 | Where-Object {$_.EntryType -eq "Error"}
```

---

## DAY 2: Decommission W09MVMPADDC01

### Hour 1: 8:00 AM - Health Check

```powershell
# Verify overnight stability
netdom query fsmo
repadmin /replsummary
dcdiag /test:replications

# Check for errors
Get-EventLog -LogName "Directory Service" -Since (Get-Date).AddHours(-12) | Where-Object {$_.EntryType -eq "Error"}
```

---

### Hour 2: 9:00 AM - Prepare W09MVMPADDC01

```powershell
# On W09MVMPADDC01
netdom query fsmo  # Verify no FSMO roles

# Check dependencies
repadmin /showrepl W09MVMPADDC01

# Update documentation
# Remove from monitoring
```

---

### Hour 3: 10:00 AM - Demote W09MVMPADDC01

```powershell
# On W09MVMPADDC01
Uninstall-ADDSDomainController -LocalAdministratorPassword (ConvertTo-SecureString "TempPass123!" -AsPlainText -Force) -Force

# Wait for reboot
# Clean metadata
# Verify 7 DCs remaining
```

---

## Post-Decommissioning Actions

### Cleanup Tasks

```powershell
# Remove DNS records
# Remove from DHCP
# Remove from monitoring systems
# Update documentation
# Update network diagrams
# Notify stakeholders
```

### Server Disposition

1. **Power off** (don't delete) for 7 days
2. **Monitor** for any issues
3. **Final deletion** after 7 days if no issues

---

## Final State

### Remaining Domain Controllers (7 Total)

| DC | OS | Location | IP | Role |
|----|----|----|----|----|
| WACPRODDC01 | 2019 | AWS 2a | 10.70.10.10 | All FSMO Roles |
| WACPRODDC02 | 2019 | AWS 2b | 10.70.11.10 | Replica |
| W09MVMPADDC02 | 2016 | On-Prem | 10.1.220.21 | Replica |
| WACHFDC01 | 2019 | On-Prem | 10.1.220.5 | Replica |
| WACHFDC02 | 2019 | On-Prem | 10.1.220.6 | Replica |
| WAC-DC01 | 2022 | On-Prem | 10.1.220.205 | Replica |
| WAC-DC02 | 2022 | On-Prem | 10.1.220.206 | Replica |

---

## Decommissioning Checklist

### Before Each Decommission

- [ ] Verify no FSMO roles on DC
- [ ] Check no applications hardcoded to DC IP
- [ ] Review DNS SRV records
- [ ] Check DHCP scope options
- [ ] Review GPO WMI filters
- [ ] Verify no scheduled tasks pointing to DC
- [ ] Check monitoring/backup systems
- [ ] Document all dependencies

### During Decommissioning

- [ ] Run dcdiag before demotion
- [ ] Gracefully demote (don't force unless necessary)
- [ ] Clean up metadata
- [ ] Remove DNS records
- [ ] Update documentation
- [ ] Notify users/teams

### After Decommissioning

- [ ] Monitor replication for 7 days
- [ ] Check event logs for errors
- [ ] Verify application functionality
- [ ] Keep powered off for 7 days (rollback option)
- [ ] Final deletion after 7 days

---

## Rollback Procedure

If issues occur after decommissioning:

```powershell
# Re-promote demoted DC
Install-ADDSDomainController -DomainName "wac.net" -Credential (Get-Credential)

# Or restore from backup/snapshot
```

---

## Success Criteria

- ✅ 3 DCs decommissioned (AD01, AD02, W09MVMPADDC01)
- ✅ 7 DCs remaining and healthy
- ✅ 0 replication failures
- ✅ No user complaints
- ✅ All applications working
- ✅ Documentation updated

---

**Last Updated:** 2025-11-24
