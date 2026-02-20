# Azure Well-Architected Framework (WAF) Test Project

This project provides a complete setup for testing Azure's Well-Architected Framework assessment capabilities.

## Quick Start

### 1. Create Azure Account
- Visit: https://azure.microsoft.com/free/
- Sign up for free account ($200 credit + 12 months free services)
- Complete verification process

### 2. Run Setup Scripts (in order)

```powershell
# Install required modules
.\01-install-azure-modules.ps1

# Connect to Azure (opens browser for auth)
.\02-connect-azure.ps1

# Deploy test workload
.\03-deploy-test-workload.ps1

# Get WAF recommendations (wait 24h for best results)
.\05-get-waf-recommendations.ps1

# Generate HTML report
.\06-generate-waf-report.ps1

# Cleanup when done
.\07-cleanup-resources.ps1
```

## What Gets Created

The test deployment creates:
- Resource Group: `rg-waf-test`
- Virtual Network with subnet
- Storage Account (Standard LRS)
- App Service Plan (Basic tier)
- Web App

Total estimated cost: ~$15-20/month (covered by free credits)

## Azure Well-Architected Framework

Azure WAF is based on 5 pillars:

1. **Cost Optimization** - Manage costs and maximize value
2. **Operational Excellence** - Operations processes that keep systems running
3. **Performance Efficiency** - Ability to scale and adapt to load
4. **Reliability** - Ability to recover from failures
5. **Security** - Protect applications and data

## Output Files

All reports are saved to `./Reports/`:
- `azure-advisor-recommendations-[timestamp].csv` - Raw data
- `waf-assessment-report-[timestamp].html` - Formatted report
- `waf-summary-[timestamp].json` - Summary statistics

## Important Notes

- **24-Hour Wait**: Azure Advisor needs 24 hours after resource creation to provide comprehensive recommendations
- **Free Tier**: All resources use free/low-cost tiers
- **Cleanup**: Always run cleanup script to avoid charges
- **Authentication**: Browser-based auth required (can't be automated)

## Comparison with AWS WAFR

| Feature | AWS WAFR | Azure WAF |
|---------|----------|-----------|
| Pillars | 6 | 5 |
| Tool | AWS Console | Azure Portal / Advisor |
| API Access | Yes | Yes (PowerShell/CLI) |
| Cost | Free | Free |
| Partner Reviews | Available | Available |

## Troubleshooting

### No recommendations found
- Wait 24 hours after resource creation
- Ensure resources are running (not stopped)
- Check Azure Advisor in portal

### Authentication fails
- Ensure PowerShell 7+ is installed
- Check internet connection
- Try clearing browser cache

### Module installation fails
- Run PowerShell as Administrator
- Or use `-Scope CurrentUser` flag

## Resources

- [Azure WAF Documentation](https://learn.microsoft.com/azure/well-architected/)
- [Azure Advisor](https://learn.microsoft.com/azure/advisor/)
- [WAF Review Tool](https://aka.ms/architecture/review)
- [Azure Free Account](https://azure.microsoft.com/free/)

## Next Steps

1. Create Azure account
2. Run setup scripts
3. Wait 24 hours
4. Review recommendations
5. Compare with AWS WAFR results (if applicable)
6. Implement improvements
7. Re-assess to track progress
