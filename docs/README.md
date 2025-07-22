# 📚 Documentation Index

Welcome to the AKS Workload Identity Sample documentation! This index provides a comprehensive guide to all available documentation in this repository.

## 🚀 Quick Start Documentation

| Document | Description | Audience |
|----------|-------------|----------|
| [README.md](../README.md) | **Main project documentation** - Start here for complete setup guide | All users |
| File | Purpose | Audience |
|------|---------|----------|
| [QUICKSTART.md](../QUICKSTART.md) | 5-minute deployment guide | End users |
| [start.sh](../start.sh) | Interactive navigation script | All users |

## 🔐 Security & Access Control

| Document | Description | Use Case |
|----------|-------------|----------|
| [Azure AD Admin Groups](azure-ad-admin-groups.md) | Configure Azure AD groups for AKS cluster admin access | Required setup |
| [Azure Federated Token File](azure-federated-token-file.md) | Deep dive into workload identity token mechanism | Understanding & troubleshooting |

## 🏗️ Infrastructure & Architecture

| Document | Description | Audience |
|----------|-------------|----------|
| [NAMING.md](../NAMING.md) | Azure resource naming conventions | Developers & operators |
| [Terraform Modules](../infra/tf/modules/README.md) | Infrastructure module documentation | Infrastructure engineers |

## 🧪 Examples & Testing

| Document | Description | Purpose |
|----------|-------------|---------|
| [Examples Guide](../examples/README.md) | Sample applications and test cases | Testing & validation |
| [Test Storage Access](../examples/test-storage-access.yaml) | Workload identity connectivity test | Verification |
| [Token Inspector](../examples/inspect-token.yaml) | Token analysis and debugging | Troubleshooting |

## 🤖 Development & Automation

| Document | Description | Audience |
|----------|-------------|----------|
| [Copilot Prompts](../.copilot/prompts.md) | GitHub Copilot generation prompts | Developers |
| [Quick Start Guide](../.copilot/quick-start.md) | Rapid deployment instructions | DevOps engineers |
| [Security Configuration](../.copilot/security-config.md) | Security setup automation | Security engineers |
| [Validation Guide](../.copilot/validation.md) | Testing and validation procedures | QA & operations |
| [Templates](../.copilot/templates.md) | Reusable configuration templates | Developers |

## 📋 Documentation Categories

### 🎯 **Getting Started**
Perfect for first-time users and quick deployments:
1. [README.md](../README.md) - Complete project overview
2. [Azure AD Admin Groups](azure-ad-admin-groups.md) - Required access configuration
3. [Quick Start Guide](../.copilot/quick-start.md) - Rapid deployment path

### 🔍 **Deep Dive Technical**
For understanding the underlying mechanisms:
1. [Azure Federated Token File](azure-federated-token-file.md) - Token authentication deep dive
2. [NAMING.md](../NAMING.md) - Resource naming strategy
3. [Terraform Modules](../infra/tf/modules/README.md) - Infrastructure architecture

### 🛠️ **Operations & Troubleshooting**
For day-2 operations and issue resolution:
1. [Validation Guide](../.copilot/validation.md) - Testing procedures
2. [Examples Guide](../examples/README.md) - Test cases and samples
3. [Azure Federated Token File](azure-federated-token-file.md) - Troubleshooting section

### 🚀 **Development & Customization**
For extending and modifying the solution:
1. [Copilot Prompts](../.copilot/prompts.md) - AI-assisted development
2. [Templates](../.copilot/templates.md) - Reusable patterns
3. [Security Configuration](../.copilot/security-config.md) - Security best practices

## 🔗 External References

### Microsoft Azure Documentation
- [Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/)
- [Azure Workload Identity](https://docs.microsoft.com/en-us/azure/aks/workload-identity-overview)
- [Azure Container Registry](https://docs.microsoft.com/en-us/azure/container-registry/)
- [Azure RBAC](https://docs.microsoft.com/en-us/azure/role-based-access-control/)

### Terraform Documentation
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)

### Azure Workload Identity
- [Azure Workload Identity Documentation](https://azure.github.io/azure-workload-identity/)
- [OAuth 2.0 Token Exchange RFC](https://tools.ietf.org/html/rfc8693)
- [Kubernetes Service Account Token Volume Projection](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#serviceaccount-token-volume-projection)

## 📝 Documentation Standards

### File Organization
```
📁 Repository Root
├── 📄 README.md (main documentation)
├── 📄 QUICKSTART.md (5-minute deployment guide)
├── 📄 NAMING.md (naming conventions)
├── 📁 docs/ (detailed technical documentation)
├── 📁 .copilot/ (development & automation guides)
├── 📁 examples/ (sample applications & tests)
└── 📁 infra/ (infrastructure documentation)
```

### Writing Guidelines
- **Headers**: Use descriptive headings with emoji for visual navigation
- **Links**: Always use relative paths for internal documentation
- **Code Blocks**: Include language tags for syntax highlighting
- **Examples**: Provide practical, runnable examples
- **Cross-References**: Link to related documentation sections

## 🚦 Documentation Status

| Document | Status | Last Updated | Maintainer |
|----------|--------|--------------|------------|
| README.md | ✅ Current | 2025-07-21 | @ckellywilson |
| azure-ad-admin-groups.md | ✅ Current | 2025-07-21 | @ckellywilson |
| azure-federated-token-file.md | ✅ Current | 2025-07-21 | Auto-generated |
| NAMING.md | ✅ Current | 2025-07-21 | @ckellywilson |
| examples/README.md | ⚠️ Empty | - | Needs content |
| infra/tf/modules/README.md | ❌ Missing | - | Needs creation |

## 🎯 Quick Navigation

### I want to...
- **Deploy for the first time** → [README.md](../README.md) → [Azure AD Admin Groups](azure-ad-admin-groups.md)
- **Understand workload identity** → [Azure Federated Token File](azure-federated-token-file.md)
- **Test the deployment** → [Examples Guide](../examples/README.md) → [Validation Guide](../.copilot/validation.md)
- **Troubleshoot issues** → [Azure Federated Token File](azure-federated-token-file.md#troubleshooting)
- **Customize the solution** → [Copilot Prompts](../.copilot/prompts.md) → [Templates](../.copilot/templates.md)
- **Understand naming** → [NAMING.md](../NAMING.md)

## 🔄 Contributing to Documentation

### Adding New Documentation
1. Create your documentation file in the appropriate directory
2. Update this index with a link and description
3. Add cross-references from related documents
4. Update the status table above

### Documentation Review Process
1. Technical accuracy review
2. Link validation
3. Example testing
4. User experience review

---

💡 **Tip**: Use the browser's search function (Ctrl+F) to quickly find specific topics across all documentation files.

📧 **Questions?** Check the troubleshooting sections or create an issue in the repository.
