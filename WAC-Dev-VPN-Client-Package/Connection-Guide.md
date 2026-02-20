# WAC Dev VPN - Connection Guide

How to connect, disconnect, and troubleshoot your VPN connection.

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

### First-Time Connection

1. **Launch AWS VPN Client**
   - Windows: Start Menu → AWS VPN Client
   - macOS: Applications → AWS VPN Client
   - Linux: Application Menu → AWS VPN Client

2. **Select Profile**
   - Click on **WAC Dev Admin VPN** from the profile list
   - Verify the server endpoint is displayed

3. **Initiate Connection**
   - Click the **Connect** button
   - Wait for connection to establish (typically 10-30 seconds)

4. **Verify Connection**
   - Status indicator turns **green**
   - Message displays: **"Connected"**
   - Connection time is shown

### Subsequent Connections

1. Launch AWS VPN Client
2. Click **Connect** (profile is remembered)
3. Wait for green status

### Auto-Connect (Optional)

To automatically connect when launching the client:

1. Click **File** → **Preferences**
2. Check **"Auto-connect on application start"**
3. Select **WAC Dev Admin VPN** as default profile
4. Click **Save**

---

## Disconnecting from VPN

### Manual Disconnect

1. Open AWS VPN Client
2. Click **Disconnect** button
3. Wait for status to change to "Disconnected"
4. You can now close the application

### Automatic Disconnect

The VPN will automatically disconnect after:
- **24 hours** of continuous connection (session timeout)
- Computer sleep/hibernate (will auto-reconnect on wake if configured)
- Network change (switching WiFi networks)

### Force Disconnect (If Needed)

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
| 🟢 **Green** | Connected | VPN is active and working |
| 🟡 **Yellow** | Connecting | Wait for connection to establish |
| 🔴 **Red** | Disconnected | Click Connect to establish VPN |
| 🟠 **Orange** | Error | Check troubleshooting section |

### Connection Information

When connected, you can view:
- **Connection Duration:** How long you've been connected
- **Bytes Sent/Received:** Data transfer statistics
- **VPN IP Address:** Your assigned IP from 10.100.0.0/16
- **Server:** VPN endpoint hostname

To view details:
1. Click on the connected profile
2. Click **Connection Details** or **Info** button

---

## Accessing Resources

### What You Can Access

Once connected, you have access to:

#### Development VPC (10.60.0.0/16)
- EC2 instances
- RDS databases
- ElastiCache clusters
- Internal load balancers
- Domain controllers (when deployed)

#### DNS Resolution
- Internal DNS: 10.60.0.2
- Resolves internal hostnames automatically

### Testing Access

#### Test DNS Resolution:
```bash
nslookup internal-resource.dev.wac.local 10.60.0.2
```

#### Test EC2 Instance Access:
```bash
# Replace with actual instance IP
ssh ec2-user@10.60.x.x
```

#### Test RDS Access:
```bash
# Replace with actual RDS endpoint
mysql -h dev-database.internal.wac.local -u admin -p
```

### Split Tunnel Behavior

**Traffic that goes through VPN:**
- Destinations in 10.60.0.0/16 (Dev VPC)

**Traffic that does NOT go through VPN:**
- Internet traffic (Google, AWS Console, etc.)
- Your local network
- Other AWS services (unless in Dev VPC)

This means:
- ✅ Fast internet access (not routed through VPN)
- ✅ Access to local printers/file shares
- ✅ Only Dev VPC traffic uses VPN bandwidth

---

## Troubleshooting

### Cannot Connect

#### Error: "Connection timeout"

**Cause:** Network connectivity issue or firewall blocking

**Solutions:**
1. Check your internet connection
2. Verify port 443 UDP is not blocked:
   ```bash
   # Windows
   Test-NetConnection -ComputerName cvpn-endpoint-02fbfb0cd399c382c.prod.clientvpn.us-west-2.amazonaws.com -Port 443
   
   # macOS/Linux
   nc -vuz cvpn-endpoint-02fbfb0cd399c382c.prod.clientvpn.us-west-2.amazonaws.com 443
   ```
3. Disable VPN-blocking software temporarily
4. Try from a different network

#### Error: "Authentication failed"

**Cause:** Incorrect or corrupted certificate

**Solutions:**
1. Verify you're using `wac-dev-admin-vpn-FIXED.ovpn`
2. Re-import the profile:
   - Delete existing profile
   - Import fresh copy of OVPN file
3. Check file wasn't corrupted during transfer
4. Contact administrator for new certificate

#### Error: "Profile not found"

**Cause:** Profile wasn't imported correctly

**Solutions:**
1. Go to **File** → **Manage Profiles**
2. Verify "WAC Dev Admin VPN" is listed
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
   - Enable auto-reconnect in preferences

3. **Firewall Interference**
   - Check firewall logs
   - Add AWS VPN Client to firewall exceptions

4. **ISP Blocking UDP 443**
   - Some ISPs block VPN traffic
   - Contact ISP or try different network

