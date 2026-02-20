# Current Access Status - HRI FAST Scanner Setup

**Date:** December 22, 2025  
**Account:** 212114479343  
**User:** ABangash@aimconsulting.com  
**Role:** AWSReservedSSO_WAFandViewOnly_fbb3d3cceb55bcc7

---

## Current Permissions

### ✅ What You CAN Do
- **Read Access:** View all AWS resources (S3, Lambda, API Gateway, DynamoDB, EC2, etc.)
- **Well-Architected Tool:** Full access to create and modify workloads
- **CloudWatch:** View logs, metrics, and alarms
- **Cost Explorer:** View cost and usage data

### ❌ What You CANNOT Do
- **CloudFormation:** Cannot validate or deploy templates
- **IAM:** Cannot create roles or policies
- **S3:** Cannot create buckets or upload files
- **Lambda:** Cannot create or modify functions
- **API Gateway:** Cannot create or deploy APIs
- **DynamoDB:** Cannot create tables or write data
- **Any resource creation or modification**

---

## Files Created

### 1. CloudFormation Template
**File:** `hri-fast-scanner-iam-permissions.yaml`

**Purpose:** Creates IAM role with all required permissions for HRI FAST Scanner deployment

**What it creates:**
- IAM Role: `HRI-FAST-Scanner-Deployer`
- 9 Managed Policies for different AWS services
- Scoped permissions (only `hri-fast-scanner-*` resources)

**Deployment:** Requires administrator access to deploy

---

### 2. Verification Script
**File:** `verify-hri-scanner-permissions.ps1`

**Purpose:** Tests all required permissions after role deployment

**Features:**
- Tests 15+ permission scenarios
- Generates detailed JSON report
- Color-coded output
- Can assume role automatically

**Usage:**
```powershell
# Basic verification
.\verify-hri-scanner-permissions.ps1

# With role assumption
.\verify-hri-scanner-permissions.ps1 -RoleArn "arn:aws:iam::212114479343:role/HRI-FAST-Scanner-Deployer" -AssumeRole
```

---

### 3. Deployment Guide
**File:** `DEPLOYMENT_GUIDE.md`

**Purpose:** Step-by-step instructions for deploying and using the IAM permissions

**Sections:**
- Prerequisites
- Deployment options (Console & CLI)
- Role assumption methods
- Verification steps
- Troubleshooting
- Security considerations

---

## Next Steps

### Step 1: Request Administrator Access (Required)

**You need someone with administrator access to:**
1. Deploy the CloudFormation template
2. Create the IAM role
3. Attach the policies

**Who to contact:**
- AWS Account Administrator
- IAM Team
- DevOps Team Lead

**What to request:**
- Deploy `hri-fast-scanner-iam-permissions.yaml` CloudFormation stack
- Set `TrustedPrincipalArn` parameter to your user ARN:
  ```
  arn:aws:sts::212114479343:assumed-role/AWSReservedSSO_WAFandViewOnly_fbb3d3cceb55bcc7/ABangash@aimconsulting.com
  ```

---

### Step 2: After Role is Created

Once the administrator deploys the stack:

1. **Get the Role ARN** from CloudFormation outputs
2. **Assume the role:**
   ```bash
   aws sts assume-role \
     --role-arn arn:aws:iam::212114479343:role/HRI-FAST-Scanner-Deployer \
     --role-session-name hri-fast-scanner-deployment \
     --external-id hri-fast-scanner-deployment
   ```
3. **Set temporary credentials** in your environment
4. **Run verification script** to confirm access
5. **Deploy HRI FAST Scanner** infrastructure

---

### Step 3: Deploy HRI FAST Scanner

With the new role, you can deploy:
- S3 buckets for documents and web hosting
- Lambda functions for backend processing
- API Gateway for REST API
- DynamoDB tables for data storage
- Cognito for user authentication
- CloudWatch for monitoring

---

## Deployment Command (For Administrator)

The administrator can deploy the IAM permissions with this command:

