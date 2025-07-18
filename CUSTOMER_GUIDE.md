# Customer Quick Start Guide

> **📖 This guide has been consolidated into the main [README.md](README.md)**

For the most up-to-date and comprehensive deployment instructions, please use the [main README](README.md).

## Quick Links

- **🚀 [Get Started Now](README.md#-quick-start)**
- **🔐 [Configure Admin Access](README.md#-configure-admin-access-required)**
- **🚀 [Deploy Infrastructure](README.md#-deployment-guide)**
- ** [Troubleshooting](README.md#-troubleshooting)**
   cd aks-workloadidentity-sample
   ```

2. **Configure**
   ```bash
   # Navigate to Terraform directory
   cd infra/tf
   
   # Edit configuration
   vim terraform.tfvars
   
   # Update these values:
   # project_name = "mycompany"  # Your short company/project name
   # environment  = "dev"        # dev, stg, or prod
   # location     = "East US"    # Your preferred Azure region
   ```

3. **Deploy**
   ```bash
   # Login to Azure
   az login
   
   # Deploy everything
   ./deploy.sh
   
   # Validate deployment
   ./validate.sh
   ```

## ⚙️ **Configuration Checklist**

Before deploying, ensure you have:

- [ ] **Azure Subscription** with appropriate permissions
- [ ] **Unique project name** (max 10 chars, lowercase alphanumeric)
- [ ] **Azure region** selected
- [ ] **Azure CLI** authenticated (`az login`)

## 🧪 **Testing Your Deployment**

```bash
# Navigate to Terraform directory
cd infra/tf

# Test AKS cluster
kubectl get nodes

# Test workload identity
kubectl apply -f ../../examples/test-pod.yaml
kubectl logs test-workload-identity

# Test ACR access
az acr list --query "[].loginServer" -o table
```

## 🆘 **Troubleshooting**

### **Common Issues**

1. **"Storage account name already exists"**
   ```bash
   # Solution: Change project_name in terraform.tfvars
   project_name = "mycompany2"  # Make it unique
   ```

2. **"Insufficient permissions"**
   ```bash
   # Solution: Ensure you have Contributor role on subscription
   az role assignment list --assignee $(az account show --query user.name -o tsv)
   ```

3. **"Terraform modules not found"**
   ```bash
   # Solution: Navigate to Terraform directory and initialize
   cd infra/tf
   terraform init
   ```

## 📞 **Support**

- **Documentation**: See `README.md` for comprehensive guide
- **Naming**: See `NAMING.md` for naming conventions
- **Examples**: Check `examples/` directory for sample applications
- **Validation**: Run `./validate.sh` to check deployment health

## 🎉 **Success Indicators**

Your deployment is successful when:

- ✅ All Terraform resources created without errors
- ✅ `kubectl get nodes` shows Ready nodes
- ✅ `./validate.sh` passes all checks
- ✅ Test pod authenticates with Azure successfully

**Next Steps**: Deploy your applications using the `workload-identity-sa` service account!
