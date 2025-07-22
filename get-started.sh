#!/bin/bash

# Auto-discovery script to help users find the right entry point
# This can be run from any location and will guide users

echo "🔍 AKS Workload Identity - Finding Your Starting Point"
echo "====================================================="
echo ""

# Check if we're already in the right place
if [ -f "deploy-now.sh" ] && [ -f "infra/tf/main.tf" ]; then
    echo "✅ You're in the aks-workloadidentity-sample directory!"
    echo ""
    echo "🚀 Ready to deploy? Choose an option:"
    echo ""
    echo "  1. One-command deployment:    ./deploy-now.sh"
    echo "  2. Quick start guide:         less QUICKSTART.md"
    echo "  3. Full documentation:        less README.md"
    echo "  4. Step-by-step navigation:   ./start.sh"
    echo ""
    read -p "Enter your choice (1-4): " -n 1 -r
    echo
    
    case $REPLY in
        1) ./deploy-now.sh ;;
        2) less QUICKSTART.md ;;
        3) less README.md ;;
        4) ./start.sh ;;
        *) echo "ℹ️ Run this script again to see options" ;;
    esac
    
elif [ -d "aks-workloadidentity-sample" ]; then
    echo "📁 Found aks-workloadidentity-sample directory!"
    echo "   Navigate there to continue:"
    echo ""
    echo "   cd aks-workloadidentity-sample"
    echo "   ./deploy-now.sh"
    
else
    echo "📦 Repository not found. Let's clone it first:"
    echo ""
    echo "   git clone <repository-url>"
    echo "   cd aks-workloadidentity-sample"
    echo "   ./deploy-now.sh"
    echo ""
    echo "🔗 Replace <repository-url> with the actual repository URL"
fi
