# WAC DC Migration - Project Summary

## Quick Reference

**Project Name:** WAC DC Migration  
**Status:** Phase 1 Complete  
**AWS Account:** 466090007609 (WACPROD)  
**Region:** us-west-2  
**Domain:** WAC.NET  

---

## Current State (As of 2025-11-24)

### ✅ Completed
- AWS Infrastructure deployed (VPC, Subnets, Security Groups)
- WACPRODDC01 deployed and operational (10.70.10.10, us-west-2a)
- WACPRODDC02 deployed and operational (10.70.11.10, us-west-2b)
- High Availability across 2 Availability Zones
- 0 replication failures across all 10 DCs
- VPN connectivity established and tested

### ⏳ Pending
- FSMO role migration to AWS (2 days)
- Decommission AD01, AD02, W09MVMPADDC01 (2 days)
- Post-migration monitoring (1 week)

---

## Key Information

### AWS Domain Controllers
| DC | IP | Instance ID | AZ |
|----|----|----|---|
| WACPRODDC01 | 10.70.10.10 | i-0745579f46a34da2e | us-west-2a |
| WACPRODDC02 | 10.70.11.10 | i-08c78db5cfc6eb412 | us-west-2b |

### Credentials
- **Domain Admin:** WAC\Administrator
- **Password:** W@Cmore4the$$0897
- **DSRM Password:** W@Cmore4the$$0897

### Network
- **VPC:** vpc-014b66d7ca2309134 (10.70.0.0/16)
- **Subnets:** MAD-2a (10.70.10.0/24), MAD-2b (10.70.11.0/24)
- **VPN:** vpn-025a12d4214e767b7
- **TGW:** tgw-0c147b016ed157991

---

## Quick Commands

### Check FSMO Roles
```powershell
netdom query fsmo
```

### Check Replication
```powershell
repadmin /replsummary
```

### Check DC Health
```powershell
dcdiag /v /c /e
```

### Run Daily Health Check
```powershell
.\Scripts\Health-Check.ps1
```

### Migrate FSMO Roles
```powershell
.\Scripts\FSMO-Migration.ps1 -TargetDC WACPRODDC01
```

---

## Project Files Location

```
WAC-DC-Migration/
├── README.md                          # Main project documentation
├── PROJECT-SUMMARY.md                 # This file (quick reference)
├── Documentation/
│   ├── 01-OnPrem-Profile.json        # On-prem AD profile
│   ├── 06-FSMO-Migration-Plan.md     # FSMO migration plan
│   ├── 07-Decommissioning-Plan.md    # DC decommissioning plan
│   └── 08-Cutover-Plan.md            # Cutover procedures
├── CloudFormation/
│   ├── WACPRODDC01-CloudFormation.json
│   └── WACPRODDC02-CloudFormation.json
├── Scripts/
│   ├── FSMO-Migration.ps1            # FSMO migration script
│   └── Health-Check.ps1              # Daily health check
└── Reports/
    ├── WACPRODDC01-SUCCESS-REPORT.txt
    ├── WACPRODDC02-SUCCESS-REPORT.txt
    └── OnPrem-Health-Status.txt
```

---

## Next Actions

### Immediate (This Week)
1. Monitor AWS DCs daily using Health-Check.ps1
2. Verify VPN stability
3. Prepare for FSMO migration

### Week 2-3
1. Execute FSMO migration (2 days)
2. Decommission old DCs (2 days)
3. Monitor post-migration (1 week)

### Month 2
1. Evaluate remaining on-prem DCs
2. Plan functional level upgrade
3. Document lessons learned

---

## Support Contacts

**AWS Support:** [AWS Support Portal]  
**Network Team:** [Contact for VPN issues]  
**AD Team:** [Contact for AD issues]  

---

## Important Reminders

⚠️ **Always check VPN status before making changes**  
⚠️ **Run health checks daily during migration**  
⚠️ **Keep backups of all DCs**  
⚠️ **Document all changes**  
⚠️ **Communicate with stakeholders**  

---

**Last Updated:** 2025-11-24
