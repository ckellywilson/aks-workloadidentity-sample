# Azure Resource Naming Conventions

> **📖 Primary Documentation**: For complete configuration details, see the main [README.md](README.md#-configuration-reference).

## Quick Reference

This deployment follows Microsoft Azure naming conventions with standardized resource abbreviations:

**Reference**: [Azure Resource Abbreviations](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations)

### Core Naming Pattern
```
<project>-<environment>-<resource-abbreviation>
```

### Resource Abbreviations (Microsoft Standard)
| Resource Type | Abbreviation | Example |
|---------------|--------------|---------|
| Resource Group | `rg` | `akswlid-dev-rg` |
| AKS Cluster | `aks` | `akswlid-dev-aks` |
| User Assigned Managed Identity | `id` | `akswlid-dev-workload-id` |
| Storage Account | `st` | `akswliddevst` (no hyphens) |
| Container Registry | `cr` | `akswliddevcr` (no hyphens) |
| Virtual Network | `vnet` | `akswlid-dev-vnet` |
| Subnet | `snet` | `akswlid-dev-snet` |
| Network Security Group | `nsg` | `akswlid-dev-nsg` |
| Key Vault | `kv` | `akswliddevkv` (no hyphens) |
| Log Analytics Workspace | `log` | `akswlid-dev-log` |

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
```

### Examples

**Development Environment**:
```hcl
project_name = "akswlid"
environment  = "dev"
```

Generated names:
- Resource Group: `akswlid-dev-rg`
- AKS Cluster: `akswlid-dev-aks`
- Storage Account: `akswliddevst`
- Container Registry: `akswliddevcr`
- Workload Identity: `akswlid-dev-workload-id`
- Federated Credential: `akswlid-dev-fedcred`

**Production Environment**:
```hcl
project_name = "akswlid"
environment  = "prod"
```

Generated names:
- Resource Group: `akswlid-prod-rg`
- AKS Cluster: `akswlid-prod-aks`
- Storage Account: `akswlidprodst`
- Container Registry: `akswlidprodcr`
- Workload Identity: `akswlid-prod-workload-id`

**📖 Complete details**: See [README.md Configuration Reference](README.md#-configuration-reference)
