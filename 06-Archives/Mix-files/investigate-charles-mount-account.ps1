# Charles Mount Account Investigation
# Deep dive into the $57K/month account to identify cost drivers

Write-Host "========================================" -ForegroundColor Green
Write-Host "CHARLES MOUNT ACCOUNT INVESTIGATION" -ForegroundColor Green
Write-Host "Account: 198161015548 - $57,452/month" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

# Verify we're in the right account
$identity = aws sts get-caller-identity --output json | ConvertFrom-Json
Write-Host "Current Account: $($identity.Account)" -ForegroundColor Cyan
Write-Host "Current User: $($identity.Arn)`n" -ForegroundColor Cyan

if ($identity.Account -ne "198161015548") {
    Write-Host "ERROR: Not in Charles Mount account!" -ForegroundColor Red
    exit 1
}

$allRegions = @(
    'us-east-1', 'us-east-2', 'us-west-1', 'us-west-2',
    'ap-south-1', 'ap-northeast-1', 'ap-northeast-2', 'ap-southeast-1', 'ap-southeast-2',
    'ca-central-1', 'eu-central-1', 'eu-west-1', 'eu-west-2', 'eu-west-3', 'sa-east-1'
)

# 1. EC2 INSTANCES
Write-Host "[1/10] Scanning EC2 Instances..." -ForegroundColor Cyan
$ec2Instances = @()
foreach ($region in $allRegions) {
    try {
        $instances = aws ec2 describe-instances --region $region --output json 2>$null | ConvertFrom-Json
        if ($instances.Reservations) {
            foreach ($reservation in $instances.Reservations) {
                foreach ($instance in $reservation.Instances) {
                    $ec2Instances += [PSCustomObject]@{
                        Region = $region
                        InstanceId = $instance.InstanceId
                        InstanceType = $instance.InstanceType
                        State = $instance.State.Name
                        LaunchTime = $instance.LaunchTime
                        Platform = if ($instance.Platform) { $instance.Platform } else { 'Linux' }
                        PrivateIP = $instance.PrivateIpAddress
                        PublicIP = if ($instance.PublicIpAddress) { $instance.PublicIpAddress } else { 'None' }
                    }
                }
            }
        }
    } catch {}
}
Write-Host "  Found: $($ec2Instances.Count) EC2 instances" -ForegroundColor Yellow
$ec2Instances | Export-Csv -Path "charles-mount-ec2-instances.csv" -NoTypeInformation

# 2. RDS DATABASES
Write-Host "[2/10] Scanning RDS Databases..." -ForegroundColor Cyan
$rdsInstances = @()
foreach ($region in $allRegions) {
    try {
        $dbs = aws rds describe-db-instances --region $region --output json 2>$null | ConvertFrom-Json
        if ($dbs.DBInstances) {
            foreach ($db in $dbs.DBInstances) {
                $rdsInstances += [PSCustomObject]@{
                    Region = $region
                    DBInstanceId = $db.DBInstanceIdentifier
                    DBInstanceClass = $db.DBInstanceClass
                    Engine = $db.Engine
                    EngineVersion = $db.EngineVersion
                    Status = $db.DBInstanceStatus
                    AllocatedStorage = $db.AllocatedStorage
                    StorageType = $db.StorageType
                    MultiAZ = $db.MultiAZ
                    CreateTime = $db.InstanceCreateTime
                }
            }
        }
    } catch {}
}
Write-Host "  Found: $($rdsInstances.Count) RDS instances" -ForegroundColor Yellow
$rdsInstances | Export-Csv -Path "charles-mount-rds-instances.csv" -NoTypeInformation

# 3. EBS VOLUMES
Write-Host "[3/10] Scanning EBS Volumes..." -ForegroundColor Cyan
$ebsVolumes = @()
foreach ($region in $allRegions) {
    try {
        $volumes = aws ec2 describe-volumes --region $region --output json 2>$null | ConvertFrom-Json
        if ($volumes.Volumes) {
            foreach ($vol in $volumes.Volumes) {
                $ebsVolumes += [PSCustomObject]@{
                    Region = $region
                    VolumeId = $vol.VolumeId
                    VolumeType = $vol.VolumeType
                    SizeGB = $vol.Size
                    State = $vol.State
                    IOPS = $vol.Iops
                    Encrypted = $vol.Encrypted
                    AttachedTo = if ($vol.Attachments.Count -gt 0) { $vol.Attachments[0].InstanceId } else { 'Unattached' }
                }
            }
        }
    } catch {}
}
Write-Host "  Found: $($ebsVolumes.Count) EBS volumes" -ForegroundColor Yellow
$ebsVolumes | Export-Csv -Path "charles-mount-ebs-volumes.csv" -NoTypeInformation

