# WAFOps

A lightweight multi-account AWS Well-Architected High-Risk Issue (HRI) detection and reporting system.

## Overview

WAFOps consists of two applications:

1. **WAFOps Scanner (App 1)**: Discovers AWS Organization accounts and executes 30 HRI checks across 6 Well-Architected pillars
2. **Partner Sync Micro-App (App 2)**: Transforms findings into AWS Partner Central format

## Features

- ✅ **Multi-Account Scanning**: Automatically discovers and scans all AWS Organization member accounts
- ✅ **30 HRI Checks**: Covers Security, Reliability, Performance, Cost, Sustainability, and Operational Excellence
- ✅ **Cost-Effective**: Designed to operate under $5/month
- ✅ **Scalable**: Supports 100+ accounts
- ✅ **Serverless**: Built on Lambda, DynamoDB, and S3

## Architecture

```
Management Account (750299845580)
├── Lambda 1: discover_accounts (✅ Implemented)
├── Lambda 2: scan_account (⏳ Pending)
├── Lambda 3: partner_sync (⏳ Pending)
├── DynamoDB: hri_findings
└── S3: hri-exports-750299845580-us-east-1

Member Accounts
└── IAM Role: HRI-ScannerRole (read-only)
```

## Project Structure

```
hri-scanner/
├── lambda/
│   ├── discover_accounts.py      # ✅ Lambda 1 - Account discovery
│   ├── scan_account.py            # ⏳ Lambda 2 - HRI scanning
│   ├── partner_sync.py            # ⏳ Lambda 3 - Partner Central sync
│   └── requirements.txt
├── tests/
│   ├── test_discover_accounts.py  # ✅ Unit tests
│   ├── test_live_account.py       # ✅ Live testing
│   └── check_aws_credentials.py   # ✅ Credential checker
├── deploy.py                      # ✅ Deployment automation
├── DEPLOYMENT.md                  # ✅ Deployment guide
└── README.md                      # This file
```

## Quick Start

### Prerequisites

- AWS Account: 750299845580 (Management account with Organizations)
- Python 3.12+
- AWS CLI configured
- Valid AWS credentials

### Installation

1. **Clone or navigate to the project**:
   ```bash
   cd hri-scanner
   ```

2. **Install dependencies**:
   ```bash
   pip install -r lambda/requirements.txt
   ```

3. **Check AWS credentials**:
   ```bash
   python tests/check_aws_credentials.py
   ```

4. **Deploy infrastructure**:
   ```bash
   python deploy.py
   ```

### Testing

#### Unit Tests
```bash
python tests/test_discover_accounts.py -v
```

#### Live Account Test
```bash
python tests/test_live_account.py
```

## Implementation Status

### Completed ✅
- [x] Task 1: Project structure and infrastructure foundation
- [x] Task 2: Lambda 1 (discover_accounts) implementation
- [x] Unit tests for Lambda 1
- [x] Deployment scripts and documentation

### In Progress ⏳
- [ ] Task 3: Lambda 2 (scan_account) - Core infrastructure
- [ ] Task 4: Security HRI checks (11 checks)
- [ ] Task 5: Reliability HRI checks (6 checks)
- [ ] Task 6: Performance HRI checks (4 checks)
- [ ] Task 7: Cost Optimization HRI checks (6 checks)
- [ ] Task 8: Sustainability HRI checks (3 checks)
- [ ] Task 9: Findings storage and reporting
- [ ] Task 10: S3 report generation
- [ ] Task 11: Error handling and logging
- [ ] Task 12: Performance optimizations
- [ ] Task 13: Checkpoint - All tests pass
- [ ] Task 14: Lambda 3 (partner_sync)
- [ ] Task 15: Partner sync S3 export
- [ ] Task 16: EventBridge scheduling
- [ ] Task 17: Region filtering
- [ ] Task 18: Deployment automation (CDK)
- [ ] Task 19: Monitoring and observability
- [ ] Task 20: Documentation

## HRI Checks

### Security (11 checks)
- Public S3 buckets
- Unencrypted EBS volumes
- Unencrypted RDS instances
- Security Hub critical findings
- Root account MFA
- IAM users without MFA
- IAM access keys > 90 days
- CloudTrail multi-region
- GuardDuty enabled
- S3 Block Public Access
- KMS CMK usage

### Reliability (6 checks)
- AWS Config enabled
- CloudWatch alarms on critical resources
- Backup solutions enabled
- Single-AZ RDS instances
- VPC Flow Logs enabled
- ASG health checks and scaling policies

### Performance (4 checks)
- Idle EC2 instances
- Over-provisioned EC2 instances
- Lambda high timeout/error rates
- Legacy instance families (t2, m3, c3)

### Cost Optimization (6 checks)
- Idle EC2 instances (low CPU)
- gp2 to gp3 migration opportunities
- Savings Plan coverage
- RDS Reserved Instance coverage
- Unattached EBS volumes
- Idle ALB/ELB/EIP

### Sustainability (3 checks)
- Old-generation instance families
- Non-gp3/non-Elastic volumes
- Outdated RDS instance classes

## Deployment

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed deployment instructions.

### Quick Deploy

```bash
# 1. Check credentials
python tests/check_aws_credentials.py

# 2. Deploy infrastructure
python deploy.py

# 3. Deploy Lambda functions (manual for now)
# See DEPLOYMENT.md for Lambda deployment steps
```

## Testing Against Account 750299845580

Once your AWS credentials are refreshed:

```bash
# Test account discovery
python tests/test_live_account.py

# Expected output:
# ✓ Successfully discovered X accounts
# ✓ Found Y active accounts
# ✓ All tests passed successfully!
```

## Documentation

- [Deployment Guide](DEPLOYMENT.md) - Step-by-step deployment instructions
- [Requirements](.kiro/specs/hri-fast-scanner/requirements.md) - Detailed requirements
- [Design Document](.kiro/specs/hri-fast-scanner/design.md) - Architecture and design
- [Task List](.kiro/specs/hri-fast-scanner/tasks.md) - Implementation plan

## Next Steps

1. **Refresh AWS credentials** (if expired):
   ```bash
   aws sso login
   ```

2. **Test Lambda 1** against your account:
   ```bash
   python tests/test_live_account.py
   ```

3. **Implement Lambda 2** (scan_account):
   - Start Task 3 from the task list
   - Implement cross-account role assumption
   - Add HRI check framework

4. **Deploy to AWS**:
   - Create IAM roles
   - Deploy Lambda functions
   - Set up EventBridge schedule

## Support

For issues or questions:
1. Check the [DEPLOYMENT.md](DEPLOYMENT.md) troubleshooting section
2. Review the spec documents in `.kiro/specs/hri-fast-scanner/`
3. Run credential checker: `python tests/check_aws_credentials.py`

## License

Internal use only - AIM Consulting
