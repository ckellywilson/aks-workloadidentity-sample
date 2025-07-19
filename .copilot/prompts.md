# Copilot Development Prompts and Instructions

## Project Overview
This repository contains a production-ready Terraform configuration for deploying an Azure Kubernetes Service (AKS) cluster with Workload Identity, Azure Container Registry (ACR), and Azure Storage Account integration.

## Architecture Principles

### Workload Identity (KEEP AS-IS)
- **Purpose**: Enable AKS pods to securely authenticate to Azure services using managed identities
- **Components**: Federated credentials, service accounts, and OIDC integration
- **Use Case**: Allows pods to access Azure Storage, Key Vault, and other Azure services without storing credentials
- **Status**: ✅ IMPLEMENTED - Keep all workload identity functionality for pod-to-storage connectivity

### Separate User Assigned Managed Identities (KEEP AS-IS)
- **Kubelet Identity**: Used for node-level operations (pulling container images from ACR)
- **Cluster Identity**: Used for cluster management operations
- **Workload Identity**: Used for pod-level authentication to Azure services
- **Rationale**: Best practice to separate concerns and follow principle of least privilege
- **Status**: ✅ IMPLEMENTED - Keep separate UAMIs as recommended Azure best practice

### Entra ID Group-Based Admin Access (NEWLY ENHANCED)
- **Purpose**: Enable Azure AD group members to access and manage the AKS cluster
- **Auto-Creation**: Automatically creates '{cluster-name}-admins' group with current user as owner/member
- **Implementation**: Uses azuread_group resource with comprehensive Azure RBAC role assignments
- **Current User Access**: Automatically grants cluster admin access to the deploying user/service principal
- **Benefits**: Centralized access management through Azure AD groups + immediate access
- **Status**: ✅ IMPLEMENTED - Automatic admin group creation + optional additional groups

### Azure Naming Standards (CRITICAL - NEWLY ENHANCED)
- **Pattern**: `{project}-{environment}-{region}-{resource-type}`
- **Region Abbreviations**: Comprehensive mapping for 30+ Azure regions (cus, eus, we, etc.)
- **Resource Groups**: Three-tier strategy (application, AKS nodes, backend state)
- **Global Uniqueness**: Handles storage accounts and container registries correctly
- **Status**: ✅ IMPLEMENTED - Full Microsoft Azure naming compliance

### Two-Phase Deployment (INFRASTRUCTURE RELIABILITY)
- **Phase 1**: Deploy Azure infrastructure (AKS, storage, managed identities)
- **Phase 2**: Configure kubeconfig and deploy Kubernetes resources
- **Purpose**: Eliminates Kubernetes provider circular dependencies
- **Benefits**: Reliable deployment without chicken-and-egg problems
- **Status**: ✅ IMPLEMENTED - Automated deployment script handles phases

## Configuration Instructions

### Setting Up Your Environment
1. **Clone or Create Project Structure**:
   ```bash
   mkdir my-aks-project
   cd my-aks-project
   mkdir -p infra/tf/modules/{aks,storage,container_registry,managed_identity,workload_identity}
   mkdir -p examples docs
   ```

2. **Configure Project Variables**:
   ```hcl
   # infra/tf/terraform.tfvars
   project_name = "myproj"      # Max 10 chars, lowercase alphanumeric
   environment  = "dev"         # dev, stg, prod
   location     = "East US"     # Your preferred Azure region
   
   # Subscription and cluster settings
   subscription_id    = "your-subscription-id"
   kubernetes_version = "1.30.12"
   node_count         = 3
   vm_size           = "Standard_B2s"
   ```

### Adding Azure AD Admin Groups
1. **Automatic Group**: '{project}-{environment}-{region}-aks-admins' created automatically
2. **Optional Additional Groups**:
   ```bash
   # Find Group Object IDs
   az ad group show --group "AKS-Admins" --query id --output tsv
   
   # PowerShell alternative
   (Get-AzADGroup -DisplayName "AKS-Admins").Id
   ```

3. **Update terraform.tfvars** (optional additional groups):
   ```hcl
   # AUTOMATIC: myproj-dev-eus-aks-admins group created with current user
   # OPTIONAL: Add additional groups here
   admin_group_object_ids = [
     "12345678-1234-1234-1234-123456789012",  # Additional AKS-Admins group
     "87654321-4321-4321-4321-210987654321"   # Additional DevOps-Team group
   ]
   ```

3. **Deploy**:
   ```bash
   cd infra/tf
   ./deploy.sh    # Automated two-phase deployment
   # OR manual approach:
   terraform init -backend-config=backend.hcl
   terraform plan
   terraform apply
   ```

