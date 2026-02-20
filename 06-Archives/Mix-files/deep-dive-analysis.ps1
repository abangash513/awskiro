# Comprehensive Deep Dive Analysis
# 1. Charles Mount Account Analysis
# 2. RDS Instance Analysis
# 3. ECS/Fargate Analysis
# 4. S3 Bucket Analysis
# 5. OpenSearch Analysis

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

Write-Host "========================================" -ForegroundColor Green
Write-Host "COMPREHENSIVE AWS DEEP DIVE ANALYSIS" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

# ============================================
# 1. CHARLES MOUNT ACCOUNT DEEP DIVE
# ============================================
Write-Host "`n[1/5] Analyzing Charles Mount Account (198161015548)..." -ForegroundColor Cyan

$charlesMountId = "198161015548"
$endDate = Get-Date -Format "yyyy-MM-dd"
$startDate = (Get-Date).AddDays(-30).ToString("yyyy-MM-dd")

try {
    # Get Charles Mount account costs by service
    $charlesCosts = aws ce get-cost-and-usage `
        --time-period Start=$startDate,End=$endDate `
        --granularity MONTHLY `
        --metrics "UnblendedCost" `
        --filter "{`"Dimensions`":{`"Key`":`"LINKED_ACCOUNT`",`"Values`":[`"$charlesMountId`"]}}" `
        --group-by Type=DIMENSION,Key=SERVICE `
        --output json 2>$null | ConvertFrom-Json
    
    $charlesServiceCosts = @()
    if ($charlesCosts.ResultsByTime) {
        foreach ($result in $charlesCosts.ResultsByTime) {
            foreach ($group in $result.Groups) {
                $service = $group.Keys[0]
                $cost = [math]::Round([decimal]$group.Metrics.UnblendedCost.Amount, 2)
                
                if ($cost -gt 0) {
                    $charlesServiceCosts += [PSCustomObject]@{
                        Service = $service
                        MonthlyCost = $cost
                    }
                }
            }
        }
    }
    
    $charlesServiceCosts | Sort-Object MonthlyCost -Descending | Export-Csv -Path "charles-mount-costs-by-service.csv" -NoTypeInformation
    
    Write-Host "  Top 10 services in Charles Mount account:" -ForegroundColor Yellow
    $charlesServiceCosts | Sort-Object MonthlyCost -Descending | Select-Object -First 10 | ForEach-Object {
        Write-Host "    $($_.Service): `$$($_.MonthlyCost)" -ForegroundColor White
    }
} catch {
    Write-Host "  Error analyzing Charles Mount account: $_" -ForegroundColor Red
}

# ============================================
# 2. RDS INSTANCE ANALYSIS
# ============================================
Write-Host "`n[2/5] Analyzing RDS Instances across all accounts..." -ForegroundColor Cyan

$rdsInstances = @()
foreach ($account in $accounts) {
    foreach ($region in $regions) {
        try {
            $instances = aws rds describe-db-instances --region $region --query 'DBInstances[].[DBInstanceIdentifier,DBInstanceClass,Engine,EngineVersion,DBInstanceStatus,AllocatedStorage,StorageType,MultiAZ,PubliclyAccessible,InstanceCreateTime,PreferredMaintenanceWindow,BackupRetentionPeriod]' --output json 2>$null | ConvertFrom-Json
            
            if ($instances -and $instances.Count -gt 0) {
                foreach ($instance in $instances) {
                    $rdsInstances += [PSCustomObject]@{
                        AccountId = $account.Id
                        AccountName = $account.Name
                        Region = $region
                        DBInstanceId = $instance[0]
                        InstanceClass = $instance[1]
                        Engine = $instance[2]
                        EngineVersion = $instance[3]
                        Status = $instance[4]
                        StorageGB = $instance[5]
                        StorageType = $instance[6]
                        MultiAZ = $instance[7]
                        PubliclyAccessible = $instance[8]
                        CreateTime = $instance[9]
                        MaintenanceWindow = $instance[10]
                        BackupRetention = $instance[11]
                    }
                }
            }
        } catch {
            # Continue on error
        }
    }
}

