# Option 1: TRUE FREE Hybrid Deployment - Complete Plan

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Azure Free Tier                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  B1S VM (FREE - 750 hours/month)                 │  │
│  │  ├── Docker Engine                               │  │
│  │  ├── Backend API (FastAPI) :8000                 │  │
│  │  ├── Celery Worker                               │  │
│  │  ├── Celery Beat                                 │  │
│  │  └── Redis (Docker) :6379                        │  │
│  └──────────────────────────────────────────────────┘  │
│                          ↓                              │
│  ┌──────────────────────────────────────────────────┐  │
│  │  PostgreSQL Flexible Server B1MS (FREE)          │  │
│  │  - 1 vCore, 2 GB RAM                             │  │
│  │  - 32 GB storage                                 │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │  App Service Free Tier                           │  │
│  │  - Frontend (React static files)                 │  │
│  │  - 1 GB storage, 60 CPU min/day                  │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Resource Verification

### ✅ What's FREE
1. **B1S Virtual Machine**
   - 750 hours/month (31.25 days × 24 hours = 750 hours) ✅
   - 1 vCPU, 1 GB RAM
   - Linux (Ubuntu 22.04 LTS)
   - **Runs 24/7 within free tier**

2. **PostgreSQL Flexible Server B1MS**
   - 750 hours/month ✅
   - 1 vCore, 2 GB RAM
   - 32 GB storage
   - 32 GB backup
   - **Runs 24/7 within free tier**

3. **App Service Free Tier (F1)**
   - 10 apps
   - 1 GB storage
   - 60 CPU minutes/day
   - 165 MB RAM
   - **Sufficient for static React app**

4. **Virtual Network**
   - 50 VNets (always free)

5. **Bandwidth**
   - 15 GB outbound/month (12 months free)

### ❌ What We're REMOVING (to stay free)
- Container Instances → VM
- Azure Container Registry → Build on VM
- Redis Cache → Self-hosted on VM
- Key Vault → Environment variables (less secure but free)
- Log Analytics → VM logs + App Service logs
- Public IPs → Use VM public IP + App Service URL

---

## Potential Issues & Solutions

### Issue 1: B1S VM Only Has 1 GB RAM
**Problem**: Running 4 services (Backend, Celery Worker, Celery Beat, Redis) on 1 GB RAM

**Analysis**:
- Backend (FastAPI): ~200-300 MB
- Celery Worker: ~200-300 MB
- Celery Beat: ~50-100 MB
- Redis: ~50-100 MB
- System: ~200 MB
- **Total: ~700-1000 MB** ⚠️ TIGHT!

**Solutions**:
1. ✅ Use Alpine Linux base images (smaller)
2. ✅ Optimize Python memory usage
3. ✅ Configure Redis maxmemory limit (50 MB)
4. ✅ Use single Celery worker (not multiple)
5. ✅ Add swap space (2 GB)
6. ⚠️ Monitor memory usage closely

**Verdict**: WORKABLE but tight. Will need optimization.

---

### Issue 2: App Service Free Tier Limitations
**Problem**: 60 CPU minutes/day, 165 MB RAM

**Analysis**:
- Frontend is static files (React build)
- Served by Node.js `serve` or similar
- Very low CPU usage (just serving files)
- 165 MB RAM sufficient for static hosting

**Solutions**:
1. ✅ Use `serve` package (lightweight)
2. ✅ Pre-build React app (no build on server)
3. ✅ Enable caching headers
4. ✅ Compress assets

**Verdict**: PERFECT for static frontend.

---

### Issue 3: VM Public IP Not Static
**Problem**: VM public IP changes on restart

**Solutions**:
1. ✅ Use Azure DNS (free for 1 zone)
2. ✅ Update DNS on VM startup script
3. ✅ Or use VM's FQDN (vmname.region.cloudapp.azure.com)
4. ✅ Frontend calls backend via FQDN

**Verdict**: SOLVED with FQDN.

---

### Issue 4: No HTTPS
**Problem**: HTTP only (no SSL)

**Solutions**:
1. ✅ Use Cloudflare Free (free SSL)
2. ✅ Or use Let's Encrypt on VM
3. ✅ App Service supports custom domains with free SSL

**Verdict**: Can add later. HTTP okay for testing.

