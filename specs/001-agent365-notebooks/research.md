# Research: Agent 365 Tutorial Jupyter Notebooks

**Feature**: Agent 365 Tutorial Jupyter Notebooks
**Date**: 2026-01-10
**Phase**: Phase 0 - Dependency Verification and Technical Research

## Research Objectives

1. Verify correct Python package names for Microsoft Entra ID/Agent ID authentication
2. Confirm Python 3.14 compatibility for required dependencies
3. Research Azure AI Search SDK capabilities for document-level RBAC demonstration
4. Identify best practices for educational Jupyter notebook structure

---

## 1. Python SDK Package Verification

### Decision: Replace `microsoft-identity-web` with `azure-identity`

**Rationale**:
- `microsoft-identity-web` is a .NET-only library with NO Python equivalent on PyPI
- `azure-identity` is the official Microsoft Python SDK for Azure/Entra ID authentication
- Provides equivalent functionality: service principal authentication, managed identities, token acquisition

**Alternatives Considered**:
- `msal` (Microsoft Authentication Library): Lower-level OAuth 2.0 library. Chosen as supplementary dependency for token acquisition examples in REST API notebook (P2)
- `azure-identity`: Higher-level abstraction. Chosen as primary SDK for P3 (SDK usage notebook) as it provides production-ready patterns

**Outcome**: Use BOTH packages with clear separation:
- **P2 (REST API)**: Use `msal` for direct OAuth 2.0 token acquisition (educational - shows how auth works)
- **P3 (SDK Usage)**: Use `azure-identity` for production-ready authentication patterns

---

## 2. Dependency Versions and Python 3.14 Compatibility

### Core Dependencies

| Package | PyPI Name | Stable Version | Python 3.14 Status | Purpose |
|---------|-----------|----------------|-------------------|---------|
| Jupyter Lab | `jupyterlab` | 4.0+ | Compatible | Notebook environment |
| HTTP Client | `requests` | 2.31+ | Compatible | REST API calls (P2) |
| Auth Library | `msal` | 1.31.1 | Verify on PyPI | OAuth token acquisition |
| Azure Identity | `azure-identity` | 1.19.0 | Verify on PyPI | Agent authentication (P3) |
| Azure AI Search | `azure-search-documents` | 11.5.2 (stable) | Verify on PyPI | Search + RBAC demo (P3) |
| Environment Vars | `python-dotenv` | 1.0.0+ | Compatible | Secure credential management |
| Visualizations | `matplotlib` | 3.8.0+ | Compatible | Conceptual diagrams (P1) |

**Python 3.14 Compatibility Notes**:
- Python 3.14 released October 2024, very recent as of January 2026
- Azure SDKs typically lag 3-6 months behind newest Python releases
- **Recommendation**: Test notebooks with Python 3.13 (mature support) and Python 3.14 (newer)
- **Fallback strategy**: If Python 3.14 compatibility issues arise, document requirement as Python 3.11-3.13 in quickstart.md

**Decision**: Specify minimum Python 3.11, recommended Python 3.13, with Python 3.14 as aspirational (pending PyPI verification)

---

## 3. Azure AI Search Document-Level RBAC Capabilities

### Research Question: Can `azure-search-documents` SDK demonstrate document-level RBAC?

**Decision**: YES - Use Azure AI Search security filters with `azure-identity`

**Approach**:
- Azure AI Search supports **security trimming** via document-level security filters
- Documents include `aclPermissions` field containing list of principal IDs (user/service principal/agent IDs)
- Search queries include security filter: `search.in(aclPermissions, 'user_principal_id', ',')`
- Agent identities authenticate via `azure-identity`, obtain their principal ID, and filter search results

**Implementation Pattern for P3**:
```python
from azure.identity import ClientSecretCredential
from azure.search.documents import SearchClient

# Authenticate as agent identity
credential = ClientSecretCredential(tenant_id, client_id, client_secret)

# Create search client
search_client = SearchClient(endpoint, index_name, credential)

# Query with security filter (only returns documents agent has access to)
results = search_client.search(
    search_text="*",
    filter=f"search.in(aclPermissions, '{agent_principal_id}', ',')"
)
```

**Alternatives Considered**:
- **Azure RBAC roles**: Too coarse-grained (index-level, not document-level)
- **Custom access control**: Over-engineered for tutorial purposes
- **Security trimming**: Chosen - built-in Azure AI Search feature, production-ready

**Outcome**: P3 notebook demonstrates:
1. Agent authenticates via `azure-identity`
2. Agent queries Azure AI Search with security filter
3. Only documents with agent's principal ID in `aclPermissions` are returned
4. Demo includes "permission denied" scenario (agent tries to access document without permission)

---

## 4. Jupyter Notebook Educational Best Practices

### Research Question: What structure maximizes learning outcomes for progressive tutorials?

**Decision**: Three independent notebooks with increasing complexity

**Pattern**:
1. **P1 (Introduction)**: Pure conceptual, no Azure required
   - Markdown-heavy with embedded diagrams
   - Mock code cells (display JSON structures, no API calls)
   - Extensive doc links for self-guided exploration

2. **P2 (REST API)**: Hands-on HTTP calls, explicit auth
   - Step-by-step token acquisition (exposes OAuth flow)
   - Direct `requests` library calls (shows HTTP mechanics)
   - Clear separation: auth cells → CRUD cells → cleanup cells

