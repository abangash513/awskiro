# Production Phase 3: Client VPN - Complete Installation Guide

**Account**: AWS_Production (466090007609)  
**Region**: us-west-2  
**Date**: January 20, 2026

---

## 📋 Overview

This guide provides complete step-by-step instructions for implementing AWS Client VPN for Production, including all prerequisite software installations.

---

## 🔧 Prerequisites Installation

### 1. Install OpenSSL (Required for Certificate Generation)

**Download Link**: https://slproweb.com/products/Win64OpenSSL.html

**Installation Steps**:

1. **Download the installer**:
   - Go to: https://slproweb.com/products/Win64OpenSSL.html
   - Download: **Win64 OpenSSL v3.x.x** (NOT the "Light" version)
   - File name will be something like: `Win64OpenSSL-3_x_x.exe`

2. **Run the installer**:
   - Double-click the downloaded `.exe` file
   - Click "Yes" if prompted by User Account Control
   - Accept the license agreement
   - **Important**: Choose installation directory: `C:\Program Files\OpenSSL-Win64`
   - Select "The OpenSSL binaries (/bin) directory" when asked where to copy DLLs
   - Click "Install"

3. **Verify installation**:
   ```powershell
   & "C:\Program Files\OpenSSL-Win64\bin\openssl.exe" version
   ```
   - Should display: `OpenSSL 3.x.x` or similar

**Alternative Download**: https://wiki.openssl.org/index.php/Binaries

---

### 2. Install AWS VPN Client (Required for Connecting)

**Download Link**: https://aws.amazon.com/vpn/client-vpn-download/

**Installation Steps**:

1. **Download the client**:
   - Go to: https://aws.amazon.com/vpn/client-vpn-download/
   - Click "Download for Windows"
   - File name: `AWS-VPN-Client.msi` or similar

2. **Run the installer**:
   - Double-click the downloaded `.msi` file
   - Click "Yes" if prompted by User Account Control
   - Follow the installation wizard
   - Click "Install"
   - Click "Finish" when complete

3. **Launch AWS VPN Client**:
   - Find "AWS VPN Client" in Start Menu
   - Launch the application
   - You should see an empty profile list

**System Requirements**:
- Windows 10 or later
- Administrator privileges for installation
- Internet connection

---

## 🚀 Implementation Steps

### Step 1: Prepare AWS Credentials


1. **Get Production credentials** (WAC_ProdFullAdmin role)
2. **Set environment variables**:
   ```powershell
   $env:AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY"
   $env:AWS_SECRET_ACCESS_KEY="YOUR_SECRET_KEY"
   $env:AWS_SESSION_TOKEN="YOUR_SESSION_TOKEN"
   ```

3. **Verify credentials**:
   ```powershell
   aws sts get-caller-identity --region us-west-2
   ```
   - Should show Account: 466090007609

---

### Step 2: Generate Certificates

**Script**: `Prod-Phase3-VPN-Step1-Certificates.ps1`

```powershell
cd C:\AWSKiro
.\Prod-Phase3-VPN-Step1-Certificates.ps1
```

**What it does**:
- Generates Certificate Authority (CA)
- Generates server certificate with proper TLS extensions
- Generates client certificate with proper TLS extensions
- Creates directory: `vpn-certs-prod-TIMESTAMP/`

**Expected output**:
```
=== Generating VPN Certificates for Production ===
Certificate directory: vpn-certs-prod-YYYYMMDD-HHMMSS
[1/7] Generating CA...
Success: CA generated
[2/7] Generating server key...
Success: Server key generated
...
[7/7] Signing client certificate...
Success: Client certificate signed
```

**Time**: ~30 seconds

---

### Step 3: Create VPN Endpoint

**Script**: `Prod-Phase3-VPN-Step2-CreateEndpoint.ps1`

```powershell
.\Prod-Phase3-VPN-Step2-CreateEndpoint.ps1
```

**What it does**:
- Imports certificates to AWS Certificate Manager (ACM)
- Creates CloudWatch log group (180-day retention)
- Creates Client VPN endpoint
- Associates Private-2a and Private-2b subnets (where DCs are located)
- Adds authorization rules for VPC access
- Adds routes to VPC

**Expected output**:
```
=== Production Phase 3: Creating VPN Endpoint ===
[1/7] Importing server certificate to ACM...
Success: Server certificate imported
  ARN: arn:aws:acm:us-west-2:466090007609:certificate/xxxxx
...
[7/7] Adding route...
Success: Route added to VPC
```

**Time**: ~2 minutes (includes wait times for AWS resource creation)

---

### Step 4: Generate VPN Client Configuration

**Script**: `Prod-Phase3-VPN-Step3-GenerateConfig.ps1`

