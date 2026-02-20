# Production Environment - Quick Reference Card

**Account**: 466090007609 (AWS_Production)  
**Region**: us-west-2  
**VPC**: vpc-014b66d7ca2309134 (10.70.0.0/16)

---

## 🎯 Key Information

### Subnets (Domain Controllers)
- **Private-2a**: subnet-02c8f0d7d48510db0 (10.70.1.0/24, us-west-2a)
- **Private-2b**: subnet-02582cf0ad3fa857b (10.70.3.0/24, us-west-2b)

### Network Configuration
- **VPC CIDR**: 10.70.0.0/16
- **VPN Client CIDR**: 10.200.0.0/16
- **AWS DNS**: 10.70.0.2

---

## 📋 Implementation Scripts

### Phase 2: SSM Session Manager
```powershell
.\Production-Phase2-SSM-Implementation.ps1
```

**Creates**:
- IAM Role: `WAC-Prod-DC-SSM-Role`
- Instance Profile: `WAC-Prod-DC-SSM-Profile`
- Log Group: `/aws/ssm/prod-domain-controllers` (180 days)
- S3 Bucket: `wac-prod-ssm-session-logs-466090007609`

### Phase 3: Client VPN
```powershell
.\Production-Phase3-ClientVPN-Implementation.ps1
```

**Creates**:
- VPN Endpoint (targeting Private-2a, Private-2b)
- Certificates in ACM
- Log Group: `/aws/clientvpn/prod-admin-vpn` (180 days)
- Config File: `wac-prod-admin-vpn.ovpn`

---

## 🔍 Quick Commands

### Check VPN Status
```powershell
aws ec2 describe-client-vpn-endpoints --region us-west-2 --query 'ClientVpnEndpoints[*].[ClientVpnEndpointId,Status.Code,VpcId]' --output table
```

### List SSM Managed Instances
```powershell
aws ssm describe-instance-information --region us-west-2 --query 'InstanceInformationList[*].[InstanceId,PingStatus,PlatformName]' --output table
```

### View VPN Logs
```powershell
aws logs tail /aws/clientvpn/prod-admin-vpn --follow --region us-west-2
```

### View SSM Logs
```powershell
aws logs tail /aws/ssm/prod-domain-controllers --follow --region us-west-2
```

### Attach Instance Profile to DC
```powershell
aws ec2 associate-iam-instance-profile --instance-id i-xxxxx --iam-instance-profile Name=WAC-Prod-DC-SSM-Profile --region us-west-2
```

---

## 💰 Monthly Costs

| Component | Cost |
|-----------|------|
| Site-to-Site VPN | $36 |
| SSM Session Manager | ~$10 |
| Client VPN Endpoint | $73 |
| Client VPN Connections | $3-30 |
| Enhanced Logging | ~$5 |
| CloudWatch Alarms | ~$2 |
| **Total** | **$129-188** |

---

## 🔒 Security Notes

- **Log Retention**: 180 days (Production requirement)
- **MFA**: Required for SSM sessions
- **Encryption**: Enabled on all S3 buckets
- **Certificate Rotation**: Every 90 days
- **Access**: Restricted to authorized admins only

---

## 📞 Key Resources

**AWS Console**:
- VPC → Client VPN Endpoints
- Systems Manager → Session Manager
- CloudWatch → Log Groups

**Documentation**:
- `PRODUCTION-IMPLEMENTATION-GUIDE.md` - Full guide
- `PRODUCTION-Three-Phase-Solution.md` - Architecture
- `Production-Phase2-SSM-Implementation.ps1` - SSM script
- `Production-Phase3-ClientVPN-Implementation.ps1` - VPN script

---

## ⚠️ Important Differences from Dev

| Item | Dev | Production |
|------|-----|------------|
| Account | 749006369142 | 466090007609 |
| VPC CIDR | 10.60.0.0/16 | 10.70.0.0/16 |
| VPN Client CIDR | 10.100.0.0/16 | 10.200.0.0/16 |
| DC Subnets | AD-A, AD-B | Private-2a, Private-2b |
| Log Retention | 90 days | 180 days |
| MFA | Optional | Required |
| Change Control | Flexible | Strict approval required |

---

## ✅ Pre-Flight Checklist

Before implementation:
- [ ] Change control ticket approved
- [ ] Stakeholders notified
- [ ] Maintenance window scheduled
- [ ] Rollback plan documented
- [ ] Production credentials ready
- [ ] OpenSSL installed

---

**Quick Start**: Run Phase 2 script first, then Phase 3 script. Total time: ~75 minutes.