### Generated Resource Names (Examples)
```bash
# East US Development Environment (project: myproj, env: dev, region: East US)
Resource Group:         myproj-dev-eus-rg
AKS Cluster:           myproj-dev-eus-aks
AKS Node RG:           myproj-dev-eus-aks-nodes-rg
Storage Account:       myprojdeveusst
Container Registry:    myprojdeveuscr
Admin Group:           myproj-dev-eus-aks-admins
Backend State RG:      tfstate-mgmt-rg

# Production West Europe (project: myproj, env: prod, region: West Europe)
Resource Group:         myproj-prod-we-rg
AKS Cluster:           myproj-prod-we-aks
Storage Account:       myprojprodwest
Container Registry:    myprojprodwecr
Admin Group:           myproj-prod-we-aks-admins
```

### Access Pattern
- **Auto-Created Admin Group**: Current user automatically added as owner/member
- **Additional Admin Groups**: Optional supplementary groups via admin_group_object_ids
- **Deploying User**: Automatic cluster admin access granted during deployment (dual roles)
- **Workload Pods**: Access Azure services via workload identity (managed identities)
- **Node Operations**: Handled by kubelet identity (ACR pulls, etc.)
- **Resource Groups**: Three-tier separation (app, nodes, state management)

## Development Guidelines

### When Making Changes
1. **Preserve Workload Identity**: Do NOT modify the workload identity setup - it's needed for pod-to-storage authentication
2. **Maintain UAMI Separation**: Keep separate managed identities for kubelet, cluster, and workload operations
3. **Follow Naming Standards**: Use the Microsoft Azure naming patterns with region abbreviations
4. **Test Admin Access**: Verify group members can access cluster after changes
5. **Validate Deployment Phases**: Ensure two-phase deployment works correctly
6. **Validate Current User Access**: Ensure deploying user retains cluster access

### Security Considerations
- Local accounts are disabled (`local_account_disabled = true`)
- Azure RBAC is enabled for fine-grained permissions
- Admin access is controlled through automatic + optional Azure AD groups
- Workload identity provides secure pod-to-Azure authentication
- Each identity has minimum required permissions
- Two-phase deployment prevents configuration drift
- Region-specific naming prevents resource conflicts

### Deployment Best Practices
- Use the provided two-phase deployment scripts in `infra/tf/`
- Backend state is managed separately to avoid circular dependencies
- Region abbreviations are automatically mapped from location
- Always validate group Object IDs before deployment
- Test cluster access with group members before production use
- Follow Microsoft Azure naming conventions with region inclusion

## Common Tasks

### Adding New Admin Group
```hcl
# In terraform.tfvars, add to existing list:
admin_group_object_ids = [
  "existing-group-id-1",
  "existing-group-id-2",
  "new-group-id-here"
]
```

### Troubleshooting Access Issues
1. Verify group Object ID is correct
2. Check group membership in Azure AD
3. Ensure user has Azure CLI/kubectl configured
4. Validate cluster RBAC assignments

### Connecting to Cluster
```bash
# Get cluster credentials (using generated names)
az aks get-credentials --resource-group myproj-dev-eus-rg --name myproj-dev-eus-aks

# Verify access
kubectl get nodes
kubectl get pods --all-namespaces

# Check admin group membership
kubectl auth can-i "*" "*" --as=abe96c86-3320-4b17-b7d6-44edb0615b9a
```

## Implementation Status
- ✅ Workload Identity: Fully implemented and operational
- ✅ Separate UAMIs: Kubelet, cluster, and workload identities configured
- ✅ Azure AD Integration: Enabled with automatic admin group creation
- ✅ Current User Access: Deploying user automatically granted admin access
- ✅ Additional Admin Groups: Support for optional supplementary groups
- ✅ ACR Integration: Kubelet identity has AcrPull permissions
- ✅ Storage Integration: Available for Terraform state and general use
- ✅ Azure Naming Standards: Microsoft-compliant naming with region abbreviations
- ✅ Three-Tier Resource Groups: Application, AKS nodes, backend state separation
- ✅ Two-Phase Deployment: Eliminates circular dependencies and deployment issues

## Notes for Copilot/AI Development
- This configuration is production-ready and follows Azure best practices
- Workload identity setup is complete and should not be modified
- Admin group configuration allows for scalable access management
- All security features are enabled (Azure RBAC, disabled local accounts)
- The architecture supports both human admin access and automated pod authentication
- local_account_disabled = true (force AAD authentication)
- role_based_access_control_enabled = true
- Network configuration with appropriate security groups

