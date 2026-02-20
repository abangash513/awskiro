# 🚀 Quick Start - POC Mode

## 5-Minute Overview

**What**: CloudOptima AI on Azure FREE tier
**Cost**: $0/month for 12 months
**Time**: 75 minutes deployment
**Mode**: POC (simplified security)

---

## Prerequisites Checklist

- [ ] Azure free tier account
- [ ] Terraform installed
- [ ] Azure CLI installed
- [ ] Node.js 18+ installed
- [ ] Azure Service Principal created

**No SSH keys needed!** ✅

---

## 4-Step Deployment

### Step 1: Configure (5 min)

```bash
cd 03-Projects/cloudoptima-ai/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your Azure credentials
```

### Step 2: Deploy (15 min)

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan

# Save credentials
terraform output vm_password > ../vm-password.txt
terraform output postgres_admin_password > ../db-password.txt
```

### Step 3: Setup VM (30 min)

```bash
# Get VM info
VM_FQDN=$(terraform output -raw vm_fqdn)

# Upload code
cd ..
tar -czf cloudoptima-backend.tar.gz backend/
scp cloudoptima-backend.tar.gz azureuser@$VM_FQDN:/tmp/

# SSH (use password from vm-password.txt)
ssh azureuser@$VM_FQDN

# On VM:
cd /opt/cloudoptima
sudo bash scripts/vm-setup.sh
```

### Step 4: Deploy Frontend (15 min)

```bash
# On local machine
cd frontend
npm install
export REACT_APP_API_URL="http://$VM_FQDN:8000"
npm run build

# Deploy to App Service
cd build
zip -r ../frontend-build.zip .
az webapp deployment source config-zip \
  --resource-group cloudoptima-rg \
  --name $(cd ../terraform && terraform output -raw frontend_url | cut -d'/' -f3 | cut -d'.' -f1) \
  --src ../frontend-build.zip
```

---

## Test It

```bash
# Backend health
curl http://$VM_FQDN:8000/health

# Frontend
FRONTEND_URL=$(cd terraform && terraform output -raw frontend_url)
echo "Open: $FRONTEND_URL"
```

---

## Important Commands

### Get Credentials
```bash
cd terraform
terraform output vm_password
terraform output postgres_admin_password
terraform output database_url
```

### SSH to VM
```bash
ssh azureuser@$(cd terraform && terraform output -raw vm_fqdn)
# Use password from: terraform output vm_password
```

### Check Services
```bash
# On VM
sudo systemctl status backend celery-worker celery-beat
sudo journalctl -u backend -f
free -h
```

### Connect to Database
```bash
# From anywhere (database is open to all IPs)
psql "$(cd terraform && terraform output -raw database_url)"
```

---

## Troubleshooting

### Can't SSH?
```bash
# Get password
cd terraform
terraform output vm_password
```

### Services not running?
```bash
# On VM
sudo systemctl restart backend celery-worker celery-beat
sudo journalctl -u backend -n 50
```

### Out of memory?
```bash
# On VM
free -h
sudo systemctl restart celery-beat
sudo systemctl restart celery-worker
sudo systemctl restart backend
```

---

## Cost Verification

```bash
# Check Azure Portal
# Cost Management → Cost Analysis
# Filter: Resource Group = cloudoptima-rg
# Should show: $0
```

---

## Cleanup

```bash
cd terraform
terraform destroy
# Type: yes
```

---

## Documentation

- **Start**: `START-HERE.md`
- **Security**: `POC-SIMPLIFICATIONS.md`
- **Full Guide**: `DEPLOYMENT-GUIDE-OPTION1.md`
- **Troubleshooting**: See deployment guide

---

## POC Mode Features

✅ Password authentication (no SSH keys)
✅ Database open to all IPs (easy testing)
✅ Simplified setup (fewer steps)
⚠️ Less secure (fine for POC)

---

## Success Criteria

- [ ] VM accessible via SSH
- [ ] Backend responds: `curl http://VM_FQDN:8000/health`
- [ ] Frontend loads in browser
- [ ] Cost is $0 in Azure Portal
- [ ] Memory < 900 MB: `free -h`

---

**Time**: 75 minutes
**Cost**: $0/month
**Difficulty**: Easy

🚀 **Ready to deploy!**
