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
                configure_storage_access  # Ensure current IP has access
                return 0  # Exit early, no need to create anything
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
                # Update backend.hcl to point to this account
                update_backend_config
                configure_storage_access  # Ensure current IP has access
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
        
        # Get current public IP for firewall rules
        local detected_ips
        mapfile -t detected_ips < <(detect_external_ips)
        
        if [ ${#detected_ips[@]} -eq 0 ]; then
            print_warning "Could not determine any external IPs. Using full public access."
            PUBLIC_ACCESS="Enabled"
            DEFAULT_ACTION="Allow"
        else
            print_status "Will configure firewall for ${#detected_ips[@]} detected IP(s)"
            PUBLIC_ACCESS="Enabled"  # Required for IP-based rules
            DEFAULT_ACTION="Deny"
        fi
        
        az storage account create \
            --resource-group $RESOURCE_GROUP_NAME \
            --name $STORAGE_ACCOUNT_NAME \
            --sku Standard_LRS \
            --encryption-services blob \
            --allow-shared-key-access false \
            --allow-blob-public-access false \
            --public-network-access $PUBLIC_ACCESS \
            --min-tls-version TLS1_2 \
            --default-action $DEFAULT_ACTION
        
        # Add IP-based firewall rules for all detected IPs
        if [ ${#detected_ips[@]} -gt 0 ]; then
            print_status "Configuring firewall rules for detected IPs..."
            for ip in "${detected_ips[@]}"; do
                print_status "Adding firewall rule for IP: $ip"
                az storage account network-rule add \
                    --resource-group $RESOURCE_GROUP_NAME \
                    --account-name $STORAGE_ACCOUNT_NAME \
                    --ip-address $ip \
                    --output none || print_warning "Failed to add IP rule for $ip"
            done
            print_status "Waiting 10 seconds for firewall rules to propagate..."
            sleep 10
        fi
        
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
    
    # Create container if it doesn't exist
    az storage container create \
        --name $CONTAINER_NAME \
        --account-name $STORAGE_ACCOUNT_NAME \
        --auth-mode login > /dev/null 2>&1 || true
    
    # Check if running in dev container and provide Portal guidance
    check_dev_container_ip_guidance
    
    # Update backend configuration
    update_backend_config
    
    print_status "Terraform state storage is ready."
    print_status "Storage Account: $STORAGE_ACCOUNT_NAME"
    print_status "Resource Group: $RESOURCE_GROUP_NAME"
}

# Detect multiple potential external IPs for dev containers
detect_external_ips() {
    local ips=()
    
    print_status "Detecting potential external IP addresses..."
    
    # Method 1: Primary IP detection service
    local ip1=$(curl -s https://api.ipify.org 2>/dev/null)
    if [ ! -z "$ip1" ]; then
        ips+=("$ip1")
        print_status "Detected IP via ipify.org: $ip1"
    fi
    
    # Method 2: Alternative IP detection service
    local ip2=$(curl -s http://checkip.amazonaws.com 2>/dev/null | tr -d '\n')
    if [ ! -z "$ip2" ] && [[ ! " ${ips[@]} " =~ " ${ip2} " ]]; then
        ips+=("$ip2")
        print_status "Detected IP via AWS checkip: $ip2"
    fi
    
    # Method 3: Another alternative service
    local ip3=$(curl -s https://icanhazip.com 2>/dev/null | tr -d '\n')
    if [ ! -z "$ip3" ] && [[ ! " ${ips[@]} " =~ " ${ip3} " ]]; then
        ips+=("$ip3")
        print_status "Detected IP via icanhazip.com: $ip3"
    fi
    
    # Method 4: Check environment variables that might contain host info
    if [ ! -z "$CODESPACE_NAME" ]; then
        print_status "Running in GitHub Codespace: $CODESPACE_NAME"
        # Codespaces might have specific IP patterns
    fi
    
    if [ ! -z "$REMOTE_CONTAINERS" ]; then
        print_status "Running in VS Code dev container"
    fi
    
    # Print summary
    if [ ${#ips[@]} -eq 0 ]; then
        print_warning "No external IPs detected"
        return 1
    else
        print_status "Detected ${#ips[@]} potential external IP(s): ${ips[*]}"
        printf '%s\n' "${ips[@]}"
    fi
}

# Check if running in dev container and provide IP guidance
check_dev_container_ip_guidance() {
    local is_dev_container=false
    
    # Check for dev container indicators
    if [ ! -z "$REMOTE_CONTAINERS" ] || [ ! -z "$CODESPACE_NAME" ] || [ -f /.dockerenv ]; then
        is_dev_container=true
    fi
    
    if [ "$is_dev_container" = true ]; then
        print_warning "==== DEV CONTAINER DETECTED ===="
        print_status "You are running in a development container environment."
        print_status "The IP addresses detected automatically may not match what Azure sees."
        print_status ""
        print_status "To ensure proper access to the Terraform backend storage:"
        print_status ""
        print_status "1. Open the Azure Portal: https://portal.azure.com"
        print_status "2. Navigate to: Storage accounts → $STORAGE_ACCOUNT_NAME → Networking"
        print_status "3. Look for 'Client IP address' or recent access attempts"
        print_status "4. Note the IP address shown by Azure Portal"
        print_status "5. If different from detected IPs, manually add it using:"
        print_status "   az storage account network-rule add \\"
        print_status "     --resource-group $RESOURCE_GROUP_NAME \\"
        print_status "     --account-name $STORAGE_ACCOUNT_NAME \\"
        print_status "     --ip-address <PORTAL_SHOWN_IP>"
        print_status ""
        print_status "Resource Group: $RESOURCE_GROUP_NAME"
        print_status "Storage Account: $STORAGE_ACCOUNT_NAME"
        print_status ""
        
        # Show currently detected IPs for comparison
        local detected_ips
        mapfile -t detected_ips < <(detect_external_ips 2>/dev/null || echo "")
        if [ ${#detected_ips[@]} -gt 0 ]; then
            print_status "Currently detected IP(s): ${detected_ips[*]}"
        fi
        
        print_warning "Press Enter to continue after verifying/adding your IP in the Portal..."
        read -r
        
        print_status "Optional: If the Azure Portal shows a different IP than detected,"
        print_status "you can add it now to ensure backend access works."
        read -p "Enter the IP shown in Azure Portal (or press Enter to skip): " PORTAL_IP
        
        if [ ! -z "$PORTAL_IP" ]; then
            # Check if this IP is already added
            local existing_ips
            mapfile -t existing_ips < <(az storage account network-rule list \
                --resource-group $RESOURCE_GROUP_NAME \
                --account-name $STORAGE_ACCOUNT_NAME \
                --query "ipRules[].ipAddressOrRange" \
                --output tsv 2>/dev/null || echo "")
            
            if [[ ! " ${existing_ips[@]} " =~ " ${PORTAL_IP} " ]]; then
                print_status "Adding Portal IP $PORTAL_IP to storage account firewall..."
                if az storage account network-rule add \
                    --resource-group $RESOURCE_GROUP_NAME \
                    --account-name $STORAGE_ACCOUNT_NAME \
                    --ip-address $PORTAL_IP \
                    --output none 2>/dev/null; then
                    print_status "✓ Portal IP $PORTAL_IP added successfully"
                    print_status "Waiting 10 seconds for firewall rules to propagate..."
                    sleep 10
                else
                    print_warning "✗ Failed to add Portal IP $PORTAL_IP"
                fi
            else
                print_status "✓ Portal IP $PORTAL_IP already allowed in firewall"
            fi
        fi
    fi
}

# Configure IP-based access for existing storage account
configure_storage_access() {
    if [ -z "$STORAGE_ACCOUNT_NAME" ]; then
        print_error "Storage account name not set"
        return 1
    fi
    
    print_status "Configuring network access for storage account..."
    
    # Get all potential external IPs
    local detected_ips
    mapfile -t detected_ips < <(detect_external_ips)
    
    if [ ${#detected_ips[@]} -eq 0 ]; then
        print_warning "Could not determine any external IPs. Manual configuration may be required."
        return 1
    fi
    
    # Get existing firewall rules
    local existing_ips
    mapfile -t existing_ips < <(az storage account network-rule list \
        --resource-group $RESOURCE_GROUP_NAME \
        --account-name $STORAGE_ACCOUNT_NAME \
        --query "ipRules[].ipAddressOrRange" \
        --output tsv 2>/dev/null || echo "")
    
    # Add each detected IP if not already present
    local added_count=0
    for ip in "${detected_ips[@]}"; do
        if [[ ! " ${existing_ips[@]} " =~ " ${ip} " ]]; then
            print_status "Adding IP $ip to storage account firewall..."
            if az storage account network-rule add \
                --resource-group $RESOURCE_GROUP_NAME \
                --account-name $STORAGE_ACCOUNT_NAME \
                --ip-address $ip \
                --output none 2>/dev/null; then
                print_status "✓ IP $ip added successfully"
                ((added_count++))
            else
                print_warning "✗ Failed to add IP $ip"
            fi
        else
            print_status "✓ IP $ip already allowed in firewall"
        fi
    done
    
    if [ $added_count -gt 0 ]; then
        print_status "Added $added_count new IP(s) to storage account firewall"
        print_status "Waiting 10 seconds for firewall rules to propagate..."
        sleep 10
    fi
    
    # Show current firewall status
    print_status "Current firewall rules:"
    az storage account network-rule list \
        --resource-group $RESOURCE_GROUP_NAME \
        --account-name $STORAGE_ACCOUNT_NAME \
        --query "ipRules[].ipAddressOrRange" \
        --output table 2>/dev/null || print_warning "Could not retrieve current rules"
    
    # Provide dev container guidance if needed
    check_dev_container_ip_guidance
}

# Helper function to add IP manually if Terraform init fails
add_ip_manually() {
    if [ -z "$STORAGE_ACCOUNT_NAME" ]; then
        print_error "Storage account name not set"
        return 1
    fi
    
    print_status "Manual IP addition helper"
    print_status "If Terraform backend access fails, you can manually add your IP:"
    print_status ""
    
    read -p "Enter the IP address shown in Azure Portal: " MANUAL_IP
    
    if [ ! -z "$MANUAL_IP" ]; then
        print_status "Adding IP $MANUAL_IP to storage account firewall..."
        if az storage account network-rule add \
            --resource-group $RESOURCE_GROUP_NAME \
            --account-name $STORAGE_ACCOUNT_NAME \
            --ip-address $MANUAL_IP \
            --output none 2>/dev/null; then
            print_status "✓ IP $MANUAL_IP added successfully"
            print_status "Waiting 10 seconds for firewall rules to propagate..."
            sleep 10
            print_status "You can now retry: terraform init -backend-config=backend.hcl"
        else
            print_error "✗ Failed to add IP $MANUAL_IP"
        fi
    else
        print_warning "No IP address provided"
    fi
}

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
        print_status "If you're in a dev container, the IP detected automatically may differ"
        print_status "from what Azure services actually see."
        print_status ""
        print_status "Troubleshooting steps:"
        if [ ! -z "$BACKEND_STORAGE_ACCOUNT" ]; then
            print_status "1. Check Azure Portal → Storage accounts → $BACKEND_STORAGE_ACCOUNT → Networking"
        else
            print_status "1. Check Azure Portal → Storage accounts → [your-storage-account] → Networking"
        fi
        print_status "2. Look for your actual IP address in the Portal"
        print_status "3. Add it manually using the helper function below"
        print_status ""
        
        read -p "Would you like to add an IP address manually? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Set storage account name for the helper function
            if [ ! -z "$BACKEND_STORAGE_ACCOUNT" ]; then
                STORAGE_ACCOUNT_NAME="$BACKEND_STORAGE_ACCOUNT"
                RESOURCE_GROUP_NAME="tfstate-mgmt-rg"
                add_ip_manually
            else
                print_error "Could not determine storage account name from backend configuration"
            fi
            print_status "Retrying Terraform initialization..."
            terraform init -backend-config=backend.hcl
        else
            print_error "Terraform initialization failed. Please resolve network access issues."
            exit 1
        fi
    fi
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

# Standalone functions for troubleshooting
# Usage: source deploy.sh && troubleshoot_ip
troubleshoot_ip() {
    RESOURCE_GROUP_NAME="tfstate-mgmt-rg"
    EXISTING_STORAGE_ACCOUNT=$(grep "storage_account_name" backend.hcl 2>/dev/null | sed 's/.*= *"\([^"]*\)".*/\1/')
    if [ ! -z "$EXISTING_STORAGE_ACCOUNT" ] && [ "$EXISTING_STORAGE_ACCOUNT" != "tfstateXXXXXXXX" ]; then
        STORAGE_ACCOUNT_NAME="$EXISTING_STORAGE_ACCOUNT"
        print_status "Troubleshooting IP access for storage account: $STORAGE_ACCOUNT_NAME"
        add_ip_manually
    else
        print_error "No storage account found in backend.hcl"
    fi
}
