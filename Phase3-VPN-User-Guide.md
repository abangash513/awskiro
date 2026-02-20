# AWS Client VPN - User Guide for Admins
## WAC Dev Environment Remote Access

**Date**: January 20, 2026  
**Environment**: Development (AWS_Dev)  
**Purpose**: Remote access to Domain Controllers from anywhere

---

## Quick Start

### 1. Install AWS VPN Client

Download and install the AWS VPN Client for your operating system:

**Download Link**: https://aws.amazon.com/vpn/client-vpn-download/

**Supported Platforms**:
- Windows 10/11 (64-bit)
- macOS 10.15 or later
- Ubuntu 18.04/20.04/22.04

---

### 2. Import VPN Configuration

1. **Open AWS VPN Client**
2. Click **File** → **Manage Profiles**
3. Click **Add Profile**
4. Browse to the `.ovpn` file provided by IT
5. Enter a profile name: **WAC Dev Admin VPN**
6. Click **Add Profile**

---

### 3. Connect to VPN

1. **Select Profile**: Choose "WAC Dev Admin VPN" from the dropdown
2. **Click Connect**: The button will turn green when connected
3. **Verify Connection**: You should see "Connected" status

**Connection Time**: Usually 5-10 seconds

---

### 4. Access Domain Controllers

Once connected, you can access resources in the Dev VPC:

#### RDP to Domain Controllers

```
# If you know the DC private IP (example):
mstsc /v:10.60.1.10

# Or use hostname if DNS is configured:
mstsc /v:WACDEVDC01
```

#### Ping Test

```powershell
# Test connectivity
ping 10.60.1.10
```

#### DNS Test

```powershell
# Test DNS resolution
nslookup wac.local 10.60.0.2
```

---

## Troubleshooting

### Cannot Connect to VPN

**Symptoms**: Connection fails or times out

**Solutions**:
1. Check your internet connection
2. Verify you're using the correct `.ovpn` file
3. Try disconnecting and reconnecting
4. Restart the AWS VPN Client
5. Contact IT if issue persists

---

### Connected but Cannot Access DCs

**Symptoms**: VPN shows "Connected" but RDP fails

**Solutions**:
1. Verify you're trying to access the correct IP address
2. Check if DC is running (contact IT)
3. Verify your AD credentials are correct
4. Try pinging the DC first: `ping 10.60.1.10`
5. Check if your user account has RDP permissions

---

### Slow Performance

**Symptoms**: RDP is laggy or slow

**Solutions**:
1. Check your internet speed (minimum 5 Mbps recommended)
2. Close unnecessary applications
3. Disconnect and reconnect to VPN
4. Try connecting at a different time
5. Contact IT if consistently slow

---

### Certificate Expired

**Symptoms**: "Certificate validation failed" error

**Solutions**:
1. Contact IT for a new `.ovpn` configuration file
2. Remove old profile and import new one
3. Certificates are valid for 10 years, so this should be rare

---

## Best Practices

### Security

- ✅ **Always disconnect** when not actively using VPN
- ✅ **Never share** your `.ovpn` file with others
- ✅ **Keep your laptop secure** - the VPN config contains authentication credentials
- ✅ **Use strong passwords** for RDP sessions
- ✅ **Lock your screen** when stepping away

### Performance

- ✅ **Use split tunneling** - Only AWS traffic goes through VPN (already configured)
- ✅ **Close VPN** when not needed to save costs
- ✅ **Minimize RDP window** when not actively using it
- ✅ **Use clipboard sparingly** - large copy/paste operations can be slow

### Cost Awareness

- 💰 **Connection costs**: $0.05/hour while connected
- 💰 **Data transfer**: $0.09/GB for data downloaded from AWS
- 💰 **Best practice**: Disconnect when done to minimize costs

---

## Common Tasks

### Connect for Quick Check

```
1. Open AWS VPN Client
2. Click Connect
3. RDP to DC
4. Perform your task
5. Disconnect RDP
6. Disconnect VPN
```

**Estimated Cost**: $0.05 (if under 1 hour)

---

### Extended Maintenance Window

```
1. Connect to VPN
2. Keep connection open during maintenance
3. RDP to DC as needed
4. Disconnect VPN when maintenance complete
```

**Estimated Cost**: $0.05/hour + data transfer

