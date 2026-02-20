# HRI Fast Scanner - PowerShell Deployment Script
# For Windows users

param(
    [string]$Region = "us-east-1",
    [string]$NotificationEmail = "",
    [string]$StackName = "hri-scanner-management",
    [string]$MemberStackName = "hri-scanner-member-role"
)

# Colors for output
function Write-Success { Write-Host "✓ $args" -ForegroundColor Green }
function Write-Info { Write-Host "ℹ $args" -ForegroundColor Cyan }
function Write-Warning { Write-Host "⚠ $args" -ForegroundColor Yellow }
function Write-Error { Write-Host "✗ $args" -ForegroundColor Red }
function Write-Header { 
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host $args -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Green
}

# Check prerequisites
function Test-Prerequisites {
    Write-Header "Checking Prerequisites"
    
    # Check AWS CLI
    try {
        $null = aws --version
        Write-Success "AWS CLI installed"
    }
    catch {
        Write-Error "AWS CLI not found. Please install it first."
        exit 1
    }
    
    # Check Python
    try {
        $null = python --version
        Write-Success "Python installed"
    }
    catch {
        Write-Error "Python not found. Please install Python 3.12+"
        exit 1
    }
    
    # Check AWS credentials
    try {
        $identity = aws sts get-caller-identity | ConvertFrom-Json
        Write-Success "AWS credentials configured"
        Write-Info "Account ID: $($identity.Account)"
        return $identity.Account
    }
    catch {
        Write-Error "AWS credentials not configured. Run 'aws configure' first."
        exit 1
    }
}

# Package Lambda code
function New-LambdaPackages {
    Write-Header "Packaging Lambda Functions"
    
    Push-Location ..\lambda
    
    # Package discover_accounts
    if (Test-Path "discover_accounts.py") {
        Compress-Archive -Path discover_accounts.py -DestinationPath discover_accounts.zip -Force
        Write-Success "Packaged discover_accounts.zip"
    }
    else {
        Write-Error "discover_accounts.py not found"
        Pop-Location
        exit 1
    }
    
    # Package scan_account
    if (Test-Path "scan_account.py") {
        Compress-Archive -Path scan_account.py -DestinationPath scan_account.zip -Force
        Write-Success "Packaged scan_account.zip"
    }
    else {
        Write-Error "scan_account.py not found"
        Pop-Location
        exit 1
    }
    
    Pop-Location
}

# Deploy management stack
function Deploy-ManagementStack {
    param([string]$AccountId)
    
    Write-Header "Deploying Management Account Stack"
    
    # Build parameters
    $params = "ParameterKey=ScannerRoleName,ParameterValue=HRI-ScannerRole"
    
    if ($NotificationEmail) {
        $params += " ParameterKey=NotificationEmail,ParameterValue=$NotificationEmail"
    }
    
    Write-Info "Creating CloudFormation stack..."
    aws cloudformation create-stack `
        --stack-name $StackName `
        --template-body file://management-account-stack.yaml `
        --capabilities CAPABILITY_NAMED_IAM `
        --parameters $params `
        --region $Region
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to create stack"
        exit 1
    }
    
    Write-Info "Waiting for stack creation to complete (this may take 5-10 minutes)..."
    aws cloudformation wait stack-create-complete `
        --stack-name $StackName `
        --region $Region
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Management stack deployed successfully"
    }
    else {
        Write-Error "Stack creation failed. Check AWS Console for details."
        exit 1
    }
}

# Update Lambda code
function Update-LambdaCode {
    Write-Header "Updating Lambda Function Code"
    
    Push-Location ..\lambda
    
    # Update discover_accounts
    Write-Info "Updating discover_accounts function..."
    aws lambda update-function-code `
        --function-name hri-discover-accounts `
        --zip-file fileb://discover_accounts.zip `
        --region $Region | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Updated discover_accounts function"
    }
    
    # Update scan_account
    Write-Info "Updating scan_account function..."
    aws lambda update-function-code `
        --function-name hri-scan-account `
        --zip-file fileb://scan_account.zip `
        --region $Region | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Updated scan_account function"
    }
    
    Pop-Location
}

