# 🚀 **Customer Quick Start Guide**

This guide helps customers quickly replicate the AKS Workload Identity deployment using either GitHub Copilot or direct cloning.

## 🎯 **Choose Your Approach**

### **Option A: Generate with GitHub Copilot (Recommended for Learning)**

**Time**: 15-30 minutes | **Skill Level**: Intermediate | **Customization**: High

1. **Prerequisites**
   - VS Code with GitHub Copilot extension
   - Azure CLI installed
   - Terraform installed

2. **Generate the Code**
   ```bash
   # Create a new directory
   mkdir my-aks-deployment
   cd my-aks-deployment
   
   # Open VS Code
   code .
   ```

3. **Use GitHub Copilot**
   - Open Copilot Chat (Ctrl+Shift+I)
   - Copy the prompt from `COPILOT_PROMPT.md`
   - Paste and execute in Copilot Chat
   - Review and save the generated files

4. **Deploy**
   ```bash
   # Navigate to Terraform directory
   cd infra/tf
   
   # Update configuration
   vim terraform.tfvars
   
   # Deploy
   ./deploy.sh
   ```

### **Option B: Clone and Deploy (Recommended for Quick Setup)**

**Time**: 10-15 minutes | **Skill Level**: Beginner | **Customization**: Medium

1. **Clone Repository**
   ```bash
   git clone <repository-url>
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
