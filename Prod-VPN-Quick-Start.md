# WAC Production VPN - Quick Start Guide

**Purpose:** Remote administration access to Production Domain Controllers  
**Estimated Time:** 15 minutes  
**Date:** January 31, 2026

---

## 🎯 What You're Setting Up

A secure VPN connection from your location to:
- **Production VPC:** 10.70.0.0/16
- **WACPRODDC01:** 10.70.10.10 (us-west-2a)
- **WACPRODDC02:** 10.70.11.10 (us-west-2b)

---

## ✅ Pre-Flight Checklist

Before you begin, verify:

- [ ] You have AWS CLI configured with Production account (466090007609)
- [ ] You have appropriate IAM permissions
- [ ] Certificates are in: `vpn-certs-prod-20260119-220611/`
- [ ] You're in the correct directory (C:\AWSKiro or equivalent)
- [ ] You have PowerShell or Bash terminal open

---

## 🚀 Deployment (Choose One Method)

### Method 1: Automated (Recommended)

**Single Command:**
```powershell
.\Setup-Prod-Client-VPN.ps1
```

**What it does:**
1. Creates CloudWatch log group
2. Creates VPN endpoint
3. Waits for endpoint to become available (~5-10 min)
4. Associates with subnets
5. Adds authorization rules
6. Configures routes
7. Generates `wac-prod-admin-vpn.ovpn`

**Time:** 10-15 minutes (mostly waiting for endpoint)

### Method 2: Manual

See `WAC-Prod-VPN-Deployment-Guide.md` for detailed manual steps.

---

## 📥 Install VPN Client

While the endpoint is being created, download AWS VPN Client:

**Windows:**
https://d20adtppz83p9s.cloudfront.net/WPF/latest/AWS_VPN_Client.msi

**macOS:**
https://d20adtppz83p9s.cloudfront.net/OSX/latest/AWS_VPN_Client.pkg

**Linux:**
https://d20adtppz83p9s.cloudfront.net/GTK/latest/awsvpnclient_amd64.deb

---

## 🔌 Connect to VPN

### Step 1: Import Profile

1. Open **AWS VPN Client**
2. Click **File** → **Manage Profiles**
3. Click **Add Profile**
4. Browse to `wac-prod-admin-vpn.ovpn`
5. Display Name: **WAC Prod Admin VPN**
6. Click **Add Profile**

### Step 2: Connect

1. Select "WAC Prod Admin VPN"
2. Click **Connect**
3. Wait for **green status**
4. You're connected!

---

## 🧪 Test Your Connection

### Quick Tests

**1. Check VPN IP:**
```bash
# Windows
ipconfig | findstr "10.200"

# macOS/Linux
ifconfig | grep "10.200"
```
✅ Should show IP in 10.200.0.0/16 range

**2. Ping Domain Controllers:**
```bash
ping 10.70.10.10
ping 10.70.11.10
```
✅ Should receive replies

**3. RDP to Domain Controller:**
```bash
# Windows
mstsc /v:10.70.10.10

# macOS
# Use Microsoft Remote Desktop app
```
✅ RDP should connect

---

## 📊 What You Get

### Network Access

**VPN Client IP Range:** 10.200.0.0/16  
**Access To:** Entire Production VPC (10.70.0.0/16)

### Resources Accessible

| Resource | IP | Purpose |
|----------|-----|---------|
| **WACPRODDC01** | 10.70.10.10 | Domain Controller (AZ-2a) |
| **WACPRODDC02** | 10.70.11.10 | Domain Controller (AZ-2b) |
| **VPC DNS** | 10.70.0.2 | DNS Resolution |

### Protocols Available

- ✅ RDP (3389) - Remote Desktop
- ✅ LDAP (389) - Directory Services
- ✅ LDAPS (636) - Secure LDAP
- ✅ Kerberos (88) - Authentication
- ✅ DNS (53) - Name Resolution
- ✅ All other Production VPC services

---

## 🔒 Security Notes

