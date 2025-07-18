# AKS Workload Identity Sample

This repository contains a complete Terraform configuration for deploying an Azure Kubernetes Service (AKS) cluster with Workload Identity, Azure Container Registry (ACR), and Azure Storage Account. The deployment follows Terraform best practices with modular architecture.

## Quick Start

For customers who want to get started quickly, run the start script:

```bash
./start.sh
```

This script will guide you to the correct directory and display next steps.

## Deployment Options

### Option 1: Using GitHub Copilot (Recommended)
1. Open GitHub Copilot in your VS Code
2. Use the prompt from [`COPILOT_PROMPT.md`](COPILOT_PROMPT.md) to generate similar infrastructure
3. Follow the prompts to customize for your environment

### Option 2: Direct Deployment
1. Review the [`CUSTOMER_GUIDE.md`](CUSTOMER_GUIDE.md) for step-by-step instructions
2. Navigate to the terraform directory:
   ```bash
   cd infra/tf
   ```
3. Follow the deployment instructions in the guide

## Architecture Overview

The infrastructure includes:

- **AKS Cluster**: Publicly accessible Kubernetes cluster with OIDC issuer and workload identity enabled
- **User Assigned Managed Identities (UAMI)**:
  - Kubelet identity for node operations
  - Cluster identity for cluster operations
  - Workload identity for pod authentication
- **Azure Container Registry (ACR)**: Connected to the AKS cluster for container image storage
- **Azure Storage Account**: Used for Terraform state management and general storage needs
- **Workload Identity Configuration**: Federated credentials and service account setup

## Prerequisites

Before deploying this infrastructure, ensure you have:

1. **Azure CLI** installed and configured
2. **Terraform** (>= 1.5) installed
3. **kubectl** installed (for cluster management)
4. **Azure subscription** with appropriate permissions
5. **Bash shell** (for deployment scripts)

## Project Structure

```
.
├── README.md               # This file
├── NAMING.md               # Naming conventions documentation
├── COPILOT_PROMPT.md       # GitHub Copilot prompt for replication
├── CUSTOMER_GUIDE.md       # Quick start guide for customers
├── start.sh                # Quick navigation helper script
├── examples/               # Example applications
│   ├── README.md
│   ├── test-pod.yaml
│   └── sample-app.yaml
└── infra/                  # Infrastructure code
    └── tf/                 # Terraform deployment
        ├── main.tf         # Main Terraform configuration
        ├── variables.tf    # Input variables
        ├── outputs.tf      # Output values
        ├── terraform.tfvars # Variable values
        ├── backend.hcl     # Backend configuration
        ├── deploy.sh       # Deployment script
        ├── cleanup.sh      # Cleanup script
        ├── validate.sh     # Validation script
        └── modules/        # Terraform modules
            ├── aks/
            ├── container_registry/
            ├── managed_identity/
            ├── storage/
            └── workload_identity/
```

## 🏢 **For Customers: Replicating This Deployment**

This repository is designed for easy replication. You have two options:

### **🤖 Generate from Scratch with GitHub Copilot**

**Best for**: Learning, customization, or adapting to different requirements

1. **Open GitHub Copilot Chat** in VS Code
2. **Copy the prompt** from [`COPILOT_PROMPT.md`](COPILOT_PROMPT.md)
3. **Paste and execute** the prompt in Copilot Chat
4. **Review the generated code** and make any needed adjustments
5. **Deploy** using the generated scripts

**Benefits:**
- ✅ Learn how each component works
- ✅ Customize for your specific needs
- ✅ Understand the complete architecture
- ✅ Generate similar deployments for other projects

### **📋 Clone and Deploy**

**Best for**: Quick deployment with minimal changes

1. **Clone this repository**
2. **Update `terraform.tfvars`** with your values
3. **Run `./deploy.sh`** to deploy everything
4. **Validate** with `./validate.sh`

**Benefits:**
- ✅ Fastest deployment
- ✅ Pre-tested configuration
- ✅ Ready-to-use scripts
- ✅ Complete documentation

> 📋 **For a detailed step-by-step guide, see [`CUSTOMER_GUIDE.md`](CUSTOMER_GUIDE.md)**

### **🎯 Recommended Workflow for Customers**

```bash
# Option 1: GitHub Copilot Generation
# 1. Use COPILOT_PROMPT.md in GitHub Copilot Chat
# 2. Review and customize generated code
# 3. Follow the deployment steps below

# Option 2: Direct Clone
git clone <this-repository>
cd aks-workloadidentity-sample

# Navigate to Terraform directory
cd infra/tf

# Update configuration
vim terraform.tfvars  # Set your project details

# Deploy infrastructure
./deploy.sh

# Validate deployment
./validate.sh

# Test with examples
kubectl apply -f ../../examples/test-pod.yaml
```

### **📚 What Customers Get**

- **Complete Infrastructure**: AKS + ACR + Storage + Managed Identities
- **Security Best Practices**: Workload identity, no stored secrets
- **Automation Scripts**: Deploy, validate, and cleanup scripts
- **Documentation**: Comprehensive guides and examples
- **Replication Guide**: GitHub Copilot prompt for generating similar deployments

### 1. Clone and Configure

```bash
git clone <repository-url>
cd aks-workloadidentity-sample
```

### 2. Update Configuration

Navigate to the Terraform directory and edit `terraform.tfvars` to customize your deployment:

```bash
cd infra/tf
vim terraform.tfvars
```

```hcl
project_name       = "akswlid"        # Short name (max 10 chars, lowercase alphanumeric)
environment        = "dev"            # Environment token: dev, stg, prod
location           = "East US"
kubernetes_version = "1.28"
node_count         = 3
vm_size            = "Standard_B2s"
```

