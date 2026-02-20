# Phase 2 Implementation Summary
## AWS Systems Manager Session Manager Setup

**Date**: January 20, 2026  
**Account**: AWS_Dev (749006369142)  
**Status**: ✅ Infrastructure Created - Ready for DC Attachment

---

## ✅ Completed Steps

### 1. IAM Role Created
- **Role Name**: `WAC-Dev-DC-SSM-Role`
- **Role ARN**: `arn:aws:iam::749006369142:role/WAC-Dev-DC-SSM-Role`
- **Policy Attached**: `AmazonSSMManagedInstanceCore` (AWS Managed)
- **Purpose**: Allows EC2 instances to communicate with Systems Manager

### 2. Instance Profile Created
- **Profile Name**: `WAC-Dev-DC-SSM-Profile`
- **Profile ARN**: `arn:aws:iam::749006369142:instance-profile/WAC-Dev-DC-SSM-Profile`
- **Role Attached**: `WAC-Dev-DC-SSM-Role`
- **Purpose**: Attaches IAM role to EC2 instances

### 3. CloudWatch Log Group Created
- **Log Group**: `/aws/ssm/dev-domain-controllers`
- **Purpose**: Stores session logs for audit trail
- **Retention**: Default (never expire) - can be configured

### 4. S3 Bucket Created
- **Bucket Name**: `wac-dev-ssm-session-logs-749006369142`
- **Region**: us-west-2
- **Purpose**: Long-term storage of session logs and transcripts

---

## 📋 Next Steps - Manual Actions Required

### Step 1: Identify Your Domain Controller Instances

You need to find the EC2 instance IDs of your Domain Controllers. Run this command:

```powershell
# List all EC2 instances in us-west-2
aws ec2 describe-instances --region us-west-2 \
  --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name,PrivateIpAddress]' \
  --output table

# Or search for instances with "DC" or "Domain" in the name
aws ec2 describe-instances --region us-west-2 \
  --filters "Name=tag:Name,Values=*DC*" \
  --query 'Reservations[*].Instances[*].[InstanceId,Tags[?Key==`Name`].Value|[0],State.Name]' \
  --output table
```

### Step 2: Attach IAM Role to Domain Controllers

Once you have the instance IDs, attach the IAM role:

```powershell
# Replace i-xxxxx with your actual DC instance ID
aws ec2 associate-iam-instance-profile \
  --instance-id i-xxxxx \
  --iam-instance-profile Name=WAC-Dev-DC-SSM-Profile \
  --region us-west-2

# If DC already has a role, you need to replace it:
# First, get the association ID
aws ec2 describe-iam-instance-profile-associations \
  --filters "Name=instance-id,Values=i-xxxxx" \
  --query 'IamInstanceProfileAssociations[0].AssociationId' \
  --output text

# Then replace it
aws ec2 replace-iam-instance-profile-association \
  --association-id iip-assoc-xxxxx \
  --iam-instance-profile Name=WAC-Dev-DC-SSM-Profile
```

### Step 3: Verify SSM Agent Status

After attaching the role, wait 2-3 minutes, then check if the DC appears in Systems Manager:

```powershell
# Check if instances are registered with SSM
aws ssm describe-instance-information \
  --query 'InstanceInformationList[*].[InstanceId,PingStatus,PlatformName,IPAddress]' \
  --output table

# If your DC doesn't appear, RDP to it via VPN and restart the SSM agent:
# On the DC, run in PowerShell:
Restart-Service AmazonSSMAgent
Get-Service AmazonSSMAgent  # Should show "Running"
```

### Step 4: Test SSM Session Access

Once the DC shows as "Online" in SSM:

```powershell
# Start a session (replace i-xxxxx with your DC instance ID)
aws ssm start-session --target i-xxxxx

# You should get a PowerShell prompt on the DC
# Type 'exit' to close the session
```

### Step 5: Test RDP via Port Forwarding

```powershell
# Start port forwarding (replace i-xxxxx with your DC instance ID)
aws ssm start-session \
  --target i-xxxxx \
  --document-name AWS-StartPortForwardingSession \
  --parameters "portNumber=3389,localPortNumber=13389"

# In another terminal, connect via RDP
mstsc /v:localhost:13389
```

---

## 🔧 Configuration Options

### Enable Session Logging (Recommended)

Configure SSM to log all sessions to CloudWatch and S3:

```powershell
# Create session preferences document
aws ssm create-document \
  --name "SSM-SessionManagerRunShell-Dev" \
  --document-type "Session" \
  --content '{
    "schemaVersion": "1.0",
    "description": "Document to hold regional settings for Session Manager",
    "sessionType": "Standard_Stream",
    "inputs": {
      "s3BucketName": "wac-dev-ssm-session-logs-749006369142",
      "s3KeyPrefix": "session-logs/",
      "s3EncryptionEnabled": true,
      "cloudWatchLogGroupName": "/aws/ssm/dev-domain-controllers",
      "cloudWatchEncryptionEnabled": true
    }
  }'
```

