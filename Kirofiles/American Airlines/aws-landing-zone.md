# AWS Landing Zone for NXOP

## Overview

This document outlines the account structure, access procedures, and governance practices for the NXOP AWS environment.

### Account Structure

NXOP follows a dedicated AWS account structure with separate accounts for each environment (dev, stage, prod) to maximize operational benefits and security isolation. This architecture provides:

**Operational Benefits:**
- **Environment Isolation**: Each environment operates independently, preventing accidental cross-environment impacts during development
- **Resource Optimization**: Dev environments can run with different SLAs and resource requirements than production
- **Reduced Blast Radius**: Issues in one environment are contained and cannot affect other environments

**Testing and Innovation:**
- **Safe Load Testing**: Enables performance testing without affecting shared resources or production workloads
- **Chaos Engineering**: Allows chaos engineering practices in stage environments without production-sized costs or risks
- **Innovation Freedom**: Developers can innovate in dev environments without risk to staging or production systems

**Security and Governance:**
- **Environment-Specific Controls**: Accounts are organized within environment-specific Organizational Units (OUs) for tailored security policies
- **Third-Party Integration**: Supports vendor negotiations for environment-specific integrations and licensing

This structure enables simplified maintenance, enhanced security posture, and operational flexibility across the NXOP platform lifecycle.

![NXOP Dev VPC](images/nxop-account-structure.png)

### Accounts 

| Account | Account ID | Purpose | Description |
|---------|------------|---------|-------------|
| **POC** | 490422579276 |Initial Testing | For initial testing and evaluation of AWS services  |
| **Dev** | 178549792225|Development | Development environment for active feature development |
| **Stage** | TBD |Staging/Testing | Pre-production testing and integration validation |
| **Prod** | TBD |Production | Live production environment serving end users |

## Access Portal

**Login URL**: [https://aa.awsapps.com/start/#/](https://aa.awsapps.com/start/#/)

## AWS Account Creation Process

### 1. Create Distribution List (DL)
**Purpose**: Distribution lists are required for AWS account management and notifications.

1. Navigate to [MS365 Group Management](https://ms365groupmanagement.azurewebsites.net/new-dl)
2. Create a new distribution list following the naming convention
3. **Example DL Name**: `DL_AWS_NXOP_DEV`
4. **Naming Pattern**: `DL_AWS_NXOP_{ENVIRONMENT}`
   - POC: `DL_AWS_NXOP_POC`
   - Dev: `DL_AWS_NXOP_DEV`
   - Stage: `DL_AWS_NXOP_STAGE`
   - Prod: `DL_AWS_NXOP_PROD`

### 2. Request AWS Account Creation
1. Submit AWS account creation request. Refer this document for Details: [AWS Account Naming Documentation](https://developer.aa.com/docs/default/component/governance-as-a-service/aws/aws-account-naming-standards/)

### 3. SCIM Onboarding Process
**User access management is handled through SCIM (System for Cross-domain Identity Management)**

1. **Account Onboarding**: Once the AWS account is created, follow the SCIM onboarding process:
   - Documentation: [AWS Account SCIM Onboarding](https://github.com/AAInternal/governance-as-a-service/blob/main/docs/aws/AWS-Account-Scim-Onboarding.md)
   - This step maps default AWS roles to SCIM roles

2. **Default Role Mapping**: The following roles are automatically mapped:
   - `admin` → SCIM admin role
   - `readonly` → SCIM readonly role  
   - `poweruser` → SCIM poweruser role

### 4. Role Assignment Management
After SCIM onboarding is complete, manage user role assignments using:
- **Process Documentation**: [SCIM Role Assignment Process](https://github.com/AAInternal/governance-as-a-service/blob/main/docs/aws/SCIM-Role-Assignment-Process.md)
- **Role Management**: Product teams can assign users to appropriate roles

### User Roles Structure
**Example roles for Dev environment** (pattern applies to all environments):

| Role Name | Access Level | SCIM Group |
|-----------|--------------|------------|
| `aa-aws-nxop-dev-admin-scim` | Administrator | Full administrative access |
| `aa-aws-nxop-dev-readonly-scim` | Read Only | View-only access to resources |
| `aa-aws-nxop-dev-poweruser-scim` | Power User | Developer access with most permissions |
| `NXOPDeveloper` | Developer | Custom role with NXOP-specific permissions |

**Role Naming Convention**: `aa-aws-nxop-{environment}-{role}-scim`

### NXOP Developer Role Management
The `NXOPDeveloper` role is a custom permission set specifically designed for NXOP development teams. This role provides tailored access permissions for NXOP-specific AWS resources and development workflows.

**Permission Management**:
- Role permissions are managed through Infrastructure as Code (IaC)
- Changes are made via pull requests to the [aws-aft-account-customizations](https://github.com/AAInternal/aws-aft-account-customizations) repository
- Specific configuration file: `controltower-mgmt/terraform/NXOP-Developer-Permissionset.tf`
- All permission changes follow code review and approval processes

To request changes to the `NXOPDeveloper` role permissions, please submit a PR. 

## Steps for Getting Access

### 1. Request Access
- Contact your team lead or AWS administrator
- Specify which account(s) you need access to (POC, Dev, Stage, Prod)
- Include your employee ID and team information

### 2. Initial Login
1. Navigate to [https://aa.awsapps.com/start/#/](https://aa.awsapps.com/start/#/)
2. Enter sam credentials

## Contact Information

### Key Contacts
- **AWS Account Administrator**: Praveen Chand
- **Network Infrastructure via Terraform**: Shashank Parvatala (Owner Access to be Provided)
- **NXOP DevOps Team**: [To be filled]

## Related Documentation
- [NXOP Architecture Overview](./README.md)
- [NXOP Deployment Workflows](./nxop-workflow.md)
- [NXOP Production Workflow](./nxop-prod-worklow.md)
- [NXOP Repository List](./nxop-repo-list.md)

---

**Last Updated**: September 4, 2025  
**Document Owner**: NXOP Platform Team  
**Review Frequency**: Quarterly
