# HRI Fast Scanner - CloudFormation Deployment Guide

## Overview

This guide provides step-by-step instructions for deploying the HRI Fast Scanner using CloudFormation templates to a new AWS account.

## Architecture

The deployment consists of two CloudFormation stacks:

1. **Management Account Stack** - Deploys Lambda functions, DynamoDB, S3, IAM roles, and EventBridge
2. **Member Account Stack** - Deploys cross-account IAM role for scanning (deployed to each member account)

## Prerequisites

### Required
- AWS CLI installed and configured
- AWS Organizations enabled in management account
- Python 3.12+ (for Lambda code deployment)
- Valid AWS credentials with administrative access

### Recommended
- AWS CloudFormation StackSets enabled (for automated member account deployment)
- SNS email subscription for error notifications

## Deployment Steps

### Step 1: Prepare Lambda Code

Before deploying the CloudFormation stack, you need to package the Lambda functions.

```bash
cd Kirofiles/hri-scanner/lambda

# Create deployment packages
zip -r discover_accounts.zip discover_accounts.py
zip -r scan_account.zip scan_account.py
zip -r partner_sync.zip partner_sync.py  # If implemented

# Upload to S3 (optional, for larger deployments)
aws s3 mb s3://hri-scanner-deployment-${AWS_ACCOUNT_ID}
aws s3 cp discover_accounts.zip s3://hri-scanner-deployment-${AWS_ACCOUNT_ID}/
aws s3 cp scan_account.zip s3://hri-scanner-deployment-${AWS_ACCOUNT_ID}/
aws s3 cp partner_sync.zip s3://hri-scanner-deployment-${AWS_ACCOUNT_ID}/
```

### Step 2: Deploy Management Account Stack

Deploy the main stack to your management account:

```bash
cd Kirofiles/hri-scanner/cloudformation

# Deploy with default parameters
aws cloudformation create-stack \
  --stack-name hri-scanner-management \
  --template-body file://management-account-stack.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters \
    ParameterKey=NotificationEmail,ParameterValue=your-email@example.com \
  --region us-east-1

# Wait for stack creation to complete
aws cloudformation wait stack-create-complete \
  --stack-name hri-scanner-management \
  --region us-east-1
```

#### Custom Parameters

You can customize the deployment with these parameters:

```bash
aws cloudformation create-stack \
  --stack-name hri-scanner-management \
  --template-body file://management-account-stack.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters \
    ParameterKey=ScannerRoleName,ParameterValue=HRI-ScannerRole \
    ParameterKey=ScanRegions,ParameterValue=us-east-1,us-west-2,eu-west-1 \
    ParameterKey=NotificationEmail,ParameterValue=alerts@example.com \
    ParameterKey=LogRetentionDays,ParameterValue=30 \
    ParameterKey=ScheduleExpression,ParameterValue="cron(0 2 * * ? *)" \
  --region us-east-1
```

### Step 3: Update Lambda Function Code

The CloudFormation template creates Lambda functions with placeholder code. Update them with actual code:

```bash
# Get the management account ID
MGMT_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Update discover_accounts function
aws lambda update-function-code \
  --function-name hri-discover-accounts \
  --zip-file fileb://lambda/discover_accounts.zip \
  --region us-east-1

# Update scan_account function
aws lambda update-function-code \
  --function-name hri-scan-account \
  --zip-file fileb://lambda/scan_account.zip \
  --region us-east-1

# Update partner_sync function (if implemented)
aws lambda update-function-code \
  --function-name hri-partner-sync \
  --zip-file fileb://lambda/partner_sync.zip \
  --region us-east-1
```

### Step 4: Deploy Member Account Stack (Single Account)

Deploy the scanner role to a single member account:

```bash
# Get management account ID
MGMT_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Deploy to member account (run this in the member account context)
aws cloudformation create-stack \
  --stack-name hri-scanner-member-role \
  --template-body file://member-account-stack.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters \
    ParameterKey=ManagementAccountId,ParameterValue=${MGMT_ACCOUNT_ID} \
    ParameterKey=ScannerRoleName,ParameterValue=HRI-ScannerRole \
    ParameterKey=ExternalId,ParameterValue=hri-scanner-external-id-12345 \
  --region us-east-1

# Wait for completion
aws cloudformation wait stack-create-complete \
  --stack-name hri-scanner-member-role \
  --region us-east-1
```

### Step 5: Deploy Member Account Stack (Multiple Accounts via StackSets)

