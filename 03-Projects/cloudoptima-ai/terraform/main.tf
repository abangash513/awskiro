# CloudOptima AI - Azure Infrastructure with Terraform
# Option 1: TRUE FREE Hybrid Deployment (VM + App Service + PostgreSQL)

terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Data source for current Azure client
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

# Random password for database
resource "random_password" "db_password" {
  length  = 32
  special = true
}

# Random password for VM
resource "random_password" "vm_password" {
  length  = 16
  special = true
}

# Random password for secret key
resource "random_password" "secret_key" {
  length  = 64
  special = false
}

# Random string for unique names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}
