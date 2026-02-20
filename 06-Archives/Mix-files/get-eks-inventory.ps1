# EKS Cluster Inventory Script for All AWS Accounts
# Collects EKS clusters, node groups, and configuration details

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
$clusterResults = @()
$nodeGroupResults = @()

Write-Host "Starting EKS cluster inventory collection across all accounts..." -ForegroundColor Green

foreach ($account in $accounts) {
    Write-Host "`nProcessing Account: $($account.Name) ($($account.Id))" -ForegroundColor Cyan
    
    foreach ($region in $regions) {
        try {
            # List EKS clusters
            $clusterNames = aws eks list-clusters --region $region --query 'clusters[]' --output json 2>$null | ConvertFrom-Json
            
            if ($clusterNames -and $clusterNames.Count -gt 0) {
                Write-Host "  Found $($clusterNames.Count) EKS cluster(s) in $region" -ForegroundColor Yellow
                
                foreach ($clusterName in $clusterNames) {
                    # Get cluster details
                    $clusterDetail = aws eks describe-cluster --region $region --name $clusterName --query 'cluster' --output json 2>$null | ConvertFrom-Json
                    
                    if ($clusterDetail) {
                        $clusterResults += [PSCustomObject]@{
                            AccountId = $account.Id
                            AccountName = $account.Name
                            Region = $region
                            ClusterName = $clusterDetail.name
                            Status = $clusterDetail.status
                            Version = $clusterDetail.version
                            Endpoint = $clusterDetail.endpoint
                            PlatformVersion = $clusterDetail.platformVersion
                            RoleArn = $clusterDetail.roleArn
                            VpcId = $clusterDetail.resourcesVpcConfig.vpcId
                            SubnetIds = ($clusterDetail.resourcesVpcConfig.subnetIds -join '; ')
                            SecurityGroupIds = ($clusterDetail.resourcesVpcConfig.securityGroupIds -join '; ')
                            EndpointPublicAccess = $clusterDetail.resourcesVpcConfig.endpointPublicAccess
                            EndpointPrivateAccess = $clusterDetail.resourcesVpcConfig.endpointPrivateAccess
                            CreatedAt = $clusterDetail.createdAt
                            LoggingEnabled = if ($clusterDetail.logging.clusterLogging[0].enabled) { 'Yes' } else { 'No' }
                            EncryptionEnabled = if ($clusterDetail.encryptionConfig) { 'Yes' } else { 'No' }
                        }
                        
                        # Get node groups for this cluster
                        $nodeGroups = aws eks list-nodegroups --region $region --cluster-name $clusterName --query 'nodegroups[]' --output json 2>$null | ConvertFrom-Json
                        
                        if ($nodeGroups -and $nodeGroups.Count -gt 0) {
                            Write-Host "    Found $($nodeGroups.Count) node group(s) in cluster: $clusterName" -ForegroundColor Gray
                            
                            foreach ($nodeGroupName in $nodeGroups) {
                                $nodeGroupDetail = aws eks describe-nodegroup --region $region --cluster-name $clusterName --nodegroup-name $nodeGroupName --query 'nodegroup' --output json 2>$null | ConvertFrom-Json
                                
                                if ($nodeGroupDetail) {
                                    $nodeGroupResults += [PSCustomObject]@{
                                        AccountId = $account.Id
                                        AccountName = $account.Name
                                        Region = $region
                                        ClusterName = $clusterName
                                        NodeGroupName = $nodeGroupDetail.nodegroupName
                                        Status = $nodeGroupDetail.status
                                        InstanceTypes = ($nodeGroupDetail.instanceTypes -join ', ')
                                        AmiType = $nodeGroupDetail.amiType
                                        DesiredSize = $nodeGroupDetail.scalingConfig.desiredSize
                                        MinSize = $nodeGroupDetail.scalingConfig.minSize
                                        MaxSize = $nodeGroupDetail.scalingConfig.maxSize
                                        DiskSize = $nodeGroupDetail.diskSize
                                        CapacityType = $nodeGroupDetail.capacityType
                                        NodeRole = $nodeGroupDetail.nodeRole
                                        SubnetIds = ($nodeGroupDetail.subnets -join '; ')
                                        CreatedAt = $nodeGroupDetail.createdAt
                                        Version = $nodeGroupDetail.version
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            Write-Host "  Error querying $region : $_" -ForegroundColor Red
        }
    }
}

Write-Host "`n`n========== EKS INVENTORY SUMMARY ==========" -ForegroundColor Green
Write-Host "Total EKS Clusters Found: $($clusterResults.Count)" -ForegroundColor Cyan
Write-Host "Total Node Groups Found: $($nodeGroupResults.Count)" -ForegroundColor Cyan

if ($clusterResults.Count -gt 0) {
    # Export cluster details
    $clusterResults | Export-Csv -Path "eks-clusters-all-accounts.csv" -NoTypeInformation
    Write-Host "`nCluster Status Breakdown:" -ForegroundColor Yellow
    $clusterResults | Group-Object Status | ForEach-Object {
        Write-Host "  $($_.Name): $($_.Count)" -ForegroundColor White
    }
    
    Write-Host "`nCluster Version Breakdown:" -ForegroundColor Yellow
    $clusterResults | Group-Object Version | ForEach-Object {
        Write-Host "  Version $($_.Name): $($_.Count)" -ForegroundColor White
    }
}

if ($nodeGroupResults.Count -gt 0) {
    # Export node group details
    $nodeGroupResults | Export-Csv -Path "eks-nodegroups-all-accounts.csv" -NoTypeInformation
    
    Write-Host "`nNode Group Summary:" -ForegroundColor Yellow
    $totalNodes = ($nodeGroupResults | Measure-Object DesiredSize -Sum).Sum
    Write-Host "  Total Desired Nodes: $totalNodes" -ForegroundColor White
    Write-Host "  Total Min Nodes: $(($nodeGroupResults | Measure-Object MinSize -Sum).Sum)" -ForegroundColor White
    Write-Host "  Total Max Nodes: $(($nodeGroupResults | Measure-Object MaxSize -Sum).Sum)" -ForegroundColor White
    
    Write-Host "`nInstance Types Used:" -ForegroundColor Yellow
    $nodeGroupResults | ForEach-Object { $_.InstanceTypes } | Sort-Object -Unique | ForEach-Object {
        Write-Host "  $_" -ForegroundColor White
    }
    
    Write-Host "`nCapacity Type Breakdown:" -ForegroundColor Yellow
    $nodeGroupResults | Group-Object CapacityType | ForEach-Object {
        Write-Host "  $($_.Name): $($_.Count) node group(s)" -ForegroundColor White
    }
    
    # Create summary by account
    $accountSummary = $clusterResults | Group-Object AccountName | ForEach-Object {
        $accountClusters = $_.Group
        $accountNodeGroups = $nodeGroupResults | Where-Object AccountName -eq $_.Name
        [PSCustomObject]@{
            AccountName = $_.Name
            AccountId = $accountClusters[0].AccountId
            TotalClusters = $accountClusters.Count
            TotalNodeGroups = $accountNodeGroups.Count
            TotalDesiredNodes = ($accountNodeGroups | Measure-Object DesiredSize -Sum).Sum
            ActiveClusters = ($accountClusters | Where-Object Status -eq 'ACTIVE').Count
        }
    }
    
    $accountSummary | Export-Csv -Path "eks-summary-by-account.csv" -NoTypeInformation
}

Write-Host "`nFiles Generated:" -ForegroundColor Cyan
if ($clusterResults.Count -gt 0) {
    Write-Host "  1. eks-clusters-all-accounts.csv - All EKS cluster details"
}
if ($nodeGroupResults.Count -gt 0) {
    Write-Host "  2. eks-nodegroups-all-accounts.csv - All node group details"
    Write-Host "  3. eks-summary-by-account.csv - Summary by account"
}
if ($clusterResults.Count -eq 0) {
    Write-Host "  No EKS clusters found in any account" -ForegroundColor Yellow
}
Write-Host "===============================================`n" -ForegroundColor Green
