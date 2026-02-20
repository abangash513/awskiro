# Azure WAF Test - Cleanup Resources
# This script removes all test resources created for WAF assessment

Write-Host "=== Cleanup Test Resources ===" -ForegroundColor Cyan
Write-Host ""

$resourceGroupName = "rg-waf-test"

# Confirm deletion
Write-Host "WARNING: This will delete the following:" -ForegroundColor Yellow
Write-Host "  • Resource Group: $resourceGroupName" -ForegroundColor White
Write-Host "  • All resources within the resource group" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "Are you sure you want to continue? (yes/no)"

if ($confirm -ne "yes") {
    Write-Host "Cleanup cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Deleting Resource Group: $resourceGroupName..." -ForegroundColor Green
Write-Host "This may take several minutes..." -ForegroundColor Yellow

try {
    Remove-AzResourceGroup -Name $resourceGroupName -Force -AsJob | Out-Null
    Write-Host "✓ Deletion initiated (running in background)" -ForegroundColor Green
    Write-Host ""
    Write-Host "To check deletion status, run:" -ForegroundColor Yellow
    Write-Host "  Get-AzResourceGroup -Name $resourceGroupName" -ForegroundColor White
}
catch {
    Write-Host "✗ Failed to delete Resource Group" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "You can manually delete from Azure Portal:" -ForegroundColor Yellow
    Write-Host "  https://portal.azure.com/#blade/HubsExtension/BrowseResourceGroups" -ForegroundColor White
}

Write-Host ""
Write-Host "=== Cleanup Complete ===" -ForegroundColor Cyan
