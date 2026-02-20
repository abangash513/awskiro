# Design Document

## Overview

The HRI Fast Scanner system is a serverless, multi-account AWS Well-Architected High-Risk Issue (HRI) detection and reporting platform. The system consists of two primary applications:

1. **HRI Fast Scanner (App 1)**: A lightweight scanning engine that discovers AWS Organization member accounts, assumes cross-account roles, executes 30 HRI checks across 6 Well-Architected pillars, and stores findings in DynamoDB with aggregated reports in S3.

2. **Partner Sync Micro-App (App 2)**: A minimal integration service that reads HRI findings from DynamoDB, transforms them into AWS Partner Central format, and exports them for partner business account integration.

The system is designed for cost-effectiveness (< $5/month), scalability (100+ accounts), and operational simplicity (3 Lambda functions, DynamoDB, S3, EventBridge).

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Management Account                            │
│                                                                   │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐  │
│  │ EventBridge  │─────▶│   Lambda 1   │      │   Lambda 3   │  │
│  │   Schedule   │      │   discover_  │      │   partner_   │  │
│  └──────────────┘      │   accounts   │      │     sync     │  │
│                        └──────┬───────┘      └──────┬───────┘  │
│                               │                     │           │
│                               ▼                     │           │
│                        ┌──────────────┐            │           │
│                        │   Lambda 2   │            │           │
│                        │    scan_     │            │           │
│                        │   account    │            │           │
│                        └──────┬───────┘            │           │
│                               │                     │           │
│                               ▼                     ▼           │
│                        ┌──────────────┐      ┌──────────────┐  │
│                        │  DynamoDB    │◀─────│  DynamoDB    │  │
│                        │ hri_findings │      │ hri_findings │  │
│                        └──────┬───────┘      └──────────────┘  │
│                               │                     │           │
│                               ▼                     ▼           │
│                        ┌──────────────┐      ┌──────────────┐  │
│                        │      S3      │      │      S3      │  │
│                        │ hri_exports  │      │partner_export│  │
│                        └──────────────┘      └──────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                               │
                               │ AssumeRole(HRI-ScannerRole)
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Member Accounts                             │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              HRI-ScannerRole (Read-Only)                  │   │
│  └──────────────────────────────────────────────────────────┘   │
│                               │                                  │
│                               ▼                                  │
│  ┌────────┬────────┬────────┬────────┬────────┬────────────┐   │
│  │   S3   │  EC2   │  RDS   │  IAM   │Security│   Config   │   │
│  │        │        │        │        │  Hub   │            │   │
│  └────────┴────────┴────────┴────────┴────────┴────────────┘   │
│  ┌────────┬────────┬────────┬────────┬────────────────────┐   │
│  │CloudWch│GuardDty│  Cost  │Compute │   CloudTrail       │   │
│  │        │        │Explorer│Optimzr │                    │   │
│  └────────┴────────┴────────┴────────┴────────────────────┘   │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **Discovery Flow**: EventBridge → Lambda 1 (discover_accounts) → Organizations API → Lambda 2 (scan_account) invocations
2. **Scanning Flow**: Lambda 2 → AssumeRole → Member Account APIs → DynamoDB (findings) → S3 (reports)
3. **Partner Sync Flow**: Lambda 3 (manual/scheduled) → DynamoDB (read) → Transform → S3 (partner export)

### Regional Deployment

- **Primary Region**: us-east-1 (or configurable)
- **Lambda Functions**: Deployed in management account primary region
- **DynamoDB**: Single-region table with point-in-time recovery
- **S3**: Single-region bucket with versioning and encryption
- **Cross-Region Scanning**: Lambda 2 queries resources across all enabled regions in each member account

## Components and Interfaces

### Lambda 1: discover_accounts

**Purpose**: Discover all active member accounts in AWS Organization

**Runtime**: Python 3.12 or Node.js 20.x

**Memory**: 256 MB

**Timeout**: 2 minutes

**Trigger**: EventBridge scheduled rule (daily/weekly) or manual invocation

**Environment Variables**:
- `SCAN_LAMBDA_ARN`: ARN of Lambda 2 (scan_account)
- `DYNAMODB_TABLE`: Name of hri_findings table
- `LOG_LEVEL`: Logging verbosity (INFO, DEBUG)

**IAM Permissions**:
- `organizations:ListAccounts`
- `organizations:DescribeAccount`
- `lambda:InvokeFunction` (for Lambda 2)
- `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`

**Input**: EventBridge event (scheduled) or empty JSON for manual invocation

**Output**: 
```json
{
  "accounts_discovered": 45,
  "accounts_scanned": 43,
  "accounts_failed": 2,
  "execution_id": "uuid"
}
```

