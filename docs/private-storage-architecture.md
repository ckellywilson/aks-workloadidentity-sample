# AKS Workload Identity with Private Storage Account

## Architecture Options

### 1. Private Endpoint (Recommended)

```
AKS Cluster (VNet) → Private Endpoint → Storage Account (Private)
```

**Setup:**
- Storage account: Public network access = Disabled
- Create private endpoint in AKS VNet/subnet
- DNS resolution via private DNS zone
- No firewall rules needed

**Benefits:**
- Traffic stays within Azure backbone
- No exposure to public internet
- Highest security

### 2. Service Endpoint + VNet Integration

```
AKS Cluster (Custom VNet) → Service Endpoint → Storage Account
```

**Setup:**
- AKS must use custom VNet (not kubenet)
- Enable service endpoint on AKS subnet
- Storage firewall: Allow selected VNets

### 3. Firewall Rules (Current Implementation)

```
AKS Cluster (Public IP) → Internet → Storage Account (Firewall Rules)
```

**Setup:**
- Storage account: Allow specific IPs
- Add AKS outbound IPs to firewall
- Less secure but simpler

## Implementation Examples

### Private Endpoint Setup (Terraform)

```hcl
# Private Endpoint for Storage
resource "azurerm_private_endpoint" "storage" {
  name                = "${var.naming_prefix}-storage-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.naming_prefix}-storage-psc"
    private_connection_resource_id = azurerm_storage_account.main.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "storage-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage.id]
  }
}

# Private DNS Zone
resource "azurerm_private_dns_zone" "storage" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
}

# Link DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  name                  = "${var.naming_prefix}-storage-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage.name
  virtual_network_id    = var.vnet_id
}

# Storage Account with Private Access
resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  # Disable public access
  public_network_access_enabled = false
  
  # Allow only private endpoints
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}
```

### Pod Configuration (No Changes Needed)

The pod configuration remains the same - workload identity handles authentication:

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: workload-identity-sa
  containers:
  - name: app
    image: myapp:latest
    # Workload identity provides authentication
    # Private endpoint provides network connectivity
```

### DNS Resolution Test Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dns-test
spec:
  containers:
  - name: test
    image: busybox
    command: ['sh', '-c', 'nslookup mystorageaccount.blob.core.windows.net && sleep 3600']
```

## Current vs. Private Endpoint Comparison

| Aspect | Current (Firewall) | Private Endpoint |
|--------|-------------------|------------------|
| **Security** | Medium | High |
| **Network Path** | Internet | Private |
| **Complexity** | Low | Medium |
| **Cost** | Lower | Higher |
| **Scalability** | Manual IP management | Automatic |
| **Compliance** | Good | Excellent |

## Migration Path

1. **Phase 1**: Current setup with firewall rules (working now)
2. **Phase 2**: Add private endpoint alongside firewall
3. **Phase 3**: Remove firewall rules, private endpoint only

## Network Requirements

### For Private Endpoint:
- Custom VNet for AKS (not kubenet)
- Dedicated subnet for private endpoints
- Private DNS zone configuration
- VNet peering if storage is in different VNet

### For Service Endpoint:
- Custom VNet for AKS
- Service endpoint enabled on subnet
- Storage firewall configured for VNet

## Code Changes Required

### None for Pod Code
The application code using Azure SDK remains unchanged:

```python
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient

# This works the same with private endpoint
credential = DefaultAzureCredential()
blob_client = BlobServiceClient(
    account_url="https://mystorageaccount.blob.core.windows.net",
    credential=credential
)
```

### Infrastructure Changes Only
All changes are in infrastructure (Terraform/ARM/Bicep):
- Add private endpoint resources
- Configure DNS zones
- Update network security groups if needed
