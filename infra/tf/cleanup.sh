#!/bin/bash

# Cleanup script for AKS Workload Identity Infrastructure
# This script destroys the infrastructure created by Terraform
# Note: Backend state resources (storage account, resource group) are NOT destroyed
# Use Azure CLI to manually clean up: az group delete --name terraform-state-rg

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

# Check if Terraform is initialized
check_terraform() {
    if [ ! -d ".terraform" ]; then
        print_error "Terraform not initialized. Please run ./deploy.sh first or terraform init."
        exit 1
    fi
}

# Destroy infrastructure
terraform_destroy() {
    print_status "Planning destruction of infrastructure..."
    terraform plan -destroy -out=destroy.tfplan
    
    print_warning "This will destroy all resources created by Terraform!"
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Destroying infrastructure..."
        terraform apply destroy.tfplan
        print_status "Infrastructure destroyed successfully."
    else
        print_status "Destruction cancelled."
        rm -f destroy.tfplan
    fi
}

# Main cleanup function
main() {
    print_status "Starting cleanup of AKS Workload Identity infrastructure..."
    
    check_terraform
    terraform_destroy
    
    print_status "Cleanup completed."
}

# Run main function
main "$@"
