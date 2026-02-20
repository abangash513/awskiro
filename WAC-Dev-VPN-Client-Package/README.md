# WAC Dev Environment VPN - Client Installation Package

**Environment:** Development  
**VPN Name:** WAC Dev Admin VPN  
**Package Date:** January 31, 2026  
**Valid Until:** January 17, 2036

---

## 📦 Package Contents

This package contains everything you need to connect to the WAC Development environment via VPN:

1. **wac-dev-admin-vpn-FIXED.ovpn** - VPN configuration file (ready to use)
2. **Installation-Guide.md** - Step-by-step installation instructions
3. **Connection-Guide.md** - How to connect and troubleshoot
4. **README.md** - This file

---

## 🚀 Quick Start

### Step 1: Install AWS VPN Client
Download and install the AWS VPN Client for your operating system:
- **Windows:** https://d20adtppz83p9s.cloudfront.net/WPF/latest/AWS_VPN_Client.msi
- **macOS:** https://d20adtppz83p9s.cloudfront.net/OSX/latest/AWS_VPN_Client.pkg
- **Linux:** https://d20adtppz83p9s.cloudfront.net/GTK/latest/awsvpnclient_amd64.deb

### Step 2: Import VPN Profile
1. Open AWS VPN Client
2. Click **File** → **Manage Profiles**
3. Click **Add Profile**
4. Browse to `wac-dev-admin-vpn-FIXED.ovpn`
5. Display Name: **WAC Dev Admin VPN**
6. Click **Add Profile**

### Step 3: Connect
1. Select "WAC Dev Admin VPN" from the profile list
2. Click **Connect**
3. Wait for connection to establish (green status)

---

## 🔒 Security Notice

**IMPORTANT:** This VPN configuration file contains authentication credentials.

- ✅ Keep this file secure and confidential
- ✅ Do not share with unauthorized personnel
- ✅ Do not commit to version control systems
- ✅ Store in encrypted location when not in use
- ❌ Never email unencrypted
- ❌ Never upload to public file sharing services

---

## 🌐 What You Can Access

Once connected to the VPN, you will have access to:

- **VPC CIDR:** 10.60.0.0/16
- **Development Environment Resources:**
  - EC2 instances
  - RDS databases
  - Internal services
  - Domain controllers (when deployed)

**Your VPN IP:** You will receive an IP address from 10.100.0.0/16

---

## ⚙️ VPN Configuration Details

| Setting | Value |
|---------|-------|
| **Protocol** | OpenVPN over UDP |
| **Port** | 443 |
| **Encryption** | AES-256-GCM |
| **Split Tunnel** | Enabled (only Dev VPC traffic routes through VPN) |
| **DNS Server** | 10.60.0.2 |
| **Session Timeout** | 24 hours |
| **Auto-reconnect** | Enabled |

---

## 📋 System Requirements

### Windows
- Windows 10 (64-bit) or later
- Administrator privileges for installation
- 100 MB free disk space

### macOS
- macOS 10.15 (Catalina) or later
- Administrator privileges for installation
- 100 MB free disk space

### Linux
- Ubuntu 18.04 or later (or equivalent)
- Root/sudo access for installation
- 100 MB free disk space

---

## 🆘 Support & Troubleshooting

### Common Issues

**Cannot connect:**
- Verify you're using `wac-dev-admin-vpn-FIXED.ovpn` (not the old version)
- Check your internet connection
- Ensure port 443 UDP is not blocked by firewall

**Connection drops:**
- Normal after 24 hours (automatic timeout)
- Simply reconnect when needed

**Cannot access resources:**
- Verify you're connected (green status in VPN client)
- Check that the resource IP is in 10.60.0.0/16 range
- Verify security group rules allow your VPN IP range (10.100.0.0/16)

### Getting Help

For VPN connection issues, contact:
- **AWS Account:** 749006369142
- **Region:** us-west-2
- **Endpoint ID:** cvpn-endpoint-02fbfb0cd399c382c

---

## 📊 Connection Monitoring

Your VPN connections are logged for security and audit purposes:
- **CloudWatch Log Group:** `/aws/clientvpn/dev-admin-vpn`
- All connection attempts, successes, and disconnections are recorded

---

## 🔄 Certificate Validity

- **Valid From:** January 20, 2026
- **Valid Until:** January 17, 2036
- **Renewal Required:** No action needed until 2036

---

## 📝 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Jan 31, 2026 | Initial client package release |

---

## ✅ Pre-Installation Checklist

Before installing, ensure you have:

- [ ] Downloaded AWS VPN Client installer
- [ ] Received `wac-dev-admin-vpn-FIXED.ovpn` file
- [ ] Administrator/root privileges on your computer
- [ ] Active internet connection
- [ ] Reviewed security guidelines above

---

## 📞 Contact Information

For questions or issues:
- Review the detailed guides in this package
- Check CloudWatch logs for connection details
- Contact your AWS administrator

---

**Package Prepared By:** Arif Bangash-Consultant  
**AWS Account:** 749006369142 (WAC Dev)  
**Last Updated:** January 31, 2026
