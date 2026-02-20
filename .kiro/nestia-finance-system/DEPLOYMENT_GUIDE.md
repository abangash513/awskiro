# HRI FAST Scanner - IAM Permissions Deployment Guide

This guide walks you through deploying the IAM permissions required for the HRI FAST Scanner application and verifying access.

---

## Prerequisites

1. **AWS CLI** installed and configured
2. **PowerShell** (for verification script)
3. **Administrator access** to AWS account 212114479343
4. **Current credentials** with CloudFormation deployment permissions

---

## Step 1: Deploy IAM Permissions Stack

### Option A: Deploy via AWS Console

1. **Open AWS CloudFormation Console**
   - Navigate to: https://console.aws.amazon.com/cloudformation/

2. **Create Stack**
   - Click "Create stack" → "With new resources (standard)"
   - Choose "Upload a template file"
   - Upload: `hri-fast-scanner-iam-permissions.yaml`
   - Click "Next"

3. **Specify Stack Details**
   - **Stack name:** `hri-fast-scanner-iam-permissions`
   - **Parameters:**
     - **RoleName:** `HRI-FAST-Scanner-Deployer` (default)
     - **TrustedPrincipalArn:** `arn:aws:iam::212114479343:user/ABangash` (or your user ARN)
   - Click "Next"

4. **Configure Stack Options**
   - **Tags** (optional):
     - Key: `Application`, Value: `HRI-FAST-Scanner`
     - Key: `Environment`, Value: `Production`
   - Click "Next"

5. **Review and Create**
   - Check "I acknowledge that AWS CloudFormation might create IAM resources"
   - Click "Create stack"

6. **Wait for Completion**
   - Status will change from `CREATE_IN_PROGRESS` to `CREATE_COMPLETE`
   - This typically takes 2-3 minutes

---

### Option B: Deploy via AWS CLI

```bash
# Validate the template first
aws cloudformation validate-template \
  --template-body file://hri-fast-scanner-iam-permissions.yaml

# Deploy the stack
aws cloudformation create-stack \
  --stack-name hri-fast-scanner-iam-permissions \
  --template-body file://hri-fast-scanner-iam-permissions.yaml \
  --parameters \
    ParameterKey=RoleName,ParameterValue=HRI-FAST-Scanner-Deployer \
    ParameterKey=TrustedPrincipalArn,ParameterValue=arn:aws:iam::212114479343:user/ABangash \
  --capabilities CAPABILITY_NAMED_IAM \
  --tags \
    Key=Application,Value=HRI-FAST-Scanner \
    Key=Environment,Value=Production

# Monitor deployment progress
aws cloudformation describe-stacks \
  --stack-name hri-fast-scanner-iam-permissions \
  --query 'Stacks[0].StackStatus'

# Wait for completion
aws cloudformation wait stack-create-complete \
  --stack-name hri-fast-scanner-iam-permissions

# Get outputs
aws cloudformation describe-stacks \
  --stack-name hri-fast-scanner-iam-permissions \
  --query 'Stacks[0].Outputs'
```

---

## Step 2: Get Role ARN

After deployment, retrieve the Role ARN:

### Via AWS Console
1. Go to CloudFormation → Stacks
2. Select `hri-fast-scanner-iam-permissions`
3. Click "Outputs" tab
4. Copy the `RoleArn` value

### Via AWS CLI
```bash
aws cloudformation describe-stacks \
  --stack-name hri-fast-scanner-iam-permissions \
  --query 'Stacks[0].Outputs[?OutputKey==`RoleArn`].OutputValue' \
  --output text
```

**Example Output:**
```
arn:aws:iam::212114479343:role/HRI-FAST-Scanner-Deployer
```

---

## Step 3: Assume the Role

### Option A: Assume Role via AWS CLI

```bash
# Set the role ARN (replace with your actual ARN)
ROLE_ARN="arn:aws:iam::212114479343:role/HRI-FAST-Scanner-Deployer"

# Assume the role
aws sts assume-role \
  --role-arn $ROLE_ARN \
  --role-session-name hri-fast-scanner-deployment \
  --external-id hri-fast-scanner-deployment \
  --duration-seconds 43200

# The output will contain temporary credentials
# Copy the AccessKeyId, SecretAccessKey, and SessionToken
```

