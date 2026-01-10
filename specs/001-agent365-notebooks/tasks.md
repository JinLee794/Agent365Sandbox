# Tasks: Agent 365 Tutorial Jupyter Notebooks

**Input**: Design documents from `specs/001-agent365-notebooks/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), data-model.md, contracts/, quickstart.md

**Tests**: This feature is educational content - no automated tests required. Manual validation occurs by executing notebooks.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Educational project**: `notebooks/` at repository root (flat structure)
- `notebooks/01-introduction.ipynb`, `notebooks/02-rest-api.ipynb`, `notebooks/03-sdk-usage.ipynb`
- Supporting files: `notebooks/requirements.txt`, `notebooks/.env.example`, `notebooks/README.md`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [X] T001 Create notebooks directory at repository root (notebooks/)
- [X] T002 Create requirements.txt with Python dependencies in notebooks/requirements.txt
- [X] T003 [P] Create .env.example template for environment variables in notebooks/.env.example
- [X] T004 [P] Create .gitignore entry for .env file
- [X] T005 [P] Create README.md with setup instructions in notebooks/README.md (link to quickstart.md)

**Checkpoint**: Basic project structure ready - notebook development can begin

---

## Phase 2: User Story 1 - Introduction to Agent 365 Concepts (Priority: P1) 🎯 MVP

**Goal**: Educational notebook explaining Agent 365 concepts without requiring Azure credentials

**Independent Test**: Execute notebook from start to finish; all cells run successfully with conceptual outputs (diagrams, JSON examples); no Azure API calls; user gains conceptual understanding

### Implementation for User Story 1

- [X] T006 [US1] Create 01-introduction.ipynb in notebooks/01-introduction.ipynb
- [X] T007 [US1] Add notebook header with learning objectives and prerequisites in notebooks/01-introduction.ipynb
- [X] T008 [US1] Create markdown cells explaining "What is Agent 365?" with use cases in notebooks/01-introduction.ipynb
- [X] T009 [US1] Add code cell demonstrating Agent Identity JSON structure (mock data, no API) in notebooks/01-introduction.ipynb
- [X] T010 [US1] Add code cell demonstrating Agent Blueprint JSON structure (mock data, no API) in notebooks/01-introduction.ipynb
- [X] T011 [US1] Create conceptual diagram showing Agent Identity lifecycle using matplotlib in notebooks/01-introduction.ipynb
- [X] T012 [US1] Create conceptual diagram showing Agent Blueprint → Agent Identity relationship using matplotlib in notebooks/01-introduction.ipynb
- [X] T013 [US1] Add markdown cells explaining Entra ID integration concepts in notebooks/01-introduction.ipynb
- [X] T014 [US1] Add markdown cells comparing Agent 365 vs other identity solutions (when to use) in notebooks/01-introduction.ipynb
- [X] T015 [US1] Add 5-7 links to official Microsoft documentation (inline with concepts) in notebooks/01-introduction.ipynb
- [X] T016 [US1] Add summary section with key takeaways in notebooks/01-introduction.ipynb
- [X] T017 [US1] Add "Next Steps" section pointing to 02-rest-api.ipynb in notebooks/01-introduction.ipynb
- [ ] T018 [US1] Execute notebook end-to-end to validate all cells run without errors

**Checkpoint**: At this point, User Story 1 (Introduction) is complete and can be used independently by learners without Azure

---

## Phase 3: User Story 2 - Creating Agent Identities via REST API (Priority: P2)

**Goal**: Hands-on notebook demonstrating agent identity CRUD operations using Microsoft Graph API

**Independent Test**: Execute notebook with valid Azure credentials; successfully create, retrieve, and delete at least one agent identity; verify via API responses and/or Azure portal

### Implementation for User Story 2

- [X] T019 [US2] Create 02-rest-api.ipynb in notebooks/02-rest-api.ipynb
- [X] T020 [US2] Add notebook header with learning objectives and prerequisites (Azure credentials required) in notebooks/02-rest-api.ipynb
- [X] T021 [US2] Add markdown cell with setup instructions (reference quickstart.md, .env file) in notebooks/02-rest-api.ipynb
- [X] T022 [US2] Add code cell to load environment variables using python-dotenv in notebooks/02-rest-api.ipynb
- [X] T023 [US2] Add validation cell to check required env vars (AZURE_TENANT_ID, CLIENT_ID, CLIENT_SECRET) in notebooks/02-rest-api.ipynb
- [X] T024 [US2] Add markdown cell explaining OAuth 2.0 client credentials flow in notebooks/02-rest-api.ipynb
- [X] T025 [US2] Implement token acquisition cell using requests library (POST to token endpoint) in notebooks/02-rest-api.ipynb
- [X] T026 [US2] Add error handling for token acquisition failures (401, invalid credentials) in notebooks/02-rest-api.ipynb
- [X] T027 [US2] Add markdown cell explaining Microsoft Graph API agent identity endpoints in notebooks/02-rest-api.ipynb
- [X] T028 [US2] Implement CREATE agent identity cell (POST /directory/agentIdentities) in notebooks/02-rest-api.ipynb
- [X] T029 [US2] Add error handling for create operation (400 bad request, 403 forbidden, missing blueprint) in notebooks/02-rest-api.ipynb
- [X] T030 [US2] Add cell to display created agent ID and details (print formatted JSON) in notebooks/02-rest-api.ipynb
- [X] T031 [US2] Implement GET agent identity cell (retrieve by ID) in notebooks/02-rest-api.ipynb
- [X] T032 [US2] Add error handling for get operation (404 not found) in notebooks/02-rest-api.ipynb
- [X] T033 [US2] Add optional LIST agent identities cell (GET /directory/agentIdentities) for exploration in notebooks/02-rest-api.ipynb
- [X] T034 [US2] Implement DELETE agent identity cell (cleanup created resource) in notebooks/02-rest-api.ipynb
- [X] T035 [US2] Add error handling for delete operation in notebooks/02-rest-api.ipynb
- [X] T036 [US2] Add markdown cell explaining API rate limits and throttling in notebooks/02-rest-api.ipynb
- [X] T037 [US2] Add markdown cell explaining token expiration (re-run auth cell if 401) in notebooks/02-rest-api.ipynb
- [X] T038 [US2] Add 3-5 links to official Microsoft Graph API documentation in notebooks/02-rest-api.ipynb
- [X] T039 [US2] Add cleanup section with instructions to delete all test resources in notebooks/02-rest-api.ipynb
- [X] T040 [US2] Add "Next Steps" section pointing to 03-sdk-usage.ipynb in notebooks/02-rest-api.ipynb
- [ ] T041 [US2] Execute notebook end-to-end with test Azure credentials to validate functionality

**Checkpoint**: At this point, User Story 2 (REST API) is complete; users can create/delete agent identities independently

---

## Phase 4: User Story 3 - Using Agent Identities with Entra ID SDK (Priority: P3)

**Goal**: Production-ready notebook showing how to authenticate AS an agent identity and access Azure resources (Azure AI Search RBAC demo)

**Independent Test**: Execute notebook with Azure credentials and Azure AI Search configured; agent successfully authenticates using azure-identity SDK; agent accesses permitted documents and is denied access to restricted documents (RBAC demo works)

### Implementation for User Story 3

- [ ] T042 [US3] Create 03-sdk-usage.ipynb in notebooks/03-sdk-usage.ipynb
- [ ] T043 [US3] Add notebook header with learning objectives and prerequisites (Azure + Azure AI Search required) in notebooks/03-sdk-usage.ipynb
- [ ] T044 [US3] Add markdown cell explaining difference between REST (P2) and SDK (P3) approaches in notebooks/03-sdk-usage.ipynb
- [ ] T045 [US3] Add code cell to load environment variables (including AZURE_SEARCH_ENDPOINT) in notebooks/03-sdk-usage.ipynb
- [ ] T046 [US3] Add validation cell to check Azure AI Search env vars in notebooks/03-sdk-usage.ipynb
- [ ] T047 [US3] Add markdown cell explaining azure-identity SDK and ClientSecretCredential in notebooks/03-sdk-usage.ipynb
- [ ] T048 [US3] Implement agent authentication cell using azure-identity (ClientSecretCredential) in notebooks/03-sdk-usage.ipynb
- [ ] T049 [US3] Add error handling for SDK authentication failures in notebooks/03-sdk-usage.ipynb
- [ ] T050 [US3] Add markdown cell explaining Azure AI Search document-level RBAC concepts in notebooks/03-sdk-usage.ipynb
- [ ] T051 [US3] Implement SearchClient initialization using authenticated credential in notebooks/03-sdk-usage.ipynb
- [ ] T052 [US3] Add cell to get agent's principal ID (needed for RBAC filtering) in notebooks/03-sdk-usage.ipynb
- [ ] T053 [US3] Implement search query WITH security filter (aclPermissions field) in notebooks/03-sdk-usage.ipynb
- [ ] T054 [US3] Add cell to display accessible documents (those matching agent's permissions) in notebooks/03-sdk-usage.ipynb
- [ ] T055 [US3] Add demonstration of permission denied scenario (search without security filter shows all docs, with filter shows subset) in notebooks/03-sdk-usage.ipynb
- [ ] T056 [US3] Add error handling for Azure AI Search operations (connection errors, permission errors) in notebooks/03-sdk-usage.ipynb
- [ ] T057 [US3] Add markdown cell explaining real-world use cases for agent identities in notebooks/03-sdk-usage.ipynb
- [ ] T058 [US3] Add optional cell demonstrating agent accessing Microsoft Graph API (e.g., read user info) in notebooks/03-sdk-usage.ipynb
- [ ] T059 [US3] Add comparison table showing REST vs SDK benefits/tradeoffs in notebooks/03-sdk-usage.ipynb
- [ ] T060 [US3] Add 3-5 links to official Azure Identity SDK and Azure AI Search documentation in notebooks/03-sdk-usage.ipynb
- [ ] T061 [US3] Add summary section with production best practices in notebooks/03-sdk-usage.ipynb
- [ ] T062 [US3] Add cleanup instructions (note: agent identity created in P2 can be reused or deleted) in notebooks/03-sdk-usage.ipynb
- [ ] T063 [US3] Execute notebook end-to-end with test environment to validate RBAC demo

**Checkpoint**: At this point, all three user stories are complete; users have full tutorial progression from concepts → REST → SDK

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Final touches that improve all notebooks

- [ ] T064 [P] Review all notebooks for consistent markdown formatting and style in notebooks/*.ipynb
- [ ] T065 [P] Verify all code cells follow PEP 8 style guidelines in notebooks/*.ipynb
- [ ] T066 [P] Ensure all notebooks have proper section numbering/organization in notebooks/*.ipynb
- [ ] T067 [P] Add estimated completion time to each notebook header in notebooks/*.ipynb
- [ ] T068 [P] Verify all Microsoft documentation links are valid and current in notebooks/*.ipynb
- [ ] T069 Verify all three notebooks run independently (no cross-notebook dependencies)
- [ ] T070 Test notebooks in different environments (JupyterLab, VS Code, Google Colab)
- [ ] T071 Verify Python 3.11, 3.13 compatibility (aspirational: test 3.14)
- [ ] T072 Update README.md with troubleshooting tips based on testing in notebooks/README.md
- [ ] T073 Add success criteria validation (SC-001 through SC-010 from spec.md)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **User Story 1 (Phase 2)**: Depends on Setup completion
- **User Story 2 (Phase 3)**: Depends on Setup completion (does NOT depend on US1 - can run in parallel if desired)
- **User Story 3 (Phase 4)**: Depends on Setup completion (does NOT depend on US1 or US2 - can run in parallel if desired)
- **Polish (Phase 5)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Fully independent - no Azure required, no dependencies
- **User Story 2 (P2)**: Fully independent - requires Azure but not other notebooks
- **User Story 3 (P3)**: Fully independent - requires Azure + Azure AI Search but not other notebooks
  - Note: P3 can reuse agent identity created in P2, but can also create its own

**Key Insight**: All three user stories are INDEPENDENT. This means:
- A developer can complete just US1 (concepts) without Azure
- A developer can skip US1 and go directly to US2 (REST API) if already familiar with concepts
- A developer can complete US3 (SDK) without running US2 first (though US2 knowledge is helpful)

### Within Each User Story

**User Story 1 (Introduction)**:
1. Notebook creation and header
2. Content cells (can be created in parallel by different authors)
3. Final validation (execute notebook)

**User Story 2 (REST API)**:
1. Notebook creation and setup cells
2. Authentication implementation (blocking)
3. CRUD operations (can be done in parallel after auth works)
4. Cleanup and validation

**User Story 3 (SDK)**:
1. Notebook creation and setup cells
2. SDK authentication (blocking)
3. Azure AI Search implementation (depends on auth)
4. RBAC demonstration (depends on search client)
5. Validation

### Parallel Opportunities

**Within Setup Phase**:
- All tasks marked [P] (T003, T004, T005) can run in parallel

**Across User Stories** (if multiple developers):
- After Setup completes:
  - Developer A: User Story 1 (T006-T018)
  - Developer B: User Story 2 (T019-T041)
  - Developer C: User Story 3 (T042-T063)
- All three can proceed simultaneously since notebooks are independent

**Within Polish Phase**:
- All tasks marked [P] (T064-T068) can run in parallel

---

## Parallel Example: Multi-Developer Workflow

```bash
# After Setup phase completes (T001-T005):

