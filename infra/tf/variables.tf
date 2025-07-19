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
  description = "Environment name (dev, stg, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition = contains(["dev", "stg", "prod", "test", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, stg, prod, test, staging, production"
  }
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

variable "deploy_kubernetes_resources" {
  description = "Deploy Kubernetes resources (requires AKS cluster to exist and kubeconfig to be configured)"
  type        = bool
  default     = false
}

variable "enable_oidc_issuer" {
  description = "Enable OIDC issuer for the AKS cluster"
  type        = bool
  default     = true
}

variable "admin_group_object_ids" {
  description = "Object IDs of Azure AD groups that should have admin access to the AKS cluster"
  type        = list(string)
  default     = []

  validation {
    condition = can([
      for id in var.admin_group_object_ids : regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", id)
    ])
    error_message = "Admin group object IDs must be valid UUIDs."
  }
}