---

### Issue 5: Database Connection from VM
**Problem**: VM needs to connect to PostgreSQL

**Solutions**:
1. ✅ PostgreSQL has public access enabled
2. ✅ Add VM public IP to firewall rules
3. ✅ Use connection string with SSL

**Verdict**: WORKS. Already configured.

---

### Issue 6: No Container Registry
**Problem**: Can't use ACR (costs money)

**Solutions**:
1. ✅ Build Docker images on VM
2. ✅ Or use Docker Hub (free for public images)
3. ✅ Or don't use Docker (run directly with systemd)

**Verdict**: Build on VM or use systemd services.

---

## Deployment Architecture Decision

### Approach A: Docker Compose on VM (Recommended)
**Pros**:
- Familiar Docker workflow
- Easy to manage
- Isolated services
- Can use existing Dockerfiles

**Cons**:
- Docker overhead (~100 MB RAM)
- More complex setup

**RAM Usage**: ~900-1000 MB (tight)

---

### Approach B: Systemd Services (More Efficient)
**Pros**:
- No Docker overhead
- Direct Python execution
- Lower RAM usage (~700-800 MB)
- Faster startup

**Cons**:
- More manual setup
- Less portable
- Need to manage dependencies

**RAM Usage**: ~700-800 MB (better)

---

### Approach C: Hybrid (Best)
**Pros**:
- Redis in Docker (easy)
- Python apps as systemd services (efficient)
- Best of both worlds

**Cons**:
- Mixed management

**RAM Usage**: ~750-850 MB (good)

**RECOMMENDATION**: Use Approach C (Hybrid)

---

## Resource Sizing

### B1S VM Optimization
```yaml
Services:
  - Backend (systemd): 250 MB
  - Celery Worker (systemd): 250 MB
  - Celery Beat (systemd): 80 MB
  - Redis (Docker): 50 MB
  - System: 200 MB
  - Swap: 2 GB (for safety)
Total RAM: ~830 MB / 1024 MB (81% usage)
```

### PostgreSQL B1MS
```yaml
Specs:
  - 1 vCore, 2 GB RAM
  - 32 GB storage
  - Max connections: 85
Usage:
  - Backend: 10 connections
  - Celery Worker: 10 connections
  - Celery Beat: 2 connections
Total: 22 / 85 connections (26% usage)
```

### App Service F1
```yaml
Specs:
  - 60 CPU min/day
  - 165 MB RAM
  - 1 GB storage
Usage:
  - Static files: ~50 MB
  - serve process: ~50 MB RAM
  - CPU: <5 min/day (just serving)
Total: Well within limits
```

---

## Deployment Steps

### Phase 1: Infrastructure (Terraform)
1. Create Resource Group
2. Create Virtual Network
3. Create PostgreSQL Flexible Server B1MS
4. Create B1S VM (Ubuntu 22.04)
5. Create App Service Plan (Free F1)
6. Create App Service (Web App)
7. Configure NSG rules
8. Configure PostgreSQL firewall

**Time**: 15 minutes

---

### Phase 2: VM Setup (Manual)
1. SSH into VM
2. Install Docker (for Redis only)
3. Install Python 3.11
4. Install PostgreSQL client
5. Install system dependencies
6. Clone repository
7. Install Python dependencies
8. Configure environment variables
9. Set up systemd services
10. Start Redis container
11. Start systemd services
12. Run database migrations

**Time**: 30 minutes

---

### Phase 3: App Service Setup (Azure Portal)
1. Build React app locally
2. Create deployment package
3. Deploy to App Service via ZIP deploy
4. Configure environment variables
5. Test frontend

**Time**: 15 minutes

---

### Phase 4: Testing & Verification
1. Test backend API
2. Test frontend
3. Test database connection
4. Test Celery tasks
5. Monitor memory usage
6. Check logs

**Time**: 15 minutes

**Total Time**: ~75 minutes (1.25 hours)

---

## Cost Verification

### Month 1-12 (Free Tier Active)
| Service | Free Tier | Cost |
|---------|-----------|------|
| B1S VM | 750 hours | $0 |
| PostgreSQL B1MS | 750 hours | $0 |
| App Service F1 | Always free | $0 |
| Virtual Network | Always free | $0 |
| Bandwidth | 15 GB | $0 |
| **TOTAL** | | **$0** |

