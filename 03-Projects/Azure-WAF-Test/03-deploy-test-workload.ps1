# Azure WAF Test - Deploy Test Workload
# This script creates a simple test workload for WAF assessment

Write-Host "=== Deploying Test Workload ===" -ForegroundColor Cyan
Write-Host ""

# Configuration
$resourceGroupName = "rg-waf-test"
$location = "eastus"
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$storageAccountName = "stwaftest$timestamp".ToLower().Substring(0, [Math]::Min(24, "stwaftest$timestamp".Length))
$appServicePlanName = "asp-waf-test"
$webAppName = "webapp-waf-test-$timestamp"
$vnetName = "vnet-waf-test"

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Resource Group: $resourceGroupName" -ForegroundColor White
Write-Host "  Location: $location" -ForegroundColor White
Write-Host "  Storage Account: $storageAccountName" -ForegroundColor White
Write-Host "  Web App: $webAppName" -ForegroundColor White
Write-Host ""

# Create Resource Group
Write-Host "Creating Resource Group..." -ForegroundColor Green
try {
    $rg = New-AzResourceGroup -Name $resourceGroupName -Location $location -Force
    Write-Host "  Resource Group created: $($rg.ResourceGroupName)" -ForegroundColor Green
}
catch {
    Write-Host "  Failed to create Resource Group" -ForegroundColor Red
    Write-Host "    Error: $_" -ForegroundColor Red
    exit 1
}

# Create Virtual Network
Write-Host "Creating Virtual Network..." -ForegroundColor Green
try {
    $subnet = New-AzVirtualNetworkSubnetConfig -Name "default" -AddressPrefix "10.0.0.0/24"
    $vnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix "10.0.0.0/16" -Subnet $subnet
    Write-Host "  Virtual Network created: $($vnet.Name)" -ForegroundColor Green
}
catch {
    Write-Host "  Failed to create Virtual Network" -ForegroundColor Red
    Write-Host "    Error: $_" -ForegroundColor Red
}

# Create Storage Account
Write-Host "Creating Storage Account..." -ForegroundColor Green
try {
    $storage = New-AzStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -Location $location -SkuName Standard_LRS -Kind StorageV2 -AccessTier Hot
    Write-Host "  Storage Account created: $($storage.StorageAccountName)" -ForegroundColor Green
}
catch {
    Write-Host "  Failed to create Storage Account" -ForegroundColor Red
    Write-Host "    Error: $_" -ForegroundColor Red
}

# Create App Service Plan
Write-Host "Creating App Service Plan..." -ForegroundColor Green
try {
    $appPlan = New-AzAppServicePlan -ResourceGroupName $resourceGroupName -Name $appServicePlanName -Location $location -Tier Basic -NumberofWorkers 1 -WorkerSize Small
    Write-Host "  App Service Plan created: $($appPlan.Name)" -ForegroundColor Green
}
catch {
    Write-Host "  Failed to create App Service Plan" -ForegroundColor Red
    Write-Host "    Error: $_" -ForegroundColor Red
}

# Create Web App
Write-Host "Creating Web App..." -ForegroundColor Green
try {
    $webapp = New-AzWebApp -ResourceGroupName $resourceGroupName -Name $webAppName -Location $location -AppServicePlan $appServicePlanName
    Write-Host "  Web App created: $($webapp.DefaultHostName)" -ForegroundColor Green
}
catch {
    Write-Host "  Failed to create Web App" -ForegroundColor Red
    Write-Host "    Error: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Deployment Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Resources created in Resource Group: $resourceGroupName" -ForegroundColor Green
Write-Host ""
Write-Host "Note: Azure Advisor needs 24 hours to analyze resources." -ForegroundColor Yellow
Write-Host "You can still run the WAF assessment, but recommendations may be limited." -ForegroundColor Yellow
Write-Host ""
Write-Host "Next step: Run .\05-get-waf-recommendations.ps1 to get recommendations" -ForegroundColor Yellow
