# Delete CloudFormation Stack Script (PowerShell)
# This script will delete the concierge medicine application from AWS account 750299845580

$ErrorActionPreference = "Stop"

$STACK_NAME = "concierge-medicine-stack"
$REGION = "us-east-1"
$ACCOUNT_ID = "750299845580"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "CloudFormation Stack Deletion Script" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Stack Name: $STACK_NAME"
Write-Host "Region: $REGION"
Write-Host "Account ID: $ACCOUNT_ID"
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check if AWS CLI is installed
try {
    $null = Get-Command aws -ErrorAction Stop
} catch {
    Write-Host "ERROR: AWS CLI is not installed. Please install it first." -ForegroundColor Red
    exit 1
}

# Verify AWS credentials
Write-Host "Verifying AWS credentials..."
try {
    $CURRENT_ACCOUNT = aws sts get-caller-identity --query Account --output text
} catch {
    Write-Host "ERROR: Unable to verify AWS credentials. Please configure AWS CLI." -ForegroundColor Red
    exit 1
}

if ($CURRENT_ACCOUNT -ne $ACCOUNT_ID) {
    Write-Host "WARNING: Current AWS account ($CURRENT_ACCOUNT) does not match expected account ($ACCOUNT_ID)" -ForegroundColor Yellow
    $CONTINUE = Read-Host "Do you want to continue? (yes/no)"
    if ($CONTINUE -ne "yes") {
        Write-Host "Aborted."
        exit 1
    }
}

Write-Host "AWS credentials verified for account: $CURRENT_ACCOUNT" -ForegroundColor Green
Write-Host ""

# Check if stack exists
Write-Host "Checking if stack exists..."
try {
    $STACK_STATUS = aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query 'Stacks[0].StackStatus' --output text 2>$null
} catch {
    $STACK_STATUS = "DOES_NOT_EXIST"
}

if ($STACK_STATUS -eq "DOES_NOT_EXIST" -or $LASTEXITCODE -ne 0) {
    Write-Host "Stack '$STACK_NAME' does not exist in region $REGION" -ForegroundColor Yellow
    Write-Host "Nothing to delete."
    exit 0
}

Write-Host "Stack found with status: $STACK_STATUS" -ForegroundColor Green
Write-Host ""

# Warn user about deletion
Write-Host "==========================================" -ForegroundColor Yellow
Write-Host "WARNING: This will DELETE the following:" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Yellow
Write-Host "- RDS Database (all data will be lost)"
Write-Host "- S3 Buckets and their contents"
Write-Host "- ECS Services and Tasks"
Write-Host "- Load Balancers"
Write-Host "- VPC and networking resources"
Write-Host "- IAM Roles and Policies"
Write-Host "- CloudWatch Logs"
Write-Host "- All other resources in the stack"
Write-Host "==========================================" -ForegroundColor Yellow
Write-Host ""

$CONFIRM = Read-Host "Are you sure you want to delete the stack? Type 'DELETE' to confirm"

if ($CONFIRM -ne "DELETE") {
    Write-Host "Deletion cancelled."
    exit 0
}

Write-Host ""
Write-Host "Starting stack deletion..." -ForegroundColor Cyan

# Delete the stack
aws cloudformation delete-stack --stack-name $STACK_NAME --region $REGION

Write-Host "Stack deletion initiated." -ForegroundColor Green
Write-Host ""
Write-Host "Waiting for stack deletion to complete..."
Write-Host "(This may take 10-20 minutes)" -ForegroundColor Yellow
Write-Host ""

# Wait for deletion to complete
aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME --region $REGION

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "Stack deletion completed successfully!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "All resources have been removed from your AWS account."
Write-Host ""

# Check for any remaining resources (S3 buckets with deletion protection)
Write-Host "Checking for any remaining S3 buckets..."
$BUCKETS = aws s3 ls | Select-String "concierge-medicine"

if ($BUCKETS) {
    Write-Host ""
    Write-Host "WARNING: The following S3 buckets may still exist:" -ForegroundColor Yellow
    Write-Host $BUCKETS
    Write-Host ""
    Write-Host "If buckets remain, you may need to manually delete them:"
    Write-Host "1. Empty the bucket: aws s3 rm s3://bucket-name --recursive"
    Write-Host "2. Delete the bucket: aws s3 rb s3://bucket-name"
}

Write-Host ""
Write-Host "Cleanup complete!" -ForegroundColor Green