**Logic**:
1. Call `organizations.list_accounts()` with pagination
2. Filter for ACTIVE accounts only
3. For each account, invoke Lambda 2 asynchronously with account details
4. Track invocation success/failure
5. Return summary statistics

### Lambda 2: scan_account

**Purpose**: Execute all 30 HRI checks for a single member account

**Runtime**: Python 3.12 or Node.js 20.x

**Memory**: 1024 MB (increased for parallel API calls)

**Timeout**: 10 minutes

**Trigger**: Asynchronous invocation from Lambda 1

**Environment Variables**:
- `SCANNER_ROLE_NAME`: Name of cross-account role (default: HRI-ScannerRole)
- `DYNAMODB_TABLE`: Name of hri_findings table
- `S3_BUCKET`: Name of hri_exports bucket
- `REGIONS`: Comma-separated list of regions to scan (default: all enabled)
- `LOG_LEVEL`: Logging verbosity

**IAM Permissions**:
- `sts:AssumeRole` (for HRI-ScannerRole in member accounts)
- `dynamodb:PutItem`, `dynamodb:UpdateItem`
- `s3:PutObject`
- `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`

**Input**:
```json
{
  "account_id": "123456789012",
  "account_name": "Production",
  "execution_id": "uuid"
}
```

**Output**:
```json
{
  "account_id": "123456789012",
  "findings_count": 12,
  "hri_count": 8,
  "scan_duration_seconds": 145,
  "status": "completed"
}
```

**Logic**:
1. Assume HRI-ScannerRole in target account using STS
2. Execute all 30 HRI checks in parallel (grouped by service)
3. For each finding, write to DynamoDB with retry logic
4. Generate account-specific JSON report and upload to S3
5. Handle errors gracefully, continue scanning even if individual checks fail
6. Return summary statistics

### Lambda 3: partner_sync

**Purpose**: Transform HRI findings into AWS Partner Central format and export

**Runtime**: Python 3.12 or Node.js 20.x

**Memory**: 512 MB

**Timeout**: 5 minutes

**Trigger**: Manual invocation or scheduled EventBridge rule

**Environment Variables**:
- `DYNAMODB_TABLE`: Name of hri_findings table
- `S3_BUCKET`: Name of hri_exports bucket
- `PARTNER_BUCKET_PREFIX`: S3 prefix for partner exports (default: partner-central/)
- `LOG_LEVEL`: Logging verbosity

**IAM Permissions**:
- `dynamodb:Scan`, `dynamodb:Query`
- `s3:PutObject`
- `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`

**Input**: Empty JSON or filter parameters

**Output**:
```json
{
  "findings_processed": 156,
  "export_file": "s3://bucket/partner-central/export-2025-01-01.json",
  "status": "completed"
}
```

**Logic**:
1. Scan DynamoDB hri_findings table (with pagination)
2. Transform each finding to Partner Central schema
3. Group findings by account and pillar
4. Generate Partner Central import JSON
5. Upload to S3 with timestamp
6. Return export summary

### DynamoDB Table: hri_findings

**Table Name**: hri_findings

**Billing Mode**: On-Demand (PAY_PER_REQUEST)

**Partition Key**: `account_id` (String)

**Sort Key**: `check_id` (String) - format: `{pillar}#{check_name}`

**Attributes**:
- `account_id` (String): AWS account ID
- `check_id` (String): Composite key of pillar and check name
- `pillar` (String): Well-Architected pillar (Security, Reliability, Performance, Cost, Sustainability, Operational Excellence)
- `check_name` (String): Human-readable check name
- `hri` (Boolean): True if high-risk issue detected
- `evidence` (String): Resource ARN, ID, or description
- `region` (String): AWS region where resource exists (or "global")
- `timestamp` (String): ISO 8601 timestamp of last scan
- `execution_id` (String): UUID of scan execution
- `resource_tags` (Map): Optional resource tags
- `cost_impact` (Number): Optional estimated monthly cost impact

**Global Secondary Indexes**:
- **GSI1**: `pillar` (PK) + `timestamp` (SK) - for querying findings by pillar
- **GSI2**: `execution_id` (PK) + `timestamp` (SK) - for querying findings by scan execution

**TTL**: Optional TTL attribute `ttl` for automatic cleanup of old findings (e.g., 90 days)

### S3 Bucket: hri_exports

**Bucket Name**: hri-exports-{account-id}-{region}

**Encryption**: SSE-S3 (AES-256) or SSE-KMS

**Versioning**: Enabled

**Lifecycle Policies**:
- Transition to S3 Standard-IA after 30 days
- Transition to S3 Glacier after 90 days
- Delete after 365 days

