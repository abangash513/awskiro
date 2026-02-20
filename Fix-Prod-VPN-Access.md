# Fix Production VPN Access to Domain Controllers

## Current Status

✅ **VPN Connected:** Yes (IP: 10.200.0.130)  
✅ **Routes Configured:** Yes (10.70.0.0/16 via VPN)  
❌ **DC Access:** No (both 10.70.10.10 and 10.70.11.10 unreachable)

## Problem

Both Domain Controllers are not responding to:
- Ping (ICMP)
- RDP (port 3389)

## Most Likely Causes

### 1. Domain Controller Instances Are Stopped

**Check in AWS Console:**
1. Go to EC2 Console: https://us-west-2.console.aws.amazon.com/ec2/home?region=us-west-2#Instances:
2. Search for instances:
   - `i-0745579f46a34da2e` (WACPRODDC01)
   - `i-08c78db5cfc6eb412` (WACPRODDC02)
3. Check "Instance State" column

**If Stopped:**
- Select the instance
- Click "Instance state" → "Start instance"
- Wait 2-3 minutes for startup
- Try ping again

### 2. Security Groups Blocking VPN Traffic

**Check Security Groups:**
1. In EC2 Console, select WACPRODDC01 instance
2. Click "Security" tab
3. Click on the security group link
4. Check "Inbound rules"

**Required Rules:**
- **ICMP (Ping):** Allow from 10.200.0.0/16 (VPN client CIDR)
- **RDP (3389):** Allow from 10.200.0.0/16 (VPN client CIDR)
- **All Traffic:** Allow from 10.70.0.0/16 (VPC CIDR)

**To Add Rules:**
1. Click "Edit inbound rules"
2. Click "Add rule"
3. Type: All ICMP - IPv4
4. Source: 10.200.0.0/16
5. Click "Add rule"
6. Type: RDP (3389)
7. Source: 10.200.0.0/16
8. Click "Save rules"

### 3. VPN Authorization Rules Missing

**Check VPN Authorization:**
1. Go to VPC Console: https://us-west-2.console.aws.amazon.com/vpc/home?region=us-west-2#ClientVPNEndpoints:
2. Find endpoint: `cvpn-endpoint-0bbd2f9ca471fa45e`
3. Click on it
4. Go to "Authorization rules" tab

**Required Rule:**
- Destination: 10.70.0.0/16
- Grant access to: All users
- Status: Active

**If Missing:**
1. Click "Authorize ingress"
2. Destination network: 10.70.0.0/16
3. Grant access to: All users
4. Click "Add authorization rule"

### 4. VPN Routes Missing

**Check VPN Routes:**
1. In the same VPN endpoint view
2. Go to "Route table" tab

**Required Route:**
- Route destination: 10.70.0.0/16
- Target network: One of the MAD subnets
- Status: Active

**If Missing:**
1. Click "Create route"
2. Route destination: 10.70.0.0/16
3. Target VPC subnet: Select a MAD subnet
4. Click "Create route"

## Quick Fix Commands (If AWS CLI Works)

If you can refresh your AWS credentials, run these:

```powershell
# Check instance status
aws ec2 describe-instances --instance-ids i-0745579f46a34da2e i-08c78db5cfc6eb412 --region us-west-2 --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PrivateIpAddress]' --output table

# Start instances if stopped
aws ec2 start-instances --instance-ids i-0745579f46a34da2e i-08c78db5cfc6eb412 --region us-west-2

# Check VPN endpoint status
aws ec2 describe-client-vpn-endpoints --client-vpn-endpoint-ids cvpn-endpoint-0bbd2f9ca471fa45e --region us-west-2 --query 'ClientVpnEndpoints[0].Status.Code' --output text

# Check authorization rules
aws ec2 describe-client-vpn-authorization-rules --client-vpn-endpoint-id cvpn-endpoint-0bbd2f9ca471fa45e --region us-west-2

# Add authorization rule if missing
aws ec2 authorize-client-vpn-ingress --client-vpn-endpoint-id cvpn-endpoint-0bbd2f9ca471fa45e --target-network-cidr 10.70.0.0/16 --authorize-all-groups --region us-west-2
```

## Testing After Fix

After making changes, test connectivity:

```powershell
# Test ping
ping 10.70.10.10
ping 10.70.11.10

# Test RDP port
Test-NetConnection -ComputerName 10.70.10.10 -Port 3389
Test-NetConnection -ComputerName 10.70.11.10 -Port 3389

# Try RDP connection
mstsc /v:10.70.10.10
```

## Alternative: Use AWS Systems Manager (SSM)

If VPN access doesn't work, you can use SSM Session Manager:

```powershell
# Start SSM session to DC1
aws ssm start-session --target i-0745579f46a34da2e --region us-west-2

# Start SSM session to DC2
aws ssm start-session --target i-08c78db5cfc6eb412 --region us-west-2
```

This bypasses VPN and connects directly through AWS.

## Next Steps

1. **Check AWS Console** - Verify instance states and security groups
2. **Refresh AWS Credentials** - Fix the "RequestExpired" errors
3. **Re-run Diagnostic** - Run `.\Diagnose-Prod-VPN-Connectivity.ps1` again
4. **Contact AWS Admin** - If you don't have console access

## Most Likely Issue

Based on the symptoms, the most likely issue is:

**Security groups are not allowing traffic from the VPN client CIDR (10.200.0.0/16)**

The Domain Controllers' security groups probably only allow traffic from:
- The VPC CIDR (10.70.0.0/16)
- Specific management IPs

But NOT from the VPN client CIDR (10.200.0.0/16).

**Fix:** Add inbound rules to the DC security groups allowing traffic from 10.200.0.0/16.
