# WAC Infrastructure Questions - Comprehensive Report
## Answers to Key Infrastructure and Security Questions

**Report Date**: February 8, 2026  
**Project**: WAC DC Migration & Infrastructure Analysis  
**Classification**: Internal Use

---

## Executive Summary

This report answers five critical questions about the WAC infrastructure:
1. Migration automation tools
2. Zero Trust Security products
3. Roaming profiles and user profile storage
4. Monitoring products
5. VDI image storage

---

## Question 1: Migration Automation Tools

### Tools Used for WAC DC Migration

#### 1. Active Directory Migration Tool (ADMT)
**Purpose**: Automate Active Directory migration tasks

**Evidence Found**:
- IAM Role: `ADMT-EC2-SSMRole` (Active Directory Migration Tool SSM access)
- IAM Role: `ADMTSSMValidation1-ADMTValidationRole-ID3a0OrZTzp0` (ADMT validation)
- S3 Bucket: `wac-admt-installers` (Active Directory Migration Tool installers)
- Production IAM Role: `WAC-Prod-ADMT-Enhanced-Role`

**What It Does**:
- Migrates user accounts and groups
- Transfers computer accounts
- Migrates security principals
- Handles password migration
- Validates migration success

**Location**: Installed on EC2 instances with SSM access

---

#### 2. Custom PowerShell Automation Scripts
**Purpose**: Automate FSMO role transfer and DC migration

**Scripts Created**:
1. **1-PRE-CUTOVER-CHECK.ps1**
   - Validates environment before migration
   - Checks AD replication health
   - Verifies FSMO role holders
   - Tests connectivity

2. **2-EXECUTE-CUTOVER.ps1**
   - Transfers FSMO roles from on-prem to AWS
   - Automates role transfer process
   - Validates each transfer step
   - Forces AD replication

3. **3-POST-CUTOVER-VERIFY.ps1**
   - Verifies FSMO roles transferred successfully
   - Checks AD replication status
   - Validates DNS resolution
   - Tests authentication

4. **4-ROLLBACK.ps1**
   - Rolls back FSMO roles if issues occur
   - Transfers roles back to on-prem DCs
   - Emergency recovery procedure

**Location**: `03-Projects/WAC-DC-Migration/Scripts/Cutover/`

---

#### 3. AWS CloudFormation
**Purpose**: Infrastructure as Code for automated deployment

**Evidence Found**:
- S3 Buckets for templates:
  - `cf-templates-1v9ia6ek17jfq-us-west-2`
  - `cf-templates-cz03qvwrc9a0-us-west-2`
- CloudFormation templates for WACPRODDC01 and WACPRODDC02
- Automated EC2 instance provisioning
- Security group configuration
- IAM role creation

**What It Automates**:
- Domain Controller deployment
- Network configuration
- Security group setup
- IAM role assignment
- EBS volume creation

**Location**: `03-Projects/WAC-DC-Migration/CloudFormation/`

---

#### 4. AWS Systems Manager (SSM)
**Purpose**: Remote management and automation

**What It Provides**:
- Remote command execution
- Session Manager for secure access
- Automated patching
- Configuration management
- No RDP/SSH required

**IAM Roles**:
- `WAC-Prod-ADMT-Enhanced-Profile` (includes SSM access)
- `AmazonSSMManagedInstanceCore` policy attached

---

#### 5. AWS Control Tower
**Purpose**: Multi-account governance and automation

**Evidence Found**:
- Control Tower Log Archive Account (729265419250)
- Automated account provisioning
- Centralized logging
- Guardrails enforcement
- Service Control Policies (SCPs)

---

### Summary: Migration Automation

| Tool | Purpose | Automation Level |
|------|---------|------------------|
| ADMT | AD object migration | High |
| PowerShell Scripts | FSMO transfer | High |
| CloudFormation | Infrastructure deployment | High |
| SSM | Remote management | Medium |
| Control Tower | Account governance | High |

**Overall Assessment**: The migration is **highly automated** with custom scripts and AWS native tools.

---


## Question 2: Zero Trust Security Products

### Zero Trust Security Implementation

Based on the documentation review, **no dedicated Zero Trust Security products** (like Zscaler, Cloudflare Zero Trust, or Okta) were explicitly mentioned. However, several **Zero Trust principles** are implemented using AWS native services and security best practices.

---

### Zero Trust Principles Implemented

