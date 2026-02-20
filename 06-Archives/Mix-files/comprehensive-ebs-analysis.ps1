# Comprehensive EBS Volume Analysis
# Analyzes all EBS volumes with detailed information

Write-Host "========================================" -ForegroundColor Green
Write-Host "COMPREHENSIVE EBS VOLUME ANALYSIS" -ForegroundColor Green
Write-Host "Charles Mount Account (198161015548)" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

$allRegions = @('us-east-1', 'us-east-2', 'us-west-1', 'us-west-2')
$allVolumes = @()
$allSnapshots = @()

# Step 1: Collect all EBS volumes with detailed information
Write-Host "[1/4] Collecting EBS volume information..." -ForegroundColor Cyan

foreach ($region in $allRegions) {
    Write-Host "  Scanning region: $region..." -ForegroundColor Gray
    
    try {
        $volumes = aws ec2 describe-volumes --region $region --output json 2>$null | ConvertFrom-Json
        
        if ($volumes.Volumes) {
            foreach ($vol in $volumes.Volumes) {
                # Determine attachment status
                $attachedTo = "Unattached"
                $attachmentState = "available"
                $attachmentTime = $null
                $deleteOnTermination = $false
                
                if ($vol.Attachments -and $vol.Attachments.Count -gt 0) {
                    $attachedTo = $vol.Attachments[0].InstanceId
                    $attachmentState = $vol.Attachments[0].State
                    $attachmentTime = $vol.Attachments[0].AttachTime
                    $deleteOnTermination = $vol.Attachments[0].DeleteOnTermination
                }
                
                # Calculate age
                $createDate = [DateTime]::Parse($vol.CreateTime)
                $ageInDays = ([DateTime]::Now - $createDate).Days
                
                # Determine environment from attached instance
                $environment = "Unknown"
                if ($attachedTo -ne "Unattached") {
                    # We'll match this later with EC2 data
                    $environment = "To Be Determined"
                }
                
                $allVolumes += [PSCustomObject]@{
                    Region = $region
                    VolumeId = $vol.VolumeId
                    VolumeType = $vol.VolumeType
                    SizeGB = $vol.Size
                    State = $vol.State
                    IOPS = $vol.Iops
                    Throughput = if ($vol.Throughput) { $vol.Throughput } else { 0 }
                    Encrypted = $vol.Encrypted
                    SnapshotId = if ($vol.SnapshotId) { $vol.SnapshotId } else { "None" }
                    CreateTime = $vol.CreateTime
                    AgeInDays = $ageInDays
                    AttachedTo = $attachedTo
                    AttachmentState = $attachmentState
                    AttachmentTime = $attachmentTime
                    DeleteOnTermination = $deleteOnTermination
                    AvailabilityZone = $vol.AvailabilityZone
                    Environment = $environment
                }
            }
        }
    } catch {
        Write-Host "  Error in $region : $_" -ForegroundColor Red
    }
}

Write-Host "  Total volumes found: $($allVolumes.Count)" -ForegroundColor Yellow

# Step 2: Get EC2 instance information to determine environment
Write-Host "`n[2/4] Matching volumes to instances and environments..." -ForegroundColor Cyan

$ec2Instances = Import-Csv "charles-mount-ec2-instances.csv"

foreach ($volume in $allVolumes) {
    if ($volume.AttachedTo -ne "Unattached") {
        $instance = $ec2Instances | Where-Object InstanceId -eq $volume.AttachedTo | Select-Object -First 1
        
        if ($instance) {
            # Determine environment from IP range
            if ($instance.PrivateIP -match "^10\.0\.|^10\.1\.") {
                $volume.Environment = "Production"
            }
            elseif ($instance.PrivateIP -match "^10\.2\.|^10\.120\.") {
                $volume.Environment = "Staging"
            }
            elseif ($instance.PrivateIP -match "^10\.121\.") {
                $volume.Environment = "Development"
            }
            elseif ($instance.PrivateIP -match "^192\.168\.") {
                $volume.Environment = "Test/QA"
            }
            else {
                $volume.Environment = "Unknown"
            }
        }
    }
    else {
        $volume.Environment = "Unattached"
    }
}

