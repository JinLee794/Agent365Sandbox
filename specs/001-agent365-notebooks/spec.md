# Feature Specification: Agent 365 Tutorial Jupyter Notebooks

**Feature Branch**: `001-agent365-notebooks`
**Created**: 2026-01-10
**Status**: Draft
**Input**: User description: "python 3.14 based jupyter notebooks that are concise, focused, and gives the user an introduction to the key concepts of agent 365 without too much complexity, walking users through how to create an agent id blueprint via rest: https://learn.microsoft.com/en-us/entra/agent-id/identity-platform/create-delete-agent-identities?tabs=microsoft-graph-api as well as agentid entraid https://learn.microsoft.com/en-us/entra/msidweb/agent-id-sdk/scenarios/using-from-python"

## Clarifications

### Session 2026-01-10

- Q: What is the relationship between Agent Blueprint and Agent Identity in the context of these notebooks? → A: Agent Blueprint is a template that defines agent properties; Notebooks create agent identities FROM existing blueprints
- Q: How should the REST API and SDK notebooks differ in scope? → A: REST API for creating/deleting agents; SDK for other operations to showcase actual usage of created identities/blueprints
- Q: How should the notebooks be organized as files? → A: Three separate .ipynb files (01-introduction.ipynb, 02-rest-api.ipynb, 03-sdk-usage.ipynb)
- Q: What specific operations should the SDK notebook demonstrate? → A: Authenticate as agent + access Azure resources (e.g., Graph API, storage) + demonstrate Azure AI Search document-level RBAC access
- Q: What content depth should the introduction notebook include? → A: Conceptual explanations + simple non-operational code examples (diagrams, JSON structures, concept illustrations) with extensive references to official documentation

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Introduction to Agent 365 Concepts (Priority: P1)

A developer new to Agent 365 wants to understand the fundamental concepts and architecture before implementing any integration. They need a guided introduction that explains what Agent 365 is, its core components, and when to use it.

**Why this priority**: Understanding foundational concepts is critical before attempting any implementation. Without this context, users will struggle with subsequent tutorials and may implement solutions incorrectly.

**Independent Test**: Can be fully tested by running the notebook from start to finish, reading all explanatory content, and executing simple demonstration code cells that illustrate key concepts. Delivers immediate value by providing conceptual understanding even if user doesn't proceed to implementation.

**Acceptance Scenarios**:

1. **Given** a developer unfamiliar with Agent 365, **When** they open and read the introduction notebook, **Then** they understand what Agent 365 is and its primary use cases
2. **Given** the introduction notebook, **When** the user executes all code cells, **Then** all cells run successfully without errors and display conceptual visualizations, JSON structure examples, and illustrative outputs (no actual Azure API calls required)
3. **Given** the conceptual explanations with official documentation links, **When** the user completes the notebook, **Then** they can identify the key components of Agent 365 (Agent IDs, blueprints, Entra ID integration) and know where to find detailed reference material
4. **Given** the introduction material, **When** the user finishes, **Then** they understand when to use Agent 365 versus other identity solutions and can navigate to official documentation for deeper exploration

---

### User Story 2 - Creating Agent Identities via REST API (Priority: P2)

A developer needs to create and manage agent identities programmatically using REST API calls. They want step-by-step guidance with working code examples that demonstrate the complete lifecycle: authentication, creation, retrieval, and deletion of agent identities from existing blueprints.

**Why this priority**: This is the core technical implementation skill. Once users understand concepts (P1), they need practical hands-on experience creating agent identities, which is the foundation for any Agent 365 integration.

**Independent Test**: Can be tested by executing the notebook and verifying that agent IDs are successfully created, retrieved, and deleted using REST API calls. User should be able to see their created agent IDs in the Azure portal or via API responses.

**Acceptance Scenarios**:

