# Production Environment - Implementation Guide
## Three-Phase Admin Access Solution

**Date**: January 20, 2026  
**Account**: AWS_Production (466090007609)  
**Region**: us-west-2  
**VPC**: vpc-014b66d7ca2309134 (Prod-VPC, 10.70.0.0/16)

---

## 🎯 Overview

This guide provides step-by-step instructions for implementing the three-phase admin access solution in the Production environment, based on the successful Dev implementation.

**IMPORTANT**: Production uses self-managed Domain Controllers in Private-2a and Private-2b subnets (NOT Managed Active Directory).

---

## 📋 Prerequisites

### Required Access
- AWS Production account credentials (WAC_ProdFullAdmin role)
- Access to AWS Console
- PowerShell with AWS CLI installed
- OpenSSL installed (for Phase 3)

### Required Approvals
- [ ] Change control ticket approved
- [ ] Stakeholder notification sent
- [ ] Rollback plan documented
- [ ] Maintenance window scheduled

---

## 🏗️ Architecture Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                  Production Environment                         │
│                  Account: 466090007609                          │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│   PHASE 1        │  │   PHASE 2        │  │   PHASE 3        │
│   Site-to-Site   │  │   SSM Session    │  │   Client VPN     │
│   VPN            │  │   Manager        │  │   (Remote)       │
│                  │  │                  │  │                  │
│   Office → AWS   │  │   Browser/CLI    │  │   Anywhere → AWS │
│   $36/month      │  │   ~$10/month     │  │   ~$76-135/month │
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
│  │                                                          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📝 Phase 1: Site-to-Site VPN (Office to AWS)

### Status Check

First, verify if Site-to-Site VPN already exists:

```powershell
# Check for existing VPN connections
aws ec2 describe-vpn-connections --region us-west-2 --query 'VpnConnections[*].[VpnConnectionId,State,Type,Tags[?Key==`Name`].Value|[0]]' --output table

# Check for Virtual Private Gateway
aws ec2 describe-vpn-gateways --region us-west-2 --filters "Name=attachment.vpc-id,Values=vpc-014b66d7ca2309134" --query 'VpnGateways[*].[VpnGatewayId,State,Type]' --output table
```

### If VPN Already Exists
- ✅ Document the VPN connection ID
- ✅ Verify connectivity from on-premises
- ✅ Test access to Domain Controllers
- ✅ Move to Phase 2

### If VPN Does Not Exist
Follow the steps in `PRODUCTION-Three-Phase-Solution.md` to create:
1. Virtual Private Gateway
2. Customer Gateway
3. VPN Connection
4. Route table updates

**Estimated Time**: 2-3 hours  
**Cost**: $36/month

---

## 📝 Phase 2: SSM Session Manager

### Implementation

**Script**: `Production-Phase2-SSM-Implementation.ps1`

**What It Creates**:
- IAM Role: `WAC-Prod-DC-SSM-Role`
- Instance Profile: `WAC-Prod-DC-SSM-Profile`
- CloudWatch Log Group: `/aws/ssm/prod-domain-controllers` (180-day retention)
- S3 Bucket: `wac-prod-ssm-session-logs-466090007609`
- Custom policies with MFA requirements

### Steps

1. **Set Production credentials**:
```powershell
# Use your Production credentials
export AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="YOUR_SECRET_KEY"
export AWS_SESSION_TOKEN="YOUR_SESSION_TOKEN"
```

2. **Run the implementation script**:
```powershell
.\Production-Phase2-SSM-Implementation.ps1
```

3. **Attach instance profile to Domain Controllers**:
```powershell
# Get your DC instance IDs
aws ec2 describe-instances --region us-west-2 --filters "Name=vpc-id,Values=vpc-014b66d7ca2309134" "Name=subnet-id,Values=subnet-02c8f0d7d48510db0,subnet-02582cf0ad3fa857b" --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],PrivateIpAddress]' --output table

# Attach profile to each DC
aws ec2 associate-iam-instance-profile --instance-id i-xxxxx --iam-instance-profile Name=WAC-Prod-DC-SSM-Profile --region us-west-2
```

