# Production Environment - Three-Phase Admin Access Solution
## On-Premises to AWS Production Connectivity

**Date**: January 20, 2026  
**Account**: AWS_Production (466090007609)  
**Region**: us-west-2  
**VPC**: vpc-014b66d7ca2309134 (Prod-VPC, 10.70.0.0/16)

---

## 🎯 Overview

This document provides an end-to-end solution for secure admin access to AWS Production environment from on-premises, mirroring the successful Dev implementation.

---

## 📊 Production Environment Details

### VPC Configuration
- **VPC ID**: vpc-014b66d7ca2309134
- **VPC Name**: Prod-VPC
- **CIDR**: 10.70.0.0/16

### Subnets
| Subnet ID | AZ | CIDR | Name | Purpose |
|-----------|----|----|------|---------|
| subnet-02c8f0d7d48510db0 | us-west-2a | 10.70.1.0/24 | Private-2a | **Domain Controllers (DC/AD)** |
| subnet-02582cf0ad3fa857b | us-west-2b | 10.70.3.0/24 | Private-2b | **Domain Controllers (DC/AD)** |
| subnet-05241411b9228d65f | us-west-2a | 10.70.10.0/24 | MAD-2a | Managed AD (not used) |
| subnet-0c6eec3752dd3e665 | us-west-2b | 10.70.11.0/24 | MAD-2b | Managed AD (not used) |
| subnet-0e00d16d934c67c04 | us-west-2a | 10.70.0.0/24 | Public-2a | Public resources |
| subnet-08b138fe9b8fb1560 | us-west-2b | 10.70.2.0/24 | Public-2b | Public resources |

### Key Differences from Dev
- ⚠️ Production uses **self-managed Domain Controllers** in Private-2a and Private-2b subnets
- ⚠️ MAD subnets exist but are NOT used for DC/AD
- ✅ Higher security requirements
- ✅ MFA should be enforced
- ✅ More stringent audit logging

---

## 🏗️ Three-Phase Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     ADMIN ACCESS METHODS                        │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│   PHASE 1        │  │   PHASE 2        │  │   PHASE 3        │
│   Site-to-Site   │  │   SSM Session    │  │   Client VPN     │
│   VPN            │  │   Manager        │  │   (Remote)       │
│                  │  │                  │  │                  │
│   Office → AWS   │  │   Browser/CLI    │  │   Anywhere → AWS │
│   $36/month      │  │   ~$5/month      │  │   ~$76-135/month │
└──────────────────┘  └──────────────────┘  └──────────────────┘
         │                     │                      │
         └─────────────────────┼──────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Prod-VPC (10.70.0.0/16)                        │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Private-2a (10.70.1.0/24)  Private-2b (10.70.3.0/24)   │  │
│  │                                                          │  │
│  │  Self-Managed Domain Controllers                        │  │
│  │  - DC/AD (Customer Managed)                             │  │
│  │  - High Availability (2 AZs)                            │  │
│  │  - Connected to On-Premises via Site-to-Site VPN        │  │
│  │                                                          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📋 Phase 1: Site-to-Site VPN (Office to AWS)

### Purpose
Connect on-premises office network to AWS Production VPC for primary admin access.

### Status
**To Be Implemented** (or verify if already exists)

### Implementation Steps

#### Step 1: Check for Existing VPN
```powershell
# Check for existing VPN connections
aws ec2 describe-vpn-connections --region us-west-2 --query 'VpnConnections[*].[VpnConnectionId,State,Type,Tags[?Key==`Name`].Value|[0]]' --output table

# Check for Virtual Private Gateway
aws ec2 describe-vpn-gateways --region us-west-2 --filters "Name=attachment.vpc-id,Values=vpc-014b66d7ca2309134" --query 'VpnGateways[*].[VpnGatewayId,State,Type]' --output table
```

#### Step 2: Create Virtual Private Gateway (if needed)
```powershell
# Create VGW
aws ec2 create-vpn-gateway --type ipsec.1 --amazon-side-asn 64512 --region us-west-2 --tag-specifications 'ResourceType=vpn-gateway,Tags=[{Key=Name,Value=Prod-VGW},{Key=Environment,Value=Production}]'

# Attach to VPC
aws ec2 attach-vpn-gateway --vpn-gateway-id vgw-xxxxx --vpc-id vpc-014b66d7ca2309134 --region us-west-2
```