NAMING CONVENTIONS (CRITICAL - UPDATED):
- Central naming logic in locals block with region abbreviation mapping
- Pattern: {project}-{environment}-{region}-{resource-type}
- Region abbreviations: 30+ Azure regions mapped (cus, eus, eus2, wus2, we, ne, etc.)
- Storage account: {project}{environment}{region}st (no hyphens, max 24 chars, lowercase)
- Container registry: {project}{environment}{region}cr (alphanumeric only, max 50 chars)
- Resource group: {project}-{environment}-{region}-rg
- AKS cluster: {project}-{environment}-{region}-aks
- AKS node RG: {project}-{environment}-{region}-aks-nodes-rg
- Managed identities: {project}-{environment}-{region}-{type}-id
- Admin group: {project}-{environment}-{region}-aks-admins
- Backend state RG: tfstate-mgmt-rg (separate from application resources)
- Project name validation: max 10 chars, lowercase alphanumeric only
- Environment validation: dev, stg, prod, test, staging, production
- Default values: project_name="akswlid", environment="dev", location="Central US"

REQUIRED FILES TO GENERATE:
1. infra/tf/main.tf - Main configuration with modules and providers
2. infra/tf/variables.tf - All input variables with validation rules
3. infra/tf/outputs.tf - All resource outputs for integration
4. infra/tf/terraform.tfvars - Default variable values
5. infra/tf/backend.hcl.template - Backend configuration template
6. infra/tf/modules/storage/main.tf, variables.tf, outputs.tf
7. infra/tf/modules/container_registry/main.tf, variables.tf, outputs.tf
8. infra/tf/modules/managed_identity/main.tf, variables.tf, outputs.tf
9. infra/tf/modules/aks/main.tf, variables.tf, outputs.tf (WITH AAD/RBAC/OIDC)
10. infra/tf/modules/workload_identity/main.tf, variables.tf, outputs.tf

AUTOMATION SCRIPTS:
- infra/tf/deploy.sh: Complete deployment with prerequisites check, Azure login, backend state storage creation
- infra/tf/validate.sh: Comprehensive validation including workload identity testing
- infra/tf/cleanup.sh: Safe resource destruction
- All scripts with proper error handling and colored output

SECURITY & COMPLIANCE:
- No hardcoded secrets anywhere
- Managed identity authentication throughout
- Proper RBAC assignments for ACR access
- Azure RBAC for cluster access control
- Resource tagging for governance
- Input validation to prevent misconfigurations

EXAMPLES & DOCUMENTATION:
- examples/ directory with test pods demonstrating workload identity
- README.md with complete setup and usage instructions
- NAMING.md with detailed naming conventions
- CUSTOMER_GUIDE.md with step-by-step deployment instructions
- .gitignore for Terraform-specific exclusions

Generate complete, working code for all these components following Terraform best practices and organize all infrastructure code in infra/tf/ directory.

---

# 🚀 How to Use These Prompts to Create Your Own Environment

## Step 1: Set Up Your Project

### 1.1 Create Project Structure
```bash
mkdir my-aks-workload-identity-project
cd my-aks-workload-identity-project

# Create the required directory structure
mkdir -p infra/tf/modules/{aks,storage,container_registry,managed_identity,workload_identity}
mkdir -p examples docs .copilot
```

### 1.2 Copy This Prompt File
```bash
# Copy this prompts.md to your project
cp /path/to/this/prompts.md .copilot/prompts.md
```

## Step 2: Generate Infrastructure with GitHub Copilot

### 2.1 Generate Core Terraform Files
**In GitHub Copilot Chat, use this prompt:**

```
Using the specifications in .copilot/prompts.md, generate a complete Terraform configuration for an AKS cluster with workload identity. 

Requirements:
- Follow the Microsoft Azure naming conventions with region abbreviations
- Implement automatic Entra group creation with current user access
- Use two-phase deployment to handle Kubernetes provider dependencies
- Include all security best practices (Azure RBAC, disabled local accounts)
- Generate all required modules: aks, storage, container_registry, managed_identity, workload_identity
- Include comprehensive validation and outputs
- Create deployment automation scripts

Project settings:
- project_name: "myproject" (change this to your project name, max 10 chars)
- environment: "dev" 
- location: "East US" (change to your preferred region)

Generate the complete file structure and all Terraform code.
```

### 2.2 Generate Deployment Scripts
**Follow up with:**

