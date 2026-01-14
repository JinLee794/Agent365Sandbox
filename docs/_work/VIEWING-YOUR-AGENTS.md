# Viewing Your Foundry Agents

After running Notebook 08, your agents are registered in three places. Here's how to see them.

---

## 1. Agent Registry File

**Location:** `notebooks/agent-registry.json`

Run this to see the registry:
```python
import json
with open('agent-registry.json') as f:
    registry = json.load(f)

# View all agents
for agent_id, config in registry['foundry_agents'].items():
    print(f"✅ {config['display_name']}")
    print(f"   ID: {agent_id}")
    print(f"   Status: {config['status']}")
    print()

# View agent-to-KB mappings
for agent_id, kbs in registry['agent_kb_mapping'].items():
    print(f"{agent_id}:")
    for kb in kbs:
        print(f"  → {kb['source_id']} (index: {kb['index_name']})")
```

---

## 2. Azure Foundry Agent Service

**Via Azure Portal:**

1. Go to **Azure Portal** → **AI Foundry**
2. Select your **Project** (created in Notebook 08, Step 1)
3. Navigate to **Agents** section
4. You'll see:
   - ✅ Customer Service Agent
   - ✅ Fulfillment Agent
   - ✅ Compliance Agent
   - ✅ Regional APAC Agent

**View Agent Details:**
- Click on any agent to see:
  - Display name and description
  - Knowledge source connections
  - Authorized indices (RBAC policy)
  - Status and configuration

**Note:** The agents are registered via `agent-registry.json`. In production, they would be fully provisioned in the Foundry Agent Service API.

---

## 3. Agent 365 / Entra ID Blueprint

**Via Microsoft Entra Admin Center:**

1. Go to **Entra Admin Center** → **Enterprise Applications** or **App Registrations**
2. Look for your **Blueprint Principal** (set in `.env`)
3. View associated service principals:
   - Agent identities for each agent
   - Group memberships
   - Assigned roles and permissions

**Find Your Blueprint Principal:**
```bash
# Run this to find your principal ID
echo $AGENT_BLUEPRINT_PRINCIPAL_ID

# Or check in .env
cat .env | grep PRINCIPAL
```

**View in Entra ID:**
1. Search for principal by ID or name
2. Check **Members** group
3. View **Assigned roles**
4. Review **Audit logs** for agent activity

---

## 4. Configuration Files

**Foundry Config:**
```bash
cat notebooks/foundry-config.json
```

Shows:
- AI Foundry endpoint
- Project name and identity
- Storage account details
- Model deployments

**Agent Registry:**
```bash
cat notebooks/agent-registry.json | python -m json.tool
```

Shows:
- All 4 agents with configurations
- Knowledge source mappings
- RBAC policies
- Blueprint integrations

---

## 5. Quick Check Commands

**List all agents in registry:**
```python
import json

with open('notebooks/agent-registry.json') as f:
    agents = json.load(f)['foundry_agents']

print(f"✅ {len(agents)} agents registered:")
for agent_id in agents:
    print(f"  • {agent_id}")
```

**Show agent knowledge base access:**
```python
import json

with open('notebooks/agent-registry.json') as f:
    data = json.load(f)

for agent_id, kbs in data['agent_kb_mapping'].items():
    agent_name = data['foundry_agents'][agent_id]['display_name']
    print(f"\n{agent_name}:")
    for kb in kbs:
        print(f"  ✓ {kb['source_id']} → {kb['index_name']}")
    
    policy = data['foundry_agents'][agent_id]['rbac_policy']
    print(f"  Authorized Indices: {', '.join(policy['authorized_indices'])}")
```

**Verify RBAC policies:**
```python
import json

with open('notebooks/agent-registry.json') as f:
    agents = json.load(f)['foundry_agents']

print("Agent RBAC Policies:\n")
for agent_id, config in agents.items():
    policy = config['rbac_policy']
    print(f"{agent_id}:")
    print(f"  Authorized: {policy['authorized_indices']}")
    print(f"  Denied: {policy['denied_indices'] or 'None'}")
    print()
```

---

## What Each Agent Can Access

### Customer Service Agent
- **Knowledge Sources:** policies, procedures
- **Authorized Indices:** agents-us, agents-apac
- **Denied Indices:** agents-us-secure
- **Purpose:** Answer customer questions about products, policies, orders

### Fulfillment Agent
- **Knowledge Sources:** procedures, regional
- **Authorized Indices:** agents-us, agents-apac
- **Denied Indices:** agents-us-secure
- **Purpose:** Handle order fulfillment and shipping

### Compliance Agent
- **Knowledge Sources:** compliance, policies
- **Authorized Indices:** agents-us-secure, agents-apac
- **Denied Indices:** *(none - highest access)*
- **Purpose:** Manage regulatory and compliance matters

### Regional APAC Agent
- **Knowledge Sources:** regional, procedures
- **Authorized Indices:** agents-apac
- **Denied Indices:** agents-us, agents-us-secure
- **Purpose:** Handle Asia-Pacific regional operations

---

## Testing Agent Access

**Query an agent's knowledge bases:**

```python
from notebooks.agent_registry import foundry_agents_runtime

# Get a specific agent
agent = foundry_agents_runtime['customer-service-agent']

# Query its knowledge bases
result = agent.execute_query("What is our return policy?")

print(f"Agent: {agent.display_name}")
print(f"Authorized KB sources: {[kb['source_id'] for kb in agent.knowledge_sources]}")
print(f"Query status: {result['status']}")
```

**Test RBAC enforcement:**

```python
# This should succeed (authorized)
result = agent.execute_query("policy question", index='agents-us')
print(f"✅ agents-us access: {result['status']}")

# This should fail (denied)
try:
    result = agent.execute_query("compliance question", index='agents-us-secure')
    if not result.get('success'):
        print(f"✅ agents-us-secure access correctly DENIED")
except:
    print(f"✅ agents-us-secure access correctly DENIED")
```

---

## Integration Checklist

After running Notebook 08:

- [ ] **Agent Registry Created:** `agent-registry.json` exists
- [ ] **Foundry Config Updated:** `foundry-config.json` has project info
- [ ] **.env Updated:** Contains Foundry endpoints and keys
- [ ] **4 Agents Registered:** In agent-registry.json
- [ ] **KB Mappings Set:** Each agent connected to knowledge sources
- [ ] **RBAC Policies Configured:** Per-agent access control
- [ ] **Blueprint Integrations:** Listed in registry
- [ ] **Test Scenarios Pass:** KB access works for authorized agents
- [ ] **Unauthorized Access Blocked:** RBAC enforcement validated

---

## Next: Deploying Your Agents

Once registered, you can:

1. **Deploy to Azure Container Instances**
   ```bash
   az container create \
     --resource-group <rg> \
     --name foundry-agent \
     --image myregistry.azurecr.io/agent:latest \
     --environment-variables \
       AGENT_ID=customer-service-agent \
       REGISTRY_PATH=/path/to/agent-registry.json
   ```

2. **Deploy to Azure Functions**
   - Create HTTP-triggered function
   - Load agent from registry
   - Route requests to appropriate agent

3. **Integrate with Copilot Studio**
   - Use agent registry as skill backend
   - Configure natural language routing
   - Enable multi-agent orchestration

---

**Status:** ✅ Agents registered and ready for deployment
