# Charles Mount Account - Optimization Plan
**Account ID:** 198161015548  
**Current Monthly Cost:** $57,452  
**Target Monthly Cost:** $30,000 - $35,000  
**Potential Savings:** $22,000 - $27,000/month ($264K - $324K/year)

---

## 📊 Executive Summary

The Charles Mount account is consuming 38.2% of total AWS spend due to:
- Over-provisioned EC2 instances (79 instances, 58 running)
- Expensive RDS databases running 24/7 (16 instances)
- Large OpenSearch clusters (4 domains)
- Excessive ElastiCache clusters (16 clusters)
- Resources from 2015-2017 still running

**This optimization plan will reduce costs by 40-50% while maintaining performance.**

---

## 🎯 Phase 1: Immediate Actions (Week 1)

### Priority 1: Stop Unused/Old EC2 Instances

#### Instances to Stop Immediately (Save ~$5,000/month):

**Stopped but still costing money (EBS volumes):**
- i-a409368e (c3.xlarge) - Stopped since 2021
- i-52cfda7c (c3.xlarge) - Stopped since 2021
- i-d07743c7 (m3.medium) - Stopped since 2021
- i-0e002527a16392fa1 (m3.medium) - Stopped since 2017
- i-0eb8bbfffdd2f3ec7 (c4.large) - Stopped since 2017
- i-05bc73a0c7e562ce0 (m3.medium) - Stopped since 2023
- i-0d106f55f0dd4fcdc (t2.micro) - Stopped since 2022
- i-0a086d7d2a4ba25a9 (t3.small) - Stopped since 2021
- i-0dbb4653a8cfca4ae (c4.xlarge Windows) - Stopped since 2021
- i-0003603fb4581513a (t4g.large) - Stopped since 2021
- i-060098e5e6b5ad472 (t2.medium Windows) - Stopped since 2022
- i-047dbab75f6716d09 (t2.medium Windows) - Stopped since 2022
- i-0490009a252a79db0 (t3a.medium) - Stopped since 2024
- i-09305503247b3b2eb (t3.medium Windows) - Stopped since 2024
- i-0e67a8be33d600e3c (m7i-flex.xlarge Windows) - Stopped since 2024
- i-0cf6e6a70c40a6a21 (m3.medium) - Stopped since 2024

**Action:** Snapshot these instances, then terminate them.  
**Savings:** ~$2,000/month in EBS costs

**Old running instances (from 2015-2017) - Likely abandoned:**
- i-0f755cb1 (c3.xlarge) - Running since 2015 (9+ years!)
- i-8af05a0d (m3.medium) - Running since 2016 (8+ years!)
- i-5b08ffb7 (t2.micro) - Running since 2017
- i-9e859f4e (t2.micro) - Running since 2017
- i-efc4fb3a (t2.micro) - Running since 2017
- i-a915407c (t2.medium) - Running since 2017

**Action:** Verify if still needed, if not, stop/terminate.  
**Savings:** ~$1,500/month

**Duplicate/Test instances in us-east-2 (all stopped):**
- i-09c5f37643e036865 (t2.large)
- i-05e80ed206905b62f (t2.large)
- i-0a4890503b8ec083b (t2.micro)
- i-02904074725f14fa6 (t3.medium)

**Action:** Terminate these test instances.  
**Savings:** ~$500/month

**Total Phase 1 EC2 Savings:** ~$4,000/month

---

### Priority 2: Right-Size Over-Provisioned Instances

#### Instances to Downsize (Save ~$8,000/month):

**c4.4xlarge instances (16 vCPU, $560/month each):**
- i-d87e770d - Check CPU utilization
- i-2c7f76f9 - Check CPU utilization
- i-059b953a2e312a39c - Check CPU utilization
- i-01400e7184ad7c200 - Check CPU utilization
- i-043114ca52c5e8164 - Check CPU utilization

**If CPU < 40%:** Downsize to c4.2xlarge (save $280/month each = $1,400 total)  
**If CPU < 20%:** Downsize to c4.xlarge (save $420/month each = $2,100 total)

**m4.2xlarge instances (8 vCPU, $336/month each):**
- i-d75fe03e - Check utilization
- i-0d6e0ade - Check utilization

**If CPU < 40%:** Downsize to m4.xlarge (save $168/month each = $336 total)

**c4.2xlarge instances ($350/month each):**
- i-fafc372e - Check utilization
- i-88be045c - Check utilization
- i-03969fef458cd4167 - Check utilization

**If CPU < 40%:** Downsize to c4.xlarge (save $175/month each = $525 total)

**Total Right-Sizing Savings:** ~$4,000-8,000/month

---

### Priority 3: Optimize RDS Databases

#### Production Databases - Reserved Instances (Save ~$8,000/month):

**Purchase 1-year Reserved Instances for:**
- doppio-prod (db.r7g.2xlarge) - Save 40% = $320/month
- doppio-prod-us-east-1d (db.r7g.2xlarge) - Save 40% = $320/month
- production-db-macchiato (db.m5.xlarge Multi-AZ) - Save 40% = $200/month
- production-db-mfa-5-7 (db.m5.large Multi-AZ) - Save 40% = $120/month
- prod-replica-57b (db.m5.xlarge) - Save 40% = $160/month
- prod-replica-8 (db.m7g.xlarge) - Save 40% = $160/month

