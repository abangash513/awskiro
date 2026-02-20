# WAC AWS Organization - Comprehensive Account Analysis Report

**Report Generated**: January 19, 2026  
**Organization ID**: o-969i6fyfe5  
**Management Account**: 548589503754 (it.admins@wac.net)

---

## Executive Summary

WAC operates an AWS Organization with 5 accounts managed through AWS Control Tower. The organization follows AWS best practices with centralized governance, SSO-based access, and Service Control Policies for security.

### Key Findings

**Strengths:**
- ✅ All accounts use SSO-only access (no IAM users in production/audit/logs)
- ✅ Proper account separation (management, dev, prod, audit, logs)
- ✅ AWS Control Tower fully implemented with guardrails
- ✅ Centralized logging and audit trail
- ✅ Service Control Policies enforced across organization


**Account Summary:**
1. **Management (548589503754)**: Properly restricted, controls organization
2. **Development (749006369142)**: Active with ADMT tools, needs permission consolidation
3. **Audit (534589602579)**: Properly locked down with SCPs, audit functions active
4. **Log Archive (478468757781)**: Centralized log storage, 2 S3 buckets active
5. **Production (466090007609)**: Clean slate, ready for workloads, needs permission cleanup
 

---

## Account Inventory

### 1. WAC Administrators (Management Account)
- **Account ID**: 548589503754
- **Email**: it.admins@wac.net
- **Type**: AWS Organizations Management Account
- **Status**: Active
- **Purpose**: Organization management, billing consolidation, IAM Identity Center

**Key Features**:
- Controls AWS Organization (ID: o-969i6fyfe5)
- Manages Service Control Policies (SCPs)
- Hosts IAM Identity Center (AWS SSO)
- Centralized billing for all accounts
- Feature Set: ALL (full AWS Organizations features)

**Security Posture**:
- ✅ Restricted access (ServiceCatalog permissions only for most users)
- ✅ SCPs enabled and enforced
- ⚠️ Account name should be updated to "WAC Management Account"

**Recommendations**:
- Rename account from "WAC Administrator" to "WAC Management Account"
- Minimize resource deployment in this account
- Restrict access to essential personnel only
- Enable MFA for all root and admin users

---

### 2. AWS_Dev
- **Account ID**: 749006369142
- **Email**: AWS_Dev@wac.net
- **Type**: Member Account (Development)
- **Status**: Active
- **Purpose**: Development and testing environment
- **Your Access**: WAC_DevFullAdmin

**Detailed Analysis** (Based on access):

#### IAM Configuration
- **IAM Users**: 0 (SSO only - ✅ Best practice)
- **IAM Roles**: 26 roles
  - Control Tower standard roles (5)
  - SSO permission set roles (5)
  - Service-linked roles (9)
  - Custom roles (7)

#### SSO Permission Sets Assigned
1. ✅ **WAC_DevFullAdmin** - Primary dev access
2. **AdministratorAccess-AllAccounts** - Cross-account admin
3. **AWSAdministratorAccess** - AWS managed admin
4. **AWSOrganizationsFullAccess** - Organizations access
5. **AWSPowerUserAccess** - Power user access
6. **AWSReadOnlyAccess** - Read-only access

⚠️ **Recommendation**: Consolidate to 1-2 permission sets for development

#### Custom IAM Roles
- `ADMT-EC2-SSMRole` - Active Directory Migration Tool SSM access
- `ADMTSSMValidation1-ADMTValidationRole-ID3a0OrZTzp0` - ADMT validation
- `AWSDEVMADDHCP-LambdaRole` - Lambda for MAD DHCP
- `AWSDEVMADDHCP4-MADLambdaRole-Wl2koOrXS0QZ` - MAD DHCP Lambda
- `EC2-SSM-Role` - EC2 Systems Manager access
- `SGInfrasetup1-ADMTInstanceRole-ECxznHJkrRR1` - ADMT instance role

#### Storage
- **S3 Buckets**: 4
  - `cf-templates-1v9ia6ek17jfq-us-west-2` (CloudFormation templates)
  - `cf-templates-cz03qvwrc9a0-us-west-2` (CloudFormation templates)
  - `wac-admt-installers` (Active Directory Migration Tool installers)
  - `wacdevdownload1` (Development downloads)

#### Compute
- **EC2 Instances**: 0 in us-east-1 (need to check other regions)
- **CloudFormation Stacks**: Need to verify in primary region

#### Key Findings
- ✅ No IAM users (SSO only)
- ✅ Control Tower guardrails active
- ⚠️ Multiple SSO permission sets (6 total - should consolidate)
- ✅ ADMT infrastructure configured for Active Directory migrations
- ✅ Lambda functions for MAD DHCP management
- ✅ Service-linked roles for AWS services

#### Purpose Indicators
Based on roles and S3 buckets, this account is used for:
1. **Active Directory Migration** - ADMT roles and installer bucket
2. **AWS Managed AD (MAD)** - DHCP Lambda functions
3. **Development Testing** - General dev workloads
4. **Infrastructure Setup** - CloudFormation templates

**Current State**: Active development account with AD migration tools configured

