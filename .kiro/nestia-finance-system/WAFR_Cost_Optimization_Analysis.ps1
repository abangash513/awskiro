# AWS Well-Architected Framework Review - Cost Optimization Analysis
# Account: 212114479343
# Date: December 22, 2025

$ErrorActionPreference = "SilentlyContinue"
$report = @{
    AccountId = "212114479343"
    AnalysisDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Findings = @()
    Recommendations = @()
    EstimatedSavings = 0
}

Write-Host "`n=== AWS WAFR Cost Optimization Analysis ===" -ForegroundColor Cyan
Write-Host "Account: $($report.AccountId)" -ForegroundColor Yellow
Write-Host "Analysis Date: $($report.AnalysisDate)`n" -ForegroundColor Yellow

# 1. EC2 Cost Optimization
Write-Host "[1/10] Analyzing EC2 Instances..." -ForegroundColor Cyan
try {
    $ec2Data = aws ec2 describe-instances --output json | ConvertFrom-Json
    $allInstances = $ec2Data.Reservations.Instances
    $runningInstances = $allInstances | Where-Object { $_.State.Name -eq "running" }
    $stoppedInstances = $allInstances | Where-Object { $_.State.Name -eq "stopped" }
    
    Write-Host "  Total Instances: $($allInstances.Count)" -ForegroundColor White
    Write-Host "  Running: $($runningInstances.Count)" -ForegroundColor Green
    Write-Host "  Stopped: $($stoppedInstances.Count)" -ForegroundColor Yellow
    
    # Check for old generation instances
    $oldGenInstances = $runningInstances | Where-Object { $_.InstanceType -match "^(t2|m4|c4|r4)" }
    if ($oldGenInstances) {
        $report.Findings += "Found $($oldGenInstances.Count) old generation EC2 instances (t2, m4, c4, r4)"
        $report.Recommendations += "Upgrade to newer generation instances (t3, m5, c5, r5) for 10-20% cost savings"
        $report.EstimatedSavings += $oldGenInstances.Count * 50
    }
    
    # Check for stopped instances with EBS volumes
    if ($stoppedInstances.Count -gt 0) {
        $report.Findings += "Found $($stoppedInstances.Count) stopped EC2 instances still incurring EBS costs"
        $report.Recommendations += "Terminate unused stopped instances or create AMIs and delete instances"
        $report.EstimatedSavings += $stoppedInstances.Count * 20
    }
} catch {
    Write-Host "  Error analyzing EC2: $_" -ForegroundColor Red
}

# 2. EBS Volume Optimization
Write-Host "`n[2/10] Analyzing EBS Volumes..." -ForegroundColor Cyan
try {
    $volumes = aws ec2 describe-volumes --output json | ConvertFrom-Json
    $allVolumes = $volumes.Volumes
    $unattachedVolumes = $allVolumes | Where-Object { $_.Attachments.Count -eq 0 }
    $gp2Volumes = $allVolumes | Where-Object { $_.VolumeType -eq "gp2" }
    
    Write-Host "  Total Volumes: $($allVolumes.Count)" -ForegroundColor White
    Write-Host "  Unattached: $($unattachedVolumes.Count)" -ForegroundColor Yellow
    Write-Host "  gp2 Volumes: $($gp2Volumes.Count)" -ForegroundColor Yellow
    
    if ($unattachedVolumes.Count -gt 0) {
        $totalSize = ($unattachedVolumes | Measure-Object -Property Size -Sum).Sum
        $report.Findings += "Found $($unattachedVolumes.Count) unattached EBS volumes ($totalSize GB)"
        $report.Recommendations += "Delete unattached EBS volumes to save ~`$$([math]::Round($totalSize * 0.10, 2))/month"
        $report.EstimatedSavings += [math]::Round($totalSize * 0.10, 2)
    }
    
    if ($gp2Volumes.Count -gt 0) {
        $gp2Size = ($gp2Volumes | Measure-Object -Property Size -Sum).Sum
        $report.Findings += "Found $($gp2Volumes.Count) gp2 volumes ($gp2Size GB) - older generation"
        $report.Recommendations += "Migrate gp2 to gp3 for 20% cost savings (~`$$([math]::Round($gp2Size * 0.02, 2))/month)"
        $report.EstimatedSavings += [math]::Round($gp2Size * 0.02, 2)
    }
} catch {
    Write-Host "  Error analyzing EBS: $_" -ForegroundColor Red
}

