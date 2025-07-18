# Outputs for the Terraform configuration
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.cluster_name
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = module.aks.cluster_id
}

output "container_registry_name" {
  description = "Name of the container registry"
  value       = module.container_registry.registry_name
}

output "container_registry_login_server" {
  description = "Login server URL for the container registry"
  value       = module.container_registry.login_server
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = module.storage.storage_account_name
}

output "workload_identity_client_id" {
  description = "Client ID of the workload identity"
  value       = module.managed_identity.workload_identity_client_id
}

output "workload_identity_principal_id" {
  description = "Principal ID of the workload identity"
  value       = module.managed_identity.workload_identity_principal_id
}

output "kubelet_identity_id" {
  description = "ID of the kubelet managed identity"
  value       = module.managed_identity.kubelet_identity_id
}

output "cluster_identity_id" {
  description = "ID of the cluster managed identity"
  value       = module.managed_identity.cluster_identity_id
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity"
  value       = module.aks.oidc_issuer_url
}

output "workload_identity_enabled" {
  description = "Whether workload identity is enabled"
  value       = module.aks.workload_identity_enabled
}

output "azure_rbac_enabled" {
  description = "Whether Azure RBAC is enabled"
  value       = module.aks.azure_rbac_enabled
}

output "local_account_disabled" {
  description = "Whether local account is disabled (AAD-only)"
  value       = module.aks.local_account_disabled
}

output "kubeconfig_command" {
  description = "Command to get kubeconfig for the AKS cluster (requires Azure AD authentication)"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${module.aks.cluster_name}"
}

output "admin_group_object_ids" {
  description = "Object IDs of Azure AD groups with admin access to the cluster"
  value       = var.admin_group_object_ids
}

output "current_user_principal_id" {
  description = "Principal ID of the current user (automatically granted cluster admin access)"
  value       = data.azurerm_client_config.current.object_id
}

output "cluster_access_info" {
  description = "Information about cluster access configuration"
  value = {
    azure_ad_integration = "enabled"
    azure_rbac_enabled   = var.enable_azure_rbac
    local_accounts       = "disabled"
    admin_groups_count   = length(var.admin_group_object_ids)
    current_user_access  = "admin (automatic)"
  }
}
