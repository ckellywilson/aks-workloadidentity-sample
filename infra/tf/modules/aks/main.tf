# Data source for current Azure configuration
data "azurerm_client_config" "current" {}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.project_name}-${var.environment}"
  kubernetes_version  = var.kubernetes_version

  # Disable local accounts to force Azure AD authentication
  local_account_disabled = var.disable_local_accounts

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.vm_size
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.cluster_identity_id]
  }

  kubelet_identity {
    client_id                 = data.azurerm_user_assigned_identity.kubelet.client_id
    object_id                 = data.azurerm_user_assigned_identity.kubelet.principal_id
    user_assigned_identity_id = var.kubelet_identity_id
  }

  # Azure Active Directory integration with Azure RBAC
  azure_active_directory_role_based_access_control {
    tenant_id          = data.azurerm_client_config.current.tenant_id
    azure_rbac_enabled = var.enable_azure_rbac
  }

  # Enable workload identity and OIDC issuer
  oidc_issuer_enabled       = var.enable_oidc_issuer
  workload_identity_enabled = var.enable_workload_identity

  tags = var.tags
}

# Get kubelet identity details
data "azurerm_user_assigned_identity" "kubelet" {
  name                = split("/", var.kubelet_identity_id)[8]
  resource_group_name = var.resource_group_name
}

# Role assignment for kubelet identity to pull from ACR
resource "azurerm_role_assignment" "kubelet_acr_pull" {
  scope                = var.container_registry_id
  role_definition_name = "AcrPull"
  principal_id         = data.azurerm_user_assigned_identity.kubelet.principal_id
}

# Role assignment for cluster identity to operate kubelet identity
resource "azurerm_role_assignment" "cluster_managed_identity_operator" {
  scope                = var.kubelet_identity_id
  role_definition_name = "Managed Identity Operator"
  principal_id         = var.cluster_identity_principal_id
}
