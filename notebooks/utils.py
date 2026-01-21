import datetime, json, os, subprocess, requests, time, traceback
import msal

# Define ANSI escape code constants vor clarity in the print commands below
RESET_FORMATTING = "\x1b[0m"
BOLD_BLUE = "\x1b[1;34m"
BOLD_RED = "\x1b[1;31m"
BOLD_GREEN = "\x1b[1;32m"
BOLD_YELLOW = "\x1b[1;33m"

# =============================================================================
# Credential Utilities
# =============================================================================
# Shared credential functions used across notebooks
#
# Agent Identity Blueprint OAuth Flows:
# https://learn.microsoft.com/en-us/entra/agent-id/identity-platform/agent-oauth-protocols
#
# 1. OBO Flow (On-Behalf-Of) - Agent acts on behalf of signed-in user
#    https://learn.microsoft.com/en-us/entra/agent-id/identity-platform/agent-on-behalf-of-oauth-flow
#
# 2. Autonomous App Flow - Agent acts autonomously (app-only)
#    https://learn.microsoft.com/en-us/entra/agent-id/identity-platform/agent-autonomous-app-oauth-flow
#
# 3. Agent User Impersonation - Agent impersonates an agent user
#    https://learn.microsoft.com/en-us/entra/agent-id/identity-platform/agent-user-oauth-flow

_cached_user_credential = None
_cached_user_token = None

def get_user_credential(tenant_id: str = None, force_refresh: bool = False):
    """
    Get a credential for authenticating as a human user via interactive browser.

    This is used for:
    - Direct Azure resource access (Search, Foundry, etc.)
    - Obtaining user tokens for Agent OBO flows

    Caches the credential to avoid repeated auth prompts.
    Falls back to device code if browser auth fails.

    Args:
        tenant_id: Azure AD tenant ID. If not provided, uses AZURE_TENANT_ID env var.
        force_refresh: If True, clears cache and re-authenticates.

    Returns:
        Azure credential object suitable for SDK clients.
    """
    global _cached_user_credential

    if force_refresh:
        _cached_user_credential = None

    if _cached_user_credential is not None:
        return _cached_user_credential

    from azure.identity import InteractiveBrowserCredential, DeviceCodeCredential

    tenant = tenant_id or os.getenv('AZURE_TENANT_ID')

    try:
        _cached_user_credential = InteractiveBrowserCredential(tenant_id=tenant)
        # Test the credential
        _cached_user_credential.get_token("https://management.azure.com/.default")
        return _cached_user_credential
    except Exception:
        # Fall back to device code
        _cached_user_credential = DeviceCodeCredential(tenant_id=tenant)
        return _cached_user_credential


def get_user_token_for_agent(scope: str = None, tenant_id: str = None) -> str:
    """
    Get a user token with audience set to the Agent Blueprint for OBO flow.

    This token (Tc) is used in step 2 of the OBO flow where the client
    sends the user token to the agent identity blueprint.

    Flow: User authenticates → Get token with aud=AgentBlueprint → Use for OBO

    Args:
        scope: OAuth scope. Defaults to api://AZURE_CLIENT_ID/access_agent
        tenant_id: Azure AD tenant ID.

    Returns:
        User access token string for OBO exchange.

    Docs: https://learn.microsoft.com/en-us/entra/agent-id/identity-platform/agent-on-behalf-of-oauth-flow
    """
    blueprint_client_id = os.getenv('AZURE_CLIENT_ID')
    if not blueprint_client_id:
        raise ValueError("AZURE_CLIENT_ID not set. Run a365.ps1 to create Agent Blueprint.")

    # Default scope for agent access
    if not scope:
        scope = f"api://{blueprint_client_id}/access_agent"

    credential = get_user_credential(tenant_id)
    token = credential.get_token(scope)
    return token.token


