# AWS Deployment Guide - Concierge Medicine Website

## Overview
This guide provides step-by-step instructions to deploy the Concierge Medicine Website on your AWS account.

## Prerequisites
- AWS Account with appropriate permissions
- AWS CLI configured with your credentials
- Docker installed locally (for testing)
- Git installed

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS Account                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  CloudFront (CDN)                                    │  │
│  │  - Frontend distribution                            │  │
│  │  - SSL/TLS termination                              │  │
│  └──────────────────────────────────────────────────────┘  │
│                          │                                  │
│  ┌──────────────────────▼──────────────────────────────┐  │
│  │  Application Load Balancer (ALB)                    │  │
│  │  - Route to ECS services                            │  │
│  │  - Health checks                                    │  │
│  └──────────────────────┬──────────────────────────────┘  │
│                         │                                  │
│  ┌──────────────────────▼──────────────────────────────┐  │
│  │  ECS Cluster (Fargate)                              │  │
│  │  - Backend API containers                           │  │
│  │  - Auto-scaling                                     │  │
│  └──────────────────────┬──────────────────────────────┘  │
│                         │                                  │
│  ┌──────────────────────▼──────────────────────────────┐  │
│  │  RDS PostgreSQL                                     │  │
│  │  - Multi-AZ deployment                              │  │
│  │  - Automated backups                                │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  ElastiCache (Redis)                                │  │
│  │  - Session management                               │  │
│  │  - Rate limiting                                    │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  S3 Buckets                                          │  │
│  │  - Medical records storage                           │  │
│  │  - Frontend static files                             │  │
│  │  - Encryption enabled                               │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Secrets Manager                                     │  │
│  │  - API keys and credentials                          │  │
│  │  - Encryption keys                                  │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Step 1: Prepare AWS Resources

### 1.1 Create S3 Bucket for Medical Records
```bash
aws s3 mb s3://concierge-medicine-prod-bucket --region us-east-1

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket concierge-medicine-prod-bucket \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket concierge-medicine-prod-bucket \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

### 1.2 Create RDS PostgreSQL Database
```bash
aws rds create-db-instance \
  --db-instance-identifier concierge-medicine-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 15.3 \
  --master-username concierge_user \
  --master-user-password 'YourSecurePassword123!' \
  --allocated-storage 20 \
  --storage-type gp3 \
  --multi-az \
  --backup-retention-period 30 \
  --enable-cloudwatch-logs-exports postgresql \
  --region us-east-1
```

### 1.3 Create ElastiCache Redis Cluster
```bash
aws elasticache create-cache-cluster \
  --cache-cluster-id concierge-medicine-redis \
  --cache-node-type cache.t3.micro \
  --engine redis \
  --engine-version 7.0 \
  --num-cache-nodes 1 \
  --region us-east-1
```

### 1.4 Create ECR Repository
```bash
aws ecr create-repository \
  --repository-name concierge-medicine-backend \
  --region us-east-1
```

## Step 2: Store Secrets in AWS Secrets Manager

```bash
# Create secret for database credentials
aws secretsmanager create-secret \
  --name concierge/db/credentials \
  --secret-string '{
    "username": "concierge_user",
    "password": "YourSecurePassword123!",
    "host": "your-rds-endpoint.rds.amazonaws.com",
    "port": 5432,
    "dbname": "concierge_medicine"
  }' \
  --region us-east-1

# Create secret for API keys
aws secretsmanager create-secret \
  --name concierge/api/keys \
  --secret-string '{
    "jwt_secret": "your_very_long_random_jwt_secret_key_min_32_chars",
    "stripe_secret": "sk_live_your_stripe_live_key",
    "stripe_webhook": "whsec_your_webhook_secret",
    "twilio_sid": "your_twilio_account_sid",
    "twilio_token": "your_twilio_auth_token",
    "sendgrid_key": "your_sendgrid_api_key",
    "agora_id": "your_agora_app_id",
    "agora_cert": "your_agora_app_certificate",
    "encryption_key": "your_32_byte_hex_encryption_key_here"
  }' \
  --region us-east-1
```

## Step 3: Build and Push Docker Image

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Build Docker image
docker build -t concierge-medicine-backend:latest .

# Tag image for ECR
docker tag concierge-medicine-backend:latest YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/concierge-medicine-backend:latest

# Push to ECR
docker push YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/concierge-medicine-backend:latest
```

## Step 4: Create ECS Cluster and Task Definition

### 4.1 Create ECS Cluster
```bash
aws ecs create-cluster \
  --cluster-name concierge-medicine-cluster \
  --region us-east-1
```

### 4.2 Create Task Definition
Create a file `task-definition.json`:

```json
{
  "family": "concierge-medicine-backend",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "backend",
      "image": "YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/concierge-medicine-backend:latest",
      "portMappings": [
        {
          "containerPort": 3001,
          "hostPort": 3001,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "NODE_ENV",
          "value": "production"
        },
        {
          "name": "PORT",
          "value": "3001"
        }
      ],
      "secrets": [
        {
          "name": "DATABASE_URL",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:YOUR_ACCOUNT_ID:secret:concierge/db/credentials:password::"
        },
        {
          "name": "JWT_SECRET",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:YOUR_ACCOUNT_ID:secret:concierge/api/keys:jwt_secret::"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/concierge-medicine",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ],
  "executionRoleArn": "arn:aws:iam::YOUR_ACCOUNT_ID:role/ecsTaskExecutionRole"
}
```

