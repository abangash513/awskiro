# WAC Production VPN - Quick Reference Card

**Print this page and keep it handy for quick reference**

**⚠️ PRODUCTION ENVIRONMENT - USE WITH CAUTION**

---

## 🔐 VPN Details

| Item | Value |
|------|-------|
| **VPN Name** | WAC Prod Admin VPN |
| **Environment** | **PRODUCTION** |
| **Config File** | wac-prod-admin-vpn.ovpn |
| **VPC CIDR** | 10.70.0.0/16 |
| **Client CIDR** | 10.200.0.0/16 |
| **DNS Server** | 10.70.0.2 |
| **Valid Until** | January 17, 2036 |

---

## 🚀 Quick Start

### Connect
1. **Verify authorization for Production access**
2. Open AWS VPN Client
3. Select "WAC Prod Admin VPN"
4. Click **Connect**
5. Wait for green status
6. **Verify environment is Production**

### Disconnect
1. Open AWS VPN Client
2. Click **Disconnect**
3. **Always disconnect when task complete**

---

## 📥 Download Links

| OS | Download URL |
|----|--------------|
| **Windows** | https://d20adtppz83p9s.cloudfront.net/WPF/latest/AWS_VPN_Client.msi |
| **macOS** | https://d20adtppz83p9s.cloudfront.net/OSX/latest/AWS_VPN_Client.pkg |
| **Linux** | https://d20adtppz83p9s.cloudfront.net/GTK/latest/awsvpnclient_amd64.deb |

---

## ✅ Connection Checklist

- [ ] AWS VPN Client installed
- [ ] Profile imported (wac-dev-admin-vpn-FIXED.ovpn)
- [ ] Connected (green status)
- [ ] VPN IP assigned (10.100.x.x)
- [ ] Can ping 10.60.0.2

---

## 🧪 Test Commands

### Check VPN IP
```bash
# Windows
ipconfig | findstr "10.200"

# macOS/Linux
ifconfig | grep "10.200"
```

### Test DNS
```bash
ping 10.70.0.2
```

### Test Domain Controllers
```bash
ping 10.70.10.10  # WACPRODDC01
ping 10.70.11.10  # WACPRODDC02
```

---

## 🔴 Troubleshooting

| Problem | Solution |
|---------|----------|
| **Can't connect** | Check internet, verify port 443 UDP not blocked |
| **Authentication fails** | Re-import OVPN file, verify using FIXED version |
| **Connection drops** | Check WiFi stability, enable auto-reconnect |
| **Can't access resources** | Verify VPN IP (10.100.x.x), check security groups |
| **Slow performance** | Use wired connection, verify split tunnel enabled |

---

## 📊 Status Indicators

| Color | Status | Meaning |
|-------|--------|---------|
| 🟢 | Connected | VPN active and working |
| 🟡 | Connecting | Wait for connection |
| 🔴 | Disconnected | Not connected |
| 🟠 | Error | Check troubleshooting |

---

## 🌐 What's Accessible

### ✅ Through VPN
- **Production VPC** (10.70.0.0/16)
- **WACPRODDC01** (10.70.10.10)
- **WACPRODDC02** (10.70.11.10)
- Active Directory services
- Production resources

### ❌ Not Through VPN (Split Tunnel)
- Internet traffic
- AWS Console
- Local network resources
- Dev environment (use Dev VPN)

---

## ⚙️ Important Settings

| Setting | Value |
|---------|-------|
| **Protocol** | OpenVPN/UDP |
| **Port** | 443 |
| **Encryption** | AES-256-GCM |
| **Split Tunnel** | Enabled |
| **Session Timeout** | 24 hours |
| **Auto-reconnect** | Configurable |

---

## 🔒 Security Reminders

- ⚠️ **PRODUCTION ACCESS - Extra caution required**
- ✅ Verify authorization before connecting
- ✅ Disconnect immediately after task complete
- ✅ Keep OVPN file extremely secure
- ✅ Follow change management procedures
- ❌ Never leave connected unattended
- ❌ Don't commit to version control
- ❌ Don't email unencrypted
- ❌ Don't use for testing (use Dev VPN)

---

## 📞 Support Information

| Item | Value |
|------|-------|
| **Endpoint ID** | [After deployment] |
| **AWS Account** | 466090007609 |
| **Region** | us-west-2 |
| **Environment** | **PRODUCTION** |
| **CloudWatch Logs** | /aws/clientvpn/prod-admin-vpn |

---

## 📁 Log Locations

### Windows
```
C:\Users\<username>\AppData\Local\AWSVPNClient\logs\
```

### macOS
```
~/Library/Application Support/AWSVPNClient/logs/
```

### Linux
```
~/.config/AWSVPNClient/logs/
```

---

## 🔄 Session Management

- **Max Duration:** 24 hours
- **Auto-disconnect:** After timeout
- **Reconnect:** Manual or auto (if configured)
- **Concurrent Connections:** Multiple devices allowed

---

## 📝 Quick Commands

### Windows
```cmd
# Check VPN status
ipconfig | findstr "10.100"

# Check routes
route print | findstr "10.60"

# Test DNS
ping 10.60.0.2
```

### macOS/Linux
```bash
# Check VPN status
ifconfig | grep "10.100"

# Check routes
netstat -rn | grep "10.60"

# Test DNS
ping 10.60.0.2
```

---

## 📅 Important Dates

| Event | Date |
|-------|------|
| **Certificate Issued** | January 20, 2026 |
| **Certificate Expires** | January 17, 2036 |
| **Package Created** | January 31, 2026 |
| **Next Review** | July 31, 2026 |

---

## 🆘 Emergency Procedures

### Force Disconnect

**Windows:**
```cmd
taskkill /F /IM "AWS VPN Client.exe"
```

**macOS/Linux:**
```bash
killall "AWS VPN Client"
```

### Reset Connection

1. Disconnect VPN
2. Close AWS VPN Client
3. Wait 10 seconds
4. Reopen and reconnect

---

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| **README.md** | Package overview |
| **Installation-Guide.md** | Setup instructions |
| **Connection-Guide.md** | Usage and troubleshooting |
| **Quick-Reference-Card.md** | This document |

---

**Version:** 1.0  
**Last Updated:** January 31, 2026  
**Print Date:** _______________

---

**✂️ Cut along this line and keep for reference ✂️**