def get_agent_obo_token(
    resource_scope: str,
    user_token: str = None,
    tenant_id: str = None,
    blueprint_client_id: str = None,
    blueprint_secret: str = None,
) -> dict:
    """
    Exchange user token for agent resource token using On-Behalf-Of flow.

    This implements the Agent OBO flow:
    1. User authenticates and gets token (Tc) with aud=AgentBlueprint
    2. Agent Blueprint exchanges Tc + credentials for T1 (exchange token)
    3. Agent Identity uses T1 + Tc to get resource token (TR)

    For notebook scenarios, we simplify to:
    - Get user token for agent scope
    - Exchange for resource token using OBO

    Args:
        resource_scope: Target resource scope (e.g., https://search.azure.com/.default)
        user_token: User token for OBO. If None, obtains one interactively.
        tenant_id: Azure AD tenant ID.
        blueprint_client_id: Agent Blueprint client ID.
        blueprint_secret: Agent Blueprint client secret.

    Returns:
        Dict with 'access_token', 'token_type', 'expires_in'

    Docs: https://learn.microsoft.com/en-us/entra/agent-id/identity-platform/agent-on-behalf-of-oauth-flow
    """
    tenant = tenant_id or os.getenv('AZURE_TENANT_ID')
    client_id = blueprint_client_id or os.getenv('AZURE_CLIENT_ID')
    client_secret = blueprint_secret or os.getenv('AZURE_CLIENT_SECRET')

    if not all([tenant, client_id, client_secret]):
        raise ValueError(
            "Missing required env vars: AZURE_TENANT_ID, AZURE_CLIENT_ID, AZURE_CLIENT_SECRET. "
            "Run a365.ps1 to configure Agent Blueprint."
        )

    # Get user token if not provided
    if not user_token:
        user_token = get_user_token_for_agent(tenant_id=tenant)

    # OBO token exchange
    token_url = f"https://login.microsoftonline.com/{tenant}/oauth2/v2.0/token"

    data = {
        'client_id': client_id,
        'client_secret': client_secret,
        'scope': resource_scope,
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': user_token,
        'requested_token_use': 'on_behalf_of',
    }

    response = requests.post(token_url, data=data)

    if not response.ok:
        error_data = response.json()
        error_code = error_data.get('error', 'unknown')
        error_desc = error_data.get('error_description', response.text)

        # Provide helpful guidance for common errors
        if 'AADSTS65001' in error_desc:
            print(f"\n❌ Admin consent required for OBO flow.")
            print(f"   Grant consent at: https://portal.azure.com/#view/Microsoft_AAD_IAM/StartboardApplicationsMenuBlade/~/AppAppsPreview")
            print(f"   Find app: {client_id}")
            print(f"   Go to: API permissions → Grant admin consent")
        elif 'AADSTS50013' in error_desc:
            print(f"\n❌ Invalid assertion (user token). May need to re-authenticate.")
        elif 'AADSTS82001' in error_desc:
            print(f"\n❌ Agent Blueprint cannot request app-only tokens.")
            print(f"   Use get_user_credential() for direct access, or")
            print(f"   Use OBO flow with a user token.")

        raise Exception(f"OBO token exchange failed: {error_code} - {error_desc}")

    return response.json()


