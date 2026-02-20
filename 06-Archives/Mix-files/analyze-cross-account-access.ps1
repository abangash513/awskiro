# Cross-Account Access Analysis Script
# Analyzes current access from management account to all child accounts

Write-Host "========================================" -ForegroundColor Green
Write-Host "CROSS-ACCOUNT ACCESS ANALYSIS" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

# Step 1: Get current identity
Write-Host "[1/5] Identifying current user and role..." -ForegroundColor Cyan
$identity = aws sts get-caller-identity --output json | ConvertFrom-Json

Write-Host "  Current Account: $($identity.Account)" -ForegroundColor White
Write-Host "  Current ARN: $($identity.Arn)" -ForegroundColor White
Write-Host "  User ID: $($identity.UserId)`n" -ForegroundColor White

# Extract role name from ARN
$roleArn = $identity.Arn
$roleName = if ($roleArn -match "assumed-role/([^/]+)") { $matches[1] } else { "Unknown" }
Write-Host "  Detected Role Name: $roleName`n" -ForegroundColor Yellow

# Step 2: Get current role details
Write-Host "[2/5] Analyzing current role permissions..." -ForegroundColor Cyan

try {
    $role = aws iam get-role --role-name $roleName --output json | ConvertFrom-Json
    Write-Host "  Role ARN: $($role.Role.Arn)" -ForegroundColor White
    Write-Host "  Created: $($role.Role.CreateDate)" -ForegroundColor White
    
    # Get attached policies
    $policies = aws iam list-attached-role-policies --role-name $roleName --output json | ConvertFrom-Json
    
    Write-Host "`n  Attached Managed Policies:" -ForegroundColor Yellow
    foreach ($policy in $policies.AttachedPolicies) {
        Write-Host "    - $($policy.PolicyName)" -ForegroundColor White
    }
    
    # Check for inline policies
    $inlinePolicies = aws iam list-role-policies --role-name $roleName --output json | ConvertFrom-Json
    if ($inlinePolicies.PolicyNames.Count -gt 0) {
        Write-Host "`n  Inline Policies:" -ForegroundColor Yellow
        foreach ($policyName in $inlinePolicies.PolicyNames) {
            Write-Host "    - $policyName" -ForegroundColor White
        }
    }
    
    # Check for AssumeRole permissions
    Write-Host "`n  Checking for AssumeRole permissions..." -ForegroundColor Yellow
    $hasAssumeRole = $false
    
    foreach ($policy in $policies.AttachedPolicies) {
        $policyDoc = aws iam get-policy --policy-arn $($policy.PolicyArn) --output json 2>$null | ConvertFrom-Json
        if ($policyDoc) {
            $policyVersion = aws iam get-policy-version --policy-arn $($policy.PolicyArn) --version-id $($policyDoc.Policy.DefaultVersionId) --output json 2>$null | ConvertFrom-Json
            
            if ($policyVersion.PolicyVersion.Document -match "sts:AssumeRole") {
                $hasAssumeRole = $true
                Write-Host "    ✓ Found AssumeRole permission in $($policy.PolicyName)" -ForegroundColor Green
            }
        }
    }
    
    if (-not $hasAssumeRole) {
        Write-Host "    ✗ No AssumeRole permissions found" -ForegroundColor Red
    }
    
} catch {
    Write-Host "  Error analyzing role: $_" -ForegroundColor Red
}

# Step 3: List all accounts
Write-Host "`n[3/5] Listing all accounts in organization..." -ForegroundColor Cyan
$accounts = aws organizations list-accounts --output json | ConvertFrom-Json

$accountList = @()
foreach ($account in $accounts.Accounts) {
    $accountList += [PSCustomObject]@{
        AccountId = $account.Id
        AccountName = $account.Name
        Email = $account.Email
        Status = $account.Status
    }
}

Write-Host "  Found $($accountList.Count) accounts`n" -ForegroundColor Yellow

# Step 4: Test assume role to each account
Write-Host "[4/5] Testing AssumeRole to each child account..." -ForegroundColor Cyan

$assumeRoleResults = @()

