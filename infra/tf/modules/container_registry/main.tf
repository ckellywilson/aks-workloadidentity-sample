# Container Registry Module
resource "azurerm_container_registry" "main" {
  name                = var.registry_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  admin_enabled       = false

  tags = var.tags
}