class AgentOBOCredential:
    """
    Custom credential that uses Agent OBO flow for Azure SDK clients.

    This credential wraps the OBO flow to work with Azure SDK clients
    that expect a TokenCredential interface.

    Usage:
        credential = AgentOBOCredential()
        client = SearchClient(endpoint, index, credential=credential)

    Docs: https://learn.microsoft.com/en-us/entra/agent-id/identity-platform/agent-on-behalf-of-oauth-flow
    """

    def __init__(self, tenant_id: str = None, blueprint_client_id: str = None, blueprint_secret: str = None):
        self.tenant_id = tenant_id or os.getenv('AZURE_TENANT_ID')
        self.client_id = blueprint_client_id or os.getenv('AZURE_CLIENT_ID')
        self.client_secret = blueprint_secret or os.getenv('AZURE_CLIENT_SECRET')
        self._user_token = None
        self._token_cache = {}

    def get_token(self, *scopes, **kwargs):
        """Get token for the specified scopes using OBO flow."""
        from azure.core.credentials import AccessToken

        scope = scopes[0] if scopes else "https://management.azure.com/.default"

        # Check cache
        if scope in self._token_cache:
            cached = self._token_cache[scope]
            if cached['expires_on'] > time.time() + 60:  # 60s buffer
                return AccessToken(cached['access_token'], int(cached['expires_on']))

        # Get fresh user token for agent
        self._user_token = get_user_token_for_agent(tenant_id=self.tenant_id)

        # Exchange via OBO
        result = get_agent_obo_token(
            resource_scope=scope,
            user_token=self._user_token,
            tenant_id=self.tenant_id,
            blueprint_client_id=self.client_id,
            blueprint_secret=self.client_secret,
        )

        expires_on = time.time() + result.get('expires_in', 3600)
        self._token_cache[scope] = {
            'access_token': result['access_token'],
            'expires_on': expires_on,
        }

        return AccessToken(result['access_token'], int(expires_on))


def get_graph_token(config: dict) -> str:
    """
    Get a Microsoft Graph API token using MSAL.

    Supports both client secret and certificate authentication.

    Args:
        config: Dictionary with keys:
            - tenant_id: Azure AD tenant ID
            - client_id: Application (client) ID
            - credential_type: 'secret' or 'certificate'

    Returns:
        Access token string for Microsoft Graph API.

    Raises:
        Exception: If token acquisition fails.
    """
    authority = f"https://login.microsoftonline.com/{config['tenant_id']}"

    if config['credential_type'] == 'secret':
        app = msal.ConfidentialClientApplication(
            client_id=config['client_id'],
            client_credential=os.getenv('AZURE_CLIENT_SECRET'),
            authority=authority
        )
    else:
        cert_path = os.getenv('AZURE_CLIENT_CERT_PATH')
        with open(cert_path, 'r') as f:
            private_key = f.read()
        app = msal.ConfidentialClientApplication(
            client_id=config['client_id'],
            client_credential={
                'private_key': private_key,
                'thumbprint': os.getenv('AZURE_CLIENT_CERT_THUMBPRINT')
            },
            authority=authority
        )

    result = app.acquire_token_for_client(['https://graph.microsoft.com/.default'])
    if 'access_token' not in result:
        raise Exception(f"Token acquisition failed: {result}")
    return result['access_token']


def get_agent_credential(tenant_id: str, blueprint_id: str, client_secret: str):
    """
    Get a credential using the agent blueprint identity.

    Use this when you want agents to operate under their own identity
    rather than the calling user's identity.

    Args:
        tenant_id: Azure AD tenant ID
        blueprint_id: Agent blueprint application ID (from a365.generated.config.json)
        client_secret: Agent blueprint client secret

    Returns:
        ClientSecretCredential for the agent identity.
    """
    from azure.identity import ClientSecretCredential

    return ClientSecretCredential(
        tenant_id=tenant_id,
        client_id=blueprint_id,
        client_secret=client_secret,
    )

print_command = lambda command='': print(f"⚙️ {BOLD_BLUE}Running: {command} {RESET_FORMATTING}")
print_error = lambda message, output='', duration='': print(f"❌ {BOLD_YELLOW}{message}{RESET_FORMATTING} ⌚ {datetime.datetime.now().time()} {duration}{' ' if output else ''}{output}")
print_info = lambda message: print(f"👉🏽 {BOLD_BLUE}{message}{RESET_FORMATTING}")
print_message = lambda message, output='', duration='': print(f"👉🏽 {BOLD_GREEN}{message}{RESET_FORMATTING} ⌚ {datetime.datetime.now().time()} {duration}{' ' if output else ''}{output}")
print_ok = lambda message, output='', duration='': print(f"✅ {BOLD_GREEN}{message}{RESET_FORMATTING} ⌚ {datetime.datetime.now().time()} {duration}{' ' if output else ''}{output}")
print_warning = lambda message, output='', duration='': print(f"⚠️ {BOLD_YELLOW}{message}{RESET_FORMATTING} ⌚ {datetime.datetime.now().time()} {duration}{' ' if output else ''}{output}")

