# 🎨 Template Generator Prompts for Different Scenarios

## Scenario 1: Development Environment
```
Generate an AKS workload identity environment for development using these settings:

PROJECT: "devapp"
ENVIRONMENT: "dev" 
REGION: "Central US"
NODE_COUNT: 2
VM_SIZE: "Standard_B2s"
FEATURES: Basic workload identity, single node pool, minimal cost

Follow the architecture patterns in .copilot/prompts.md
```

## Scenario 2: Production Environment
```
Generate an AKS workload identity environment for production using these settings:

PROJECT: "prodapp"
ENVIRONMENT: "prod"
REGION: "East US 2"
NODE_COUNT: 5
VM_SIZE: "Standard_D4s_v3"
FEATURES: High availability, multiple node pools, enhanced monitoring, private cluster

Follow the architecture patterns in .copilot/prompts.md with production hardening
```

## Scenario 3: Multi-Region Setup
```
Generate AKS workload identity environments for multi-region deployment:

PRIMARY:
- PROJECT: "globalapp"
- ENVIRONMENT: "prod"
- REGION: "East US"

SECONDARY:
- PROJECT: "globalapp" 
- ENVIRONMENT: "prod"
- REGION: "West Europe"

Include cross-region networking and global load balancing considerations.
Follow the architecture patterns in .copilot/prompts.md
```

## Scenario 4: Government Cloud
```
Generate an AKS workload identity environment for Azure Government using these settings:

PROJECT: "govapp"
ENVIRONMENT: "prod"
REGION: "US Gov Virginia"
COMPLIANCE: FedRAMP, NIST controls
FEATURES: Enhanced security, audit logging, private endpoints

Follow the architecture patterns in .copilot/prompts.md with government compliance
```

## Scenario 5: Existing Resource Integration
```
Generate AKS workload identity configuration that integrates with existing Azure resources:

EXISTING_VNET: "existing-vnet-rg/prod-vnet"
EXISTING_SUBNET: "aks-subnet"
EXISTING_LOG_ANALYTICS: "existing-law-workspace"
PROJECT: "integrate"
ENVIRONMENT: "prod"

Follow the architecture patterns in .copilot/prompts.md but use existing network infrastructure
```

## Scenario 6: Cost-Optimized Environment
```
Generate a cost-optimized AKS workload identity environment for experimentation:

PROJECT: "experiment"
ENVIRONMENT: "dev"
REGION: "South Central US" (lower cost region)
NODE_COUNT: 1
VM_SIZE: "Standard_B1s"
FEATURES: Minimal viable configuration, spot instances, auto-shutdown

Follow the architecture patterns in .copilot/prompts.md with cost optimizations
```

## Scenario 7: Microservices Platform
```
Generate an AKS workload identity environment optimized for microservices:

PROJECT: "platform"
ENVIRONMENT: "prod"
REGION: "West US 2"
FEATURES: 
- Multiple workload identities for different service teams
- Service mesh integration (Istio)
- Advanced networking
- Multi-tenant namespace isolation

Follow the architecture patterns in .copilot/prompts.md with microservices enhancements
```

## Custom Scenario Template
```
Generate an AKS workload identity environment with these custom requirements:

PROJECT: "[your-project-name]"
ENVIRONMENT: "[dev/stg/prod]"
REGION: "[your-azure-region]"
NODE_COUNT: [number]
VM_SIZE: "[azure-vm-size]"

SPECIAL REQUIREMENTS:
- [List your specific requirements]
- [Any compliance needs]
- [Integration requirements]
- [Performance requirements]

Follow the architecture patterns in .copilot/prompts.md and adapt for these requirements
```

## How to Use These Templates

### Step 1: Choose Your Scenario
Pick the scenario that best matches your needs, or use the custom template.

### Step 2: Customize the Values
Replace the bracketed placeholders with your actual values:
- `[your-project-name]`: Max 10 characters, lowercase alphanumeric
- `[your-azure-region]`: Valid Azure region name
- `[your-requirements]`: Your specific needs

### Step 3: Run in GitHub Copilot
1. Copy the chosen template
2. Paste into GitHub Copilot Chat
3. Let Copilot generate all the code
4. Review and customize as needed

### Step 4: Deploy
```bash
cd infra/tf
chmod +x *.sh
./deploy.sh
```

## Regional Considerations

### Popular Azure Regions and Abbreviations
- **East US**: `eus` - Primary US region, most services
- **East US 2**: `eus2` - Paired with East US
- **West US 2**: `wus2` - West coast primary
- **Central US**: `cus` - Central location
- **West Europe**: `we` - Primary Europe region
- **North Europe**: `ne` - Secondary Europe region
- **Southeast Asia**: `sea` - Primary Asia Pacific
- **Australia East**: `aue` - Primary Australia

### Cost Optimization Regions
- **South Central US**: Lower cost option
- **West US**: Basic tier availability
- **North Central US**: Good for dev/test

### Compliance Regions
- **US Gov Virginia**: Government cloud
- **US Gov Texas**: Government cloud secondary
- **Germany West Central**: GDPR compliance
- **Switzerland North**: Data residency

## Resource Naming Examples by Scenario

### Development (`devapp-dev-cus`)
```
Resource Group:    devapp-dev-cus-rg
AKS Cluster:      devapp-dev-cus-aks
Storage Account:  devappdevcusst
Admin Group:      devapp-dev-cus-aks-admins
```

### Production (`prodapp-prod-eus2`)
```
Resource Group:    prodapp-prod-eus2-rg
AKS Cluster:      prodapp-prod-eus2-aks
Storage Account:  prodappprodeus2st
Admin Group:      prodapp-prod-eus2-aks-admins
```

### Global (`globalapp-prod-we`)
```
Resource Group:    globalapp-prod-we-rg
AKS Cluster:      globalapp-prod-we-aks
Storage Account:  globalappprodwest
Admin Group:      globalapp-prod-we-aks-admins
```

This template system allows you to quickly generate tailored AKS environments for any scenario while maintaining consistency and best practices!
