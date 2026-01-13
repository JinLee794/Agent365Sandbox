// Bicep template for creating Azure AI Foundry resources, project scaffolding,
// and Azure OpenAI deployments for use by Notebook 08.
// Based on: https://learn.microsoft.com/en-us/azure/ai-foundry/how-to/create-resource-template

targetScope = 'resourceGroup'

param location string = resourceGroup().location
param blueprintPrincipalId string
param aiFoundryName string = 'aif${uniqueString(resourceGroup().id, location)}'
param aiProjectName string = 'agent365-project'
param foundryStorageName string = 'fnd${uniqueString(resourceGroup().id, location)}'

// Model deployment parameters
param chatDeploymentName string = 'gpt-4o'
param chatModelName string = 'gpt-4o'
param embeddingsDeploymentName string = 'text-embedding-3-large'
param embeddingsModelName string = 'text-embedding-3-large'

// Create Storage Account for Foundry
resource foundryStorage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: foundryStorageName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
  }

  // Create blob container for Foundry
  resource blobServices 'blobServices' = {
    name: 'default'

    resource container 'containers' = {
      name: 'foundry-data'
      properties: {
        publicAccess: 'None'
      }
    }
  }
}

// Azure AI Foundry resource (CognitiveServices/accounts kind: AIServices)
resource aiFoundry 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' = {
  name: aiFoundryName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'S0'
  }
  kind: 'AIServices'
  properties: {
    allowProjectManagement: true
    customSubDomainName: aiFoundryName
    disableLocalAuth: true
  }
}

// AI Foundry Project (sub-resource with its own identity)
resource aiProject 'Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview' = {
  name: aiProjectName
  parent: aiFoundry
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
}

// Chat deployment (gpt-4o)
resource chatDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  name: chatDeploymentName
  parent: aiFoundry
  sku: {
    capacity: 1
    name: 'GlobalStandard'
  }
  properties: {
    model: {
      name: chatModelName
      format: 'OpenAI'
    }
  }
}

// Embeddings deployment (text-embedding-3-large)
resource embeddingsDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  name: embeddingsDeploymentName
  parent: aiFoundry
  sku: {
    capacity: 1
    name: 'Standard'
  }
  properties: {
    model: {
      name: embeddingsModelName
      format: 'OpenAI'
    }
    raiPolicyName: 'Microsoft.Default'
  }
  dependsOn: [
    chatDeployment
  ]
}

// RBAC: Grant aiProject identity Storage Blob Data Contributor on foundry-data container
var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

resource projectStorageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(foundryStorage.id, aiProject.id, storageBlobDataContributorRoleId)
  scope: foundryStorage
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleId)
    principalId: aiProject.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// RBAC: Grant blueprint principal Storage Blob Data Contributor on foundry-data container
resource blueprintStorageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(foundryStorage.id, blueprintPrincipalId, storageBlobDataContributorRoleId)
  scope: foundryStorage
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleId)
    principalId: blueprintPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// Outputs for use by Notebook 08 and subsequent notebooks
output aiFoundryName string = aiFoundry.name
output aiFoundryId string = aiFoundry.id
output aiFoundryEndpoint string = 'https://${aiFoundry.properties.customSubDomainName}.openai.azure.com/'
output aiProjectName string = aiProject.name
output aiProjectId string = aiProject.id
output aiProjectIdentityPrincipalId string = aiProject.identity.principalId

output foundryStorageAccountName string = foundryStorage.name
output foundryStorageAccountId string = foundryStorage.id
output foundryStorageEndpoint string = foundryStorage.properties.primaryEndpoints.blob
output foundryContainerName string = 'foundry-data'
output blueprintPrincipalId string = blueprintPrincipalId

output chatDeploymentName string = chatDeployment.name
output embeddingsDeploymentName string = embeddingsDeployment.name
