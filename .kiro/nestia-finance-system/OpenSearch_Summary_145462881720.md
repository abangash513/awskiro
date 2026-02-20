# OpenSearch Optimization Summary
**AWS Account:** 145462881720  
**Date:** December 22, 2025

---

## Current State

### Domain
**cortado-staging** (Staging/Non-Production)
- **Engine:** OpenSearch 1.3
- **Instances:** 2x c4.large.search (2 vCPU, 3.75 GB RAM each)
- **Master Nodes:** 3x m5.large.search
- **Storage:** 10 GB gp2 (old generation)
- **Availability:** Single-AZ
- **Logs:** CloudWatch application logs enabled

### Monthly Cost
**~$450**

**Cost Breakdown:**
- Data Nodes: 2x c4.large @ $0.105/hr = $153/month
- Master Nodes: 3x m5.large @ $0.136/hr = $298/month
- Storage: 10 GB gp2 @ $0.10/GB = $1/month
- CloudWatch Logs: ~$5/month
- **Total: ~$457/month**

### Issues
🟡 **Staging running 24/7** - Unnecessary cost for non-production  
🟡 **Old c4 instances** - 3 generations old, inefficient  
🟡 **No encryption** - Not critical for staging but best practice  
🟡 **Using gp2 storage** - 20% more expensive than gp3  
🟡 **Dedicated masters for staging** - Overkill for non-production  
🟡 **Old OpenSearch version** - 1.3 (current is 2.x)

---

## Optimization Plan

### Key Insight
This is a **staging environment** running with production-grade resources 24/7. Massive savings opportunity!

### Expected Results
- **New Monthly Cost:** $50 - $100
- **Savings:** $350 - $400/month (78-87% reduction)
- **Annual Savings:** $4,200 - $4,800

---

## Optimization Strategy

### Option 1: Automated Scheduling (Recommended) ⭐
**Savings:** $350/month (77%) | **Risk:** Low

**Run staging only during business hours (M-F, 8am-6pm)**
- Current: 168 hours/week
- Optimized: 50 hours/week (70% reduction)
- Savings: ~$350/month

**Implementation:**
- Lambda function to start/stop domain
- EventBridge schedule (M-F 8am start, 6pm stop)
- SNS notifications for failures
- Override capability for extended testing

### Option 2: Right-Size + Schedule
**Savings:** $400/month (87%) | **Risk:** Low

**Simplify configuration:**
- Remove dedicated master nodes (not needed for staging)
- Downsize to 1x t3.medium.search
- Add automated scheduling
- **New cost:** ~$50/month (with scheduling)

### Option 3: Delete & Recreate On-Demand
**Savings:** $450/month (98%) | **Risk:** Medium

**For truly intermittent use:**
- Delete domain when not needed
- Recreate from snapshot when needed
- Use Infrastructure as Code (Terraform/CloudFormation)
- **Cost:** Only when running (~$10-20/month)

---

## Quick Wins (Start This Week)

### 1. Implement Automated Scheduling ⏰
**Savings:** $350/month | **Risk:** Low | **Time:** 2 hours

**Steps:**
1. Deploy Lambda scheduler function
2. Configure EventBridge rules (M-F 8am-6pm)
3. Test start/stop functionality
4. Add SNS notifications

**Script:** Use `lambda-opensearch-scheduler.py` (provided)

### 2. Migrate Storage gp2 → gp3 💾
**Savings:** $0.20/month | **Risk:** Low | **Time:** 30 min
```bash
aws opensearch update-domain-config --domain-name cortado-staging \
  --ebs-options EBSEnabled=true,VolumeType=gp3,VolumeSize=10
```

### 3. Apply Service Update 🔄
**Savings:** Security/stability | **Risk:** Low | **Time:** 15 min
- Update available: OpenSearch_1_3_R20251106-P1

### 4. Enable Off-Peak Window ⏰
**Savings:** Performance | **Risk:** Low | **Time:** 10 min
```bash
aws opensearch update-domain-config --domain-name cortado-staging \
  --auto-tune-options DesiredState=ENABLED,UseOffPeakWindow=true
```

---

## Detailed Optimization Roadmap

### Week 1: Automated Scheduling
- [ ] Deploy Lambda scheduler
- [ ] Configure EventBridge (M-F 8am-6pm EST)
- [ ] Test start/stop cycles
- [ ] Add SNS notifications
- [ ] Document override procedures
- **Savings:** $350/month

### Week 2: Right-Sizing (Optional)
- [ ] Remove dedicated master nodes
- [ ] Downsize to t3.medium
- [ ] Migrate storage to gp3
- [ ] Test all staging workloads
- **Additional Savings:** $50/month

### Week 3: Optimization & Monitoring
- [ ] Apply service update
- [ ] Enable off-peak window
- [ ] Set up cost monitoring
- [ ] Document new procedures

---

## Cost Comparison

