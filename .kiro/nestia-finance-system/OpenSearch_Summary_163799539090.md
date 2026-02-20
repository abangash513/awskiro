# OpenSearch Optimization Summary
**AWS Account:** 163799539090  
**Date:** December 22, 2025

---

## Current State

### Domain
**cortado-stage-os** (Staging/Non-Production)
- **Region:** us-west-2
- **Engine:** OpenSearch 1.3
- **Instances:** 1x m5.4xlarge.search (16 vCPU, 64 GB RAM)
- **Master Nodes:** None (no dedicated masters)
- **Storage:** 500 GB gp2 (old generation)
- **Availability:** Single-AZ, Single Node
- **Auto-Tune:** Enabled (but not using off-peak window)

### Monthly Cost
**~$1,100**

**Cost Breakdown:**
- Data Node: 1x m5.4xlarge @ $1.472/hr = $1,075/month
- Storage: 500 GB gp2 @ $0.10/GB = $50/month
- **Total: ~$1,125/month**

### Issues
🟡 **Staging running 24/7** - Unnecessary cost for non-production  
🟡 **Massive over-provisioning** - m5.4xlarge for staging is overkill  
🟡 **Old m5 instances** - Previous generation, more expensive  
🟡 **No encryption** - Not critical for staging but best practice  
🟡 **Using gp2 storage** - 20% more expensive than gp3  
🟡 **Old OpenSearch version** - 1.3 (current is 2.x)  
🟡 **No HTTPS enforcement** - Insecure connections allowed  
🟡 **Service update pending** - OpenSearch_1_3_R20251106-P1 available

---

## Optimization Plan

### Key Insight
This is a **staging environment** running on a **production-sized instance** 24/7. Massive over-provisioning!

**Reality Check:**
- Using same instance size as production domains in other accounts
- Staging workload rarely needs 16 vCPU and 64 GB RAM
- Running continuously when likely only needed during business hours
- Costing more than necessary by 80-90%

### Expected Results
- **New Monthly Cost:** $50 - $150
- **Savings:** $975 - $1,075/month (87-96% reduction)
- **Annual Savings:** $11,700 - $12,900

---

## Optimization Strategy

### Option 1: Right-Size + Schedule (Recommended) ⭐
**Savings:** $1,050/month (93%) | **Risk:** Low

**Aggressive optimization for staging:**
- Downsize to 1x t3.medium.search (2 vCPU, 4 GB RAM)
- Reduce storage to 100 GB gp3
- Add automated scheduling (M-F 8am-6pm)
- **New cost:** ~$75/month (with scheduling)

**Why this works:**
- Staging rarely needs production-grade resources
- t3.medium sufficient for most staging workloads
- 70% time savings from scheduling
- 100 GB adequate for staging data

### Option 2: Moderate Right-Size + Schedule
**Savings:** $950/month (84%) | **Risk:** Low

**Conservative approach:**
- Downsize to 1x m6g.large.search (2 vCPU, 8 GB RAM)
- Reduce storage to 200 GB gp3
- Add automated scheduling (M-F 8am-6pm)
- **New cost:** ~$150/month (with scheduling)

**Why this works:**
- More headroom than t3.medium
- Graviton2 for better performance
- Still massive savings vs current

### Option 3: Schedule Only (Quick Win)
**Savings:** $787/month (70%) | **Risk:** Very Low

**Minimal changes:**
- Keep current instance size
- Add automated scheduling (M-F 8am-6pm)
- Migrate storage to gp3
- **New cost:** ~$338/month

**Why start here:**
- Immediate 70% savings
- No performance risk
- Easy to implement
- Can right-size later

---

## Quick Wins (Start This Week)

### 1. Implement Automated Scheduling ⏰
**Savings:** $787/month | **Risk:** Low | **Time:** 2 hours

**Run staging only during business hours (M-F, 8am-6pm)**
- Current: 168 hours/week
- Optimized: 50 hours/week (70% reduction)

**Implementation:**
- Lambda function to start/stop domain
- EventBridge schedule (M-F 8am start, 6pm stop)
- SNS notifications for failures
- Override capability for extended testing

### 2. Migrate Storage gp2 → gp3 💾
**Savings:** $10/month | **Risk:** Low | **Time:** 30 min
```bash
aws opensearch update-domain-config --domain-name cortado-stage-os --region us-west-2 \
  --ebs-options EBSEnabled=true,VolumeType=gp3,VolumeSize=500,Iops=3000
```

### 3. Apply Service Update 🔄
**Savings:** Security/stability | **Risk:** Low | **Time:** 15 min
- Update available: OpenSearch_1_3_R20251106-P1
- Will auto-deploy on Dec 16, 2025 if not applied

