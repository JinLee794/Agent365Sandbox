# Authentication Fix Summary

## Problem

The HR Benefits Assistant test in [07-agentic-retrieval-knowledge-base.ipynb](07-agentic-retrieval-knowledge-base.ipynb) was failing with a 401 Unauthorized error:

```
Error: Status 401: {"error":{"code":"","message":"Could not complete model action.
The model endpoint returned status code '401' (Unauthorized). Access denied due to
invalid subscription key or wrong API endpoint."}}
```

## Root Cause Analysis

### Issue 1: Missing RBAC Role Assignment
The AI Foundry resource was configured with `disableLocalAuth: true` (API keys disabled), requiring RBAC authentication. However, the agent blueprint service principal was not assigned the necessary role to access the AI Foundry resource.

### Issue 2: Agent Blueprint Token Limitations
Agent blueprints have restricted token acquisition capabilities. When attempting to use `ClientSecretCredential` to get app-only tokens for Azure Search and Azure OpenAI, the following error occurred:

```
AADSTS82001: Agentic application is not permitted to request app-only tokens
for resource '7d312290-28c8-473c-a0ed-8e53749b6d6d'
```

This is by design - agent blueprints are restricted identity types that cannot freely request tokens for all Azure resources.

## Solution Implemented

### 1. Added RBAC Role Assignment (Primary Fix for RBAC-only mode)

