# Phase 3: Quick Start Checklist
## AWS Client VPN Implementation

**Account**: AWS_Dev (749006369142)  
**Date**: January 20, 2026

---

## Pre-Implementation Checklist

### ✅ Prerequisites Verified

- [x] **AWS Access**: Logged into AWS_Dev account (749006369142)
- [x] **Region**: Set to us-west-2
- [x] **VPC**: Dev-VPC (vpc-014ec3818a5b2940e) exists
- [x] **Subnets**: AD-A and AD-B subnets exist
- [ ] **OpenSSL**: Installed and in PATH

---

## Installation Steps

### Step 1: Install OpenSSL

**Check if installed**:
```powershell
openssl version
```

**If not installed, choose one option**:

**Option A - Chocolatey** (Fastest):
```powershell
choco install openssl
```

**Option B - Direct Download**:
1. Visit: https://slproweb.com/products/Win32OpenSSL.html
2. Download "Win64 OpenSSL v3.x.x"
3. Install to default location
4. Restart PowerShell

**Option C - Git for Windows**:
- Already includes OpenSSL
- Download: https://git-scm.com/download/win

**Verify installation**:
```powershell
openssl version
# Should show: OpenSSL 3.x.x or 1.1.1x
```

- [ ] OpenSSL installed and verified

---

### Step 2: Run Implementation Script

```powershell
# Navigate to workspace
cd C:\AWSKiro

# Run the script
.\Phase3-Implementation-Steps.ps1
```

**Expected Duration**: 15-20 minutes

**What to watch for**:
- ✅ Certificate generation (8 steps)
- ✅ Certificate import to ACM (2 ARNs)
- ✅ VPN endpoint creation (takes 5-10 minutes)
- ✅ Subnet associations (2 subnets)
- ✅ Authorization rules
- ✅ Routes configuration
- ✅ Client config file download

**Output files**:
- `vpn-certs-YYYYMMDD-HHMMSS/` - Certificate directory
- `wac-dev-admin-vpn.ovpn` - VPN client configuration

- [ ] Script completed successfully
- [ ] Certificate directory created
- [ ] VPN config file generated

---

### Step 3: Verify VPN Endpoint

```powershell
# Check endpoint status
aws ec2 describe-client-vpn-endpoints --region us-west-2 --query 'ClientVpnEndpoints[*].[ClientVpnEndpointId,Status.Code]' --output table
```

**Expected output**:
```
ClientVpnEndpointId: cvpn-endpoint-xxxxx
Status: available
```

- [ ] VPN endpoint shows "available" status

---

### Step 4: Install AWS VPN Client

1. **Download**:
   - Visit: https://aws.amazon.com/vpn/client-vpn-download/
   - Choose your OS (Windows/macOS/Linux)
   - Download and install

2. **Verify installation**:
   - Open AWS VPN Client application
   - Should see empty profile list

- [ ] AWS VPN Client installed

---

### Step 5: Import VPN Configuration

1. **Open AWS VPN Client**
2. **Click**: File → Manage Profiles
3. **Click**: Add Profile
4. **Browse**: Select `wac-dev-admin-vpn.ovpn`
5. **Name**: "WAC Dev Admin VPN"
6. **Click**: Add Profile

- [ ] VPN profile imported successfully

---

### Step 6: Test Connection

1. **Select Profile**: "WAC Dev Admin VPN"
2. **Click**: Connect
3. **Wait**: 5-10 seconds
4. **Verify**: Status shows "Connected"

**Troubleshooting**:
- If connection fails, check CloudWatch logs
- Verify endpoint is "available"
- Check authorization rules exist

- [ ] Successfully connected to VPN

---

### Step 7: Test VPC Access

```powershell
# Test 1: Ping AWS DNS
ping 10.60.0.2

# Test 2: Ping AD subnet
ping 10.60.1.1

# Test 3: Check your VPN IP
ipconfig | findstr "10.100"
# Should show an IP in 10.100.0.0/16 range
```

**Expected results**:
- ✅ Ping to 10.60.0.2 succeeds
- ✅ Ping to 10.60.1.1 succeeds
- ✅ VPN IP assigned from 10.100.0.0/16

- [ ] VPC connectivity verified

---

### Step 8: Test RDP Access (If DCs exist)

```powershell
# If you have Domain Controllers running:
mstsc /v:10.60.1.10

# Or use hostname if DNS configured:
mstsc /v:WACDEVDC01
```

**Note**: This step requires Domain Controllers to be deployed and running.

- [ ] RDP access tested (or N/A if no DCs yet)

---

## Post-Implementation Tasks

### Immediate

- [ ] **Secure certificates**: Move certificate directory to secure location
- [ ] **Backup certificates**: Copy to encrypted backup storage
- [ ] **Document VPN endpoint ID**: Save for future reference
- [ ] **Test from different location**: Try connecting from home/remote

### This Week

- [ ] **Generate additional client certificates**: For other admins
- [ ] **Distribute user guide**: Share `Phase3-VPN-User-Guide.md` with team
- [ ] **Set up monitoring**: Configure CloudWatch alarms
- [ ] **Review logs**: Check connection logs in CloudWatch

### This Month

- [ ] **Review costs**: Monitor actual usage and costs
- [ ] **Gather feedback**: Ask admins about experience
- [ ] **Optimize configuration**: Adjust based on usage patterns
- [ ] **Plan for production**: Consider AD integration and MFA

---

## Quick Reference

### VPN Endpoint Details