### 4. Enable Off-Peak Window for Auto-Tune ⏰
**Savings:** Performance | **Risk:** Low | **Time:** 10 min
```bash
aws opensearch update-domain-config --domain-name cortado-stage-os --region us-west-2 \
  --auto-tune-options DesiredState=ENABLED,UseOffPeakWindow=true
```

---

## Detailed Optimization Roadmap

### Week 1: Automated Scheduling (Immediate Impact)
- [ ] Deploy Lambda scheduler function
- [ ] Configure EventBridge (M-F 8am-6pm PST)
- [ ] Test start/stop cycles
- [ ] Add SNS notifications
- [ ] Document override procedures
- **Savings:** $787/month

### Week 2: Storage Optimization
- [ ] Migrate storage to gp3
- [ ] Apply service update
- [ ] Enable off-peak window for Auto-Tune
- [ ] Set up cost monitoring
- **Additional Savings:** $10/month

### Week 3: Right-Sizing Analysis
- [ ] Review actual CPU/memory utilization
- [ ] Analyze query patterns and load
- [ ] Determine optimal instance size
- [ ] Plan instance downsize

### Week 4: Instance Right-Sizing
- [ ] Downsize to t3.medium or m6g.large
- [ ] Reduce storage to 100-200 GB
- [ ] Test all staging workloads
- [ ] Performance validation
- **Additional Savings:** $200-300/month

---

## Cost Comparison

| Configuration | Monthly Cost | Savings | Annual Savings |
|--------------|-------------|---------|----------------|
| **Current (24/7, m5.4xlarge)** | $1,125 | Baseline | - |
| With Scheduling Only | $338 | $787 (70%) | $9,444 |
| Right-Size + Schedule (m6g.large) | $150 | $975 (87%) | $11,700 |
| Aggressive Optimization (t3.medium) | $75 | $1,050 (93%) | $12,600 |

---

## Recommended Approach

### Phase 1: Automated Scheduling (Week 1) - DO THIS FIRST
**Investment:** 2 hours  
**Savings:** $787/month  
**Risk:** Very Low  
**Reversible:** Yes (easily disable)

**Why this first:**
- Immediate 70% cost reduction
- No performance impact during business hours
- Easy to implement and test
- Fully reversible if issues arise
- Proves the concept before right-sizing

### Phase 2: Storage Optimization (Week 2)
**Investment:** 1 hour  
**Additional Savings:** $10/month  
**Risk:** Very Low  
**Reversible:** Yes

**Quick wins:**
- gp3 migration (20% cheaper, better performance)
- Apply service update (security/stability)
- Enable off-peak window (better Auto-Tune)

### Phase 3: Right-Sizing (Week 3-4) - OPTIONAL
**Investment:** 4 hours  
**Additional Savings:** $200-300/month  
**Risk:** Low  
**Reversible:** Yes

**Consider if:**
- Staging workload is light (likely)
- Want maximum savings
- Comfortable with smaller instance

**Recommended target:** t3.medium (2 vCPU, 4 GB RAM)

---

## Implementation Details

### Automated Scheduling Setup

**Lambda Function:**
```python
# Use provided lambda-opensearch-scheduler.py
# Environment variables:
DOMAIN_NAME=cortado-stage-os
REGION=us-west-2
SNS_TOPIC_ARN=<your-sns-topic>
```

**EventBridge Rules:**
- **Start:** M-F 8:00 AM PST → Invoke Lambda with {"action": "start"}
- **Stop:** M-F 6:00 PM PST → Invoke Lambda with {"action": "stop"}

**Override Procedure:**
- Manual start: `aws lambda invoke --function-name opensearch-scheduler --payload '{"action":"start","domain":"cortado-stage-os","region":"us-west-2"}'`
- Manual stop: `aws lambda invoke --function-name opensearch-scheduler --payload '{"action":"stop","domain":"cortado-stage-os","region":"us-west-2"}'`

**Cost:** Lambda + EventBridge = ~$1/month

---

## Right-Sizing Analysis

### Current vs Recommended

**Current (Massive Over-Provisioning):**
```
Instance: m5.4xlarge (16 vCPU, 64 GB RAM)
Use Case: Staging environment
Cost: $1,075/month (24/7)
Assessment: 🔴 Extreme overkill for staging
```

**Recommended (Appropriate Sizing):**
```
Instance: t3.medium (2 vCPU, 4 GB RAM)
Use Case: Staging environment
Cost: $30/month (24/7) or $9/month (scheduled)
Assessment: ✅ Right-sized for staging workload
```

**Cost Difference:** $1,045/month savings from right-sizing alone!

### Why t3.medium is Sufficient

**Typical staging workload:**
- Intermittent queries (not continuous)
- Small data volumes (test data)
- Low concurrent users (dev team only)
- No SLA requirements
- Occasional load testing (can scale temporarily)

