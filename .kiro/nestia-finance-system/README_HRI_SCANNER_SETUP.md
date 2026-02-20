# HRI FAST Scanner - Complete Setup Package

This package contains everything needed to set up IAM permissions and deploy the HRI FAST Scanner application.

---

## 📋 Package Contents

### 1. IAM Permissions
- **`hri-fast-scanner-iam-permissions.yaml`** - CloudFormation template for IAM role and policies
- **`verify-hri-scanner-permissions.ps1`** - PowerShell script to verify all permissions
- **`DEPLOYMENT_GUIDE.md`** - Step-by-step deployment instructions

### 2. Analysis & Documentation
- **`HRI_FAST_Scanner_Access_Analysis.md`** - Complete access analysis and requirements
- **`CURRENT_ACCESS_STATUS.md`** - Your current access status and next steps
- **`README_HRI_SCANNER_SETUP.md`** - This file

---

## 🚀 Quick Start

### Current Situation
- ✅ You have **read-only access** to AWS account 212114479343
- ❌ You **cannot deploy** resources or create IAM roles
- 🎯 You need **elevated permissions** to deploy HRI FAST Scanner

### Solution
Deploy the CloudFormation template to create an IAM role with required permissions.

---

## 📝 Step-by-Step Process

### Step 1: Get Administrator Help (Required)

**You need an AWS administrator to deploy the IAM permissions.**

**Send this to your administrator:**

```
Hi [Administrator Name],

I need to deploy the HRI FAST Scanner application and require elevated AWS permissions.

Please deploy the attached CloudFormation template (hri-fast-scanner-iam-permissions.yaml) 
with the following parameters:

Stack Name: hri-fast-scanner-iam-permissions
RoleName: HRI-FAST-Scanner-Deployer
TrustedPrincipalArn: arn:aws:sts::212114479343:assumed-role/AWSReservedSSO_WAFandViewOnly_fbb3d3cceb55bcc7/ABangash@aimconsulting.com

CLI Command:
aws cloudformation create-stack \
  --stack-name hri-fast-scanner-iam-permissions \
  --template-body file://hri-fast-scanner-iam-permissions.yaml \
  --parameters \
    ParameterKey=RoleName,ParameterValue=HRI-FAST-Scanner-Deployer \
    ParameterKey=TrustedPrincipalArn,ParameterValue="arn:aws:sts::212114479343:assumed-role/AWSReservedSSO_WAFandViewOnly_fbb3d3cceb55bcc7/ABangash@aimconsulting.com" \
  --capabilities CAPABILITY_NAMED_IAM \
  --tags Key=Application,Value=HRI-FAST-Scanner

This will create a scoped IAM role that allows me to deploy the HRI FAST Scanner 
application without affecting other AWS resources.

Deployment time: ~3 minutes
Security: All permissions scoped to hri-fast-scanner-* resources only

Thank you!
```

---

### Step 2: Assume the Role

After the administrator deploys the stack, get the Role ARN from CloudFormation outputs:

```bash
# Get the Role ARN
aws cloudformation describe-stacks \
  --stack-name hri-fast-scanner-iam-permissions \
  --query 'Stacks[0].Outputs[?OutputKey==`RoleArn`].OutputValue' \
  --output text
```

**Assume the role:**

```bash
# Assume role
aws sts assume-role \
  --role-arn arn:aws:iam::212114479343:role/HRI-FAST-Scanner-Deployer \
  --role-session-name hri-fast-scanner-deployment \
  --external-id hri-fast-scanner-deployment \
  --duration-seconds 43200
```

**Set credentials (PowerShell):**

```powershell
$assumeRole = aws sts assume-role `
  --role-arn "arn:aws:iam::212114479343:role/HRI-FAST-Scanner-Deployer" `
  --role-session-name "hri-fast-scanner-deployment" `
  --external-id "hri-fast-scanner-deployment" `
  --duration-seconds 43200 `
  --output json | ConvertFrom-Json

$env:AWS_ACCESS_KEY_ID = $assumeRole.Credentials.AccessKeyId
$env:AWS_SECRET_ACCESS_KEY = $assumeRole.Credentials.SecretAccessKey
$env:AWS_SESSION_TOKEN = $assumeRole.Credentials.SessionToken

# Verify
aws sts get-caller-identity
```

---

### Step 3: Verify Permissions

Run the verification script:

```powershell
# Run verification
.\verify-hri-scanner-permissions.ps1

# Or with automatic role assumption
.\verify-hri-scanner-permissions.ps1 `
  -RoleArn "arn:aws:iam::212114479343:role/HRI-FAST-Scanner-Deployer" `
  -AssumeRole