For deploying to multiple member accounts automatically:

```bash
# Create StackSet
aws cloudformation create-stack-set \
  --stack-set-name hri-scanner-member-roles \
  --template-body file://member-account-stack.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters \
    ParameterKey=ManagementAccountId,ParameterValue=${MGMT_ACCOUNT_ID} \
    ParameterKey=ScannerRoleName,ParameterValue=HRI-ScannerRole \
    ParameterKey=ExternalId,ParameterValue=hri-scanner-external-id-12345 \
  --administration-role-arn arn:aws:iam::${MGMT_ACCOUNT_ID}:role/AWSCloudFormationStackSetAdministrationRole \
  --execution-role-name AWSCloudFormationStackSetExecutionRole

# Deploy to specific accounts
aws cloudformation create-stack-instances \
  --stack-set-name hri-scanner-member-roles \
  --accounts 111111111111 222222222222 333333333333 \
  --regions us-east-1

# Or deploy to all accounts in an OU
aws cloudformation create-stack-instances \
  --stack-set-name hri-scanner-member-roles \
  --deployment-targets OrganizationalUnitIds=ou-xxxx-xxxxxxxx \
  --regions us-east-1
```

### Step 6: Verify Deployment

Verify all resources were created successfully:

```bash
# Check stack status
aws cloudformation describe-stacks \
  --stack-name hri-scanner-management \
  --query 'Stacks[0].StackStatus' \
  --output text

# Get stack outputs
aws cloudformation describe-stacks \
  --stack-name hri-scanner-management \
  --query 'Stacks[0].Outputs' \
  --output table

# Verify Lambda functions
aws lambda list-functions \
  --query 'Functions[?starts_with(FunctionName, `hri-`)].FunctionName' \
  --output table

# Verify DynamoDB table
aws dynamodb describe-table \
  --table-name hri_findings \
  --query 'Table.TableStatus' \
  --output text

# Verify S3 bucket
aws s3 ls | grep hri-exports
```

### Step 7: Test the Deployment

Run a manual test scan:

```bash
# Invoke discover_accounts function
aws lambda invoke \
  --function-name hri-discover-accounts \
  --payload '{}' \
  --region us-east-1 \
  response.json

# Check response
cat response.json

# Check CloudWatch Logs
aws logs tail /aws/lambda/hri-discover-accounts --follow

# Check DynamoDB for findings
aws dynamodb scan \
  --table-name hri_findings \
  --max-items 10 \
  --output table
```

## Post-Deployment Configuration

### Configure SNS Email Subscription

If you provided an email address, confirm the SNS subscription:

1. Check your email for a subscription confirmation from AWS
2. Click the confirmation link
3. Verify subscription in AWS Console

### Adjust EventBridge Schedule

To change the scan schedule:

```bash
aws events put-rule \
  --name hri-scheduled-scan \
  --schedule-expression "cron(0 6 * * ? *)" \
  --state ENABLED
```

### Enable/Disable Scheduled Scans

```bash
# Disable scheduled scans
aws events disable-rule --name hri-scheduled-scan

# Enable scheduled scans
aws events enable-rule --name hri-scheduled-scan
```

## Network Configuration

### VPC Deployment (Optional)

If you need to deploy Lambda functions in a VPC:

1. Create VPC with private subnets and NAT Gateway
2. Update Lambda functions with VPC configuration:

```bash
aws lambda update-function-configuration \
  --function-name hri-scan-account \
  --vpc-config SubnetIds=subnet-xxx,subnet-yyy,SecurityGroupIds=sg-xxx
```

**Note**: VPC deployment increases costs due to NAT Gateway charges (~$32/month).

### VPC Endpoints (Cost Optimization)

To avoid NAT Gateway costs, create VPC endpoints:

```bash
# DynamoDB endpoint
aws ec2 create-vpc-endpoint \
  --vpc-id vpc-xxx \
  --service-name com.amazonaws.us-east-1.dynamodb \
  --route-table-ids rtb-xxx

# S3 endpoint
aws ec2 create-vpc-endpoint \
  --vpc-id vpc-xxx \
  --service-name com.amazonaws.us-east-1.s3 \
  --route-table-ids rtb-xxx
```

## IAM Permissions Summary

### Management Account

