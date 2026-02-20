# CloudOptima AI - Deployment Documentation Index

Quick reference guide to all deployment documentation and scripts.

## 📚 Documentation Files

### Getting Started
1. **[README.md](README.md)** - Project overview and quick start
2. **[AWS-QUICKSTART.md](AWS-QUICKSTART.md)** ⭐ - Fastest way to deploy to AWS (start here!)
3. **[DEPLOYMENT-SUMMARY.md](DEPLOYMENT-SUMMARY.md)** - Complete deployment overview

### Detailed Guides
4. **[AWS-DEPLOYMENT-GUIDE.md](AWS-DEPLOYMENT-GUIDE.md)** - Comprehensive AWS deployment guide
5. **[DEPLOYMENT-CHECKLIST.md](DEPLOYMENT-CHECKLIST.md)** - Step-by-step deployment checklist

---

## 🛠️ Deployment Scripts

### Local Testing (Run First!)
- **`quickstart.sh`** (Linux/Mac) - Start application locally
- **`quickstart.ps1`** (Windows) - Start application locally
- **`health-check.sh`** (Linux/Mac) - Verify all services are working
- **`health-check.ps1`** (Windows) - Verify all services are working

### AWS EC2 Deployment
- **`deploy-ec2.sh`** - Automated EC2 instance deployment
- **`setup-instance.sh`** - Configure EC2 instance after launch

### AWS ECS Fargate Deployment
- **`infrastructure/app.py`** - AWS CDK application entry point
- **`infrastructure/stacks/cloudoptima_stack.py`** - CDK stack definition
- **`infrastructure/cdk.json`** - CDK configuration

### CI/CD
- **`.github/workflows/deploy-ecs.yml`** - GitHub Actions pipeline for ECS

---

## 🚀 Quick Start Paths

### Path 1: Local Testing (5 minutes)
```bash
# Windows
.\quickstart.ps1

# Linux/Mac
chmod +x quickstart.sh
./quickstart.sh

# Verify
.\health-check.ps1  # Windows
./health-check.sh   # Linux/Mac
```

### Path 2: AWS EC2 Deployment (15 minutes)
```bash
# 1. Deploy infrastructure
chmod +x deploy-ec2.sh
./deploy-ec2.sh

# 2. SSH to instance
ssh -i your-key.pem ubuntu@<PUBLIC_IP>

# 3. Setup instance
curl -fsSL https://raw.githubusercontent.com/your-org/cloudoptima-ai/main/setup-instance.sh | bash

# 4. Deploy application (see AWS-QUICKSTART.md)
```

### Path 3: AWS ECS Fargate Deployment (30 minutes)
```bash
# 1. Install CDK
npm install -g aws-cdk
cd infrastructure
pip install -r requirements.txt

# 2. Deploy infrastructure
cdk bootstrap
cdk deploy

# 3. Build and push images (see AWS-QUICKSTART.md)

# 4. Update services (see AWS-QUICKSTART.md)
```

---

## 📖 Documentation by Use Case

### "I want to test locally first"
1. Read: [README.md](README.md)
2. Run: `quickstart.sh` or `quickstart.ps1`
3. Verify: `health-check.sh` or `health-check.ps1`

### "I want the fastest AWS deployment"
1. Read: [AWS-QUICKSTART.md](AWS-QUICKSTART.md) - Method 1
2. Run: `deploy-ec2.sh`
3. Follow: EC2 deployment steps

### "I want a production-ready AWS deployment"
1. Read: [AWS-QUICKSTART.md](AWS-QUICKSTART.md) - Method 2
2. Read: [AWS-DEPLOYMENT-GUIDE.md](AWS-DEPLOYMENT-GUIDE.md) - Option 1
3. Use: CDK infrastructure code
4. Follow: [DEPLOYMENT-CHECKLIST.md](DEPLOYMENT-CHECKLIST.md)

### "I want to understand the architecture"
1. Read: [DEPLOYMENT-SUMMARY.md](DEPLOYMENT-SUMMARY.md) - Architecture Overview
2. Read: [AWS-DEPLOYMENT-GUIDE.md](AWS-DEPLOYMENT-GUIDE.md) - Architecture section
3. Review: `infrastructure/stacks/cloudoptima_stack.py`

### "I want to set up CI/CD"
1. Read: [AWS-DEPLOYMENT-GUIDE.md](AWS-DEPLOYMENT-GUIDE.md) - CI/CD section
2. Review: `.github/workflows/deploy-ecs.yml`
3. Configure: GitHub Secrets

### "I'm having issues"
1. Run: `health-check.sh` or `health-check.ps1`
2. Check: [AWS-DEPLOYMENT-GUIDE.md](AWS-DEPLOYMENT-GUIDE.md) - Troubleshooting
3. Check: [AWS-QUICKSTART.md](AWS-QUICKSTART.md) - Troubleshooting
4. Review: Application logs

---

## 📋 Deployment Checklist Summary

Use [DEPLOYMENT-CHECKLIST.md](DEPLOYMENT-CHECKLIST.md) for complete checklists:

