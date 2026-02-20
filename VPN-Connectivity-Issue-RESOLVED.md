# VPN Connectivity Issue - RESOLVED

**Date:** February 1, 2026  
**Issue:** Ping timeout to Production Domain Controllers (10.70.10.10 and 10.70.11.10)  
**Status:** ✅ RESOLVED

---

## Problem Summary

User was unable to ping or RDP to Production Domain Controllers despite:
- VPN being connected (IP: 10.200.0.130)
- VPN endpoint status: available
- Routes configured correctly
- Domain Controller instances running

---

## Root Cause

**Multiple security configuration issues:**

1. **DC Security Group Missing VPN CIDR Rules**
   - Security group `sg-0b0bd0839e63d3075` only allowed RDP from `10.1.220.0/24` (admin network)
   - Did not allow traffic from VPN client CIDR `10.200.0.0/16`

2. **VPN Endpoint Security Group Restrictions**
   - VPN security group `sg-0307723a886264cfe` only allowed traffic to itself
   - Did not allow egress traffic to DC security group

3. **Windows Firewall on DCs**
   - No explicit rule allowing RDP from VPN client CIDR

---

## Solutions Applied

### 1. Added RDP Access from VPN CIDR to DC Security Group

```powershell
aws ec2 authorize-security-group-ingress \
  --group-id sg-0b0bd0839e63d3075 \
  --ip-permissions IpProtocol=tcp,FromPort=3389,ToPort=3389,IpRanges="[{CidrIp=10.200.0.0/16,Description='RDP from VPN clients'}]" \
  --region us-west-2
```

**Result:** Added rule allowing TCP 3389 from 10.200.0.0/16

### 2. Added ICMP (Ping) Access from VPN CIDR to DC Security Group

```powershell
aws ec2 authorize-security-group-ingress \
  --group-id sg-0b0bd0839e63d3075 \
  --ip-permissions IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges="[{CidrIp=10.200.0.0/16,Description='ICMP from VPN clients'}]" \
  --region us-west-2
```

**Result:** Added rule allowing ICMP from 10.200.0.0/16

### 3. Added Windows Firewall Rules on Both DCs

```powershell
New-NetFirewallRule -DisplayName "RDP from VPN Clients" \
  -Direction Inbound \
  -Protocol TCP \
  -LocalPort 3389 \
  -RemoteAddress 10.200.0.0/16 \
  -Action Allow \
  -Enabled True
```

**Applied to:**
- WACPRODDC01 (i-0745579f46a34da2e)
- WACPRODDC02 (i-08c78db5cfc6eb412)

**Result:** Successfully created firewall rules on both DCs

### 4. Added VPN-to-DC Security Group Rules

**Egress from VPN Security Group:**
```powershell
aws ec2 authorize-security-group-egress \
  --group-id sg-0307723a886264cfe \
  --ip-permissions IpProtocol=-1,UserIdGroupPairs="[{GroupId=sg-0b0bd0839e63d3075,Description='Allow traffic to Domain Controllers'}]" \
  --region us-west-2
```

**Ingress to DC Security Group:**
```powershell
aws ec2 authorize-security-group-ingress \
  --group-id sg-0b0bd0839e63d3075 \
  --ip-permissions IpProtocol=-1,UserIdGroupPairs="[{GroupId=sg-0307723a886264cfe,Description='Allow traffic from VPN endpoint'}]" \
  --region us-west-2
```

**Result:** Established bidirectional security group rules between VPN and DCs

---

## Verification Results

### WACPRODDC01 (10.70.10.10)

**Ping Test:**
```
Reply from 10.70.10.10: bytes=32 time=64ms TTL=127
Reply from 10.70.10.10: bytes=32 time=63ms TTL=127
Packets: Sent = 2, Received = 2, Lost = 0 (0% loss)
```
✅ **SUCCESS**

**RDP Port Test:**
```
TcpTestSucceeded : True
```
✅ **SUCCESS**

### WACPRODDC02 (10.70.11.10)

**Ping Test:**
```
Reply from 10.70.11.10: bytes=32 time=67ms TTL=127
Reply from 10.70.11.10: bytes=32 time=61ms TTL=127
Packets: Sent = 2, Received = 2, Lost = 0 (0% loss)
```
✅ **SUCCESS**

**RDP Port Test:**
```
TcpTestSucceeded : True
```
✅ **SUCCESS**

---

## Configuration Summary

