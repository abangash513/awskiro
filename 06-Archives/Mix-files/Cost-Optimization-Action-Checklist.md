# AWS Cost Optimization - Action Checklist
**Current Monthly Spend:** $150,501.21  
**Target Monthly Spend:** $80,000 - $90,000  
**Target Savings:** $60,000 - $70,000/month

---

## ✅ Week 1: Quick Wins & Investigation

### Day 1-2: Critical Investigation
- [ ] Schedule meeting with Charles Mount to review $57K/month account
- [ ] Run complete AWS region scan (all 20+ regions, not just 4)
- [ ] Generate AWS Cost and Usage Report (CUR) for detailed analysis
- [ ] Identify all Elastic IPs and check for unattached ($3.60/month each)
- [ ] List all NAT Gateways across accounts ($30-45/month each)

### Day 3-4: EBS Quick Wins
- [ ] Snapshot all 18 unattached EBS volumes
- [ ] Delete unattached volumes (Save: $50-100/month)
- [ ] Start GP2 to GP3 migration for test volumes
- [ ] Document GP2 to GP3 migration process
- [ ] Schedule GP2 to GP3 migration for all 126 volumes (Save: $88/month)

### Day 5: Resource Cleanup
- [ ] Identify and delete old EBS snapshots (>90 days)
- [ ] Identify and delete old AMIs not in use
- [ ] Review and delete unused Elastic IPs
- [ ] Document all deleted resources

**Week 1 Target Savings:** $500 - $1,000/month

---

## ✅ Week 2-3: S3 & Storage Optimization

### S3 Optimization
- [ ] Enable S3 Storage Lens for detailed analytics
- [ ] Implement lifecycle policy for `srs.logzio` (445 GB)
  - Move to Glacier after 90 days
  - Delete after 1 year
- [ ] Implement lifecycle policy for `srsa.archived.g-suite.users` (139 GB)
  - Move to Glacier Deep Archive immediately
- [ ] Implement lifecycle policy for `srsa-billing-report` (139 GB)
  - Move to Glacier after 30 days
- [ ] Clean up incomplete multipart uploads across all buckets
- [ ] Review and optimize S3 request patterns
- [ ] Analyze S3 data transfer costs

### EFS Optimization
- [ ] Review EFS usage ($3,633/month)
- [ ] Implement EFS Lifecycle Management
- [ ] Move infrequently accessed files to IA storage class
- [ ] Consider migrating to S3 if appropriate

**Week 2-3 Target Savings:** $3,000 - $5,000/month

---

## ✅ Week 4: Network & Compute Optimization

### NAT Gateway Review
- [ ] List all NAT Gateways across all accounts
- [ ] Identify NAT Gateways in dev/test environments
- [ ] Replace dev/test NAT Gateways with NAT instances
- [ ] Consolidate NAT Gateways where possible
- [ ] Document NAT Gateway usage and costs

### Load Balancer Optimization
- [ ] List all Load Balancers ($885/month)
- [ ] Identify unused or underutilized Load Balancers
- [ ] Consolidate Load Balancers where possible
- [ ] Consider Application Load Balancer vs Classic Load Balancer
- [ ] Delete unused Load Balancers

### EC2 Mystery Investigation
- [ ] Scan all regions for EC2 instances
- [ ] Check for EC2 instances with frequent start/stop
- [ ] Review EC2 data transfer costs
- [ ] Analyze EC2 Reserved Instance utilization
- [ ] Identify source of $39K/month EC2 compute costs

**Week 4 Target Savings:** $2,000 - $5,000/month

---

## ✅ Month 2: Database & Cache Optimization

### RDS Investigation & Optimization
- [ ] Scan ALL AWS regions for RDS instances
- [ ] Check for Aurora Serverless clusters
- [ ] List all RDS snapshots and calculate costs
- [ ] Review RDS automated backup retention periods
- [ ] Identify source of $26K/month RDS costs
- [ ] Right-size RDS instances based on CloudWatch metrics
- [ ] Consider Aurora Serverless for variable workloads
- [ ] Analyze RDS Reserved Instance opportunities