# 4. S3 BUCKETS
Write-Host "[4/10] Scanning S3 Buckets..." -ForegroundColor Cyan
$s3Buckets = @()
try {
    $buckets = aws s3api list-buckets --output json 2>$null | ConvertFrom-Json
    if ($buckets.Buckets) {
        foreach ($bucket in $buckets.Buckets) {
            $s3Buckets += [PSCustomObject]@{
                BucketName = $bucket.Name
                CreationDate = $bucket.CreationDate
            }
        }
    }
} catch {}
Write-Host "  Found: $($s3Buckets.Count) S3 buckets" -ForegroundColor Yellow
$s3Buckets | Export-Csv -Path "charles-mount-s3-buckets.csv" -NoTypeInformation

# 5. LOAD BALANCERS
Write-Host "[5/10] Scanning Load Balancers..." -ForegroundColor Cyan
$loadBalancers = @()
foreach ($region in $allRegions) {
    try {
        # ALB/NLB
        $albs = aws elbv2 describe-load-balancers --region $region --output json 2>$null | ConvertFrom-Json
        if ($albs.LoadBalancers) {
            foreach ($lb in $albs.LoadBalancers) {
                $loadBalancers += [PSCustomObject]@{
                    Region = $region
                    Name = $lb.LoadBalancerName
                    Type = $lb.Type
                    Scheme = $lb.Scheme
                    State = $lb.State.Code
                    CreatedTime = $lb.CreatedTime
                }
            }
        }
        # Classic LB
        $clbs = aws elb describe-load-balancers --region $region --output json 2>$null | ConvertFrom-Json
        if ($clbs.LoadBalancerDescriptions) {
            foreach ($lb in $clbs.LoadBalancerDescriptions) {
                $loadBalancers += [PSCustomObject]@{
                    Region = $region
                    Name = $lb.LoadBalancerName
                    Type = 'classic'
                    Scheme = $lb.Scheme
                    State = 'active'
                    CreatedTime = $lb.CreatedTime
                }
            }
        }
    } catch {}
}
Write-Host "  Found: $($loadBalancers.Count) Load Balancers" -ForegroundColor Yellow
$loadBalancers | Export-Csv -Path "charles-mount-load-balancers.csv" -NoTypeInformation

# 6. NAT GATEWAYS
Write-Host "[6/10] Scanning NAT Gateways..." -ForegroundColor Cyan
$natGateways = @()
foreach ($region in $allRegions) {
    try {
        $nats = aws ec2 describe-nat-gateways --region $region --output json 2>$null | ConvertFrom-Json
        if ($nats.NatGateways) {
            foreach ($nat in $nats.NatGateways) {
                $natGateways += [PSCustomObject]@{
                    Region = $region
                    NatGatewayId = $nat.NatGatewayId
                    State = $nat.State
                    VpcId = $nat.VpcId
                    SubnetId = $nat.SubnetId
                    CreateTime = $nat.CreateTime
                }
            }
        }
    } catch {}
}
Write-Host "  Found: $($natGateways.Count) NAT Gateways" -ForegroundColor Yellow
$natGateways | Export-Csv -Path "charles-mount-nat-gateways.csv" -NoTypeInformation

