# Azure AD Group Admin Access Configuration

This document explains how to configure Azure AD groups for admin access to the AKS cluster.

## Quick Start

1. **Find your Azure AD group Object ID**:
   ```bash
   # Using Azure CLI
   az ad group show --group "AKS-Admins" --query id --output tsv
   ```

2. **Add the Object ID to terraform.tfvars**:
   ```hcl
   admin_group_object_ids = [
     "12345678-1234-1234-1234-123456789012"  # Replace with your actual Object ID
   ]
   ```

3. **Deploy the configuration**:
   ```bash
   cd infra/tf
   terraform plan
   terraform apply
   ```

4. **Test access** (group members):
   ```bash
   az aks get-credentials --resource-group akswlid-dev-rg --name akswlid-dev-aks
   kubectl get nodes
   ```

## Finding Group Object IDs

### Azure Portal
1. Go to Azure Active Directory > Groups
2. Search for your group name
3. Click on the group
4. Copy the "Object ID"

### Azure CLI
```bash
# List all groups (filter as needed)
az ad group list --query "[].{Name:displayName, ObjectId:id}" --output table

# Get specific group by name
az ad group show --group "Your-Group-Name" --query id --output tsv
```

### PowerShell
```powershell
# Get group by display name
(Get-AzADGroup -DisplayName "Your-Group-Name").Id

# List all groups
Get-AzADGroup | Select-Object DisplayName, Id
```

## Configuration Examples

### Single Admin Group
```hcl
admin_group_object_ids = [
  "12345678-1234-1234-1234-123456789012"
]
```

### Multiple Admin Groups
```hcl
admin_group_object_ids = [
  "12345678-1234-1234-1234-123456789012",  # AKS-Admins
  "87654321-4321-4321-4321-210987654321",  # DevOps-Team
  "11111111-2222-3333-4444-555555555555"   # Platform-Engineers
]
```

### No Admin Groups (Current User Only)
```hcl
admin_group_object_ids = []
```

## Access Levels

- **Admin Groups**: Full cluster admin access via Azure RBAC
- **Current User**: The user/service principal deploying the infrastructure automatically gets admin access
- **Workload Pods**: Access Azure services through workload identity (separate from human access)

## Security Notes

- Local accounts are disabled (`local_account_disabled = true`)
- Only Azure AD authentication is allowed
- Admin access is managed through Azure AD groups
- Changes to group membership take effect immediately
- Group Object IDs are validated during terraform plan/apply

## Troubleshooting

### "Forbidden" Error When Accessing Cluster
1. Verify you're a member of one of the configured admin groups
2. Check that the group Object ID is correct in terraform.tfvars
3. Ensure you're signed in with the correct Azure account: `az account show`
4. Try getting fresh credentials: `az aks get-credentials --resource-group akswlid-dev-rg --name akswlid-dev-aks --overwrite-existing`

### Group Object ID Not Found
1. Verify the group exists: `az ad group show --group "Group-Name"`
2. Check you have permissions to read the group
3. Ensure the Object ID format is correct (UUID format)

### Changes Not Taking Effect
1. Run `terraform plan` to see if changes are detected
2. Apply changes: `terraform apply`
3. Get fresh cluster credentials after applying changes
