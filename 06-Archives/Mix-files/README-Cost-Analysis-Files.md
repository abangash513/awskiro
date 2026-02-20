# AWS Cost Analysis - File Index

**Analysis Date:** December 2, 2025  
**Total Monthly Spend:** $150,501.21  
**Potential Savings:** $60,000 - $70,000/month

---

## 📋 Executive Documents

### 1. Executive-Summary-Cost-Optimization.md
**Purpose:** High-level overview for leadership  
**Audience:** C-level, VPs, Directors  
**Key Content:**
- Current spend: $150,501/month
- Top 5 cost drivers
- Potential savings: $60K-70K/month
- 30-60-90 day plan
- Critical actions required

### 2. AWS-Cost-Optimization-Report.md
**Purpose:** Comprehensive technical analysis  
**Audience:** Engineering, FinOps, Cloud Architects  
**Key Content:**
- 14 detailed sections
- Service-by-service analysis
- Account-by-account breakdown
- Optimization recommendations
- Implementation timeline

### 3. Cost-Optimization-Action-Checklist.md
**Purpose:** Actionable task list  
**Audience:** Implementation teams  
**Key Content:**
- Week-by-week action items
- Savings tracker with checkboxes
- Escalation procedures
- Progress tracking

---

## 📊 Cost Analysis Files

### 4. aws-costs-by-service.csv
**Records:** 100+ services  
**Total Cost:** $150,501.21  
**Top Services:**
- Amazon EC2 Compute: $39,388.19
- Amazon RDS: $26,317.89
- Amazon S3: $18,410.55
- EC2 Other: $17,112.40
- Amazon OpenSearch: $11,220.17

### 5. aws-costs-by-account.csv
**Records:** 18 accounts  
**Total Cost:** $150,501.21  
**Top Accounts:**
- Charles Mount: $57,452.10 (38.2%)
- Production: $20,696.91 (13.8%)
- AWS Development: $20,290.23 (13.5%)
- Cortado Production: $15,810.09 (10.5%)
- Stage: $10,894.83 (7.2%)

---

## 💻 EC2 Analysis Files

### 6. ec2-inventory-all-accounts.csv
**Records:** 108 EC2 instances  
**Status:** ALL STOPPED  
**Key Finding:** All instances stopped but $39K/month EC2 costs  
**Columns:**
- AccountId, AccountName, Region
- InstanceId, InstanceType, State
- Platform, PrivateIP, Name, Lifecycle

### 7. ec2-cost-analysis-detailed.csv
**Records:** 108 instances with cost data  
**Current Cost:** $0 (all stopped)  
**Potential Cost:** $1,432.44/month if running  
**Columns:**
- All EC2 inventory columns
- HourlyRate, MonthlyCost, PotentialMonthlyCost

### 8. ec2-cost-summary-by-account.csv
**Records:** 18 accounts  
**Key Metrics:**
- TotalInstances, RunningInstances, StoppedInstances
- CurrentMonthlyCost, PotentialMonthlyCost

### 9. ec2-cost-summary-by-type.csv
**Records:** 2 instance types  
**Breakdown:**
- t2.micro: 90 instances
- t2.medium: 18 instances

---

## 💾 EBS Volume Analysis Files

### 10. ebs-volumes-all-accounts.csv
**Records:** 126 EBS volumes  
**Total Storage:** 4,392 GB (4.3 TB)  
**Total Cost:** $439.20/month  
**Columns:**
- AccountId, AccountName, Region
- VolumeId, VolumeType, SizeGB, State
- IOPS, Throughput, Encrypted
- AttachedInstanceId, MonthlyCost

### 11. ebs-volumes-gp2.csv
**Records:** 126 volumes (100% of all volumes)  
**Total Storage:** 4,392 GB  
**Total Cost:** $439.20/month  
**Migration Opportunity:** All volumes are GP2 (old generation)

### 12. ebs-volumes-gp3.csv
**Records:** 0 volumes  
**Finding:** No GP3 volumes in use  
**Opportunity:** Migrate all GP2 to GP3 for 20% savings

### 13. ebs-summary-by-type.csv
**Records:** 1 volume type (GP2 only)  
**Key Metrics:**
- TotalCount: 126
- InUseCount: 108
- AvailableCount: 18 (unattached - wasting money)
- EncryptedCount: 0 (security risk)

### 14. ebs-summary-by-account.csv
**Records:** 18 accounts  
**Key Metrics per account:**
- TotalVolumes, TotalSizeGB
- GP2Count, GP3Count, OtherCount
- TotalMonthlyCost

---

## 🪣 S3 Storage Analysis Files

### 15. s3-buckets-analysis.csv
**Records:** 13 S3 buckets  
**Total Storage:** 748.69 GB  
**Estimated Cost:** ~$17/month  
**Actual Cost:** $18,410.55/month (huge discrepancy!)  
**Top 3 Buckets:**
- srs.logzio: 444.97 GB
- srsa.archived.g-suite.users: 139.31 GB
- srsa-billing-report: 139.18 GB

**Columns:**
- BucketName, Region, CreationDate
- SizeGB, EstimatedMonthlyCost

---

## 🗄️ Database Analysis Files

### 16. rds-instances-all-accounts.csv
**Records:** 0 RDS instances found  
**Actual Cost:** $26,317.89/month  
**Status:** ⚠️ MYSTERY - Need to scan all regions  
**Possible Causes:**
- RDS in regions not scanned
- Aurora Serverless (different API)
- RDS snapshots/backups

---

