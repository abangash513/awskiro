# Enhanced EC2 and AMI Analysis Summary

**Analysis Date:** 2025-12-16 17:57:53
**Account ID:** 946447852237
**Total Instances:** 15

## AMI Categories

- **Amazon Linux:** 7 instances
- **Container Optimized:** 6 instances
- **Other/Custom:** 2 instances

## Security Risk Assessment

- **High Risk:** 15 instances

## Compliance Status

- **Non-Compliant: Deprecated AMI:** 13 instances
- **Non-Compliant: AMI >1 year old:** 2 instances

## AMI Age Analysis

- **Average AMI Age:** 572 days
- **Oldest AMI:** 1202 days
- **Newest AMI:** 32 days

## Update Recommendations

- **URGENT: Replace deprecated AMI immediately:** 13 instances
- **HIGH PRIORITY: Update AMI (>1 year old):** 2 instances

## High Priority Actions

### High Risk AMIs (Immediate Action Required)
- **production-muhimbi-node-1** (i-072cfc3d826e32b41): AMI is 1202 days old (>1 year); Third-party AMI owner: 198161015548; Not using IMDSv2 (Instance Metadata Service v2)
- **production-muhimbi-node-0** (i-003db9cf5ac1ca620): AMI is 1202 days old (>1 year); Third-party AMI owner: 198161015548; Not using IMDSv2 (Instance Metadata Service v2)
- **production-bastion-node-0** (i-085667f918d2952d6): AMI is 1160 days old (>1 year); Public AMI - verify source; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **production-eks128-ng-2** (i-0f6c6c758cd7100f4): AMI is 805 days old (>1 year); Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **production-eks128-ng-1** (i-02cd0f7feea1dffcf): AMI is 805 days old (>1 year); Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **production-eks128-ng-2** (i-00a6e2a15b3fb1904): AMI is 805 days old (>1 year); Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **production-eks128-ng-1** (i-0ecf15b423fe7f783): AMI is 805 days old (>1 year); Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **production-eks128-ng-2** (i-06850070c870bd0bf): AMI is 805 days old (>1 year); Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **production-eks128-ng-1** (i-019f15d6c23b88bd6): AMI is 805 days old (>1 year); Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **production-eks134-ng-1** (i-0d28bbc2445048f7e): Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated
- **production-eks134-ng-1** (i-087f0e905c86d26ac): Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated
- **production-eks134-ng-2** (i-09dfab155924baeea): Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated
- **production-eks134-ng-1** (i-0f34341e154ccd087): Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated
- **production-eks134-ng-2** (i-017f0adf5429a8e10): Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated
- **production-eks134-ng-2** (i-05a3f0060c2cce9c1): Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated

### Deprecated AMIs (Replace Immediately)
- **production-bastion-node-0** (i-085667f918d2952d6): amzn2-ami-kernel-5.10-hvm-2.0.20221004.0-x86_64-gp2
- **production-eks128-ng-2** (i-0f6c6c758cd7100f4): amazon-eks-node-1.28-v20231002
- **production-eks128-ng-1** (i-02cd0f7feea1dffcf): amazon-eks-node-1.28-v20231002
- **production-eks128-ng-2** (i-00a6e2a15b3fb1904): amazon-eks-node-1.28-v20231002
- **production-eks128-ng-1** (i-0ecf15b423fe7f783): amazon-eks-node-1.28-v20231002
- **production-eks128-ng-2** (i-06850070c870bd0bf): amazon-eks-node-1.28-v20231002
- **production-eks128-ng-1** (i-019f15d6c23b88bd6): amazon-eks-node-1.28-v20231002
- **production-eks134-ng-1** (i-0d28bbc2445048f7e): amazon-eks-node-al2023-x86_64-standard-1.34-v20251112
- **production-eks134-ng-1** (i-087f0e905c86d26ac): amazon-eks-node-al2023-x86_64-standard-1.34-v20251112
- **production-eks134-ng-2** (i-09dfab155924baeea): amazon-eks-node-al2023-x86_64-standard-1.34-v20251112
- **production-eks134-ng-1** (i-0f34341e154ccd087): amazon-eks-node-al2023-x86_64-standard-1.34-v20251112
- **production-eks134-ng-2** (i-017f0adf5429a8e10): amazon-eks-node-al2023-x86_64-standard-1.34-v20251112
- **production-eks134-ng-2** (i-05a3f0060c2cce9c1): amazon-eks-node-al2023-x86_64-standard-1.34-v20251112
