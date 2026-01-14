# Notebook 07 Updates - Baked-In Fixes

## Summary

All fixes discovered during troubleshooting have been baked into [07-agentic-retrieval-knowledge-base.ipynb](07-agentic-retrieval-knowledge-base.ipynb). The notebook now follows the Microsoft LAB511 pattern for reliable knowledge base creation.

## Changes Made

### 1. **Added Troubleshooting Documentation** (New Cell 2)

Added a comprehensive troubleshooting section covering:
- Prerequisites (API keys, RBAC, vectorizer configuration)
- Common issues and their fixes:
  - 401 Unauthorized (Vectorization)
  - 400 Bad Request (Invalid kind)
  - No Results (Missing alwaysQuerySource)
- Key differences from Python SDK pattern
- References to solution documentation

### 2. **Configuration Cell** (Cell 3) - No Changes

The configuration cell properly loads:
- `AZURE_OPENAI_API_KEY` (required for both knowledge base and vectorizers)
- `AZURE_OPENAI_DEPLOYMENT`
- `AZURE_OPENAI_MODEL`
- Search service credentials

**Important**: The vectorizer in Cell 4 uses `azure_openai_api_key` - this is correct!

### 3. **Index Creation Cell** (Cell 4) - Working Correctly

The index vectorizer properly references:
```python
AzureOpenAIVectorizer(
    vectorizer_name="openai-vectorizer",
    parameters=AzureOpenAIVectorizerParameters(
        resource_url=azure_openai_endpoint,
        deployment_name="text-embedding-3-large",
        model_name="text-embedding-3-large",
        api_key=azure_openai_api_key  # ✅ Uses current API key
    )
)
```

**Note**: If indices already exist with old API keys, run `update-index-vectorizers.py` to update them.

### 4. **Knowledge Source Cell** (Cell 6) - FIXED

**Before**:
```python
"searchIndexParameters": {
    "searchIndexName": ks["index_name"],
    "searchFields": [
        {"name": "*"}  # ❌ Problematic
    ],
    "sourceDataFields": [...]
}
```

**After**:
```python
"searchIndexParameters": {  # No searchFields - searches all searchable fields by default
    "searchIndexName": ks["index_name"],
    "sourceDataFields": [
        {"name": "snippet"},
        {"name": "uid"},
        {"name": "blob_path"}
    ],
    "semanticConfigurationName": "semantic-config"
}
```

**Why**: `searchFields` was causing issues with query generation. Omitting it lets Azure AI Search search all searchable fields by default, which is the Microsoft LAB511 pattern.

### 5. **Knowledge Base Cell** (Cell 8) - Added Documentation

Added comments explaining the simplified pattern:
```python
# Note: Following Microsoft LAB511 pattern - start simple, add complexity later
# For production, you may want to add retrievalInstructions and answerInstructions
knowledge_base_definition = {
    "name": "hr-benefits-assistant",
    "retrievalInstructions": """...""",  # Included but noted as optional
    "answerInstructions": """...""",      # Included but noted as optional
    ...
}
```

**Note**: The instructions are kept in the notebook for demonstration, but beginners can comment them out to start with a minimal configuration.

### 6. **Query Function** (Cell 11) - FIXED

**Before**:
```python
"knowledgeSourceParams": [
    {
        "knowledgeSourceName": "health-benefits-ks",  # ❌ Missing kind
        "includeReferences": True,
        "includeReferenceSourceData": True
    }
]
```

**After**:
```python
"knowledgeSourceParams": [
    {
        "kind": "searchIndex",              # ✅ Added
        "knowledgeSourceName": "health-benefits-ks",
        "includeReferences": True,
        "includeReferenceSourceData": True,
        "alwaysQuerySource": True            # ✅ Added
    },
    {
        "kind": "searchIndex",              # ✅ Added
        "knowledgeSourceName": "hr-policies-ks",
        "includeReferences": True,
        "includeReferenceSourceData": True,
        "alwaysQuerySource": True            # ✅ Added
    }
]
```

**Why**:
- `kind` is required by the REST API
- `alwaysQuerySource` ensures all knowledge sources are queried even when the LLM thinks only one is needed

### 7. **Test Cells** (Cells 13-15) - Updated

All three test queries now use the fixed query function with `kind` and `alwaysQuerySource` parameters.

## Files Supporting the Notebook

### Helper Scripts

1. **[update-index-vectorizers.py](update-index-vectorizers.py)**
   - Updates existing indices with current Azure OpenAI API key
   - Run this if you get 401 vectorization errors
   - Safe to run multiple times

