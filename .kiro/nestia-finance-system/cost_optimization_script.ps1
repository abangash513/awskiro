# AWS Cost Optimization Script
# Run this script to implement immediate cost savings

Write-Host "🔍 AWS Cost Optimization Analysis Starting..." -ForegroundColor Green

# 1. Check for unused EBS volumes
Write-Host "`n📦 Checking for unused EBS volumes..." -ForegroundColor Yellow
$unusedVolumes = aws ec2 describe-volumes --filters "Name=status,Values=available" --query "Volumes[].{VolumeId:VolumeId,Size:Size,VolumeType:VolumeType}" --output json | ConvertFrom-Json

if ($unusedVolumes.Count -gt 0) {
    Write-Host "⚠️  Found $($unusedVolumes.Count) unused EBS volumes:" -ForegroundColor Red
    $unusedVolumes | ForEach-Object {
        $monthlyCost = switch ($_.VolumeType) {
            "gp3" { $_.Size * 0.08 }
            "gp2" { $_.Size * 0.10 }
            "io1" { $_.Size * 0.125 }
            default { $_.Size * 0.10 }
        }
        Write-Host "  - Volume: $($_.VolumeId), Size: $($_.Size)GB, Type: $($_.VolumeType), Monthly Cost: `$$([math]::Round($monthlyCost, 2))" -ForegroundColor White
    }
    
    $response = Read-Host "`nDo you want to delete these unused volumes? (y/N)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        $unusedVolumes | ForEach-Object {
            Write-Host "Deleting volume $($_.VolumeId)..." -ForegroundColor Green
            aws ec2 delete-volume --volume-id $_.VolumeId
        }
    }
} else {
    Write-Host "✅ No unused EBS volumes found" -ForegroundColor Green
}

# 2. Check for old snapshots (older than 90 days)
Write-Host "`n📸 Checking for old snapshots..." -ForegroundColor Yellow
$oldDate = (Get-Date).AddDays(-90).ToString("yyyy-MM-dd")
$oldSnapshots = aws ec2 describe-snapshots --owner-ids 750299845580 --query "Snapshots[?StartTime<='$oldDate'].{SnapshotId:SnapshotId,VolumeSize:VolumeSize,StartTime:StartTime}" --output json | ConvertFrom-Json

if ($oldSnapshots.Count -gt 0) {
    Write-Host "⚠️  Found $($oldSnapshots.Count) snapshots older than 90 days:" -ForegroundColor Red
    $totalSize = ($oldSnapshots | Measure-Object -Property VolumeSize -Sum).Sum
    $estimatedCost = $totalSize * 0.05  # $0.05 per GB per month
    Write-Host "  Total size: ${totalSize}GB, Estimated monthly cost: `$$([math]::Round($estimatedCost, 2))" -ForegroundColor White
    
    $response = Read-Host "`nDo you want to delete snapshots older than 90 days? (y/N)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        $oldSnapshots | ForEach-Object {
            Write-Host "Deleting snapshot $($_.SnapshotId) from $($_.StartTime)..." -ForegroundColor Green
            aws ec2 delete-snapshot --snapshot-id $_.SnapshotId
        }
    }
} else {
    Write-Host "✅ No old snapshots found" -ForegroundColor Green
}

# 3. Check for running SageMaker resources
Write-Host "`n🤖 Checking SageMaker resources..." -ForegroundColor Yellow

# Check notebook instances
$notebooks = aws sagemaker list-notebook-instances --status-equals InService --output json | ConvertFrom-Json
if ($notebooks.NotebookInstances.Count -gt 0) {
    Write-Host "⚠️  Found $($notebooks.NotebookInstances.Count) running SageMaker notebook instances:" -ForegroundColor Red
    $notebooks.NotebookInstances | ForEach-Object {
        Write-Host "  - $($_.NotebookInstanceName) ($($_.InstanceType))" -ForegroundColor White
    }
    
    $response = Read-Host "`nDo you want to stop these notebook instances? (y/N)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        $notebooks.NotebookInstances | ForEach-Object {
            Write-Host "Stopping notebook $($_.NotebookInstanceName)..." -ForegroundColor Green
            aws sagemaker stop-notebook-instance --notebook-instance-name $_.NotebookInstanceName
        }
    }
} else {
    Write-Host "✅ No running SageMaker notebook instances found" -ForegroundColor Green
}

