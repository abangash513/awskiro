# WAC Production Client VPN - Deployment Guide

**Purpose:** Remote administration access to Production VPC and Domain Controllers  
**Date:** January 31, 2026  
**Environment:** Production (Account: 466090007609)  
**Status:** Ready to Deploy

---

## Overview

This guide will help you deploy the WAC Production Client VPN endpoint for secure remote access to:
- Production VPC (10.70.0.0/16)
- Domain Controller WACPRODDC01 (10.70.10.10)
- Domain Controller WACPRODDC02 (10.70.11.10)

---

## Network Architecture

### Production VPC Configuration

| Component | Value |
|-----------|-------|
| **VPC ID** | vpc-014b66d7ca2309134 |
| **VPC CIDR** | 10.70.0.0/16 |
| **VPC Name** | Prod-VPC |
| **Environment** | Production |
| **Region** | us-west-2 |

### Subnets

| Subnet ID | Name | AZ | CIDR | Type |
|-----------|------|----|----|------|
| subnet-0e00d16d934c67c04 | Public-2a | us-west-2a | 10.70.0.0/24 | Public |
| subnet-08b138fe9b8fb1560 | Public-2b | us-west-2b | 10.70.2.0/24 | Public |
| subnet-02c8f0d7d48510db0 | Private-2a | us-west-2a | 10.70.1.0/24 | Private |
| subnet-02582cf0ad3fa857b | Private-2b | us-west-2b | 10.70.3.0/24 | Private |
| subnet-05241411b9228d65f | MAD-2a | us-west-2a | 10.70.10.0/24 | MAD |
| subnet-0c6eec3752dd3e665 | MAD-2b | us-west-2b | 10.70.11.0/24 | MAD |

### Domain Controllers

| Name | Instance ID | Private IP | Subnet | AZ |
|------|-------------|------------|--------|-----|
| **WACPRODDC01** | i-0745579f46a34da2e | 10.70.10.10 | MAD-2a | us-west-2a |
| **WACPRODDC02** | i-08c78db5cfc6eb412 | 10.70.11.10 | MAD-2b | us-west-2b |

---

## VPN Configuration

### Client VPN Settings

| Setting | Value |
|---------|-------|
| **Client CIDR** | 10.200.0.0/16 |
| **DNS Server** | 10.70.0.2 (VPC DNS) |
| **Protocol** | OpenVPN over UDP |
| **Port** | 443 |
| **Encryption** | AES-256-GCM |
| **Split Tunnel** | Enabled |
| **Session Timeout** | 24 hours |

### Network Associations

The VPN will be associated with both private subnets for high availability:
- **Subnet 1:** subnet-02c8f0d7d48510db0 (Private-2a, us-west-2a)
- **Subnet 2:** subnet-02582cf0ad3fa857b (Private-2b, us-west-2b)

### Authorization Rules

- **Target:** 10.70.0.0/16 (entire Production VPC)
- **Access:** All authenticated users
- **Description:** Allow access to entire Production VPC

### Routes

- **Destination:** 10.70.0.0/16
- **Target:** Private subnets
- **Description:** Route to Production VPC

---

## Prerequisites

Before deploying, ensure you have:

- [x] AWS CLI configured with Production account credentials
- [x] Appropriate IAM permissions (EC2, ACM, Logs)
- [x] Certificates already imported to ACM:
  - Server: arn:aws:acm:us-west-2:466090007609:certificate/fc6b385c-1d75-49de-91a2-93fae977030a
  - Client: arn:aws:acm:us-west-2:466090007609:certificate/e3437609-1535-4ed7-b6e8-dceb076f67df
- [x] Certificate files in: vpn-certs-prod-20260119-220611/
- [x] PowerShell or Bash terminal

---

## Deployment Steps

### Option 1: Automated Deployment (Recommended)

**Using PowerShell Script:**

```powershell
# Run the automated setup script
.\Setup-Prod-Client-VPN.ps1
```

The script will:
1. Create CloudWatch log group
2. Create VPN endpoint
3. Wait for endpoint to become available
4. Associate with both private subnets
5. Add authorization rules
6. Configure routes
7. Generate OVPN configuration file
8. Update configuration JSON

**Estimated Time:** 10-15 minutes

### Option 2: Manual Deployment

If you prefer manual deployment, follow these steps:

#### Step 1: Create CloudWatch Log Group

```bash
aws logs create-log-group \
  --log-group-name /aws/clientvpn/prod-admin-vpn \
  --region us-west-2

aws logs put-retention-policy \
  --log-group-name /aws/clientvpn/prod-admin-vpn \
  --retention-in-days 180 \
  --region us-west-2
```

