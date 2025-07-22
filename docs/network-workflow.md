# 🌐 Network Workflow: Kubernetes Pod to Private Azure Storage

This document explains the detailed network flow when a Kubernetes pod accesses Azure Storage through private endpoints using workload identity.

## 📋 Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Network Flow Step-by-Step](#network-flow-step-by-step)
3. [DNS Resolution Process](#dns-resolution-process)
4. [Authentication Flow](#authentication-flow)
5. [Traffic Path Analysis](#traffic-path-analysis)
6. [Security Boundaries](#security-boundaries)
7. [Troubleshooting Network Issues](#troubleshooting-network-issues)

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Azure Subscription                       │
│  ┌─────────────────┐    ┌─────────────────┐    ┌──────────────┐ │
│  │   AKS Cluster   │    │  Private DNS    │    │   Storage    │ │
│  │                 │    │     Zone        │    │   Account    │ │
│  │  ┌───────────┐  │    │                 │    │              │ │
│  │  │    Pod    │──┼────┼─DNS Query───────┼────┼─Private IP   │ │
│  │  │           │  │    │                 │    │              │ │
│  │  └───────────┘  │    │                 │    │              │ │
│  │       │         │    └─────────────────┘    └──────┬───────┘ │
│  │       │         │                                  │         │
│  │       │         │    ┌─────────────────┐          │         │
│  │       │         │    │ Private Endpoint│          │         │
│  │       └─────────┼────┤    Subnet       ├──────────┘         │
│  │                 │    │   10.0.2.0/24   │                    │
│  │                 │    └─────────────────┘                    │
│  └─────────────────┘                                           │
└─────────────────────────────────────────────────────────────────┘
```

## 🔄 Network Flow Step-by-Step

### Step 1: Pod Initialization
```yaml
# Pod starts with workload identity configuration
spec:
  serviceAccountName: workload-identity-sa
  containers:
  - name: app
    env:
    - name: AZURE_CLIENT_ID          # Injected by workload identity
    - name: AZURE_TENANT_ID          # Injected by workload identity
    - name: AZURE_FEDERATED_TOKEN_FILE # Injected by workload identity
```

**Network Context:**
- Pod gets IP from AKS subnet: `10.0.1.0/24`
- Pod inherits cluster DNS configuration
- Workload identity volumes mounted automatically

### Step 2: DNS Resolution Request
```bash
# Pod attempts to resolve storage account
nslookup akswliddevcentralusst.blob.core.windows.net
```

**DNS Flow:**
1. **Pod DNS Query** → `10.2.0.10` (AKS DNS service)
2. **AKS DNS** → Azure DNS with private zone override
3. **Private DNS Zone** → Returns private IP `10.0.2.4`
4. **Response Path** → Back to pod

**Expected Resolution:**
```
akswliddevcentralusst.blob.core.windows.net → 10.0.2.4
```

### Step 3: Authentication Token Request
```python
# DefaultAzureCredential initiates token exchange
credential = DefaultAzureCredential()
```

**Authentication Flow:**
1. **Read Federated Token** from `/var/run/secrets/azure/tokens/azure-identity-token`
2. **Token Exchange Request** to `https://login.microsoftonline.com/{tenant-id}/oauth2/v2.0/token`
3. **Azure AD Validation** of federated token
4. **Access Token Response** for storage scope

**Network Path for Auth:**
- Pod → AKS egress → Internet → Azure AD
- Uses public internet (not private endpoint)
- Standard HTTPS/443

### Step 4: Storage API Call
```python
# Authenticated request to storage
blob_service_client = BlobServiceClient(
    account_url="https://akswliddevcentralusst.blob.core.windows.net",
    credential=credential
)
```

**Storage Request Flow:**
1. **HTTPS Request** to `akswliddevcentralusst.blob.core.windows.net`
2. **DNS Resolution** → `10.0.2.4` (private endpoint)
3. **Traffic Routing** through VNet internal routing
4. **Private Endpoint** receives and forwards to storage
5. **Storage Response** back through private endpoint

## 🌐 DNS Resolution Process

### Private DNS Zone Configuration
```yaml
# Created by Terraform
resource "azurerm_private_dns_zone" "storage" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
}

# Links VNet to private DNS zone  
resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  name                  = "storage-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.storage.name
  virtual_network_id    = var.vnet_id
}
```

### DNS Resolution Verification
```bash
# Test from within a pod
kubectl run dns-test --image=busybox --rm -it -- nslookup akswliddevcentralusst.blob.core.windows.net

# Expected output:
# Name: akswliddevcentralusst.blob.core.windows.net
# Address: 10.0.2.4    ← Private endpoint IP
```

### Public vs Private Resolution
| Source | Domain | Resolves To | Path |
|--------|--------|-------------|------|
| External Internet | `*.blob.core.windows.net` | Public IP (e.g., 20.x.x.x) | Internet → Storage public endpoint |
| AKS Pod | `*.blob.core.windows.net` | Private IP (10.0.2.4) | VNet → Private endpoint → Storage |

## 🔐 Authentication Flow

### 1. Federated Token Structure
```json
{
  "aud": ["api://AzureADTokenExchange"],
  "iss": "https://centralus.oic.prod-aks.azure.com/38c7b18a-f92a-4353-a784-df16e895da23/3cb8845a-5445-421d-a39b-48de52286e43/",
  "sub": "system:serviceaccount:default:workload-identity-sa",
  "exp": 1726712345,
  "iat": 1726708745,
  "kubernetes.io": {
    "namespace": "default",
    "pod": {"name": "storage-query", "uid": "..."},
    "serviceaccount": {"name": "workload-identity-sa", "uid": "..."}
  }
}
```

### 2. Token Exchange Request
```http
POST https://login.microsoftonline.com/38c7b18a-f92a-4353-a784-df16e895da23/oauth2/v2.0/token
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials
&client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer
&client_assertion={FEDERATED_TOKEN}
&client_id=fa98300c-a162-490c-94e7-e2b69b195e77
&scope=https://storage.azure.com/.default
```

### 3. Access Token Response
```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIs...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "scope": "https://storage.azure.com/.default"
}
```

## 🛣️ Traffic Path Analysis

### Pod to Storage Network Path
```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│    Pod      │    │ AKS Subnet  │    │Private EP   │    │  Storage    │
│ 10.244.x.x  │───▶│ 10.0.1.0/24 │───▶│ 10.0.2.4    │───▶│  Account    │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

### Detailed Packet Flow
1. **Pod Network Namespace**
   - Source IP: `10.244.x.x` (Pod CIDR)
   - Destination: `10.0.2.4:443`
   - Protocol: HTTPS/TLS

2. **AKS Node Bridge**
   - CNI handles pod-to-node routing
   - Source NAT to node IP if needed
   - Forwards to VNet routing

3. **Azure VNet Routing**
   - Internal VNet routing table
   - Routes `10.0.2.4` to private endpoint subnet
   - No internet gateway involved

4. **Private Endpoint**
   - Receives on `10.0.2.4:443`
   - Terminates TLS connection
   - Forwards to storage via Azure backbone

5. **Storage Account**
   - Processes request privately
   - Returns response via same path
   - Never exposed to public internet

### Network Security Rules
```yaml
# Private endpoint subnet allows inbound from AKS
Source: 10.0.1.0/24 (AKS subnet)
Destination: 10.0.2.0/24 (Private endpoint subnet)  
Port: 443
Protocol: TCP
Action: Allow

# Storage account blocks public access
PublicNetworkAccess: Disabled
DefaultAction: Deny
```

## 🔒 Security Boundaries

### 1. Network Isolation
- ✅ **Private Connectivity**: Traffic never leaves Azure backbone
- ✅ **Subnet Isolation**: Private endpoint in dedicated subnet
- ✅ **DNS Isolation**: Private DNS zone prevents accidental public resolution
- ✅ **Firewall Protection**: Storage account denies all public access

### 2. Identity Isolation  
- ✅ **Workload Identity**: No shared secrets or service principal keys
- ✅ **RBAC Enforcement**: Managed identity has minimal required permissions
- ✅ **Token Scope**: Access tokens scoped to storage only
- ✅ **Automatic Rotation**: Federated tokens automatically expire and renew

### 3. Traffic Analysis
```bash
# Verify private endpoint usage from pod
kubectl exec -it <pod> -- python3 -c "
import socket
ip = socket.gethostbyname('akswliddevcentralusst.blob.core.windows.net')
print(f'Resolved IP: {ip}')
if ip.startswith('10.0.2.'):
    print('✅ Using private endpoint')
else:
    print('❌ Using public endpoint')
"
```

## 🔧 Troubleshooting Network Issues

### Common Issues and Solutions

#### Issue 1: Pod resolves to public IP
**Symptoms:**
```bash
nslookup akswliddevcentralusst.blob.core.windows.net
# Returns: 20.x.x.x (public IP)
```

**Diagnosis:**
```bash
# Check private DNS zone link
az network private-dns link vnet list \
  --resource-group <rg> \
  --zone-name privatelink.blob.core.windows.net

# Check private endpoint status  
az network private-endpoint show \
  --resource-group <rg> \
  --name <pe-name>
```

**Solution:** Verify private DNS zone is linked to AKS VNet

#### Issue 2: Connection timeouts to private IP
**Symptoms:**
```bash
curl https://10.0.2.4 
# Connection timeout
```

**Diagnosis:**
```bash
# Check network security groups
az network nsg rule list \
  --resource-group <rg> \
  --nsg-name <nsg-name>

# Verify subnet routes
az network route-table route list \
  --resource-group <rg> \
  --route-table-name <route-table>
```

**Solution:** Ensure NSG allows traffic from AKS subnet to private endpoint subnet

#### Issue 3: Authentication failures
**Symptoms:**
```
Error: This request is not authorized to perform this operation
```

**Diagnosis:**
```bash
# Check workload identity configuration
kubectl get serviceaccount workload-identity-sa -o yaml

# Verify federated credential
az identity federated-credential list \
  --identity-name <identity-name> \
  --resource-group <rg>
```

**Solution:** Verify federated credential subject matches service account

### Network Verification Commands
```bash
# Test complete flow from pod
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: network-debug
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: workload-identity-sa
  containers:
  - name: debug
    image: mcr.microsoft.com/azure-cli:latest
    command: ["/bin/bash", "-c", "sleep 3600"]
EOF

# Exec into pod and test
kubectl exec -it network-debug -- bash

# Inside pod:
# 1. Test DNS resolution
nslookup akswliddevcentralusst.blob.core.windows.net

# 2. Test network connectivity
curl -I https://akswliddevcentralusst.blob.core.windows.net

# 3. Test authentication
az storage container list --account-name akswliddevcentralusst --auth-mode login
```

## 📊 Performance Considerations

### Latency Analysis
- **DNS Resolution**: ~5-10ms (cached after first lookup)
- **Token Exchange**: ~50-100ms (cached for ~1 hour)  
- **Storage API Call**: ~10-20ms (private endpoint, same region)
- **Public vs Private**: Private endpoint typically 20-30% faster

### Monitoring Network Health
```bash
# Monitor private endpoint metrics
az monitor metrics list \
  --resource "/subscriptions/.../privateEndpoints/storage-pe" \
  --metric "BytesIn,BytesOut" \
  --interval PT1M
```

This comprehensive network workflow documentation helps users understand exactly how their Kubernetes pods securely access Azure Storage through private endpoints! 🚀
