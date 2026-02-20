# HRI Fast Scanner - CloudFormation Templates

## Overview

This directory contains CloudFormation templates for deploying the HRI Fast Scanner to AWS accounts. The templates provide a complete Infrastructure as Code (IaC) solution for automated deployment.

## Files

### CloudFormation Templates

1. **management-account-stack.yaml**
   - Deploys all resources to the management account
   - Creates Lambda functions, DynamoDB table, S3 bucket, IAM roles
   - Sets up EventBridge scheduling and CloudWatch monitoring
   - Configures SNS notifications for errors

2. **member-account-stack.yaml**
   - Deploys cross-account IAM role to member accounts
   - Provides read-only access for scanning
   - Includes explicit deny for write operations
   - Supports deployment via StackSets

### Deployment Scripts

3. **deploy.sh**
   - Automated deployment script (Linux/Mac)
   - Interactive prompts for configuration
   - Handles Lambda code packaging and deployment
   - Includes verification and testing steps

4. **DEPLOYMENT_GUIDE.md**
   - Comprehensive deployment documentation
   - Step-by-step instructions
   - Troubleshooting guide
   - Cost optimization tips

## Quick Start

### Prerequisites

- AWS CLI installed and configured
- Python 3.12+
- Administrative access to AWS account
- AWS Organizations enabled (for management account)

### Option 1: Automated Deployment (Linux/Mac)

```bash
cd Kirofiles/hri-scanner/cloudformation
./deploy.sh
```

Follow the interactive prompts to complete deployment.

### Option 2: Manual Deployment

```bash
# 1. Deploy management account stack
aws cloudformation create-stack \
  --stack-name hri-scanner-management \
  --template-body file://management-account-stack.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters ParameterKey=NotificationEmail,ParameterValue=your-email@example.com \
  --region us-east-1

# 2. Wait for completion
aws cloudformation wait stack-create-complete \
  --stack-name hri-scanner-management \
  --region us-east-1

# 3. Update Lambda code
cd ../lambda
zip discover_accounts.zip discover_accounts.py
zip scan_account.zip scan_account.py

aws lambda update-function-code \
  --function-name hri-discover-accounts \
  --zip-file fileb://discover_accounts.zip

aws lambda update-function-code \
  --function-name hri-scan-account \
  --zip-file fileb://scan_account.zip

# 4. Deploy member account role
aws cloudformation create-stack \
  --stack-name hri-scanner-member-role \
  --template-body file://member-account-stack.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters \
    ParameterKey=ManagementAccountId,ParameterValue=YOUR_MGMT_ACCOUNT_ID \
  --region us-east-1
```

### Option 3: Windows PowerShell Deployment

```powershell
# 1. Set variables
$StackName = "hri-scanner-management"
$Region = "us-east-1"
$Email = "your-email@example.com"

# 2. Deploy management stack
aws cloudformation create-stack `
  --stack-name $StackName `
  --template-body file://management-account-stack.yaml `
  --capabilities CAPABILITY_NAMED_IAM `
  --parameters ParameterKey=NotificationEmail,ParameterValue=$Email `
  --region $Region

# 3. Wait for completion
aws cloudformation wait stack-create-complete `
  --stack-name $StackName `
  --region $Region

# 4. Update Lambda code
cd ..\lambda
Compress-Archive -Path discover_accounts.py -DestinationPath discover_accounts.zip -Force
Compress-Archive -Path scan_account.py -DestinationPath scan_account.zip -Force

aws lambda update-function-code `
  --function-name hri-discover-accounts `
  --zip-file fileb://discover_accounts.zip `
  --region $Region

aws lambda update-function-code `
  --function-name hri-scan-account `
  --zip-file fileb://scan_account.zip `
  --region $Region
```

## Template Parameters

### Management Account Stack

| Parameter | Default | Description |
|-----------|---------|-------------|
| ScannerRoleName | HRI-ScannerRole | Name of cross-account role in member accounts |
| ScanRegions | us-east-1,us-west-2 | Comma-separated list of regions to scan |
| NotificationEmail | (empty) | Email for SNS error notifications |
| LogRetentionDays | 30 | CloudWatch Logs retention period |
| ScheduleExpression | cron(0 2 * * ? *) | EventBridge schedule (daily at 2 AM UTC) |

### Member Account Stack

| Parameter | Default | Description |
|-----------|---------|-------------|
| ManagementAccountId | (required) | AWS Account ID of management account |
| ScannerRoleName | HRI-ScannerRole | Name of cross-account role |
| ExternalId | hri-scanner-external-id-12345 | External ID for role assumption |

## Resources Created

### Management Account

**Compute:**
- 3 Lambda functions (discover_accounts, scan_account, partner_sync)
- CloudWatch Log Groups (30-day retention)

**Storage:**
- DynamoDB table (hri_findings) with 2 GSIs
- S3 bucket (hri-exports-{account-id}-{region})

**Security:**
- IAM execution role (HRIScannerExecutionRole)
- S3 bucket policy (deny insecure transport)

**Monitoring:**
- EventBridge scheduled rule
- CloudWatch alarms (Lambda errors)
- SNS topic (error notifications)

### Member Accounts

**Security:**
- IAM role (HRI-ScannerRole) with read-only permissions
- Trust policy allowing management account assumption
- Explicit deny for all write operations

## Network Configuration

### Default Deployment (No VPC)

The default deployment does not use VPC. Lambda functions run in AWS-managed VPC with internet access.

**Pros:**
- Simple deployment
- No additional costs
- Automatic scaling

**Cons:**
- Cannot access VPC-only resources
- Less network isolation

### VPC Deployment (Optional)

For enhanced security or VPC resource access:

1. Create VPC with private subnets
2. Create NAT Gateway or VPC endpoints
3. Update Lambda configuration:

```bash
aws lambda update-function-configuration \
  --function-name hri-scan-account \
  --vpc-config SubnetIds=subnet-xxx,subnet-yyy,SecurityGroupIds=sg-xxx