#### 1. Multi-Factor Authentication (MFA)
**Status**: Recommended but not fully enforced

**Evidence Found**:
- Root account MFA: **Enabled** ✅
- IAM user MFA: **4 users without MFA** ❌
- VPN MFA: **Recommended** for production
- SSM MFA: **Supported** via IAM policies

**Users Without MFA** (Security Gap):
1. insightIDR_Rapid7 (service account)
2. jennifer.davis (human user)
3. jsisk (human user)
4. srs.logz.io (service account)

**Recommendation**: Enable MFA for all human users immediately

---

#### 2. Identity and Access Management (IAM)
**Product**: AWS IAM (Native)

**Zero Trust Features**:
- ✅ Principle of least privilege enforced
- ✅ Separate admin accounts for privileged operations
- ✅ IAM roles instead of long-term credentials
- ✅ Cross-account access via IAM roles
- ✅ Regular access reviews (monthly recommended)

**IAM Roles for DCs**:
- `WAC-Prod-ADMT-Enhanced-Role`
- `ADMT-EC2-SSMRole`
- Policies: `AmazonSSMManagedInstanceCore`, `CloudWatchAgentServerPolicy`

---

#### 3. Network Segmentation
**Product**: AWS VPC + Security Groups

**Zero Trust Features**:
- ✅ VPC isolation (vpc-014b66d7ca2309134)
- ✅ Private subnets for Domain Controllers
- ✅ Security groups with least privilege rules
- ✅ Network ACLs for additional layer
- ✅ No public IP addresses on DCs

**Security Group**: sg-0b0bd0839e63d3075 (WAC-Prod-ADMT-Enhanced-SG)
- Only allows traffic from specific CIDR blocks
- RDP restricted to VPN clients only (10.200.0.0/16)
- AD ports restricted to internal networks

---

#### 4. VPN Access Control
**Product**: AWS Client VPN

**Zero Trust Features**:
- ✅ Certificate-based authentication
- ✅ Split-tunnel configuration (only VPC traffic)
- ✅ Session timeout (24 hours)
- ✅ Connection logging to CloudWatch
- ✅ IP-based access control
- ⚠️ MFA recommended but not enforced

**VPN Configuration**:
- CIDR: 10.200.0.0/16 (Production)
- CIDR: 10.100.0.0/16 (Development)
- Authentication: Mutual TLS (certificate-based)
- Logging: CloudWatch (180-day retention)

---

#### 5. Session Monitoring and Logging
**Product**: AWS Systems Manager Session Manager

**Zero Trust Features**:
- ✅ Session recording (all sessions logged)
- ✅ CloudWatch integration
- ✅ S3 session log storage
- ✅ No direct RDP/SSH required
- ✅ IAM-based access control
- ✅ Audit trail for all access

**Log Retention**:
- Production: 180 days
- Development: 90 days

---

#### 6. Encryption
**Products**: AWS KMS, TLS/SSL

**Zero Trust Features**:
- ✅ EBS volumes encrypted at rest
- ✅ S3 buckets encrypted
- ✅ TLS for all network traffic
- ✅ Certificate-based authentication
- ⚠️ EBS encryption by default: **Disabled** (should be enabled)

---

### Zero Trust Security Gaps

#### Critical Gaps:
1. ❌ **No dedicated Zero Trust platform** (Zscaler, Cloudflare, etc.)
2. ❌ **MFA not enforced** for all users
3. ❌ **EBS encryption by default disabled**
4. ❌ **Old access keys** (up to 7.8 years old!)

#### Recommendations:
1. **Implement MFA enforcement** for all human users
2. **Enable EBS encryption by default**
3. **Rotate old access keys** (5 keys older than 90 days)
4. **Consider Zero Trust platform** (Zscaler, Cloudflare Zero Trust, or Okta)
5. **Implement device posture checking**
6. **Add conditional access policies**

---

### Summary: Zero Trust Security

| Component | Product | Status |
|-----------|---------|--------|
| MFA | AWS IAM | ⚠️ Partial (root only) |
| Identity Management | AWS IAM | ✅ Implemented |
| Network Segmentation | AWS VPC + SG | ✅ Implemented |
| VPN Access | AWS Client VPN | ✅ Implemented |
| Session Monitoring | AWS SSM | ✅ Implemented |
| Encryption | AWS KMS | ⚠️ Partial |
| Zero Trust Platform | None | ❌ Not Implemented |