```
Generate the deployment automation scripts referenced in the prompts.md:
- deploy.sh: Two-phase deployment with prerequisites check
- validate.sh: Comprehensive validation including workload identity testing  
- cleanup.sh: Safe resource destruction
- All scripts with proper error handling and colored output
```

### 2.3 Generate Documentation
**Follow up with:**

```
Generate comprehensive documentation based on the prompts.md specifications:
- README.md: Complete setup and usage instructions
- NAMING.md: Detailed naming conventions with examples for my project settings
- CUSTOMER_GUIDE.md: Step-by-step deployment instructions
- examples/: Test pod YAML files demonstrating workload identity
```

## Step 3: Customize for Your Environment

### 3.1 Update Project Variables
Edit `infra/tf/terraform.tfvars`:
```hcl
# Your project settings
project_name         = "myproj"      # Max 10 chars, lowercase alphanumeric
environment          = "dev"         # dev, stg, prod, test, staging, production  
location             = "East US"     # Your Azure region
subscription_id      = "your-subscription-guid"

# AKS settings
kubernetes_version   = "1.30.12"
node_count          = 3
vm_size             = "Standard_B2s"

# Optional: Additional admin groups (auto-group created automatically)
admin_group_object_ids = [
  # "12345678-1234-1234-1234-123456789012"  # Optional additional groups
]
```

### 3.2 Generated Resource Names Preview
With your settings, resources will be named:
```bash
# Example: project_name="myproj", environment="dev", location="East US"
Resource Group:         myproj-dev-eus-rg
AKS Cluster:           myproj-dev-eus-aks  
AKS Node RG:           myproj-dev-eus-aks-nodes-rg
Storage Account:       myprojdeveusst
Container Registry:    myprojdeveuscr
Admin Group:           myproj-dev-eus-aks-admins (auto-created)
Workload Identity:     myproj-dev-eus-workload-id
Backend State RG:      tfstate-mgmt-rg
```

## Step 4: Deploy Your Infrastructure

### 4.1 Automated Deployment
```bash
cd infra/tf

# Make scripts executable
chmod +x *.sh

# Deploy with automation (recommended)
./deploy.sh
```

### 4.2 Manual Deployment (Alternative)
```bash
# Initialize Terraform
terraform init -backend-config=backend.hcl

# Plan deployment
terraform plan -out=tfplan

# Apply Phase 1 (Azure infrastructure)
terraform apply -var="deploy_kubernetes_resources=false" tfplan

# Configure kubectl access
az aks get-credentials --resource-group myproj-dev-eus-rg --name myproj-dev-eus-aks

# Apply Phase 2 (Kubernetes resources)
terraform plan -var="deploy_kubernetes_resources=true" -out=k8s-plan.tfplan
terraform apply k8s-plan.tfplan
```

## Step 5: Verify Your Deployment

### 5.1 Test Cluster Access
```bash
# Verify kubectl access
kubectl get nodes
kubectl get pods --all-namespaces

# Check your admin group membership
kubectl auth can-i "*" "*"
```

### 5.2 Test Workload Identity
```bash
# Deploy test pod (generated in examples/)
kubectl apply -f examples/test-pod.yaml

# Check if pod can authenticate to Azure
kubectl logs test-workload-identity-pod
```

### 5.3 Run Validation Script
```bash
./validate.sh  # Comprehensive validation including workload identity
```

## Step 6: Customize and Extend

### 6.1 Add Additional Environments
```bash
# Create staging environment
cp terraform.tfvars terraform-staging.tfvars

# Edit for staging
# environment = "stg"
# location = "West US 2"  # Different region for separation

# Deploy staging
terraform workspace new staging
terraform plan -var-file="terraform-staging.tfvars"
```

### 6.2 Add Additional Admin Groups
```bash
# Find your existing Azure AD groups
az ad group list --display-name "DevOps*" --query "[].{Name:displayName,Id:id}" -o table

# Add to terraform.tfvars
admin_group_object_ids = [
  "your-devops-group-id",
  "your-security-group-id"
]

# Apply changes
terraform plan
terraform apply
```

## 🎯 Key Benefits of This Approach

### ✅ **Complete Automation**
- GitHub Copilot generates all code based on best practices
- Automated deployment scripts handle complex scenarios
- Two-phase deployment eliminates dependency issues

### ✅ **Production Ready**
- Microsoft Azure naming standards compliance
- Comprehensive security configuration
- Enterprise-grade access management

### ✅ **Immediate Access**
- Current user automatically gets cluster admin access
- No manual Azure AD group setup required
- Ready to use kubectl commands immediately