# 7. OPENSEARCH DOMAINS
Write-Host "[7/10] Scanning OpenSearch Domains..." -ForegroundColor Cyan
$openSearchDomains = @()
foreach ($region in $allRegions) {
    try {
        $domains = aws opensearch list-domain-names --region $region --output json 2>$null | ConvertFrom-Json
        if ($domains.DomainNames) {
            foreach ($domain in $domains.DomainNames) {
                $domainInfo = aws opensearch describe-domain --region $region --domain-name $domain.DomainName --output json 2>$null | ConvertFrom-Json
                if ($domainInfo.DomainStatus) {
                    $openSearchDomains += [PSCustomObject]@{
                        Region = $region
                        DomainName = $domainInfo.DomainStatus.DomainName
                        InstanceType = $domainInfo.DomainStatus.ClusterConfig.InstanceType
                        InstanceCount = $domainInfo.DomainStatus.ClusterConfig.InstanceCount
                        StorageSize = $domainInfo.DomainStatus.EBSOptions.VolumeSize
                        EngineVersion = $domainInfo.DomainStatus.EngineVersion
                    }
                }
            }
        }
    } catch {}
}
Write-Host "  Found: $($openSearchDomains.Count) OpenSearch domains" -ForegroundColor Yellow
$openSearchDomains | Export-Csv -Path "charles-mount-opensearch-domains.csv" -NoTypeInformation

# 8. ELASTICACHE CLUSTERS
Write-Host "[8/10] Scanning ElastiCache Clusters..." -ForegroundColor Cyan
$elastiCacheClusters = @()
foreach ($region in $allRegions) {
    try {
        $clusters = aws elasticache describe-cache-clusters --region $region --output json 2>$null | ConvertFrom-Json
        if ($clusters.CacheClusters) {
            foreach ($cluster in $clusters.CacheClusters) {
                $elastiCacheClusters += [PSCustomObject]@{
                    Region = $region
                    ClusterId = $cluster.CacheClusterId
                    NodeType = $cluster.CacheNodeType
                    Engine = $cluster.Engine
                    EngineVersion = $cluster.EngineVersion
                    NumNodes = $cluster.NumCacheNodes
                    Status = $cluster.CacheClusterStatus
                }
            }
        }
    } catch {}
}
Write-Host "  Found: $($elastiCacheClusters.Count) ElastiCache clusters" -ForegroundColor Yellow
$elastiCacheClusters | Export-Csv -Path "charles-mount-elasticache-clusters.csv" -NoTypeInformation

# 9. ECS CLUSTERS & TASKS
Write-Host "[9/10] Scanning ECS Clusters..." -ForegroundColor Cyan
$ecsClusters = @()
$ecsTasks = @()
foreach ($region in $allRegions) {
    try {
        $clusters = aws ecs list-clusters --region $region --output json 2>$null | ConvertFrom-Json
        if ($clusters.clusterArns) {
            foreach ($clusterArn in $clusters.clusterArns) {
                $clusterInfo = aws ecs describe-clusters --region $region --clusters $clusterArn --output json 2>$null | ConvertFrom-Json
                if ($clusterInfo.clusters) {
                    $ecsClusters += [PSCustomObject]@{
                        Region = $region
                        ClusterName = $clusterInfo.clusters[0].clusterName
                        Status = $clusterInfo.clusters[0].status
                        RunningTasks = $clusterInfo.clusters[0].runningTasksCount
                        PendingTasks = $clusterInfo.clusters[0].pendingTasksCount
                        ActiveServices = $clusterInfo.clusters[0].activeServicesCount
                    }
                    
                    # Get tasks
                    $tasks = aws ecs list-tasks --region $region --cluster $clusterArn --output json 2>$null | ConvertFrom-Json
                    if ($tasks.taskArns) {
                        $ecsTasks += [PSCustomObject]@{
                            Region = $region
                            ClusterName = $clusterInfo.clusters[0].clusterName
                            TaskCount = $tasks.taskArns.Count
                        }
                    }
                }
            }
        }
    } catch {}
}
Write-Host "  Found: $($ecsClusters.Count) ECS clusters, $($ecsTasks.Count) task groups" -ForegroundColor Yellow
$ecsClusters | Export-Csv -Path "charles-mount-ecs-clusters.csv" -NoTypeInformation

# 10. LAMBDA FUNCTIONS
Write-Host "[10/10] Scanning Lambda Functions..." -ForegroundColor Cyan
$lambdaFunctions = @()
foreach ($region in $allRegions) {
    try {
        $functions = aws lambda list-functions --region $region --output json 2>$null | ConvertFrom-Json
        if ($functions.Functions) {
            foreach ($func in $functions.Functions) {
                $lambdaFunctions += [PSCustomObject]@{
                    Region = $region
                    FunctionName = $func.FunctionName
                    Runtime = $func.Runtime
                    MemorySize = $func.MemorySize
                    Timeout = $func.Timeout
                    LastModified = $func.LastModified
                }
            }
        }
    } catch {}
}
Write-Host "  Found: $($lambdaFunctions.Count) Lambda functions" -ForegroundColor Yellow
$lambdaFunctions | Export-Csv -Path "charles-mount-lambda-functions.csv" -NoTypeInformation

