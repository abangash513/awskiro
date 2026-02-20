# Uninstall Instructions for Concierge Medicine Application

## Overview
This guide will help you completely remove the concierge medicine application from your AWS account (750299845580).

## Prerequisites
- AWS CLI installed and configured
- Credentials for AWS account 750299845580
- Appropriate IAM permissions to delete CloudFormation stacks

## Quick Uninstall

### Option 1: Using PowerShell (Windows)
```powershell
.\delete-cloudformation-stack.ps1
```

### Option 2: Using Bash (Linux/Mac/Git Bash)
```bash
chmod +x delete-cloudformation-stack.sh
./delete-cloudformation-stack.sh
```

### Option 3: Using AWS CLI Directly
```bash
# Delete the stack
aws cloudformation delete-stack --stack-name concierge-medicine-stack --region us-east-1

# Wait for deletion to complete (optional)
aws cloudformation wait stack-delete-complete --stack-name concierge-medicine-stack --region us-east-1
```

## What Gets Deleted

When you delete the CloudFormation stack, the following resources will be removed:

### Compute Resources
- ECS Cluster
- ECS Services (Backend and Frontend)
- ECS Task Definitions
- Fargate Tasks

### Networking Resources
- Application Load Balancer
- Target Groups
- VPC (if created by the stack)
- Subnets
- Internet Gateway
- Route Tables
- Security Groups

### Database Resources
- RDS PostgreSQL Instance
- Database Subnet Group
- **⚠️ WARNING: All database data will be permanently deleted**

### Storage Resources
- S3 Buckets (medical records, documents)
- **⚠️ WARNING: All uploaded files will be permanently deleted**

### Security Resources
- IAM Roles
- IAM Policies
- Security Groups

### Monitoring Resources
- CloudWatch Log Groups
- CloudWatch Alarms

## Deletion Timeline

The deletion process typically takes **10-20 minutes** and follows this sequence:

1. ECS Services stop (2-3 minutes)
2. Load Balancer deletion (2-3 minutes)
3. RDS Database deletion (5-10 minutes)
4. VPC and networking cleanup (2-3 minutes)
5. IAM roles and policies cleanup (1-2 minutes)

## Manual Cleanup (If Needed)

If the CloudFormation deletion fails or you need to manually clean up resources:

### 1. Empty and Delete S3 Buckets
```bash
# List buckets
aws s3 ls | grep concierge-medicine

# Empty a bucket
aws s3 rm s3://bucket-name --recursive

# Delete the bucket
aws s3 rb s3://bucket-name
```

### 2. Delete RDS Database
```bash
# Delete without final snapshot
aws rds delete-db-instance \
  --db-instance-identifier concierge-medicine-db \
  --skip-final-snapshot \
  --region us-east-1
```

### 3. Delete ECS Resources
```bash
# Stop and delete services
aws ecs update-service \
  --cluster concierge-medicine-cluster \
  --service backend-service \
  --desired-count 0 \
  --region us-east-1

aws ecs delete-service \
  --cluster concierge-medicine-cluster \
  --service backend-service \
  --region us-east-1

# Delete cluster
aws ecs delete-cluster \
  --cluster concierge-medicine-cluster \
  --region us-east-1
```

### 4. Delete Load Balancer
```bash
# Get load balancer ARN
aws elbv2 describe-load-balancers \
  --region us-east-1 \
  --query 'LoadBalancers[?contains(LoadBalancerName, `concierge`)].LoadBalancerArn' \
  --output text

# Delete load balancer
aws elbv2 delete-load-balancer \
  --load-balancer-arn <ARN> \
  --region us-east-1
```

### 5. Delete VPC Resources
```bash
# Delete security groups, subnets, route tables, internet gateway, and VPC
# (This is complex - use AWS Console for easier manual cleanup)
```

## Verification

After deletion, verify all resources are removed:

```bash
# Check CloudFormation stack
aws cloudformation describe-stacks \
  --stack-name concierge-medicine-stack \
  --region us-east-1

# Should return: "Stack with id concierge-medicine-stack does not exist"

# Check for remaining S3 buckets
aws s3 ls | grep concierge-medicine

# Check for remaining RDS instances
aws rds describe-db-instances \
  --region us-east-1 \
  --query 'DBInstances[?contains(DBInstanceIdentifier, `concierge`)].DBInstanceIdentifier'

# Check for remaining ECS clusters
aws ecs list-clusters --region us-east-1 | grep concierge-medicine
```

## Cost Considerations

After deletion:
- **Immediate**: ECS, Load Balancer, and compute charges stop
- **Within hours**: RDS charges stop after deletion completes
- **Within 24 hours**: S3 storage charges stop after bucket deletion
- **Final bill**: You may see charges for the current billing period

## Troubleshooting

### Stack Deletion Fails
If the stack deletion fails:

1. Check the CloudFormation events:
```bash
aws cloudformation describe-stack-events \
  --stack-name concierge-medicine-stack \
  --region us-east-1 \
  --max-items 20
```

2. Common issues:
   - **S3 buckets not empty**: Empty buckets manually before retrying
   - **RDS deletion protection**: Disable protection in RDS console
   - **ENI still attached**: Wait a few minutes and retry

3. Force delete (if needed):
```bash
# Retain problematic resources and delete the rest
aws cloudformation delete-stack \
  --stack-name concierge-medicine-stack \
  --region us-east-1 \
  --retain-resources <ResourceLogicalId>
```

### Resources Still Exist After Deletion
Some resources may persist:
- S3 buckets with versioning enabled
- CloudWatch Logs (may be retained)
- IAM roles with dependencies

Manually delete these using the AWS Console or CLI commands above.

## Support

If you encounter issues:
1. Check CloudFormation stack events for error messages
2. Review AWS CloudFormation documentation
3. Contact AWS Support if needed

## Data Backup Reminder

**⚠️ IMPORTANT**: Before deleting, ensure you have backed up:
- Patient data from RDS database
- Medical records from S3 buckets
- Any configuration or customization you want to preserve

Once deleted, **data cannot be recovered**.
