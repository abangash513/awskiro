# HRI Fast Scanner - CloudFormation Templates Index

## 📁 File Structure

```
cloudformation/
├── management-account-stack.yaml    # Main CloudFormation template
├── member-account-stack.yaml        # Member account IAM role template
├── deploy.sh                        # Automated deployment (Linux/Mac)
├── deploy.ps1                       # Automated deployment (Windows)
├── DEPLOYMENT_GUIDE.md              # Comprehensive deployment guide
├── README.md                        # Quick reference guide
├── CLOUDFORMATION_SUMMARY.md        # Complete summary document
└── INDEX.md                         # This file
```

## 🚀 Quick Start

### For Linux/Mac Users
```bash
cd Kirofiles/hri-scanner/cloudformation
chmod +x deploy.sh
./deploy.sh
```

### For Windows Users
```powershell
cd Kirofiles\hri-scanner\cloudformation
.\deploy.ps1
```

### Manual Deployment (All Platforms)
See **DEPLOYMENT_GUIDE.md** for step-by-step instructions.

## 📄 File Descriptions

### CloudFormation Templates

#### management-account-stack.yaml
**Purpose**: Deploys all HRI Scanner resources to the management account

**Creates**:
- 3 Lambda functions (discover_accounts, scan_account, partner_sync)
- DynamoDB table (hri_findings) with 2 GSIs
- S3 bucket with encryption and lifecycle policies
- IAM execution role with least-privilege permissions
- EventBridge scheduled rule for automated scans
- CloudWatch Log Groups and Alarms
- SNS topic for error notifications

**Parameters**:
- ScannerRoleName (default: HRI-ScannerRole)
- ScanRegions (default: us-east-1,us-west-2)
- NotificationEmail (optional)
- LogRetentionDays (default: 30)
- ScheduleExpression (default: daily at 2 AM UTC)

**Size**: ~500 lines
**Deployment Time**: 5-10 minutes

#### member-account-stack.yaml
**Purpose**: Deploys cross-account IAM role to member accounts

**Creates**:
- HRI-ScannerRole with read-only permissions
- Trust policy allowing management account assumption
- Explicit deny for all write operations

**Parameters**:
- ManagementAccountId (required)
- ScannerRoleName (default: HRI-ScannerRole)
- ExternalId (default: hri-scanner-external-id-12345)

**Size**: ~300 lines
**Deployment Time**: 2-3 minutes

### Deployment Scripts

#### deploy.sh (Linux/Mac)
**Purpose**: Automated deployment script with interactive prompts

**Features**:
- Prerequisite checking (AWS CLI, Python, credentials)
- Automatic Lambda code packaging
- Stack deployment with wait conditions
- Lambda code updates
- Member account deployment options
- Deployment verification
- Test execution
- Summary output

**Usage**:
```bash
./deploy.sh
```

**Size**: ~400 lines

#### deploy.ps1 (Windows)
**Purpose**: PowerShell deployment script for Windows users

**Features**:
- Same functionality as deploy.sh
- Windows-compatible commands
- PowerShell-native error handling
- Colored output for better readability

**Usage**:
```powershell
.\deploy.ps1
# Or with parameters
.\deploy.ps1 -Region us-east-1 -NotificationEmail email@example.com
```

**Size**: ~350 lines

### Documentation

#### DEPLOYMENT_GUIDE.md
**Purpose**: Comprehensive deployment documentation

**Contents**:
- Prerequisites and requirements
- Step-by-step deployment instructions
- Single account and StackSets deployment
- Lambda code packaging and deployment
- Network configuration (VPC optional)
- Post-deployment verification
- Testing procedures
- Troubleshooting guide (common issues and solutions)
- Cost optimization tips
- Update and cleanup procedures

**Size**: ~600 lines
**Read Time**: 15-20 minutes

#### README.md
**Purpose**: Quick reference guide

**Contents**:
- Overview of all files
- Quick start instructions (3 deployment options)
- Template parameters reference
- Resources created summary
- Network configuration options
- IAM permissions summary
- Cost estimates
- Monitoring setup
- Security best practices
- Troubleshooting quick reference

**Size**: ~400 lines
**Read Time**: 10-15 minutes

#### CLOUDFORMATION_SUMMARY.md
**Purpose**: Complete summary of the CloudFormation solution

**Contents**:
- What was created (detailed breakdown)
- Deployment options comparison
- Network architecture diagrams
- IAM permission model
- Resource naming conventions
- Stack outputs reference
- Testing procedures
- Cost breakdown
- Security considerations
- Maintenance schedule
- Next steps after deployment

**Size**: ~500 lines
**Read Time**: 15-20 minutes

#### INDEX.md (This File)
**Purpose**: Navigation and overview of all files

**Contents**:
- File structure
- Quick start guide
- File descriptions
- Usage recommendations
- Decision tree for choosing files

## 🎯 Which File Should I Use?

### I want to deploy quickly
→ Use **deploy.sh** (Linux/Mac) or **deploy.ps1** (Windows)

### I want to understand what will be deployed
→ Read **CLOUDFORMATION_SUMMARY.md** first

### I want step-by-step instructions
→ Follow **DEPLOYMENT_GUIDE.md**

### I want to customize the deployment
→ Edit **management-account-stack.yaml** parameters

### I want to deploy to multiple accounts
→ See **DEPLOYMENT_GUIDE.md** Section "Deploy via StackSets"

### I need quick reference
→ Use **README.md**

### I want to troubleshoot issues
→ Check **DEPLOYMENT_GUIDE.md** Troubleshooting section

### I want to understand costs
→ See **CLOUDFORMATION_SUMMARY.md** Cost Breakdown

