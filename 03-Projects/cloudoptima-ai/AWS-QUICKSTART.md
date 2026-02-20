# CloudOptima AI - AWS Quick Start

Get CloudOptima AI running on AWS in 15 minutes.

## Choose Your Deployment Method

### 🚀 Method 1: Single EC2 Instance (Fastest - 10 minutes)
Best for: Testing, demos, small teams
Cost: ~$75/month

### ☁️ Method 2: ECS Fargate (Production - 30 minutes)
Best for: Production workloads, auto-scaling
Cost: ~$150/month

---

## Method 1: EC2 Single Instance (Recommended for Quick Start)

### Prerequisites
- AWS account with EC2 permissions
- AWS CLI installed and configured
- EC2 key pair created

### Step 1: Run Deployment Script

```bash
cd 03-Projects/cloudoptima-ai
chmod +x deploy-ec2.sh
./deploy-ec2.sh
```

The script will:
1. Create security group (if needed)
2. Launch Ubuntu 24.04 EC2 instance (t3.large)
3. Install Docker and Docker Compose
4. Output connection details

### Step 2: Connect and Deploy Application

```bash
# SSH to instance (use IP from script output)
ssh -i your-key.pem ubuntu@<PUBLIC_IP>

# Create app directory
cd /opt/cloudoptima

# Upload your code (from local machine)
# Option A: Using SCP
scp -i your-key.pem -r /path/to/cloudoptima-ai ubuntu@<PUBLIC_IP>:/opt/cloudoptima

# Option B: Using Git
git clone https://github.com/your-org/cloudoptima-ai.git .

# Configure environment
cp .env.example .env
nano .env  # Add your Azure credentials

# Generate secure secrets
export SECRET_KEY=$(openssl rand -hex 32)
export DB_PASSWORD=$(openssl rand -hex 16)
sed -i "s/SECRET_KEY=change-me.*/SECRET_KEY=$SECRET_KEY/" .env
sed -i "s/POSTGRES_PASSWORD=cloudoptima/POSTGRES_PASSWORD=$DB_PASSWORD/" .env
sed -i "s/:cloudoptima@/:$DB_PASSWORD@/" .env

# Start services
docker compose up -d

# Check status
docker compose ps
docker compose logs -f
```

### Step 3: Access Application

```
Frontend:  http://<PUBLIC_IP>:3000
Backend:   http://<PUBLIC_IP>:8000
API Docs:  http://<PUBLIC_IP>:8000/docs
```

### Step 4: Initialize Database

```bash
# Enable TimescaleDB extension
docker compose exec db psql -U cloudoptima -d cloudoptima -c "CREATE EXTENSION IF NOT EXISTS timescaledb;"
docker compose exec db psql -U cloudoptima -d cloudoptima -c "SELECT create_hypertable('cost_data', 'billing_period_start', if_not_exists => TRUE);"
```

### Step 5: Create Admin User

```bash
# Via API
curl -X POST http://<PUBLIC_IP>:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "SecurePassword123!",
    "full_name": "Admin User",
    "organization_name": "My Company"
  }'
```

---

## Method 2: ECS Fargate (Production)

### Prerequisites
- AWS account with full permissions
- AWS CLI installed and configured
- Node.js 18+ (for CDK)
- Python 3.12+ (for CDK)

### Step 1: Install AWS CDK

```bash
npm install -g aws-cdk
cd 03-Projects/cloudoptima-ai/infrastructure
pip install -r requirements.txt
```

### Step 2: Bootstrap CDK (First Time Only)

```bash
cdk bootstrap aws://ACCOUNT-ID/us-east-1
```

### Step 3: Deploy Infrastructure

```bash
cdk deploy
```

This creates:
- VPC with public/private subnets
- RDS PostgreSQL 16 with TimescaleDB
- ElastiCache Redis
- ECS Fargate cluster
- Application Load Balancer
- ECR repositories
- CloudWatch Logs

### Step 4: Build and Push Docker Images

```bash
# Get account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=us-east-1

# Login to ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Build and push backend
cd ..
docker build -f docker/Dockerfile.backend -t cloudoptima-backend .
docker tag cloudoptima-backend:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/cloudoptima-backend:latest
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/cloudoptima-backend:latest

# Build and push frontend
docker build -f docker/Dockerfile.frontend -t cloudoptima-frontend .
docker tag cloudoptima-frontend:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/cloudoptima-frontend:latest
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/cloudoptima-frontend:latest
```

### Step 5: Update ECS Services

```bash
# Force new deployment with latest images
aws ecs update-service --cluster CloudOptimaStack-CloudOptimaCluster --service CloudOptimaStack-BackendService --force-new-deployment
aws ecs update-service --cluster CloudOptimaStack-CloudOptimaCluster --service CloudOptimaStack-FrontendService --force-new-deployment
```

### Step 6: Get Application URLs

```bash
# Get ALB DNS names from CDK outputs
aws cloudformation describe-stacks --stack-name CloudOptimaStack --query "Stacks[0].Outputs"
```