#### Step 2: Create VPN Endpoint

```bash
aws ec2 create-client-vpn-endpoint \
  --client-cidr-block "10.200.0.0/16" \
  --server-certificate-arn "arn:aws:acm:us-west-2:466090007609:certificate/fc6b385c-1d75-49de-91a2-93fae977030a" \
  --authentication-options Type=certificate-authentication,MutualAuthentication={ClientRootCertificateChainArn=arn:aws:acm:us-west-2:466090007609:certificate/e3437609-1535-4ed7-b6e8-dceb076f67df} \
  --connection-log-options Enabled=true,CloudwatchLogGroup=/aws/clientvpn/prod-admin-vpn \
  --dns-servers 10.70.0.2 \
  --vpc-id vpc-014b66d7ca2309134 \
  --description "WAC Production Admin VPN - Remote access to Domain Controllers" \
  --split-tunnel \
  --transport-protocol udp \
  --vpn-port 443 \
  --region us-west-2 \
  --tag-specifications 'ResourceType=client-vpn-endpoint,Tags=[{Key=Name,Value=WAC-Prod-Admin-VPN},{Key=Environment,Value=Production},{Key=Purpose,Value=DomainControllerAccess}]'
```

**Save the returned ClientVpnEndpointId** - you'll need it for subsequent steps.

#### Step 3: Wait for Endpoint to Become Available

```bash
# Check status
aws ec2 describe-client-vpn-endpoints \
  --client-vpn-endpoint-ids cvpn-endpoint-xxxxx \
  --region us-west-2 \
  --query 'ClientVpnEndpoints[0].Status.Code'
```

Wait until status is "available" (typically 5-10 minutes).

#### Step 4: Associate with Subnets

```bash
# Associate with Private-2a
aws ec2 associate-client-vpn-target-network \
  --client-vpn-endpoint-id cvpn-endpoint-xxxxx \
  --subnet-id subnet-02c8f0d7d48510db0 \
  --region us-west-2

# Associate with Private-2b
aws ec2 associate-client-vpn-target-network \
  --client-vpn-endpoint-id cvpn-endpoint-xxxxx \
  --subnet-id subnet-02582cf0ad3fa857b \
  --region us-west-2
```

#### Step 5: Add Authorization Rule

```bash
aws ec2 authorize-client-vpn-ingress \
  --client-vpn-endpoint-id cvpn-endpoint-xxxxx \
  --target-network-cidr 10.70.0.0/16 \
  --authorize-all-groups \
  --description "Allow access to entire Production VPC" \
  --region us-west-2
```

#### Step 6: Add Route

```bash
aws ec2 create-client-vpn-route \
  --client-vpn-endpoint-id cvpn-endpoint-xxxxx \
  --destination-cidr-block 10.70.0.0/16 \
  --target-vpc-subnet-id subnet-02c8f0d7d48510db0 \
  --description "Route to Production VPC via Private-2a" \
  --region us-west-2
```

#### Step 7: Generate OVPN Configuration

```bash
# Export VPN configuration
aws ec2 export-client-vpn-client-configuration \
  --client-vpn-endpoint-id cvpn-endpoint-xxxxx \
  --region us-west-2 \
  --output text > wac-prod-admin-vpn-base.ovpn

# Manually add certificates to the file:
# <ca>
# [contents of vpn-certs-prod-20260119-220611/ca.crt]
# </ca>
#
# <cert>
# [contents of vpn-certs-prod-20260119-220611/client1.crt]
# </cert>
#
# <key>
# [contents of vpn-certs-prod-20260119-220611/client1.key]
# </key>
```

---

## Post-Deployment Verification

### 1. Verify Endpoint Status

```bash
aws ec2 describe-client-vpn-endpoints \
  --client-vpn-endpoint-ids cvpn-endpoint-xxxxx \
  --region us-west-2
```

**Expected Output:**
- Status: available
- VpcId: vpc-014b66d7ca2309134
- ClientCidrBlock: 10.200.0.0/16
- DnsServers: 10.70.0.2

### 2. Verify Network Associations

```bash
aws ec2 describe-client-vpn-target-networks \
  --client-vpn-endpoint-id cvpn-endpoint-xxxxx \
  --region us-west-2
```

**Expected:** 2 associations (Private-2a and Private-2b), both with status "associated"

### 3. Verify Authorization Rules

