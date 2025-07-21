#!/bin/bash

# Verification script for dev container setup
echo "=== Dev Container Setup Verification ==="

echo "✅ Checking Azure CLI..."
az version --output table | head -5

echo "✅ Checking kubectl..."
kubectl version --client

echo "✅ Checking kubelogin..."
kubelogin --version

echo "✅ Checking Terraform..."
terraform version

echo "✅ Checking Helm..."
helm version

echo "✅ Checking GitHub CLI..."
gh --version

echo "=== All tools are ready! ==="
