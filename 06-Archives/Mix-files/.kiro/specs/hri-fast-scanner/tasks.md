# Implementation Plan

- [x] 1. Set up project structure and infrastructure foundation



  - Create CDK project structure with management and member account stacks
  - Define DynamoDB table schema with GSIs
  - Define S3 bucket with encryption and lifecycle policies
  - Create IAM roles for Lambda execution in management account
  - Create HRI-ScannerRole template for member accounts
  - _Requirements: 16.1, 16.2, 16.3, 16.4, 16.5, 17.1, 17.2, 17.3_

- [ ]* 1.1 Write property test for DynamoDB key structure
  - **Property 12: DynamoDB Key Structure**



  - **Validates: Requirements 8.2**

- [ ] 2. Implement Lambda 1: discover_accounts
  - Create Lambda function handler with Organizations API integration
  - Implement account discovery with pagination support
  - Filter ACTIVE accounts and exclude SUSPENDED/CLOSED accounts
  - Store account metadata (account_id, account_name, organizational_unit)
  - Implement asynchronous invocation of scan_account Lambda
  - Add exponential backoff retry logic for Organizations API failures (3 attempts)
  - Implement structured logging with execution_id tracking
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 11.2, 14.1_

- [ ]* 2.1 Write property test for account discovery completeness
  - **Property 1: Account Discovery Completeness**
  - **Validates: Requirements 1.1, 1.2**

- [ ]* 2.2 Write property test for account metadata completeness
  - **Property 2: Account Metadata Completeness**
  - **Validates: Requirements 1.3**

- [ ]* 2.3 Write property test for retry logic consistency
  - **Property 3: Retry Logic Consistency**
  - **Validates: Requirements 1.5**




- [ ]* 2.4 Write property test for pagination handling
  - **Property 16: Pagination Handling**
  - **Validates: Requirements 10.2**

- [ ] 3. Implement Lambda 2: scan_account - Core infrastructure
  - Create Lambda function handler with STS AssumeRole logic
  - Implement cross-account role assumption with external ID
  - Handle role assumption failures gracefully (log and continue)
  - Implement credential refresh mechanism
  - Create base scanner framework with error handling
  - Implement multi-region scanning logic
  - Add global service single-query optimization
  - _Requirements: 2.1, 2.2, 2.3, 2.5, 20.1, 20.2, 20.3, 20.5_

- [ ]* 3.1 Write property test for cross-account role assumption
  - **Property 4: Cross-Account Role Assumption**
  - **Validates: Requirements 2.1, 2.2**

- [ ]* 3.2 Write property test for graceful role assumption failure
  - **Property 5: Graceful Role Assumption Failure**
  - **Validates: Requirements 2.3, 2.5**




- [ ]* 3.3 Write property test for multi-region scanning
  - **Property 36: Multi-Region Scanning**
  - **Validates: Requirements 20.1, 20.2, 20.4**

- [ ]* 3.4 Write property test for global service single query
  - **Property 37: Global Service Single Query**
  - **Validates: Requirements 20.3**

- [ ] 4. Implement Security HRI checks (11 checks)
  - Implement check for public S3 buckets using S3 API
  - Implement check for unencrypted EBS volumes using EC2 API
  - Implement check for unencrypted RDS instances using RDS API
  - Implement Security Hub critical findings retrieval
  - Implement root account MFA check using IAM API
  - Implement IAM users without MFA check
  - Implement IAM access keys > 90 days check
  - Implement CloudTrail multi-region verification
  - Implement GuardDuty enabled check
  - Implement S3 Block Public Access account-level check



  - Implement KMS CMK usage check for sensitive workloads
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.10, 3.11_

- [ ]* 4.1 Write property test for security check execution
  - **Property 6: Security Check Execution**
  - **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8, 3.9, 3.10, 3.11**

- [ ]* 4.2 Write property test for Security Hub ARN reference
  - **Property 34: Security Hub ARN Reference**
  - **Validates: Requirements 19.4**




- [ ] 5. Implement Reliability HRI checks (6 checks)
  - Implement AWS Config enabled verification
  - Implement CloudWatch alarms absence check on critical resources
  - Implement backup solutions verification for critical resources
  - Implement single-AZ RDS instances detection
  - Implement VPC Flow Logs enabled verification
  - Implement ASG health checks and scaling policies check



  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

- [ ]* 5.1 Write property test for reliability check execution
  - **Property 7: Reliability Check Execution**
  - **Validates: Requirements 4.1, 4.2, 4.3, 4.4, 4.5, 4.6**

- [ ] 6. Implement Performance HRI checks (4 checks)
  - Implement idle EC2 instances detection using CloudWatch metrics
  - Implement over-provisioned EC2 detection using Compute Optimizer
  - Implement Lambda high timeout/error rate detection
  - Implement legacy instance families detection (t2, m3, c3)
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [x]* 6.1 Write property test for performance check execution



  - **Property 8: Performance Check Execution**
  - **Validates: Requirements 5.1, 5.2, 5.3, 5.4**

