# OpenSearch Optimization Summary
**AWS Account:** 198161015548  
**Date:** December 22, 2025

---

## Current State

### Domains
- **onehub-search-production** - Elasticsearch 7.4, 2x m4.2xlarge, 1,536 GB gp2
- **opensearch-13-staging** - OpenSearch 1.3, 3x r6g.large (Multi-AZ + Standby)
- **search-staging** - Elasticsearch 7.4, 2x m4.large, 50 GB gp2

### Monthly Cost
**$2,204**

### Key Issues
- Production lacks encryption and Multi-AZ
- Two staging environments (redundant)
- Old m4 instances (expensive)
- Using gp2 storage (20% more than gp3)
- No Index Lifecycle Management

---

## Optimization Plan

### 2-Month Timeline
- **Month 1:** Storage migration, ILM, security baseline
- **Month 2:** Consolidate staging, upgrade production

### Expected Results
- **New Monthly Cost:** $1,020
- **Savings:** $1,184/month (54% reduction)
- **Annual Savings:** $14,208

---

## Quick Wins (Start Immediately)

### 1. Migrate Storage gp2 → gp3
**Savings:** $35/month | **Risk:** Low | **Time:** 1 hour
```bash
aws opensearch update-domain-config --domain-name search-staging \
  --ebs-options EBSEnabled=true,VolumeType=gp3,VolumeSize=50
```

### 2. Enable Index Lifecycle Management
**Savings:** $50-100/month | **Risk:** Low | **Time:** 2 hours
- Define retention policies (e.g., delete data >90 days)
- Prevent uncontrolled storage growth

### 3. Enable Auto-Tune on Production
**Savings:** Performance | **Risk:** Low | **Time:** 30 min
```bash
aws opensearch update-domain-config --domain-name onehub-search-production \
  --auto-tune-options DesiredState=ENABLED
```

---

## Major Changes (Month 2)

### Consolidate Staging Domains
- Merge search-staging into opensearch-13-staging
- Right-size to 2x t3.medium (Single-AZ)
- Add automated scheduling (M-F 8am-6pm only)
- **Savings:** $1,002/month

### Upgrade Production
- Switch to m6g instances (Graviton2)
- Enable Multi-AZ for high availability
- Enable encryption at rest
- **Savings:** $180/month

---

## Action Items

### This Week
1. Review this summary with stakeholders
2. Get approval to proceed
3. Run backup script: `./scripts/backup-opensearch-config.sh`
4. Set baseline: `./scripts/track-opensearch-costs.sh 30`

### Next Week
1. Migrate storage to gp3 (staging first, then production)
2. Implement ILM policies
3. Enable Auto-Tune

---

## ROI

| Investment | Return | Payback |
|------------|--------|---------|
| $300 (project costs) | $14,208/year | <1 month |
| ~80 hours (team time) | 54% cost reduction | Immediate |

---

## Risk Level
🟢 **LOW** - Most changes are low-risk with easy rollbacks

**High-risk activities** (Week 7):
- Production instance upgrade (weekend window required)
- Encryption enablement (blue/green deployment)

---

## Files Included
- `README.md` - Full project overview
- `QUICK_START_GUIDE.md` - 30-minute onboarding
- `OpenSearch_Analysis_Account_198161015548.md` - Complete analysis
- `OpenSearch_Optimization_Roadmap_2Month.md` - Detailed plan
- `OpenSearch_Project_Tracker.md` - Task tracking
- `scripts/` - Automation tools

---

## Bottom Line

**Spend 2 months optimizing → Save $14,000+ per year**

✅ Lower costs (54% reduction)  
✅ Better security (encryption enabled)  
✅ Improved performance (15-20% faster)  
✅ Higher availability (Multi-AZ)

**Ready to start?** Read `QUICK_START_GUIDE.md`
