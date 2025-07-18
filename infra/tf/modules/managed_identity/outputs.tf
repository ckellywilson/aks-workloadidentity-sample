output "kubelet_identity_id" {
  description = "ID of the kubelet managed identity"
  value       = azurerm_user_assigned_identity.kubelet.id
}

output "kubelet_identity_client_id" {
  description = "Client ID of the kubelet managed identity"
  value       = azurerm_user_assigned_identity.kubelet.client_id
}

output "cluster_identity_id" {
  description = "ID of the cluster managed identity"
  value       = azurerm_user_assigned_identity.cluster.id
}

output "cluster_identity_client_id" {
  description = "Client ID of the cluster managed identity"
  value       = azurerm_user_assigned_identity.cluster.client_id
}

output "cluster_identity_principal_id" {
  description = "Principal ID of the cluster managed identity"
  value       = azurerm_user_assigned_identity.cluster.principal_id
}

output "workload_identity_id" {
  description = "ID of the workload managed identity"
  value       = azurerm_user_assigned_identity.workload.id
}

output "workload_identity_client_id" {
  description = "Client ID of the workload managed identity"
  value       = azurerm_user_assigned_identity.workload.client_id
}

output "workload_identity_principal_id" {
  description = "Principal ID of the workload managed identity"
  value       = azurerm_user_assigned_identity.workload.principal_id
}

output "workload_identity_name" {
  description = "Name of the workload managed identity"
  value       = azurerm_user_assigned_identity.workload.name
}