### Option B: Configure AWS CLI Profile

Create a profile in `~/.aws/config`:

```ini
[profile hri-scanner-deployer]
role_arn = arn:aws:iam::212114479343:role/HRI-FAST-Scanner-Deployer
source_profile = default
external_id = hri-fast-scanner-deployment
region = us-east-1
```

Then use the profile:

```bash
# Set environment variable
export AWS_PROFILE=hri-scanner-deployer

# Or use --profile flag
aws s3 ls --profile hri-scanner-deployer
```

### Option C: Set Environment Variables (PowerShell)

```powershell
# Assume role and get credentials
$assumeRole = aws sts assume-role `
  --role-arn "arn:aws:iam::212114479343:role/HRI-FAST-Scanner-Deployer" `
  --role-session-name "hri-fast-scanner-deployment" `
  --external-id "hri-fast-scanner-deployment" `
  --duration-seconds 43200 `
  --output json | ConvertFrom-Json

# Set environment variables
$env:AWS_ACCESS_KEY_ID = $assumeRole.Credentials.AccessKeyId
$env:AWS_SECRET_ACCESS_KEY = $assumeRole.Credentials.SecretAccessKey
$env:AWS_SESSION_TOKEN = $assumeRole.Credentials.SessionToken

# Verify
aws sts get-caller-identity
```

---

## Step 4: Verify Permissions

Run the verification script to test all permissions:

### Basic Verification (Current Credentials)

```powershell
# Run verification with current credentials
.\verify-hri-scanner-permissions.ps1
```

### Verification with Role Assumption

```powershell
# Run verification and assume role automatically
.\verify-hri-scanner-permissions.ps1 `
  -RoleArn "arn:aws:iam::212114479343:role/HRI-FAST-Scanner-Deployer" `
  -AssumeRole
```

### Expected Output

```
=== Current Identity ===
ℹ Account: 212114479343
ℹ User/Role: arn:aws:sts::212114479343:assumed-role/HRI-FAST-Scanner-Deployer/hri-fast-scanner-verification
ℹ User ID: AROAXXXXXXXXXXXXXXXXX:hri-fast-scanner-verification

=== Testing S3 Permissions ===
ℹ Testing: List S3 buckets...
✓ Can list S3 buckets
ℹ Testing: Create S3 bucket...
✓ Can create S3 bucket: hri-fast-scanner-test-20251222143022
ℹ Testing: Upload object to S3...
✓ Can upload objects to S3

=== Testing Lambda Permissions ===
ℹ Testing: List Lambda functions...
✓ Can list Lambda functions
ℹ Testing: Lambda create function permissions...
✓ Have Lambda GetFunction permission

=== Testing API Gateway Permissions ===
ℹ Testing: List API Gateway REST APIs...
✓ Can list API Gateway REST APIs

=== Testing DynamoDB Permissions ===
ℹ Testing: List DynamoDB tables...
✓ Can list DynamoDB tables
ℹ Testing: Create DynamoDB table...
✓ Can create DynamoDB table: hri-fast-scanner-test-table
ℹ Testing: Put item to DynamoDB...
✓ Can put items to DynamoDB

=== Test Summary ===
Total Tests: 15
Passed: 15
Failed: 0
Pass Rate: 100%