**t3.medium provides:**
- 2 vCPU (sufficient for staging queries)
- 4 GB RAM (adequate for small indices)
- Burstable performance (handles occasional spikes)
- 93% cost savings vs current

---

## Risk Assessment

### Very Low-Risk Activities
✅ Automated scheduling (staging only, easy rollback)  
✅ Storage migration to gp3 (rolling update, no downtime)  
✅ Service updates (automated, tested)  
✅ Off-peak window enablement (configuration change)

### Low-Risk Activities
✅ Right-sizing to t3.medium (staging environment, recreatable)  
✅ Storage reduction (staging data, can restore from snapshot)

### Considerations
- **Development team coordination:** Notify about new schedule
- **Extended testing needs:** Document override procedures
- **Weekend work:** Ensure team knows domain is stopped
- **Monitoring:** Set up alerts for failed start/stop
- **Performance testing:** Validate t3.medium handles workload

---

## Action Items

### This Week (Immediate)
1. [ ] Review with development team
2. [ ] Get approval for scheduling
3. [ ] Deploy Lambda scheduler
4. [ ] Configure EventBridge rules
5. [ ] Test start/stop functionality
6. [ ] Migrate storage to gp3

### Next Week
1. [ ] Monitor scheduled operations
2. [ ] Apply service update
3. [ ] Enable off-peak window
4. [ ] Analyze utilization for right-sizing

### Week 3-4 (Optional)
1. [ ] Right-size to t3.medium
2. [ ] Reduce storage to 100 GB
3. [ ] Test all staging workloads
4. [ ] Performance validation

### Ongoing
1. [ ] Weekly cost review
2. [ ] Monitor for failed starts/stops
3. [ ] Adjust schedule if needed
4. [ ] Consider deletion for extended non-use

---

## ROI Analysis

| Investment | Return | Payback |
|------------|--------|---------|
| $50 (Lambda + setup) | $9,444/year (scheduling only) | <2 days |
| 2 hours (team time) | 70% cost reduction | Immediate |
| 6 hours (full optimization) | $12,600/year (with right-sizing) | <1 week |

**Break-even:** Less than 2 days for scheduling, less than 1 week for full optimization!

---

## Comparison with Similar Accounts

### Account 145462881720 (Similar Staging)
- Domain: cortado-staging
- Instance: 2x c4.large + 3x m5.large masters
- Cost: $457/month
- **This account is 2.5x more expensive!**

### Account 015815251546 (Production)
- Domain: cortado-prod-os
- Instance: 1x m5.4xlarge (same as this staging!)
- Cost: $1,125/month
- **This staging costs the same as their production!**

### Key Insight
**This staging environment is sized like production but costs more than it should.**

---

## Recommendations Priority

### 🟢 IMMEDIATE (Do This Week)
1. **Implement automated scheduling** - 70% savings, very low risk
2. Migrate storage to gp3
3. Apply service update
4. Enable off-peak window

### 🟡 HIGH (Next 2 Weeks)
5. **Right-size to t3.medium** - Additional 23% savings
6. Reduce storage to 100 GB
7. Set up cost monitoring

### 🔵 OPTIONAL (Evaluate)
8. Upgrade to OpenSearch 2.x
9. Consider on-demand deletion for extended non-use
10. Evaluate if staging is still needed at this scale

---

## Bottom Line

**Current State:** Staging environment massively over-provisioned and running 24/7  
**Target State:** Right-sized with scheduled operation (business hours only)  
**Investment:** 2-6 hours, ~$50  
**Return:** $9,444-12,600/year (70-93% reduction)

### Key Benefits
✅ **Cost:** 70% reduction with scheduling alone (93% with right-sizing)  
✅ **Simplicity:** Easy to implement and reverse  
✅ **Functionality:** No impact during business hours  
✅ **Environment:** Appropriate sizing for staging workload

### Reality Check
**You're spending $1,125/month on a staging environment that could cost $75/month.**

That's $1,050/month ($12,600/year) being wasted on over-provisioned staging infrastructure.

---

## Next Steps

1. **Today:** Review with development team
2. **This Week:** Deploy automated scheduling (save $787/month immediately)
3. **Next Week:** Migrate to gp3 and apply updates
4. **Week 3-4:** Right-size to t3.medium (save additional $263/month)
5. **Ongoing:** Track savings and adjust as needed

**Contact:** AWS Solutions Architect Team  
**Support:** Lambda scheduler script available in project files

---

**💡 KEY INSIGHT:** This staging environment is sized like production. Right-sizing + scheduling = 93% cost savings ($12,600/year)!

---

## Service Update Notice

**Pending Update:** OpenSearch_1_3_R20251106-P1  
**Auto-Deploy Date:** December 16, 2025  
**Action Required:** Apply manually before auto-deploy or let it auto-apply

**Recommendation:** Apply during next maintenance window (after scheduling is implemented)
