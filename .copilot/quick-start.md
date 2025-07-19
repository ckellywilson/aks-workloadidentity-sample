# 🚀 Quick Start: Generate Your AKS Workload Identity Environment

## Copy and Paste This Into GitHub Copilot Chat

```
Generate a complete Azure Kubernetes Service (AKS) environment with workload identity based on the following specifications:

PROJECT SETTINGS:
- project_name: "myproject" (change this - max 10 chars, lowercase alphanumeric)
- environment: "dev"
- location: "East US" (change to your preferred Azure region)
- subscription_id: "your-subscription-guid"

ARCHITECTURE REQUIREMENTS:
✅ AKS cluster with Azure AD integration and Azure RBAC
✅ Workload Identity for secure pod-to-Azure authentication
✅ Three separate User Assigned Managed Identities (kubelet, cluster, workload)
✅ Azure Container Registry with managed identity integration
✅ Azure Storage Account for application data
✅ Automatic Entra ID group creation with current user as admin
✅ Microsoft Azure naming conventions with region abbreviations
✅ Three-tier resource group strategy (app, nodes, backend state)
✅ Two-phase deployment to handle Kubernetes provider dependencies

SECURITY FEATURES:
- local_account_disabled = true (Azure AD only)
- azure_rbac_enabled = true
- workload_identity_enabled = true
- oidc_issuer_enabled = true
- Comprehensive role assignments for cluster access
- Network security groups
- Current user automatically granted cluster admin access

NAMING PATTERN: {project}-{environment}-{region}-{resource-type}
Examples:
- Resource Group: myproject-dev-eus-rg
- AKS Cluster: myproject-dev-eus-aks
- Storage Account: myprojectdeveusst
- Container Registry: myprojectdeveuscr
- Admin Group: myproject-dev-eus-aks-admins

INFRASTRUCTURE MODULES NEEDED:
1. infra/tf/main.tf - Root configuration with locals and naming
2. infra/tf/variables.tf - All variables with validation
3. infra/tf/outputs.tf - Comprehensive outputs
4. infra/tf/terraform.tfvars - Default values
5. infra/tf/backend.hcl.template - Backend configuration
6. infra/tf/modules/aks/ - AKS cluster with security features
7. infra/tf/modules/storage/ - Storage account and containers
8. infra/tf/modules/container_registry/ - ACR with managed identity
9. infra/tf/modules/managed_identity/ - Three UAMIs
10. infra/tf/modules/workload_identity/ - Federated credentials and service accounts

AUTOMATION SCRIPTS NEEDED:
- deploy.sh: Two-phase deployment with error handling
- validate.sh: Comprehensive validation
- cleanup.sh: Safe resource destruction

DOCUMENTATION NEEDED:
- README.md: Complete setup instructions
- NAMING.md: Naming conventions guide
- examples/: Test pods demonstrating workload identity

Generate all files with complete, working Terraform code following Azure best practices.
```

## After Generation: Customize These Files

### 1. Update `infra/tf/terraform.tfvars`
```hcl
project_name         = "myproject"  # CHANGE THIS
environment          = "dev"
location             = "East US"    # CHANGE THIS
subscription_id      = "your-guid" # CHANGE THIS
kubernetes_version   = "1.30.12"
node_count          = 3
vm_size             = "Standard_B2s"
```

### 2. Deploy
```bash
cd infra/tf
chmod +x *.sh
./deploy.sh
```

### 3. Test
```bash
kubectl get nodes
kubectl apply -f examples/test-pod.yaml
./validate.sh
```

## What You'll Get

🎯 **Complete Production Environment**:
- AKS cluster ready for workloads
- Workload identity configured and tested
- Azure AD integration with your user as admin
- All security best practices implemented

🎯 **Automatic Resource Names**:
- myproject-dev-eus-rg (Resource Group)
- myproject-dev-eus-aks (AKS Cluster)
- myprojectdeveusst (Storage Account)
- myproject-dev-eus-aks-admins (Admin Group)

🎯 **Ready to Use**:
- kubectl access configured
- Service account ready for pods
- Examples for testing workload identity
- Comprehensive documentation

🎯 **Enterprise Grade**:
- Microsoft naming standards
- Multi-environment support
- Proper state management
- Security compliance
