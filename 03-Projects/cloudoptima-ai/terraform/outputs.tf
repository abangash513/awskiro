# Terraform Outputs - VM-Only Deployment

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "vm_public_ip" {
  description = "VM public IP address"
  value       = azurerm_public_ip.vm.ip_address
}

output "vm_fqdn" {
  description = "VM fully qualified domain name"
  value       = azurerm_public_ip.vm.fqdn
}

output "vm_username" {
  description = "VM username"
  value       = "azureuser"
}

output "vm_password" {
  description = "VM password (POC only - use SSH keys in production)"
  value       = random_password.vm_password.result
  sensitive   = true
}

output "vm_ssh_command" {
  description = "SSH command to connect to VM"
  value       = "ssh azureuser@${azurerm_public_ip.vm.fqdn}"
}

output "backend_url" {
  description = "Backend API URL"
  value       = "http://${azurerm_public_ip.vm.fqdn}:8000"
}

output "backend_api_docs" {
  description = "Backend API documentation URL"
  value       = "http://${azurerm_public_ip.vm.fqdn}:8000/docs"
}

output "frontend_url" {
  description = "Frontend application URL"
  value       = "http://${azurerm_public_ip.vm.fqdn}:3000"
}

output "secret_key" {
  description = "Application secret key for JWT"
  value       = random_password.secret_key.result
  sensitive   = true
}

output "db_password" {
  description = "PostgreSQL password (Docker)"
  value       = random_password.db_password.result
  sensitive   = true
}

output "deployment_summary" {
  description = "Deployment summary with access URLs"
  value       = <<-EOT
  
  ========================================
  CloudOptima AI - VM-Only Deployment!
  ========================================
  
  Access URLs:
    Frontend:  http://${azurerm_public_ip.vm.fqdn}:3000
    Backend:   http://${azurerm_public_ip.vm.fqdn}:8000
    API Docs:  http://${azurerm_public_ip.vm.fqdn}:8000/docs
  
  VM Access:
    SSH:       ssh azureuser@${azurerm_public_ip.vm.fqdn}
    IP:        ${azurerm_public_ip.vm.ip_address}
    FQDN:      ${azurerm_public_ip.vm.fqdn}
    Password:  (run: terraform output vm_password)
  
  Services (All on VM in Docker):
    - Frontend (React) :3000
    - Backend (FastAPI) :8000
    - PostgreSQL :5432
    - Redis :6379
    - Celery Worker
    - Celery Beat
  
  Cost:
    Current:   $0/month (FREE tier - B1S VM)
    After 12m: ~$10/month
  
  Next Steps:
    1. SSH into VM: ssh azureuser@${azurerm_public_ip.vm.fqdn}
    2. Run setup script: sudo bash /opt/cloudoptima/scripts/vm-only-setup.sh
    3. Check services: docker ps
    4. Test: curl http://localhost:8000/health
  
  View sensitive outputs:
    terraform output vm_password
    terraform output db_password
    terraform output secret_key
  
  ========================================
  EOT
}
