# Sample Application with Workload Identity

This directory contains sample applications demonstrating how to use Azure Workload Identity with the deployed AKS cluster.

## Test Pod

A simple test pod that uses the workload identity to authenticate with Azure services.

### Deploy

```bash
# Update the CLIENT_ID in test-pod.yaml first
kubectl apply -f test-pod.yaml
```

### Test

```bash
# Check if the pod is running
kubectl get pods

# Test Azure authentication
kubectl exec -it test-workload-identity -- az account show

# Test accessing Azure resources
kubectl exec -it test-workload-identity -- az storage account list
```

## Sample Application

A more complete application that demonstrates accessing Azure Storage using workload identity.

### Deploy

```bash
kubectl apply -f sample-app.yaml
```

### Check Logs

```bash
kubectl logs -f deployment/sample-app
```