```bash
aws cloudformation create-stack \
  --stack-name hri-fast-scanner-iam-permissions \
  --template-body file://hri-fast-scanner-iam-permissions.yaml \
  --parameters \
    ParameterKey=RoleName,ParameterValue=HRI-FAST-Scanner-Deployer \
    ParameterKey=TrustedPrincipalArn,ParameterValue="arn:aws:sts::212114479343:assumed-role/AWSReservedSSO_WAFandViewOnly_fbb3d3cceb55bcc7/ABangash@aimconsulting.com" \
  --capabilities CAPABILITY_NAMED_IAM \
  --tags Key=Application,Value=HRI-FAST-Scanner Key=Purpose,Value=Deployment
```

---

## Alternative: Request Temporary Elevated Access

If you need to deploy immediately, request temporary elevated permissions:

**Option 1: Attach AdministratorAccess policy temporarily**
- Duration: 1-2 hours
- Purpose: Deploy IAM role and HRI FAST Scanner
- Revoke after deployment

**Option 2: Create custom policy for your user**
- Permissions: CloudFormation + IAM (limited scope)
- Duration: Permanent or temporary
- More secure than full admin access

---

## Security Notes

### External ID
The role requires an external ID for assumption:
- **Value:** `hri-fast-scanner-deployment`
- **Purpose:** Prevents confused deputy attacks
- **Required:** Must be provided when assuming role

### Resource Scoping
All permissions are limited to resources matching:
- `hri-fast-scanner-*` (S3 buckets, Lambda functions, etc.)
- Prevents accidental modification of other resources

### Session Duration
- **Maximum:** 12 hours (43,200 seconds)
- **Recommended:** 4 hours for deployments
- **Re-assume:** Required after expiration

---

## Estimated Timeline

### With Administrator Help
- **Day 1:** Request deployment, administrator deploys stack (30 minutes)
- **Day 1:** Assume role, verify permissions (15 minutes)
- **Day 1-2:** Deploy HRI FAST Scanner infrastructure (2-4 hours)
- **Day 2-3:** Configure and test application (4-8 hours)

### Self-Service (If Given Temporary Admin)
- **Day 1:** Deploy IAM stack (30 minutes)
- **Day 1:** Verify permissions (15 minutes)
- **Day 1-2:** Deploy HRI FAST Scanner (2-4 hours)
- **Day 2-3:** Configure and test (4-8 hours)

---

## Cost Impact

### IAM Resources
- **IAM Role:** Free
- **Managed Policies:** Free
- **No ongoing costs**

### HRI FAST Scanner (After Deployment)
- **Development:** ~$31/month
- **Production:** ~$150-300/month
- See `HRI_FAST_Scanner_Access_Analysis.md` for details

---

## Summary

### Current Status
❌ **Cannot deploy** - Read-only access  
✅ **Templates ready** - CloudFormation template created  
✅ **Verification ready** - PowerShell script prepared  
✅ **Documentation complete** - Deployment guide available

### Required Action
🔴 **Administrator must deploy IAM permissions stack**

### After Deployment
✅ Full access to deploy HRI FAST Scanner  
✅ Scoped permissions (secure)  
✅ 12-hour sessions  
✅ Automated verification

---

## Contact Information

**For IAM Role Deployment:**
- AWS Account Administrator
- Email: [admin@aimconsulting.com]
- Slack: #aws-support

**For HRI FAST Scanner Questions:**
- Development Team Lead
- Project Manager

---

## Quick Reference

### Files
- `hri-fast-scanner-iam-permissions.yaml` - CloudFormation template
- `verify-hri-scanner-permissions.ps1` - Verification script
- `DEPLOYMENT_GUIDE.md` - Detailed deployment instructions
- `HRI_FAST_Scanner_Access_Analysis.md` - Complete access analysis
- `CURRENT_ACCESS_STATUS.md` - This file

### Key ARNs
- **Your Current Role:** `arn:aws:sts::212114479343:assumed-role/AWSReservedSSO_WAFandViewOnly_fbb3d3cceb55bcc7/ABangash@aimconsulting.com`
- **Target Role:** `arn:aws:iam::212114479343:role/HRI-FAST-Scanner-Deployer` (after deployment)

### External ID
- **Value:** `hri-fast-scanner-deployment`
- **Required for:** Role assumption

---

**Status:** ⏳ Waiting for administrator to deploy IAM permissions stack
