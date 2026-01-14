# Comparison: Your Notebook vs Microsoft LAB511

## Key Differences

### 1. **Authentication Method**

**Microsoft LAB511:**
```python
from azure.core.credentials import AzureKeyCredential

credential = AzureKeyCredential(os.environ["AZURE_SEARCH_ADMIN_KEY"])
azure_openai_key = os.environ["AZURE_OPENAI_KEY"]
```

**Your Current Approach:**
```python
# Using REST API with api-key header
headers = {
    "Content-Type": "application/json",
    "api-key": search_api_key
}
```

**✅ Both use API keys** - This is correct! The issue isn't authentication method.

---

### 2. **SDK vs REST API**

**Microsoft LAB511:**
Uses the **Azure Search Python SDK**:
```python
from azure.search.documents.indexes import SearchIndexClient
from azure.search.documents.indexes.models import (
    SearchIndexKnowledgeSource,
    KnowledgeBase,
    KnowledgeBaseAzureOpenAIModel
)

index_client = SearchIndexClient(endpoint=endpoint, credential=credential)
index_client.create_or_update_knowledge_source(knowledge_source=ks)
index_client.create_or_update_knowledge_base(knowledge_base)
```

**Your Current Approach:**
Uses **REST API directly**:
```python
url = f"{search_endpoint}/knowledgesources/{ks['name']}?api-version={api_version}"
headers = {"Content-Type": "application/json", "api-key": search_api_key}
response = requests.put(url, json=knowledge_source_definition, headers=headers)
```

**✅ Both approaches are valid**, but the SDK provides better error messages and validation.

---

### 3. **Knowledge Source Creation**

**Microsoft LAB511:**
```python
from azure.search.documents.indexes.models import (
    SearchIndexFieldReference,
    SearchIndexKnowledgeSource,
    SearchIndexKnowledgeSourceParameters
)

ks = SearchIndexKnowledgeSource(
    name="hrdocs-knowledge-source",
    description="Knowledge source for HR Docs",
    search_index_parameters=SearchIndexKnowledgeSourceParameters(
        search_index_name="hrdocs",
        source_data_fields=[
            SearchIndexFieldReference(name="blob_path"),
            SearchIndexFieldReference(name="snippet")
        ]
    )
)
```

**Your Current Approach:**
```python
knowledge_source_definition = {
    "kind": "searchIndex",
    "name": "health-benefits-ks",
    "description": "Health insurance benefits documentation...",
    "searchIndexParameters": {
        "searchIndexName": "healthdocs-index",
        "searchFields": [{"name": "*"}],  # ⚠️ Different!
        "sourceDataFields": [
            {"name": "snippet"},
            {"name": "uid"},
            {"name": "blob_path"}
        ],
        "semanticConfigurationName": "semantic-config"
    }
}
```

**❌ Key Difference:** You have `"searchFields": [{"name": "*"}]` which Microsoft doesn't use!

---

### 4. **Knowledge Base Configuration**

**Microsoft LAB511:**
```python
from azure.search.documents.indexes.models import (
    AzureOpenAIVectorizerParameters,
    KnowledgeBase,
    KnowledgeBaseAzureOpenAIModel,
    KnowledgeRetrievalOutputMode,
    KnowledgeSourceReference
)

aoai_params = AzureOpenAIVectorizerParameters(
    resource_url=azure_openai_endpoint,
    deployment_name=azure_openai_chatgpt_deployment,
    model_name=azure_openai_chatgpt_model_name,
    api_key=azure_openai_key
)

knowledge_base = KnowledgeBase(
    name="hrdocs-knowledge-base",
    models=[KnowledgeBaseAzureOpenAIModel(azure_open_ai_parameters=aoai_params)],
    knowledge_sources=[KnowledgeSourceReference(name="hrdocs-knowledge-source")],
    output_mode=KnowledgeRetrievalOutputMode.ANSWER_SYNTHESIS
)
```

**Your Current Approach:**
```python
knowledge_base_definition = {
    "name": "hr-benefits-assistant",
    "description": "HR Benefits Assistant knowledge base...",
    "retrievalInstructions": """...""",  # ⚠️ You have this, they don't (initially)
    "answerInstructions": """...""",      # ⚠️ You have this, they don't (initially)
    "outputMode": "answerSynthesis",
    "knowledgeSources": [
        {"name": "health-benefits-ks"},
        {"name": "hr-policies-ks"}
    ],
    "models": [{
        "kind": "azureOpenAI",
        "azureOpenAIParameters": {
            "resourceUri": azure_openai_endpoint,
            "apiKey": azure_openai_api_key,
            "deploymentId": azure_openai_deployment,
            "modelName": azure_openai_model
        }
    }],
    "retrievalReasoningEffort": {"kind": "low"}  # ⚠️ You have this, they don't (initially)
}
```

**❌ Key Differences:**
1. They don't include `retrievalInstructions` and `answerInstructions` in the basic example
2. They don't include `retrievalReasoningEffort` until part 7/8

---

### 5. **Query Execution**

