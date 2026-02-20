# Azure Well-Architected Framework Test Setup Guide

## Prerequisites
- Azure account created (https://azure.microsoft.com/free/)
- PowerShell 7+ installed
- Internet connection for authentication

## Step 1: Initial Azure Setup

### 1.1 Install Required PowerShell Modules
```powershell
# Run the setup script
.\01-install-azure-modules.ps1
```

### 1.2 Connect to Azure
```powershell
# Run the connection script
.\02-connect-azure.ps1
```

This will:
- Open a browser for authentication
- List your subscriptions
- Set the default subscription

## Step 2: Deploy Test Workload

### 2.1 Create Test Resources
```powershell
# Deploy a simple test workload
.\03-deploy-test-workload.ps1
```

This creates:
- Resource Group: `rg-waf-test`
- Virtual Network
- Storage Account
- App Service Plan
- Web App

### 2.2 Verify Deployment
```powershell
# Check resources
.\04-verify-deployment.ps1
```

## Step 3: Run Well-Architected Review

### 3.1 Get Azure Advisor Recommendations
```powershell
# Get all recommendations
.\05-get-waf-recommendations.ps1
```

### 3.2 Generate WAF Report
```powershell
# Create detailed report
.\06-generate-waf-report.ps1
```

## Step 4: Review Results

Check the generated files:
- `azure-advisor-recommendations.csv` - Raw recommendations
- `waf-assessment-report.html` - Formatted report
- `waf-summary.json` - Summary statistics

## Step 5: Cleanup (Optional)

```powershell
# Remove all test resources
.\07-cleanup-resources.ps1
```

## Troubleshooting

### Issue: Cannot connect to Azure
**Solution:** Ensure you're using PowerShell 7+ and have internet access

### Issue: No recommendations found
**Solution:** Wait 24 hours after resource creation for Advisor to analyze

### Issue: Module installation fails
**Solution:** Run PowerShell as Administrator or use `-Scope CurrentUser`

## Next Steps

1. Review recommendations by category
2. Implement high-priority improvements
3. Re-run assessment to track progress
4. Compare with AWS WAFR results (if applicable)

## Resources

- Azure Well-Architected Framework: https://learn.microsoft.com/azure/well-architected/
- Azure Advisor: https://learn.microsoft.com/azure/advisor/
- WAF Review Tool: https://aka.ms/architecture/review
