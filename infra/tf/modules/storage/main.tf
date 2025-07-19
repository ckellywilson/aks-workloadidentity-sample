# Storage Account Module
resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

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
