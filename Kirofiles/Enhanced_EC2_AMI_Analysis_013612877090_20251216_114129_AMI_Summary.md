# Enhanced EC2 and AMI Analysis Summary

**Analysis Date:** 2025-12-16 11:42:02
**Account ID:** 013612877090
**Total Instances:** 47

## AMI Categories

- **Unknown:** 34 instances
- **Ubuntu Linux:** 4 instances
- **Amazon Linux:** 4 instances
- **Debian:** 4 instances
- **Other/Custom:** 1 instances

## Security Risk Assessment

- **Unknown Risk:** 34 instances
- **High Risk:** 13 instances

## Compliance Status

- **Unknown:** 34 instances
- **Non-Compliant: Deprecated AMI:** 13 instances

## AMI Age Analysis

- **Average AMI Age:** 91 days
- **Oldest AMI:** 1477 days
- **Newest AMI:** 0 days

## Update Recommendations

- **Could not retrieve AMI ID:** 32 instances
- **URGENT: Replace deprecated AMI immediately:** 13 instances
- **AMI not found or deleted:** 2 instances

## High Priority Actions

### High Risk AMIs (Immediate Action Required)
- **Jenkins-master01** (i-002071f300a0cd8e2): AMI is 1477 days old (>1 year); Public AMI - verify source; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **strong-analytics-ml** (i-0ef44815c667c08ad): AMI is 600 days old (>1 year); Public AMI - verify source; AMI is deprecated
- **strong-analytics-deep-learning-base** (i-0a1f0faaefc2131f6): AMI is 640 days old (>1 year); Public AMI - verify source; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **GitHub-Actions-Runner** (i-03cd531043a18893e): AMI is 287 days old (>6 months); Public AMI - verify source; AMI is deprecated
- **nan** (i-08045589f7b626db4): AMI is 287 days old (>6 months); Public AMI - verify source; AMI is deprecated
- **dev-dealdashboard-250612** (i-0240c9bbaa797b29f): AMI is 200 days old (>6 months); Public AMI - verify source; Third-party AMI owner: 136693071363; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **dev-ods-250612** (i-068a3474fe3f77083): AMI is 200 days old (>6 months); Public AMI - verify source; Third-party AMI owner: 136693071363; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **dev-ods-itdr-refresh-20251106** (i-01e05ac27ea534446): Public AMI - verify source; Third-party AMI owner: 136693071363; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **port-gha-runner** (i-0b6cddb9bc58975ff): AMI is 189 days old (>6 months); Public AMI - verify source; AMI is deprecated
- **Sonarqube-runner** (i-0b0d236eb331a67e3): Public AMI - verify source; AMI is deprecated
- **dev-pup-250909** (i-00e93682d3972d406): Public AMI - verify source; Third-party AMI owner: 136693071363; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **Sophos** (i-0fcb1d0af2a1c2065): Public AMI - verify source; AMI is deprecated
- **Sophos Data Collector** (i-049811bd83a7af13a): Public AMI - verify source; Third-party AMI owner: 679593333241; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)

### Deprecated AMIs (Replace Immediately)
- **Jenkins-master01** (i-002071f300a0cd8e2): ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20211129
- **strong-analytics-ml** (i-0ef44815c667c08ad): ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20240423
- **strong-analytics-deep-learning-base** (i-0a1f0faaefc2131f6): Deep Learning Base Proprietary Nvidia Driver GPU AMI (Ubuntu 20.04) 20240315
- **GitHub-Actions-Runner** (i-03cd531043a18893e): al2023-ami-2023.6.20250303.0-kernel-6.1-x86_64
- **nan** (i-08045589f7b626db4): al2023-ami-2023.6.20250303.0-kernel-6.1-x86_64
- **dev-dealdashboard-250612** (i-0240c9bbaa797b29f): debian-12-amd64-20250530-2128
- **dev-ods-250612** (i-068a3474fe3f77083): debian-12-amd64-20250530-2128
- **dev-ods-itdr-refresh-20251106** (i-01e05ac27ea534446): debian-12-amd64-20251006-2257
- **port-gha-runner** (i-0b6cddb9bc58975ff): ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-20250610
- **Sonarqube-runner** (i-0b0d236eb331a67e3): al2023-ami-2023.8.20250915.0-kernel-6.1-x86_64
- **dev-pup-250909** (i-00e93682d3972d406): debian-12-amd64-20250814-2204
- **Sophos** (i-0fcb1d0af2a1c2065): al2023-ami-2023.9.20251117.1-kernel-6.1-x86_64
- **Sophos Data Collector** (i-049811bd83a7af13a): NDR-PROD-Appliance-2025-10-07_09.49.36GMT-16580282-44e6-458b-9865-24c48c105d48
