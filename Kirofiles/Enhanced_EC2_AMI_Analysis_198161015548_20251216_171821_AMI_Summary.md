# Enhanced EC2 and AMI Analysis Summary

**Analysis Date:** 2025-12-16 17:18:35
**Account ID:** 198161015548
**Total Instances:** 12

## AMI Categories

- **Other/Custom:** 6 instances
- **Ubuntu Linux:** 2 instances
- **Unknown:** 2 instances
- **Amazon Linux:** 2 instances

## Security Risk Assessment

- **High Risk:** 10 instances
- **Unknown Risk:** 2 instances

## Compliance Status

- **Non-Compliant: AMI >1 year old:** 6 instances
- **Non-Compliant: Deprecated AMI:** 4 instances
- **Unknown:** 2 instances

## AMI Age Analysis

- **Average AMI Age:** 1714 days
- **Oldest AMI:** 4209 days
- **Newest AMI:** 0 days

## Update Recommendations

- **HIGH PRIORITY: Update AMI (>1 year old):** 6 instances
- **URGENT: Replace deprecated AMI immediately:** 4 instances
- **AMI not found or deleted:** 2 instances

## High Priority Actions

### High Risk AMIs (Immediate Action Required)
- **puppetmaster.old** (i-a409368e): AMI is 4209 days old (>1 year); Public AMI - verify source; AMI is deprecated; Missing Enhanced Networking (ENA) support; Not using IMDSv2 (Instance Metadata Service v2)
- **ops-search-d** (i-a12f2a8b): AMI is 4209 days old (>1 year); Public AMI - verify source; AMI is deprecated; Missing Enhanced Networking (ENA) support; Not using IMDSv2 (Instance Metadata Service v2)
- **ops-nat** (i-5b08ffb7): AMI is 4074 days old (>1 year); Public AMI - verify source; AMI is deprecated; Missing Enhanced Networking (ENA) support; Not using IMDSv2 (Instance Metadata Service v2)
- **mysql-upgrade** (i-09c5f37643e036865): AMI is 1146 days old (>1 year); Third-party AMI owner: 198161015548; Missing Enhanced Networking (ENA) support; Not using IMDSv2 (Instance Metadata Service v2)
- **staging-database-source** (i-05e80ed206905b62f): AMI is 1146 days old (>1 year); Third-party AMI owner: 198161015548; Missing Enhanced Networking (ENA) support; Not using IMDSv2 (Instance Metadata Service v2)
- **new-bastion** (i-0a4890503b8ec083b): AMI is 972 days old (>1 year); Public AMI - verify source; AMI is deprecated
- **staging-database-replica** (i-02904074725f14fa6): AMI is 1146 days old (>1 year); Third-party AMI owner: 198161015548; Missing Enhanced Networking (ENA) support; Not using IMDSv2 (Instance Metadata Service v2)
- **ops-search** (i-015d864871acc6280): AMI is 1155 days old (>1 year); Third-party AMI owner: 198161015548; Missing Enhanced Networking (ENA) support; Not using IMDSv2 (Instance Metadata Service v2)
- **opensearch-test** (i-0cd3b6aaf9dadb07d): AMI is 1155 days old (>1 year); Third-party AMI owner: 198161015548; Missing Enhanced Networking (ENA) support; Not using IMDSv2 (Instance Metadata Service v2)
- **muhimbi-node0** (i-09ccc6ac0b3f0339a): AMI is 1358 days old (>1 year); Third-party AMI owner: 198161015548; Not using IMDSv2 (Instance Metadata Service v2)

### Deprecated AMIs (Replace Immediately)
- **puppetmaster.old** (i-a409368e): ubuntu/images/ebs/ubuntu-lucid-10.04-amd64-server-20140606
- **ops-search-d** (i-a12f2a8b): ubuntu/images/ebs/ubuntu-lucid-10.04-amd64-server-20140606
- **ops-nat** (i-5b08ffb7): amzn-ami-vpc-nat-hvm-2014.09.1.x86_64-gp2
- **new-bastion** (i-0a4890503b8ec083b): al2023-ami-2023.0.20230419.0-kernel-6.1-x86_64