class Output(object):
    def __init__(self, success, text):
        self.success = success
        self.text = text

        try:
            self.json_data = json.loads(text)
        except:
            self.json_data = json.loads("{}")   # return an empty JSON object if the output is not valid JSON rather than None as that makes consuming it easier this way


def get_current_subscription():
    try:
        output = run("az account show", "Retrieved az account", "Failed to get the current az account")

        if output.success and output.json_data:
            subscription_id = output.json_data['id']
            subscription_name = output.json_data['name']
            print_info(f"Using Subscription ID: {subscription_id} ({subscription_name})")
            return subscription_id
        else:
            print_error("No current subscription found.")
            return None
    except Exception as e:
        print_error(f"Error retrieving current subscription: {e}")
        return None

# Retrieves resources in a resource group
def get_resources(resource_group_name, config):
    if not resource_group_name:
        print_error("Missing resource group name parameter.")
        return

    resources = {}
    try:
        ## retrieve resource group location
        output = run(f"az group show --name {resource_group_name}")

        if output.success:
            print_info(f"Using existing resource group '{resource_group_name}'")
            output = run(f"az group show --name {resource_group_name} -o json", "Retrieved resource group ", "Failed to retrieve resource group")
            if output.success and output.json_data:
                resources['resourceGroupLocation'] = output.json_data["location"]

                ## retrieve resources
                output = run(f'az resource list -g {resource_group_name} -o json', "Listed resources", "Failed to list resources")
                if output.success and output.json_data:
                    for resource in output.json_data:
                        match resource["type"].lower():
                            case "microsoft.operationalinsights/workspaces":
                                resources['logAnalyticsResourceId'] = resource["id"]
                                resources['logAnalyticsResourceName'] = resource["name"]
                            case "microsoft.insights/components":
                                resources['appInsightsResourceId'] = resource["id"]
                                resources['appInsightsResourceName'] = resource["name"]
                                output = run(f'az resource show -g {resource_group_name} -n {resource["name"]} --resource-type "microsoft.insights/components" -o json', "Retrieved App Insights resource", "Failed to retrieve App Insights resource")
                                if output.success and output.json_data:
                                    resources['appInsightsInstrumentationKey'] = output.json_data["properties"]["InstrumentationKey"]
                            case "microsoft.cognitiveservices/accounts":
                                resources['foundryResourceId'] = resource["id"]
                                resources['foundryResourceName'] = resource["name"]
                            case "microsoft.cognitiveservices/accounts/projects":
                                resources['foundryProjectId'] = resource["id"]
                                resources['foundryProjectName'] = resource["name"]
                            case "microsoft.apimanagement/service":
                                resources['apimResourceId'] = resource["id"]
                                resources['apimResourceName'] = resource["name"]
                                resources['apimPrincipalId'] = resource["identity"]["principalId"]
        else:
            return config

    except Exception as e:
        print_error(f"Error retrieving resources: {e}")

    return resources