**Folder Structure**:
```
/reports/
  /{execution_id}/
    /summary.json
    /accounts/
      /{account_id}.json
/partner-central/
  /export-{timestamp}.json
```

### IAM Role: HRI-ScannerRole (Member Accounts)

**Role Name**: HRI-ScannerRole

**Trust Policy**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::{management-account-id}:role/HRIScannerExecutionRole"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "{unique-external-id}"
        }
      }
    }
  ]
}
```

**Permissions Policy**: Read-only access to:
- S3: `s3:GetBucketPublicAccessBlock`, `s3:GetBucketAcl`, `s3:GetBucketPolicy`, `s3:ListBucket`, `s3:GetEncryptionConfiguration`
- EC2: `ec2:DescribeVolumes`, `ec2:DescribeInstances`, `ec2:DescribeVpcs`, `ec2:DescribeFlowLogs`, `ec2:DescribeAddresses`
- RDS: `rds:DescribeDBInstances`, `rds:DescribeDBClusters`
- IAM: `iam:GetAccountSummary`, `iam:ListUsers`, `iam:ListAccessKeys`, `iam:GetAccountPasswordPolicy`, `iam:GetCredentialReport`
- Security Hub: `securityhub:GetFindings`, `securityhub:DescribeHub`
- Config: `config:DescribeConfigurationRecorders`, `config:DescribeDeliveryChannels`
- CloudWatch: `cloudwatch:DescribeAlarms`, `cloudwatch:GetMetricStatistics`
- GuardDuty: `guardduty:ListDetectors`, `guardduty:GetDetector`
- CloudTrail: `cloudtrail:DescribeTrails`, `cloudtrail:GetTrailStatus`
- Cost Explorer: `ce:GetCostAndUsage`, `ce:GetSavingsPlansUtilizationDetails`, `ce:GetReservationUtilization`
- Compute Optimizer: `compute-optimizer:GetEC2InstanceRecommendations`, `compute-optimizer:GetLambdaFunctionRecommendations`
- Backup: `backup:ListBackupPlans`, `backup:ListProtectedResources`
- Auto Scaling: `autoscaling:DescribeAutoScalingGroups`, `autoscaling:DescribePolicies`
- Elastic Load Balancing: `elasticloadbalancing:DescribeLoadBalancers`, `elasticloadbalancing:DescribeTargetHealth`
- Lambda: `lambda:ListFunctions`, `lambda:GetFunction`
- KMS: `kms:ListKeys`, `kms:DescribeKey`

## Data Models

### Finding Record (DynamoDB)

```json
{
  "account_id": "123456789012",
  "check_id": "Security#Public_S3_Bucket",
  "pillar": "Security",
  "check_name": "Public S3 Bucket",
  "hri": true,
  "evidence": "arn:aws:s3:::my-public-bucket",
  "region": "us-east-1",
  "timestamp": "2025-01-01T12:00:00Z",
  "execution_id": "550e8400-e29b-41d4-a716-446655440000",
  "resource_tags": {
    "Environment": "Production",
    "Owner": "TeamA"
  },
  "cost_impact": 0
}
```

### Account Report (S3 JSON)

```json
{
  "account_id": "123456789012",
  "account_name": "Production",
  "scan_timestamp": "2025-01-01T12:00:00Z",
  "execution_id": "550e8400-e29b-41d4-a716-446655440000",
  "summary": {
    "total_checks": 30,
    "total_hris": 8,
    "by_pillar": {
      "Security": 3,
      "Reliability": 2,
      "Performance": 1,
      "Cost": 2,
      "Sustainability": 0,
      "Operational Excellence": 0
    }
  },
  "findings": [
    {
      "pillar": "Security",
      "check_name": "Public S3 Bucket",
      "hri": true,
      "evidence": "arn:aws:s3:::my-public-bucket",
      "region": "us-east-1"
    }
  ]
}
```

### Aggregated Report (S3 JSON)

```json
{
  "execution_id": "550e8400-e29b-41d4-a716-446655440000",
  "scan_timestamp": "2025-01-01T12:00:00Z",
  "accounts_scanned": 43,
  "total_hris": 156,
  "summary_by_pillar": {
    "Security": 67,
    "Reliability": 34,
    "Performance": 23,
    "Cost": 28,
    "Sustainability": 4,
    "Operational Excellence": 0
  },
  "top_issues": [
    {
      "check_name": "IAM Users Without MFA",
      "count": 23,
      "affected_accounts": 15
    }
  ],
  "accounts": [
    {
      "account_id": "123456789012",
      "account_name": "Production",
      "hri_count": 8
    }
  ]
}
```

### Partner Central Export Format

```json
{
  "export_timestamp": "2025-01-01T12:00:00Z",
  "partner_id": "partner-12345",
  "customer_accounts": [
    {
      "account_id": "123456789012",
      "account_name": "Production",
      "assessment_date": "2025-01-01",
      "pillars": [
        {
          "pillar_name": "Security",
          "risk_level": "HIGH",
          "findings_count": 3,
          "findings": [
            {
              "finding_id": "Security#Public_S3_Bucket",
              "title": "Public S3 Bucket Detected",
              "description": "S3 bucket is publicly accessible",
              "severity": "HIGH",
              "resource_arn": "arn:aws:s3:::my-public-bucket",
              "recommendation": "Enable S3 Block Public Access and review bucket policies"
            }
          ]
        }
      ]
    }
  ]
}
```


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Account Discovery Completeness

*For any* AWS Organization structure, when the discovery function executes, all accounts with ACTIVE status should be included in the returned account list, and no accounts with SUSPENDED or CLOSED status should be included.

**Validates: Requirements 1.1, 1.2**

### Property 2: Account Metadata Completeness

*For any* discovered account, the stored metadata must include account_id, account_name, and organizational_unit fields, and all fields must be non-empty strings.

**Validates: Requirements 1.3**

### Property 3: Retry Logic Consistency

*For any* Organizations API failure, the system should retry exactly 3 times with exponential backoff, and the delay between retries should increase exponentially.

**Validates: Requirements 1.5**

### Property 4: Cross-Account Role Assumption

*For any* member account with HRI-ScannerRole present, the scanner should successfully assume the role and receive temporary credentials that are used for all subsequent API calls.

**Validates: Requirements 2.1, 2.2**

### Property 5: Graceful Role Assumption Failure

*For any* member account where role assumption fails, the system should log the failure, mark the account as unscannable, and continue processing the next account without throwing exceptions.

**Validates: Requirements 2.3, 2.5**

### Property 6: Security Check Execution

*For any* scannable account, all 11 security HRI checks should be executed, and each check should make the appropriate AWS API call (S3, EC2, RDS, IAM, Security Hub, GuardDuty, CloudTrail, KMS).

**Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.10, 3.11**

### Property 7: Reliability Check Execution

*For any* scannable account, all 6 reliability HRI checks should be executed, and each check should make the appropriate AWS API call (Config, CloudWatch, Backup, RDS, VPC, Auto Scaling).

**Validates: Requirements 4.1, 4.2, 4.3, 4.4, 4.5, 4.6**

### Property 8: Performance Check Execution

*For any* scannable account, all 4 performance HRI checks should be executed, and each check should make the appropriate AWS API call (CloudWatch, Compute Optimizer, Lambda, EC2).

**Validates: Requirements 5.1, 5.2, 5.3, 5.4**

### Property 9: Cost Optimization Check Execution

*For any* scannable account, all 6 cost optimization HRI checks should be executed, and each check should make the appropriate AWS API call (CloudWatch, EC2, Cost Explorer, ELB).

**Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.5, 6.6**

### Property 10: Sustainability Check Execution

*For any* scannable account, all 3 sustainability HRI checks should be executed, and each check should make the appropriate AWS API call (EC2, RDS).

**Validates: Requirements 7.1, 7.2, 7.3**

### Property 11: Finding Record Structure

*For any* detected HRI, the created finding record must include account_id, pillar, check_name, evidence, timestamp, and hri fields, and all fields must be non-empty.

**Validates: Requirements 8.1, 8.3, 8.4**

### Property 12: DynamoDB Key Structure

*For any* finding stored in DynamoDB, the partition key should be account_id and the sort key should be in the format "{pillar}#{check_name}".

**Validates: Requirements 8.2**

### Property 13: Finding Update Idempotency

*For any* existing finding, when a new scan detects the same issue, the system should update the timestamp and evidence fields without creating a duplicate record.

**Validates: Requirements 8.5**

### Property 14: Report Grouping Correctness

*For any* aggregated report, findings should be grouped by pillar and account, and the summary statistics should accurately reflect the count of HRIs in each group.

**Validates: Requirements 9.2, 9.3**

### Property 15: S3 Upload Encryption

*For any* report uploaded to S3, server-side encryption should be enabled, verifiable through the S3 object metadata.

**Validates: Requirements 9.5**

### Property 16: Pagination Handling

*For any* account list exceeding the API page size limit, the system should implement pagination and retrieve all accounts across all pages.

**Validates: Requirements 10.2**

### Property 17: Exponential Backoff with Jitter

*For any* API rate limit error, the system should implement exponential backoff with jitter, where retry delays increase exponentially and include random jitter to avoid thundering herd.

**Validates: Requirements 10.4**

### Property 18: Batch Processing

*For any* account count exceeding 50, the system should process accounts in batches, and no batch should exceed the configured batch size.

**Validates: Requirements 10.5**

### Property 19: EventBridge Trigger Handling

*For any* EventBridge scheduled event, the system should initiate account discovery and log the execution start to CloudWatch.

**Validates: Requirements 11.2, 11.3**

### Property 20: Error Notification

*For any* critical error during execution, the system should publish an error notification to the configured SNS topic with error details.

**Validates: Requirements 11.4, 14.4**

### Property 21: Partner Sync Data Completeness

*For any* HRI finding in DynamoDB, the Partner Sync function should read the finding and include it in the transformation process.

**Validates: Requirements 12.1**

### Property 22: Partner Central Format Transformation

*For any* HRI finding, the transformation to Partner Central format should map pillar to pillar_name, check_name to title, evidence to resource_arn, and hri to severity.

**Validates: Requirements 12.2, 12.3, 12.4**

### Property 23: Partner Sync Unique Identifiers

*For any* finding synced to Partner Central, the system should generate a unique identifier in the format "{account_id}#{pillar}#{check_name}", ensuring no duplicates exist.

**Validates: Requirements 13.1**

### Property 24: Partner Sync Idempotency

*For any* finding that already exists in the Partner Central export, re-running the sync should update the existing record rather than creating a duplicate.

**Validates: Requirements 13.2**

### Property 25: Sync Timestamp Recording

*For any* completed sync operation, the system should record the sync timestamp in DynamoDB, allowing tracking of last successful sync.

**Validates: Requirements 13.3**

### Property 26: Comprehensive Logging

*For any* Lambda function execution, the system should log execution start, completion, and any errors to CloudWatch with appropriate log levels.

**Validates: Requirements 14.1, 14.2, 14.3**

### Property 27: Throttle Event Logging

*For any* API throttling event, the system should log the throttle event, the service being called, and the retry attempt number.

**Validates: Requirements 14.5**

### Property 28: API Call Caching

*For any* repeated API call with identical parameters within the same execution, the system should return cached results rather than making redundant API calls.

**Validates: Requirements 15.4**

### Property 29: Parallel Processing Concurrency Limits

*For any* parallel processing operation, the system should enforce the configured concurrency limit, ensuring no more than the limit number of concurrent executions occur.

**Validates: Requirements 18.1, 18.2**

### Property 30: DynamoDB Throttle Handling

*For any* DynamoDB throttling error, the system should implement exponential backoff and retry the operation up to the configured maximum retry count.

**Validates: Requirements 18.4**

### Property 31: S3 Retry Logic

*For any* S3 throttling error, the system should implement retry logic with jitter, where retry delays include random jitter to avoid synchronized retries.

**Validates: Requirements 18.5**

### Property 32: Evidence Field Completeness

*For any* detected HRI, the evidence field should contain either a resource ARN or a resource identifier, and the field should not be empty.

**Validates: Requirements 19.1**

### Property 33: Finding Metadata Completeness

*For any* detected HRI, the finding metadata should include region and, if available, resource_tags fields.

**Validates: Requirements 19.2, 19.3**

### Property 34: Security Hub ARN Reference

*For any* HRI derived from Security Hub, the evidence field should contain the Security Hub finding ARN in the correct format.

**Validates: Requirements 19.4**

### Property 35: Cost Impact Inclusion

*For any* cost-related HRI, the finding should include a cost_impact field with an estimated monthly cost value greater than or equal to zero.

**Validates: Requirements 19.5**

### Property 36: Multi-Region Scanning

*For any* account scan, the system should query resources in all enabled regions, and regional findings should include the region identifier.

**Validates: Requirements 20.1, 20.2, 20.4**

### Property 37: Global Service Single Query

*For any* global service (IAM, Organizations, CloudTrail), the system should query the service only once per account, regardless of the number of regions configured.

**Validates: Requirements 20.3**

### Property 38: Region Filtering

*For any* configured region exclusion list, the system should skip scanning resources in excluded regions, and no findings should be generated for excluded regions.

**Validates: Requirements 20.5**

## Error Handling

### Error Categories

1. **Transient Errors**: API throttling, temporary network issues, service unavailability
   - **Strategy**: Exponential backoff with jitter, retry up to 3 times
   - **Implementation**: Use AWS SDK built-in retry logic with custom backoff configuration

2. **Permanent Errors**: Missing IAM role, insufficient permissions, resource not found
   - **Strategy**: Log error, mark account/check as failed, continue processing
   - **Implementation**: Catch specific exception types, log to CloudWatch, update status in DynamoDB

3. **Critical Errors**: Lambda timeout, out of memory, unhandled exceptions
   - **Strategy**: Log error with stack trace, send SNS notification, fail gracefully
   - **Implementation**: Top-level exception handler, CloudWatch Logs, SNS integration

### Error Handling Patterns

**Pattern 1: Retry with Exponential Backoff**
```python
def retry_with_backoff(func, max_retries=3, base_delay=1):
    for attempt in range(max_retries):
        try:
            return func()
        except ThrottlingException as e:
            if attempt == max_retries - 1:
                raise
            delay = base_delay * (2 ** attempt) + random.uniform(0, 1)
            time.sleep(delay)
            logger.warning(f"Retry {attempt + 1}/{max_retries} after {delay}s")
