# Notebooks Guide

Complete guide to all Jupyter notebooks in Agent365 Sandbox, with learning paths and detailed descriptions.

## Table of Contents

1. [Notebooks Overview](#notebooks-overview)
2. [Learning Path](#learning-path)
3. [Detailed Descriptions](#detailed-descriptions)
4. [Execution Guide](#execution-guide)

---

## Notebooks Overview

| # | Name | Purpose | Duration | Status | Dependencies |
|---|------|---------|----------|--------|---|
| **01** | **validate-configuration** | Load & test `.env`, verify Graph connectivity | 10-15 min | Reference | None |
| **01b** | **agent365-cli-init** | Initialize agent blueprint via Agent365 CLI | 15-20 min | ✅ **Active** | None |
| **02** | **token-flows** | OAuth 2.0 flows, JWT inspection, token caching | 20-25 min | Reference | 01 |
| **03** | **agent-sdk** | Microsoft Entra SDK, agent lifecycle, sign-in logs | 30-40 min | Reference | 02 |
| **04** | **interactive-authentication** | Authorization codes, OBO flow, user consent | 35-45 min | Reference | 03 |
| **05** | **azure-infra-setup** | Deploy Azure AI Search via Bicep, create indices | 15-20 min | ✅ **Active** | 01 |
| **06** | **search-rbac-demo** | Index RBAC + document-level security | 20-30 min | ✅ **Active** | 05 |
| **07** | **agentic-retrieval-knowledge-base** | Multi-agent KB with synthesis + conversations | 25-35 min | ✅ **Active** | 06 |
| **08** | **agent-framework-foundry** | *(Legacy)* Combined setup + agents | 30-40 min | Deprecated | 07 |
| **08a** | **foundry-setup** | Foundry configuration, credentials, connections | 15-20 min | ✅ **Active** | 07 |
| **08b** | **foundry-agents** | Agent creation, queries, invocation | 20-25 min | ✅ **Active** | 08a |

---

## Learning Path

### Path 1: Agent Identity & Authentication (Reference)
Recommended for understanding Entra ID concepts.

```
Blueprint Setup (a365.ps1)
    ↓
01-validate-configuration
    ↓
02-token-flows
    ↓
03-agent-sdk
    ↓
04-interactive-authentication
```

**Outcomes:**
- ✅ Understand OAuth 2.0 flows
- ✅ Inspect JWT tokens
- ✅ Work with Microsoft Graph API
- ✅ Handle token caching and refresh

### Path 2: Azure Search & RBAC (Active)
Recommended for production implementations.

```
Blueprint Setup (a365.ps1)
    ↓
01-validate-configuration
    ↓
05-azure-infra-setup
    ↓
06-search-rbac-demo
```

**Outcomes:**
- ✅ Deploy Azure AI Search via Bicep
- ✅ Create and manage indices
- ✅ Configure RBAC (index-level)
- ✅ Implement document-level security

### Path 3: Agentic Retrieval & Knowledge Base (Active)
Recommended for building AI applications.

```
Blueprint Setup (a365.ps1)
    ↓
01-validate-configuration
    ↓
05-azure-infra-setup
    ↓
06-search-rbac-demo
    ↓
07-agentic-retrieval-knowledge-base
```

**Outcomes:**
- ✅ Build multi-agent systems
- ✅ Create knowledge bases with selective access
- ✅ Implement agentic retrieval patterns
- ✅ Synthesize answers from documents
- ✅ Enable multi-turn conversations

### Path 4: Full Stack - Foundry + Agent Framework (Active)
Recommended for production agents.

```
Blueprint Setup (a365.ps1)
    ↓
01-validate-configuration
    ↓
05-azure-infra-setup
    ↓
06-search-rbac-demo
    ↓
07-agentic-retrieval-knowledge-base
    ↓
08a-foundry-setup
    ↓
08b-foundry-agents
```

**Outcomes:**
- ✅ Deploy Foundry infrastructure
- ✅ Initialize Agent Framework
- ✅ Create production-ready agents
- ✅ Orchestrate multi-agent workflows
- ✅ Validate RBAC enforcement
- ✅ Integrate with Azure OpenAI

---

## Detailed Descriptions

### Notebook 01: validate-configuration.ipynb

**Duration:** 10-15 minutes  
**Purpose:** Verify environment setup and configuration

**What it does:**
1. Loads `.env` file
2. Validates all required environment variables
3. Tests Azure authentication
4. Verifies Microsoft Graph connectivity
5. Displays configuration summary (masked values)

**Cells:**
- Load environment variables
- Validate required fields
- Test authentication tokens
- Verify Graph API access
- Display configuration

**Prerequisites:**
- `.env` file in current directory
- Azure CLI logged in

**Expected output:**
```
✅ Configuration loaded successfully
✅ All required variables present
✅ Azure authentication working
✅ Graph API accessible
```

**Next steps:** Proceed to Notebook 02 or 05

---

### Notebook 02: token-flows.ipynb

**Duration:** 20-25 minutes  
**Purpose:** Understand OAuth 2.0 flows and JWT tokens

**What it does:**
1. Demonstrates authorization code flow
2. Handles token refresh
3. Inspects JWT token claims
4. Shows token caching mechanisms
5. Explains on-behalf-of (OBO) flow

**Cells:**
- OAuth 2.0 authorization code flow
- Token acquisition and caching
- JWT inspection and claims extraction
- Token refresh mechanisms
- OBO flow demonstration

**Prerequisites:**
- Completed Notebook 01
- Blueprint app registration in Entra ID

**Expected output:**
```
Authorization Code: <code>
Access Token: eyJ0eXAiOiJKV1QiLCJhbGc...
Token Claims:
  - oid: <object-id>
  - appid: <client-id>
  - exp: <expiration>
```

**Key concepts:**
- Authorization code flow
- Access tokens vs. ID tokens
- Token expiration and refresh
- On-behalf-of (OBO) delegation

**Next steps:** Proceed to Notebook 03

---

### Notebook 03: agent-sdk.ipynb

**Duration:** 30-40 minutes  
**Purpose:** Work with Microsoft Entra Agent SDK

**What it does:**
1. Initializes Agent SDK client
2. Creates and manages agent identities
3. Handles agent lifecycle operations
4. Queries sign-in logs
5. Demonstrates agent-to-agent communication

**Cells:**
- Agent SDK initialization
- Agent identity creation/management
- Agent lifecycle (create, update, delete)
- Sign-in log analysis
- Agent delegation patterns

**Prerequisites:**
- Completed Notebook 02
- Agent identity permissions in Entra ID

**Expected output:**
```
Agent ID: <agent-id>
Agent Name: my-agent
Created: 2024-01-12
Sign-in events: 156
Last activity: 2024-01-12 15:30:00
```

**Key concepts:**
- Agent identity model
- Agent lifecycle management
- Sign-in and audit logs
- Agent-to-agent collaboration

**Next steps:** Proceed to Notebook 04

---

### Notebook 04: interactive-authentication.ipynb

**Duration:** 35-45 minutes  
**Purpose:** Handle user authentication and authorization

**What it does:**
1. Initiates interactive browser sign-in
2. Requests user consent for permissions
3. Handles authorization codes
4. Implements OBO flow for user delegation
5. Manages user context in agent operations

**Cells:**
- Interactive sign-in flow
- Permission consent prompts
- Authorization code exchange
- OBO (On-Behalf-Of) delegation
- User context preservation

**Prerequisites:**
- Completed Notebook 03
- Microsoft authentication library configured

**Expected output:**
```
Redirecting to browser for authentication...
User signed in: user@contoso.com
Permissions requested: email, profile, offline_access
User consent: Granted
Access token acquired for: https://graph.microsoft.com
```

**Key concepts:**
- Interactive user authentication
- Consent and permissions
- Authorization code flow
- On-behalf-of delegation

**Next steps:** Choose learning path (02-04 complete authentication concepts)

---

### Notebook 05: azure-infra-setup.ipynb

**Duration:** 15-20 minutes  
**Purpose:** Deploy Azure AI Search infrastructure

**What it does:**
1. Creates resource group
2. Deploys Azure AI Search via Bicep
3. Creates two indices: `agents-us`, `agents-apac`
4. Uploads initial documents
5. Saves deployment outputs for downstream notebooks

**Cells:**
- Environment setup and validation
- Bicep template deployment (subscription + RG scope)
- Index schema creation
- Document upload
- Configuration persistence

**Prerequisites:**
- `.env` file with AZURE_TENANT_ID, AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, AZURE_SUBSCRIPTION_ID
- Azure permissions to create resources
- Azure CLI installed and authenticated

**Key resources created:**
- Resource Group: `rg-agent-blueprint-demo`
- Search Service: `search-<unique-suffix>`
- Index 1: `agents-us` (fields: id, title, content, region)
- Index 2: `agents-apac` (fields: id, title, content, region)

**Expected output:**
```
✅ Resource group created
✅ Search service deployed
✅ agents-us index created with 50 documents
✅ agents-apac index created with 30 documents
✅ Configuration saved to foundry-config.json
```

**Outputs saved:**
- `foundry-config.json` (endpoint, index names)
- Updated `.env` (AZURE_SEARCH_ENDPOINT, AZURE_SEARCH_SERVICE_NAME)

**Deployment details:**
- Uses Bicep for infrastructure as code
- Deterministic naming via `uniqueString()`
- Free tier supported
- CORS enabled for browser access

**Next steps:** Run Notebook 06

---

### Notebook 06: search-rbac-demo.ipynb

**Duration:** 20-30 minutes  
**Purpose:** Configure RBAC and document-level security

**What it does:**
1. Assigns Azure RBAC roles to service principal
2. Creates `agents-us-secure` index with security field
3. Uploads documents with per-principal access lists
4. Demonstrates OData filters for document-level security
5. Validates queries with different principals

**Steps:**

**Step 1: Index-Scoped RBAC Setup**
- Grant service principal "Search Index Data Reader" role
- Verify role assignment propagation
- Test index access

**Step 2: RBAC Validation**
- Query authorized indices
- Verify read permissions working
- Test multiple principal identities

**Step 3: Document-Level Security**
- Create `agents-us-secure` index with `security` Collection(Edm.String) field
- Upload documents with security lists:
  ```json
  {
    "id": "doc1",
    "security": ["principal-a", "principal-b"]
  }
  ```

**Step 4: OData Filter Queries**
- Use `security/any(s: s eq '<principal>')` filter
- Demonstrate selective document visibility
- Show combined RBAC + document-level control

**Step 5: Multi-Principal Scenarios**
- Query as principal-a (sees doc1, doc2)
- Query as principal-b (sees doc1, doc3)
- Query as principal-c (sees no docs)

**Prerequisites:**
- Completed Notebook 05
- Azure role assignment permissions

**Key concepts:**
- Azure RBAC (index-level access)
- Document-level security (field-level filters)
- OData filter syntax for collections
- Multi-principal scenarios

**Expected output:**
```
✅ RBAC role assigned
✅ agents-us-secure index created
✅ 10 documents uploaded with security fields
✅ Query as principal-a: 3 results
✅ Query as principal-b: 2 results
✅ Query as principal-c: 0 results (access denied)
```

**Next steps:** Run Notebook 07

---

### Notebook 07: agentic-retrieval-knowledge-base.ipynb

**Duration:** 25-35 minutes  
**Purpose:** Build multi-agent knowledge base with answer synthesis

**What it does:**
1. Creates knowledge base with multiple indices
2. Defines data agents with selective access
3. Implements agentic retrieval pattern
4. Synthesizes answers from retrieved documents
5. Runs multi-agent conversation scenarios

**Architecture:**
```
Knowledge Base (3 indices)
├── policies-kb (product/company policies)
├── procedures-kb (operational workflows)
└── compliance-kb (regulatory & legal)

Data Agents (selective access)
├── Customer Service Agent → policies-kb, procedures-kb
├── Fulfillment Agent → procedures-kb
└── Compliance Agent → compliance-kb, policies-kb
```

**Steps:**

**Step 1: Knowledge Base Setup**
- Upload documents to 3 specialized indices
- Organize by domain (policies, procedures, compliance)

**Step 2: Data Agent Definition**
- Create agent classes with RBAC policies
- Define authorized indices per agent
- Implement query isolation

**Step 3: Agentic Retrieval**
- Agents query only authorized indices
- Retrieve relevant documents
- Rank by relevance score

**Step 4: Answer Synthesis**
- Format retrieved documents
- Generate conversational summaries
- Attribute information to sources

**Step 5: Multi-Agent Conversations**
- Support multi-turn interactions
- Track conversation context
- Implement conversation memory

**Step 6: Demo Scenarios**
- Query 1: "What is our return policy?" → Customer Service Agent
- Query 2: "How do we process orders?" → Fulfillment Agent
- Query 3: "What are compliance requirements?" → Compliance Agent
- Query 4: Cross-agent collaborative query

**Prerequisites:**
- Completed Notebooks 05 & 06
- Azure Search indices created and populated
- RBAC configured

**Key classes:**
- `DataAgent`: Core agent with KB access
- `AnswerSynthesizer`: Formats and summarizes results
- `ConversationMemory`: Tracks multi-turn context

**Expected output:**
```
✅ Uploaded 50 documents to policies-kb
✅ Uploaded 40 documents to procedures-kb
✅ Uploaded 30 documents to compliance-kb
✅ Created 3 data agents
✅ Query results: Customer Service (5 docs), Fulfillment (3 docs)
✅ Synthesis: "Based on our policies, returns are accepted within..."
```

**Concepts demonstrated:**
- Multi-agent knowledge bases
- Role-based access control (agent-level)
- Answer synthesis and summarization
- Conversation management

**Next steps:** Run Notebook 08 for Agent Framework integration

---

### Notebook 08: agent-framework-foundry.ipynb ⭐ LATEST

**Duration:** 30-40 minutes  
**Purpose:** Production-ready agents with Microsoft Agent Framework

**What it does:**
1. Deploys Foundry infrastructure via Bicep
2. Initializes Microsoft Agent Framework
3. Creates production-ready agents
4. Implements RBAC enforcement
5. Validates security boundaries
6. Orchestrates multi-agent workflows

**Architecture:**
```
User Input
    ↓
Agent Framework (Chat Client)
    ↓
Foundry Agent (4 specialized agents)
    ├─ Customer Service Agent
    ├─ Fulfillment Agent
    ├─ Compliance Agent
    └─ Regional APAC Agent
    ↓
RBAC Enforcement Layer
    ├─ Index-level access control
    ├─ Denied index blocking
    └─ Access logging
    ↓
Azure AI Search (with RBAC)
    ├─ agents-us
    ├─ agents-apac
    └─ agents-us-secure
```

**Steps:**

**Step 1: Deploy Foundry Resources**
- Creates Azure AI Foundry (AIServices kind)
- Provisions AI Project with separate identity
- Deploys models (gpt-4o, text-embedding-3-large)
- Configures storage with RBAC

**Step 2: Initialize Agent Framework**
- Loads Azure OpenAI or OpenAI configuration
- Initializes chat and embeddings clients
- Sets up agent framework configuration

**Step 3: Configure Search Connections**
- Establishes connections to all indices
- Handles RBAC authentication (or falls back to admin key)
- Verifies index accessibility

**Step 4: Implement RBAC for Search**
- Defines agent RBAC policies
- Specifies authorized/denied indices per agent
- Shows enforcement configuration

**Step 5: Create Foundry Agents**
- Builds agent classes with RBAC enforcement
- Creates 4 specialized agents
- Initializes agent tools

**Step 6: Define Agent Tools**
- `search_knowledge_base(agent_name, query, index)`
- `get_knowledge_base_info(agent_name)`
- `list_agent_queries(agent_name)`

**Step 7: Test Agent Interactions**
- 5 success scenarios (authorized queries)
- Multi-agent collaboration
- Cross-index access patterns

**Step 8: Validate RBAC Enforcement**
- 4 unauthorized access tests
- Verify denied indices are blocked
- Confirm access denial responses

**Prerequisites:**
- Completed Notebooks 05-07
- Microsoft Agent Framework: `pip install agent-framework --pre`
- Azure OpenAI or OpenAI configured

**Key classes:**
- `RBACEnforcingSearchClient`: Wraps Search SDK with policy enforcement
- `FoundryAgent`: Agent with blueprint RBAC integration
- Agent tools for KB queries and history

**Expected output:**
```
Step 1:
✅ Foundry infrastructure deployed
✅ AI Project created with identity
✅ Models deployed: gpt-4o, text-embedding-3-large

Step 3:
✅ Connected to 3/3 indices (RBAC or Admin Key)

Step 5:
✅ Created 4 Foundry agents with blueprint RBAC

Step 7:
Scenario 1: Customer Service Agent - Authorized Query
✅ Found 3 documents
- Return Policy (Score: 0.95)
- Customer Guarantees (Score: 0.87)

Step 8:
Unauthorized Access Attempts: 4
Correctly DENIED: 4
✅ RBAC Enforcement Status: VALID
```

**Agent capability matrix:**
```
Agent Name              | Authorized Indices
─────────────────────────────────────────────
Customer Service        | agents-us, agents-apac
Fulfillment             | agents-us
Compliance              | agents-apac, agents-us-secure
Regional APAC          | agents-apac
```

**Configuration persistence:**
- `foundry-config.json`: Foundry and search endpoints
- `.env`: LLM and storage configuration

**Next steps:** Deploy agents to production (Azure Container Instances, Functions, or Copilot Studio)

---

## Execution Guide

### Running a Single Notebook

```bash
# Launch Jupyter
jupyter lab

# Open notebook file and run cells in order
# - Click cell
# - Press Shift+Enter to execute
# - Review output before proceeding
```

### Running Multiple Notebooks in Sequence

```bash
# 1. Open first notebook
jupyter lab 01-validate-configuration.ipynb

# 2. Run all cells (Kernel > Run All Cells)
# 3. Verify output
# 4. Close notebook
# 5. Open next notebook
# 6. Repeat

# Or run via command line
jupyter nbconvert --to notebook --execute --inplace 05-azure-infra-setup.ipynb
```

### Handling Errors

**If a cell fails:**
1. Read the error message carefully
2. Check if it's a missing module: `pip install <module>`
3. Check if it's an auth error: Re-run Notebook 01
4. Check if it's an Azure error: Verify permissions
5. Refer to [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md)

**If you need to restart:**
```python
# In a Jupyter cell:
import sys
import importlib

# Reload modules
importlib.reload(sys.modules['azure.search.documents'])
importlib.reload(sys.modules['azure.identity'])

# Or restart kernel: Kernel > Restart Kernel
```

### Best Practices

✅ **Do:**
- Run cells in order top-to-bottom
- Save `.env` locally (don't commit)
- Review outputs after each cell
- Take notes on key values (endpoint, principal IDs)
- Backup `foundry-config.json`

❌ **Don't:**
- Skip cells or run out of order
- Commit `.env` or secrets
- Modify Bicep templates without understanding
- Share API keys or service principal secrets
- Run multiple notebooks simultaneously (state conflicts)

---

## Troubleshooting Notebooks

Common issues and solutions:

| Issue | Cause | Solution |
|-------|-------|----------|
| Module not found | Missing dependency | `pip install -r requirements.txt` |
| Auth failed | Missing/expired credentials | Re-run Notebook 01 |
| Bicep deploy failed | Invalid parameters | Check `foundry-deployment-params.json` |
| RBAC not working | Role propagation delay | Wait 1-2 minutes and retry |
| Search connection timeout | Network/firewall | Check Azure Portal connectivity |
| LLM not configured | Missing API key | Add to `.env` and reload |

---

## References

- [Microsoft Entra Agent Identity Platform](https://learn.microsoft.com/en-us/entra/agent-id/identity-platform/)
- [Azure AI Search Documentation](https://learn.microsoft.com/en-us/azure/search/)
- [Microsoft Agent Framework](https://github.com/microsoft/agent-framework)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Python SDK Documentation](https://learn.microsoft.com/python/api/)