**Overall Assessment**: **Zero Trust principles** are partially implemented using AWS native services, but **no dedicated Zero Trust platform** is in use. MFA enforcement and encryption gaps need to be addressed.

---

## Question 3: Roaming Profiles and User Profile Storage

### User Profile Management

**Finding**: **No roaming profiles or centralized user profile storage** (like FSLogix, UPD, or traditional roaming profiles) were found in the documentation.

---

### What Was NOT Found:

❌ **FSLogix** - Not mentioned  
❌ **User Profile Disks (UPD)** - Not mentioned  
❌ **Traditional Roaming Profiles** - Not mentioned  
❌ **Profile Containers** - Not mentioned  
❌ **Citrix Profile Management** - Not mentioned  
❌ **VMware Dynamic Environment Manager** - Not mentioned  

---

### What IS Used:

#### Local Profiles Only
**Evidence**: The infrastructure is focused on **Domain Controllers** and **server infrastructure**, not end-user workstations or VDI.

**Profile Storage**:
- User profiles stored **locally** on each workstation/server
- No centralized profile storage mentioned
- Standard Windows local profile behavior

**Why No Roaming Profiles?**:
1. **Infrastructure Focus**: Documentation focuses on DC migration, not end-user computing
2. **Server Environment**: Domain Controllers don't require roaming profiles
3. **Admin Access**: Administrators likely use local profiles when accessing DCs via RDP/SSM

---

### If Roaming Profiles Were Needed:

**Recommended Solutions**:

1. **FSLogix Profile Containers** (Microsoft)
   - Store profiles in Azure Files or SMB share
   - Best for Windows Virtual Desktop / AVD
   - Supports Office 365 containers

2. **AWS FSx for Windows File Server**
   - Fully managed Windows file server
   - SMB protocol support
   - Can host roaming profiles
   - Integrated with Active Directory

3. **Traditional Roaming Profiles**
   - Store on file server (on-prem or AWS)
   - Configure via Group Policy
   - Not recommended (slow, problematic)

---

### Summary: User Profiles

| Question | Answer |
|----------|--------|
| Are roaming profiles used? | **No** |
| Where are profiles stored? | **Locally on each machine** |
| Is FSLogix used? | **No** |
| Is there centralized profile storage? | **No** |
| Recommended solution if needed? | **FSLogix + AWS FSx** |

**Overall Assessment**: **No roaming profiles** are currently implemented. This is appropriate for a server infrastructure focused on Domain Controllers. If end-user VDI is added in the future, FSLogix with AWS FSx would be recommended.

---

## Question 4: Monitoring Products

### Monitoring and Observability Stack

The WAC infrastructure uses **AWS native monitoring services** with some third-party integrations.

---

### Primary Monitoring Products

#### 1. Amazon CloudWatch (Primary)
**Purpose**: Comprehensive AWS monitoring and logging

**What It Monitors**:
- ✅ EC2 instance metrics (CPU, memory, disk, network)
- ✅ VPN connection logs
- ✅ Session Manager logs
- ✅ Application logs
- ✅ Custom metrics from CloudWatch Agent

**CloudWatch Components Used**:

**CloudWatch Alarms**:
- Instance status checks (WACPRODDC01, WACPRODDC02)
- High CPU alarms (both DCs)
- Memory utilization alarms
- Disk space alarms
- VPN connection status

**CloudWatch Logs**:
- Log Group: `/aws/clientvpn/prod-admin-vpn` (VPN logs)
- Log Group: `/aws/ad-health-monitor` (AD health monitoring)
- Retention: 180 days (Production), 90 days (Development)

**CloudWatch Agent**:
- Installed on both Domain Controllers
- Configuration file: `cloudwatch-agent-config.json`
- Collects: Memory, disk, custom metrics
- Location: `C:\AWSKiro\cloudwatch-agent-config.json`

**Cost**: ~$5/month

---

#### 2. AWS CloudTrail
**Purpose**: API activity logging and audit trail

**What It Monitors**:
- ✅ All AWS API calls
- ✅ User activity
- ✅ Resource changes
- ✅ Security events

**Configuration**:
- 3 CloudTrail trails enabled
- Encrypted with KMS
- Stored in S3 with lifecycle policies
- Integrated with CloudWatch Logs

---

#### 3. AWS Config
**Purpose**: Configuration compliance and change tracking

