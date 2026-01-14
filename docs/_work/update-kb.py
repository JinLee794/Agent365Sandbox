#!/usr/bin/env python3
"""Update knowledge base with fresh API key."""
import requests
import os
from dotenv import load_dotenv

load_dotenv(override=True)

# Config
search_endpoint = os.getenv('AZURE_SEARCH_ENDPOINT')
azure_openai_endpoint = os.getenv('AZURE_OPENAI_ENDPOINT', '').rstrip('/')
azure_openai_api_key = os.getenv('AZURE_OPENAI_API_KEY')
azure_openai_deployment = os.getenv('AZURE_OPENAI_DEPLOYMENT', 'gpt-4o')
azure_openai_model = os.getenv('AZURE_OPENAI_MODEL', 'gpt-4o')

# Get search admin key
import subprocess
result = subprocess.run(
    f"az search admin-key show --resource-group {os.getenv('AZURE_RESOURCE_GROUP')} --service-name {os.getenv('AZURE_SEARCH_SERVICE_NAME')} --query primaryKey --output tsv",
    shell=True, capture_output=True, text=True
)
search_api_key = result.stdout.strip()

print(f"Search Endpoint: {search_endpoint}")
print(f"OpenAI Endpoint: {azure_openai_endpoint}")
print(f"OpenAI Key (first 20): {azure_openai_api_key[:20]}...")
print(f"Deployment: {azure_openai_deployment}")

# Update knowledge base
knowledge_base_definition = {
    "name": "hr-benefits-assistant",
    "description": "HR Benefits Assistant for employee questions about health benefits and company policies",
    "retrievalInstructions": "You are an HR Benefits Assistant. Query both knowledge sources to find relevant information about health benefits and company policies.",
    "answerInstructions": "Provide clear, concise answers based on the retrieved documents.",
    "outputMode": "answerSynthesis",
    "knowledgeSources": [
        {"name": "health-benefits-ks"},
        {"name": "hr-policies-ks"}
    ],
    "models": [{
        "kind": "azureOpenAI",
        "azureOpenAIParameters": {
            "resourceUri": azure_openai_endpoint,
            "apiKey": azure_openai_api_key,
            "deploymentId": azure_openai_deployment,
            "modelName": azure_openai_model
        }
    }],
    "retrievalReasoningEffort": {"kind": "low"}
}

url = f"{search_endpoint}/knowledgebases/hr-benefits-assistant?api-version=2025-11-01-preview"
headers = {"Content-Type": "application/json", "api-key": search_api_key}

response = requests.put(url, json=knowledge_base_definition, headers=headers)
print(f"\nUpdate Status: {response.status_code}")

if response.status_code in [200, 201, 204]:
    print("✅ Knowledge base updated with fresh API key!")
else:
    print(f"❌ Error: {response.text[:500]}")
