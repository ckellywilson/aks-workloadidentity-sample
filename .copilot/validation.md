# ✅ Deployment Validation Checklist

## Pre-Deployment Validation

### Azure Prerequisites
- [ ] Azure CLI installed and authenticated (`az login`)
- [ ] Terraform installed (>= 1.5)
- [ ] kubectl installed
- [ ] Target subscription selected (`az account show`)
- [ ] Required permissions:
  - [ ] Contributor role on subscription
  - [ ] Azure AD permissions to create groups
  - [ ] Azure AD permissions to assign roles

### Configuration Validation
- [ ] Project name is valid (max 10 chars, alphanumeric)
- [ ] Environment is valid (dev/stg/prod)
- [ ] Azure region is supported
- [ ] Resource names follow pattern: `{project}-{env}-{region}-{type}`

## Deployment Validation

### Phase 1: Azure Infrastructure
Run these commands after `terraform apply` (first phase):

```bash
# Verify Resource Group
az group show --name "[project]-[env]-[region]-rg"

# Verify AKS Cluster
az aks show --name "[project]-[env]-[region]-aks" --resource-group "[project]-[env]-[region]-rg"

# Verify Entra ID Group
az ad group show --group "[project]-[env]-[region]-aks-admins"

# Verify Storage Account
az storage account show --name "[project][env][region]st" --resource-group "[project]-[env]-[region]-rg"

# Verify Container Registry
az acr show --name "[project][env][region]acr" --resource-group "[project]-[env]-[region]-rg"
```

### Phase 2: Kubernetes Resources
Run these commands after second `terraform apply`:

```bash
# Get AKS credentials
az aks get-credentials --name "[project]-[env]-[region]-aks" --resource-group "[project]-[env]-[region]-rg"

# Verify cluster connectivity
kubectl get nodes

# Verify workload identity
kubectl get serviceaccount -A
kubectl get federatedidentity -A

# Verify RBAC
kubectl auth can-i "*" "*" --as="$(az ad signed-in-user show --query userPrincipalName -o tsv)"
```

## Post-Deployment Testing

### Workload Identity Testing
```bash
# Deploy test pod
kubectl apply -f examples/test-pod.yaml

# Check pod logs for successful authentication
kubectl logs workload-identity-test-pod

# Verify storage access
kubectl exec workload-identity-test-pod -- az storage blob list --account-name "[project][env][region]st" --container-name "test"
```

### Network Connectivity Testing
```bash
# Test internal connectivity
kubectl run test-pod --image=busybox --rm -it -- sh
# Inside pod: nslookup kubernetes.default

# Test external connectivity
kubectl run test-pod --image=curlimages/curl --rm -it -- curl -s https://www.microsoft.com
```

### RBAC Testing
```bash
# Test as admin user
kubectl get pods --all-namespaces

# Test namespace access
kubectl create namespace test-namespace
kubectl get namespace test-namespace
kubectl delete namespace test-namespace
```

## Security Validation

### Managed Identity Verification
- [ ] AKS cluster has system-assigned managed identity disabled
- [ ] Kubelet identity is user-assigned managed identity
- [ ] Control plane identity is user-assigned managed identity
- [ ] Workload identity is properly federated

### Network Security
- [ ] AKS cluster uses private IPs
- [ ] Network security groups are properly configured
- [ ] Storage account has appropriate access restrictions
- [ ] Container registry has admin user disabled

### Azure AD Integration
- [ ] AKS cluster has Azure AD integration enabled
- [ ] Azure RBAC is enabled for Kubernetes authorization
- [ ] Admin group has appropriate cluster roles
- [ ] Current user is member of admin group

## Troubleshooting Common Issues

### Authentication Issues
```bash
# Check Azure login
az account show

# Re-authenticate if needed
az login

# Check AKS credentials
kubectl config current-context
kubectl config get-contexts
```

### Permission Issues
```bash
# Check current user permissions
az role assignment list --assignee "$(az ad signed-in-user show --query objectId -o tsv)" --scope "/subscriptions/$(az account show --query id -o tsv)"

# Check group membership
az ad group member check --group "[project]-[env]-[region]-aks-admins" --member-id "$(az ad signed-in-user show --query objectId -o tsv)"
```

### Workload Identity Issues
```bash
# Check service account annotations
kubectl get serviceaccount [workload-identity-sa-name] -o yaml

# Check federated identity
az identity federated-credential list --identity-name "[project]-[env]-[region]-workload-identity" --resource-group "[project]-[env]-[region]-rg"

# Check OIDC issuer
az aks show --name "[project]-[env]-[region]-aks" --resource-group "[project]-[env]-[region]-rg" --query "oidcIssuerProfile"
```

### Networking Issues
```bash
# Check node status
kubectl get nodes -o wide

# Check system pods
kubectl get pods -n kube-system

# Check DNS resolution
kubectl run test-dns --image=busybox --rm -it -- nslookup kubernetes.default
```

## Performance Validation

### Resource Utilization
```bash
# Check node resources
kubectl top nodes

# Check pod resources
kubectl top pods --all-namespaces

# Check cluster utilization
kubectl describe nodes
```

### Storage Performance
```bash
# Test storage mount
kubectl apply -f examples/sample-app.yaml
kubectl exec deployment/sample-app -- df -h /mnt/azure

# Test storage read/write
kubectl exec deployment/sample-app -- touch /mnt/azure/test-file
kubectl exec deployment/sample-app -- ls -la /mnt/azure/
```

## Compliance Checks

### Naming Convention Compliance
- [ ] All resources follow `{project}-{env}-{region}-{type}` pattern
- [ ] Region abbreviations match Microsoft standards
- [ ] Storage account names are globally unique and valid
- [ ] Resource names are within Azure limits

### Security Compliance
- [ ] No admin users enabled on container registry
- [ ] Storage account uses managed identity authentication
- [ ] AKS cluster uses Azure AD for authentication
- [ ] Network policies are in place (if required)

### Operational Compliance
- [ ] Resource tags are applied consistently
- [ ] Monitoring and logging are configured
- [ ] Backup strategies are in place
- [ ] Update policies are defined

## Success Criteria

### ✅ Deployment is successful if:
1. All Azure resources are created with correct names
2. AKS cluster is accessible via kubectl
3. Current user can perform administrative tasks
4. Workload identity test pod authenticates successfully
5. Sample application can mount and access storage
6. No security violations or misconfigurations

### ⚠️ Common warnings that are acceptable:
- Terraform warnings about preview features
- kubectl warnings about deprecated API versions
- Azure CLI warnings about preview extensions

### ❌ Deployment failed if:
- Cannot connect to AKS cluster
- Authentication failures
- Workload identity not working
- Storage access denied
- Permission errors

## Cleanup Validation

After running cleanup/destroy:
```bash
# Verify all resources are deleted
az resource list --resource-group "[project]-[env]-[region]-rg"

# Verify Entra ID group is deleted
az ad group show --group "[project]-[env]-[region]-aks-admins"

# Verify no orphaned resources
az resource list --query "[?resourceGroup=='[project]-[env]-[region]-rg']"
```

Use this checklist to ensure your AKS workload identity deployment is properly configured, secure, and functional!