# Check endpoints
$endpoints = aws sagemaker list-endpoints --status-equals InService --output json | ConvertFrom-Json
if ($endpoints.Endpoints.Count -gt 0) {
    Write-Host "⚠️  Found $($endpoints.Endpoints.Count) running SageMaker endpoints:" -ForegroundColor Red
    $endpoints.Endpoints | ForEach-Object {
        Write-Host "  - $($_.EndpointName)" -ForegroundColor White
    }
    
    $response = Read-Host "`nDo you want to delete these endpoints? (y/N)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        $endpoints.Endpoints | ForEach-Object {
            Write-Host "Deleting endpoint $($_.EndpointName)..." -ForegroundColor Green
            aws sagemaker delete-endpoint --endpoint-name $_.EndpointName
        }
    }
} else {
    Write-Host "✅ No running SageMaker endpoints found" -ForegroundColor Green
}

# 4. Check Lightsail instances
Write-Host "`n💡 Checking Lightsail instances..." -ForegroundColor Yellow
$lightsailInstances = aws lightsail get-instances --output json | ConvertFrom-Json
if ($lightsailInstances.instances.Count -gt 0) {
    Write-Host "⚠️  Found $($lightsailInstances.instances.Count) Lightsail instances:" -ForegroundColor Red
    $lightsailInstances.instances | ForEach-Object {
        $status = if ($_.state.name -eq "running") { "🟢 Running" } else { "🔴 Stopped" }
        Write-Host "  - $($_.name) ($($_.bundleId)) - $status" -ForegroundColor White
    }
    Write-Host "`nReview these instances manually to determine if they're needed." -ForegroundColor Yellow
} else {
    Write-Host "✅ No Lightsail instances found" -ForegroundColor Green
}

# 5. Set up cost monitoring
Write-Host "`n📊 Setting up cost monitoring..." -ForegroundColor Yellow

# Create SNS topic for billing alerts (if it doesn't exist)
$snsTopicArn = aws sns create-topic --name "aws-billing-alerts" --query "TopicArn" --output text 2>$null
if ($snsTopicArn) {
    Write-Host "✅ Created SNS topic for billing alerts: $snsTopicArn" -ForegroundColor Green
    
    # Subscribe your email (you'll need to confirm the subscription)
    $email = Read-Host "Enter your email address for billing alerts (optional)"
    if ($email) {
        aws sns subscribe --topic-arn $snsTopicArn --protocol email --notification-endpoint $email
        Write-Host "📧 Subscription request sent to $email - please confirm in your email" -ForegroundColor Yellow
    }
    
    # Create CloudWatch billing alarm
    aws cloudwatch put-metric-alarm `
        --alarm-name "Monthly-Billing-Alert-200" `
        --alarm-description "Alert when monthly bill exceeds $200" `
        --metric-name EstimatedCharges `
        --namespace "AWS/Billing" `
        --statistic Maximum `
        --period 86400 `
        --threshold 200 `
        --comparison-operator GreaterThanThreshold `
        --dimensions Name=Currency,Value=USD `
        --evaluation-periods 1 `
        --alarm-actions $snsTopicArn
    
    Write-Host "✅ Created billing alarm for $200/month threshold" -ForegroundColor Green
}

# 6. Generate cost optimization report
Write-Host "`n📋 Generating current cost summary..." -ForegroundColor Yellow

$currentMonth = Get-Date -Format "yyyy-MM-01"
$nextMonth = (Get-Date).AddMonths(1).ToString("yyyy-MM-01")

$monthlyCost = aws ce get-cost-and-usage --time-period Start=$currentMonth,End=$nextMonth --granularity MONTHLY --metrics BlendedCost --query "ResultsByTime[0].Total.BlendedCost.Amount" --output text

Write-Host "`n💰 Current Month Cost Summary:" -ForegroundColor Cyan
Write-Host "  Current month-to-date: `$$monthlyCost" -ForegroundColor White

# Get top services
$topServices = aws ce get-cost-and-usage --time-period Start=$currentMonth,End=$nextMonth --granularity MONTHLY --metrics BlendedCost --group-by Type=DIMENSION,Key=SERVICE --query "ResultsByTime[0].Groups[?Metrics.BlendedCost.Amount > '1'].{Service:Keys[0],Cost:Metrics.BlendedCost.Amount}" --output json | ConvertFrom-Json

Write-Host "`n🔝 Top Cost Drivers:" -ForegroundColor Cyan
$topServices | Sort-Object {[decimal]$_.Cost} -Descending | Select-Object -First 5 | ForEach-Object {
    Write-Host "  - $($_.Service): `$$([math]::Round([decimal]$_.Cost, 2))" -ForegroundColor White
}

Write-Host "`n✅ Cost optimization analysis complete!" -ForegroundColor Green
Write-Host "💡 Review the AWS_Cost_Optimization_Plan.md file for detailed recommendations" -ForegroundColor Yellow