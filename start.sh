#!/bin/bash

# Quick n    echo "📚 Additional Documentation:"
    echo "  🔐 Azure AD Groups Setup:        docs/azure-ad-admin-groups.md"
    echo "  🤖 Development Instructions:     .copilot/prompts.md"
    echo "  📝 Naming Conventions:           NAMING.md"ation script for AKS Workload Identity deployment

echo "🚀 AKS Workload Identity Deployment"
echo "==================================="
echo ""
echo "📖 Primary Documentation: README.md (comprehensive guide)"
echo ""

# Check if we're in the right directory
if [ -f "infra/tf/main.tf" ]; then
    echo "✅ Found Terraform configuration in infra/tf/"
    echo ""
    echo "🎯 Quick Actions:"
    echo "  1. � Read the comprehensive guide:  less README.md"
    echo "  2. 🔐 Configure admin access:        vim infra/tf/terraform.tfvars"
    echo "  3. 🚀 Deploy infrastructure:         cd infra/tf && ./deploy.sh"
    echo "  4. ✅ Validate deployment:           cd infra/tf && ./validate.sh"
    echo "  5. 🧪 Test with examples:            kubectl apply -f examples/test-pod.yaml"
    echo "  6. 🧹 Cleanup resources:             cd infra/tf && ./cleanup.sh"
    echo ""
    echo "� Additional Documentation:"
    echo "  � Azure AD Groups Setup:        docs/azure-ad-admin-groups.md"
    echo "  🤖 Development Instructions:     .copilot/prompts.md"
    echo "  📝 Naming Conventions:           NAMING.md"
    echo ""
    
    read -p "Choose an action (1-6) or press Enter to navigate to Terraform directory: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[1]$ ]]; then
        less README.md
    elif [[ $REPLY =~ ^[2]$ ]]; then
        echo "Opening terraform.tfvars for editing..."
        ${EDITOR:-nano} infra/tf/terraform.tfvars
    elif [[ $REPLY =~ ^[3]$ ]]; then
        echo "Navigating to infra/tf and running deploy.sh..."
        cd infra/tf && ./deploy.sh
    elif [[ $REPLY =~ ^[4]$ ]]; then
        echo "Navigating to infra/tf and running validate.sh..."
        cd infra/tf && ./validate.sh
    elif [[ $REPLY =~ ^[5]$ ]]; then
        echo "Applying example test pod..."
        kubectl apply -f examples/test-pod.yaml
    elif [[ $REPLY =~ ^[6]$ ]]; then
        echo "Navigating to infra/tf and running cleanup.sh..."
        cd infra/tf && ./cleanup.sh
    else
        echo "Navigating to Terraform directory..."
        cd infra/tf
        echo "📂 Now in: $(pwd)"
        echo "Run './deploy.sh' to start deployment"
        exec bash
    fi
else
    echo "❌ Terraform configuration not found in expected location."
    echo "Please ensure you're in the root of the aks-workloadidentity-sample repository."
fi