| Configuration | Monthly Cost | Savings | Annual Savings |
|--------------|-------------|---------|----------------|
| **Current (24/7)** | $457 | Baseline | - |
| With Scheduling (M-F 8am-6pm) | $107 | $350 (77%) | $4,200 |
| Right-Sized + Scheduled | $50 | $407 (89%) | $4,884 |
| On-Demand (Delete/Recreate) | $10-20 | $437 (96%) | $5,244 |

---

## Recommended Approach

### Phase 1: Automated Scheduling (Week 1)
**Investment:** 2 hours  
**Savings:** $350/month  
**Risk:** Low  
**Reversible:** Yes (easily disable)

**Why this first:**
- Immediate 77% cost reduction
- No impact on functionality during business hours
- Easy to implement and test
- Fully reversible if issues arise

### Phase 2: Right-Sizing (Week 2-3) - Optional
**Investment:** 4 hours  
**Additional Savings:** $50/month  
**Risk:** Low  
**Reversible:** Yes

**Consider if:**
- Staging workload is light
- Don't need dedicated masters
- Want maximum savings

---

## Implementation Details

### Automated Scheduling Setup

**Lambda Function:**
```python
# Use provided lambda-opensearch-scheduler.py
# Environment variables:
DOMAIN_NAME=cortado-staging
SNS_TOPIC_ARN=<your-sns-topic>
```

**EventBridge Rules:**
- **Start:** M-F 8:00 AM EST → Invoke Lambda with {"action": "start"}
- **Stop:** M-F 6:00 PM EST → Invoke Lambda with {"action": "stop"}

**Override Procedure:**
- Manual start: `aws lambda invoke --function-name opensearch-scheduler --payload '{"action":"start"}'`
- Manual stop: `aws lambda invoke --function-name opensearch-scheduler --payload '{"action":"stop"}'`

**Cost:** Lambda + EventBridge = ~$1/month

---

## Risk Assessment

### Low-Risk Activities
✅ Automated scheduling (staging only, easy rollback)  
✅ Storage migration (rolling update, no downtime)  
✅ Service updates (automated)  
✅ Right-sizing (staging environment, recreatable)

### Considerations
- **Development team coordination:** Notify about new schedule
- **Extended testing needs:** Document override procedures
- **Weekend work:** Ensure team knows domain is stopped
- **Monitoring:** Set up alerts for failed start/stop

---

## Action Items

### This Week (Immediate)
1. [ ] Review with development team
2. [ ] Get approval for scheduling
3. [ ] Deploy Lambda scheduler
4. [ ] Configure EventBridge rules
5. [ ] Test start/stop functionality

### Next Week
1. [ ] Monitor scheduled operations
2. [ ] Migrate storage to gp3
3. [ ] Apply service update
4. [ ] Evaluate right-sizing option

### Ongoing
1. [ ] Weekly cost review
2. [ ] Monitor for failed starts/stops
3. [ ] Adjust schedule if needed
4. [ ] Consider deletion for extended non-use

---

## ROI Analysis

| Investment | Return | Payback |
|------------|--------|---------|
| $50 (Lambda + setup) | $4,200/year | <1 week |
| 2 hours (team time) | 77% cost reduction | Immediate |

**Break-even:** Less than 1 week!

---

## Comparison with Production Account

**Production (946447852237):**
- cortado-production-os: $2,501/month
- Security issues, needs encryption

**Staging (145462881720):**
- cortado-staging: $457/month
- Over-provisioned, needs scheduling

**Combined Opportunity:**
- Current: $2,958/month
- Optimized: $1,550/month
- **Total Savings: $1,408/month (48%)**
- **Annual Savings: $16,896**

---

## Recommendations Priority

### 🟢 IMMEDIATE (Do This Week)
1. **Implement automated scheduling** - 77% savings, low risk
2. Migrate storage to gp3
3. Apply service update

### 🟡 SOON (Next 2 Weeks)
4. Consider right-sizing (remove masters, downsize)
5. Enable off-peak window
6. Set up cost monitoring

### 🔵 OPTIONAL (Evaluate)
7. Upgrade to OpenSearch 2.x
8. Consider on-demand deletion for extended non-use
9. Evaluate if staging is still needed

---

## Bottom Line

**Current State:** Staging environment running 24/7 with production-grade resources  
**Target State:** Scheduled operation (business hours only)  
**Investment:** 2 hours, ~$50  
**Return:** $4,200/year (77% reduction)

### Key Benefits
✅ **Cost:** 77% reduction with scheduling alone  
✅ **Simplicity:** Easy to implement and reverse  
✅ **Functionality:** No impact during business hours  
✅ **Environment:** Appropriate sizing for staging

---

## Next Steps

1. **Today:** Review with development team
2. **This Week:** Deploy automated scheduling
3. **Next Week:** Monitor and optimize further
4. **Ongoing:** Track savings and adjust as needed

**Contact:** AWS Solutions Architect Team  
**Support:** Lambda scheduler script provided in project files

---

**💡 KEY INSIGHT:** Staging environments don't need to run 24/7. Save 77% with simple scheduling!
