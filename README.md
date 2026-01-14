# Agent 365 Sandbox

A hands-on sandbox for exploring **Microsoft Entra Agent Identities**, **Azure AI Search RBAC patterns**, and **Microsoft Agent Framework**. This repo implements the [Agent Identity Blueprint](https://learn.microsoft.com/en-us/entra/agent-id/identity-platform/agent-blueprint) setup and provides eight interactive Jupyter notebooks for learning and experimentation.

## 📂 Project Structure

```
├── README.md                          # This file (overview & quick start)
├── CLAUDE.md                          # AI context & decision log
├── docs/                              # 📚 Comprehensive documentation
│   ├── ARCHITECTURE.md                # System design and patterns
│   ├── SETUP.md                       # Configuration & troubleshooting
│   ├── NOTEBOOKS.md                   # Detailed notebook descriptions
│   └── PATTERNS.md                    # Advanced implementation patterns
├── notebooks/
│   ├── a365.ps1                       # Blueprint setup script (PowerShell)
│   ├── .env.example                   # Configuration template
│   ├── requirements.txt                # Python dependencies
│   ├── 01-validate-configuration.ipynb
│   ├── 02-token-flows.ipynb
│   ├── 03-agent-sdk.ipynb
│   ├── 04-interactive-authentication.ipynb
│   ├── 05-search-setup.ipynb          # ✅ Deploy Azure AI Search
│   ├── 06-search-rbac-demo.ipynb      # ✅ RBAC + document security
│   ├── 07-agentic-retrieval-kb.ipynb  # ✅ Multi-agent KB
│   ├── 08-foundry-iq-agent-framework.ipynb # ✅ Agent Framework + Foundry
│   ├── foundry-resources.bicep        # Infrastructure as Code
│   └── utils.py
└── specs/
    └── 001-agent365-notebooks/        # Detailed specs & contracts
```

---

## 📖 Documentation Guide

**Start here based on your needs:**

- **[docs/SETUP.md](docs/SETUP.md)** — Configuration, prerequisites, and troubleshooting
- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** — System design, RBAC patterns, data flows
- **[docs/NOTEBOOKS.md](docs/NOTEBOOKS.md)** — Detailed descriptions of all 8 notebooks with learning paths
- **[docs/PATTERNS.md](docs/PATTERNS.md)** — Advanced patterns, extensions, and best practices

---

## 🚀 Quick Start

<details open>
<summary><b>1. Run Blueprint Setup (PowerShell)</b></summary>

The `a365.ps1` script creates your Agent Identity Blueprint infrastructure:

```powershell
cd notebooks
pwsh a365.ps1 -Step all
```

This creates:
- ✅ Agent Identity Blueprint (app registration)
- ✅ Service Principal with credentials
- ✅ OAuth scope & identifier URI
- ✅ `.env` file with configuration

**Prerequisites:**
- PowerShell 7+ (cross-platform)
- Microsoft Graph PowerShell SDK
- Entra ID tenant with app creation rights
- OpenSSL (optional, for certificate credentials)

**Reference:** [Agent Blueprint Setup Doc](https://learn.microsoft.com/en-us/entra/agent-id/identity-platform/agent-blueprint)

</details>

<details open>
<summary><b>2. Install Python & Dependencies</b></summary>

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate           # macOS/Linux
# OR
.venv\Scripts\activate             # Windows

# Install via uv (recommended)
pip install uv
uv pip install -r requirements.txt

# OR install directly
pip install -r requirements.txt
```

**Python version:** 3.11+ (3.13 recommended)

</details>

<details open>
<summary><b>3. Verify Configuration & Launch Jupyter</b></summary>

```bash
# Verify .env file was created
cat .env

# Launch Jupyter
uv run jupyter lab
# OR
jupyter lab
```

</details>

---

## 📚 Notebooks Overview

| # | Name | Purpose | Duration | Status |
|---|------|---------|----------|--------|
| 01 | **validate-configuration** | Load & test `.env` config, verify Graph connectivity | 10-15 min | Reference |
| 02 | **token-flows** | OAuth 2.0 flows, JWT inspection, token caching | 20-25 min | Reference |
| 03 | **agent-sdk** | Microsoft Entra SDK, agent lifecycle, sign-in logs | 30-40 min | Reference |
| 04 | **interactive-authentication** | Authorization codes, OBO flow, user consent | 35-45 min | Reference |
| 05 | **search-setup** | Deploy Azure AI Search via Bicep, create indices | 15-20 min | ✅ Active |
| 06 | **search-rbac-demo** | Index-scoped RBAC + document-level security | 20-30 min | ✅ Active |
| 07 | **agentic-retrieval-kb** | Multi-agent KB with answer synthesis | 25-35 min | ✅ Active |
| 08 | **foundry-iq-agent-framework** | Foundry + Agent Framework + RBAC | 30-40 min | ✅ Active |

**📖 Full descriptions:** See [docs/NOTEBOOKS.md](docs/NOTEBOOKS.md) for detailed explanations, code samples, and learning paths.

### What's in Each Notebook?

**Notebooks 01-04 (Reference):** Authentication and Entra ID concepts
- Understand OAuth flows, token handling, and agent identities
- Foundation for working with Microsoft Graph API

**Notebooks 05-08 (Active):** Production agent systems
- **Notebook 05:** Deploy Azure AI Search infrastructure
- **Notebook 06:** Configure RBAC and document-level security
- **Notebook 07:** Build multi-agent knowledge bases
- **Notebook 08:** Integrate with Microsoft Agent Framework

For detailed descriptions, code examples, and learning paths, see [docs/NOTEBOOKS.md](docs/NOTEBOOKS.md).

---

## 🔧 Configuration & Setup

**📖 See [docs/SETUP.md](docs/SETUP.md) for:**
- Step-by-step setup instructions
- Azure prerequisites and permissions
- Environment variable reference
- Comprehensive troubleshooting
- Production checklist

**Quick summary:**

1. Run Blueprint setup: `pwsh notebooks/a365.ps1 -Step all`
2. Install dependencies: `pip install -r notebooks/requirements.txt`
3. Configure environment: Copy `.env.example` → `.env` and fill in values
4. Launch notebooks: `jupyter lab` (see [docs/SETUP.md](docs/SETUP.md) for detailed steps)

---

## � Learning Paths

**📖 See [docs/NOTEBOOKS.md](docs/NOTEBOOKS.md) for complete learning paths including:**

- **Path 1:** Agent Identity & Authentication (Notebooks 01-04)
- **Path 2:** Azure Search & RBAC (Notebooks 05-06)
- **Path 3:** Agentic Retrieval & Knowledge Base (Notebooks 05-07)
- **Path 4:** Full Stack - Foundry + Agent Framework (Notebooks 05-08)

Each path includes prerequisites, execution guide, expected outputs, and next steps.

---

## � Troubleshooting

**📖 See [docs/SETUP.md](docs/SETUP.md) for comprehensive troubleshooting including:**

- Blueprint setup issues
- Jupyter and Python errors
- Azure AI Search configuration
- RBAC authentication problems
- Network and firewall issues
- Step-by-step solutions for 7+ common problems

---

## � Key Concepts

**📖 See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for deep dives on:**

- **Agent Identity Blueprint:** Template for agent app registrations
- **OAuth 2.0 Flows:** App-only, user delegation, on-behalf-of patterns
- **RBAC (Multi-Layer):** Azure RBAC, agent policies, document filters
- **Agent Framework:** Tool calling, orchestration, integration patterns
- **Knowledge Bases:** Multi-index organization with selective access
- **Answer Synthesis:** Formatting and summarizing retrieved documents

**Quick reference:**
- **Agent Blueprint** = Application registration template in Entra ID
- **RBAC** = Role-based access control at index and document level
- **Agent Framework** = LLM-powered agent orchestration with tool support
- **Knowledge Base** = Organized set of indices with agent-level access control

---

## 📚 Resources & Documentation

**Project Documentation:**
- [docs/SETUP.md](docs/SETUP.md) — Configuration, prerequisites, troubleshooting
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — System design and RBAC patterns
- [docs/NOTEBOOKS.md](docs/NOTEBOOKS.md) — Notebook descriptions and learning paths
- [docs/PATTERNS.md](docs/PATTERNS.md) — Advanced implementation patterns

**External References:**

| Topic | Link |
|-------|------|
| **Agent Identity Platform** | [Microsoft Docs](https://learn.microsoft.com/en-us/entra/agent-id/identity-platform/) |
| **Agent Blueprint** | [Microsoft Docs](https://learn.microsoft.com/en-us/entra/agent-id/identity-platform/agent-blueprint) |
| **Azure AI Search** | [Microsoft Docs](https://learn.microsoft.com/en-us/azure/search/) |
| **Agent Framework** | [GitHub Repository](https://github.com/microsoft/agent-framework) |
| **Azure Foundry** | [Microsoft Docs](https://learn.microsoft.com/azure/ai-services/agents/) |
| **OAuth 2.0 Flows** | [Microsoft Docs](https://learn.microsoft.com/en-us/entra/identity-platform/v2-oauth2-auth-code-flow) |
| **Microsoft Graph** | [Graph Explorer](https://developer.microsoft.com/en-us/graph/graph-explorer) |

**Reference Content:**

The agentic retrieval and knowledge base patterns in this repo (notebooks 07-08) are based on Microsoft's official lab:
- [**Microsoft LAB511**: Build Agentic Knowledge Bases with Azure AI Search](https://github.com/microsoft/ignite25-LAB511-build-agentic-knowledge-bases-next-level-rag-with-azure-ai-search)

---

## 📝 Notes

- **Beta APIs:** Blueprint APIs are on Microsoft Graph beta; expect changes
- **Secrets:** Keep `.env` and certificate files local; do not commit
- **File Size:** Azure Cosmos DB items limited to 2 MB
- **Data Modeling:** Prefer embedding over normalization for single-partition access patterns

---

## 🙏 Built With

- Microsoft Entra ID
- Microsoft Graph API
- Azure AI Search
- MSAL (Microsoft Authentication Library)
- Jupyter Notebooks
- PowerShell 7+
- Python 3.11+

---

**Last Updated:** January 2026 | **Status:** Active Development
