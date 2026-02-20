# Quick Start: RDP to Production Domain Controllers

**Status:** ✅ VPN Endpoint is AVAILABLE - Ready to Connect!

---

## 🚀 Quick Steps (5 Minutes)

### Step 1: Install AWS VPN Client (One-time)

**Download:** https://aws.amazon.com/vpn/client-vpn-download/

1. Download Windows installer
2. Run installer
3. Click through installation wizard
4. Launch "AWS VPN Client"

---

### Step 2: Import VPN Profile (One-time)

1. Open **AWS VPN Client**
2. Click **File** → **Manage Profiles**
3. Click **Add Profile**
4. Browse to: `C:\AWSKiro\wac-prod-admin-vpn.ovpn`
5. Click **Add Profile**
6. Click **Done**

---

### Step 3: Connect to VPN

1. In AWS VPN Client, select **"WAC Prod Admin VPN"**
2. Click **Connect**
3. Wait for **green "Connected"** status (10-30 seconds)

**You should see:**
- Status: Connected (green)
- IP Address: 10.200.x.x

---

### Step 4: Test Connectivity

Open PowerShell and run:

```powershell
# Test DC1
ping 10.70.10.10

# Test DC2
ping 10.70.11.10
```

**Expected:** Replies from both IPs

---

### Step 5: RDP to Domain Controllers

#### Connect to WACPRODDC01:

1. Press `Windows Key + R`
2. Type: `mstsc /v:10.70.10.10`
3. Press Enter
4. Enter your credentials:
   - Username: `WAC\your-username` or `your-username@wac.local`
   - Password: Your Active Directory password
5. Click **OK**
6. Click **Yes** on certificate warning

#### Connect to WACPRODDC02:

Same steps, but use: `mstsc /v:10.70.11.10`

---

## 📋 Domain Controller Information

| Name | IP Address | Purpose |
|------|------------|---------|
| **WACPRODDC01** | 10.70.10.10 | Primary Domain Controller (us-west-2a) |
| **WACPRODDC02** | 10.70.11.10 | Secondary Domain Controller (us-west-2b) |

---

## 🔧 Troubleshooting

### VPN Won't Connect

```powershell
# Check endpoint status
aws ec2 describe-client-vpn-endpoints --client-vpn-endpoint-ids cvpn-endpoint-0bbd2f9ca471fa45e --region us-west-2 --query 'ClientVpnEndpoints[0].Status.Code' --output text
```

Should show: `available`

### Can't Ping DCs

1. Verify VPN shows "Connected" (green)
2. Check your VPN IP is 10.200.x.x
3. Try disconnecting and reconnecting VPN

### RDP Won't Connect

```powershell
# Test RDP port
Test-NetConnection -ComputerName 10.70.10.10 -Port 3389
```

Should show: `TcpTestSucceeded: True`

### Wrong Credentials

Try different username formats:
- `WAC\username`
- `username@wac.local`
- `wac.local\username`

---

## ⚠️ Important Reminders

1. **Always connect VPN first** before attempting RDP
2. **Disconnect VPN** when done with Production work
3. **Follow change management** for all Production changes
4. **All activity is logged** to CloudWatch
5. **This is PRODUCTION** - handle with care!

---

## 📞 Need Help?

**VPN Issues:** AWS Administrator / Network Team  
**RDP Issues:** Domain Administrators / IT Help Desk  
**Security Issues:** Security Team (immediate)

---

**VPN Endpoint:** cvpn-endpoint-0bbd2f9ca471fa45e  
**Status:** ✅ Available  
**Environment:** PRODUCTION  

---

**Ready to connect! Follow the steps above to access your Production Domain Controllers.**