```

**Expected result:** All tests pass (100% pass rate)

---

### Step 4: Deploy HRI FAST Scanner

Now you can deploy the application infrastructure!

See `HRI_FAST_Scanner_Access_Analysis.md` for:
- Complete architecture
- CloudFormation templates
- Deployment instructions
- Cost estimates

---

## 🔐 Security Features

### Scoped Permissions
All permissions are limited to resources matching `hri-fast-scanner-*`:
- ✅ Can create: `hri-fast-scanner-documents` bucket
- ❌ Cannot create: `my-other-bucket`

### External ID Required
- Value: `hri-fast-scanner-deployment`
- Prevents confused deputy attacks
- Must be provided when assuming role

### Time-Limited Sessions
- Maximum: 12 hours
- Credentials automatically expire
- Re-assume for extended work

### Least Privilege
- Only permissions needed for HRI FAST Scanner
- No wildcard permissions on sensitive actions
- Read-only where possible

---

## 📊 What Gets Created

### IAM Resources (by CloudFormation)
- 1 IAM Role: `HRI-FAST-Scanner-Deployer`
- 9 Managed Policies:
  - S3 Policy
  - Lambda Policy
  - API Gateway Policy
  - DynamoDB Policy
  - IAM Policy
  - CloudWatch Policy
  - CloudFormation Policy
  - Cognito Policy
  - VPC Policy

### Application Resources (after deployment)
- S3 buckets for documents and web hosting
- Lambda functions for backend processing
- API Gateway for REST API
- DynamoDB tables for data storage
- Cognito user pool for authentication
- CloudWatch logs and alarms

---

## 💰 Cost Breakdown

### IAM Permissions
- **Cost:** $0 (IAM resources are free)

### HRI FAST Scanner Application
- **Development:** ~$31/month
- **Production:** ~$150-300/month

**Detailed breakdown in:** `HRI_FAST_Scanner_Access_Analysis.md`

---

## 🛠️ Troubleshooting

### "Access Denied" when deploying CloudFormation

**Problem:** Your current role doesn't have CloudFormation permissions

**Solution:** Administrator must deploy the template

---

### "Cannot assume role"

**Problem:** Trust relationship not configured or external ID mismatch

**Solution:** 
1. Verify `TrustedPrincipalArn` matches your ARN
2. Use external ID: `hri-fast-scanner-deployment`
3. Check role exists: `aws iam get-role --role-name HRI-FAST-Scanner-Deployer`

---

### Verification script fails

**Problem:** Permissions not working as expected

**Solution:**
1. Check you've assumed the role correctly
2. Verify role has all policies attached
3. Review detailed error in JSON report
4. Check for service control policies (SCPs)

---

## 📚 Documentation

### For Deployment
1. **Start here:** `CURRENT_ACCESS_STATUS.md` - Your current status
2. **Deploy IAM:** `DEPLOYMENT_GUIDE.md` - Step-by-step instructions
3. **Verify:** Run `verify-hri-scanner-permissions.ps1`
4. **Deploy app:** `HRI_FAST_Scanner_Access_Analysis.md` - Application setup

### For Reference
- **CloudFormation template:** `hri-fast-scanner-iam-permissions.yaml`
- **Verification script:** `verify-hri-scanner-permissions.ps1`
- **Complete analysis:** `HRI_FAST_Scanner_Access_Analysis.md`

---

## ⏱️ Timeline

### With Administrator Help (Recommended)
- **Day 1, Hour 1:** Request deployment from administrator
- **Day 1, Hour 1:** Administrator deploys stack (3 minutes)
- **Day 1, Hour 1:** You assume role and verify (15 minutes)
- **Day 1-2:** Deploy HRI FAST Scanner infrastructure (2-4 hours)
- **Day 2-3:** Configure and test application (4-8 hours)

**Total:** 2-3 days to fully operational

---

## ✅ Checklist

### Before Requesting Deployment
- [ ] Review `CURRENT_ACCESS_STATUS.md`
- [ ] Read `DEPLOYMENT_GUIDE.md`
- [ ] Prepare request email for administrator
- [ ] Confirm your user ARN

### After Stack Deployment
- [ ] Get Role ARN from CloudFormation outputs
- [ ] Assume the role
- [ ] Run verification script
- [ ] Confirm 100% pass rate
- [ ] Save credentials for deployment session

### During Application Deployment
- [ ] Deploy S3 buckets
- [ ] Create DynamoDB tables
- [ ] Deploy Lambda functions
- [ ] Configure API Gateway
- [ ] Set up Cognito
- [ ] Configure monitoring

### After Deployment
- [ ] Test application functionality
- [ ] Set up monitoring and alarms
- [ ] Document configuration
- [ ] Train team members

---

## 🎯 Success Criteria

### IAM Permissions Deployed
- ✅ CloudFormation stack status: `CREATE_COMPLETE`
- ✅ Role exists: `HRI-FAST-Scanner-Deployer`
- ✅ 9 policies attached to role
- ✅ Can assume role successfully

### Permissions Verified
- ✅ Verification script: 100% pass rate
- ✅ Can create S3 buckets
- ✅ Can create Lambda functions
- ✅ Can create DynamoDB tables
- ✅ Can deploy CloudFormation stacks

### Application Deployed
- ✅ All infrastructure resources created
- ✅ Application accessible
- ✅ Authentication working
- ✅ Monitoring configured

---

## 📞 Support

### For IAM Deployment Issues
- Contact: AWS Account Administrator
- Escalate to: IAM Team Lead

### For Application Deployment Issues
- Contact: Development Team Lead
- Reference: `HRI_FAST_Scanner_Access_Analysis.md`

### For AWS Service Issues
- AWS Support Console
- AWS Documentation

---

## 🔄 Updates

### Version 1.0 (December 22, 2025)
- Initial package creation
- CloudFormation template for IAM permissions
- Verification script
- Complete documentation

---

## 📝 Notes

### Important
- **External ID is required:** `hri-fast-scanner-deployment`
- **Session duration:** Maximum 12 hours
- **Resource naming:** All resources must start with `hri-fast-scanner-`

### Best Practices
- Always verify permissions before deployment
- Use role assumption for all deployments
- Monitor CloudWatch for errors
- Review costs weekly
- Update documentation as needed

---

## 🎉 Ready to Deploy?

1. ✅ **Read** `CURRENT_ACCESS_STATUS.md`
2. ✅ **Request** administrator to deploy IAM stack
3. ✅ **Assume** the role after deployment
4. ✅ **Verify** permissions with script
5. ✅ **Deploy** HRI FAST Scanner application

**Good luck with your deployment!** 🚀
