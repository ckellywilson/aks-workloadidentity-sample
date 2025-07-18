# User Assigned Managed Identity Module
resource "azurerm_user_assigned_identity" "kubelet" {
  location            = var.location
  name                = var.kubelet_identity_name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "cluster" {
  location            = var.location
  name                = var.cluster_identity_name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_user_assigned_identity" "workload" {
  location            = var.location
  name                = var.workload_identity_name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}
