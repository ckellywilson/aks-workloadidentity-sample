#!/bin/bash

# Deployment script for AKS Workload Identity Infrastructure
# This script sets up the infrastructure using Terraform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install Azure CLI first."
        exit 1
    fi
    
    print_status "Prerequisites check passed."
}

# Login to Azure
azure_login() {
    print_status "Checking Azure login status..."
    
    if ! az account show &> /dev/null; then
        print_status "Not logged in to Azure. Initiating login..."
        az login
    else
        print_status "Already logged in to Azure."
    fi
    
    # Show current subscription
    SUBSCRIPTION=$(az account show --query name -o tsv)
    print_status "Current Azure subscription: $SUBSCRIPTION"
}

# Create storage account for Terraform state (if needed)
# Note: These resources are managed outside of Terraform to avoid circular dependencies
create_state_storage() {
    print_status "Setting up Terraform state storage..."
    print_status "Note: Backend state resources are managed via Azure CLI, not Terraform"
    
    # Variables for state storage - Following Azure naming standards
    RESOURCE_GROUP_NAME="tfstate-mgmt-rg"  # terraform state management resource group
    STORAGE_ACCOUNT_NAME="tfstate$(date +%s | tail -c 6)"
    CONTAINER_NAME="tfstate"
    LOCATION="Central US"
    
    # Create resource group if it doesn't exist
    if ! az group show --name $RESOURCE_GROUP_NAME &> /dev/null; then
        print_status "Creating resource group for Terraform state..."
        az group create --name $RESOURCE_GROUP_NAME --location "$LOCATION"
    fi
    
    # Create storage account if it doesn't exist
    if ! az storage account show --name $STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP_NAME &> /dev/null; then
        print_status "Creating storage account for Terraform state..."
        az storage account create \
            --resource-group $RESOURCE_GROUP_NAME \
            --name $STORAGE_ACCOUNT_NAME \
            --sku Standard_LRS \
            --encryption-services blob
    fi
    
    # Create container if it doesn't exist
    az storage container create \
        --name $CONTAINER_NAME \
        --account-name $STORAGE_ACCOUNT_NAME \
        --auth-mode login > /dev/null 2>&1 || true
    
    # Create backend configuration from template
    print_status "Creating backend configuration..."
    if [ ! -f backend.hcl.template ]; then
        print_error "Backend configuration template not found!"
        exit 1
    fi
    
    cp backend.hcl.template backend.hcl
    sed -i.bak "s/storage_account_name = \"tfstateXXXXXXXX\"/storage_account_name = \"$STORAGE_ACCOUNT_NAME\"/" backend.hcl
    sed -i.bak "s/resource_group_name  = \"tfstate-mgmt-rg\"/resource_group_name  = \"$RESOURCE_GROUP_NAME\"/" backend.hcl
    rm -f backend.hcl.bak
    
    print_status "Terraform state storage is ready."
    print_status "Storage Account: $STORAGE_ACCOUNT_NAME"
    print_status "Resource Group: $RESOURCE_GROUP_NAME"
}

# Initialize Terraform
terraform_init() {
    print_status "Initializing Terraform..."
    terraform init -backend-config=backend.hcl
}

# Plan Terraform deployment
terraform_plan() {
    print_status "Planning Terraform deployment..."
    terraform plan -out=tfplan
}

# Apply Terraform deployment in phases to handle Kubernetes provider dependencies
terraform_apply() {
    print_status "Applying Terraform deployment in phases..."
    
    # Phase 1: Deploy Azure infrastructure (no Kubernetes resources)
    print_status "Phase 1: Deploying Azure infrastructure..."
    terraform apply -var="deploy_kubernetes_resources=false" tfplan
    
    # Configure kubectl access to the newly created AKS cluster
    print_status "Configuring kubectl access to AKS cluster..."
    get_kubeconfig
    
    # Phase 2: Deploy Kubernetes resources now that cluster exists
    print_status "Phase 2: Deploying Kubernetes workload identity resources..."
    terraform plan -var="deploy_kubernetes_resources=true" -out=kubernetes-plan.tfplan
    terraform apply kubernetes-plan.tfplan
}

# Get kubeconfig
get_kubeconfig() {
    print_status "Getting kubeconfig..."
    
    RESOURCE_GROUP=$(terraform output -raw resource_group_name)
    CLUSTER_NAME=$(terraform output -raw aks_cluster_name)
    
    az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --overwrite-existing
    
    print_status "Kubeconfig updated successfully."
}

# Main deployment function
main() {
    print_status "Starting AKS Workload Identity deployment..."
    
    check_prerequisites
    azure_login
    
    # Ask if user wants to create state storage
    read -p "Do you want to create a new storage account for Terraform state? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        create_state_storage
    else
        print_warning "Please ensure backend.hcl is configured with your existing storage account details."
    fi
    
    terraform_init
    terraform_plan
    
    # Ask for confirmation before applying
    read -p "Do you want to apply the Terraform plan? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        terraform_apply
        
        print_status "Deployment completed successfully!"
        print_status "Your AKS cluster is ready with workload identity configured."
        print_status ""
        print_status "Next steps:"
        print_status "1. Test the workload identity configuration"
        print_status "2. Deploy your applications using the configured service account"
        print_status ""
        print_status "Service Account: $(terraform output -raw workload_identity_client_id)"
        print_status "Namespace: default"
    else
        print_warning "Deployment cancelled."
    fi
}

# Run main function
main "$@"
