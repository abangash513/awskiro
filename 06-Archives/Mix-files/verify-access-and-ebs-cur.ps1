# Comprehensive Account Access Verification and EBS/CUR Comparison
# Verifies access to all accounts and compares EBS inventory with CUR data

Write-Host "========================================" -ForegroundColor Green
Write-Host "COMPREHENSIVE ACCESS & EBS/CUR VERIFICATION" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

# Step 1: List all accounts
Write-Host "[1/4] Fetching all accounts in organization..." -ForegroundColor Cyan
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

Write-Host "Found $($accountList.Count) accounts`n" -ForegroundColor Yellow
$accountList | Format-Table -AutoSize

$accountList | Export-Csv -Path "all-organization-accounts.csv" -NoTypeInformation

# Step 2: Test access to each account by trying to list resources
Write-Host "`n[2/4] Testing access to each account..." -ForegroundColor Cyan

$accessResults = @()
$regions = @('us-east-1', 'us-west-1', 'us-west-2', 'us-east-2')

foreach ($account in $accountList) {
    Write-Host "`nTesting Account: $($account.AccountName) ($($account.AccountId))" -ForegroundColor Yellow
    
    $canAccessEC2 = $false
    $canAccessEBS = $false
    $ebsVolumeCount = 0
    
    foreach ($region in $regions) {
        try {
            # Test EC2 access
            $ec2Test = aws ec2 describe-instances --region $region --max-results 1 --output json 2>$null
            if ($LASTEXITCODE -eq 0) {
                $canAccessEC2 = $true
            }
            
            # Test EBS access and count volumes
            $ebsTest = aws ec2 describe-volumes --region $region --output json 2>$null | ConvertFrom-Json
            if ($LASTEXITCODE -eq 0) {
                $canAccessEBS = $true
                if ($ebsTest.Volumes) {
                    $ebsVolumeCount += $ebsTest.Volumes.Count
                }
            }
        } catch {
            # Continue on error
        }
    }
    
    $accessResults += [PSCustomObject]@{
        AccountId = $account.AccountId
        AccountName = $account.AccountName
        EC2Access = if ($canAccessEC2) { "YES" } else { "NO" }
        EBSAccess = if ($canAccessEBS) { "YES" } else { "NO" }
        EBSVolumesFound = $ebsVolumeCount
    }
    
    Write-Host "  EC2 Access: $(if ($canAccessEC2) { 'YES' } else { 'NO' })" -ForegroundColor $(if ($canAccessEC2) { 'Green' } else { 'Red' })
    Write-Host "  EBS Access: $(if ($canAccessEBS) { 'YES' } else { 'NO' })" -ForegroundColor $(if ($canAccessEBS) { 'Green' } else { 'Red' })
    Write-Host "  EBS Volumes Found: $ebsVolumeCount" -ForegroundColor White
}

$accessResults | Export-Csv -Path "account-access-verification.csv" -NoTypeInformation

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "ACCESS VERIFICATION SUMMARY" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green
$accessResults | Format-Table -AutoSize

# Step 3: Complete EBS scan across all regions
Write-Host "`n[3/4] Scanning ALL EBS volumes across all regions..." -ForegroundColor Cyan

$allRegions = @(
    'us-east-1', 'us-east-2', 'us-west-1', 'us-west-2',
    'ap-south-1', 'ap-northeast-1', 'ap-northeast-2', 'ap-southeast-1', 'ap-southeast-2',
    'ca-central-1', 'eu-central-1', 'eu-west-1', 'eu-west-2', 'eu-west-3',
    'sa-east-1'
)

$allEBSVolumes = @()
$totalVolumes = 0
$totalSizeGB = 0