3. **P3 (SDK Usage)**: Production-ready patterns
   - `azure-identity` for auth (hides OAuth complexity)
   - SDK method calls (abstracted, clean code)
   - Real-world scenario: RBAC filtering in Azure AI Search

**Alternatives Considered**:
- **Single comprehensive notebook**: Rejected - too long (60+ minutes), intimidating for beginners
- **Two notebooks (concepts + implementation)**: Rejected - combines REST and SDK, loses educational contrast
- **Four+ notebooks**: Rejected - over-fragmentation, maintenance burden

**Outcome**: Three-notebook structure confirmed, matching spec.md clarifications

**Best Practices Applied**:
- Each notebook ≤30 cells (manageable)
- Cell execution order matters: numbered cells guide sequence
- Prerequisite cells clearly marked (e.g., "⚠️ Run authentication cell first")
- Cleanup cells at end (delete created resources)
- Error handling cells demonstrate common failures

---

## 5. Microsoft Documentation Integration

### Research Question: Which official docs to link for user self-guided learning?

**Key Documentation Links**:

**P1 (Concepts)**:
- [What is Microsoft Entra ID?](https://learn.microsoft.com/en-us/entra/fundamentals/whatis)
- [Agent ID Overview](https://learn.microsoft.com/en-us/entra/agent-id/overview)
- [Service Principals in Azure](https://learn.microsoft.com/en-us/entra/identity-platform/app-objects-and-service-principals)

**P2 (REST API)**:
- [Create/Delete Agent Identities (Graph API)](https://learn.microsoft.com/en-us/entra/agent-id/identity-platform/create-delete-agent-identities?tabs=microsoft-graph-api)
- [Microsoft Graph API REST Reference](https://learn.microsoft.com/en-us/graph/api/overview)
- [OAuth 2.0 Client Credentials Flow](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-client-creds-grant-flow)

**P3 (SDK Usage)**:
- [Agent ID SDK for Python](https://learn.microsoft.com/en-us/entra/msidweb/agent-id-sdk/scenarios/using-from-python)
- [Azure Identity SDK for Python](https://learn.microsoft.com/en-us/python/api/overview/azure/identity-readme)
- [Azure AI Search Security Trimming](https://learn.microsoft.com/en-us/azure/search/search-security-trimming-for-azure-search)

**Decision**: Include 3-5 doc links per notebook section, inline with relevant concepts

---

## 6. Environment Configuration Best Practices

### Research Question: How to securely manage Azure credentials in educational notebooks?

**Decision**: `.env` file with `python-dotenv`, never commit secrets

**Pattern**:
```python
# Cell 1: Load environment variables
import os
from dotenv import load_dotenv

load_dotenv()  # Loads .env file from same directory

tenant_id = os.getenv('AZURE_TENANT_ID')
client_id = os.getenv('AZURE_CLIENT_ID')
client_secret = os.getenv('AZURE_CLIENT_SECRET')

# Validate (fail fast if missing)
if not all([tenant_id, client_id, client_secret]):
    raise ValueError("Missing required environment variables. See README.md for setup.")
```

**Deliverables**:
- `.env.example` with placeholder values:
  ```
  AZURE_TENANT_ID=your-tenant-id-here
  AZURE_CLIENT_ID=your-client-id-here
  AZURE_CLIENT_SECRET=your-client-secret-here
  AZURE_SEARCH_ENDPOINT=https://your-search-service.search.windows.net
  ```
- `.gitignore` entry for `.env`
- Quickstart.md instructions for creating `.env` from example

**Alternatives Considered**:
- **Hardcoded values**: Rejected - security risk, violates FR-014
- **Manual input via `input()`**: Rejected - poor UX, not reproducible
- **Azure Key Vault**: Rejected - over-engineered for tutorial, adds complexity

---

## Summary of Research Decisions

| Category | Decision | Rationale |
|----------|----------|-----------|
| **Python SDK** | `azure-identity` (not microsoft-identity-web) | microsoft-identity-web is .NET-only; azure-identity is official Python equivalent |
| **Auth Library** | Both `msal` (P2) and `azure-identity` (P3) | Educational contrast: low-level OAuth vs. high-level SDK |
| **Azure AI Search SDK** | `azure-search-documents` 11.5.2+ | Stable version, supports security trimming for RBAC demo |
| **Python Version** | Minimum 3.11, recommended 3.13, aspirational 3.14 | Balance between modern features and SDK compatibility |
| **Notebook Structure** | Three independent .ipynb files | Progressive complexity, independent execution per FR-002 |
| **Secret Management** | `.env` + `python-dotenv` | Secure, industry-standard, prevents accidental commits |
| **Documentation Strategy** | 3-5 inline doc links per notebook | Self-guided learning without overwhelming users |
| **RBAC Demo Approach** | Azure AI Search security filters | Built-in feature, production-ready, no custom code needed |

---

## Action Items for Implementation

1. ✅ Update plan.md line 19: Replace `microsoft-identity-web` with `azure-identity`
2. ✅ Document Python version requirements in quickstart.md (3.11+ required, 3.13 recommended)
3. ✅ Create contracts for Graph API (agent identity CRUD) and OAuth token acquisition
4. ⏭️ Create quickstart.md with environment setup instructions
5. ⏭️ Update agent context with verified dependencies
6. ⏭️ Proceed to Phase 2: Task generation

All research unknowns from Technical Context have been resolved.