```powershell
.\Prod-Phase3-VPN-Step3-GenerateConfig.ps1
```

**What it does**:
- Exports VPN configuration from AWS
- Embeds certificates into configuration file
- Creates: `wac-prod-admin-vpn.ovpn`

**Expected output**:
```
=== Generating VPN Client Configuration ===
[1/2] Exporting VPN configuration from AWS...
Success: Configuration exported
[2/2] Embedding certificates...
Success: VPN configuration file created

VPN Configuration File: wac-prod-admin-vpn.ovpn
```

**Time**: ~10 seconds

---

## 📱 Connecting to VPN

### Step 1: Import VPN Profile

1. **Open AWS VPN Client**
2. **Click "File" → "Manage Profiles"**
3. **Click "Add Profile"**
4. **Fill in details**:
   - Display Name: `WAC Production Admin VPN`
   - VPN Configuration File: Browse to `C:\AWSKiro\wac-prod-admin-vpn.ovpn`
5. **Click "Add Profile"**

### Step 2: Connect

1. **Select profile**: "WAC Production Admin VPN"
2. **Click "Connect"**
3. **Wait for connection**: Status should change to "Connected"
4. **Verify IP assignment**: You should receive an IP from 10.200.0.0/16 range

### Step 3: Test Connectivity

```powershell
# Test AWS DNS
ping 10.70.0.2

# Check your VPN IP
ipconfig | findstr "10.200"

# Test access to Domain Controllers (if IPs are known)
ping 10.70.1.10
ping 10.70.3.10
```

---

## 🔍 Troubleshooting

### OpenSSL Not Found

**Error**: `OpenSSL not found at C:\Program Files\OpenSSL-Win64\bin\openssl.exe`

**Solution**:
1. Verify installation path
2. Check if installed in different location
3. Reinstall OpenSSL to correct path

### Certificate Import Fails

**Error**: `An error occurred (ValidationException) when calling the ImportCertificate operation`

**Solution**:
1. Verify certificates were generated correctly
2. Check certificate files exist in `vpn-certs-prod-*/` directory
3. Regenerate certificates if needed

### VPN Connection Fails

**Error**: "Connection failed" or "TLS handshake error"

**Solution**:
1. Verify VPN endpoint status in AWS Console
2. Check subnet associations are "associated" (not "associating")
3. Verify authorization rules exist
4. Check routes are configured
5. Wait 5-10 minutes after endpoint creation for full propagation

### Cannot Access VPC Resources

**Problem**: Connected to VPN but cannot ping or access resources

**Solution**:
1. Verify you received an IP from 10.200.0.0/16 range
2. Test DNS: `ping 10.70.0.2`
3. Check security groups allow traffic from 10.200.0.0/16
4. Verify routes are active in VPN endpoint
5. Check Domain Controllers are running

### Credentials Expired

**Error**: `Request has expired`

**Solution**:
1. Get fresh Production credentials
2. Set environment variables again
3. Re-run the failed script

---

## 📊 Resources Created

### AWS Resources

| Resource | Name/ID | Purpose |
|----------|---------|---------|
| **IAM Role** | WAC-Prod-DC-SSM-Role | SSM access for DCs |
| **Instance Profile** | WAC-Prod-DC-SSM-Profile | Attach to EC2 instances |
| **CloudWatch Log (SSM)** | /aws/ssm/prod-domain-controllers | SSM session logs (180 days) |
| **CloudWatch Log (VPN)** | /aws/clientvpn/prod-admin-vpn | VPN connection logs (180 days) |
| **S3 Bucket** | wac-prod-ssm-session-logs-466090007609 | SSM session storage |
| **ACM Certificate (Server)** | arn:aws:acm:...:certificate/xxxxx | VPN server auth |
| **ACM Certificate (Client)** | arn:aws:acm:...:certificate/xxxxx | VPN client auth |
| **VPN Endpoint** | cvpn-endpoint-xxxxx | Client VPN endpoint |

### Local Files

| File/Directory | Purpose |
|----------------|---------|
| `vpn-certs-prod-TIMESTAMP/` | Certificate files (SECURE!) |
| `wac-prod-admin-vpn.ovpn` | VPN client configuration |
| `prod-vpn-config.json` | Configuration metadata |
| `prod-cert-dir.txt` | Certificate directory reference |

---

## 🔒 Security Best Practices

### Certificate Security

1. **Move certificates to encrypted storage**:
   ```powershell
   # Example: Move to encrypted folder
   Move-Item -Path "vpn-certs-prod-*" -Destination "D:\Secure\Certificates\"
   ```

2. **Set restrictive permissions**:
   - Right-click certificate folder
   - Properties → Security
   - Remove all users except Administrators

3. **Create encrypted backup**:
   - Use BitLocker or similar encryption
   - Store backup in secure location
   - Document backup location