### Pre-Deployment
- [ ] Local testing complete
- [ ] AWS prerequisites ready
- [ ] Azure credentials obtained

### EC2 Deployment
- [ ] Infrastructure deployed
- [ ] Instance configured
- [ ] Application running
- [ ] Post-deployment complete

### ECS Fargate Deployment
- [ ] CDK setup complete
- [ ] Infrastructure deployed
- [ ] Images pushed to ECR
- [ ] Services running
- [ ] Post-deployment complete

### Security
- [ ] Credentials secured
- [ ] Network security configured
- [ ] Application security enabled

### Monitoring
- [ ] Health checks passing
- [ ] Logging configured
- [ ] Alerts configured

---

## 🔧 Common Commands

### Local Development
```bash
# Start services
docker compose up -d

# View logs
docker compose logs -f

# Stop services
docker compose down

# Health check
./health-check.sh  # or .ps1 on Windows
```

### EC2 Management
```bash
# SSH to instance
ssh -i key.pem ubuntu@<PUBLIC_IP>

# View logs
docker compose logs -f backend

# Restart services
docker compose restart

# Backup database
docker compose exec db pg_dump -U cloudoptima cloudoptima > backup.sql
```

### ECS Management
```bash
# View logs
aws logs tail /ecs/cloudoptima-backend --follow

# Update service
aws ecs update-service --cluster CloudOptimaStack-CloudOptimaCluster --service CloudOptimaStack-BackendService --force-new-deployment

# Check service status
aws ecs describe-services --cluster CloudOptimaStack-CloudOptimaCluster --services CloudOptimaStack-BackendService
```

---

## 💰 Cost Estimates

| Deployment Type | Monthly Cost | Best For |
|----------------|--------------|----------|
| Local (Docker) | $0 | Development, testing |
| EC2 Single Instance | ~$75 | Demos, small teams |
| ECS Fargate | ~$150 | Production, auto-scaling |
| ECS on EC2 | ~$100 | Cost-optimized production |

See [DEPLOYMENT-SUMMARY.md](DEPLOYMENT-SUMMARY.md) for detailed cost breakdown.

---

## 🎯 Success Criteria

Your deployment is successful when:

✅ All services running and healthy  
✅ Frontend accessible at your domain  
✅ Backend API responding correctly  
✅ Users can register and login  
✅ Azure connection working  
✅ Cost data ingesting successfully  
✅ Recommendations being generated  

Run `health-check.sh` or `health-check.ps1` to verify!

---

## 📞 Support Resources

### Documentation
- [AWS Documentation](https://docs.aws.amazon.com/)
- [Docker Documentation](https://docs.docker.com/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [React Documentation](https://react.dev/)

### Troubleshooting
1. Check application logs
2. Review [AWS-DEPLOYMENT-GUIDE.md](AWS-DEPLOYMENT-GUIDE.md) troubleshooting section
3. Run health check script
4. Check API documentation at `/docs`

---

## 🗺️ Deployment Roadmap

### Phase 1: MVP (Current)
- ✅ Azure cost visibility
- ✅ Basic recommendations
- ✅ AI cost dashboard
- ✅ FOCUS data export
- ✅ AWS deployment ready

### Phase 2: Enhanced Features
- [ ] AWS Cost and Usage Report ingestion
- [ ] Multi-cloud cost comparison
- [ ] Advanced AI recommendations
- [ ] Budget alerts and forecasting

### Phase 3: Enterprise Features
- [ ] GCP support
- [ ] Automated Well-Architected reviews
- [ ] Cost anomaly detection with ML
- [ ] Slack/Teams integrations

---

## 📝 Quick Reference

| Need | File | Command |
|------|------|---------|
| Start locally | quickstart.sh | `./quickstart.sh` |
| Check health | health-check.sh | `./health-check.sh` |
| Deploy to EC2 | deploy-ec2.sh | `./deploy-ec2.sh` |
| Deploy to ECS | infrastructure/ | `cdk deploy` |
| View logs | - | `docker compose logs -f` |
| Restart | - | `docker compose restart` |

---

## 🎓 Learning Path

1. **Beginner**: Start with local deployment
   - Run `quickstart.sh`
   - Explore the UI
   - Read [README.md](README.md)

2. **Intermediate**: Deploy to EC2
   - Read [AWS-QUICKSTART.md](AWS-QUICKSTART.md)
   - Run `deploy-ec2.sh`
   - Follow EC2 deployment steps

3. **Advanced**: Deploy to ECS Fargate
   - Read [AWS-DEPLOYMENT-GUIDE.md](AWS-DEPLOYMENT-GUIDE.md)
   - Learn AWS CDK
   - Set up CI/CD pipeline

---

## ✅ Next Steps

1. Choose your deployment path (Local → EC2 → ECS)
2. Follow the appropriate quick start guide
3. Use the deployment checklist
4. Run health checks
5. Configure monitoring
6. Set up backups
7. Document your deployment

**Ready to start? Go to [AWS-QUICKSTART.md](AWS-QUICKSTART.md)!**