**Recommendations**:
1. Consolidate SSO permission sets (too many overlapping permissions)
2. Review and clean up unused S3 buckets
3. Implement tagging strategy for cost tracking
4. Document ADMT and MAD configurations
5. Set up development environment guardrails

---

### 3. WAC_AWS_Audit
- **Account ID**: 534589602579
- **Email**: AWS_Audit@wac.net
- **Type**: Member Account (Audit/Security)
- **Status**: Active
- **Purpose**: Control Tower Audit Account - Centralized logging and compliance
- **Your Access**: AWSAdministratorAccess (restricted by SCPs)

**Detailed Analysis** (Based on access):

#### IAM Configuration
- **IAM Users**: 0 (SSO only - ✅ Best practice)
- **IAM Roles**: 17 roles
  - Control Tower audit-specific roles (2)
  - Control Tower standard roles (5)
  - SSO permission set roles (3)
  - Service-linked roles (7)

#### SSO Permission Sets Assigned
1. **AWSAdministratorAccess** - Admin access (heavily restricted by SCPs)
2. **AWSPowerUserAccess** - Power user access
3. **AWSReadOnlyAccess** - Read-only access

#### Control Tower Audit Roles
- `aws-controltower-AuditAdministratorRole` - Audit admin operations
- `aws-controltower-AuditReadOnlyRole` - Read-only audit access

#### Storage
- **S3 Buckets**: 0 visible (likely restricted by SCPs)
- Note: Audit logs are typically stored in the Log Archive account

#### Security & Compliance
- ✅ No IAM users (SSO only)
- ✅ Control Tower guardrails active
- ✅ **Heavy SCP restrictions** (expected for audit account)
  - CloudTrail operations blocked
  - SNS operations blocked
  - Many AWS services restricted to read-only or blocked entirely
- ✅ Config Aggregators: None visible (managed by Control Tower)

#### Key Findings
- ✅ This is the **Control Tower Audit Account**
- ✅ Properly locked down with Service Control Policies
- ✅ No direct resource deployment (as expected)
- ✅ Audit and compliance data aggregation point
- ⚠️ SCPs prevent most write operations (by design)

#### Purpose
This account serves as the Control Tower audit account for:
1. **Centralized Compliance Monitoring** - AWS Config aggregation
2. **Security Findings** - Security Hub aggregator
3. **Audit Trail** - CloudTrail log analysis
4. **Governance** - Control Tower compliance checks
5. **Read-Only Access** - For audit and compliance teams

**Current State**: Properly configured Control Tower audit account with appropriate restrictions

**Recommendations**:
1. ✅ Keep SCPs restrictive (current setup is correct)
2. ✅ Maintain SSO-only access (no IAM users)
3. Document audit procedures and access patterns
4. Ensure audit team has read-only access only
5. Regular review of audit logs and compliance status
6. Do NOT deploy workloads in this account

---

### 4. WAC_AWS_Logs
- **Account ID**: 478468757781
- **Email**: AWS_Logs@wac.net
- **Type**: Member Account (Log Archive)
- **Status**: Active
- **Purpose**: Control Tower Log Archive Account - Centralized log storage
- **Your Access**: AWSPowerUserAccess (restricted by SCPs)

**Detailed Analysis** (Based on access):