### VPN Configuration Security

1. **Protect OVPN file**:
   - Contains embedded certificates
   - Never commit to Git
   - Never email unencrypted
   - Distribute via secure channel only

2. **Rotate certificates**:
   - Schedule: Every 90 days
   - Process: Generate new certificates, update VPN endpoint
   - Document rotation dates

### Access Control

1. **Limit VPN distribution**:
   - Only authorized administrators
   - Document who has access
   - Revoke access when no longer needed

2. **Monitor connections**:
   - Review CloudWatch logs regularly
   - Set up alerts for unusual activity
   - Audit access quarterly

---

## 💰 Cost Breakdown

| Component | Monthly Cost | Notes |
|-----------|--------------|-------|
| VPN Endpoint (24/7) | $73.00 | Fixed cost |
| Connection Time | $0.05/hour | Per active connection |
| Data Transfer (out) | $0.09/GB | Varies by usage |
| CloudWatch Logs | ~$2.00 | 180-day retention |
| S3 Storage | ~$1.00 | Session logs |
| **Total (estimated)** | **$76-135/month** | Depends on usage |

**Usage Examples**:
- Light (2 hrs/day, 1 user): ~$76/month
- Moderate (4 hrs/day, 3 users): ~$95/month
- Heavy (8 hrs/day, 5 users): ~$135/month

---

## 📞 Support Resources

### AWS Console Links

- **VPC → Client VPN Endpoints**: Check endpoint status, connections, logs
- **Certificate Manager**: View imported certificates
- **CloudWatch → Log Groups**: View connection logs
- **Systems Manager**: SSM session access

### Documentation

- AWS Client VPN: https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/
- OpenSSL Documentation: https://www.openssl.org/docs/
- Troubleshooting Guide: `PRODUCTION-IMPLEMENTATION-GUIDE.md`

### Internal Resources

- IT Support: it.admins@wac.net
- Change Control: Submit ticket before implementation
- Documentation: Internal wiki

---

## ✅ Post-Implementation Checklist

### Immediate Actions

- [ ] VPN endpoint created and available
- [ ] Certificates secured in encrypted storage
- [ ] VPN configuration file distributed to authorized users
- [ ] Test connection successful
- [ ] Can access Domain Controllers via RDP
- [ ] CloudWatch logs receiving data
- [ ] Documentation updated

### Within 24 Hours

- [ ] Train admin team on VPN usage
- [ ] Set up CloudWatch alarms for failed connections
- [ ] Document VPN endpoint ID and certificate ARNs
- [ ] Create runbook for common issues
- [ ] Schedule certificate rotation (90 days)

### Within 1 Week

- [ ] Review connection logs
- [ ] Verify all authorized users can connect
- [ ] Test failover between subnets
- [ ] Conduct security audit
- [ ] Update disaster recovery procedures

---

## 🎓 User Training

### For End Users

1. **Download and install AWS VPN Client**
2. **Import provided OVPN file**
3. **Connect when remote access needed**
4. **Disconnect when done** (to save costs)
5. **Report any connection issues immediately**

### Best Practices for Users

- ✅ Disconnect VPN when not actively using
- ✅ Use strong passwords for RDP
- ✅ Lock screen when away from computer
- ✅ Report suspicious activity
- ✅ Keep VPN client updated

### What NOT to Do

- ❌ Share VPN configuration file
- ❌ Leave VPN connected overnight
- ❌ Use VPN for non-work purposes
- ❌ Bypass security policies
- ❌ Store credentials in plain text

---

## 📝 Quick Reference

### Connection Commands

```powershell
# Test VPN connectivity
ping 10.70.0.2

# Check VPN IP
ipconfig | findstr "10.200"

# RDP to Domain Controller
mstsc /v:10.70.1.10
```

### AWS CLI Commands

```powershell
# Check VPN endpoint status
aws ec2 describe-client-vpn-endpoints --region us-west-2

# View active connections
aws ec2 describe-client-vpn-connections --client-vpn-endpoint-id cvpn-endpoint-xxxxx --region us-west-2

# View VPN logs
aws logs tail /aws/clientvpn/prod-admin-vpn --follow --region us-west-2
```

### Important Information

- **VPC CIDR**: 10.70.0.0/16
- **VPN Client CIDR**: 10.200.0.0/16
- **AWS DNS**: 10.70.0.2
- **DC Subnets**: Private-2a (10.70.1.0/24), Private-2b (10.70.3.0/24)
- **Region**: us-west-2
- **Account**: 466090007609

---

**Document Version**: 1.0  
**Created**: January 20, 2026  
**Status**: Ready for Implementation  

**Questions?** Contact IT Support or refer to `PRODUCTION-IMPLEMENTATION-GUIDE.md`
