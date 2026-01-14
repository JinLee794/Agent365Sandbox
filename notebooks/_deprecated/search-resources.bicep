targetScope = 'resourceGroup'

@description('Name of the Azure AI Search service')
param searchServiceName string = 'a365-search-${toLower(uniqueString(resourceGroup().id))}'

@description('Name of the Azure Storage Account')
param storageAccountName string = 'a365sa${toLower(uniqueString(resourceGroup().id))}'

@description('Azure region for resources')
param location string = resourceGroup().location

@description('Principal ID of the agent blueprint for RBAC')
param blueprintPrincipalId string

@description('SKU for the Azure AI Search service')
@allowed(['free', 'basic', 'standard', 'standard2', 'standard3'])
param searchSku string = 'free'

// Built-in role definition IDs
var searchIndexDataReaderRoleId = '1407120a-92aa-4202-b7e9-c0e197c71c8f'
var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
  }
}

// Blob service and containers
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
}

resource usContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: 'agents-us-data'
  properties: {
    publicAccess: 'None'
  }
}

resource apacContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: 'agents-apac-data'
  properties: {
    publicAccess: 'None'
  }
}

// Azure AI Search Service
resource searchService 'Microsoft.Search/searchServices@2023-11-01' = {
  name: searchServiceName
  location: location
  sku: {
    name: searchSku
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    hostingMode: 'default'
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// RBAC: Search service managed identity → Storage (read data for indexing)
resource searchToStorageRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, searchService.id, storageBlobDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleId)
    principalId: searchService.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// RBAC: Blueprint principal → Search Index (agents-us) - scoped at service level
// Note: Index-level RBAC must be assigned after indices are created via Azure CLI or Portal
resource blueprintToSearchRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(searchService.id, blueprintPrincipalId, searchIndexDataReaderRoleId)
  scope: searchService
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', searchIndexDataReaderRoleId)
    principalId: blueprintPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs
output searchServiceName string = searchService.name
output searchEndpoint string = 'https://${searchService.name}.search.windows.net'
output searchPrincipalId string = searchService.identity.principalId
output storageAccountName string = storageAccount.name
output storageEndpoint string = storageAccount.properties.primaryEndpoints.blob
output usContainerName string = usContainer.name
output apacContainerName string = apacContainer.name
