# Data Model: Agent 365 Tutorial Jupyter Notebooks

**Feature**: Agent 365 Tutorial Jupyter Notebooks
**Date**: 2026-01-10

## Overview

This feature is educational/documentation focused - the "data model" represents the conceptual entities users will learn about and interact with via Microsoft Graph API and Azure services. No application database or persistence layer is required.

## Entities

### Agent Identity

**Purpose**: Represents a non-human identity (service principal, application, bot) in Microsoft Entra ID with Agent 365 capabilities.

**Attributes**:
- `id` (string, UUID): Unique identifier assigned by Azure upon creation
- `displayName` (string): Human-readable name for the agent identity
- `createdDateTime` (ISO 8601 timestamp): When the agent identity was created
- `agentType` (string): Type classification (e.g., "service", "bot", "application")
- `blueprintId` (string, UUID): Reference to the agent blueprint used for creation
- `status` (enum: "active", "disabled", "deleted"): Current lifecycle state
- `permissions` (array of permission objects): Assigned permissions/scopes

**Relationships**:
- **Created FROM**: Agent Blueprint (many-to-one - multiple identities can be created from one blueprint)
- **Assigned TO**: Azure Resources (many-to-many - one identity can access multiple resources, one resource can be accessed by multiple identities)

**Validation Rules**:
- `displayName` must be 1-256 characters
- `id` is immutable after creation
- `blueprintId` must reference an existing, valid blueprint
- Cannot be deleted if currently assigned to active resources (soft delete recommended)

**State Transitions**:
```
[Created] → active
active → disabled (revoke access)
disabled → active (re-enable)
active|disabled → deleted (permanent removal)
```

**API Representation** (Microsoft Graph API):
```json
{
  "id": "12345678-1234-1234-1234-123456789abc",
  "displayName": "Tutorial Demo Agent",
  "createdDateTime": "2026-01-10T12:00:00Z",
  "agentType": "service",
  "blueprintId": "87654321-4321-4321-4321-cba987654321",
  "status": "active"
}
```

---

### Agent Blueprint

**Purpose**: Pre-configured template defining the properties, permissions, and capabilities for agent identities.

**Attributes**:
- `id` (string, UUID): Unique identifier for the blueprint
- `name` (string): Blueprint name
- `description` (string): Purpose and use case description
- `defaultPermissions` (array of permission objects): Permissions granted to identities created from this blueprint
- `allowedResourceTypes` (array of strings): Types of Azure resources this blueprint can access
- `createdDateTime` (ISO 8601 timestamp): Blueprint creation date
- `version` (string, semver): Blueprint schema version

**Relationships**:
- **Creates**: Agent Identity (one-to-many - one blueprint creates multiple identities)

**Validation Rules**:
- `name` must be unique within tenant
- `defaultPermissions` must be valid Azure AD permission scopes
- Blueprint cannot be deleted if agent identities are still using it

**Assumptions**:
- Blueprints are **pre-existing** in the Azure environment for tutorial purposes
- Notebooks demonstrate **using** blueprints to create identities, not creating the blueprints themselves

**API Representation** (Microsoft Graph API):
```json
{
  "id": "87654321-4321-4321-4321-cba987654321",
  "name": "Basic Service Agent Blueprint",
  "description": "Template for service agents with read-only access",
  "defaultPermissions": [
    {"scope": "https://graph.microsoft.com/.default", "type": "application"}
  ],
  "allowedResourceTypes": ["Microsoft.Storage", "Microsoft.Search"],
  "version": "1.0.0"
}
```

---

### Access Token

**Purpose**: OAuth 2.0 bearer token used to authenticate API requests to Microsoft Graph and Azure services.

**Attributes**:
- `access_token` (string, JWT): The actual token value
- `token_type` (string): Always "Bearer" for OAuth 2.0
- `expires_in` (integer, seconds): Token lifetime (typically 3600 seconds / 1 hour)
- `scope` (string): Granted permissions scope
- `issued_at` (timestamp): When token was issued

