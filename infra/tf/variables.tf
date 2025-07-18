# Variables for the Terraform configuration
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = ""
}

variable "project_name" {
  description = "Name of the project (keep short for resource naming constraints)"
  type        = string
  default     = "akswlid"

  validation {
    condition     = length(var.project_name) <= 10 && can(regex("^[a-z0-9]+$", var.project_name))
    error_message = "Project name must be 10 characters or less and contain only lowercase letters and numbers."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
  default     = "Central US"
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS cluster"
  type        = string
  default     = "1.28"
}

variable "node_count" {
  description = "Number of nodes in the AKS cluster"
  type        = number
  default     = 3
}

variable "vm_size" {
  description = "Size of the VM instances for AKS nodes"
  type        = string
  default     = "Standard_B2s"
}

variable "namespace" {
  description = "Kubernetes namespace for workload identity"
  type        = string
  default     = "default"
}

variable "service_account_name" {
  description = "Name of the Kubernetes service account"
  type        = string
  default     = "workload-identity-sa"
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
