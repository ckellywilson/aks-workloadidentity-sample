# Azure Resource Naming Conventions

> **📖 Primary Documentation**: For complete configuration details, see the main [README.md](README.md#-configuration-reference).

## Quick Reference

This deployment follows Microsoft Azure naming conventions with standardized resource abbreviations:

**Reference**: [Azure Resource Abbreviations](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations)

### Core Naming Pattern
```
<project>-<environment>-<region>-<resource-abbreviation>
```

### Resource Abbreviations (Microsoft Standard)
| Resource Type | Abbreviation | Example |
|---------------|--------------|---------|
| Resource Group | `rg` | `akswlid-dev-cus-rg` |
| AKS Cluster | `aks` | `akswlid-dev-cus-aks` |
| User Assigned Managed Identity | `id` | `akswlid-dev-cus-workload-id` |
| Storage Account | `st` | `akswliddevcusst` (no hyphens) |
| Container Registry | `cr` | `akswliddevcuscr` (no hyphens) |
| Virtual Network | `vnet` | `akswlid-dev-cus-vnet` |
| Subnet | `snet` | `akswlid-dev-cus-snet` |
| Network Security Group | `nsg` | `akswlid-dev-cus-nsg` |
| Key Vault | `kv` | `akswliddevcuskv` (no hyphens) |
| Log Analytics Workspace | `log` | `akswlid-dev-cus-log` |

### Region Abbreviations
| Region | Abbreviation | Example Usage |
|--------|--------------|---------------|
| Central US | `cus` | `akswlid-dev-cus-rg` |
| East US | `eus` | `akswlid-prod-eus-rg` |
| East US 2 | `eus2` | `akswlid-stg-eus2-rg` |
| West US 2 | `wus2` | `akswlid-dev-wus2-rg` |
| West Europe | `we` | `akswlid-prod-we-rg` |
| North Europe | `ne` | `akswlid-dev-ne-rg` |

**Full List**: 30+ regions supported with standard abbreviations

### Special Naming Rules

**Storage Account & Container Registry**: 
- No hyphens allowed
- Globally unique across Azure
- Storage: 3-24 characters, lowercase letters/numbers only
- Container Registry: 5-50 characters, alphanumeric only

### Environment Abbreviations
| Environment | Abbreviation |
|-------------|--------------|
| Development | `dev` |
| Staging | `stg` |
| Production | `prod` |
| Test | `test` |

### Resource Group Strategy

This deployment uses **three-tier resource group strategy** following Azure best practices:

#### 1. Application Resource Groups
- **Purpose**: Contains application infrastructure (AKS control plane, storage, etc.)
- **Naming**: `{project}-{environment}-{region}-rg`
- **Examples**: `akswlid-dev-cus-rg`, `akswlid-prod-eus-rg`
- **Management**: Managed by Terraform

#### 2. AKS Infrastructure Resource Groups
- **Purpose**: Contains AKS infrastructure (nodes, load balancers, NSGs, disks)
- **Naming**: `{project}-{environment}-{region}-aks-nodes-rg`
- **Examples**: `akswlid-dev-cus-aks-nodes-rg`, `akswlid-prod-eus-aks-nodes-rg`
- **Management**: Managed by Azure (auto-created with custom name)

#### 3. Backend State Resource Group  
- **Purpose**: Contains Terraform state storage
- **Naming**: `tfstate-mgmt-rg`
- **Management**: Managed by Azure CLI (prevents circular dependencies)
- **Security**: Isolated from application resources

**Benefits**:
- ✅ Clear separation of control plane vs. infrastructure
- ✅ Prevents circular dependencies
- ✅ Organized resource lifecycle management
- ✅ Enhanced security isolation
- ✅ Simplified disaster recovery
- ✅ Enterprise-grade governance
- ✅ Better cost attribution and monitoring

### Project Name Requirements
- **Maximum**: 10 characters
- **Characters**: Lowercase letters and numbers only (a-z, 0-9)
- **Must start with letter**: Cannot begin with a number
- **Validation**: Enforced by Terraform validation rules

### Configuration
Update `infra/tf/terraform.tfvars`:
```hcl
project_name = "myproject"  # Max 10 chars, lowercase alphanumeric
environment  = "dev"        # dev, stg, prod, test, staging, production
location     = "Central US" # Azure region name
```

### Examples

**Development Environment (Central US)**:
```hcl
project_name = "akswlid"
environment  = "dev"
location     = "Central US"
```

Generated names:
- Resource Group: `akswlid-dev-cus-rg`
- AKS Cluster: `akswlid-dev-cus-aks`
- AKS Node Resource Group: `akswlid-dev-cus-aks-nodes-rg`
- Storage Account: `akswliddevcusst`
- Container Registry: `akswliddevcuscr`
- Workload Identity: `akswlid-dev-cus-workload-id`
- Federated Credential: `akswlid-dev-cus-fedcred`

**Production Environment (East US)**:
```hcl
project_name = "akswlid"
environment  = "prod"
location     = "East US"
```

Generated names:
- Resource Group: `akswlid-prod-eus-rg`
- AKS Cluster: `akswlid-prod-eus-aks`
- AKS Node Resource Group: `akswlid-prod-eus-aks-nodes-rg`
- Storage Account: `akswlidprodeusst`
- Container Registry: `akswlidprodeuscr`
- Workload Identity: `akswlid-prod-eus-workload-id`

**📖 Complete details**: See [README.md Configuration Reference](README.md#-configuration-reference)