**Lifecycle**:
- **Acquisition**: Obtained via Azure App Registration credentials (client ID + secret)
- **Usage**: Included in HTTP Authorization header for API calls
- **Expiration**: Must be refreshed after `expires_in` duration
- **Revocation**: Tokens are revoked when credentials are rotated

**Validation Rules**:
- Tokens are opaque to clients (don't parse or validate JWT structure in notebooks)
- Must be treated as secrets (never log, commit, or display in output)
- Expired tokens result in 401 Unauthorized responses

**Notebook Usage**:
- P2: Obtain token for creating/deleting agent identities
- P3: Obtain token AS agent identity for resource access

---

### Azure App Registration

**Purpose**: Application registration in Microsoft Entra ID providing credentials for authentication.

**Attributes**:
- `applicationId` (string, UUID): Client ID
- `tenantId` (string, UUID): Azure AD tenant identifier
- `clientSecret` (string): Secret credential (password)
- `displayName` (string): Application name
- `permissions` (array): Configured API permissions

**Security Requirements**:
- Secrets stored in `.env` file (never hardcoded)
- `.env` file excluded from version control (.gitignore)
- `.env.example` provided as template without actual secrets

---

### Azure AI Search Document

**Purpose**: Searchable content in Azure AI Search with document-level RBAC permissions for P3 demonstration.

**Attributes**:
- `id` (string): Document identifier
- `content` (string): Document text content
- `metadata` (object): Additional fields (title, author, category, etc.)
- `aclPermissions` (array of principal IDs): Access control list defining which identities can access this document

**RBAC Demonstration**:
- Documents are pre-configured with different permission sets
- Agent identity A can access documents [1, 2, 3]
- Agent identity B can access documents [2, 3, 4]
- P3 notebook demonstrates accessing allowed vs. denied documents

**API Representation** (Azure Search):
```json
{
  "id": "doc-001",
  "content": "Sample document for RBAC demonstration",
  "metadata": {
    "title": "Introduction to Agent 365",
    "category": "tutorial"
  },
  "aclPermissions": ["12345678-1234-1234-1234-123456789abc"]
}
```

---

## Entity Relationships Diagram

```
┌─────────────────────┐
│  Agent Blueprint    │
│  (Pre-existing)     │
└──────────┬──────────┘
           │
           │ creates (1:N)
           ▼
┌─────────────────────┐         ┌──────────────────────┐
│  Agent Identity     │─────────│  Access Token        │
│  (Created in P2)    │  uses   │  (Obtained for auth) │
└──────────┬──────────┘         └──────────────────────┘
           │
           │ accesses (M:N)
           ▼
┌─────────────────────┐
│ Azure AI Search     │
│ Documents (P3 demo) │
└─────────────────────┘
```

## Notes for Implementation

1. **No Application Database**: This is educational content - all entities exist in Azure/Entra ID, accessed via APIs
2. **Read-Heavy Operations**: Notebooks primarily READ blueprints, CREATE/DELETE identities, and DEMONSTRATE access patterns
3. **Error Handling**: Notebooks should gracefully handle:
   - Missing blueprints (clear error: "Blueprint XYZ not found")
   - Permission errors (clear error: "Agent lacks permissions for this resource")
   - Expired tokens (clear error: "Token expired, re-run authentication cell")
4. **Data Cleanup**: P2 and P3 notebooks include cleanup cells to delete created agent identities

## References

- [Microsoft Graph API - Service Principals](https://learn.microsoft.com/en-us/graph/api/resources/serviceprincipal)
- [Agent ID Documentation](https://learn.microsoft.com/en-us/entra/agent-id/identity-platform/create-delete-agent-identities)
- [Azure AI Search RBAC](https://learn.microsoft.com/en-us/azure/search/search-security-rbac)
