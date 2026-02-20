# CloudOptima AI — AWS Deployment Guide

Complete guide to deploy the CloudOptima AI MVP to your AWS account.

## Deployment Options

### Option 1: AWS ECS Fargate (Recommended for MVP)
- Fully managed containers, no server management
- Auto-scaling, load balancing included
- Cost: ~$50-150/month for MVP workload

### Option 2: AWS EC2 with Docker Compose
- Single EC2 instance running all containers
- Simplest migration from local development
- Cost: ~$30-80/month (t3.large or t3.xlarge)

### Option 3: AWS ECS on EC2
- More control than Fargate, lower cost at scale
- Requires cluster management
- Cost: ~$40-100/month

---

## Option 1: ECS Fargate Deployment (Recommended)

### Prerequisites
- AWS CLI installed and configured
- AWS account with appropriate permissions
- Domain name (optional, for custom domain)

### Architecture
```
Internet → ALB → ECS Fargate Services:
  - Frontend (React)
  - Backend (FastAPI)
  - Celery Worker
  - Celery Beat
  ↓
RDS PostgreSQL (with TimescaleDB extension)
ElastiCache Redis
```

### Step 1: Set Up Infrastructure

We'll use AWS CDK (Python) to provision everything.

```bash
cd 03-Projects/cloudoptima-ai
mkdir infrastructure && cd infrastructure
```

### Step 2: Install AWS CDK

```bash
npm install -g aws-cdk
pip install aws-cdk-lib constructs
cdk init app --language python
source .venv/bin/activate  # On Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

### Step 3: Deploy with CDK

The CDK stack will create:
- VPC with public/private subnets
- RDS PostgreSQL 16 instance
- ElastiCache Redis cluster
- ECR repositories for Docker images
- ECS Fargate cluster with 4 services
- Application Load Balancer
- CloudWatch Logs
- Secrets Manager for credentials

```bash
cdk bootstrap  # First time only
cdk deploy
```

### Step 4: Push Docker Images to ECR

```bash
# Get ECR login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com

# Build and push backend
docker build -f docker/Dockerfile.backend -t cloudoptima-backend .
docker tag cloudoptima-backend:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/cloudoptima-backend:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/cloudoptima-backend:latest

# Build and push frontend
docker build -f docker/Dockerfile.frontend -t cloudoptima-frontend .
docker tag cloudoptima-frontend:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/cloudoptima-frontend:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/cloudoptima-frontend:latest
```

### Step 5: Configure Environment Variables

Store secrets in AWS Secrets Manager:

```bash
aws secretsmanager create-secret \
  --name cloudoptima/prod/db \
  --secret-string '{"username":"cloudoptima","password":"CHANGE_ME"}'

aws secretsmanager create-secret \
  --name cloudoptima/prod/jwt \
  --secret-string '{"secret_key":"CHANGE_ME_USE_OPENSSL_RAND_HEX_32"}'

aws secretsmanager create-secret \
  --name cloudoptima/prod/azure \
  --secret-string '{"tenant_id":"","client_id":"","client_secret":""}'
```

---

## Option 2: Single EC2 Instance with Docker Compose (Fastest)

### Step 1: Launch EC2 Instance

```bash
# Launch Ubuntu 24.04 LTS instance (t3.large recommended)
aws ec2 run-instances \
  --image-id ami-0c7217cdde317cfec \
  --instance-type t3.large \
  --key-name YOUR_KEY_NAME \
  --security-group-ids sg-XXXXXXXX \
  --subnet-id subnet-XXXXXXXX \
  --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":50,"VolumeType":"gp3"}}]' \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=CloudOptima-AI}]'
```

### Step 2: Configure Security Group

Allow inbound traffic:
- Port 22 (SSH) from your IP
- Port 80 (HTTP) from 0.0.0.0/0
- Port 443 (HTTPS) from 0.0.0.0/0
- Port 8000 (API) from 0.0.0.0/0 (or restrict to ALB)
- Port 3000 (Frontend) from 0.0.0.0/0 (or restrict to ALB)

### Step 3: SSH and Install Dependencies

```bash
ssh -i your-key.pem ubuntu@<instance-public-ip>

# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu
newgrp docker

# Install Docker Compose
sudo apt install docker-compose-plugin -y

