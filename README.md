# AKS Workload Identity Sample

A production-ready Terraform configuration for deploying Azure Kubernetes Service (AKS) with Workload Identity, Azure ContainSee [AZD-QUICKSTART.md](AZD-QUICKSTART.md) for details.

## 🐛 Troubleshooting

### Common Issuesgistry (ACR), and private Azure Storage. The deployment follows Azure and Terraform best practices with a modular architecture.

## 🚀 One-Command Deployment

Deploy a complete AKS cluster with workload identity in under 5 minutes:

```bash
git clone <repository-url>
cd aks-workloadidentity-sample
./deploy-now.sh
```

**That's it!** The script will:
- ✅ Check prerequisites (Azure CLI, Terraform, kubectl)
- ✅ Log you into Azure 
- ✅ Auto-configure terraform.tfvars with your subscription
- ✅ Fetch the latest AKS version
- ✅ Deploy the infrastructure
- ✅ Validate the deployment
- ✅ Show you how to test it

## 📋 Prerequisites

Ensure you have these tools installed:
- **Azure CLI**: [Install guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- **Terraform**: [Install guide](https://developer.hashicorp.com/terraform/downloads)  
- **kubectl**: [Install guide](https://kubernetes.io/docs/tasks/tools/)

> 💡 **In a dev container?** All tools are pre-installed! Just run `./deploy-now.sh`

## 🎛️ Alternative: Step-by-Step Deployment

If you prefer manual control or want to customize settings:

### 1. Configure Your Deployment
```bash
cd infra/tf
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # Customize your settings
```

### 2. Deploy Infrastructure
```bash
./deploy.sh  # Deploy everything
./validate.sh  # Validate deployment
```

### 3. Test Workload Identity
```bash
kubectl apply -f examples/test-workload-identity-simple.yaml
kubectl logs workload-identity-test-simple
```

## 🏗️ What Gets Deployed

This deployment creates a secure, production-ready AKS environment:

### � Security Features
- **Azure AD Integration**: Enterprise authentication with group-based admin access
- **Workload Identity**: Pods access Azure services without storing secrets
- **Private Storage**: Azure Storage accessible only through private endpoints
- **Managed Identities**: Separate identities for different purposes (principle of least privilege)
- **No Local Accounts**: Azure AD-only authentication

### 🏛️ Infrastructure Components
- **AKS Cluster**: Azure AD integrated, workload identity enabled
- **Azure Container Registry**: Connected with managed identity authentication
- **Azure Storage**: Private endpoint for secure access
- **Virtual Network**: Custom VNet with dedicated subnets for AKS and private endpoints
- **Managed Identities**: Three separate identities for different roles

### 📊 Resource Organization  
- Consistent naming following Azure best practices
- Comprehensive tagging for cost management
- Modular Terraform architecture for maintainability

## 🧪 Testing Your Deployment

Test workload identity with these examples:

```bash
# Simple test - verify workload identity authentication
kubectl apply -f examples/test-workload-identity-simple.yaml
kubectl logs workload-identity-test-simple

# Private storage test - verify private endpoint connectivity  
kubectl apply -f examples/test-private-storage.yaml
kubectl logs private-storage-test

# Azure Resource Manager test - verify Azure API access
kubectl apply -f examples/test-workload-identity-arm.yaml
kubectl logs workload-identity-test-keyvault
```

## 🔧 Customization Options

### Project Configuration
Edit `infra/tf/terraform.tfvars` to customize:

```hcl
project_name         = "mycompany"     # Your company/project name (max 10 chars)
environment          = "dev"          # dev, staging, prod
location             = "East US"       # Your preferred Azure region
kubernetes_version   = "1.33.1"       # AKS version (auto-updated)
node_count           = 3               # Number of worker nodes
vm_size              = "Standard_B2s"  # VM size for nodes
```

### Azure AD Admin Access
Add Azure AD groups for cluster admin access:

```hcl
admin_group_object_ids = [
  "12345678-1234-1234-1234-123456789012"  # Your Azure AD group Object ID
]
```

Find group Object IDs:
```bash
# Azure CLI
az ad group show --group "AKS-Admins" --query id --output tsv

# PowerShell
(Get-AzADGroup -DisplayName "AKS-Admins").Id
```

## 🧹 Cleanup

Remove all deployed resources:

```bash
cd infra/tf
./cleanup.sh
```

> ⚠️ **Warning**: This will delete all Azure resources created by the deployment
## 📚 Additional Documentation

For detailed technical information:

- **� [Quick Start Guide](QUICKSTART.md)** - 5-minute deployment guide
- **�🗂️ [Documentation Hub](docs/README.md)** - Complete technical documentation
- **🔐 [Azure AD Admin Groups](docs/azure-ad-admin-groups.md)** - Advanced admin access configuration
- **🔍 [Azure Federated Token File](docs/azure-federated-token-file.md)** - Workload identity deep dive
- **🏗️ [Private Storage Architecture](docs/private-storage-architecture.md)** - Private endpoint details
- **🧪 [Examples Guide](examples/README.md)** - Test cases and validation
- **🏗️ [Infrastructure Guide](infra/tf/modules/README.md)** - Terraform module details

## 🚀 Alternative: Azure Developer CLI

For a simpler approach, you can also use Azure Developer CLI:

```bash
azd up  # One command deployment with azd
```

See [AZD-QUICKSTART.md](AZD-QUICKSTART.md) for details.

## � Troubleshooting

### Common Issues

**"Cannot access storage account"**
- Add your IP to the storage account firewall in Azure Portal
- Navigate to: Storage accounts → [storage-name] → Networking → Add your IP

**"Access denied to AKS cluster"**  
- Ensure you're added to the auto-created Azure AD admin group
- Or add your Azure AD group to `admin_group_object_ids` in terraform.tfvars

**"Pod cannot access Azure services"**
- Verify workload identity is properly configured: `kubectl describe sa workload-identity-sa`
- Check pod has the correct label: `azure.workload.identity/use: "true"`

### Get Help

Run the validation script for detailed diagnostics:
```bash
cd infra/tf && ./validate.sh
```

For more help, see the [Documentation Hub](docs/README.md).

---

**🎯 Ready to deploy?** Run `./deploy-now.sh` for a seamless experience!

- **Azure CLI** installed and configured (`az login`)
- **Terraform** (>= 1.5) installed 
- **kubectl** installed (for cluster management)
- **Azure subscription** with Owner or Contributor permissions
- **Bash shell** (for deployment scripts)
- **Azure AD group** for admin access (recommended)

## 📁 Project Structure

```
aks-workloadidentity-sample/
├── 📖 README.md                    # This comprehensive guide
├── 📝 NAMING.md                    # Resource naming conventions (quick reference)
├── 🚀 start.sh                     # Navigation helper script
├── 📁 .copilot/                    # Development and AI instructions
│   ├── prompts.md                  # GitHub Copilot development guide
│   └── security-config.md          # Security configuration reference
├── 📁 docs/                        # 📚 Comprehensive documentation hub
│   ├── README.md                   # 🗂️ Master documentation index
│   ├── azure-ad-admin-groups.md    # 🔐 Azure AD group setup guide
│   └── azure-federated-token-file.md # 🔍 Token mechanism deep dive
├── 📁 examples/                    # 🧪 Example applications and test cases
│   ├── README.md                   # 📖 Examples and testing guide
│   ├── test-storage-access.yaml   # 🔐 Workload identity connectivity test
│   └── inspect-token.yaml         # 🔍 Token inspection and debugging
└── 📁 infra/tf/                   # Terraform deployment
    ├── main.tf                    # Main configuration
    ├── variables.tf               # Input variables
    ├── outputs.tf                 # Output values  
    ├── terraform.tfvars           # Configuration values
    ├── backend.hcl.template       # Backend configuration template
    ├── deploy.sh                  # 🚀 Main deployment script
    ├── cleanup.sh                 # 🧹 Cleanup script
    ├── validate.sh                # ✅ Validation script
    └── modules/                   # Terraform modules
        ├── aks/                   # AKS cluster
        ├── container_registry/    # Azure Container Registry
        ├── managed_identity/      # User Assigned Managed Identities
        ├── storage/              # Storage account
        └── workload_identity/    # Workload identity configuration
```
## 🚀 Deployment Guide

### Step 1: Configure Your Deployment

1. **Navigate to Terraform directory**:
   ```bash
   cd infra/tf
   ```

2. **Update `terraform.tfvars`** with your settings:
   ```hcl
   # Basic Configuration
   project_name         = "myproject"    # Max 10 chars, lowercase alphanumeric
   environment          = "dev"          # dev, staging, prod
   location             = "East US"      # Azure region
   kubernetes_version   = "1.30.12"     # Supported AKS version
   
   # Admin Access (REQUIRED)
   admin_group_object_ids = [
     "12345678-1234-1234-1234-123456789012"  # Your Azure AD group Object ID
   ]
   
   # Optional Customization
   node_count           = 3              # Number of nodes
   vm_size              = "Standard_B2s" # Node VM size
   namespace            = "default"      # K8s namespace
   service_account_name = "workload-identity-sa"
   ```

### Step 2: Deploy Infrastructure

**Option A: Automated Deployment (Recommended)**
```bash
./deploy.sh
```

**Option B: Manual Deployment**
```bash
# Initialize Terraform
terraform init -backend-config=backend.hcl.template

# Plan and apply
terraform plan -out=tfplan
terraform apply tfplan

# Configure kubectl
az aks get-credentials --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw aks_cluster_name)
```

### Step 3: Verify Deployment

```bash
# Check cluster access
kubectl get nodes

# Verify workload identity service account
kubectl get serviceaccount workload-identity-sa

# List managed identities
az identity list --resource-group $(terraform output -raw resource_group_name)

# Test workload identity with example pod
kubectl apply -f ../../examples/test-pod.yaml
```

## 🔧 Using Workload Identity

Once deployed, your pods can authenticate to Azure services without storing secrets:

### Example: Pod with Workload Identity
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: workload-identity-test
  namespace: default
spec:
  serviceAccountName: workload-identity-sa  # Uses the created service account
  containers:
  - name: azure-cli
    image: mcr.microsoft.com/azure-cli:latest
    command: ["/bin/bash", "-c", "sleep 3600"]
    env:
    - name: AZURE_CLIENT_ID
      value: "$(terraform output -raw workload_identity_client_id)"
```

### Testing Workload Identity
```bash
# Deploy test pod
kubectl apply -f examples/test-pod.yaml

# Test Azure authentication from within the pod
kubectl exec -it workload-identity-test -- az account show

# The pod should authenticate automatically using workload identity
```

### Common Workload Identity Patterns
```bash
# Grant workload identity access to storage account
az role assignment create \
  --assignee $(terraform output -raw workload_identity_principal_id) \
  --role "Storage Blob Data Contributor" \
  --scope /subscriptions/<subscription-id>/resourceGroups/<rg-name>/providers/Microsoft.Storage/storageAccounts/<storage-name>

# Grant access to Key Vault
az role assignment create \
  --assignee $(terraform output -raw workload_identity_principal_id) \
  --role "Key Vault Secrets User" \
  --scope /subscriptions/<subscription-id>/resourceGroups/<rg-name>/providers/Microsoft.KeyVault/vaults/<keyvault-name>
```

## 📊 Configuration Reference

### Key Variables

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `project_name` | Short project identifier | `akswlid` | `myapp` |
| `environment` | Environment name | `dev` | `dev`, `staging`, `prod` |
| `location` | Azure region | `centralus` | `East US`, `West Europe` |
| `admin_group_object_ids` | Azure AD admin groups | `[]` | `["12345678-1234-1234-1234-123456789012"]` |
| `kubernetes_version` | AKS version | `1.30.12` | `1.29.9`, `1.30.12` |
| `node_count` | Number of nodes | `3` | `2`, `5`, `10` |
| `vm_size` | Node VM size | `Standard_B2s` | `Standard_D2s_v3` |

> 📋 **Full reference**: See [`variables.tf`](infra/tf/variables.tf) for all configuration options

### Important Outputs

After deployment, use these outputs to integrate with your applications:

```bash
# Get cluster connection command
terraform output kubeconfig_command

# Get workload identity details
terraform output workload_identity_client_id
terraform output workload_identity_principal_id

# Get resource information
terraform output resource_group_name
terraform output aks_cluster_name
terraform output container_registry_login_server
```

## 🛠️ Advanced Topics

### Terraform Modules

This deployment uses modular Terraform architecture:

- **`modules/aks/`**: AKS cluster with Azure AD integration and workload identity
- **`modules/container_registry/`**: Azure Container Registry with managed identity access
- **`modules/managed_identity/`**: Three User Assigned Managed Identities
- **`modules/storage/`**: Storage account for Terraform state and application data
- **`modules/workload_identity/`**: Federated credentials and Kubernetes service account

### State Management

Terraform state is stored in Azure Storage for team collaboration:
- **Storage Account**: Auto-created or specified in `backend.hcl`
- **Container**: `tfstate`
- **State File**: `aks-workloadidentity/terraform.tfstate`

### Security Best Practices

✅ **No Secrets Stored**: Workload identity uses federated credentials  
✅ **Least Privilege**: Separate managed identities for different purposes  
✅ **Azure AD Only**: Local cluster accounts disabled  
✅ **RBAC Enabled**: Fine-grained permissions with Azure RBAC  
✅ **Tagged Resources**: Consistent tagging for governance  

### Customization Options

**Scale the cluster**:
```hcl
node_count = 5
vm_size = "Standard_D2s_v3"
```

**Multiple admin groups**:
```hcl
admin_group_object_ids = [
  "group-1-object-id",
  "group-2-object-id"
]
```

**Different environment**:
```hcl
environment = "production"
location = "West Europe"
```

## 🔍 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Authentication errors | Run `az login` and ensure correct subscription |
| Terraform init fails | Check `backend.hcl` configuration and storage account access |
| kubectl access denied | Verify you're a member of the configured admin groups |
| Workload identity not working | Check service account annotations and federated credentials |

### Debugging Commands

```bash
# Check Azure authentication
az account show

# Validate Terraform configuration
cd infra/tf && terraform validate

# Check cluster status
az aks show --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw aks_cluster_name)

# Verify workload identity setup
kubectl describe serviceaccount workload-identity-sa
kubectl describe federatedidentitycredential

# Test cluster connectivity
kubectl get nodes -v=6  # Verbose output for debugging
```

### Getting Help

1. **Check the troubleshooting section above**
2. **Review Azure documentation**: [AKS Troubleshooting](https://docs.microsoft.com/en-us/azure/aks/troubleshooting)
3. **Workload Identity docs**: [Azure Workload Identity](https://azure.github.io/azure-workload-identity/)
4. **Open an issue** in this repository

## 🧹 Cleanup

To remove all deployed resources:

```bash
cd infra/tf
./cleanup.sh
```

Or manually:
```bash
terraform destroy
```

> ⚠️ **Warning**: This will permanently delete all resources. Ensure you have backups if needed.

## 📚 Additional Resources

### 📖 Complete Documentation Suite
- 🗂️ **[Documentation Hub](docs/README.md)**: Master index and navigation guide
- 📖 **[Naming Conventions](NAMING.md)**: Resource naming guidelines (quick reference)
- 🔐 **[Azure AD Groups Guide](docs/azure-ad-admin-groups.md)**: Detailed admin access setup
- 🔍 **[Token Deep Dive](docs/azure-federated-token-file.md)**: Understanding workload identity internals
- 🧪 **[Examples & Testing](examples/README.md)**: Validation and troubleshooting examples
- 🏗️ **[Infrastructure Guide](infra/tf/modules/README.md)**: Architecture and module documentation
- 🤖 **[Development Guide](.copilot/prompts.md)**: Instructions for developers and AI

### Azure Documentation
- [Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/)
- [Azure Workload Identity](https://docs.microsoft.com/en-us/azure/aks/workload-identity-overview)
- [Azure Container Registry](https://docs.microsoft.com/en-us/azure/container-registry/)
- [Azure RBAC](https://docs.microsoft.com/en-us/azure/role-based-access-control/)

### Terraform Resources
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests if applicable
5. Update documentation
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Questions?** Open an issue or check the [troubleshooting section](#-troubleshooting) above.