# Step 3: Get snapshot information
Write-Host "`n[3/4] Collecting snapshot information..." -ForegroundColor Cyan

foreach ($region in $allRegions) {
    Write-Host "  Scanning snapshots in: $region..." -ForegroundColor Gray
    
    try {
        $snapshots = aws ec2 describe-snapshots --owner-ids self --region $region --output json 2>$null | ConvertFrom-Json
        
        if ($snapshots.Snapshots) {
            foreach ($snap in $snapshots.Snapshots) {
                $allSnapshots += [PSCustomObject]@{
                    Region = $region
                    SnapshotId = $snap.SnapshotId
                    VolumeId = $snap.VolumeId
                    VolumeSize = $snap.VolumeSize
                    StartTime = $snap.StartTime
                    State = $snap.State
                    Progress = $snap.Progress
                    Description = $snap.Description
                }
            }
        }
    } catch {
        Write-Host "  Error in $region : $_" -ForegroundColor Red
    }
}

Write-Host "  Total snapshots found: $($allSnapshots.Count)" -ForegroundColor Yellow

# Step 4: Check for lifecycle policies
Write-Host "`n[4/4] Checking for snapshot lifecycle policies..." -ForegroundColor Cyan

$lifecyclePolicies = @()
foreach ($region in $allRegions) {
    try {
        $policies = aws dlm get-lifecycle-policies --region $region --output json 2>$null | ConvertFrom-Json
        
        if ($policies.Policies) {
            foreach ($policy in $policies.Policies) {
                $policyDetail = aws dlm get-lifecycle-policy --policy-id $policy.PolicyId --region $region --output json 2>$null | ConvertFrom-Json
                
                $lifecyclePolicies += [PSCustomObject]@{
                    Region = $region
                    PolicyId = $policy.PolicyId
                    Description = $policy.Description
                    State = $policy.State
                    PolicyType = $policyDetail.Policy.PolicyDetails.PolicyType
                }
            }
        }
    } catch {
        # No policies or error
    }
}

Write-Host "  Lifecycle policies found: $($lifecyclePolicies.Count)" -ForegroundColor Yellow

# Analysis and Reporting
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "ANALYSIS RESULTS" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

# Overall Statistics
Write-Host "OVERALL STATISTICS:" -ForegroundColor Cyan
Write-Host "  Total EBS Volumes: $($allVolumes.Count)" -ForegroundColor White
Write-Host "  Total Storage: $(($allVolumes | Measure-Object SizeGB -Sum).Sum) GB" -ForegroundColor White
Write-Host "  Total Snapshots: $($allSnapshots.Count)" -ForegroundColor White
Write-Host "  Lifecycle Policies: $($lifecyclePolicies.Count)" -ForegroundColor White

# Volume Type Breakdown
Write-Host "`nVOLUME TYPE BREAKDOWN:" -ForegroundColor Cyan
$volumeTypes = $allVolumes | Group-Object VolumeType
foreach ($type in $volumeTypes) {
    $totalSize = ($type.Group | Measure-Object SizeGB -Sum).Sum
    $monthlyCost = switch ($type.Name) {
        "gp2" { $totalSize * 0.10 }
        "gp3" { $totalSize * 0.08 }
        "io1" { $totalSize * 0.125 }
        "io2" { $totalSize * 0.125 }
        default { $totalSize * 0.10 }
    }
    Write-Host "  $($type.Name): $($type.Count) volumes, $totalSize GB, ~`$$([math]::Round($monthlyCost, 2))/month" -ForegroundColor White
}

# Attachment Status
Write-Host "`nATTACHMENT STATUS:" -ForegroundColor Cyan
$attached = ($allVolumes | Where-Object State -eq "in-use").Count
$unattached = ($allVolumes | Where-Object State -eq "available").Count
Write-Host "  Attached: $attached volumes" -ForegroundColor Green
Write-Host "  Unattached: $unattached volumes" -ForegroundColor Red