# Cleans up resources associated with a deployment in a resource group
def cleanup_resources(deployment_name, resource_group_name = None):
    if not deployment_name:
        print_error("Missing deployment name parameter.")
        return

    if not resource_group_name:
        resource_group_name = f"lab-{deployment_name}"

    try:
        print_info(f"🧹 Cleaning up resource group '{resource_group_name}'...")

        # Show the deployment details
        output = run(f"az deployment group show --name {deployment_name} -g {resource_group_name} -o json", "Deployment retrieved", "Failed to retrieve the deployment")

        if output.success and output.json_data:
            provisioning_state = output.json_data.get("properties").get("provisioningState")
            print_info(f"Deployment provisioning state: {provisioning_state}")

            # Delete AI Foundry projects
            output = run(f'az resource list -g {resource_group_name} --resource-type "microsoft.cognitiveservices/accounts/projects"', "Retrieved AI Foundry projects", "Failed to list AI Foundry projects")
            if output.success and output.json_data:
                for resource in output.json_data:
                    print_info(f"Deleting AI Foundry project '{resource['name']}' in resource group '{resource_group_name}'...")
                    output = run(f'az resource delete --ids "{resource['id']}"', f"AI Foundry project '{resource['name']}' deleted", f"Failed to delete AI Foundry project '{resource['name']}'")

            # Delete and purge CognitiveService accounts
            output = run(f"az cognitiveservices account list -g {resource_group_name}", f"Listed CognitiveService accounts", f"Failed to list CognitiveService accounts")
            if output.success and output.json_data:
                for resource in output.json_data:
                    print_info(f"Deleting and purging Cognitive Service Account '{resource['name']}' in resource group '{resource_group_name}'...")
                    output = run(f"az cognitiveservices account delete -g {resource_group_name} -n {resource['name']}", f"Cognitive Services '{resource['name']}' deleted", f"Failed to delete Cognitive Services '{resource['name']}'")
                    output = run(f"az cognitiveservices account purge -g {resource_group_name} -n {resource['name']} -l \"{resource['location']}\"", f"Cognitive Services '{resource['name']}' purged", f"Failed to purge Cognitive Services '{resource['name']}'")

            # Delete and purge APIM resources
            output = run(f" az apim list -g {resource_group_name}", f"Listed APIM resources", f"Failed to list APIM resources")
            if output.success and output.json_data:
                for resource in output.json_data:
                    print_info(f"Deleting and purging API Management '{resource['name']}' in resource group '{resource_group_name}'...")
                    output = run(f"az apim delete -n {resource['name']} -g {resource_group_name} -y", f"API Management '{resource['name']}' deleted", f"Failed to delete API Management '{resource['name']}'")
                    output = run(f"az apim deletedservice purge --service-name {resource['name']} --location \"{resource['location']}\"", f"API Management '{resource['name']}' purged", f"Failed to purge API Management '{resource['name']}'")

            # Delete and purge Key Vault resources
            output = run(f"az keyvault list -g {resource_group_name}", f"Listed Key Vault resources", f"Failed to list Key Vault resources")
            if output.success and output.json_data:
                for resource in output.json_data:
                    print_info(f"Deleting and purging Key Vault '{resource['name']}' in resource group '{resource_group_name}'...")
                    output = run(f"az keyvault delete -n {resource['name']} -g {resource_group_name}", f"Key Vault '{resource['name']}' deleted", f"Failed to delete Key Vault '{resource['name']}'")
                    output = run(f"az keyvault purge -n {resource['name']} --location \"{resource['location']}\"", f"Key Vault '{resource['name']}' purged", f"Failed to purge Key Vault '{resource['name']}'")

            # Delete the resource group last
            print_message(f"🧹 Deleting resource group '{resource_group_name}'...")
            output = run(f"az group delete --name {resource_group_name} -y", f"Resource group '{resource_group_name}' deleted", f"Failed to delete resource group '{resource_group_name}'")

            print_message("🧹 Cleanup completed.")

    except Exception as e:
        print(f"An error occurred during cleanup: {e}")
        traceback.print_exc()

def create_resource_group(resource_group_name, resource_group_location = None):
    if not resource_group_name:
        print_error('Please specify the resource group name.')
    else:
        output = run(f"az group show --name {resource_group_name}")

        if output.success:
            print_info(f"Using existing resource group '{resource_group_name}'")
        else:
            if not resource_group_location:
                print_error('Please specify the resource group location.')
            else:
                print_info(f"Resource group {resource_group_name} does not yet exist. Creating the resource group now...")

                output = run(f"az group create --name {resource_group_name} --location {resource_group_location} --tags source=ai-gateway",
                    f"Resource group '{resource_group_name}' created",
                    f"Failed to create the resource group '{resource_group_name}'")