2. **[fix-knowledge-base.py](fix-knowledge-base.py)**
   - Recreates knowledge sources and knowledge base with correct configuration
   - Includes a test query to verify everything works
   - Useful for resetting to known-good state

### Documentation

1. **[FINAL-SOLUTION-SUMMARY.md](FINAL-SOLUTION-SUMMARY.md)**
   - Complete technical breakdown of all issues and fixes
   - Architecture diagrams
   - Test results
   - Production recommendations

2. **[COMPARISON-MSFT-LAB511.md](COMPARISON-MSFT-LAB511.md)**
   - Side-by-side comparison with Microsoft's official lab
   - Explains why certain patterns are used
   - Helps understand REST API vs SDK differences

3. **[AUTHENTICATION-FIX-SUMMARY.md](AUTHENTICATION-FIX-SUMMARY.md)**
   - Initial RBAC authentication fixes
   - Agent blueprint permission configuration
   - Infrastructure changes made

## How to Use the Updated Notebook

### First Time Setup

1. **Ensure `.env` is configured**:
   ```bash
   AZURE_OPENAI_API_KEY=<your-key>
   AZURE_OPENAI_DEPLOYMENT=gpt-4o
   AZURE_OPENAI_MODEL=gpt-4o
   AZURE_SUBSCRIPTION_ID=<your-sub-id>
   AZURE_SEARCH_SERVICE_NAME=<your-search-service>
   AZURE_RESOURCE_GROUP=<your-rg>
   ```

2. **Deploy infrastructure** (if not already done):
   ```bash
   az deployment group create \
     --resource-group <your-rg> \
     --template-file azure-resources.bicep \
     --parameters blueprintPrincipalId=<your-blueprint-principal-id>
   ```

3. **Run the notebook cells in order**:
   - Cell 1-2: Documentation
   - Cell 3: Load configuration
   - Cell 4: Create indices (creates with current API key)
   - Cell 5-6: Create knowledge sources
   - Cell 7-8: Create knowledge base
   - Cell 9-11: Define query functions
   - Cell 12-15: Run test queries

### If Indices Already Exist

If you previously created indices with old API keys:

1. **Update vectorizers**:
   ```bash
   python update-index-vectorizers.py
   ```

2. **Recreate knowledge sources/base** (optional):
   ```bash
   python fix-knowledge-base.py
   ```

3. **Continue with notebook** from Cell 12 (test queries)

### Troubleshooting

**401 Vectorization Error**:
```bash
python update-index-vectorizers.py
```

**400 Invalid Kind Error**:
- Check that notebook Cell 11 has been updated with latest changes
- Ensure `"kind": "searchIndex"` is present in all `knowledgeSourceParams`

**No Results / "Sorry, I could not find an answer"**:
- Ensure `"alwaysQuerySource": True` is set
- Check that indices have data (Cell 4 should show upload statistics)
- Verify Azure OpenAI API key is valid

## Testing the Updated Notebook

### Quick Test

Run this from the notebooks directory:
```bash
python fix-knowledge-base.py
```

Expected output:
```
✅ Knowledge sources updated
✅ Knowledge base updated
✅ Test query successful
Answer: [Detailed answer about copayments with citations]
```

### Full Test

Run the entire notebook 07 from top to bottom. All three test queries should succeed:

1. **Test 1**: "What are the copayment amounts for office visits with Northwind Health Plus?"
   - Expected: Specific dollar amounts with citations

2. **Test 2**: "How many weeks of vacation do employees get at Zava?"
   - Expected: Tiered vacation benefits (2/4/6 weeks)

3. **Test 3**: "Tell me about Zava's health benefits and employee perks"
   - Expected: Comprehensive answer covering both knowledge sources

## Next Steps

### For Learning

1. **Simplify the knowledge base** - Try removing `retrievalInstructions` and `answerInstructions` to see minimal config
2. **Experiment with `alwaysQuerySource`** - Set to `false` and see how LLM decides which sources to query
3. **Try different queries** - Test edge cases and see how the agentic retrieval handles them

### For Production

1. **Review FINAL-SOLUTION-SUMMARY.md** for production recommendations
2. **Consider RBAC-only mode** - See section on migrating away from API keys
3. **Add document-level security** - Integrate permission filters from notebook 06
4. **Implement user authentication** - Use patterns from notebook 04

## Summary

The notebook now:
- ✅ Follows Microsoft LAB511 best practices
- ✅ Includes comprehensive troubleshooting documentation
- ✅ Uses correct REST API parameters (`kind`, `alwaysQuerySource`)
- ✅ Avoids problematic `searchFields` configuration
- ✅ Properly configures vectorizers with current API keys
- ✅ Works reliably for all test queries

All discovered issues have been fixed and patterns documented for future reference.
