# Azure WAF Test - Retry Failed Resources
# This script retries creating resources that failed due to unregistered providers

Write-Host "=== Retrying Failed Resources ===" -ForegroundColor Cyan
Write-Host ""

# Check provider registration status
Write-Host "Checking resource provider registration..." -ForegroundColor Yellow
$storageProvider = Get-AzResourceProvider -ProviderNamespace Microsoft.Storage | Select-Object -First 1
$webProvider = Get-AzResourceProvider -ProviderNamespace Microsoft.Web | Select-Object -First 1

Write-Host "  Microsoft.Storage: $($storageProvider.RegistrationState)" -ForegroundColor White
Write-Host "  Microsoft.Web: $($webProvider.RegistrationState)" -ForegroundColor White
Write-Host ""

if ($storageProvider.RegistrationState -ne "Registered") {
    Write-Host "Microsoft.Storage is still registering. This may take a few minutes." -ForegroundColor Yellow
    Write-Host "You can run this script again in 2-3 minutes." -ForegroundColor Yellow
    Write-Host ""
}

# Configuration
$resourceGroupName = "rg-waf-test"
$location = "eastus"
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$storageAccountName = "stwaftest$timestamp".ToLower().Substring(0, [Math]::Min(24, "stwaftest$timestamp".Length))
$appServicePlanName = "asp-waf-test"
$webAppName = "webapp-waf-test-$timestamp"

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Resource Group: $resourceGroupName" -ForegroundColor White
Write-Host "  Storage Account: $storageAccountName" -ForegroundColor White
Write-Host "  App Service Plan: $appServicePlanName" -ForegroundColor White
Write-Host "  Web App: $webAppName" -ForegroundColor White
Write-Host ""

# Create Storage Account
Write-Host "Creating Storage Account..." -ForegroundColor Green
try {
    $storage = New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -Location $location -SkuName Standard_LRS -Kind StorageV2 -AccessTier Hot -ErrorAction Stop
    Write-Host "  SUCCESS: Storage Account created: $($storage.StorageAccountName)" -ForegroundColor Green
}
catch {
    Write-Host "  FAILED: Could not create Storage Account" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
}

# Create App Service Plan
Write-Host "Creating App Service Plan..." -ForegroundColor Green
try {
    $appPlan = New-AzAppServicePlan -ResourceGroupName $resourceGroupName -Name $appServicePlanName -Location $location -Tier Free -ErrorAction Stop
    Write-Host "  SUCCESS: App Service Plan created: $($appPlan.Name)" -ForegroundColor Green
}
catch {
    Write-Host "  FAILED: Could not create App Service Plan" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
}

# Create Web App
Write-Host "Creating Web App..." -ForegroundColor Green
try {
    $webapp = New-AzWebApp -ResourceGroupName $resourceGroupName -Name $webAppName -Location $location -AppServicePlan $appServicePlanName -ErrorAction Stop
    Write-Host "  SUCCESS: Web App created: $($webapp.DefaultHostName)" -ForegroundColor Green
}
catch {
    Write-Host "  FAILED: Could not create Web App" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Retry Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Check created resources:" -ForegroundColor Yellow
Get-AzResource -ResourceGroupName $resourceGroupName | Format-Table -Property Name, ResourceType, Location

Write-Host ""
Write-Host "Next step: Wait 24 hours, then run .\05-get-waf-recommendations.ps1" -ForegroundColor Yellow
