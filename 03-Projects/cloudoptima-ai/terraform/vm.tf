# B1S Virtual Machine for Backend Services
# FREE for 12 months (750 hours/month = 24/7)

# Public IP for VM
resource "azurerm_public_ip" "vm" {
  name                = "${var.prefix}-vm-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "${var.prefix}-vm-${random_string.suffix.result}"

  tags = var.tags
}

# Network Interface for VM
resource "azurerm_network_interface" "vm" {
  name                = "${var.prefix}-vm-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }

  tags = var.tags
}

# Network Security Group for VM
resource "azurerm_network_security_group" "vm" {
  name                = "${var.prefix}-vm-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Allow SSH
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow Backend API
  security_rule {
    name                       = "Backend"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow Frontend
  security_rule {
    name                       = "Frontend"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow outbound
  security_rule {
    name                       = "AllowOutbound"
    priority                   = 1004
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "vm" {
  network_interface_id      = azurerm_network_interface.vm.id
  network_security_group_id = azurerm_network_security_group.vm.id
}

# B2S Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
  name                            = "${var.prefix}-vm"
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  size                            = "Standard_D2s_v3" # 2 vCPU, 8 GB RAM - more widely available
  admin_username                  = "azureuser"
  admin_password                  = random_password.vm_password.result
  disable_password_authentication = false # POC: Allow password auth for easier access

  network_interface_ids = [
    azurerm_network_interface.vm.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Cloud-init script for initial setup
  custom_data = base64encode(templatefile("${path.module}/../scripts/cloud-init-vm-only.yml", {
    redis_url           = "redis://localhost:6379/0"
    secret_key          = random_password.secret_key.result
    azure_tenant_id     = var.azure_tenant_id
    azure_client_id     = var.azure_client_id
    azure_client_secret = var.azure_client_secret
  }))

  tags = var.tags
}