4. **Test SSM access**:
```powershell
# List managed instances
aws ssm describe-instance-information --region us-west-2

# Start a session (from AWS Console or CLI)
aws ssm start-session --target i-xxxxx --region us-west-2
```

**Estimated Time**: 30 minutes  
**Cost**: ~$10/month

---

## 📝 Phase 3: Client VPN (Remote Access)

### Implementation

**Script**: `Production-Phase3-ClientVPN-Implementation.ps1`

**What It Creates**:
- Client VPN Endpoint (targeting Private-2a and Private-2b subnets)
- Server and Client certificates in ACM
- CloudWatch Log Group: `/aws/clientvpn/prod-admin-vpn` (180-day retention)
- VPN client configuration file: `wac-prod-admin-vpn.ovpn`
- Authorization rules for VPC access
- Routes to Domain Controller subnets

### Steps

1. **Verify OpenSSL is installed**:
```powershell
& "C:\Program Files\OpenSSL-Win64\bin\openssl.exe" version
```

2. **Set Production credentials**:
```powershell
# Use your Production credentials
export AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="YOUR_SECRET_KEY"
export AWS_SESSION_TOKEN="YOUR_SESSION_TOKEN"
```

3. **Run the implementation script**:
```powershell
.\Production-Phase3-ClientVPN-Implementation.ps1
```

4. **Secure the certificate files**:
```powershell
# Move to encrypted storage
# The script creates: vpn-certs-prod-TIMESTAMP/
# Contains: CA, server, and client certificates
```

5. **Distribute VPN configuration**:
- File: `wac-prod-admin-vpn.ovpn`
- Distribute securely to authorized admins only
- Never commit to Git or share publicly

6. **Test VPN connection**:
- Download AWS VPN Client: https://aws.amazon.com/vpn/client-vpn-download/
- Import `wac-prod-admin-vpn.ovpn`
- Connect and test access to Domain Controllers

**Estimated Time**: 45 minutes  
**Cost**: ~$76-135/month

---

## 🔒 Production Security Requirements

### MFA Enforcement
- SSM sessions require MFA (configured in IAM policies)
- Consider enabling MFA for Client VPN (requires SAML/AD integration)

### Logging and Monitoring
- CloudWatch log retention: 180 days (vs 90 days in Dev)
- S3 bucket for long-term log storage
- Encryption at rest enabled
- Versioning enabled on S3 buckets

### Access Control
- Restrict VPN access to authorized users only
- Use security groups to limit access from VPN CIDR
- Monitor connection logs regularly
- Review IAM policies quarterly

### Certificate Management
- Rotate certificates every 90 days
- Store certificates in encrypted storage
- Document certificate locations
- Maintain backup copies securely

---

## 📊 Cost Summary

| Component | Monthly Cost | Notes |
|-----------|--------------|-------|
| Phase 1: Site-to-Site VPN | $36 | Fixed cost |
| Phase 2: SSM Session Manager | ~$10 | Based on usage + logs |
| Phase 3: Client VPN Endpoint | $73 | Fixed cost (24/7) |
| Phase 3: Connection Time | $3-30 | $0.05/hour per connection |
| Phase 3: Data Transfer | Variable | $0.09/GB outbound |
| Enhanced Logging (S3) | ~$5 | Storage + requests |
| CloudWatch Alarms | ~$2 | Per alarm |
| **Total** | **$129-188/month** | Depends on usage |

---

## ✅ Implementation Checklist

### Pre-Implementation
- [ ] Change control ticket approved
- [ ] Stakeholder notification sent
- [ ] Maintenance window scheduled
- [ ] Rollback plan documented
- [ ] Production credentials obtained
- [ ] OpenSSL installed and verified

### Phase 1: Site-to-Site VPN
- [ ] Verify existing VPN or create new
- [ ] Test connectivity from on-premises
- [ ] Update route tables
- [ ] Document VPN configuration