```

**Pattern 2: Graceful Degradation**
```python
def scan_account(account_id):
    findings = []
    for check in ALL_CHECKS:
        try:
            result = execute_check(check, account_id)
            if result:
                findings.append(result)
        except Exception as e:
            logger.error(f"Check {check} failed for {account_id}: {e}")
            # Continue with next check
    return findings
```

**Pattern 3: Circuit Breaker**
```python
class CircuitBreaker:
    def __init__(self, failure_threshold=5, timeout=60):
        self.failure_count = 0
        self.failure_threshold = failure_threshold
        self.timeout = timeout
        self.last_failure_time = None
        self.state = "CLOSED"  # CLOSED, OPEN, HALF_OPEN
    
    def call(self, func):
        if self.state == "OPEN":
            if time.time() - self.last_failure_time > self.timeout:
                self.state = "HALF_OPEN"
            else:
                raise CircuitBreakerOpenError()
        
        try:
            result = func()
            if self.state == "HALF_OPEN":
                self.state = "CLOSED"
                self.failure_count = 0
            return result
        except Exception as e:
            self.failure_count += 1
            self.last_failure_time = time.time()
            if self.failure_count >= self.failure_threshold:
                self.state = "OPEN"
            raise
```

### Logging Strategy

**Log Levels**:
- **DEBUG**: Detailed diagnostic information (API request/response, intermediate values)
- **INFO**: General informational messages (scan started, account processed, findings count)
- **WARNING**: Recoverable errors (API throttling, retry attempts, missing optional data)
- **ERROR**: Serious errors (check failures, permission denied, resource not found)
- **CRITICAL**: System-level failures (Lambda timeout, out of memory, unhandled exceptions)

**Structured Logging Format**:
```json
{
  "timestamp": "2025-01-01T12:00:00Z",
  "level": "INFO",
  "execution_id": "uuid",
  "account_id": "123456789012",
  "component": "scan_account",
  "message": "Scan completed",
  "metadata": {
    "findings_count": 12,
    "duration_seconds": 145
  }
}
```

## Testing Strategy

### Unit Testing

**Scope**: Individual functions and methods in isolation

**Approach**:
- Mock AWS SDK calls using `boto3` mocking libraries (`moto`, `botocore.stub`)
- Test each HRI check function independently
- Verify error handling and retry logic
- Test data transformation functions (DynamoDB to Partner Central)
- Test utility functions (key generation, timestamp formatting)

**Example Unit Tests**:
- `test_discover_accounts_filters_inactive()`: Verify inactive accounts are filtered
- `test_check_public_s3_buckets_detects_public()`: Verify public S3 bucket detection
- `test_retry_logic_exponential_backoff()`: Verify exponential backoff calculation
- `test_transform_to_partner_format()`: Verify Partner Central transformation
- `test_generate_composite_key()`: Verify DynamoDB key generation

**Coverage Target**: 80% code coverage minimum

### Property-Based Testing

**Framework**: Hypothesis (Python) or fast-check (Node.js)

**Scope**: Universal properties that should hold across all inputs

**Approach**:
- Generate random AWS account structures and verify discovery completeness
- Generate random finding records and verify DynamoDB key structure
- Generate random API responses and verify parsing correctness
- Generate random error scenarios and verify retry behavior
- Generate random account lists and verify batching logic

**Property Test Configuration**:
- Minimum 100 iterations per property test
- Use shrinking to find minimal failing examples
- Seed random generator for reproducibility

**Example Property Tests**:
- Property 1: Account discovery completeness (Requirements 1.1, 1.2)
- Property 11: Finding record structure (Requirements 8.1, 8.3, 8.4)
- Property 17: Exponential backoff with jitter (Requirements 10.4)
- Property 22: Partner Central format transformation (Requirements 12.2, 12.3, 12.4)

### Integration Testing

**Scope**: End-to-end workflows with real AWS services (in test account)

**Approach**:
- Deploy system to test AWS account
- Create test member accounts with known HRI conditions
- Execute full scan and verify findings
- Verify DynamoDB records and S3 reports
- Test Partner Sync with real DynamoDB data

**Test Scenarios**:
- Single account scan with all HRI types present
- Multi-account scan with 10+ accounts
- Scan with missing IAM role in one account
- Scan with API throttling simulation
- Partner Sync with 100+ findings

### Performance Testing

**Scope**: Verify system meets performance requirements

**Approach**:
- Measure Lambda execution time for single account scan
- Measure end-to-end execution time for 50+ accounts
- Verify memory usage stays within Lambda limits
- Test API rate limit handling under load
- Verify cost stays under $5/month target

**Performance Targets**:
- Single account scan: < 5 minutes
- 50 account scan: < 30 minutes
- Lambda memory usage: < 1024 MB
- DynamoDB read/write: < 100 units per scan
- S3 storage: < 100 MB per month

## Deployment

### Infrastructure as Code

**Tool**: AWS CDK (TypeScript) or AWS SAM (YAML)

**Stacks**:
1. **Management Account Stack**: Lambda functions, DynamoDB table, S3 bucket, EventBridge rules, IAM roles
2. **Member Account Stack**: HRI-ScannerRole with trust policy and permissions

### CDK Deployment Structure

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
└── package.json
```

