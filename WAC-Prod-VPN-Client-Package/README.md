# WAC Production Environment VPN - Client Installation Package

**Environment:** Production  
**VPN Name:** WAC Prod Admin VPN  
**Package Date:** January 31, 2026  
**Valid Until:** January 17, 2036

---

## 📦 Package Contents

This package contains everything you need to connect to the WAC Production environment via VPN for Domain Controller administration:

1. **wac-prod-admin-vpn.ovpn** - VPN configuration file (will be generated after deployment)
2. **Installation-Guide.md** - Step-by-step installation instructions
3. **Connection-Guide.md** - How to connect and troubleshoot
4. **Quick-Reference-Card.md** - Printable quick reference
5. **SECURITY-NOTICE.md** - Security policies and procedures
6. **README.md** - This file

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
4. Browse to `wac-prod-admin-vpn.ovpn`
5. Display Name: **WAC Prod Admin VPN**
6. Click **Add Profile**

### Step 3: Connect
1. Select "WAC Prod Admin VPN" from the profile list
2. Click **Connect**
3. Wait for connection to establish (green status)

---

## 🔒 Security Notice

**CRITICAL:** This VPN configuration file contains authentication credentials for Production environment access.

- ✅ Keep this file secure and confidential
- ✅ Do not share with unauthorized personnel
- ✅ Do not commit to version control systems
- ✅ Store in encrypted location when not in use
- ❌ Never email unencrypted
- ❌ Never upload to public file sharing services
- ⚠️ **PRODUCTION ACCESS** - Extra care required

---

## 🌐 What You Can Access

Once connected to the VPN, you will have access to:

- **VPC CIDR:** 10.70.0.0/16
- **Production Environment Resources:**
  - Domain Controller WACPRODDC01 (10.70.10.10)
  - Domain Controller WACPRODDC02 (10.70.11.10)
  - All Production VPC services
  - Active Directory management

**Your VPN IP:** You will receive an IP address from 10.200.0.0/16

---

## ⚙️ VPN Configuration Details

| Setting | Value |
|---------|-------|
| **Protocol** | OpenVPN over UDP |
| **Port** | 443 |
| **Encryption** | AES-256-GCM |
| **Split Tunnel** | Enabled (only Prod VPC traffic routes through VPN) |
| **DNS Server** | 10.70.0.2 |
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
- Verify you're using the correct OVPN file for Production
- Check your internet connection
- Ensure port 443 UDP is not blocked by firewall

**Connection drops:**
- Normal after 24 hours (automatic timeout)
- Simply reconnect when needed

**Cannot access resources:**
- Verify you're connected (green status in VPN client)
- Check that the resource IP is in 10.70.0.0/16 range
- Verify security group rules allow your VPN IP range (10.200.0.0/16)

### Getting Help

For VPN connection issues, contact:
- **AWS Account:** 466090007609 (Production)
- **Region:** us-west-2
- **Environment:** Production

---

## 📊 Connection Monitoring

Your VPN connections are logged for security and audit purposes:
- **CloudWatch Log Group:** `/aws/clientvpn/prod-admin-vpn`
- **Retention:** 180 days
- All connection attempts, successes, and disconnections are recorded

---

## 🔄 Certificate Validity

- **Valid From:** January 19, 2026
- **Valid Until:** January 17, 2036
- **Renewal Required:** No action needed until 2036

---

## 📝 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Jan 31, 2026 | Initial Production client package release |

---

## ✅ Pre-Installation Checklist

Before installing, ensure you have:

- [ ] Downloaded AWS VPN Client installer
- [ ] Received `wac-prod-admin-vpn.ovpn` file
- [ ] Administrator/root privileges on your computer
- [ ] Active internet connection
- [ ] Reviewed security guidelines above
- [ ] **Confirmed authorization for Production access**

---

## ⚠️ Production Environment Warning

**This VPN provides access to the PRODUCTION environment.**

- All actions are logged and monitored
- Changes can impact live systems
- Follow change management procedures
- Use with extreme caution
- Disconnect when not actively administering

---

## 📞 Contact Information

For questions or issues:
- Review the detailed guides in this package
- Check CloudWatch logs for connection details
- Contact your AWS administrator
- Follow incident response procedures for Production issues

---

## 🎯 Use Cases

This VPN is intended for:

✅ **Domain Controller Administration**
- Managing WACPRODDC01 and WACPRODDC02
- Active Directory administration
- User account management
- Group Policy configuration

✅ **Emergency Access**
- Incident response
- Troubleshooting Production issues
- Critical maintenance

❌ **Not for:**
- Regular development work (use Dev VPN)
- Testing or experimentation
- Non-administrative access
- Continuous connection

---

## 📈 Best Practices

### Connection Management
- Connect only when needed
- Disconnect after completing tasks
- Don't leave connected overnight
- Monitor your session time

### Security
- Keep OVPN file in secure location
- Use strong computer password
- Enable full disk encryption
- Lock computer when away

### Compliance
- Follow change management procedures
- Document all Production changes
- Use approved maintenance windows
- Report any security incidents

---

**Package Prepared By:** Arif Bangash-Consultant  
**AWS Account:** 466090007609 (WAC Production)  
**Last Updated:** January 31, 2026

---

## 🚨 Emergency Contacts

**Production Issues:**
- Immediately disconnect VPN if issues occur
- Contact Production support team
- Follow incident response procedures
- Document all actions taken

**Security Incidents:**
- Report immediately to Security team
- Do not attempt to resolve alone
- Preserve evidence
- Follow security incident procedures

---

**PRODUCTION ENVIRONMENT - USE WITH CAUTION**
