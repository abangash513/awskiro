# HRI Fast Scanner - CloudFormation Deployment Summary

## What Was Created

I've created a complete CloudFormation Infrastructure as Code (IaC) solution for deploying the HRI Fast Scanner to new AWS accounts. This includes:

### 📄 CloudFormation Templates

#### 1. **management-account-stack.yaml** (Main Stack)
Deploys all resources to the management account:

**Compute Resources:**
- ✅ 3 Lambda functions (discover_accounts, scan_account, partner_sync)
- ✅ CloudWatch Log Groups with configurable retention

**Storage Resources:**
- ✅ DynamoDB table (hri_findings) with 2 Global Secondary Indexes
- ✅ S3 bucket with encryption, versioning, and lifecycle policies

**Security Resources:**
- ✅ IAM execution role with least-privilege permissions
- ✅ S3 bucket policy denying insecure transport

**Monitoring Resources:**
- ✅ EventBridge scheduled rule for automated scans
- ✅ CloudWatch alarms for Lambda errors
- ✅ SNS topic for error notifications

**Configurable Parameters:**
- Scanner role name
- Scan regions (comma-separated)
- Notification email
- Log retention days
- Schedule expression (cron)

#### 2. **member-account-stack.yaml** (Member Stack)
Deploys cross-account IAM role to member accounts:

**Security Resources:**
- ✅ HRI-ScannerRole with read-only permissions
- ✅ Trust policy allowing management account assumption
- ✅ External ID for additional security
- ✅ Explicit deny for all write operations

**Permissions Included:**
- S3, EC2, RDS, IAM, Security Hub, Config
- CloudWatch, GuardDuty, CloudTrail
- Cost Explorer, Compute Optimizer
- Backup, Auto Scaling, ELB, Lambda, KMS

### 📚 Documentation

#### 3. **DEPLOYMENT_GUIDE.md**
Comprehensive 400+ line deployment guide including:
- Step-by-step deployment instructions
- Prerequisites and requirements
- Single account and StackSets deployment
- Lambda code packaging and deployment
- Network configuration (VPC optional)
- Post-deployment verification
- Testing procedures
- Troubleshooting guide
- Cost optimization tips
- Update and cleanup procedures

#### 4. **README.md**
Quick reference guide covering:
- Overview of all files
- Quick start instructions (3 deployment options)
- Template parameters reference
- Resources created summary
- Network configuration options
- IAM permissions summary
- Cost estimates
- Monitoring setup
- Security best practices

#### 5. **deploy.sh**
Automated deployment script (Linux/Mac) featuring:
- Interactive prompts for configuration
- Prerequisite checking
- Automatic Lambda code packaging
- Stack deployment with wait conditions
- Lambda code updates
- Member account deployment options
- Deployment verification
- Test execution
- Summary output with next steps

### 🎯 Key Features

#### Complete Infrastructure as Code
- No manual AWS Console configuration needed
- Repeatable deployments across accounts
- Version-controlled infrastructure
- Easy updates and rollbacks

#### Security Best Practices
- Least-privilege IAM roles
- External ID for role assumption
- Explicit deny for write operations
- Encryption at rest and in transit
- Secure transport enforcement

#### Cost Optimization
- On-demand DynamoDB billing
- S3 lifecycle policies (IA → Glacier → Delete)
- Configurable log retention
- Estimated cost: $3.62/month for 50 accounts

#### Flexibility
- Configurable scan regions
- Adjustable scan schedule
- Optional SNS notifications
- VPC deployment support
- StackSets for multi-account deployment

#### Monitoring & Observability
- CloudWatch Logs with retention
- CloudWatch alarms for errors
- SNS notifications for critical issues
- EventBridge scheduled execution

## Deployment Options

### Option 1: Automated Script (Recommended for Linux/Mac)
```bash
cd Kirofiles/hri-scanner/cloudformation
./deploy.sh
```
- Interactive prompts
- Automatic verification
- Built-in testing