---

## Post-Deployment Configuration

### 1. Set Up Azure Service Principal

```bash
# Create service principal with Cost Management Reader role
az ad sp create-for-rbac \
  --name cloudoptima-reader \
  --role "Cost Management Reader" \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID

# Output will show:
# {
#   "appId": "...",        # This is AZURE_CLIENT_ID
#   "password": "...",     # This is AZURE_CLIENT_SECRET
#   "tenant": "..."        # This is AZURE_TENANT_ID
# }
```

### 2. Update Environment Variables

For EC2:
```bash
nano .env
# Add Azure credentials
docker compose restart backend celery-worker celery-beat
```

For ECS Fargate:
```bash
# Update Secrets Manager
aws secretsmanager update-secret \
  --secret-id cloudoptima/prod/azure \
  --secret-string '{"tenant_id":"xxx","client_id":"xxx","client_secret":"xxx"}'

# Restart services
aws ecs update-service --cluster CloudOptimaStack-CloudOptimaCluster --service CloudOptimaStack-BackendService --force-new-deployment
```

### 3. Trigger Initial Cost Ingestion

```bash
# Get JWT token first (login via UI or API)
TOKEN="your-jwt-token"

# Trigger ingestion
curl -X POST http://your-domain/api/costs/ingest \
  -H "Authorization: Bearer $TOKEN"
```

---

## Optional: Set Up Custom Domain

### Using Route 53 and ACM

```bash
# Request SSL certificate
aws acm request-certificate \
  --domain-name cloudoptima.example.com \
  --validation-method DNS \
  --region us-east-1

# Create Route 53 record pointing to ALB
aws route53 change-resource-record-sets \
  --hosted-zone-id YOUR_ZONE_ID \
  --change-batch file://route53-change.json
```

---

## Monitoring and Logs

### EC2 Instance
```bash
# View all logs
docker compose logs -f

# View specific service
docker compose logs -f backend
docker compose logs -f celery-worker

# Check resource usage
docker stats
```

### ECS Fargate
```bash
# View logs
aws logs tail /ecs/cloudoptima-backend --follow
aws logs tail /ecs/cloudoptima-frontend --follow

# Check service status
aws ecs describe-services \
  --cluster CloudOptimaStack-CloudOptimaCluster \
  --services CloudOptimaStack-BackendService
```

---

## Backup and Restore

### EC2 Database Backup
```bash
# Backup
docker compose exec db pg_dump -U cloudoptima cloudoptima > backup_$(date +%Y%m%d).sql

# Restore
docker compose exec -T db psql -U cloudoptima cloudoptima < backup_20260213.sql
```

### RDS Automated Backups
- Enabled by default with 7-day retention
- Point-in-time recovery available
- Manual snapshots via AWS Console

---

## Troubleshooting

### Backend won't start
```bash
# Check logs
docker compose logs backend

# Verify database connection
docker compose exec backend python -c "from app.core.database import engine; print(engine.url)"

# Check database is running
docker compose exec db psql -U cloudoptima -d cloudoptima -c "SELECT version();"
```

### Celery tasks not running
```bash
# Check Redis connection
docker compose exec backend python -c "import redis; r=redis.from_url('redis://redis:6379/0'); print(r.ping())"

# View Celery logs
docker compose logs celery-worker
docker compose logs celery-beat

# Restart workers
docker compose restart celery-worker celery-beat
```

### Frontend can't reach backend
- Check CORS_ORIGINS in backend .env
- Verify REACT_APP_API_URL in frontend environment
- Check security group rules (ports 3000, 8000)

### High costs
- Stop unused services: `docker compose stop frontend` (if using API only)
- Downgrade EC2 instance type: t3.medium instead of t3.large
- Use ECS Fargate Spot for non-critical workloads

---

## Cost Optimization

### EC2 Instance
- Use Reserved Instances for 1-year commitment: Save 40%
- Use Savings Plans: Save 30-40%
- Schedule stop/start for dev environments

### ECS Fargate
- Use Fargate Spot: Save 70% (with interruptions)
- Right-size task CPU/memory
- Use Application Auto Scaling

### Database
- Use RDS Reserved Instances: Save 40%
- Enable storage auto-scaling
- Use Aurora Serverless v2 for variable workloads

---

## Next Steps

1. ✅ Application deployed and running
2. ⏭️ Connect Azure subscription
3. ⏭️ Set up CI/CD pipeline (see .github/workflows/deploy-ecs.yml)
4. ⏭️ Configure custom domain
5. ⏭️ Enable AWS WAF for security
6. ⏭️ Set up CloudWatch alarms
7. ⏭️ Add AWS Cost and Usage Report ingestion (Phase 2)

---

## Support

For issues or questions:
- Check logs first: `docker compose logs -f`
- Review AWS-DEPLOYMENT-GUIDE.md for detailed instructions
- Check API docs: http://your-domain:8000/docs