1. **Given** valid Azure credentials and permissions, **When** the user runs the authentication cells, **Then** they successfully obtain an access token for Microsoft Graph API
2. **Given** an authenticated session, **When** the user executes the agent creation code, **Then** a new agent identity is created and a unique agent ID is returned
3. **Given** an existing agent ID, **When** the user runs the retrieval code, **Then** the agent details are fetched and displayed
4. **Given** an agent ID, **When** the user executes the deletion code, **Then** the agent identity is removed and confirmed via API response
5. **Given** step-by-step code cells, **When** the user follows along, **Then** they understand the request structure, required headers, and response handling for each REST operation

---

### User Story 3 - Using Agent Identities with Entra ID SDK (Priority: P3)

A developer wants to use created agent identities in real-world scenarios using the official Python SDK (microsoft-identity-web for Python). They need examples showing how to authenticate as an agent identity and perform actual operations (not just CRUD) that demonstrate the practical usage of agent identities with Entra ID.

**Why this priority**: After learning how to create agent identities via REST API (P2), developers need to see how these identities are actually USED in production scenarios. The SDK provides the production-ready approach for agent authentication and operational usage. This builds on P1 and P2 knowledge.

**Independent Test**: Can be tested by installing the required SDK packages and executing notebook cells that demonstrate agent authentication and real operational scenarios (e.g., accessing resources, making authenticated calls, demonstrating agent permissions) using agent identities created in P2.

**Acceptance Scenarios**:

1. **Given** the required SDK installed, **When** the user runs SDK import cells, **Then** all dependencies load without errors
2. **Given** an agent identity created via REST API, **When** the user executes SDK authentication code, **Then** they successfully authenticate AS the agent identity using the SDK
3. **Given** an authenticated agent context, **When** the user runs Azure resource access examples, **Then** they can successfully call Microsoft Graph API or access Azure storage using the agent identity
4. **Given** Azure AI Search configured with document-level RBAC, **When** the user executes the RBAC demonstration code, **Then** the agent identity successfully accesses only documents it has permissions for, demonstrating fine-grained access control
5. **Given** operational scenarios, **When** the user completes the notebook, **Then** they understand how to use agent identities for production use cases including resource access and permission-based operations

---

### Edge Cases

- What happens when the user lacks required Azure permissions to create agent identities?
- How does the notebook handle expired authentication tokens during long sessions?
- What if the user tries to create an agent ID with invalid parameters or naming conventions?
- How are API rate limits or throttling scenarios explained and handled?
- What happens when network connectivity is lost during API calls?
- How does the notebook handle Python 3.14 environment compatibility if users have older versions?
- What happens when an agent identity attempts to access Azure AI Search documents it doesn't have RBAC permissions for?
- How are permission denied scenarios demonstrated and explained in the RBAC examples?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Notebooks MUST be compatible with Python 3.14 runtime environment
- **FR-002**: Three separate notebook files MUST be created (01-introduction.ipynb, 02-rest-api.ipynb, 03-sdk-usage.ipynb), each running independently without requiring execution of other notebooks
- **FR-003**: Notebooks MUST include clear, concise explanatory markdown cells before each code section
- **FR-004**: Introduction notebook MUST explain Agent 365 core concepts (agent identities, blueprints, Entra ID integration) using conceptual explanations and non-operational code examples (diagrams, JSON structures, concept illustrations) that run without requiring Azure setup
- **FR-005**: REST API notebook MUST demonstrate complete CRUD operations (Create, Read, Delete) for agent identities using Microsoft Graph API, assuming pre-existing agent blueprints are available
- **FR-006**: REST API notebook MUST include working authentication code to obtain access tokens
- **FR-007**: SDK notebook MUST demonstrate practical operational usage of agent identities (not CRUD) using the official Python SDK for Entra ID, showing how to authenticate as an agent and perform real-world operations including Azure resource access and Azure AI Search document-level RBAC demonstration
- **FR-008**: All code cells MUST be executable and produce expected output when run in sequence
- **FR-009**: Notebooks MUST include prerequisites section listing required Azure permissions and setup steps
- **FR-010**: Error handling examples MUST be included for common failure scenarios (authentication failures, permission errors, API errors)
- **FR-011**: Each notebook MUST include extensive links to official Microsoft documentation for reference, enabling users to perform independent deep dives into specific topics
- **FR-012**: Code examples MUST follow Python best practices and PEP 8 style guidelines
- **FR-013**: Notebooks MUST include environment setup instructions (dependencies, configuration)
- **FR-014**: Sensitive information (API keys, tenant IDs, secrets) MUST NOT be hardcoded; notebooks must use environment variables or secure configuration
- **FR-015**: Each notebook MUST have a clear learning objective stated at the beginning
- **FR-016**: Notebooks MUST include cleanup instructions to delete test resources created during the tutorial
- **FR-017**: SDK notebook MUST include a demonstration of Azure AI Search document-level RBAC, showing how agent identities can access specific documents based on assigned permissions

