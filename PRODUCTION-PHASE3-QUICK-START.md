# Production Phase 3: Client VPN - Quick Start Card

**Account**: 466090007609 | **Region**: us-west-2 | **VPN CIDR**: 10.200.0.0/16

---

## 📥 Downloads

### OpenSSL (Required for Setup)
**Link**: https://slproweb.com/products/Win64OpenSSL.html  
**File**: Win64 OpenSSL v3.x.x (NOT Light version)  
**Install to**: `C:\Program Files\OpenSSL-Win64`

### AWS VPN Client (Required for Connection)
**Link**: https://aws.amazon.com/vpn/client-vpn-download/  
**File**: AWS-VPN-Client.msi  
**Platform**: Windows 10 or later

---

## ⚡ Implementation (3 Steps)

### Step 1: Generate Certificates (~30 seconds)
```powershell
cd C:\AWSKiro
.\Prod-Phase3-VPN-Step1-Certificates.ps1
```
**Creates**: `vpn-certs-prod-TIMESTAMP/`

### Step 2: Create VPN Endpoint (~2 minutes)
```powershell
# Set credentials first
$env:AWS_ACCESS_KEY_ID="YOUR_KEY"
$env:AWS_SECRET_ACCESS_KEY="YOUR_SECRET"
$env:AWS_SESSION_TOKEN="YOUR_TOKEN"

# Run script
.\Prod-Phase3-VPN-Step2-CreateEndpoint.ps1
```
**Creates**: VPN endpoint, imports certificates, configures networking

### Step 3: Generate Config (~10 seconds)
```powershell
.\Prod-Phase3-VPN-Step3-GenerateConfig.ps1
```
**Creates**: `wac-prod-admin-vpn.ovpn`

---

## 🔌 Connect to VPN

1. **Open AWS VPN Client**
2. **File → Manage Profiles → Add Profile**
3. **Browse to**: `C:\AWSKiro\wac-prod-admin-vpn.ovpn`
4. **Name**: WAC Production Admin VPN
5. **Click "Add Profile"**
6. **Select profile and click "Connect"**

---

## ✅ Test Connection

```powershell
# Test DNS
ping 10.70.0.2

# Check VPN IP (should be 10.200.x.x)
ipconfig | findstr "10.200"

# RDP to Domain Controller
mstsc /v:10.70.1.10
```

---

## 🔧 Troubleshooting

| Problem | Solution |
|---------|----------|
| OpenSSL not found | Install to `C:\Program Files\OpenSSL-Win64` |
| Credentials expired | Get fresh credentials, set env vars again |
| VPN won't connect | Wait 5-10 min after endpoint creation |
| Can't access VPC | Check security groups allow 10.200.0.0/16 |

---

## 📊 Key Information

- **VPC**: vpc-014b66d7ca2309134 (10.70.0.0/16)
- **DC Subnets**: Private-2a (10.70.1.0/24), Private-2b (10.70.3.0/24)
- **VPN Client CIDR**: 10.200.0.0/16
- **AWS DNS**: 10.70.0.2
- **Log Group**: /aws/clientvpn/prod-admin-vpn (180 days)

---

## 💰 Cost

- **Fixed**: $73/month (endpoint)
- **Variable**: $0.05/hour per connection + $0.09/GB data transfer
- **Total**: ~$76-135/month depending on usage

---

## 🔒 Security Reminders

- ✅ Move certificates to encrypted storage
- ✅ Never commit OVPN file to Git
- ✅ Distribute VPN config securely only
- ✅ Disconnect VPN when not in use
- ✅ Rotate certificates every 90 days

---

## 📞 Support

**Full Guide**: `PRODUCTION-PHASE3-INSTALLATION-GUIDE.md`  
**IT Support**: it.admins@wac.net  
**AWS Console**: VPC → Client VPN Endpoints

---

**Total Setup Time**: ~3 minutes | **Difficulty**: Easy
