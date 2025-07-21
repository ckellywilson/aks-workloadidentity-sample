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

### 3. Cleanup
```bash
# Remove test pods
kubectl delete -f test-storage-access.yaml
kubectl delete -f inspect-token.yaml
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

### Scenario 4: Multi-Environment Testing
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