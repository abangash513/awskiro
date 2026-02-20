# HRI Fast Scanner - Deployment Guide (App1a)

## What's Included in App1a

This is the **core HRI Fast Scanner** with:
- ✅ 3 Lambda functions (discover_accounts, scan_account, partner_sync skeleton)
- ✅ All 30 HRI checks across 6 pillars
- ✅ DynamoDB storage for findings
- ✅ S3 report generation
- ✅ Cross-account role assumption
- ✅ Multi-region scanning
- ✅ Error handling and retry logic

**Not Yet Included** (will be App1b):
- EventBridge scheduling
- SNS notifications
- Partner Central sync (full implementation)
- CloudWatch dashboards
- Advanced error handling

## Prerequisites

1. **AWS CLI** configured with credentials
2. **Node.js 20.x** or later
3. **Python 3.12** (for Lambda functions)
4. **AWS CDK 2.110.0** or later
5. **Management account access** for deployment
6. **Member account access** for role deployment

## Step 1: Install Dependencies

```bash
cd hri-scanner
npm install
```

## Step 2: Set Configuration

Set these environment variables or use CDK context:

```bash
# Required
export MANAGEMENT_ACCOUNT_ID="123456789012"
export AWS_REGION="us-east-1"
export EXTERNAL_ID="hri-scanner-$(date +%s)"

# Optional
export SCAN_REGIONS="us-east-1,us-west-2,eu-west-1"
export LOG_LEVEL="INFO"
export NOTIFICATION_EMAIL="your-email@example.com"
```

Or use CDK context:

```bash
cdk deploy --context managementAccountId=123456789012 \
           --context region=us-east-1 \
           --context externalId=hri-scanner-unique-id
```

## Step 3: Bootstrap CDK (First Time Only)

```bash
cdk bootstrap aws://$MANAGEMENT_ACCOUNT_ID/$AWS_REGION
```

## Step 4: Review What Will Be Deployed

```bash
cdk synth ManagementStack
```

This will show you:
- 3 Lambda functions
- 1 DynamoDB table (hri_findings)
- 1 S3 bucket (hri-exports)
- 1 SNS topic (error notifications)
- IAM roles and policies

## Step 5: Deploy Management Account Stack

```bash
cdk deploy ManagementStack
```

**Expected Output:**
```
ManagementStack.ExportsBucketName = hri-exports-123456789012-us-east-1
ManagementStack.TableName = hri_findings
ManagementStack.DiscoverAccountsLambdaArn = arn:aws:lambda:...
ManagementStack.ScanAccountLambdaArn = arn:aws:lambda:...
ManagementStack.PartnerSyncLambdaArn = arn:aws:lambda:...
ManagementStack.ExternalId = hri-scanner-1234567890
```

**Save the ExternalId** - you'll need it for member account deployment!

## Step 6: Deploy Member Account Roles

### Option A: Single Member Account (Manual)

```bash
# Synthesize the member stack template
cdk synth MemberStack > member-role-template.yaml

# Deploy to a single member account
aws cloudformation deploy \
  --template-file member-role-template.yaml \
  --stack-name HRI-ScannerRole \
  --parameter-overrides \
      ManagementAccountId=$MANAGEMENT_ACCOUNT_ID \
      ExternalId=$EXTERNAL_ID \
  --capabilities CAPABILITY_NAMED_IAM \
  --profile member-account-profile
```

### Option B: Multiple Member Accounts (StackSets)

```bash
# Create StackSet
aws cloudformation create-stack-set \
  --stack-set-name HRI-ScannerRole \
  --template-body file://member-role-template.yaml \
  --parameters \
      ParameterKey=ManagementAccountId,ParameterValue=$MANAGEMENT_ACCOUNT_ID \
      ParameterKey=ExternalId,ParameterValue=$EXTERNAL_ID \
  --capabilities CAPABILITY_NAMED_IAM

# Deploy to member accounts
aws cloudformation create-stack-instances \
  --stack-set-name HRI-ScannerRole \
  --accounts 111111111111 222222222222 333333333333 \
  --regions $AWS_REGION
```

## Step 7: Verify Deployment

### Check Lambda Functions

```bash
aws lambda list-functions --query 'Functions[?starts_with(FunctionName, `hri-`)].FunctionName'
```

Expected output:
```json
[
  "hri-discover-accounts",
  "hri-scan-account",
  "hri-partner-sync"
]
```

### Check DynamoDB Table

```bash
aws dynamodb describe-table --table-name hri_findings --query 'Table.[TableName,TableStatus,BillingModeSummary.BillingMode]'
```

Expected output:
```json
[
  "hri_findings",
  "ACTIVE",
  "PAY_PER_REQUEST"
]
```

### Check S3 Bucket

```bash
aws s3 ls | grep hri-exports
```

Expected output:
```
2025-01-01 12:00:00 hri-exports-123456789012-us-east-1
```

### Check Member Account Role

```bash
# Run this in a member account
aws iam get-role --role-name HRI-ScannerRole --query 'Role.RoleName'
```

Expected output:
```
"HRI-ScannerRole"
```

## Step 8: Test the Scanner

### Test 1: Manual Invocation (Single Account)

```bash
# Invoke discover_accounts Lambda
aws lambda invoke \
  --function-name hri-discover-accounts \
  --payload '{}' \
  --cli-binary-format raw-in-base64-out \
  response.json

# Check response
cat response.json
```

