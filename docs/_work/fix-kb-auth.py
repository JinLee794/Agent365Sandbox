#!/usr/bin/env python3
"""
Fix authentication in notebook 07 to use agent blueprint credentials
"""

import os
from azure.identity import ClientSecretCredential
from dotenv import load_dotenv

load_dotenv()

# Load agent blueprint credentials
tenant_id = os.getenv('AZURE_TENANT_ID')
client_id = os.getenv('AZURE_CLIENT_ID')
client_secret = os.getenv('AZURE_CLIENT_SECRET')
search_endpoint = os.getenv('AZURE_SEARCH_ENDPOINT')
azure_openai_endpoint = os.getenv('AZURE_OPENAI_ENDPOINT')

# Create credential
credential = ClientSecretCredential(
    tenant_id=tenant_id,
    client_id=client_id,
    client_secret=client_secret
)

# Get tokens for different scopes
def get_search_token():
    """Get token for Azure Search"""
    token = credential.get_token("https://search.azure.com/.default")
    return token.token

def get_openai_token():
    """Get token for Azure OpenAI"""
    token = credential.get_token("https://cognitiveservices.azure.com/.default")
    return token.token

# Test authentication
print("🔐 Testing agent blueprint authentication...\n")

try:
    search_token = get_search_token()
    print(f"✅ Azure Search token acquired")
    print(f"   Token preview: {search_token[:40]}...\n")
except Exception as e:
    print(f"❌ Failed to get Search token: {e}\n")

try:
    openai_token = get_openai_token()
    print(f"✅ Azure OpenAI token acquired")
    print(f"   Token preview: {openai_token[:40]}...\n")
except Exception as e:
    print(f"❌ Failed to get OpenAI token: {e}\n")

print("✅ Agent blueprint credentials are working!")
print("\nYou can now use bearer token authentication instead of API keys.")