- [ ] 7. Implement Cost Optimization HRI checks (6 checks)
  - Implement idle EC2 instances detection with low CPU utilization
  - Implement gp2 to gp3 migration opportunity detection
  - Implement Savings Plan coverage percentage calculation



  - Implement RDS Reserved Instance coverage percentage calculation
  - Implement unattached EBS volumes detection
  - Implement idle ALB/ELB/EIP detection
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

- [ ]* 7.1 Write property test for cost optimization check execution
  - **Property 9: Cost Optimization Check Execution**
  - **Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.5, 6.6**

- [ ]* 7.2 Write property test for cost impact inclusion
  - **Property 35: Cost Impact Inclusion**
  - **Validates: Requirements 19.5**

- [ ] 8. Implement Sustainability HRI checks (3 checks)
  - Implement old-generation instance families detection
  - Implement non-gp3/non-Elastic Volume detection
  - Implement outdated RDS instance classes detection
  - _Requirements: 7.1, 7.2, 7.3_

- [ ]* 8.1 Write property test for sustainability check execution
  - **Property 10: Sustainability Check Execution**
  - **Validates: Requirements 7.1, 7.2, 7.3**

- [ ] 9. Implement findings storage and reporting
  - Implement DynamoDB write logic with composite key (account_id + check_id)
  - Implement finding record creation with all required fields
  - Implement finding update logic for existing records (idempotent)



  - Add HRI boolean flag to findings
  - Add evidence field with resource ARN or identifier
  - Add region and resource_tags to finding metadata
  - Implement exponential backoff for DynamoDB throttling
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 18.4, 19.1, 19.2, 19.3_

- [ ]* 9.1 Write property test for finding record structure
  - **Property 11: Finding Record Structure**
  - **Validates: Requirements 8.1, 8.3, 8.4**

- [ ]* 9.2 Write property test for finding update idempotency
  - **Property 13: Finding Update Idempotency**
  - **Validates: Requirements 8.5**

- [ ]* 9.3 Write property test for evidence field completeness
  - **Property 32: Evidence Field Completeness**
  - **Validates: Requirements 19.1**

- [ ]* 9.4 Write property test for finding metadata completeness
  - **Property 33: Finding Metadata Completeness**
  - **Validates: Requirements 19.2, 19.3**

- [ ]* 9.5 Write property test for DynamoDB throttle handling
  - **Property 30: DynamoDB Throttle Handling**
  - **Validates: Requirements 18.4**

- [ ] 10. Implement S3 report generation and export
  - Implement account-specific JSON report generation
  - Implement aggregated report generation with grouping by pillar and account
  - Add summary statistics calculation (total HRIs per pillar)
  - Implement S3 upload with server-side encryption
  - Add timestamp-based naming for reports
  - Implement S3 retry logic with jitter for throttling
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 18.5_

- [ ]* 10.1 Write property test for report grouping correctness
  - **Property 14: Report Grouping Correctness**
  - **Validates: Requirements 9.2, 9.3**

- [ ]* 10.2 Write property test for S3 upload encryption
  - **Property 15: S3 Upload Encryption**
  - **Validates: Requirements 9.5**

- [ ]* 10.3 Write property test for S3 retry logic
  - **Property 31: S3 Retry Logic**
  - **Validates: Requirements 18.5**

- [ ] 11. Implement error handling and logging
  - Implement structured logging with execution_id, account_id, component
  - Add log levels (DEBUG, INFO, WARNING, ERROR, CRITICAL)
  - Implement API call failure logging with service, operation, error details
  - Implement exception stack trace capture
  - Add throttle event logging with retry attempt tracking
  - Implement SNS error notifications for critical errors
  - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5_

- [ ]* 11.1 Write property test for comprehensive logging
  - **Property 26: Comprehensive Logging**
  - **Validates: Requirements 14.1, 14.2, 14.3**

- [ ]* 11.2 Write property test for throttle event logging
  - **Property 27: Throttle Event Logging**
  - **Validates: Requirements 14.5**

- [ ]* 11.3 Write property test for error notification
  - **Property 20: Error Notification**
  - **Validates: Requirements 11.4, 14.4**

- [ ] 12. Implement performance optimizations
  - Implement API call caching to minimize redundant calls
  - Implement parallel check execution grouped by service
  - Add batch processing for accounts exceeding 50
  - Implement concurrency limits for parallel processing
  - Add exponential backoff with jitter for API rate limits
  - _Requirements: 10.4, 10.5, 15.4, 15.5, 18.1, 18.2_

- [ ]* 12.1 Write property test for API call caching
  - **Property 28: API Call Caching**
  - **Validates: Requirements 15.4**

- [ ]* 12.2 Write property test for batch processing
  - **Property 18: Batch Processing**
  - **Validates: Requirements 10.5**