# Deletes a specific resource based on its type
def delete_resource(resource, resource_group_name):
    resource_name = resource.get("name")
    resource_type = resource.get("type")
    resource_location = resource.get("location")

    print(f"🗑 Deleting {resource_type} '{resource_name}' in resource group '{resource_group_name}'...")

    # API Management
    if resource_type == "Microsoft.ApiManagement/service":
        output = run(f"az apim delete -n {resource_name} -g {resource_group_name} -y", f"API Management '{resource_name}' deleted", f"Failed to delete API Management '{resource_name}'")

        output = run(f"az apim deletedservice purge --service-name {resource_name} --location \"{resource_location}\"", f"API Management '{resource_name}' purged", f"Failed to purge API Management '{resource_name}'")

    # Cognitive Services
    elif resource_type == "Microsoft.CognitiveServices/accounts":
        output = run(f"az cognitiveservices account delete -g {resource_group_name} -n {resource_name}", f"Cognitive Services '{resource_name}' deleted", f"Failed to delete Cognitive Services '{resource_name}'")

        output = run(f"az cognitiveservices account purge -g {resource_group_name} -n {resource_name} -l \"{resource_location}\"", f"Cognitive Services '{resource_name}' purged", f"Failed to purge Cognitive Services '{resource_name}'")

    # Key Vault
    elif resource_type == "Microsoft.KeyVault/vaults":
        output = run(f"az keyvault delete -n {resource_name} -g {resource_group_name}", f"Key Vault '{resource_name}' deleted", f"Failed to delete Key Vault '{resource_name}'")

def get_deployment_output(output, output_property, output_label = '', secure = False) -> str:
    try:
        deployment_output = output.json_data['properties']['outputs'][output_property]['value']

        if output_label:
            if secure:
                print_info(f"{output_label}: ****{deployment_output[-4:]}")
            else:
                print_info(f"{output_label}: {deployment_output}")

        return str(deployment_output)
    except Exception as e:
        error = f"Failed to retrieve output property: '{output_property}'\nError: {e}"
        print_error(error)
        raise Exception(error)

def print_response(response):
    print("Response headers: ", response.headers)

    if (response.status_code == 200):
        print_ok(f"Status Code: {response.status_code}")
        data = json.loads(response.text)
        print(json.dumps(data, indent=4))
    else:
        print_warning(f"Status Code: {response.status_code}")
        print(response.text)

def print_response_code(response):
    # Check the response status code and apply formatting
    if 200 <= response.status_code < 300:
        status_code_str = f"{BOLD_GREEN}{response.status_code} - {response.reason}{RESET_FORMATTING}"
    elif response.status_code >= 400:
        status_code_str = f"{BOLD_RED}{response.status_code} - {response.reason}{RESET_FORMATTING}"
    else:
        status_code_str = str(response.status_code)

    # Print the response status with the appropriate formatting
    print(f"Response status: {status_code_str}")

# Simple: print full error body (JSON if available, else raw text)
def print_full_http_error(response):
    try:
        data = response.json()
        print_error("Request failed. Full JSON body:", json.dumps(data, indent=2))
        # If ARM-style error present, surface message too
        if isinstance(data, dict) and isinstance(data.get("error"), dict):
            code = data["error"].get("code", "")
            msg = data["error"].get("message", "")
            if msg or code:
                print_error(f"Service error:", f"{code} - {msg}")
    except ValueError:
        print_error("Request failed. Full text body:", response.text or "")

def run(command, ok_message = '', error_message = '', print_output = False, print_command_to_run = True):
    if print_command_to_run:
        print_command(command)

    start_time = time.time()

    try:
        completed_process = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        output_text = completed_process.stdout
        success = completed_process.returncode == 0
    except subprocess.CalledProcessError as e:
        output_text = e.output.decode("utf-8")
        success = False

    minutes, seconds = divmod(time.time() - start_time, 60)

    print_message = print_ok if success else print_error

    if (ok_message or error_message):
        print_message(ok_message if success else error_message, output_text if not success or print_output  else "", f"[{int(minutes)}m:{int(seconds)}s]")

    return Output(success, output_text)