**Microsoft LAB511:**
```python
from azure.search.documents.knowledgebases import KnowledgeBaseRetrievalClient
from azure.search.documents.knowledgebases.models import (
    KnowledgeBaseMessage,
    KnowledgeBaseMessageTextContent,
    KnowledgeBaseRetrievalRequest,
    SearchIndexKnowledgeSourceParams
)

knowledge_base_client = KnowledgeBaseRetrievalClient(
    endpoint=endpoint,
    knowledge_base_name=knowledge_base_name,
    credential=credential
)

req = KnowledgeBaseRetrievalRequest(
    messages=[
        KnowledgeBaseMessage(
            role="user",
            content=[KnowledgeBaseMessageTextContent(text="What is the responsibility of the Zava CEO?")]
        )
    ],
    knowledge_source_params=[
        SearchIndexKnowledgeSourceParams(
            knowledge_source_name=knowledge_source_name,
            include_references=True,
            include_reference_source_data=True,
            always_query_source=True
        )
    ],
    include_activity=True
)

result = knowledge_base_client.retrieve(retrieval_request=req)
```

**Your Current Approach:**
```python
def query_knowledge_base(query: str, kb_name: str = "hr-benefits-assistant"):
    retrieval_request = {
        "messages": [{
            "role": "user",
            "content": [{"type": "text", "text": query}]
        }],
        "knowledgeSourceParams": [
            {
                "knowledgeSourceName": "health-benefits-ks",
                "kind": "searchIndex",  # ⚠️ Extra field
                "includeReferences": True,
                "includeReferenceSourceData": True
            },
            {
                "knowledgeSourceName": "hr-policies-ks",
                "kind": "searchIndex",  # ⚠️ Extra field
                "includeReferences": True,
                "includeReferenceSourceData": True
            }
        ],
        "includeActivity": True
    }

    url = f"{search_endpoint}/knowledgebases/{kb_name}/retrieve?api-version={api_version}"
    headers = {"Content-Type": "application/json", "api-key": search_api_key}
    response = requests.post(url, json=retrieval_request, headers=headers)
```

**✅ Similar structure**, but you're missing `always_query_source` parameter.

---

## Likely Root Cause of Your 400 Error

Based on the comparison, the **400 Bad Request (content filter)** error is likely caused by:

### 1. **Extra Fields in Knowledge Source**
You have `"searchFields": [{"name": "*"}]` which Microsoft LAB511 doesn't use. This might be causing the knowledge base to send unexpected content to the LLM.

### 2. **Complex Instructions**
Your `retrievalInstructions` and `answerInstructions` are very detailed and might contain phrases that trigger content filtering.

### 3. **Missing `always_query_source`**
Without this parameter, the agentic retrieval might be generating unexpected queries that trigger content filters.

---

## Recommended Fixes

### Option 1: Simplify to Match Microsoft LAB511 (Recommended)

1. **Remove `searchFields` from knowledge source:**
   ```python
   # Don't specify searchFields - let it search all searchable fields by default
   ```

2. **Start with minimal knowledge base (no instructions):**
   ```python
   knowledge_base_definition = {
       "name": "hr-benefits-assistant",
       "outputMode": "answerSynthesis",
       "knowledgeSources": [
           {"name": "health-benefits-ks"},
           {"name": "hr-policies-ks"}
       ],
       "models": [{
           "kind": "azureOpenAI",
           "azureOpenAIParameters": {
               "resourceUri": azure_openai_endpoint,
               "apiKey": azure_openai_api_key,
               "deploymentId": azure_openai_deployment,
               "modelName": azure_openai_model
           }
       }]
       # No retrievalInstructions or answerInstructions initially
   }
   ```

3. **Add `always_query_source=True` to queries:**
   ```python
   "knowledgeSourceParams": [
       {
           "knowledgeSourceName": "health-benefits-ks",
           "includeReferences": True,
           "includeReferenceSourceData": True,
           "alwaysQuerySource": True  # Add this!
       }
   ]
   ```

### Option 2: Use Python SDK Instead of REST API

Install the SDK:
```bash
pip install azure-search-documents --pre
```

Then use the same code structure as Microsoft LAB511 (shown above).

---

## Summary

| Feature | Microsoft LAB511 | Your Approach | Issue? |
|---------|------------------|---------------|--------|
| Authentication | API Keys (AzureKeyCredential) | API Keys (REST) | ✅ Same |
| API Method | Python SDK | REST API | ⚠️ Different but both valid |
| searchFields | Not specified | `[{"name": "*"}]` | ❌ Remove this |
| retrievalInstructions | Added in Part 2 | In initial setup | ⚠️ Simplify |
| answerInstructions | Added in Part 2 | In initial setup | ⚠️ Simplify |
| retrievalReasoningEffort | Added in Part 7/8 | In initial setup | ⚠️ Remove initially |
| always_query_source | Used in queries | Missing | ❌ Add this |

The content filter error is most likely caused by the **combination of complex instructions + searchFields configuration** creating unexpected query patterns that trigger Azure OpenAI's content management policy.

**Next Steps:** Simplify your knowledge base to match Microsoft's minimal approach, then add instructions incrementally to see what triggers the filter.
