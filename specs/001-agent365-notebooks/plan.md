# Implementation Plan: Agent 365 Tutorial Jupyter Notebooks

**Branch**: `001-agent365-notebooks` | **Date**: 2026-01-10 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/001-agent365-notebooks/spec.md`

## Summary

Create three progressive Jupyter notebooks teaching Agent 365 concepts: introduction (concepts without Azure), REST API operations (create/delete agent identities), and SDK usage (authenticate as agent + Azure AI Search RBAC demo). Notebooks must be Python 3.14 compatible, independently executable, and include extensive Microsoft documentation links for self-guided learning.

**Technical Approach**: Educational Jupyter notebooks with zero-to-production progression, leveraging Microsoft Graph API for lifecycle management and microsoft-identity-web SDK for operational usage demonstrations.

## Technical Context

**Language/Version**: Python 3.14
**Primary Dependencies**:
- `jupyter` or `jupyterlab` (notebook environment)
- `requests` (HTTP client for REST API examples)
- `msal` (Microsoft Authentication Library for Python - OAuth token acquisition)
- `azure-identity` (Azure/Entra ID authentication SDK - Python equivalent of .NET's microsoft-identity-web)
- `azure-search-documents` (Azure AI Search SDK for RBAC demo, version 11.5.2+)
- `python-dotenv` (environment variable management)
- `matplotlib` or `graphviz` (for conceptual diagrams in introduction)

**Storage**: N/A (educational notebooks, no persistent storage)
**Testing**: Manual notebook execution validation; no automated test framework needed for educational content
**Target Platform**: Cross-platform (Windows, macOS, Linux) Jupyter environments; JupyterLab, Jupyter Notebook, VS Code, Google Colab
**Project Type**: Educational/Documentation - standalone Jupyter notebooks
**Performance Goals**: Each notebook executes in under 5 minutes (cell execution time, excluding user reading)
**Constraints**:
- P1 notebook MUST run without Azure credentials
- Code cells MUST be copy-paste ready
- No hardcoded secrets (environment variables only)
- Clear error messages for missing prerequisites
**Scale/Scope**: 3 notebooks, ~15-30 cells each, targeting 15-45 minute completion time per notebook

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Since no project-specific constitution exists, applying standard educational content principles:

- [x] **Clarity & Simplicity**: Notebooks use progressive complexity (concepts → REST → SDK), no premature abstraction
- [x] **Self-Contained**: Each notebook runs independently (FR-002)
- [x] **Observable & Debuggable**: Error handling examples included (FR-010), clear outputs for each cell
- [x] **Documentation**: Extensive links to official Microsoft docs (FR-011)
- [x] **Security**: No hardcoded secrets (FR-014), environment variables for credentials

**Status**: PASS - Educational content aligns with simplicity, observability, and security best practices

## Project Structure

### Documentation (this feature)

```text
specs/001-agent365-notebooks/
├── plan.md              # This file
├── research.md          # Phase 0: Dependency verification, SDK research
├── data-model.md        # Phase 1: Entity definitions (Agent Identity, Blueprint, etc.)
├── quickstart.md        # Phase 1: Setup instructions for users
├── contracts/           # Phase 1: Microsoft Graph API examples (JSON schemas)
└── tasks.md             # Created by /speckit.tasks (NOT this command)
```

### Source Code (repository root)

```text
notebooks/
├── 01-introduction.ipynb        # P1: Agent 365 concepts, no Azure required
├── 02-rest-api.ipynb            # P2: Create/delete agent identities via Graph API
├── 03-sdk-usage.ipynb           # P3: Authenticate as agent + Azure AI Search RBAC
├── .env.example                 # Template for required environment variables
├── requirements.txt             # Python dependencies
└── README.md                    # Setup instructions (links to quickstart.md)
```

**Structure Decision**: Flat `notebooks/` directory at repository root for maximum discoverability. Educational projects benefit from simple, non-nested structures. Each .ipynb file is self-contained per FR-002.

## Complexity Tracking

No violations - structure is intentionally simple for educational purposes.

---

## Phase 0: Research Summary

**Status**: ✅ Complete

All unknowns from Technical Context have been resolved. Key findings:

1. **SDK Package Correction**: `microsoft-identity-web` does not exist for Python; replaced with `azure-identity`
2. **Python 3.14 Compatibility**: Minimum Python 3.11, recommended 3.13, aspirational 3.14 (pending SDK verification)
3. **RBAC Implementation**: Azure AI Search security filters provide document-level RBAC capabilities
4. **Notebook Structure**: Three independent .ipynb files confirmed as optimal educational pattern

See [research.md](./research.md) for detailed findings.

---

## Phase 1: Design Artifacts

**Status**: ✅ Complete

Generated artifacts:

1. **data-model.md**: Entity definitions for Agent Identity, Agent Blueprint, Access Token, Azure App Registration, and Azure AI Search Document
2. **contracts/graph-api-agent-identity.json**: Microsoft Graph API contract for agent identity CRUD operations
3. **contracts/oauth-token-request.json**: OAuth 2.0 token acquisition contract with security notes
4. **quickstart.md**: Comprehensive setup guide (Azure configuration, environment setup, troubleshooting)

All design decisions documented and validated against functional requirements.

---

## Constitution Check (Post-Design Re-evaluation)

**Status**: ✅ PASS

Design artifacts maintain compliance with educational content principles:

- ✅ **Clarity & Simplicity**: API contracts use standard REST patterns; no custom abstractions
- ✅ **Self-Contained**: Each artifact (data model, contracts, quickstart) is independently usable
- ✅ **Observable & Debuggable**: Contracts include detailed error responses; quickstart has extensive troubleshooting section
- ✅ **Documentation**: Quickstart includes 10+ Microsoft doc links; contracts reference official Graph API documentation
- ✅ **Security**: Contracts emphasize environment variables; quickstart has dedicated security best practices section

No new complexity introduced during design phase. Structure remains flat and educational-focused.

---

## Next Steps

This plan is complete through Phase 1. To continue implementation:

1. Run `/speckit.tasks` to generate detailed task breakdown from this plan
2. Tasks will be organized by user story (P1, P2, P3) for independent implementation
3. Consider creating GitHub issues from tasks using `/speckit.taskstoissues` if working in a team

**Estimated Implementation Effort**:
- P1 (Introduction notebook): ~4-6 hours (content writing, diagram creation)
- P2 (REST API notebook): ~6-8 hours (code examples, error handling, testing)
- P3 (SDK notebook): ~8-10 hours (Azure AI Search setup, RBAC demo, integration)
- Documentation & testing: ~4-6 hours
- **Total**: ~22-30 hours for complete implementation
