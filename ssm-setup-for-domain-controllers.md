# AWS Systems Manager Setup for Domain Controllers
## Phase 2: Backup Admin Access Method

**Date**: January 19, 2026  
**Account**: AWS_Dev (749006369142)  
**Purpose**: Enable SSM Session Manager for secure DC access

---

## Prerequisites
- ✅ Site-to-Site VPN already configured (Phase 1)
- ✅ Domain Controllers running in AWS
- ✅ Admin access to AWS Console
- ✅ PowerShell access to DCs via VPN

---

## Step 1: Create IAM Role for Domain Controllers

### 1.1 Create IAM Policy (if not exists)
```powershell
# This policy allows EC2 instances to communicate with SSM
aws iam create-role --role-name WAC-DC-SSM-Role --assume-role-policy-document '{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "ec2.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}'

# Attach AWS managed policy for SSM
aws iam attach-role-policy \
  --role-name WAC-DC-SSM-Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
```

### 1.2 Create Instance Profile
```powershell
aws iam create-instance-profile --instance-profile-name WAC-DC-SSM-Profile

aws iam add-role-to-instance-profile \
  --instance-profile-name WAC-DC-SSM-Profile \
  --role-name WAC-DC-SSM-Role
```

---

## Step 2: Attach IAM Role to Domain Controllers

### Option A: Via AWS Console
1. Go to EC2 Console
2. Select your Domain Controller instance
3. Actions → Security → Modify IAM Role
4. Select `WAC-DC-SSM-Role`
5. Click Update IAM Role

### Option B: Via AWS CLI
```powershell
# Replace i-xxxxx with your DC instance ID
aws ec2 associate-iam-instance-profile \
  --instance-id i-xxxxx \
  --iam-instance-profile Name=WAC-DC-SSM-Profile
```

---

## Step 3: Verify SSM Agent Status

### 3.1 Check from AWS Console
1. Go to Systems Manager → Fleet Manager
2. Look for your DC instances
3. Status should show "Online"

### 3.2 Check via CLI
```powershell
aws ssm describe-instance-information \
  --filters "Key=tag:Name,Values=*DC*" \
  --query 'InstanceInformationList[*].[InstanceId,PingStatus,PlatformName,PlatformVersion]' \
  --output table
```

### 3.3 If agent not running, restart it on DC
```powershell
# RDP to DC via VPN, then run:
Restart-Service AmazonSSMAgent
Get-Service AmazonSSMAgent  # Verify it's running
```

---

## Step 4: Test SSM Session Manager Access

### Method 1: Browser-Based Shell Access
1. Go to AWS Console → Systems Manager → Session Manager
2. Click "Start Session"
3. Select your Domain Controller
4. Click "Start Session"
5. You'll get a PowerShell prompt in the browser

### Method 2: AWS CLI Session
```powershell
# Start interactive session
aws ssm start-session --target i-xxxxx

# You'll get a PowerShell prompt
# Type 'exit' to close
```

---

## Step 5: Enable RDP via Port Forwarding

This allows you to RDP to DCs without VPN!

### 5.1 Start Port Forwarding Session
```powershell
# Forward DC's RDP port (3389) to your local port (13389)
aws ssm start-session \
  --target i-xxxxx \
  --document-name AWS-StartPortForwardingSession \
  --parameters "portNumber=3389,localPortNumber=13389"
```

### 5.2 Connect via RDP
```powershell
# In another terminal/window, RDP to localhost
mstsc /v:localhost:13389

# Or use Remote Desktop Connection app:
# Computer: localhost:13389
# Username: DOMAIN\Administrator
```

---

## Step 6: Enable Session Logging (Audit Trail)

### 6.1 Create CloudWatch Log Group
```powershell
aws logs create-log-group --log-group-name /aws/ssm/domain-controllers
```

### 6.2 Create S3 Bucket for Session Logs
```powershell
aws s3 mb s3://wac-ssm-session-logs-749006369142

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket wac-ssm-session-logs-749006369142 \
  --versioning-configuration Status=Enabled
```

### 6.3 Configure Session Manager Preferences
```powershell
aws ssm update-document \
  --name "SSM-SessionManagerRunShell" \
  --content '{
    "schemaVersion": "1.0",
    "description": "Document to hold regional settings for Session Manager",
    "sessionType": "Standard_Stream",
    "inputs": {
      "s3BucketName": "wac-ssm-session-logs-749006369142",
      "s3KeyPrefix": "session-logs/",
      "s3EncryptionEnabled": true,
      "cloudWatchLogGroupName": "/aws/ssm/domain-controllers",
      "cloudWatchEncryptionEnabled": true,
      "kmsKeyId": ""
    }
  }'
```

---

## Step 7: Security Best Practices

### 7.1 Restrict SSM Access via IAM Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:StartSession"
      ],
      "Resource": [
        "arn:aws:ec2:*:749006369142:instance/*"
      ],
      "Condition": {
        "StringLike": {
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
      "Resource": [
        "arn:aws:ssm:*:749006369142:session/${aws:username}-*"
      ]
    }
  ]
}
```

### 7.2 Tag Your Domain Controllers
```powershell
aws ec2 create-tags \
  --resources i-xxxxx \
  --tags Key=Role,Value=DomainController Key=Environment,Value=Production
