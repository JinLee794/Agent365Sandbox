# Quickstart: Agent 365 Tutorial Jupyter Notebooks

**Feature**: Agent 365 Tutorial Jupyter Notebooks
**Estimated Setup Time**: 15-30 minutes (depending on Azure configuration)

## Overview

This quickstart guides you through setting up your environment to run the Agent 365 tutorial notebooks. The notebooks teach Agent 365 concepts through three progressive lessons:

1. **01-introduction.ipynb** - Agent 365 concepts (no Azure required) ✅
2. **02-rest-api.ipynb** - Create/delete agent identities via REST API (requires Azure)
3. **03-sdk-usage.ipynb** - Authenticate as agent + Azure AI Search RBAC (requires Azure)

## Prerequisites

### Required for All Notebooks

- **Python 3.11 or higher** (Python 3.13 recommended, Python 3.14 aspirational)
- **Jupyter environment**: JupyterLab, Jupyter Notebook, VS Code with Jupyter extension, or Google Colab
- **Git** (to clone this repository)

### Required for Notebooks 02 and 03 ONLY

- **Azure subscription** with appropriate permissions
- **Ability to create Azure App Registrations** in your tenant
- **Azure AI Search service** (for notebook 03 RBAC demo)
- **Pre-existing Agent Blueprint** in your Azure environment (or permissions to create one)

**Note**: Notebook 01 (Introduction) runs completely offline with no Azure credentials required!

---

## Installation Steps

### Step 1: Clone Repository and Install Dependencies

```bash
# Clone the repository
git clone <repository-url>
cd Agent365Sandbox

# Navigate to notebooks directory
cd notebooks

# Create virtual environment (recommended)
python -m venv venv

# Activate virtual environment
# On macOS/Linux:
source venv/bin/activate
# On Windows:
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

**Expected `requirements.txt` contents**:
```
jupyter>=1.0.0
jupyterlab>=4.0.0
requests>=2.31.0
msal>=1.31.0
azure-identity>=1.19.0
azure-search-documents>=11.5.2
python-dotenv>=1.0.0
matplotlib>=3.8.0
```

### Step 2: Verify Python Version

```bash
python --version
# Should output: Python 3.11.x or higher
```

If you have Python 3.10 or lower, upgrade before proceeding:
- **macOS/Linux**: Use `pyenv` or download from python.org
- **Windows**: Download installer from python.org
- **All platforms**: Consider using Anaconda/Miniconda for version management

---

## Azure Setup (Required for Notebooks 02 and 03)

### Step 3: Create Azure App Registration

1. Sign in to [Azure Portal](https://portal.azure.com)
2. Navigate to **Microsoft Entra ID** (formerly Azure Active Directory)
3. Select **App registrations** → **New registration**
4. Configure:
   - **Name**: "Agent 365 Tutorial"
   - **Supported account types**: Single tenant
   - **Redirect URI**: Leave empty (not needed for service authentication)
5. Click **Register**
6. **Save** the following values (you'll need them for `.env` file):
   - **Application (client) ID**
   - **Directory (tenant) ID**

### Step 4: Upload a Certificate (client assertion)

1. In your App Registration, go to **Certificates & secrets** → **Certificates**
2. Upload the **public** certificate file (`.cer` or `.pem`)
3. After upload, copy the **Thumbprint** (remove colons, use uppercase) → will be `AZURE_CLIENT_CERT_THUMBPRINT`
4. Keep the **private key PEM** locally; do **not** upload the private key to Azure
5. If you need to generate a self-signed cert for testing:
   ```bash
   # Generates private key (private.pem) and matching public cert (public.cer)
   openssl req -x509 -newkey rsa:2048 -keyout private.pem -out public.cer -days 365 -nodes -subj "/CN=Agent365Tutorial"
   ```
   Upload `public.cer` to Azure; reference `private.pem` locally via `AZURE_CLIENT_CERT_PATH`.

### Step 5: Grant API Permissions

1. In your App Registration, go to **API permissions**
2. Click **Add a permission**
3. Select **Microsoft Graph**
4. Select **Application permissions** (not Delegated)
5. Search and add the following permissions:
   - `Directory.ReadWrite.All` (for creating/deleting agent identities)
   - `Application.ReadWrite.All` (for managing service principals)
6. Click **Add permissions**
7. **CRITICAL**: Click **Grant admin consent for [your tenant]**
   - You must be a tenant admin OR request admin approval

### Step 6: Verify Agent Blueprint Exists

**Option A: Use Existing Blueprint**
1. Ask your Azure admin for an existing Agent Blueprint ID
2. Save the Blueprint ID for later use in notebooks

**Option B: Create Blueprint (if you have permissions)**
1. Follow [Microsoft documentation for creating Agent Blueprints](https://learn.microsoft.com/en-us/entra/agent-id/identity-platform/create-delete-agent-identities)
2. Save the created Blueprint ID

### Step 7: Setup Azure AI Search (Required for Notebook 03)

**Option A: Use Existing Search Service**
1. Get the endpoint URL (e.g., `https://your-search-service.search.windows.net`)
2. Ensure your App Registration has appropriate permissions to access the service

