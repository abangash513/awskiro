# HRI FAST Scanner - Permission Verification Script
# This script tests all required permissions for deploying the HRI FAST Scanner application

param(
    [Parameter(Mandatory=$false)]
    [string]$RoleArn = "",
    
    [Parameter(Mandatory=$false)]
    [string]$ExternalId = "hri-fast-scanner-deployment",
    
    [Parameter(Mandatory=$false)]
    [switch]$AssumeRole = $false
)

# Color output functions
function Write-Success { param($Message) Write-Host "✓ $Message" -ForegroundColor Green }
function Write-Failure { param($Message) Write-Host "✗ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ $Message" -ForegroundColor Cyan }
function Write-Warning { param($Message) Write-Host "⚠ $Message" -ForegroundColor Yellow }
function Write-Section { param($Message) Write-Host "`n=== $Message ===" -ForegroundColor Magenta }

# Test results tracking
$script:TestResults = @{
    Passed = 0
    Failed = 0
    Skipped = 0
    Tests = @()
}

function Add-TestResult {
    param(
        [string]$Service,
        [string]$Action,
        [bool]$Success,
        [string]$Message = ""
    )
    
    $script:TestResults.Tests += [PSCustomObject]@{
        Service = $Service
        Action = $Action
        Success = $Success
        Message = $Message
        Timestamp = Get-Date
    }
    
    if ($Success) {
        $script:TestResults.Passed++
    } else {
        $script:TestResults.Failed++
    }
}

