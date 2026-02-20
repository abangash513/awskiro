# HRI Fast Scanner

A lightweight multi-account AWS Well-Architected High-Risk Issue (HRI) detection and reporting system.

## Overview

The HRI Fast Scanner consists of two applications:

1. **HRI Fast Scanner (App 1)**: Scans AWS Organization accounts for ~30 critical issues across 6 Well-Architected pillars
2. **Partner Sync Micro-App (App 2)**: Exports findings to AWS Partner Central format

## Architecture

- **3 Lambda Functions**: discover_accounts, scan_account, partner_sync
- **DynamoDB Table**: hri_findings (on-demand billing)
- **S3 Bucket**: hri_exports (encrypted with lifecycle policies)
- **SNS Topic**: Error notifications
- **EventBridge**: Scheduled execution (optional)

## Cost

Estimated monthly cost: **$3.62** (for 50 accounts, daily scans)
- Lambda: $2.52
- DynamoDB: $0.50
- S3: $0.10
- CloudWatch: $0.50

## Prerequisites

- Node.js 20.x or later
- AWS CDK CLI 2.110.0 or later
- AWS CLI configured with appropriate credentials
- Management account access for deployment
- Member account access for role deployment

## Installation

```bash
cd hri-scanner
npm install
```

## Configuration

Set the following environment variables or CDK context:

```bash
export MANAGEMENT_ACCOUNT_ID="123456789012"
export AWS_REGION="us-east-1"
export EXTERNAL_ID="hri-scanner-unique-id"
```

Or use CDK context:

```bash
cdk deploy --context managementAccountId=123456789012 \
           --context region=us-east-1 \
           --context externalId=hri-scanner-unique-id
```

## Deployment

### Step 1: Bootstrap CDK (if not already done)

```bash
cdk bootstrap aws://MANAGEMENT_ACCOUNT_ID/REGION
```

### Step 2: Deploy Management Account Stack

```bash
npm run deploy:management
```

This deploys:
- Lambda functions (discover_accounts, scan_account, partner_sync)
- DynamoDB table (hri_findings)
- S3 bucket (hri_exports)
- SNS topic for error notifications
- IAM roles and policies

### Step 3: Deploy Member Account Roles

Deploy the HRI-ScannerRole to each member account using CloudFormation StackSets:

```bash
# Synthesize the member stack template
cdk synth MemberStack > member-role-template.yaml

# Create StackSet
aws cloudformation create-stack-set \
  --stack-set-name HRI-ScannerRole \
  --template-body file://member-role-template.yaml \
  --parameters ParameterKey=ManagementAccountId,ParameterValue=MANAGEMENT_ACCOUNT_ID \
               ParameterKey=ExternalId,ParameterValue=EXTERNAL_ID \
  --capabilities CAPABILITY_NAMED_IAM

# Deploy to member accounts
aws cloudformation create-stack-instances \
  --stack-set-name HRI-ScannerRole \
  --accounts ACCOUNT_ID_1 ACCOUNT_ID_2 ACCOUNT_ID_3 \
  --regions REGION
```

### Step 4: Verify Deployment

1. Check Lambda functions in AWS Console
2. Verify DynamoDB table exists
3. Verify S3 bucket exists with encryption
4. Test manual invocation of discover_accounts Lambda

## Usage

### Manual Execution

Invoke the discover_accounts Lambda function manually:

```bash
aws lambda invoke \
  --function-name hri-discover-accounts \
  --payload '{}' \
  response.json
```

### Scheduled Execution

Configure EventBridge to run daily at 2 AM UTC:

```bash
aws events put-rule \
  --name HRI-DailyScan \
  --schedule-expression "cron(0 2 * * ? *)" \
  --state ENABLED

aws events put-targets \
  --rule HRI-DailyScan \
  --targets "Id"="1","Arn"="arn:aws:lambda:REGION:ACCOUNT:function:hri-discover-accounts"

aws lambda add-permission \
  --function-name hri-discover-accounts \
  --statement-id HRI-DailyScan \
  --action 'lambda:InvokeFunction' \
  --principal events.amazonaws.com \
  --source-arn arn:aws:events:REGION:ACCOUNT:rule/HRI-DailyScan
```

### Partner Central Sync

Invoke the partner_sync Lambda function:

```bash
aws lambda invoke \
  --function-name hri-partner-sync \
  --payload '{}' \
  response.json
```

## Monitoring

### CloudWatch Logs

View logs for each Lambda function:

```bash
aws logs tail /aws/lambda/hri-discover-accounts --follow
aws logs tail /aws/lambda/hri-scan-account --follow
aws logs tail /aws/lambda/hri-partner-sync --follow
```

### DynamoDB Findings

Query findings by account:

```bash
aws dynamodb query \
  --table-name hri_findings \
  --key-condition-expression "account_id = :account_id" \
  --expression-attribute-values '{":account_id":{"S":"123456789012"}}'
```

### S3 Reports

List reports:

```bash
aws s3 ls s3://hri-exports-ACCOUNT-REGION/reports/
```

Download a report:

```bash
aws s3 cp s3://hri-exports-ACCOUNT-REGION/reports/EXECUTION_ID/summary.json .
```

## Development

### Build

```bash
npm run build
```

### Watch Mode

```bash
npm run watch
```

### Run Tests

```bash
npm test
```

### Synthesize CloudFormation

```bash
npm run synth
```

### View Differences

```bash
npm run diff
```

## Project Structure

```
hri-scanner/
├── bin/
│   └── hri-scanner.ts          # CDK app entry point
├── lib/
│   ├── management-stack.ts     # Management account resources
│   ├── member-stack.ts         # Member account role
│   └── constructs/
│       ├── scanner-lambda.ts   # Lambda construct
│       └── findings-table.ts   # DynamoDB construct
├── lambda/
│   ├── discover_accounts/
│   │   ├── index.py
│   │   └── requirements.txt
│   ├── scan_account/
│   │   ├── index.py
│   │   └── requirements.txt
│   └── partner_sync/
│       ├── index.py
│       └── requirements.txt
├── test/
│   ├── unit/
│   ├── property/
│   └── integration/
├── cdk.json
├── package.json
├── tsconfig.json
└── README.md
```

## Troubleshooting

### Lambda Timeout

If scans timeout for large accounts:
- Increase Lambda timeout in `lib/management-stack.ts`
- Reduce number of regions scanned
- Implement batching for > 50 accounts

### Permission Denied

If role assumption fails:
- Verify HRI-ScannerRole exists in member account
- Check trust policy includes management account
- Verify external ID matches

### DynamoDB Throttling

If writes are throttled:
- DynamoDB is on-demand, should auto-scale
- Check for burst traffic patterns
- Implement exponential backoff (already included)

## Security

- All data encrypted at rest (DynamoDB, S3)
- All data encrypted in transit (TLS 1.2+)
- Least-privilege IAM roles
- Cross-account roles with external ID
- No long-term credentials stored
- CloudTrail logging enabled

## License

MIT

## Support

For issues or questions, please open an issue in the repository.
