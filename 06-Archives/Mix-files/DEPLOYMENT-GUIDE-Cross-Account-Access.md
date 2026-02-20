# Cross-Account Access Deployment Guide

**Purpose:** Enable cross-account access from management account to all child accounts  
**Current Status:** ❌ No cross-account access  
**Target Status:** ✅ Full read-only access to all 18 accounts

---

## 📋 Prerequisites

Before starting, ensure you have:

- [ ] AWS CLI configured with management account credentials
- [ ] Administrator access to management account (729265419250)
- [ ] Permission to create CloudFormation StackSets
- [ ] Permission to deploy stacks to child accounts

---

## 🎯 What This Will Do

### Current State:
- ✅ Can access management account (SRSAWS) only
- ❌ Cannot access 17 child accounts
- ❌ Cannot see resources in child accounts

### After Deployment:
- ✅ Can access ALL 18 accounts
- ✅ Can see resources in all accounts
- ✅ Can run cost optimization across all accounts
- ✅ Can perform Well-Architected Reviews in all accounts

---

## 📁 Files Provided

1. **analyze-cross-account-access.ps1** - Analysis script (run first)
2. **management-account-policy.yaml** - Adds AssumeRole permission (management account)
3. **cross-account-role-stackset.yaml** - Creates role in child accounts (StackSet)
4. **update-existing-role-trust.yaml** - Updates existing roles (if needed)

---

## 🚀 Deployment Steps

### Step 1: Analyze Current Access

Run the analysis script to understand current state:

```powershell
.\analyze-cross-account-access.ps1
```

**Expected Output:**
- List of all 18 accounts
- Access test results for each account
- Recommendations for fixing access

**Review the file:** `cross-account-access-test-results.csv`

---

### Step 2: Deploy to Management Account

Deploy the policy that allows assuming roles in child accounts.

#### Option A: Using AWS Console

1. Go to **CloudFormation** in AWS Console
2. Click **Create Stack** → **With new resources**
3. Upload `management-account-policy.yaml`
4. Stack name: `cross-account-assume-role-policy`
5. Parameters:
   - **SSORoleName:** `AWSReservedSSO_AIM-WellArchitectedReview_ffafce28ad424f54`
   - **OrganizationId:** `o-rnymoexhtu`
6. Click **Next** → **Next** → Check "I acknowledge..." → **Create stack**
7. Wait for **CREATE_COMPLETE** status

#### Option B: Using AWS CLI

```bash
aws cloudformation create-stack \
  --stack-name cross-account-assume-role-policy \
  --template-body file://management-account-policy.yaml \
  --parameters \
    ParameterKey=SSORoleName,ParameterValue=AWSReservedSSO_AIM-WellArchitectedReview_ffafce28ad424f54 \
    ParameterKey=OrganizationId,ParameterValue=o-rnymoexhtu \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-west-2
```

**Wait for completion:**
```bash
aws cloudformation wait stack-create-complete \
  --stack-name cross-account-assume-role-policy \
  --region us-west-2
```

---

### Step 3: Deploy to All Child Accounts (StackSet)

Deploy the cross-account role to all 17 child accounts using CloudFormation StackSets.

#### Option A: Using AWS Console

1. Go to **CloudFormation** → **StackSets**
2. Click **Create StackSet**
3. Choose **Template is ready** → Upload `cross-account-role-stackset.yaml`
4. Click **Next**
5. StackSet name: `cross-account-sso-role`
6. Parameters:
   - **ManagementAccountId:** `729265419250`
   - **SSORoleName:** `AWSReservedSSO_AIM-WellArchitectedReview_ffafce28ad424f54`
   - **SSOProviderArn:** `arn:aws:iam::729265419250:saml-provider/AWSSSO_db6c0d50bf5bdbae_DO_NOT_DELETE`
7. Click **Next**
8. Deployment options:
   - **Deployment targets:** Deploy to organization
   - **Specify regions:** us-west-2 (or your primary region)
   - **Deployment options:** 
     - Maximum concurrent accounts: 5
     - Failure tolerance: 2
