# CloudOptima AI - Option 1 Deployment Guide
## TRUE FREE Hybrid Deployment (VM + App Service + PostgreSQL)

---

## Prerequisites

1. **Azure Account**
   - Azure free tier account
   - $200 credit (optional but helpful)
   - Subscription with free tier services available

2. **Local Tools**
   - Terraform >= 1.0
   - Azure CLI
   - Node.js 18+ (for frontend build)
   - Git
   - SSH client (PuTTY on Windows, or built-in terminal)

3. **Azure Service Principal**
   ```bash
   az login
   az account set --subscription "YOUR_SUBSCRIPTION_ID"
   az ad sp create-for-rbac --name "cloudoptima-sp" --role="Contributor" --scopes="/subscriptions/YOUR_SUBSCRIPTION_ID"
   ```
   Save the output (tenant_id, client_id, client_secret)

**Note**: For POC, SSH keys are optional. VM uses password authentication for easier access.

---

## Phase 1: Infrastructure Deployment (15 minutes)

### Step 1: Configure Terraform Variables

1. Navigate to terraform directory:
   ```bash
   cd 03-Projects/cloudoptima-ai/terraform
   ```

2. Copy example variables:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Edit `terraform.tfvars`:
   ```hcl
   prefix              = "cloudoptima"
   resource_group_name = "cloudoptima-rg"
   location            = "eastus"  # Must be eastus (not eastus2)
   db_admin_username   = "cloudoptima"
   db_name             = "cloudoptima"
   
   # Azure Service Principal
   azure_tenant_id     = "your-tenant-id"
   azure_client_id     = "your-client-id"
   azure_client_secret = "your-client-secret"
   ```

### Step 2: Initialize Terraform

```bash
terraform init
```

### Step 3: Plan Deployment

```bash
terraform plan -out=tfplan
```

Review the plan. You should see:
- ✅ Resource Group
- ✅ Virtual Network + Subnet
- ✅ B1S VM (FREE)
- ✅ PostgreSQL B1MS (FREE)
- ✅ App Service F1 (FREE)
- ✅ Public IP
- ✅ NSG

### Step 4: Apply Deployment

```bash
terraform apply tfplan
```

This takes ~10-15 minutes. PostgreSQL creation is the slowest part.

### Step 5: Save Outputs

```bash
terraform output > ../deployment-outputs.txt
terraform output -json > ../deployment-outputs.json

# View sensitive outputs
terraform output vm_password
terraform output postgres_admin_password
terraform output secret_key
terraform output database_url
```

Save these securely! You'll need the VM password to SSH in.

---

## Phase 2: VM Setup (30 minutes)

### Step 1: Get VM Connection Info

```bash
VM_FQDN=$(terraform output -raw vm_fqdn)
echo "VM FQDN: $VM_FQDN"
```

### Step 2: SSH into VM

```bash
ssh azureuser@$VM_FQDN
```

When prompted for password:
```bash
# Get password from Terraform
cd ../terraform
terraform output vm_password
```

Copy and paste the password when prompted.

If connection refused, wait 2-3 minutes for cloud-init to complete.

### Step 3: Verify Cloud-Init Completed

```bash
cat /tmp/setup-complete.txt
docker --version
python3.11 --version
```

### Step 4: Upload Application Code

From your local machine:

```bash
# Create tarball
cd 03-Projects/cloudoptima-ai
tar -czf cloudoptima-backend.tar.gz backend/

# Upload to VM
scp cloudoptima-backend.tar.gz azureuser@$VM_FQDN:/tmp/

# SSH back in
ssh azureuser@$VM_FQDN

# Extract
sudo mkdir -p /opt/cloudoptima
sudo chown azureuser:azureuser /opt/cloudoptima
cd /opt/cloudoptima
tar -xzf /tmp/cloudoptima-backend.tar.gz
```

### Step 5: Run Setup Script

```bash
cd /opt/cloudoptima
chmod +x scripts/vm-setup.sh
sudo bash scripts/vm-setup.sh
```

