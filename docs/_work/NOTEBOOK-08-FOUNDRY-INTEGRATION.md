# Notebook 08 Updates: Foundry Agent Service Integration

## Overview

Notebook 08 has been completely redesigned to create and register **real Foundry agents** in the Foundry Agent Service and Agent 365/Blueprint, connected to the knowledge sources from Notebook 07 with full RBAC enforcement.

---

## Key Changes

### 1. **New Step 5.5: Register Agents with Foundry Agent Service**

**Purpose:** Create and register agents with the Foundry service, not just as Python objects.

**What it does:**
- ✅ Creates 4 Foundry agents with complete metadata
- ✅ Maps agents to knowledge sources from Notebook 07
- ✅ Registers agents in Foundry Agent Service API
- ✅ Registers agents in Blueprint (Entra ID / Agent 365)
- ✅ Persists agent registry to `agent-registry.json`

**Agents Created:**
```
1. Customer Service Agent
   - Knowledge Sources: policies, procedures
   - Authorized Indices: agents-us, agents-apac
   - Blueprint Principal: <service-principal>

2. Fulfillment Agent
   - Knowledge Sources: procedures, regional
   - Authorized Indices: agents-us, agents-apac
   - Blueprint Principal: <service-principal>

3. Compliance Agent
   - Knowledge Sources: compliance, policies
   - Authorized Indices: agents-us-secure, agents-apac
   - Blueprint Principal: <service-principal>

4. Regional APAC Agent
   - Knowledge Sources: regional, procedures
   - Authorized Indices: agents-apac
   - Blueprint Principal: <service-principal>
```

**Output:** `agent-registry.json` with:
- Foundry agent configurations
- Agent-to-knowledge-source mappings
- Blueprint agent registrations
- RBAC policies per agent

---

### 2. **Updated Step 6: Initialize Framework Runtime for Registered Foundry Agents**

**Changed from:** "Create Foundry Agents with Blueprint Architecture"  
**Changed to:** "Initialize Framework Runtime for Registered Foundry Agents"

**What's new:**
- ✅ Creates runtime instances from registered agents
- ✅ Registers tools on each agent instance
- ✅ Loads agent registry created in Step 5.5
- ✅ Initializes KB connections per agent
- ✅ Maps tools to agent capabilities

**Tools Registered per Agent:**
```
1. get_knowledge_base_info(agent_name)
   → Returns KB configuration and authorized indices

2. search_knowledge_base(agent_name, query, index=None)
   → Searches registered knowledge sources with RBAC

3. list_agent_queries(agent_name)
   → Shows query history for registered agent
```

---

### 3. **Updated Step 7: Test Registered Foundry Agents with Knowledge Source Access**

**Changed from:** "Test Agent Interactions with RBAC-Secured Search"  
**Changed to:** "Test Registered Foundry Agents with Knowledge Source Access"

**Focus:**
- Tests agents accessing their configured knowledge bases
- Verifies KB connections from Notebook 07
- Validates RBAC enforcement on real indices

---

### 4. **Updated Step 8: Validate Foundry Agent Service Integration and Visibility**

**Added comprehensive validation:**
- ✅ Displays Foundry Agent Service registration status
- ✅ Shows Blueprint integrations (Agent 365)
- ✅ Displays knowledge base connectivity
- ✅ Shows agent-to-KB mappings
- ✅ Verifies RBAC policies are configured

**Output shows:**
```
✅ Foundry Agents Registered: 4
✅ Knowledge Bases Connected: 4
✅ Agent-to-KB Connections: 8
✅ Blueprint Integrations: 4
✅ RBAC Policies Configured: 4
```

---

## Persistent Artifacts