# Developer A focuses on User Story 1 (Introduction)
Tasks: T006-T018 (13 tasks)
Deliverable: notebooks/01-introduction.ipynb

# Developer B focuses on User Story 2 (REST API)
Tasks: T019-T041 (23 tasks)
Deliverable: notebooks/02-rest-api.ipynb

# Developer C focuses on User Story 3 (SDK)
Tasks: T042-T063 (22 tasks)
Deliverable: notebooks/03-sdk-usage.ipynb

# All three work in parallel, then converge for Polish phase (T064-T073)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T005)
2. Complete Phase 2: User Story 1 (T006-T018)
3. **STOP and VALIDATE**: Test introduction notebook independently
4. Publish/share for early feedback

**MVP Delivers**: Conceptual understanding of Agent 365, no Azure required, 15-minute learning experience

### Incremental Delivery

1. Complete Setup (T001-T005)
2. Complete User Story 1 (T006-T018) → Publish MVP
3. Complete User Story 2 (T019-T041) → Publish REST API tutorial
4. Complete User Story 3 (T042-T063) → Publish complete tutorial series
5. Complete Polish (T064-T073) → Final production release

**Benefit**: Each user story adds value independently without breaking previous notebooks

### Parallel Team Strategy

With three developers:
1. All: Complete Setup together (5 tasks)
2. Split by user story:
   - Dev A: US1 (13 tasks, ~4-6 hours)
   - Dev B: US2 (23 tasks, ~6-8 hours)
   - Dev C: US3 (22 tasks, ~8-10 hours)
