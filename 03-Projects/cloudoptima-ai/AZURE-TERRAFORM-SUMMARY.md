# CloudOptima AI - Azure Terraform Deployment Summary

Complete Azure deployment package with Terraform infrastructure as code.

## 📦 What's Been Created

### Terraform Infrastructure Files (8 files)
1. **terraform/main.tf** - Main configuration, VNet, NSG, Key Vault
2. **terraform/database.tf** - PostgreSQL Flexible Server with TimescaleDB
3. **terraform/redis.tf** - Azure Cache for Redis
4. **terraform/container-registry.tf** - Azure Container Registry
5. **terraform/container-instances.tf** - 4 Container Instances (frontend, backend, celery-worker, celery-beat)
6. **terraform/variables.tf** - Input variables
7. **terraform/outputs.tf** - Output values and deployment summary
8. **terraform/terraform.tfvars.example** - Example configuration

### Deployment Scripts (2 files)
1. **deploy-azure.sh** - Automated deployment for Linux/Mac
2. **deploy-azure.ps1** - Automated deployment for Windows

### Documentation (3 files)
1. **AZURE-DEPLOYMENT-GUIDE.md** - Comprehensive deployment guide
2. **AZURE-QUICKSTART.md** - Quick start guide (15 minutes)
3. **DEPLOYMENT-COMPARISON.md** - Azure vs AWS comparison

---

## 🏗️ Infrastructure Components

### Compute
- **4 Azure Container Instances**
  - Frontend (React): 0.5 CPU, 1GB RAM
  - Backend (FastAPI): 1 CPU, 2GB RAM
  - Celery Worker: 1 CPU, 2GB RAM
  - Celery Beat: 0.5 CPU, 1GB RAM

### Database
- **Azure Database for PostgreSQL Flexible Server**
  - Version: 16
  - SKU: B_Standard_B2s (burstable)
  - Storage: 32GB with auto-grow
  - Backup: 7-day retention
  - Extensions: TimescaleDB enabled

### Cache
- **Azure Cache for Redis**
  - Tier: Basic
  - Size: C0 (250MB)
  - SSL: Enabled
  - TLS: 1.2 minimum

### Networking
- **Virtual Network**: 10.0.0.0/16
  - Container Subnet: 10.0.1.0/24
  - Database Subnet: 10.0.2.0/24
- **Network Security Group**: HTTP, HTTPS, API ports
- **Public IPs**: Frontend and Backend

### Storage & Registry
- **Azure Container Registry**: Basic tier
- **Log Analytics Workspace**: 30-day retention

### Security
- **Azure Key Vault**: Secrets management
  - Database password
  - JWT secret
  - Azure credentials

---

## 🚀 Quick Start Commands

### Deploy Everything (15 minutes)

```powershell
# Windows
cd 03-Projects\cloudoptima-ai
.\deploy-azure.ps1
```

```bash
# Linux/Mac
cd 03-Projects/cloudoptima-ai
chmod +x deploy-azure.sh
./deploy-azure.sh
```

### Manual Deployment

```bash
# 1. Login to Azure
az login
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# 2. Create Service Principal
az ad sp create-for-rbac \
  --name cloudoptima-reader \
  --role "Cost Management Reader" \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID

# 3. Configure Terraform
cd terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Add your values

# 4. Deploy
terraform init
terraform plan
terraform apply

# 5. Build and push images
ACR_NAME=$(terraform output -raw acr_name)
az acr login --name $ACR_NAME

docker build -f docker/Dockerfile.backend -t $ACR_NAME.azurecr.io/cloudoptima-backend:latest .
docker push $ACR_NAME.azurecr.io/cloudoptima-backend:latest

docker build -f docker/Dockerfile.frontend -t $ACR_NAME.azurecr.io/cloudoptima-frontend:latest .
docker push $ACR_NAME.azurecr.io/cloudoptima-frontend:latest

# 6. Restart containers
az container restart --resource-group cloudoptima-rg --name cloudoptima-backend
az container restart --resource-group cloudoptima-rg --name cloudoptima-frontend
az container restart --resource-group cloudoptima-rg --name cloudoptima-celery-worker
az container restart --resource-group cloudoptima-rg --name cloudoptima-celery-beat
```

