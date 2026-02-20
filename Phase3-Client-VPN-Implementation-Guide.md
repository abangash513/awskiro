# Phase 3: AWS Client VPN Implementation Guide
## Remote Admin Access to Domain Controllers

**Date**: January 20, 2026  
**Account**: AWS_Dev (749006369142)  
**Purpose**: Enable secure remote access for admins from anywhere

---

## Overview

AWS Client VPN allows individual admins to connect securely to AWS resources from any location using a VPN client application. This is ideal for:
- Remote work scenarios
- Admins working from home
- Emergency access when traveling
- Contractors needing temporary access

---

## Architecture

```
Admin Laptop (anywhere) 
    ↓
AWS VPN Client App
    ↓
AWS Client VPN Endpoint (in AWS VPC)
    ↓
Domain Controllers (Private Subnet)
```

---

## Prerequisites

- ✅ VPC with private subnets (where DCs will be)
- ✅ Admin access to AWS account
- ✅ Certificate management capability
- ⚠️ Estimated Cost: $0.10/hour per connection + $0.05/GB data transfer

---

## Phase 3 Implementation Steps

### Step 1: Generate Certificates

AWS Client VPN requires certificates for authentication. We'll use AWS Certificate Manager (ACM) with self-signed certificates.

#### Option A: Using Easy-RSA (Recommended for Dev/Test)

```powershell
# Install Easy-RSA (if not already installed)
# Download from: https://github.com/OpenVPN/easy-rsa/releases

# 1. Clone Easy-RSA
git clone https://github.com/OpenVPN/easy-rsa.git
cd easy-rsa/easyrsa3

# 2. Initialize PKI
./easyrsa init-pki

# 3. Build CA
./easyrsa build-ca nopass
# Enter "WAC-VPN-CA" when prompted for Common Name

# 4. Generate server certificate
./easyrsa build-server-full server nopass

# 5. Generate client certificate
./easyrsa build-client-full client1.domain.tld nopass

# 6. Copy certificates to a working directory
mkdir ~/vpn-certs
cp pki/ca.crt ~/vpn-certs/
cp pki/issued/server.crt ~/vpn-certs/
cp pki/private/server.key ~/vpn-certs/
cp pki/issued/client1.domain.tld.crt ~/vpn-certs/
cp pki/private/client1.domain.tld.key ~/vpn-certs/
```

#### Option B: Using OpenSSL (Alternative)

```powershell
# Create working directory
mkdir vpn-certs
cd vpn-certs

# 1. Generate CA private key
openssl genrsa -out ca.key 2048

# 2. Generate CA certificate
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt -subj "/C=US/ST=State/L=City/O=WAC/OU=IT/CN=WAC-VPN-CA"

# 3. Generate server private key
openssl genrsa -out server.key 2048

# 4. Generate server certificate signing request
openssl req -new -key server.key -out server.csr -subj "/C=US/ST=State/L=City/O=WAC/OU=IT/CN=server"

# 5. Sign server certificate with CA
openssl x509 -req -days 3650 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt

# 6. Generate client private key
openssl genrsa -out client1.key 2048

# 7. Generate client certificate signing request
openssl req -new -key client1.key -out client1.csr -subj "/C=US/ST=State/L=City/O=WAC/OU=IT/CN=client1"

# 8. Sign client certificate with CA
openssl x509 -req -days 3650 -in client1.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client1.crt
```

---

### Step 2: Import Certificates to AWS Certificate Manager

```powershell
# Import server certificate
aws acm import-certificate \
  --certificate fileb://server.crt \
  --private-key fileb://server.key \
  --certificate-chain fileb://ca.crt \
  --region us-west-2

# Save the ARN output - you'll need it later
# Example: arn:aws:acm:us-west-2:749006369142:certificate/xxxxx

# Import client certificate (for mutual TLS)
aws acm import-certificate \
  --certificate fileb://client1.crt \
  --private-key fileb://client1.key \
  --certificate-chain fileb://ca.crt \
  --region us-west-2

# Save this ARN too
```

---

### Step 3: Create Client VPN Endpoint

```powershell
# First, get your VPC ID and subnet IDs
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' --output table

aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-xxxxx" \
  --query 'Subnets[*].[SubnetId,AvailabilityZone,CidrBlock,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# Create Client VPN Endpoint
aws ec2 create-client-vpn-endpoint \
  --client-cidr-block "10.100.0.0/16" \
  --server-certificate-arn "arn:aws:acm:us-west-2:749006369142:certificate/xxxxx" \
  --authentication-options Type=certificate-authentication,MutualAuthentication={ClientRootCertificateChainArn=arn:aws:acm:us-west-2:749006369142:certificate/yyyyy} \
  --connection-log-options Enabled=true,CloudwatchLogGroup=/aws/clientvpn/dev-admin-vpn \
  --dns-servers 10.0.0.2 \
  --vpc-id vpc-xxxxx \
  --description "WAC Dev Admin VPN" \
  --split-tunnel \
  --tag-specifications 'ResourceType=client-vpn-endpoint,Tags=[{Key=Name,Value=WAC-Dev-Admin-VPN},{Key=Environment,Value=Development}]'

# Save the Client VPN Endpoint ID from output
# Example: cvpn-endpoint-xxxxx
```

