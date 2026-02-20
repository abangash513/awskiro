# CloudFormation Deployment Guide

## Overview

This guide provides instructions for deploying the Concierge Medicine Website to your AWS account (750299845580) in US-EAST-1 using CloudFormation.

## What Gets Deployed

The CloudFormation template creates a complete, production-ready infrastructure:

### Networking
- VPC with public and private subnets across 2 availability zones
- Internet Gateway and NAT Gateway
- Route tables and security groups

### Compute
- ECS Cluster (Fargate)
- ECS Service with auto-scaling (1-10 instances)
- Application Load Balancer
- CloudWatch Logs

### Database
- RDS PostgreSQL 15 (db.t3.micro)
- Multi-AZ capable
- Automated backups (7 days)
- Encryption enabled

### Cache
- ElastiCache Redis 7 (cache.t3.micro)
- Automatic failover

### Storage
- S3 Bucket for medical records
- Versioning enabled
- Encryption enabled
- Public access blocked

### Container Registry
- ECR Repository for Docker images
- Image scanning enabled
- Lifecycle policy (keep last 10 images)

### Monitoring
- CloudWatch Log Group
- CloudWatch Alarms (CPU, Memory, Target Health)
- Container Insights enabled

### Security
- IAM Roles and Policies
- Security Groups with least privilege
- Secrets Manager integration
- Encryption at rest and in transit

## Prerequisites

### AWS Account
- Account ID: 750299845580
- Region: us-east-1
- Permissions: Administrator or equivalent

### Local Tools
- AWS CLI v2 installed and configured
- Docker installed
- Bash shell (Linux/Mac) or PowerShell (Windows)

### AWS Credentials
Configure AWS CLI with your credentials:
```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: us-east-1
# Default output format: json
```

## Deployment Steps

### Step 1: Extract and Navigate to Project

```bash
unzip concierge-medicine-website.zip
cd concierge-medicine-website
```

### Step 2: Make Deployment Script Executable

```bash
chmod +x deploy-cloudformation.sh
```

### Step 3: Review CloudFormation Template

```bash
cat cloudformation-template.yaml
```

The template includes all parameters with default values for test environment:
- Database: PostgreSQL 15 (db.t3.micro)
- Cache: Redis 7 (cache.t3.micro)
- Compute: ECS Fargate (256 CPU, 512 MB memory)
- Desired Count: 1 instance

### Step 4: Deploy Infrastructure

```bash
./deploy-cloudformation.sh
```

This script will:
1. Validate the CloudFormation template
2. Store database password in Secrets Manager
3. Create or update the CloudFormation stack
4. Wait for stack creation to complete (10-15 minutes)
5. Display stack outputs

### Step 5: Build and Push Docker Image

Once the stack is created, build and push the Docker image to ECR:

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 750299845580.dkr.ecr.us-east-1.amazonaws.com

# Build Docker image
docker build -t concierge-medicine:latest .

# Tag for ECR
docker tag concierge-medicine:latest 750299845580.dkr.ecr.us-east-1.amazonaws.com/concierge-medicine-backend:latest

# Push to ECR
docker push 750299845580.dkr.ecr.us-east-1.amazonaws.com/concierge-medicine-backend:latest
```

### Step 6: Deploy to ECS

```bash
aws ecs update-service \
  --cluster concierge-medicine-cluster \
  --service concierge-medicine-service \
  --force-new-deployment \
  --region us-east-1
```

### Step 7: Verify Deployment

```bash
# Check service status
aws ecs describe-services \
  --cluster concierge-medicine-cluster \
  --services concierge-medicine-service \
  --region us-east-1

# View logs
aws logs tail /ecs/concierge-medicine --follow --region us-east-1

# Get ALB DNS name
aws cloudformation describe-stacks \
  --stack-name concierge-medicine-stack \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
  --output text
```

## Configuration Parameters

The CloudFormation template uses the following parameters (all with test defaults):

### Environment
- **EnvironmentName**: test
- **ApplicationName**: concierge-medicine

### Database
- **DBUsername**: concierge_user
- **DBPassword**: ConciergeTest123!@#
- **DBName**: concierge_medicine

### Security
- **JWTSecret**: your_test_jwt_secret_key_min_32_characters_long_12345
- **EncryptionKey**: 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef

### External Services (Test Placeholders)
- **StripeSecretKey**: sk_test_placeholder_key_for_testing
- **TwilioAccountSID**: AC_test_placeholder
- **TwilioAuthToken**: test_placeholder_token
- **TwilioPhoneNumber**: +1234567890
- **SendGridAPIKey**: SG.test_placeholder_key
- **AgoraAppID**: test_agora_app_id
- **AgoraAppCertificate**: test_agora_certificate

### Email
- **AdminEmail**: admin@concierge-medicine-test.com
- **SupportEmail**: support@concierge-medicine-test.com

### Compute
- **DesiredCount**: 1 (number of ECS tasks)
- **TaskCPU**: 256 (CPU units)
- **TaskMemory**: 512 (MB)

## Updating Parameters

To update any parameters after deployment:

```bash
aws cloudformation update-stack \
  --stack-name concierge-medicine-stack \
  --template-body file://cloudformation-template.yaml \
  --parameters \
    ParameterKey=EnvironmentName,ParameterValue=test \
    ParameterKey=DesiredCount,ParameterValue=2 \
  --capabilities CAPABILITY_IAM \
  --region us-east-1
