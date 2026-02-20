# CloudOptima AI - AWS Deployment Checklist

Use this checklist to ensure a smooth deployment to AWS.

## Pre-Deployment

### Local Testing
- [ ] Application runs locally with `./quickstart.sh` or `.\quickstart.ps1`
- [ ] All services start successfully (`docker compose ps`)
- [ ] Health check passes (`./health-check.sh` or `.\health-check.ps1`)
- [ ] Frontend accessible at http://localhost:3000
- [ ] Backend API accessible at http://localhost:8000
- [ ] API docs accessible at http://localhost:8000/docs
- [ ] User registration works
- [ ] Database initialized with TimescaleDB extension
- [ ] cost_data hypertable created

### AWS Prerequisites
- [ ] AWS account created
- [ ] AWS CLI installed (`aws --version`)
- [ ] AWS CLI configured (`aws configure`)
- [ ] IAM user/role has necessary permissions
- [ ] EC2 key pair created (for EC2 deployment)
- [ ] Domain name registered (optional, for custom domain)

### Azure Prerequisites
- [ ] Azure subscription active
- [ ] Azure CLI installed (`az --version`)
- [ ] Service principal created with Cost Management Reader role
- [ ] Tenant ID, Client ID, Client Secret saved

---

## EC2 Deployment Checklist

### Infrastructure Setup
- [ ] Run `./deploy-ec2.sh` script
- [ ] Security group created with correct ports (22, 80, 443, 3000, 8000)
- [ ] EC2 instance launched (t3.large or larger)
- [ ] Instance is running and accessible
- [ ] Public IP address noted
- [ ] SSH connection works (`ssh -i key.pem ubuntu@<IP>`)

### Instance Configuration
- [ ] Run `./setup-instance.sh` on EC2 instance
- [ ] Docker installed and running
- [ ] Docker Compose installed
- [ ] Application code uploaded or cloned
- [ ] `.env` file created from `.env.example`
- [ ] Secure secrets generated (SECRET_KEY, DB_PASSWORD)
- [ ] Azure credentials added to `.env`

### Application Deployment
- [ ] Services started (`docker compose up -d`)
- [ ] All containers running (`docker compose ps`)
- [ ] Database initialized with TimescaleDB
- [ ] Hypertable created for cost_data
- [ ] Health check passes
- [ ] Frontend accessible at http://<IP>:3000
- [ ] Backend accessible at http://<IP>:8000
- [ ] API docs accessible at http://<IP>:8000/docs

### Post-Deployment
- [ ] Admin user created
- [ ] Azure connection tested
- [ ] Initial cost ingestion triggered
- [ ] Recommendations generated
- [ ] Nginx reverse proxy configured (optional)
- [ ] SSL certificate installed (optional)
- [ ] Custom domain configured (optional)

---

## ECS Fargate Deployment Checklist

### CDK Setup
- [ ] Node.js 18+ installed
- [ ] Python 3.12+ installed
- [ ] AWS CDK installed (`npm install -g aws-cdk`)
- [ ] CDK dependencies installed (`pip install -r infrastructure/requirements.txt`)
- [ ] CDK bootstrapped (`cdk bootstrap`)

### Infrastructure Deployment
- [ ] CDK stack deployed (`cdk deploy`)
- [ ] VPC created
- [ ] RDS PostgreSQL instance created
- [ ] ElastiCache Redis cluster created
- [ ] ECS cluster created
- [ ] ECR repositories created
- [ ] Application Load Balancer created
- [ ] CloudWatch Logs configured
- [ ] Secrets Manager secrets created

### Docker Images
- [ ] Backend image built
- [ ] Backend image pushed to ECR
- [ ] Frontend image built
- [ ] Frontend image pushed to ECR
- [ ] Image tags noted

### ECS Services
- [ ] Backend service deployed
- [ ] Frontend service deployed
- [ ] Celery worker service deployed
- [ ] Celery beat service deployed
- [ ] All services running
- [ ] Health checks passing
- [ ] Load balancer targets healthy