### VPN Configuration
| Property | Value |
|----------|-------|
| **Endpoint ID** | cvpn-endpoint-0bbd2f9ca471fa45e |
| **Status** | available |
| **Client CIDR** | 10.200.0.0/16 |
| **VPC CIDR** | 10.70.0.0/16 |
| **Authorization Rules** | 10.70.0.0/16 (active) |
| **Routes** | 10.70.0.0/16 via subnet-02c8f0d7d48510db0, subnet-02582cf0ad3fa857b (active) |

### Security Groups

**DC Security Group (sg-0b0bd0839e63d3075):**
- ✅ Allows RDP (3389) from 10.200.0.0/16
- ✅ Allows ICMP from 10.200.0.0/16
- ✅ Allows all traffic from VPN security group (sg-0307723a886264cfe)

**VPN Security Group (sg-0307723a886264cfe):**
- ✅ Allows egress to DC security group (sg-0b0bd0839e63d3075)

### Domain Controllers

| Name | Instance ID | IP Address | State | Firewall Rule |
|------|-------------|------------|-------|---------------|
| **WACPRODDC01** | i-0745579f46a34da2e | 10.70.10.10 | running | ✅ RDP from 10.200.0.0/16 |
| **WACPRODDC02** | i-08c78db5cfc6eb412 | 10.70.11.10 | running | ✅ RDP from 10.200.0.0/16 |

---

## Next Steps

### 1. Test RDP Connection

You can now RDP to the Domain Controllers:

```powershell
# RDP to WACPRODDC01
mstsc /v:10.70.10.10

# RDP to WACPRODDC02
mstsc /v:10.70.11.10
```

**Credentials:**
- Username: `WAC\your-username` or `your-username@wac.local`
- Password: Your Active Directory password

### 2. Document Changes

Update your VPN documentation to reflect the security group changes:
- VPN clients (10.200.0.0/16) can now access Domain Controllers
- Security group rules are in place for future VPN users

### 3. Test with Other VPN Users

When other administrators connect via VPN, they should now be able to:
- Ping Domain Controllers
- RDP to Domain Controllers
- Access other resources in the 10.70.0.0/16 VPC

---

## Lessons Learned

### Security Group Best Practices

1. **VPN Client CIDR Must Be Allowed**
   - Always add VPN client CIDR (10.200.0.0/16) to security groups for resources that VPN users need to access

2. **Security Group References**
   - Use security group references (not just CIDR blocks) for VPN endpoint to resource communication
   - This provides better security and easier management

3. **Windows Firewall**
   - Don't forget Windows Firewall rules on Windows instances
   - AWS security groups AND Windows Firewall must both allow traffic

4. **Testing Methodology**
   - Test both ICMP (ping) and specific ports (RDP 3389)
   - Check security groups on both source (VPN) and destination (DC)
   - Verify Windows Firewall rules via SSM

---

## Troubleshooting Tools Used

1. **AWS CLI Commands**
   - `describe-client-vpn-endpoints` - Check VPN status
   - `describe-client-vpn-authorization-rules` - Verify authorization
   - `describe-client-vpn-routes` - Check routing
   - `describe-instances` - Verify DC status
   - `describe-security-groups` - Inspect security group rules

2. **PowerShell Commands**
   - `Test-NetConnection` - Test port connectivity
   - `ping` - Test ICMP connectivity
   - `ipconfig` - Verify VPN IP assignment
   - `route print` - Check routing table

3. **AWS Systems Manager**
   - `send-command` - Execute commands on DCs
   - `get-command-invocation` - Retrieve command results

4. **Custom Scripts**
   - `Diagnose-Prod-VPN-Connectivity.ps1` - Comprehensive diagnostic
   - `Add-VPN-Firewall-Rule.ps1` - Add Windows Firewall rules

---

## Files Created

1. **Diagnose-Prod-VPN-Connectivity.ps1** - Diagnostic script for Production VPN
2. **Fix-Prod-VPN-Access.md** - Troubleshooting guide
3. **Add-VPN-Firewall-Rule.ps1** - Script to add Windows Firewall rules
4. **VPN-Connectivity-Issue-RESOLVED.md** - This document

---

## Summary

The VPN connectivity issue was caused by missing security group rules and Windows Firewall configurations. After adding:
- CIDR-based rules (10.200.0.0/16) to DC security group
- Security group reference rules between VPN and DC security groups
- Windows Firewall rules on both DCs

Both Domain Controllers are now fully accessible via VPN for ping and RDP.

**Status:** ✅ RESOLVED  
**Verified:** February 1, 2026  
**Tested By:** Kiro AI Assistant

---

**END OF RESOLUTION DOCUMENT**