foreach ($account in $accountList) {
    if ($account.AccountId -eq $identity.Account) {
        Write-Host "  Skipping management account: $($account.AccountName)" -ForegroundColor Gray
        $assumeRoleResults += [PSCustomObject]@{
            AccountId = $account.AccountId
            AccountName = $account.AccountName
            CanAssumeRole = "N/A (Management Account)"
            RoleExists = "N/A"
            ErrorMessage = "Current account"
        }
        continue
    }
    
    Write-Host "  Testing $($account.AccountName) ($($account.AccountId))..." -ForegroundColor Gray
    
    # Try to assume role in target account
    $targetRoleArn = "arn:aws:iam::$($account.AccountId):role/$roleName"
    
    try {
        $assumeResult = aws sts assume-role `
            --role-arn $targetRoleArn `
            --role-session-name "CrossAccountTest" `
            --duration-seconds 900 `
            --output json 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    ✓ Successfully assumed role" -ForegroundColor Green
            $assumeRoleResults += [PSCustomObject]@{
                AccountId = $account.AccountId
                AccountName = $account.AccountName
                CanAssumeRole = "YES"
                RoleExists = "YES"
                ErrorMessage = "Success"
            }
        } else {
            $errorMsg = $assumeResult | Out-String
            
            if ($errorMsg -match "AccessDenied") {
                Write-Host "    ✗ Access Denied - Role may exist but no permission to assume" -ForegroundColor Red
                $assumeRoleResults += [PSCustomObject]@{
                    AccountId = $account.AccountId
                    AccountName = $account.AccountName
                    CanAssumeRole = "NO"
                    RoleExists = "UNKNOWN"
                    ErrorMessage = "AccessDenied"
                }
            } elseif ($errorMsg -match "NoSuchEntity") {
                Write-Host "    ✗ Role does not exist in target account" -ForegroundColor Red
                $assumeRoleResults += [PSCustomObject]@{
                    AccountId = $account.AccountId
                    AccountName = $account.AccountName
                    CanAssumeRole = "NO"
                    RoleExists = "NO"
                    ErrorMessage = "Role does not exist"
                }
            } else {
                Write-Host "    ✗ Unknown error" -ForegroundColor Red
                $assumeRoleResults += [PSCustomObject]@{
                    AccountId = $account.AccountId
                    AccountName = $account.AccountName
                    CanAssumeRole = "NO"
                    RoleExists = "UNKNOWN"
                    ErrorMessage = $errorMsg.Substring(0, [Math]::Min(100, $errorMsg.Length))
                }
            }
        }
    } catch {
        Write-Host "    ✗ Error: $_" -ForegroundColor Red
        $assumeRoleResults += [PSCustomObject]@{
            AccountId = $account.AccountId
            AccountName = $account.AccountName
            CanAssumeRole = "NO"
            RoleExists = "UNKNOWN"
            ErrorMessage = $_.Exception.Message
        }
    }
}

# Export results
$assumeRoleResults | Export-Csv -Path "cross-account-access-test-results.csv" -NoTypeInformation

# Step 5: Generate summary and recommendations
Write-Host "`n[5/5] Generating summary and recommendations..." -ForegroundColor Cyan

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "CROSS-ACCOUNT ACCESS SUMMARY" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

$canAccess = ($assumeRoleResults | Where-Object CanAssumeRole -eq "YES").Count
$cannotAccess = ($assumeRoleResults | Where-Object CanAssumeRole -eq "NO").Count
$roleDoesNotExist = ($assumeRoleResults | Where-Object RoleExists -eq "NO").Count

Write-Host "Total Accounts: $($accountList.Count)" -ForegroundColor Cyan
Write-Host "Management Account: 1" -ForegroundColor White
Write-Host "Child Accounts: $($accountList.Count - 1)" -ForegroundColor White
Write-Host "`nAccess Status:" -ForegroundColor Cyan
Write-Host "  ✓ Can Access: $canAccess accounts" -ForegroundColor Green
Write-Host "  ✗ Cannot Access: $cannotAccess accounts" -ForegroundColor Red
Write-Host "  ✗ Role Does Not Exist: $roleDoesNotExist accounts" -ForegroundColor Red

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "DETAILED RESULTS" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

$assumeRoleResults | Format-Table -AutoSize

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "RECOMMENDATIONS" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

if ($roleDoesNotExist -gt 0) {
    Write-Host "✗ ISSUE: Role '$roleName' does not exist in $roleDoesNotExist child account(s)" -ForegroundColor Red
    Write-Host "`nSOLUTION:" -ForegroundColor Yellow
    Write-Host "  1. Deploy the role to all child accounts using CloudFormation StackSets" -ForegroundColor White
    Write-Host "  2. Use the provided CloudFormation template: cross-account-role-stackset.yaml" -ForegroundColor White
    Write-Host "  3. Deploy from management account to all child accounts" -ForegroundColor White
}

if ($cannotAccess -gt 0 -and $roleDoesNotExist -eq 0) {
    Write-Host "✗ ISSUE: Role exists but you don't have permission to assume it" -ForegroundColor Red
    Write-Host "`nSOLUTION:" -ForegroundColor Yellow
    Write-Host "  1. Update the trust policy on the role in child accounts" -ForegroundColor White
    Write-Host "  2. Add AssumeRole permission to your current role in management account" -ForegroundColor White
    Write-Host "  3. Use the provided CloudFormation templates" -ForegroundColor White
}

if ($canAccess -eq ($accountList.Count - 1)) {
    Write-Host "✓ SUCCESS: You have access to all child accounts!" -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "NEXT STEPS" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "1. Review the test results: cross-account-access-test-results.csv" -ForegroundColor White
Write-Host "2. Deploy CloudFormation templates to fix access issues:" -ForegroundColor White
Write-Host "   - management-account-policy.yaml (in management account)" -ForegroundColor White
Write-Host "   - cross-account-role-stackset.yaml (to all child accounts)" -ForegroundColor White
Write-Host "3. Re-run this script to verify access" -ForegroundColor White

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "FILES GENERATED" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "1. cross-account-access-test-results.csv - Detailed test results" -ForegroundColor White

Write-Host "`n========================================`n" -ForegroundColor Green
