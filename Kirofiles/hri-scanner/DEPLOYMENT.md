# HRI Scanner Deployment Guide

## Prerequisites

1. **AWS Account**: Management account with AWS Organizations enabled
2. **AWS CLI**: Configured with valid credentials
3. **Python 3.12**: For Lambda functions
4. **AWS CDK** (optional): For infrastructure deployment

## Target Account

- **Account ID**: 750299845580
- **Purpose**: Testing HRI Scanner application

## Deployment Steps

### Step 1: Configure AWS Credentials

Ensure your AWS credentials are configured and valid:

```bash
# Check credentials
python hri-scanner/tests/check_aws_credentials.py

# If expired, refresh credentials
aws sso login
# OR
aws configure
```

### Step 2: Create IAM Roles

#### Management Account Role

Create an execution role in the management account (750299845580) with these permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "organizations:ListAccounts",
        "organizations:DescribeAccount",
        "organizations:DescribeOrganization"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Resource": "arn:aws:lambda:*:750299845580:function:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole"
      ],
      "Resource": "arn:aws:iam::*:role/HRI-ScannerRole"
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ],
      "Resource": "arn:aws:dynamodb:*:750299845580:table/hri_findings"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::hri-exports-750299845580-*/*"
    }
  ]
}
```

#### Member Account Role (HRI-ScannerRole)

Deploy this role to each member account you want to scan:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetBucketPublicAccessBlock",
        "s3:GetBucketAcl",
        "s3:GetBucketPolicy",
        "s3:ListAllMyBuckets",
        "s3:GetEncryptionConfiguration",
        "ec2:DescribeVolumes",
        "ec2:DescribeInstances",
        "ec2:DescribeVpcs",
        "ec2:DescribeFlowLogs",
        "ec2:DescribeAddresses",
        "rds:DescribeDBInstances",
        "rds:DescribeDBClusters",
        "iam:GetAccountSummary",
        "iam:ListUsers",
        "iam:ListAccessKeys",
        "iam:GetAccountPasswordPolicy",
        "iam:GetCredentialReport",
        "iam:GenerateCredentialReport",
        "securityhub:GetFindings",
        "securityhub:DescribeHub",
        "config:DescribeConfigurationRecorders",
        "config:DescribeDeliveryChannels",
        "cloudwatch:DescribeAlarms",
        "cloudwatch:GetMetricStatistics",
        "guardduty:ListDetectors",
        "guardduty:GetDetector",
        "cloudtrail:DescribeTrails",
        "cloudtrail:GetTrailStatus",
        "ce:GetCostAndUsage",
        "ce:GetSavingsPlansUtilizationDetails",
        "ce:GetReservationUtilization",
        "compute-optimizer:GetEC2InstanceRecommendations",
        "compute-optimizer:GetLambdaFunctionRecommendations",
        "backup:ListBackupPlans",
        "backup:ListProtectedResources",
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribePolicies",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeTargetHealth",
        "lambda:ListFunctions",
        "lambda:GetFunction",
        "kms:ListKeys",
        "kms:DescribeKey"
      ],
      "Resource": "*"
    }
  ]
}
```

Trust policy for HRI-ScannerRole:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::750299845580:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "hri-scanner-external-id-12345"
        }
      }
    }
  ]
}
```

### Step 3: Create DynamoDB Table

```bash
aws dynamodb create-table \
  --table-name hri_findings \
  --attribute-definitions \
    AttributeName=account_id,AttributeType=S \
    AttributeName=check_id,AttributeType=S \
    AttributeName=pillar,AttributeType=S \
    AttributeName=timestamp,AttributeType=S \
    AttributeName=execution_id,AttributeType=S \
  --key-schema \
    AttributeName=account_id,KeyType=HASH \
    AttributeName=check_id,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST \
  --global-secondary-indexes \
    "[
      {
        \"IndexName\": \"pillar-timestamp-index\",
        \"KeySchema\": [
          {\"AttributeName\":\"pillar\",\"KeyType\":\"HASH\"},
          {\"AttributeName\":\"timestamp\",\"KeyType\":\"RANGE\"}
        ],
        \"Projection\": {\"ProjectionType\":\"ALL\"}
      },
      {
        \"IndexName\": \"execution-timestamp-index\",
        \"KeySchema\": [
          {\"AttributeName\":\"execution_id\",\"KeyType\":\"HASH\"},
          {\"AttributeName\":\"timestamp\",\"KeyType\":\"RANGE\"}
        ],
        \"Projection\": {\"ProjectionType\":\"ALL\"}
      }
    ]" \
  --region us-east-1
```

### Step 4: Create S3 Bucket

```bash
aws s3 mb s3://hri-exports-750299845580-us-east-1 --region us-east-1

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket hri-exports-750299845580-us-east-1 \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket hri-exports-750299845580-us-east-1 \
  --versioning-configuration Status=Enabled
```

### Step 5: Deploy Lambda Functions

#### Package Lambda 1 (discover_accounts)

```bash
cd hri-scanner/lambda
zip -r discover_accounts.zip discover_accounts.py

# Create Lambda function
aws lambda create-function \
  --function-name hri-discover-accounts \
  --runtime python3.12 \
  --role arn:aws:iam::750299845580:role/HRIScannerExecutionRole \
  --handler discover_accounts.lambda_handler \
  --zip-file fileb://discover_accounts.zip \
  --timeout 120 \
  --memory-size 256 \
  --environment Variables="{
    SCAN_LAMBDA_ARN=arn:aws:lambda:us-east-1:750299845580:function:hri-scan-account,
    DYNAMODB_TABLE=hri_findings,
    LOG_LEVEL=INFO
  }" \
  --region us-east-1
```

### Step 6: Test the Deployment

```bash
# Test account discovery
python hri-scanner/tests/test_live_account.py

# Or invoke Lambda directly
aws lambda invoke \
  --function-name hri-discover-accounts \
  --payload '{}' \
  --region us-east-1 \
  response.json

cat response.json
```

## Verification Checklist

- [ ] AWS credentials are valid and not expired
- [ ] IAM roles created in management account
- [ ] HRI-ScannerRole deployed to member accounts
- [ ] DynamoDB table created with GSIs
- [ ] S3 bucket created with encryption and versioning
- [ ] Lambda function deployed successfully
- [ ] Test execution completes without errors

## Troubleshooting

### Expired Credentials

```bash
aws sso login
# OR
aws configure
```

### Permission Errors

Ensure the IAM role has all required permissions listed above.

### Lambda Timeout

Increase timeout if scanning takes longer than expected:

```bash
aws lambda update-function-configuration \
  --function-name hri-discover-accounts \
  --timeout 300
```

## Next Steps

1. Implement Lambda 2 (scan_account)
2. Implement HRI checks for all 6 pillars
3. Set up EventBridge schedule for automated scanning
4. Configure SNS for error notifications
5. Create CloudWatch dashboards for monitoring
