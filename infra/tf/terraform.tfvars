# Environment-specific variable values
project_name         = "akswlid"
environment          = "dev"
location             = "centralus"
kubernetes_version   = "1.30.12"
subscription_id      = "f8a5f387-2f0b-42f5-b71f-5ee02b8967cf"
node_count           = 3
vm_size              = "Standard_B2s"
namespace            = "default"
service_account_name = "workload-identity-sa"

# Azure AD Admin Groups Configuration
# AUTOMATIC: A group named "{cluster-name}-admins" is created automatically and the current user is added
# OPTIONAL: Add additional Azure AD group Object IDs for admin access to the AKS cluster
# To find group Object IDs:
# - Azure Portal: Azure Active Directory > Groups > [Group Name] > Object ID
# - Azure CLI: az ad group show --group "[Group Name]" --query id --output tsv
# - PowerShell: (Get-AzADGroup -DisplayName "[Group Name]").Id
admin_group_object_ids = [
  # Example: "12345678-1234-1234-1234-123456789012"
  # Add your additional Azure AD group Object IDs here (optional)
]
