# Enhanced EC2 and AMI Analysis Summary

**Analysis Date:** 2025-12-16 18:03:46
**Account ID:** 145462881720
**Total Instances:** 30

## AMI Categories

- **Amazon Linux:** 18 instances
- **Container Optimized:** 9 instances
- **Other/Custom:** 2 instances
- **Ubuntu Linux:** 1 instances

## Security Risk Assessment

- **High Risk:** 30 instances

## Compliance Status

- **Non-Compliant: Deprecated AMI:** 28 instances
- **Non-Compliant: AMI >1 year old:** 2 instances

## AMI Age Analysis

- **Average AMI Age:** 459 days
- **Oldest AMI:** 1202 days
- **Newest AMI:** 60 days

## Update Recommendations

- **URGENT: Replace deprecated AMI immediately:** 28 instances
- **HIGH PRIORITY: Update AMI (>1 year old):** 2 instances

## High Priority Actions

### High Risk AMIs (Immediate Action Required)
- **staging-bastion-node-0** (i-01e821adf38adfb9c): AMI is 1188 days old (>1 year); Public AMI - verify source; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **staging-muhimbi-node-0** (i-028d73ecadf6de719): AMI is 1202 days old (>1 year); Third-party AMI owner: 198161015548; Not using IMDSv2 (Instance Metadata Service v2)
- **staging-muhimbi-node-1** (i-0a8c6d3da7058346a): AMI is 1202 days old (>1 year); Third-party AMI owner: 198161015548; Not using IMDSv2 (Instance Metadata Service v2)
- **qa-bastion-node** (i-0283c8394b7dac06e): AMI is 612 days old (>1 year); Public AMI - verify source; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **staging-eks128-ng-2** (i-0777b5e13f8d5e803): AMI is 818 days old (>1 year); Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **staging-eks128-ng-2** (i-081452c5861de024c): AMI is 818 days old (>1 year); Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **staging-eks128-ng-1** (i-0ce3ab3dcbd8f6c4d): AMI is 818 days old (>1 year); Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **staging-eks128-ng-2** (i-0ef7183c1be371ffa): AMI is 818 days old (>1 year); Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **staging-eks128-ng-2** (i-0fc141347c79d5891): AMI is 818 days old (>1 year); Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **staging-eks128-ng-1** (i-037e60e6d6d94b3a0): AMI is 818 days old (>1 year); Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **staging-eks128-ng-1** (i-01c61377f5a00d644): AMI is 818 days old (>1 year); Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **staging-eks128-ng-1** (i-077e8fd7cca869147): AMI is 818 days old (>1 year); Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **staging-eks128-ng-1** (i-02cb11efbaf965a79): AMI is 818 days old (>1 year); Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)
- **qa-eks134-ng-1** (i-00dff438dd3d46e25): Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated
- **qa-eks134-ng-2** (i-03db3450af02422ce): Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated
- **staging-eks134-ng-1** (i-0da3b49b961a43a11): Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated
- **staging-eks134-ng-2** (i-0bd05d372b13cedcf): Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated
- **staging-eks134-ng-2** (i-0ca44038269905693): Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated
- **staging-eks134-ng-2** (i-06afd90c87e23902d): Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated
- **qa-eks134-ng-2** (i-085e3df618384660a): Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated
- **staging-eks134-ng-2** (i-00486f4390510fddc): Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated
- **staging-eks134-ng-2** (i-076a5ffa88a0c5352): Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated
- **qa-eks134-ng-2** (i-0348f9a312b0d6b7f): Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated
- **qa-eks134-ng-1** (i-0f6ac3060fbf33ded): Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated
- **staging-eks134-ng-1** (i-02bbb85092fa63213): Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated
- **staging-eks134-ng-1** (i-036ab030dad3a4eb3): Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated
- **qa-eks134-ng-1** (i-0f2982411e4b294a0): Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated
- **staging-eks134-ng-1** (i-07ab68f4064ad39e6): Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated
- **staging-eks134-ng-1** (i-0f800f69a08ca6f43): Public AMI - verify source; Third-party AMI owner: 602401143452; AMI is deprecated
- **nan** (i-08c2ceb28ae89d460): AMI is 1189 days old (>1 year); Public AMI - verify source; AMI is deprecated; Not using IMDSv2 (Instance Metadata Service v2)

