# Requirements Document

## Introduction

This document specifies requirements for a lightweight multi-account AWS Well-Architected High-Risk Issue (HRI) detection and reporting system. The system consists of two applications: (1) HRI Fast Scanner - a minimal HRI detection engine that scans AWS Organization accounts for ~30 critical issues across 6 Well-Architected pillars, and (2) Partner Sync Micro-App - a lightweight integration that exports findings to AWS Partner Central. The system must operate cost-effectively (< $5/month), support 100+ accounts, and avoid full Well-Architected Review complexity.

## Glossary

- **HRI**: High-Risk Issue - a critical finding in AWS Well-Architected Framework assessment
- **WAR**: Well-Architected Review - comprehensive AWS architecture assessment
- **Management Account**: AWS Organizations payer account with cross-account access
- **Member Account**: Individual AWS account within an Organization
- **HRI-ScannerRole**: Cross-account IAM role assumed for scanning member accounts
- **Partner Central**: AWS Partner Central platform for partner business management
- **Security Hub**: AWS service aggregating security findings
- **AWS Config**: AWS service tracking resource configuration compliance
- **Trusted Advisor**: AWS service providing best practice recommendations
- **Cost Explorer**: AWS service for cost analysis and optimization
- **Compute Optimizer**: AWS service for resource rightsizing recommendations

## Requirements

### Requirement 1

**User Story:** As a cloud architect, I want to discover all member accounts in my AWS Organization, so that I can scan every account for high-risk issues without manual configuration.

#### Acceptance Criteria

1. WHEN the discovery function executes, THE HRI Fast Scanner SHALL retrieve all active member accounts from AWS Organizations API
2. WHEN member accounts are retrieved, THE HRI Fast Scanner SHALL filter out suspended or closed accounts
3. WHEN the account list is compiled, THE HRI Fast Scanner SHALL store account metadata including account ID, account name, and organizational unit
4. WHEN discovery completes, THE HRI Fast Scanner SHALL return a list of scannable accounts for processing
5. WHEN Organizations API calls fail, THE HRI Fast Scanner SHALL retry with exponential backoff up to 3 attempts

### Requirement 2

**User Story:** As a cloud architect, I want to assume a cross-account role in each member account, so that the scanner can access resources without storing credentials.

#### Acceptance Criteria

1. WHEN scanning a member account, THE HRI Fast Scanner SHALL assume the HRI-ScannerRole using AWS STS
2. WHEN role assumption succeeds, THE HRI Fast Scanner SHALL use temporary credentials for all subsequent API calls
3. WHEN role assumption fails, THE HRI Fast Scanner SHALL log the failure and continue to the next account
4. WHEN temporary credentials expire, THE HRI Fast Scanner SHALL refresh credentials automatically
5. WHERE the HRI-ScannerRole does not exist in a member account, THE HRI Fast Scanner SHALL record the account as unscannable

### Requirement 3

**User Story:** As a security engineer, I want to detect 11 critical security HRIs, so that I can identify and remediate security vulnerabilities across all accounts.

#### Acceptance Criteria

1. WHEN scanning an account, THE HRI Fast Scanner SHALL check for public S3 buckets using S3 API
2. WHEN scanning an account, THE HRI Fast Scanner SHALL check for unencrypted EBS volumes using EC2 API
3. WHEN scanning an account, THE HRI Fast Scanner SHALL check for unencrypted RDS instances using RDS API
4. WHEN scanning an account, THE HRI Fast Scanner SHALL retrieve critical findings from Security Hub
5. WHEN scanning an account, THE HRI Fast Scanner SHALL check if root account has MFA enabled using IAM API
6. WHEN scanning an account, THE HRI Fast Scanner SHALL identify IAM users without MFA enabled
7. WHEN scanning an account, THE HRI Fast Scanner SHALL identify IAM access keys older than 90 days
8. WHEN scanning an account, THE HRI Fast Scanner SHALL verify CloudTrail is enabled and configured for multi-region
9. WHEN scanning an account, THE HRI Fast Scanner SHALL verify GuardDuty is enabled
10. WHEN scanning an account, THE HRI Fast Scanner SHALL check if S3 Block Public Access is disabled at account level
11. WHEN scanning an account, THE HRI Fast Scanner SHALL identify sensitive workloads without KMS CMK encryption

