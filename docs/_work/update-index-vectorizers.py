#!/usr/bin/env python3
"""
Update search index vectorizers with current Azure OpenAI API key
"""

import os
import subprocess
import requests
from dotenv import load_dotenv

load_dotenv()

# Configuration
search_service_name = os.getenv('AZURE_SEARCH_SERVICE_NAME')
search_endpoint = f"https://{search_service_name}.search.windows.net"
azure_openai_endpoint = os.getenv('AZURE_OPENAI_ENDPOINT')
azure_openai_api_key = os.getenv('AZURE_OPENAI_API_KEY')
resource_group = os.getenv('AZURE_RESOURCE_GROUP')

# Get search admin key
result = subprocess.run(
    f"az search admin-key show --resource-group {resource_group} --service-name {search_service_name} --query primaryKey --output tsv",
    shell=True, capture_output=True, text=True
)
search_api_key = result.stdout.strip()

print("🔧 Updating Index Vectorizers with Current API Key\n")
print("="*80)

indices = ["healthdocs-index", "hrdocs-index"]

for index_name in indices:
    print(f"\n📋 Updating {index_name}...\n")

    # Get current index definition
    url = f"{search_endpoint}/indexes/{index_name}?api-version=2024-07-01"
    headers = {"api-key": search_api_key}

    response = requests.get(url, headers=headers)

    if response.status_code != 200:
        print(f"❌ Failed to get {index_name}: {response.status_code}")
        continue

    index_def = response.json()

    # Update vectorizer API key
    if "vectorSearch" in index_def and "vectorizers" in index_def["vectorSearch"]:
        for vectorizer in index_def["vectorSearch"]["vectorizers"]:
            if vectorizer.get("kind") == "azureOpenAI":
                vectorizer["azureOpenAIParameters"]["apiKey"] = azure_openai_api_key
                print(f"   ✅ Updated vectorizer: {vectorizer['name']}")

    # Update index
    headers = {
        "Content-Type": "application/json",
        "api-key": search_api_key
    }

    response = requests.put(url, json=index_def, headers=headers)

    if response.status_code in [200, 201, 204]:
        print(f"   ✅ Index {index_name} updated successfully\n")
    else:
        print(f"   ❌ Failed to update {index_name}: {response.status_code}")
        print(f"   {response.text[:200]}\n")

print("="*80)
print("\n✅ Vectorizer API keys updated!")
print("\nNow try your knowledge base query again.")
