// Subscription-scope deployment: creates a resource group with required tag and deploys azure-resources.bicep inside it

targetScope = 'subscription'

@description('Name of the resource group to create')
param resourceGroupName string

@description('Azure region for the resource group')
param location string

@description('Principal ID of the agent blueprint for RBAC')
param blueprintPrincipalId string

@description('Additional tags to apply to the resource group')
param extraTags object = {}

// Base tag required by security control
var baseTags = {
  SecurityControl: 'Ignore'
}

var mergedTags = union(baseTags, extraTags)

// Resource group with required tag
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: mergedTags
}

// Deploy consolidated resources into the created resource group
module azureResources 'azure-resources.bicep' = {
  name: 'azure-resources-deployment'
  scope: rg
  params: {
    blueprintPrincipalId: blueprintPrincipalId
    // Note: other parameters use defaults defined in azure-resources.bicep
  }
}

output resourceGroupName string = rg.name
output resourceGroupLocation string = rg.location
output resourceGroupTags object = rg.tags

// Surface key outputs from nested deployment (if needed downstream)
// Search outputs
output searchServiceName string = azureResources.outputs.searchServiceName
output searchEndpoint string = azureResources.outputs.searchEndpoint
output searchPrincipalId string = azureResources.outputs.searchPrincipalId

// Storage outputs
output storageAccountName string = azureResources.outputs.storageAccountName
output storageEndpoint string = azureResources.outputs.storageEndpoint
output usContainerName string = azureResources.outputs.usContainerName
output apacContainerName string = azureResources.outputs.apacContainerName
output foundryContainerName string = azureResources.outputs.foundryContainerName

// Foundry outputs
output aiFoundryName string = azureResources.outputs.aiFoundryName
output aiFoundryId string = azureResources.outputs.aiFoundryId
output aiFoundryEndpoint string = azureResources.outputs.aiFoundryEndpoint
output aiProjectName string = azureResources.outputs.aiProjectName
output aiProjectId string = azureResources.outputs.aiProjectId
output aiProjectIdentityPrincipalId string = azureResources.outputs.aiProjectIdentityPrincipalId

// Model deployment outputs
output chatDeploymentName string = azureResources.outputs.chatDeploymentName
output embeddingsDeploymentName string = azureResources.outputs.embeddingsDeploymentName
output blueprintPrincipalId string = azureResources.outputs.blueprintPrincipalId
