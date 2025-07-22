# 🧪 Examples and Testing Guide

This directory contains practical examples and test cases for validating your AKS Workload Identity deployment. Use these examples to verify connectivity, understand workload identity behavior, and troubleshoot issues.

## 📋 Table of Contents

1. [Available Examples](#available-examples)
2. [Quick Testing](#quick-testing)
3. [Example Descriptions](#example-descriptions)
4. [Testing Scenarios](#testing-scenarios)
5. [Troubleshooting Examples](#troubleshooting-examples)

## 📁 Available Examples

| File | Purpose | Use Case |
|------|---------|----------|
| [test-storage-access.yaml](test-storage-access.yaml) | Test Azure Storage connectivity with workload identity | Validation & debugging |
| [inspect-token.yaml](inspect-token.yaml) | Analyze federated token structure and environment | Token inspection & troubleshooting |
| [storage-query-configmap.yaml](storage-query-configmap.yaml) | ConfigMap with Python script to query storage containers and blobs | Storage content inspection |
| [storage-query-pod.yaml](storage-query-pod.yaml) | Pod that uses the configmap to query storage account contents | Production-ready storage querying |
| [network-workflow-simple-validation.yaml](network-workflow-simple-validation.yaml) | **Network workflow validation** - Validates DNS, connectivity, and tokens | Network troubleshooting & validation |

### 🌐 Network Workflow Validation

| File | Purpose | Description |
|------|---------|-------------|
| [network-workflow-simple-validation.yaml](network-workflow-simple-validation.yaml) | Network flow validation | Tests DNS resolution, HTTPS connectivity, token presence, and network environment |

## 🚀 Quick Testing

### 1. Basic Workload Identity Test
```bash
# Deploy the storage access test
kubectl apply -f test-storage-access.yaml

# Check pod status
kubectl get pods

# View logs to see results
kubectl logs storage-access-test
```

### 2. Token Inspection
```bash
# Deploy token inspector
kubectl apply -f inspect-token.yaml

# Wait for completion and view results
kubectl wait --for=condition=complete job/token-inspector --timeout=60s
kubectl logs job/token-inspector
```

### 3. Storage Content Query
```bash
# Deploy the configmap with the Python script
kubectl apply -f storage-query-configmap.yaml

# Deploy the storage query pod
kubectl apply -f storage-query-pod.yaml

# Wait for pod to complete and view results
kubectl wait --for=condition=Ready pod/storage-query --timeout=60s
kubectl logs storage-query

# Alternative: Follow logs in real-time
kubectl logs -f storage-query
```

### 4. Network Workflow Validation
```bash
# Create required ConfigMap (if not already present)
kubectl create configmap storage-query-config --from-literal=storage-account-name=<your-storage-account-name>

# Deploy network validation pod
kubectl apply -f network-workflow-simple-validation.yaml

# Wait for completion and view results
kubectl wait --for=condition=Ready pod/network-workflow-simple-validation --timeout=60s || kubectl get pod network-workflow-simple-validation
kubectl logs network-workflow-simple-validation

# Expected output shows:
# ✅ DNS resolves to private IP (10.x.x.x) 
# ✅ HTTPS connectivity successful
# ✅ Federated token file exists
# ✅ Network environment details
```

### 5. Cleanup
```bash
# Remove test pods and configmaps
kubectl delete -f test-storage-access.yaml
kubectl delete -f inspect-token.yaml
kubectl delete -f storage-query-pod.yaml
kubectl delete -f storage-query-configmap.yaml
kubectl delete -f network-workflow-simple-validation.yaml
kubectl delete configmap storage-query-config
```

## 📖 Example Descriptions

### 🔐 test-storage-access.yaml

**Purpose**: Validates workload identity connectivity to Azure Storage

**What it does**:
1. ✅ Prints all Azure workload identity environment variables
2. ✅ Attempts to list storage containers
3. ✅ Tries to create a test blob in the `app-data` container
4. ✅ Reads back the created blob
5. ✅ Shows all environment variables for debugging

**Expected Output (Success)**:
```
=== Environment Variables ===
AZURE_CLIENT_ID: 6be2b4da-09e4-4246-aab1-d04d656a31f4
AZURE_TENANT_ID: 38c7b18a-f92a-4353-a784-df16e895da23
AZURE_FEDERATED_TOKEN_FILE: /var/run/secrets/azure/tokens/azure-identity-token
AZURE_AUTHORITY_HOST: https://login.microsoftonline.com/

=== Testing Azure Storage Access ===
Attempting to list containers...
Found containers: ['app-data', 'other-container']
Attempting to create a test blob...
✅ Successfully created test blob!
✅ Successfully read back: This blob was created using workload identity!
🎉 WORKLOAD IDENTITY TEST SUCCESSFUL! 🎉
```

**Expected Output (Permission Issue)**:
```
❌ Error: This request is not authorized to perform this operation.
RequestId:d695fa12-301e-000d-6f4e-faa85b000000
ErrorCode:AuthorizationFailure
WORKLOAD IDENTITY TEST FAILED
```

**Key Features**:
- Uses `azure.workload.identity/use: "true"` label
- References `workload-identity-sa` service account
- Installs Azure SDK packages at runtime
- Comprehensive environment variable logging
- Error handling with detailed Azure error messages

### 🔍 inspect-token.yaml

**Purpose**: Deep inspection of the federated token file and workload identity configuration

**What it does**:
1. 📋 Shows all Azure environment variables
2. 📁 Displays token file location and permissions
3. 🔐 Prints the raw JWT token
4. 🧪 Decodes JWT header and payload
5. 💾 Shows volume mount details

**Token Structure Revealed**:
```json
{
  "aud": ["api://AzureADTokenExchange"],
  "iss": "https://centralus.oic.prod-aks.azure.com/.../",
  "sub": "system:serviceaccount:default:workload-identity-sa",
  "kubernetes.io": {
    "namespace": "default",
    "pod": {"name": "token-inspector", "uid": "..."},
    "serviceaccount": {"name": "workload-identity-sa", "uid": "..."}
  }
}
```

**Key Insights**:
- Token audience is `api://AzureADTokenExchange`
- Issuer is the AKS cluster OIDC endpoint
- Subject identifies the Kubernetes service account
- Rich Kubernetes context included in token

### 📊 storage-query-configmap.yaml & storage-query-pod.yaml

**Purpose**: Query and inspect existing data in Azure Storage containers using workload identity

**What it does**:
1. 📦 **ConfigMap**: Contains a Python script that lists containers and blobs
2. 🔍 **Pod**: Runs the script to query storage account contents
3. 📋 **Lists all containers** in the storage account
4. 📄 **Shows blob details**: name, size, last modified, content type
5. 📖 **Displays content** for small text files (< 1KB)

**Expected Output (Success)**:
```
=== Azure Storage Query using Workload Identity ===
Storage Account: akswliddevcentralusst
Account URL: https://akswliddevcentralusst.blob.core.windows.net

=== Listing Containers ===
Container: app-data

=== Blobs in Container: app-data ===
  Blob: workload-identity-test.txt
    Size: 61 bytes
    Last Modified: 2025-07-22 04:27:44+00:00
    Content Type: application/octet-stream
    Content: Test from workload identity using private endpoint - 10.0.2.4

✅ Storage query completed successfully!
```

**Key Features**:
- **Production-ready script**: Robust error handling and detailed output
- **ConfigMap pattern**: Reusable script that can be mounted in multiple pods
- **Environment variable support**: Can override storage account name
- **Content inspection**: Shows actual blob content for verification
- **Private endpoint awareness**: Works seamlessly with private storage

### 🌐 network-workflow-simple-validation.yaml

**Purpose**: Validates the complete network workflow from Kubernetes pod to Azure Storage through private endpoints

**What it does**:
1. 🌐 **DNS Resolution Test**: Verifies storage account resolves to private IP (10.x.x.x range)
2. 🔗 **HTTPS Connectivity Test**: Confirms network path to storage endpoint works
3. 🎫 **Token Validation**: Checks federated token file exists and has correct format
4. 📱 **HTTP Response Test**: Inspects actual HTTP headers from storage service
5. 🖥️ **Network Environment**: Shows pod network configuration and DNS settings

**Expected Output (Success)**:
```
=== Simple Network Workflow Validation Test ===

1. Environment Setup:
Storage Account: akswliddevcentralusst
Service Account: workload-identity-sa
Client ID: fa98300c-a162-490c-94e7-e2b69b195e77
Tenant ID: 38c7b18a-f92a-4353-a784-df16e895da23
Token File: /var/run/secrets/azure/tokens/azure-identity-token

2. DNS Resolution Test:
Resolving: akswliddevcentralusst.blob.core.windows.net
akswliddevcentralusst.blob.core.windows.net canonical name = akswliddevcentralusst.privatelink.blob.core.windows.net
Name: akswliddevcentralusst.privatelink.blob.core.windows.net
Address: 10.0.2.4
Resolved IP: 10.0.2.4
✅ DNS resolves to private IP - private endpoint working

3. Network Connectivity Test:
Testing HTTPS connectivity to storage endpoint...
✅ HTTPS connectivity successful

4. HTTP Response Test:
Testing HTTP response headers...
HTTP/1.1 400 Value for one of the query parameters specified in the request URI is invalid.
Transfer-Encoding: chunked
Server: Microsoft-HTTPAPI/2.0

5. Federated Token Validation:
✅ Federated token file exists
Token file size: 1633 bytes
Token preview (first 50 chars):
eyJhbGciOiJSUzI1NiIsImtpZCI6Inc0WVMtV0JQWF80ME9XMm...

6. Network Environment:
Container network info:
eth0: <BROADCAST,UP,LOWER_UP,M-DOWN> mtu 1500
    inet 10.244.2.167/16 scope global eth0

DNS configuration:
nameserver 10.2.0.10
search default.svc.cluster.local svc.cluster.local cluster.local
```

**Key Validation Points**:
- **Private DNS Resolution**: CNAME chain shows `blob.core.windows.net` → `privatelink.blob.core.windows.net`
- **Private IP Confirmation**: Storage resolves to 10.x.x.x (private endpoint IP)
- **Network Connectivity**: Pod can reach storage over HTTPS
- **Token Presence**: Workload identity token properly mounted
- **Network Configuration**: Pod network and DNS settings are correct

**References the detailed documentation**: See [Network Workflow Guide](../docs/network-workflow.md) for comprehensive network flow analysis and troubleshooting.

## 🧪 Testing Scenarios

### Scenario 1: Fresh Deployment Validation
**Goal**: Verify everything works after initial deployment

```bash
# 1. Test basic connectivity
kubectl apply -f test-storage-access.yaml
kubectl logs storage-access-test

# 2. Inspect token structure
kubectl apply -f inspect-token.yaml
kubectl logs token-inspector

# 3. Cleanup
kubectl delete pod storage-access-test token-inspector
```

### Scenario 2: Permission Troubleshooting
**Goal**: Understand why workload identity authentication fails

```bash
# 1. Deploy test (expect failure)
kubectl apply -f test-storage-access.yaml

# 2. Check specific error
kubectl logs storage-access-test | grep "Error:"

# 3. Verify environment variables are injected
kubectl logs storage-access-test | grep "AZURE_"

# 4. Check token structure
kubectl apply -f inspect-token.yaml
kubectl logs token-inspector | grep -A 20 "JWT Payload"
```

**Common Error Patterns**:
- `AuthorizationFailure`: Managed identity lacks storage permissions
- `Token file not found`: Workload identity not configured
- `Environment variables missing`: Pod missing required labels/service account

### Scenario 3: Token Rotation Testing
**Goal**: Verify tokens rotate properly

```bash
# 1. Deploy long-running inspector
kubectl apply -f inspect-token.yaml

# 2. Check initial token
kubectl logs token-inspector | grep "exp"

# 3. Wait 1 hour and check again (new token should be issued)
```

### Scenario 4: Storage Content Verification
**Goal**: Inspect what data exists in storage containers

```bash
# 1. Deploy storage query tools
kubectl apply -f storage-query-configmap.yaml
kubectl apply -f storage-query-pod.yaml

# 2. Check results
kubectl logs storage-query

# 3. Verify specific blob content
kubectl logs storage-query | grep -A 5 "Content:"

# 4. Test with custom storage account (if different)
# Edit the pod yaml and add environment variable:
# - name: STORAGE_ACCOUNT_NAME
#   value: "yourstorageaccount"
```

### Scenario 5: Multi-Environment Testing
**Goal**: Test across different environments/namespaces

```bash
# Test in different namespace
kubectl create namespace test-env
kubectl apply -f test-storage-access.yaml -n test-env

# Note: This will fail unless service account exists in that namespace
```

## 🔧 Troubleshooting Examples

### Issue 1: Pod Doesn't Have Workload Identity Environment Variables

**Test**:
```bash
kubectl apply -f test-storage-access.yaml
kubectl exec storage-access-test -- env | grep AZURE
```

**Expected**: Should show 4 Azure environment variables
**If empty**: Check pod labels and service account configuration

**Fix**:
```yaml
metadata:
  labels:
    azure.workload.identity/use: "true"  # Required label
spec:
  serviceAccountName: workload-identity-sa  # Must use correct SA
```

### Issue 2: Token File Not Accessible

**Test**:
```bash
kubectl exec storage-access-test -- ls -la /var/run/secrets/azure/tokens/
```

**Expected**: Should show `azure-identity-token` symlink
**If missing**: Workload identity webhook not injecting volume

**Debug**:
```bash
# Check webhook is running
kubectl get pods -n azure-workload-identity-system

# Verify pod spec was modified
kubectl get pod storage-access-test -o yaml | grep -A 10 volumeMounts
```

### Issue 3: Authentication Working but Authorization Failing

**Symptoms**: 
- ✅ Environment variables present
- ✅ Token file exists and valid
- ❌ Azure API calls return `AuthorizationFailure`

**Root Cause**: Managed identity lacks permissions

**Fix**:
```bash
# Check current role assignments
az role assignment list --assignee <AZURE_CLIENT_ID>

# Grant Storage Blob Data Contributor role
az role assignment create \
  --assignee <AZURE_CLIENT_ID> \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<storage>"
```

### Issue 4: Wrong Storage Account Target

**Symptoms**: Authentication works but accessing wrong storage account

**Debug**:
```bash
# Check what storage account the test is targeting
kubectl logs storage-access-test | grep "storage_account_name"

# Verify storage account exists
az storage account show --name <storage-account-name> --resource-group <rg>
```

## 🎯 Custom Test Examples

### Create Your Own Test Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-workload-test
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: workload-identity-sa
  containers:
  - name: test
    image: mcr.microsoft.com/azure-cli:latest
    command: ["/bin/bash", "-c"]
    args:
    - |
      echo "Testing Azure CLI with workload identity..."
      
      # Check environment
      echo "AZURE_CLIENT_ID: $AZURE_CLIENT_ID"
      
      # Login using workload identity
      az login --identity --username $AZURE_CLIENT_ID
      
      # Test Azure operations
      az account show
      az storage account list
      
      sleep 300  # Keep pod running for debugging
  restartPolicy: Never
```

### Minimal Python Test

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: python-minimal-test
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: workload-identity-sa
  containers:
  - name: python-test
    image: python:3.9-slim
    command: ["/bin/bash", "-c"]
    args:
    - |
      pip install azure-identity azure-mgmt-storage
      python3 -c "
      from azure.identity import DefaultAzureCredential
      from azure.mgmt.storage import StorageManagementClient
      
      credential = DefaultAzureCredential()
      print('✅ Credential obtained successfully')
      
      # Test credential with Azure Management API
      client = StorageManagementClient(credential, '<subscription-id>')
      print('✅ Storage client created successfully')
      "
  restartPolicy: Never
```

## 📚 Related Documentation

- [Network Workflow](../docs/network-workflow.md) - **Pod-to-storage network flow analysis**
- [Azure Federated Token File](../docs/azure-federated-token-file.md) - Deep dive into token mechanism
- [Azure AD Admin Groups](../docs/azure-ad-admin-groups.md) - Access control setup
- [Infrastructure Documentation](../infra/tf/modules/README.md) - Architecture details
- [Main README](../README.md) - Complete project guide

## 💡 Best Practices

1. **Always check logs**: Use `kubectl logs` to see detailed error messages
2. **Test incrementally**: Start with token inspection, then move to API calls
3. **Verify environment**: Ensure all Azure environment variables are present
4. **Check permissions**: Verify managed identity has required Azure role assignments
5. **Use cleanup**: Always clean up test resources after validation

---

🔍 **Need Help?** Check the troubleshooting section in [Azure Federated Token File](../docs/azure-federated-token-file.md#troubleshooting) documentation.