# 3. S3 Cost Optimization
Write-Host "`n[3/10] Analyzing S3 Buckets..." -ForegroundColor Cyan
try {
    $buckets = aws s3 ls | ForEach-Object { $_.Split()[-1] }
    Write-Host "  Total Buckets: $($buckets.Count)" -ForegroundColor White
    
    $report.Findings += "Found $($buckets.Count) S3 buckets"
    $report.Recommendations += "Review S3 lifecycle policies, enable Intelligent-Tiering, and delete old versions"
} catch {
    Write-Host "  Error analyzing S3: $_" -ForegroundColor Red
}

# 4. RDS Cost Optimization
Write-Host "`n[4/10] Analyzing RDS Instances..." -ForegroundColor Cyan
try {
    $rdsInstances = aws rds describe-db-instances --output json | ConvertFrom-Json
    $allRDS = $rdsInstances.DBInstances
    
    if ($allRDS.Count -gt 0) {
        Write-Host "  Total RDS Instances: $($allRDS.Count)" -ForegroundColor White
        
        $oldGenRDS = $allRDS | Where-Object { $_.DBInstanceClass -match "db\.(t2|m4|r4)" }
        if ($oldGenRDS) {
            $report.Findings += "Found $($oldGenRDS.Count) old generation RDS instances"
            $report.Recommendations += "Upgrade RDS to newer instance classes for better price/performance"
            $report.EstimatedSavings += $oldGenRDS.Count * 100
        }
    } else {
        Write-Host "  No RDS instances found" -ForegroundColor White
    }
} catch {
    Write-Host "  No RDS instances or error: $_" -ForegroundColor Yellow
}

# 5. Lambda Cost Optimization
Write-Host "`n[5/10] Analyzing Lambda Functions..." -ForegroundColor Cyan
try {
    $lambdaFunctions = aws lambda list-functions --output json | ConvertFrom-Json
    $allFunctions = $lambdaFunctions.Functions
    
    Write-Host "  Total Lambda Functions: $($allFunctions.Count)" -ForegroundColor White
    
    if ($allFunctions.Count -gt 0) {
        $report.Findings += "Found $($allFunctions.Count) Lambda functions"
        $report.Recommendations += "Review Lambda memory allocation and timeout settings for optimization"
    }
} catch {
    Write-Host "  Error analyzing Lambda: $_" -ForegroundColor Red
}

# 6. Elastic IP Optimization
Write-Host "`n[6/10] Analyzing Elastic IPs..." -ForegroundColor Cyan
try {
    $eips = aws ec2 describe-addresses --output json | ConvertFrom-Json
    $unassociatedEIPs = $eips.Addresses | Where-Object { -not $_.AssociationId }
    
    if ($unassociatedEIPs.Count -gt 0) {
        Write-Host "  Unassociated EIPs: $($unassociatedEIPs.Count)" -ForegroundColor Yellow
        $report.Findings += "Found $($unassociatedEIPs.Count) unassociated Elastic IPs"
        $report.Recommendations += "Release unassociated Elastic IPs to save ~`$$($unassociatedEIPs.Count * 3.6)/month"
        $report.EstimatedSavings += $unassociatedEIPs.Count * 3.6
    } else {
        Write-Host "  No unassociated EIPs found" -ForegroundColor Green
    }
} catch {
    Write-Host "  Error analyzing EIPs: $_" -ForegroundColor Red
}

# 7. Load Balancer Optimization
Write-Host "`n[7/10] Analyzing Load Balancers..." -ForegroundColor Cyan
try {
    $elbv2 = aws elbv2 describe-load-balancers --output json | ConvertFrom-Json
    $loadBalancers = $elbv2.LoadBalancers
    
    if ($loadBalancers.Count -gt 0) {
        Write-Host "  Total Load Balancers: $($loadBalancers.Count)" -ForegroundColor White
        $report.Findings += "Found $($loadBalancers.Count) load balancers"
        $report.Recommendations += "Review load balancer usage and consolidate where possible"
    } else {
        Write-Host "  No load balancers found" -ForegroundColor White
    }
} catch {
    Write-Host "  Error analyzing Load Balancers: $_" -ForegroundColor Yellow
}

