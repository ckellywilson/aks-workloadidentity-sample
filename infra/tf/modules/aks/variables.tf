variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
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

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
}

variable "node_count" {
  description = "Number of nodes"
  type        = number
}

variable "vm_size" {
  description = "VM size for nodes"
  type        = string
}

variable "kubelet_identity_id" {
  description = "ID of the kubelet managed identity"
  type        = string
}

variable "cluster_identity_id" {
  description = "ID of the cluster managed identity"
  type        = string
}

variable "cluster_identity_principal_id" {
  description = "Principal ID of the cluster managed identity"
  type        = string
}

variable "workload_identity_id" {
  description = "ID of the workload managed identity"
  type        = string
}

variable "container_registry_id" {
  description = "ID of the container registry"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "enable_azure_rbac" {
  description = "Enable Azure RBAC for AKS cluster authorization"
  type        = bool
  default     = true
}

variable "disable_local_accounts" {
  description = "Disable local accounts to force Azure AD authentication"
  type        = bool
  default     = true
}

variable "enable_workload_identity" {
  description = "Enable workload identity for the AKS cluster"
  type        = bool
  default     = true
}

variable "enable_oidc_issuer" {
  description = "Enable OIDC issuer for the AKS cluster"
  type        = bool
  default     = true
}
