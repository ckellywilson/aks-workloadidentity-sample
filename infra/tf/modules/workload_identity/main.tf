# Workload Identity Configuration Module
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.37"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.4"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.37"
    }
  }
}

data "azurerm_client_config" "current" {}

# Create federated identity credential for workload identity
resource "azurerm_federated_identity_credential" "workload_identity" {
  name                = "${var.project_name}-${var.environment}-federated-cred"
  resource_group_name = var.resource_group_name
  parent_id           = var.workload_identity_id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.aks_oidc_issuer_url
  subject             = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
}

# Create Kubernetes service account with workload identity annotation
resource "kubernetes_service_account" "workload_identity" {
  metadata {
    name      = var.service_account_name
    namespace = var.namespace
    annotations = {
      "azure.workload.identity/client-id" = var.workload_identity_client_id
    }
  }
}

# Create Kubernetes namespace if it doesn't exist
resource "kubernetes_namespace" "workload_identity" {
  count = var.namespace != "default" ? 1 : 0
  metadata {
    name = var.namespace
  }
}