### Requirement 4

**User Story:** As a reliability engineer, I want to detect 6 critical reliability HRIs, so that I can improve system resilience and availability.

#### Acceptance Criteria

1. WHEN scanning an account, THE HRI Fast Scanner SHALL verify AWS Config is enabled
2. WHEN scanning an account, THE HRI Fast Scanner SHALL check for absence of CloudWatch alarms on critical resources
3. WHEN scanning an account, THE HRI Fast Scanner SHALL verify backup solutions are enabled for critical resources
4. WHEN scanning an account, THE HRI Fast Scanner SHALL identify single-AZ RDS instances
5. WHEN scanning an account, THE HRI Fast Scanner SHALL verify VPC Flow Logs are enabled
6. WHEN scanning an account, THE HRI Fast Scanner SHALL identify Auto Scaling Groups without health checks or scaling policies

### Requirement 5

**User Story:** As a performance engineer, I want to detect 4 critical performance HRIs, so that I can optimize application performance and resource utilization.

#### Acceptance Criteria

1. WHEN scanning an account, THE HRI Fast Scanner SHALL identify idle EC2 instances using CloudWatch metrics
2. WHEN scanning an account, THE HRI Fast Scanner SHALL identify over-provisioned EC2 instances using Compute Optimizer
3. WHEN scanning an account, THE HRI Fast Scanner SHALL identify Lambda functions with high timeout rates or error rates
4. WHEN scanning an account, THE HRI Fast Scanner SHALL identify legacy instance families including t2, m3, and c3 types

### Requirement 6

**User Story:** As a cost optimization engineer, I want to detect 6 critical cost optimization HRIs, so that I can reduce unnecessary cloud spending.

#### Acceptance Criteria

1. WHEN scanning an account, THE HRI Fast Scanner SHALL identify idle EC2 instances with low CPU utilization
2. WHEN scanning an account, THE HRI Fast Scanner SHALL identify gp2 volumes that should be migrated to gp3
3. WHEN scanning an account, THE HRI Fast Scanner SHALL calculate Savings Plan coverage percentage
4. WHEN scanning an account, THE HRI Fast Scanner SHALL calculate RDS Reserved Instance coverage percentage
5. WHEN scanning an account, THE HRI Fast Scanner SHALL identify unattached EBS volumes
6. WHEN scanning an account, THE HRI Fast Scanner SHALL identify idle Application Load Balancers, Elastic Load Balancers, and Elastic IPs

### Requirement 7

**User Story:** As a sustainability engineer, I want to detect 3 critical sustainability HRIs, so that I can reduce environmental impact of cloud infrastructure.

#### Acceptance Criteria

1. WHEN scanning an account, THE HRI Fast Scanner SHALL identify old-generation instance families
2. WHEN scanning an account, THE HRI Fast Scanner SHALL identify EBS volumes not using gp3 or Elastic Volume types
3. WHEN scanning an account, THE HRI Fast Scanner SHALL identify outdated RDS instance classes

### Requirement 8

**User Story:** As a cloud architect, I want all HRI findings stored in DynamoDB, so that I can query, analyze, and track findings over time.

#### Acceptance Criteria

1. WHEN an HRI is detected, THE HRI Fast Scanner SHALL create a finding record with account ID, pillar, check name, evidence, and timestamp
2. WHEN storing findings, THE HRI Fast Scanner SHALL use a composite key of account ID and check name
3. WHEN storing findings, THE HRI Fast Scanner SHALL include an HRI boolean flag indicating severity
4. WHEN storing findings, THE HRI Fast Scanner SHALL include evidence field with resource ARN or identifier
5. WHEN a finding already exists, THE HRI Fast Scanner SHALL update the timestamp and evidence fields