```bash
aws ec2 describe-client-vpn-authorization-rules \
  --client-vpn-endpoint-id cvpn-endpoint-xxxxx \
  --region us-west-2
```

**Expected:** Rule for 10.70.0.0/16 with status "active"

### 4. Verify Routes

```bash
aws ec2 describe-client-vpn-routes \
  --client-vpn-endpoint-id cvpn-endpoint-xxxxx \
  --region us-west-2
```

**Expected:** Route to 10.70.0.0/16 with status "active"

### 5. Verify OVPN File

```bash
# Check file exists and has content
ls -lh wac-prod-admin-vpn.ovpn

# Verify certificates are embedded
grep -c "BEGIN CERTIFICATE" wac-prod-admin-vpn.ovpn
# Should return 2 (CA and client cert)

grep -c "BEGIN PRIVATE KEY" wac-prod-admin-vpn.ovpn
# Should return 1
```

---

## Client Configuration

### Install AWS VPN Client

**Download Links:**
- Windows: https://d20adtppz83p9s.cloudfront.net/WPF/latest/AWS_VPN_Client.msi
- macOS: https://d20adtppz83p9s.cloudfront.net/OSX/latest/AWS_VPN_Client.pkg
- Linux: https://d20adtppz83p9s.cloudfront.net/GTK/latest/awsvpnclient_amd64.deb

### Import VPN Profile

1. Open AWS VPN Client
2. Click **File** → **Manage Profiles**
3. Click **Add Profile**
4. Browse to `wac-prod-admin-vpn.ovpn`
5. Display Name: **WAC Prod Admin VPN**
6. Click **Add Profile**

### Connect to VPN

1. Select "WAC Prod Admin VPN" from profile list
2. Click **Connect**
3. Wait for green status (connected)
4. Verify you receive an IP in 10.200.0.0/16 range

---

## Testing Access

### Test 1: Verify VPN IP Assignment

**Windows:**
```cmd
ipconfig | findstr "10.200"
```

**macOS/Linux:**
```bash
ifconfig | grep "10.200"
```

**Expected:** You should see an IP address in 10.200.0.0/16 range

### Test 2: Test DNS Resolution

```bash
nslookup wacproddc01.wac.local 10.70.0.2
nslookup wacproddc02.wac.local 10.70.0.2
```

**Expected:** Should resolve to 10.70.10.10 and 10.70.11.10

### Test 3: Ping Domain Controllers

```bash
ping 10.70.10.10
ping 10.70.11.10
```

**Expected:** Should receive replies from both DCs

### Test 4: RDP to Domain Controllers

**Windows:**
```cmd
mstsc /v:10.70.10.10
mstsc /v:10.70.11.10
```

**macOS:**
- Use Microsoft Remote Desktop app
- Connect to 10.70.10.10 and 10.70.11.10

**Expected:** RDP connection should establish successfully

### Test 5: Verify CloudWatch Logging

```bash
aws logs tail /aws/clientvpn/prod-admin-vpn --follow --region us-west-2
```

**Expected:** Should see connection logs

---

## Security Configuration

### Firewall Rules

Ensure the following ports are allowed:

**Outbound (from client):**
- UDP 443 to AWS VPN endpoint

**Inbound (to Domain Controllers):**
- TCP 3389 (RDP) from 10.200.0.0/16
- TCP 389 (LDAP) from 10.200.0.0/16
- TCP 636 (LDAPS) from 10.200.0.0/16
- TCP 88 (Kerberos) from 10.200.0.0/16
- TCP 53 (DNS) from 10.200.0.0/16
- UDP 53 (DNS) from 10.200.0.0/16

### Security Group Configuration

**Domain Controller Security Groups should allow:**

```bash
# RDP access from VPN clients
Type: RDP (3389)
Protocol: TCP
Port: 3389
Source: 10.200.0.0/16

# LDAP access
Type: Custom TCP
Protocol: TCP
Port: 389
Source: 10.200.0.0/16

# LDAPS access
Type: Custom TCP
Protocol: TCP
Port: 636
Source: 10.200.0.0/16

# Kerberos
Type: Custom TCP
Protocol: TCP
Port: 88
Source: 10.200.0.0/16

# DNS
Type: DNS (TCP)
Protocol: TCP
Port: 53
Source: 10.200.0.0/16

Type: DNS (UDP)
Protocol: UDP
Port: 53
Source: 10.200.0.0/16
```

---

## Monitoring and Logging

### CloudWatch Logs

**Log Group:** `/aws/clientvpn/prod-admin-vpn`  
**Retention:** 180 days  
**Region:** us-west-2

