# AWS Client VPN - Setup Instructions
## Connect to WAC Dev Environment

**Date**: January 20, 2026  
**VPN Endpoint**: cvpn-endpoint-0f3409fb7606460cf

---

## Step 1: Download AWS VPN Client

**Download Link**: https://aws.amazon.com/vpn/client-vpn-download/

**For Windows**:
1. Click "Download for Windows"
2. Save the installer
3. Run the installer
4. Follow the installation wizard
5. Click "Finish"

---

## Step 2: Import VPN Configuration

**Configuration File**: `C:\AWSKiro\wac-dev-admin-vpn.ovpn`

**Steps**:
1. **Open AWS VPN Client** (from Start Menu)
2. Click **"File"** → **"Manage Profiles"**
3. Click **"Add Profile"**
4. Click **"Browse"**
5. Navigate to: `C:\AWSKiro\`
6. Select: `wac-dev-admin-vpn.ovpn`
7. **Display Name**: Enter "WAC Dev Admin VPN"
8. Click **"Add Profile"**
9. Click **"Done"**

---

## Step 3: Connect to VPN

1. In AWS VPN Client main window
2. Select **"WAC Dev Admin VPN"** from dropdown
3. Click **"Connect"**
4. Wait 5-10 seconds
5. Status should show **"Connected"** (green)

**Your VPN IP**: Will be in range 10.100.0.0/16

---

## Step 4: Test Connection

**Option A: Run Test Script**
```powershell
cd C:\AWSKiro
.\Test-VPN-Connection.ps1
```

**Option B: Manual Tests**
```powershell
# Test 1: Check VPN IP
ipconfig | findstr "10.100"

# Test 2: Ping AWS DNS
ping 10.60.0.2

# Test 3: Ping AD subnet
ping 10.60.1.1

# Test 4: Test Domain Controller (if deployed)
ping 10.60.1.10
```

---

## Step 5: Access Domain Controllers

**If Domain Controllers are deployed:**

```powershell
# RDP to DC1
mstsc /v:10.60.1.10

# RDP to DC2
mstsc /v:10.60.2.10

# Or use hostname (if DNS configured)
mstsc /v:WACDEVDC01
```

**Login Credentials**: Use your Active Directory credentials

---

## Troubleshooting

### Issue: Cannot connect to VPN

**Solutions**:
1. Verify configuration file was imported correctly
2. Check internet connection
3. Try disconnecting and reconnecting
4. Restart AWS VPN Client
5. Check VPN endpoint status in AWS Console

---

### Issue: Connected but cannot access VPC

**Solutions**:
1. Verify you have a 10.100.x.x IP address
   ```powershell
   ipconfig | findstr "10.100"
   ```

2. Test basic connectivity
   ```powershell
   ping 10.60.0.2
   ```

3. Check authorization rules in AWS Console:
   - Go to VPC → Client VPN Endpoints
   - Select: cvpn-endpoint-0f3409fb7606460cf
   - Check "Authorization" tab
   - Should show: 10.60.0.0/16 authorized

4. Check routes:
   - Go to "Route Table" tab
   - Should show route to 10.60.0.0/16

---

### Issue: Cannot RDP to Domain Controllers

**Solutions**:
1. Verify DCs are deployed and running
2. Check DC security groups allow RDP from 10.100.0.0/16
3. Test connectivity first:
   ```powershell
   ping 10.60.1.10
   ```
4. Verify your AD credentials are correct

---

## VPN Connection Details

**VPC Information**:
- VPC CIDR: 10.60.0.0/16
- VPN Client CIDR: 10.100.0.0/16
- DNS Server: 10.60.0.2

**Subnets**:
- AD-A: 10.60.1.0/24 (us-west-2a)
- AD-B: 10.60.2.0/24 (us-west-2b)

**Domain Controllers** (when deployed):
- DC1: 10.60.1.10 (AD-A subnet)
- DC2: 10.60.2.10 (AD-B subnet)

---

## Best Practices

### Security
- ✅ Always disconnect VPN when not in use
- ✅ Never share your VPN configuration file
- ✅ Keep your laptop secure (VPN config contains credentials)
- ✅ Use strong passwords for RDP sessions
- ✅ Lock your screen when stepping away

### Performance
- ✅ Split tunneling is enabled (only AWS traffic uses VPN)
- ✅ Close VPN when done to save costs
- ✅ Minimize large file transfers over VPN

### Cost Awareness
- 💰 Connection costs: $0.05/hour while connected
- 💰 Data transfer: $0.09/GB
- 💰 Best practice: Disconnect when not actively using

---

## Quick Reference

**Connect to VPN**:
1. Open AWS VPN Client
2. Select "WAC Dev Admin VPN"
3. Click "Connect"

**Test Connection**:
```powershell
.\Test-VPN-Connection.ps1
```

**RDP to DC**:
```powershell
mstsc /v:10.60.1.10
```

**Disconnect VPN**:
1. Open AWS VPN Client
2. Click "Disconnect"

---

## Support

**IT Support**: it.admins@wac.net  
**Consultant**: Arif Bangash  
**Documentation**: C:\AWSKiro\

**AWS Console**:
- VPC → Client VPN Endpoints
- Endpoint ID: cvpn-endpoint-0f3409fb7606460cf

---

## Next Steps

1. ✅ Download AWS VPN Client
2. ✅ Import configuration file
3. ✅ Connect to VPN
4. ✅ Run test script
5. ✅ Access Domain Controllers (when deployed)

---

**Ready to connect!** Download the AWS VPN Client and follow the steps above.