```

## Stack Outputs

After successful deployment, the stack provides these outputs:

- **LoadBalancerDNS**: DNS name of the Application Load Balancer
- **RDSEndpoint**: PostgreSQL database endpoint
- **RedisEndpoint**: Redis cluster endpoint
- **S3BucketName**: S3 bucket for medical records
- **ECRRepositoryURI**: ECR repository URI for Docker images
- **ECSClusterName**: ECS cluster name
- **ECSServiceName**: ECS service name
- **LogGroupName**: CloudWatch log group name
- **VPCId**: VPC ID

## Accessing the Application

Once deployed and running:

```bash
# Get ALB DNS name
ALB_DNS=$(aws cloudformation describe-stacks \
  --stack-name concierge-medicine-stack \
  --region us-east-1 \
  --query 'Stacks[0].Outputs[?OutputKey==`LoadBalancerDNS`].OutputValue' \
  --output text)

# Access the application
echo "http://$ALB_DNS"
```

## Monitoring

### CloudWatch Logs

```bash
# View logs in real-time
aws logs tail /ecs/concierge-medicine --follow

# View specific time range
aws logs filter-log-events \
  --log-group-name /ecs/concierge-medicine \
  --start-time $(date -d '1 hour ago' +%s)000
```

### CloudWatch Metrics

```bash
# Get CPU utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=concierge-medicine-service Name=ClusterName,Value=concierge-medicine-cluster \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

### CloudWatch Alarms

```bash
# List alarms
aws cloudwatch describe-alarms \
  --alarm-name-prefix concierge-medicine

# Get alarm state
aws cloudwatch describe-alarms \
  --alarm-names concierge-medicine-cpu-high
```

## Scaling

### Manual Scaling

```bash
# Scale to 3 instances
aws ecs update-service \
  --cluster concierge-medicine-cluster \
  --service concierge-medicine-service \
  --desired-count 3 \
  --region us-east-1
```

### Auto-Scaling Configuration

The template includes auto-scaling that:
- Scales from 1 to 10 instances
- Targets 70% CPU utilization
- Scales out in 60 seconds
- Scales in after 300 seconds

## Updating the Application

### Update Docker Image

```bash
# Build new image
docker build -t concierge-medicine:v2 .

# Tag for ECR
docker tag concierge-medicine:v2 750299845580.dkr.ecr.us-east-1.amazonaws.com/concierge-medicine-backend:v2

# Push to ECR
docker push 750299845580.dkr.ecr.us-east-1.amazonaws.com/concierge-medicine-backend:v2

# Update ECS service
aws ecs update-service \
  --cluster concierge-medicine-cluster \
  --service concierge-medicine-service \
  --force-new-deployment \
  --region us-east-1
```

## Troubleshooting

### Stack Creation Failed

```bash
# Check stack events
aws cloudformation describe-stack-events \
  --stack-name concierge-medicine-stack \
  --region us-east-1 \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]'
```

### ECS Service Not Running

```bash
# Check service status
aws ecs describe-services \
  --cluster concierge-medicine-cluster \
  --services concierge-medicine-service \
  --region us-east-1

# Check task status
aws ecs list-tasks \
  --cluster concierge-medicine-cluster \
  --region us-east-1

# Describe tasks
aws ecs describe-tasks \
  --cluster concierge-medicine-cluster \
  --tasks <task-arn> \
  --region us-east-1
```

### Database Connection Issues

```bash
# Check RDS status
aws rds describe-db-instances \
  --db-instance-identifier concierge-medicine-db \
  --region us-east-1

# Check security group
aws ec2 describe-security-groups \
  --group-ids <rds-security-group-id> \
  --region us-east-1
```

### Redis Connection Issues

```bash
# Check ElastiCache status
aws elasticache describe-cache-clusters \
  --cache-cluster-id concierge-medicine-redis \
  --region us-east-1
```

## Cleanup

To delete the entire stack and all resources:

```bash
# Delete stack
aws cloudformation delete-stack \
  --stack-name concierge-medicine-stack \
  --region us-east-1

# Wait for deletion
aws cloudformation wait stack-delete-complete \
  --stack-name concierge-medicine-stack \
  --region us-east-1

# Verify deletion
aws cloudformation describe-stacks \
  --stack-name concierge-medicine-stack \
  --region us-east-1
```

**Note**: This will delete all resources including the database. Make sure to backup any important data first.

## Cost Estimation

Monthly costs for test environment (us-east-1):

- ECS Fargate (1 task, 256 CPU, 512 MB): ~$10
- RDS PostgreSQL (db.t3.micro): ~$15
- ElastiCache Redis (cache.t3.micro): ~$10
- S3 Storage (10 GB): ~$0.23
- ALB: ~$16
- Data Transfer: ~$5
- CloudWatch: ~$5

**Estimated Total: ~$60/month**

## Support

For issues or questions:
- AWS Support: https://console.aws.amazon.com/support
- Application Support: support@concierge-medicine.com
- Documentation: See README.md and other .md files

## Next Steps

1. Deploy the CloudFormation stack
2. Build and push Docker image to ECR
3. Update ECS service to use the new image
4. Monitor logs and metrics
5. Test the application
6. Update parameters as needed for production

---

**Last Updated**: November 2024
**Version**: 1.0.0
**Status**: Production Ready
