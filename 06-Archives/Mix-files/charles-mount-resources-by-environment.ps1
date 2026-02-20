# Charles Mount Account - Resources Grouped by Environment
# Analyzes EC2, RDS, and EBS volumes by environment and application

Write-Host "========================================" -ForegroundColor Green
Write-Host "CHARLES MOUNT RESOURCES BY ENVIRONMENT" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

# Import existing data
$ec2Instances = Import-Csv "charles-mount-ec2-instances.csv"
$rdsInstances = Import-Csv "charles-mount-rds-instances.csv"
$ebsVolumes = Import-Csv "charles-mount-ebs-volumes.csv"

# Function to determine environment from name
function Get-Environment {
    param($name)
    
    if ($name -match "prod|production") { return "Production" }
    elseif ($name -match "stag|staging") { return "Staging" }
    elseif ($name -match "dev|development") { return "Development" }
    elseif ($name -match "test|qa") { return "Test/QA" }
    else { return "Unknown/Other" }
}

# Function to determine application from name
function Get-Application {
    param($name)
    
    if ($name -match "doppio") { return "Doppio" }
    elseif ($name -match "macchiato") { return "Macchiato" }
    elseif ($name -match "mfa") { return "MFA" }
    elseif ($name -match "onehub|search") { return "Onehub Search" }
    elseif ($name -match "replica") { return "Database Replica" }
    else { return "General/Unknown" }
}

# Categorize resources
$categorizedResources = @{
    Production = @{
        EC2 = @()
        RDS = @()
        EBS = @()
    }
    Staging = @{
        EC2 = @()
        RDS = @()
        EBS = @()
    }
    Development = @{
        EC2 = @()
        RDS = @()
        EBS = @()
    }
    TestQA = @{
        EC2 = @()
        RDS = @()
        EBS = @()
    }
    Unknown = @{
        EC2 = @()
        RDS = @()
        EBS = @()
    }
}

# Categorize RDS instances
foreach ($rds in $rdsInstances) {
    $env = Get-Environment $rds.DBInstanceId
    $app = Get-Application $rds.DBInstanceId
    
    $resource = [PSCustomObject]@{
        Name = $rds.DBInstanceId
        Type = "RDS"
        InstanceClass = $rds.DBInstanceClass
        Engine = $rds.Engine
        Status = $rds.Status
        Storage = "$($rds.AllocatedStorage) GB"
        MultiAZ = $rds.MultiAZ
        Region = $rds.Region
        Application = $app
        Environment = $env
    }
    
    switch ($env) {
        "Production" { $categorizedResources.Production.RDS += $resource }
        "Staging" { $categorizedResources.Staging.RDS += $resource }
        "Development" { $categorizedResources.Development.RDS += $resource }
        "Test/QA" { $categorizedResources.TestQA.RDS += $resource }
        default { $categorizedResources.Unknown.RDS += $resource }
    }
}

# Categorize EC2 instances (by tags or naming if available)
foreach ($ec2 in $ec2Instances) {
    # Try to determine environment from private IP pattern or other indicators
    $env = "Unknown/Other"
    $app = "General/Unknown"
    
    # Infer from IP ranges (common pattern)
    if ($ec2.PrivateIP -match "^10\.0\.") { $env = "Production" }
    elseif ($ec2.PrivateIP -match "^10\.1\.") { $env = "Production" }
    elseif ($ec2.PrivateIP -match "^10\.2\.") { $env = "Staging" }
    elseif ($ec2.PrivateIP -match "^10\.120\.") { $env = "Staging" }
    elseif ($ec2.PrivateIP -match "^10\.121\.") { $env = "Development" }
    elseif ($ec2.PrivateIP -match "^192\.168\.") { $env = "Test/QA" }
    
    $resource = [PSCustomObject]@{
        InstanceId = $ec2.InstanceId
        Type = "EC2"
        InstanceType = $ec2.InstanceType
        State = $ec2.State
        Platform = $ec2.Platform
        PrivateIP = $ec2.PrivateIP
        PublicIP = $ec2.PublicIP
        Region = $ec2.Region
        LaunchTime = $ec2.LaunchTime
        Application = $app
        Environment = $env
    }
    
    switch ($env) {
        "Production" { $categorizedResources.Production.EC2 += $resource }
        "Staging" { $categorizedResources.Staging.EC2 += $resource }
        "Development" { $categorizedResources.Development.EC2 += $resource }
        "Test/QA" { $categorizedResources.TestQA.EC2 += $resource }
        default { $categorizedResources.Unknown.EC2 += $resource }
    }
}