### Phase 2: SSM Session Manager
- [ ] Run `Production-Phase2-SSM-Implementation.ps1`
- [ ] Verify IAM role and instance profile created
- [ ] Attach instance profile to Domain Controllers
- [ ] Test SSM access from Console
- [ ] Test SSM access from CLI
- [ ] Verify CloudWatch logs

### Phase 3: Client VPN
- [ ] Run `Production-Phase3-ClientVPN-Implementation.ps1`
- [ ] Verify VPN endpoint created
- [ ] Verify subnets associated (Private-2a, Private-2b)
- [ ] Verify authorization rules
- [ ] Verify routes
- [ ] Secure certificate files
- [ ] Test VPN connection
- [ ] Test access to Domain Controllers
- [ ] Distribute VPN config to authorized users

### Post-Implementation
- [ ] Update documentation
- [ ] Train admin team
- [ ] Set up monitoring alerts
- [ ] Schedule certificate rotation
- [ ] Close change control ticket
- [ ] Conduct post-implementation review

---

## 🆘 Troubleshooting

### Phase 2: SSM Issues

**Problem**: Instance not showing in SSM
- Verify SSM Agent is installed and running
- Check instance profile is attached
- Verify security group allows HTTPS (443) outbound
- Check CloudWatch logs for errors

**Problem**: Cannot start session
- Verify IAM permissions
- Check MFA is configured (if required)
- Verify instance is in "managed" state

### Phase 3: VPN Issues

**Problem**: Cannot connect to VPN
- Verify AWS VPN Client is installed
- Check configuration file imported correctly
- Verify endpoint status is "available"
- Check subnet associations are "associated"

**Problem**: Connected but cannot access VPC
- Verify authorization rules exist
- Check routes are configured
- Verify security groups allow traffic from VPN CIDR (10.200.0.0/16)
- Test DNS resolution: `ping 10.70.0.2`

**Problem**: TLS handshake error
- Verify certificates have proper TLS extensions
- Check server certificate has serverAuth
- Check client certificate has clientAuth
- Regenerate certificates if needed

---

## 📞 Support

**AWS Console**:
- VPC → Client VPN Endpoints
- Systems Manager → Session Manager
- CloudWatch → Log Groups

**Documentation**:
- `PRODUCTION-Three-Phase-Solution.md` - Overview
- `Production-Phase2-SSM-Implementation.ps1` - SSM script
- `Production-Phase3-ClientVPN-Implementation.ps1` - VPN script

**Change Control**:
- All production changes require approval
- Document all changes in change control system
- Notify stakeholders before and after changes

---

## 🎉 Success Criteria

### Phase 1
- [x] Site-to-Site VPN operational (or verified existing)
- [x] On-premises can reach Domain Controllers
- [x] Route tables updated

### Phase 2
- [ ] IAM role and instance profile created
- [ ] Instance profile attached to Domain Controllers
- [ ] SSM sessions working from Console
- [ ] SSM sessions working from CLI
- [ ] CloudWatch logs capturing session data

### Phase 3
- [ ] VPN endpoint created and available
- [ ] Subnets associated (Private-2a, Private-2b)
- [ ] Authorization rules configured
- [ ] Routes configured
- [ ] VPN client configuration generated
- [ ] Test connection successful
- [ ] Can access Domain Controllers via RDP

---

## 📚 Next Steps After Implementation

1. **User Training**
   - Train admin team on SSM access
   - Train admin team on VPN access
   - Document procedures in internal wiki

2. **Monitoring Setup**
   - Configure CloudWatch alarms
   - Set up SNS notifications
   - Create dashboards for visibility

3. **Regular Maintenance**
   - Review access logs weekly
   - Rotate certificates quarterly
   - Update documentation as needed
   - Review costs monthly

4. **Security Audits**
   - Quarterly IAM policy review
   - Annual security assessment
   - Regular penetration testing

---

**Document Version**: 1.0  
**Created**: January 20, 2026  
**Status**: Ready for Implementation  
**Approved By**: [Pending]

---

**Ready to implement? Start with Phase 1 verification, then proceed to Phase 2!**