def create_bicep_params(policy_xml_filepath, parameters_filepath, bicep_parameters, replacements_list):
    # Read the specified policy XML file
    with open(policy_xml_filepath, 'r') as policy_xml_file:
        policy_template_xml = policy_xml_file.read()

    # Replace the placeholders in the policy XML with the actual values from the replacements_lists array
    for key, value in replacements_list:
        policy_template_xml = policy_template_xml.replace(key, str(value))

    # Set or update the policyXml parameter in the bicep parameters file
    bicep_parameters['parameters'].setdefault('policyXml', {})
    bicep_parameters['parameters']['policyXml']['value'] = policy_template_xml

    # Write the updated bicep parameters to the specified parameters file
    with open(parameters_filepath, 'w') as bicep_parameters_file:
        bicep_parameters_file.write(json.dumps(bicep_parameters))

    print(f"📝 Updated the policy XML in the bicep parameters file '{parameters_filepath}'")

    return bicep_parameters

def update_api_policy(subscription_id, resource_group_name, apim_service_name, api_id, policy_xml):
    # We first need to obtain an access token for the REST API
    output = run(f"az account get-access-token --resource https://management.azure.com/",
        f"Successfully obtained access token", f"Failed to obtain access token")

    if output.success and output.json_data:
        access_token = output.json_data['accessToken']

        print("Updating the API policy...")
        # https://learn.microsoft.com/en-us/rest/api/apimanagement/api-policy/create-or-update?view=rest-apimanagement-2024-06-01-preview
        url = f"https://management.azure.com/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{apim_service_name}/apis/{api_id}/policies/policy?api-version=2024-06-01-preview"
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {access_token}"
        }

        body = {
            "properties": {
                "format": "rawxml",
                "value": policy_xml
            }
        }

        response = requests.put(url, headers = headers, json = body)
        if 200 <= response.status_code < 300:
            print_response_code(response)
        else:
            print_response_code(response)
            print_full_http_error(response)

def update_api_operation_policy(subscription_id, resource_group_name, apim_service_name, api_id, operation_id, policy_xml):
    # We first need to obtain an access token for the REST API
    output = run(f"az account get-access-token --resource https://management.azure.com/",
        f"Successfully obtained access token", f"Failed to obtain access token")

    if output.success and output.json_data:
        access_token = output.json_data['accessToken']

        print("Updating the API policy...")
        # https://learn.microsoft.com/en-us/rest/api/apimanagement/api-policy/create-or-update?view=rest-apimanagement-2024-06-01-preview
        url = f"https://management.azure.com/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.ApiManagement/service/{apim_service_name}/apis/{api_id}/operations/{operation_id}/policies/policy?api-version=2024-06-01-preview"
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {access_token}"
        }

        body = {
            "properties": {
                "format": "rawxml",
                "value": policy_xml
            }
        }

        response = requests.put(url, headers = headers, json = body)
        print_response_code(response)

def get_debug_credentials(apim_service_id, api_id, expire_after = 'PT1H') -> str | None:
    request = {
        "credentialsExpireAfter": expire_after,
        "apiId": f"{apim_service_id}/apis/{api_id}",
        "purposes": ["tracing"]
    }
    output = run(f"az rest --method post --uri {apim_service_id}/gateways/managed/listDebugCredentials?api-version=2023-05-01-preview --body \"{str(request)}\"",
            "Retrieved APIM debug credentials", "Failed to get the APIM debug credentials")
    return output.json_data['token'] if output.success and output.json_data else None
        
def get_trace(apim_service_id, trace_id) -> str | None:
    request = {
        "traceId": trace_id
    }
    output = run(f"az rest --method post --uri {apim_service_id}/gateways/managed/listTrace?api-version=2023-05-01-preview --body \"{str(request)}\"",
            "Retrieved trace details", "Failed to get the trace details")
    return output.json_data if output.success and output.json_data else None
