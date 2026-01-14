# Infrastructure Consolidation Guide

## Overview

The Azure infrastructure has been consolidated from two separate Bicep deployments into a single unified deployment that handles all resources with a shared storage account.

## What Changed

### Before
- **search-resources.bicep** - Deployed Azure AI Search and dedicated storage
- **foundry-resources.bicep** - Deployed Azure AI Foundry and separate storage
- Two separate storage accounts with different containers
- Two separate deployment workflows

### After
- **azure-resources.bicep** - Single consolidated template deploying:
  - Azure AI Search service
  - Azure AI Foundry (AI Services) with project
  - Model deployments (GPT-4o, text-embedding-3-large)
  - **One shared storage account** with separate containers:
    - `agents-us-data` - Search data for US region
    - `agents-apac-data` - Search data for APAC region
    - `foundry-data` - AI Foundry operations
  - All RBAC assignments for services and identities

## Benefits

✅ **Simplified Management** - One deployment, one set of parameters
✅ **Cost Optimization** - Single storage account instead of two
✅ **Consistent Configuration** - All resources deployed together
✅ **Easier Cleanup** - Delete one resource group to remove everything
✅ **Better Resource Organization** - Clear separation via containers, not accounts

## Updated Notebooks

### Notebook 05 (05-search-setup.ipynb)
- Now deploys **both** Search and Foundry infrastructure
- Uses `azure-resources.bicep` template
- Deployment name changed to: `agent365-resources`
- Creates all storage containers in one account

### Notebook 08 (08-foundry-iq-agent-framework.ipynb)
- Loads configuration from Notebook 05's consolidated deployment
- No longer performs separate Foundry deployment
- References the same `agent365-resources` deployment
- Uses shared storage account with `foundry-data` container

## File Changes

| File | Status | Notes |
|------|--------|-------|
| `notebooks/azure-resources.bicep` | ✨ NEW | Consolidated Bicep template |
| `notebooks/search-resources.bicep` | ⚠️ LEGACY | Can be removed (kept for reference) |
| `notebooks/foundry-resources.bicep` | ⚠️ LEGACY | Can be removed (kept for reference) |
| `notebooks/05-search-setup.ipynb` | ✏️ UPDATED | Uses new template |
| `notebooks/08-foundry-iq-agent-framework.ipynb` | ✏️ UPDATED | Loads from consolidated deployment |

## Migration Guide

### For New Users
1. Run `05-search-setup.ipynb` - deploys everything
2. Continue with notebooks 06, 07, 08 as normal

### For Existing Users
Two options:

#### Option A: Clean Slate (Recommended)
```bash
# Delete existing resource group
az group delete --name rg-agent-blueprint-demo -y

# Run notebook 05 to redeploy with consolidated template
# Run notebook 08 - will automatically use new deployment
```

#### Option B: Keep Existing Resources
Your existing deployments will continue to work. The notebooks now check for:
1. Environment variables (`.env` file) - if all Foundry settings exist, reuses them
2. Consolidated deployment (`agent365-resources`) - loads from it
3. Legacy deployment (`search-setup`, `foundry-setup`) - for backward compatibility

## Storage Account Structure

```
a365sa{uniqueString}  ← Single storage account
├── agents-us-data/      ← Search: US region documents
├── agents-apac-data/    ← Search: APAC region documents
└── foundry-data/        ← AI Foundry: project artifacts
```

## Deployment Outputs

The consolidated template provides all outputs needed by both notebooks:

### Search Outputs
- `searchServiceName`
- `searchEndpoint`
- `searchPrincipalId`

### Storage Outputs
- `storageAccountName`
- `storageEndpoint`
- `usContainerName`
- `apacContainerName`
- `foundryContainerName`

### Foundry Outputs
- `aiFoundryName`
- `aiFoundryId`
- `aiFoundryEndpoint`
- `aiProjectName`
- `aiProjectId`
- `aiProjectIdentityPrincipalId`
- `chatDeploymentName`
- `embeddingsDeploymentName`

## RBAC Configuration

All role assignments are created in one deployment:

1. **Search → Storage**: Storage Blob Data Contributor (for indexing)
2. **AI Project → Storage**: Storage Blob Data Contributor (for artifacts)
3. **Blueprint Principal → Storage**: Storage Blob Data Contributor (for data access)
4. **Blueprint Principal → Search**: Search Index Data Reader (for queries)

## Next Steps

- Remove legacy Bicep files after confirming everything works
- Update documentation to reference the consolidated approach
- Consider adding additional containers for future use cases (e.g., `kb-data`, `agent-logs`)
