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

# Prompt user to add their IP address manually
prompt_ip_configuration() {
    print_warning "==== NETWORK ACCESS CONFIGURATION REQUIRED ===="
    print_status ""
    print_status "To access the Terraform backend storage account, you need to add your IP address to the firewall."
    print_status ""
    print_status "Please follow these steps:"
    print_status "1. Open the Azure Portal: https://portal.azure.com"
    print_status "2. Navigate to: Storage accounts → $STORAGE_ACCOUNT_NAME → Networking"
    print_status "3. Under 'Firewall and virtual networks', you'll see your current IP address detected"
    print_status "4. Click 'Add your client IP address' or manually add the IP shown"
    print_status "5. Click 'Save' to apply the changes"
    print_status ""
    print_status "Resource Group: $RESOURCE_GROUP_NAME"
    print_status "Storage Account: $STORAGE_ACCOUNT_NAME"
    print_status ""
    print_warning "Please complete the IP configuration in the Azure Portal before continuing."
    print_status ""
    read -p "Press Enter after you have added your IP address in the Azure Portal..."
    
    print_status "Great! The storage account should now be accessible."
}

# Create storage account for Terraform state (if needed)
create_state_storage() {
    print_status "Setting up Terraform state storage..."
    print_status "Note: Backend state resources are managed via Azure CLI, not Terraform"
    
    # Variables for state storage - Following Azure naming standards
    RESOURCE_GROUP_NAME="tfstate-mgmt-rg"  # terraform state management resource group
    CONTAINER_NAME="tfstate"
    LOCATION="Central US"
    
    # Check if there's already a backend.hcl with existing storage account
    if [ -f backend.hcl ]; then
        EXISTING_STORAGE_ACCOUNT=$(grep "storage_account_name" backend.hcl | sed 's/.*= *"\([^"]*\)".*/\1/')
        if [ ! -z "$EXISTING_STORAGE_ACCOUNT" ] && [ "$EXISTING_STORAGE_ACCOUNT" != "tfstateXXXXXXXX" ]; then
            print_status "Found existing storage account in backend.hcl: $EXISTING_STORAGE_ACCOUNT"
            # Check if the storage account actually exists
            if az storage account show --name "$EXISTING_STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP_NAME" &> /dev/null; then
                print_status "Storage account $EXISTING_STORAGE_ACCOUNT exists and will be used."
                STORAGE_ACCOUNT_NAME="$EXISTING_STORAGE_ACCOUNT"
                prompt_ip_configuration
                return 0
            else
                print_warning "Storage account $EXISTING_STORAGE_ACCOUNT from backend.hcl does not exist."
            fi
        fi
    fi
    
    # Check for any existing storage accounts in the resource group
    if az group show --name "$RESOURCE_GROUP_NAME" &> /dev/null; then
        EXISTING_ACCOUNTS=$(az storage account list --resource-group "$RESOURCE_GROUP_NAME" --query "[?contains(name, 'tfstate')].name" -o tsv)
        if [ ! -z "$EXISTING_ACCOUNTS" ]; then
            print_status "Found existing terraform state storage accounts:"
            echo "$EXISTING_ACCOUNTS"
            FIRST_ACCOUNT=$(echo "$EXISTING_ACCOUNTS" | head -n 1)
            read -p "Do you want to use existing storage account '$FIRST_ACCOUNT'? (Y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                STORAGE_ACCOUNT_NAME="$FIRST_ACCOUNT"
                print_status "Using existing storage account: $STORAGE_ACCOUNT_NAME"
                update_backend_config
                prompt_ip_configuration
                return 0
            fi
        fi
    fi
    
    # If we get here, create a new storage account
    STORAGE_ACCOUNT_NAME="tfstate$(date +%s | tail -c 6)"
    print_status "Creating new storage account: $STORAGE_ACCOUNT_NAME"
    
    # Create resource group if it doesn't exist
    if ! az group show --name $RESOURCE_GROUP_NAME &> /dev/null; then
        print_status "Creating resource group for Terraform state..."
        az group create --name $RESOURCE_GROUP_NAME --location "$LOCATION"
    fi
    
    # Create storage account if it doesn't exist
    if ! az storage account show --name $STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP_NAME &> /dev/null; then
        print_status "Creating storage account for Terraform state..."
        
        # Create storage account with network restrictions (user will add their IP manually)
        az storage account create \
            --resource-group $RESOURCE_GROUP_NAME \
            --name $STORAGE_ACCOUNT_NAME \
            --sku Standard_LRS \
            --encryption-services blob \
            --allow-shared-key-access false \
            --allow-blob-public-access false \
            --public-network-access Enabled \
            --min-tls-version TLS1_2 \
            --default-action Deny
        
        # Allow Azure services (required for some Azure integrations)
        az storage account update \
            --resource-group $RESOURCE_GROUP_NAME \
            --name $STORAGE_ACCOUNT_NAME \
            --bypass AzureServices \
            --output none
        
        # Ensure current user has required RBAC permissions
        print_status "Configuring RBAC permissions for Terraform state access..."
        CURRENT_USER=$(az account show --query user.name -o tsv)
        STORAGE_ACCOUNT_ID="/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME"
        
        # Assign Storage Blob Data Contributor role (required for state file access)
        az role assignment create \
            --assignee "$CURRENT_USER" \
            --role "Storage Blob Data Contributor" \
            --scope "$STORAGE_ACCOUNT_ID" \
            --output none 2>/dev/null || true
            
        # Assign Storage Account Contributor role (required for container operations)
        az role assignment create \
            --assignee "$CURRENT_USER" \
            --role "Storage Account Contributor" \
            --scope "$STORAGE_ACCOUNT_ID" \
            --output none 2>/dev/null || true
    fi
    
    # Create container if it doesn't exist (this will work after IP is added)
    az storage container create \
        --name $CONTAINER_NAME \
        --account-name $STORAGE_ACCOUNT_NAME \
        --auth-mode login > /dev/null 2>&1 || print_warning "Container creation may require IP configuration first"
    
    # Prompt user to configure IP access
    prompt_ip_configuration
    
    # Update backend configuration
    update_backend_config
    
    print_status "Terraform state storage is ready."
    print_status "Storage Account: $STORAGE_ACCOUNT_NAME"
    print_status "Resource Group: $RESOURCE_GROUP_NAME"
}

