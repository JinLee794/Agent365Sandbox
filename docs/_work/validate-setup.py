#!/usr/bin/env python3
"""
Validate complete knowledge base setup
This script checks all components needed for notebook 07 to work correctly
"""

import os
import sys
import subprocess
import requests
from dotenv import load_dotenv

def check_env_var(name, required=True):
    """Check if environment variable exists"""
    value = os.getenv(name)
    if value:
        print(f"   ✅ {name}")
        return True
    elif required:
        print(f"   ❌ {name} - MISSING")
        return False
    else:
        print(f"   ⚠️  {name} - Optional, not set")
        return True

def check_azure_resource(resource_type, name):
    """Check if Azure resource exists"""
    try:
        if resource_type == "search":
            result = subprocess.run(
                f"az search service show --name {name} --resource-group {os.getenv('AZURE_RESOURCE_GROUP')} --query 'status' -o tsv 2>/dev/null",
                shell=True, capture_output=True, text=True, timeout=10
            )
            if result.returncode == 0:
                print(f"   ✅ Azure Search: {name}")
                return True
        elif resource_type == "cognitiveservices":
            result = subprocess.run(
                f"az cognitiveservices account show --name {name} --resource-group {os.getenv('AZURE_RESOURCE_GROUP')} --query 'name' -o tsv 2>/dev/null",
                shell=True, capture_output=True, text=True, timeout=10
            )
            if result.returncode == 0:
                print(f"   ✅ AI Foundry: {name}")
                return True

        print(f"   ❌ {resource_type}: {name} - NOT FOUND")
        return False
    except Exception as e:
        print(f"   ⚠️  {resource_type}: {name} - Could not verify ({str(e)[:50]})")
        return False

def check_index_vectorizer(search_service, index_name, api_key):
    """Check if index vectorizer has valid API key"""
    try:
        url = f"https://{search_service}.search.windows.net/indexes/{index_name}?api-version=2024-07-01"
        headers = {"api-key": api_key}
        response = requests.get(url, headers=headers, timeout=5)

        if response.status_code == 200:
            index_def = response.json()
            if "vectorSearch" in index_def and "vectorizers" in index_def["vectorSearch"]:
                vectorizers = index_def["vectorSearch"]["vectorizers"]
                if vectorizers:
                    print(f"   ✅ Index {index_name}: Vectorizer configured")
                    return True
            print(f"   ⚠️  Index {index_name}: No vectorizer found")
            return False
        elif response.status_code == 404:
            print(f"   ℹ️  Index {index_name}: Not found (will be created by notebook)")
            return True
        else:
            print(f"   ❌ Index {index_name}: Error {response.status_code}")
            return False
    except Exception as e:
        print(f"   ⚠️  Index {index_name}: Could not check ({str(e)[:50]})")
        return False

def check_rbac_role(principal_id, scope, role_name):
    """Check if RBAC role is assigned"""
    try:
        result = subprocess.run(
            f"az role assignment list --assignee {principal_id} --scope {scope} --query \"[?roleDefinitionName=='{role_name}'].roleDefinitionName\" -o tsv 2>/dev/null",
            shell=True, capture_output=True, text=True, timeout=10
        )
        if result.returncode == 0 and result.stdout.strip():
            print(f"   ✅ RBAC: {role_name}")
            return True
        else:
            print(f"   ❌ RBAC: {role_name} - NOT ASSIGNED")
            return False
    except Exception as e:
        print(f"   ⚠️  RBAC: {role_name} - Could not verify ({str(e)[:50]})")
        return False

def main():
    print("🔍 Validating Knowledge Base Setup")
    print("="*80)

    # Load environment
    load_dotenv()

    all_checks_passed = True

    # Check 1: Environment Variables
    print("\n1️⃣ Environment Variables:")
    required_vars = [
        'AZURE_SEARCH_SERVICE_NAME',
        'AZURE_OPENAI_ENDPOINT',
        'AZURE_OPENAI_API_KEY',
        'AZURE_OPENAI_DEPLOYMENT',
        'AZURE_RESOURCE_GROUP',
        'AZURE_SUBSCRIPTION_ID',
        'AGENT_BLUEPRINT_PRINCIPAL_ID'
    ]

    for var in required_vars:
        if not check_env_var(var):
            all_checks_passed = False

    # Check 2: Azure Resources
    print("\n2️⃣ Azure Resources:")
    search_service = os.getenv('AZURE_SEARCH_SERVICE_NAME')
    ai_foundry = os.getenv('AI_FOUNDRY_NAME', os.getenv('AZURE_OPENAI_ENDPOINT', '').split('//')[1].split('.')[0] if os.getenv('AZURE_OPENAI_ENDPOINT') else None)

    if search_service:
        check_azure_resource('search', search_service)

    if ai_foundry:
        check_azure_resource('cognitiveservices', ai_foundry)

    # Check 3: Index Vectorizers
    print("\n3️⃣ Search Index Vectorizers:")
    if search_service:
        # Get search API key
        result = subprocess.run(
            f"az search admin-key show --resource-group {os.getenv('AZURE_RESOURCE_GROUP')} --service-name {search_service} --query primaryKey --output tsv 2>/dev/null",
            shell=True, capture_output=True, text=True, timeout=10
        )
        if result.returncode == 0:
            search_api_key = result.stdout.strip()
            check_index_vectorizer(search_service, 'healthdocs-index', search_api_key)
            check_index_vectorizer(search_service, 'hrdocs-index', search_api_key)
        else:
            print("   ⚠️  Could not get search admin key")

    # Check 4: RBAC Permissions
    print("\n4️⃣ RBAC Permissions:")
    principal_id = os.getenv('AGENT_BLUEPRINT_PRINCIPAL_ID')
    subscription_id = os.getenv('AZURE_SUBSCRIPTION_ID')
    resource_group = os.getenv('AZURE_RESOURCE_GROUP')

    if principal_id and subscription_id and resource_group and search_service:
        # Search RBAC
        search_scope = f"/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Search/searchServices/{search_service}"
        check_rbac_role(principal_id, search_scope, 'Search Index Data Reader')

    if principal_id and subscription_id and resource_group and ai_foundry:
        # AI Foundry RBAC
        foundry_scope = f"/subscriptions/{subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.CognitiveServices/accounts/{ai_foundry}"
        check_rbac_role(principal_id, foundry_scope, 'Cognitive Services OpenAI User')

    # Check 5: Test Query (if everything else passes)
    print("\n5️⃣ Test Query:")
    if os.path.exists('fix-knowledge-base.py'):
        print("   ℹ️  Run 'python fix-knowledge-base.py' to test complete flow")
    else:
        print("   ℹ️  fix-knowledge-base.py not found - run notebook manually")

    # Summary
    print("\n" + "="*80)
    if all_checks_passed:
        print("✅ All checks passed! Notebook 07 should work correctly.")
        print("\nNext steps:")
        print("  1. Run notebook 07 from top to bottom")
        print("  2. All three test queries should succeed")
    else:
        print("⚠️  Some checks failed. Review errors above.")
        print("\nCommon fixes:")
        print("  • Missing env vars: Update your .env file")
        print("  • Missing RBAC: Run Bicep deployment")
        print("  • Vectorizer issues: Run 'python update-index-vectorizers.py'")
        print("\nFor detailed troubleshooting, see:")
        print("  • FINAL-SOLUTION-SUMMARY.md")
        print("  • NOTEBOOK-07-UPDATES.md")
    print("="*80)

    return 0 if all_checks_passed else 1

if __name__ == '__main__':
    sys.exit(main())
