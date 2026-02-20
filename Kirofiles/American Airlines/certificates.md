# Certificate Management

This page documents the process for requesting and importing SSL/TLS certificates into AWS Certificate Manager (ACM) using KeyFactor.

## KeyFactor Environment Access

### Environment URLs

- **Test Environment** (for Dev/Test): https://aalet.keyfactorpki.com/Keyfactor/Portal
- **Production Environment**: https://aale.keyfactorpki.com/Keyfactor/Portal

### Access Request

If you do not have access to the KeyFactor environment, contact:
- **Tony Coleman**: tony.coleman@aa.com

## Certificate Request Process

> **⚠️ Important Note on Wildcard Certificates**
>
> Wildcard certificates have been routinely declined in the production environment. If you require a wildcard certificate, you must work with the certificate team prior to submitting your request. Failure to do so will result in your request being declined.

### Step 1: Generate Certificate Signing Request (CSR)

1. Navigate to **Enrollment > CSR Generation**
2. Select template: **AA Application Server CMS - Requires Approval**
3. Fill out the form with the required information
4. Add any Subject Alternate Names (SANs) as needed
5. Click **Generate**
6. The CSR Request will be downloaded to your computer

### Step 2: Submit CSR for Enrollment

1. Navigate to **Enrollment > CSR Enrollment**
2. Select template: **AA Application Server CMS - Requires Approval**
3. Paste the contents of the CSR from Step 1 into the **CSR Content** field
4. Fill out the remaining form fields:
   - **ArcherApplicationSHORTName**: `OpsPlatNxt`
   - Complete any other required fields
5. Click **Enroll** to submit the certificate request

### Step 3: Wait for Certificate Approval

- Certificate approval notification emails will be sent to your AA email account
- Monitor your email for approval status
- Approval time may vary depending on the approval workflow

### Step 4: Download Certificate and Private Key

1. Once the certificate is approved, download both:
   - The certificate file
   - The encrypted private key
2. **IMPORTANT**: When downloading the private key, a password will be displayed on screen
   - This password is required for decryption
   - Copy and save this password immediately as it may not be shown again

### Step 5: Decrypt the Private Key

The private key must be decrypted before it can be imported into ACM.

#### Preparation

1. Extract the certificate body from your PEM file:
   - Copy from `-----BEGIN CERTIFICATE-----` to `-----END CERTIFICATE-----`
   - Save to a file named `certbody.pem`

2. Extract the encrypted private key:
   - Copy from `-----BEGIN ENCRYPTED PRIVATE KEY-----` to `-----END ENCRYPTED PRIVATE KEY-----`
   - Save to a file named `enc_private.pem`

3. Save the password from Step 4 to a file named `pwd.txt`

#### Decrypt Command

Run the following OpenSSL command to decrypt the private key:

```bash
openssl rsa -in /path/to/enc_private.pem -out /path/to/decrypted_private.pem -passin file:/path/to/pwd.txt
```

**Example:**

```bash
openssl rsa -in ./enc_private.pem -out ./decrypted_private.pem -passin file:./pwd.txt
```

### Step 6: Import Certificate into ACM

1. Provide the following files to someone with access to the target AWS environment:
   - Certificate PEM file (`certbody.pem`)
   - Decrypted private key (`decrypted_private.pem`)

2. The certificate must be manually imported into ACM in the target environment

3. Once imported, the certificate is ready for use

## Certificate Renewal Process

Certificates have a limited validity period and must be renewed before expiration to avoid service disruptions.

### Monitoring Certificate Expiration

- Certificates in ACM will display their expiration dates
- AWS sends notifications as certificates approach expiration
- Set calendar reminders to begin renewal 30-45 days before expiration
- Plan for approval workflows which may take several days

### Renewal Methods

#### Reimport Method (Recommended)

ACM allows you to reimport a certificate before it expires while **preserving AWS service associations** with the original certificate. This is the preferred method as it maintains existing integrations without requiring updates to service configurations.

**Reimport Conditions and Limitations:**

- ✅ You can add or remove domain names (SANs)
- ❌ You cannot remove all domain names from a certificate
- ✅ You can add new Key Usage extension values
- ❌ You cannot remove existing Key Usage extension values
- ✅ You can add new Extended Key Usage extension values
- ❌ You cannot remove existing Extended Key Usage extension values
  - **Exception**: You can remove the Client Authentication Extended Key Usage (to comply with Chrome's root program requirements)
- ❌ Key type and size cannot be changed
- ❌ You cannot apply resource tags when reimporting a certificate

> **⚠️ Important: Client Authentication Removal**
>
> If you remove Client Authentication functionality, you must implement additional validations on your side. ACM does not support rollback to previously imported certificates.

**Reimport Steps:**

1. **Generate a new CSR** following [Step 1](#step-1-generate-certificate-signing-request-csr)
   - Use the same Common Name (CN) and Subject Alternate Names (SANs) as the expiring certificate (unless adding/removing SANs)
   - **Ensure the same key type and size** as the original certificate

2. **Submit the CSR for enrollment** following [Step 2](#step-2-submit-csr-for-enrollment)

3. **Wait for approval** following [Step 3](#step-3-wait-for-certificate-approval)

4. **Download and decrypt** the new certificate and private key following [Steps 4-5](#step-4-download-certificate-and-private-key)

5. **Reimport the certificate** into ACM:
   - In the ACM console, select the existing certificate to be renewed
   - Choose **Reimport certificate**
   - Provide the certificate PEM file and decrypted private key
   - The certificate will be updated while maintaining all existing service associations

#### New Certificate Method

If you need to change the key type/size or make other incompatible changes, you must request a completely new certificate:

1. Follow the complete [Certificate Request Process](#certificate-request-process)
2. Import as a new certificate in ACM
3. Manually update all AWS services to reference the new certificate ARN
4. Delete the old certificate after confirming all services are updated

### Best Practices for Renewal

- **Start early**: Begin the renewal process at least 30 days before expiration
- **Use reimport when possible**: Preserves service associations and simplifies the renewal process
- **Verify key compatibility**: Ensure the new certificate uses the same key type and size for reimport
- **Test first**: If possible, test the renewal process in a non-production environment
- **Document dependencies**: Maintain a list of services/applications using each certificate
- **Verify after renewal**: Confirm the new certificate is active and services are functioning correctly
- **Clean up**: Remove old certificate files from local systems after successful renewal

## Security Best Practices

- Never commit certificate files or private keys to version control
- Store passwords securely and delete temporary password files after use
- Limit access to certificate files to only those who need them
- Delete decrypted private keys from local machines after successful import
  ```