# Deploy member stack
function Deploy-MemberStack {
    param([string]$AccountId)
    
    Write-Header "Deploying Member Account Stack"
    
    $choice = Read-Host "Deploy member account role? (Y/N)"
    
    if ($choice -eq 'Y' -or $choice -eq 'y') {
        Write-Info "Deploying to current account..."
        
        aws cloudformation create-stack `
            --stack-name $MemberStackName `
            --template-body file://member-account-stack.yaml `
            --capabilities CAPABILITY_NAMED_IAM `
            --parameters `
                ParameterKey=ManagementAccountId,ParameterValue=$AccountId `
                ParameterKey=ScannerRoleName,ParameterValue=HRI-ScannerRole `
                ParameterKey=ExternalId,ParameterValue=hri-scanner-external-id-12345 `
            --region $Region
        
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Failed to create member stack"
            return
        }
        
        Write-Info "Waiting for stack creation to complete..."
        aws cloudformation wait stack-create-complete `
            --stack-name $MemberStackName `
            --region $Region
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Member account stack deployed successfully"
        }
    }
    else {
        Write-Warning "Skipping member account deployment"
        Write-Info "Deploy manually using:"
        Write-Host "aws cloudformation create-stack --stack-name $MemberStackName --template-body file://member-account-stack.yaml --capabilities CAPABILITY_NAMED_IAM --parameters ParameterKey=ManagementAccountId,ParameterValue=$AccountId"
    }
}

# Verify deployment
function Test-Deployment {
    Write-Header "Verifying Deployment"
    
    # Check stack status
    $stackStatus = aws cloudformation describe-stacks `
        --stack-name $StackName `
        --query 'Stacks[0].StackStatus' `
        --output text `
        --region $Region
    
    if ($stackStatus -eq "CREATE_COMPLETE") {
        Write-Success "Stack status: $stackStatus"
    }
    else {
        Write-Error "Stack status: $stackStatus"
        return
    }
    
    # Check Lambda functions
    Write-Info "Verifying Lambda functions..."
    try {
        aws lambda get-function --function-name hri-discover-accounts --region $Region | Out-Null
        aws lambda get-function --function-name hri-scan-account --region $Region | Out-Null
        Write-Success "Lambda functions verified"
    }
    catch {
        Write-Warning "Lambda function verification failed"
    }
    
    # Check DynamoDB table
    Write-Info "Verifying DynamoDB table..."
    $tableStatus = aws dynamodb describe-table `
        --table-name hri_findings `
        --query 'Table.TableStatus' `
        --output text `
        --region $Region
    Write-Success "DynamoDB table status: $tableStatus"
    
    # Check S3 bucket
    Write-Info "Verifying S3 bucket..."
    $accountId = aws sts get-caller-identity --query Account --output text
    $bucketName = "hri-exports-$accountId-$Region"
    
    try {
        aws s3 ls "s3://$bucketName" | Out-Null
        Write-Success "S3 bucket verified: $bucketName"
    }
    catch {
        Write-Warning "S3 bucket verification failed"
    }
}

# Test the deployment
function Invoke-TestScan {
    Write-Header "Testing Deployment"
    
    $runTest = Read-Host "Run test scan? (Y/N)"
    
    if ($runTest -eq 'Y' -or $runTest -eq 'y') {
        Write-Info "Invoking discover_accounts function..."
        
        aws lambda invoke `
            --function-name hri-discover-accounts `
            --payload '{}' `
            --region $Region `
            response.json | Out-Null
        
        Write-Info "Response:"
        Get-Content response.json | ConvertFrom-Json | ConvertTo-Json
        
        Remove-Item response.json -ErrorAction SilentlyContinue
        
        Write-Info "`nCheck CloudWatch Logs for detailed output:"
        Write-Host "aws logs tail /aws/lambda/hri-discover-accounts --follow" -ForegroundColor Cyan
    }
    else {
        Write-Warning "Skipping test"
    }
}

# Print summary
function Show-Summary {
    Write-Header "Deployment Summary"
    
    Write-Info "Stack Outputs:"
    aws cloudformation describe-stacks `
        --stack-name $StackName `
        --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' `
        --output table `
        --region $Region
    
    Write-Success "`nDeployment completed successfully!"
    
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Confirm SNS email subscription (if provided)"
    Write-Host "2. Deploy member account roles to other accounts"
    Write-Host "3. Run a test scan: aws lambda invoke --function-name hri-discover-accounts --payload '{}' response.json"
    Write-Host "4. Check findings: aws dynamodb scan --table-name hri_findings --max-items 10"
    Write-Host "`nDocumentation: See DEPLOYMENT_GUIDE.md for detailed instructions"
}

# Main execution
function Main {
    Write-Header "HRI Fast Scanner - PowerShell Deployment"
    
    try {
        $accountId = Test-Prerequisites
        New-LambdaPackages
        Deploy-ManagementStack -AccountId $accountId
        Update-LambdaCode
        Deploy-MemberStack -AccountId $accountId
        Test-Deployment
        Invoke-TestScan
        Show-Summary
    }
    catch {
        Write-Error "Deployment failed: $_"
        exit 1
    }
}

# Run main function
Main