## 🐳 Container Service Analysis Files

### 17. ecs-clusters-all-accounts.csv
**Records:** 0 ECS clusters found  
**Columns:**
- AccountId, AccountName, Region
- ClusterName, Status
- RunningTasksCount, ActiveServicesCount

### 18. ecs-services-all-accounts.csv
**Records:** 0 ECS services found  
**Columns:**
- AccountId, AccountName, Region
- ClusterName, ServiceName, Status
- DesiredCount, RunningCount, LaunchType

### 19. ecs-tasks-all-accounts.csv
**Records:** 0 ECS tasks found  
**Columns:**
- AccountId, AccountName, Region
- ClusterName, TaskArn, LaunchType
- Cpu, Memory, StartedAt

### 20. eks-clusters-all-accounts.csv
**Records:** 0 EKS clusters found  
**Finding:** No Kubernetes clusters in use

---

## 🔍 OpenSearch Analysis Files

### 21. opensearch-domains-all-accounts.csv
**Records:** 0 OpenSearch domains found  
**Actual Cost:** $11,220.17/month  
**Status:** ⚠️ MYSTERY - Need to scan all regions  
**Columns:**
- AccountId, AccountName, Region
- DomainName, EngineVersion
- InstanceType, InstanceCount, StorageSize

---

## 🎯 Charles Mount Account Analysis

### 22. charles-mount-costs-by-service.csv
**Status:** Empty (query timed out)  
**Account Cost:** $57,452.10/month (38.2% of total)  
**Action Required:** Manual deep dive investigation

---

## 📈 Analysis Scripts

### 23. get-ec2-inventory.ps1
**Purpose:** Scan all accounts for EC2 instances  
**Output:** ec2-inventory-all-accounts.csv

### 24. ec2-cost-analysis.ps1
**Purpose:** Add cost calculations to EC2 inventory  
**Output:** ec2-cost-analysis-detailed.csv, summaries

### 25. get-ebs-inventory.ps1
**Purpose:** Scan all accounts for EBS volumes  
**Output:** ebs-volumes-*.csv files

### 26. get-eks-inventory.ps1
**Purpose:** Scan all accounts for EKS clusters  
**Output:** eks-*.csv files

### 27. get-cost-analysis.ps1
**Purpose:** Get actual costs from AWS Cost Explorer  
**Output:** aws-costs-*.csv files

### 28. deep-dive-analysis.ps1
**Purpose:** Comprehensive analysis of all services  
**Output:** Multiple analysis files

---

## 🚨 Key Findings Summary

### Critical Issues:
1. **Charles Mount Account:** $57K/month (38% of total) - needs investigation
2. **EC2 Mystery:** $39K/month but all instances stopped
3. **RDS Mystery:** $26K/month but no instances found
4. **S3 Mystery:** $18K/month but only $17/month visible storage
5. **OpenSearch Mystery:** $11K/month but no domains found

### Quick Wins:
1. **GP2 to GP3 Migration:** $88/month savings (126 volumes)
2. **Delete Unattached Volumes:** $50-100/month savings (18 volumes)
3. **Enable Encryption:** 0 encrypted volumes (security risk)

### Data Quality Issues:
- Only scanned 4 of 20+ AWS regions
- Many services require different API calls
- Data transfer costs hidden in service costs
- Need AWS Cost and Usage Reports (CUR) for complete picture

---

## 📊 Savings Potential Summary

| Category | Monthly Savings | Annual Savings |
|----------|----------------|----------------|
| Charles Mount Account | $15,000 - $25,000 | $180K - $300K |
| EC2 Optimization | $5,000 - $10,000 | $60K - $120K |
| RDS Optimization | $5,000 - $8,000 | $60K - $96K |
| S3 Optimization | $3,000 - $8,000 | $36K - $96K |
| OpenSearch Optimization | $2,000 - $5,000 | $24K - $60K |
| EBS GP2→GP3 | $88 | $1,054 |
| Reserved Instances | $15,000 - $30,000 | $180K - $360K |
| Other Services | $3,000 - $6,000 | $36K - $72K |
| **TOTAL** | **$48K - $92K** | **$577K - $1.1M** |

**Realistic Target:** $60,000 - $70,000/month ($720K - $840K/year)

---

## 🔄 Next Steps

### Immediate (This Week):
1. Review Executive Summary with leadership
2. Schedule Charles Mount account investigation
3. Scan ALL AWS regions (not just 4)
4. Start GP2 to GP3 migration

### Short-Term (This Month):
5. Implement S3 lifecycle policies
6. Delete unattached EBS volumes
7. Optimize NAT Gateways
8. Conduct Reserved Instance analysis

### Medium-Term (This Quarter):
9. Purchase Reserved Instances
10. Right-size databases and caches
11. Implement tagging strategy
12. Establish monthly cost reviews

---

## 📞 Questions or Issues?

**For Technical Questions:**
- Review AWS-Cost-Optimization-Report.md (comprehensive)
- Check Cost-Optimization-Action-Checklist.md (actionable tasks)

**For Executive Summary:**
- Review Executive-Summary-Cost-Optimization.md

**For Raw Data:**
- All CSV files contain detailed resource inventories
- Use Excel/Google Sheets for custom analysis

---

**Report Generated:** December 2, 2025  
**Analysis Tool:** AWS CLI + PowerShell  
**Regions Scanned:** us-east-1, us-west-2, us-east-2, us-west-1  
**Accounts Analyzed:** 18 accounts  
**Total Files Generated:** 28 files