### Requirement 9

**User Story:** As a cloud architect, I want aggregated HRI reports exported to S3, so that I can share findings with stakeholders and maintain audit trails.

#### Acceptance Criteria

1. WHEN all accounts are scanned, THE HRI Fast Scanner SHALL generate an aggregated JSON report
2. WHEN generating reports, THE HRI Fast Scanner SHALL group findings by pillar and account
3. WHEN generating reports, THE HRI Fast Scanner SHALL include summary statistics for total HRIs per pillar
4. WHEN reports are generated, THE HRI Fast Scanner SHALL upload them to S3 with timestamp-based naming
5. WHEN uploading to S3, THE HRI Fast Scanner SHALL enable server-side encryption

### Requirement 10

**User Story:** As a cloud architect, I want the scanner to execute within Lambda timeout limits, so that scanning completes successfully for all accounts.

#### Acceptance Criteria

1. WHEN scanning a single account, THE HRI Fast Scanner SHALL complete all 30 checks within 5 minutes
2. WHEN processing multiple accounts, THE HRI Fast Scanner SHALL implement pagination for large account lists
3. WHEN Lambda execution time approaches timeout, THE HRI Fast Scanner SHALL save progress and trigger continuation
4. WHEN API rate limits are encountered, THE HRI Fast Scanner SHALL implement exponential backoff with jitter
5. WHERE account count exceeds 50, THE HRI Fast Scanner SHALL process accounts in batches

### Requirement 11

**User Story:** As a cloud architect, I want the system to run on a schedule, so that HRI detection happens automatically without manual intervention.

#### Acceptance Criteria

1. WHEN scheduled execution is configured, THE HRI Fast Scanner SHALL trigger via EventBridge on daily or weekly schedule
2. WHEN EventBridge triggers execution, THE HRI Fast Scanner SHALL initiate account discovery
3. WHEN scheduled execution completes, THE HRI Fast Scanner SHALL log execution summary to CloudWatch
4. WHEN scheduled execution fails, THE HRI Fast Scanner SHALL send notification via SNS
5. WHERE manual execution is needed, THE HRI Fast Scanner SHALL support direct Lambda invocation

### Requirement 12

**User Story:** As an AWS partner, I want HRI findings automatically synced to AWS Partner Central, so that I can demonstrate value to customers through the partner platform.

#### Acceptance Criteria

1. WHEN partner sync executes, THE Partner Sync Micro-App SHALL read all HRI findings from DynamoDB
2. WHEN findings are retrieved, THE Partner Sync Micro-App SHALL transform findings into Partner Central import format
3. WHEN transformation completes, THE Partner Sync Micro-App SHALL map HRI pillars to Partner Central categories
4. WHEN transformation completes, THE Partner Sync Micro-App SHALL map check names to Partner Central field names
5. WHEN Partner Central payload is ready, THE Partner Sync Micro-App SHALL write the formatted file to S3

### Requirement 13

**User Story:** As an AWS partner, I want Partner Central sync to be idempotent, so that repeated executions do not create duplicate findings.

#### Acceptance Criteria

1. WHEN syncing findings, THE Partner Sync Micro-App SHALL use unique identifiers for each finding
2. WHEN a finding already exists in Partner Central, THE Partner Sync Micro-App SHALL update the existing record
3. WHEN sync completes, THE Partner Sync Micro-App SHALL record sync timestamp in DynamoDB
4. WHEN sync fails, THE Partner Sync Micro-App SHALL log error details to CloudWatch
5. WHEN sync is retried, THE Partner Sync Micro-App SHALL resume from last successful state

### Requirement 14

**User Story:** As a cloud architect, I want comprehensive error handling and logging, so that I can troubleshoot issues and monitor system health.

#### Acceptance Criteria

1. WHEN any Lambda function executes, THE system SHALL log execution start and completion to CloudWatch
2. WHEN API calls fail, THE system SHALL log error details including service, operation, and error message
3. WHEN exceptions occur, THE system SHALL capture stack traces in CloudWatch Logs
4. WHEN critical errors occur, THE system SHALL publish error notifications to SNS topic
5. WHEN throttling occurs, THE system SHALL log throttle events and retry attempts

