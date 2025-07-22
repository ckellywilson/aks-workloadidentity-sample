# Backend configuration for Terraform state
# This file should be used with: terraform init -backend-config=backend.hcl
# Generated from Azure query on 2025-07-22

resource_group_name  = "tfstate-mgmt-rg"
storage_account_name = "tfstate93025"
container_name       = "tfstate"
key                  = "aks-workloadidentity/terraform.tfstate"
use_azuread_auth     = true
