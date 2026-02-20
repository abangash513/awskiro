# WAC Production Domain Controller & Active Directory - Complete Documentation

**Document Version:** 2.0  
**Last Updated:** February 6, 2026  
**Environment:** PRODUCTION  
**Classification:** HIGHLY CONFIDENTIAL  
**Prepared By:** Arif Bangash-Consultant

---

## 📋 Table of Contents

1. [Executive Summary](#executive-summary)
2. [Infrastructure Overview](#infrastructure-overview)
3. [Network Architecture](#network-architecture)
4. [Domain Controllers](#domain-controllers)
5. [Security Configuration](#security-configuration)
6. [VPN Client Access](#vpn-client-access)
7. [Active Directory Configuration](#active-directory-configuration)
8. [Monitoring & Alerting](#monitoring--alerting)
9. [Operational Procedures](#operational-procedures)
10. [Disaster Recovery](#disaster-recovery)
11. [Troubleshooting Guide](#troubleshooting-guide)
12. [Configuration Files](#configuration-files)
13. [Scripts & Automation](#scripts--automation)
14. [Compliance & Security](#compliance--security)
15. [Support & Contacts](#support--contacts)

---

## Executive Summary

### Project Status
- **Status:** Phase 1 Complete - AWS DCs Operational
- **Start Date:** November 23, 2025
- **Completion Date:** November 24, 2025 (Phase 1)
- **Environment:** Production
- **AWS Account:** 466090007609 (WACPROD)
- **Region:** us-west-2

### Key Achievements
✅ **High Availability:** 2 AWS DCs across different Availability Zones  
✅ **Zero Downtime:** All deployments with no user impact  
✅ **Replication Health:** 0 failures across all 10 DCs  
✅ **Network Connectivity:** VPN and Transit Gateway operational  
✅ **Security:** Encrypted volumes, termination protection enabled  

### Current State
- **Total Domain Controllers:** 10 (2 AWS + 8 On-Premises)
- **Domain:** WAC.NET
- **Forest Functional Level:** Windows Server 2008 (3)
- **Domain Functional Level:** Windows Server 2008 (3)


---

## Infrastructure Overview

### AWS Infrastructure Components

| Component | Details | Purpose |
|-----------|---------|---------|
| **VPC** | vpc-014b66d7ca2309134 | Production VPC (10.70.0.0/16) |
| **Subnets** | MAD-2a: subnet-05241411b9228d65f (10.70.10.0/24)<br>MAD-2b: subnet-0c6eec3752dd3e665 (10.70.11.0/24) | Domain Controller subnets across 2 AZs |
| **Security Group** | sg-0b0bd0839e63d3075 | WAC-Prod-ADMT-Enhanced-SG |
| **IAM Profile** | WAC-Prod-ADMT-Enhanced-Profile | SSM and CloudWatch access |
| **Transit Gateway** | tgw-0c147b016ed157991 | Connects AWS to On-Premises |
| **VPN Connection** | vpn-025a12d4214e767b7 | Site-to-Site VPN (1 tunnel UP: 44.252.167.140) |
| **Key Pair** | AWSProdKey | EC2 instance access |

### AWS Domain Controllers

| Name | Instance ID | IP Address | AZ | Subnet | Status |
|------|-------------|------------|-----|--------|--------|
| **WACPRODDC01** | i-0745579f46a34da2e | 10.70.10.10 | us-west-2a | MAD-2a | ✅ Operational |
| **WACPRODDC02** | i-08c78db5cfc6eb412 | 10.70.11.10 | us-west-2b | MAD-2b | ✅ Operational |

**Instance Configuration:**
- **Instance Type:** m5.large
- **Operating System:** Windows Server 2019 Datacenter
- **Root Volume:** 100 GB gp3 (Encrypted)
- **AMI:** ami-0948bfde6d7c1b495
- **Termination Protection:** Enabled
- **Global Catalog:** Yes
- **DNS Server:** Yes
- **Read-Only:** No

### On-Premises Domain Controllers

| Name | IP Address | OS Version | Status | Notes |
|------|------------|------------|--------|-------|
| **AD01** | 10.1.220.8 | Server 2008 R2 | ⚠️ To Decommission | Holds FSMO roles |
| **AD02** | 10.1.220.9 | Server 2008 R2 | ⚠️ To Decommission | Holds FSMO roles |
| **W09MVMPADDC01** | 10.1.220.20 | Server 2012 R2 | ⚠️ To Decommission | Older OS |
| **W09MVMPADDC02** | 10.1.220.21 | Server 2016 | ✅ Keep | Modern OS |
| **WACHFDC01** | 10.1.220.5 | Server 2019 | ✅ Keep | Primary on-prem DC |
| **WACHFDC02** | 10.1.220.6 | Server 2019 | ✅ Keep | Secondary on-prem DC |
| **WAC-DC01** | 10.1.220.205 | Server 2022 | ✅ Keep | Latest OS |
| **WAC-DC02** | 10.1.220.206 | Server 2022 | ✅ Keep | Latest OS |


---

## Network Architecture

### Network Topology

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS Cloud (us-west-2)                     │
│                     Account: 466090007609                        │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Prod-VPC (10.70.0.0/16)                       │ │
│  │                                                             │ │
│  │  ┌──────────────────────┐    ┌──────────────────────┐    │ │
│  │  │   MAD-2a Subnet      │    │   MAD-2b Subnet      │    │ │
│  │  │   10.70.10.0/24      │    │   10.70.11.0/24      │    │ │
│  │  │   (us-west-2a)       │    │   (us-west-2b)       │    │ │
│  │  │                      │    │                      │    │ │
│  │  │  ┌────────────────┐ │    │  ┌────────────────┐ │    │ │
│  │  │  │ WACPRODDC01    │ │    │  │ WACPRODDC02    │ │    │ │
│  │  │  │ 10.70.10.10    │ │    │  │ 10.70.11.10    │ │    │ │
│  │  │  │ i-0745579f...  │ │    │  │ i-08c78db5...  │ │    │ │
│  │  │  └────────────────┘ │    │  └────────────────┘ │    │ │
│  │  └──────────────────────┘    └──────────────────────┘    │ │
│  │                                                             │ │
│  │  ┌──────────────────────┐    ┌──────────────────────┐    │ │
│  │  │   Private-2a         │    │   Private-2b         │    │ │
│  │  │   10.70.20.0/24      │    │   10.70.21.0/24      │    │ │
│  │  └──────────────────────┘    └──────────────────────┘    │ │
│  │                                                             │ │
│  └─────────────────────────┬───────────────────────────────────┘ │
│                            │                                     │
│                   ┌────────▼────────┐                           │
│                   │ Transit Gateway │                           │
│                   │ tgw-0c147b0...  │                           │
│                   └────────┬────────┘                           │
│                            │                                     │
└────────────────────────────┼─────────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │   Site-to-Site  │
                    │   VPN Connection│
                    │ vpn-025a12d4... │
                    │ Tunnel: UP      │
                    │ 44.252.167.140  │
                    └────────┬────────┘
                             │
┌────────────────────────────┼─────────────────────────────────────┐
│                            │                                     │
│                   On-Premises Network                            │
│                      10.1.0.0/16                                 │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              Domain Controllers                           │  │
│  │                                                            │  │
│  │  AD01 (10.1.220.8)          WACHFDC01 (10.1.220.5)       │  │
│  │  AD02 (10.1.220.9)          WACHFDC02 (10.1.220.6)       │  │
│  │  W09MVMPADDC01 (10.1.220.20) WAC-DC01 (10.1.220.205)     │  │
│  │  W09MVMPADDC02 (10.1.220.21) WAC-DC02 (10.1.220.206)     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

### Network Routing

| Source | Destination | Route | Purpose |
|--------|-------------|-------|---------|
| AWS VPC | On-Premises | 10.1.0.0/16 → TGW → VPN | Access on-prem DCs |
| On-Premises | AWS VPC | 10.70.0.0/16 → VPN → TGW | Access AWS DCs |
| VPN Clients | AWS VPC | 10.70.0.0/16 → Client VPN | Remote admin access |

### DNS Configuration

**AWS Domain Controllers:**
- Primary DNS: 10.1.220.5 (WACHFDC01)
- Secondary DNS: 10.1.220.6 (WACHFDC02)
- VPC DNS: 10.70.0.2 (AWS provided)

**DNS Zones:**
- Forward Lookup: WAC.NET
- Reverse Lookup: 10.70.10.0/24, 10.70.11.0/24, 10.1.220.0/24


---

## Domain Controllers

### WACPRODDC01 (Primary AWS DC)

**Instance Details:**
- **Instance ID:** i-0745579f46a34da2e
- **Private IP:** 10.70.10.10
- **Availability Zone:** us-west-2a
- **Subnet:** subnet-05241411b9228d65f (MAD-2a)
- **Instance Type:** m5.large (2 vCPU, 8 GB RAM)
- **Operating System:** Windows Server 2019 Datacenter
- **Hostname:** WACPRODDC01.WAC.NET

**Deployment Details:**
- **Deployed:** November 23, 2025 20:27:31 UTC
- **Replication Source:** WACHFDC01.wac.net
- **Promotion Time:** ~35 minutes
- **CloudFormation Stack:** WACPRODDC01-Stack

**Roles:**
- Global Catalog Server: Yes
- DNS Server: Yes
- Read-Only: No
- FSMO Roles: None (planned to hold all 5)

**Storage:**
- Root Volume (C:): 100 GB gp3, Encrypted
- Delete on Termination: No
- Termination Protection: Enabled

**Security:**
- Security Group: sg-0b0bd0839e63d3075
- IAM Instance Profile: WAC-Prod-ADMT-Enhanced-Profile
- Key Pair: AWSProdKey

### WACPRODDC02 (Secondary AWS DC)

**Instance Details:**
- **Instance ID:** i-08c78db5cfc6eb412
- **Private IP:** 10.70.11.10
- **Availability Zone:** us-west-2b
- **Subnet:** subnet-0c6eec3752dd3e665 (MAD-2b)
- **Instance Type:** m5.large (2 vCPU, 8 GB RAM)
- **Operating System:** Windows Server 2019 Datacenter
- **Hostname:** WACPRODDC02.WAC.NET

**Deployment Details:**
- **Deployed:** November 24, 2025 00:31:52 UTC
- **Replication Source:** WACHFDC01.wac.net
- **Promotion Time:** ~19 minutes
- **CloudFormation Stack:** WACPRODDC02-Stack

**Roles:**
- Global Catalog Server: Yes
- DNS Server: Yes
- Read-Only: No
- FSMO Roles: None (replica)

**Storage:**
- Root Volume (C:): 100 GB gp3, Encrypted
- Delete on Termination: No
- Termination Protection: Enabled

**Security:**
- Security Group: sg-0b0bd0839e63d3075
- IAM Instance Profile: WAC-Prod-ADMT-Enhanced-Profile
- Key Pair: AWSProdKey

### High Availability Configuration

**Multi-AZ Deployment:**
- WACPRODDC01 in us-west-2a
- WACPRODDC02 in us-west-2b
- Automatic failover capability
- Load balanced across AZs

**Replication Status:**
- Source Replication: 0 failures
- Destination Replication: 0 failures
- Replication Latency: 2-5 minutes (normal)
- Last Replication: Real-time


---

## Security Configuration

### Security Group Rules (sg-0b0bd0839e63d3075)

**Inbound Rules:**

| Protocol | Port | Source | Purpose |
|----------|------|--------|---------|
| TCP | 53 | 10.70.0.0/16, 10.1.0.0/16 | DNS |
| UDP | 53 | 10.70.0.0/16, 10.1.0.0/16 | DNS |
| TCP | 88 | 10.70.0.0/16, 10.1.0.0/16 | Kerberos |
| UDP | 88 | 10.70.0.0/16, 10.1.0.0/16 | Kerberos |
| TCP | 135 | 10.70.0.0/16, 10.1.0.0/16 | RPC Endpoint Mapper |
| TCP | 139 | 10.70.0.0/16, 10.1.0.0/16 | NetBIOS Session |
| TCP | 389 | 10.70.0.0/16, 10.1.0.0/16 | LDAP |
| UDP | 389 | 10.70.0.0/16, 10.1.0.0/16 | LDAP |
| TCP | 445 | 10.70.0.0/16, 10.1.0.0/16 | SMB/CIFS |
| TCP | 464 | 10.70.0.0/16, 10.1.0.0/16 | Kerberos Password Change |
| UDP | 464 | 10.70.0.0/16, 10.1.0.0/16 | Kerberos Password Change |
| TCP | 636 | 10.70.0.0/16, 10.1.0.0/16 | LDAPS (Secure LDAP) |
| TCP | 3268 | 10.70.0.0/16, 10.1.0.0/16 | Global Catalog |
| TCP | 3269 | 10.70.0.0/16, 10.1.0.0/16 | Global Catalog SSL |
| TCP | 3389 | 10.200.0.0/16 | RDP (VPN clients only) |
| TCP | 49152-65535 | 10.70.0.0/16, 10.1.0.0/16 | RPC Dynamic Ports |
| ICMP | All | 10.70.0.0/16, 10.1.0.0/16 | Ping/Network Diagnostics |

**Outbound Rules:**
- All traffic allowed (0.0.0.0/0)

### IAM Role Configuration

**Role Name:** WAC-Prod-ADMT-Enhanced-Role  
**Instance Profile:** WAC-Prod-ADMT-Enhanced-Profile

**Attached Policies:**
1. **AmazonSSMManagedInstanceCore** - Systems Manager access
2. **CloudWatchAgentServerPolicy** - CloudWatch metrics and logs
3. **AmazonEC2ReadOnlyAccess** - EC2 metadata access

**Trust Relationship:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

### Encryption

**EBS Volumes:**
- Encryption: Enabled (AWS managed keys)
- Volume Type: gp3
- Delete on Termination: No
- Snapshots: Encrypted

**Network Traffic:**
- VPN: IPSec encryption
- LDAPS: TLS 1.2+
- RDP: TLS 1.2+
- Kerberos: AES256

### Access Control

**RDP Access:**
- Restricted to VPN clients (10.200.0.0/16)
- Requires domain credentials
- MFA recommended

**Systems Manager Access:**
- IAM-based authentication
- Session logging enabled
- Audit trail in CloudTrail

**Domain Admin Credentials:**
- Username: WAC\Administrator
- Password: W@Cmore4the$0897 (stored in AWS Secrets Manager recommended)
- DSRM Password: W@Cmore4the$0897


---

## VPN Client Access

### Production Client VPN Configuration

**VPN Endpoint Details:**
- **Endpoint ID:** (To be deployed)
- **Client CIDR:** 10.200.0.0/16
- **VPC:** vpc-014b66d7ca2309134 (10.70.0.0/16)
- **DNS Server:** 10.70.0.2
- **Protocol:** OpenVPN over UDP
- **Port:** 443
- **Split Tunnel:** Enabled
- **Session Timeout:** 24 hours

**Associated Subnets:**
- Private-2a: subnet-02c8f0d7d48510db0 (10.70.20.0/24)
- Private-2b: subnet-02582cf0ad3fa857b (10.70.21.0/24)

### Certificate Configuration

**Server Certificate:**
- **ARN:** arn:aws:acm:us-west-2:466090007609:certificate/fc6b385c-1d75-49de-91a2-93fae977030a
- **Common Name:** server.wac-vpn.local
- **Subject:** C=US, ST=California, L=SanFrancisco, O=WAC, OU=IT, CN=server.wac-vpn.local
- **Valid From:** January 19, 2026
- **Valid Until:** January 17, 2036 (10 years)
- **Key Algorithm:** RSA-2048
- **Signature:** SHA256withRSA

**Client Certificate:**
- **ARN:** arn:aws:acm:us-west-2:466090007609:certificate/e3437609-1535-4ed7-b6e8-dceb076f67df
- **Common Name:** client1.wac-vpn.local
- **Subject:** C=US, ST=California, L=SanFrancisco, O=WAC, OU=IT, CN=client1.wac-vpn.local
- **Valid From:** January 19, 2026
- **Valid Until:** January 17, 2036 (10 years)
- **Key Algorithm:** RSA-2048
- **Signature:** SHA256withRSA

**Certificate Directory:** vpn-certs-prod-20260119-220611/

### VPN Client Setup

**Prerequisites:**
- AWS VPN Client installed
- VPN configuration file (wac-prod-admin-vpn.ovpn)
- Authorized for Production access
- Training completed

**Installation Steps:**
1. Download AWS VPN Client from https://aws.amazon.com/vpn/client-vpn-download/
2. Install AWS VPN Client
3. Import wac-prod-admin-vpn.ovpn
4. Connect to "WAC Prod Admin VPN"
5. Verify IP in 10.200.0.0/16 range
6. Test RDP to Domain Controllers

**Connection Testing:**
```powershell
# Verify VPN IP
ipconfig | Select-String "10.200"

# Test connectivity to DCs
Test-NetConnection -ComputerName 10.70.10.10 -Port 3389
Test-NetConnection -ComputerName 10.70.11.10 -Port 3389

# Test DNS resolution
nslookup wacproddc01.wac.local 10.70.0.2
nslookup wac.local 10.70.0.2

# Test RDP
mstsc /v:10.70.10.10
```

### CloudWatch Logging

**Log Group:** /aws/clientvpn/prod-admin-vpn  
**Retention:** 180 days  
**Logged Events:**
- Connection attempts
- Authentication success/failure
- Disconnections
- Data transfer statistics

### Security Policies

**Access Requirements:**
- Monthly access reviews (vs quarterly for Dev)
- Management approval required
- Company-managed devices only
- Full disk encryption required
- Security training completed

**Usage Policies:**
- VPN must be disconnected when not in use
- No sharing of VPN configuration files
- Report any suspicious activity immediately
- Follow change management procedures
- All access is logged and audited


---

## Active Directory Configuration

### Domain Information

**Domain Details:**
- **Domain Name:** WAC.NET
- **NetBIOS Name:** WAC
- **Domain SID:** S-1-5-21-515967899-963894560-725345543
- **Forest Name:** WAC.NET
- **Forest Functional Level:** Windows Server 2008 (3)
- **Domain Functional Level:** Windows Server 2008 (3)

**Object Counts:**
- Users: 829
- Groups: 546
- Computers: 1,100
- Group Policy Objects: 124

### FSMO Roles (Current State)

| Role | Current Holder | Target Holder (Planned) |
|------|----------------|-------------------------|
| **Schema Master** | AD01.WAC.NET | WACPRODDC01.WAC.NET |
| **Domain Naming Master** | AD01.WAC.NET | WACPRODDC01.WAC.NET |
| **PDC Emulator** | AD01.WAC.NET | WACPRODDC01.WAC.NET |
| **RID Master** | AD02.WAC.NET | WACPRODDC01.WAC.NET |
| **Infrastructure Master** | AD02.WAC.NET | WACPRODDC01.WAC.NET |

**FSMO Migration Status:** Pending (planned for Phase 2)

### Sites and Services

**Sites:**
- Default-First-Site-Name (all DCs currently in this site)

**Site Links:**
- DEFAULTIPSITELINK (cost: 100, replication interval: 180 minutes)

**Subnets:**
- 10.1.220.0/24 (On-Premises)
- 10.70.10.0/24 (AWS MAD-2a)
- 10.70.11.0/24 (AWS MAD-2b)

### Replication Topology

**Replication Partners (WACPRODDC01):**

**Inbound Replication:**
- AD01: 0 failures
- AD02: 0 failures
- W09MVMPADDC01: 0 failures
- W09MVMPADDC02: 0 failures
- WAC-DC01: 0 failures
- WAC-DC02: 0 failures
- WACHFDC01: 0 failures
- WACHFDC02: 0 failures

**Outbound Replication:**
- All DCs: 0 failures

**Replication Metrics:**
- Average Latency: 2-5 minutes
- Replication Frequency: Every 15 seconds (intra-site)
- Last Successful Replication: Real-time
- Replication Queue: 0 items

### DNS Configuration

**DNS Zones:**

**Forward Lookup Zones:**
- WAC.NET (Primary, AD-Integrated)
- _msdcs.WAC.NET (Primary, AD-Integrated)

**Reverse Lookup Zones:**
- 10.in-addr.arpa (Primary, AD-Integrated)
- 220.1.10.in-addr.arpa (Primary, AD-Integrated)
- 10.70.10.in-addr.arpa (Primary, AD-Integrated)
- 11.70.10.in-addr.arpa (Primary, AD-Integrated)

**DNS Forwarders:**
- 8.8.8.8 (Google DNS)
- 8.8.4.4 (Google DNS)

**DNS Records (AWS DCs):**
```
WACPRODDC01.WAC.NET    A    10.70.10.10
WACPRODDC02.WAC.NET    A    10.70.11.10
```

### Group Policy

**Default GPOs:**
- Default Domain Policy
- Default Domain Controllers Policy

**Custom GPOs:** 122 (application-specific, security policies, etc.)

**GPO Replication:**
- SYSVOL Path: \\WAC.NET\SYSVOL\WAC.NET\Policies
- Replication Method: DFS-R
- Replication Status: Healthy


---

## Monitoring & Alerting

### CloudWatch Alarms

**Instance Status Alarms:**
- WACPRODDC01-StatusCheck: Alerts if instance status check fails
- WACPRODDC02-StatusCheck: Alerts if instance status check fails

**Performance Alarms:**
- WACPRODDC01-HighCPU: Alerts if CPU > 70% for 10 minutes
- WACPRODDC02-HighCPU: Alerts if CPU > 70% for 10 minutes
- WACPRODDC01-HighMemory: Alerts if Memory > 70% for 10 minutes
- WACPRODDC02-HighMemory: Alerts if Memory > 70% for 10 minutes

**Notification Method:**
- SNS Topic: WAC-Prod-DC-Alerts
- Email notifications
- SMS notifications (optional)

### CloudWatch Agent Configuration

**Metrics Collected:**
- CPU Utilization (per core and total)
- Memory Utilization (used, available, committed)
- Disk Utilization (C: drive usage and I/O)
- Network Utilization (bytes in/out, packets)

**Logs Collected:**
- System Event Log (Errors and Warnings)
- Directory Service Event Log (All events)
- DNS Server Event Log (Errors and Warnings)
- Application Event Log (Errors)

**Collection Interval:** 60 seconds  
**Log Retention:** 180 days

### Active Directory Health Monitoring

**Scheduled Task:** WAC-AD-Health-Monitor  
**Frequency:** Every 5 minutes  
**Script:** ad-health-monitor.ps1

**Monitored Services:**
- NTDS (Active Directory Domain Services)
- DNS Server
- Netlogon
- KDC (Kerberos Key Distribution Center)
- W32Time (Time Synchronization)

**Replication Monitoring:**
- Replication errors between DCs
- Replication partner status
- Last successful replication time (alerts if > 60 min)
- Replication queue depth (alerts if > 50 items)

**Additional Checks:**
- SYSVOL share accessibility
- DNS resolution for domain
- Event log errors (last 24 hours)
- Disk space (alerts if < 20% free)

**Alert Delivery:**
- CloudWatch Logs: /aws/ad-health-monitor
- SNS Topic: WAC-Prod-DC-Alerts
- Email and SMS notifications

### Daily Health Check

**Script:** Health-Check.ps1  
**Frequency:** Daily (manual or scheduled)  
**Report Location:** C:\Logs\HealthCheck-YYYYMMDD.txt

**Checks Performed:**
1. FSMO role holders verification
2. Domain controller inventory
3. Replication summary
4. Replication failures detection
5. DC diagnostics (replication test)
6. Event log errors (last 24 hours)
7. AWS DC status verification
8. Network connectivity tests
9. Time synchronization status

### Cost Monitoring

**Monthly Estimated Costs:**
- EC2 Instances (2 × m5.large): ~$140/month
- EBS Volumes (2 × 100 GB gp3): ~$20/month
- Data Transfer: ~$10/month
- CloudWatch: ~$5/month
- VPN Endpoint: ~$150/month
- **Total:** ~$325/month


---

## Operational Procedures

### Daily Operations

**Morning Checks (Every Day):**
```powershell
# Run daily health check
cd C:\Logs
.\Health-Check.ps1

# Review report
Get-Content C:\Logs\HealthCheck-$(Get-Date -Format yyyyMMdd).txt

# Check CloudWatch alarms
aws cloudwatch describe-alarms --state-value ALARM --region us-west-2
```

**Monitoring Tasks:**
- Review CloudWatch alarms
- Check replication status
- Verify no event log errors
- Monitor disk space
- Check VPN connectivity

### Weekly Operations

**Every Monday:**
- Review CloudWatch metrics for past week
- Check for Windows updates
- Verify backup completion
- Review access logs
- Test failover procedures (monthly)

**Tasks:**
```powershell
# Check Windows updates
Get-WindowsUpdate

# Verify backups
aws ec2 describe-snapshots --owner-ids 466090007609 --region us-west-2

# Review replication health
repadmin /replsummary
repadmin /showrepl
```

### Monthly Operations

**First Monday of Month:**
- Review and update documentation
- Conduct access review
- Test disaster recovery procedures
- Review and optimize costs
- Update security patches

**Tasks:**
- Review IAM access
- Audit VPN connections
- Review CloudWatch logs
- Test backup restoration
- Update runbooks

### FSMO Role Migration (Planned)

**Timeline:** 2 days  
**Impact:** Minimal to none  
**Prerequisites:**
- AWS DCs stable for 2+ weeks
- VPN both tunnels UP
- Backups completed
- Team on standby

**Migration Order:**
1. Infrastructure Master (Hour 2)
2. RID Master (Hour 3)
3. Domain Naming Master (Hour 4)
4. Schema Master (Hour 5)
5. PDC Emulator (Hour 6) - CRITICAL

**Migration Script:**
```powershell
# Run FSMO migration script
cd C:\Scripts
.\FSMO-Migration.ps1 -TargetDC WACPRODDC01

# Verify migration
netdom query fsmo
repadmin /replsummary
```

**Post-Migration:**
- Monitor for 1 hour
- Check event logs
- Verify authentication
- Test applications
- Document completion

### Domain Controller Decommissioning (Planned)

**DCs to Decommission:**
1. AD01 (Server 2008 R2)
2. AD02 (Server 2008 R2)
3. W09MVMPADDC01 (Server 2012 R2)

**Decommissioning Process:**
```powershell
# On DC to decommission
Uninstall-ADDSDomainController -LocalAdministratorPassword (ConvertTo-SecureString "TempPass123!" -AsPlainText -Force) -Force

# After reboot, clean metadata on remaining DC
ntdsutil
metadata cleanup
connections
connect to server WACPRODDC01
quit
select operation target
list domains
select domain 0
list sites
select site 0
list servers in site
select server X  # Server to remove
quit
remove selected server
quit
quit
```

**Post-Decommissioning:**
- Verify DC removed from AD
- Check replication health
- Update DNS records
- Remove from monitoring
- Power off (keep for 7 days)
- Final deletion after 7 days


---

## Disaster Recovery

### Backup Strategy

**EC2 Instance Backups:**
- **Method:** AWS Backup or EBS Snapshots
- **Frequency:** Daily
- **Retention:** 30 days
- **Backup Window:** 2:00 AM - 4:00 AM UTC

**System State Backups:**
- **Method:** Windows Server Backup
- **Frequency:** Daily
- **Location:** S3 bucket (encrypted)
- **Retention:** 14 days

**Active Directory Backups:**
- **Method:** System State includes AD database
- **Frequency:** Daily
- **Verification:** Weekly restore test

### Recovery Procedures

**Scenario 1: Single DC Failure**

**If WACPRODDC01 fails:**
1. WACPRODDC02 automatically handles all requests
2. Users experience no downtime
3. Restore WACPRODDC01 from latest snapshot
4. Verify replication after restoration

**Recovery Steps:**
```powershell
# Stop failed instance
aws ec2 stop-instances --instance-ids i-0745579f46a34da2e --region us-west-2

# Create AMI from latest snapshot
aws ec2 create-image --instance-id i-0745579f46a34da2e --name "WACPRODDC01-Recovery-$(Get-Date -Format yyyyMMdd)" --region us-west-2

# Launch new instance from AMI
# Verify replication
repadmin /replsummary
```

**Scenario 2: Both AWS DCs Fail**

**If both AWS DCs fail:**
1. On-premises DCs continue to serve users
2. Restore both AWS DCs from snapshots
3. Verify replication after restoration
4. Check FSMO roles if migrated

**Recovery Time Objective (RTO):** 2 hours  
**Recovery Point Objective (RPO):** 24 hours

**Scenario 3: Complete AWS Region Failure**

**If entire us-west-2 region fails:**
1. On-premises DCs handle all operations
2. No immediate action required
3. Wait for AWS region recovery
4. Restore AWS DCs when region available
5. Verify replication and FSMO roles

**RTO:** 4-8 hours  
**RPO:** 24 hours

**Scenario 4: VPN Failure**

**If VPN connection fails:**
1. AWS DCs cannot replicate with on-prem
2. On-prem users unaffected
3. AWS workloads may experience authentication delays
4. Restore VPN connection immediately

**Mitigation:**
- Maintain second VPN tunnel (currently 1 UP)
- Configure Direct Connect as backup
- Monitor VPN status continuously

### Authoritative Restore

**When to use:** Accidental deletion of AD objects

**Process:**
```powershell
# Boot DC into Directory Services Restore Mode (DSRM)
# Restore System State from backup
wbadmin start systemstaterecovery -version:XX/XX/XXXX-XX:XX -backupTarget:D:

# Mark objects as authoritative
ntdsutil
activate instance ntds
authoritative restore
restore subtree "OU=DeletedOU,DC=wac,DC=local"
quit
quit

# Reboot and verify
```

### Tombstone Reanimation

**Recover deleted objects (within tombstone lifetime):**
```powershell
# Enable AD Recycle Bin (if not already enabled)
Enable-ADOptionalFeature -Identity "Recycle Bin Feature" -Scope ForestOrConfigurationSet -Target "wac.local"

# Restore deleted object
Get-ADObject -Filter {DisplayName -eq "DeletedUser"} -IncludeDeletedObjects | Restore-ADObject
```

### Disaster Recovery Testing

**Frequency:** Quarterly  
**Test Scenarios:**
1. Single DC failure and recovery
2. Snapshot restoration
3. FSMO role seizure
4. VPN failover
5. Authoritative restore

**Test Documentation:** Maintain test results in C:\DR-Tests\


---

## Troubleshooting Guide

### Common Issues and Solutions

#### Issue 1: Replication Failures

**Symptoms:**
- repadmin /replsummary shows failures
- Event ID 2042 in Directory Service log
- Objects not replicating between DCs

**Diagnosis:**
```powershell
# Check replication status
repadmin /replsummary
repadmin /showrepl
Get-ADReplicationFailure -Target * -Scope Domain

# Check replication partners
repadmin /showreps WACPRODDC01
```

**Solutions:**
```powershell
# Force replication
repadmin /syncall /AdeP

# Rebuild replication topology
repadmin /kcc

# Check network connectivity
Test-NetConnection -ComputerName 10.1.220.5 -Port 389

# Verify DNS resolution
nslookup wachfdc01.wac.local
```

#### Issue 2: VPN Connection Failure

**Symptoms:**
- Cannot connect to AWS DCs from on-prem
- Replication failures between AWS and on-prem
- VPN tunnel status DOWN

**Diagnosis:**
```powershell
# Check VPN status
aws ec2 describe-vpn-connections --vpn-connection-ids vpn-025a12d4214e767b7 --region us-west-2

# Check Transit Gateway attachments
aws ec2 describe-transit-gateway-attachments --region us-west-2

# Test connectivity
Test-NetConnection -ComputerName 10.70.10.10 -Port 389
```

**Solutions:**
1. Verify VPN tunnel configuration
2. Check on-premises firewall rules
3. Verify Transit Gateway routes
4. Contact network team if persistent

#### Issue 3: Authentication Failures

**Symptoms:**
- Users cannot log in
- "Domain controller unavailable" errors
- Kerberos authentication failures

**Diagnosis:**
```powershell
# Check DC availability
nltest /dsgetdc:wac.net

# Check Kerberos
klist tickets

# Check time sync
w32tm /query /status
w32tm /stripchart /computer:WACPRODDC01

# Check DNS
nslookup wac.local
nslookup _ldap._tcp.wac.local
```

**Solutions:**
```powershell
# Force time sync
w32tm /resync /rediscover

# Clear Kerberos tickets
klist purge

# Verify DNS records
nslookup wacproddc01.wac.local

# Test authentication
Test-ComputerSecureChannel -Server WACPRODDC01
```

#### Issue 4: High CPU or Memory Usage

**Symptoms:**
- CloudWatch alarm triggered
- DC performance degraded
- Slow authentication

**Diagnosis:**
```powershell
# Check processes
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10

# Check AD database size
Get-ChildItem "C:\Windows\NTDS\ntds.dit"

# Check event logs
Get-EventLog -LogName "Directory Service" -Newest 50 -EntryType Error
```

**Solutions:**
1. Identify resource-intensive processes
2. Check for AD database fragmentation
3. Consider offline defragmentation
4. Upgrade instance type if needed

#### Issue 5: SYSVOL Replication Issues

**Symptoms:**
- Group Policy not applying
- SYSVOL share inaccessible
- Event ID 13508 or 13509

**Diagnosis:**
```powershell
# Check SYSVOL share
Test-Path \\wac.net\SYSVOL

# Check DFS-R status
dfsrdiag replicationstate

# Check event logs
Get-EventLog -LogName "DFS Replication" -Newest 50
```

**Solutions:**
```powershell
# Force SYSVOL replication
dfsrdiag pollad

# Restart DFS Replication service
Restart-Service DFSR

# Verify SYSVOL share permissions
Get-SmbShare SYSVOL
```

#### Issue 6: DNS Resolution Problems

**Symptoms:**
- Cannot resolve domain names
- DC discovery failures
- Application connectivity issues

**Diagnosis:**
```powershell
# Test DNS resolution
nslookup wac.local 10.70.0.2
nslookup wacproddc01.wac.local

# Check DNS server status
Get-Service DNS

# Check DNS zones
Get-DnsServerZone
```

**Solutions:**
```powershell
# Restart DNS service
Restart-Service DNS

# Clear DNS cache
Clear-DnsServerCache

# Verify DNS forwarders
Get-DnsServerForwarder

# Re-register DNS records
ipconfig /registerdns
```

### Emergency Contacts

**Critical Issues (24/7):**
- AWS Support: [AWS Support Portal]
- On-Call Administrator: [Phone]
- Security Team: [Phone]

**Business Hours:**
- AD Team: [Email/Phone]
- Network Team: [Email/Phone]
- AWS Administrator: [Email/Phone]


---

## Configuration Files

### CloudFormation Templates

#### WACPRODDC01 CloudFormation Template

**File:** WACPRODDC01-CloudFormation.json  
**Purpose:** Deploy WACPRODDC01 EC2 instance with AD DS prerequisites

**Key Parameters:**
- VpcId: vpc-014b66d7ca2309134
- SubnetIdAD: subnet-05241411b9228d65f (MAD-2a)
- AmiId: ami-0948bfde6d7c1b495 (Windows Server 2019)
- InstanceType: m5.large
- StaticPrivateIp: 10.70.10.10
- KeyName: AWSProdKey
- SecurityGroupId: sg-0b0bd0839e63d3075
- IamInstanceProfileName: WAC-Prod-ADMT-Enhanced-Profile

**UserData Script Actions:**
1. Rename computer to WACPRODDC01
2. Configure DNS client (10.1.220.5, 10.1.220.6)
3. Install AD DS role and management tools
4. Install AWS CLI v2
5. Create build status file
6. Reboot

**Outputs:**
- InstanceId: i-0745579f46a34da2e
- PrivateIp: 10.70.10.10
- AvailabilityZone: us-west-2a

#### WACPRODDC02 CloudFormation Template

**File:** WACPRODDC02-CloudFormation.json  
**Purpose:** Deploy WACPRODDC02 EC2 instance with AD DS prerequisites

**Key Parameters:**
- VpcId: vpc-014b66d7ca2309134
- SubnetIdAD: subnet-0c6eec3752dd3e665 (MAD-2b)
- AmiId: ami-0948bfde6d7c1b495 (Windows Server 2019)
- InstanceType: m5.large
- StaticPrivateIp: 10.70.11.10
- KeyName: AWSProdKey
- SecurityGroupId: sg-0b0bd0839e63d3075
- IamInstanceProfileName: WAC-Prod-ADMT-Enhanced-Profile

**Outputs:**
- InstanceId: i-08c78db5cfc6eb412
- PrivateIp: 10.70.11.10
- AvailabilityZone: us-west-2b

### CloudWatch Agent Configuration

**File:** cloudwatch-agent-config.json  
**Location:** C:\AWSKiro\cloudwatch-agent-config.json (on DCs)

**Metrics Collected:**
```json
{
  "metrics": {
    "namespace": "WAC/DomainControllers",
    "metrics_collected": {
      "Processor": {
        "measurement": [
          {"name": "% Processor Time", "rename": "CPUUtilization", "unit": "Percent"}
        ],
        "metrics_collection_interval": 60
      },
      "Memory": {
        "measurement": [
          {"name": "% Committed Bytes In Use", "rename": "MemoryUtilization", "unit": "Percent"}
        ],
        "metrics_collection_interval": 60
      },
      "LogicalDisk": {
        "measurement": [
          {"name": "% Free Space", "rename": "DiskFreeSpace", "unit": "Percent"}
        ],
        "metrics_collection_interval": 60,
        "resources": ["C:"]
      }
    }
  },
  "logs": {
    "logs_collected": {
      "windows_events": {
        "collect_list": [
          {
            "event_name": "System",
            "event_levels": ["ERROR", "WARNING"],
            "log_group_name": "/aws/ec2/windows/System",
            "log_stream_name": "{instance_id}"
          },
          {
            "event_name": "Directory Service",
            "event_levels": ["ERROR", "WARNING", "INFORMATION"],
            "log_group_name": "/aws/ec2/windows/DirectoryService",
            "log_stream_name": "{instance_id}"
          },
          {
            "event_name": "DNS Server",
            "event_levels": ["ERROR", "WARNING"],
            "log_group_name": "/aws/ec2/windows/DNS",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  }
}
```

### VPN Configuration

**File:** wac-prod-admin-vpn.ovpn  
**Purpose:** Client VPN configuration for remote administration

**Configuration:**
- Protocol: UDP
- Port: 443
- Cipher: AES-256-GCM
- Split Tunnel: Enabled
- DNS: 10.70.0.2
- Routes: 10.70.0.0/16

**Embedded Certificates:**
- CA Certificate (wac-vpn-ca.local)
- Client Certificate (client1.wac-vpn.local)
- Client Private Key

**Security:**
- TLS 1.2+ required
- Mutual authentication (server + client certificates)
- Renegotiation disabled
- Server verification: verify-x509-name server.wac-vpn.local name


---

## Scripts & Automation

### FSMO Migration Script

**File:** FSMO-Migration.ps1  
**Location:** 03-Projects/WAC-DC-Migration/Scripts/  
**Purpose:** Migrate all 5 FSMO roles to WACPRODDC01

**Usage:**
```powershell
# Dry run (WhatIf mode)
.\FSMO-Migration.ps1 -TargetDC WACPRODDC01 -WhatIf

# Execute migration
.\FSMO-Migration.ps1 -TargetDC WACPRODDC01
```

**Features:**
- Pre-flight checks (FSMO roles, replication, DC health)
- Sequential role migration (least critical to most critical)
- Automatic replication sync after each role
- Post-migration verification
- Comprehensive logging

**Migration Order:**
1. Infrastructure Master
2. RID Master
3. Domain Naming Master
4. Schema Master
5. PDC Emulator (most critical)

**Log Location:** C:\Logs\FSMO-Migration-YYYYMMDDHHMMSS.log

### Health Check Script

**File:** Health-Check.ps1  
**Location:** 03-Projects/WAC-DC-Migration/Scripts/  
**Purpose:** Daily health check for AD environment

**Usage:**
```powershell
.\Health-Check.ps1
```

**Checks Performed:**
1. FSMO role holders
2. Domain controller inventory
3. Replication summary
4. Replication failures
5. DC diagnostics
6. Event log errors (last 24 hours)
7. AWS DC status
8. Network connectivity
9. Time synchronization

**Output:**
- Console display
- Report file: C:\Logs\HealthCheck-YYYYMMDD.txt
- Summary object returned

**Scheduling:**
```powershell
# Create scheduled task for daily health check
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\Scripts\Health-Check.ps1"
$trigger = New-ScheduledTaskTrigger -Daily -At 8:00AM
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
Register-ScheduledTask -TaskName "WAC-Daily-Health-Check" -Action $action -Trigger $trigger -Principal $principal
```

### AD Health Monitor Script

**File:** ad-health-monitor.ps1  
**Location:** 03-Projects/Monitoring/  
**Purpose:** Continuous AD health monitoring with CloudWatch integration

**Usage:**
```powershell
.\ad-health-monitor.ps1
```

**Monitored Components:**
- Critical services (NTDS, DNS, Netlogon, KDC, W32Time)
- AD replication status
- Replication lag
- Replication queue depth
- SYSVOL share accessibility
- DNS resolution

**Alert Conditions:**
- Any critical service stopped
- Replication failures detected
- Replication lag > 60 minutes
- Replication queue > 50 items
- SYSVOL share inaccessible
- DNS resolution failures

**Integration:**
- Sends metrics to CloudWatch
- Triggers SNS notifications
- Logs to CloudWatch Logs

**Scheduled Task:**
- Task Name: WAC-AD-Health-Monitor
- Frequency: Every 5 minutes
- User: SYSTEM

### CloudWatch Agent Installation Script

**File:** install-cloudwatch-agent.ps1  
**Location:** 03-Projects/Monitoring/  
**Purpose:** Install and configure CloudWatch agent on DCs

**Usage:**
```powershell
.\install-cloudwatch-agent.ps1
```

**Actions:**
1. Download CloudWatch agent installer
2. Install agent silently
3. Copy configuration file
4. Start CloudWatch agent
5. Verify agent status

**Configuration File:** cloudwatch-agent-config.json

### VPN Setup Script

**File:** Setup-Prod-Client-VPN.ps1  
**Location:** Root directory  
**Purpose:** Deploy Client VPN endpoint for Production

**Usage:**
```powershell
.\Setup-Prod-Client-VPN.ps1
```

**Actions:**
1. Create CloudWatch log group
2. Create Client VPN endpoint
3. Wait for endpoint availability
4. Associate with subnets (Private-2a, Private-2b)
5. Add authorization rules
6. Add routes to VPC
7. Generate OVPN configuration file

**Output:**
- VPN Endpoint ID
- OVPN file: wac-prod-admin-vpn.ovpn
- Configuration: prod-vpn-config.json

**Prerequisites:**
- AWS CLI configured
- Certificates imported to ACM
- VPC and subnets exist
- IAM permissions for VPN operations

### Monitoring Setup Script

**File:** wac-monitoring-setup.ps1  
**Location:** 03-Projects/Monitoring/  
**Purpose:** Initial monitoring setup (SNS + CloudWatch alarms)

**Usage:**
```powershell
.\wac-monitoring-setup.ps1
```

**Actions:**
1. Fetch instance IDs for both DCs
2. Create SNS topic: WAC-Prod-DC-Alerts
3. Subscribe email and phone
4. Create CloudWatch alarms:
   - Status check alarms (both DCs)
   - High CPU alarms (both DCs)

**Prompts:**
- Email address for notifications
- Phone number for SMS (format: +12345678900)

### Memory Alarms Script

**File:** add-memory-alarms.ps1  
**Location:** 03-Projects/Monitoring/  
**Purpose:** Add memory utilization alarms after CloudWatch agent installation

**Usage:**
```powershell
.\add-memory-alarms.ps1
```

**Actions:**
- Create memory utilization alarms for both DCs
- Threshold: 70% for 10 minutes
- Notification: WAC-Prod-DC-Alerts SNS topic


---

## Compliance & Security

### Security Best Practices

**Access Control:**
- ✅ Principle of least privilege enforced
- ✅ Separate admin accounts for privileged operations
- ✅ MFA required for Production access (recommended)
- ✅ Regular access reviews (monthly)
- ✅ VPN access restricted to authorized administrators

**Network Security:**
- ✅ Security groups restrict traffic to required ports only
- ✅ VPN encryption (IPSec) for site-to-site connectivity
- ✅ Client VPN with mutual TLS authentication
- ✅ Split tunnel enabled (reduces attack surface)
- ✅ No direct internet access to DCs

**Data Protection:**
- ✅ EBS volumes encrypted at rest
- ✅ Snapshots encrypted
- ✅ LDAPS (port 636) available for secure LDAP
- ✅ Kerberos AES256 encryption
- ✅ TLS 1.2+ for all encrypted connections

**Monitoring & Logging:**
- ✅ CloudWatch logging enabled (180-day retention)
- ✅ VPN connection logging enabled
- ✅ AD health monitoring every 5 minutes
- ✅ Event log collection and analysis
- ✅ CloudTrail enabled for API audit trail

**Backup & Recovery:**
- ✅ Daily EBS snapshots
- ✅ System State backups
- ✅ 30-day retention for snapshots
- ✅ Quarterly DR testing
- ✅ Documented recovery procedures

### Compliance Requirements

**Change Management:**
- All Production changes require approval
- Change requests documented in ticketing system
- Emergency change procedures defined
- Post-implementation review required

**Access Management:**
- Monthly access reviews
- Management approval for new access
- Training requirements enforced
- Access revocation within 24 hours of termination

**Audit Requirements:**
- Quarterly compliance audits
- Annual security assessments
- Penetration testing (annual)
- Vulnerability scanning (monthly)

**Documentation:**
- Architecture diagrams maintained
- Configuration documentation current
- Runbooks updated quarterly
- Incident response procedures documented

### Security Hardening

**Windows Server Hardening:**
- Latest security patches applied
- Unnecessary services disabled
- Windows Firewall enabled
- Local Administrator password unique per DC
- DSRM password complex and unique

**Active Directory Hardening:**
- AdminSDHolder protection enabled
- Protected Users group utilized
- Kerberos AES encryption enforced
- LDAP signing required
- NTLM authentication restricted

**Network Hardening:**
- SMB signing required
- SMB v1 disabled
- RDP NLA (Network Level Authentication) required
- RDP encryption level: High
- Unused protocols disabled

### Incident Response

**Security Incident Procedures:**

**Phase 1: Detection**
- Monitor CloudWatch alarms
- Review security logs daily
- Investigate anomalies immediately

**Phase 2: Containment**
- Isolate affected systems
- Disable compromised accounts
- Block malicious IPs
- Preserve evidence

**Phase 3: Eradication**
- Remove malware/backdoors
- Patch vulnerabilities
- Reset compromised credentials
- Verify system integrity

**Phase 4: Recovery**
- Restore from clean backups
- Verify replication health
- Monitor for re-infection
- Document lessons learned

**Phase 5: Post-Incident**
- Conduct root cause analysis
- Update security controls
- Improve detection capabilities
- Train staff on findings

**Incident Contacts:**
- Security Team: [24/7 Phone]
- Incident Response Team: [Email]
- AWS Support: [Support Portal]
- Management: [Contact Info]

### Vulnerability Management

**Patching Schedule:**
- Critical patches: Within 7 days
- Important patches: Within 30 days
- Moderate patches: Within 90 days
- Testing required before Production deployment

**Vulnerability Scanning:**
- Monthly automated scans
- Quarterly manual assessments
- Remediation tracking
- Exception process for accepted risks

**Security Updates:**
- Windows Update configured for automatic download
- Manual installation during maintenance windows
- Testing in Dev environment first
- Rollback plan prepared


---

## Support & Contacts

### Technical Support

**AWS Infrastructure:**
- AWS Account: 466090007609 (WACPROD)
- Region: us-west-2
- AWS Support: [AWS Support Portal]
- Support Plan: [Business/Enterprise]

**Active Directory:**
- AD Team: [Email/Phone]
- Identity Management: [Email/Phone]
- On-Call Administrator: [24/7 Phone]

**Network:**
- Network Team: [Email/Phone]
- VPN Support: [Email/Phone]
- Firewall Team: [Email/Phone]

**Security:**
- Security Team: [Email/Phone]
- Security Operations Center (SOC): [24/7 Phone]
- Incident Response: [Email/Phone]

### Escalation Path

**Level 1: Initial Response**
- Help Desk: [Phone/Email]
- Response Time: 15 minutes
- Available: 24/7

**Level 2: Technical Support**
- Systems Administrators: [Phone/Email]
- Response Time: 30 minutes
- Available: Business hours + on-call

**Level 3: Senior Engineers**
- Senior AD Administrators: [Phone/Email]
- AWS Solutions Architects: [Phone/Email]
- Response Time: 1 hour
- Available: On-call 24/7

**Level 4: Management**
- IT Manager: [Phone/Email]
- Director of IT: [Phone/Email]
- Response Time: 2 hours
- Available: Business hours + emergency

### Service Level Agreements (SLAs)

**Availability Targets:**
- Domain Controller Availability: 99.9%
- Authentication Services: 99.95%
- Replication: 99.9%
- VPN Availability: 99.5%

**Response Times:**
- Critical (P1): 15 minutes
- High (P2): 1 hour
- Medium (P3): 4 hours
- Low (P4): Next business day

**Resolution Times:**
- Critical (P1): 4 hours
- High (P2): 8 hours
- Medium (P3): 24 hours
- Low (P4): 5 business days

### Documentation Repository

**Location:** 03-Projects/WAC-DC-Migration/

**Key Documents:**
- README.md - Project overview
- PROJECT-SUMMARY.md - Quick reference
- 01-OnPrem-Profile.json - On-prem AD profile
- 06-FSMO-Migration-Plan.md - FSMO migration procedures
- 07-Decommissioning-Plan.md - DC decommissioning procedures
- 08-Cutover-Plan.md - Cutover procedures and expectations

**CloudFormation Templates:**
- WACPRODDC01-CloudFormation.json
- WACPRODDC02-CloudFormation.json

**Scripts:**
- FSMO-Migration.ps1
- Health-Check.ps1
- ad-health-monitor.ps1
- install-cloudwatch-agent.ps1
- Setup-Prod-Client-VPN.ps1

**Reports:**
- WACPRODDC01-SUCCESS-REPORT.txt
- WACPRODDC02-SUCCESS-REPORT.txt
- OnPrem-Health-Status.txt

### Training Resources

**Required Training:**
- Active Directory Administration Fundamentals
- AWS EC2 and VPC Fundamentals
- Security Best Practices for Production
- Incident Response Procedures
- Change Management Procedures

**Recommended Training:**
- Advanced Active Directory Troubleshooting
- AWS Solutions Architect Associate
- PowerShell for AD Administration
- Disaster Recovery Planning
- CloudWatch Monitoring and Alerting

**Training Providers:**
- Microsoft Learn (Active Directory)
- AWS Training and Certification
- Internal training programs
- Third-party vendors

### Knowledge Base Articles

**Common Procedures:**
- KB001: How to Connect to AWS Domain Controllers
- KB002: VPN Client Setup and Troubleshooting
- KB003: Active Directory Health Check Procedures
- KB004: Replication Troubleshooting Guide
- KB005: FSMO Role Management
- KB006: Backup and Restore Procedures
- KB007: Emergency Access Procedures
- KB008: Performance Tuning Guidelines

**Troubleshooting Guides:**
- TG001: Replication Failures
- TG002: Authentication Issues
- TG003: VPN Connectivity Problems
- TG004: DNS Resolution Issues
- TG005: High CPU/Memory Usage
- TG006: SYSVOL Replication Problems

### Change Log

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-11-23 | 1.0 | Initial deployment of WACPRODDC01 | Arif Bangash |
| 2025-11-24 | 1.1 | Deployment of WACPRODDC02 | Arif Bangash |
| 2026-01-19 | 1.2 | VPN certificates generated | Arif Bangash |
| 2026-01-31 | 1.3 | VPN client package prepared | Arif Bangash |
| 2026-02-06 | 2.0 | Complete documentation created | Arif Bangash |

### Review Schedule

**Documentation Review:**
- Monthly: Verify accuracy of operational procedures
- Quarterly: Update configuration details
- Annually: Comprehensive review and update

**Next Review Date:** May 6, 2026

---

## Appendices

### Appendix A: Port Reference

**Active Directory Ports:**
| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 53 | TCP/UDP | DNS | Name resolution |
| 88 | TCP/UDP | Kerberos | Authentication |
| 135 | TCP | RPC Endpoint Mapper | RPC services |
| 139 | TCP | NetBIOS Session | File sharing |
| 389 | TCP/UDP | LDAP | Directory queries |
| 445 | TCP | SMB | File sharing, SYSVOL |
| 464 | TCP/UDP | Kerberos Password | Password changes |
| 636 | TCP | LDAPS | Secure LDAP |
| 3268 | TCP | Global Catalog | GC queries |
| 3269 | TCP | Global Catalog SSL | Secure GC queries |
| 3389 | TCP | RDP | Remote desktop |
| 49152-65535 | TCP | RPC Dynamic | Dynamic RPC |

### Appendix B: Event ID Reference

**Critical Event IDs:**
| Event ID | Source | Severity | Description |
|----------|--------|----------|-------------|
| 2042 | NTDS Replication | Error | Replication has not occurred |
| 1311 | NTDS KCC | Warning | Replication configuration failed |
| 1388 | NTDS Replication | Error | Replication error |
| 1925 | NTDS KCC | Warning | Failed to establish replication link |
| 2087 | NTDS Replication | Error | DNS lookup failure |
| 5805 | NETLOGON | Warning | Session setup failed |
| 5722 | NETLOGON | Error | Session setup failed (no trust) |

### Appendix C: PowerShell Quick Reference

**Common AD Commands:**
```powershell
# Get domain info
Get-ADDomain -Server 10.70.10.10

# Get all DCs
Get-ADDomainController -Filter * -Server 10.70.10.10

# Check FSMO roles
netdom query fsmo

# Check replication
repadmin /replsummary
repadmin /showrepl

# Force replication
repadmin /syncall /AdeP

# Get replication failures
Get-ADReplicationFailure -Target * -Scope Domain

# Check DC health
dcdiag /v /c /e

# Test authentication
Test-ComputerSecureChannel -Server WACPRODDC01

# Check time sync
w32tm /query /status
```

### Appendix D: AWS CLI Quick Reference

**Common AWS Commands:**
```powershell
# Describe instances
aws ec2 describe-instances --instance-ids i-0745579f46a34da2e --region us-west-2

# Check VPN status
aws ec2 describe-vpn-connections --vpn-connection-ids vpn-025a12d4214e767b7 --region us-west-2

# List CloudWatch alarms
aws cloudwatch describe-alarms --region us-west-2

# Get CloudWatch metrics
aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name CPUUtilization --dimensions Name=InstanceId,Value=i-0745579f46a34da2e --start-time 2026-02-06T00:00:00Z --end-time 2026-02-06T23:59:59Z --period 3600 --statistics Average --region us-west-2

# Create snapshot
aws ec2 create-snapshot --volume-id vol-XXXXXXXXX --description "Manual backup" --region us-west-2

# Start SSM session
aws ssm start-session --target i-0745579f46a34da2e --region us-west-2
```

---

## Document Information

**Document Title:** WAC Production Domain Controller & Active Directory - Complete Documentation  
**Document Version:** 2.0  
**Classification:** HIGHLY CONFIDENTIAL  
**Last Updated:** February 6, 2026  
**Next Review:** May 6, 2026  
**Prepared By:** Arif Bangash-Consultant  
**Approved By:** [Approval Required]

**Distribution List:**
- IT Management
- Active Directory Team
- AWS Administrators
- Security Team
- Network Team

**Document Control:**
- This document contains sensitive Production infrastructure information
- Distribution restricted to authorized personnel only
- Do not share outside the organization
- Report any unauthorized access immediately

---

**⚠️ PRODUCTION ENVIRONMENT - HANDLE WITH EXTREME CARE ⚠️**

**END OF DOCUMENTATION**