---

### Step 4: Associate VPN Endpoint with Subnets

```powershell
# Associate with first subnet (different AZ for HA)
aws ec2 associate-client-vpn-target-network \
  --client-vpn-endpoint-id cvpn-endpoint-xxxxx \
  --subnet-id subnet-xxxxx

# Associate with second subnet (for high availability)
aws ec2 associate-client-vpn-target-network \
  --client-vpn-endpoint-id cvpn-endpoint-xxxxx \
  --subnet-id subnet-yyyyy
```

---

### Step 5: Add Authorization Rules

```powershell
# Allow all authenticated users to access the VPC CIDR
aws ec2 authorize-client-vpn-ingress \
  --client-vpn-endpoint-id cvpn-endpoint-xxxxx \
  --target-network-cidr 10.0.0.0/16 \
  --authorize-all-groups \
  --description "Allow access to VPC"

# If you want to restrict to specific subnets (e.g., only DC subnet)
aws ec2 authorize-client-vpn-ingress \
  --client-vpn-endpoint-id cvpn-endpoint-xxxxx \
  --target-network-cidr 10.0.1.0/24 \
  --authorize-all-groups \
  --description "Allow access to DC subnet only"
```

---

### Step 6: Add Route to VPC

```powershell
# Add route to allow traffic to VPC
aws ec2 create-client-vpn-route \
  --client-vpn-endpoint-id cvpn-endpoint-xxxxx \
  --destination-cidr-block 10.0.0.0/16 \
  --target-vpc-subnet-id subnet-xxxxx \
  --description "Route to VPC"
```

---

### Step 7: Create CloudWatch Log Group

```powershell
# Create log group for VPN connection logs
aws logs create-log-group --log-group-name /aws/clientvpn/dev-admin-vpn

# Set retention (optional - 30 days)
aws logs put-retention-policy \
  --log-group-name /aws/clientvpn/dev-admin-vpn \
  --retention-in-days 30
```

---

### Step 8: Download VPN Client Configuration

```powershell
# Download the client configuration file
aws ec2 export-client-vpn-client-configuration \
  --client-vpn-endpoint-id cvpn-endpoint-xxxxx \
  --output text > wac-dev-admin-vpn.ovpn
```

---

### Step 9: Modify Configuration File

Edit the `wac-dev-admin-vpn.ovpn` file and add the client certificate and key:

```
# Add these lines at the end of the .ovpn file

<cert>
[paste contents of client1.crt here]
</cert>

<key>
[paste contents of client1.key here]
</key>
```

---

### Step 10: Distribute to Admins

1. **Install AWS VPN Client**
   - Download from: https://aws.amazon.com/vpn/client-vpn-download/
   - Available for Windows, macOS, Linux

2. **Import Configuration**
   - Open AWS VPN Client
   - Click "File" → "Manage Profiles"
   - Click "Add Profile"
   - Browse to `wac-dev-admin-vpn.ovpn`
   - Give it a name: "WAC Dev Admin VPN"

3. **Connect**
   - Select the profile
   - Click "Connect"
   - Status should show "Connected"

4. **Test Access**
   - Try to RDP to a Domain Controller private IP
   - `mstsc /v:10.0.1.10`

---

## Security Best Practices

### 1. Use Active Directory Authentication (Production)

For production, integrate with Active Directory:

```powershell
# Create Client VPN with AD authentication
aws ec2 create-client-vpn-endpoint \
  --client-cidr-block "10.100.0.0/16" \
  --server-certificate-arn "arn:aws:acm:..." \
  --authentication-options Type=directory-service-authentication,ActiveDirectory={DirectoryId=d-xxxxx} \
  --connection-log-options Enabled=true,CloudwatchLogGroup=/aws/clientvpn/prod-admin-vpn \
  --dns-servers 10.0.0.2 \
  --vpc-id vpc-xxxxx \
  --split-tunnel
```

### 2. Enable MFA

```powershell
# Enable SAML-based authentication with MFA
aws ec2 create-client-vpn-endpoint \
  --authentication-options Type=federated-authentication,SAMLProviderArn=arn:aws:iam::749006369142:saml-provider/YourIdP
```

### 3. Implement Security Groups

```powershell
# Create security group for VPN clients
aws ec2 create-security-group \
  --group-name vpn-client-sg \
  --description "Security group for VPN clients" \
  --vpc-id vpc-xxxxx

# Allow RDP only from VPN client CIDR
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 3389 \
  --cidr 10.100.0.0/16
```

### 4. Enable Split Tunneling

Split tunneling ensures only AWS traffic goes through VPN (not all internet traffic):

```powershell
# Already enabled with --split-tunnel flag
# This improves performance and reduces data transfer costs
```

---

## Monitoring and Alerts

### CloudWatch Metrics

```powershell
# Create alarm for active connections
aws cloudwatch put-metric-alarm \
  --alarm-name "ClientVPN-High-Connections" \
  --alarm-description "Alert when VPN connections exceed threshold" \
  --metric-name "ActiveConnectionsCount" \
  --namespace "AWS/ClientVPN" \
  --statistic Average \
  --period 300 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --dimensions Name=Endpoint,Value=cvpn-endpoint-xxxxx
```

