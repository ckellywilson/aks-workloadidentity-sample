output "cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "cluster_endpoint" {
  description = "Kubernetes cluster endpoint"
  value       = azurerm_kubernetes_cluster.main.kube_config.0.host
}

output "cluster_ca_certificate" {
  description = "Kubernetes cluster CA certificate"
  value       = azurerm_kubernetes_cluster.main.kube_config.0.cluster_ca_certificate
}

output "kube_config" {
  description = "Kubernetes configuration"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity"
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
}

output "workload_identity_enabled" {
  description = "Whether workload identity is enabled"
  value       = azurerm_kubernetes_cluster.main.workload_identity_enabled
}

output "azure_rbac_enabled" {
  description = "Whether Azure RBAC is enabled"
  value       = azurerm_kubernetes_cluster.main.azure_active_directory_role_based_access_control[0].azure_rbac_enabled
}

output "local_account_disabled" {
  description = "Whether local account is disabled (AAD-only)"
  value       = azurerm_kubernetes_cluster.main.local_account_disabled
}

output "kubelet_identity" {
  description = "Kubelet identity details"
  value       = azurerm_kubernetes_cluster.main.kubelet_identity
}
