# EC2 Inventory Script for All AWS Accounts
# Collects EC2 instances, types, commitment, and estimated costs

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

Write-Host "Starting EC2 inventory collection across all accounts..." -ForegroundColor Green

foreach ($account in $accounts) {
    Write-Host "`nProcessing Account: $($account.Name) ($($account.Id))" -ForegroundColor Cyan
    
    foreach ($region in $regions) {
        try {
            $instances = aws ec2 describe-instances --region $region --query 'Reservations[].Instances[].[InstanceId,InstanceType,State.Name,Platform,PrivateIpAddress,Tags[?Key==`Name`].Value|[0],InstanceLifecycle]' --output json 2>$null | ConvertFrom-Json
            
            if ($instances -and $instances.Count -gt 0) {
                foreach ($instance in $instances) {
                    $results += [PSCustomObject]@{
                        AccountId = $account.Id
                        AccountName = $account.Name
                        Region = $region
                        InstanceId = $instance[0]
                        InstanceType = $instance[1]
                        State = $instance[2]
                        Platform = if ($instance[3]) { $instance[3] } else { 'Linux' }
                        PrivateIP = $instance[4]
                        Name = if ($instance[5]) { $instance[5] } else { 'N/A' }
                        Lifecycle = if ($instance[6]) { $instance[6] } else { 'on-demand' }
                    }
                }
                Write-Host "  Found $($instances.Count) instances in $region" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "  Error querying $region : $_" -ForegroundColor Red
        }
    }
}

Write-Host "`n`nTotal instances found: $($results.Count)" -ForegroundColor Green
Write-Host "Exporting to CSV..." -ForegroundColor Green

$results | Export-Csv -Path "ec2-inventory-all-accounts.csv" -NoTypeInformation

Write-Host "Export complete: ec2-inventory-all-accounts.csv" -ForegroundColor Green
