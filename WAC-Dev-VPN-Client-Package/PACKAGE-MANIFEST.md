# WAC Dev VPN Client Package - Manifest

**Package Version:** 1.0  
**Created:** January 31, 2026  
**Created By:** Arif Bangash-Consultant  
**AWS Account:** 749006369142 (WAC Dev)  
**Environment:** Development

---

## 📦 Package Contents

### Configuration Files

| File | Size | Purpose | Required |
|------|------|---------|----------|
| **wac-dev-admin-vpn-FIXED.ovpn** | ~6 KB | VPN configuration with embedded certificates | ✅ Yes |

### Documentation Files

| File | Purpose | Audience |
|------|---------|----------|
| **README.md** | Package overview and quick start | All users |
| **Installation-Guide.md** | Detailed installation instructions | New users |
| **Connection-Guide.md** | Usage and troubleshooting | All users |
| **Quick-Reference-Card.md** | Quick reference (printable) | All users |
| **SECURITY-NOTICE.md** | Security policies and procedures | All users |
| **PACKAGE-MANIFEST.md** | This file - package inventory | Administrators |

---

## 🔐 Certificate Information

### Embedded Certificates

The OVPN file contains the following embedded certificates:

#### CA Certificate
- **Subject:** C=US, ST=California, L=SanFrancisco, O=WAC, OU=IT, CN=wac-vpn-ca.local
- **Valid From:** January 20, 2026 02:52:38 UTC
- **Valid Until:** January 18, 2036 02:52:38 UTC
- **Key Size:** 2048-bit RSA
- **Signature:** SHA256withRSA

#### Server Certificate (Referenced)
- **ACM ARN:** arn:aws:acm:us-west-2:749006369142:certificate/6f9363fd-fa99-4d96-b5b8-b4993571a1af
- **Subject:** C=US, ST=California, L=SanFrancisco, O=WAC, OU=IT, CN=server.wac-vpn.local
- **Valid From:** January 19, 2026 21:20:59 PST
- **Valid Until:** January 17, 2036 21:20:59 PST

#### Client Certificate
- **ACM ARN:** arn:aws:acm:us-west-2:749006369142:certificate/1ad0144e-b29c-489a-931c-d80aef002469
- **Subject:** C=US, ST=California, L=SanFrancisco, O=WAC, OU=IT, CN=client1.wac-vpn.local
- **Valid From:** January 20, 2026 02:52:38 UTC
- **Valid Until:** January 18, 2036 02:52:38 UTC
- **Key Size:** 2048-bit RSA
- **Signature:** SHA256withRSA
- **Key Usage:** Digital Signature
- **Extended Key Usage:** TLS Web Client Authentication

#### Client Private Key
- **Type:** RSA 2048-bit
- **Format:** PKCS#8
- **Status:** Embedded in OVPN file
- **Security:** ⚠️ CONFIDENTIAL - Protect this file

---

## 🌐 VPN Endpoint Details

### AWS Configuration

| Property | Value |
|----------|-------|
| **Endpoint ID** | cvpn-endpoint-02fbfb0cd399c382c |
| **DNS Name** | *.cvpn-endpoint-02fbfb0cd399c382c.prod.clientvpn.us-west-2.amazonaws.com |
| **Status** | available |
| **Description** | WAC Dev Admin VPN (Fixed) |
| **Region** | us-west-2 |
| **Created** | January 20, 2026 03:22:55 UTC |

### Network Configuration

| Property | Value |
|----------|-------|
| **VPC ID** | vpc-014ec3818a5b2940e |
| **VPC CIDR** | 10.60.0.0/16 |
| **Client CIDR** | 10.100.0.0/16 |
| **DNS Servers** | 10.60.0.2 |
| **Security Group** | sg-0d26e40f0767cc881 |
| **Subnets** | subnet-06888c11ff940086d, subnet-0aebef249b6787cba |

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
| **CloudWatch Logging** | Enabled |
| **Log Group** | /aws/clientvpn/dev-admin-vpn |
| **Log Stream** | cvpn-endpoint-02fbfb0cd399c382c-us-west-2-2026/01/20-OF1pLYzHEGQ2 |
| **Retention** | 90 days |

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

