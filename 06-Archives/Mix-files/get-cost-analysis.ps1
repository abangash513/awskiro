# AWS Cost Analysis Script for All Accounts
# Analyzes actual spending across all services and accounts

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

# Get current month dates
$endDate = Get-Date -Format "yyyy-MM-dd"
$startDate = (Get-Date).AddDays(-30).ToString("yyyy-MM-dd")

Write-Host "Analyzing AWS costs from $startDate to $endDate..." -ForegroundColor Green
Write-Host "This may take a few minutes...`n" -ForegroundColor Yellow

$allCosts = @()
$serviceCosts = @()
$accountCosts = @()

try {
    # Get cost by service across all accounts
    Write-Host "Fetching cost breakdown by service..." -ForegroundColor Cyan
    $costByService = aws ce get-cost-and-usage `
        --time-period Start=$startDate,End=$endDate `
        --granularity MONTHLY `
        --metrics "UnblendedCost" `
        --group-by Type=DIMENSION,Key=SERVICE `
        --output json 2>$null | ConvertFrom-Json
    
    if ($costByService.ResultsByTime) {
        foreach ($result in $costByService.ResultsByTime) {
            foreach ($group in $result.Groups) {
                $service = $group.Keys[0]
                $cost = [math]::Round([decimal]$group.Metrics.UnblendedCost.Amount, 2)
                
                if ($cost -gt 0) {
                    $serviceCosts += [PSCustomObject]@{
                        Service = $service
                        MonthlyCost = $cost
                    }
                }
            }
        }
    }
    
    # Get cost by linked account
    Write-Host "Fetching cost breakdown by account..." -ForegroundColor Cyan
    $costByAccount = aws ce get-cost-and-usage `
        --time-period Start=$startDate,End=$endDate `
        --granularity MONTHLY `
        --metrics "UnblendedCost" `
        --group-by Type=DIMENSION,Key=LINKED_ACCOUNT `
        --output json 2>$null | ConvertFrom-Json
    
    if ($costByAccount.ResultsByTime) {
        foreach ($result in $costByAccount.ResultsByTime) {
            foreach ($group in $result.Groups) {
                $accountId = $group.Keys[0]
                $cost = [math]::Round([decimal]$group.Metrics.UnblendedCost.Amount, 2)
                
                # Find account name
                $accountName = ($accounts | Where-Object Id -eq $accountId).Name
                if (-not $accountName) { $accountName = "Unknown Account" }
                
                if ($cost -gt 0) {
                    $accountCosts += [PSCustomObject]@{
                        AccountId = $accountId
                        AccountName = $accountName
                        MonthlyCost = $cost
                    }
                }
            }
        }
    }
    
    # Get detailed cost by service and account
    Write-Host "Fetching detailed cost breakdown by service and account..." -ForegroundColor Cyan
    foreach ($account in $accounts) {
        try {
            $accountServiceCost = aws ce get-cost-and-usage `
                --time-period Start=$startDate,End=$endDate `
                --granularity MONTHLY `
                --metrics "UnblendedCost" `
                --filter "file://filter-$($account.Id).json" `
                --group-by Type=DIMENSION,Key=SERVICE `
                --output json 2>$null | ConvertFrom-Json
            
            if ($accountServiceCost.ResultsByTime) {
                foreach ($result in $accountServiceCost.ResultsByTime) {
                    foreach ($group in $result.Groups) {
                        $service = $group.Keys[0]
                        $cost = [math]::Round([decimal]$group.Metrics.UnblendedCost.Amount, 2)
                        
                        if ($cost -gt 0) {
                            $allCosts += [PSCustomObject]@{
                                AccountId = $account.Id
                                AccountName = $account.Name
                                Service = $service
                                MonthlyCost = $cost
                            }
                        }
                    }
                }
            }
        } catch {
            # Continue if account filtering fails
        }
    }
    
} catch {
    Write-Host "Error fetching cost data: $_" -ForegroundColor Red
}

# Sort and display results
Write-Host "`n========== AWS COST ANALYSIS SUMMARY ==========" -ForegroundColor Green

if ($serviceCosts.Count -gt 0) {
    $totalCost = ($serviceCosts | Measure-Object MonthlyCost -Sum).Sum
    Write-Host "`nTotal Monthly Cost (Last 30 Days): `$$totalCost" -ForegroundColor Cyan
    
    Write-Host "`n========== TOP 5 SERVICES BY COST ==========" -ForegroundColor Yellow
    $topServices = $serviceCosts | Sort-Object MonthlyCost -Descending | Select-Object -First 5
    $rank = 1
    foreach ($service in $topServices) {
        $percentage = [math]::Round(($service.MonthlyCost / $totalCost) * 100, 1)
        Write-Host "$rank. $($service.Service): `$$($service.MonthlyCost) ($percentage%)" -ForegroundColor White
        $rank++
    }
    
    # Export service costs
    $serviceCosts | Sort-Object MonthlyCost -Descending | Export-Csv -Path "aws-costs-by-service.csv" -NoTypeInformation
}

if ($accountCosts.Count -gt 0) {
    Write-Host "`n========== TOP 5 ACCOUNTS BY COST ==========" -ForegroundColor Yellow
    $topAccounts = $accountCosts | Sort-Object MonthlyCost -Descending | Select-Object -First 5
    $rank = 1
    foreach ($account in $topAccounts) {
        $percentage = [math]::Round(($account.MonthlyCost / $totalCost) * 100, 1)
        Write-Host "$rank. $($account.AccountName) ($($account.AccountId)): `$$($account.MonthlyCost) ($percentage%)" -ForegroundColor White
        $rank++
    }
    
    # Export account costs
    $accountCosts | Sort-Object MonthlyCost -Descending | Export-Csv -Path "aws-costs-by-account.csv" -NoTypeInformation
}

if ($allCosts.Count -gt 0) {
    # Export detailed costs
    $allCosts | Sort-Object MonthlyCost -Descending | Export-Csv -Path "aws-costs-detailed.csv" -NoTypeInformation
    
    Write-Host "`n========== TOP 10 SERVICE/ACCOUNT COMBINATIONS ==========" -ForegroundColor Yellow
    $topCombinations = $allCosts | Sort-Object MonthlyCost -Descending | Select-Object -First 10
    $rank = 1
    foreach ($combo in $topCombinations) {
        Write-Host "$rank. $($combo.Service) in $($combo.AccountName): `$$($combo.MonthlyCost)" -ForegroundColor White
        $rank++
    }
}

Write-Host "`nFiles Generated:" -ForegroundColor Cyan
Write-Host "  1. aws-costs-by-service.csv - Costs grouped by service"
Write-Host "  2. aws-costs-by-account.csv - Costs grouped by account"
if ($allCosts.Count -gt 0) {
    Write-Host "  3. aws-costs-detailed.csv - Detailed breakdown by service and account"
}
Write-Host "===============================================`n" -ForegroundColor Green