**Option B: Create New Search Service**
1. In Azure Portal, create a new Azure AI Search service
2. Choose **Free** tier for tutorial purposes
3. Once created, navigate to **Keys** and copy the endpoint URL
4. Configure RBAC (see [Azure AI Search RBAC documentation](https://learn.microsoft.com/en-us/azure/search/search-security-rbac))

---

## Environment Configuration

### Step 8: Create `.env` File

1. In the `notebooks/` directory, copy the example file:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` with your actual Azure credentials:
   ```env
   # Azure App Registration credentials (certificate-based)
   AZURE_TENANT_ID=your-tenant-id-here
   AZURE_CLIENT_ID=your-application-client-id-here

   # Private key PEM that matches the public cert uploaded to the app registration
   AZURE_CLIENT_CERT_PATH=./certs/your-private-key.pem

   # Cert thumbprint from Azure Portal (Certificates & secrets → Certificates). Remove colons, uppercase.
   AZURE_CLIENT_CERT_THUMBPRINT=YOURCERTTHUMBPRINT

   # Agent Blueprint (from Step 6)
   AGENT_BLUEPRINT_ID=your-blueprint-id-here

   # Azure AI Search (from Step 7, for notebook 03)
   AZURE_SEARCH_ENDPOINT=https://your-search-service.search.windows.net
   AZURE_SEARCH_INDEX_NAME=agent365-demo
   ```

3. **IMPORTANT**: Verify `.env` is listed in `.gitignore` (prevents accidental commits)

**Security Checklist**:
- ✅ `.env` file created with real credentials
- ✅ `.env` is in `.gitignore`
- ✅ Private key stays local; only the public cert is uploaded
- ✅ Never commit `.env` to version control
- ✅ Rotate certificate if accidentally exposed

---

## Running the Notebooks

### Step 9: Launch Jupyter

**Option A: JupyterLab (Recommended)**
```bash
jupyter lab
```

**Option B: Jupyter Notebook (Classic)**
```bash
jupyter notebook
```

**Option C: VS Code**
1. Open VS Code
2. Install "Jupyter" extension
3. Open notebooks directory
4. Click on any `.ipynb` file

**Option D: Google Colab**
1. Upload notebooks to Google Drive
2. Open with Google Colab
3. Upload `.env` file manually (or set environment variables in notebook)

### Step 10: Execute Notebooks in Order

**Recommended Learning Path**:

1. **Start with 01-introduction.ipynb**
   - ✅ No Azure credentials needed
   - Completes in ~15 minutes
   - Builds conceptual foundation

2. **Proceed to 02-rest-api.ipynb**
   - ⚠️ Requires Azure credentials (`.env` file)
   - Hands-on: Create and delete agent identities
   - Completes in ~20-30 minutes

3. **Finish with 03-sdk-usage.ipynb**
   - ⚠️ Requires Azure credentials + Azure AI Search
   - Real-world usage: Authenticate as agent, access resources
   - Completes in ~20-30 minutes

**Execution Tips**:
- Run cells **in sequence** from top to bottom
- Each notebook is independent (no need to run previous notebooks first)
- Look for cells marked ⚠️ "Prerequisites" - run these first
- Check for ✅ checkmarks after each section for validation
- Run "Cleanup" cells at the end to delete test resources

---

## Troubleshooting

### Python Version Issues

**Error**: `ModuleNotFoundError: No module named 'azure.identity'`
**Solution**: Ensure you activated the virtual environment and ran `pip install -r requirements.txt`

**Error**: Package incompatibility with Python 3.14
**Solution**: Downgrade to Python 3.13:
```bash
pyenv install 3.13.0
pyenv local 3.13.0
python -m venv venv --python=python3.13
```

### Azure Authentication Errors

**Error**: `401 Unauthorized` when calling Microsoft Graph API
**Possible Causes**:
1. Certificate thumbprint mismatch or expired certificate → Re-upload cert and update thumbprint (no colons, uppercase)
2. Private key path incorrect or unreadable → Fix `AZURE_CLIENT_CERT_PATH` and ensure file permissions allow reading
3. Missing admin consent → Re-grant admin consent (Step 5)
4. Incorrect tenant/client ID → Verify `.env` values match Azure Portal

**Error**: `403 Forbidden` - insufficient permissions
**Possible Causes**:
1. API permissions not granted → Check Step 5
2. Admin consent not given → Request admin approval
3. Wrong permission type (Delegated vs. Application) → Re-configure permissions

### Azure AI Search Issues

**Error**: Cannot connect to Azure AI Search endpoint
**Possible Causes**:
1. Incorrect endpoint URL → Verify format: `https://[service-name].search.windows.net`
2. Network restrictions → Check firewall/IP whitelisting in Azure AI Search
3. Missing authentication → Ensure `azure-identity` is configured correctly

**Error**: No search results returned (RBAC filtering)
**Expected Behavior**: This may be intentional! Notebook 03 demonstrates access control. If agent doesn't have permissions, zero results is correct.

### Environment Variable Issues

**Error**: `ValueError: Missing required environment variables`
**Solution**:
1. Verify `.env` file exists in `notebooks/` directory (same location as `.ipynb` files)
2. Check `.env` has no typos in variable names (case-sensitive)
3. Restart Jupyter kernel after editing `.env`

---

## Next Steps

After completing the quickstart setup:

1. **Run 01-introduction.ipynb** to learn Agent 365 concepts
2. **Explore 02-rest-api.ipynb** to create agent identities
3. **Experiment with 03-sdk-usage.ipynb** for production patterns
4. **Read official documentation** linked within each notebook
5. **Adapt code examples** to your own use cases

---

## Additional Resources

**Official Microsoft Documentation**:
- [Agent ID Overview](https://learn.microsoft.com/en-us/entra/agent-id/overview)
- [Create/Delete Agent Identities](https://learn.microsoft.com/en-us/entra/agent-id/identity-platform/create-delete-agent-identities?tabs=microsoft-graph-api)
- [Azure Identity SDK for Python](https://learn.microsoft.com/en-us/python/api/overview/azure/identity-readme)
- [Azure AI Search Security](https://learn.microsoft.com/en-us/azure/search/search-security-rbac)

**Support**:
- For Azure portal issues → [Azure Support](https://azure.microsoft.com/support/)
- For notebook bugs → Open an issue in this repository
- For Python/Jupyter help → [Jupyter Documentation](https://jupyter.org/documentation)

**Estimated Costs** (Azure):
- App Registration: **Free**
- Agent Identities: **Free** (included in Entra ID)
- Azure AI Search (Free tier): **Free** (limited to 50MB storage, 10k documents)
- Total for tutorial: **~$0 if using free tiers**

---

## Security Best Practices

🔒 **Never commit credentials**:
- Keep `.env` in `.gitignore`
- Never hardcode secrets or private keys in notebooks
- Rotate certificates regularly (every 6-12 months)

🔒 **Limit permissions**:
- Use principle of least privilege
- Create separate App Registration for tutorials (not production)
- Delete agent identities after testing

🔒 **Clean up resources**:
- Run cleanup cells in notebooks
- Delete App Registration when done with tutorials
- Remove API permissions after tutorial completion

---

## Quick Reference

| Notebook | Azure Required? | Duration | Key Learning |
|----------|----------------|----------|--------------|
| 01-introduction.ipynb | ❌ No | ~15 min | Agent 365 concepts |
| 02-rest-api.ipynb | ✅ Yes | ~30 min | Create/delete agents via API |
| 03-sdk-usage.ipynb | ✅ Yes | ~30 min | Authenticate + RBAC demo |

**Total Learning Time**: ~75 minutes

**Setup Time**: 15-30 minutes (one-time)

Ready to start? Open **01-introduction.ipynb** and begin learning! 🚀