# Encryption Status
Write-Host "`nENCRYPTION STATUS:" -ForegroundColor Cyan
$encrypted = ($allVolumes | Where-Object Encrypted -eq $true).Count
$unencrypted = ($allVolumes | Where-Object Encrypted -eq $false).Count
Write-Host "  Encrypted: $encrypted volumes" -ForegroundColor Green
Write-Host "  Unencrypted: $unencrypted volumes" -ForegroundColor Red

# Environment Breakdown
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "BREAKDOWN BY ENVIRONMENT" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

$environments = $allVolumes | Group-Object Environment | Sort-Object Name

foreach ($env in $environments) {
    Write-Host "$($env.Name) Environment:" -ForegroundColor Cyan
    Write-Host "  Total Volumes: $($env.Count)" -ForegroundColor White
    Write-Host "  Total Size: $(($env.Group | Measure-Object SizeGB -Sum).Sum) GB" -ForegroundColor White
    
    $gp2Count = ($env.Group | Where-Object VolumeType -eq "gp2").Count
    $gp3Count = ($env.Group | Where-Object VolumeType -eq "gp3").Count
    Write-Host "  GP2: $gp2Count volumes" -ForegroundColor White
    Write-Host "  GP3: $gp3Count volumes" -ForegroundColor White
    
    $attachedCount = ($env.Group | Where-Object State -eq "in-use").Count
    $unattachedCount = ($env.Group | Where-Object State -eq "available").Count
    Write-Host "  Attached: $attachedCount" -ForegroundColor White
    Write-Host "  Unattached: $unattachedCount" -ForegroundColor White
    Write-Host ""
}

# Unattached Volumes Detail
Write-Host "========================================" -ForegroundColor Green
Write-Host "UNATTACHED VOLUMES DETAIL" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

$unattachedVolumes = $allVolumes | Where-Object State -eq "available" | Sort-Object AgeInDays -Descending

if ($unattachedVolumes.Count -gt 0) {
    Write-Host "Found $($unattachedVolumes.Count) unattached volumes:`n" -ForegroundColor Yellow
    
    $unattachedVolumes | Format-Table VolumeId, VolumeType, SizeGB, Region, AgeInDays, CreateTime -AutoSize
    
    $totalUnattachedSize = ($unattachedVolumes | Measure-Object SizeGB -Sum).Sum
    $totalUnattachedCost = $totalUnattachedSize * 0.10
    
    Write-Host "Total unattached storage: $totalUnattachedSize GB" -ForegroundColor Yellow
    Write-Host "Wasted cost: ~`$$([math]::Round($totalUnattachedCost, 2))/month" -ForegroundColor Red
} else {
    Write-Host "No unattached volumes found!" -ForegroundColor Green
}

# Snapshot Analysis
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "SNAPSHOT ANALYSIS" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "Total Snapshots: $($allSnapshots.Count)" -ForegroundColor Cyan
Write-Host "Total Snapshot Storage: $(($allSnapshots | Measure-Object VolumeSize -Sum).Sum) GB" -ForegroundColor Cyan
Write-Host "Estimated Snapshot Cost: ~`$$([math]::Round((($allSnapshots | Measure-Object VolumeSize -Sum).Sum) * 0.05, 2))/month" -ForegroundColor Cyan

# Snapshots by region
Write-Host "`nSnapshots by Region:" -ForegroundColor Yellow
$allSnapshots | Group-Object Region | ForEach-Object {
    Write-Host "  $($_.Name): $($_.Count) snapshots, $(($_.Group | Measure-Object VolumeSize -Sum).Sum) GB" -ForegroundColor White
}

# Volumes with snapshots
$volumesWithSnapshots = ($allVolumes | Where-Object SnapshotId -ne "None").Count
$volumesWithoutSnapshots = ($allVolumes | Where-Object SnapshotId -eq "None").Count

Write-Host "`nVolumes created from snapshots: $volumesWithSnapshots" -ForegroundColor White
Write-Host "Volumes without snapshot origin: $volumesWithoutSnapshots" -ForegroundColor White

# Lifecycle Policies
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "SNAPSHOT LIFECYCLE POLICIES" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

