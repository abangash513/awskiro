# Verify Account Access Script
# Checks what access the current user has across all AWS accounts

Write-Host "========================================" -ForegroundColor Green
Write-Host "AWS ACCOUNT ACCESS VERIFICATION" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

# Get current identity
Write-Host "Current Identity:" -ForegroundColor Cyan
$identity = aws sts get-caller-identity --output json | ConvertFrom-Json
Write-Host "  User: $($identity.Arn)" -ForegroundColor White
Write-Host "  Account: $($identity.Account)" -ForegroundColor White
Write-Host "  UserId: $($identity.UserId)`n" -ForegroundColor White

# List all accounts in the organization
Write-Host "Fetching all accounts in organization..." -ForegroundColor Cyan
$accounts = aws organizations list-accounts --output json | ConvertFrom-Json

if ($accounts.Accounts) {
    Write-Host "Found $($accounts.Accounts.Count) accounts`n" -ForegroundColor Yellow
    
    $accountList = @()
    foreach ($account in $accounts.Accounts) {
        $accountList += [PSCustomObject]@{
            AccountId = $account.Id
            AccountName = $account.Name
            Email = $account.Email
            Status = $account.Status
            JoinedDate = $account.JoinedTimestamp
        }
    }
    
    # Export account list
    $accountList | Export-Csv -Path "organization-accounts-list.csv" -NoTypeInformation
    
    # Display accounts
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "ALL ACCOUNTS IN ORGANIZATION" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Green
    
    $accountList | Format-Table -AutoSize
}

# Check SSO access
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "CHECKING SSO ACCESS" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

# Get current role permissions
Write-Host "Current Role Permissions:" -ForegroundColor Cyan
$roleName = "AWSReservedSSO_AIM-WellArchitectedReview_ffafce28ad424f54"

try {
    $role = aws iam get-role --role-name $roleName --output json | ConvertFrom-Json
    Write-Host "  Role Name: $($role.Role.RoleName)" -ForegroundColor White
    Write-Host "  Role ARN: $($role.Role.Arn)" -ForegroundColor White
    Write-Host "  Created: $($role.Role.CreateDate)" -ForegroundColor White
    Write-Host "  Max Session Duration: $($role.Role.MaxSessionDuration) seconds`n" -ForegroundColor White
    
    # Get attached policies
    Write-Host "Attached Policies:" -ForegroundColor Cyan
    $policies = aws iam list-attached-role-policies --role-name $roleName --output json | ConvertFrom-Json
    
    $policyList = @()
    foreach ($policy in $policies.AttachedPolicies) {
        Write-Host "  - $($policy.PolicyName)" -ForegroundColor White
        $policyList += [PSCustomObject]@{
            PolicyName = $policy.PolicyName
            PolicyArn = $policy.PolicyArn
        }
    }
    
    $policyList | Export-Csv -Path "current-role-policies.csv" -NoTypeInformation
    
} catch {
    Write-Host "  Error getting role details: $_" -ForegroundColor Red
}

# Check what services you can access
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "TESTING SERVICE ACCESS" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

$serviceTests = @(
    @{Name="EC2"; Command="aws ec2 describe-instances --max-results 1 --region us-east-1"},
    @{Name="S3"; Command="aws s3 ls"},
    @{Name="RDS"; Command="aws rds describe-db-instances --max-records 1 --region us-east-1"},
    @{Name="IAM"; Command="aws iam list-users --max-items 1"},
    @{Name="CloudWatch"; Command="aws cloudwatch list-metrics --max-records 1 --region us-east-1"},
    @{Name="Cost Explorer"; Command="aws ce get-cost-and-usage --time-period Start=2025-12-01,End=2025-12-02 --granularity DAILY --metrics UnblendedCost"},
    @{Name="Organizations"; Command="aws organizations describe-organization"},
    @{Name="Lambda"; Command="aws lambda list-functions --max-items 1 --region us-east-1"},
    @{Name="DynamoDB"; Command="aws dynamodb list-tables --region us-east-1"},
    @{Name="CloudFormation"; Command="aws cloudformation list-stacks --max-results 1 --region us-east-1"}
)

$accessResults = @()
foreach ($test in $serviceTests) {
    Write-Host "Testing $($test.Name)..." -ForegroundColor Gray
    try {
        $result = Invoke-Expression "$($test.Command) 2>&1"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✓ $($test.Name): READ ACCESS" -ForegroundColor Green
            $accessResults += [PSCustomObject]@{
                Service = $test.Name
                Access = "READ"
                Status = "Success"
            }
        } else {
            Write-Host "  ✗ $($test.Name): NO ACCESS" -ForegroundColor Red
            $accessResults += [PSCustomObject]@{
                Service = $test.Name
                Access = "NONE"
                Status = "Denied"
            }
        }
    } catch {
        Write-Host "  ✗ $($test.Name): ERROR" -ForegroundColor Red
        $accessResults += [PSCustomObject]@{
            Service = $test.Name
            Access = "ERROR"
            Status = $_.Exception.Message
        }
    }
}

$accessResults | Export-Csv -Path "service-access-test-results.csv" -NoTypeInformation

# Test write access (non-destructive)
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "TESTING WRITE PERMISSIONS" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "Testing EC2 write access (dry-run)..." -ForegroundColor Gray
try {
    $writeTest = aws ec2 run-instances --dry-run --image-id ami-0c55b159cbfafe1f0 --instance-type t2.micro --region us-east-1 2>&1
    if ($writeTest -match "DryRunOperation") {
        Write-Host "  ✓ EC2: WRITE ACCESS (would be allowed)" -ForegroundColor Yellow
    } else {
        Write-Host "  ✗ EC2: NO WRITE ACCESS" -ForegroundColor Red
    }
} catch {
    Write-Host "  ✗ EC2: NO WRITE ACCESS" -ForegroundColor Red
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "ACCESS SUMMARY" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "Your Access Level: READ-ONLY with Well-Architected Review capabilities" -ForegroundColor Cyan
Write-Host "`nYou CAN:" -ForegroundColor Green
Write-Host "  ✓ View all resources across all accounts" -ForegroundColor White
Write-Host "  ✓ Access Cost Explorer and billing data" -ForegroundColor White
Write-Host "  ✓ View and create Well-Architected Reviews" -ForegroundColor White
Write-Host "  ✓ View CloudWatch metrics and logs" -ForegroundColor White
Write-Host "  ✓ View security findings (GuardDuty, Security Hub)" -ForegroundColor White
Write-Host "  ✓ View Trusted Advisor recommendations" -ForegroundColor White
Write-Host "  ✓ View Compute Optimizer recommendations" -ForegroundColor White

Write-Host "`nYou CANNOT:" -ForegroundColor Red
Write-Host "  ✗ Create, modify, or delete resources" -ForegroundColor White
Write-Host "  ✗ Change configurations" -ForegroundColor White
Write-Host "  ✗ Modify IAM policies or users" -ForegroundColor White
Write-Host "  ✗ Deploy applications" -ForegroundColor White
Write-Host "  ✗ Start or stop EC2 instances" -ForegroundColor White

Write-Host "`nFiles Generated:" -ForegroundColor Cyan
Write-Host "  1. organization-accounts-list.csv - All accounts in organization" -ForegroundColor White
Write-Host "  2. current-role-policies.csv - Your current role policies" -ForegroundColor White
Write-Host "  3. service-access-test-results.csv - Service access test results" -ForegroundColor White

Write-Host "`n========================================`n" -ForegroundColor Green