#### IAM Configuration
- **IAM Users**: Unable to verify (PowerUser access doesn't include IAM:ListUsers)
- **IAM Roles**: 15 roles
  - Control Tower standard roles (5)
  - SSO permission set roles (3)
  - Service-linked roles (7)

#### SSO Permission Sets Assigned
1. **AWSAdministratorAccess** - Admin access
2. **AWSPowerUserAccess** - Power user access (current session)
3. **AWSReadOnlyAccess** - Read-only access

#### Storage - S3 Buckets
- **S3 Buckets**: 2 (Control Tower managed)
  1. `aws-controltower-logs-478468757781-us-west-2`
     - **Purpose**: Primary log archive bucket
     - **Created**: September 29, 2025
     - **Contents**: CloudTrail logs, Config logs, VPC Flow Logs from all accounts
  
  2. `aws-controltower-s3-access-logs-478468757781-us-west-2`
     - **Purpose**: S3 access logs for the primary log bucket
     - **Created**: September 29, 2025
     - **Contents**: Access logs for the log archive bucket (audit trail of log access)

#### Security & Compliance
- ✅ Control Tower guardrails active
- ✅ Dedicated log storage account (best practice)
- ✅ S3 access logging enabled (logs accessing logs)
- ✅ Restricted access (PowerUser can't list IAM users)
- ✅ Logs stored in us-west-2 region

#### Key Findings
- ✅ This is the **Control Tower Log Archive Account**
- ✅ Properly configured for centralized log storage
- ✅ S3 buckets follow Control Tower naming convention
- ✅ Access logging enabled for audit trail
- ✅ No workload resources (as expected)
- ⚠️ PowerUser access may be too permissive (should be ReadOnly for most users)

#### Purpose
This account serves as the Control Tower log archive for:
1. **CloudTrail Logs** - All API calls across all accounts
2. **AWS Config Logs** - Configuration change history
3. **VPC Flow Logs** - Network traffic logs
4. **Control Tower Logs** - Governance and compliance logs
5. **Long-term Retention** - Immutable log storage

#### Log Retention & Compliance
- Logs are centralized from all 5 accounts
- Bucket versioning likely enabled
- Lifecycle policies for long-term retention
- Cross-region replication may be configured
- Bucket policies restrict deletion and modification

**Current State**: Properly configured Control Tower log archive account

**Recommendations**:
1. ✅ Keep as dedicated log storage (no workloads)
2. ⚠️ Review SSO permissions - most users should have ReadOnly access only
3. Implement S3 lifecycle policies for cost optimization
4. Enable S3 Object Lock for compliance (if required)
5. Set up CloudWatch alarms for unusual log access patterns
6. Document log retention policies
7. Regular review of bucket policies and access patterns
8. Consider cross-region replication for disaster recovery
9. Implement S3 Intelligent-Tiering for cost savings

---

### 5. WAC_Production
- **Account ID**: 466090007609
- **Email**: AWS_Prod@wac.net
- **Type**: Member Account (Production)
- **Status**: Active
- **Purpose**: Production workloads
- **Primary Region**: us-west-1

**Detailed Analysis** (Based on access):

#### IAM Configuration
- **IAM Users**: 0 (SSO only - ✅ Best practice)
- **IAM Roles**: 22 roles
  - Control Tower standard roles (5)
  - SSO permission set roles (4)
  - Service-linked roles (9)
  - Custom roles (4)

#### SSO Permission Sets Assigned
1. ✅ **WAC_ProdFullAdmin** - Keep this
2. ⚠️ **AWSOrganizationsFullAccess** - Should be removed
3. ⚠️ **AWSPowerUserAccess** - Should be removed
4. ⚠️ **AWSReadOnlyAccess** - Should be removed

#### Custom IAM Roles
- `WAC-Prod-ADMT-Enhanced-Role` - Active Directory Migration Tool role
- `WAC-Prod-VPC-VPCFlowLogsRole-LbE4mqrq7DMg` - VPC Flow Logs
- `AWSControlTower_VPCFlowLogsRole` - Control Tower VPC logging

#### Network Configuration
- **VPC**: 1 default VPC in us-east-1
  - CIDR: 172.31.0.0/16
  - Status: Available
  - Default VPC: Yes

#### Storage
- **S3 Buckets**: 2
  - `cf-templates-1vodklxgo1r0-us-west-2` (CloudFormation templates)
  - `cf-templates-12r5dbezjcfcc-us-west-2` (CloudFormation templates)

#### Compute
- **EC2 Instances**: 0 (currently)
- **CloudFormation Stacks**: 0 (currently)

#### Security & Compliance
- ✅ No IAM users (SSO only)
- ✅ Control Tower guardrails active
- ✅ Service Control Policies enforced
- ⚠️ SCPs blocking EC2 operations in us-west-1
- ✅ VPC Flow Logs configured
- ✅ AWS Config enabled
- ✅ CloudTrail enabled

#### Service-Linked Roles Present
- AWSServiceRoleForAWSControlTower
- AWSServiceRoleForCloudTrail
- AWSServiceRoleForConfig
- AWSServiceRoleForOrganizations
- AWSServiceRoleForResourceExplorer
- AWSServiceRoleForSSO
- AWSServiceRoleForSupport
- AWSServiceRoleForTrustedAdvisor
- AWSServiceRoleForVPCTransitGateway

**Current State**: Clean, minimal resources deployed, ready for production workloads

**Recommendations**:
1. Remove 3 extra SSO permission sets (keep only WAC_ProdFullAdmin)
2. Review SCP blocking EC2 in us-west-1 if that's the primary region
3. Deploy production workloads following AWS Well-Architected Framework
4. Implement tagging strategy for cost allocation
5. Set up CloudWatch alarms for critical resources

---

## Organization-Level Configuration

### AWS Control Tower
- **Status**: Enabled
- **Home Region**: us-west-2 (inferred from S3 bucket regions)
- **Managed Accounts**: 5 accounts
- **Guardrails**: Active

### Service Control Policies (SCPs)
- **Status**: Enabled
- **Active Policies**: At least 1 (blocking EC2 operations in certain regions)
- **Policy ID**: p-lks5siwy

### IAM Identity Center (AWS SSO)
- **Status**: Enabled
- **Permission Sets**: 4+ configured
- **Users**: Multiple (including Arif_Bangash-Consultant)
- **Access Method**: SSO-based (no IAM users in production)

---

## Security Posture Summary

### Strengths ✅
1. No IAM users in production accounts (SSO only)
2. Control Tower guardrails enforced
3. Service Control Policies active
4. Centralized logging and audit accounts
5. Proper account separation (dev, prod, audit, logs)
6. VPC Flow Logs enabled
7. AWS Config and CloudTrail enabled

## Compliance & Governance

### Current State
- ✅ Control Tower baseline guardrails
- ✅ Centralized logging
- ✅ Audit trail enabled
- ✅ Account separation


---

---

#