```

**Cost Impact:**
- NAT Gateway: ~$32/month
- VPC Endpoints (DynamoDB + S3): Free

**Recommendation:** Use VPC endpoints instead of NAT Gateway to avoid additional costs.

## IAM Permissions

### Management Account Role

The Lambda execution role has permissions for:
- **Organizations**: List and describe accounts
- **Lambda**: Invoke scan functions
- **STS**: Assume cross-account roles
- **DynamoDB**: Read/write findings
- **S3**: Store reports
- **SNS**: Publish notifications
- **CloudWatch Logs**: Write logs

### Member Account Role

The HRI-ScannerRole has read-only permissions for:
- **Security**: S3, IAM, Security Hub, GuardDuty, CloudTrail, KMS
- **Compute**: EC2, Lambda, Auto Scaling
- **Database**: RDS
- **Monitoring**: CloudWatch, Config
- **Cost**: Cost Explorer, Compute Optimizer
- **Backup**: AWS Backup
- **Network**: VPC, ELB

**Security Features:**
- External ID required for role assumption
- Explicit deny for all write operations
- Least-privilege access model

## Cost Estimate

### Monthly Costs (50 accounts, daily scans)

| Service | Usage | Cost |
|---------|-------|------|
| Lambda (discover_accounts) | 30 invocations × 2 min × 256 MB | $0.01 |
| Lambda (scan_account) | 1,500 invocations × 5 min × 1024 MB | $2.50 |
| Lambda (partner_sync) | 4 invocations × 2 min × 512 MB | $0.01 |
| DynamoDB | 1,500 writes + 100 reads | $0.50 |
| S3 | 100 MB storage + 1,500 PUT requests | $0.10 |
| CloudWatch Logs | 1 GB logs | $0.50 |
| **Total** | | **$3.62** |

**Note:** Costs scale linearly with account count and scan frequency.

## Monitoring

### CloudWatch Metrics

The deployment creates CloudWatch alarms for:
- Lambda function errors
- High error rates
- Execution failures

### CloudWatch Logs

Log groups created:
- `/aws/lambda/hri-discover-accounts`
- `/aws/lambda/hri-scan-account`
- `/aws/lambda/hri-partner-sync`

### SNS Notifications

If email is provided, you'll receive notifications for:
- Lambda execution errors
- High error rates
- Critical failures

## Updating the Deployment

### Update Stack Parameters

```bash
aws cloudformation update-stack \
  --stack-name hri-scanner-management \
  --use-previous-template \
  --parameters ParameterKey=ScanRegions,ParameterValue=us-east-1,us-west-2,eu-west-1 \
  --capabilities CAPABILITY_NAMED_IAM
```

### Update Lambda Code

```bash
cd lambda
zip scan_account.zip scan_account.py

aws lambda update-function-code \
  --function-name hri-scan-account \
  --zip-file fileb://scan_account.zip
```

### Update Template

```bash
aws cloudformation update-stack \
  --stack-name hri-scanner-management \
  --template-body file://management-account-stack.yaml \
  --capabilities CAPABILITY_NAMED_IAM
```

## Cleanup

### Delete Management Stack

```bash
# Disable EventBridge rule
aws events disable-rule --name hri-scheduled-scan

# Empty S3 bucket
aws s3 rm s3://hri-exports-${ACCOUNT_ID}-us-east-1 --recursive

# Delete stack
aws cloudformation delete-stack --stack-name hri-scanner-management
```

### Delete Member Stack

```bash
aws cloudformation delete-stack --stack-name hri-scanner-member-role
```

## Troubleshooting

### Common Issues

**Issue: Stack creation fails with "CAPABILITY_NAMED_IAM required"**
```bash
# Solution: Add --capabilities flag
aws cloudformation create-stack ... --capabilities CAPABILITY_NAMED_IAM
```

**Issue: Lambda function has no code**
```bash
# Solution: Update function code after stack creation
aws lambda update-function-code --function-name hri-scan-account --zip-file fileb://scan_account.zip
```

**Issue: Role assumption fails**
```bash
# Solution: Verify external ID matches in both stacks
# Check trust policy in member account role
aws iam get-role --role-name HRI-ScannerRole
```

**Issue: DynamoDB access denied**
```bash
# Solution: Verify Lambda execution role has DynamoDB permissions
aws iam get-role-policy --role-name HRIScannerExecutionRole --policy-name HRIScannerPolicy
```

### Getting Help

1. Check CloudWatch Logs for detailed error messages
2. Review stack events for deployment issues
3. Verify IAM permissions are correctly configured
4. Consult DEPLOYMENT_GUIDE.md for detailed troubleshooting

## Security Best Practices

1. **Use External ID**: Always use a unique external ID for role assumption
2. **Rotate External ID**: Change external ID periodically
3. **Limit Regions**: Only scan regions where you have resources
4. **Enable CloudTrail**: Monitor all API calls
5. **Review Findings**: Regularly review and remediate findings
6. **Least Privilege**: Member account role has read-only access only
7. **Encryption**: All data encrypted at rest and in transit

## Support

For issues or questions:
- Review DEPLOYMENT_GUIDE.md for detailed instructions
- Check CloudWatch Logs for error details
- Verify prerequisites are met
- Ensure AWS credentials are valid

## License

Internal use only - AIM Consulting
