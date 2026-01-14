# Quick Reference: Notebook 08 Agents

## The 4 Foundry Agents

### 1. Customer Service Agent 🎧
```
ID: customer-service-agent
Status: Registered in Foundry & Blueprint

Knowledge Sources:
  ✓ policies (agents-us index)
  ✓ procedures (agents-us index)

Authorized Indices:
  ✓ agents-us
  ✓ agents-apac
  ✗ agents-us-secure (DENIED)

Purpose: 
  Answer customer questions about products, 
  policies, returns, and orders
```

### 2. Fulfillment Agent 📦
```
ID: fulfillment-agent
Status: Registered in Foundry & Blueprint

Knowledge Sources:
  ✓ procedures (agents-us index)
  ✓ regional (agents-apac index)

Authorized Indices:
  ✓ agents-us
  ✓ agents-apac
  ✗ agents-us-secure (DENIED)

Purpose:
  Handle order fulfillment, shipping,
  and warehouse operations
```

### 3. Compliance Agent ⚖️
```
ID: compliance-agent
Status: Registered in Foundry & Blueprint

Knowledge Sources:
  ✓ compliance (agents-us-secure index)
  ✓ policies (agents-us index)

Authorized Indices:
  ✓ agents-us-secure (HIGHEST ACCESS)
  ✓ agents-apac

Purpose:
  Manage regulatory requirements,
  compliance policies, and legal matters
```

### 4. Regional APAC Agent 🌏
```
ID: regional-apac-agent
Status: Registered in Foundry & Blueprint

Knowledge Sources:
  ✓ regional (agents-apac index)
  ✓ procedures (agents-us index)

Authorized Indices:
  ✓ agents-apac
  ✗ agents-us (DENIED)
  ✗ agents-us-secure (DENIED)

Purpose:
  Handle Asia-Pacific regional operations
  and regional-specific requests
```

---

## Where Are Your Agents?

### ✅ In agent-registry.json
```bash
# View complete agent registry
cat notebooks/agent-registry.json | python -m json.tool
```

### ✅ In Azure Portal (Foundry)
1. Azure → AI Foundry
2. Select your project
3. Click "Agents"
4. See all 4 agents listed

### ✅ In Entra ID (Agent 365)
1. Entra Admin Center
2. Find your Blueprint Principal
3. View member agents
4. Check role assignments

### ✅ In Configuration
- **agent-registry.json** — Agent metadata
- **foundry-config.json** — Infrastructure
- **.env** — Endpoints & credentials

---

## Quick Commands

### List All Agents
```python
import json
with open('notebooks/agent-registry.json') as f:
    agents = json.load(f)['foundry_agents']
    
for agent_id in agents:
    name = agents[agent_id]['display_name']
    status = agents[agent_id]['status']
    print(f"✅ {name} ({agent_id}) - {status}")
```

### Show Agent KB Access
```python
import json
with open('notebooks/agent-registry.json') as f:
    data = json.load(f)
    
for agent_id, kbs in data['agent_kb_mapping'].items():
    agent = data['foundry_agents'][agent_id]
    print(f"\n{agent['display_name']}:")
    for kb in kbs:
        print(f"  → {kb['source_id']} (index: {kb['index_name']})")
```

### Check RBAC Policies
```python
import json
with open('notebooks/agent-registry.json') as f:
    agents = json.load(f)['foundry_agents']
    
for agent_id, agent in agents.items():
    policy = agent['rbac_policy']
    print(f"{agent_id}:")
    print(f"  Authorized: {', '.join(policy['authorized_indices'])}")
    print(f"  Denied: {', '.join(policy['denied_indices']) or 'None'}")
```

---

## Agent → Index Access Matrix

```
                    agents-us  agents-apac  agents-us-secure
Customer Service      ✓          ✓             ✗
Fulfillment          ✓          ✓             ✗
Compliance           ✓          ✓             ✓
Regional APAC        ✗          ✓             ✗
```

## Knowledge Source Coverage

```
policies (agents-us)
  ↓
  Used by: Customer Service, Compliance

procedures (agents-us)
  ↓
  Used by: Customer Service, Fulfillment, Regional APAC

compliance (agents-us-secure)
  ↓
  Used by: Compliance (only)

regional (agents-apac)
  ↓
  Used by: Fulfillment, Regional APAC
```

---

## Key Files

| File | Content | Action |
|------|---------|--------|
| `agent-registry.json` | All agent configs & KB mappings | View with JSON tool |
| `foundry-config.json` | Foundry infrastructure details | Check endpoints |
| `.env` | Updated with Foundry credentials | Source in shell |
| `08-foundry-iq-agent-framework.ipynb` | Complete notebook with all steps | Run end-to-end |

---

## Running Notebook 08

```bash
cd notebooks
jupyter lab 08-foundry-iq-agent-framework.ipynb
```

**Steps:**
1. Run all cells in order
2. Step 5.5 creates agent-registry.json
3. Step 8 validates all 4 agents registered
4. Check Azure Portal and Entra ID

---

## Testing Agent Access

### Authorized Query
```python
# This should work ✅
result = customer_service_agent.execute_query(
    "What is the return policy?",
    index="agents-us"
)
```

### Unauthorized Query  
```python
# This should FAIL ✅
result = customer_service_agent.execute_query(
    "Compliance info",
    index="agents-us-secure"  # DENIED
)
```

---

## Integration Status

✅ **Registered in Foundry Agent Service**
✅ **Registered in Blueprint (Agent 365)**
✅ **Connected to Knowledge Bases (Notebook 07)**
✅ **RBAC Policies Configured**
✅ **Tools Enabled**
✅ **Ready for Deployment**

---

## Next Steps

1. **View in Portal** — Check Foundry Agent console
2. **Test Queries** — Run agent queries against KBs
3. **Deploy** — Container Instances or Functions
4. **Monitor** — Application Insights telemetry

---

**Agents Created:** 4  
**Knowledge Bases Connected:** 4  
**RBAC Policies:** 4  
**Blueprint Integrations:** 4  
**Status:** ✅ Ready