---

## 🔄 Version History

### Package Version 1.0 (January 31, 2026)

**Initial Release**

**Includes:**
- VPN configuration file (FIXED version)
- Complete documentation suite
- Security policies and procedures
- Quick reference materials

**Certificate Details:**
- Server certificate: 6f9363fd-fa99-4d96-b5b8-b4993571a1af
- Client certificate: 1ad0144e-b29c-489a-931c-d80aef002469
- Valid until: January 17, 2036

**VPN Endpoint:**
- Endpoint ID: cvpn-endpoint-02fbfb0cd399c382c
- Status: Available and operational
- Created: January 20, 2026

---

## 📊 Package Checksums

### File Integrity Verification

To verify package integrity, use these checksums:

**Note:** Generate checksums after package creation using:

**Windows (PowerShell):**
```powershell
Get-FileHash -Path "wac-dev-admin-vpn-FIXED.ovpn" -Algorithm SHA256
```

**macOS/Linux:**
```bash
shasum -a 256 wac-dev-admin-vpn-FIXED.ovpn
```

---

## 🎯 Distribution Information

### Authorized Recipients

This package should only be distributed to:
- WAC Development team members
- Authorized contractors with Dev access
- AWS administrators
- Security team members (as needed)

### Distribution Methods

**Approved:**
- Encrypted email (S/MIME, PGP)
- Secure file sharing (company-approved platforms)
- In-person transfer (encrypted USB)
- Company VPN/intranet (encrypted)

**Prohibited:**
- Unencrypted email
- Public file sharing services
- Unencrypted cloud storage
- Public repositories

### Distribution Log

Maintain a log of all distributions:

| Date | Recipient | Method | Authorized By | Purpose |
|------|-----------|--------|---------------|---------|
| | | | | |
| | | | | |
| | | | | |

---

## 🔒 Security Classification

### Document Classification

| Item | Classification | Handling |
|------|---------------|----------|
| **OVPN File** | Confidential | Encrypted storage required |
| **Documentation** | Internal Use | Standard protection |
| **Security Notice** | Internal Use | Standard protection |
| **This Manifest** | Internal Use | Standard protection |

### Access Control

- **Read Access:** Authorized VPN users only
- **Write Access:** AWS administrators only
- **Distribution:** Controlled distribution only
- **Retention:** Duration of employment + 1 year

---

## 📞 Support Information

### Technical Support

**For installation and connection issues:**
- Review documentation in this package
- Check CloudWatch logs: `/aws/clientvpn/dev-admin-vpn`
- Contact IT Help Desk

**For security concerns:**
- Review SECURITY-NOTICE.md
- Contact Security Team immediately
- Report incidents promptly

### Administrative Contacts

| Role | Responsibility |
|------|---------------|
| **AWS Administrator** | Certificate management, endpoint configuration |
| **Security Team** | Policy enforcement, incident response |
| **IT Help Desk** | User support, troubleshooting |
| **Network Team** | Connectivity issues, routing |

---

## 🔍 Audit Information

### Package Audit Trail

| Event | Date | Performed By | Details |
|-------|------|--------------|---------|
| **Package Created** | Jan 31, 2026 | Arif Bangash-Consultant | Initial package creation |
| **Certificates Verified** | Jan 31, 2026 | Arif Bangash-Consultant | ACM verification completed |
| **Endpoint Verified** | Jan 31, 2026 | Arif Bangash-Consultant | Status: available |
| **Documentation Completed** | Jan 31, 2026 | Arif Bangash-Consultant | All guides created |

### Compliance Verification

- ✅ Certificates valid and properly configured
- ✅ Endpoint operational and accessible
- ✅ Security policies documented
- ✅ User documentation complete
- ✅ Audit trail established

---

