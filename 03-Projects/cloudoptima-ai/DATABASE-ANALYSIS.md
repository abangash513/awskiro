# Database Analysis for CloudOptimaAI

## Azure Free Tier PostgreSQL

### What's Available FREE for 12 Months
With an Azure free account, you get:
- **750 hours/month** of Burstable B1MS instance (enough to run 24/7)
- **32 GB storage**
- **32 GB backup storage**
- **12 months free** for new Azure customers

### B1MS Specifications
- **vCPUs**: 1 vCore
- **RAM**: 2 GB
- **Storage**: Up to 32 GB (free tier)
- **Connections**: ~85 max user connections (100 total - 15 reserved)
- **Performance**: Burstable (uses CPU credits)
- **Cost after free tier**: ~$0.02/hour (~$15/month)

Source: [Microsoft Learn - Azure Free PostgreSQL](https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/how-to-deploy-on-azure-free-account)

---

## Current App Database Requirements

### Your Application Has 10 Tables:
1. **Organization** - Multi-tenant org data
2. **User** - User accounts and auth
3. **CloudConnection** - Azure/AWS credentials
4. **Resource** - Cloud resources inventory
5. **CostData** - Cost and billing data (largest table)
6. **Recommendation** - Cost optimization recommendations
7. **AIWorkload** - AI/ML workload tracking
8. **Budget** - Budget definitions
9. **Alert** - Cost alerts
10. **AuditLog** - Activity logging

### Database Technology Stack:
- **Current**: Azure SQL Server (not working)
- **Needed**: PostgreSQL with async support
- **ORM**: SQLAlchemy with asyncpg
- **Already in requirements.txt**: ✅ asyncpg, psycopg2-binary

---

## Is B1MS Sufficient for Your App?

### ✅ YES - B1MS is Perfect for MVP/Development

**Why it works:**
1. **Low initial data volume**
   - Starting with 0 users
   - Cost data grows gradually
   - 32 GB is plenty for first 6-12 months

2. **Moderate transaction load**
   - Celery workers batch process cost data
   - Not real-time transactional system
   - Burstable CPU handles periodic spikes

3. **Connection pooling**
   - FastAPI + SQLAlchemy uses connection pooling
   - 85 connections is sufficient for:
     - Backend API (10-20 connections)
     - Celery workers (10-20 connections)
     - Celery beat (2-5 connections)

4. **Cost-effective**
   - FREE for 12 months
   - Only $15/month after
   - Can upgrade to General Purpose later without downtime

### When to Upgrade

Upgrade to **General Purpose (D2ds_v4)** when:
- Storage exceeds 25 GB
- Consistent high CPU usage (>80%)
- More than 50 concurrent users
- Query performance degrades
- Need more than 85 connections

**General Purpose D2ds_v4**: 2 vCores, 8 GB RAM, ~$100/month

---

## Comparison: Azure SQL vs PostgreSQL

| Feature | Azure SQL (Current) | PostgreSQL (Recommended) |
|---------|-------------------|------------------------|
| **Free Tier** | ❌ No free tier | ✅ 12 months free |
| **Async Support** | ⚠️ aioodbc (problematic) | ✅ asyncpg (native) |
| **Cost (Basic)** | ~$5/month | FREE → $15/month |
| **Connection Issues** | ❌ Timeout errors | ✅ Reliable |
| **Your App Support** | ✅ Already configured | ✅ Already configured |
| **Migration Effort** | N/A | 30 minutes |

---

## Recommendation

### Switch to PostgreSQL Flexible Server B1MS

**Reasons:**
1. ✅ **FREE for 12 months** (vs $5/month for SQL)
2. ✅ **Better async support** (asyncpg is rock-solid)
3. ✅ **Fixes current connection issues**
4. ✅ **Your app already supports it** (asyncpg in requirements.txt)
5. ✅ **More than sufficient** for MVP and first year
6. ✅ **Easy to upgrade** when you need more resources

**Migration Steps:**
1. Delete Azure SQL Server (5 min)
2. Create PostgreSQL Flexible Server B1MS (10 min)
3. Update connection string in Terraform (2 min)
4. Redeploy backend container (5 min)
5. Initialize database schema (2 min)
6. Test end-to-end (5 min)

**Total Time**: ~30 minutes

---

## Storage Capacity Planning

### 32 GB Breakdown:
- **System databases**: ~500 MB
- **Application tables**: ~100 MB (initial)
- **Cost data growth**: ~50-100 MB/month (depends on resources)
- **Indexes**: ~20% of data size
- **Backups**: Separate 32 GB allocation

### Estimated Timeline:
- **Months 1-6**: 1-5 GB used
- **Months 7-12**: 5-15 GB used
- **Year 2**: 15-30 GB used (still within free tier storage)

---

## Final Answer

**Use PostgreSQL Flexible Server B1MS (Burstable)**

- ✅ FREE for 12 months
- ✅ 1 vCore, 2 GB RAM
- ✅ 32 GB storage
- ✅ Perfect for your app
- ✅ Fixes all current issues
- ✅ Can run 24/7 within free hours
- ✅ Easy to upgrade later

**After 12 months**: ~$15/month (still cheaper than Azure SQL Basic at $5/month + better performance)