**What It Monitors**:
- ✅ Resource configuration changes
- ✅ Compliance with rules
- ✅ Configuration history
- ✅ Relationship tracking

**Config Rules Enabled**:
- s3-bucket-public-read-prohibited
- iam-password-policy
- mfa-enabled-for-iam-console-access

---

#### 4. VPC Flow Logs
**Purpose**: Network traffic monitoring

**What It Monitors**:
- ✅ Network traffic patterns
- ✅ Security group effectiveness
- ✅ Troubleshooting connectivity
- ✅ Security analysis

**IAM Role**: `WAC-Prod-VPC-VPCFlowLogsRole-LbE4mqrq7DMg`

---

#### 5. Amazon SNS (Alerting)
**Purpose**: Alert notifications

**Configuration**:
- SNS Topic: `WAC-Prod-DC-Alerts`
- Email notifications
- SMS notifications (optional)
- Integrated with CloudWatch Alarms

**Alert Types**:
- Instance status failures
- High CPU/memory usage
- AD replication failures
- VPN connection issues

---

### Third-Party Monitoring (Limited)

#### 1. Rapid7 InsightIDR
**Evidence**: IAM user `insightIDR_Rapid7` (service account)

**Purpose**: Security monitoring and incident detection
- SIEM (Security Information and Event Management)
- Threat detection
- Log analysis
- Incident response

---

#### 2. Logz.io
**Evidence**: IAM user `srs.logz.io` (service account)

**Purpose**: Log aggregation and analysis
- Centralized logging
- Log search and analysis
- Dashboards and visualizations
- Based on ELK stack (Elasticsearch, Logstash, Kibana)

---

### Custom Monitoring Scripts

#### 1. AD Health Monitor
**Script**: `ad-health-monitor.ps1`  
**Location**: `03-Projects/Monitoring/`

**What It Monitors**:
- AD replication status
- FSMO role holders
- DNS resolution
- DC connectivity
- Event log errors

**Integration**:
- Sends metrics to CloudWatch
- Triggers SNS notifications
- Logs to CloudWatch Logs
- Runs every 5 minutes (scheduled task)

---

#### 2. VPN Monitoring
**Script**: `setup-vpn-monitoring.ps1`  
**Location**: `03-Projects/Monitoring/`

**What It Monitors**:
- VPN connection status
- Client connections
- Connection failures
- Bandwidth usage

---

### Monitoring for NXOP (American Airlines Project)

**Note**: The NXOP project (separate from WAC) uses additional monitoring:

#### Dynatrace
**Purpose**: Application Performance Monitoring (APM)

**What It Monitors**:
- EKS clusters
- MSK (Kafka)
- DocumentDB
- Microservices (21 services)
- Service maps
- Distributed tracing

---

#### Mezmo
**Purpose**: Log aggregation and analysis

**What It Monitors**:
- Application logs
- Microservice logs
- Correlation IDs for tracing
- Log-based alerting

---

### Monitoring Dashboard Locations

**CloudWatch Dashboards**:
- AWS Console → CloudWatch → Dashboards
- Custom dashboards for:
  - EC2 instances (DCs)
  - VPN connections
  - AD health metrics
  - Network traffic

**Monitoring Scripts**:
- `03-Projects/Monitoring/ad-health-monitor.ps1`
- `03-Projects/Monitoring/wac-monitoring-setup.ps1`
- `03-Projects/Monitoring/add-memory-alarms.ps1`
- `03-Projects/Monitoring/install-cloudwatch-agent.ps1`

---

### Summary: Monitoring Products

| Product | Purpose | Status | Cost |
|---------|---------|--------|------|
| **CloudWatch** | Primary monitoring | ✅ Active | ~$5/month |
| **CloudTrail** | API audit logging | ✅ Active | Included |
| **AWS Config** | Compliance monitoring | ✅ Active | ~$2/month |
| **VPC Flow Logs** | Network monitoring | ✅ Active | ~$1/month |
| **SNS** | Alerting | ✅ Active | < $1/month |
| **Rapid7 InsightIDR** | Security monitoring | ✅ Active | Unknown |
| **Logz.io** | Log aggregation | ✅ Active | Unknown |
| **Custom Scripts** | AD health monitoring | ✅ Active | Free |

**Overall Assessment**: **Comprehensive monitoring** using AWS native services (CloudWatch, CloudTrail, Config) with third-party security monitoring (Rapid7, Logz.io). Total AWS monitoring cost: **~$10/month**.

