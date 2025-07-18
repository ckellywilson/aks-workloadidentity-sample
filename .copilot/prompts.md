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

### Entra ID Group-Based Admin Access (NEWLY ADDED)
- **Purpose**: Enable Azure AD group members to access and manage the AKS cluster
- **Implementation**: Configure admin_group_object_ids in azure_active_directory_role_based_access_control
- **Current User Access**: Automatically grants cluster admin access to the deploying user/service principal
- **Benefits**: Centralized access management through Azure AD groups
- **Status**: ✅ IMPLEMENTED - Admin groups can now be configured via terraform.tfvars

## Configuration Instructions

### Adding Azure AD Admin Groups
1. **Find Group Object IDs**:
   ```bash
   # Azure CLI
   az ad group show --group "AKS-Admins" --query id --output tsv
   
   # PowerShell
   (Get-AzADGroup -DisplayName "AKS-Admins").Id
   ```

2. **Update terraform.tfvars**:
   ```hcl
   admin_group_object_ids = [
     "12345678-1234-1234-1234-123456789012",  # AKS-Admins group
     "87654321-4321-4321-4321-210987654321"   # DevOps-Team group
   ]
   ```

3. **Deploy**:
   ```bash
   cd infra/tf
   terraform plan
   terraform apply
   ```

### Access Pattern
- **Admin Groups**: Full cluster admin access via Azure RBAC
- **Deploying User**: Automatic cluster admin access granted during deployment
- **Workload Pods**: Access Azure services via workload identity (managed identities)
- **Node Operations**: Handled by kubelet identity (ACR pulls, etc.)

## Development Guidelines

### When Making Changes
1. **Preserve Workload Identity**: Do NOT modify the workload identity setup - it's needed for pod-to-storage authentication
2. **Maintain UAMI Separation**: Keep separate managed identities for kubelet, cluster, and workload operations
3. **Test Admin Access**: Verify group members can access cluster after changes
4. **Validate Current User Access**: Ensure deploying user retains cluster access

### Security Considerations
- Local accounts are disabled (`local_account_disabled = true`)
- Azure RBAC is enabled for fine-grained permissions
- Admin access is controlled through Azure AD groups
- Workload identity provides secure pod-to-Azure authentication
- Each identity has minimum required permissions

### Deployment Best Practices
- Use the provided deployment scripts in `infra/tf/`
- Backend state is managed separately to avoid circular dependencies
- Always validate group Object IDs before deployment
- Test cluster access with group members before production use

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
# Get cluster credentials
az aks get-credentials --resource-group akswlid-dev-rg --name akswlid-dev-aks

# Verify access
kubectl get nodes
```

## Implementation Status
- ✅ Workload Identity: Fully implemented and operational
- ✅ Separate UAMIs: Kubelet, cluster, and workload identities configured
- ✅ Azure AD Integration: Enabled with admin group support
- ✅ Current User Access: Deploying user automatically granted admin access
- ✅ ACR Integration: Kubelet identity has AcrPull permissions
- ✅ Storage Integration: Available for Terraform state and general use

## Notes for Copilot/AI Development
- This configuration is production-ready and follows Azure best practices
- Workload identity setup is complete and should not be modified
- Admin group configuration allows for scalable access management
- All security features are enabled (Azure RBAC, disabled local accounts)
- The architecture supports both human admin access and automated pod authentication
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
