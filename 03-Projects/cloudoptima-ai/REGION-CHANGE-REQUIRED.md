# CloudOptima AI - Region Change Required

## Issue

Your Azure subscription has a quota restriction for PostgreSQL Flexible Server in the `eastus` region.

**Error:** "Subscriptions are restricted from provisioning in location 'eastus'"

## Solution

We need to change the deployment region to `westus2` (or another available region).

## Current Status

✅ Resources already created in `eastus`:
- Resource Group: cloudoptima-rg
- Virtual Network
- Subnets
- Network Security Group
- Public IPs
- Container Registry: cloudoptimaacrxmln4y
- Redis Cache (took 15 minutes to create!)
- Key Vault with secrets
- Log Analytics Workspace

❌ Not yet created:
- PostgreSQL Flexible Server (blocked by quota)
- Container Instances (4)

## Options

### Option 1: Destroy and Recreate in New Region (Recommended)

This will delete all existing resources and recreate them in `westus2`.

```powershell
cd 03-Projects\cloudoptima-ai\terraform

# Destroy existing resources
terraform destroy -auto-approve

# Deploy in new region (westus2)
terraform apply -auto-approve
```

**Time:** ~30 minutes (Redis takes 15 minutes)
**Cost:** No additional cost, just redeployment

### Option 2: Request Quota Increase for eastus

Follow Azure's process to request quota increase:
https://aka.ms/postgres-request-quota-increase

**Time:** 1-3 business days
**Complexity:** Requires support ticket

### Option 3: Keep Existing Resources, Deploy Database Separately

Keep the existing resources in `eastus` and try to deploy just the database in a different region.

**Not Recommended:** Cross-region latency and complexity

## Recommended Action

**Destroy and recreate in westus2:**

```powershell
cd 03-Projects\cloudoptima-ai\terraform

# Destroy all resources
terraform destroy -auto-approve

# Apply in new region
terraform apply -auto-approve
```

## What's Been Updated

I've already updated the configuration files:
- ✅ `variables.tf` - Changed default location to `westus2`
- ✅ `terraform.tfvars` - Changed location to `westus2`

## After Region Change

Once deployed in `westus2`, you'll need to:

1. **Build and push Docker images** (if Docker is installed)
2. **Initialize database** with TimescaleDB
3. **Access application** via new URLs

## Alternative Regions

If `westus2` also has restrictions, try these regions:
- `centralus`
- `westeurope`
- `northeurope`
- `southeastasia`

To change region, edit `terraform/terraform.tfvars`:
```hcl
location = "centralus"  # or another region
```

## Cost Impact

Destroying and recreating resources:
- **No additional cost** - You only pay for active resources
- Redis cache creation time: ~15 minutes
- Total deployment time: ~30 minutes

## Commands Summary

```powershell
# Navigate to terraform directory
cd 03-Projects\cloudoptima-ai\terraform

# Option 1: Destroy and recreate (recommended)
terraform destroy -auto-approve
terraform apply -auto-approve

# Option 2: Just try westus2 without destroying first
# (This will fail because resource group already exists in eastus)
terraform apply -auto-approve

# Check what will be destroyed
terraform plan -destroy
```

## Next Steps

1. Decide on approach (destroy and recreate recommended)
2. Run terraform destroy
3. Run terraform apply
4. Wait ~30 minutes for deployment
5. Build and push Docker images
6. Initialize database
7. Access application

---

**Recommendation:** Go with Option 1 (destroy and recreate in westus2). It's the fastest and cleanest solution.