# Install Git
sudo apt install git -y
```

### Step 4: Clone and Deploy

```bash
# Clone your repo or upload files
git clone <your-repo-url> cloudoptima-ai
cd cloudoptima-ai

# Configure environment
cp .env.example .env
nano .env  # Edit with your values

# Start services
docker compose up -d

# Check logs
docker compose logs -f
```

### Step 5: Set Up Nginx Reverse Proxy (Optional)

```bash
sudo apt install nginx certbot python3-certbot-nginx -y

# Create Nginx config
sudo nano /etc/nginx/sites-available/cloudoptima
```

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location /api {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/cloudoptima /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com
```

---

## Post-Deployment Steps

### 1. Initialize Database

```bash
# Run migrations (if using Alembic)
docker compose exec backend alembic upgrade head

# Or connect to DB and enable TimescaleDB
docker compose exec db psql -U cloudoptima -d cloudoptima
```

```sql
CREATE EXTENSION IF NOT EXISTS timescaledb;
SELECT create_hypertable('cost_data', 'billing_period_start', if_not_exists => TRUE);
```

### 2. Create First Admin User

```bash
# Via API
curl -X POST http://your-domain.com/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com",
    "password": "SecurePassword123!",
    "full_name": "Admin User",
    "organization_name": "My Company"
  }'
```

### 3. Connect Azure Subscription

1. Create Azure Service Principal:
```bash
az ad sp create-for-rbac --name cloudoptima-reader --role "Cost Management Reader" --scopes /subscriptions/YOUR_SUBSCRIPTION_ID
```

2. Add credentials to `.env` or Secrets Manager
3. Test connection via API or UI

### 4. Trigger Initial Cost Ingestion

```bash
# Via API
curl -X POST http://your-domain.com/api/costs/ingest \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Or wait for Celery Beat to run daily job
```

---

## Monitoring and Maintenance

### CloudWatch Logs (ECS Fargate)
```bash
aws logs tail /ecs/cloudoptima-backend --follow
aws logs tail /ecs/cloudoptima-frontend --follow
```

### Docker Compose Logs (EC2)
```bash
docker compose logs -f backend
docker compose logs -f celery-worker
```

### Database Backups

#### RDS (Fargate)
- Automated daily snapshots enabled by default
- Point-in-time recovery available

#### EC2 Docker Compose
```bash
# Backup
docker compose exec db pg_dump -U cloudoptima cloudoptima > backup_$(date +%Y%m%d).sql

# Restore
docker compose exec -T db psql -U cloudoptima cloudoptima < backup_20260213.sql
```

### Scaling

#### ECS Fargate
```bash
# Update desired count
aws ecs update-service --cluster cloudoptima --service backend --desired-count 3
```

#### EC2
- Upgrade instance type
- Add more EC2 instances with load balancer

---

## Cost Estimates

### ECS Fargate (Recommended)
- ECS Fargate tasks: $40-80/month
- RDS db.t4g.medium: $30-50/month
- ElastiCache t4g.micro: $12/month
- ALB: $20/month
- Data transfer: $10-30/month
- **Total: ~$110-190/month**

### EC2 Single Instance
- EC2 t3.large: $60/month
- EBS 50GB gp3: $5/month
- Data transfer: $10-20/month
- **Total: ~$75-85/month**

---

## Troubleshooting

### Backend won't start
```bash
# Check database connection
docker compose exec backend python -c "from app.core.database import engine; print(engine.url)"

# Check logs
docker compose logs backend
```

### Celery tasks not running
```bash
# Check Redis connection
docker compose exec backend python -c "import redis; r=redis.from_url('redis://redis:6379/0'); print(r.ping())"

# Restart workers
docker compose restart celery-worker celery-beat
```

### Frontend can't reach backend
- Check CORS_ORIGINS in `.env`
- Verify REACT_APP_API_URL in frontend environment
- Check network connectivity between containers

---

## Next Steps

1. Set up CI/CD pipeline (GitHub Actions → ECR → ECS)
2. Configure custom domain with Route 53
3. Enable AWS WAF for security
4. Set up CloudWatch alarms for cost anomalies
5. Implement AWS Cost and Usage Report ingestion (Phase 2)

