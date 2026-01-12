// Azure AI Search + Storage with RBAC
// Subscription-level deployment: Creates resource group, search service, storage account, and RBAC

targetScope = 'subscription'

@description('Name of the resource group to create')
param resourceGroupName string = 'rg-a365-${toLower(uniqueString(subscription().id, deployment().name))}'

@description('Name of the Azure AI Search service')
param searchServiceName string = 'a365-search-${toLower(uniqueString(subscription().id, deployment().name))}'

@description('Name of the storage account for data sources')
param storageAccountName string = 'a365sa${toLower(uniqueString(subscription().id, deployment().name))}'

@description('Azure region for resources')
param location string = 'eastus'

@description('Object ID of the agent blueprint service principal')
param blueprintPrincipalId string

@description('SKU for Azure AI Search')
@allowed(['free', 'basic', 'standard', 'standard2', 'standard3'])
param searchSku string = 'free'

// Create resource group
resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
}

// Built-in role definition IDs
var searchIndexDataReaderRoleId = '1407120a-92aa-4202-b7e9-c0e197c71c8f'
var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

// Deploy resources into the resource group
module resources 'search-resources.bicep' = {
  name: 'searchResources'
  scope: rg
  params: {
    searchServiceName: searchServiceName
    storageAccountName: storageAccountName
    location: location
    blueprintPrincipalId: blueprintPrincipalId
    searchSku: searchSku
  }
}

// Outputs
output resourceGroupName string = rg.name
output searchServiceName string = resources.outputs.searchServiceName
output searchEndpoint string = resources.outputs.searchEndpoint
output searchPrincipalId string = resources.outputs.searchPrincipalId
output storageAccountName string = resources.outputs.storageAccountName
output storageEndpoint string = resources.outputs.storageEndpoint
output usContainerName string = resources.outputs.usContainerName
output apacContainerName string = resources.outputs.apacContainerName
