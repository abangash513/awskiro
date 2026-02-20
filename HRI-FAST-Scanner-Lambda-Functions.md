# HRI FAST Scanner - Lambda Functions

**Account:** 750299845580 (AAIDemo)  
**Region:** us-east-1  
**Status:** ✅ Deployed and Operational  
**Last Updated:** December 9, 2025

---

## Lambda Functions

### 1. hri-discover-accounts

**Function Name:** `hri-discover-accounts`  
**Runtime:** Python 3.11  
**Memory:** 256 MB  
**Timeout:** 2 minutes  
**Handler:** `discover_accounts.lambda_handler`

**Purpose:** Discovers all AWS Organization member accounts and triggers scanning

**AWS Console Link:**
```
https://us-east-1.console.aws.amazon.com/lambda/home?region=us-east-1#/functions/hri-discover-accounts
```

**Direct Link (clickable):**
[Open hri-discover-accounts in AWS Console](https://us-east-1.console.aws.amazon.com/lambda/home?region=us-east-1#/functions/hri-discover-accounts)

**Code Location:**
- Local: `Kirofiles/hri-scanner/lambda/discover_accounts.py`
- Deployed: `Kirofiles/hri-scanner/lambda/discover_accounts.zip`

**Key Features:**
- Retrieves all active member accounts from AWS Organizations
- Filters out suspended or closed accounts
- Invokes scan_account Lambda for each discovered account
- Handles pagination for large organizations

**IAM Role:** `HRIScannerExecutionRole`

**Environment Variables:**
- `SCAN_LAMBDA_NAME`: hri-scan-account
- `SCANNER_ROLE_NAME`: HRI-ScannerRole

---

### 2. hri-scan-account

**Function Name:** `hri-scan-account`  
**Runtime:** Python 3.11  
**Memory:** 1024 MB  
**Timeout:** 10 minutes  
**Handler:** `scan_account.lambda_handler`

**Purpose:** Executes 30 HRI checks across 6 Well-Architected pillars for a single account

**AWS Console Link:**
```
https://us-east-1.console.aws.amazon.com/lambda/home?region=us-east-1#/functions/hri-scan-account
```

**Direct Link (clickable):**
[Open hri-scan-account in AWS Console](https://us-east-1.console.aws.amazon.com/lambda/home?region=us-east-1#/functions/hri-scan-account)

**Code Location:**
- Local: `Kirofiles/hri-scanner/lambda/scan_account.py`
- Deployed: `Kirofiles/hri-scanner/lambda/scan_account.zip`

**Key Features:**
- Assumes cross-account HRI-ScannerRole
- Executes 30 Well-Architected HRI checks
- Stores findings in DynamoDB
- Handles errors gracefully

**IAM Role:** `HRIScannerExecutionRole`

**Environment Variables:**
- `SCANNER_ROLE_NAME`: HRI-ScannerRole
- `DYNAMODB_TABLE`: hri_findings
- `S3_BUCKET`: hri-exports-750299845580-us-east-1

**HRI Checks Implemented (30 total):**

**Security (11 checks):**
1. Public S3 buckets
2. Unencrypted EBS volumes
3. Unencrypted RDS instances
4. Root account MFA
5. IAM users without MFA
6. IAM access keys > 90 days
7. CloudTrail multi-region
8. GuardDuty enabled
9. S3 Block Public Access
10. KMS CMK usage
11. Security Hub findings

**Reliability (6 checks):**
1. AWS Config enabled
2. CloudWatch alarms
3. Backup solutions
4. Single-AZ RDS
5. VPC Flow Logs
6. ASG health checks

**Performance (4 checks):**
1. Legacy instance families
2. Idle EC2 instances
3. Over-provisioned EC2
4. Lambda high timeout/error rates

**Cost Optimization (6 checks):**
1. Unattached EBS volumes
2. Idle EC2 instances
3. gp2 to gp3 migration
4. Savings Plan coverage
5. RDS RI coverage
6. Idle ALB/ELB/EIP

**Sustainability (3 checks):**
1. Non-gp3 volumes
2. Old-generation instances
3. Outdated RDS classes

---

### 3. partner_sync (Not Yet Deployed)

**Function Name:** `hri-partner-sync` (planned)  
**Status:** ⏳ Not implemented yet

**Purpose:** Reads HRI findings from DynamoDB and exports to AWS Partner Central format

**Planned Features:**
- Read findings from DynamoDB
- Transform to Partner Central format
- Export to S3 for partner integration
- Schedule regular syncs

---

## Supporting Resources

### DynamoDB Table

**Table Name:** `hri_findings`

**AWS Console Link:**
```
https://us-east-1.console.aws.amazon.com/dynamodbv2/home?region=us-east-1#table?name=hri_findings
```

**Direct Link:**
[Open hri_findings in AWS Console](https://us-east-1.console.aws.amazon.com/dynamodbv2/home?region=us-east-1#table?name=hri_findings)

**Schema:**
- Partition Key: `account_id` (String)
- Sort Key: `check_id` (String)
- Billing Mode: On-Demand
- GSIs:
  - `pillar-timestamp-index`
  - `execution-timestamp-index`

---

### S3 Bucket

**Bucket Name:** `hri-exports-750299845580-us-east-1`

**AWS Console Link:**
```
https://s3.console.aws.amazon.com/s3/buckets/hri-exports-750299845580-us-east-1?region=us-east-1
```

**Direct Link:**
[Open hri-exports bucket in AWS Console](https://s3.console.aws.amazon.com/s3/buckets/hri-exports-750299845580-us-east-1?region=us-east-1)

**Configuration:**
- Encryption: SSE-S3 (AES-256)
- Versioning: Enabled
- Lifecycle: Configured

---

### IAM Roles

#### HRIScannerExecutionRole (Management Account)

**Role Name:** `HRIScannerExecutionRole`

**AWS Console Link:**
```
https://us-east-1.console.aws.amazon.com/iam/home?region=us-east-1#/roles/HRIScannerExecutionRole
```

**Direct Link:**
[Open HRIScannerExecutionRole in AWS Console](https://us-east-1.console.aws.amazon.com/iam/home?region=us-east-1#/roles/HRIScannerExecutionRole)

**Permissions:**
- Assume HRI-ScannerRole in member accounts
- Write to DynamoDB (hri_findings)
- Write to S3 (hri-exports bucket)
- Invoke Lambda functions
- CloudWatch Logs

---

#### HRI-ScannerRole (Member Accounts)

**Role Name:** `HRI-ScannerRole`

**AWS Console Link (for account 750299845580):**
```
https://us-east-1.console.aws.amazon.com/iam/home?region=us-east-1#/roles/HRI-ScannerRole
```

**Direct Link:**
[Open HRI-ScannerRole in AWS Console](https://us-east-1.console.aws.amazon.com/iam/home?region=us-east-1#/roles/HRI-ScannerRole)

**Trust Policy:**
- Trusted by: HRIScannerExecutionRole in management account

**Permissions:**
- Read-only access to:
  - EC2 (instances, volumes, security groups)
  - S3 (buckets, ACLs)
  - RDS (instances, snapshots)
  - IAM (users, roles, policies)
  - CloudTrail (trails, status)
  - GuardDuty (detectors)
  - Security Hub (findings)
  - Config (recorders)
  - CloudWatch (metrics, alarms)
  - VPC (flow logs)
  - Auto Scaling (groups)
  - Lambda (functions)
  - Cost Explorer (recommendations)

---

## CloudWatch Logs

### discover_accounts Logs

**Log Group:** `/aws/lambda/hri-discover-accounts`

**AWS Console Link:**
```
https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups/log-group/$252Faws$252Flambda$252Fhri-discover-accounts
```

**Direct Link:**
[Open discover_accounts logs in AWS Console](https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups/log-group/$252Faws$252Flambda$252Fhri-discover-accounts)

---

### scan_account Logs

**Log Group:** `/aws/lambda/hri-scan-account`

**AWS Console Link:**
```
https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups/log-group/$252Faws$252Flambda$252Fhri-scan-account
```

**Direct Link:**
[Open scan_account logs in AWS Console](https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups/log-group/$252Faws$252Flambda$252Fhri-scan-account)

---

## Quick Access Commands

### Test Lambda Functions

```powershell
# Test discover_accounts
aws lambda invoke --function-name hri-discover-accounts --region us-east-1 response.json
cat response.json

# Test scan_account for specific account
aws lambda invoke --function-name hri-scan-account --region us-east-1 --payload '{"account_id":"750299845580","account_name":"AAIDemo"}' response.json
cat response.json
```

### View Findings

```powershell
# Query DynamoDB for all findings
aws dynamodb scan --table-name hri_findings --region us-east-1

# Query findings for specific account
aws dynamodb query --table-name hri_findings --region us-east-1 --key-condition-expression "account_id = :aid" --expression-attribute-values '{":aid":{"S":"750299845580"}}'

# Count findings by severity
aws dynamodb scan --table-name hri_findings --region us-east-1 --select COUNT
```

### View Logs

```powershell
# View recent discover_accounts logs
aws logs tail /aws/lambda/hri-discover-accounts --region us-east-1 --follow

# View recent scan_account logs
aws logs tail /aws/lambda/hri-scan-account --region us-east-1 --follow
```

---

## Local Development

### Code Locations

```
Kirofiles/hri-scanner/
├── lambda/
│   ├── discover_accounts.py       # Lambda 1 source code
│   ├── scan_account.py            # Lambda 2 source code
│   ├── requirements.txt           # Python dependencies
│   ├── discover_accounts.zip      # Deployed package
│   └── scan_account.zip           # Deployed package
├── tests/
│   ├── test_discover_accounts.py  # Unit tests
│   ├── test_scan_account.py       # Unit tests
│   └── test_live_account.py       # Integration tests
├── deploy.py                      # Infrastructure deployment
├── deploy_lambdas.py              # Lambda deployment
├── deploy_scanner_role.py         # Role deployment
├── check_findings.py              # View findings
└── generate_report.py             # Generate reports
```

### Deployment Scripts

```powershell
# Deploy infrastructure (DynamoDB, S3, IAM roles)
cd Kirofiles/hri-scanner
python deploy.py

# Deploy Lambda functions
python deploy_lambdas.py

# Deploy scanner role to member accounts
python deploy_scanner_role.py --account-id 750299845580

# Check findings
python check_findings.py

# Generate report
python generate_report.py
```

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     Management Account (750299845580)            │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                  EventBridge (Optional)                   │   │
│  │              Scheduled Trigger (Daily/Weekly)             │   │
│  └──────────────────────────────────────────────────────────┘   │
│                               │                                  │
│                               ▼                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │         Lambda 1: hri-discover-accounts                   │   │
│  │         - List AWS Organization accounts                  │   │
│  │         - Filter active accounts                          │   │
│  │         - Invoke scan Lambda for each                     │   │
│  └──────────────────────────────────────────────────────────┘   │
│                               │                                  │
│                               ▼                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │         Lambda 2: hri-scan-account                        │   │
│  │         - Assume cross-account role                       │   │
│  │         - Execute 30 HRI checks                           │   │
│  │         - Store findings in DynamoDB                      │   │
│  └──────────────────────────────────────────────────────────┘   │
│                               │                                  │
│                               │ AssumeRole(HRI-ScannerRole)      │
│                               ▼                                  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Member Account (750299845580)                │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              HRI-ScannerRole (Read-Only)                  │   │
│  └──────────────────────────────────────────────────────────┘   │
│                               │                                  │
│                               ▼                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    AWS Resources                          │   │
│  │  - EC2 Instances, EBS Volumes                             │   │
│  │  - S3 Buckets                                             │   │
│  │  - RDS Instances                                          │   │
│  │  - IAM Users, Roles                                       │   │
│  │  - CloudTrail, GuardDuty, Config                          │   │
│  │  - Security Hub, CloudWatch                               │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Storage & Reporting                      │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │         DynamoDB: hri_findings                            │   │
│  │         - Stores all HRI findings                         │   │
│  │         - Indexed by account and pillar                   │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │         S3: hri-exports-750299845580-us-east-1            │   │
│  │         - Aggregated reports                              │   │
│  │         - Partner Central exports                         │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Current Findings

### Account: 750299845580 (AAIDemo)

**Last Scan:** December 9, 2025

**Critical Issues Found: 5**

1. ❌ **CloudTrail Multi-Region Not Enabled**
   - Severity: HIGH
   - Pillar: Security

2. ❌ **GuardDuty Not Enabled** (us-west-2)
   - Severity: HIGH
   - Pillar: Security

3. ❌ **IAM User Without MFA**
   - User: AAIDemo
   - Severity: HIGH
   - Pillar: Security

4. ❌ **IAM Access Key 788 Days Old**
   - Key: AKIA25MK3CPGF3BSAOWC
   - Severity: CRITICAL
   - Pillar: Security

5. ❌ **Public S3 Bucket**
   - Bucket: elasticbeanstalk-us-east-1-750299845580
   - Severity: HIGH
   - Pillar: Security

---

## Performance Metrics

### Lambda Execution Times
- **discover_accounts:** < 1 second
- **scan_account:** < 15 seconds per account

### Cost Estimate
- **Lambda invocations:** ~$0.01 per scan
- **DynamoDB:** On-demand (minimal cost)
- **S3:** Minimal storage costs
- **Total monthly cost:** < $5

---

## Next Steps

1. **Deploy to Additional Accounts:**
   - Deploy HRI-ScannerRole to member accounts:
     - 610382284946 (Audit)
     - 488705985969 (Log Archive)

2. **Implement Lambda 3 (partner_sync):**
   - Read findings from DynamoDB
   - Transform to Partner Central format
   - Export to S3

3. **Set Up Automation:**
   - Configure EventBridge schedule
   - Set up SNS notifications
   - Create CloudWatch dashboards

4. **Address Findings:**
   - Enable MFA for IAM users
   - Rotate old access keys
   - Enable CloudTrail multi-region
   - Enable GuardDuty
   - Secure public S3 buckets

---

## Support

**Documentation:**
- Full documentation: `Kirofiles/hri-scanner/README.md`
- Deployment guide: `Kirofiles/hri-scanner/DEPLOYMENT.md`
- Final summary: `Kirofiles/hri-scanner/FINAL_SUMMARY.md`

**Troubleshooting:**
1. Check CloudWatch Logs for errors
2. Verify IAM roles and permissions
3. Confirm HRI-ScannerRole deployed to member accounts
4. Review DynamoDB for findings

---

**Last Updated:** February 1, 2026  
**Account:** 750299845580 (AAIDemo)  
**Region:** us-east-1  
**Status:** ✅ Operational

---

**END OF DOCUMENT**