**Log Events Include:**
- Connection attempts
- Authentication successes/failures
- Disconnection events
- Data transfer statistics

### View Logs

**AWS Console:**
1. Navigate to CloudWatch → Log groups
2. Select `/aws/clientvpn/prod-admin-vpn`
3. View log streams

**AWS CLI:**
```bash
# Tail logs in real-time
aws logs tail /aws/clientvpn/prod-admin-vpn --follow --region us-west-2

# Query specific time range
aws logs filter-log-events \
  --log-group-name /aws/clientvpn/prod-admin-vpn \
  --start-time $(date -d '1 hour ago' +%s)000 \
  --region us-west-2
```

### Recommended CloudWatch Alarms

Create alarms for:

1. **Failed Authentication Attempts**
   - Metric: Failed authentication count
   - Threshold: > 5 in 5 minutes
   - Action: SNS notification to security team

2. **Unusual Connection Volume**
   - Metric: Active connections
   - Threshold: > 20 concurrent connections
   - Action: SNS notification to administrators

3. **Endpoint Availability**
   - Metric: Endpoint status
   - Threshold: Not available
   - Action: SNS notification to operations team

---

## Troubleshooting

### Issue: Cannot Connect to VPN

**Symptoms:** Connection timeout or authentication failure

**Solutions:**
1. Verify endpoint status is "available"
2. Check firewall allows UDP 443 outbound
3. Verify OVPN file has certificates embedded
4. Try from different network
5. Check CloudWatch logs for error messages

### Issue: Connected but Cannot Access Domain Controllers

**Symptoms:** VPN connected but cannot ping/RDP to DCs

**Solutions:**
1. Verify VPN IP is in 10.200.0.0/16 range
2. Check authorization rules are active
3. Verify routes are configured
4. Check DC security groups allow traffic from 10.200.0.0/16
5. Test DNS resolution: `nslookup 10.70.10.10 10.70.0.2`

### Issue: DNS Not Resolving

**Symptoms:** Cannot resolve internal hostnames

**Solutions:**
1. Verify DNS server is set to 10.70.0.2
2. Check VPN configuration has correct DNS settings
3. Test direct IP access to verify routing works
4. Verify Route 53 resolver or DNS server is running

### Issue: Slow Performance

**Symptoms:** Slow RDP or file transfer

**Solutions:**
1. Check internet connection speed
2. Verify split tunnel is enabled (only VPC traffic uses VPN)
3. Test from wired connection instead of WiFi
4. Check VPN endpoint metrics in CloudWatch
5. Consider adding more subnet associations

---

## Cost Estimate

### Monthly Costs (us-west-2)

**VPN Endpoint:**
- Endpoint association: $0.10/hour × 2 subnets × 730 hours = $146/month
- Connection hours: $0.05/hour per connection
  - Example: 10 users × 8 hours/day × 22 days = 1,760 hours = $88/month
- **Subtotal:** ~$234/month

**Data Transfer:**
- Data transfer out: Standard AWS rates (~$0.09/GB)
- Estimated: 100 GB/month = $9/month

**CloudWatch Logs:**
- Log storage: $0.50/GB
- Estimated: 5 GB/month = $2.50/month

**Total Estimated Cost:** ~$245/month

**Note:** Actual costs vary based on usage patterns.

---

## Maintenance

### Regular Tasks

**Weekly:**
- Review CloudWatch logs for unusual activity
- Verify endpoint status
- Check connection metrics

**Monthly:**
- Review user access list
- Audit CloudWatch logs
- Review cost and usage
- Update documentation if needed

**Quarterly:**
- Review security group rules
- Audit who has VPN access
- Test disaster recovery procedures
- Review and update this guide

**Annually:**
- Review certificate expiration (valid until 2036)
- Evaluate need for individual user certificates
- Review network architecture
- Update security policies

---

## Disaster Recovery

### Backup Procedures

**Certificate Backup:**
```bash
# Create encrypted backup of certificates
tar -czf vpn-certs-prod-backup-$(date +%Y%m%d).tar.gz vpn-certs-prod-20260119-220611/
gpg --symmetric --cipher-algo AES256 vpn-certs-prod-backup-*.tar.gz
```

**Configuration Backup:**
- Save `prod-vpn-config.json`
- Save `wac-prod-admin-vpn.ovpn`
- Document endpoint ID and settings

### Recovery Procedures