### Configuration
- [ ] Database credentials in Secrets Manager
- [ ] JWT secret in Secrets Manager
- [ ] Azure credentials in Secrets Manager
- [ ] Environment variables configured
- [ ] CORS origins set correctly

### Post-Deployment
- [ ] ALB DNS names noted
- [ ] Frontend accessible via ALB
- [ ] Backend accessible via ALB
- [ ] Database initialized with TimescaleDB
- [ ] Hypertable created
- [ ] Admin user created
- [ ] Azure connection tested
- [ ] Initial cost ingestion triggered
- [ ] Route 53 DNS configured (optional)
- [ ] SSL certificate configured (optional)

---

## Security Checklist

### Credentials
- [ ] Default database password changed
- [ ] Strong JWT secret key generated (32+ characters)
- [ ] Azure service principal credentials secured
- [ ] Secrets stored in Secrets Manager (ECS) or .env (EC2)
- [ ] .env file not committed to Git

### Network Security
- [ ] Security groups configured with minimal access
- [ ] SSH access restricted to your IP only
- [ ] Database not publicly accessible
- [ ] Redis not publicly accessible
- [ ] HTTPS enabled (production)

### Application Security
- [ ] CORS origins configured correctly
- [ ] Rate limiting enabled (optional)
- [ ] Input validation enabled
- [ ] SQL injection protection (SQLAlchemy ORM)
- [ ] XSS protection enabled

### AWS Security
- [ ] IAM roles follow least privilege principle
- [ ] CloudWatch Logs enabled
- [ ] RDS encryption at rest enabled
- [ ] EBS volumes encrypted
- [ ] AWS WAF configured (optional)
- [ ] GuardDuty enabled (optional)

---

## Monitoring Checklist

### Health Monitoring
- [ ] Health check endpoint responding (`/health`)
- [ ] All Docker containers running
- [ ] All ECS tasks running
- [ ] Database accepting connections
- [ ] Redis responding to pings
- [ ] Celery worker processing tasks
- [ ] Celery beat scheduling tasks

### Logging
- [ ] Application logs accessible
- [ ] Database logs accessible
- [ ] Celery logs accessible
- [ ] CloudWatch Logs configured (ECS)
- [ ] Log retention configured

### Metrics
- [ ] CPU utilization monitored
- [ ] Memory utilization monitored
- [ ] Disk usage monitored
- [ ] Network traffic monitored
- [ ] Database connections monitored

### Alerts
- [ ] CloudWatch alarms configured
- [ ] High CPU alert
- [ ] High memory alert
- [ ] Disk space alert
- [ ] Error rate alert
- [ ] Cost anomaly alert (optional)

---

## Backup Checklist

### Database Backups
- [ ] RDS automated backups enabled (ECS)
- [ ] Backup retention period set (7+ days)
- [ ] Manual backup script created (EC2)
- [ ] Backup restoration tested
- [ ] Point-in-time recovery enabled (ECS)

### Application Backups
- [ ] Code repository backed up (Git)
- [ ] Configuration files backed up
- [ ] Environment variables documented
- [ ] Infrastructure as code saved (CDK)

---

## Performance Checklist

### Database Optimization
- [ ] TimescaleDB compression enabled
- [ ] Indexes created on frequently queried columns
- [ ] Query performance monitored
- [ ] Connection pooling configured
- [ ] Slow query logging enabled

### Application Optimization
- [ ] Caching enabled (Redis)
- [ ] API response times acceptable (<500ms)
- [ ] Frontend load time acceptable (<3s)
- [ ] Static assets cached
- [ ] Database queries optimized

### Infrastructure Optimization
- [ ] Instance types right-sized
- [ ] Auto-scaling configured (ECS)
- [ ] Load balancer configured correctly
- [ ] CDN configured (optional)

---

## Cost Optimization Checklist

### AWS Cost Management
- [ ] Cost Explorer enabled
- [ ] Budgets configured
- [ ] Cost allocation tags applied
- [ ] Reserved Instances considered (1-year commitment)
- [ ] Savings Plans considered

### Resource Optimization
- [ ] Unused resources identified and removed
- [ ] Instance types right-sized
- [ ] Storage optimized (gp3 instead of gp2)
- [ ] Fargate Spot considered for non-critical workloads
- [ ] Auto-scaling configured to scale down during off-hours

