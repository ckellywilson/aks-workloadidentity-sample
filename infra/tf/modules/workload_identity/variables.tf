variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "aks_oidc_issuer_url" {
  description = "OIDC issuer URL of the AKS cluster"
  type        = string
}

variable "workload_identity_id" {
  description = "ID of the workload managed identity"
  type        = string
}

variable "workload_identity_name" {
  description = "Name of the workload managed identity"
  type        = string
}

variable "workload_identity_client_id" {
  description = "Client ID of the workload managed identity"
  type        = string
}

variable "workload_identity_principal_id" {
  description = "Principal ID of the workload managed identity"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
  default     = "default"
}

variable "service_account_name" {
  description = "Name of the Kubernetes service account"
  type        = string
  default     = "workload-identity-sa"
}