### Month 13+ (After Free Tier)
| Service | Cost |
|---------|------|
| B1S VM | ~$10/month |
| PostgreSQL B1MS | ~$15/month |
| App Service F1 | $0 |
| Virtual Network | $0 |
| Bandwidth | ~$1/month |
| **TOTAL** | **~$26/month** |

---

## Risks & Mitigations

### Risk 1: Out of Memory (OOM)
**Likelihood**: Medium
**Impact**: High (services crash)

**Mitigation**:
- Add 2 GB swap space
- Monitor memory with `htop`
- Optimize Python memory usage
- Use Alpine base images
- Set Redis maxmemory to 50 MB
- Restart services if needed

---

### Risk 2: CPU Bottleneck
**Likelihood**: Low
**Impact**: Medium (slow responses)

**Mitigation**:
- B1S has burstable CPU (can burst above baseline)
- Optimize database queries
- Use Redis caching
- Monitor CPU usage

---

### Risk 3: Storage Full
**Likelihood**: Low
**Impact**: Medium

**Mitigation**:
- VM has 30 GB disk
- PostgreSQL has 32 GB
- Monitor disk usage
- Clean up logs regularly
- Set log rotation

---

### Risk 4: Network Bandwidth Exceeded
**Likelihood**: Low
**Impact**: Medium (charges apply)

**Mitigation**:
- 15 GB/month free
- Monitor bandwidth usage
- Compress responses
- Use CDN for static assets (Cloudflare free)

---

### Risk 5: App Service CPU Minutes Exceeded
**Likelihood**: Very Low
**Impact**: Low (app stops for the day)

**Mitigation**:
- Static files use minimal CPU
- 60 min/day is plenty
- Monitor usage in Azure Portal

---

## Pre-Deployment Checklist

### Code Preparation
- [ ] Clean up requirements.txt (remove SQL Server deps)
- [ ] Update database.py for PostgreSQL
- [ ] Create systemd service files
- [ ] Create VM setup script
- [ ] Build React frontend
- [ ] Test locally with Docker Compose

### Terraform Preparation
- [ ] Create new terraform files for VM
- [ ] Update database.tf for PostgreSQL
- [ ] Create App Service terraform
- [ ] Remove Container Instances
- [ ] Remove ACR
- [ ] Remove Redis Cache
- [ ] Remove Key Vault
- [ ] Set region to eastus

### Documentation
- [ ] VM setup instructions
- [ ] Deployment guide
- [ ] Troubleshooting guide
- [ ] Monitoring guide

---

## Success Criteria

After deployment, verify:
- [ ] VM is running and accessible via SSH
- [ ] PostgreSQL is running and accessible
- [ ] Backend API responds at http://VM_IP:8000/health
- [ ] Frontend loads at https://appname.azurewebsites.net
- [ ] Frontend can call backend API
- [ ] Database migrations completed
- [ ] Can create user via API
- [ ] Celery worker processes tasks
- [ ] Redis is running
- [ ] Memory usage < 900 MB
- [ ] All services auto-start on reboot

---

## Monitoring Plan

### Daily Checks
- Memory usage: `free -h`
- CPU usage: `top`
- Disk usage: `df -h`
- Service status: `systemctl status`

### Weekly Checks
- PostgreSQL storage: Azure Portal
- Bandwidth usage: Azure Portal
- App Service CPU minutes: Azure Portal
- Error logs: `journalctl -u backend`

### Monthly Checks
- Cost analysis: Azure Portal (should be $0)
- Security updates: `apt update && apt upgrade`
- Backup verification: PostgreSQL backups

---

## Rollback Plan

If deployment fails:
1. Stop all services on VM
2. Delete VM (no cost)
3. Keep PostgreSQL (has data)
4. Delete App Service
5. Revert to previous design
6. Or try Option 2 (Single VM)

---

## Next Steps

Ready to proceed? I'll:
1. Create Terraform files for VM + PostgreSQL + App Service
2. Create VM setup scripts
3. Create systemd service files
4. Update application code
5. Create deployment guide

Estimated time: 30 minutes prep + 75 minutes deployment = ~2 hours total

Should I proceed with Option 1 implementation?
