# How to RDP to WAC Production Domain Controllers

**Date:** January 31, 2026  
**Environment:** PRODUCTION  
**Domain Controllers:**
- WACPRODDC01: 10.70.10.10
- WACPRODDC02: 10.70.11.10

---

## 📋 Prerequisites

Before you can RDP to the Domain Controllers, you need:

1. ✅ AWS VPN Client installed
2. ✅ VPN profile imported (wac-prod-admin-vpn.ovpn)
3. ✅ VPN endpoint status is "available" (wait 5-10 minutes after deployment)
4. ✅ Domain credentials (Active Directory username and password)
5. ✅ Remote Desktop Connection (built into Windows)

---

## Step 1: Install AWS VPN Client

### Download AWS VPN Client

**Download Link:** https://aws.amazon.com/vpn/client-vpn-download/

**Choose your platform:**
- Windows: Download Windows installer
- macOS: Download macOS installer
- Linux: Download Linux package

### Install on Windows

1. Run the downloaded installer
2. Click "Next" through the installation wizard
3. Accept the license agreement
4. Click "Install"
5. Click "Finish" when complete

**Installation Location:** `C:\Program Files\Amazon\AWS VPN Client\`

---

## Step 2: Import VPN Profile

### Open AWS VPN Client

1. Click Start menu
2. Search for "AWS VPN Client"
3. Click to open the application

### Add VPN Profile

1. In AWS VPN Client, click **"File"** → **"Manage Profiles"**
2. Click **"Add Profile"**
3. Click **"Browse"** and navigate to:
   - `C:\AWSKiro\wac-prod-admin-vpn.ovpn`
4. Click **"Open"**
5. The profile name will show as: **"WAC Prod Admin VPN"** or similar
6. Click **"Add Profile"**
7. Click **"Done"**

---

## Step 3: Connect to VPN

### Verify Endpoint Status First

Before connecting, verify the VPN endpoint is ready:

```powershell
aws ec2 describe-client-vpn-endpoints --client-vpn-endpoint-ids cvpn-endpoint-0bbd2f9ca471fa45e --region us-west-2 --query 'ClientVpnEndpoints[0].Status.Code' --output text
```

**Expected Output:** `available`

If it shows `pending-associate`, wait a few more minutes.

### Connect to VPN

1. In AWS VPN Client, select **"WAC Prod Admin VPN"** from the dropdown
2. Click the **"Connect"** button
3. Wait for connection (10-30 seconds)
4. Status will change to **"Connected"** (green)

### Verify Connection

Once connected, you should see:
- **Status:** Connected (green indicator)
- **IP Address:** Something in 10.200.x.x range (your VPN client IP)
- **Duration:** Connection time counter

### Test Network Connectivity

Open PowerShell and test connectivity:

```powershell
# Test Domain Controller 1
ping 10.70.10.10

# Test Domain Controller 2
ping 10.70.11.10

