# Agent Framework & Integration Patterns

Advanced patterns for building production-ready agents with Microsoft Agent Framework, Azure Foundry, and RBAC-protected search.

## Table of Contents

1. [Core Patterns](#core-patterns)
2. [Agent Framework Integration](#agent-framework-integration)
3. [Foundry Patterns](#foundry-patterns)
4. [Security Patterns](#security-patterns)
5. [Extension Patterns](#extension-patterns)
6. [Testing Patterns](#testing-patterns)
7. [Performance Patterns](#performance-patterns)

---

## Core Patterns

### 1. RBAC-Enforcing Search Client Pattern

The foundation of secure agent access to knowledge bases:

```python
class RBACEnforcingSearchClient:
    """Wraps Azure Search SDK to enforce role-based access control."""
    
    def __init__(self, agent_name: str, policy: dict, endpoint: str, api_key: str):
        self.agent_name = agent_name
        self.policy = policy  # {authorized_indices, denied_indices, principal_id}
        self.endpoint = endpoint
        self.api_key = api_key
    
    def search(self, index_name: str, query: str) -> dict:
        # Step 1: Validate access
        if not self._is_authorized(index_name):
            return {
                'success': False,
                'access_denied': True,
                'message': f'Agent {self.agent_name} cannot access {index_name}'
            }
        
        # Step 2: Execute search
        client = SearchClient(
            endpoint=self.endpoint,
            index_name=index_name,
            credential=AzureKeyCredential(self.api_key)
        )
        
        results = client.search(query, select=['id', 'title', 'content', 'region'])
        
        # Step 3: Return with metadata
        return {
            'success': True,
            'documents': list(results),
            'index': index_name,
            'query': query
        }
    
    def _is_authorized(self, index_name: str) -> bool:
        """Check if agent can access this index."""
        
        # Check explicit denials first
        if index_name in self.policy.get('denied_indices', []):
            return False
        
        # Check authorizations
        authorized = self.policy.get('authorized_indices', [])
        return index_name in authorized
```

**Use Cases:**
- ✅ Multi-tenant agent systems
- ✅ Role-based knowledge base access
- ✅ Audit and compliance logging
- ✅ Fine-grained access control per agent

**Key Benefits:**
- Enforces access at query time
- Prevents unauthorized index access
- Provides audit trail
- Integrates seamlessly with Agent Framework

---

### 2. FoundryAgent with Blueprint Integration

Agents that inherit their access from Blueprint principals:

```python
class FoundryAgent:
    """Foundry agent with blueprint RBAC integration."""
    
    def __init__(self, 
                 name: str, 
                 policy: dict,
                 search_endpoint: str,
                 search_api_key: str):
        self.name = name
        self.principal_id = policy['principal_id']  # Blueprint principal
        self.policy = policy
        
        # Create RBAC-enforcing client
        self.search_client = RBACEnforcingSearchClient(
            agent_name=name,
            policy=policy,
            endpoint=search_endpoint,
            api_key=search_api_key
        )
    
    def query_knowledge_base(self, query: str, index: str = None) -> dict:
        """Query KB with automatic RBAC enforcement."""
        
        # If no index specified, search all authorized indices
        if not index:
            return self._search_authorized_indices(query)
        
        # Single index query with RBAC check
        result = self.search_client.search(index, query)
        return {
            'agent': self.name,
            'principal_id': self.principal_id,
            'query': query,
            **result
        }
    
    def _search_authorized_indices(self, query: str) -> dict:
        """Broadcast query to all authorized indices."""
        
        all_results = {
            'agent': self.name,
            'query': query,
            'indices_searched': [],
            'total_documents': 0,
            'combined_results': []
        }
        
        for index in self.policy['authorized_indices']:
            result = self.search_client.search(index, query)
            
            if result['success']:
                all_results['indices_searched'].append(index)
                all_results['combined_results'].extend(result['documents'])
                all_results['total_documents'] += len(result['documents'])
        
        return all_results
```

**Extends to:**
- Custom agent behaviors
- Tool implementations
- Conversation memory
- Multi-turn interactions

**Key Features:**
- Automatic RBAC enforcement
- Single or multi-index queries
- Access denial tracking
- Integration with Agent Framework

---

### 3. Agent Tool Framework Pattern

Tools that agents can call:

```python
# Define tool function with type hints
def search_knowledge_base(
    query: Annotated[str, Field(description="Search query for KB")],
    agent_name: Annotated[str, Field(
        description="Agent name",
        default="customer-service-agent"
    )],
    index: Annotated[str, Field(
        description="Optional: specific index to search",
        default=None
    )]
) -> str:
    """Search knowledge base with RBAC enforcement.
    
    This tool searches the knowledge base and enforces role-based access
    control based on the agent's policy. Results are automatically filtered.
    """
    
    # Get agent
    if agent_name not in foundry_agents:
        return f"Error: Unknown agent '{agent_name}'"
    
    agent = foundry_agents[agent_name]
    
    # Execute query
    result = agent.query_knowledge_base(query, index)
    
    # Check for access denial
    if not result.get('success', True) and result.get('access_denied'):
        return f"Access denied: You cannot access '{index}'"
    
    # Format results for agent consumption
    if result.get('total_documents', 0) == 0:
        return f"No documents found for query: {query}"
    
    # Create formatted response
    formatted = f"Found {result['total_documents']} documents:\n\n"
    for doc in result.get('combined_results', [])[:5]:  # Top 5
        formatted += f"- **{doc['title']}** (Index: {doc.get('index', 'unknown')})\n"
        formatted += f"  {doc['content'][:200]}...\n\n"
    
    return formatted


# Register tool with Agent Framework
agent_tools = {
    'search_knowledge_base': {
        'function': search_knowledge_base,
        'description': 'Search KB with automatic RBAC enforcement',
        'parameters': {
            'query': 'str (required)',
            'agent_name': 'str (optional, default: customer-service-agent)',
            'index': 'str (optional, search all if not specified)'
        }
    }
}
```

**Extends to:**
- Complex tool pipelines
- Multi-step workflows
- Conditional logic
- External API calls
- Database queries
- Real-time data retrieval

---

## Agent Framework Integration

### Pattern 1: Chat Agent with Azure OpenAI

Production-ready agent configuration:

```python
from agent_framework import ChatAgent
from agent_framework.azure import AzureOpenAIChatClient

# Step 1: Configure chat client
chat_client = AzureOpenAIChatClient(
    api_key=os.getenv('AZURE_OPENAI_API_KEY'),
    endpoint=os.getenv('AZURE_OPENAI_ENDPOINT'),
    deployment_name=os.getenv('AZURE_OPENAI_CHAT_DEPLOYMENT_NAME'),
    api_version='2024-10-21',  # Use latest stable version
    model_name='gpt-4o'
)

# Step 2: Create agent with tools and instructions
agent = ChatAgent(
    chat_client=chat_client,
    name='customer-service-agent',
    instructions="""You are a helpful customer service representative.
    
Your responsibilities:
- Answer questions about our products and policies
- Help customers with orders and returns
- Provide clear, empathetic responses
- Escalate to specialists when needed

Use the search_knowledge_base tool to find relevant information.""",
    tools=[
        search_knowledge_base,
        get_knowledge_base_info,
        list_agent_queries
    ]
)

# Step 3: Execute agent
response = await agent.run("What is your return policy?")
print(response)
```

**Key Configuration:**
- ✅ Proper API version for stability
- ✅ Clear instructions for agent behavior
- ✅ Relevant tools registered
- ✅ Error handling for tool execution

---

### Pattern 2: Multi-Agent Orchestration

Handle complex queries across multiple agents:

```python
# Sequential orchestration - escalation pattern
async def handle_customer_query(query: str) -> str:
    """Route query to appropriate agent, escalate if needed."""
    
    # Step 1: Try customer service agent
    cs_agent = foundry_agents['customer-service-agent']
    cs_response = await cs_agent.run(query)
    
    # Step 2: Check if escalation needed
    if 'shipping' in query.lower() or 'delivery' in query.lower():
        ff_agent = foundry_agents['fulfillment-agent']
        ff_response = await ff_agent.run(query)
        
        # Combine responses
        return f"""
**Customer Service Response:**
{cs_response}

**Fulfillment Details:**
{ff_response}
"""
    
    return cs_response


# Broadcast orchestration - parallel queries
async def comprehensive_answer(query: str) -> str:
    """Get insights from multiple agents in parallel."""
    
    tasks = [
        foundry_agents['customer-service-agent'].run(query),
        foundry_agents['compliance-agent'].run(query),
        foundry_agents['fulfillment-agent'].run(query)
    ]
    
    # Wait for all agents
    results = await asyncio.gather(*tasks)
    
    return aggregate_responses(results)


# Conditional orchestration
async def intelligent_routing(query: str) -> str:
    """Route based on query analysis."""
    
    # Analyze query intent
    intent = classify_intent(query)
    
    if intent == 'return':
        agent = foundry_agents['customer-service-agent']
    elif intent == 'shipping':
        agent = foundry_agents['fulfillment-agent']
    elif intent == 'legal':
        agent = foundry_agents['compliance-agent']
    else:
        agent = foundry_agents['customer-service-agent']  # default
    
    return await agent.run(query)
```

**Orchestration Strategies:**
1. **Sequential** - One agent then another
2. **Broadcast** - All agents in parallel
3. **Conditional** - Route based on intent
4. **Hierarchical** - Master agent dispatches to specialists

---

### Pattern 3: Function Calling for Tool Execution

Agent Framework automatic tool binding:

```python
from pydantic import Field
from typing import Annotated

def search_knowledge_base(
    query: Annotated[str, Field(
        description="Search query for knowledge base"
    )],
    agent_name: Annotated[str, Field(
        description="Agent to use for search",
        default="customer-service-agent"
    )] = "customer-service-agent"
) -> str:
    """Search knowledge base for relevant documents.
    
    Uses the specified agent's RBAC policy to filter results.
    Only documents the agent is authorized to see are returned.
    """
    agent = foundry_agents[agent_name]
    result = agent.query_knowledge_base(query)
    return format_results(result)


# Agent Framework automatically:
# 1. Inspects function signature
# 2. Creates JSON schema for function calling
# 3. Detects when LLM wants to call tool
# 4. Passes proper types/parameters
# 5. Catches exceptions and reports back
# 6. Includes result in conversation
```

**Type Annotations Required:**
- Use `Annotated[type, Field(...)]` for parameters
- Include `description` for LLM understanding
- Use default values for optional parameters
- Add docstring for context

---

## Foundry Patterns

### Pattern 1: Foundry Project Organization

Recommended folder structure:

```
Foundry Project
├── agents/
│   ├── customer-service-agent/
│   │   ├── config.yaml
│   │   ├── instructions.txt
│   │   ├── tools.json
│   │   ├── rbac-policy.json
│   │   └── __init__.py
│   ├── fulfillment-agent/
│   │   └── ...
│   └── compliance-agent/
│       └── ...
├── knowledge-bases/
│   ├── agents-us/
│   │   ├── documents/
│   │   ├── schema.json
│   │   └── index-config.json
│   ├── agents-apac/
│   │   └── ...
│   └── agents-us-secure/
│       ├── documents/
│       └── security-fields.json
├── models/
│   ├── embeddings-config.json
│   └── deployment-params.json
├── shared/
│   ├── constants.py
│   ├── utils.py
│   └── decorators.py
└── tests/
    ├── test_agents.py
    ├── test_rbac.py
    └── test_orchestration.py
```

**Best Practices:**
- ✅ Separate agent configs
- ✅ Organized KB structure
- ✅ Shared utilities
- ✅ Comprehensive tests

---

### Pattern 2: Foundry Deployment

Complete deployment workflow:

```bash
#!/bin/bash
# Deploy Foundry infrastructure

# Step 1: Create resource group
az group create \
  --name rg-agent-blueprint-demo \
  --location eastus2

# Step 2: Deploy via Bicep
az deployment group create \
  --name foundry-setup \
  --resource-group rg-agent-blueprint-demo \
  --template-file notebooks/foundry-resources.bicep \
  --parameters \
    blueprintPrincipalId=$BLUEPRINT_PRINCIPAL_ID \
    location=eastus2

# Step 3: Retrieve outputs
OUTPUTS=$(az deployment group show \
  --name foundry-setup \
  --resource-group rg-agent-blueprint-demo \
  --query properties.outputs -o json)

# Step 4: Save configuration
echo "$OUTPUTS" | jq . > foundry-config.json

# Step 5: Deploy containers
az container create \
  --resource-group rg-agent-blueprint-demo \
  --name agent-container \
  --image myregistry.azurecr.io/agent-framework:latest \
  --environment-variables \
    FOUNDRY_ENDPOINT=$(jq -r '.foundryEndpoint.value' foundry-config.json) \
    PROJECT_ID=$(jq -r '.projectId.value' foundry-config.json)
```

---

### Pattern 3: Foundry with Managed Identity

Eliminate API keys with Azure managed identity:

```python
from azure.identity import ManagedIdentityCredential
from azure.search.documents import SearchClient

# In Azure Container Instance, App Service, or Function
credential = ManagedIdentityCredential()

# Use with Azure Search
search_client = SearchClient(
    endpoint=os.getenv('AZURE_SEARCH_ENDPOINT'),
    index_name='agents-us',
    credential=credential  # No API key needed!
)

# Use with Cosmos DB
cosmosdb_client = CosmosClient(
    url=os.getenv('COSMOS_ENDPOINT'),
    credential=credential
)

# Benefits:
# - No API key management
# - Automatic token refresh
# - Audit trail in Azure AD
# - Role-based access control
```

---

## Security Patterns

### Pattern 1: Principal-Based Access Control

Verify identity before granting access:

```python
def validate_principal(principal_id: str, allowed_principals: list) -> bool:
    """Check if principal is authorized."""
    return principal_id in allowed_principals


def enforce_rbac(agent_name: str, index_name: str) -> bool:
    """Verify agent can access index."""
    
    # Load agent policy
    policy = agent_policies.get(agent_name)
    if not policy:
        return False
    
    # Check authorized indices
    authorized = policy['authorized_indices']
    if index_name not in authorized:
        return False
    
    # Check denied indices
    denied = policy.get('denied_indices', [])
    return index_name not in denied


# Usage in agent
@authorize_principal
async def execute_query(principal_id: str, query: str):
    """Execute query only if principal authorized."""
    if not validate_principal(principal_id, allowed_principals):
        raise PermissionError(f"Principal {principal_id} not authorized")
    
    return await search_kb(query)
```

---

### Pattern 2: Query Audit Logging

Track all agent queries for compliance:

```python
import logging
from datetime import datetime
from azure.data.tables import TableClient

class AuditLogger:
    """Audit log for agent queries."""
    
    def __init__(self, table_connection_string: str):
        self.table_client = TableClient.from_connection_string(
            conn_str=table_connection_string,
            table_name='agent-audit-log'
        )
    
    def log_query(self, 
                  agent_name: str, 
                  query: str,
                  result: dict,
                  principal_id: str = None):
        """Log agent query for audit trail."""
        
        log_entry = {
            'PartitionKey': agent_name,
            'RowKey': f"{datetime.utcnow().isoformat()}_{uuid.uuid4()}",
            'timestamp': datetime.utcnow().isoformat(),
            'agent_name': agent_name,
            'principal_id': principal_id,
            'query': query,
            'indices_queried': ','.join(result.get('indices', [])),
            'documents_found': result.get('total_documents', 0),
            'access_denied_attempts': result.get('access_denied_count', 0),
            'execution_time_ms': result.get('execution_time_ms', 0),
            'status': 'success' if result.get('success') else 'failed'
        }
        
        self.table_client.upsert_entity(log_entry)
        logging.info(f"Audit logged for agent {agent_name}")

# Usage
audit_logger = AuditLogger(table_connection_string)

result = agent.query_knowledge_base("How to process returns?")
audit_logger.log_query(
    agent_name='customer-service-agent',
    query="How to process returns?",
    result=result,
    principal_id=agent.principal_id
)
```

---

### Pattern 3: Access Denial Response

Handle unauthorized access gracefully:

```python
def handle_access_denied(agent_name: str, index_name: str, query: str):
    """Respond to unauthorized access attempts."""
    
    agent = foundry_agents[agent_name]
    
    # Step 1: Log the incident
    logging.warning(
        f"Access denied: {agent_name} attempted to access {index_name}",
        extra={
            'agent': agent_name,
            'index': index_name,
            'principal_id': agent.principal_id,
            'query': query
        }
    )
    
    # Step 2: Check for suspicious patterns
    recent_denials = get_recent_access_denials(agent_name, minutes=5)
    if len(recent_denials) > 5:
        # Potential security incident
        send_security_alert(
            f"Agent {agent_name} exceeded access denial threshold",
            severity='WARNING'
        )
    
    # Step 3: Return safe error message
    return {
        'success': False,
        'message': f'You are not authorized to access the {index_name} knowledge base',
        'contact_support': True,
        'support_email': 'support@company.com'
    }
```

---

## Extension Patterns

### Pattern 1: Custom Agent Implementation

Extend FoundryAgent with domain-specific logic:

```python
class SpecializedAgent(FoundryAgent):
    """Domain-specific agent with custom query processing."""
    
    def __init__(self, *args, domain: str = None, **kwargs):
        super().__init__(*args, **kwargs)
        self.domain = domain
        self.domain_vocabulary = load_domain_terms(domain)
    
    async def query_knowledge_base(self, 
                                   query: str, 
                                   index: str = None) -> dict:
        """Query KB with domain-specific preprocessing."""
        
        # Step 1: Preprocess query
        normalized_query = self.preprocess_query(query)
        
        # Step 2: Call parent
        result = await super().query_knowledge_base(
            normalized_query, 
            index
        )
        
        # Step 3: Post-process results
        if result.get('success'):
            result['documents'] = self.rank_by_domain(result['documents'])
            result['summary'] = self.generate_summary(result['documents'])
            result['confidence_score'] = self.calculate_confidence(result)
        
        return result
    
    def preprocess_query(self, query: str) -> str:
        """Normalize query using domain vocabulary."""
        # Replace domain synonyms
        for synonym, canonical in self.domain_vocabulary.items():
            query = query.replace(synonym, canonical)
        return query
    
    def rank_by_domain(self, documents: list) -> list:
        """Re-rank results by domain relevance."""
        def domain_score(doc):
            # Score based on domain-specific fields
            score = 0
            for term in self.domain_vocabulary.values():
                if term.lower() in doc['content'].lower():
                    score += 1
            return score
        
        return sorted(documents, 
                     key=domain_score, 
                     reverse=True)
    
    def generate_summary(self, documents: list) -> str:
        """Generate domain-specific summary."""
        # Implementation specific to domain
        pass
```

---

### Pattern 2: Custom Tools

Extend toolkit with specialized functions:

```python
def advanced_search(
    agent_name: Annotated[str, Field(description="Agent name")],
    query: Annotated[str, Field(description="Search query")],
    filters: Annotated[dict, Field(
        description="Optional OData filters",
        default={}
    )] = {},
    ranking_strategy: Annotated[str, Field(
        description="Ranking strategy: bm25 | semantic | combined",
        default="bm25"
    )] = "bm25"
) -> str:
    """Advanced search with custom filters and ranking strategies."""
    
    agent = foundry_agents[agent_name]
    
    # Step 1: Execute search
    result = agent.query_knowledge_base(query)
    
    # Step 2: Apply custom filtering
    if filters:
        result['documents'] = apply_odata_filters(
            result['documents'],
            filters
        )
    
    # Step 3: Apply custom ranking
    if ranking_strategy == 'semantic':
        result['documents'] = semantic_rank(
            result['documents'],
            query,
            embedding_model=embeddings_client
        )
    elif ranking_strategy == 'combined':
        result['documents'] = combined_rank(
            result['documents'],
            query
        )
    
    return format_results(result)


def enriched_search(
    agent_name: Annotated[str, Field(description="Agent name")],
    query: Annotated[str, Field(description="Search query")]
) -> str:
    """Search KB and enrich with external data."""
    
    # Step 1: Query KB
    kb_result = foundry_agents[agent_name].query_knowledge_base(query)
    
    # Step 2: Call external APIs
    weather_data = call_weather_api(query)
    news_data = call_news_api(query)
    
    # Step 3: Combine and synthesize
    enriched = {
        'kb_documents': kb_result['documents'][:3],
        'external_context': {
            'weather': weather_data,
            'news': news_data
        },
        'synthesis': synthesize_insights(kb_result, weather_data, news_data)
    }
    
    return format_enriched_results(enriched)
```

---

## Testing Patterns

### Pattern 1: RBAC Validation Tests

Ensure access control is enforced:

```python
import pytest

class TestRBACEnforcement:
    """Test suite for RBAC enforcement."""
    
    def test_agent_can_access_authorized_index(self):
        """Agent should access authorized indices."""
        result = foundry_agents['customer-service-agent'].query_knowledge_base(
            'return policy',
            'agents-us'
        )
        
        assert result['success'] == True
        assert len(result['documents']) > 0
    
    def test_agent_cannot_access_denied_index(self):
        """Agent should be blocked from denied indices."""
        result = foundry_agents['customer-service-agent'].query_knowledge_base(
            'internal compliance',
            'agents-us-secure'  # Not authorized
        )
        
        assert result['success'] == False
        assert result.get('access_denied') == True
    
    def test_all_agents_rbac_matrix(self):
        """Verify RBAC matrix for all agents."""
        expected_matrix = {
            'customer-service-agent': {
                'agents-us': True,
                'agents-apac': True,
                'agents-us-secure': False
            },
            'fulfillment-agent': {
                'agents-us': True,
                'agents-apac': False,
                'agents-us-secure': False
            },
            'compliance-agent': {
                'agents-us': False,
                'agents-apac': True,
                'agents-us-secure': True
            }
        }
        
        for agent_name, matrix in expected_matrix.items():
            agent = foundry_agents[agent_name]
            for index, should_succeed in matrix.items():
                result = agent.query_knowledge_base('test', index)
                assert result['success'] == should_succeed, \
                    f"{agent_name} → {index} failed"
```

---

### Pattern 2: Integration Tests

Test multi-agent workflows:

```python
@pytest.mark.asyncio
async def test_multi_agent_orchestration():
    """Test orchestrated query across multiple agents."""
    
    query = "What is the return policy and when will my order arrive?"
    
    # Execute multi-agent query
    responses = await handle_customer_query(query)
    
    # Verify both agents responded
    assert 'return' in responses.lower() or 'policy' in responses.lower()
    assert 'shipping' in responses.lower() or 'delivery' in responses.lower()


@pytest.mark.asyncio
async def test_agent_tool_execution():
    """Test that Agent Framework executes tools correctly."""
    
    agent = foundry_agents['customer-service-agent']
    
    # Run agent with query requiring tool use
    response = await agent.run(
        "Based on our policies, what is the return window?"
    )
    
    # Verify tool was called and results used
    assert len(response) > 0
    assert 'days' in response or 'hours' in response
```

---

## Performance Patterns

### Pattern 1: Query Caching

Reduce duplicate query execution:

```python
from functools import lru_cache
from datetime import datetime, timedelta

# In-memory caching (single process)
@lru_cache(maxsize=1000)
def cached_search(agent_name: str, query: str, index: str = None) -> str:
    """Cache search results to improve performance."""
    
    agent = foundry_agents[agent_name]
    result = agent.query_knowledge_base(query, index)
    
    return format_results(result)


# Distributed caching with Redis
import redis

class CachedSearchClient:
    """Search client with Redis caching."""
    
    def __init__(self, redis_connection_string: str, ttl_seconds: int = 3600):
        self.redis = redis.Redis.from_url(redis_connection_string)
        self.ttl = ttl_seconds
    
    def search(self, agent_name: str, query: str, index: str = None) -> str:
        """Search with caching."""
        
        # Create cache key
        cache_key = f"search:{agent_name}:{index}:{hash(query)}"
        
        # Try cache
        cached_result = self.redis.get(cache_key)
        if cached_result:
            return cached_result.decode()
        
        # Execute search
        agent = foundry_agents[agent_name]
        result = agent.query_knowledge_base(query, index)
        formatted = format_results(result)
        
        # Cache result
        self.redis.setex(cache_key, self.ttl, formatted)
        
        return formatted
```

---

### Pattern 2: Batch Processing

Process multiple queries efficiently:

```python
import asyncio

async def batch_query_agents(queries: list[str]) -> list[dict]:
    """Process multiple queries in parallel."""
    
    tasks = [
        foundry_agents['customer-service-agent'].run(q)
        for q in queries
    ]
    
    # Wait for all queries
    results = await asyncio.gather(*tasks, return_exceptions=True)
    
    # Handle exceptions
    processed = []
    for query, result in zip(queries, results):
        if isinstance(result, Exception):
            processed.append({
                'query': query,
                'error': str(result)
            })
        else:
            processed.append({
                'query': query,
                'response': result
            })
    
    return processed


# Usage
queries = [
    "What is the return policy?",
    "How do I track my order?",
    "What payment methods do you accept?"
]

results = await batch_query_agents(queries)

for result in results:
    print(f"Q: {result['query']}")
    print(f"A: {result['response']}\n")
```

---

## References & Resources

**Official Documentation:**
- [Microsoft Agent Framework](https://github.com/microsoft/agent-framework)
- [Agent Framework Samples](https://github.com/microsoft/agent-framework/tree/main/python/samples)
- [Azure AI Foundry](https://learn.microsoft.com/azure/ai-services/agents/)
- [Azure Search RBAC](https://learn.microsoft.com/azure/search/search-security-rbac)

**Related Guides:**
- [docs/ARCHITECTURE.md](ARCHITECTURE.md) - System design and patterns
- [docs/SETUP.md](SETUP.md) - Configuration and deployment
- [docs/NOTEBOOKS.md](NOTEBOOKS.md) - Detailed notebook descriptions

**Key SDK References:**
- [Agent Framework Python API](https://github.com/microsoft/agent-framework/tree/main/python)
- [Azure Search SDK for Python](https://learn.microsoft.com/python/api/overview/azure/search-documents-readme)
- [Azure Identity SDK](https://learn.microsoft.com/python/api/overview/azure/identity-readme)

---

**Last Updated:** January 2026  
**Version:** 1.1
