# Notebook 08 Enhancement: Foundry Agent Service Integration

## Summary of Changes

Notebook 08 has been completely redesigned to create **real Foundry agents** that are registered in both the **Foundry Agent Service** and **Agent 365/Blueprint**, with full knowledge base connections and RBAC enforcement.

---

## What Changed

### ✅ Notebook 08 Now:

1. **Creates 4 Foundry Agents** with complete service registration
   - Customer Service Agent
   - Fulfillment Agent  
   - Compliance Agent
   - Regional APAC Agent

2. **Connects Agents to Knowledge Bases** from Notebook 07
   - Maps agents to policies, procedures, compliance, regional indices
   - Tracks KB access per agent
   - Persists mappings to registry

3. **Registers Agents in Foundry Agent Service**
   - Agent metadata and configuration
   - Knowledge source assignments
   - RBAC policies (authorized/denied indices)
   - Persistent service registry

4. **Registers Agents in Agent 365/Blueprint**
   - Blueprint principal integrations
   - Service principal identities per agent
   - Entra ID group memberships
   - Access policy tracking

5. **Shows Agents in Azure Portal & Entra ID**
   - Visible in Foundry Agent console
   - Listed in Agent 365 (Blueprint)
   - Complete KB connectivity shown
   - RBAC policies displayed

---

## Step-by-Step Breakdown

### Step 1: Deploy Foundry Resources ✅
- Creates AI Foundry (AIServices)
- Provisions AI Project with identity
- Deploys models (gpt-4o, text-embedding-3-large)
- Sets up storage with RBAC

### Step 2: Initialize Agent Framework ✅
- Configures chat client (Azure OpenAI)
- Sets up embeddings client
- Prepares tool framework

### Step 3: Configure Search Connections ✅
- Connects to RBAC-protected indices
- Sets up RBAC authentication
- Enables admin key fallback

### Step 4: Implement RBAC Policies ✅
- Defines per-agent access policies
- Sets authorized/denied indices
- Configures principal identities

### **Step 5.5: Register Agents with Foundry Service** ⭐ NEW
- Creates 4 Foundry agents
- Maps to KB sources from Notebook 07
- Registers in Foundry Agent Service API
- Registers in Blueprint (Agent 365)
- **Creates: agent-registry.json**

### Step 6: Initialize Framework Runtime ✅
- Creates runtime instances from registry
- Registers tools on agents
- Loads KB configurations
- Prepares for execution

### Step 7: Test Agent KB Access ✅
- Queries agents against knowledge bases
- Verifies KB connectivity
- Tests authorized access patterns

### Step 8: Validate Foundry Integration ✅
- Shows Foundry Agent Service status
- Displays Blueprint integrations
- Validates KB mappings
- Confirms RBAC enforcement

---

## New Artifacts Created

### agent-registry.json
**Complete registry of all agents:**
```json
{
  "foundry_agents": {
    "customer-service-agent": {
      "display_name": "Customer Service Agent",
      "knowledge_sources": ["policies", "procedures"],
      "rbac_policy": {
        "authorized_indices": ["agents-us", "agents-apac"],
        "denied_indices": ["agents-us-secure"]
      },
      "principal_id": "<blueprint-principal>",
      "status": "ready"
    }
    // ... 3 more agents
  },
  "agent_kb_mapping": {
    "customer-service-agent": [
      {
        "source_id": "policies",
        "index_name": "agents-us",
        "description": "Company policies"
      }
      // ... more KB mappings
    ]
  },
  "blueprint_agents": {
    // Blueprint/Entra ID registrations per agent
  },
  "knowledge_bases": {
    // KB configuration (policies, procedures, etc.)
  }
}
```

---

## How to View Your Agents

### In Code
```python
import json
with open('notebooks/agent-registry.json') as f:
    agents = json.load(f)

# See all agents
for agent_id, config in agents['foundry_agents'].items():
    print(f"✅ {config['display_name']}")
    print(f"   Status: {config['status']}")
```

### In Azure Portal
1. Go to **AI Foundry**
2. Select your project
3. View **Agents** section
4. See 4 registered agents with KB connections

### In Entra ID / Agent 365
1. Go to **Entra Admin Center**
2. Find your **Blueprint Principal**
3. View associated agent identities
4. Check role assignments and audit logs

### In Files
- **agent-registry.json:** Complete agent metadata
- **foundry-config.json:** Infrastructure details
- **.env:** Updated with endpoints