### Cannot Access Resources After Connecting

#### Symptom: VPN connected but can't reach 10.60.x.x addresses

**Solutions:**

1. **Verify VPN IP Assignment**
   ```bash
   # Windows
   ipconfig | findstr "10.100"
   
   # macOS/Linux
   ifconfig | grep "10.100"
   ```
   You should see an IP in 10.100.0.0/16 range

2. **Test DNS Resolution**
   ```bash
   nslookup google.com 10.60.0.2
   ```
   Should resolve successfully

3. **Check Routing Table**
   ```bash
   # Windows
   route print | findstr "10.60"
   
   # macOS/Linux
   netstat -rn | grep "10.60"
   ```
   Should show route to 10.60.0.0/16 via VPN

4. **Verify Security Groups**
   - Ensure target resource allows traffic from 10.100.0.0/16
   - Check AWS security group rules

5. **Test Basic Connectivity**
   ```bash
   ping 10.60.0.2
   ```
   Should respond successfully

### Slow Performance

#### Symptom: Slow access to Dev resources

**Solutions:**

1. **Check Connection Speed**
   - Test your internet speed
   - VPN performance depends on your connection

2. **Verify Split Tunnel**
   - Ensure split tunnel is enabled
   - Only Dev VPC traffic should use VPN

3. **Check VPN Server Load**
   - Contact administrator to check endpoint metrics
   - May need to scale VPN capacity

4. **Local Network Issues**
   - Test from different network
   - Check for local bandwidth congestion

### Certificate Expiration

#### Symptom: "Certificate expired" error

**Current Certificate Valid Until:** January 17, 2036

If you see this error before 2036:
1. Check your system clock is correct
2. Verify OVPN file is the latest version
3. Contact administrator for updated certificate

---

## Best Practices

### Security

1. **Always Disconnect When Not Needed**
   - Don't leave VPN connected 24/7
   - Disconnect when not accessing Dev resources

2. **Protect Your OVPN File**
   - Never share with unauthorized users
   - Store in secure location
   - Don't commit to version control

3. **Monitor Your Connections**
   - Review connection logs periodically
   - Report suspicious activity

### Performance

1. **Use Wired Connection When Possible**
   - More stable than WiFi
   - Better performance for large transfers

2. **Close Unnecessary Applications**
   - Reduces bandwidth competition
   - Improves VPN performance

3. **Connect Only When Needed**
   - Reduces load on VPN endpoint
   - Saves bandwidth

### Reliability

1. **Keep Client Updated**
   - Check for AWS VPN Client updates monthly
   - Install updates promptly

2. **Enable Auto-Reconnect**
   - Automatically reconnects after network changes
   - Reduces manual intervention

3. **Test Connection Regularly**
   - Verify access before critical work
   - Report issues promptly

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

All connections are logged to AWS CloudWatch:
- **Log Group:** `/aws/clientvpn/dev-admin-vpn`
- **Log Stream:** `cvpn-endpoint-02fbfb0cd399c382c-us-west-2-*`

Administrators can view:
- Connection attempts
- Authentication successes/failures
- Disconnection events
- Data transfer statistics

---

## Quick Reference Commands

### Check VPN Status

**Windows:**
```cmd
ipconfig | findstr "10.100"
route print | findstr "10.60"
```

**macOS/Linux:**
```bash
ifconfig | grep "10.100"
netstat -rn | grep "10.60"
```

### Test Connectivity

```bash
# Test DNS
ping 10.60.0.2

# Test specific resource (replace with actual IP)
ping 10.60.x.x

# Test port connectivity
telnet 10.60.x.x 22
```

### Connection Information

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

### Administrator Support

If issues persist, contact your administrator with:
- Error message (exact text)
- Connection logs (from local logs directory)
- Your VPN IP address (if connected)
- Steps to reproduce the issue
- Your operating system and version

**VPN Endpoint ID:** cvpn-endpoint-02fbfb0cd399c382c  
**AWS Account:** 749006369142  
**Region:** us-west-2

---

## FAQ

**Q: How long can I stay connected?**  
A: Maximum 24 hours, then automatic disconnect. Simply reconnect when needed.

**Q: Can I use VPN on multiple devices?**  
A: Yes, import the OVPN file on each device. All devices share the same certificate.

**Q: Does VPN work on mobile devices?**  
A: AWS VPN Client is available for Windows, macOS, and Linux only. Mobile devices are not supported.

**Q: Will VPN slow down my internet?**  
A: No, split tunnel is enabled. Only Dev VPC traffic (10.60.0.0/16) uses VPN.

**Q: Can I access production resources?**  
A: No, this VPN only provides access to Development environment (10.60.0.0/16).

**Q: What if I lose the OVPN file?**  
A: Contact your administrator for a new copy. Do not share your copy with others.

---

**Guide Version:** 1.0  
**Last Updated:** January 31, 2026  
**Next Review:** July 31, 2026
