# Azure Workload Identity: AZURE_FEDERATED_TOKEN_FILE Documentation

## Overview

The `AZURE_FEDERATED_TOKEN_FILE` is a core component of Azure Workload Identity that enables secure, passwordless authentication from Kubernetes pods to Azure services. This document explains how it works, what it contains, and the complete authentication flow.

## Table of Contents

1. [What is AZURE_FEDERATED_TOKEN_FILE?](#what-is-azure_federated_token_file)
2. [How It Gets Created](#how-it-gets-created)
3. [Token Structure and Contents](#token-structure-and-contents)
4. [Authentication Flow](#authentication-flow)
5. [Security Model](#security-model)
6. [Volume Mount Configuration](#volume-mount-configuration)
7. [Token Lifecycle](#token-lifecycle)
8. [Troubleshooting](#troubleshooting)

## What is AZURE_FEDERATED_TOKEN_FILE?

The `AZURE_FEDERATED_TOKEN_FILE` is an environment variable that points to a file containing a JWT (JSON Web Token) issued by the Kubernetes cluster. This token serves as proof of the pod's identity and is used in the OAuth 2.0 Token Exchange flow to obtain Azure access tokens.

**Key Properties:**
- **File Path**: `/var/run/secrets/azure/tokens/azure-identity-token`
- **Format**: JWT (JSON Web Token)
- **Validity**: 1 hour (3600 seconds)
- **Issuer**: AKS cluster's OIDC endpoint
- **Purpose**: Federated identity authentication with Azure AD

## How It Gets Created

### 1. Prerequisites

The token file is automatically created when all of the following conditions are met:

```yaml
# Pod must have the workload identity label
metadata:
  labels:
    azure.workload.identity/use: "true"

# Pod must use a service account configured for workload identity
spec:
  serviceAccountName: workload-identity-sa
```

### 2. Azure Workload Identity Mutating Webhook

When a pod is created, the Azure Workload Identity mutating webhook intercepts the pod creation and automatically:

#### Injects Environment Variables:
```bash
AZURE_CLIENT_ID=<managed-identity-client-id>
AZURE_TENANT_ID=<azure-tenant-id>
AZURE_FEDERATED_TOKEN_FILE=/var/run/secrets/azure/tokens/azure-identity-token
AZURE_AUTHORITY_HOST=https://login.microsoftonline.com/
```

#### Adds Volume Mount:
```yaml
volumeMounts:
- mountPath: /var/run/secrets/azure/tokens
  name: azure-identity-token
  readOnly: true
```

#### Configures Projected Volume:
```yaml
volumes:
- name: azure-identity-token
  projected:
    defaultMode: 420
    sources:
    - serviceAccountToken:
        audience: api://AzureADTokenExchange
        expirationSeconds: 3600
        path: azure-identity-token
```

### 3. Kubernetes Token Projection

Kubernetes creates the token using the **TokenRequest API** with these specifications:
- **Audience**: `api://AzureADTokenExchange` (Azure's token exchange endpoint)
- **Expiration**: 3600 seconds (1 hour)
- **Path**: `azure-identity-token`
- **Issuer**: AKS cluster's OIDC issuer URL

## Token Structure and Contents

### JWT Header
```json
{
  "alg": "RS256",
  "kid": "<key-identifier>"
}
```

### JWT Payload (Claims)
```json
{
  "aud": ["api://AzureADTokenExchange"],
  "exp": 1753112924,
  "iat": 1753109324,
  "iss": "https://<region>.oic.prod-aks.azure.com/<tenant-id>/<cluster-oidc-id>/",
  "jti": "<unique-token-id>",
  "kubernetes.io": {
    "namespace": "<pod-namespace>",
    "node": {
      "name": "<node-name>",
      "uid": "<node-uid>"
    },
    "pod": {
      "name": "<pod-name>",
      "uid": "<pod-uid>"
    },
    "serviceaccount": {
      "name": "<service-account-name>",
      "uid": "<service-account-uid>"
    }
  },
  "nbf": 1753109324,
  "sub": "system:serviceaccount:<namespace>:<service-account>"
}
```

### Claim Definitions

| Claim | Description |
|-------|-------------|
| `aud` | Audience - Always `api://AzureADTokenExchange` |
| `exp` | Expiration time (Unix timestamp) |
| `iat` | Issued at time (Unix timestamp) |
| `iss` | Issuer - AKS cluster's OIDC endpoint |
| `jti` | JWT ID - Unique identifier for this token |
| `nbf` | Not before time (Unix timestamp) |
| `sub` | Subject - Kubernetes service account identifier |
| `kubernetes.io` | Rich Kubernetes context (namespace, pod, node, service account) |

## Authentication Flow

### Step 1: Pod Startup
```
1. Pod starts with workload identity label
2. Webhook injects environment variables and volume mount
3. Kubernetes creates projected volume with federated token
4. Token file appears at /var/run/secrets/azure/tokens/azure-identity-token
```

### Step 2: Token Exchange
```
1. Application reads AZURE_FEDERATED_TOKEN_FILE
2. DefaultAzureCredential loads the federated token
3. Azure SDK calls Azure AD token exchange endpoint:
   POST https://login.microsoftonline.com/{tenant}/oauth2/v2.0/token
   Content-Type: application/x-www-form-urlencoded
   
   grant_type=urn:ietf:params:oauth:grant-type:token-exchange
   &client_id={managed-identity-client-id}
   &client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer
   &client_assertion={federated-token}
   &scope=https://storage.azure.com/.default
   &requested_token_use=on_behalf_of
   &subject_token_type=urn:ietf:params:oauth:token-type:access_token
   &subject_token={federated-token}
```

### Step 3: Azure Access Token
```
1. Azure AD validates the federated token:
   - Verifies JWT signature against AKS OIDC public keys
   - Checks token audience, issuer, and expiration
   - Validates the trust relationship between AKS and managed identity
2. Azure AD issues an access token for the managed identity
3. Application uses the access token to call Azure services
```

## Security Model

### Trust Relationship
```
AKS Cluster OIDC Issuer ←→ Azure AD ←→ Managed Identity
```

1. **AKS OIDC Issuer**: Issues signed JWT tokens for service accounts
2. **Azure AD Trust**: Configured to trust the AKS OIDC issuer
3. **Federated Identity Credential**: Links the Kubernetes service account to the managed identity

### Security Features

#### Cryptographic Security
- **RS256 Signature**: Token signed with cluster's private key
- **Public Key Validation**: Azure AD verifies signature using cluster's public OIDC keys
- **Tamper Detection**: Any modification invalidates the signature

#### Temporal Security
- **Short-lived Tokens**: 1-hour expiration prevents long-term credential exposure
- **Automatic Rotation**: Kubernetes automatically rotates tokens before expiration
- **Just-in-time**: Tokens created only when pods start

#### Context Security
- **Pod-specific**: Each token contains unique pod/node/namespace identifiers
- **Audience Restriction**: Tokens only valid for Azure AD token exchange
- **Subject Binding**: Tied to specific Kubernetes service account

#### Network Security
- **In-cluster Only**: Tokens only accessible within the Kubernetes cluster
- **Volume Mount**: Secured through Kubernetes RBAC and pod security contexts
- **Read-only**: Token files mounted as read-only

## Volume Mount Configuration

### File System Details
```bash
# Token file is a symbolic link to projected volume data
$ ls -la /var/run/secrets/azure/tokens/azure-identity-token
lrwxrwxrwx 1 root root 27 Jul 21 14:48 /var/run/secrets/azure/tokens/azure-identity-token -> ..data/azure-identity-token

# Volume is mounted as tmpfs (in-memory)
$ mount | grep azure
tmpfs on /run/secrets/azure/tokens type tmpfs (ro,relatime,size=2856348k,inode64)

# Disk usage
$ df -h /var/run/secrets/azure/tokens
Filesystem      Size  Used Avail Use% Mounted on
tmpfs           2.8G  4.0K  2.8G   1% /run/secrets/azure/tokens
```

### Projected Volume Structure
```
/var/run/secrets/azure/tokens/
├── azure-identity-token -> ..data/azure-identity-token
└── ..data/
    └── azure-identity-token (actual JWT content)
```

## Token Lifecycle

### Creation Timeline
```
1. Pod Creation Request
   ↓
2. Webhook Intercepts (< 1 second)
   ↓
3. Environment Variables Injected
   ↓
4. Volume Mount Added
   ↓
5. Pod Scheduled to Node
   ↓
6. Kubelet Creates Projected Volume
   ↓
7. Token File Available (< 5 seconds total)
```

### Rotation Process
```
Every ~50 minutes:
1. Kubernetes generates new token
2. New token written to volume
3. Symbolic link updated atomically
4. Old token becomes invalid
5. Applications automatically pick up new token
```

### Cleanup
```
Pod Termination:
1. Pod receives SIGTERM
2. Grace period begins (default 30 seconds)
3. Volume unmounted
4. Token file removed
5. Pod deleted
```

## Troubleshooting

### Common Issues

#### 1. Token File Not Present
```bash
# Check if webhook is running
$ kubectl get pods -n azure-workload-identity-system

# Verify pod has correct label
$ kubectl get pod <pod-name> -o yaml | grep azure.workload.identity

# Check service account configuration
$ kubectl get serviceaccount workload-identity-sa -o yaml
```

#### 2. Authentication Failures
```bash
# Verify environment variables
$ kubectl exec <pod-name> -- env | grep AZURE

# Check token content
$ kubectl exec <pod-name> -- cat $AZURE_FEDERATED_TOKEN_FILE

# Validate token structure
$ kubectl exec <pod-name> -- python3 -c "
import jwt, json, os
token = open(os.environ['AZURE_FEDERATED_TOKEN_FILE']).read()
print(json.dumps(jwt.decode(token, options={'verify_signature': False}), indent=2))
"
```

#### 3. Permission Errors
```bash
# Check managed identity assignments
$ az role assignment list --assignee <client-id>

# Verify federated identity credential
$ az identity federated-credential list --name <identity-name> --resource-group <rg>
```

### Debugging Commands

#### Inspect Token Details
```bash
# View all environment variables
kubectl exec <pod-name> -- printenv | grep AZURE

# Check token file permissions
kubectl exec <pod-name> -- ls -la $AZURE_FEDERATED_TOKEN_FILE

# Decode JWT token
kubectl exec <pod-name> -- python3 -c "
import jwt, json, os
with open(os.environ['AZURE_FEDERATED_TOKEN_FILE']) as f:
    token = f.read().strip()
header = jwt.get_unverified_header(token)
payload = jwt.decode(token, options={'verify_signature': False})
print('Header:', json.dumps(header, indent=2))
print('Payload:', json.dumps(payload, indent=2))
"
```

#### Validate Configuration
```bash
# Check webhook configuration
kubectl get mutatingwebhookconfiguration azure-wi-webhook-mutating-webhook-configuration

# Verify OIDC issuer
kubectl get --raw /.well-known/openid_configuration

# Test token exchange manually
curl -X POST https://login.microsoftonline.com/{tenant}/oauth2/v2.0/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=urn:ietf:params:oauth:grant-type:token-exchange&client_id={client-id}&client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer&client_assertion={federated-token}&scope=https://storage.azure.com/.default&requested_token_use=on_behalf_of&subject_token_type=urn:ietf:params:oauth:token-type:access_token&subject_token={federated-token}"
```

## Best Practices

### Application Development
1. **Use DefaultAzureCredential**: Always use the Azure SDK's DefaultAzureCredential
2. **Handle Token Rotation**: Design applications to handle automatic token rotation
3. **Error Handling**: Implement proper retry logic for authentication failures
4. **Token Caching**: Let Azure SDK handle token caching and refresh

### Security
1. **Least Privilege**: Grant minimal required permissions to managed identities
2. **Resource Scoping**: Scope role assignments to specific resources when possible
3. **Regular Auditing**: Regularly review federated identity credentials and role assignments
4. **Pod Security**: Use pod security contexts to further restrict container privileges

### Operations
1. **Monitoring**: Monitor authentication failures and token exchange errors
2. **Logging**: Enable Azure AD sign-in logs for workload identity authentication
3. **Alerting**: Set up alerts for authentication failures or misconfigurations
4. **Documentation**: Document service account to managed identity mappings

## References

- [Azure Workload Identity Documentation](https://azure.github.io/azure-workload-identity/)
- [OAuth 2.0 Token Exchange RFC](https://tools.ietf.org/html/rfc8693)
- [Kubernetes Service Account Token Volume Projection](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#serviceaccount-token-volume-projection)
- [Azure AD Federated Identity Credentials](https://docs.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation)

## 📚 Related Documentation

- [📚 Documentation Hub](README.md) - Complete navigation guide
- [🔐 Azure AD Admin Groups](azure-ad-admin-groups.md) - Access control setup
- [🧪 Examples Guide](../examples/README.md) - Test workload identity
- [🏗️ Infrastructure Guide](../infra/tf/modules/README.md) - Architecture details
- [📖 Main README](../README.md) - Project overview

---

💡 **Ready to Test?** Use the [Examples Guide](../examples/README.md) to validate your workload identity setup.