### Deployment Steps

**Step 1: Deploy Management Account Stack**
```bash
cd hri-scanner
npm install
cdk bootstrap aws://{management-account-id}/{region}
cdk deploy ManagementStack
```

**Step 2: Deploy Member Account Roles (StackSets)**
```bash
# Create StackSet for member account roles
aws cloudformation create-stack-set \
  --stack-set-name HRI-ScannerRole \
  --template-body file://member-role-template.yaml \
  --parameters ParameterKey=ManagementAccountId,ParameterValue={management-account-id} \
  --capabilities CAPABILITY_NAMED_IAM

# Deploy to all member accounts
aws cloudformation create-stack-instances \
  --stack-set-name HRI-ScannerRole \
  --accounts {account-id-1} {account-id-2} ... \
  --regions {region}
```

**Step 3: Configure EventBridge Schedule**
```bash
# Enable daily scan at 2 AM UTC
aws events put-rule \
  --name HRI-DailyScan \
  --schedule-expression "cron(0 2 * * ? *)" \
  --state ENABLED

aws events put-targets \
  --rule HRI-DailyScan \
  --targets "Id"="1","Arn"="{discover-accounts-lambda-arn}"
```

### Configuration Parameters

**Management Stack Parameters**:
- `ScannerRoleName`: Name of cross-account role (default: HRI-ScannerRole)
- `ScanRegions`: Comma-separated list of regions to scan
- `ScheduleExpression`: EventBridge cron expression for scheduled scans
- `NotificationEmail`: Email address for SNS error notifications
- `LogRetentionDays`: CloudWatch Logs retention period (default: 30)