### Deprecated AMIs (Replace Immediately)
- **staging-bastion-node-0** (i-01e821adf38adfb9c): amzn2-ami-kernel-5.10-hvm-2.0.20220912.1-x86_64-gp2
- **qa-bastion-node** (i-0283c8394b7dac06e): amzn2-ami-hvm-2.0.20240412.0-x86_64-gp2
- **staging-eks128-ng-2** (i-0777b5e13f8d5e803): amazon-eks-node-1.28-v20230919
- **staging-eks128-ng-2** (i-081452c5861de024c): amazon-eks-node-1.28-v20230919
- **staging-eks128-ng-1** (i-0ce3ab3dcbd8f6c4d): amazon-eks-node-1.28-v20230919
- **staging-eks128-ng-2** (i-0ef7183c1be371ffa): amazon-eks-node-1.28-v20230919
- **staging-eks128-ng-2** (i-0fc141347c79d5891): amazon-eks-node-1.28-v20230919
- **staging-eks128-ng-1** (i-037e60e6d6d94b3a0): amazon-eks-node-1.28-v20230919
- **staging-eks128-ng-1** (i-01c61377f5a00d644): amazon-eks-node-1.28-v20230919
- **staging-eks128-ng-1** (i-077e8fd7cca869147): amazon-eks-node-1.28-v20230919
- **staging-eks128-ng-1** (i-02cb11efbaf965a79): amazon-eks-node-1.28-v20230919
- **qa-eks134-ng-1** (i-00dff438dd3d46e25): amazon-eks-node-al2023-x86_64-standard-1.34-v20251007
- **qa-eks134-ng-2** (i-03db3450af02422ce): amazon-eks-node-al2023-x86_64-standard-1.34-v20251007
- **staging-eks134-ng-1** (i-0da3b49b961a43a11): amazon-eks-node-al2023-x86_64-standard-1.34-v20251016
- **staging-eks134-ng-2** (i-0bd05d372b13cedcf): amazon-eks-node-al2023-x86_64-standard-1.34-v20251016
- **staging-eks134-ng-2** (i-0ca44038269905693): amazon-eks-node-al2023-x86_64-standard-1.34-v20251016
- **staging-eks134-ng-2** (i-06afd90c87e23902d): amazon-eks-node-al2023-x86_64-standard-1.34-v20251016
- **qa-eks134-ng-2** (i-085e3df618384660a): amazon-eks-node-al2023-x86_64-standard-1.34-v20251007
- **staging-eks134-ng-2** (i-00486f4390510fddc): amazon-eks-node-al2023-x86_64-standard-1.34-v20251016
- **staging-eks134-ng-2** (i-076a5ffa88a0c5352): amazon-eks-node-al2023-x86_64-standard-1.34-v20251016
- **qa-eks134-ng-2** (i-0348f9a312b0d6b7f): amazon-eks-node-al2023-x86_64-standard-1.34-v20251007
- **qa-eks134-ng-1** (i-0f6ac3060fbf33ded): amazon-eks-node-al2023-x86_64-standard-1.34-v20251007
- **staging-eks134-ng-1** (i-02bbb85092fa63213): amazon-eks-node-al2023-x86_64-standard-1.34-v20251016
- **staging-eks134-ng-1** (i-036ab030dad3a4eb3): amazon-eks-node-al2023-x86_64-standard-1.34-v20251016
- **qa-eks134-ng-1** (i-0f2982411e4b294a0): amazon-eks-node-al2023-x86_64-standard-1.34-v20251007
- **staging-eks134-ng-1** (i-07ab68f4064ad39e6): amazon-eks-node-al2023-x86_64-standard-1.34-v20251016
- **staging-eks134-ng-1** (i-0f800f69a08ca6f43): amazon-eks-node-al2023-x86_64-standard-1.34-v20251016
- **nan** (i-08c2ceb28ae89d460): ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20220914