# Update backend configuration with current storage account

# Update backend configuration with current storage account
update_backend_config() {
    print_status "Updating backend configuration..."
    if [ ! -f backend.hcl.template ]; then
        print_error "Backend configuration template not found!"
        exit 1
    fi
    
    # Make backend.hcl writable if it exists
    if [ -f backend.hcl ]; then
        chmod 644 backend.hcl
    fi
    
    cp backend.hcl.template backend.hcl
    sed -i.bak "s/storage_account_name = \"tfstateXXXXXXXX\"/storage_account_name = \"$STORAGE_ACCOUNT_NAME\"/" backend.hcl
    sed -i.bak "s/resource_group_name  = \"tfstate-mgmt-rg\"/resource_group_name  = \"$RESOURCE_GROUP_NAME\"/" backend.hcl
    rm -f backend.hcl.bak
    
    # Make backend.hcl read-only to prevent accidental changes
    chmod 444 backend.hcl
}

# Initialize Terraform
terraform_init() {
    print_status "Initializing Terraform..."
    
    # Get storage account name from backend config for error messages
    local BACKEND_STORAGE_ACCOUNT=""
    if [ -f backend.hcl ]; then
        BACKEND_STORAGE_ACCOUNT=$(grep "storage_account_name" backend.hcl | sed 's/.*= *"\([^"]*\)".*/\1/')
    fi
    
    if terraform init -backend-config=backend.hcl; then
        print_status "✓ Terraform backend initialized successfully"
    else
        print_error "✗ Terraform backend initialization failed"
        print_status ""
        print_status "This is likely due to network access restrictions on the storage account."
        print_status ""
        print_status "Please ensure you have added your IP address to the storage account firewall:"
        if [ ! -z "$BACKEND_STORAGE_ACCOUNT" ]; then
            print_status "1. Open Azure Portal → Storage accounts → $BACKEND_STORAGE_ACCOUNT → Networking"
        else
            print_status "1. Open Azure Portal → Storage accounts → [your-storage-account] → Networking"
        fi
        print_status "2. Add your client IP address to the firewall rules"
        print_status "3. Save the changes and wait a few moments for propagation"
        print_status ""
        
        read -p "Press Enter after you have added your IP address to retry initialization..."
        print_status "Retrying Terraform initialization..."
        if terraform init -backend-config=backend.hcl; then
            print_status "✓ Terraform backend initialized successfully"
        else
            print_error "Terraform initialization failed. Please verify your IP is correctly added to the storage account firewall."
            exit 1
        fi
    fi
}

# Plan Terraform deployment
terraform_plan() {
    print_status "Planning Terraform deployment..."
    terraform plan -out=tfplan
}

# Apply Terraform deployment
terraform_apply() {
    print_status "Applying Terraform deployment..."
    terraform apply tfplan
    
    # Configure kubectl access to the newly created AKS cluster
    print_status "Configuring kubectl access to AKS cluster..."
    get_kubeconfig
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