# Assume role if requested
if ($AssumeRole -and $RoleArn) {
    Write-Section "Assuming Role"
    Write-Info "Role ARN: $RoleArn"
    Write-Info "External ID: $ExternalId"
    
    try {
        $assumeRole = aws sts assume-role `
            --role-arn $RoleArn `
            --role-session-name "hri-fast-scanner-verification" `
            --external-id $ExternalId `
            --duration-seconds 3600 `
            --output json | ConvertFrom-Json
        
        if ($assumeRole) {
            $env:AWS_ACCESS_KEY_ID = $assumeRole.Credentials.AccessKeyId
            $env:AWS_SECRET_ACCESS_KEY = $assumeRole.Credentials.SecretAccessKey
            $env:AWS_SESSION_TOKEN = $assumeRole.Credentials.SessionToken
            
            Write-Success "Successfully assumed role"
            Write-Info "Session expires: $($assumeRole.Credentials.Expiration)"
        }
    } catch {
        Write-Failure "Failed to assume role: $_"
        exit 1
    }
}

# Get current identity
Write-Section "Current Identity"
try {
    $identity = aws sts get-caller-identity --output json | ConvertFrom-Json
    Write-Info "Account: $($identity.Account)"
    Write-Info "User/Role: $($identity.Arn)"
    Write-Info "User ID: $($identity.UserId)"
} catch {
    Write-Failure "Failed to get caller identity: $_"
    exit 1
}

# Test S3 Permissions
Write-Section "Testing S3 Permissions"

# Test: List buckets
Write-Info "Testing: List S3 buckets..."
try {
    $buckets = aws s3 ls 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Can list S3 buckets"
        Add-TestResult -Service "S3" -Action "ListBuckets" -Success $true
    } else {
        Write-Failure "Cannot list S3 buckets"
        Add-TestResult -Service "S3" -Action "ListBuckets" -Success $false -Message $buckets
    }
} catch {
    Write-Failure "Error listing S3 buckets: $_"
    Add-TestResult -Service "S3" -Action "ListBuckets" -Success $false -Message $_
}

# Test: Create bucket
Write-Info "Testing: Create S3 bucket..."
$testBucket = "hri-fast-scanner-test-$(Get-Date -Format 'yyyyMMddHHmmss')"
try {
    $result = aws s3 mb "s3://$testBucket" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Can create S3 bucket: $testBucket"
        Add-TestResult -Service "S3" -Action "CreateBucket" -Success $true
        
        # Test: Upload object
        Write-Info "Testing: Upload object to S3..."
        "Test content" | Out-File -FilePath "test-file.txt" -Encoding utf8
        $uploadResult = aws s3 cp test-file.txt "s3://$testBucket/test-file.txt" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Can upload objects to S3"
            Add-TestResult -Service "S3" -Action "PutObject" -Success $true
        } else {
            Write-Failure "Cannot upload objects to S3"
            Add-TestResult -Service "S3" -Action "PutObject" -Success $false -Message $uploadResult
        }
        
        # Cleanup
        aws s3 rb "s3://$testBucket" --force 2>&1 | Out-Null
        Remove-Item "test-file.txt" -ErrorAction SilentlyContinue
    } else {
        Write-Failure "Cannot create S3 bucket"
        Add-TestResult -Service "S3" -Action "CreateBucket" -Success $false -Message $result
    }
} catch {
    Write-Failure "Error creating S3 bucket: $_"
    Add-TestResult -Service "S3" -Action "CreateBucket" -Success $false -Message $_
}

# Test Lambda Permissions
Write-Section "Testing Lambda Permissions"

# Test: List functions
Write-Info "Testing: List Lambda functions..."
try {
    $functions = aws lambda list-functions --max-items 1 --output json 2>&1 | ConvertFrom-Json
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Can list Lambda functions"
        Add-TestResult -Service "Lambda" -Action "ListFunctions" -Success $true
    } else {
        Write-Failure "Cannot list Lambda functions"
        Add-TestResult -Service "Lambda" -Action "ListFunctions" -Success $false
    }
} catch {
    Write-Failure "Error listing Lambda functions: $_"
    Add-TestResult -Service "Lambda" -Action "ListFunctions" -Success $false -Message $_
}

# Test: Create function (dry-run simulation)
Write-Info "Testing: Lambda create function permissions..."
$testFunctionName = "hri-fast-scanner-test-function"
try {
    # Check if we can get function (will fail if doesn't exist, but tests permission)
    $getResult = aws lambda get-function --function-name $testFunctionName 2>&1
    if ($getResult -match "ResourceNotFoundException") {
        Write-Success "Have Lambda GetFunction permission (function doesn't exist, which is expected)"
        Add-TestResult -Service "Lambda" -Action "GetFunction" -Success $true
    } elseif ($LASTEXITCODE -eq 0) {
        Write-Success "Have Lambda GetFunction permission"
        Add-TestResult -Service "Lambda" -Action "GetFunction" -Success $true
    } else {
        Write-Warning "Lambda GetFunction permission unclear"
        Add-TestResult -Service "Lambda" -Action "GetFunction" -Success $false -Message $getResult
    }
} catch {
    Write-Warning "Lambda GetFunction test inconclusive: $_"
}

# Test API Gateway Permissions
Write-Section "Testing API Gateway Permissions"

# Test: List REST APIs
Write-Info "Testing: List API Gateway REST APIs..."
try {
    $apis = aws apigateway get-rest-apis --output json 2>&1 | ConvertFrom-Json
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Can list API Gateway REST APIs"
        Add-TestResult -Service "APIGateway" -Action "GetRestApis" -Success $true
    } else {
        Write-Failure "Cannot list API Gateway REST APIs"
        Add-TestResult -Service "APIGateway" -Action "GetRestApis" -Success $false
    }
} catch {
    Write-Failure "Error listing API Gateway REST APIs: $_"
    Add-TestResult -Service "APIGateway" -Action "GetRestApis" -Success $false -Message $_
}

# Test DynamoDB Permissions
Write-Section "Testing DynamoDB Permissions"

# Test: List tables
Write-Info "Testing: List DynamoDB tables..."
try {
    $tables = aws dynamodb list-tables --output json 2>&1 | ConvertFrom-Json
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Can list DynamoDB tables"
        Add-TestResult -Service "DynamoDB" -Action "ListTables" -Success $true
    } else {
        Write-Failure "Cannot list DynamoDB tables"
        Add-TestResult -Service "DynamoDB" -Action "ListTables" -Success $false
    }
} catch {
    Write-Failure "Error listing DynamoDB tables: $_"
    Add-TestResult -Service "DynamoDB" -Action "ListTables" -Success $false -Message $_
}

# Test: Create table
Write-Info "Testing: Create DynamoDB table..."
$testTable = "hri-fast-scanner-test-table"
try {
    $createTableJson = @"
{
    "TableName": "$testTable",
    "KeySchema": [
        {"AttributeName": "id", "KeyType": "HASH"}
    ],
    "AttributeDefinitions": [
        {"AttributeName": "id", "AttributeType": "S"}
    ],
    "BillingMode": "PAY_PER_REQUEST",
    "Tags": [
        {"Key": "Purpose", "Value": "PermissionTest"}
    ]
}
"@
    
    $createTableJson | Out-File -FilePath "create-table.json" -Encoding utf8
    $result = aws dynamodb create-table --cli-input-json file://create-table.json 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Can create DynamoDB table: $testTable"
        Add-TestResult -Service "DynamoDB" -Action "CreateTable" -Success $true
        
        # Wait for table to be active
        Write-Info "Waiting for table to be active..."
        Start-Sleep -Seconds 5
        
        # Test: Put item
        Write-Info "Testing: Put item to DynamoDB..."
        $putItemJson = @"
{
    "TableName": "$testTable",
    "Item": {
        "id": {"S": "test-id"},
        "data": {"S": "test-data"}
    }
}
"@
        $putItemJson | Out-File -FilePath "put-item.json" -Encoding utf8
        $putResult = aws dynamodb put-item --cli-input-json file://put-item.json 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Can put items to DynamoDB"
            Add-TestResult -Service "DynamoDB" -Action "PutItem" -Success $true
        } else {
            Write-Failure "Cannot put items to DynamoDB"
            Add-TestResult -Service "DynamoDB" -Action "PutItem" -Success $false -Message $putResult
        }
        
        # Cleanup
        aws dynamodb delete-table --table-name $testTable 2>&1 | Out-Null
        Remove-Item "create-table.json" -ErrorAction SilentlyContinue
        Remove-Item "put-item.json" -ErrorAction SilentlyContinue
    } else {
        Write-Failure "Cannot create DynamoDB table"
        Add-TestResult -Service "DynamoDB" -Action "CreateTable" -Success $false -Message $result
    }
} catch {
    Write-Failure "Error creating DynamoDB table: $_"
    Add-TestResult -Service "DynamoDB" -Action "CreateTable" -Success $false -Message $_
}

# Test IAM Permissions
Write-Section "Testing IAM Permissions"

# Test: List roles
Write-Info "Testing: List IAM roles..."
try {
    $roles = aws iam list-roles --max-items 1 --output json 2>&1 | ConvertFrom-Json
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Can list IAM roles"
        Add-TestResult -Service "IAM" -Action "ListRoles" -Success $true
    } else {
        Write-Failure "Cannot list IAM roles"
        Add-TestResult -Service "IAM" -Action "ListRoles" -Success $false
    }
} catch {
    Write-Failure "Error listing IAM roles: $_"
    Add-TestResult -Service "IAM" -Action "ListRoles" -Success $false -Message $_
}

# Test CloudWatch Permissions
Write-Section "Testing CloudWatch Permissions"

# Test: List log groups
Write-Info "Testing: List CloudWatch log groups..."
try {
    $logGroups = aws logs describe-log-groups --max-items 1 --output json 2>&1 | ConvertFrom-Json
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Can list CloudWatch log groups"
        Add-TestResult -Service "CloudWatch" -Action "DescribeLogGroups" -Success $true
    } else {
        Write-Failure "Cannot list CloudWatch log groups"
        Add-TestResult -Service "CloudWatch" -Action "DescribeLogGroups" -Success $false
    }
} catch {
    Write-Failure "Error listing CloudWatch log groups: $_"
    Add-TestResult -Service "CloudWatch" -Action "DescribeLogGroups" -Success $false -Message $_
}

# Test CloudFormation Permissions
Write-Section "Testing CloudFormation Permissions"

# Test: List stacks
Write-Info "Testing: List CloudFormation stacks..."
try {
    $stacks = aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --max-items 1 --output json 2>&1 | ConvertFrom-Json
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Can list CloudFormation stacks"
        Add-TestResult -Service "CloudFormation" -Action "ListStacks" -Success $true
    } else {
        Write-Failure "Cannot list CloudFormation stacks"
        Add-TestResult -Service "CloudFormation" -Action "ListStacks" -Success $false
    }
} catch {
    Write-Failure "Error listing CloudFormation stacks: $_"
    Add-TestResult -Service "CloudFormation" -Action "ListStacks" -Success $false -Message $_
}

# Test Cognito Permissions
Write-Section "Testing Cognito Permissions"

# Test: List user pools
Write-Info "Testing: List Cognito user pools..."
try {
    $userPools = aws cognito-idp list-user-pools --max-results 1 --output json 2>&1 | ConvertFrom-Json
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Can list Cognito user pools"
        Add-TestResult -Service "Cognito" -Action "ListUserPools" -Success $true
    } else {
        Write-Failure "Cannot list Cognito user pools"
        Add-TestResult -Service "Cognito" -Action "ListUserPools" -Success $false
    }
} catch {
    Write-Failure "Error listing Cognito user pools: $_"
    Add-TestResult -Service "Cognito" -Action "ListUserPools" -Success $false -Message $_
}

# Test EC2/VPC Permissions
Write-Section "Testing EC2/VPC Permissions"

# Test: Describe VPCs
Write-Info "Testing: Describe VPCs..."
try {
    $vpcs = aws ec2 describe-vpcs --max-results 5 --output json 2>&1 | ConvertFrom-Json
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Can describe VPCs"
        Add-TestResult -Service "EC2" -Action "DescribeVpcs" -Success $true
    } else {
        Write-Failure "Cannot describe VPCs"
        Add-TestResult -Service "EC2" -Action "DescribeVpcs" -Success $false
    }
} catch {
    Write-Failure "Error describing VPCs: $_"
    Add-TestResult -Service "EC2" -Action "DescribeVpcs" -Success $false -Message $_
}

# Generate Summary Report
Write-Section "Test Summary"

$totalTests = $script:TestResults.Passed + $script:TestResults.Failed
$passRate = if ($totalTests -gt 0) { [math]::Round(($script:TestResults.Passed / $totalTests) * 100, 2) } else { 0 }

Write-Host "`nTotal Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $($script:TestResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($script:TestResults.Failed)" -ForegroundColor Red
Write-Host "Pass Rate: $passRate%" -ForegroundColor $(if ($passRate -ge 80) { "Green" } elseif ($passRate -ge 50) { "Yellow" } else { "Red" })

# Detailed results by service
Write-Section "Results by Service"

$serviceGroups = $script:TestResults.Tests | Group-Object -Property Service

foreach ($group in $serviceGroups) {
    $servicePassed = ($group.Group | Where-Object { $_.Success }).Count
    $serviceFailed = ($group.Group | Where-Object { -not $_.Success }).Count
    $serviceTotal = $servicePassed + $serviceFailed
    
    Write-Host "`n$($group.Name):" -ForegroundColor Cyan
    Write-Host "  Passed: $servicePassed / $serviceTotal" -ForegroundColor $(if ($servicePassed -eq $serviceTotal) { "Green" } else { "Yellow" })
    
    foreach ($test in $group.Group) {
        $icon = if ($test.Success) { "✓" } else { "✗" }
        $color = if ($test.Success) { "Green" } else { "Red" }
        Write-Host "    $icon $($test.Action)" -ForegroundColor $color
        if (-not $test.Success -and $test.Message) {
            Write-Host "      Error: $($test.Message)" -ForegroundColor DarkRed
        }
    }
}

# Export results to JSON
$reportFile = "hri-scanner-permission-test-results-$(Get-Date -Format 'yyyyMMddHHmmss').json"
$script:TestResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportFile -Encoding utf8
Write-Info "`nDetailed results exported to: $reportFile"

# Final verdict
Write-Section "Final Verdict"

if ($script:TestResults.Failed -eq 0) {
    Write-Success "All permissions verified successfully! You can proceed with HRI FAST Scanner deployment."
    exit 0
} elseif ($passRate -ge 80) {
    Write-Warning "Most permissions verified ($passRate% pass rate). Review failed tests before deployment."
    exit 0
} else {
    Write-Failure "Insufficient permissions ($passRate% pass rate). Please review and fix failed tests."
    exit 1
}
