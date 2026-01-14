# Final Solution Summary: HR Benefits Assistant

## Problem Evolution

### Initial Error: 401 Unauthorized
```
Status 401: Access denied due to invalid subscription key or wrong API endpoint
```

**Root Cause**: Missing RBAC role assignment for agent blueprint to access AI Foundry

**Solution Applied**: Added `Cognitive Services OpenAI User` role in [azure-resources.bicep](azure-resources.bicep#L222-L231)

---

### Second Error: 400 Bad Request (Content Filter)
```
Status 400: The response was filtered due to the prompt triggering Azure OpenAI's content management policy
```

**Root Cause**: Initially thought to be content filter issue, but was actually masking a deeper problem

---

### True Root Cause: 401 Unauthorized (Vectorization)
```
Error: "Could not complete vectorization action. The vectorization endpoint returned status code '401' (Unauthorized)"
```

**Root Cause**: Search index vectorizers were configured with old/invalid Azure OpenAI API keys

**Solution Applied**: Updated vectorizer API keys in both indices using [update-index-vectorizers.py](update-index-vectorizers.py)

---

## Complete Solution

### 1. Infrastructure Changes ([azure-resources.bicep](azure-resources.bicep))

```bicep
// Enable API key authentication (hybrid mode)
disableLocalAuth: false

// Add RBAC role for agent blueprint
resource blueprintToFoundryRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiFoundry.id, blueprintPrincipalId, cognitiveServicesOpenAIUserRoleId)
  scope: aiFoundry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd')
    principalId: blueprintPrincipalId
    principalType: 'ServicePrincipal'
  }
}
```

### 2. Environment Configuration ([.env](notebooks/.env))

```bash
AZURE_OPENAI_API_KEY=<your-api-key>
AZURE_OPENAI_DEPLOYMENT=gpt-4o
AZURE_OPENAI_MODEL=gpt-4o
AZURE_SUBSCRIPTION_ID=<your-subscription-id>
```

### 3. Knowledge Source Simplification

**Before** (causing issues):
```python
"searchIndexParameters": {
    "searchIndexName": "healthdocs-index",
    "searchFields": [{"name": "*"}],  # ❌ Problematic
    "sourceDataFields": [...],
    "semanticConfigurationName": "semantic-config"
}
```

**After** (following Microsoft LAB511 pattern):
```python
"searchIndexParameters": {
    "searchIndexName": "healthdocs-index",
    # searchFields removed - searches all searchable fields by default
    "sourceDataFields": [
        {"name": "blob_path"},
        {"name": "snippet"}
    ],
    "semanticConfigurationName": "semantic-config"
}
```

### 4. Knowledge Base Simplification

**Before**:
```python
knowledge_base_definition = {
    "name": "hr-benefits-assistant",
    "retrievalInstructions": "...",  # ❌ Too complex initially
    "answerInstructions": "...",      # ❌ Too complex initially
    "retrievalReasoningEffort": {"kind": "low"},  # ❌ Unnecessary
    ...
}
```

**After** (minimal configuration):
```python
knowledge_base_definition = {
    "name": "hr-benefits-assistant",
    "description": "HR Benefits Assistant for employee questions",
    "outputMode": "answerSynthesis",
    "knowledgeSources": [...],
    "models": [...]
    # No retrieval/answer instructions initially
}
```

### 5. Query Parameters Enhancement

```python
"knowledgeSourceParams": [
    {
        "kind": "searchIndex",
        "knowledgeSourceName": "health-benefits-ks",
        "includeReferences": True,
        "includeReferenceSourceData": True,
        "alwaysQuerySource": True  # ✅ Added (from Microsoft LAB511)
    }
]
```

### 6. Index Vectorizer Update

Updated both `healthdocs-index` and `hrdocs-index` vectorizers with current Azure OpenAI API key:

```python
vectorizer["azureOpenAIParameters"]["apiKey"] = azure_openai_api_key
```

---

## Test Results

### Query 1: Company Perks
**Query**: "What company perks does Zava offer?"

**Result**: ✅ SUCCESS
- Retrieved information from both HR policies and health benefits sources
- Properly cited sources with `[ref_id:N]` references
- Synthesized comprehensive answer covering vacation, recognition, health, and PerksPlus program

### Query 2: Health Benefits (Original Failing Query)
**Query**: "What are the copayment amounts for office visits with Northwind Health Plus?"

**Result**: ✅ SUCCESS
- In-network: $35 (primary), $60 (specialist), $45 (mental health)
- Out-of-network: $50 (primary), $75 (specialist), $60 (mental health)
- Properly cited with references to source documents

---

## Key Learnings

### 1. **Authentication Hierarchy**
```
User/Agent Identity → RBAC Roles → Azure Resources
              ↓
     Search Index Vectorizers → Azure OpenAI (with API key)
              ↓
     Knowledge Base Query → Azure OpenAI (with API key)
```

Both the **agent identity** AND the **index vectorizers** need proper authentication.

### 2. **Error Message Misleading**
The 400 "content filter" error was misleading - it occurred because the vectorization failed (401), which caused the query to fail, which triggered a generic 400 response. The actual issue was authentication, not content.

### 3. **Microsoft LAB511 Pattern**
Following Microsoft's official lab pattern was crucial:
- Remove `searchFields` configuration
- Start with minimal knowledge base (no complex instructions)
- Use `alwaysQuerySource=True` in queries
- Keep it simple initially, add complexity incrementally

### 4. **Hybrid Authentication**
Using `disableLocalAuth: false` allows BOTH:
- API keys (for demos and development)
- RBAC (for production security)

This flexibility is valuable during development.

---

## Files Modified

1. **[azure-resources.bicep](azure-resources.bicep)**
   - Added `cognitiveServicesOpenAIUserRoleId` variable
   - Added `blueprintToFoundryRole` RBAC assignment
   - Changed `disableLocalAuth` to `false`

2. **[.env](.env)**
   - Added `AZURE_OPENAI_API_KEY`
   - Added `AZURE_OPENAI_DEPLOYMENT`
   - Added `AZURE_OPENAI_MODEL`
   - Added `AZURE_SUBSCRIPTION_ID`

3. **Search Indices** (via `update-index-vectorizers.py`)
   - Updated `healthdocs-index` vectorizer API key
   - Updated `hrdocs-index` vectorizer API key

4. **Knowledge Sources** (via `fix-knowledge-base.py`)
   - Removed `searchFields` parameter
   - Simplified configuration

5. **Knowledge Base** (via `fix-knowledge-base.py`)
   - Removed complex instructions
   - Simplified to minimal configuration

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│  Agent Blueprint                                             │
│  Principal ID: 6c2cc277-984d-44f7-8208-8f9097cb8631        │
│  App ID: 1dea2bb3-1ef2-4fff-a480-470dca002770              │
├─────────────────────────────────────────────────────────────┤
│  Credentials: Client Secret (from .env)                     │
│  RBAC Roles:                                                │
│    • Search Index Data Reader (Azure Search)                │
│    • Cognitive Services OpenAI User (AI Foundry)            │
└────────────┬────────────────────────────────────────────────┘
             │
             │ Authenticates to
             ▼
┌─────────────────────────────────────────────────────────────┐
│  Azure AI Foundry (aifz6vuv4jvgmejw)                        │
│  Authentication: API Keys + RBAC (hybrid)                   │
├─────────────────────────────────────────────────────────────┤
│  Deployments:                                               │
│    • gpt-4o (chat completion)                               │
│    • text-embedding-3-large (embeddings)                    │
└─────────────────────────────────────────────────────────────┘
             ▲
             │ Calls for embeddings
             │
┌────────────┴────────────────────────────────────────────────┐
│  Azure AI Search (a365-search-6uuruydd4tej6)                │
├─────────────────────────────────────────────────────────────┤
│  Indices:                                                   │
│    • healthdocs-index (334 documents)                       │
│    • hrdocs-index (50 documents)                            │
│                                                             │
│  Each index has vectorizer with API key to AI Foundry      │
└─────────────────────────────────────────────────────────────┘
             ▲
             │ Queries via
             │
┌────────────┴────────────────────────────────────────────────┐
│  Knowledge Base: hr-benefits-assistant                      │
├─────────────────────────────────────────────────────────────┤
│  Knowledge Sources:                                         │
│    • health-benefits-ks → healthdocs-index                  │
│    • hr-policies-ks → hrdocs-index                          │
│                                                             │
│  Models: gpt-4o (via API key)                               │
│  Output: answerSynthesis                                    │
└─────────────────────────────────────────────────────────────┘
```

---

## Next Steps

### For Production

1. **Migrate to RBAC-only authentication**
   - Set `disableLocalAuth: true`
   - Configure index vectorizers to use managed identity or RBAC
   - Remove API keys from environment

2. **Add retrieval/answer instructions incrementally**
   - Test each addition to ensure no content filter issues
   - Use Microsoft LAB511 Part 2 as reference

3. **Configure custom RAI policy** (if needed)
   - Only if encountering actual content filter issues
   - Set thresholds appropriate for HR/benefits domain

4. **Monitor and optimize**
   - Track query patterns via activity logs
   - Adjust semantic configurations
   - Fine-tune retrieval reasoning effort (low/medium/high)

### For Development

1. **Add more test queries** to validate coverage
2. **Implement conversation history** for multi-turn dialogs
3. **Add permission filters** for document-level security (from Notebook 06)
4. **Integrate with employee authentication** (from Notebook 04)

---

## Status: ✅ RESOLVED

The HR Benefits Assistant is now fully functional and ready for use!

**Test Command**:
```bash
python fix-knowledge-base.py
```

**Expected Result**: Successful query with cited answers from both knowledge sources.