---

### Emergency Access

```
1. Connect from anywhere (home, hotel, etc.)
2. Access DCs immediately
3. Resolve issue
4. Disconnect
```

**Benefit**: No need to be in office or on corporate network

---

## VPN Connection Details

### What Gets Routed Through VPN

✅ **Through VPN** (Split Tunnel Enabled):
- Traffic to 10.60.0.0/16 (Dev VPC)
- RDP sessions to DCs
- DNS queries to AWS DNS

❌ **NOT Through VPN**:
- General internet browsing
- Email, Slack, Teams
- Other websites and services

**Benefit**: Better performance and lower costs

---

### IP Address Assignment

When connected, you'll receive an IP from: **10.100.0.0/16**

Example: `10.100.0.45`

This is your VPN client IP address, separate from your local network IP.

---

## Support

### IT Contact Information

- **Email**: it.admins@wac.net
- **Phone**: (555) 123-4567
- **Slack**: #it-support

### What to Include in Support Request

1. Your name and role
2. Time of connection attempt
3. Error message (screenshot if possible)
4. What you were trying to access
5. Your location (office, home, etc.)

---

## FAQ

### Q: Can I use this from home?
**A**: Yes! That's the primary purpose. Connect from anywhere with internet.

### Q: Do I need to be on corporate VPN first?
**A**: No. AWS Client VPN is independent. You can connect directly from any internet connection.

### Q: How many people can connect at once?
**A**: Currently configured for up to 10 concurrent connections.

### Q: Is my traffic encrypted?
**A**: Yes. All traffic through the VPN tunnel is encrypted with TLS 1.2+.

### Q: Can I access production DCs with this?
**A**: No. This VPN is only for Dev environment. Production has separate access controls.

### Q: What if I lose my .ovpn file?
**A**: Contact IT immediately. They can revoke the old certificate and issue you a new one.

### Q: Can I use this on my personal laptop?
**A**: Check with IT/Security. Company policy may require company-managed devices only.

### Q: Does this work on mobile devices?
**A**: AWS VPN Client is available for desktop only (Windows, macOS, Linux). Not for iOS/Android.

---

## Monitoring

Your VPN connections are logged for security and compliance:

- ✅ Connection time and duration
- ✅ Source IP address
- ✅ Data transferred
- ✅ Accessed resources

**Note**: This is for security purposes only. Normal usage is not flagged.

---

## Updates and Maintenance

### VPN Endpoint Maintenance

IT will notify you in advance of any planned maintenance:
- Typical maintenance window: Weekends, 2-4 AM
- Duration: Usually 15-30 minutes
- You'll need to reconnect after maintenance

### Certificate Renewal

Certificates are valid for 10 years. IT will contact you well in advance if renewal is needed.

---

## Comparison: When to Use What

### AWS Client VPN (This)
- ✅ Remote work from home
- ✅ Travel / on the road
- ✅ Emergency access
- ✅ Individual admin tasks

### Site-to-Site VPN (Office)
- ✅ Working from office
- ✅ Multiple users simultaneously
- ✅ Bulk operations
- ✅ Regular daily work

### AWS Systems Manager (SSM)
- ✅ Quick command-line access
- ✅ Automated scripts
- ✅ No VPN needed
- ✅ Browser-based access

**Recommendation**: Use the right tool for the job. Client VPN is best for remote RDP access.

---

## Quick Reference Card

```
┌─────────────────────────────────────────┐
│   AWS Client VPN - Quick Reference      │
├─────────────────────────────────────────┤
│ Profile: WAC Dev Admin VPN              │
│ VPC CIDR: 10.60.0.0/16                  │
│ VPN Client CIDR: 10.100.0.0/16          │
│                                         │
│ Domain Controllers:                     │
│   DC1: 10.60.1.10 (AD-A subnet)        │
│   DC2: 10.60.2.10 (AD-B subnet)        │
│                                         │
│ DNS Server: 10.60.0.2                   │
│                                         │
│ Support: it.admins@wac.net              │
│ Cost: $0.05/hour + $0.09/GB             │
└─────────────────────────────────────────┘
```

---

**Document Version**: 1.0  
**Last Updated**: January 20, 2026  
**Owner**: IT Department  
**Consultant**: Arif Bangash