```

### 7.3 Enable MFA for SSM Access
1. Go to IAM → Users → Your Admin User
2. Security Credentials → Assign MFA Device
3. Require MFA in IAM policies for SSM access

---

## Step 8: Create Quick Access Scripts

### 8.1 PowerShell Script for RDP via SSM
```powershell
# Save as: Connect-DC-SSM.ps1
param(
    [Parameter(Mandatory=$true)]
    [string]$InstanceId,
    
    [int]$LocalPort = 13389
)

Write-Host "Starting SSM port forwarding session..." -ForegroundColor Green
Write-Host "Instance: $InstanceId" -ForegroundColor Yellow
Write-Host "Local Port: $LocalPort" -ForegroundColor Yellow

# Start port forwarding in background
Start-Process powershell -ArgumentList "-NoExit", "-Command", `
    "aws ssm start-session --target $InstanceId --document-name AWS-StartPortForwardingSession --parameters portNumber=3389,localPortNumber=$LocalPort"

# Wait for port to be ready
Start-Sleep -Seconds 5

# Launch RDP
Write-Host "Launching Remote Desktop..." -ForegroundColor Green
mstsc /v:localhost:$LocalPort

Write-Host "Done! Close the SSM session window when finished." -ForegroundColor Green
```

### 8.2 Usage
```powershell
# Connect to DC1
.\Connect-DC-SSM.ps1 -InstanceId i-xxxxx -LocalPort 13389

# Connect to DC2 (use different port)
.\Connect-DC-SSM.ps1 -InstanceId i-yyyyy -LocalPort 13390
```

---

## Step 9: Monitoring and Alerts

### 9.1 CloudWatch Alarm for Failed Sessions
```powershell
aws cloudwatch put-metric-alarm \
  --alarm-name "SSM-Failed-Sessions-DC" \
  --alarm-description "Alert on failed SSM sessions to DCs" \
  --metric-name "SessionsFailed" \
  --namespace "AWS/SSM" \
  --statistic Sum \
  --period 300 \
  --threshold 3 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1
```

### 9.2 SNS Topic for Alerts
```powershell
# Create SNS topic
aws sns create-topic --name SSM-DC-Alerts

# Subscribe your email
aws sns subscribe \
  --topic-arn arn:aws:sns:us-west-1:749006369142:SSM-DC-Alerts \
  --protocol email \
  --notification-endpoint admin@wac.net
```

---

## Troubleshooting

### Issue: Instance not showing in Session Manager
**Solution:**
1. Verify IAM role is attached to instance
2. Check SSM agent is running: `Get-Service AmazonSSMAgent`
3. Verify outbound HTTPS (443) is allowed in security group
4. Check instance has internet connectivity (via NAT Gateway or IGW)

### Issue: Port forwarding fails
**Solution:**
1. Ensure AWS CLI is up to date: `aws --version`
2. Install Session Manager plugin: https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html
3. Check local port is not in use: `netstat -an | findstr 13389`

### Issue: RDP connection refused
**Solution:**
1. Verify RDP is enabled on DC
2. Check Windows Firewall allows RDP
3. Verify port forwarding session is still active

---

## Comparison: VPN vs SSM Access

| Feature | Site-to-Site VPN | SSM Session Manager |
|---------|------------------|---------------------|
| **Setup Complexity** | Medium | Easy |
| **Cost** | $36/month | Free |
| **Latency** | Low | Medium |
| **Audit Trail** | Limited | Full (CloudTrail) |
| **Requires Public IP** | Yes (on-prem) | No |
| **Works if VPN Down** | No | Yes |
| **MFA Support** | Depends on setup | Native AWS MFA |
| **Session Recording** | Requires extra tools | Built-in |
| **Best For** | Primary access | Backup/Emergency |

---

## Next Steps (Phase 3)

Once SSM is working, consider:

1. **AWS Client VPN** - For remote admin access from home
2. **Session Recording** - Record all admin sessions for compliance
3. **Automated Patching** - Use SSM Patch Manager for DC updates
4. **Inventory Management** - Track installed software via SSM Inventory
5. **Run Command** - Execute scripts across all DCs simultaneously

---

## Quick Reference Commands

```powershell
# List all managed instances
aws ssm describe-instance-information

# Start session to DC
aws ssm start-session --target i-xxxxx

# Port forward for RDP
aws ssm start-session --target i-xxxxx \
  --document-name AWS-StartPortForwardingSession \
  --parameters "portNumber=3389,localPortNumber=13389"

# View session history
aws ssm describe-sessions --state History

# Terminate active session
aws ssm terminate-session --session-id session-xxxxx
```

---

## Support Contacts

- **AWS Support**: https://console.aws.amazon.com/support/
- **SSM Documentation**: https://docs.aws.amazon.com/systems-manager/
- **Internal IT**: it.admins@wac.net

---

**Document Version**: 1.0  
**Last Updated**: January 19, 2026  
**Owner**: Arif Bangash (Consultant)