**Member Stack Parameters**:
- `ManagementAccountId`: AWS account ID of management account
- `ExternalId`: Unique external ID for role assumption security

### Post-Deployment Verification

1. **Verify Lambda Functions**: Check Lambda console for 3 functions
2. **Verify DynamoDB Table**: Check table exists with correct schema
3. **Verify S3 Bucket**: Check bucket exists with encryption enabled
4. **Verify IAM Roles**: Check management and member account roles
5. **Test Manual Invocation**: Invoke discover_accounts Lambda manually
6. **Verify Findings**: Check DynamoDB for findings after test scan
7. **Verify Reports**: Check S3 for generated reports

## Operational Considerations

### Monitoring and Observability

**CloudWatch Metrics**:
- `AccountsDiscovered`: Count of accounts discovered per execution
- `AccountsScanned`: Count of accounts successfully scanned
- `AccountsFailed`: Count of accounts that failed to scan
- `FindingsDetected`: Count of HRIs detected per execution
- `ScanDuration`: Duration of scan execution in seconds
- `APIThrottles`: Count of API throttling events
- `LambdaErrors`: Count of Lambda execution errors

**CloudWatch Dashboards**:
- **Overview Dashboard**: Accounts scanned, findings by pillar, error rate
- **Performance Dashboard**: Execution duration, API call latency, throttle rate
- **Cost Dashboard**: Lambda invocations, DynamoDB usage, S3 storage

