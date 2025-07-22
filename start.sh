#!/bin/bash

# � AKS Workload Identity - Quick Navigation and Deployment Helper

echo "🚀 AKS Workload Identity Sample"
echo "==============================="
echo ""

# Check if we're in the right directory
if [ -f "infra/tf/main.tf" ]; then
    echo "✅ Repository structure validated"
    echo ""
    echo "🎯 Choose your deployment approach:"
    echo ""
    echo "  1. 🚀 One-Command Deployment (Recommended)"
    echo "     ./deploy-now.sh"
    echo ""
    echo "  2. � Read the Guide First"
    echo "     less README.md"
    echo ""
    echo "  3. �️  Manual Step-by-Step"
    echo "     cd infra/tf && ./deploy.sh"
    echo ""
    echo "  4. 🔧 Customize Configuration"
    echo "     vim infra/tf/terraform.tfvars"
    echo ""
    echo "  5. 🧪 Test Examples"
    echo "     kubectl apply -f examples/"
    echo ""
    echo "  6. 🧹 Cleanup Resources"
    echo "     cd infra/tf && ./cleanup.sh"
    echo ""
    echo "📚 Additional Resources:"
    echo "  • Documentation Hub:            docs/README.md"
    echo "  • Azure AD Groups Setup:        docs/azure-ad-admin-groups.md"
    echo "  • Private Storage Architecture: docs/private-storage-architecture.md"
    echo "  • Examples & Testing:           examples/README.md"
    echo ""
    
    read -p "Choose an action (1-6) or press Enter for one-command deployment: " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[1]$ ]] || [[ -z $REPLY ]]; then
        echo "🚀 Starting one-command deployment..."
        ./deploy-now.sh
    elif [[ $REPLY =~ ^[2]$ ]]; then
        less README.md
    elif [[ $REPLY =~ ^[3]$ ]]; then
        echo "📁 Navigating to infra/tf for manual deployment..."
        cd infra/tf && ./deploy.sh
    elif [[ $REPLY =~ ^[4]$ ]]; then
        echo "⚙️  Opening configuration for editing..."
        if [ ! -f "infra/tf/terraform.tfvars" ]; then
            cp infra/tf/terraform.tfvars.example infra/tf/terraform.tfvars
            echo "✅ Created terraform.tfvars from template"
        fi
        ${EDITOR:-nano} infra/tf/terraform.tfvars
    elif [[ $REPLY =~ ^[5]$ ]]; then
        echo "🧪 Available test examples:"
        echo "  kubectl apply -f examples/test-workload-identity-simple.yaml"
        echo "  kubectl apply -f examples/test-private-storage.yaml"
        echo "  kubectl apply -f examples/test-workload-identity-arm.yaml"
        echo ""
        echo "📖 See examples/README.md for details"
    elif [[ $REPLY =~ ^[6]$ ]]; then
        echo "🧹 Navigating to infra/tf for cleanup..."
        cd infra/tf && ./cleanup.sh
    else
        echo "ℹ️  Invalid option. Run ./start.sh again to see options."
    fi
else
    echo "❌ Error: This doesn't appear to be the aks-workloadidentity-sample repository"
    echo "Expected to find: infra/tf/main.tf"
    echo ""
    echo "Please ensure you're in the root directory of the repository:"
    echo "  git clone <repository-url>"
    echo "  cd aks-workloadidentity-sample"
    echo "  ./start.sh"
fi
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