9. Click **Next** → Check "I acknowledge..." → **Submit**

#### Option B: Using AWS CLI

```bash
# Create StackSet
aws cloudformation create-stack-set \
  --stack-set-name cross-account-sso-role \
  --template-body file://cross-account-role-stackset.yaml \
  --parameters \
    ParameterKey=ManagementAccountId,ParameterValue=729265419250 \
    ParameterKey=SSORoleName,ParameterValue=AWSReservedSSO_AIM-WellArchitectedReview_ffafce28ad424f54 \
    ParameterKey=SSOProviderArn,ParameterValue=arn:aws:iam::729265419250:saml-provider/AWSSSO_db6c0d50bf5bdbae_DO_NOT_DELETE \
  --capabilities CAPABILITY_NAMED_IAM \
  --permission-model SERVICE_MANAGED \
  --auto-deployment Enabled=true,RetainStacksOnAccountRemoval=false \
  --region us-west-2

# Deploy to all accounts in organization
aws cloudformation create-stack-instances \
  --stack-set-name cross-account-sso-role \
  --deployment-targets OrganizationalUnitIds=<ROOT_OU_ID> \
  --regions us-west-2 \
  --operation-preferences \
    MaxConcurrentCount=5,FailureToleranceCount=2 \
  --region us-west-2
```

**To get ROOT_OU_ID:**
```bash
aws organizations list-roots --query 'Roots[0].Id' --output text
```

**Monitor deployment:**
```bash
aws cloudformation list-stack-instances \
  --stack-set-name cross-account-sso-role \
  --region us-west-2
```

---

### Step 4: Verify Access

After deployment completes (15-30 minutes), verify access:

```powershell
.\analyze-cross-account-access.ps1
```

**Expected Results:**
- ✅ Can Access: 17 accounts (all child accounts)
- ✅ Role Exists: YES (in all accounts)

---

## 🧪 Test Cross-Account Access

Test assuming a role in a child account:

```bash
# Test assuming role in Production Account
aws sts assume-role \
  --role-arn "arn:aws:iam::015815251546:role/AWSReservedSSO_AIM-WellArchitectedReview_ffafce28ad424f54" \
  --role-session-name "test-session"

# If successful, you'll get temporary credentials
```

Test listing resources in a child account:

```bash
# Set temporary credentials from assume-role output
export AWS_ACCESS_KEY_ID="<AccessKeyId from above>"
export AWS_SECRET_ACCESS_KEY="<SecretAccessKey from above>"
export AWS_SESSION_TOKEN="<SessionToken from above>"

# List EC2 instances in child account
aws ec2 describe-instances --region us-west-1

# List EBS volumes in child account
aws ec2 describe-volumes --region us-west-1
```

---

## 🔧 Troubleshooting

### Issue 1: "AccessDenied" when creating StackSet

**Cause:** Insufficient permissions in management account

**Solution:**
```bash
# Ensure you have these permissions:
- cloudformation:CreateStackSet
- cloudformation:CreateStackInstances
- organizations:ListAccounts
- organizations:DescribeOrganization
```

### Issue 2: StackSet deployment fails in some accounts

**Cause:** Account may have restrictions or SCPs blocking IAM role creation

**Solution:**
1. Check Service Control Policies (SCPs)
2. Verify account is not suspended
3. Check CloudFormation StackSet operation details for specific errors

### Issue 3: "Role already exists" error

**Cause:** Role already exists in child account (from AWS SSO)

**Solution:** Use `update-existing-role-trust.yaml` instead:

```bash
# Deploy to specific account
aws cloudformation create-stack \
  --stack-name update-sso-role-trust \
  --template-body file://update-existing-role-trust.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-west-2
```

### Issue 4: Cannot assume role after deployment

**Cause:** Trust policy not updated correctly

**Solution:**
1. Check role trust policy in child account:
```bash
aws iam get-role --role-name AWSReservedSSO_AIM-WellArchitectedReview_ffafce28ad424f54
```

