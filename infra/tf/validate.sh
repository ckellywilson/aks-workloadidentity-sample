#!/bin/bash

# Validation script for AKS Workload Identity deployment
# This script validates that the infrastructure is properly deployed and configured

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

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if kubectl is available and configured
check_kubectl() {
    print_status "Checking kubectl configuration..."
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed."
        return 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        print_error "kubectl is not configured or cluster is not accessible."
        return 1
    fi
    
    print_success "kubectl is configured and cluster is accessible."
    return 0
}

# Check if Terraform outputs are available
check_terraform_outputs() {
    print_status "Checking Terraform outputs..."
    
    if [ ! -f "terraform.tfstate" ] && [ ! -d ".terraform" ]; then
        print_error "Terraform state not found. Please run terraform init and apply first."
        return 1
    fi
    
    # Check if we can get outputs
    if ! terraform output > /dev/null 2>&1; then
        print_error "Cannot read Terraform outputs. Please ensure Terraform is initialized."
        return 1
    fi
    
    print_success "Terraform outputs are available."
    return 0
}

# Validate AKS cluster
validate_aks_cluster() {
    print_status "Validating AKS cluster..."
    
    # Check if nodes are ready
    if ! kubectl get nodes | grep -q "Ready"; then
        print_error "AKS cluster nodes are not ready."
        return 1
    fi
    
    # Check if system pods are running
    if ! kubectl get pods -n kube-system | grep -q "Running"; then
        print_error "System pods are not running properly."
        return 1
    fi
    
    print_success "AKS cluster is healthy."
    return 0
}

# Validate workload identity configuration
validate_workload_identity() {
    print_status "Validating workload identity configuration..."
    
    # Check if service account exists
    if ! kubectl get serviceaccount workload-identity-sa &> /dev/null; then
        print_error "Workload identity service account not found."
        return 1
    fi
    
    # Check if service account has the required annotation
    if ! kubectl get serviceaccount workload-identity-sa -o jsonpath='{.metadata.annotations.azure\.workload\.identity/client-id}' | grep -q "."; then
        print_error "Service account is missing workload identity annotation."
        return 1
    fi
    
    print_success "Workload identity service account is configured correctly."
    return 0
}

# Test workload identity functionality
test_workload_identity() {
    print_status "Testing workload identity functionality..."
    
    # Get the client ID from Terraform output
    CLIENT_ID=$(terraform output -raw workload_identity_client_id 2>/dev/null || echo "")
    
    if [ -z "$CLIENT_ID" ]; then
        print_error "Cannot get workload identity client ID from Terraform outputs."
        return 1
    fi
    
    # Create a test pod
    print_status "Creating test pod..."
    
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: workload-identity-test
  namespace: default
spec:
  serviceAccountName: workload-identity-sa
  containers:
  - name: test-container
    image: mcr.microsoft.com/azure-cli:latest
    command: ["/bin/bash"]
    args: ["-c", "az account show && echo 'Workload Identity Test Successful' || echo 'Workload Identity Test Failed'"]
    env:
    - name: AZURE_CLIENT_ID
      value: "$CLIENT_ID"
  restartPolicy: Never
EOF
    
    # Wait for pod to complete
    print_status "Waiting for test pod to complete..."
    kubectl wait --for=condition=Ready pod/workload-identity-test --timeout=60s || {
        print_error "Test pod did not become ready in time."
        kubectl logs workload-identity-test || true
        kubectl delete pod workload-identity-test --ignore-not-found=true
        return 1
    }
    
    # Wait for completion
    sleep 10
    
    # Check pod logs
    LOGS=$(kubectl logs workload-identity-test 2>/dev/null || echo "")
    
    if echo "$LOGS" | grep -q "Workload Identity Test Successful"; then
        print_success "Workload identity test passed."
        kubectl delete pod workload-identity-test --ignore-not-found=true
        return 0
    else
        print_error "Workload identity test failed."
        echo "Pod logs:"
        echo "$LOGS"
        kubectl delete pod workload-identity-test --ignore-not-found=true
        return 1
    fi
}

# Validate ACR integration
validate_acr_integration() {
    print_status "Validating ACR integration..."
    
    # Get ACR name from Terraform output
    ACR_NAME=$(terraform output -raw container_registry_name 2>/dev/null || echo "")
    
    if [ -z "$ACR_NAME" ]; then
        print_error "Cannot get ACR name from Terraform outputs."
        return 1
    fi
    
    # Check if ACR exists
    if ! az acr show --name "$ACR_NAME" &> /dev/null; then
        print_error "ACR '$ACR_NAME' not found."
        return 1
    fi
    
    print_success "ACR integration is configured."
    return 0
}

# Display deployment summary
show_deployment_summary() {
    print_status "Deployment Summary:"
    
    echo "Resource Group: $(terraform output -raw resource_group_name 2>/dev/null || echo 'N/A')"
    echo "AKS Cluster: $(terraform output -raw aks_cluster_name 2>/dev/null || echo 'N/A')"
    echo "ACR Name: $(terraform output -raw container_registry_name 2>/dev/null || echo 'N/A')"
    echo "ACR Login Server: $(terraform output -raw container_registry_login_server 2>/dev/null || echo 'N/A')"
    echo "Workload Identity Client ID: $(terraform output -raw workload_identity_client_id 2>/dev/null || echo 'N/A')"
    echo "Storage Account: $(terraform output -raw storage_account_name 2>/dev/null || echo 'N/A')"
    echo ""
    echo "Kubeconfig Command: $(terraform output -raw kubeconfig_command 2>/dev/null || echo 'N/A')"
}

# Main validation function
main() {
    print_status "Starting validation of AKS Workload Identity deployment..."
    echo ""
    
    local failed=0
    
    # Run all validation checks
    check_kubectl || failed=1
    check_terraform_outputs || failed=1
    validate_aks_cluster || failed=1
    validate_workload_identity || failed=1
    test_workload_identity || failed=1
    validate_acr_integration || failed=1
    
    echo ""
    
    if [ $failed -eq 0 ]; then
        print_success "All validation checks passed!"
        echo ""
        show_deployment_summary
        echo ""
        print_status "Your AKS cluster with Workload Identity is ready to use."
        print_status "You can now deploy applications using the 'workload-identity-sa' service account."
    else
        print_error "Some validation checks failed. Please review the errors above."
        exit 1
    fi
}

# Run main function
main "$@"