## 📅 Maintenance Schedule

### Regular Reviews

| Activity | Frequency | Next Due | Owner |
|----------|-----------|----------|-------|
| **Certificate Validity** | Quarterly | Apr 30, 2026 | AWS Admin |
| **Endpoint Status** | Monthly | Feb 28, 2026 | AWS Admin |
| **Documentation Updates** | Semi-annually | Jul 31, 2026 | Technical Writer |
| **Security Policy Review** | Annually | Jan 31, 2027 | Security Team |
| **Access List Review** | Quarterly | Apr 30, 2026 | Security Team |

### Planned Updates

| Update | Planned Date | Description |
|--------|-------------|-------------|
| **Certificate Renewal** | Jan 2036 | New certificates before expiration |
| **Documentation Refresh** | Jul 2026 | Update based on user feedback |
| **Security Policy Update** | Jan 2027 | Annual policy review |

---

## 🎓 Training Requirements

### Required Training

All users must complete before receiving package:
- [ ] Security Awareness Training
- [ ] VPN Security Best Practices
- [ ] Data Handling Procedures
- [ ] Incident Response Procedures

### Optional Training

Recommended for all users:
- [ ] AWS VPN Client Advanced Features
- [ ] Network Troubleshooting Basics
- [ ] CloudWatch Log Analysis

---

## 📝 Change Log

### Version 1.0 (January 31, 2026)

**Initial Release**
- Created complete VPN client package
- Included all required documentation
- Verified certificate and endpoint configuration
- Established security policies
- Created distribution procedures

---

## ✅ Pre-Distribution Checklist

Before distributing this package, verify:

- [ ] OVPN file is the FIXED version
- [ ] All documentation files are included
- [ ] Certificates are valid and not expired
- [ ] VPN endpoint is operational (status: available)
- [ ] Recipient is authorized for Dev access
- [ ] Distribution method is secure and approved
- [ ] Distribution is logged
- [ ] Recipient has completed required training
- [ ] Security notice has been acknowledged

---

## 🔐 Package Integrity

### Verification Steps

Recipients should verify package integrity:

1. **Check File Count:** 6 files total (1 OVPN + 5 documentation)
2. **Verify OVPN File:** Contains "FIXED" in filename
3. **Check Endpoint:** References cvpn-endpoint-02fbfb0cd399c382c
4. **Verify Certificates:** Valid until 2036
5. **Review Documentation:** All guides present and readable

### Tampering Indicators

Report immediately if you observe:
- Missing or extra files
- Modified file sizes
- Corrupted or unreadable files
- Different endpoint ID
- Expired certificates
- Suspicious content

---

## 📊 Package Statistics

| Metric | Value |
|--------|-------|
| **Total Files** | 6 |
| **Configuration Files** | 1 |
| **Documentation Files** | 5 |
| **Total Size** | ~50 KB |
| **Certificate Count** | 3 (CA, Server, Client) |
| **Documentation Pages** | ~40 pages |
| **Supported OS** | 3 (Windows, macOS, Linux) |

---

## 🎯 Success Criteria

Package is considered successful when:

- ✅ User can install AWS VPN Client
- ✅ User can import VPN profile
- ✅ User can connect to VPN
- ✅ User receives IP in 10.100.0.0/16 range
- ✅ User can access Dev VPC resources (10.60.0.0/16)
- ✅ User understands security requirements
- ✅ User can troubleshoot common issues

---

## 📞 Emergency Contacts

### Security Incidents
- **Immediate:** Contact Security Team
- **After Hours:** Use emergency security hotline
- **Email:** security@company.com (encrypted)

### Technical Emergencies
- **VPN Outage:** Contact AWS Administrator
- **Certificate Issues:** Contact AWS Administrator
- **Network Issues:** Contact Network Team

---

**Package Manifest Version:** 1.0  
**Last Updated:** January 31, 2026  
**Next Review:** July 31, 2026  
**Maintained By:** AWS Administration Team

---

**END OF MANIFEST**
