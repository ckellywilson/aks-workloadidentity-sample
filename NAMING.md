# Azure Resource Naming Conventions

This document outlines the naming conventions used in this Terraform deployment to ensure consistency and compliance with Azure naming requirements.

## Naming Pattern

The standardized naming pattern follows Azure best practices:

```
<project>-<environment>-<resource-type>
```

For resources with specific constraints (like Storage Accounts and Container Registry), special handling is applied.

## Resource Naming Standards

| Resource Type | Pattern | Example | Notes |
|---------------|---------|---------|-------|
| Resource Group | `{project}-{env}-rg` | `akswlid-dev-rg` | Standard pattern |
| AKS Cluster | `{project}-{env}-aks` | `akswlid-dev-aks` | Standard pattern |
| Managed Identity | `{project}-{env}-{type}-mi` | `akswlid-dev-kubelet-mi` | Type: kubelet, cluster, workload |
| Storage Account | `{project}{env}st` | `akswliddevst` | No hyphens, max 24 chars, lowercase |
| Container Registry | `{project}{env}acr` | `akswliddevacr` | No hyphens, max 50 chars, lowercase |
| Federated Credential | `{project}-{env}-federated-cred` | `akswlid-dev-federated-cred` | Standard pattern |

## Environment Tokens

| Environment | Token |
|-------------|-------|
| Development | `dev` |
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