### Assumptions

- Users have basic Python programming knowledge
- Users have access to an Azure subscription with appropriate permissions
- Users can create Azure App Registrations for authentication
- Users have Jupyter environment set up locally or access to JupyterLab/Google Colab
- Introduction notebook (P1) does not require Azure access or API credentials; only P2 and P3 require active Azure subscription
- Users understand basic REST API concepts (HTTP methods, headers, JSON)
- Standard Azure authentication patterns (OAuth 2.0, client credentials flow) are used
- Performance expectations align with typical educational notebook usage (seconds per cell, not sub-second)
- Pre-existing agent blueprints are available in the Azure environment for creating agent identities
- REST API is used for agent identity lifecycle management (create/delete); SDK is used for operational usage scenarios
- Azure AI Search instance is available with sample documents configured for document-level RBAC demonstration
- Agent identities can be assigned specific permissions to Azure AI Search documents for RBAC testing

### Key Entities

- **Agent Identity**: Represents a non-human identity (service, application, bot) in Agent 365 with unique identifier, creation timestamp, and associated metadata; created from an agent blueprint template
- **Agent Blueprint**: Pre-existing template or configuration that defines the properties, permissions, and capabilities for agent identities; used as the basis for creating agent identity instances
- **Access Token**: OAuth 2.0 token required for authenticating API requests to Microsoft Graph
- **Azure App Registration**: Application registration in Azure AD/Entra ID that provides credentials for authentication
- **Jupyter Notebook**: Interactive document containing executable code cells, markdown explanations, and outputs; delivered as three separate files (01-introduction.ipynb, 02-rest-api.ipynb, 03-sdk-usage.ipynb)
- **Azure AI Search Document**: Searchable content in Azure AI Search with document-level RBAC permissions that can be assigned to agent identities for fine-grained access control

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can complete the introduction notebook in under 15 minutes without Azure setup, answer basic comprehension questions about Agent 365 concepts, and know where to find official documentation for further learning
- **SC-002**: Users can successfully create at least one agent identity using the REST API notebook without external assistance
- **SC-003**: All code cells in each notebook execute successfully without errors when run sequentially in a properly configured environment
- **SC-004**: 90% of users can complete each notebook on first attempt without getting blocked by errors or unclear instructions
- **SC-005**: Users report understanding of when to use Agent 365 based on use case scenarios presented in the introduction
- **SC-006**: Users can adapt the provided code examples to their own use cases within 30 minutes of completing the tutorials
- **SC-007**: Each of the three notebooks (introduction, REST API, SDK usage) completes execution in under 5 minutes (excluding user reading time)
- **SC-008**: Users successfully authenticate and obtain valid access tokens on first attempt when following authentication instructions
- **SC-009**: 80% of users who complete the REST notebook feel confident to implement agent identity creation in their own projects
- **SC-010**: Notebooks receive positive feedback on clarity and conciseness (not overwhelming with complexity)
