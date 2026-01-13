# Architecture Guide

Comprehensive overview of the Agent365 Sandbox architecture, Azure AI Foundry integration, and RBAC patterns.

## Table of Contents

1. [Azure AI Foundry Architecture](#azure-ai-foundry-architecture)
2. [RBAC & Security Design](#rbac--security-design)
3. [Agent Framework Integration](#agent-framework-integration)
4. [Data Flow & Components](#data-flow--components)

---

## Azure AI Foundry Architecture

### Resource Structure

Following Microsoft's recommended pattern from the [Foundry quickstart](https://learn.microsoft.com/en-us/azure/ai-foundry/how-to/create-resource-template?view=foundry-classic&tabs=cli):

```
┌─────────────────────────────────────────────────────────────┐
│                   Azure AI Foundry                           │
│                (CognitiveServices/accounts)                  │
│                    kind: AIServices                          │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │          AI Foundry Resource                         │  │
│  │  • SystemAssigned Identity                           │  │
│  │  • Custom Subdomain                                  │  │
│  │  • Endpoint: https://<name>.openai.azure.com/        │  │
│  └──────────────────┬───────────────────────────────────┘  │
│                     │                                        │
│  ┌──────────────────▼───────────────────────────────────┐  │
│  │          AI Project (Sub-resource)                   │  │
│  │  • SystemAssigned Identity (separate)                │  │
│  │  • Manages project-scoped resources                  │  │
│  │  • RBAC: Storage Blob Data Contributor → Storage    │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │          Model Deployments                           │  │
│  │  • gpt-4o (chat)                                     │  │
│  │  • text-embedding-3-large (embeddings)               │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                  Foundry Storage                             │
│               (Storage Account)                              │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │          foundry-data Container                      │  │
│  │  • RBAC: AI Project Identity → Contributor          │  │
│  │  • RBAC: Blueprint Principal → Contributor          │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              Azure AI Search (from Notebook 05)              │
│                                                              │
│  • agents-us (RBAC: index-level)                            │
│  • agents-apac (RBAC: index-level)                          │
│  • agents-us-secure (RBAC + document-level security)        │
└─────────────────────────────────────────────────────────────┘
```

### Key Design Principles

#### 1. AI Foundry Resource (Parent)

- **Type:** `Microsoft.CognitiveServices/accounts@2025-04-01-preview`
- **Kind:** `AIServices`
- **Identity:** SystemAssigned managed identity
- **Purpose:** Hosts model deployments and manages project hierarchy
- **API Endpoint:** Accessible via custom subdomain (https://aif-xxx.openai.azure.com)

#### 2. AI Project (Child)

- **Type:** `Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview`
- **Parent:** AI Foundry resource
- **Identity:** Separate SystemAssigned managed identity
- **Purpose:** Project-scoped configuration, RBAC boundary, resource grouping
- **RBAC:** Has own role assignments (Storage Blob Data Contributor)

#### 3. Model Deployments

Deployed as children of AI Foundry:
- **Chat:** `gpt-4o` with `GlobalStandard` SKU
- **Embeddings:** `text-embedding-3-large` with `Standard` SKU

#### 4. Storage with RBAC

- **Account:** StorageV2, Hot tier, TLS 1.2+ required
- **Container:** `foundry-data`
- **RBAC Assignments:**
  - AI Project identity → Storage Blob Data Contributor
  - Blueprint principal → Storage Blob Data Contributor

---

## RBAC & Security Design

### Multi-Layer RBAC Approach

```
┌─────────────────────────────────────┐
│        Service Principal             │
│    (Agent Identity Blueprint)        │
└──────────────┬──────────────────────┘
               │
     ┌─────────▼──────────┐
     │                    │
┌────▼──────┐      ┌──────▼────┐
│ RBAC Layer│      │ App Layer  │
│           │      │            │
│ Azure Role│      │ Agent RBAC │
│ Assignment│      │ Policies   │
│           │      │            │
│ Search    │      │ Authorized │
│ Index     │      │ Indices    │
│ Reader    │      │ Denied     │
└─────┬──────┘      └─────┬─────┘
      │                   │
      └──────────┬────────┘
                 │
        ┌────────▼────────┐
        │ Query Execution  │
        │                  │
        │ 1. Authenticate  │
        │ 2. Authorize     │
        │ 3. Query         │
        │ 4. Filter        │
        └──────────────────┘
```

### Layer 1: Azure RBAC (Infrastructure)

**Purpose:** Control who can access Azure Search

**Mechanism:**
```bash
# Grant Search Index Data Reader role
az role assignment create \
  --assignee <PRINCIPAL_ID> \
  --role "Search Index Data Reader" \
  --scope /subscriptions/<SUB>/resourceGroups/<RG>/providers/Microsoft.Search/searchServices/<NAME>
```

**Scope:** Entire search service or specific indices

**Authentication:** DefaultAzureCredential (AAD token)

### Layer 2: Agent RBAC Policies (Application)

**Purpose:** Control which indices each agent can access

**Policy Example:**
```python
agent_rbac_policies = {
    'customer-service-agent': {
        'principal_id': 'agent-customer-service',
        'authorized_indices': ['agents-us', 'agents-apac'],
        'denied_indices': ['agents-us-secure'],
        'permissions': ['search', 'read']
    }
}
```

**Enforcement:** Checked at query time in `RBACEnforcingSearchClient`

**Benefits:**
- Fine-grained agent-level control
- No Azure RBAC changes needed per agent
- Easy testing and audit logging

### Layer 3: Document-Level Security

**Purpose:** Filter which documents a principal sees

**Mechanism:** OData filter on `security` collection field

```python
# agents-us-secure index schema
{
    "id": "doc1",
    "title": "Confidential Procedure",
    "security": ["principal-a", "principal-b"]  # Who can see this doc
}

# Query filter
security/any(s: s eq 'principal-a')  # Only docs where principal is in security list
```

**Combined with RBAC:**
```
Azure RBAC: principal-a can query agents-us-secure ✅
Document Filter: Only sees docs where security contains principal-a ✅
Result: Least-privilege access
```

---

## Agent Framework Integration

### Architecture Stack

```
┌─────────────────────────────────────────────────┐
│         User Input / Chat Interface              │
└────────────────────┬────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────┐
│     Agent Framework Runtime                      │
│  • Chat Client (Azure OpenAI / OpenAI)          │
│  • Tool Registry & Execution                    │
│  • State Management & Memory                    │
│  • Conversation Loop                            │
└────────────────────┬────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────┐
│    Foundry Agent Layer (Notebook 08)             │
│  • RBAC Enforcement                             │
│  • Blueprint Integration                        │
│  • Tool Definitions (search, KB info, history)  │
│  • Query Logging & Audit                        │
└────────────────────┬────────────────────────────┘
                     │
         ┌───────────┼───────────┐
         │           │           │
┌────────▼──┐ ┌──────▼─────┐ ┌──▼──────────┐
│ Azure AI  │ │ Azure Key  │ │ Blueprint   │
│ Search    │ │ Vault      │ │ Principal   │
│ (Indices) │ │ (Secrets)  │ │ (Identity)  │
└───────────┘ └────────────┘ └─────────────┘
```

### Tool Pattern

```python
# Tool definition
def search_knowledge_base(
    agent_name: str,           # Which agent
    query: str,                # Search query
    index: str = None          # Specific index (optional)
) -> str:
    """Search KB with RBAC enforcement."""
    agent = foundry_agents[agent_name]
    result = agent.query_knowledge_base(query, index)
    return format_results(result)

# Agent Framework:
# 1. Detects function via Pydantic annotations
# 2. Creates function calling schema
# 3. LLM decides to call tool
# 4. Parses LLM output and calls function
# 5. Returns results to LLM for synthesis
```

### Multi-Agent Orchestration

```
User Query: "What's the return policy and when will my order arrive?"
│
├─► Customer Service Agent
│   └─► Query: "return policy"
│       └─► agents-us, agents-apac
│           └─► Result: "Returns within 30 days..."
│
├─► Fulfillment Agent
│   └─► Query: "order arrival shipping"
│       └─► agents-us (only authorized)
│           └─► Result: "Standard shipping 5-7 days..."
│
└─► Synthesize Results
    └─► "Based on our policies, returns within 30 days and shipping takes 5-7 days."
```

---

## Data Flow & Components

### Query Execution Flow

```
1. User Input
   │
   ├─ "What is the return policy?"
   │
2. Agent Framework
   │
   ├─ Chat Client → Azure OpenAI LLM
   │  └─ LLM decides to call search_knowledge_base tool
   │
3. Tool Execution
   │
   ├─ search_knowledge_base(
   │    agent_name='customer-service-agent',
   │    query='return policy'
   │  )
   │
4. RBAC Enforcement
   │
   ├─ RBACEnforcingSearchClient.search()
   │  ├─ Check: Is index authorized for agent? ✅
   │  ├─ Check: Is index in denied list? ✅
   │  └─ Proceed to search
   │
5. Azure Search Query
   │
   ├─ SearchClient.search()
   │  ├─ Authenticate: Use DefaultAzureCredential (or admin key fallback)
   │  ├─ Query: "return policy"
   │  ├─ Index: agents-us
   │  ├─ Select: ['id', 'title', 'content', 'region']
   │  └─ Results: [doc1, doc2, doc3]
   │
6. Document-Level Filtering (if secure index)
   │
   ├─ OData Filter: security/any(s: s eq '<principal-id>')
   │  └─ Only docs where principal is authorized
   │
7. Result Formatting
   │
   ├─ Format for LLM consumption
   │  └─ Titles, content excerpts, scores
   │
8. LLM Synthesis
   │
   ├─ LLM reads search results
   │  └─ Generates conversational response
   │
9. User Output
   └─ "Based on our policy, returns within 30 days..."
```

### Knowledge Base Structure

```
Azure AI Search
├── agents-us
│   ├── Document: "Return Policy"
│   │   ├── id: "policy-1"
│   │   ├── title: "Return Policy"
│   │   ├── content: "All returns accepted within 30 days..."
│   │   ├── region: "US"
│   │   └── @search.score: 0.95
│   │
│   └── Document: "Order Processing"
│       ├── id: "proc-1"
│       ├── title: "Standard Shipping (US)"
│       ├── content: "Orders ship 5-7 business days..."
│       ├── region: "US"
│       └── @search.score: 0.87
│
├── agents-apac
│   ├── Document: "Regional Compliance"
│   └── Document: "APAC Procedures"
│
└── agents-us-secure
    ├── Document: "Executive Summary"
    │   └── security: ["principal-a", "principal-b"]
    │
    └── Document: "Confidential Operations"
        └── security: ["principal-c"]
```

### Agent Policies

```python
agent_rbac_policies = {
    'customer-service-agent': {
        'authorized_indices': ['agents-us', 'agents-apac'],
        'denied_indices': ['agents-us-secure']
        # Can query US and APAC, but NOT secure docs
    },
    'fulfillment-agent': {
        'authorized_indices': ['agents-us'],
        'denied_indices': ['agents-us-secure', 'agents-apac']
        # Can only query US (fulfillment-specific)
    },
    'compliance-agent': {
        'authorized_indices': ['agents-apac', 'agents-us-secure'],
        'denied_indices': []
        # Can query both regional and secure (compliance role)
    },
    'regional-apac-agent': {
        'authorized_indices': ['agents-apac'],
        'denied_indices': ['agents-us', 'agents-us-secure']
        # Can only query APAC (regional scope)
    }
}
```

---

## Performance Considerations

### Query Optimization

1. **Index Selection:** Agents query only authorized indices (reduces scope)
2. **Field Selection:** Use `select=['id', 'title', 'content', 'region']` (reduces payload)
3. **Result Limits:** Use `top=3` for relevance (faster, less data)
4. **Caching:** Cache embeddings and frequent queries

### Scaling Strategies

1. **Multi-Agent Parallelization:** Async/await for concurrent agent queries
2. **Index Sharding:** Large KBs split across regional indices
3. **Managed Identity:** No key rotation overhead (RBAC-based)
4. **Azure Monitor:** Track query latency and error rates

---

## Security Best Practices

✅ **Do's**
- Use RBAC (Azure role assignments) for Search access
- Implement agent policies for fine-grained control
- Use document-level security for sensitive data
- Log all queries for audit trail
- Use managed identities (no secrets in code)
- Implement least-privilege (only needed permissions)

❌ **Don'ts**
- Don't share admin keys across agents
- Don't disable local auth in production without RBAC setup
- Don't store secrets in code or notebooks
- Don't skip audit logging
- Don't grant excessive permissions
- Don't rely solely on document filters (combine with RBAC)

---

## References

- [Azure AI Foundry Quickstart](https://learn.microsoft.com/en-us/azure/ai-foundry/how-to/create-resource-template?view=foundry-classic&tabs=cli)
- [Azure Search RBAC](https://learn.microsoft.com/en-us/azure/search/search-security-rbac)
- [Microsoft Agent Framework](https://github.com/microsoft/agent-framework)
- [Azure Identity SDK](https://learn.microsoft.com/python/api/azure-identity/azure.identity.defaultazurecredential)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