# SUMMARY
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "CHARLES MOUNT ACCOUNT SUMMARY" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "Resource Inventory:" -ForegroundColor Cyan
Write-Host "  EC2 Instances: $($ec2Instances.Count)" -ForegroundColor White
Write-Host "  RDS Databases: $($rdsInstances.Count)" -ForegroundColor White
Write-Host "  EBS Volumes: $($ebsVolumes.Count)" -ForegroundColor White
Write-Host "  S3 Buckets: $($s3Buckets.Count)" -ForegroundColor White
Write-Host "  Load Balancers: $($loadBalancers.Count)" -ForegroundColor White
Write-Host "  NAT Gateways: $($natGateways.Count)" -ForegroundColor White
Write-Host "  OpenSearch Domains: $($openSearchDomains.Count)" -ForegroundColor White
Write-Host "  ElastiCache Clusters: $($elastiCacheClusters.Count)" -ForegroundColor White
Write-Host "  ECS Clusters: $($ecsClusters.Count)" -ForegroundColor White
Write-Host "  Lambda Functions: $($lambdaFunctions.Count)" -ForegroundColor White

Write-Host "`nRunning Resources:" -ForegroundColor Cyan
$runningEC2 = ($ec2Instances | Where-Object State -eq 'running').Count
$runningRDS = ($rdsInstances | Where-Object Status -eq 'available').Count
Write-Host "  Running EC2: $runningEC2" -ForegroundColor $(if ($runningEC2 -gt 0) { 'Yellow' } else { 'White' })
Write-Host "  Running RDS: $runningRDS" -ForegroundColor $(if ($runningRDS -gt 0) { 'Yellow' } else { 'White' })
Write-Host "  Running ECS Tasks: $(($ecsClusters | Measure-Object RunningTasks -Sum).Sum)" -ForegroundColor Yellow

Write-Host "`nCost Drivers (Estimated):" -ForegroundColor Cyan
if ($runningEC2 -gt 0) {
    Write-Host "  EC2: $runningEC2 running instances" -ForegroundColor Yellow
}
if ($runningRDS -gt 0) {
    Write-Host "  RDS: $runningRDS running databases" -ForegroundColor Yellow
}
if ($natGateways.Count -gt 0) {
    Write-Host "  NAT Gateways: $($natGateways.Count) x ~`$32/month = ~`$$($natGateways.Count * 32)/month" -ForegroundColor Yellow
}
if ($loadBalancers.Count -gt 0) {
    Write-Host "  Load Balancers: $($loadBalancers.Count) x ~`$16/month = ~`$$($loadBalancers.Count * 16)/month" -ForegroundColor Yellow
}
if ($openSearchDomains.Count -gt 0) {
    Write-Host "  OpenSearch: $($openSearchDomains.Count) domain(s)" -ForegroundColor Yellow
}
if ($elastiCacheClusters.Count -gt 0) {
    Write-Host "  ElastiCache: $($elastiCacheClusters.Count) cluster(s)" -ForegroundColor Yellow
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "FILES GENERATED" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "1. charles-mount-ec2-instances.csv" -ForegroundColor White
Write-Host "2. charles-mount-rds-instances.csv" -ForegroundColor White
Write-Host "3. charles-mount-ebs-volumes.csv" -ForegroundColor White
Write-Host "4. charles-mount-s3-buckets.csv" -ForegroundColor White
Write-Host "5. charles-mount-load-balancers.csv" -ForegroundColor White
Write-Host "6. charles-mount-nat-gateways.csv" -ForegroundColor White
Write-Host "7. charles-mount-opensearch-domains.csv" -ForegroundColor White
Write-Host "8. charles-mount-elasticache-clusters.csv" -ForegroundColor White
Write-Host "9. charles-mount-ecs-clusters.csv" -ForegroundColor White
Write-Host "10. charles-mount-lambda-functions.csv" -ForegroundColor White

Write-Host "`n========================================`n" -ForegroundColor Green