**Note**: See [NAMING.md](NAMING.md) for detailed naming conventions and constraints.

### 3. Deploy Infrastructure

Run the deployment script:

```bash
./deploy.sh
```

This script will:
- Check prerequisites
- Login to Azure
- Create storage account for Terraform state (optional)
- Initialize Terraform
- Plan and apply the deployment
- Configure kubectl

### 4. Verify Deployment

After deployment, verify the setup:

```bash
# Check cluster status
kubectl get nodes

# Check workload identity service account
kubectl get serviceaccount workload-identity-sa

# Check managed identities
az identity list --resource-group <resource-group-name>
```

## Manual Deployment

If you prefer manual deployment:

### 1. Initialize Terraform

```bash
# Navigate to Terraform directory
cd infra/tf

# Configure backend (update backend.hcl with your storage account details)
terraform init -backend-config=backend.hcl
```

### 2. Plan and Apply

```bash
# Plan deployment
terraform plan -out=tfplan

# Apply deployment
terraform apply tfplan
```

### 3. Configure kubectl

```bash
# Get cluster credentials
az aks get-credentials --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw aks_cluster_name)
```

## Using Workload Identity

Once deployed, you can use the workload identity in your pods:

### Example Pod Configuration

```yaml
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
    args: ["-c", "sleep 3600"]
    env:
    - name: AZURE_CLIENT_ID
      value: "<workload-identity-client-id>"
```

### Testing Workload Identity

```bash
# Get the client ID (run from infra/tf directory)
WORKLOAD_IDENTITY_CLIENT_ID=$(terraform output -raw workload_identity_client_id)

# Create a test pod
kubectl run test-workload-identity \
  --image=mcr.microsoft.com/azure-cli:latest \
  --serviceaccount=workload-identity-sa \
  --env="AZURE_CLIENT_ID=$WORKLOAD_IDENTITY_CLIENT_ID" \
  --command -- sleep 3600

# Test authentication
kubectl exec -it test-workload-identity -- az account show
```

## Modules

### AKS Module (`modules/aks/`)
- Creates AKS cluster with workload identity enabled
- Configures kubelet and cluster managed identities
- Sets up ACR integration

### Container Registry Module (`modules/container_registry/`)
- Creates Azure Container Registry
- Configures access policies

### Managed Identity Module (`modules/managed_identity/`)
- Creates three User Assigned Managed Identities
- Provides identity details for other modules

### Storage Module (`modules/storage/`)
- Creates storage account for Terraform state
- Sets up blob container for state files

### Workload Identity Module (`modules/workload_identity/`)
- Creates federated identity credentials
- Sets up Kubernetes service account
- Configures workload identity integration

## Configuration Variables

| Variable | Description | Default | Constraints |
|----------|-------------|---------|-------------|
| `project_name` | Name of the project | `akswlid` | Max 10 chars, lowercase alphanumeric only |
| `environment` | Environment name | `dev` | Use: dev, stg, prod |
| `location` | Azure region | `East US` | Valid Azure region |
| `kubernetes_version` | Kubernetes version | `1.28` | Supported AKS version |
| `node_count` | Number of nodes | `3` | 1-100 |
| `vm_size` | VM size for nodes | `Standard_B2s` | Valid Azure VM size |
| `namespace` | Kubernetes namespace | `default` | Valid k8s namespace name |
| `service_account_name` | Service account name | `workload-identity-sa` | Valid k8s SA name |

## Outputs

After deployment, the following outputs are available:

- `resource_group_name`: Resource group name
- `aks_cluster_name`: AKS cluster name
- `container_registry_login_server`: ACR login server
- `workload_identity_client_id`: Workload identity client ID
- `kubeconfig_command`: Command to get kubeconfig

## State Management

This configuration uses Azure Storage Account for Terraform state management. The state is stored in:
- **Storage Account**: Created automatically or specified in `infra/tf/backend.hcl`
- **Container**: `tfstate`
- **Blob**: `aks-workloadidentity/terraform.tfstate`

## Security Considerations

- The cluster is publicly accessible by default
- Workload identity uses federated credentials (no secrets stored)
- ACR integration uses managed identity authentication
- All resources are tagged for governance

## Troubleshooting

### Common Issues

1. **Authentication Errors**: Ensure you're logged in to Azure CLI
2. **State Backend Issues**: Check storage account configuration in backend.hcl
3. **Kubernetes Provider Issues**: Ensure AKS cluster is accessible

### Debugging Commands

```bash
# Navigate to Terraform directory
cd infra/tf

# Check Terraform state
terraform show

# Validate configuration
terraform validate

# Check AKS cluster
az aks show --resource-group <rg-name> --name <cluster-name>

# Check workload identity
az identity show --name <identity-name> --resource-group <rg-name>
```

## Cleanup

To destroy all resources:

```bash
# Navigate to Terraform directory
cd infra/tf

# Run cleanup script
./cleanup.sh
```

Or manually:

```bash
cd infra/tf
terraform destroy
```

## Best Practices

This configuration follows Terraform best practices:

- **Modular Design**: Separate modules for different components
- **Variable Management**: Centralized variable definitions
- **State Management**: Remote state with Azure Storage
- **Output Values**: Meaningful outputs for integration
- **Tagging**: Consistent resource tagging
- **Security**: Managed identity authentication

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review Azure documentation
3. Open an issue in the repository

## References

- [Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/)
- [Workload Identity](https://docs.microsoft.com/en-us/azure/aks/workload-identity-overview)
- [Azure Container Registry](https://docs.microsoft.com/en-us/azure/container-registry/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