**CloudWatch Alarms**:
- `HighErrorRate`: Alert when error rate > 10%
- `ScanDurationExceeded`: Alert when scan duration > 30 minutes
- `NoRecentScans`: Alert when no scans in last 48 hours
- `HighThrottleRate`: Alert when throttle rate > 5%

### Cost Model

**Monthly Cost Breakdown** (assuming 50 accounts, daily scans):

| Service | Usage | Cost |
|---------|-------|------|
| Lambda (discover_accounts) | 30 invocations × 2 min × 256 MB | $0.01 |
| Lambda (scan_account) | 1,500 invocations × 5 min × 1024 MB | $2.50 |
| Lambda (partner_sync) | 4 invocations × 2 min × 512 MB | $0.01 |
| DynamoDB | 1,500 writes + 100 reads | $0.50 |
| S3 | 100 MB storage + 1,500 PUT requests | $0.10 |
| CloudWatch Logs | 1 GB logs | $0.50 |
| **Total** | | **$3.62** |

**Cost Optimization Strategies**:
- Use Lambda ARM architecture (Graviton2) for 20% cost reduction
- Implement aggressive log filtering to reduce CloudWatch costs
- Use S3 Intelligent-Tiering for automatic cost optimization
- Batch DynamoDB writes to reduce write units
- Cache API responses to reduce Lambda execution time

