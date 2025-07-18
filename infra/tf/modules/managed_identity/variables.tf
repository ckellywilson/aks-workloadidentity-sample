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

variable "kubelet_identity_name" {
  description = "Name of the kubelet managed identity"
  type        = string
}

variable "cluster_identity_name" {
  description = "Name of the cluster managed identity"
  type        = string
}

variable "workload_identity_name" {
  description = "Name of the workload managed identity"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
