# Azure Resource Naming Conventions

> **📖 Primary Documentation**: For complete configuration details, see the main [README.md](README.md#-configuration-reference).

## Quick Reference

This deployment uses standardized naming patterns:

```
<project>-<environment>-<resource-type>
```

### Examples
- Resource Group: `akswlid-dev-rg`
- AKS Cluster: `akswlid-dev-aks`  
- Storage Account: `akswliddevst` (no hyphens due to Azure constraints)
- Container Registry: `akswliddevacr` (no hyphens due to Azure constraints)

### Project Name Requirements
- **Maximum**: 10 characters
- **Characters**: Lowercase letters and numbers only (a-z, 0-9)
- **Validation**: Enforced by Terraform validation rules

### Configuration
Update `infra/tf/terraform.tfvars`:
```hcl
project_name = "myproject"  # Max 10 chars, lowercase alphanumeric
environment  = "dev"        # dev, staging, prod
```

**📖 Complete details**: See [README.md Configuration Reference](README.md#-configuration-reference)
| Staging | `stg` |
| Production | `prod` |

## Project Name Constraints

To ensure compatibility with all Azure resource types:

- **Length**: Maximum 10 characters
- **Characters**: Lowercase letters and numbers only (a-z, 0-9)
- **No special characters**: No hyphens, underscores, or spaces
- **Must start with letter**: Cannot start with a number

### Recommended Project Names

- `akswlid` (AKS Workload Identity)
- `myapp`
- `webapp01`
- `api`

## Storage Account Naming Rules

Azure Storage Account names have strict requirements:

- Length: 3-24 characters
- Characters: Lowercase letters and numbers only
- Must be globally unique
- Pattern: `{project}{environment}st`

Example: `akswliddevst`

## Container Registry Naming Rules

Azure Container Registry names have specific requirements:

- Length: 5-50 characters
- Characters: Alphanumeric only
- Must be globally unique
- Pattern: `{project}{environment}acr`

Example: `akswliddevacr`

## Validation

The Terraform configuration includes validation rules to ensure:

1. Project name meets length and character requirements
2. Resource names comply with Azure naming rules
3. Names are consistent across all resources

## Usage

When deploying:

1. Set `project_name` to a short, descriptive name (≤10 chars)
2. Set `environment` to the appropriate token (`dev`, `stg`, `prod`)
3. The naming module automatically generates compliant names for all resources

## Examples

### Development Environment
```hcl
project_name = "akswlid"
environment  = "dev"
```

Generated names:
- Resource Group: `akswlid-dev-rg`
- AKS Cluster: `akswlid-dev-aks`
- Storage Account: `akswliddevst`
- Container Registry: `akswliddevacr`
- Kubelet Identity: `akswlid-dev-kubelet-mi`

### Production Environment
```hcl
project_name = "akswlid"
environment  = "prod"
```

Generated names:
- Resource Group: `akswlid-prod-rg`
- AKS Cluster: `akswlid-prod-aks`
- Storage Account: `akswlidprodst`
- Container Registry: `akswlidprodacr`
- Kubelet Identity: `akswlid-prod-kubelet-mi`