**Total RI Savings:** ~$1,280/month

#### Staging Databases - Stop at Night (Save ~$3,000/month):

**Implement auto-stop schedule (7pm-7am + weekends):**
- staging-cluster (db.t4g.large)
- staging-cluster-us-east-1d (db.t4g.large)
- staging-db-macchiato (db.t3.small)
- staging-db-mfa (db.t3.micro)
- staging-replica-57 (db.t3.medium)
- staging-replica-8 (db.t3.medium)
- stagingdev-doppio-1-one (db.t4g.medium)
- stagingdev-doppio-1-two (db.t4g.medium)
- staging-database-test (db.t4g.large)
- staging-database-test-us-west2b (db.t4g.large)

**Savings:** 70% uptime reduction = ~$3,000/month

**Total RDS Savings:** ~$4,280/month

---

### Priority 4: Optimize OpenSearch Domains

#### Production OpenSearch - Right-Size (Save ~$3,000/month):

**onehub-search-production:**
- Current: 2x m4.2xlarge.search + 1.5TB storage = ~$5,000/month
- Recommended: 2x r6g.xlarge.search + 1TB storage = ~$2,000/month
- **Savings:** ~$3,000/month

#### Staging OpenSearch - Downsize (Save ~$2,000/month):

**opensearch-13-staging:**
- Current: 3x r6g.large.search = ~$1,500/month
- Recommended: 1x r6g.large.search = ~$500/month
- **Savings:** ~$1,000/month

**search-staging:**
- Current: 2x m4.large.search = ~$1,000/month
- Recommended: 1x t3.medium.search = ~$200/month
- **Savings:** ~$800/month

**stagingdev-opensearch:**
- Current: 1x r6g.large.search = ~$500/month
- Recommended: Stop when not in use or use t3.small.search = ~$100/month
- **Savings:** ~$400/month

**Total OpenSearch Savings:** ~$5,200/month

---

### Priority 5: Consolidate ElastiCache Clusters

#### Production ElastiCache - Reserved Nodes (Save ~$1,500/month):

**Purchase Reserved Nodes for:**
- production-a-redis (cache.m4.large)
- production-a-redis-p (cache.m4.large)
- production-c-redis (cache.m4.large)
- production-c-redis-p (cache.m4.large)
- production-memcache-cluster (2x cache.r6g.large)
- production-redis (cache.r5.large)
- production-replica (cache.r5.large)
- location-redis (cache.r5.large)

**Savings:** 40% discount = ~$1,500/month

#### Staging ElastiCache - Consolidate (Save ~$1,000/month):

**Current staging clusters (8 clusters):**
- staging-a-redis, staging-a-redis-p, staging-c-redis-p, staging-redis
- staging-cache, staging-memcache-cluster
- staging-redis (us-west-2), staging-replica (us-west-2)

**Recommended:** Consolidate to 2-3 clusters, stop when not in use  
**Savings:** ~$1,000/month

**Total ElastiCache Savings:** ~$2,500/month

---

## 📅 Phase 2: Short-Term Actions (Weeks 2-4)

### Action 1: Implement Auto-Scaling

**EC2 Auto-Scaling Groups:**
- Create ASGs for web/app tiers
- Scale down during off-peak hours (nights/weekends)
- Target: 30-50% reduction in running instances during off-peak

**Estimated Savings:** $3,000-5,000/month

### Action 2: Purchase Compute Savings Plans

**Analyze steady-state compute usage:**
- Commit to $500-1,000/month in Compute Savings Plans
- Get 30-50% discount on flexible compute

**Estimated Savings:** $2,000-3,000/month

### Action 3: Optimize EBS Volumes

**Actions:**
- Delete unattached volumes (likely 20-30 volumes)
- Migrate all gp2 to gp3 (20% savings)
- Right-size over-provisioned volumes

**Estimated Savings:** $500-1,000/month

### Action 4: Implement S3 Lifecycle Policies

**Actions:**
- Move infrequently accessed data to S3 IA
- Archive old data to Glacier
- Delete old logs/backups

**Estimated Savings:** $1,000-2,000/month

---

## 📊 Phase 3: Medium-Term Actions (Months 2-3)

### Action 1: Migrate to Graviton Instances

**Target instances for Graviton migration:**
- All m4/m5 instances → m6g/m7g (20% cost savings)
- All c4/c5 instances → c6g/c7g (20% cost savings)
- All r5 instances → r6g/r7g (20% cost savings)

**Estimated Savings:** $4,000-6,000/month

### Action 2: Implement Reserved Instances (3-year)

**For long-term stable workloads:**
- Production EC2 instances
- Production RDS databases
- Production ElastiCache nodes

**Estimated Savings:** $5,000-8,000/month (additional to 1-year RIs)

### Action 3: Review and Optimize Data Transfer

**Actions:**
- Analyze VPC Flow Logs for data transfer patterns
- Reduce cross-region data transfer
- Use VPC endpoints for AWS services
- Implement CloudFront for static content