### Scaling Considerations

**Current Limits**:
- Lambda concurrent executions: 1000 (default account limit)
- DynamoDB on-demand throughput: Unlimited (with throttling protection)
- S3 request rate: 3,500 PUT/s per prefix
- Organizations API: 20 TPS (ListAccounts)

**Scaling Strategies for 100+ Accounts**:
1. **Parallel Processing**: Invoke scan_account Lambda in parallel with concurrency limit
2. **Batching**: Process accounts in batches of 50 to avoid Lambda timeout
3. **Step Functions**: Use Step Functions for orchestration if > 100 accounts
4. **Regional Distribution**: Deploy scanner in multiple regions for geographic distribution
5. **API Throttling Protection**: Implement token bucket algorithm for API rate limiting

**Scaling Thresholds**:
- < 50 accounts: Simple Lambda invocation (current design)
- 50-100 accounts: Parallel processing with batching
- 100-500 accounts: Step Functions orchestration
- > 500 accounts: Multi-region deployment with sharding

### Security Considerations

**Data Protection**:
- All data at rest encrypted (DynamoDB, S3)
- All data in transit encrypted (TLS 1.2+)
- No sensitive data in CloudWatch Logs
- S3 bucket policies restrict access to management account only

**Access Control**:
- Least-privilege IAM roles for all components
- Cross-account roles with external ID for additional security
- No long-term credentials stored
- All API calls use temporary STS credentials

**Compliance**:
- CloudTrail logging enabled for all API calls
- VPC Flow Logs for network traffic analysis
- AWS Config for resource configuration tracking
- Regular security audits using Security Hub

### Maintenance and Updates

**Regular Maintenance Tasks**:
- Review and update HRI check logic quarterly
- Update Lambda runtime versions annually
- Review and optimize DynamoDB schema semi-annually
- Clean up old S3 reports (automated via lifecycle policy)
- Review and update IAM permissions quarterly

**Update Procedures**:
1. **Lambda Code Updates**: Deploy new version, test in dev, promote to prod
2. **Schema Changes**: Use DynamoDB schema versioning, support backward compatibility
3. **IAM Permission Updates**: Update member account roles via StackSets
4. **Configuration Changes**: Update environment variables, redeploy Lambdas

## Roadmap

### MVP (Minimum Viable Product)

**Scope**: Core functionality for single-region, < 50 accounts
- Lambda 1: discover_accounts
- Lambda 2: scan_account (all 30 checks)
- Lambda 3: partner_sync
- DynamoDB table with basic schema
- S3 bucket for reports
- Manual invocation only
- Basic error handling and logging

**Timeline**: 2-3 weeks

### Version 1.0 (Production Ready)

**Enhancements**:
- EventBridge scheduled execution
- Multi-region scanning support
- SNS error notifications
- CloudWatch dashboards and alarms
- Comprehensive error handling
- StackSets deployment for member accounts
- Documentation and runbooks

**Timeline**: 4-6 weeks

### Version 2.0 (Enhanced Features)

**Enhancements**:
- Step Functions orchestration for > 100 accounts
- Web UI for viewing findings and reports
- Trend analysis and historical reporting
- Custom check definitions
- Integration with AWS Service Catalog
- Automated remediation workflows
- Cost impact calculations for all findings

**Timeline**: 8-12 weeks

### Future Enhancements

**Potential Features**:
- Machine learning for anomaly detection
- Predictive analytics for future HRIs
- Integration with third-party ITSM tools (ServiceNow, Jira)
- Mobile app for on-the-go monitoring
- Real-time scanning with EventBridge event triggers
- Multi-cloud support (Azure, GCP)
- Compliance framework mapping (SOC 2, HIPAA, PCI-DSS)
