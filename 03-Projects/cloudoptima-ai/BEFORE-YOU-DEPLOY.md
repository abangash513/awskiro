# ⚠️ Before You Deploy - Important Checks (POC Version)

## Critical Items to Update

### 1. Terraform Variables ⚠️

**File**: `terraform/terraform.tfvars`

You need to create this file from the example:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Then edit `terraform.tfvars` with your values:

```hcl
# Required
azure_tenant_id     = "your-tenant-id-here"
azure_client_id     = "your-client-id-here"
azure_client_secret = "your-client-secret-here"

# Optional (defaults are fine)
prefix              = "cloudoptima"
resource_group_name = "cloudoptima-rg"
location            = "eastus"  # Must be eastus!
db_admin_username   = "cloudoptima"
db_name             = "cloudoptima"
```

**How to get Azure credentials**:

```bash
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Create service principal
az ad sp create-for-rbac \
  --name "cloudoptima-sp" \
  --role="Contributor" \
  --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID"
```

This outputs:
```json
{
  "appId": "xxx",        # This is client_id
  "password": "xxx",     # This is client_secret
  "tenant": "xxx"        # This is tenant_id
}
```

---

### 2. SSH Key (OPTIONAL for POC) ✅

**Good News**: For POC, SSH keys are NOT required!

The VM is configured with password authentication for easier access. Terraform will generate a random password automatically.

If you prefer SSH keys, you can add them later or modify `terraform/vm.tf`.

---

### 3. Repository URL (Optional)

**File**: `scripts/vm-setup.sh` (line 15)

```bash
REPO_URL="https://github.com/yourusername/cloudoptima-ai.git"  # ⚠️ UPDATE THIS
```

**Action**: If you want to clone from Git, update this URL.

Otherwise, you'll upload code manually via SCP (documented in deployment guide).

---

## Verification Checklist

Before running `terraform apply`, verify:

### Azure Account
- [ ] Azure free tier account active
- [ ] Subscription has free tier services available
- [ ] Region is set to `eastus` (not eastus2)
- [ ] Service principal created with Contributor role

### Local Tools
- [ ] Terraform >= 1.0 installed (`terraform --version`)
- [ ] Azure CLI installed (`az --version`)
- [ ] Logged into Azure CLI (`az account show`)
- [ ] Node.js 18+ installed (`node --version`)
- [ ] SSH client available (built-in on Linux/Mac, PuTTY on Windows)

### Configuration Files
- [ ] `terraform/terraform.tfvars` created and filled
- [ ] Azure credentials verified (tenant_id, client_id, client_secret)
- [ ] Region set to `eastus` (not eastus2)

### Code Preparation
- [ ] Backend code ready in `backend/` directory
- [ ] Frontend code ready in `frontend/` directory
- [ ] `backend/requirements.txt` cleaned (no SQL Server deps)

---

## Quick Pre-Flight Test

Run these commands to verify everything is ready:

```bash
# 1. Check Terraform
terraform --version

# 2. Check Azure CLI
az account show

# 3. Check Node.js
node --version

# 4. Validate Terraform config
cd 03-Projects/cloudoptima-ai/terraform
terraform init
terraform validate

# 5. Check for syntax errors
terraform fmt -check
```

All should pass without errors.

---

## Common Issues

### Issue: "Can't connect to VM"

**Solution**: Get password from Terraform:
```bash
cd terraform
terraform output vm_password
# Use this password when SSH prompts for it
```

### Issue: "Azure credentials not found"

**Solution**: Create service principal:
```bash
az login
az ad sp create-for-rbac --name "cloudoptima-sp" --role="Contributor"
```

### Issue: "Region not supported"

**Solution**: Ensure `location = "eastus"` in terraform.tfvars (NOT eastus2)

### Issue: "Terraform validation failed"

**Solution**: Check terraform.tfvars has all required variables:
- azure_tenant_id
- azure_client_id
- azure_client_secret

---

## Estimated Costs

### During Free Tier (12 months)
- B1S VM: $0 (750 hours/month FREE)
- PostgreSQL B1MS: $0 (750 hours/month FREE)
- App Service F1: $0 (always FREE)
- VNet: $0 (always FREE)
- **Total: $0/month**

### After Free Tier
- B1S VM: ~$10/month
- PostgreSQL B1MS: ~$15/month
- App Service F1: $0 (always FREE)
- VNet: $0 (always FREE)
- **Total: ~$26/month**

---

## What Happens During Deployment

### Phase 1: Terraform (15 min)
1. Creates resource group
2. Creates virtual network
3. Creates B1S VM (takes ~5 min)
4. Creates PostgreSQL B1MS (takes ~10 min) ⏰ SLOWEST
5. Creates App Service F1
6. Configures networking and firewall

### Phase 2: VM Setup (30 min)
1. Cloud-init runs (installs Docker, Python, etc.)
2. You SSH in and upload code
3. Run vm-setup.sh script
4. Installs Python dependencies
5. Starts Redis container
6. Creates systemd services
7. Starts all services
8. Runs database migrations

### Phase 3: Frontend (15 min)
1. Build React app locally
2. Create ZIP package
3. Deploy to App Service
4. Configure environment variables

### Phase 4: Testing (15 min)
1. Test backend health endpoint
2. Test frontend loads
3. Test frontend → backend communication
4. Test database connectivity
5. Test Celery tasks
6. Monitor memory usage

**Total: ~75 minutes**

---

## Rollback Plan

If something goes wrong:

```bash
# Destroy everything
cd terraform
terraform destroy

# This will delete:
# - VM
# - PostgreSQL (and all data!)
# - App Service
# - All networking

# Cost: $0 (nothing running)
```

Then you can start over.

---

## Ready to Deploy?

If all checks pass:

1. ✅ Terraform variables set
2. ✅ Azure credentials verified
3. ✅ Tools installed
4. ✅ Code prepared

**Then proceed to**: `DEPLOYMENT-GUIDE-OPTION1.md`

**Note**: SSH keys are NOT required for POC. VM uses password authentication.

---

## Need Help?

- **Terraform errors**: Check `terraform validate` output
- **Azure errors**: Check `az account show` and service principal
- **SSH errors**: Check `~/.ssh/id_rsa.pub` exists
- **Cost concerns**: Monitor Azure Portal → Cost Management

---

**Good luck! 🚀**