if ($rdsInstances.Count -gt 0) {
    $rdsInstances | Export-Csv -Path "rds-instances-all-accounts.csv" -NoTypeInformation
    Write-Host "  Found $($rdsInstances.Count) RDS instances" -ForegroundColor Yellow
    Write-Host "  Instance Class Breakdown:" -ForegroundColor Yellow
    $rdsInstances | Group-Object InstanceClass | ForEach-Object {
        Write-Host "    $($_.Name): $($_.Count) instance(s)" -ForegroundColor White
    }
} else {
    Write-Host "  No RDS instances found" -ForegroundColor Yellow
}

# ============================================
# 3. ECS/FARGATE ANALYSIS
# ============================================
Write-Host "`n[3/5] Analyzing ECS Clusters and Fargate Tasks..." -ForegroundColor Cyan

$ecsClusters = @()
$ecsTasks = @()
$ecsServices = @()

foreach ($account in $accounts) {
    foreach ($region in $regions) {
        try {
            # List ECS clusters
            $clusterArns = aws ecs list-clusters --region $region --query 'clusterArns[]' --output json 2>$null | ConvertFrom-Json
            
            if ($clusterArns -and $clusterArns.Count -gt 0) {
                foreach ($clusterArn in $clusterArns) {
                    $clusterName = $clusterArn.Split('/')[-1]
                    
                    # Describe cluster
                    $clusterDetail = aws ecs describe-clusters --region $region --clusters $clusterArn --query 'clusters[0]' --output json 2>$null | ConvertFrom-Json
                    
                    if ($clusterDetail) {
                        $ecsClusters += [PSCustomObject]@{
                            AccountId = $account.Id
                            AccountName = $account.Name
                            Region = $region
                            ClusterName = $clusterDetail.clusterName
                            Status = $clusterDetail.status
                            RunningTasksCount = $clusterDetail.runningTasksCount
                            PendingTasksCount = $clusterDetail.pendingTasksCount
                            ActiveServicesCount = $clusterDetail.activeServicesCount
                            RegisteredContainerInstancesCount = $clusterDetail.registeredContainerInstancesCount
                        }
                        
                        # List services in cluster
                        $serviceArns = aws ecs list-services --region $region --cluster $clusterArn --query 'serviceArns[]' --output json 2>$null | ConvertFrom-Json
                        
                        if ($serviceArns -and $serviceArns.Count -gt 0) {
                            $serviceDetails = aws ecs describe-services --region $region --cluster $clusterArn --services $serviceArns --query 'services[]' --output json 2>$null | ConvertFrom-Json
                            
                            foreach ($service in $serviceDetails) {
                                $ecsServices += [PSCustomObject]@{
                                    AccountId = $account.Id
                                    AccountName = $account.Name
                                    Region = $region
                                    ClusterName = $clusterName
                                    ServiceName = $service.serviceName
                                    Status = $service.status
                                    DesiredCount = $service.desiredCount
                                    RunningCount = $service.runningCount
                                    LaunchType = $service.launchType
                                    TaskDefinition = $service.taskDefinition.Split('/')[-1]
                                }
                            }
                        }
                        
                        # List tasks in cluster
                        $taskArns = aws ecs list-tasks --region $region --cluster $clusterArn --query 'taskArns[]' --output json 2>$null | ConvertFrom-Json
                        
                        if ($taskArns -and $taskArns.Count -gt 0) {
                            $taskDetails = aws ecs describe-tasks --region $region --cluster $clusterArn --tasks $taskArns --query 'tasks[]' --output json 2>$null | ConvertFrom-Json
                            
                            foreach ($task in $taskDetails) {
                                $ecsTasks += [PSCustomObject]@{
                                    AccountId = $account.Id
                                    AccountName = $account.Name
                                    Region = $region
                                    ClusterName = $clusterName
                                    TaskArn = $task.taskArn.Split('/')[-1]
                                    LaunchType = $task.launchType
                                    LastStatus = $task.lastStatus
                                    DesiredStatus = $task.desiredStatus
                                    Cpu = $task.cpu
                                    Memory = $task.memory
                                    StartedAt = $task.startedAt
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            # Continue on error
        }
    }
}

if ($ecsClusters.Count -gt 0) {
    $ecsClusters | Export-Csv -Path "ecs-clusters-all-accounts.csv" -NoTypeInformation
    Write-Host "  Found $($ecsClusters.Count) ECS cluster(s)" -ForegroundColor Yellow
    Write-Host "  Total Running Tasks: $(($ecsClusters | Measure-Object RunningTasksCount -Sum).Sum)" -ForegroundColor Yellow
}

if ($ecsServices.Count -gt 0) {
    $ecsServices | Export-Csv -Path "ecs-services-all-accounts.csv" -NoTypeInformation
    Write-Host "  Found $($ecsServices.Count) ECS service(s)" -ForegroundColor Yellow
    Write-Host "  Launch Type Breakdown:" -ForegroundColor Yellow
    $ecsServices | Group-Object LaunchType | ForEach-Object {
        Write-Host "    $($_.Name): $($_.Count) service(s)" -ForegroundColor White
    }
}

if ($ecsTasks.Count -gt 0) {
    $ecsTasks | Export-Csv -Path "ecs-tasks-all-accounts.csv" -NoTypeInformation
}

# ============================================
# 4. S3 BUCKET ANALYSIS
# ============================================
Write-Host "`n[4/5] Analyzing S3 Buckets..." -ForegroundColor Cyan

$s3Buckets = @()
try {
    $bucketList = aws s3api list-buckets --query 'Buckets[].[Name,CreationDate]' --output json 2>$null | ConvertFrom-Json
    
    if ($bucketList -and $bucketList.Count -gt 0) {
        Write-Host "  Found $($bucketList.Count) S3 buckets. Analyzing sizes (this may take a while)..." -ForegroundColor Yellow
        
        $counter = 0
        foreach ($bucket in $bucketList) {
            $counter++
            $bucketName = $bucket[0]
            
            if ($counter % 10 -eq 0) {
                Write-Host "    Processed $counter/$($bucketList.Count) buckets..." -ForegroundColor Gray
            }
            
            try {
                # Get bucket location
                $location = aws s3api get-bucket-location --bucket $bucketName --query 'LocationConstraint' --output text 2>$null
                if (-not $location -or $location -eq 'None') { $location = 'us-east-1' }
                
                # Get bucket size using CloudWatch metrics (faster than listing all objects)
                $endTime = Get-Date
                $startTime = $endTime.AddDays(-1)
                
                $sizeMetric = aws cloudwatch get-metric-statistics `
                    --namespace AWS/S3 `
                    --metric-name BucketSizeBytes `
                    --dimensions Name=BucketName,Value=$bucketName Name=StorageType,Value=StandardStorage `
                    --start-time $startTime.ToString("yyyy-MM-ddTHH:mm:ss") `
                    --end-time $endTime.ToString("yyyy-MM-ddTHH:mm:ss") `
                    --period 86400 `
                    --statistics Average `
                    --region $location `
                    --output json 2>$null | ConvertFrom-Json
                
                $sizeBytes = 0
                if ($sizeMetric.Datapoints -and $sizeMetric.Datapoints.Count -gt 0) {
                    $sizeBytes = [math]::Round($sizeMetric.Datapoints[0].Average, 0)
                }
                
                $sizeGB = [math]::Round($sizeBytes / 1GB, 2)
                $monthlyCost = [math]::Round($sizeGB * 0.023, 2)  # $0.023 per GB for S3 Standard
                
                $s3Buckets += [PSCustomObject]@{
                    BucketName = $bucketName
                    Region = $location
                    CreationDate = $bucket[1]
                    SizeGB = $sizeGB
                    EstimatedMonthlyCost = $monthlyCost
                }
            } catch {
                $s3Buckets += [PSCustomObject]@{
                    BucketName = $bucketName
                    Region = $location
                    CreationDate = $bucket[1]
                    SizeGB = 0
                    EstimatedMonthlyCost = 0
                }
            }
        }
        
        $s3Buckets | Sort-Object SizeGB -Descending | Export-Csv -Path "s3-buckets-analysis.csv" -NoTypeInformation
        
        Write-Host "  Top 10 largest S3 buckets:" -ForegroundColor Yellow
        $s3Buckets | Sort-Object SizeGB -Descending | Select-Object -First 10 | ForEach-Object {
            Write-Host "    $($_.BucketName): $($_.SizeGB) GB (~`$$($_.EstimatedMonthlyCost)/month)" -ForegroundColor White
        }
    }
} catch {
    Write-Host "  Error analyzing S3 buckets: $_" -ForegroundColor Red
}

# ============================================
# 5. OPENSEARCH ANALYSIS
# ============================================
Write-Host "`n[5/5] Analyzing OpenSearch Domains..." -ForegroundColor Cyan

$openSearchDomains = @()
foreach ($account in $accounts) {
    foreach ($region in $regions) {
        try {
            $domainNames = aws opensearch list-domain-names --region $region --query 'DomainNames[].DomainName' --output json 2>$null | ConvertFrom-Json
            
            if ($domainNames -and $domainNames.Count -gt 0) {
                foreach ($domainName in $domainNames) {
                    $domainStatus = aws opensearch describe-domain --region $region --domain-name $domainName --query 'DomainStatus' --output json 2>$null | ConvertFrom-Json
                    
                    if ($domainStatus) {
                        $openSearchDomains += [PSCustomObject]@{
                            AccountId = $account.Id
                            AccountName = $account.Name
                            Region = $region
                            DomainName = $domainStatus.DomainName
                            EngineVersion = $domainStatus.EngineVersion
                            InstanceType = $domainStatus.ClusterConfig.InstanceType
                            InstanceCount = $domainStatus.ClusterConfig.InstanceCount
                            DedicatedMasterEnabled = $domainStatus.ClusterConfig.DedicatedMasterEnabled
                            DedicatedMasterType = $domainStatus.ClusterConfig.DedicatedMasterType
                            DedicatedMasterCount = $domainStatus.ClusterConfig.DedicatedMasterCount
                            StorageType = $domainStatus.EBSOptions.VolumeType
                            StorageSize = $domainStatus.EBSOptions.VolumeSize
                            Created = $domainStatus.Created
                            Deleted = $domainStatus.Deleted
                        }
                    }
                }
            }
        } catch {
            # Continue on error
        }
    }
}

if ($openSearchDomains.Count -gt 0) {
    $openSearchDomains | Export-Csv -Path "opensearch-domains-all-accounts.csv" -NoTypeInformation
    Write-Host "  Found $($openSearchDomains.Count) OpenSearch domain(s)" -ForegroundColor Yellow
    Write-Host "  Instance Type Breakdown:" -ForegroundColor Yellow
    $openSearchDomains | Group-Object InstanceType | ForEach-Object {
        Write-Host "    $($_.Name): $($_.Count) domain(s)" -ForegroundColor White
    }
} else {
    Write-Host "  No OpenSearch domains found" -ForegroundColor Yellow
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "ANALYSIS COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "`nGenerated Files:" -ForegroundColor Cyan
Write-Host "  1. charles-mount-costs-by-service.csv" -ForegroundColor White
Write-Host "  2. rds-instances-all-accounts.csv" -ForegroundColor White
Write-Host "  3. ecs-clusters-all-accounts.csv" -ForegroundColor White
Write-Host "  4. ecs-services-all-accounts.csv" -ForegroundColor White
Write-Host "  5. ecs-tasks-all-accounts.csv" -ForegroundColor White
Write-Host "  6. s3-buckets-analysis.csv" -ForegroundColor White
Write-Host "  7. opensearch-domains-all-accounts.csv" -ForegroundColor White
Write-Host "`n"