### Monitoring
- [ ] Cost anomaly detection enabled
- [ ] Daily cost reports configured
- [ ] Cost allocation by service tracked
- [ ] Optimization recommendations reviewed monthly

---

## CI/CD Checklist

### GitHub Actions (Optional)
- [ ] GitHub repository created
- [ ] AWS credentials added to GitHub Secrets
- [ ] `.github/workflows/deploy-ecs.yml` configured
- [ ] Pipeline tested with test deployment
- [ ] Automatic deployments on push to main enabled

### Manual Deployment Process
- [ ] Deployment runbook documented
- [ ] Rollback procedure documented
- [ ] Deployment checklist created
- [ ] Team trained on deployment process

---

## Documentation Checklist

### Technical Documentation
- [ ] Architecture diagram created
- [ ] API documentation reviewed
- [ ] Database schema documented
- [ ] Environment variables documented
- [ ] Deployment process documented

### Operational Documentation
- [ ] Runbook created
- [ ] Troubleshooting guide created
- [ ] Monitoring guide created
- [ ] Backup and restore procedures documented
- [ ] Incident response plan created

---

## Testing Checklist

### Functional Testing
- [ ] User registration works
- [ ] User login works
- [ ] Azure connection works
- [ ] Cost data ingestion works
- [ ] Recommendations generated
- [ ] FOCUS export works
- [ ] All API endpoints tested

### Performance Testing
- [ ] Load testing performed
- [ ] Response times acceptable
- [ ] Database performance acceptable
- [ ] Concurrent user testing performed

### Security Testing
- [ ] Authentication tested
- [ ] Authorization tested
- [ ] Input validation tested
- [ ] SQL injection testing performed
- [ ] XSS testing performed

---

## Go-Live Checklist

### Final Checks
- [ ] All previous checklists completed
- [ ] Production environment tested end-to-end
- [ ] Backup and restore tested
- [ ] Monitoring and alerts configured
- [ ] Documentation complete
- [ ] Team trained
- [ ] Support process defined

### Communication
- [ ] Stakeholders notified of go-live date
- [ ] Users notified of new system
- [ ] Support team briefed
- [ ] Escalation process defined

### Post-Launch
- [ ] Monitor system for 24 hours
- [ ] Review logs for errors
- [ ] Check performance metrics
- [ ] Verify backups running
- [ ] Collect user feedback
- [ ] Schedule post-launch review

---

## Maintenance Checklist

### Daily
- [ ] Check service health
- [ ] Review error logs
- [ ] Monitor cost data ingestion
- [ ] Verify backups completed

### Weekly
- [ ] Review performance metrics
- [ ] Check for security updates
- [ ] Review cost trends
- [ ] Update documentation as needed

### Monthly
- [ ] Review and optimize costs
- [ ] Update dependencies
- [ ] Review security posture
- [ ] Conduct backup restoration test
- [ ] Review and update documentation

### Quarterly
- [ ] Conduct security audit
- [ ] Review architecture for optimization
- [ ] Update disaster recovery plan
- [ ] Conduct team training
- [ ] Review and update roadmap

---

## Success Criteria

Your deployment is successful when:

- ✅ All services running and healthy
- ✅ Frontend accessible and responsive
- ✅ Backend API responding correctly
- ✅ Users can register and login
- ✅ Azure connection working
- ✅ Cost data ingesting successfully
- ✅ Recommendations being generated
- ✅ Monitoring and alerts configured
- ✅ Backups running successfully
- ✅ Documentation complete
- ✅ Team trained and ready

---

## Need Help?

Refer to:
- [AWS-DEPLOYMENT-GUIDE.md](AWS-DEPLOYMENT-GUIDE.md) - Detailed deployment instructions
- [AWS-QUICKSTART.md](AWS-QUICKSTART.md) - Quick start guide
- [DEPLOYMENT-SUMMARY.md](DEPLOYMENT-SUMMARY.md) - Overview and summary
- API Documentation: http://your-domain:8000/docs