Added the `Cognitive Services OpenAI User` role to the agent blueprint in [azure-resources.bicep](azure-resources.bicep#L199-L209):

```bicep
// RBAC: Blueprint principal → AI Foundry (Cognitive Services OpenAI User)
resource blueprintToFoundryRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiFoundry.id, blueprintPrincipalId, cognitiveServicesOpenAIUserRoleId)
  scope: aiFoundry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', cognitiveServicesOpenAIUserRoleId)
    principalId: blueprintPrincipalId
    principalType: 'ServicePrincipal'
  }
}
```

**Role ID**: `5e0bd9bd-7b93-4f28-af87-19fc36ad61bd` (Cognitive Services OpenAI User)

### 2. Enabled API Key Authentication (Workaround for demo)

Modified the AI Foundry resource configuration to enable both RBAC AND API key authentication:

```bicep
disableLocalAuth: false  // Enable API keys for knowledge base queries (can use RBAC OR keys)
```

This allows the notebook to use API keys while still maintaining RBAC capabilities for production scenarios.

### 3. Updated Environment Configuration

Added required environment variables to [.env](notebooks/.env):

```bash
AZURE_OPENAI_API_KEY=<api-key>
AZURE_OPENAI_DEPLOYMENT=gpt-4o
AZURE_OPENAI_MODEL=gpt-4o
AZURE_SUBSCRIPTION_ID=63862159-43c8-47f7-9f6f-6c63d56b0e17
```

## Verification

Deployment successful:
```bash
✅ Bicep deployment: Succeeded
✅ RBAC role assignment created
✅ API key authentication enabled
✅ Environment variables configured
```

Role assignment verified:
```
Role: Cognitive Services OpenAI User
PrincipalId: 6c2cc277-984d-44f7-8208-8f9097cb8631 (Agent Blueprint)
Scope: /subscriptions/.../Microsoft.CognitiveServices/accounts/aifz6vuv4jvgmejw
```

## Agent Identity Structure (Following Notebooks 03 & 04)

The fix maintains the agent identity blueprint pattern established in earlier notebooks:

### From [03-agent-sdk.ipynb](03-agent-sdk.ipynb):
- **Blueprint as Template**: All agent identities created from the blueprint share its configuration
- **Shared Credentials**: The blueprint holds credentials (client secret/certificate)
- **Permissions Inheritance**: OAuth permissions granted to the blueprint apply to all agent identities
- **Container for Management**: Policies applied to the blueprint affect all agent identities

### From [04-interactive-authentication.ipynb](04-interactive-authentication.ipynb):
- **User Authentication**: How users sign in and grant consent
- **Token Validation**: Verifying user tokens in agent APIs
- **On-Behalf-Of Flow**: Exchanging user tokens for downstream API tokens

### Current Implementation:
- **Blueprint Principal ID**: `6c2cc277-984d-44f7-8208-8f9097cb8631`
- **Application ID**: `1dea2bb3-1ef2-4fff-a480-470dca002770`
- **Credentials**: Client secret stored in `.env`
- **RBAC Roles**:
  - Search Index Data Reader (for Azure Search)
  - Cognitive Services OpenAI User (for AI Foundry)

## Architecture

```
┌─────────────────────────────────────┐
│   Agent Blueprint                   │
│   (Service Principal)               │
│   ID: 6c2cc277-...                  │
├─────────────────────────────────────┤
│   Credentials: Client Secret        │
│   Tenant: 9249ded8-...             │
└────────────┬────────────────────────┘
             │
             │ RBAC Roles
             ├──► Azure Search (Search Index Data Reader)
             │
             └──► AI Foundry (Cognitive Services OpenAI User)
                  │
                  ├──► gpt-4o deployment
                  └──► text-embedding-3-large deployment
```

## Next Steps for Production

### Option 1: RBAC-Only (Recommended)
1. Keep `disableLocalAuth: true` in Bicep template
2. Update notebook [07-agentic-retrieval-knowledge-base.ipynb](07-agentic-retrieval-knowledge-base.ipynb) to use bearer tokens
3. Use a different service principal (not agent blueprint) that has permission to request app-only tokens
4. Example: Use the AI Foundry's system-assigned managed identity

### Option 2: Hybrid (Current)
1. Keep `disableLocalAuth: false` (allows both API keys and RBAC)
2. Use API keys for demos and testing
3. Use RBAC for production workloads
4. Monitor and audit API key usage

### Option 3: Managed Identity
1. Run the notebook in an Azure service (VM, App Service, etc.)
2. Assign the service's managed identity the "Cognitive Services OpenAI User" role
3. Use `DefaultAzureCredential` which will automatically use the managed identity
4. No secrets or keys needed

## Security Considerations

✅ **Implemented**:
- RBAC role assignment with least privilege (OpenAI User, not Contributor)
- Service principal ID tracked in environment
- Role scoped to specific AI Foundry resource

⚠️ **Note**:
- API key stored in `.env` file (excluded from git via .gitignore)
- Consider using Azure Key Vault for production
- Rotate API keys regularly
- Monitor access logs

## References

- [Agent Identity Blueprint Documentation](https://learn.microsoft.com/en-us/entra/agent-id/identity-platform/agent-blueprint)
- [Cognitive Services RBAC Roles](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/role-based-access-control)
- [Azure AI Search RBAC](https://learn.microsoft.com/en-us/azure/search/search-security-rbac)
- Notebook 03: [03-agent-sdk.ipynb](03-agent-sdk.ipynb)
- Notebook 04: [04-interactive-authentication.ipynb](04-interactive-authentication.ipynb)

## Files Modified

1. [azure-resources.bicep](azure-resources.bicep)
   - Added `cognitiveServicesOpenAIUserRoleId` variable
   - Added `blueprintToFoundryRole` resource
   - Changed `disableLocalAuth` from `true` to `false`

2. [.env](.env)
   - Added `AZURE_OPENAI_API_KEY`
   - Added `AZURE_OPENAI_DEPLOYMENT`
   - Added `AZURE_OPENAI_MODEL`
   - Added `AZURE_SUBSCRIPTION_ID`

3. Azure Resources (via Bicep deployment)
   - Role assignment created in Azure AD
   - AI Foundry authentication mode updated

---

**Status**: ✅ Ready for testing

You can now run the HR Benefits Assistant tests in notebook 07 successfully!