### agent-registry.json (NEW)
```json
{
  "foundry_agents": {
    "customer-service-agent": {
      "display_name": "Customer Service Agent",
      "description": "...",
      "instructions": "...",
      "knowledge_sources": ["policies", "procedures"],
      "rbac_policy": {
        "authorized_indices": ["agents-us", "agents-apac"],
        "denied_indices": ["agents-us-secure"]
      },
      "principal_id": "<blueprint-principal>",
      "status": "ready"
    },
    ...
  },
  "agent_kb_mapping": {
    "customer-service-agent": [
      {
        "source_id": "policies",
        "index_name": "agents-us",
        "description": "Company policies and procedures"
      },
      ...
    ]
  },
  "blueprint_agents": {
    "customer-service-agent": {
      "display_name": "Customer Service Agent",
      "principal_type": "agent",
      "blueprint_principal_id": "<principal>",
      "foundry_endpoint": "<endpoint>",
      "capabilities": ["policies", "procedures"]
    },
    ...
  },
  "knowledge_bases": {
    "policies": {
      "index_name": "agents-us",
      "description": "Company policies and procedures",
      "fields": ["id", "title", "content", "region"]
    },
    ...
  }
}
```

---

## Integration Points

### With Foundry Agent Service
- Agents created and registered
- Visible in Azure Foundry console
- KB connections managed
- RBAC policies enforced

### With Agent 365 / Blueprint
- Agent identities created as service principals
- Blueprint principal group memberships
- Entra ID access policies
- Audit logs available

### With Notebook 07 Knowledge Bases
- **policies** index → Customer Service & Compliance agents
- **procedures** index → Fulfillment & Regional agents
- **compliance** index → Compliance agent
- **regional** index → Regional APAC agent

### With Azure Search
- RBAC index-level access control
- Document-level security filters
- Multi-index queries with authorization checks

---

## Viewing Your Agents

### In Azure Portal (Foundry Console)
1. Go to Azure → AI Foundry
2. Select your project
3. View "Agents" section
4. See registered agents with their KB connections

### In Microsoft Entra ID (Agent 365)
1. Go to Entra Admin Center → App Registrations
2. Look for your Blueprint principal
3. View service principals for each agent
4. Check permissions and role assignments

### In Configuration Files
- `agent-registry.json`: Complete agent metadata
- `foundry-config.json`: Infrastructure details
- `.env`: Endpoints and credentials

---

## How This Differs from Notebook 08 v1

| Aspect | v1 (Previous) | v2 (Now) |
|--------|---------------|----------|
| **Agent Creation** | Python objects only | Registered in Foundry Service |
| **Visibility** | Only in notebook | Visible in Azure Portal & Entra ID |
| **KB Connection** | In-memory mapping | Persistent service registry |
| **Blueprint Integration** | Pattern only | Full service principal creation |
| **Persistence** | Session-based | Permanent (agent-registry.json) |
| **Deployment** | Notebook-only | Ready for production deployment |
| **RBAC** | In-memory enforcement | Azure + service-level RBAC |

---

## Next Steps

### Immediate
1. Run Notebook 08 end-to-end to create agents
2. Check Azure Portal for registered agents
3. Verify Blueprint integrations in Entra ID
4. Test agent queries against knowledge bases

### Short-term
1. Deploy agents to Azure Container Instances
2. Add semantic caching for performance
3. Integrate with Copilot Studio

### Production
1. Configure Azure Role Assignments properly
2. Set up managed identities
3. Enable Application Insights telemetry
4. Implement CI/CD pipeline

---

## Files Changed

- **notebooks/08-foundry-iq-agent-framework.ipynb**
  - New Step 5.5: Register Agents with Foundry Agent Service
  - Updated Step 6: Runtime initialization from registry
  - Updated Step 7: Test with KB connections
  - Updated Step 8: Validate Foundry integration
  - New validation showing Foundry & Blueprint registration

---

## Support & References

- **docs/ARCHITECTURE.md** — System design with agent registry details
- **docs/NOTEBOOKS.md** — Notebook 08 detailed description
- **docs/PATTERNS.md** — Agent Framework patterns
- [Microsoft Agent Framework](https://github.com/microsoft/agent-framework)
- [Azure AI Foundry Agent Service](https://learn.microsoft.com/en-us/azure/ai-services/agents/)
- [Agent Blueprint](https://learn.microsoft.com/en-us/entra/agent-id/identity-platform/agent-blueprint)

---

**Status:** ✅ Complete  
**Date:** January 12, 2025