### ElastiCache Optimization
- [ ] Review ElastiCache usage ($8,157/month)
- [ ] Analyze cache hit rates and utilization
- [ ] Right-size cache node types
- [ ] Consider Redis vs Memcached appropriateness
- [ ] Evaluate ElastiCache Reserved Node opportunities

### OpenSearch Investigation
- [ ] Scan ALL AWS regions for OpenSearch domains
- [ ] Check for OpenSearch Serverless collections
- [ ] Identify source of $11K/month OpenSearch costs
- [ ] Right-size OpenSearch domains
- [ ] Review data retention policies
- [ ] Consider alternatives (CloudWatch Logs Insights, Athena)

**Month 2 Target Savings:** $10,000 - $20,000/month

---

## ✅ Month 2-3: Reserved Instances & Savings Plans

### Analysis Phase
- [ ] Run AWS Cost Explorer RI recommendations
- [ ] Analyze EC2 usage patterns for RI opportunities
- [ ] Analyze RDS usage patterns for RI opportunities
- [ ] Analyze ElastiCache usage for Reserved Node opportunities
- [ ] Calculate ROI for 1-year vs 3-year commitments
- [ ] Get approval for RI/SP purchases

### Purchase Phase
- [ ] Purchase EC2 Reserved Instances (target: $15K-20K/month savings)
- [ ] Purchase RDS Reserved Instances (target: $5K-8K/month savings)
- [ ] Purchase Compute Savings Plans (flexible option)
- [ ] Purchase ElastiCache Reserved Nodes (target: $2K-3K/month savings)
- [ ] Document all RI/SP purchases and expected savings

**Month 2-3 Target Savings:** $25,000 - $35,000/month

---

## ✅ Month 3: Monitoring & Governance

### CloudWatch Optimization
- [ ] Review CloudWatch Logs retention ($2,509/month)
- [ ] Reduce retention for non-critical logs (7 days instead of 30)
- [ ] Export old logs to S3 with Glacier lifecycle
- [ ] Review custom metrics and reduce unnecessary ones
- [ ] Implement CloudWatch Logs Insights for analysis

### Security Services Review
- [ ] Review GuardDuty necessity in all accounts ($1,079/month)
- [ ] Review Security Hub necessity in all accounts ($680/month)
- [ ] Review Detective necessity in all accounts ($1,155/month)
- [ ] Review Config necessity in all accounts ($634/month)
- [ ] Consolidate security services where possible
- [ ] Consider delegated administrator account

### Other Services
- [ ] Review QuickSight user licenses ($1,935/month)
- [ ] Remove inactive QuickSight users
- [ ] Review CloudTrail logging ($1,659/month)
- [ ] Optimize CloudTrail with S3 lifecycle policies
- [ ] Review AWS Transfer Family usage ($894/month)
- [ ] Review AWS Glue usage ($1,021/month)

**Month 3 Target Savings:** $3,000 - $5,000/month

---

## ✅ Ongoing: FinOps Best Practices

### Tagging Strategy
- [ ] Define cost allocation tag strategy
- [ ] Implement mandatory tags: Environment, Owner, Project, CostCenter
- [ ] Tag all existing resources
- [ ] Enforce tagging via AWS Config rules or Service Control Policies
- [ ] Create cost allocation reports by tag

### Cost Monitoring
- [ ] Enable AWS Cost Anomaly Detection
- [ ] Set up budget alerts for each account
- [ ] Set up budget alerts for each service
- [ ] Create CloudWatch dashboard for cost metrics
- [ ] Schedule monthly cost review meetings

### Automation
- [ ] Implement auto-stop for dev/test EC2 instances (nights/weekends)
- [ ] Implement auto-scaling for production workloads
- [ ] Create Lambda function to delete old snapshots
- [ ] Create Lambda function to identify unattached resources
- [ ] Implement AWS Systems Manager for patch management

### Documentation
- [ ] Document all optimization actions taken
- [ ] Create runbook for monthly cost optimization
- [ ] Document Reserved Instance strategy
- [ ] Create cost optimization playbook
- [ ] Train team on cost-aware development

---

## 📊 Savings Tracker