Expected output:
```json
{
  "accounts_discovered": 5,
  "accounts_active": 5,
  "accounts_scanned": 5,
  "accounts_failed": 0,
  "execution_id": "uuid",
  "status": "completed"
}
```

### Test 2: Check CloudWatch Logs

```bash
# View discover_accounts logs
aws logs tail /aws/lambda/hri-discover-accounts --follow

# View scan_account logs (in another terminal)
aws logs tail /aws/lambda/hri-scan-account --follow
```

### Test 3: Check DynamoDB Findings

```bash
# Query findings for a specific account
aws dynamodb query \
  --table-name hri_findings \
  --key-condition-expression "account_id = :account_id" \
  --expression-attribute-values '{":account_id":{"S":"123456789012"}}' \
  --limit 5
```

### Test 4: Check S3 Reports

```bash
# List reports
aws s3 ls s3://hri-exports-$MANAGEMENT_ACCOUNT_ID-$AWS_REGION/reports/ --recursive

# Download a report
aws s3 cp s3://hri-exports-$MANAGEMENT_ACCOUNT_ID-$AWS_REGION/reports/EXECUTION_ID/accounts/ACCOUNT_ID.json ./report.json

# View report
cat report.json | jq .
```

## Troubleshooting

### Issue: Lambda Timeout

**Symptom:** scan_account Lambda times out

**Solution:**
1. Check Lambda timeout setting (should be 10 minutes)
2. Reduce number of regions in REGIONS environment variable
3. Check CloudWatch Logs for specific API errors

```bash
aws lambda update-function-configuration \
  --function-name hri-scan-account \
  --timeout 600
```

### Issue: Role Assumption Failed

**Symptom:** "Account is unscannable - role assumption failed"

**Solution:**
1. Verify HRI-ScannerRole exists in member account
2. Check trust policy includes management account
3. Verify ExternalId matches

```bash
# Check role in member account
aws iam get-role --role-name HRI-ScannerRole --profile member-account

# Check trust policy
aws iam get-role --role-name HRI-ScannerRole --query 'Role.AssumeRolePolicyDocument' --profile member-account
```

### Issue: DynamoDB Throttling

**Symptom:** "ProvisionedThroughputExceededException"

**Solution:** DynamoDB is on-demand, should auto-scale. Check for burst traffic.

```bash
# Check table metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name UserErrors \
  --dimensions Name=TableName,Value=hri_findings \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

### Issue: S3 Upload Failed

**Symptom:** "Failed to upload report to S3"

**Solution:**
1. Check S3 bucket exists
2. Verify Lambda has s3:PutObject permission
3. Check bucket policy

```bash
# Check Lambda role permissions
aws iam get-role-policy \
  --role-name hri-scan-account-role \
  --policy-name default-policy
```

### Issue: No Findings Detected

**Symptom:** All scans return 0 findings

**Solution:**
1. This might be correct if accounts are well-configured!
2. Check CloudWatch Logs for check execution
3. Verify checks are running (look for "Security checks completed" logs)

```bash
# Search logs for check execution
aws logs filter-log-events \
  --log-group-name /aws/lambda/hri-scan-account \
  --filter-pattern "checks completed"
```

## Monitoring

### View Lambda Metrics

```bash
# Invocations
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=hri-scan-account \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum

# Errors
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Errors \
  --dimensions Name=FunctionName,Value=hri-scan-account \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

### View DynamoDB Metrics

```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ConsumedWriteCapacityUnits \
  --dimensions Name=TableName,Value=hri_findings \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum
```

## Cost Estimation

For 50 accounts scanned daily:

| Service | Usage | Monthly Cost |
|---------|-------|--------------|
| Lambda (discover_accounts) | 30 invocations × 2 min × 256 MB | $0.01 |
| Lambda (scan_account) | 1,500 invocations × 5 min × 1024 MB | $2.50 |
| DynamoDB | 1,500 writes + 100 reads | $0.50 |
| S3 | 100 MB storage + 1,500 PUT requests | $0.10 |
| CloudWatch Logs | 1 GB logs | $0.50 |
| **Total** | | **~$3.61/month** |

## Clean Up (If Needed)

```bash
# Delete management stack
cdk destroy ManagementStack

# Delete member account roles
aws cloudformation delete-stack-instances \
  --stack-set-name HRI-ScannerRole \
  --accounts 111111111111 222222222222 \
  --regions $AWS_REGION \
  --no-retain-stacks

aws cloudformation delete-stack-set \
  --stack-set-name HRI-ScannerRole
```

## Next Steps (App1b)

After verifying App1a works:
1. Add EventBridge scheduling for automatic daily scans
2. Implement full Partner Central sync
3. Add CloudWatch dashboards
4. Add advanced error handling and notifications
5. Add performance optimizations

## Support

For issues:
1. Check CloudWatch Logs first
2. Review this troubleshooting guide
3. Check AWS service quotas
4. Verify IAM permissions

## Success Criteria

App1a is working correctly when:
- ✅ discover_accounts Lambda successfully lists all accounts
- ✅ scan_account Lambda completes for each account
- ✅ Findings are stored in DynamoDB
- ✅ Reports are uploaded to S3
- ✅ No errors in CloudWatch Logs (or only expected errors for missing services)
- ✅ Cost is under $5/month