# Categorize EBS volumes by attachment
foreach ($ebs in $ebsVolumes) {
    $env = "Unknown/Other"
    $attachedInstance = $ec2Instances | Where-Object InstanceId -eq $ebs.AttachedTo | Select-Object -First 1
    
    if ($attachedInstance) {
        if ($attachedInstance.PrivateIP -match "^10\.0\.|^10\.1\.") { $env = "Production" }
        elseif ($attachedInstance.PrivateIP -match "^10\.2\.|^10\.120\.") { $env = "Staging" }
        elseif ($attachedInstance.PrivateIP -match "^10\.121\.") { $env = "Development" }
        elseif ($attachedInstance.PrivateIP -match "^192\.168\.") { $env = "Test/QA" }
    }
    
    $resource = [PSCustomObject]@{
        VolumeId = $ebs.VolumeId
        Type = "EBS"
        VolumeType = $ebs.VolumeType
        SizeGB = $ebs.SizeGB
        State = $ebs.State
        Encrypted = $ebs.Encrypted
        AttachedTo = $ebs.AttachedTo
        Region = $ebs.Region
        Environment = $env
    }
    
    switch ($env) {
        "Production" { $categorizedResources.Production.EBS += $resource }
        "Staging" { $categorizedResources.Staging.EBS += $resource }
        "Development" { $categorizedResources.Development.EBS += $resource }
        "Test/QA" { $categorizedResources.TestQA.EBS += $resource }
        default { $categorizedResources.Unknown.EBS += $resource }
    }
}

# Display results
Write-Host "========================================" -ForegroundColor Green
Write-Host "PRODUCTION ENVIRONMENT" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "RDS Databases ($($categorizedResources.Production.RDS.Count)):" -ForegroundColor Cyan
$categorizedResources.Production.RDS | Format-Table Name, InstanceClass, Engine, Status, Storage, Application -AutoSize

Write-Host "`nEC2 Instances ($($categorizedResources.Production.EC2.Count)):" -ForegroundColor Cyan
$categorizedResources.Production.EC2 | Format-Table InstanceId, InstanceType, State, Platform, PrivateIP -AutoSize

Write-Host "`nEBS Volumes ($($categorizedResources.Production.EBS.Count)):" -ForegroundColor Cyan
Write-Host "  Total Size: $(($categorizedResources.Production.EBS | Measure-Object SizeGB -Sum).Sum) GB" -ForegroundColor White
Write-Host "  Attached: $(($categorizedResources.Production.EBS | Where-Object State -eq 'in-use').Count)" -ForegroundColor White
Write-Host "  Unattached: $(($categorizedResources.Production.EBS | Where-Object State -eq 'available').Count)" -ForegroundColor White

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "STAGING ENVIRONMENT" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "RDS Databases ($($categorizedResources.Staging.RDS.Count)):" -ForegroundColor Cyan
$categorizedResources.Staging.RDS | Format-Table Name, InstanceClass, Engine, Status, Storage, Application -AutoSize

Write-Host "`nEC2 Instances ($($categorizedResources.Staging.EC2.Count)):" -ForegroundColor Cyan
$categorizedResources.Staging.EC2 | Format-Table InstanceId, InstanceType, State, Platform, PrivateIP -AutoSize

Write-Host "`nEBS Volumes ($($categorizedResources.Staging.EBS.Count)):" -ForegroundColor Cyan
Write-Host "  Total Size: $(($categorizedResources.Staging.EBS | Measure-Object SizeGB -Sum).Sum) GB" -ForegroundColor White
Write-Host "  Attached: $(($categorizedResources.Staging.EBS | Where-Object State -eq 'in-use').Count)" -ForegroundColor White
Write-Host "  Unattached: $(($categorizedResources.Staging.EBS | Where-Object State -eq 'available').Count)" -ForegroundColor White

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "DEVELOPMENT ENVIRONMENT" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "RDS Databases ($($categorizedResources.Development.RDS.Count)):" -ForegroundColor Cyan
if ($categorizedResources.Development.RDS.Count -gt 0) {
    $categorizedResources.Development.RDS | Format-Table Name, InstanceClass, Engine, Status, Storage, Application -AutoSize
} else {
    Write-Host "  None found" -ForegroundColor Gray
}