### Quick Wins (Month 1)
| Action | Status | Savings/Month |
|--------|--------|---------------|
| GP2 to GP3 migration | ⬜ Not Started | $88 |
| Delete unattached volumes | ⬜ Not Started | $50-100 |
| Delete unused Elastic IPs | ⬜ Not Started | TBD |
| Delete old snapshots | ⬜ Not Started | TBD |
| **Month 1 Total** | | **$500-1,000** |

### Storage Optimization (Month 1-2)
| Action | Status | Savings/Month |
|--------|--------|---------------|
| S3 lifecycle policies | ⬜ Not Started | $3,000-8,000 |
| EFS optimization | ⬜ Not Started | $500-1,500 |
| **Storage Total** | | **$3,500-9,500** |

### Compute Optimization (Month 2)
| Action | Status | Savings/Month |
|--------|--------|---------------|
| NAT Gateway optimization | ⬜ Not Started | $500-1,000 |
| Load Balancer consolidation | ⬜ Not Started | $200-500 |
| EC2 optimization | ⬜ Not Started | $5,000-10,000 |
| **Compute Total** | | **$5,700-11,500** |

### Database & Cache (Month 2)
| Action | Status | Savings/Month |
|--------|--------|---------------|
| RDS optimization | ⬜ Not Started | $5,000-8,000 |
| ElastiCache optimization | ⬜ Not Started | $1,000-2,000 |
| OpenSearch optimization | ⬜ Not Started | $2,000-5,000 |
| **Database Total** | | **$8,000-15,000** |

### Reserved Instances (Month 2-3)
| Action | Status | Savings/Month |
|--------|--------|---------------|
| EC2 Reserved Instances | ⬜ Not Started | $15,000-20,000 |
| RDS Reserved Instances | ⬜ Not Started | $5,000-8,000 |
| ElastiCache Reserved Nodes | ⬜ Not Started | $2,000-3,000 |
| Compute Savings Plans | ⬜ Not Started | $5,000-10,000 |
| **RI/SP Total** | | **$27,000-41,000** |

### Other Services (Month 3)
| Action | Status | Savings/Month |
|--------|--------|---------------|
| CloudWatch optimization | ⬜ Not Started | $500-1,000 |
| Security services review | ⬜ Not Started | $500-1,000 |
| QuickSight optimization | ⬜ Not Started | $300-800 |
| Other services | ⬜ Not Started | $1,000-2,000 |
| **Other Total** | | **$2,300-4,800** |

### Charles Mount Account (Ongoing)
| Action | Status | Savings/Month |
|--------|--------|---------------|
| Account investigation | ⬜ Not Started | TBD |
| Resource optimization | ⬜ Not Started | $15,000-25,000 |
| **Charles Mount Total** | | **$15,000-25,000** |

---

## 🎯 Total Savings Target

| Timeframe | Target Savings | Cumulative |
|-----------|----------------|------------|
| Month 1 | $5,000 | $5,000 |
| Month 2 | $20,000 | $25,000 |
| Month 3 | $35,000 | $60,000 |

**Final Target:** $60,000 - $70,000/month ($720K - $840K/year)

---

## 📞 Escalation & Support

### For Technical Issues:
- AWS Support (Business Plan): Available 24/7
- AWS Account Manager: [Contact Info]
- Internal DevOps Team: [Contact Info]

### For Budget/Finance Questions:
- FinOps Team: [Contact Info]
- Finance Department: [Contact Info]

### For Approval Required:
- Reserved Instance purchases > $10K
- Resource deletions in production
- Major architecture changes

---

## 📝 Notes & Lessons Learned

### Key Insights:
1. Charles Mount account needs immediate attention (38% of spend)
2. Many resources not visible in initial 4-region scan
3. Data transfer costs hidden in service costs
4. Need better tagging for cost allocation

### Process Improvements:
1. Implement mandatory tagging before resource creation
2. Set up automated cost anomaly detection
3. Schedule monthly cost review meetings
4. Create cost-aware development guidelines

### Tools to Implement:
1. AWS Cost Explorer (already available)
2. AWS Cost and Usage Reports (CUR)
3. AWS Cost Anomaly Detection
4. Third-party tools (CloudHealth, CloudCheckr, etc.)

---

**Last Updated:** December 2, 2025  
**Next Review:** Weekly for first month, then monthly  
**Owner:** FinOps Team / Cloud Infrastructure Team