### I want to understand security
→ See **CLOUDFORMATION_SUMMARY.md** Security Considerations

## 📊 Deployment Decision Tree

```
Start
  │
  ├─ Do you have AWS CLI and Python installed?
  │   ├─ Yes → Continue
  │   └─ No → Install prerequisites first
  │
  ├─ What's your operating system?
  │   ├─ Linux/Mac → Use deploy.sh
  │   ├─ Windows → Use deploy.ps1
  │   └─ Any → Use manual AWS CLI commands
  │
  ├─ Do you want to customize parameters?
  │   ├─ Yes → Edit template or use CLI parameters
  │   └─ No → Use defaults
  │
  ├─ How many accounts to deploy?
  │   ├─ 1 account → Single account deployment
  │   └─ Multiple → Use StackSets
  │
  └─ Ready to deploy!
```

## 🔧 Common Tasks

### Deploy to Management Account
```bash
# Linux/Mac
./deploy.sh

# Windows
.\deploy.ps1

# Manual
aws cloudformation create-stack \
  --stack-name hri-scanner-management \
  --template-body file://management-account-stack.yaml \
  --capabilities CAPABILITY_NAMED_IAM
```

### Deploy to Member Account
```bash
aws cloudformation create-stack \
  --stack-name hri-scanner-member-role \
  --template-body file://member-account-stack.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters ParameterKey=ManagementAccountId,ParameterValue=123456789012
```

### Update Lambda Code
```bash
cd ../lambda
zip scan_account.zip scan_account.py
aws lambda update-function-code \
  --function-name hri-scan-account \
  --zip-file fileb://scan_account.zip
```

### Test Deployment
```bash
aws lambda invoke \
  --function-name hri-discover-accounts \
  --payload '{}' \
  response.json
```

### Check Findings
```bash
aws dynamodb scan \
  --table-name hri_findings \
  --max-items 10
```

### View Logs
```bash
aws logs tail /aws/lambda/hri-discover-accounts --follow
```

## 📈 Deployment Checklist

### Pre-Deployment
- [ ] AWS CLI installed and configured
- [ ] Python 3.12+ installed
- [ ] Valid AWS credentials
- [ ] AWS Organizations enabled (management account)
- [ ] Read CLOUDFORMATION_SUMMARY.md
- [ ] Decide on deployment method

### During Deployment
- [ ] Deploy management account stack
- [ ] Wait for stack creation to complete
- [ ] Update Lambda function code
- [ ] Deploy member account stack(s)
- [ ] Verify all resources created

### Post-Deployment
- [ ] Confirm SNS email subscription
- [ ] Run test scan
- [ ] Check DynamoDB for findings
- [ ] Review CloudWatch Logs
- [ ] Set up monitoring dashboards
- [ ] Document custom settings

## 💰 Cost Estimate

**Monthly Cost** (50 accounts, daily scans):
- Lambda: $2.52
- DynamoDB: $0.50
- S3: $0.10
- CloudWatch Logs: $0.50
- **Total: $3.62/month**

See **CLOUDFORMATION_SUMMARY.md** for detailed cost breakdown.

## 🔒 Security Highlights

- ✅ Least-privilege IAM roles
- ✅ External ID for role assumption
- ✅ Explicit deny for write operations
- ✅ Encryption at rest (DynamoDB, S3)
- ✅ Encryption in transit (TLS 1.2+)
- ✅ S3 bucket policy denying insecure transport
- ✅ CloudWatch Logs for audit trail

## 📞 Support

### For Deployment Issues
1. Check **DEPLOYMENT_GUIDE.md** Troubleshooting section
2. Review CloudWatch Logs for error details
3. Verify prerequisites are met
4. Check AWS CloudFormation stack events

### For Understanding the Solution
1. Read **CLOUDFORMATION_SUMMARY.md**
2. Review **README.md** for quick reference
3. Check template comments for details

### For Customization
1. Edit template parameters
2. Modify IAM permissions as needed
3. Adjust scan schedule
4. Configure additional regions

## 🎓 Learning Path

### Beginner
1. Read **README.md** (10 min)
2. Run **deploy.sh** or **deploy.ps1** (15 min)
3. Test deployment (5 min)

### Intermediate
1. Read **CLOUDFORMATION_SUMMARY.md** (20 min)
2. Review **management-account-stack.yaml** (15 min)
3. Customize parameters (10 min)
4. Deploy manually (20 min)

### Advanced
1. Read **DEPLOYMENT_GUIDE.md** (30 min)
2. Review both templates in detail (30 min)
3. Deploy via StackSets (30 min)
4. Set up VPC deployment (60 min)
5. Customize IAM permissions (30 min)

## 📝 Version History

- **v1.0** (2025-01-25): Initial CloudFormation templates
  - Management account stack
  - Member account stack
  - Deployment scripts (Bash and PowerShell)
  - Comprehensive documentation

## 🚀 Next Steps

After reviewing this index:

1. **Quick Deploy**: Run `./deploy.sh` or `.\deploy.ps1`
2. **Learn More**: Read **CLOUDFORMATION_SUMMARY.md**
3. **Detailed Guide**: Follow **DEPLOYMENT_GUIDE.md**
4. **Customize**: Edit template parameters
5. **Deploy**: Create CloudFormation stacks
6. **Test**: Run test scan
7. **Monitor**: Set up CloudWatch dashboards

## 📚 Additional Resources

- AWS CloudFormation Documentation
- AWS Lambda Best Practices
- AWS Organizations Guide
- AWS Well-Architected Framework
- HRI Scanner Requirements (.kiro/specs/hri-fast-scanner/)

---

**Ready to deploy?** Start with the Quick Start section above!