---

## 💰 Cost Breakdown

### Monthly Costs (USD)

| Service | SKU | Cost |
|---------|-----|------|
| Container Instances (4) | 3 CPU, 6GB RAM | $40-70 |
| PostgreSQL Flexible Server | B_Standard_B2s | $30-50 |
| Azure Cache for Redis | Basic C0 | $15 |
| Container Registry | Basic | $5 |
| Virtual Network | Standard | $5 |
| Log Analytics | Pay-as-you-go | $5-10 |
| Data Transfer | Outbound | $5-10 |
| **Total** | | **$105-165** |

### Cost Optimization
- Use Reserved Instances: Save 40-60%
- Use Burstable tier for PostgreSQL: Already included
- Enable auto-shutdown for dev/test: Manual setup
- Clean up unused resources: Regular maintenance

---

## 📊 Architecture Diagram

```
Internet
   ↓
[Network Security Group]
   ↓
[Virtual Network 10.0.0.0/16]
   ├── Container Subnet (10.0.1.0/24)
   │   ├── Frontend Container (Public IP)
   │   ├── Backend Container (Public IP)
   │   ├── Celery Worker Container
   │   └── Celery Beat Container
   │
   └── Database Subnet (10.0.2.0/24)
       └── PostgreSQL Flexible Server
           └── TimescaleDB Extension

[Azure Cache for Redis]
[Azure Container Registry]
[Azure Key Vault]
[Log Analytics Workspace]
```

---

## 🔐 Security Features

### Network Security
- Virtual Network isolation
- Network Security Groups with minimal rules
- Private DNS for PostgreSQL
- SSL/TLS for all connections

### Secrets Management
- Azure Key Vault for sensitive data
- Terraform-generated secure passwords
- No secrets in code or version control

### Database Security
- Private subnet deployment
- Firewall rules (Azure services only)
- SSL required for connections
- Encrypted at rest and in transit

### Container Security
- Private container registry
- Admin credentials managed by Terraform
- Environment variables for configuration
- Log Analytics for monitoring

---

## 📈 Monitoring and Logging

### Log Analytics Workspace
- All container logs centralized
- 30-day retention
- Query with KQL (Kusto Query Language)

### Container Insights
```bash
# View logs
az container logs --resource-group cloudoptima-rg --name cloudoptima-backend --follow

# View metrics
az monitor metrics list --resource /subscriptions/.../cloudoptima-backend
```

### Database Monitoring
```bash
# View database metrics
az postgres flexible-server show --resource-group cloudoptima-rg --name cloudoptima-db

# View slow queries
az postgres flexible-server parameter set \
  --resource-group cloudoptima-rg \
  --server-name cloudoptima-db \
  --name log_min_duration_statement \
  --value 1000
```

---

## 🔄 CI/CD Integration

### GitHub Actions Example

```yaml
name: Deploy to Azure

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Build and push images
        run: |
          ACR_NAME=${{ secrets.ACR_NAME }}
          az acr login --name $ACR_NAME
          
          docker build -f docker/Dockerfile.backend -t $ACR_NAME.azurecr.io/cloudoptima-backend:${{ github.sha }} .
          docker push $ACR_NAME.azurecr.io/cloudoptima-backend:${{ github.sha }}
          
          docker build -f docker/Dockerfile.frontend -t $ACR_NAME.azurecr.io/cloudoptima-frontend:${{ github.sha }} .
          docker push $ACR_NAME.azurecr.io/cloudoptima-frontend:${{ github.sha }}
      
      - name: Restart containers
        run: |
          az container restart --resource-group cloudoptima-rg --name cloudoptima-backend
          az container restart --resource-group cloudoptima-rg --name cloudoptima-frontend
```

---

## 🛠️ Common Operations

### View Deployment Info
```bash
cd terraform
terraform output deployment_summary
```

### Get Sensitive Values
```bash
terraform output postgres_password
terraform output redis_primary_key
terraform output acr_admin_password
```

### Update Container Resources
```bash
# Edit container-instances.tf
nano terraform/container-instances.tf

# Apply changes
terraform plan
terraform apply
```

### Scale Containers
```bash
# Increase backend resources
az container create \
  --resource-group cloudoptima-rg \
  --name cloudoptima-backend \
  --cpu 2 \
  --memory 4
```