### Requirement 15

**User Story:** As a cloud architect, I want the system to operate cost-effectively, so that scanning costs remain under $5 per month.

#### Acceptance Criteria

1. WHEN Lambda functions execute, THE system SHALL use minimum memory allocation sufficient for performance
2. WHEN storing data in DynamoDB, THE system SHALL use on-demand billing mode
3. WHEN storing reports in S3, THE system SHALL use S3 Standard-IA storage class for archived reports
4. WHEN making API calls, THE system SHALL minimize redundant calls through caching
5. WHEN processing accounts, THE system SHALL batch operations to reduce Lambda invocations

### Requirement 16

**User Story:** As a cloud architect, I want cross-account IAM roles properly configured, so that the scanner has necessary permissions without over-privileging.

#### Acceptance Criteria

1. WHEN deploying to management account, THE system SHALL create an execution role with Organizations read permissions
2. WHEN deploying to member accounts, THE system SHALL create HRI-ScannerRole with read-only permissions for all scanned services
3. WHEN HRI-ScannerRole is created, THE system SHALL restrict trust policy to management account principal
4. WHEN HRI-ScannerRole is created, THE system SHALL include permissions for S3, EC2, RDS, IAM, Security Hub, Config, CloudWatch, GuardDuty, and Cost Explorer
5. WHEN HRI-ScannerRole is created, THE system SHALL use least-privilege principle with explicit deny for write operations

### Requirement 17

**User Story:** As a cloud architect, I want deployment automation, so that I can deploy the system quickly across management and member accounts.

#### Acceptance Criteria

1. WHEN deploying the system, THE deployment tool SHALL support AWS CDK or SAM templates
2. WHEN deploying to management account, THE deployment tool SHALL create all Lambda functions, DynamoDB table, and S3 bucket
3. WHEN deploying to member accounts, THE deployment tool SHALL create HRI-ScannerRole with proper trust relationships
4. WHEN deployment completes, THE deployment tool SHALL output configuration values including role ARNs and resource names
5. WHERE StackSets are available, THE deployment tool SHALL support automated member account deployment

### Requirement 18

**User Story:** As a cloud architect, I want the system to scale to 100+ accounts, so that it supports large enterprise organizations.

#### Acceptance Criteria

1. WHEN processing more than 50 accounts, THE system SHALL implement parallel processing with concurrency limits
2. WHEN parallel processing is active, THE system SHALL limit concurrent executions to avoid API throttling
3. WHEN account count exceeds Lambda timeout capacity, THE system SHALL implement continuation pattern
4. WHEN DynamoDB throughput is insufficient, THE system SHALL handle throttling with exponential backoff
5. WHEN S3 operations are throttled, THE system SHALL implement retry logic with jitter

### Requirement 19

**User Story:** As a cloud architect, I want findings to include sufficient evidence, so that I can validate and remediate issues efficiently.

#### Acceptance Criteria

1. WHEN an HRI is detected, THE system SHALL include resource ARN or identifier in evidence field
2. WHEN an HRI is detected, THE system SHALL include resource region in finding metadata
3. WHEN an HRI is detected, THE system SHALL include resource tags if available
4. WHEN Security Hub findings are included, THE system SHALL reference Security Hub finding ARN
5. WHEN cost-related HRIs are detected, THE system SHALL include estimated monthly cost impact

### Requirement 20

**User Story:** As a cloud architect, I want the system to support multiple AWS regions, so that findings cover all deployed resources.

#### Acceptance Criteria

1. WHEN scanning an account, THE system SHALL query resources in all enabled regions
2. WHEN regional services are scanned, THE system SHALL iterate through configured region list
3. WHEN global services are scanned, THE system SHALL query only once per account
4. WHEN region-specific findings are stored, THE system SHALL include region identifier
5. WHERE certain regions are excluded, THE system SHALL support region filtering configuration
