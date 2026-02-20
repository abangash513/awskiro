# Enhanced EC2 and AMI Analysis Summary

**Analysis Date:** 2025-12-16 18:18:36
**Account ID:** 163799539090
**Total Instances:** 25

## AMI Categories

- **Unknown:** 21 instances
- **Debian:** 3 instances
- **Amazon Linux:** 1 instances

## Security Risk Assessment

- **Unknown Risk:** 21 instances
- **High Risk:** 4 instances

## Compliance Status

- **Unknown:** 21 instances
- **Non-Compliant: Deprecated AMI:** 4 instances

## AMI Age Analysis

- **Average AMI Age:** 34 days
- **Oldest AMI:** 369 days
- **Newest AMI:** 0 days

## Update Recommendations

- **Could not retrieve AMI ID:** 19 instances
- **URGENT: Replace deprecated AMI immediately:** 4 instances
- **AMI not found or deleted:** 2 instances

## High Priority Actions

### High Risk AMIs (Immediate Action Required)
- **nan** (i-09f1105f2a9160482): AMI is 369 days old (>1 year); Public AMI - verify source; AMI is deprecated
- **stage-ods-250612** (i-004ec4119f05ab7a6): AMI is 200 days old (>6 months); Public AMI - verify source; Third-party AMI owner: 136693071363; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **stage-dealdashboard-250612** (i-05d1c2921da1311c3): AMI is 200 days old (>6 months); Public AMI - verify source; Third-party AMI owner: 136693071363; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **stage-pup-250929** (i-0d100a47727b47636): Public AMI - verify source; Third-party AMI owner: 136693071363; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)

### Deprecated AMIs (Replace Immediately)
- **nan** (i-09f1105f2a9160482): al2023-ami-2023.6.20241212.0-kernel-6.1-x86_64
- **stage-ods-250612** (i-004ec4119f05ab7a6): debian-12-amd64-20250530-2128
- **stage-dealdashboard-250612** (i-05d1c2921da1311c3): debian-12-amd64-20250530-2128
- **stage-pup-250929** (i-0d100a47727b47636): debian-12-amd64-20250923-2244
