#!/bin/bash

# 🚀 One-Command AKS Workload Identity Deployment
# This script provides a seamless deployment experience for manual (non-AZD) users

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_title() {
    echo -e "${CYAN}▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓${NC}"
    echo -e "${CYAN}▓                                                                    ▓${NC}"
    echo -e "${CYAN}▓${NC}  ${GREEN}🚀 AKS Workload Identity - Seamless Deployment${NC}               ${CYAN}▓${NC}"
    echo -e "${CYAN}▓                                                                    ▓${NC}"
    echo -e "${CYAN}▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓${NC}"
}

print_section() {
    echo -e "\n${BLUE}═══ $1 ═══${NC}"
}

print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC}  $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_action() {
    echo -e "${CYAN}➤${NC} $1"
}

# Check if we're in the right directory
check_directory() {
    if [ ! -f "infra/tf/main.tf" ]; then
        print_error "Please run this script from the root of the aks-workloadidentity-sample repository"
        print_action "Expected structure: ./infra/tf/main.tf should exist"
        exit 1
    fi
}

# Check prerequisites
check_prerequisites() {
    print_section "Checking Prerequisites"
    
    local missing_tools=()
    
    if ! command -v az &> /dev/null; then
        missing_tools+=("Azure CLI")
    fi
    
    if ! command -v terraform &> /dev/null; then
        missing_tools+=("Terraform")
    fi
    
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        echo ""
        echo "📥 Installation instructions:"
        echo "  Azure CLI:  https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        echo "  Terraform:  https://developer.hashicorp.com/terraform/downloads"
        echo "  kubectl:    https://kubernetes.io/docs/tasks/tools/"
        echo ""
        print_action "Install the missing tools and run this script again"
        exit 1
    fi
    
    print_status "All required tools are installed"
}

# Check Azure login
check_azure_login() {
    print_section "Azure Authentication"
    
    if ! az account show &> /dev/null; then
        print_action "Logging in to Azure..."
        az login
    fi
    
    SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    print_status "Logged in to Azure subscription: $SUBSCRIPTION_NAME"
    print_status "Subscription ID: $SUBSCRIPTION_ID"
}

# Auto-configure terraform.tfvars
auto_configure_tfvars() {
    print_section "Auto-Configuring Deployment"
    
    cd infra/tf
    
    # Get current Azure context
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    USER_EMAIL=$(az account show --query user.name -o tsv 2>/dev/null || echo "unknown")
    
    # Get latest AKS version
    print_action "Fetching latest AKS version for centralus..."
    LATEST_AKS_VERSION=$(az aks get-versions --location centralus --query "orchestrators[-1].orchestratorVersion" -o tsv)
    
    # Generate unique project name if needed
    if [ ! -f terraform.tfvars ]; then
        print_action "Creating terraform.tfvars with auto-detected values..."
        
        # Create terraform.tfvars from template with auto-populated values
        cat > terraform.tfvars << EOF
# Auto-generated terraform.tfvars
# Generated on: $(date)
# Azure User: $USER_EMAIL

project_name         = "akswlid"
environment          = "dev"
location             = "centralus"
kubernetes_version   = "$LATEST_AKS_VERSION"
subscription_id      = "$SUBSCRIPTION_ID"
node_count           = 3
vm_size              = "Standard_B2s"
namespace            = "default"
service_account_name = "workload-identity-sa"

# Azure AD Admin Groups Configuration
# AUTOMATIC: A group named "{cluster-name}-admins" is created automatically and the current user is added
# OPTIONAL: Add additional Azure AD group Object IDs for admin access to the AKS cluster
admin_group_object_ids = [
  # Add your Azure AD group Object IDs here (optional)
  # Example: "12345678-1234-1234-1234-123456789012"
]
EOF
        print_status "Created terraform.tfvars with auto-detected values"
    else
        print_status "terraform.tfvars already exists, updating subscription and AKS version..."
        
        # Update existing file with current values
        sed -i.bak "s/subscription_id.*=.*/subscription_id      = \"$SUBSCRIPTION_ID\"/" terraform.tfvars
        sed -i.bak "s/kubernetes_version.*=.*/kubernetes_version   = \"$LATEST_AKS_VERSION\"/" terraform.tfvars
        rm -f terraform.tfvars.bak
        print_status "Updated subscription_id and kubernetes_version"
    fi
    
    echo ""
    print_status "Configuration summary:"
    echo "  📋 Subscription: $SUBSCRIPTION_ID"
    echo "  🚀 AKS Version: $LATEST_AKS_VERSION"
    echo "  📍 Location: centralus"
    echo "  🏷️  Project: akswlid-dev"
    
    cd ../..
}