2. Verify it includes management account in trust policy
3. Re-deploy update-existing-role-trust.yaml if needed

---

## 📊 Post-Deployment Validation

### 1. Run Complete EBS Scan

```powershell
.\get-ebs-inventory.ps1
```

**Expected:** Should now see ~126 volumes across all accounts

### 2. Run Complete Cost Analysis

```powershell
.\deep-dive-analysis.ps1
```

**Expected:** Should see resources in all accounts

### 3. Verify Account Access

```powershell
.\verify-access-and-ebs-cur.ps1
```

**Expected:** 
- EBS Access: YES (all accounts)
- EBS Volumes Found: ~126 total

---

## 🔒 Security Considerations

### What This Deployment Does:
- ✅ Grants READ-ONLY access to child accounts
- ✅ Uses existing SSO role (no new users)
- ✅ Maintains audit trail (CloudTrail logs all assume-role actions)
- ✅ Follows AWS best practices for cross-account access

### What This Does NOT Do:
- ❌ Does NOT grant write/modify permissions
- ❌ Does NOT create new users or access keys
- ❌ Does NOT bypass existing security controls
- ❌ Does NOT affect existing SSO configuration

### Permissions Granted:
- ReadOnlyAccess (view all resources)
- WellArchitectedConsoleFullAccess (create/edit reviews)
- Billing/Cost read access
- Security service read access (GuardDuty, Security Hub, etc.)

---

## 🎯 Success Criteria

After successful deployment, you should be able to:

- [ ] List all 18 accounts
- [ ] Assume role in any child account
- [ ] View EC2 instances in all accounts
- [ ] View EBS volumes in all accounts (~126 total)
- [ ] View RDS databases in all accounts
- [ ] View S3 buckets in all accounts
- [ ] Run cost optimization analysis across all accounts
- [ ] Create Well-Architected Reviews in any account

---

## 📞 Support

### If Deployment Fails:

1. **Check CloudFormation Events:**
   - Go to CloudFormation console
   - Click on failed stack
   - View "Events" tab for error details

2. **Check StackSet Operations:**
   - Go to CloudFormation → StackSets
   - Click on StackSet name
   - View "Operations" tab

3. **Review Analysis Script Output:**
   - Check `cross-account-access-test-results.csv`
   - Look for specific error messages

4. **Contact AWS Support:**
   - Provide StackSet operation ID
   - Provide error messages from CloudFormation events

---

## 🔄 Rollback Instructions

If you need to rollback the changes:

### 1. Delete StackSet Instances

```bash
aws cloudformation delete-stack-instances \
  --stack-set-name cross-account-sso-role \
  --deployment-targets OrganizationalUnitIds=<ROOT_OU_ID> \
  --regions us-west-2 \
  --no-retain-stacks \
  --region us-west-2
```

### 2. Delete StackSet

```bash
aws cloudformation delete-stack-set \
  --stack-set-name cross-account-sso-role \
  --region us-west-2
```

### 3. Delete Management Account Stack

```bash
aws cloudformation delete-stack \
  --stack-name cross-account-assume-role-policy \
  --region us-west-2
```

---

## 📝 Deployment Checklist

- [ ] Run analyze-cross-account-access.ps1
- [ ] Review current access status
- [ ] Deploy management-account-policy.yaml
- [ ] Wait for stack CREATE_COMPLETE
- [ ] Deploy cross-account-role-stackset.yaml
- [ ] Wait for StackSet deployment (15-30 min)
- [ ] Run analyze-cross-account-access.ps1 again
- [ ] Verify all accounts show "Can Access: YES"
- [ ] Test assuming role in a child account
- [ ] Run complete EBS scan
- [ ] Run complete cost analysis
- [ ] Document any issues encountered

---

**Deployment Time:** 30-45 minutes  
**Difficulty:** Medium  
**Risk Level:** Low (read-only access only)  
**Reversible:** Yes (full rollback available)

---

**Questions?** Review the troubleshooting section or contact your AWS administrator.
