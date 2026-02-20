# WAC Production VPN Client Package - Manifest

**⚠️ PRODUCTION ENVIRONMENT - HANDLE WITH EXTREME CARE ⚠️**

**Package Version:** 1.0  
**Created:** January 31, 2026  
**Created By:** Arif Bangash-Consultant  
**AWS Account:** 466090007609 (WAC Production)  
**Environment:** **PRODUCTION**

---

## 📦 Package Contents

### Configuration Files

| File | Size | Purpose | Required |
|------|------|---------|----------|
| **wac-prod-admin-vpn.ovpn** | ~6 KB | VPN configuration with embedded certificates | ✅ Yes |

**⚠️ NOTE:** OVPN file will be generated AFTER running `Setup-Prod-Client-VPN.ps1`

### Documentation Files

| File | Purpose | Audience |
|------|---------|----------|
| **README.md** | Package overview and Production warnings | All users |
| **Installation-Guide.md** | Detailed installation instructions | New users |
| **Connection-Guide.md** | Usage, best practices, and troubleshooting | All users |
| **Quick-Reference-Card.md** | Quick reference (printable) | All users |
| **SECURITY-NOTICE.md** | Security policies and procedures | **ALL USERS - MANDATORY** |
| **PACKAGE-MANIFEST.md** | This file - package inventory | Administrators |

---

## 🔐 Certificate Information

### Embedded Certificates

The OVPN file contains the following embedded certificates:

#### CA Certificate
- **Subject:** C=US, ST=California, L=SanFrancisco, O=WAC, OU=IT, CN=wac-vpn-ca.local
- **Valid From:** January 19, 2026 21:20:59 PST
- **Valid Until:** January 17, 2036 21:20:59 PST
- **Key Size:** 2048-bit RSA
- **Signature:** SHA256withRSA
- **Location:** vpn-certs-prod-20260119-220611/ca.crt

#### Server Certificate
- **ACM ARN:** arn:aws:acm:us-west-2:466090007609:certificate/fc6b385c-1d75-49de-91a2-93fae977030a
- **Subject:** C=US, ST=California, L=SanFrancisco, O=WAC, OU=IT, CN=server.wac-vpn.local
- **Valid From:** January 19, 2026 21:20:59 PST
- **Valid Until:** January 17, 2036 21:20:59 PST
- **Key Size:** 2048-bit RSA
- **Signature:** SHA256withRSA
- **Status:** ✅ Imported to ACM (Production)

#### Client Certificate
- **ACM ARN:** arn:aws:acm:us-west-2:466090007609:certificate/e3437609-1535-4ed7-b6e8-dceb076f67df
- **Subject:** C=US, ST=California, L=SanFrancisco, O=WAC, OU=IT, CN=client1.wac-vpn.local
- **Valid From:** January 19, 2026 21:20:59 PST
- **Valid Until:** January 17, 2036 21:20:59 PST
- **Key Size:** 2048-bit RSA
- **Signature:** SHA256withRSA
- **Key Usage:** Digital Signature
- **Extended Key Usage:** TLS Web Client Authentication
- **Status:** ✅ Imported to ACM (Production)

#### Client Private Key
- **Type:** RSA 2048-bit
- **Format:** PKCS#8
- **Status:** Embedded in OVPN file
- **Security:** 🚨 **HIGHLY CONFIDENTIAL - PRODUCTION ACCESS**

---

## 🌐 VPN Endpoint Details

### AWS Configuration

| Property | Value |
|----------|-------|
| **Endpoint ID** | ⏳ Will be created during deployment |
| **DNS Name** | ⏳ Will be assigned during deployment |
| **Status** | ⏳ Pending deployment |
| **Description** | WAC Production Admin VPN |
| **Region** | us-west-2 |
| **Account** | 466090007609 (Production) |

### Network Configuration

| Property | Value |
|----------|-------|
| **VPC ID** | vpc-014b66d7ca2309134 |
| **VPC CIDR** | **10.70.0.0/16** (Production) |
| **VPC Name** | Prod-VPC |
| **Client CIDR** | **10.200.0.0/16** |
| **DNS Servers** | 10.70.0.2 (VPC DNS) |
| **Subnets** | Private-2a (subnet-02c8f0d7d48510db0), Private-2b (subnet-02582cf0ad3fa857b) |