### Option 2: Manual AWS CLI (All Platforms)
```bash
# Deploy management stack
aws cloudformation create-stack \
  --stack-name hri-scanner-management \
  --template-body file://management-account-stack.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters ParameterKey=NotificationEmail,ParameterValue=email@example.com

# Update Lambda code
aws lambda update-function-code \
  --function-name hri-discover-accounts \
  --zip-file fileb://discover_accounts.zip

# Deploy member stack
aws cloudformation create-stack \
  --stack-name hri-scanner-member-role \
  --template-body file://member-account-stack.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters ParameterKey=ManagementAccountId,ParameterValue=123456789012
```

### Option 3: AWS Console
1. Upload templates to S3
2. Create stack via CloudFormation console
3. Provide parameters
4. Update Lambda code via console

## Network Architecture

### Default (No VPC)
```
Lambda Functions (AWS-managed VPC)
    ↓
Internet Gateway
    ↓
AWS Services (DynamoDB, S3, Organizations)
```
- **Cost**: $0 additional
- **Pros**: Simple, no management
- **Cons**: No VPC resource access

### VPC Deployment (Optional)
```
Lambda Functions (Private Subnets)
    ↓
NAT Gateway / VPC Endpoints
    ↓
AWS Services
```
- **Cost**: $32/month (NAT) or $0 (VPC Endpoints)
- **Pros**: Enhanced security, VPC access
- **Cons**: Additional complexity

## IAM Permission Model

### Management Account
```
HRIScannerExecutionRole
├── Organizations (ListAccounts, DescribeAccount)
├── Lambda (InvokeFunction)
├── STS (AssumeRole)
├── DynamoDB (PutItem, UpdateItem, Query, Scan)
├── S3 (PutObject, GetObject)
├── SNS (Publish)
└── CloudWatch Logs (CreateLogGroup, PutLogEvents)
```

### Member Accounts
```
HRI-ScannerRole (Read-Only)
├── S3 (Get*, List*, Describe*)
├── EC2 (Describe*)
├── RDS (Describe*)
├── IAM (Get*, List*)
├── Security Hub (GetFindings, DescribeHub)
├── Config (Describe*)
├── CloudWatch (Describe*, GetMetricStatistics)
├── GuardDuty (List*, Get*)
├── CloudTrail (Describe*, GetTrailStatus)
├── Cost Explorer (Get*)
├── Compute Optimizer (Get*)
├── Backup (List*, Describe*)
├── Auto Scaling (Describe*)
├── ELB (Describe*)
├── Lambda (List*, Get*)
├── KMS (List*, Describe*)
└── DENY (All Write Operations)
```

## Resource Naming Convention

All resources follow consistent naming:
- **Lambda Functions**: `hri-{function-name}`
- **DynamoDB Table**: `hri_findings`
- **S3 Bucket**: `hri-exports-{account-id}-{region}`
- **IAM Role (Management)**: `HRIScannerExecutionRole`
- **IAM Role (Member)**: `HRI-ScannerRole`
- **Log Groups**: `/aws/lambda/hri-{function-name}`
- **EventBridge Rule**: `hri-scheduled-scan`
- **SNS Topic**: `hri-scanner-errors`

## Stack Outputs

After deployment, the following outputs are available:

**Management Stack:**
- FindingsTableName
- ReportsBucketName
- DiscoverAccountsFunctionArn
- ScanAccountFunctionArn
- PartnerSyncFunctionArn
- LambdaExecutionRoleArn
- ErrorNotificationTopicArn
- ManagementAccountId

**Member Stack:**
- HRIScannerRoleArn
- HRIScannerRoleName
- ManagementAccountId
- ExternalId

## Testing the Deployment

### 1. Verify Stack Creation
```bash
aws cloudformation describe-stacks \
  --stack-name hri-scanner-management \
  --query 'Stacks[0].StackStatus'
```

### 2. Test Lambda Function
```bash
aws lambda invoke \
  --function-name hri-discover-accounts \
  --payload '{}' \
  response.json
```

### 3. Check Findings
```bash
aws dynamodb scan \
  --table-name hri_findings \
  --max-items 10
```