#### Step 3: Create Customer Gateway
```powershell
# Replace with your on-premises public IP
$onPremPublicIP = "YOUR_OFFICE_PUBLIC_IP"

aws ec2 create-customer-gateway --type ipsec.1 --public-ip $onPremPublicIP --bgp-asn 65000 --region us-west-2 --tag-specifications 'ResourceType=customer-gateway,Tags=[{Key=Name,Value=OnPrem-CGW},{Key=Environment,Value=Production}]'
```

#### Step 4: Create VPN Connection
```powershell
aws ec2 create-vpn-connection --type ipsec.1 --customer-gateway-id cgw-xxxxx --vpn-gateway-id vgw-xxxxx --region us-west-2 --options TunnelOptions=[{PreSharedKey=YOUR_SECURE_PSK}] --tag-specifications 'ResourceType=vpn-connection,Tags=[{Key=Name,Value=Prod-S2S-VPN},{Key=Environment,Value=Production}]'
```

#### Step 5: Update Route Tables
```powershell
# Get route table IDs
aws ec2 describe-route-tables --region us-west-2 --filters "Name=vpc-id,Values=vpc-014b66d7ca2309134" --query 'RouteTables[*].[RouteTableId,Tags[?Key==`Name`].Value|[0]]' --output table

# Add route to on-premises network (example: 192.168.0.0/16)
aws ec2 create-route --route-table-id rtb-xxxxx --destination-cidr-block 192.168.0.0/16 --gateway-id vgw-xxxxx --region us-west-2
```

### Cost
- **$36/month** (fixed)

### Security Considerations
- ✅ Use strong pre-shared keys (minimum 32 characters)
- ✅ Enable BGP for dynamic routing
- ✅ Configure redundant tunnels
- ✅ Monitor tunnel status with CloudWatch

---

## 📋 Phase 2: AWS Systems Manager (SSM) Session Manager

### Purpose
Browser-based and CLI access to EC2 instances without requiring VPN connection.

### Status
**Ready to Implement**

### Implementation Script

I'll create an automated script for this...

### Key Differences from Dev
- ✅ Stricter IAM policies (MFA required)
- ✅ Session recording mandatory
- ✅ Longer log retention (180 days vs 90 days)
- ✅ Encryption at rest for session logs

### Cost
- **~$5-10/month** (depending on usage)

---

## 📋 Phase 3: AWS Client VPN (Remote Access)

### Purpose
Secure remote access for admins from anywhere (home, travel, etc.)

### Status
**Ready to Implement**

### Configuration
- **VPN Client CIDR**: 10.200.0.0/16 (different from Dev: 10.100.0.0/16)
- **Target Subnets**: Private-2a (subnet-02c8f0d7d48510db0), Private-2b (subnet-02582cf0ad3fa857b)
- **Authentication**: Certificate-based + MFA (recommended)
- **DNS**: 10.70.0.2 (AWS-provided DNS)
- **Target Resources**: Domain Controllers in Private subnets

### Enhanced Security for Production
1. **MFA Required**: Integrate with SAML/Active Directory
2. **Certificate Rotation**: 90-day rotation policy
3. **Connection Limits**: Max 10 concurrent connections
4. **IP Whitelisting**: Restrict to known IP ranges (optional)
5. **Session Timeout**: 8-hour maximum session
6. **Audit Logging**: All connections logged to CloudWatch + S3

### Cost
- **~$76-135/month** (depending on usage)

---

## 🔒 Production Security Enhancements

### 1. Multi-Factor Authentication (MFA)
```powershell
# Require MFA for all SSM sessions
# Add to IAM policy:
{
  "Condition": {
    "BoolIfExists": {
      "aws:MultiFactorAuthPresent": "true"
    }
  }
}
```

