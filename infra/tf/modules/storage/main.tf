# Storage Account Module
resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Enable private endpoint access only
  public_network_access_enabled = false
  
  # Network rules - deny all public access
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }

  blob_properties {
    versioning_enabled = true
  }

  tags = var.tags
}

resource "azurerm_storage_container" "app_data" {
  name                  = var.app_data_container_name
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

# Private DNS Zone for Storage
resource "azurerm_private_dns_zone" "storage" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  name                  = "${var.project_name}-${var.environment}-storage-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

# Private Endpoint for Storage
resource "azurerm_private_endpoint" "storage" {
  name                = "${var.project_name}-${var.environment}-storage-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.project_name}-${var.environment}-storage-psc"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "storage-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage.id]
  }

  tags = var.tags
}