### Domain Controllers

| Name | Instance ID | Private IP | Subnet | AZ | Purpose |
|------|-------------|------------|--------|-----|---------|
| **WACPRODDC01** | i-0745579f46a34da2e | **10.70.10.10** | MAD-2a | us-west-2a | Primary DC |
| **WACPRODDC02** | i-08c78db5cfc6eb412 | **10.70.11.10** | MAD-2b | us-west-2b | Secondary DC |

### Connection Settings

| Property | Value |
|----------|-------|
| **Protocol** | OpenVPN |
| **Transport** | UDP |
| **Port** | 443 |
| **Cipher** | AES-256-GCM |
| **Split Tunnel** | Enabled |
| **Session Timeout** | 24 hours |
| **Auto-disconnect** | Yes (on timeout) |

### Logging Configuration

| Property | Value |
|----------|-------|
| **CloudWatch Logging** | ✅ Enabled |
| **Log Group** | /aws/clientvpn/prod-admin-vpn |
| **Retention** | **180 days** (Production requirement) |
| **Monitoring** | Enhanced monitoring enabled |

---

## 📋 System Requirements

### Supported Operating Systems

| OS | Minimum Version | Recommended Version |
|----|----------------|---------------------|
| **Windows** | Windows 10 (64-bit) | Windows 11 |
| **macOS** | macOS 10.15 (Catalina) | macOS 14 (Sonoma) |
| **Linux** | Ubuntu 18.04 | Ubuntu 22.04 |

### Hardware Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **CPU** | Dual-core 2.0 GHz | Quad-core 2.5 GHz+ |
| **RAM** | 4 GB | 8 GB+ |
| **Disk Space** | 100 MB | 500 MB |
| **Network** | 1 Mbps | 10 Mbps+ |

### Software Requirements

- Administrator/root privileges for installation
- Active internet connection
- Port 443 UDP not blocked by firewall
- OpenVPN compatible network adapter
- **Company-managed device (Production requirement)**
- **Full disk encryption enabled (Production requirement)**
- **Antivirus/EDR software installed and updated**

---

## 🔄 Version History

### Package Version 1.0 (January 31, 2026)

**Initial Production Release**

**Includes:**
- VPN configuration file (to be generated)
- Complete documentation suite
- Enhanced security policies for Production
- Quick reference materials
- Production-specific warnings and procedures

**Certificate Details:**
- Server certificate: fc6b385c-1d75-49de-91a2-93fae977030a
- Client certificate: e3437609-1535-4ed7-b6e8-dceb076f67df
- Valid until: January 17, 2036

**VPN Endpoint:**
- Status: Ready for deployment
- Deployment script: Setup-Prod-Client-VPN.ps1

---

## 📊 Package Checksums

### File Integrity Verification

To verify package integrity, use these checksums:

**Note:** Generate checksums after OVPN file creation using:

**Windows (PowerShell):**
```powershell
Get-FileHash -Path "wac-prod-admin-vpn.ovpn" -Algorithm SHA256
```

**macOS/Linux:**
```bash
shasum -a 256 wac-prod-admin-vpn.ovpn
```

**⚠️ IMPORTANT:** Verify checksums before distributing to ensure file integrity.

---

## 🎯 Distribution Information

### Authorized Recipients

**This package should ONLY be distributed to:**
- Senior Production administrators (approved by management)
- AWS Production administrators
- Security team members (as needed for audits)
- **NO contractors without explicit written approval**
- **NO temporary staff**

### Distribution Methods

**Approved:**
- Encrypted email (S/MIME, PGP) - **Production approved only**
- Secure file sharing (company-approved platforms with encryption)
- In-person transfer (encrypted USB with password)
- Company VPN/intranet (encrypted, logged access)

**Prohibited:**
- Unencrypted email
- Public file sharing services
- Unencrypted cloud storage
- Public repositories
- Personal devices
- Unencrypted messaging apps

### Distribution Log

**⚠️ MANDATORY:** Maintain a log of all distributions:

| Date | Recipient | Method | Authorized By | Purpose | Acknowledged |
|------|-----------|--------|---------------|---------|--------------|
| | | | | | |
| | | | | | |
| | | | | | |