if ($lifecyclePolicies.Count -gt 0) {
    Write-Host "Found $($lifecyclePolicies.Count) lifecycle policies:" -ForegroundColor Green
    $lifecyclePolicies | Format-Table Region, PolicyId, Description, State, PolicyType -AutoSize
} else {
    Write-Host "⚠️  NO LIFECYCLE POLICIES FOUND!" -ForegroundColor Red
    Write-Host "   Recommendation: Implement lifecycle policies to automatically manage snapshots" -ForegroundColor Yellow
}

# Export detailed reports
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "EXPORTING DETAILED REPORTS" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

# Export all volumes
$allVolumes | Export-Csv -Path "ebs-volumes-complete-analysis.csv" -NoTypeInformation
Write-Host "✓ Exported: ebs-volumes-complete-analysis.csv" -ForegroundColor Green

# Export by environment
$allVolumes | Where-Object Environment -eq "Production" | Export-Csv -Path "ebs-production-volumes.csv" -NoTypeInformation
$allVolumes | Where-Object Environment -eq "Staging" | Export-Csv -Path "ebs-staging-volumes.csv" -NoTypeInformation
$allVolumes | Where-Object Environment -eq "Unattached" | Export-Csv -Path "ebs-unattached-volumes.csv" -NoTypeInformation

Write-Host "✓ Exported: ebs-production-volumes.csv" -ForegroundColor Green
Write-Host "✓ Exported: ebs-staging-volumes.csv" -ForegroundColor Green
Write-Host "✓ Exported: ebs-unattached-volumes.csv" -ForegroundColor Green

# Export snapshots
$allSnapshots | Export-Csv -Path "ebs-snapshots-complete.csv" -NoTypeInformation
Write-Host "✓ Exported: ebs-snapshots-complete.csv" -ForegroundColor Green

# Export GP2 volumes (migration candidates)
$allVolumes | Where-Object VolumeType -eq "gp2" | Export-Csv -Path "ebs-gp2-migration-candidates.csv" -NoTypeInformation
Write-Host "✓ Exported: ebs-gp2-migration-candidates.csv" -ForegroundColor Green

# Create summary report
$summaryReport = @"
# EBS Volume Analysis Summary
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Account: Charles Mount (198161015548)

## Overall Statistics
- Total Volumes: $($allVolumes.Count)
- Total Storage: $(($allVolumes | Measure-Object SizeGB -Sum).Sum) GB
- Total Snapshots: $($allSnapshots.Count)
- Lifecycle Policies: $($lifecyclePolicies.Count)

## Volume Types
$(foreach ($type in $volumeTypes) {
    $totalSize = ($type.Group | Measure-Object SizeGB -Sum).Sum
    "- $($type.Name): $($type.Count) volumes, $totalSize GB"
})

## Attachment Status
- Attached: $attached volumes
- Unattached: $unattached volumes

## Encryption Status
- Encrypted: $encrypted volumes
- Unencrypted: $unencrypted volumes

## Environment Breakdown
$(foreach ($env in $environments) {
    "### $($env.Name)
- Volumes: $($env.Count)
- Size: $(($env.Group | Measure-Object SizeGB -Sum).Sum) GB
- GP2: $(($env.Group | Where-Object VolumeType -eq 'gp2').Count)
- GP3: $(($env.Group | Where-Object VolumeType -eq 'gp3').Count)
"
})

## Cost Estimates
- Total EBS Cost: ~`$$([math]::Round((($allVolumes | Measure-Object SizeGB -Sum).Sum) * 0.10, 2))/month
- Snapshot Cost: ~`$$([math]::Round((($allSnapshots | Measure-Object VolumeSize -Sum).Sum) * 0.05, 2))/month
- Unattached Volume Waste: ~`$$([math]::Round($totalUnattachedCost, 2))/month

## Recommendations
1. Migrate all GP2 volumes to GP3 (save 20%)
2. Delete unattached volumes (save `$$([math]::Round($totalUnattachedCost, 2))/month)
3. Enable encryption on all volumes
4. Implement snapshot lifecycle policies
5. Review and delete old snapshots
"@

$summaryReport | Out-File -FilePath "ebs-analysis-summary.txt" -Encoding UTF8
Write-Host "✓ Exported: ebs-analysis-summary.txt" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "ANALYSIS COMPLETE!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green
