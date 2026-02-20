# AWS Official Documentation - Infrastructure Questions Report

**Report Date**: February 12, 2026  
**Source**: AWS Official Documentation  
**Purpose**: Answer 5 infrastructure questions using official AWS guidance

---

## Executive Summary

This report provides answers to 5 critical infrastructure questions based on official AWS documentation. Each section includes direct references to AWS documentation, service descriptions, and implementation guidance.

---

## Question 1: Migration Automation Tools

### AWS Services for Automating Migration

#### 1.1 AWS Application Migration Service (MGN)
**Official Documentation**: [What Is AWS Application Migration Service?](https://docs.aws.amazon.com/mgn/latest/ug/what-is-application-migration-service.html)

**Description** (content rephrased for compliance with licensing restrictions):
- Highly automated lift-and-shift solution for migrating applications to AWS
- Simplifies and expedites migration of physical, virtual, or cloud servers
- Replicates source servers into AWS account without compatibility issues
- Automatically converts and launches servers on AWS
- Eliminates long cutover windows and performance disruption

**Key Features**:
- Continuous data replication from source servers
- Automated server conversion for AWS compatibility
- Test launches before production cutover
- Minimal downtime during migration
- Support for Windows and Linux operating systems

**Supported Regions**: Available in 40+ AWS Regions including US, Europe, Asia Pacific, Middle East, and GovCloud

**Integration**: Works with AWS Migration Hub for tracking migration progress across multiple servers and applications


#### 1.2 AWS Database Migration Service (DMS)
**Official Documentation**: [AWS Database Migration Service](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_GettingStarted.html)

**Description** (content rephrased for compliance with licensing restrictions):
- Seamless migration of databases to AWS
- Supports homogeneous migrations (Oracle to Oracle) and heterogeneous migrations (Oracle to Aurora)
- Continuous data replication with minimal downtime
- Schema conversion capabilities via DMS Schema Conversion tool

**Use Cases**:
- Migrate from Oracle to Amazon Aurora MySQL
- Migrate from SQL Server to Amazon Aurora PostgreSQL
- Migrate from on-premises databases to Amazon RDS
- Create data lakes by migrating to Amazon S3

#### 1.3 AWS DataSync
**Official Documentation**: [AWS DataSync Getting Started](https://docs.aws.amazon.com/datasync/latest/userguide/getting-started.html)

**Description** (content rephrased for compliance with licensing restrictions):
- Efficient and secure transfer of large datasets
- Automates data movement between on-premises and AWS storage
- Maintains data integrity throughout migration
- Supports continuous operations with minimal downtime

**Key Benefits**:
- Up to 10x faster than open-source tools
- Automatic encryption and data validation
- Bandwidth throttling and scheduling
- Integration with S3, EFS, and FSx


#### 1.4 AWS Transform
**Official Documentation**: [AWS Transform](https://docs.aws.amazon.com/transform/latest/userguide/what-is-service.html)

**Description** (content rephrased for compliance with licensing restrictions):
- Uses generative AI and agentic AI to automate migration
- Accelerates and optimizes the migration process
- Orchestrates migration for VMware workloads, mainframes, and .NET applications
- Creates inventory of applications and dependencies

#### 1.5 AWS Migration Hub
**Official Documentation**: [AWS Migration Hub](https://docs.aws.amazon.com/migrationhub/latest/ug/mha.html)

**Description** (content rephrased for compliance with licensing restrictions):
- Central location to track migration progress
- Organizes servers into applications
- Tracks progress at server and application level
- Automation units streamline migration tasks
- Supports cross-Region migrations

**Automation Capabilities**:
- Installing replication agents
- Verifying server health
- Launching test and cutover instances
- Finalizing cutover operations
- Archiving source servers

#### 1.6 AWS Storage Gateway
**Official Documentation**: [AWS Storage Gateway](https://docs.aws.amazon.com/filegateway/latest/files3/setting-up.html)

**Description** (content rephrased for compliance with licensing restrictions):
- Hybrid cloud storage integration
- Connects on-premises environments with AWS cloud storage
- Enables unified data management strategy
- Minimizes disruptions during migration

---


## Question 2: Zero Trust Security Products

### AWS Services for Zero Trust Architecture

**Official Documentation**: [Zero Trust Architecture Components](https://docs.aws.amazon.com/prescriptive-guidance/latest/strategy-zero-trust-architecture/components.html)

#### 2.1 AWS Verified Access
**Official Documentation**: [How Verified Access Works](https://docs.aws.amazon.com/verified-access/latest/ug/how-it-works.html)

**Description** (content rephrased for compliance with licensing restrictions):
- Provides secure access to applications without VPN
- Evaluates each application request based on trust data and policies
- Grants access only when security requirements are met
- All requests denied by default until policy is defined

**Key Components**:
- **Verified Access Instances**: Evaluate application requests and grant access based on security requirements
- **Verified Access Endpoints**: Each endpoint represents an application
- **Verified Access Groups**: Collection of endpoints with similar security requirements
- **Access Policies**: User-defined rules determining allow/deny access based on user identity and device security state
- **Trust Providers**: Services managing user identities or device security state (AWS or third-party)
- **Trust Data**: Security-related data from trust providers (user claims, device state)

**Benefits**:
- Zero Trust Network Access (ZTNA) without VPN infrastructure
- Continuous validation of user and device security posture
- Comprehensive logging of all access attempts
- Integration with identity providers and device management solutions


#### 2.2 AWS IAM Identity Center (formerly AWS SSO)
**Official Documentation**: [What is IAM Identity Center?](https://docs.aws.amazon.com/singlesignon/latest/userguide/what-is.html)

**Description** (content rephrased for compliance with licensing restrictions):
- Single point of federation for workforce user access
- Connects existing identity providers or manages users directly
- Provides centralized access to AWS accounts and applications
- Enables trusted identity propagation across applications

**Key Capabilities**:
- **Single Sign-On (SSO)**: One authentication for multiple AWS accounts and applications
- **Multi-Factor Authentication (MFA)**: Enhanced authentication security
- **Centralized Permission Management**: Assign permissions across multiple AWS accounts
- **Identity Federation**: Integrates with external identity providers (Active Directory, Okta, Azure AD)
- **Attribute-Based Access Control (ABAC)**: Fine-grained permissions using user attributes

**Zero Trust Benefits**:
- Strong user authentication foundation
- Centralized identity governance
- Continuous authentication and authorization
- Integration with AWS managed applications

#### 2.3 AWS Identity and Access Management (IAM)
**Official Documentation**: [IAM Roles](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html)

**Zero Trust Features**:
- Fine-grained access control policies
- Temporary security credentials
- Least privilege access enforcement
- Policy-based authorization decisions
- Service control policies (SCPs) for organization-wide governance


#### 2.4 Zero Trust Architecture Key Components (AWS Prescriptive Guidance)

**Official Documentation**: [Key Components of Zero Trust Architecture](https://docs.aws.amazon.com/prescriptive-guidance/latest/strategy-zero-trust-architecture/components.html)

Content was rephrased for compliance with licensing restrictions:

**1. Identity and Access Management**:
- Foundation of Zero Trust Architecture
- Robust user authentication mechanisms
- Single sign-on (SSO) and multi-factor authentication (MFA)
- Identity governance and management solutions
- Per-user, per-device, per-session access control

**2. Secure Access Service Edge (SASE)**:
- Virtualizes and combines networking and security functions
- Cloud-based service delivery
- Secure web gateways and firewall as a service
- Zero Trust Network Access (ZTNA)
- Protection against malware, phishing, and ransomware

**3. Data Loss Prevention (DLP)**:
- Protects sensitive data from unauthorized disclosure
- Monitors and controls data in motion and at rest
- Enforces policies preventing data-related security events

**4. Security Information and Event Management (SIEM)**:
- Collects and aggregates security event logs
- Analyzes data from various infrastructure sources
- Detects security incidents and facilitates response
- Correlates telemetry from different security systems

**5. Unified Endpoint Management (UEM)**:
- Assesses device health, posture, and state
- Device provisioning and configuration management
- Security baselining and patch management
- Telemetry reporting and device retirement

**6. Policy-Based Enforcement Points**:
- Explicit authorization for each resource access
- Considers wider array of context and signals
- Maintains comprehensive policy sets
- Enhanced with intelligence from combined telemetry


#### 2.5 Additional AWS Zero Trust Services

**AWS Services Supporting Zero Trust**:
- **Amazon VPC**: Network isolation and segmentation
- **AWS Security Groups**: Stateful firewall rules
- **AWS Network Firewall**: Advanced network protection
- **AWS CloudTrail**: Comprehensive audit logging
- **AWS Config**: Resource configuration monitoring
- **AWS GuardDuty**: Threat detection service
- **AWS Security Hub**: Centralized security findings
- **AWS Systems Manager**: Secure instance management without SSH/RDP

---

## Question 3: Roaming Profiles and User Profile Storage

### AWS Services for Windows User Profiles

#### 3.1 Amazon FSx for Windows File Server
**Official Documentation**: [What is FSx for Windows File Server?](https://docs.aws.amazon.com/fsx/latest/WindowsGuide/what-is.html)

**Description** (content rephrased for compliance with licensing restrictions):
- Fully managed Microsoft Windows file servers
- Native Windows file system with SMB protocol support
- Optimized for enterprise Windows workloads
- Sub-millisecond latencies and enterprise performance

**Key Features for User Profiles**:
- **Native Windows Compatibility**: Full support for Windows file system features
- **Active Directory Integration**: Seamless integration with AWS Directory Service or self-managed AD
- **SMB Protocol Support**: SMB 2.0 to 3.1.1 for Windows file sharing
- **High Availability**: Single-AZ and Multi-AZ deployment options
- **Automatic Backups**: Daily automated backups with VSS consistency
- **Encryption**: Automatic encryption at rest (AWS KMS) and in transit (SMB Kerberos)


**Use Cases for Roaming Profiles**:
- **Home Directories**: Centralized storage for user home directories
- **Roaming Profiles**: Store Windows roaming profile data
- **FSLogix Profile Containers**: Compatible with FSLogix for VDI environments
- **Folder Redirection**: Redirect user folders (Documents, Desktop) to FSx

**Access Methods**:
- Amazon EC2 instances (Windows and Linux)
- Amazon WorkSpaces
- Amazon AppStream 2.0
- VMware Cloud on AWS
- On-premises via AWS Direct Connect or Site-to-Site VPN
- Cross-VPC, cross-account, cross-Region via VPC peering or transit gateways

**Performance and Scalability**:
- Configurable storage capacity (32 GiB to 64 TiB)
- Configurable throughput capacity (8 MBps to 2,048 MBps)
- Configurable SSD IOPS for performance optimization
- Automatic scaling as needs change

**Security and Compliance**:
- Windows Access Control Lists (ACLs) for file/folder permissions
- VPC security groups for network-level access control
- IAM policies for API-level access control
- Microsoft Active Directory authentication
- ISO, PCI-DSS, SOC certifications
- HIPAA eligible

#### 3.2 User Profile Storage Best Practices
**Official Documentation**: [End User Computing Lens - User Profiles](https://docs.aws.amazon.com/wellarchitected/latest/end-user-computing-lens/eucsus07-bp01.html)

Content was rephrased for compliance with licensing restrictions:
- Each user persona may require different storage volume and performance
- Align storage requirements with business case
- Consider profile size, access patterns, and performance needs
- Plan for growth and scalability


#### 3.3 Alternative Storage Options

**Amazon EFS (Elastic File System)**:
- Linux-based file storage
- Not recommended for Windows roaming profiles
- Better suited for Linux home directories

**Amazon S3**:
- Object storage, not file system
- Not suitable for Windows roaming profiles
- Can be used for profile backups or archival

**Recommendation**: Amazon FSx for Windows File Server is the AWS-recommended solution for storing Windows roaming profiles, home directories, and FSLogix profile containers.

---

## Question 4: Monitoring Products

### Amazon CloudWatch - Primary Monitoring Service

**Official Documentation**: [What is Amazon CloudWatch?](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html)

#### 4.1 CloudWatch Overview

**Description** (content rephrased for compliance with licensing restrictions):
- Monitors AWS resources and applications in real time
- Provides system-wide observability of application performance
- Tracks operational health and resource utilization
- Comprehensive monitoring and logging platform


#### 4.2 CloudWatch Core Features

**1. Metrics and Alarms**:
- Collect and track key performance data at user-defined intervals
- Many AWS services automatically report metrics
- Custom metrics from applications
- Alarms continuously monitor metrics against thresholds
- Automated actions triggered by alarm state changes

**2. Dashboards**:
- Unified view of resources and applications
- Visualizations of metrics and logs in single location
- Share dashboards across accounts and Regions
- Curated automatic dashboards for AWS services

**3. Application Performance Monitoring (APM)**:
- **Application Signals**: Automatically detect and monitor key performance indicators (latency, error rates, request rates)
- **CloudWatch Synthetics**: Proactive endpoint and API monitoring with canaries
- **CloudWatch RUM**: Real user monitoring for performance data from actual user sessions
- **Service Level Objectives (SLOs)**: Define, track, and alert on reliability targets

**4. Infrastructure Monitoring**:
- **Database Insights**: Monitor database performance metrics in real time
- **Lambda Insights**: System-level metrics for Lambda functions (memory, CPU, cold starts)
- **Container Insights**: Metrics from containerized applications (ECS, EKS, Kubernetes)

**5. Log Management**:
- **CloudWatch Logs**: Collect, store, and query logs from AWS services and applications
- **Log Groups and Streams**: Organized log storage
- **CloudWatch Logs Insights**: Interactive queries with SQL, PPL, or CloudWatch query language
- **Log Outlier Detection**: Find unusual patterns indicating issues
- **Metric Filters**: Extract numerical values from logs to generate metrics
- **Subscription Filters**: Real-time log processing and routing to S3 or Firehose


**6. CloudWatch Agent**:
- Collect detailed system metrics from EC2 instances and on-premises servers
- Monitor processes, CPU, memory, disk usage, network performance
- Collect and monitor custom application metrics
- Aggregate logs from multiple sources
- Support for Windows and Linux
- GPU metrics collection
- Integration with Systems Manager for centralized configuration

**7. Cross-Account Monitoring**:
- Central monitoring account for multiple AWS accounts
- View metrics, logs, and traces from source accounts
- Create cross-account dashboards
- Set up alarms watching metrics from multiple accounts
- Root-cause analysis across accounts

**8. Network and Internet Monitoring**:
- Monitor network performance and connectivity
- Internet Monitor for application availability
- VPC Flow Logs integration

#### 4.3 Additional AWS Monitoring Services

**AWS CloudTrail**:
- API call logging and auditing
- Governance, compliance, and operational auditing
- Track user activity and API usage

**AWS Config**:
- Resource configuration tracking
- Configuration change history
- Compliance monitoring against desired configurations

**AWS X-Ray**:
- Distributed tracing for applications
- Analyze and debug production applications
- Identify performance bottlenecks

**Amazon EventBridge**:
- Event-driven architecture monitoring
- Route events between AWS services
- Custom application event monitoring

**AWS Systems Manager**:
- Operational insights and automation
- Fleet management and compliance
- Patch management monitoring


#### 4.4 Monitoring Best Practices

**Official Documentation**: [Designing and Implementing Logging and Monitoring](https://docs.aws.amazon.com/prescriptive-guidance/latest/implementing-logging-monitoring-cloudwatch/welcome.html)

Content was rephrased for compliance with licensing restrictions:
- Collect metrics for latency, throughput, and error rates
- Capture data for each resource
- Implement comprehensive logging strategy
- Use CloudWatch for centralized monitoring
- Set up alarms for critical metrics
- Create dashboards for operational visibility
- Enable cross-account monitoring for multi-account environments

---

## Question 5: VDI Image Storage

### AWS Services for Virtual Desktop Infrastructure

#### 5.1 Amazon WorkSpaces
**Official Documentation**: [Amazon WorkSpaces Bundles and Images](https://docs.aws.amazon.com/workspaces/latest/adminguide/amazon-workspaces-bundles.html)

**Description** (content rephrased for compliance with licensing restrictions):
- Fully managed virtual desktop service
- Provision cloud-based Windows or Linux desktops
- Eliminates need for on-premises VDI infrastructure


#### 5.2 WorkSpaces Image Storage

**Bundle Components**:
- **WorkSpace Bundle**: Combination of operating system, storage, compute, and software resources
- **Public Bundles**: Default bundles provided by AWS
- **Custom Images**: Created from customized WorkSpaces (OS, software, settings only)
- **Custom Bundles**: Combination of custom image and hardware configuration

**Image Storage Architecture**:
- Custom images stored in AWS-managed storage (not directly visible to customers)
- Images contain OS, software, and settings
- Hardware configuration (compute, storage) selected when creating bundle
- Images used to launch new WorkSpaces with consistent configuration

**Supported Operating Systems**:
- Windows Server 2016, 2019, 2022
- Windows 10 (BYOL)
- Windows 11 (BYOL)
- Amazon Linux 2
- Ubuntu 22.04 LTS
- Rocky Linux 8
- Red Hat Enterprise Linux 8

**Streaming Protocols**:
- DCV (NICE DCV)
- PCoIP (PC-over-IP)

**Bundle Types**:
- Value, Standard, Performance
- Power, PowerPro
- GraphicsPro, Graphics G4dn, Graphics G6
- GeneralPurpose


#### 5.3 WorkSpaces Image Management

**Creating Custom Images**:
1. Launch a WorkSpace with desired configuration
2. Customize software, settings, and applications
3. Create custom image from the WorkSpace
4. Build custom bundle combining image and hardware specs
5. Launch new WorkSpaces from custom bundle

**Updating Custom Bundles**:
- Perform software updates on source WorkSpace
- Create new custom image
- Update custom bundle
- Rebuild WorkSpaces with updated bundle

**Image Operations**:
- **Copy Images**: Copy custom images across AWS Regions
- **Share Images**: Share custom images with other AWS accounts
- **Delete Images**: Remove unused custom images and bundles

#### 5.4 Amazon WorkSpaces Applications (formerly AppStream 2.0)
**Official Documentation**: [Import Image - WorkSpaces Applications](https://docs.aws.amazon.com/appstream2/latest/developerguide/import-image.html)

**Description** (content rephrased for compliance with licensing restrictions):
- Application streaming service
- Import customized EC2 AMIs to create WorkSpaces Applications images
- Use Image Builder to customize applications
- Images stored as Amazon Machine Images (AMIs)

**Image Storage**:
- Based on Amazon EC2 AMIs
- Stored in Amazon EBS snapshots
- Can import custom AMIs with prerequisites
- Supports various stream instance types


#### 5.5 Amazon WorkSpaces Core
**Official Documentation**: [Amazon WorkSpaces Core](https://docs.aws.amazon.com/workspaces-core/latest/pg/intro.html)

**Description** (content rephrased for compliance with licensing restrictions):
- Enables third-party VDI solution providers to build custom desktop solutions
- Managed virtual desktop infrastructure platform
- Flexible and customizable desktop solutions

#### 5.6 VDI Image Storage Summary

**Where VDI Images Are Stored**:

1. **Amazon WorkSpaces**:
   - Custom images stored in AWS-managed storage (internal to WorkSpaces service)
   - Not directly accessible as AMIs or EBS snapshots
   - Managed through WorkSpaces console/API
   - Regional storage (images are Region-specific)

2. **Amazon WorkSpaces Applications (AppStream 2.0)**:
   - Images stored as Amazon Machine Images (AMIs)
   - AMIs backed by Amazon EBS snapshots
   - Accessible through EC2 AMI management
   - Can be copied across Regions

3. **Self-Managed VDI on EC2**:
   - Images stored as Amazon Machine Images (AMIs)
   - AMIs stored in Amazon EBS snapshots
   - Full control over image lifecycle
   - Can use EC2 Image Builder for automation

**Storage Locations**:
- **Amazon EBS Snapshots**: Underlying storage for AMIs
- **AWS-Managed Storage**: For WorkSpaces custom images (abstracted from users)
- **Amazon S3**: For image exports and backups (optional)


**Key Differences**:

| Aspect | Amazon WorkSpaces | WorkSpaces Applications | Self-Managed EC2 VDI |
|--------|------------------|------------------------|---------------------|
| Image Storage | AWS-managed (internal) | AMIs + EBS Snapshots | AMIs + EBS Snapshots |
| Direct Access | No (via WorkSpaces API) | Yes (via EC2 API) | Yes (via EC2 API) |
| Management | Fully managed | Fully managed | Self-managed |
| Customization | Limited to WorkSpaces | Application streaming | Full control |
| Use Case | Persistent desktops | Application delivery | Custom VDI solutions |

---

## Summary and Recommendations

### Key Findings from AWS Official Documentation

**1. Migration Automation**:
- AWS provides comprehensive migration automation through Application Migration Service, Database Migration Service, DataSync, and Transform
- Migration Hub provides centralized tracking and orchestration
- Highly automated lift-and-shift capabilities minimize manual effort

**2. Zero Trust Security**:
- AWS Verified Access provides native Zero Trust Network Access (ZTNA)
- IAM Identity Center serves as centralized identity and access management
- Comprehensive Zero Trust architecture requires multiple AWS services working together
- AWS Prescriptive Guidance provides detailed Zero Trust implementation framework

**3. Roaming Profiles**:
- Amazon FSx for Windows File Server is the recommended solution for Windows roaming profiles
- Native Windows compatibility with SMB protocol and Active Directory integration
- Supports home directories, roaming profiles, and FSLogix profile containers
- High availability and enterprise-grade performance


**4. Monitoring**:
- Amazon CloudWatch is the primary monitoring service for AWS
- Comprehensive capabilities: metrics, logs, alarms, dashboards, APM, infrastructure monitoring
- CloudWatch Agent extends monitoring to EC2 and on-premises servers
- Additional services (CloudTrail, Config, X-Ray) provide specialized monitoring

**5. VDI Image Storage**:
- Amazon WorkSpaces stores custom images in AWS-managed storage (internal to service)
- WorkSpaces Applications uses AMIs backed by EBS snapshots
- Self-managed VDI on EC2 uses standard AMIs and EBS snapshots
- Storage location depends on VDI solution chosen

### Implementation Recommendations

**For Migration Projects**:
1. Start with AWS Application Migration Service for server migrations
2. Use AWS Database Migration Service for database migrations
3. Leverage AWS DataSync for large-scale data transfers
4. Track progress centrally with AWS Migration Hub
5. Consider AWS Transform for AI-assisted migration automation

**For Zero Trust Implementation**:
1. Deploy AWS Verified Access for application access without VPN
2. Implement IAM Identity Center for centralized identity management
3. Enable MFA for all users
4. Use AWS Security Hub for centralized security monitoring
5. Follow AWS Prescriptive Guidance for phased Zero Trust adoption

**For User Profile Storage**:
1. Deploy Amazon FSx for Windows File Server for roaming profiles
2. Configure Multi-AZ deployment for high availability
3. Integrate with AWS Managed Microsoft AD or self-managed AD
4. Implement automated backups with appropriate retention
5. Size storage and throughput based on user count and profile sizes


**For Monitoring Implementation**:
1. Enable CloudWatch for all AWS resources
2. Deploy CloudWatch Agent on EC2 instances for detailed metrics
3. Create custom dashboards for operational visibility
4. Configure alarms for critical metrics with SNS notifications
5. Enable CloudWatch Logs for centralized log management
6. Implement cross-account monitoring for multi-account environments
7. Use CloudWatch Synthetics for proactive endpoint monitoring

**For VDI Deployment**:
1. Use Amazon WorkSpaces for managed persistent virtual desktops
2. Create custom images with required software and configurations
3. Build custom bundles for consistent WorkSpace deployments
4. Implement WorkSpaces Applications for application streaming needs
5. Store user data on Amazon FSx for Windows File Server
6. Enable Multi-AZ WorkSpaces for high availability requirements

---

## References

All information in this report is sourced from official AWS documentation. Content was rephrased for compliance with licensing restrictions.

### Primary Documentation Sources

1. **Migration Services**:
   - [AWS Application Migration Service](https://docs.aws.amazon.com/mgn/latest/ug/what-is-application-migration-service.html)
   - [AWS Database Migration Service](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_GettingStarted.html)
   - [AWS DataSync](https://docs.aws.amazon.com/datasync/latest/userguide/getting-started.html)
   - [Choosing AWS Migration Services](https://docs.aws.amazon.com/decision-guides/latest/migration-on-aws-how-to-choose/migration-on-aws-how-to-choose.html)

2. **Zero Trust Security**:
   - [AWS Verified Access](https://docs.aws.amazon.com/verified-access/latest/ug/how-it-works.html)
   - [IAM Identity Center](https://docs.aws.amazon.com/singlesignon/latest/userguide/what-is.html)
   - [Zero Trust Architecture Components](https://docs.aws.amazon.com/prescriptive-guidance/latest/strategy-zero-trust-architecture/components.html)


3. **User Profile Storage**:
   - [Amazon FSx for Windows File Server](https://docs.aws.amazon.com/fsx/latest/WindowsGuide/what-is.html)
   - [End User Computing Lens - User Profiles](https://docs.aws.amazon.com/wellarchitected/latest/end-user-computing-lens/eucsus07-bp01.html)

4. **Monitoring**:
   - [Amazon CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html)
   - [CloudWatch Agent](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Install-CloudWatch-Agent.html)
   - [Implementing Logging and Monitoring](https://docs.aws.amazon.com/prescriptive-guidance/latest/implementing-logging-monitoring-cloudwatch/welcome.html)

5. **VDI Services**:
   - [Amazon WorkSpaces](https://docs.aws.amazon.com/workspaces/latest/adminguide/amazon-workspaces.html)
   - [WorkSpaces Bundles and Images](https://docs.aws.amazon.com/workspaces/latest/adminguide/amazon-workspaces-bundles.html)
   - [WorkSpaces Applications](https://docs.aws.amazon.com/appstream2/latest/developerguide/import-image.html)

### Additional Resources

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS Prescriptive Guidance](https://aws.amazon.com/prescriptive-guidance/)
- [AWS Migration Hub](https://aws.amazon.com/migration-hub/)
- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)

---

**Report Prepared By**: Kiro AI Assistant  
**Date**: February 12, 2026  
**Version**: 1.0  
**Classification**: Internal Use

**Note**: This report contains information rephrased from AWS official documentation to comply with licensing restrictions. All technical details are accurate as of the report date. For the most current information, please refer to the official AWS documentation links provided.