3. Converge: Polish together (10 tasks, ~4-6 hours)

**Total**: ~22-30 hours (same as sequential, but completes faster with parallel work)

---

## Validation Checklist

Before marking tasks complete, verify:

### Per-Notebook Validation

- [ ] All code cells execute successfully in sequence
- [ ] No hardcoded secrets (all use environment variables)
- [ ] Clear error messages for missing prerequisites
- [ ] Links to Microsoft documentation are valid
- [ ] Markdown cells are clear and concise
- [ ] Code follows PEP 8 style guidelines
- [ ] Notebook completes in under 5 minutes execution time

### Cross-Notebook Validation

- [ ] Each notebook runs independently (no cross-dependencies)
- [ ] Notebooks work in JupyterLab, Jupyter Notebook, VS Code
- [ ] Python 3.11+ compatibility verified
- [ ] README.md accurately describes setup process
- [ ] .env.example includes all required variables

### Success Criteria Validation (from spec.md)

- [ ] **SC-001**: Introduction notebook completable in <15 minutes without Azure
- [ ] **SC-002**: Users can create agent identity in REST notebook without help
- [ ] **SC-003**: All cells execute successfully
- [ ] **SC-007**: Each notebook executes in <5 minutes (code execution time)
- [ ] **SC-008**: Users successfully authenticate on first attempt
- [ ] **SC-010**: Notebooks are clear and not overwhelming