**Estimated Savings:** $1,000-3,000/month

---

## 💰 Total Savings Summary

### Phase 1 (Week 1) - Immediate Actions:
| Action | Monthly Savings |
|--------|----------------|
| Stop unused EC2 instances | $4,000 |
| Right-size over-provisioned instances | $6,000 |
| RDS Reserved Instances + auto-stop | $4,280 |
| OpenSearch optimization | $5,200 |
| ElastiCache consolidation | $2,500 |
| **Phase 1 Total** | **$21,980/month** |

### Phase 2 (Weeks 2-4) - Short-Term Actions:
| Action | Monthly Savings |
|--------|----------------|
| Auto-scaling implementation | $4,000 |
| Compute Savings Plans | $2,500 |
| EBS optimization | $750 |
| S3 lifecycle policies | $1,500 |
| **Phase 2 Total** | **$8,750/month** |

### Phase 3 (Months 2-3) - Medium-Term Actions:
| Action | Monthly Savings |
|--------|----------------|
| Graviton migration | $5,000 |
| 3-year Reserved Instances | $6,500 |
| Data transfer optimization | $2,000 |
| **Phase 3 Total** | **$13,500/month** |

---

## 🎯 Final Results

| Metric | Current | After Phase 1 | After Phase 2 | After Phase 3 |
|--------|---------|---------------|---------------|---------------|
| Monthly Cost | $57,452 | $35,472 | $26,722 | $13,222 |
| Monthly Savings | - | $21,980 | $30,730 | $44,230 |
| Annual Savings | - | $263,760 | $368,760 | $530,760 |
| Cost Reduction | - | 38% | 53% | 77% |

**Conservative Target:** $30,000-35,000/month (40-50% reduction)  
**Aggressive Target:** $15,000-20,000/month (65-75% reduction)

---

## ✅ Implementation Checklist

### Week 1:
- [ ] Snapshot and terminate stopped instances (16 instances)
- [ ] Verify and stop old running instances (6 instances from 2015-2017)
- [ ] Analyze CPU utilization for c4.4xlarge instances
- [ ] Create right-sizing plan for over-provisioned instances
- [ ] Purchase 1-year RDS Reserved Instances
- [ ] Implement auto-stop schedule for staging databases
- [ ] Create OpenSearch right-sizing plan
- [ ] Consolidate staging ElastiCache clusters

### Week 2:
- [ ] Execute instance right-sizing (downsize 10-15 instances)
- [ ] Migrate production OpenSearch to r6g instances
- [ ] Downsize staging OpenSearch domains
- [ ] Purchase ElastiCache Reserved Nodes
- [ ] Identify unattached EBS volumes

### Week 3:
- [ ] Create EC2 Auto-Scaling Groups
- [ ] Implement auto-scaling policies
- [ ] Delete unattached EBS volumes
- [ ] Migrate gp2 to gp3 volumes
- [ ] Analyze Compute Savings Plans recommendations

### Week 4:
- [ ] Purchase Compute Savings Plans
- [ ] Implement S3 lifecycle policies
- [ ] Review and optimize S3 bucket policies
- [ ] Document all changes and savings

### Month 2:
- [ ] Plan Graviton migration
- [ ] Test applications on Graviton instances
- [ ] Begin Graviton migration (non-production first)
- [ ] Analyze 3-year RI opportunities

### Month 3:
- [ ] Complete Graviton migration
- [ ] Purchase 3-year Reserved Instances
- [ ] Implement data transfer optimizations
- [ ] Set up cost anomaly detection
- [ ] Establish monthly cost review process

---

## 🚨 Risk Mitigation

### Before Making Changes:

1. **Snapshot Everything:**
   - Take EBS snapshots before terminating instances
   - Backup RDS databases before modifications
   - Document current configurations

2. **Test in Staging First:**
   - Test right-sizing in staging environment
   - Verify application performance
   - Monitor for 1 week before production

3. **Communicate Changes:**
   - Notify development teams
   - Schedule maintenance windows
   - Have rollback plan ready

4. **Monitor Closely:**
   - Set up CloudWatch alarms
   - Monitor application performance
   - Track cost changes daily

---

## 📞 Support & Escalation

### If Issues Arise:

**Performance Degradation:**
- Immediately scale back up
- Analyze CloudWatch metrics
- Adjust instance sizes as needed

**Application Errors:**
- Check application logs
- Verify connectivity
- Rollback if necessary

**Cost Increases:**
- Review Cost Explorer daily
- Check for unexpected resources
- Investigate anomalies immediately

---

## 📈 Success Metrics

### Track Weekly:
- Total monthly cost (target: decrease by 10% per week)
- Number of running instances (target: decrease by 15%)
- Average CPU utilization (target: increase to 50-70%)
- Application performance (target: maintain or improve)

### Track Monthly:
- Total cost savings achieved
- Reserved Instance utilization
- Savings Plans utilization
- Cost per transaction/user

---

**Next Steps:** Review this plan with stakeholders and begin Phase 1 implementation.

**Questions?** Contact the FinOps team or AWS account manager for assistance.