- [ ]* 12.3 Write property test for exponential backoff with jitter
  - **Property 17: Exponential Backoff with Jitter**
  - **Validates: Requirements 10.4**

- [ ]* 12.4 Write property test for parallel processing concurrency limits
  - **Property 29: Parallel Processing Concurrency Limits**
  - **Validates: Requirements 18.1, 18.2**

- [ ] 13. Checkpoint - Ensure all tests pass for App 1 (HRI Fast Scanner)
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 14. Implement Lambda 3: partner_sync
  - Create Lambda function handler for Partner Central sync
  - Implement DynamoDB scan with pagination to read all findings
  - Implement transformation logic to Partner Central format
  - Map HRI pillars to Partner Central categories
  - Map check names to Partner Central field names
  - Generate unique identifiers for each finding (account_id#pillar#check_name)
  - Implement idempotent update logic for existing findings
  - _Requirements: 12.1, 12.2, 12.3, 12.4, 13.1, 13.2_

- [ ]* 14.1 Write property test for partner sync data completeness
  - **Property 21: Partner Sync Data Completeness**
  - **Validates: Requirements 12.1**

- [ ]* 14.2 Write property test for Partner Central format transformation
  - **Property 22: Partner Central Format Transformation**
  - **Validates: Requirements 12.2, 12.3, 12.4**

- [ ]* 14.3 Write property test for partner sync unique identifiers
  - **Property 23: Partner Sync Unique Identifiers**
  - **Validates: Requirements 13.1**

- [ ]* 14.4 Write property test for partner sync idempotency
  - **Property 24: Partner Sync Idempotency**
  - **Validates: Requirements 13.2**

- [ ] 15. Implement partner sync S3 export and state management
  - Implement Partner Central JSON file generation
  - Implement S3 upload to partner-central/ prefix with timestamp
  - Record sync timestamp in DynamoDB for tracking
  - Implement error logging to CloudWatch for sync failures
  - Implement resume logic from last successful state
  - _Requirements: 12.5, 13.3, 13.4, 13.5_

- [ ]* 15.1 Write property test for sync timestamp recording
  - **Property 25: Sync Timestamp Recording**
  - **Validates: Requirements 13.3**

- [ ] 16. Implement EventBridge scheduling and triggers
  - Create EventBridge scheduled rule for daily/weekly execution
  - Configure EventBridge to trigger discover_accounts Lambda
  - Implement execution summary logging to CloudWatch
  - Add support for manual Lambda invocation
  - _Requirements: 11.1, 11.2, 11.3, 11.5_

- [ ]* 16.1 Write property test for EventBridge trigger handling
  - **Property 19: EventBridge Trigger Handling**
  - **Validates: Requirements 11.2, 11.3**

- [ ] 17. Implement region filtering and configuration
  - Add region list configuration via environment variables
  - Implement region filtering logic for excluded regions
  - Ensure region identifier is included in regional findings
  - _Requirements: 20.4, 20.5_

- [ ]* 17.1 Write property test for region filtering
  - **Property 38: Region Filtering**
  - **Validates: Requirements 20.5**

- [ ] 18. Create deployment automation
  - Create CDK constructs for Lambda functions
  - Create CDK construct for DynamoDB table with GSIs
  - Create CDK construct for S3 bucket with encryption and lifecycle
  - Create management account stack with all resources
  - Create member account stack with HRI-ScannerRole
  - Add CloudFormation StackSets support for member account deployment
  - Configure environment variables and parameters
  - Add deployment output for role ARNs and resource names
  - _Requirements: 17.1, 17.2, 17.3, 17.4, 17.5_

- [ ] 19. Create monitoring and observability
  - Implement CloudWatch custom metrics (AccountsDiscovered, AccountsScanned, AccountsFailed, FindingsDetected, ScanDuration, APIThrottles, LambdaErrors)
  - Create CloudWatch dashboard for overview (accounts, findings, errors)
  - Create CloudWatch dashboard for performance (duration, latency, throttles)
  - Create CloudWatch dashboard for cost (invocations, DynamoDB, S3)
  - Create CloudWatch alarms (HighErrorRate, ScanDurationExceeded, NoRecentScans, HighThrottleRate)
  - _Requirements: 14.1, 14.3_

- [ ] 20. Create deployment documentation
  - Write deployment guide with step-by-step instructions
  - Document configuration parameters for management and member stacks
  - Create post-deployment verification checklist
  - Document EventBridge schedule configuration
  - Write operational runbook for common tasks
  - _Requirements: 17.4_

- [ ]* 21. Write integration tests
  - Test end-to-end account discovery and scanning workflow
  - Test multi-account scanning with 10+ accounts
  - Test scan with missing IAM role in one account
  - Test Partner Sync with real DynamoDB data
  - Test API throttling scenarios

- [ ] 22. Final Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