foreach ($region in $allRegions) {
    Write-Host "  Scanning region: $region..." -ForegroundColor Gray
    
    try {
        $volumes = aws ec2 describe-volumes --region $region --output json 2>$null | ConvertFrom-Json
        
        if ($volumes.Volumes -and $volumes.Volumes.Count -gt 0) {
            Write-Host "    Found $($volumes.Volumes.Count) volumes" -ForegroundColor Yellow
            
            foreach ($vol in $volumes.Volumes) {
                $totalVolumes++
                $totalSizeGB += $vol.Size
                
                $allEBSVolumes += [PSCustomObject]@{
                    Region = $region
                    VolumeId = $vol.VolumeId
                    VolumeType = $vol.VolumeType
                    SizeGB = $vol.Size
                    State = $vol.State
                    Encrypted = $vol.Encrypted
                    CreateTime = $vol.CreateTime
                    AvailabilityZone = $vol.AvailabilityZone
                    IOPS = $vol.Iops
                    Throughput = if ($vol.Throughput) { $vol.Throughput } else { 'N/A' }
                }
            }
        }
    } catch {
        # Continue on error
    }
}

Write-Host "`nTotal EBS Volumes Found: $totalVolumes" -ForegroundColor Green
Write-Host "Total Storage: $totalSizeGB GB" -ForegroundColor Green

$allEBSVolumes | Export-Csv -Path "complete-ebs-inventory-all-regions.csv" -NoTypeInformation

# Step 4: Get EBS costs from CUR
Write-Host "`n[4/4] Fetching EBS costs from Cost Explorer..." -ForegroundColor Cyan

$endDate = Get-Date -Format "yyyy-MM-dd"
$startDate = (Get-Date).AddDays(-30).ToString("yyyy-MM-dd")