# Show next steps
show_customization_options() {
    echo ""
    print_section "Customization Options (Optional)"
    echo ""
    echo "Your deployment is ready with sensible defaults, but you can customize:"
    echo ""
    echo "📝 Edit terraform.tfvars to customize:"
    echo "  • project_name: Change from 'akswlid' to your preferred name"
    echo "  • location: Change from 'centralus' to your preferred region"
    echo "  • vm_size: Change from 'Standard_B2s' for different node sizes"
    echo "  • admin_group_object_ids: Add Azure AD groups for admin access"
    echo ""
    echo "🔐 To add Azure AD admin groups:"
    echo "  1. Find group Object ID: az ad group show --group 'YourGroupName' --query id -o tsv"
    echo "  2. Add to admin_group_object_ids array in terraform.tfvars"
    echo ""
    
    read -p "Would you like to edit terraform.tfvars now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ${EDITOR:-nano} infra/tf/terraform.tfvars
        print_status "Configuration updated"
    else
        print_status "Using default configuration"
    fi
}

# Deploy infrastructure
deploy_infrastructure() {
    print_section "Deploying Infrastructure"
    
    cd infra/tf
    
    print_action "Running deployment script..."
    ./deploy.sh
    
    print_status "Infrastructure deployment completed!"
    cd ../..
}

# Validate deployment
validate_deployment() {
    print_section "Validating Deployment"
    
    cd infra/tf
    ./validate.sh
    cd ../..
    
    print_status "Deployment validation completed!"
}

# Show test examples
show_test_examples() {
    print_section "Testing Your Deployment"
    
    echo ""
    echo "🧪 Test your workload identity setup:"
    echo ""
    echo "1. Simple workload identity test:"
    echo "   kubectl apply -f examples/test-workload-identity-simple.yaml"
    echo "   kubectl logs workload-identity-test-simple"
    echo ""
    echo "2. Private storage access test:"
    echo "   kubectl apply -f examples/test-private-storage.yaml"
    echo "   kubectl logs private-storage-test"
    echo ""
    echo "3. Azure Resource Manager test:"
    echo "   kubectl apply -f examples/test-workload-identity-arm.yaml"
    echo "   kubectl logs workload-identity-test-keyvault"
    echo ""
    
    read -p "Would you like to run the simple test now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_action "Running simple workload identity test..."
        kubectl apply -f examples/test-workload-identity-simple.yaml
        echo ""
        print_status "Test pod created. Check logs with:"
        echo "  kubectl logs workload-identity-test-simple"
    fi
}

# Show cleanup instructions
show_cleanup() {
    echo ""
    print_section "Resource Cleanup"
    echo ""
    echo "🧹 When you're done testing, clean up resources:"
    echo "   cd infra/tf && ./cleanup.sh"
    echo ""
    print_warning "This will delete all Azure resources created by this deployment"
}

# Main execution
main() {
    print_title
    echo ""
    echo "This script will deploy a complete AKS cluster with workload identity in one command!"
    echo ""
    
    check_directory
    check_prerequisites
    check_azure_login
    auto_configure_tfvars
    show_customization_options
    
    echo ""
    print_action "Ready to deploy! This will create:"
    echo "  • AKS cluster with workload identity"
    echo "  • Azure Container Registry"
    echo "  • Azure Storage with private endpoints"
    echo "  • Managed identities and RBAC"
    echo ""
    
    read -p "Continue with deployment? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_status "Deployment cancelled. Your configuration is saved in infra/tf/terraform.tfvars"
        exit 0
    fi
    
    deploy_infrastructure
    validate_deployment
    show_test_examples
    show_cleanup
    
    echo ""
    print_section "🎉 Deployment Complete!"
    echo ""
    print_status "Your AKS cluster with workload identity is ready!"
    print_status "Access with: kubectl get nodes"
    print_status "Documentation: README.md"
    echo ""
}

# Run main function
main "$@"