### ✅ **Scalable & Maintainable**
- Modular Terraform architecture
- Proper state management
- Comprehensive documentation generated

### ✅ **Multi-Environment Support**
- Region-aware naming prevents conflicts
- Easy environment replication
- Consistent resource organization

## 🔧 Troubleshooting

### Common Issues and Solutions

**Issue**: "Kubernetes provider connection failed"
```bash
# Solution: Ensure two-phase deployment completed
./deploy.sh  # This handles phasing automatically
```

**Issue**: "Cannot access cluster nodes"
```bash
# Solution: Verify group membership and re-get credentials
az aks get-credentials --resource-group myproj-dev-eus-rg --name myproj-dev-eus-aks --overwrite-existing
kubectl get nodes
```

**Issue**: "Workload identity not working"
```bash
# Solution: Verify service account and federated credential
kubectl describe serviceaccount workload-identity-sa
kubectl logs your-pod-name
```

This approach gives you a complete, production-ready AKS environment with workload identity in minutes, following all Azure best practices and security standards!
```

## 🔧 **AKS Configuration Refinement Prompt**

Use this follow-up prompt to ensure proper AKS security configuration:

```
Update the AKS module to ensure these security features are properly configured:

1. Azure Active Directory Integration:
   - azure_active_directory_role_based_access_control block properly configured
   - managed = true for AAD integration
   - tenant_id specified
   - azure_rbac_enabled = true

2. Workload Identity Configuration:
   - workload_identity_enabled = true
   - oidc_issuer_enabled = true
   - Proper service account annotations in workload_identity module

3. Security Hardening:
   - local_account_disabled = true (force AAD authentication)
   - role_based_access_control_enabled = true
   - Network security policies
   - Proper node pool configuration with managed identity

4. Add validation in variables.tf to ensure all security features are enabled by default

5. Update outputs.tf to expose OIDC issuer URL and other security-related outputs

Generate the complete updated AKS module configuration with these requirements.
```

## 📋 **What These Prompts Will Generate**

When you use these prompts with GitHub Copilot, you should get:

### **Core Infrastructure**
- ✅ Complete Terraform configuration
- ✅ Modular architecture (5 separate modules)
- ✅ Azure Storage backend configuration
- ✅ Proper provider configuration

### **AKS Security Configuration**
- ✅ Azure Active Directory integration
- ✅ Azure RBAC authorization
- ✅ Workload Identity enabled
- ✅ OIDC issuer enabled
- ✅ Local account disabled (AAD-only)
- ✅ Network security groups

### **Identity & Access Management**
- ✅ Three User Assigned Managed Identities
- ✅ Federated identity credentials
- ✅ ACR integration with managed identity
- ✅ Kubernetes service account configuration
- ✅ Proper RBAC role assignments

### **Automation Scripts**
- ✅ Deployment script (`deploy.sh`)
- ✅ Validation script (`validate.sh`)
- ✅ Cleanup script (`cleanup.sh`)
- ✅ Example applications

### **Documentation**
- ✅ Comprehensive README
- ✅ Naming conventions guide
- ✅ Configuration examples
- ✅ Troubleshooting guide

## 🔄 **Additional Refinement Prompts**

After the initial generation, you can refine with these follow-up prompts:

### **Networking & Security**
```
"Add network security groups with proper ingress/egress rules for AKS cluster"
"Configure private cluster endpoint with authorized IP ranges"
"Add Azure Policy assignments for security compliance"
```

### **Monitoring & Observability**
```
"Add Azure Monitor integration for AKS cluster monitoring"
"Configure Container Insights for detailed pod and node monitoring"
"Add log analytics workspace for centralized logging"
```

### **High Availability & Scaling**
```
"Configure multiple node pools with different VM sizes"
"Add cluster autoscaler configuration"
"Configure availability zones for high availability"
```

## ⚡ **Quick Start with Generated Code**

1. Use the primary prompt above in GitHub Copilot
2. Review and customize the generated configuration
3. Update `terraform.tfvars` with your values
4. Run `./deploy.sh` to deploy the infrastructure
5. Use `./validate.sh` to verify the deployment

## 🔍 **Verification Checklist**

After deployment, verify these features are working:

- [ ] AKS cluster accessible via Azure AD authentication
- [ ] Azure RBAC permissions working correctly
- [ ] Workload Identity functioning (test pod can authenticate)
- [ ] OIDC issuer URL accessible
- [ ] ACR integration working with managed identity
- [ ] No local admin accounts enabled
- [ ] Network security groups properly configured
