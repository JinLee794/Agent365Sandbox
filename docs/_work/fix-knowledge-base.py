#!/usr/bin/env python3
"""
Fix knowledge base configuration to match Microsoft LAB511 pattern
This removes the searchFields parameter and simplifies the knowledge base definition
"""

import os
import requests
from dotenv import load_dotenv

load_dotenv()

# Configuration
search_service_name = os.getenv('AZURE_SEARCH_SERVICE_NAME')
search_endpoint = f"https://{search_service_name}.search.windows.net"
azure_openai_endpoint = os.getenv('AZURE_OPENAI_ENDPOINT')
azure_openai_api_key = os.getenv('AZURE_OPENAI_API_KEY')
azure_openai_deployment = os.getenv('AZURE_OPENAI_DEPLOYMENT', 'gpt-4o')
azure_openai_model = os.getenv('AZURE_OPENAI_MODEL', 'gpt-4o')
resource_group = os.getenv('AZURE_RESOURCE_GROUP')
api_version = "2025-11-01-preview"

# Get search admin key
import subprocess
result = subprocess.run(
    f"az search admin-key show --resource-group {resource_group} --service-name {search_service_name} --query primaryKey --output tsv",
    shell=True, capture_output=True, text=True
)
search_api_key = result.stdout.strip()

print("🔧 Fixing Knowledge Base Configuration\n")
print("="*80)

# Step 1: Recreate knowledge sources WITHOUT searchFields
print("\n1️⃣ Recreating knowledge sources (simplified)...\n")

knowledge_sources = [
    {
        "name": "health-benefits-ks",
        "description": "Health insurance benefits documentation including Northwind Health Plus plans",
        "index_name": "healthdocs-index"
    },
    {
        "name": "hr-policies-ks",
        "description": "HR policies and company information including Zava company overview",
        "index_name": "hrdocs-index"
    }
]

for ks in knowledge_sources:
    # Simplified knowledge source definition (matching Microsoft LAB511)
    knowledge_source_definition = {
        "kind": "searchIndex",
        "name": ks["name"],
        "description": ks["description"],
        "searchIndexParameters": {
            "searchIndexName": ks["index_name"],
            # Remove searchFields - let it search all searchable fields by default
            "sourceDataFields": [
                {"name": "blob_path"},  # For citations
                {"name": "snippet"}     # For content
            ],
            "semanticConfigurationName": "semantic-config"
        }
    }

    url = f"{search_endpoint}/knowledgesources/{ks['name']}?api-version={api_version}"
    headers = {
        "Content-Type": "application/json",
        "api-key": search_api_key
    }

    response = requests.put(url, json=knowledge_source_definition, headers=headers)

    if response.status_code in [200, 201, 204]:
        print(f"✅ Updated knowledge source: {ks['name']}")
    else:
        print(f"⚠️  Error updating {ks['name']}: {response.status_code}")
        print(f"   {response.text[:200]}")

# Step 2: Recreate knowledge base (minimal configuration)
print("\n2️⃣ Recreating knowledge base (minimal config)...\n")

# Minimal knowledge base definition (matching Microsoft LAB511 Part 1)
knowledge_base_definition = {
    "name": "hr-benefits-assistant",
    "description": "HR Benefits Assistant for employee questions",
    # No retrievalInstructions initially
    # No answerInstructions initially
    # No retrievalReasoningEffort initially
    "outputMode": "answerSynthesis",
    "knowledgeSources": [
        {"name": "health-benefits-ks"},
        {"name": "hr-policies-ks"}
    ],
    "models": [
        {
            "kind": "azureOpenAI",
            "azureOpenAIParameters": {
                "resourceUri": azure_openai_endpoint,
                "apiKey": azure_openai_api_key,
                "deploymentId": azure_openai_deployment,
                "modelName": azure_openai_model
            }
        }
    ]
}

url = f"{search_endpoint}/knowledgebases/hr-benefits-assistant?api-version={api_version}"
headers = {
    "Content-Type": "application/json",
    "api-key": search_api_key
}

response = requests.put(url, json=knowledge_base_definition, headers=headers)

if response.status_code in [200, 201, 204]:
    print("✅ Knowledge base updated successfully!")
    print("   Removed: retrievalInstructions, answerInstructions, retrievalReasoningEffort")
    print("   Simplified: Knowledge source searchFields removed")
else:
    print(f"⚠️  Error updating knowledge base: {response.status_code}")
    print(f"   {response.text}")

# Step 3: Test query with alwaysQuerySource
print("\n3️⃣ Testing query with alwaysQuerySource=true...\n")

test_query = "What are the copayment amounts for office visits with Northwind Health Plus?"

retrieval_request = {
    "messages": [
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": test_query
                }
            ]
        }
    ],
    "knowledgeSourceParams": [
        {
            "kind": "searchIndex",
            "knowledgeSourceName": "health-benefits-ks",
            "includeReferences": True,
            "includeReferenceSourceData": True,
            "alwaysQuerySource": True
        },
        {
            "kind": "searchIndex",
            "knowledgeSourceName": "hr-policies-ks",
            "includeReferences": True,
            "includeReferenceSourceData": True,
            "alwaysQuerySource": True
        }
    ],
    "includeActivity": True
}

url = f"{search_endpoint}/knowledgebases/hr-benefits-assistant/retrieve?api-version={api_version}"
headers = {
    "Content-Type": "application/json",
    "api-key": search_api_key
}

response = requests.post(url, json=retrieval_request, headers=headers)

print(f"Query: {test_query}\n")

if response.status_code == 200:
    result = response.json()

    # Extract answer
    if "response" in result and result["response"]:
        answer_content = result["response"][0].get("content", [])
        if answer_content:
            answer_text = answer_content[0].get("text", "No answer generated")
            print(f"✅ Answer received:\n{answer_text}\n")

    # Show activity
    if "activity" in result:
        print("📊 Query Activity:")
        for activity in result["activity"]:
            ks_name = activity.get("knowledgeSourceName", "unknown")
            print(f"   • Queried: {ks_name}")

    print("\n" + "="*80)
    print("✅ SUCCESS! Knowledge base is working correctly.")
    print("="*80)
else:
    print(f"❌ Error {response.status_code}: {response.text}")
    print("\nIf you still get a 400 error, the content filter may need to be adjusted.")
    print("See COMPARISON-MSFT-LAB511.md for more details.")
