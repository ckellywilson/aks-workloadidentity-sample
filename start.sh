#!/bin/bash

# Quick navigation script for AKS Workload Identity deployment

echo "🚀 AKS Workload Identity Deployment"
echo "=================================="
echo ""
echo "This script helps you navigate to the correct directory for deployment."
echo ""

# Check if we're in the right directory
if [ -f "infra/tf/main.tf" ]; then
    echo "✅ Found Terraform configuration in infra/tf/"
    echo ""
    echo "Quick commands:"
    echo "  📂 Navigate to Terraform:    cd infra/tf"
    echo "  🏗️  Deploy infrastructure:   cd infra/tf && ./deploy.sh"
    echo "  ✅ Validate deployment:      cd infra/tf && ./validate.sh"
    echo "  🧹 Cleanup resources:        cd infra/tf && ./cleanup.sh"
    echo "  🧪 Test with examples:       kubectl apply -f examples/test-pod.yaml"
    echo ""
    echo "📖 Documentation:"
    echo "  📋 Customer Guide:           cat CUSTOMER_GUIDE.md"
    echo "  📝 Naming Conventions:       cat NAMING.md"
    echo "  🤖 Copilot Prompt:           cat COPILOT_PROMPT.md"
    echo ""
    
    read -p "Do you want to navigate to the Terraform directory? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd infra/tf
        echo "📂 Now in: $(pwd)"
        echo "Run './deploy.sh' to start deployment"
        exec bash
    fi
else
    echo "❌ Terraform configuration not found in expected location."
    echo "Please ensure you're in the root of the aks-workloadidentity-sample repository."
fi
