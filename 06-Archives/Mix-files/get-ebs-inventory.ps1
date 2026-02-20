# EBS Volume Inventory Script for All AWS Accounts
# Collects EBS volumes with type, size, and cost analysis

$accounts = @(
    @{Id='729265419250'; Name='SRSAWS'},
    @{Id='015815251546'; Name='Production Account'},
    @{Id='163799539090'; Name='Stage Account'},
    @{Id='508093650048'; Name='QA Account'},
    @{Id='013612877090'; Name='AWS Development'},
    @{Id='193650285903'; Name='Backup Account'},
    @{Id='010928212058'; Name='Log Archive'},
    @{Id='010928211854'; Name='Audit'},
    @{Id='010928226815'; Name='AFT-Management'},
    @{Id='450320546527'; Name='IT Solutions'},
    @{Id='946447852237'; Name='Cortado Production'},
    @{Id='145462881720'; Name='cortado-staging'},
    @{Id='317609321563'; Name='doppio-production'},
    @{Id='582520650702'; Name='formkiq_dev'},
    @{Id='223347559318'; Name='Development'},
    @{Id='145260055644'; Name='Onehub Development'},
    @{Id='198161015548'; Name='Charles Mount'},
    @{Id='872864771989'; Name='Brian Moran'}
)

$regions = @('us-east-1', 'us-west-2', 'us-east-2', 'us-west-1')
$results = @()

# Pricing per GB-month (us-west-1 approximate)
$pricing = @{
    'gp2' = 0.10
    'gp3' = 0.08
    'io1' = 0.125
    'io2' = 0.125
    'st1' = 0.045
    'sc1' = 0.025
    'standard' = 0.05
}

Write-Host "Starting EBS volume inventory collection across all accounts..." -ForegroundColor Green

