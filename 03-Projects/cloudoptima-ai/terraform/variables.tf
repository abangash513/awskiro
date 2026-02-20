# Terraform Variables

variable "prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "cloudoptima"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "cloudoptima-rg"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"  # Must be eastus for PostgreSQL free tier
}

variable "db_admin_username" {
  description = "PostgreSQL administrator username"
  type        = string
  default     = "cloudoptima"
}

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "cloudoptima"
}

variable "db_sku_name" {
  description = "PostgreSQL SKU name (B_Standard_B1ms for free tier, B_Standard_B2s for burstable, GP_Standard_D2s_v3 for general purpose)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "azure_tenant_id" {
  description = "Azure Tenant ID for Cost Management API"
  type        = string
  sensitive   = true
}

variable "azure_client_id" {
  description = "Azure Client ID (Service Principal) for Cost Management API"
  type        = string
  sensitive   = true
}

variable "azure_client_secret" {
  description = "Azure Client Secret for Cost Management API"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Production"
    Project     = "CloudOptima AI"
    ManagedBy   = "Terraform"
  }
}