---

## 🔒 Security Classification

### Document Classification

| Item | Classification | Handling |
|------|---------------|----------|
| **OVPN File** | **Highly Confidential** | **Maximum protection required** |
| **Private Keys** | **Highly Confidential** | **Maximum protection required** |
| **Documentation** | Confidential | Encrypted storage required |
| **Security Notice** | Confidential | Must be read by all users |
| **This Manifest** | Confidential | Administrators only |

### Access Control

- **Read Access:** Authorized Production administrators only
- **Write Access:** AWS Production administrators only
- **Distribution:** Controlled distribution with approval
- **Retention:** Duration of employment + 3 years (Production)

---

## 📞 Support Information

### Technical Support

**For installation and connection issues:**
- Review documentation in this package
- Check CloudWatch logs: `/aws/clientvpn/prod-admin-vpn`
- Contact IT Help Desk (Production support line)
- **DO NOT troubleshoot Production issues without approval**

**For security concerns:**
- Review SECURITY-NOTICE.md
- Contact Security Team **immediately**
- Report incidents promptly per incident response procedures
- **Disconnect VPN immediately if compromise suspected**

### Administrative Contacts

| Role | Responsibility |
|------|---------------|
| **AWS Production Administrator** | Certificate management, endpoint configuration |
| **Security Team** | Policy enforcement, incident response |
| **IT Help Desk** | User support, troubleshooting |
| **Network Team** | Connectivity issues, routing |
| **Change Management** | Production change approvals |

---

## 🔍 Audit Information

### Package Audit Trail

| Event | Date | Performed By | Details |
|-------|------|--------------|---------|
| **Package Created** | Jan 31, 2026 | Arif Bangash-Consultant | Initial Production package creation |
| **Certificates Verified** | Jan 31, 2026 | Arif Bangash-Consultant | ACM verification completed |
| **Network Verified** | Jan 31, 2026 | Arif Bangash-Consultant | VPC and DC verification |
| **Documentation Completed** | Jan 31, 2026 | Arif Bangash-Consultant | All guides created |
| **Security Review** | Pending | Security Team | Pre-deployment security review |

### Compliance Verification

- ✅ Certificates valid and properly configured
- ✅ Network configuration verified
- ✅ Security policies documented
- ✅ User documentation complete
- ✅ Audit trail established
- ⏳ Security review pending
- ⏳ Management approval pending

---

## 📅 Maintenance Schedule

### Regular Reviews

| Activity | Frequency | Next Due | Owner |
|----------|-----------|----------|-------|
| **Certificate Validity** | **Monthly** | Feb 28, 2026 | AWS Admin |
| **Endpoint Status** | **Weekly** | Feb 7, 2026 | AWS Admin |
| **Documentation Updates** | Quarterly | Apr 30, 2026 | Technical Writer |
| **Security Policy Review** | **Quarterly** | Apr 30, 2026 | Security Team |
| **Access List Review** | **Monthly** | Feb 28, 2026 | Security Team |
| **Compliance Audit** | **Quarterly** | Apr 30, 2026 | Compliance Team |

### Planned Updates

| Update | Planned Date | Description |
|--------|-------------|-------------|
| **Certificate Renewal** | Jan 2036 | New certificates before expiration |
| **Documentation Refresh** | Apr 2026 | Update based on user feedback |
| **Security Policy Update** | Apr 2026 | Quarterly policy review |

---

## 🎓 Training Requirements

### Required Training (MANDATORY)

**All users MUST complete before receiving package:**
- [ ] Security Awareness Training (current year)
- [ ] Production Access Training
- [ ] VPN Security Best Practices
- [ ] Data Handling Procedures (Production)
- [ ] Incident Response Procedures
- [ ] Change Management Training

### Optional Training

Recommended for all users:
- [ ] AWS VPN Client Advanced Features
- [ ] Network Troubleshooting Basics
- [ ] CloudWatch Log Analysis
- [ ] Active Directory Administration

---

## 📝 Change Log

### Version 1.0 (January 31, 2026)

**Initial Production Release**
- Created complete Production VPN client package
- Included all required documentation
- Verified certificate and network configuration
- Established enhanced security policies for Production
- Created distribution procedures with approval workflow
- Added Production-specific warnings throughout

