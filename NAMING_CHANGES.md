# ✅ **Resource Naming Conventions Updated**

I've standardized all resource naming to follow Azure best practices with "dev" as the environment token. Here's what was implemented:

## 🏗️ **Standardized Naming Pattern**

### **Core Pattern:**
```
{project}-{environment}-{resource-type}
```

### **Special Cases (due to Azure constraints):**
- **Storage Account**: `{project}{environment}st` (no hyphens, max 24 chars)
- **Container Registry**: `{project}{environment}acr` (no hyphens, max 50 chars)

## 📋 **Resource Names with "dev" Environment**

| Resource Type | Name Pattern | Example |
|---------------|--------------|---------|
| Resource Group | `{project}-dev-rg` | `akswlid-dev-rg` |
| AKS Cluster | `{project}-dev-aks` | `akswlid-dev-aks` |
| Storage Account | `{project}devst` | `akswliddevst` |
| Container Registry | `{project}devacr` | `akswliddevacr` |
| Kubelet Identity | `{project}-dev-kubelet-mi` | `akswlid-dev-kubelet-mi` |
| Cluster Identity | `{project}-dev-cluster-mi` | `akswlid-dev-cluster-mi` |
| Workload Identity | `{project}-dev-workload-mi` | `akswlid-dev-workload-mi` |
| Federated Credential | `{project}-dev-federated-cred` | `akswlid-dev-federated-cred` |

## 🔧 **Implementation Changes**

### **1. Centralized Naming Logic**
- Added `locals` block in `main.tf` with standardized naming patterns
- All resource names now generated consistently from a single source

### **2. Module Updates**
- **Storage Module**: Added `storage_account_name` parameter
- **Container Registry Module**: Added `registry_name` parameter  
- **Managed Identity Module**: Added individual name parameters for each identity
- **AKS Module**: Added `cluster_name` parameter

### **3. Project Name Constraints**
- **Length**: Maximum 10 characters
- **Characters**: Lowercase letters and numbers only (a-z, 0-9)
- **Validation**: Added Terraform validation rule
- **Default**: Changed from `aks-workloadidentity` to `akswlid`

### **4. Documentation**
- Created `NAMING.md` with comprehensive naming conventions
- Updated `README.md` with naming constraints
- Added validation rules and examples

## 🎯 **Benefits**

✅ **Azure Compliance**: All names meet Azure resource naming requirements  
✅ **Consistency**: Uniform naming across all resources  
✅ **Scalability**: Easy to deploy multiple environments  
✅ **Clarity**: Clear resource identification by name  
✅ **Validation**: Prevents naming conflicts and errors  

## 🚀 **Usage**

The environment token "dev" is now properly integrated:

```hcl
# terraform.tfvars
project_name = "akswlid"  # Short, compliant name
environment  = "dev"      # Environment token
```

This generates all resource names following the established patterns with "dev" as the environment identifier.
