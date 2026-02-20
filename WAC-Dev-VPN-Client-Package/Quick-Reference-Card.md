# WAC Dev VPN - Quick Reference Card

**Print this page and keep it handy for quick reference**

---

## 🔐 VPN Details

| Item | Value |
|------|-------|
| **VPN Name** | WAC Dev Admin VPN |
| **Environment** | Development |
| **Config File** | wac-dev-admin-vpn-FIXED.ovpn |
| **VPC CIDR** | 10.60.0.0/16 |
| **Client CIDR** | 10.100.0.0/16 |
| **DNS Server** | 10.60.0.2 |
| **Valid Until** | January 17, 2036 |

---

## 🚀 Quick Start

### Connect
1. Open AWS VPN Client
2. Select "WAC Dev Admin VPN"
3. Click **Connect**
4. Wait for green status

### Disconnect
1. Open AWS VPN Client
2. Click **Disconnect**

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
ipconfig | findstr "10.100"

# macOS/Linux
ifconfig | grep "10.100"
```

### Test DNS
```bash
ping 10.60.0.2
```

### Test Connectivity
```bash
# Replace with actual resource IP
ping 10.60.x.x
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
- Dev VPC resources (10.60.0.0/16)
- EC2 instances
- RDS databases
- Internal services

### ❌ Not Through VPN (Split Tunnel)
- Internet traffic
- AWS Console
- Local network resources

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

- ✅ Disconnect when not needed
- ✅ Keep OVPN file secure
- ✅ Never share credentials
- ❌ Don't commit to version control
- ❌ Don't email unencrypted

---

## 📞 Support Information

| Item | Value |
|------|-------|
| **Endpoint ID** | cvpn-endpoint-02fbfb0cd399c382c |
| **AWS Account** | 749006369142 |
| **Region** | us-west-2 |
| **CloudWatch Logs** | /aws/clientvpn/dev-admin-vpn |

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
