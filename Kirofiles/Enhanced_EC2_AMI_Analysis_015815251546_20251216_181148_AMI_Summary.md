# Enhanced EC2 and AMI Analysis Summary

**Analysis Date:** 2025-12-16 18:12:05
**Account ID:** 015815251546
**Total Instances:** 25

## AMI Categories

- **Unknown:** 18 instances
- **Debian:** 3 instances
- **Amazon Linux:** 2 instances
- **Windows:** 2 instances

## Security Risk Assessment

- **Unknown Risk:** 18 instances
- **High Risk:** 7 instances

## Compliance Status

- **Unknown:** 18 instances
- **Non-Compliant: Deprecated AMI:** 7 instances

## AMI Age Analysis

- **Average AMI Age:** 79 days
- **Oldest AMI:** 767 days
- **Newest AMI:** 0 days

## Update Recommendations

- **Could not retrieve AMI ID:** 18 instances
- **URGENT: Replace deprecated AMI immediately:** 7 instances

## High Priority Actions

### High Risk AMIs (Immediate Action Required)
- **chmigration** (i-0b247eb5fc04944e3): AMI is 767 days old (>1 year); Public AMI - verify source; AMI is deprecated
- **bgreen-dev** (i-04d511a0c8d01d5cd): AMI is 545 days old (>1 year); Public AMI - verify source; Third-party AMI owner: 526746638873; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **prod-ods-250612** (i-0efe0d80326bc975a): AMI is 200 days old (>6 months); Public AMI - verify source; Third-party AMI owner: 136693071363; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **prod-dealdashboard-250612** (i-012fb33e9e562c720): AMI is 200 days old (>6 months); Public AMI - verify source; Third-party AMI owner: 136693071363; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **prod-pup-250929** (i-0cd81e287b076d11f): Public AMI - verify source; Third-party AMI owner: 136693071363; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **prod-muhimbi-node-1** (i-0c311c03040874b2a): Public AMI - verify source; Third-party AMI owner: 801119661308; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **prod-muhimbi-node-0** (i-09e771a492ee7b083): Public AMI - verify source; Third-party AMI owner: 801119661308; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)

### Deprecated AMIs (Replace Immediately)
- **chmigration** (i-0b247eb5fc04944e3): al2023-ami-2023.2.20231113.0-kernel-6.1-x86_64
- **bgreen-dev** (i-04d511a0c8d01d5cd): amzn2-x86_64-MATEDE_DOTNET-2024.06.19
- **prod-ods-250612** (i-0efe0d80326bc975a): debian-12-amd64-20250530-2128
- **prod-dealdashboard-250612** (i-012fb33e9e562c720): debian-12-amd64-20250530-2128
- **prod-pup-250929** (i-0cd81e287b076d11f): debian-12-amd64-20250923-2244
- **prod-muhimbi-node-1** (i-0c311c03040874b2a): Windows_Server-2022-English-Full-SQL_2022_Standard-2025.09.10
- **prod-muhimbi-node-0** (i-09e771a492ee7b083): Windows_Server-2022-English-Full-SQL_2022_Standard-2025.09.10