---

## ✅ Pre-Distribution Checklist

**Before distributing this package, verify:**

- [ ] OVPN file has been generated (Setup-Prod-Client-VPN.ps1 executed)
- [ ] All documentation files are included
- [ ] Certificates are valid and not expired
- [ ] VPN endpoint is operational (status: available)
- [ ] Recipient is authorized for **Production** access
- [ ] **Management approval obtained**
- [ ] Distribution method is secure and approved
- [ ] Distribution is logged
- [ ] Recipient has completed **all required training**
- [ ] Security notice has been acknowledged **in writing**
- [ ] Recipient device meets security requirements
- [ ] Recipient understands Production change management procedures

---

## 🔐 Package Integrity

### Verification Steps

Recipients should verify package integrity:

1. **Check File Count:** 6 files total (1 OVPN + 5 documentation)
2. **Verify OVPN File:** Contains "prod" in filename
3. **Check Endpoint:** Verify endpoint ID matches documentation
4. **Verify Certificates:** Valid until 2036
5. **Review Documentation:** All guides present and readable
6. **Verify Environment:** Confirms Production (not Dev)

### Tampering Indicators

**Report immediately if you observe:**
- Missing or extra files
- Modified file sizes
- Corrupted or unreadable files
- Different endpoint ID
- Expired certificates
- Suspicious content
- **Wrong environment (Dev instead of Prod)**
- **Incorrect VPC CIDR (should be 10.70.0.0/16)**

---

## 📊 Package Statistics

| Metric | Value |
|--------|-------|
| **Total Files** | 6 |
| **Configuration Files** | 1 |
| **Documentation Files** | 5 |
| **Total Size** | ~50 KB |
| **Certificate Count** | 3 (CA, Server, Client) |
| **Documentation Pages** | ~45 pages |
| **Supported OS** | 3 (Windows, macOS, Linux) |
| **Environment** | **PRODUCTION** |

---

## 🎯 Success Criteria

Package is considered successful when:

- ✅ User can install AWS VPN Client
- ✅ User can import VPN profile
- ✅ User can connect to VPN
- ✅ User receives IP in 10.200.0.0/16 range
- ✅ User can access Production VPC resources (10.70.0.0/16)
- ✅ User can RDP to Domain Controllers (10.70.10.10, 10.70.11.10)
- ✅ User understands **Production** security requirements
- ✅ User can troubleshoot common issues
- ✅ All activity is logged to CloudWatch

---

## 📞 Emergency Contacts

### Security Incidents (24/7)
- **Immediate:** Contact Security Team
- **After Hours:** Use emergency security hotline
- **Email:** security@company.com (encrypted)
- **Severity:** **ALL Production incidents are HIGH priority**

### Technical Emergencies (24/7)
- **VPN Outage:** Contact AWS Production Administrator
- **Certificate Issues:** Contact AWS Production Administrator
- **Network Issues:** Contact Network Team
- **DC Issues:** Contact Domain Admin Team

### Change Management
- **Production Changes:** Submit change request BEFORE making changes
- **Emergency Changes:** Follow emergency change procedures
- **Approval Required:** All Production changes require approval

---

## ⚠️ PRODUCTION WARNINGS

### CRITICAL REMINDERS

🚨 **THIS IS PRODUCTION** - All actions affect live systems  
🚨 **ALL ACTIVITY IS LOGGED** - Every connection, every action  
🚨 **CHANGE MANAGEMENT REQUIRED** - No unauthorized changes  
🚨 **MAXIMUM SECURITY** - Treat credentials as highly confidential  
🚨 **IMMEDIATE REPORTING** - Report all incidents immediately  

### Consequences of Misuse

**Unauthorized access or misuse may result in:**
- Immediate termination of employment
- Revocation of all system access
- Legal action under applicable laws
- Criminal prosecution
- Civil liability for damages
- **Regulatory penalties**
- **Audit findings**

---

**Package Manifest Version:** 1.0  
**Last Updated:** January 31, 2026  
**Next Review:** February 28, 2026  
**Maintained By:** AWS Production Administration Team

---

**⚠️ PRODUCTION ENVIRONMENT - HANDLE WITH EXTREME CARE ⚠️**

**END OF MANIFEST**