foreach ($account in $accounts) {
    Write-Host "`nProcessing Account: $($account.Name) ($($account.Id))" -ForegroundColor Cyan
    
    foreach ($region in $regions) {
        try {
            $volumes = aws ec2 describe-volumes --region $region --query 'Volumes[].[VolumeId,VolumeType,Size,State,Iops,Throughput,Encrypted,SnapshotId,CreateTime,Attachments[0].InstanceId,Attachments[0].Device,Attachments[0].State,Tags[?Key==`Name`].Value|[0]]' --output json 2>$null | ConvertFrom-Json
            
            if ($volumes -and $volumes.Count -gt 0) {
                foreach ($volume in $volumes) {
                    $volumeType = $volume[1]
                    $sizeGB = $volume[2]
                    $pricePerGB = if ($pricing.ContainsKey($volumeType)) { $pricing[$volumeType] } else { 0.10 }
                    $monthlyCost = [math]::Round($sizeGB * $pricePerGB, 2)
                    
                    $results += [PSCustomObject]@{
                        AccountId = $account.Id
                        AccountName = $account.Name
                        Region = $region
                        VolumeId = $volume[0]
                        VolumeType = $volumeType
                        SizeGB = $sizeGB
                        State = $volume[3]
                        IOPS = $volume[4]
                        Throughput = if ($volume[5]) { $volume[5] } else { 'N/A' }
                        Encrypted = $volume[6]
                        SnapshotId = if ($volume[7]) { $volume[7] } else { 'N/A' }
                        CreateTime = $volume[8]
                        AttachedInstanceId = if ($volume[9]) { $volume[9] } else { 'Unattached' }
                        Device = if ($volume[10]) { $volume[10] } else { 'N/A' }
                        AttachmentState = if ($volume[11]) { $volume[11] } else { 'N/A' }
                        Name = if ($volume[12]) { $volume[12] } else { 'N/A' }
                        MonthlyCost = $monthlyCost
                    }
                }
                Write-Host "  Found $($volumes.Count) volumes in $region" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "  Error querying $region : $_" -ForegroundColor Red
        }
    }
}

Write-Host "`n`nTotal volumes found: $($results.Count)" -ForegroundColor Green

# Export all volumes
$results | Export-Csv -Path "ebs-volumes-all-accounts.csv" -NoTypeInformation

# Separate gp2 and gp3
$gp2Volumes = $results | Where-Object VolumeType -eq 'gp2'
$gp3Volumes = $results | Where-Object VolumeType -eq 'gp3'

$gp2Volumes | Export-Csv -Path "ebs-volumes-gp2.csv" -NoTypeInformation
$gp3Volumes | Export-Csv -Path "ebs-volumes-gp3.csv" -NoTypeInformation

# Create summary by type
$typeSummary = $results | Group-Object VolumeType | ForEach-Object {
    $typeVolumes = $_.Group
    [PSCustomObject]@{
        VolumeType = $_.Name
        TotalCount = $typeVolumes.Count
        TotalSizeGB = ($typeVolumes | Measure-Object SizeGB -Sum).Sum
        InUseCount = ($typeVolumes | Where-Object State -eq 'in-use').Count
        AvailableCount = ($typeVolumes | Where-Object State -eq 'available').Count
        EncryptedCount = ($typeVolumes | Where-Object Encrypted -eq $true).Count
        TotalMonthlyCost = [math]::Round(($typeVolumes | Measure-Object MonthlyCost -Sum).Sum, 2)
    }
}

$typeSummary | Export-Csv -Path "ebs-summary-by-type.csv" -NoTypeInformation

# Create summary by account
$accountSummary = $results | Group-Object AccountName | ForEach-Object {
    $accountVolumes = $_.Group
    [PSCustomObject]@{
        AccountName = $_.Name
        AccountId = $accountVolumes[0].AccountId
        TotalVolumes = $accountVolumes.Count
        TotalSizeGB = ($accountVolumes | Measure-Object SizeGB -Sum).Sum
        GP2Count = ($accountVolumes | Where-Object VolumeType -eq 'gp2').Count
        GP3Count = ($accountVolumes | Where-Object VolumeType -eq 'gp3').Count
        OtherCount = ($accountVolumes | Where-Object {$_.VolumeType -notin @('gp2','gp3')}).Count
        TotalMonthlyCost = [math]::Round(($accountVolumes | Measure-Object MonthlyCost -Sum).Sum, 2)
    }
}

$accountSummary | Export-Csv -Path "ebs-summary-by-account.csv" -NoTypeInformation

Write-Host "`n========== EBS VOLUME ANALYSIS SUMMARY ==========" -ForegroundColor Green
Write-Host "Total Volumes: $($results.Count)" -ForegroundColor Cyan
Write-Host "Total Storage: $(($results | Measure-Object SizeGB -Sum).Sum) GB" -ForegroundColor Cyan
Write-Host "`nVolume Type Breakdown:" -ForegroundColor Yellow
Write-Host "  GP2 Volumes: $($gp2Volumes.Count) ($(($gp2Volumes | Measure-Object SizeGB -Sum).Sum) GB)" -ForegroundColor White
Write-Host "  GP3 Volumes: $($gp3Volumes.Count) ($(($gp3Volumes | Measure-Object SizeGB -Sum).Sum) GB)" -ForegroundColor White
Write-Host "  Other Types: $(($results | Where-Object {$_.VolumeType -notin @('gp2','gp3')}).Count)" -ForegroundColor White
Write-Host "`nTotal Monthly Cost: `$$([math]::Round(($results | Measure-Object MonthlyCost -Sum).Sum, 2))" -ForegroundColor Green
Write-Host "  GP2 Cost: `$$([math]::Round(($gp2Volumes | Measure-Object MonthlyCost -Sum).Sum, 2))" -ForegroundColor White
Write-Host "  GP3 Cost: `$$([math]::Round(($gp3Volumes | Measure-Object MonthlyCost -Sum).Sum, 2))" -ForegroundColor White
Write-Host "`nPotential Savings (GP2 to GP3 migration): `$$([math]::Round((($gp2Volumes | Measure-Object SizeGB -Sum).Sum) * 0.02, 2))/month" -ForegroundColor Magenta
Write-Host "`nFiles Generated:" -ForegroundColor Cyan
Write-Host "  1. ebs-volumes-all-accounts.csv - All EBS volumes"
Write-Host "  2. ebs-volumes-gp2.csv - GP2 volumes only"
Write-Host "  3. ebs-volumes-gp3.csv - GP3 volumes only"
Write-Host "  4. ebs-summary-by-type.csv - Summary by volume type"
Write-Host "  5. ebs-summary-by-account.csv - Summary by account"
Write-Host "===============================================`n" -ForegroundColor Green