This script will:
1. Install Python dependencies
2. Start Redis container
3. Create systemd services
4. Start all services
5. Run database migrations

### Step 6: Verify Services

```bash
# Check service status
sudo systemctl status backend
sudo systemctl status celery-worker
sudo systemctl status celery-beat

# Check Redis
docker ps | grep redis

# Check memory
free -h

# Test backend
curl http://localhost:8000/health
```

Expected response:
```json
{"status": "healthy"}
```

### Step 7: Check Logs

```bash
# Backend logs
sudo journalctl -u backend -f

# Celery worker logs
sudo journalctl -u celery-worker -f

# Celery beat logs
sudo journalctl -u celery-beat -f
```

---

## Phase 3: Frontend Deployment (15 minutes)

### Step 1: Build Frontend

From your local machine:

```bash
cd 03-Projects/cloudoptima-ai/frontend

# Install dependencies
npm install

# Set backend URL
export REACT_APP_API_URL="http://$VM_FQDN:8000"

# Build
npm run build
```

### Step 2: Deploy to App Service

```bash
# Get App Service name
APP_NAME=$(cd ../terraform && terraform output -raw frontend_url | cut -d'/' -f3 | cut -d'.' -f1)

# Create deployment package
cd build
zip -r ../frontend-build.zip .
cd ..

# Deploy
az webapp deployment source config-zip \
  --resource-group cloudoptima-rg \
  --name $APP_NAME \
  --src frontend-build.zip
```

### Step 3: Configure App Service

```bash
# Set environment variables
az webapp config appsettings set \
  --resource-group cloudoptima-rg \
  --name $APP_NAME \
  --settings \
    REACT_APP_API_URL="http://$VM_FQDN:8000" \
    WEBSITE_NODE_DEFAULT_VERSION="18-lts"
```

### Step 4: Test Frontend

```bash
FRONTEND_URL=$(cd terraform && terraform output -raw frontend_url)
echo "Frontend URL: $FRONTEND_URL"
```

Open in browser: `$FRONTEND_URL`

---

## Phase 4: Integration Testing (15 minutes)

### Test 1: Backend Health

```bash
curl http://$VM_FQDN:8000/health
```

Expected: `{"status": "healthy"}`

### Test 2: API Documentation

Open in browser: `http://$VM_FQDN:8000/docs`

### Test 3: Database Connection

```bash
ssh azureuser@$VM_FQDN
cd /opt/cloudoptima/backend
source venv/bin/activate
python -c "from app.core.database import engine; import asyncio; asyncio.run(engine.connect())"
```

Expected: No errors

### Test 4: Create Test User

```bash
curl -X POST http://$VM_FQDN:8000/api/v1/users \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpass123",
    "full_name": "Test User"
  }'
```

### Test 5: Frontend → Backend Communication

1. Open frontend in browser
2. Try to login/register
3. Check browser console for errors
4. Check backend logs: `ssh azureuser@$VM_FQDN sudo journalctl -u backend -f`

### Test 6: Celery Tasks

```bash
ssh azureuser@$VM_FQDN
cd /opt/cloudoptima/backend
source venv/bin/activate
python -c "from app.core.celery_app import app; print(app.control.inspect().active())"
```

### Test 7: Memory Usage

```bash
ssh azureuser@$VM_FQDN
free -h
htop  # Press q to quit
```

Expected: < 900 MB used

---

## Monitoring

### Daily Checks

```bash
# SSH into VM
ssh azureuser@$VM_FQDN

# Check services
sudo systemctl status backend celery-worker celery-beat

# Check memory
free -h

# Check disk
df -h

# Check Redis
docker ps
docker stats redis --no-stream
```

### Weekly Checks

1. **Azure Portal**
   - Cost Analysis (should be $0)
   - VM metrics (CPU, memory)
   - PostgreSQL metrics
   - App Service metrics

2. **Logs**
   ```bash
   # Backend errors
   sudo journalctl -u backend --since "1 week ago" | grep ERROR
   
   # Celery errors
   sudo journalctl -u celery-worker --since "1 week ago" | grep ERROR
   ```