Write-Host "`nEC2 Instances ($($categorizedResources.Development.EC2.Count)):" -ForegroundColor Cyan
if ($categorizedResources.Development.EC2.Count -gt 0) {
    $categorizedResources.Development.EC2 | Format-Table InstanceId, InstanceType, State, Platform, PrivateIP -AutoSize
} else {
    Write-Host "  None found" -ForegroundColor Gray
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "TEST/QA ENVIRONMENT" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "RDS Databases ($($categorizedResources.TestQA.RDS.Count)):" -ForegroundColor Cyan
if ($categorizedResources.TestQA.RDS.Count -gt 0) {
    $categorizedResources.TestQA.RDS | Format-Table Name, InstanceClass, Engine, Status, Storage, Application -AutoSize
} else {
    Write-Host "  None found" -ForegroundColor Gray
}

Write-Host "`nEC2 Instances ($($categorizedResources.TestQA.EC2.Count)):" -ForegroundColor Cyan
if ($categorizedResources.TestQA.EC2.Count -gt 0) {
    $categorizedResources.TestQA.EC2 | Format-Table InstanceId, InstanceType, State, Platform, PrivateIP -AutoSize
} else {
    Write-Host "  None found" -ForegroundColor Gray
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "UNKNOWN/OTHER ENVIRONMENT" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "EC2 Instances ($($categorizedResources.Unknown.EC2.Count)):" -ForegroundColor Cyan
if ($categorizedResources.Unknown.EC2.Count -gt 0) {
    $categorizedResources.Unknown.EC2 | Select-Object -First 10 | Format-Table InstanceId, InstanceType, State, Platform, PrivateIP -AutoSize
    if ($categorizedResources.Unknown.EC2.Count -gt 10) {
        Write-Host "  ... and $($categorizedResources.Unknown.EC2.Count - 10) more" -ForegroundColor Gray
    }
}

# Export detailed reports
$categorizedResources.Production.RDS | Export-Csv -Path "production-rds.csv" -NoTypeInformation
$categorizedResources.Production.EC2 | Export-Csv -Path "production-ec2.csv" -NoTypeInformation
$categorizedResources.Production.EBS | Export-Csv -Path "production-ebs.csv" -NoTypeInformation

$categorizedResources.Staging.RDS | Export-Csv -Path "staging-rds.csv" -NoTypeInformation
$categorizedResources.Staging.EC2 | Export-Csv -Path "staging-ec2.csv" -NoTypeInformation
$categorizedResources.Staging.EBS | Export-Csv -Path "staging-ebs.csv" -NoTypeInformation

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "SUMMARY BY ENVIRONMENT" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

$summary = @(
    [PSCustomObject]@{
        Environment = "Production"
        EC2 = $categorizedResources.Production.EC2.Count
        RDS = $categorizedResources.Production.RDS.Count
        EBS = $categorizedResources.Production.EBS.Count
        "EBS Size (GB)" = ($categorizedResources.Production.EBS | Measure-Object SizeGB -Sum).Sum
    }
    [PSCustomObject]@{
        Environment = "Staging"
        EC2 = $categorizedResources.Staging.EC2.Count
        RDS = $categorizedResources.Staging.RDS.Count
        EBS = $categorizedResources.Staging.EBS.Count
        "EBS Size (GB)" = ($categorizedResources.Staging.EBS | Measure-Object SizeGB -Sum).Sum
    }
    [PSCustomObject]@{
        Environment = "Development"
        EC2 = $categorizedResources.Development.EC2.Count
        RDS = $categorizedResources.Development.RDS.Count
        EBS = $categorizedResources.Development.EBS.Count
        "EBS Size (GB)" = ($categorizedResources.Development.EBS | Measure-Object SizeGB -Sum).Sum
    }
    [PSCustomObject]@{
        Environment = "Test/QA"
        EC2 = $categorizedResources.TestQA.EC2.Count
        RDS = $categorizedResources.TestQA.RDS.Count
        EBS = $categorizedResources.TestQA.EBS.Count
        "EBS Size (GB)" = ($categorizedResources.TestQA.EBS | Measure-Object SizeGB -Sum).Sum
    }
    [PSCustomObject]@{
        Environment = "Unknown/Other"
        EC2 = $categorizedResources.Unknown.EC2.Count
        RDS = $categorizedResources.Unknown.RDS.Count
        EBS = $categorizedResources.Unknown.EBS.Count
        "EBS Size (GB)" = ($categorizedResources.Unknown.EBS | Measure-Object SizeGB -Sum).Sum
    }
)

$summary | Format-Table -AutoSize

Write-Host "`nFiles Generated:" -ForegroundColor Cyan
Write-Host "  1. production-rds.csv" -ForegroundColor White
Write-Host "  2. production-ec2.csv" -ForegroundColor White
Write-Host "  3. production-ebs.csv" -ForegroundColor White
Write-Host "  4. staging-rds.csv" -ForegroundColor White
Write-Host "  5. staging-ec2.csv" -ForegroundColor White
Write-Host "  6. staging-ebs.csv" -ForegroundColor White

Write-Host "`n========================================`n" -ForegroundColor Green