The Lambda execution role requires:
- **Organizations**: ListAccounts, DescribeAccount
- **Lambda**: InvokeFunction
- **STS**: AssumeRole (for member accounts)
- **DynamoDB**: PutItem, UpdateItem, GetItem, Query, Scan
- **S3**: PutObject, GetObject
- **SNS**: Publish (for notifications)
- **CloudWatch Logs**: CreateLogGroup, CreateLogStream, PutLogEvents

### Member Accounts

The HRI-ScannerRole requires read-only access to:
- S3, EC2, RDS, IAM, Security Hub, Config
- CloudWatch, GuardDuty, CloudTrail
- Cost Explorer, Compute Optimizer
- Backup, Auto Scaling, ELB, Lambda, KMS

**Security**: The role explicitly denies all write operations.

## Troubleshooting

### Stack Creation Failed

```bash
# Check stack events
aws cloudformation describe-stack-events \
  --stack-name hri-scanner-management \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`]' \
  --output table

# Delete failed stack
aws cloudformation delete-stack \
  --stack-name hri-scanner-management
```

### Lambda Function Errors

```bash
# Check CloudWatch Logs
aws logs tail /aws/lambda/hri-discover-accounts --follow

# Check Lambda configuration
aws lambda get-function-configuration \
  --function-name hri-discover-accounts

# Test Lambda locally
aws lambda invoke \
  --function-name hri-discover-accounts \
  --log-type Tail \
  --query 'LogResult' \
  --output text | base64 -d
```

### Role Assumption Failures

```bash
# Verify role exists in member account
aws iam get-role --role-name HRI-ScannerRole

# Test role assumption
aws sts assume-role \
  --role-arn arn:aws:iam::MEMBER_ACCOUNT_ID:role/HRI-ScannerRole \
  --role-session-name test \
  --external-id hri-scanner-external-id-12345
```

### DynamoDB Access Issues

```bash
# Check table status
aws dynamodb describe-table --table-name hri_findings

# Test write access
aws dynamodb put-item \
  --table-name hri_findings \
  --item '{"account_id":{"S":"test"},"check_id":{"S":"test"}}'
```

## Cost Optimization

### Estimated Monthly Costs

For 50 accounts with daily scans:
- Lambda: $2.52
- DynamoDB: $0.50
- S3: $0.10
- CloudWatch Logs: $0.50
- **Total: ~$3.62/month**

### Cost Reduction Tips

1. **Reduce scan frequency**: Change from daily to weekly
2. **Limit regions**: Scan only active regions
3. **Optimize Lambda memory**: Test with lower memory settings
4. **Enable log filtering**: Reduce CloudWatch Logs volume
5. **Use S3 lifecycle policies**: Automatically archive old reports

## Updating the Stack

### Update Stack Parameters

```bash
aws cloudformation update-stack \
  --stack-name hri-scanner-management \
  --use-previous-template \
  --parameters \
    ParameterKey=ScanRegions,ParameterValue=us-east-1,us-west-2,ap-southeast-1 \
  --capabilities CAPABILITY_NAMED_IAM
```

### Update Lambda Code

```bash
# Package new code
cd lambda
zip -r scan_account.zip scan_account.py

# Update function
aws lambda update-function-code \
  --function-name hri-scan-account \
  --zip-file fileb://scan_account.zip
```

## Cleanup

### Delete Management Account Stack

```bash
# Disable EventBridge rule first
aws events disable-rule --name hri-scheduled-scan

# Empty S3 bucket
aws s3 rm s3://hri-exports-${AWS_ACCOUNT_ID}-us-east-1 --recursive

# Delete stack
aws cloudformation delete-stack \
  --stack-name hri-scanner-management

# Wait for deletion
aws cloudformation wait stack-delete-complete \
  --stack-name hri-scanner-management
```

### Delete Member Account Stacks

```bash
# Delete StackSet instances
aws cloudformation delete-stack-instances \
  --stack-set-name hri-scanner-member-roles \
  --accounts 111111111111 222222222222 \
  --regions us-east-1 \
  --no-retain-stacks

# Delete StackSet
aws cloudformation delete-stack-set \
  --stack-set-name hri-scanner-member-roles
```

## Support

For issues or questions:
1. Check CloudWatch Logs for detailed error messages
2. Review the troubleshooting section above
3. Verify IAM permissions are correctly configured
4. Ensure member account roles are deployed

## Next Steps

After successful deployment:
1. Review initial scan findings in DynamoDB
2. Set up CloudWatch dashboards for monitoring
3. Configure SNS notifications for critical findings
4. Implement automated remediation workflows
5. Integrate with AWS Partner Central (if applicable)