---

## Question 5: VDI Image Storage

### VDI (Virtual Desktop Infrastructure) Implementation

**Finding**: **No VDI implementation** was found in the WAC infrastructure documentation.

---

### What Was NOT Found:

❌ **Amazon WorkSpaces** - Not mentioned  
❌ **Amazon AppStream 2.0** - Not mentioned  
❌ **Citrix Virtual Apps and Desktops** - Not mentioned  
❌ **VMware Horizon** - Not mentioned  
❌ **Windows Virtual Desktop / Azure Virtual Desktop** - Not mentioned  
❌ **VDI Golden Images** - Not mentioned  
❌ **VDI Image Storage** - Not mentioned  

---

### What IS Used Instead:

#### EC2 Instances (Servers, Not VDI)
**Purpose**: Domain Controllers and infrastructure servers

**AMI (Amazon Machine Image) Used**:
- **AMI ID**: `ami-0948bfde6d7c1b495`
- **OS**: Windows Server 2019 Datacenter
- **Purpose**: Domain Controller deployment
- **Storage**: Amazon EBS (Elastic Block Store)

**Instances**:
1. **WACPRODDC01**
   - Instance ID: i-0745579f46a34da2e
   - Instance Type: m5.large
   - Root Volume: 100 GB gp3 (encrypted)
   - AMI: ami-0948bfde6d7c1b495

2. **WACPRODDC02**
   - Instance ID: i-08c78db5cfc6eb412
   - Instance Type: m5.large
   - Root Volume: 100 GB gp3 (encrypted)
   - AMI: ami-0948bfde6d7c1b495

---

### Where Server Images Are Stored:

#### 1. Amazon Machine Images (AMIs)
**Storage Location**: Amazon EC2 AMI Registry (us-west-2)

**What They Contain**:
- Operating system (Windows Server 2019)
- Pre-configured settings
- Installed applications
- System configuration

**AMI Storage**:
- Backed by EBS snapshots
- Stored in S3 (managed by AWS)
- Regional (us-west-2)
- Can be copied to other regions

**Cost**: Based on EBS snapshot storage (~$0.05/GB/month)

---

#### 2. EBS Snapshots
**Purpose**: Backup and recovery

**What They Contain**:
- Point-in-time backups of EBS volumes
- Domain Controller system state
- Application data
- Configuration

**Snapshot Strategy**:
- Automated daily snapshots (recommended)
- Manual snapshots before changes
- Stored in S3 (managed by AWS)
- Incremental (only changed blocks)

**Cost**: ~$0.05/GB/month

---

#### 3. CloudFormation Templates
**Purpose**: Infrastructure as Code

**Storage Location**: S3 buckets
- `cf-templates-1v9ia6ek17jfq-us-west-2`
- `cf-templates-cz03qvwrc9a0-us-west-2`

**What They Contain**:
- EC2 instance configuration
- Network settings
- Security group rules
- IAM role definitions
- UserData scripts

**Location**: `03-Projects/WAC-DC-Migration/CloudFormation/`

---

### If VDI Were Needed:

**Recommended AWS Solutions**:

#### 1. Amazon WorkSpaces
**Best For**: Persistent virtual desktops

**Image Storage**:
- Custom WorkSpaces images stored in AWS
- Based on WorkSpaces bundles
- Regional storage
- Can create custom images from existing WorkSpaces

**Cost**: $25-75/user/month (depending on bundle)

---

#### 2. Amazon AppStream 2.0
**Best For**: Application streaming (non-persistent)

**Image Storage**:
- AppStream 2.0 image builder
- Custom images stored in AWS
- Regional storage
- Can create fleet from images

**Cost**: $0.20-0.60/hour (depending on instance type)

---

#### 3. EC2 with RDP (Current Approach)
**Best For**: Admin access to servers

**Image Storage**:
- AMIs in EC2
- EBS snapshots
- S3 for templates

**Cost**: Based on EC2 instance type + storage

---

### Summary: VDI Image Storage

| Question | Answer |
|----------|--------|
| Is VDI implemented? | **No** |
| Are WorkSpaces used? | **No** |
| Are AppStream used? | **No** |
| Where are server images stored? | **AMIs in EC2 (us-west-2)** |
| What AMI is used for DCs? | **ami-0948bfde6d7c1b495** |
| Where are backups stored? | **EBS Snapshots in S3** |
| Recommended VDI solution? | **Amazon WorkSpaces** |