---

## Task Summary

**Total Tasks**: 73

**Breakdown by Phase**:
- Phase 1 (Setup): 5 tasks
- Phase 2 (User Story 1 - Introduction): 13 tasks
- Phase 3 (User Story 2 - REST API): 23 tasks
- Phase 4 (User Story 3 - SDK): 22 tasks
- Phase 5 (Polish): 10 tasks

**Parallel Opportunities**: 12 tasks can run in parallel (marked with [P])

**User Story Independence**: All 3 user stories are independently deliverable and testable

**Estimated Effort**:
- Sequential implementation: 22-30 hours
- Parallel (3 developers): 10-15 hours wall-clock time

**MVP Scope**: Phase 1 + Phase 2 (18 tasks, ~6-8 hours) delivers valuable standalone introduction notebook

---

## Notes

- No automated tests for this educational feature - validation is manual notebook execution
- Each notebook MUST run independently per FR-002
- Focus on educational clarity over production robustness
- Error handling focuses on educational value (explaining what went wrong and why)
- All notebooks assume user has basic Python knowledge (per spec assumptions)
- REST notebook (P2) demonstrates OAuth mechanics; SDK notebook (P3) uses production patterns
- RBAC demo (P3) requires pre-configured Azure AI Search instance (documented in quickstart.md)