**If VPN Endpoint is Deleted:**
1. Run `Setup-Prod-Client-VPN.ps1` again
2. Certificates are still in ACM (no need to re-import)
3. New endpoint ID will be generated
4. New OVPN file will be created
5. Redistribute to users

**If Certificates are Lost:**
1. Restore from encrypted backup
2. Verify certificates in ACM
3. If not in ACM, re-import using:
   ```bash
   aws acm import-certificate \
     --certificate fileb://server.crt \
     --private-key fileb://server.key \
     --certificate-chain fileb://ca.crt \
     --region us-west-2
   ```

---

## Support and Contacts

### AWS Resources

**VPN Endpoint ID:** [Will be generated during deployment]  
**AWS Account:** 466090007609  
**Region:** us-west-2  
**CloudWatch Logs:** /aws/clientvpn/prod-admin-vpn

### Documentation

- AWS Client VPN Documentation: https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/
- AWS VPN Client Download: https://aws.amazon.com/vpn/client-vpn-download/
- Troubleshooting Guide: https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/troubleshooting.html

### Internal Contacts

- **AWS Administrator:** [Your team]
- **Network Team:** [Your team]
- **Security Team:** [Your team]
- **Domain Controller Admins:** [Your team]

---

## Appendix A: Network Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    On-Premises / Remote                      │
│                                                              │
│  ┌──────────────┐                                           │
│  │ Admin Laptop │ (10.200.x.x via VPN)                     │
│  └──────┬───────┘                                           │
│         │                                                    │
└─────────┼────────────────────────────────────────────────────┘
          │ UDP 443
          │ (OpenVPN)
          ▼
┌─────────────────────────────────────────────────────────────┐
│              AWS Client VPN Endpoint                         │
│         (cvpn-endpoint-xxxxx)                               │
│                                                              │
│  Client CIDR: 10.200.0.0/16                                 │
│  Authentication: Mutual TLS (Certificates)                   │
│  Encryption: AES-256-GCM                                     │
└─────────────────────────────────────────────────────────────┘
          │
          │ Associated with
          ▼
┌─────────────────────────────────────────────────────────────┐
│           Production VPC (vpc-014b66d7ca2309134)            │
│                    10.70.0.0/16                             │
│                                                              │
│  ┌────────────────────┐      ┌────────────────────┐        │
│  │   us-west-2a       │      │   us-west-2b       │        │
│  │                    │      │                    │        │
│  │  Private-2a        │      │  Private-2b        │        │
│  │  10.70.1.0/24      │      │  10.70.3.0/24      │        │
│  │  (VPN Associated)  │      │  (VPN Associated)  │        │
│  └────────────────────┘      └────────────────────┘        │
│                                                              │
│  ┌────────────────────┐      ┌────────────────────┐        │
│  │  MAD-2a            │      │  MAD-2b            │        │
│  │  10.70.10.0/24     │      │  10.70.11.0/24     │        │
│  │                    │      │                    │        │
│  │  ┌──────────────┐  │      │  ┌──────────────┐  │        │
│  │  │ WACPRODDC01  │  │      │  │ WACPRODDC02  │  │        │
│  │  │ 10.70.10.10  │  │      │  │ 10.70.11.10  │  │        │
│  │  └──────────────┘  │      │  └──────────────┘  │        │
│  └────────────────────┘      └────────────────────┘        │
│                                                              │
│  DNS: 10.70.0.2                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Appendix B: Certificate Details

**CA Certificate:**
- Subject: CN=wac-prod-vpn-ca.local, OU=IT, O=WAC, L=SanFrancisco, ST=California, C=US
- Valid: 2026-01-20 to 2036-01-18
- Key: RSA 2048-bit

**Server Certificate:**
- ARN: arn:aws:acm:us-west-2:466090007609:certificate/fc6b385c-1d75-49de-91a2-93fae977030a
- Subject: CN=server.wac-prod-vpn.local, OU=IT, O=WAC, L=SanFrancisco, ST=California, C=US
- SAN: server.wac-prod-vpn.local, *.wac-prod-vpn.local
- Valid: 2026-01-19 to 2036-01-17

**Client Certificate:**
- ARN: arn:aws:acm:us-west-2:466090007609:certificate/e3437609-1535-4ed7-b6e8-dceb076f67df
- Subject: CN=client1.wac-prod-vpn.local, OU=IT, O=WAC, L=SanFrancisco, ST=California, C=US
- Valid: 2026-01-19 to 2036-01-17

---

**Document Version:** 1.0  
**Last Updated:** January 31, 2026  
**Next Review:** After deployment  
**Status:** Ready for Deployment