**Overall Assessment**: **No VDI implementation** exists. The infrastructure uses traditional EC2 instances for servers (Domain Controllers). Server images are stored as **AMIs** backed by **EBS snapshots** in **S3** (managed by AWS). If VDI is needed in the future, **Amazon WorkSpaces** would be the recommended solution.

---

## Consolidated Summary

### Quick Reference Table

| Question | Answer | Product/Service | Status |
|----------|--------|-----------------|--------|
| **1. Migration Automation** | Highly automated | ADMT, PowerShell, CloudFormation, SSM | ✅ Implemented |
| **2. Zero Trust Security** | Partial implementation | AWS IAM, VPC, Client VPN, SSM | ⚠️ Gaps exist |
| **3. Roaming Profiles** | Not used | Local profiles only | N/A |
| **4. Monitoring** | Comprehensive | CloudWatch, CloudTrail, Config, Rapid7, Logz.io | ✅ Implemented |
| **5. VDI Images** | No VDI | AMIs for servers only | N/A |

---

### Key Findings

#### Strengths:
- ✅ **Highly automated migration** with custom scripts and AWS tools
- ✅ **Comprehensive monitoring** with CloudWatch and third-party tools
- ✅ **Strong network segmentation** with VPC and security groups
- ✅ **Session logging** and audit trails
- ✅ **Infrastructure as Code** with CloudFormation

#### Gaps:
- ❌ **No dedicated Zero Trust platform** (Zscaler, Cloudflare, etc.)
- ❌ **MFA not enforced** for all users (4 users without MFA)
- ❌ **Old access keys** (up to 7.8 years old)
- ❌ **EBS encryption by default disabled**
- ❌ **No roaming profiles** (not needed for current use case)
- ❌ **No VDI implementation** (not needed for current use case)

---

### Recommendations

#### Immediate (Within 1 Week):
1. **Enable MFA** for all human IAM users (jennifer.davis, jsisk)
2. **Rotate old access keys** (5 keys older than 90 days)
3. **Enable EBS encryption by default**
4. **Review service account credentials** (insightIDR_Rapid7, srs.logz.io)

#### Short-Term (Within 1 Month):
1. **Implement MFA enforcement** via IAM policies
2. **Add conditional access policies**
3. **Enable CloudWatch anomaly detection**
4. **Implement automated security remediation**

#### Long-Term (3-6 Months):
1. **Evaluate Zero Trust platform** (Zscaler, Cloudflare Zero Trust, or Okta)
2. **Implement device posture checking**
3. **Add user behavior analytics**
4. **Consider VDI** if remote workforce expands (Amazon WorkSpaces)
5. **Implement FSLogix** if roaming profiles needed

---

## Appendix: Product Comparison

### Zero Trust Platforms (If Needed)

| Product | Strengths | Cost | Best For |
|---------|-----------|------|----------|
| **Zscaler** | Comprehensive, cloud-native | $$$ | Large enterprises |
| **Cloudflare Zero Trust** | Fast, global network | $$ | Mid-size companies |
| **Okta** | Strong identity focus | $$ | Identity-first approach |
| **AWS Native** | Integrated, no extra cost | $ | AWS-only environments |

### VDI Solutions (If Needed)

| Product | Strengths | Cost | Best For |
|---------|-----------|------|----------|
| **Amazon WorkSpaces** | Fully managed, AWS-native | $$ | AWS environments |
| **Amazon AppStream 2.0** | Application streaming | $ | Non-persistent desktops |
| **Citrix Virtual Apps** | Feature-rich, mature | $$$ | Complex requirements |
| **VMware Horizon** | VMware integration | $$$ | VMware shops |

### Monitoring Solutions

| Product | Strengths | Cost | Best For |
|---------|-----------|------|----------|
| **CloudWatch** | AWS-native, integrated | $ | AWS infrastructure |
| **Dynatrace** | AI-powered APM | $$$ | Application monitoring |
| **Datadog** | Multi-cloud, comprehensive | $$ | Hybrid environments |
| **Rapid7 InsightIDR** | Security-focused | $$ | Security monitoring |

---

**Report Prepared By**: Kiro AI Assistant  
**Review Date**: February 8, 2026  
**Next Review**: After infrastructure changes  
**Approval Required**: IT Management, Security Team

---

**END OF REPORT**