### 2. Enhanced Logging
```powershell
# Create S3 bucket for long-term log storage
aws s3api create-bucket --bucket wac-prod-access-logs-466090007609 --region us-west-2 --create-bucket-configuration LocationConstraint=us-west-2

# Enable versioning
aws s3api put-bucket-versioning --bucket wac-prod-access-logs-466090007609 --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption --bucket wac-prod-access-logs-466090007609 --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

### 3. CloudWatch Alarms
```powershell
# Alert on failed VPN connections
aws cloudwatch put-metric-alarm --alarm-name "Prod-VPN-Failed-Connections" --alarm-description "Alert on failed VPN connection attempts" --metric-name "ConnectionAttempts" --namespace "AWS/ClientVPN" --statistic Sum --period 300 --threshold 3 --comparison-operator GreaterThanThreshold --evaluation-periods 1 --region us-west-2

# Alert on SSM session failures
aws cloudwatch put-metric-alarm --alarm-name "Prod-SSM-Failed-Sessions" --alarm-description "Alert on failed SSM sessions" --metric-name "SessionsFailed" --namespace "AWS/SSM" --statistic Sum --period 300 --threshold 2 --comparison-operator GreaterThanThreshold --evaluation-periods 1 --region us-west-2
```

### 4. Security Groups
```powershell
# Create security group for VPN clients
aws ec2 create-security-group --group-name prod-vpn-client-sg --description "Security group for production VPN clients" --vpc-id vpc-014b66d7ca2309134 --region us-west-2

# Allow RDP only from VPN CIDR
aws ec2 authorize-security-group-ingress --group-id sg-xxxxx --protocol tcp --port 3389 --cidr 10.200.0.0/16 --region us-west-2

# Allow HTTPS for SSM
aws ec2 authorize-security-group-ingress --group-id sg-xxxxx --protocol tcp --port 443 --cidr 10.70.0.0/16 --region us-west-2
```

---

## 📊 Cost Comparison: Dev vs Production

| Component | Dev Cost | Prod Cost | Notes |
|-----------|----------|-----------|-------|
| **Phase 1: Site-to-Site VPN** | $36/month | $36/month | Same |
| **Phase 2: SSM** | ~$5/month | ~$10/month | More logging |
| **Phase 3: Client VPN** | ~$76-135/month | ~$76-135/month | Same usage |
| **Enhanced Logging** | Included | +$5/month | S3 + longer retention |
| **CloudWatch Alarms** | Basic | +$2/month | More alarms |
| **Total** | **$117-176/month** | **$129-188/month** | +$12/month for enhanced security |

---

## 🚀 Implementation Order

### Recommended Sequence:

**Week 1: Assessment**
1. ✅ Verify existing VPN connections
2. ✅ Document current access methods
3. ✅ Identify security requirements
4. ✅ Get stakeholder approval

**Week 2: Phase 1 (Site-to-Site VPN)**
1. Create/verify Virtual Private Gateway
2. Configure Customer Gateway
3. Establish VPN connection
4. Test connectivity
5. Update route tables

**Week 3: Phase 2 (SSM Session Manager)**
1. Create IAM roles with MFA
2. Set up CloudWatch log groups (180-day retention)
3. Configure S3 bucket for session logs
4. Test SSM access
5. Document procedures

**Week 4: Phase 3 (Client VPN)**
1. Generate certificates with proper extensions
2. Import to ACM
3. Create Client VPN endpoint
4. Configure with MFA
5. Test with pilot group
6. Roll out to all admins

---

## 📝 Next Steps

### Immediate Actions:

1. **Review this document** with your team
2. **Get approval** for production changes
3. **Schedule implementation** windows
4. **Prepare rollback plans**
5. **Notify stakeholders**

### Implementation Scripts:

I'll create automated scripts for:
- ✅ Phase 2 (SSM) implementation
- ✅ Phase 3 (Client VPN) implementation
- ✅ Security group configuration
- ✅ Logging and monitoring setup

---

## 🆘 Support and Documentation

**Production Change Control**:
- All changes require change tickets
- Testing in Dev first (already done!)
- Rollback procedures documented
- Stakeholder notification required

**Documentation Location**:
- Implementation scripts: `C:\AWSKiro\Production\`
- Configuration files: Encrypted storage
- Runbooks: Internal wiki

---

**Ready to proceed with production implementation?**

Let me know which phase you'd like to implement first, and I'll create the detailed implementation scripts!

