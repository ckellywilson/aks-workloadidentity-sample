# GitHub Copilot Prompts for AKS Workload Identity Deployment

## 🎯 **Primary Deployment Prompt**

Use this prompt with GitHub Copilot to generate a complete Terraform deployment for AKS with Workload Identity:

```
I need a complete, production-ready Terraform deployment for Azure Kubernetes Service (AKS) with comprehensive identity and security features. Generate all files following these exact specifications:

CORE INFRASTRUCTURE:
- AKS cluster: Public access, workload identity enabled, OIDC issuer enabled
- Azure Active Directory integration with Azure RBAC enabled
- Azure Container Registry: Connected to AKS with managed identity authentication
- Azure Storage Account: For Terraform state backend with versioning enabled
- Resource Group: To contain all resources
- Three User Assigned Managed Identities:
  * Kubelet identity: For AKS node operations and ACR pull access
  * Cluster identity: For AKS cluster operations
  * Workload identity: For pod authentication with Azure services

AKS SECURITY FEATURES (CRITICAL):
- Azure Active Directory (AAD) integration enabled
- Azure RBAC authorization enabled (not Kubernetes RBAC)
- Workload Identity enabled for pod-level identity
- OIDC issuer enabled for federated authentication
- Network security groups with appropriate rules
- Private cluster endpoint (optional but recommended)

WORKLOAD IDENTITY SETUP:
- Federated identity credential linking Azure AD to Kubernetes service account
- Kubernetes service account with proper workload identity annotations
- OIDC integration between AKS and Azure AD
- No secrets stored anywhere - use federated credentials only
- Proper Azure RBAC role assignments for workload identity

TERRAFORM ARCHITECTURE:
- Main configuration with provider setup (azurerm, azuread, kubernetes)
- Remote backend configuration for Azure Storage
- Organize all Terraform code in infra/tf/ directory
- Five separate modules in infra/tf/modules/ directory:
  1. storage/ - Storage account and container for app data
  2. container_registry/ - ACR with proper configuration
  3. managed_identity/ - Three UAMI resources with role assignments
  4. aks/ - AKS cluster with AAD, RBAC, workload identity, and OIDC
  5. workload_identity/ - Federated credentials and K8s service account

AKS MODULE REQUIREMENTS:
- azure_active_directory_role_based_access_control enabled
- workload_identity_enabled = true
- oidc_issuer_enabled = true
- local_account_disabled = true (force AAD authentication)
- role_based_access_control_enabled = true
- Network configuration with appropriate security groups

NAMING CONVENTIONS (CRITICAL):
- Central naming logic in locals block
- Pattern: {project}-{environment}-{resource-type}
- Storage account: {project}{environment}st (no hyphens, max 24 chars, lowercase)
- Container registry: {project}{environment}acr (alphanumeric only, max 50 chars)
- Resource group: {project}-{environment}-rg
- AKS cluster: {project}-{environment}-aks
- Managed identities: {project}-{environment}-{type}-mi
- Project name validation: max 10 chars, lowercase alphanumeric only
- Default values: project_name="akswlid", environment="dev"

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
