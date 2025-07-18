output "service_account_name" {
  description = "Name of the Kubernetes service account"
  value       = kubernetes_service_account.workload_identity.metadata[0].name
}

output "service_account_namespace" {
  description = "Namespace of the Kubernetes service account"
  value       = kubernetes_service_account.workload_identity.metadata[0].namespace
}

output "federated_credential_id" {
  description = "ID of the federated identity credential"
  value       = azurerm_federated_identity_credential.workload_identity.id
}