### Enable S3 Bucket Versioning (Recommended)

```powershell
aws s3api put-bucket-versioning \
  --bucket wac-dev-ssm-session-logs-749006369142 \
  --versioning-configuration Status=Enabled
```

### Set CloudWatch Log Retention (Optional)

```powershell
# Set logs to expire after 90 days (cost savings)
aws logs put-retention-policy \
  --log-group-name /aws/ssm/dev-domain-controllers \
  --retention-in-days 90
```

---

## 🔒 Security Recommendations

### 1. Tag Your Domain Controllers

```powershell
aws ec2 create-tags \
  --resources i-xxxxx \
  --tags Key=Role,Value=DomainController Key=Environment,Value=Development Key=SSM,Value=Enabled
```

### 2. Restrict SSM Access via IAM Policy

Create an IAM policy that only allows SSM access to tagged DCs:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ssm:StartSession"],
      "Resource": "arn:aws:ec2:*:749006369142:instance/*",
      "Condition": {
        "StringEquals": {
          "ssm:resourceTag/Role": "DomainController"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:TerminateSession",
        "ssm:ResumeSession"
      ],
      "Resource": "arn:aws:ssm:*:749006369142:session/${aws:username}-*"
    }
  ]
}
```

### 3. Enable MFA for SSM Access

Require MFA for all SSM sessions by adding this condition to IAM policies:

```json
"Condition": {
  "BoolIfExists": {
    "aws:MultiFactorAuthPresent": "true"
  }
}
```

---

## 📊 Monitoring and Alerts

### CloudWatch Alarm for Failed Sessions

```powershell
aws cloudwatch put-metric-alarm \
  --alarm-name "SSM-Failed-Sessions-Dev-DC" \
  --alarm-description "Alert on failed SSM sessions to Dev DCs" \
  --metric-name "SessionsFailed" \
  --namespace "AWS/SSM" \
  --statistic Sum \
  --period 300 \
  --threshold 3 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1
```

---

## 🎯 Quick Reference Commands

### Start Session (Browser)
1. Go to AWS Console → Systems Manager → Session Manager
2. Click "Start Session"
3. Select your DC instance
4. Click "Start Session"

### Start Session (CLI)
```powershell
aws ssm start-session --target i-xxxxx
```

### Port Forward for RDP
```powershell
aws ssm start-session \
  --target i-xxxxx \
  --document-name AWS-StartPortForwardingSession \
  --parameters "portNumber=3389,localPortNumber=13389"
```

### View Session History
```powershell
aws ssm describe-sessions --state History
```

### Terminate Session
```powershell
aws ssm terminate-session --session-id session-xxxxx
```

---

## 💰 Cost Estimate

| Resource | Cost |
|----------|------|
| IAM Role & Instance Profile | Free |
| CloudWatch Logs (first 5GB) | Free |
| CloudWatch Logs (after 5GB) | $0.50/GB |
| S3 Storage | $0.023/GB/month |
| SSM Session Manager | Free |
| Data Transfer (in) | Free |
| Data Transfer (out) | $0.09/GB |

**Estimated Monthly Cost**: $5-10 (depending on usage)

---

## ✅ Success Criteria

Phase 2 is complete when:
- [x] IAM role created and configured
- [x] Instance profile created
- [x] CloudWatch log group created
- [x] S3 bucket created
- [ ] IAM role attached to DC instances
- [ ] DC instances show as "Online" in SSM
- [ ] Successfully started a session via browser
- [ ] Successfully connected via RDP port forwarding
- [ ] Session logs appearing in CloudWatch

---

## 🆘 Troubleshooting

### DC not showing in Session Manager
1. Verify IAM role is attached: `aws ec2 describe-instances --instance-ids i-xxxxx --query 'Reservations[0].Instances[0].IamInstanceProfile'`
2. Check SSM agent status on DC: `Get-Service AmazonSSMAgent`
3. Verify outbound HTTPS (443) allowed in security group
4. Check VPC has internet connectivity (NAT Gateway or IGW)

### Port forwarding fails
1. Install Session Manager plugin: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html
2. Update AWS CLI: `pip install --upgrade awscli`
3. Check local port not in use: `netstat -an | findstr 13389`

### Session logs not appearing
1. Verify CloudWatch log group exists
2. Check S3 bucket permissions
3. Wait 5-10 minutes for logs to appear
4. Verify session preferences document is configured

---

## 📞 Support

- **AWS Documentation**: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html
- **Internal IT**: it.admins@wac.net
- **Consultant**: Arif Bangash

---

**Next Phase**: Phase 3 - AWS Client VPN for Remote Admin Access