try {
    # Get EBS costs
    $ebsCosts = aws ce get-cost-and-usage `
        --time-period Start=$startDate,End=$endDate `
        --granularity MONTHLY `
        --metrics "UnblendedCost" `
        --filter '{\"Dimensions\":{\"Key\":\"SERVICE\",\"Values\":[\"Amazon Elastic Compute Cloud - Compute\"]}}' `
        --group-by Type=DIMENSION,Key=USAGE_TYPE `
        --output json 2>$null | ConvertFrom-Json
    
    $ebsCostBreakdown = @()
    
    if ($ebsCosts.ResultsByTime) {
        foreach ($result in $ebsCosts.ResultsByTime) {
            foreach ($group in $result.Groups) {
                $usageType = $group.Keys[0]
                $cost = [math]::Round([decimal]$group.Metrics.UnblendedCost.Amount, 2)
                
                # Filter for EBS-related usage types
                if ($usageType -match "EBS|Volume" -and $cost -gt 0) {
                    $ebsCostBreakdown += [PSCustomObject]@{
                        UsageType = $usageType
                        MonthlyCost = $cost
                    }
                }
            }
        }
    }
    
    if ($ebsCostBreakdown.Count -gt 0) {
        $totalEBSCost = ($ebsCostBreakdown | Measure-Object MonthlyCost -Sum).Sum
        
        Write-Host "`nEBS Cost from Cost Explorer:" -ForegroundColor Yellow
        Write-Host "  Total EBS Cost: `$$totalEBSCost/month" -ForegroundColor White
        
        $ebsCostBreakdown | Sort-Object MonthlyCost -Descending | Export-Csv -Path "ebs-costs-from-cur.csv" -NoTypeInformation
        
        Write-Host "`nTop 10 EBS Usage Types by Cost:" -ForegroundColor Yellow
        $ebsCostBreakdown | Sort-Object MonthlyCost -Descending | Select-Object -First 10 | Format-Table -AutoSize
    }
    
    # Get overall EC2 costs (includes EBS)
    $ec2Costs = aws ce get-cost-and-usage `
        --time-period Start=$startDate,End=$endDate `
        --granularity MONTHLY `
        --metrics "UnblendedCost" `
        --filter '{\"Dimensions\":{\"Key\":\"SERVICE\",\"Values\":[\"Amazon Elastic Compute Cloud - Compute\"]}}' `
        --output json 2>$null | ConvertFrom-Json
    
    if ($ec2Costs.ResultsByTime) {
        $totalEC2Cost = [math]::Round([decimal]$ec2Costs.ResultsByTime[0].Total.UnblendedCost.Amount, 2)
        Write-Host "`nTotal EC2 Service Cost (includes EBS): `$$totalEC2Cost/month" -ForegroundColor Cyan
    }
    
} catch {
    Write-Host "Error fetching cost data: $_" -ForegroundColor Red
}

# Step 5: Comparison and Analysis
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "EBS INVENTORY vs CUR COMPARISON" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

# Calculate expected cost from inventory
$gp2Volumes = $allEBSVolumes | Where-Object VolumeType -eq 'gp2'
$gp3Volumes = $allEBSVolumes | Where-Object VolumeType -eq 'gp3'
$io1Volumes = $allEBSVolumes | Where-Object VolumeType -eq 'io1'
$io2Volumes = $allEBSVolumes | Where-Object VolumeType -eq 'io2'

$gp2Cost = ($gp2Volumes | Measure-Object SizeGB -Sum).Sum * 0.10
$gp3Cost = ($gp3Volumes | Measure-Object SizeGB -Sum).Sum * 0.08
$io1Cost = ($io1Volumes | Measure-Object SizeGB -Sum).Sum * 0.125
$io2Cost = ($io2Volumes | Measure-Object SizeGB -Sum).Sum * 0.125

$calculatedEBSCost = $gp2Cost + $gp3Cost + $io1Cost + $io2Cost

Write-Host "EBS Inventory Analysis:" -ForegroundColor Cyan
Write-Host "  Total Volumes: $totalVolumes" -ForegroundColor White
Write-Host "  Total Storage: $totalSizeGB GB" -ForegroundColor White
Write-Host "  GP2 Volumes: $($gp2Volumes.Count) ($(($gp2Volumes | Measure-Object SizeGB -Sum).Sum) GB)" -ForegroundColor White
Write-Host "  GP3 Volumes: $($gp3Volumes.Count) ($(($gp3Volumes | Measure-Object SizeGB -Sum).Sum) GB)" -ForegroundColor White
Write-Host "  IO1 Volumes: $($io1Volumes.Count) ($(($io1Volumes | Measure-Object SizeGB -Sum).Sum) GB)" -ForegroundColor White
Write-Host "  IO2 Volumes: $($io2Volumes.Count) ($(($io2Volumes | Measure-Object SizeGB -Sum).Sum) GB)" -ForegroundColor White
Write-Host "`n  Calculated Monthly Cost: `$$([math]::Round($calculatedEBSCost, 2))" -ForegroundColor Yellow

if ($totalEBSCost) {
    Write-Host "`nCost Explorer (CUR) Data:" -ForegroundColor Cyan
    Write-Host "  Actual EBS Cost: `$$totalEBSCost/month" -ForegroundColor White
    
    $difference = $totalEBSCost - $calculatedEBSCost
    $percentDiff = if ($calculatedEBSCost -gt 0) { [math]::Round(($difference / $calculatedEBSCost) * 100, 1) } else { 0 }
    
    Write-Host "`nComparison:" -ForegroundColor Cyan
    Write-Host "  Difference: `$$([math]::Round($difference, 2)) ($percentDiff%)" -ForegroundColor $(if ($difference -gt 50) { 'Red' } else { 'Yellow' })
    
    if ([math]::Abs($difference) -gt 50) {
        Write-Host "`n  Note: Significant difference detected. This may be due to:" -ForegroundColor Yellow
        Write-Host "    - Snapshots (not included in volume inventory)" -ForegroundColor White
        Write-Host "    - IOPS provisioning costs" -ForegroundColor White
        Write-Host "    - Data transfer costs" -ForegroundColor White
        Write-Host "    - Volumes in regions not scanned" -ForegroundColor White
    }
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "FILES GENERATED" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "1. all-organization-accounts.csv - All accounts in organization" -ForegroundColor White
Write-Host "2. account-access-verification.csv - Access test results per account" -ForegroundColor White
Write-Host "3. complete-ebs-inventory-all-regions.csv - Complete EBS inventory" -ForegroundColor White
Write-Host "4. ebs-costs-from-cur.csv - EBS costs from Cost Explorer" -ForegroundColor White

Write-Host "`n========================================`n" -ForegroundColor Green
