# Azure WAF Test - Connection Script
# This script connects to Azure and sets up the subscription

Write-Host "=== Azure Connection Setup ===" -ForegroundColor Cyan
Write-Host ""

# Connect to Azure
Write-Host "Connecting to Azure..." -ForegroundColor Green
Write-Host "A browser window will open for authentication." -ForegroundColor Yellow
Write-Host ""

try {
    Connect-AzAccount -ErrorAction Stop
    Write-Host "Successfully connected to Azure" -ForegroundColor Green
}
catch {
    Write-Host "Failed to connect to Azure" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# List available subscriptions
Write-Host "Available Subscriptions:" -ForegroundColor Green
$subscriptions = Get-AzSubscription
$subscriptions | Format-Table -Property Name, Id, State -AutoSize

# Select subscription
if ($subscriptions.Count -gt 1) {
    Write-Host ""
    Write-Host "Multiple subscriptions found." -ForegroundColor Yellow
    $subId = Read-Host "Enter Subscription ID to use"
    Set-AzContext -SubscriptionId $subId
}
else {
    $subId = $subscriptions[0].Id
    Set-AzContext -SubscriptionId $subId
}

# Display current context
Write-Host ""
Write-Host "Current Azure Context:" -ForegroundColor Green
$context = Get-AzContext
Write-Host "  Subscription: $($context.Subscription.Name)" -ForegroundColor White
Write-Host "  Account: $($context.Account.Id)" -ForegroundColor White
Write-Host "  Tenant: $($context.Tenant.Id)" -ForegroundColor White

Write-Host ""
Write-Host "=== Connection Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next step: Run .\03-deploy-test-workload.ps1 to create test resources" -ForegroundColor Yellow