### Backup Database
```bash
# Manual backup
pg_dump "host=$(terraform output -raw postgres_host) dbname=cloudoptima user=cloudoptima password=$(terraform output -raw postgres_password) sslmode=require" > backup.sql

# Restore
psql "host=$(terraform output -raw postgres_host) dbname=cloudoptima user=cloudoptima password=$(terraform output -raw postgres_password) sslmode=require" < backup.sql
```

---

## 🐛 Troubleshooting

### Terraform Issues

```bash
# Refresh state
terraform refresh

# Show current state
terraform show

# Validate configuration
terraform validate

# Format code
terraform fmt
```

### Container Issues

```bash
# View logs
az container logs --resource-group cloudoptima-rg --name cloudoptima-backend

# Show container details
az container show --resource-group cloudoptima-rg --name cloudoptima-backend

# Restart container
az container restart --resource-group cloudoptima-rg --name cloudoptima-backend

# Delete and recreate
az container delete --resource-group cloudoptima-rg --name cloudoptima-backend --yes
terraform apply
```

### Database Issues

```bash
# Test connection
psql "host=$(terraform output -raw postgres_host) dbname=cloudoptima user=cloudoptima password=$(terraform output -raw postgres_password) sslmode=require"

# Check firewall rules
az postgres flexible-server firewall-rule list --resource-group cloudoptima-rg --name cloudoptima-db

# View server logs
az postgres flexible-server server-logs list --resource-group cloudoptima-rg --name cloudoptima-db
```

---

## 🗑️ Cleanup

### Destroy All Resources

```bash
cd terraform
terraform destroy

# Confirm with: yes
```

### Delete Specific Resources

```bash
# Delete container group
az container delete --resource-group cloudoptima-rg --name cloudoptima-backend --yes

# Delete database
az postgres flexible-server delete --resource-group cloudoptima-rg --name cloudoptima-db --yes

# Delete entire resource group
az group delete --name cloudoptima-rg --yes --no-wait
```

---

## ✅ Success Checklist

After deployment, verify:

- [ ] All 4 containers are running
- [ ] Frontend accessible at public URL
- [ ] Backend API responding at /health
- [ ] API docs accessible at /docs
- [ ] Database connection working
- [ ] Redis connection working
- [ ] TimescaleDB extension enabled
- [ ] cost_data hypertable created
- [ ] User registration working
- [ ] Azure Cost Management API connected
- [ ] Cost data ingestion working
- [ ] Recommendations being generated

---

## 📚 Additional Resources

### Terraform Documentation
- [Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Container Instances](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_group)
- [PostgreSQL Flexible Server](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server)

### Azure Documentation
- [Container Instances](https://docs.microsoft.com/en-us/azure/container-instances/)
- [PostgreSQL Flexible Server](https://docs.microsoft.com/en-us/azure/postgresql/flexible-server/)
- [Container Registry](https://docs.microsoft.com/en-us/azure/container-registry/)

### CloudOptima AI Documentation
- [AZURE-DEPLOYMENT-GUIDE.md](AZURE-DEPLOYMENT-GUIDE.md)
- [AZURE-QUICKSTART.md](AZURE-QUICKSTART.md)
- [DEPLOYMENT-COMPARISON.md](DEPLOYMENT-COMPARISON.md)

---

## 🎯 Next Steps

1. ✅ Infrastructure deployed with Terraform
2. ✅ Containers running on Azure
3. ⏭️ Set up custom domain with Azure DNS
4. ⏭️ Enable Azure Front Door for CDN and WAF
5. ⏭️ Configure Azure DevOps or GitHub Actions for CI/CD
6. ⏭️ Set up Azure Monitor alerts
7. ⏭️ Enable Azure Backup for additional protection
8. ⏭️ Implement cost optimization recommendations

---

## 📞 Support

For issues or questions:
- Check container logs: `az container logs --resource-group cloudoptima-rg --name cloudoptima-backend --follow`
- Review Terraform state: `terraform show`
- Check [AZURE-DEPLOYMENT-GUIDE.md](AZURE-DEPLOYMENT-GUIDE.md)
- Review API docs at your backend URL + `/docs`