### Important

- ⚠️ **Keep `wac-prod-admin-vpn.ovpn` secure** - Contains authentication credentials
- ⚠️ **Never commit to version control** - Git, SVN, etc.
- ⚠️ **Distribute only to authorized admins** - Production access
- ⚠️ **Disconnect when not in use** - 24-hour session timeout

### What's Logged

All VPN activity is logged to CloudWatch:
- **Log Group:** `/aws/clientvpn/prod-admin-vpn`
- **Retention:** 180 days
- **Includes:** Connections, disconnections, data transfer

---

## 🆘 Troubleshooting

### Can't Connect

**Problem:** Connection timeout or fails

**Solutions:**
1. Check internet connection
2. Verify firewall allows UDP 443
3. Try from different network
4. Check endpoint status in AWS Console

### Connected but Can't Access DCs

**Problem:** VPN connected but can't ping/RDP

**Solutions:**
1. Verify VPN IP is in 10.200.x.x range
2. Check security groups allow 10.200.0.0/16
3. Test DNS: `nslookup 10.70.10.10 10.70.0.2`
4. Check CloudWatch logs for errors

### Slow Performance

**Problem:** Slow RDP or transfers

**Solutions:**
1. Use wired connection instead of WiFi
2. Verify split tunnel is enabled
3. Check internet speed
4. Try connecting to different DC

---

## 📞 Need Help?

### Quick Commands

**Check endpoint status:**
```bash
aws ec2 describe-client-vpn-endpoints --region us-west-2
```

**View logs:**
```bash
aws logs tail /aws/clientvpn/prod-admin-vpn --follow --region us-west-2
```

**Check your VPN connection:**
```bash
# Windows
route print | findstr "10.70"

# macOS/Linux
netstat -rn | grep "10.70"
```

### Documentation

- **Full Guide:** `WAC-Prod-VPN-Deployment-Guide.md`
- **Certificate Status:** `WAC-Prod-VPN-Certificate-Status.md`
- **AWS Docs:** https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/

---

## 📋 Post-Deployment Checklist

After successful deployment:

- [ ] VPN endpoint created and available
- [ ] OVPN file generated
- [ ] AWS VPN Client installed
- [ ] Profile imported
- [ ] Successfully connected
- [ ] Can ping Domain Controllers
- [ ] Can RDP to Domain Controllers
- [ ] CloudWatch logs showing connections
- [ ] Configuration documented
- [ ] OVPN file backed up securely

---

## 🎉 Success Criteria

You're done when:

✅ VPN shows **green/connected** status  
✅ You have IP in **10.200.0.0/16** range  
✅ You can **ping 10.70.10.10** and **10.70.11.10**  
✅ You can **RDP to both Domain Controllers**  
✅ **CloudWatch logs** show your connection  

---

## 📝 Configuration Summary

| Setting | Value |
|---------|-------|
| **VPC** | vpc-014b66d7ca2309134 (10.70.0.0/16) |
| **Client CIDR** | 10.200.0.0/16 |
| **DNS** | 10.70.0.2 |
| **Protocol** | OpenVPN/UDP:443 |
| **Encryption** | AES-256-GCM |
| **Split Tunnel** | Enabled |
| **Session Timeout** | 24 hours |
| **Logging** | /aws/clientvpn/prod-admin-vpn |

---

## 🔄 Daily Usage

### Connect

1. Open AWS VPN Client
2. Select "WAC Prod Admin VPN"
3. Click Connect
4. Wait for green status

### Disconnect

1. Click Disconnect
2. Close AWS VPN Client (optional)

### Auto-Disconnect

VPN automatically disconnects after:
- 24 hours of continuous connection
- Computer sleep/hibernate
- Network change

Simply reconnect when needed!

---

**Quick Start Version:** 1.0  
**Last Updated:** January 31, 2026  
**Status:** Ready to Use

**Next:** Run `.\Setup-Prod-Client-VPN.ps1` to begin!