Register the task definition:
```bash
aws ecs register-task-definition \
  --cli-input-json file://task-definition.json \
  --region us-east-1
```

## Step 5: Create Application Load Balancer

```bash
# Create ALB
aws elbv2 create-load-balancer \
  --name concierge-medicine-alb \
  --subnets subnet-xxxxx subnet-yyyyy \
  --security-groups sg-xxxxx \
  --scheme internet-facing \
  --type application \
  --region us-east-1

# Create target group
aws elbv2 create-target-group \
  --name concierge-medicine-tg \
  --protocol HTTP \
  --port 3001 \
  --vpc-id vpc-xxxxx \
  --target-type ip \
  --region us-east-1

# Create listener
aws elbv2 create-listener \
  --load-balancer-arn arn:aws:elasticloadbalancing:us-east-1:YOUR_ACCOUNT_ID:loadbalancer/app/concierge-medicine-alb/xxxxx \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:us-east-1:YOUR_ACCOUNT_ID:targetgroup/concierge-medicine-tg/xxxxx \
  --region us-east-1
```

## Step 6: Create ECS Service

```bash
aws ecs create-service \
  --cluster concierge-medicine-cluster \
  --service-name concierge-medicine-backend \
  --task-definition concierge-medicine-backend:1 \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxxxx,subnet-yyyyy],securityGroups=[sg-xxxxx],assignPublicIp=ENABLED}" \
  --load-balancers targetGroupArn=arn:aws:elasticloadbalancing:us-east-1:YOUR_ACCOUNT_ID:targetgroup/concierge-medicine-tg/xxxxx,containerName=backend,containerPort=3001 \
  --region us-east-1
```

## Step 7: Configure Auto Scaling

```bash
# Register scalable target
aws application-autoscaling register-scalable-target \
  --service-namespace ecs \
  --resource-id service/concierge-medicine-cluster/concierge-medicine-backend \
  --scalable-dimension ecs:service:DesiredCount \
  --min-capacity 2 \
  --max-capacity 10 \
  --region us-east-1

# Create scaling policy
aws application-autoscaling put-scaling-policy \
  --policy-name concierge-medicine-scaling \
  --service-namespace ecs \
  --resource-id service/concierge-medicine-cluster/concierge-medicine-backend \
  --scalable-dimension ecs:service:DesiredCount \
  --policy-type TargetTrackingScaling \
  --target-tracking-scaling-policy-configuration file://scaling-policy.json \
  --region us-east-1
```

## Step 8: Set Up CloudWatch Monitoring

```bash
# Create log group
aws logs create-log-group \
  --log-group-name /ecs/concierge-medicine \
  --region us-east-1

# Create alarms
aws cloudwatch put-metric-alarm \
  --alarm-name concierge-medicine-cpu-high \
  --alarm-description "Alert when CPU exceeds 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/ECS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --region us-east-1
```

## Step 9: Configure SSL/TLS with ACM

```bash
# Request certificate
aws acm request-certificate \
  --domain-name your-domain.com \
  --subject-alternative-names www.your-domain.com \
  --validation-method DNS \
  --region us-east-1
```

## Step 10: Deploy Frontend to S3 + CloudFront

```bash
# Build frontend
npm run build -w frontend

# Upload to S3
aws s3 sync frontend/dist s3://concierge-medicine-frontend-bucket/ --delete

# Create CloudFront distribution (use AWS Console or CLI)
```

## Monitoring and Maintenance

### View Logs
```bash
aws logs tail /ecs/concierge-medicine --follow
```

### Check Service Status
```bash
aws ecs describe-services \
  --cluster concierge-medicine-cluster \
  --services concierge-medicine-backend \
  --region us-east-1
```

### Update Service
```bash
aws ecs update-service \
  --cluster concierge-medicine-cluster \
  --service concierge-medicine-backend \
  --force-new-deployment \
  --region us-east-1
```

## Cost Optimization

1. **Use Spot Instances** for non-critical workloads
2. **Enable RDS Auto Scaling** for storage
3. **Use CloudFront** for static content caching
4. **Set up CloudWatch Alarms** for cost anomalies
5. **Use Reserved Instances** for predictable workloads

## Security Best Practices

1. ✓ Enable VPC Flow Logs
2. ✓ Use Security Groups with least privilege
3. ✓ Enable RDS encryption
4. ✓ Use Secrets Manager for credentials
5. ✓ Enable CloudTrail for audit logging
6. ✓ Use WAF with ALB
7. ✓ Enable S3 versioning and MFA delete
8. ✓ Regular security assessments

## Troubleshooting

### Service won't start
- Check CloudWatch logs: `aws logs tail /ecs/concierge-medicine --follow`
- Verify task definition and environment variables
- Check security group rules

### Database connection issues
- Verify RDS security group allows port 5432
- Check database credentials in Secrets Manager
- Verify VPC and subnet configuration

### High latency
- Check CloudWatch metrics
- Review RDS performance insights
- Consider increasing task CPU/memory

## Support
For issues or questions, contact: support@concierge-medicine.com
