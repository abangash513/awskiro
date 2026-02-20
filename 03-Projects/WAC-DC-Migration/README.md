# WAC DC Migration Project

## Project Overview
Migration of WAC.NET Active Directory Domain Controllers from On-Premises to AWS

**Project Status:** Phase 1 Complete - AWS DCs Deployed  
**Start Date:** 2025-11-23  
**Completion Date:** In Progress  

---

## Project Phases

### ✅ Phase 1: AWS Infrastructure Deployment (COMPLETE)
- Deployed WACPRODDC01 (10.70.10.10, us-west-2a)
- Deployed WACPRODDC02 (10.70.11.10, us-west-2b)
- Both DCs operational and replicating
- High Availability across 2 Availability Zones

### ⏳ Phase 2: FSMO Migration (PLANNED)
- Migrate all 5 FSMO roles to WACPRODDC01
- Timeline: 2 days
- Status: Ready to execute

### ⏳ Phase 3: Decommissioning (PLANNED)
- Decommission AD01, AD02 (2008 R2)
- Decommission W09MVMPADDC01 (2012 R2)
- Timeline: 2 days (concurrent with Phase 2)

---

## Current Environment

### AWS Domain Controllers (2)
| DC | IP | AZ | OS | Status |
|----|----|----|----|----|
| WACPRODDC01 | 10.70.10.10 | us-west-2a | Windows Server 2019 | ✅ Operational |
| WACPRODDC02 | 10.70.11.10 | us-west-2b | Windows Server 2019 | ✅ Operational |

### On-Premises Domain Controllers (8)
| DC | IP | OS | Status |
|----|----|----|----|
| AD01 | 10.1.220.8 | Server 2008 R2 | ⚠️ To Decommission |
| AD02 | 10.1.220.9 | Server 2008 R2 | ⚠️ To Decommission |
| W09MVMPADDC01 | 10.1.220.20 | Server 2012 R2 | ⚠️ To Decommission |
| W09MVMPADDC02 | 10.1.220.21 | Server 2016 | ✅ Keep |
| WACHFDC01 | 10.1.220.5 | Server 2019 | ✅ Keep |
| WACHFDC02 | 10.1.220.6 | Server 2019 | ✅ Keep |
| WAC-DC01 | 10.1.220.205 | Server 2022 | ✅ Keep |
| WAC-DC02 | 10.1.220.206 | Server 2022 | ✅ Keep |

---

## Network Configuration

### AWS Infrastructure
- **VPC:** vpc-014b66d7ca2309134 (Prod-VPC, 10.70.0.0/16)
- **Subnets:** 
  - MAD-2a: subnet-05241411b9228d65f (10.70.10.0/24)
  - MAD-2b: subnet-0c6eec3752dd3e665 (10.70.11.0/24)
- **Security Group:** sg-0b0bd0839e63d3075 (WAC-Prod-ADMT-Enhanced-SG)
- **IAM Profile:** WAC-Prod-ADMT-Enhanced-Profile

### Connectivity
- **Transit Gateway:** tgw-0c147b016ed157991
- **VPN Connection:** vpn-025a12d4214e767b7
- **VPN Status:** 1 tunnel UP (44.252.167.140)
- **Route:** 10.1.0.0/16 → TGW → VPN → On-Prem

---

## FSMO Roles (Current State)

| Role | Current Holder | Target Holder |
|------|----------------|---------------|
| Schema Master | AD01.WAC.NET | WACPRODDC01.WAC.NET |
| Domain Naming Master | AD01.WAC.NET | WACPRODDC01.WAC.NET |
| PDC Emulator | AD01.WAC.NET | WACPRODDC01.WAC.NET |
| RID Master | AD02.WAC.NET | WACPRODDC01.WAC.NET |
| Infrastructure Master | AD02.WAC.NET | WACPRODDC01.WAC.NET |

---

## Project Files

### Documentation
- `01-OnPrem-Profile.json` - On-premises AD environment profile
- `02-Pre-Deployment-Verification.txt` - Pre-deployment checks
- `03-WACPRODDC01-Success-Report.txt` - DC01 deployment report
- `04-WACPRODDC02-Success-Report.txt` - DC02 deployment report
- `05-OnPrem-Health-Status.txt` - On-prem DC health verification
- `06-FSMO-Migration-Plan.md` - FSMO migration detailed plan
- `07-Decommissioning-Plan.md` - DC decommissioning plan
- `08-Cutover-Plan.md` - Cutover procedures and expectations

### CloudFormation Templates
- `WACPRODDC01-CloudFormation.json` - DC01 infrastructure template
- `WACPRODDC02-CloudFormation.json` - DC02 infrastructure template

### Scripts
- `WACPRODDC01-monitor.ps1` - DC01 monitoring script
- `Promote-WACPRODDC01.ps1` - DC promotion script
- `FSMO-Migration.ps1` - FSMO role migration script
- `DC-Decommission.ps1` - DC decommissioning script
- `Health-Check.ps1` - Daily health check script

### Reports
- `WACPRODDC01-Verification-Report.txt` - DC01 verification
- `WACPRODDC02-SUCCESS-REPORT.txt` - DC02 success report
- `OnPrem-Health-Status.txt` - On-prem health status

---

## Key Achievements

✅ **High Availability:** 2 AWS DCs across different AZs  
✅ **Zero Downtime:** All deployments with no user impact  
✅ **Replication Health:** 0 failures across all 10 DCs  
✅ **Network Connectivity:** VPN and TGW operational  
✅ **Security:** Encrypted volumes, termination protection enabled  

---

## Next Steps

1. **FSMO Migration (2 days)**
   - Day 1: Migrate all 5 FSMO roles to WACPRODDC01
   - Day 1: Decommission AD01, AD02
   - Day 2: Decommission W09MVMPADDC01

2. **Post-Migration Monitoring (1 week)**
   - Monitor replication health
   - Verify application connectivity
   - Check event logs

3. **Final State (Target)**
   - 7 DCs total (2 AWS + 5 On-Prem)
   - All FSMO roles on AWS
   - Modern OS versions only (2016+)

---

## Contact Information

**Project Lead:** [Your Name]  
**AWS Account:** 466090007609 (WACPROD)  
**Region:** us-west-2  
**Domain:** WAC.NET  

---

## Important Notes

⚠️ **VPN Dependency:** AWS DCs require stable VPN connectivity to on-prem  
⚠️ **FSMO Roles:** Do not move until AWS DCs stable for 2+ weeks  
⚠️ **Backups:** All DCs backed up before any changes  
⚠️ **Rollback:** Keep decommissioned DCs powered off for 7 days  

---

**Last Updated:** 2025-11-24  
**Project Status:** Phase 1 Complete, Phase 2 Ready
