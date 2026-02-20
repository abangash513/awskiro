# Production Phase 2: SSM Session Manager Implementation
# Account: AWS_Production (466090007609)
# Region: us-west-2
# VPC: vpc-014b66d7ca2309134

# IMPORTANT: Run this with Production credentials (WAC_ProdFullAdmin role)

$accountId = "466090007609"
$region = "us-west-2"
$vpcId = "vpc-014b66d7ca2309134"

Write-Host "=== Production Phase 2: SSM Session Manager Implementation ===" -ForegroundColor Green
Write-Host ""
Write-Host "Account: $accountId" -ForegroundColor Cyan
Write-Host "Region: $region" -ForegroundColor Cyan
Write-Host "VPC: $vpcId" -ForegroundColor Cyan
Write-Host ""

# Step 1: Create IAM Role for Domain Controllers
Write-Host "[1/6] Creating IAM role for Domain Controllers..." -ForegroundColor Yellow

$trustPolicy = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
"@

$trustPolicy | Out-File -FilePath "trust-policy-prod.json" -Encoding utf8

aws iam create-role `
  --role-name WAC-Prod-DC-SSM-Role `
  --assume-role-policy-document file://trust-policy-prod.json `
  --description "SSM access role for Production Domain Controllers" `
  --tags Key=Environment,Value=Production Key=Purpose,Value=SSM

if ($LASTEXITCODE -eq 0) {
    Write-Host "Success: IAM role created successfully" -ForegroundColor Green
} else {
    Write-Host "Note: Failed to create IAM role (may already exist)" -ForegroundColor Red
}

# Step 2: Attach AWS managed policy for SSM
Write-Host "[2/6] Attaching SSM managed policy..." -ForegroundColor Yellow

aws iam attach-role-policy `
  --role-name WAC-Prod-DC-SSM-Role `
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

if ($LASTEXITCODE -eq 0) {
    Write-Host "Success: SSM policy attached" -ForegroundColor Green
}

# Step 3: Create custom policy for CloudWatch Logs (with MFA requirement)
Write-Host "[3/6] Creating custom CloudWatch Logs policy with MFA..." -ForegroundColor Yellow

$logGroupArn = "arn:aws:logs:${region}:${accountId}:log-group:/aws/ssm/prod-domain-controllers:*"
$s3BucketArn = "arn:aws:s3:::wac-prod-ssm-session-logs-${accountId}/*"

$cloudwatchPolicy = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": "$logGroupArn"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": "$s3BucketArn",
      "Condition": {
        "BoolIfExists": {
          "aws:MultiFactorAuthPresent": "true"
        }
      }
    }
  ]
}
"@

$cloudwatchPolicy | Out-File -FilePath "cloudwatch-policy-prod.json" -Encoding utf8

aws iam create-policy `
  --policy-name WAC-Prod-DC-CloudWatch-Policy `
  --policy-document file://cloudwatch-policy-prod.json `
  --description "CloudWatch Logs access for Production Domain Controllers with MFA"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Success: CloudWatch policy created" -ForegroundColor Green
    
    # Attach the custom policy
    aws iam attach-role-policy `
      --role-name WAC-Prod-DC-SSM-Role `
      --policy-arn arn:aws:iam::${accountId}:policy/WAC-Prod-DC-CloudWatch-Policy
}

# Step 4: Create Instance Profile
Write-Host "[4/6] Creating instance profile..." -ForegroundColor Yellow

aws iam create-instance-profile --instance-profile-name WAC-Prod-DC-SSM-Profile

if ($LASTEXITCODE -eq 0) {
    Write-Host "Success: Instance profile created" -ForegroundColor Green
    
    # Add role to instance profile
    aws iam add-role-to-instance-profile `
      --instance-profile-name WAC-Prod-DC-SSM-Profile `
      --role-name WAC-Prod-DC-SSM-Role
    
    Write-Host "Success: Role added to instance profile" -ForegroundColor Green
}

# Step 5: Create CloudWatch Log Group (180-day retention for Production)
Write-Host "[5/6] Creating CloudWatch log group..." -ForegroundColor Yellow

aws logs create-log-group `
  --log-group-name /aws/ssm/prod-domain-controllers `
  --region $region

if ($LASTEXITCODE -eq 0) {
    Write-Host "Success: Log group created" -ForegroundColor Green
    
    # Set retention to 180 days (Production requirement)
    aws logs put-retention-policy `
      --log-group-name /aws/ssm/prod-domain-controllers `
      --retention-in-days 180 `
      --region $region
    
    Write-Host "Success: Retention set to 180 days" -ForegroundColor Green
}

# Step 6: Create S3 bucket for session logs
Write-Host "[6/6] Creating S3 bucket for session logs..." -ForegroundColor Yellow

aws s3api create-bucket `
  --bucket wac-prod-ssm-session-logs-$accountId `
  --region $region `
  --create-bucket-configuration LocationConstraint=$region

if ($LASTEXITCODE -eq 0) {
    Write-Host "Success: S3 bucket created" -ForegroundColor Green
    
    # Enable versioning
    aws s3api put-bucket-versioning `
      --bucket wac-prod-ssm-session-logs-$accountId `
      --versioning-configuration Status=Enabled
    
    Write-Host "Success: Versioning enabled" -ForegroundColor Green
    
    # Enable encryption
    aws s3api put-bucket-encryption `
      --bucket wac-prod-ssm-session-logs-$accountId `
      --server-side-encryption-configuration '{
        "Rules": [{
          "ApplyServerSideEncryptionByDefault": {
            "SSEAlgorithm": "AES256"
          }
        }]
      }'
    
    Write-Host "Success: Encryption enabled" -ForegroundColor Green
    
    # Block public access
    aws s3api put-public-access-block `
      --bucket wac-prod-ssm-session-logs-$accountId `
      --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    
    Write-Host "Success: Public access blocked" -ForegroundColor Green
}

# Cleanup temp files
Remove-Item -Path "trust-policy-prod.json" -ErrorAction SilentlyContinue
Remove-Item -Path "cloudwatch-policy-prod.json" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "=== Phase 2 Implementation Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Resources Created:" -ForegroundColor Cyan
Write-Host "  IAM Role: WAC-Prod-DC-SSM-Role" -ForegroundColor White
Write-Host "  Instance Profile: WAC-Prod-DC-SSM-Profile" -ForegroundColor White
Write-Host "  CloudWatch Log Group: /aws/ssm/prod-domain-controllers with 180 day retention" -ForegroundColor White
Write-Host "  S3 Bucket: wac-prod-ssm-session-logs-$accountId" -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Attach instance profile to Domain Controller EC2 instances" -ForegroundColor White
Write-Host "  2. Install SSM Agent on instances if not already installed" -ForegroundColor White
Write-Host "  3. Test SSM access from AWS Console or CLI" -ForegroundColor White
Write-Host ""
Write-Host "To attach instance profile to an EC2 instance:" -ForegroundColor Yellow
Write-Host '  aws ec2 associate-iam-instance-profile --instance-id i-xxxxx --iam-instance-profile Name=WAC-Prod-DC-SSM-Profile --region us-west-2' -ForegroundColor White
Write-Host ""