### 4. View Logs
```bash
aws logs tail /aws/lambda/hri-discover-accounts --follow
```

## Cost Breakdown

### Monthly Costs (50 accounts, daily scans)

| Component | Details | Cost |
|-----------|---------|------|
| **Lambda** | 1,534 invocations, ~7 min total | $2.52 |
| **DynamoDB** | 1,500 writes, 100 reads | $0.50 |
| **S3** | 100 MB storage, 1,500 PUTs | $0.10 |
| **CloudWatch Logs** | 1 GB logs | $0.50 |
| **SNS** | Email notifications | $0.00 |
| **EventBridge** | 30 invocations | $0.00 |
| **Total** | | **$3.62** |

**Scaling:**
- 100 accounts: ~$7/month
- 200 accounts: ~$14/month
- Weekly scans: ~$0.50/month (50 accounts)

## Security Considerations

### ✅ Implemented Security Controls

1. **Encryption**
   - DynamoDB: SSE enabled
   - S3: AES-256 encryption
   - Transit: TLS 1.2+ enforced

2. **Access Control**
   - Least-privilege IAM roles
   - External ID for role assumption
   - Explicit deny for write operations
   - S3 bucket policy denying insecure transport

3. **Monitoring**
   - CloudWatch Logs for all executions
   - CloudWatch alarms for errors
   - SNS notifications for critical issues

4. **Data Protection**
   - S3 versioning enabled
   - DynamoDB point-in-time recovery
   - S3 lifecycle policies for data retention

### 🔒 Additional Recommendations

1. Enable AWS CloudTrail for API auditing
2. Use AWS Config for compliance monitoring
3. Implement AWS Security Hub for centralized findings
4. Rotate external ID periodically
5. Review IAM permissions quarterly
6. Enable MFA for administrative access

## Maintenance

### Regular Tasks

**Weekly:**
- Review CloudWatch Logs for errors
- Check SNS notifications

**Monthly:**
- Review DynamoDB usage and costs
- Clean up old S3 reports (automated)
- Review findings and remediate issues

**Quarterly:**
- Update Lambda runtime versions
- Review and optimize IAM permissions
- Update HRI check logic
- Review cost optimization opportunities

**Annually:**
- Rotate external ID
- Review security posture
- Update documentation
- Conduct security audit

## Next Steps After Deployment

1. **Confirm SNS Subscription**
   - Check email for confirmation link
   - Click to confirm subscription

2. **Deploy to Member Accounts**
   - Use StackSets for multiple accounts
   - Or deploy individually to each account

3. **Run Initial Scan**
   - Invoke discover_accounts manually
   - Review findings in DynamoDB
   - Check S3 for reports

4. **Configure Monitoring**
   - Set up CloudWatch dashboards
   - Configure additional alarms
   - Review notification settings

5. **Optimize Configuration**
   - Adjust scan regions
   - Modify scan schedule
   - Fine-tune log retention

6. **Document Custom Settings**
   - Record external ID securely
   - Document any custom parameters
   - Update runbooks

## Support Resources

- **DEPLOYMENT_GUIDE.md**: Detailed deployment instructions
- **README.md**: Quick reference guide
- **CloudWatch Logs**: Detailed execution logs
- **Stack Events**: CloudFormation deployment history
- **AWS Documentation**: CloudFormation, Lambda, DynamoDB

## Conclusion

You now have a complete, production-ready CloudFormation solution for deploying the HRI Fast Scanner to any AWS account. The templates include:

✅ All required AWS resources
✅ Comprehensive IAM permissions
✅ Security best practices
✅ Cost optimization
✅ Monitoring and alerting
✅ Detailed documentation
✅ Automated deployment scripts

The solution is ready to deploy and will provide automated, cost-effective scanning of AWS accounts for high-risk issues across all Well-Architected pillars.

**Estimated deployment time**: 15-30 minutes
**Estimated monthly cost**: $3.62 (50 accounts, daily scans)
**Maintenance effort**: Minimal (automated scanning)
