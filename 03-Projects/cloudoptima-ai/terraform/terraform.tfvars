# CloudOptima AI - Terraform Variables

prefix              = "cloudoptima"
resource_group_name = "cloudoptima-rg"
location            = "eastus2"  # East US 2 region - better VM availability

db_admin_username = "cloudoptima"
db_name           = "cloudoptima"

azure_tenant_id     = "d2449d27-d175-4648-90c3-04288acd1837"
azure_client_id     = "b3aa0768-ba45-4fb8-bae9-e5af46a60d35"
azure_client_secret = "ZmA8Q~PjdbSYKOs7rGjgzSwOKwuEfu0DBH_Gnbb-"

tags = {
  Environment = "Production"
  Project     = "CloudOptima AI"
  ManagedBy   = "Terraform"
}