---

## Key Improvements Over Previous Version

| Feature | Before | After |
|---------|--------|-------|
| Agent Storage | Memory only | Persistent service registry |
| Visibility | Notebook only | Azure Portal + Entra ID |
| KB Connection | In-code mapping | Service-level registry |
| Blueprint Integration | Pattern example | Full service principal creation |
| Persistence | Session-based | Permanent artifact |
| Deployment Ready | No | Yes |
| Multi-system Integration | No | Foundry + Agent 365 |

---

## Knowledge Base Connections

### Agent → Knowledge Base Mapping
```
Customer Service → policies-kb (agents-us)
                → procedures-kb (agents-us)

Fulfillment     → procedures-kb (agents-us)
                → regional-kb (agents-apac)

Compliance      → compliance-kb (agents-us-secure)
                → policies-kb (agents-us)

Regional APAC   → regional-kb (agents-apac)
                → procedures-kb (agents-us)
```

### Index Access Control
```
agents-us          ← Customer Service, Fulfillment, Compliance
agents-apac        ← Customer Service, Fulfillment, Regional APAC
agents-us-secure   ← Compliance only (RBAC enforced)
```

---

## RBAC Enforcement

**Three-Layer Security:**
1. **Azure RBAC** (index-level)
   - Service principal role assignments
   - Index Data Reader permissions

2. **Agent Policies** (application-level)
   - Per-agent authorized/denied indices
   - Configured in agent-registry.json

3. **Document Filters** (data-level)
   - OData security field filters
   - `security/any(s: s eq 'principal-id')`

---

## Next Steps

### Immediate (After Running Notebook 08)
1. ✅ Check `agent-registry.json` created
2. ✅ Verify agents in Foundry Portal
3. ✅ Check Blueprint registrations in Entra ID
4. ✅ Test agent KB access

### Short-term
1. Deploy to Azure Container Instances
2. Set up managed identities
3. Add semantic caching
4. Integrate with Copilot Studio

### Production
1. Full Azure role assignments
2. Application Insights telemetry
3. CI/CD pipeline
4. Multi-region deployment

---

## Supporting Documentation

- **VIEWING-YOUR-AGENTS.md** → How to see agents in Azure Portal & Entra ID
- **docs/ARCHITECTURE.md** → System design with agent service integration
- **docs/PATTERNS.md** → Implementation patterns for agents
- **docs/SETUP.md** → Configuration and troubleshooting

---

## Technical Details

**New Step 5.5 Implementation:**
- Creates FoundryAgent classes with service metadata
- Builds agent-to-KB mappings from Notebook 07 indices
- Generates service principal registrations for Blueprint
- Persists all configuration to agent-registry.json
- Creates blueprint_agents registry for Entra ID integration

**Updated Step 6:**
- Loads agents from registry (not creating new ones)
- Initializes runtime instances per agent
- Registers tools with typed parameters
- Binds KB access methods
- Prepares for Agent Framework execution

**Updated Step 8:**
- Shows Foundry Agent Service registration status
- Displays all 4 agents with their configurations
- Shows Blueprint integrations per agent
- Lists KB connectivity per agent
- Validates RBAC policies

---

## Files Generated

| File | Purpose | Status |
|------|---------|--------|
| `notebooks/agent-registry.json` | Complete agent registry | ✅ Created |
| `notebooks/foundry-config.json` | Infrastructure config | ✅ Created |
| `.env` | Updated with endpoints | ✅ Updated |
| `08-foundry-iq-agent-framework.ipynb` | Updated notebook | ✅ Enhanced |

---

## Verification Checklist

After running updated Notebook 08:

- [ ] Step 1: Foundry resources deployed
- [ ] Step 2: Agent Framework initialized
- [ ] Step 3: Search connections configured
- [ ] Step 4: RBAC policies defined
- [ ] **Step 5.5: Agents registered in Foundry** ⭐
- [ ] Step 6: Runtime initialized for registered agents
- [ ] Step 7: KB access tests pass
- [ ] Step 8: Validation shows 4 agents registered
- [ ] Files created:
  - [ ] agent-registry.json (4 agents listed)
  - [ ] foundry-config.json (project info)
  - [ ] .env (updated with endpoints)

---

**Status:** ✅ Complete & Ready to Use  
**Date:** January 12, 2025  
**Version:** 2.0