3. **Database Size**
   ```bash
   # SSH into VM
   psql "postgresql://cloudoptima:PASSWORD@POSTGRES_FQDN:5432/cloudoptima?sslmode=require" \
     -c "SELECT pg_size_pretty(pg_database_size('cloudoptima'));"
   ```

---

## Troubleshooting

### Issue: Services Won't Start

```bash
# Check logs
sudo journalctl -u backend -n 50
sudo journalctl -u celery-worker -n 50

# Check environment
cat /etc/environment

# Restart services
sudo systemctl restart backend celery-worker celery-beat
```

### Issue: Out of Memory

```bash
# Check memory
free -h

# Check swap
swapon --show

# Restart services one by one
sudo systemctl restart celery-beat  # Smallest first
sudo systemctl restart celery-worker
sudo systemctl restart backend
```

### Issue: Can't Connect to Database

```bash
# Test connection
psql "postgresql://cloudoptima:PASSWORD@POSTGRES_FQDN:5432/cloudoptima?sslmode=require"

# Check firewall rules in Azure Portal
# Ensure VM IP is allowed
```

### Issue: Frontend Can't Reach Backend

1. Check NSG rules (port 8000 open)
2. Check backend is running: `curl http://localhost:8000/health`
3. Check from outside: `curl http://$VM_FQDN:8000/health`
4. Check CORS settings in backend

---

## Cost Verification

### Check Current Cost

```bash
az consumption usage list \
  --start-date $(date -d "1 month ago" +%Y-%m-%d) \
  --end-date $(date +%Y-%m-%d) \
  --query "[?contains(instanceName, 'cloudoptima')]" \
  --output table
```

Expected: $0 for first 12 months

### Monitor Free Tier Usage

Azure Portal → Cost Management → Cost Analysis
- Filter by Resource Group: cloudoptima-rg
- Should show $0 or minimal cost

---

## Backup & Recovery

### Database Backup

Azure automatically backs up PostgreSQL (7 days retention).

Manual backup:
```bash
pg_dump "postgresql://cloudoptima:PASSWORD@POSTGRES_FQDN:5432/cloudoptima?sslmode=require" \
  > cloudoptima-backup-$(date +%Y%m%d).sql
```

### VM Backup

Create VM snapshot in Azure Portal:
1. Go to VM → Disks → OS Disk
2. Create Snapshot
3. Name: cloudoptima-vm-snapshot-YYYYMMDD

---

## Scaling (After Free Tier)

When you outgrow the free tier:

1. **Upgrade VM**: B1S → B2S (2 vCPU, 4 GB RAM) = +$30/month
2. **Upgrade PostgreSQL**: B1MS → B2S (2 vCore, 4 GB RAM) = +$30/month
3. **Add Redis Cache**: Basic C0 = +$17/month
4. **Add Load Balancer**: Standard = +$20/month

Total after upgrades: ~$100/month

---

## Cleanup

To destroy everything:

```bash
cd 03-Projects/cloudoptima-ai/terraform
terraform destroy
```

This will delete:
- VM
- PostgreSQL
- App Service
- All data

---

## Success Criteria

✅ VM accessible via SSH
✅ Backend API responds at http://VM_FQDN:8000/health
✅ Frontend loads at https://appname.azurewebsites.net
✅ Frontend can call backend API
✅ Database migrations completed
✅ Can create user via API
✅ Celery worker processes tasks
✅ Redis running in Docker
✅ Memory usage < 900 MB
✅ All services auto-start on reboot
✅ Cost is $0 in Azure Portal

---

## Support

If you encounter issues:
1. Check logs: `sudo journalctl -u backend -f`
2. Check memory: `free -h`
3. Check services: `sudo systemctl status backend celery-worker celery-beat`
4. Restart services: `sudo systemctl restart backend`
5. Check Azure Portal for resource status

---

**Deployment Complete! 🎉**

Your CloudOptima AI is now running on Azure FREE tier!