# Test DNS resolution
nslookup wacproddc01.wac.local 10.70.0.2
nslookup wacproddc02.wac.local 10.70.0.2
```

**Expected Results:**
- Ping should succeed with replies from 10.70.10.10 and 10.70.11.10
- DNS lookups should resolve to the correct IP addresses

---

## Step 4: RDP to WACPRODDC01

### Option A: Using Remote Desktop Connection (GUI)

1. **Open Remote Desktop Connection:**
   - Press `Windows Key + R`
   - Type: `mstsc`
   - Press Enter

2. **Enter Connection Details:**
   - **Computer:** `10.70.10.10`
   - Click **"Show Options"** (optional, for more settings)

3. **Configure Connection (Optional):**
   - **User name:** `WAC\your-username` or `your-username@wac.local`
   - **Display:** Adjust screen size if needed
   - **Local Resources:** Configure clipboard, drives, etc.

4. **Connect:**
   - Click **"Connect"**

5. **Enter Credentials:**
   - **Username:** Your Active Directory username
     - Format: `WAC\username` or `username@wac.local`
   - **Password:** Your Active Directory password
   - Check **"Remember my credentials"** (optional)
   - Click **"OK"**

6. **Certificate Warning:**
   - You may see a certificate warning
   - Click **"Yes"** to continue (this is normal for internal servers)

7. **Connected!**
   - You should now see the WACPRODDC01 desktop

### Option B: Using PowerShell Command

```powershell
# RDP to WACPRODDC01
mstsc /v:10.70.10.10
```

This opens Remote Desktop Connection with the IP pre-filled.

### Option C: Using Command Line with Credentials

```powershell
# Create RDP file with settings
cmdkey /generic:10.70.10.10 /user:WAC\your-username /pass:your-password
mstsc /v:10.70.10.10
```

**⚠️ Security Warning:** Don't save passwords in scripts. Use this only for testing.

---

## Step 5: RDP to WACPRODDC02

Follow the same steps as above, but use:

**IP Address:** `10.70.11.10`

### Quick Connection

```powershell
# RDP to WACPRODDC02
mstsc /v:10.70.11.10
```

---

## 🔧 Troubleshooting

### Issue 1: "VPN Connection Failed"

**Symptoms:** Cannot connect to VPN

**Solutions:**
1. Check VPN endpoint status:
   ```powershell
   aws ec2 describe-client-vpn-endpoints --client-vpn-endpoint-ids cvpn-endpoint-0bbd2f9ca471fa45e --region us-west-2
   ```
   - Status should be "available"
   - If "pending-associate", wait 5-10 minutes

2. Check your internet connection
3. Verify port 443 UDP is not blocked by firewall
4. Try disconnecting and reconnecting

### Issue 2: "Cannot Ping Domain Controllers"

**Symptoms:** Ping fails to 10.70.10.10 or 10.70.11.10

**Solutions:**
1. Verify VPN is connected (green status in AWS VPN Client)
2. Check your VPN IP address (should be 10.200.x.x)
3. Check routing:
   ```powershell
   route print | findstr "10.70"
   ```
   - Should show route to 10.70.0.0/16 via VPN interface

4. Check authorization rules:
   ```powershell
   aws ec2 describe-client-vpn-authorization-rules --client-vpn-endpoint-id cvpn-endpoint-0bbd2f9ca471fa45e --region us-west-2
   ```

### Issue 3: "RDP Connection Refused"

**Symptoms:** Remote Desktop cannot connect

**Solutions:**
1. Verify VPN is connected
2. Verify you can ping the DC:
   ```powershell
   ping 10.70.10.10
   ```

3. Check if RDP port is open:
   ```powershell
   Test-NetConnection -ComputerName 10.70.10.10 -Port 3389
   ```
   - Should show "TcpTestSucceeded: True"

4. Verify Domain Controller is running:
   ```powershell
   aws ec2 describe-instances --instance-ids i-0745579f46a34da2e --region us-west-2 --query 'Reservations[0].Instances[0].State.Name' --output text
   ```
   - Should show "running"

### Issue 4: "Authentication Failed"

**Symptoms:** RDP prompts for credentials but rejects them

**Solutions:**
1. Verify username format:
   - Try: `WAC\username`
   - Try: `username@wac.local`
   - Try: `wac.local\username`

2. Verify your Active Directory account is active
3. Check if your account has RDP permissions
4. Try resetting your AD password

### Issue 5: "Certificate Warning"

**Symptoms:** Certificate warning when connecting via RDP

**Solution:**
- This is normal for internal servers
- Click "Yes" to continue
- The certificate is self-signed or issued by internal CA

---

## 📊 Connection Status Check

### Check VPN Status

```powershell
# In AWS VPN Client, look for:
# - Status: Connected (green)
# - IP Address: 10.200.x.x
# - Duration: Active connection time
```

### Check Network Routes

```powershell
# Verify route to Production VPC
route print | findstr "10.70"

# Expected output:
# 10.70.0.0    255.255.0.0    [VPN Gateway IP]    [VPN Interface]
```

### Check DNS Resolution

```powershell
# Test DNS resolution
nslookup wacproddc01.wac.local 10.70.0.2
nslookup wacproddc02.wac.local 10.70.0.2

