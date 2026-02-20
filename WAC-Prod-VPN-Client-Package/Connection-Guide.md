# WAC Production VPN - Connection Guide

How to connect, disconnect, and troubleshoot your Production VPN connection.

**Environment:** Production  
**Purpose:** Domain Controller Administration  
**⚠️ Use with Caution - Production Environment**

---

## Table of Contents
1. [Connecting to VPN](#connecting-to-vpn)
2. [Disconnecting from VPN](#disconnecting-from-vpn)
3. [Connection Status](#connection-status)
4. [Accessing Resources](#accessing-resources)
5. [Troubleshooting](#troubleshooting)
6. [Best Practices](#best-practices)

---

## Connecting to VPN

### ⚠️ Before Connecting - Production Checklist

**STOP! Verify before connecting:**

- [ ] I have authorization for Production access
- [ ] I have a specific task to complete
- [ ] Change management approval obtained (if required)
- [ ] I'm in an appropriate maintenance window (if required)
- [ ] I have a rollback plan
- [ ] I'm in a secure location
- [ ] My computer is secure (encrypted, locked, updated)
- [ ] I will disconnect immediately after completing my task

### First-Time Connection

1. **Launch AWS VPN Client**
   - Windows: Start Menu → AWS VPN Client
   - macOS: Applications → AWS VPN Client
   - Linux: Application Menu → AWS VPN Client

2. **Select Profile**
   - Click on **WAC Prod Admin VPN** from the profile list
   - Verify the environment indicator shows "Production"

3. **Initiate Connection**
   - Click the **Connect** button
   - Wait for connection to establish (typically 10-30 seconds)

4. **Verify Connection**
   - Status indicator turns **green**
   - Message displays: **"Connected"**
   - Connection time is shown
   - **Verify VPN IP is in 10.200.x.x range**

### Subsequent Connections

1. Launch AWS VPN Client
2. Click **Connect** (profile is remembered)
3. Wait for green status
4. **Always verify you're connected to Production VPN**

### ⚠️ Auto-Connect (NOT RECOMMENDED)

**DO NOT enable auto-connect for Production VPN.**

Production access should be:
- Intentional
- Time-limited
- Task-specific
- Manually initiated

---

## Disconnecting from VPN

### Manual Disconnect (Required)

**Always disconnect when:**
- Task is complete
- Taking a break
- Leaving computer
- End of work session
- Switching to non-Production work

**To Disconnect:**
1. Open AWS VPN Client
2. Click **Disconnect** button
3. Wait for status to change to "Disconnected"
4. Verify disconnection complete
5. Close the application

### Automatic Disconnect

The VPN will automatically disconnect after:
- **24 hours** of continuous connection (session timeout)
- Computer sleep/hibernate
- Network change (switching WiFi networks)

**⚠️ Do not rely on automatic disconnect - always disconnect manually when done.**

### Force Disconnect (Emergency)

**Windows:**
```cmd
taskkill /F /IM "AWS VPN Client.exe"
```

**macOS/Linux:**
```bash
killall "AWS VPN Client"
```

---

## Connection Status

### Status Indicators

| Indicator | Meaning | Action |
|-----------|---------|--------|
| 🟢 **Green** | Connected to Production | Proceed with caution |
| 🟡 **Yellow** | Connecting | Wait for connection |
| 🔴 **Red** | Disconnected | Not connected to Production |
| 🟠 **Orange** | Error | Check troubleshooting section |

### Connection Information

When connected, you can view:
- **Connection Duration:** How long you've been connected
- **Bytes Sent/Received:** Data transfer statistics
- **VPN IP Address:** Your assigned IP from 10.200.0.0/16
- **Server:** VPN endpoint hostname
- **Environment:** Production (verify this!)

To view details:
1. Click on the connected profile
2. Click **Connection Details** or **Info** button

### ⚠️ Connection Time Monitoring

**Best Practice:** Limit Production VPN sessions to:
- Specific tasks only
- Maximum 2-4 hours per session
- Disconnect between tasks
- Document connection time in change tickets

---

## Accessing Resources

### What You Can Access

Once connected, you have access to:

#### Production VPC (10.70.0.0/16)
- **Domain Controllers:**
  - WACPRODDC01: 10.70.10.10 (us-west-2a)
  - WACPRODDC02: 10.70.11.10 (us-west-2b)
- **Active Directory Services**
- **DNS Services**
- **Other Production VPC resources**

#### DNS Resolution
- Internal DNS: 10.70.0.2
- Resolves internal hostnames automatically

### Testing Access

#### Test DNS Resolution:
```bash
nslookup wacproddc01.wac.local 10.70.0.2
nslookup wacproddc02.wac.local 10.70.0.2
```

#### Test Domain Controller Access:
```bash
# Ping test
ping 10.70.10.10
ping 10.70.11.10

# RDP test (Windows)
mstsc /v:10.70.10.10
mstsc /v:10.70.11.10
```

#### Test Active Directory:
```powershell
# From Windows with AD tools
Get-ADDomainController -Server 10.70.10.10
Get-ADDomainController -Server 10.70.11.10
```

### Split Tunnel Behavior

**Traffic that goes through VPN:**
- Destinations in 10.70.0.0/16 (Production VPC)

**Traffic that does NOT go through VPN:**
- Internet traffic (Google, AWS Console, etc.)
- Your local network
- Other AWS services (unless in Production VPC)

This means:
- ✅ Fast internet access (not routed through VPN)
- ✅ Access to local printers/file shares
- ✅ Only Production VPC traffic uses VPN bandwidth

---

## Troubleshooting

### Cannot Connect

#### Error: "Connection timeout"

**Cause:** Network connectivity issue or firewall blocking

**Solutions:**
1. Check your internet connection
2. Verify port 443 UDP is not blocked:
   ```bash
   # Test connectivity
   nc -vuz [vpn-endpoint] 443
   ```
3. Disable VPN-blocking software temporarily
4. Try from a different network
5. Check CloudWatch logs for errors

#### Error: "Authentication failed"

**Cause:** Incorrect or corrupted certificate

**Solutions:**
1. Verify you're using `wac-prod-admin-vpn.ovpn` (Production file)
2. Re-import the profile:
   - Delete existing profile
   - Import fresh copy of OVPN file
3. Check file wasn't corrupted during transfer
4. Contact administrator for new certificate
5. **Verify you have Production access authorization**

#### Error: "Profile not found"

**Cause:** Profile wasn't imported correctly

**Solutions:**
1. Go to **File** → **Manage Profiles**
2. Verify "WAC Prod Admin VPN" is listed
3. If not, re-import using Installation Guide
4. Ensure OVPN file is not corrupted

### Connection Drops Frequently

#### Symptom: Disconnects every few minutes

**Possible Causes & Solutions:**

1. **Unstable Internet Connection**
   - Test internet stability
   - Try wired connection instead of WiFi
   - Move closer to WiFi router

2. **Network Changes**
   - Switching between WiFi networks causes disconnect
   - Reconnect manually after network change

3. **Firewall Interference**
   - Check firewall logs
   - Add AWS VPN Client to firewall exceptions

4. **ISP Blocking UDP 443**
   - Some ISPs block VPN traffic
   - Contact ISP or try different network

### Cannot Access Resources After Connecting

#### Symptom: VPN connected but can't reach Domain Controllers

**Solutions:**

1. **Verify VPN IP Assignment**
   ```bash
   # Windows
   ipconfig | findstr "10.200"
   
   # macOS/Linux
   ifconfig | grep "10.200"
   ```
   You should see an IP in 10.200.0.0/16 range

2. **Test DNS Resolution**
   ```bash
   nslookup wacproddc01.wac.local 10.70.0.2
   ```
   Should resolve to 10.70.10.10

3. **Check Routing Table**
   ```bash
   # Windows
   route print | findstr "10.70"
   
   # macOS/Linux
   netstat -rn | grep "10.70"
   ```
   Should show route to 10.70.0.0/16 via VPN

4. **Verify Security Groups**
   - Ensure Domain Controllers allow traffic from 10.200.0.0/16
   - Check AWS security group rules

5. **Test Basic Connectivity**
   ```bash
   ping 10.70.0.2
   ping 10.70.10.10
   ping 10.70.11.10
   ```
   All should respond successfully

### Slow Performance

#### Symptom: Slow access to Production resources

**Solutions:**

1. **Check Connection Speed**
   - Test your internet speed
   - VPN performance depends on your connection

2. **Verify Split Tunnel**
   - Ensure split tunnel is enabled
   - Only Production VPC traffic should use VPN

3. **Check VPN Server Load**
   - Contact administrator to check endpoint metrics
   - May need to scale VPN capacity

4. **Local Network Issues**
   - Test from different network
   - Check for local bandwidth congestion

5. **Time of Day**
   - Production usage patterns may affect performance
   - Consider off-peak hours for large operations

---

## Best Practices

### Security

1. **Always Disconnect When Not Needed**
   - Don't leave VPN connected 24/7
   - Disconnect when not actively administering
   - Disconnect during breaks and lunch

2. **Protect Your OVPN File**
   - Never share with unauthorized users
   - Store in secure, encrypted location
   - Don't commit to version control
   - Delete securely when no longer needed

3. **Monitor Your Connections**
   - Review connection logs periodically
   - Report suspicious activity immediately
   - Track your connection time

4. **Secure Your Computer**
   - Enable full disk encryption
   - Use strong password/PIN
   - Enable screen lock (5-minute timeout)
   - Keep security software updated

### Performance

1. **Use Wired Connection When Possible**
   - More stable than WiFi
   - Better performance for large transfers
   - Especially important for Production

2. **Close Unnecessary Applications**
   - Reduces bandwidth competition
   - Improves VPN performance
   - Minimizes security risks

3. **Connect Only When Needed**
   - Reduces load on VPN endpoint
   - Saves bandwidth
   - Follows security best practices

### Reliability

1. **Test Connection Before Critical Work**
   - Verify access before maintenance windows
   - Test RDP to both Domain Controllers
   - Confirm DNS resolution working

2. **Have Backup Plan**
   - Know alternative access methods
   - Have emergency contacts ready
   - Document rollback procedures

3. **Monitor Connection During Work**
   - Watch for disconnections
   - Check connection status regularly
   - Be prepared to reconnect if needed

### Compliance

1. **Follow Change Management**
   - Obtain approvals before connecting
   - Document all Production changes
   - Use approved maintenance windows

2. **Document Your Work**
   - Log connection times
   - Record changes made
   - Update change tickets
   - Report any issues

3. **Respect Production Environment**
   - Test in Dev first
   - Make only approved changes
   - Verify changes before disconnecting
   - Follow rollback procedures if needed

---

## Connection Logs

### Viewing Local Logs

**Windows:**
```
C:\Users\<username>\AppData\Local\AWSVPNClient\logs\
```

**macOS:**
```
~/Library/Application Support/AWSVPNClient/logs/
```

**Linux:**
```
~/.config/AWSVPNClient/logs/
```

### CloudWatch Logs

All Production VPN connections are logged to AWS CloudWatch:
- **Log Group:** `/aws/clientvpn/prod-admin-vpn`
- **Retention:** 180 days
- **Log Stream:** cvpn-endpoint-xxxxx-us-west-2-*

Administrators can view:
- Connection attempts
- Authentication successes/failures
- Disconnection events
- Data transfer statistics
- Source IP addresses
- Connection duration

**⚠️ All Production access is monitored and audited.**

---

## Quick Reference Commands

### Check VPN Status

**Windows:**
```cmd
ipconfig | findstr "10.200"
route print | findstr "10.70"
```

**macOS/Linux:**
```bash
ifconfig | grep "10.200"
netstat -rn | grep "10.70"
```

### Test Connectivity

```bash
# Test DNS
ping 10.70.0.2

# Test Domain Controllers
ping 10.70.10.10
ping 10.70.11.10

# Test DNS resolution
nslookup wacproddc01.wac.local 10.70.0.2

# Test RDP port
telnet 10.70.10.10 3389
```

### Monitor Connection

```bash
# View connection details in AWS VPN Client
# Click on connected profile → Connection Details
```

---

## Getting Help

### Self-Service

1. Review this troubleshooting guide
2. Check local logs for error messages
3. Test from different network
4. Try disconnecting and reconnecting
5. Verify security groups and firewall rules

### Administrator Support

If issues persist, contact your administrator with:
- Error message (exact text)
- Connection logs (from local logs directory)
- Your VPN IP address (if connected)
- Steps to reproduce the issue
- Your operating system and version
- **Change ticket number (for Production access)**

**VPN Endpoint:** [Will be provided after deployment]  
**AWS Account:** 466090007609 (Production)  
**Region:** us-west-2  
**Environment:** Production

---

## FAQ

**Q: How long can I stay connected?**  
A: Maximum 24 hours, then automatic disconnect. However, best practice is to disconnect after completing your specific task (typically 1-4 hours).

**Q: Can I use VPN on multiple devices?**  
A: Yes, import the OVPN file on each device. All devices share the same certificate. All connections are logged.

**Q: Does VPN work on mobile devices?**  
A: AWS VPN Client is available for Windows, macOS, and Linux only. Mobile devices are not supported.

**Q: Will VPN slow down my internet?**  
A: No, split tunnel is enabled. Only Production VPC traffic (10.70.0.0/16) uses VPN.

**Q: Can I access Dev resources through Production VPN?**  
A: No, Production VPN only provides access to Production environment (10.70.0.0/16). Use Dev VPN for Dev access.

**Q: What if I lose the OVPN file?**  
A: Contact your administrator for a new copy. Do not share your copy with others. Report loss immediately.

**Q: What happens if I make a mistake in Production?**  
A: Follow your rollback procedures immediately. Contact Production support. Document the incident. All actions are logged.

**Q: Can I leave VPN connected overnight?**  
A: No. Always disconnect when not actively working. This is a security and compliance requirement.

---

## Production Environment Reminders

### Before Connecting
- ✅ Verify authorization
- ✅ Review change plan
- ✅ Check maintenance window
- ✅ Have rollback plan ready

### While Connected
- ⚠️ Work carefully and deliberately
- ⚠️ Double-check all commands
- ⚠️ Document all changes
- ⚠️ Monitor for issues

### After Disconnecting
- ✅ Verify changes successful
- ✅ Update change tickets
- ✅ Document work completed
- ✅ Report any issues

---

**Guide Version:** 1.0  
**Environment:** Production  
**Last Updated:** January 31, 2026  
**Next Review:** July 31, 2026

**⚠️ PRODUCTION ENVIRONMENT - ALL ACCESS IS LOGGED AND MONITORED**