### Connection Logs

```powershell
# Query connection logs
aws logs filter-log-events \
  --log-group-name /aws/clientvpn/dev-admin-vpn \
  --start-time $(date -u -d '1 hour ago' +%s)000 \
  --filter-pattern "connection-attempt"
```

---

## Cost Optimization

### Pricing Breakdown

| Component | Cost |
|-----------|------|
| VPN Endpoint (per hour) | $0.10/hour (~$73/month) |
| VPN Connection (per hour) | $0.05/hour per connection |
| Data Transfer (out) | $0.09/GB |
| Certificate Manager | Free |

### Cost Saving Tips

1. **Use split tunneling** - Only AWS traffic uses VPN
2. **Limit concurrent connections** - Set max connections
3. **Delete endpoint when not needed** - For dev/test environments
4. **Monitor data transfer** - Set up billing alerts

```powershell
# Set connection limit
aws ec2 modify-client-vpn-endpoint \
  --client-vpn-endpoint-id cvpn-endpoint-xxxxx \
  --max-connections 5
```

---

## User Management

### Add New Admin

1. Generate new client certificate
2. Import to ACM (if using mutual TLS)
3. Create new .ovpn file with their certificate
4. Distribute securely (encrypted email, secure file share)

### Revoke Access

```powershell
# Revoke a specific certificate
aws acm delete-certificate --certificate-arn arn:aws:acm:...

# Or disconnect specific user
aws ec2 terminate-client-vpn-connections \
  --client-vpn-endpoint-id cvpn-endpoint-xxxxx \
  --connection-id cvpn-connection-xxxxx
```

---

## Troubleshooting

### Issue: Cannot connect to VPN
**Solutions:**
1. Verify certificate is valid: `openssl x509 -in client1.crt -text -noout`
2. Check VPN endpoint status: `aws ec2 describe-client-vpn-endpoints`
3. Verify subnet associations exist
4. Check security groups allow VPN traffic

### Issue: Connected but cannot access DCs
**Solutions:**
1. Verify authorization rules: `aws ec2 describe-client-vpn-authorization-rules`
2. Check routes: `aws ec2 describe-client-vpn-routes`
3. Verify DC security groups allow traffic from VPN CIDR (10.100.0.0/16)
4. Test DNS resolution

### Issue: Slow performance
**Solutions:**
1. Enable split tunneling (if not already)
2. Check data transfer metrics
3. Verify subnet associations in multiple AZs
4. Consider increasing VPN endpoint size

---

## Comparison: Site-to-Site VPN vs Client VPN

| Feature | Site-to-Site VPN | Client VPN |
|---------|------------------|------------|
| **Use Case** | Office to AWS | Individual remote access |
| **Setup** | One-time | Per user |
| **Cost** | $36/month fixed | $73/month + $0.05/hour per user |
| **Scalability** | All office users | Individual users |
| **Flexibility** | Office only | Anywhere |
| **Management** | Network team | IT admin |
| **Best For** | Primary access | Remote/mobile access |

---

## Quick Reference Commands

### Check VPN Status
```powershell
aws ec2 describe-client-vpn-endpoints \
  --client-vpn-endpoint-ids cvpn-endpoint-xxxxx
```

### View Active Connections
```powershell
aws ec2 describe-client-vpn-connections \
  --client-vpn-endpoint-id cvpn-endpoint-xxxxx
```

### Disconnect All Users
```powershell
aws ec2 terminate-client-vpn-connections \
  --client-vpn-endpoint-id cvpn-endpoint-xxxxx
```

### Delete VPN Endpoint
```powershell
# First, disassociate subnets
aws ec2 disassociate-client-vpn-target-network \
  --client-vpn-endpoint-id cvpn-endpoint-xxxxx \
  --association-id cvpn-assoc-xxxxx

# Then delete endpoint
aws ec2 delete-client-vpn-endpoint \
  --client-vpn-endpoint-id cvpn-endpoint-xxxxx
```

---

## Next Steps After Phase 3

1. **Test with pilot group** - 2-3 admins first
2. **Gather feedback** - Performance, usability
3. **Roll out to all admins** - Gradual deployment
4. **Document procedures** - Connection guide for users
5. **Set up monitoring** - CloudWatch dashboards
6. **Regular audits** - Review connection logs monthly

---

## Support Resources

- **AWS Client VPN Documentation**: https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/
- **AWS VPN Client Download**: https://aws.amazon.com/vpn/client-vpn-download/
- **Certificate Management**: https://docs.aws.amazon.com/acm/
- **Internal IT Support**: it.admins@wac.net

---

**Implementation Status**: 📋 Ready to implement  
**Estimated Time**: 2-3 hours  
**Prerequisites**: VPC with subnets, certificates generated  
**Next Phase**: Production rollout and monitoring

---

**Document Version**: 1.0  
**Last Updated**: January 20, 2026  
**Owner**: Arif Bangash (Consultant)