# Expected output:
# Server: 10.70.0.2
# Address: 10.70.0.2
# Name: wacproddc01.wac.local
# Address: 10.70.10.10
```

### Check RDP Port

```powershell
# Test RDP port connectivity
Test-NetConnection -ComputerName 10.70.10.10 -Port 3389
Test-NetConnection -ComputerName 10.70.11.10 -Port 3389

# Expected output:
# TcpTestSucceeded: True
```

---

## 🔐 Security Best Practices

### During Connection

1. **Always verify VPN is connected** before accessing Production resources
2. **Use strong passwords** for Active Directory accounts
3. **Enable MFA** if available for your AD account
4. **Lock your workstation** when stepping away
5. **Disconnect VPN** when not actively using Production resources

### After Connection

1. **Log out** from RDP session (don't just close window)
2. **Disconnect VPN** when done
3. **Review CloudWatch logs** periodically
4. **Report any suspicious activity** immediately

### Production Access

1. **Follow change management** procedures for all changes
2. **Document all actions** taken on Production systems
3. **Use least privilege** - only access what you need
4. **Obtain approval** before making Production changes

---

## 📝 Quick Reference

### Domain Controller Details

| Name | IP Address | Instance ID | Subnet | AZ |
|------|------------|-------------|--------|-----|
| **WACPRODDC01** | 10.70.10.10 | i-0745579f46a34da2e | MAD-2a | us-west-2a |
| **WACPRODDC02** | 10.70.11.10 | i-08c78db5cfc6eb412 | MAD-2b | us-west-2b |

### VPN Details

| Property | Value |
|----------|-------|
| **Endpoint ID** | cvpn-endpoint-0bbd2f9ca471fa45e |
| **Client CIDR** | 10.200.0.0/16 |
| **VPC CIDR** | 10.70.0.0/16 |
| **DNS Server** | 10.70.0.2 |

### Quick Commands

```powershell
# Connect to VPN (in AWS VPN Client GUI)
# Then:

# Test connectivity
ping 10.70.10.10
ping 10.70.11.10

# RDP to DC1
mstsc /v:10.70.10.10

# RDP to DC2
mstsc /v:10.70.11.10

# Check VPN endpoint status
aws ec2 describe-client-vpn-endpoints --client-vpn-endpoint-ids cvpn-endpoint-0bbd2f9ca471fa45e --region us-west-2 --query 'ClientVpnEndpoints[0].Status.Code' --output text

# Check DC instance status
aws ec2 describe-instances --instance-ids i-0745579f46a34da2e i-08c78db5cfc6eb412 --region us-west-2 --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PrivateIpAddress]' --output table
```

---

## 📞 Support

### Technical Issues

**VPN Connection Issues:**
- AWS Administrator
- Network Team

**RDP Issues:**
- Domain Administrators
- IT Help Desk

**Active Directory Issues:**
- Domain Administrators
- Identity Management Team

### Security Issues

**Suspicious Activity:**
- Security Team (immediate)
- Incident Response Team

**Access Issues:**
- Security Team
- Compliance Team

---

## ✅ Connection Checklist

Before attempting RDP connection:

- [ ] AWS VPN Client installed
- [ ] VPN profile imported (wac-prod-admin-vpn.ovpn)
- [ ] VPN endpoint status is "available"
- [ ] VPN connected (green status)
- [ ] VPN IP received (10.200.x.x)
- [ ] Can ping 10.70.10.10
- [ ] Can ping 10.70.11.10
- [ ] Have Active Directory credentials
- [ ] Authorized for Production access
- [ ] Change management approval (if making changes)

---

**Guide Version:** 1.0  
**Last Updated:** January 31, 2026  
**Environment:** Production  
**Maintained By:** AWS Administration Team

---

**⚠️ PRODUCTION ENVIRONMENT - HANDLE WITH CARE ⚠️**

**END OF RDP CONNECTION GUIDE**
