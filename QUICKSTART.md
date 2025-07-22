# 🚀 Quick Start Guide

Deploy AKS with Workload Identity in **under 5 minutes** with this streamlined guide.

## ⚡ One-Command Deployment

The fastest way to get started:

```bash
git clone <repository-url>
cd aks-workloadidentity-sample
./deploy-now.sh
```

That's it! The script handles everything automatically:
- ✅ Prerequisites check
- ✅ Azure authentication  
- ✅ Configuration with your subscription
- ✅ Infrastructure deployment
- ✅ Validation and testing

## 📋 Prerequisites

Make sure you have these installed:
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Terraform](https://developer.hashicorp.com/terraform/downloads)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

> 💡 **Using a dev container?** All tools are pre-installed!

## 🛠️ Manual Deployment (For Customization)

If you need more control or want to customize settings:

### 1. Configure
```bash
cd infra/tf
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # Edit your settings
```

### 2. Deploy
```bash
./deploy.sh    # Deploy infrastructure
./validate.sh  # Validate deployment
```

### 3. Test
```bash
kubectl apply -f examples/test-workload-identity-simple.yaml
kubectl logs workload-identity-test-simple
```

## 🔧 Key Configuration Options

Edit `terraform.tfvars` to customize:

```hcl
project_name = "mycompany"    # Your project name (max 10 chars)
environment  = "dev"          # Environment: dev, staging, prod
location     = "East US"      # Your preferred Azure region

# Optional: Add Azure AD groups for admin access
admin_group_object_ids = [
  "12345678-1234-1234-1234-123456789012"  # Your group Object ID
]
```

## 🧪 Testing Your Deployment

Verify everything works:

```bash
# Test workload identity
kubectl apply -f examples/test-workload-identity-simple.yaml
kubectl logs workload-identity-test-simple

# Test private storage access
kubectl apply -f examples/test-private-storage.yaml  
kubectl logs private-storage-test
```

## 🧹 Cleanup

Remove all resources when done:

```bash
cd infra/tf && ./cleanup.sh
```

## 🆘 Need Help?

- **Validation Issues**: Run `cd infra/tf && ./validate.sh` for diagnostics
- **Storage Access**: Add your IP to storage firewall in Azure Portal
- **Cluster Access**: Ensure you're in the Azure AD admin group

For detailed help, see the [full documentation](README.md).

---

**Ready to start?** Run `./deploy-now.sh` now! 🚀
