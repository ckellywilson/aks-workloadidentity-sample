# Data source for current Azure configuration
data "azurerm_client_config" "current" {}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.project_name}-${var.environment}"
  kubernetes_version  = var.kubernetes_version

  # Custom node resource group for AKS infrastructure resources
  # This follows Azure naming standards and provides better organization
  node_resource_group = var.node_resource_group

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
    tenant_id              = data.azurerm_client_config.current.tenant_id
    azure_rbac_enabled     = var.enable_azure_rbac
    admin_group_object_ids = var.admin_group_object_ids
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

# Role assignment for current user/service principal as cluster admin
# This ensures the deploying user can access the cluster after creation
resource "azurerm_role_assignment" "current_user_cluster_admin" {
  scope                = azurerm_kubernetes_cluster.main.id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Additional role assignment for current user as Azure Kubernetes Service RBAC Cluster Admin
# This provides full Kubernetes RBAC access through Azure AD
resource "azurerm_role_assignment" "current_user_rbac_cluster_admin" {
  scope                = azurerm_kubernetes_cluster.main.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Role assignment for admin groups as cluster admin
resource "azurerm_role_assignment" "admin_groups_cluster_admin" {
  count                = length(var.admin_group_object_ids)
  scope                = azurerm_kubernetes_cluster.main.id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  principal_id         = var.admin_group_object_ids[count.index]
}

# Role assignment for admin groups as Azure Kubernetes Service RBAC Cluster Admin
resource "azurerm_role_assignment" "admin_groups_rbac_cluster_admin" {
  count                = length(var.admin_group_object_ids)
  scope                = azurerm_kubernetes_cluster.main.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = var.admin_group_object_ids[count.index]
}