# 8. NAT Gateway Optimization
Write-Host "`n[8/10] Analyzing NAT Gateways..." -ForegroundColor Cyan
try {
    $natGateways = aws ec2 describe-nat-gateways --output json | ConvertFrom-Json
    $activeNATs = $natGateways.NatGateways | Where-Object { $_.State -eq "available" }
    
    if ($activeNATs.Count -gt 0) {
        Write-Host "  Active NAT Gateways: $($activeNATs.Count)" -ForegroundColor White
        $report.Findings += "Found $($activeNATs.Count) NAT Gateways (~`$$($activeNATs.Count * 32)/month base cost)"
        $report.Recommendations += "Consider NAT instances for dev/test or consolidate NAT Gateways"
    } else {
        Write-Host "  No NAT Gateways found" -ForegroundColor White
    }
} catch {
    Write-Host "  Error analyzing NAT Gateways: $_" -ForegroundColor Yellow
}

# 9. CloudWatch Logs Optimization
Write-Host "`n[9/10] Analyzing CloudWatch Logs..." -ForegroundColor Cyan
try {
    $logGroups = aws logs describe-log-groups --output json | ConvertFrom-Json
    $allLogGroups = $logGroups.logGroups
    $noRetention = $allLogGroups | Where-Object { -not $_.retentionInDays }
    
    Write-Host "  Total Log Groups: $($allLogGroups.Count)" -ForegroundColor White
    
    if ($noRetention.Count -gt 0) {
        Write-Host "  Log Groups without retention: $($noRetention.Count)" -ForegroundColor Yellow
        $report.Findings += "Found $($noRetention.Count) log groups without retention policies"
        $report.Recommendations += "Set retention policies on CloudWatch Logs to reduce storage costs"
        $report.EstimatedSavings += 20
    }
} catch {
    Write-Host "  Error analyzing CloudWatch Logs: $_" -ForegroundColor Red
}

# 10. Snapshot Optimization
Write-Host "`n[10/10] Analyzing EBS Snapshots..." -ForegroundColor Cyan
try {
    $snapshots = aws ec2 describe-snapshots --owner-ids self --output json | ConvertFrom-Json
    $allSnapshots = $snapshots.Snapshots
    
    if ($allSnapshots.Count -gt 0) {
        Write-Host "  Total Snapshots: $($allSnapshots.Count)" -ForegroundColor White
        
        # Check for old snapshots (>90 days)
        $oldSnapshots = $allSnapshots | Where-Object { 
            (New-TimeSpan -Start $_.StartTime -End (Get-Date)).Days -gt 90 
        }
        
        if ($oldSnapshots.Count -gt 0) {
            $report.Findings += "Found $($oldSnapshots.Count) snapshots older than 90 days"
            $report.Recommendations += "Review and delete old snapshots to reduce storage costs"
            $report.EstimatedSavings += 30
        }
    } else {
        Write-Host "  No snapshots found" -ForegroundColor White
    }
} catch {
    Write-Host "  Error analyzing Snapshots: $_" -ForegroundColor Red
}

# Generate Report
Write-Host "`n`n=== COST OPTIMIZATION FINDINGS ===" -ForegroundColor Magenta
Write-Host "Total Findings: $($report.Findings.Count)" -ForegroundColor Yellow
Write-Host "Estimated Monthly Savings: `$$($report.EstimatedSavings)" -ForegroundColor Green
Write-Host "Estimated Annual Savings: `$$($report.EstimatedSavings * 12)`n" -ForegroundColor Green

Write-Host "FINDINGS:" -ForegroundColor Cyan
$report.Findings | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }

Write-Host "`nRECOMMENDATIONS:" -ForegroundColor Cyan
$report.Recommendations | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }

# Export to JSON
$reportFile = "WAFR_Cost_Optimization_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$report | ConvertTo-Json -Depth 10 | Out-File -FilePath $reportFile -Encoding utf8
Write-Host "`n`nReport saved to: $reportFile" -ForegroundColor Green

# Return summary
return $report