=== Final Verdict ===
✓ All permissions verified successfully! You can proceed with HRI FAST Scanner deployment.
```

---

## Step 5: Review Test Results

The verification script generates a detailed JSON report:

```powershell
# View the latest test results
Get-Content (Get-ChildItem "hri-scanner-permission-test-results-*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName | ConvertFrom-Json | ConvertTo-Json -Depth 10
```

---

## Troubleshooting

### Issue: "Access Denied" when deploying CloudFormation stack

**Solution:**
- Ensure you have `iam:CreateRole` and `iam:AttachRolePolicy` permissions
- Your current role needs `cloudformation:CreateStack` permission
- Add `CAPABILITY_NAMED_IAM` capability when deploying

### Issue: "Cannot assume role"

**Possible Causes:**
1. **Trust relationship not configured correctly**
   - Check the `TrustedPrincipalArn` parameter
   - Ensure it matches your current user/role ARN

2. **External ID mismatch**
   - Use `hri-fast-scanner-deployment` as the external ID
   - This is hardcoded in the template for security

3. **Session duration too long**
   - Maximum is 12 hours (43200 seconds)
   - Reduce if needed

**Fix:**
```bash
# Get your current ARN
aws sts get-caller-identity --query 'Arn' --output text

# Update the stack with correct ARN
aws cloudformation update-stack \
  --stack-name hri-fast-scanner-iam-permissions \
  --use-previous-template \
  --parameters \
    ParameterKey=RoleName,UsePreviousValue=true \
    ParameterKey=TrustedPrincipalArn,ParameterValue=<YOUR_ARN> \
  --capabilities CAPABILITY_NAMED_IAM
```

### Issue: Verification script fails on specific service

**Solution:**
1. Check the detailed error message in the JSON report
2. Verify the policy is attached to the role:
   ```bash
   aws iam list-attached-role-policies \
     --role-name HRI-FAST-Scanner-Deployer
   ```
3. Check for service control policies (SCPs) that might restrict access
4. Ensure you're in the correct AWS region

### Issue: "Stack already exists"

**Solution:**
```bash
# Delete the existing stack
aws cloudformation delete-stack \
  --stack-name hri-fast-scanner-iam-permissions

# Wait for deletion
aws cloudformation wait stack-delete-complete \
  --stack-name hri-fast-scanner-iam-permissions

# Redeploy
aws cloudformation create-stack \
  --stack-name hri-fast-scanner-iam-permissions \
  --template-body file://hri-fast-scanner-iam-permissions.yaml \
  --parameters ... \
  --capabilities CAPABILITY_NAMED_IAM
```

---

## What's Included

The CloudFormation template creates:

### IAM Role
- **Name:** `HRI-FAST-Scanner-Deployer`
- **Type:** Assumable role with external ID
- **Session Duration:** 12 hours

### Managed Policies (9 total)
1. **S3 Policy** - Bucket and object management
2. **Lambda Policy** - Function deployment and management
3. **API Gateway Policy** - API creation and deployment
4. **DynamoDB Policy** - Table management and data access
5. **IAM Policy** - Role and policy management
6. **CloudWatch Policy** - Logging and monitoring
7. **CloudFormation Policy** - Stack management
8. **Cognito Policy** - User pool management
9. **VPC Policy** - Network configuration (optional)

### Permissions Scope
All permissions are scoped to resources with the `hri-fast-scanner-*` naming pattern for security.

---

## Security Considerations

### External ID
- Required for assuming the role
- Value: `hri-fast-scanner-deployment`
- Prevents confused deputy problem

### Resource Naming
- All permissions scoped to `hri-fast-scanner-*` resources
- Prevents accidental modification of other resources

### Session Duration
- Maximum: 12 hours
- Credentials automatically expire
- Re-assume role for extended sessions

### Least Privilege
- Only permissions required for HRI FAST Scanner
- No wildcard permissions on sensitive actions
- Read-only where possible

---

## Next Steps

After successful verification:

1. **Deploy HRI FAST Scanner Infrastructure**
   - Use the verified role to deploy application resources
   - Follow the main deployment guide

2. **Set Up CI/CD Pipeline**
   - Configure pipeline to assume this role
   - Automate deployments

3. **Monitor Usage**
   - Enable CloudTrail for audit logging
   - Review IAM Access Analyzer findings

4. **Regular Reviews**
   - Quarterly permission reviews
   - Remove unused permissions
   - Update policies as needed

---

## Cleanup

To remove the IAM permissions:

```bash
# Delete the CloudFormation stack
aws cloudformation delete-stack \
  --stack-name hri-fast-scanner-iam-permissions

# Verify deletion
aws cloudformation wait stack-delete-complete \
  --stack-name hri-fast-scanner-iam-permissions
```

**Note:** This will delete the role and all associated policies. Ensure no active deployments are using this role.

---

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review CloudFormation stack events for errors
3. Check IAM role trust relationships
4. Verify AWS CLI configuration
5. Contact AWS Support if needed

---

## Summary

✅ **CloudFormation Template:** `hri-fast-scanner-iam-permissions.yaml`  
✅ **Verification Script:** `verify-hri-scanner-permissions.ps1`  
✅ **Deployment Time:** ~5 minutes  
✅ **Verification Time:** ~2 minutes  

**You're now ready to deploy the HRI FAST Scanner application!**