```
VPN Endpoint ID: cvpn-endpoint-xxxxx (from script output)
VPC: vpc-014ec3818a5b2940e (Dev-VPC)
VPC CIDR: 10.60.0.0/16
VPN Client CIDR: 10.100.0.0/16
Subnets: AD-A (us-west-2a), AD-B (us-west-2b)
DNS: 10.60.0.2
```

### Important Files

```
📄 wac-dev-admin-vpn.ovpn - VPN client configuration
📁 vpn-certs-YYYYMMDD-HHMMSS/ - Certificates (KEEP SECURE!)
📄 Phase3-VPN-User-Guide.md - User documentation
📄 Phase3-Implementation-Summary.md - Technical details
```

### Useful Commands

```powershell
# Check VPN endpoint status
aws ec2 describe-client-vpn-endpoints --region us-west-2

# View active connections
aws ec2 describe-client-vpn-connections --client-vpn-endpoint-id cvpn-endpoint-xxxxx --region us-west-2

# View connection logs
aws logs tail /aws/clientvpn/dev-admin-vpn --follow --region us-west-2

# Check your VPN IP
ipconfig | findstr "10.100"
```

---

## Troubleshooting Quick Fixes

### Problem: OpenSSL not found
```powershell
# Install via Chocolatey
choco install openssl

# Then restart PowerShell
```

### Problem: Script fails at certificate import
```powershell
# Verify AWS credentials are still valid
aws sts get-caller-identity

# If expired, get new credentials and set environment variables
```

### Problem: VPN endpoint stuck in "pending-associate"
```
# Wait 5-10 minutes - this is normal
# Check status periodically:
aws ec2 describe-client-vpn-endpoints --region us-west-2
```

### Problem: Cannot connect to VPN
```
1. Verify endpoint is "available"
2. Check .ovpn file has client certificate embedded
3. Try disconnecting and reconnecting
4. Restart AWS VPN Client application
```

### Problem: Connected but cannot access VPC
```powershell
# Check authorization rules
aws ec2 describe-client-vpn-authorization-rules --client-vpn-endpoint-id cvpn-endpoint-xxxxx --region us-west-2

# Check routes
aws ec2 describe-client-vpn-routes --client-vpn-endpoint-id cvpn-endpoint-xxxxx --region us-west-2
```

---

## Cost Tracking

### Monthly Cost Estimate

| Component | Estimated Cost |
|-----------|----------------|
| VPN Endpoint (24/7) | $73.00 |
| Connection time (varies) | $0.05/hour |
| Data transfer (varies) | $0.09/GB |
| **Total** | **~$76-135/month** |

### Monitor Costs

```powershell
# View current month costs for VPN
aws ce get-cost-and-usage \
  --time-period Start=2026-01-01,End=2026-01-31 \
  --granularity MONTHLY \
  --metrics "UnblendedCost" \
  --filter file://vpn-cost-filter.json
```

---

## Success Criteria

Phase 3 is successful when:

- ✅ OpenSSL installed
- ✅ Certificates generated
- ✅ VPN endpoint created and available
- ✅ Client configuration file generated
- ✅ AWS VPN Client installed
- ✅ Successfully connected to VPN
- ✅ Can access VPC resources
- ✅ Connection logs appearing in CloudWatch
- ✅ User guide distributed to team

---

## Next Steps After Success

1. **Generate certificates for other admins**:
   ```powershell
   # In certificate directory
   openssl genrsa -out client2.key 2048
   openssl req -new -key client2.key -out client2.csr -subj "/C=US/ST=California/L=SanFrancisco/O=WAC/OU=IT/CN=client2.wac.net"
   openssl x509 -req -days 3650 -in client2.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client2.crt
   
   # Import to ACM and create new .ovpn file
   ```

2. **Set up monitoring**:
   ```powershell
   # Create CloudWatch alarm for failed connections
   aws cloudwatch put-metric-alarm \
     --alarm-name "ClientVPN-Failed-Connections" \
     --alarm-description "Alert on failed VPN connections" \
     --metric-name "ConnectionAttempts" \
     --namespace "AWS/ClientVPN" \
     --statistic Sum \
     --period 300 \
     --threshold 5 \
     --comparison-operator GreaterThanThreshold \
     --evaluation-periods 1
   ```

3. **Document for team**:
   - Share user guide with all admins
   - Schedule training session
   - Create internal wiki page
   - Add to onboarding checklist

4. **Plan for production**:
   - Evaluate Active Directory integration
   - Consider MFA requirements
   - Review security policies
   - Plan certificate rotation process

---

## Support

### Documentation
- 📄 User Guide: `Phase3-VPN-User-Guide.md`
- 📄 Technical Guide: `Phase3-Client-VPN-Implementation-Guide.md`
- 📄 Implementation Summary: `Phase3-Implementation-Summary.md`

### Contacts
- **Consultant**: Arif Bangash
- **IT Support**: it.admins@wac.net
- **Slack**: #it-support

### AWS Resources
- Client VPN Docs: https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/
- VPN Client Download: https://aws.amazon.com/vpn/client-vpn-download/

---

## Completion Sign-off

**Implemented by**: ___________________  
**Date**: ___________________  
**VPN Endpoint ID**: ___________________  
**Tested by**: ___________________  
**Status**: ⬜ Success  ⬜ Issues (describe below)

**Notes**:
```
[Space for implementation notes, issues encountered, or special configurations]
```

---

**Ready to begin? Start with Step 1: Install OpenSSL**

