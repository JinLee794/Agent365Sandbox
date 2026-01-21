// Consolidated Bicep template for Azure AI Search and Azure AI Foundry resources
// with shared storage account and separate containers

targetScope = 'resourceGroup'

@description('Azure region for resources')
param location string = resourceGroup().location

@description('Principal ID of the agent blueprint for RBAC')
param blueprintPrincipalId string

@description('Name of the Azure AI Search service')
param searchServiceName string = 'a365-search-${toLower(uniqueString(resourceGroup().id))}'

@description('SKU for the Azure AI Search service')
@allowed(['free', 'basic', 'standard', 'standard2', 'standard3'])
param searchSku string = 'standard'

@description('Name of the shared Azure Storage Account')
param storageAccountName string = 'a365sa${toLower(uniqueString(resourceGroup().id))}'

@description('Name of the Azure AI Foundry resource')
param aiFoundryName string = 'aif${uniqueString(resourceGroup().id, location)}'

@description('Name of the AI Foundry project')
param aiProjectName string = 'agent365-project'

@description('Chat deployment name')
param chatDeploymentName string = 'gpt-4o'

@description('Chat model name')
param chatModelName string = 'gpt-4o'

@description('Embeddings deployment name')
param embeddingsDeploymentName string = 'text-embedding-3-large'

@description('Embeddings model name')
param embeddingsModelName string = 'text-embedding-3-large'

// Built-in role definition IDs
var searchIndexDataReaderRoleId = '1407120a-92aa-4202-b7e9-c0e197c71c8f'
var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var cognitiveServicesOpenAIUserRoleId = '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd'

// ========== Shared Storage Account ==========
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

// Blob service
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
}

// ========== Search Containers ==========
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

// ========== Foundry Container ==========
resource foundryContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  parent: blobService
  name: 'foundry-data'
  properties: {
    publicAccess: 'None'
  }
}

// ========== Log Analytics & Application Insights ==========
// Required for monitoring Foundry agents, tool calls, and tracing

@description('Name of the Log Analytics workspace')
param logAnalyticsName string = 'a365-logs-${toLower(uniqueString(resourceGroup().id))}'

@description('Name of the Application Insights resource')
param appInsightsName string = 'a365-insights-${toLower(uniqueString(resourceGroup().id))}'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// ========== Azure AI Search Service ==========
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
    // Enable both API Key and RBAC (Entra ID) authentication
    // This is required for agentic mode (Knowledge Sources) which uses RBAC
    authOptions: {
      aadOrApiKey: {
        aadAuthFailureMode: 'http401WithBearerChallenge'
      }
    }
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

// RBAC: Blueprint principal → Search Index (service-level)
resource blueprintToSearchRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(searchService.id, blueprintPrincipalId, searchIndexDataReaderRoleId)
  scope: searchService
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', searchIndexDataReaderRoleId)
    principalId: blueprintPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ========== Azure AI Foundry ==========
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
    disableLocalAuth: false  // Enable API keys for knowledge base queries (can use RBAC OR keys)
    // Explicitly allow public network access to satisfy platform requirement
    publicNetworkAccess: 'Enabled'
  }
}

// Custom RAI Policy for HR Benefits content (less restrictive for medical/health terms)
resource hrBenefitsRaiPolicy 'Microsoft.CognitiveServices/accounts/raiPolicies@2024-10-01' = {
  name: 'hr-benefits-policy'
  parent: aiFoundry
  properties: {
    mode: 'Default'
    contentFilters: [
      { name: 'Hate', severityThreshold: 'High', blocking: true, enabled: true, source: 'Prompt' }
      { name: 'Hate', severityThreshold: 'High', blocking: true, enabled: true, source: 'Completion' }
      { name: 'Sexual', severityThreshold: 'High', blocking: true, enabled: true, source: 'Prompt' }
      { name: 'Sexual', severityThreshold: 'High', blocking: true, enabled: true, source: 'Completion' }
      { name: 'Violence', severityThreshold: 'High', blocking: true, enabled: true, source: 'Prompt' }
      { name: 'Violence', severityThreshold: 'High', blocking: true, enabled: true, source: 'Completion' }
      { name: 'SelfHarm', severityThreshold: 'High', blocking: true, enabled: true, source: 'Prompt' }
      { name: 'SelfHarm', severityThreshold: 'High', blocking: true, enabled: true, source: 'Completion' }
    ]
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

// Chat deployment (gpt-4o) with HR benefits RAI policy
resource chatDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  name: chatDeploymentName
  parent: aiFoundry
  sku: {
    capacity: 200
    name: 'GlobalStandard'
  }
  properties: {
    model: {
      name: chatModelName
      format: 'OpenAI'
    }
    raiPolicyName: hrBenefitsRaiPolicy.name
  }
  dependsOn: [
    hrBenefitsRaiPolicy
  ]
}

// Embeddings deployment (text-embedding-3-large)
resource embeddingsDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  name: embeddingsDeploymentName
  parent: aiFoundry
  sku: {
    capacity: 200
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

// ========== RBAC: Agent Blueprint Access ==========
// RBAC: Blueprint principal → AI Foundry (Cognitive Services OpenAI User)
resource blueprintToFoundryRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiFoundry.id, blueprintPrincipalId, cognitiveServicesOpenAIUserRoleId)
  scope: aiFoundry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', cognitiveServicesOpenAIUserRoleId)
    principalId: blueprintPrincipalId
    principalType: 'ServicePrincipal'
  }
}

// ========== Outputs ==========
// Search outputs
output searchServiceName string = searchService.name
output searchEndpoint string = 'https://${searchService.name}.search.windows.net'
output searchPrincipalId string = searchService.identity.principalId

// Storage outputs
output storageAccountName string = storageAccount.name
output storageEndpoint string = storageAccount.properties.primaryEndpoints.blob
output usContainerName string = usContainer.name
output apacContainerName string = apacContainer.name
output foundryContainerName string = foundryContainer.name

// Foundry outputs
output aiFoundryName string = aiFoundry.name
output aiFoundryId string = aiFoundry.id
output aiFoundryEndpoint string = 'https://${aiFoundry.properties.customSubDomainName}.openai.azure.com/'
output aiFoundryProjectEndpoint string = 'https://${aiFoundry.properties.customSubDomainName}.services.ai.azure.com/api/projects/${aiProject.name}'
output aiProjectName string = aiProject.name
output aiProjectId string = aiProject.id
output aiProjectIdentityPrincipalId string = aiProject.identity.principalId

// Model deployment outputs
output chatDeploymentName string = chatDeployment.name
output embeddingsDeploymentName string = embeddingsDeployment.name
output blueprintPrincipalId string = blueprintPrincipalId

// Monitoring outputs
output logAnalyticsWorkspaceId string = logAnalytics.id
output logAnalyticsWorkspaceName string = logAnalytics.name
output appInsightsName string = appInsights.name
output appInsightsConnectionString string = appInsights.properties.ConnectionString
output appInsightsInstrumentationKey string = appInsights.properties.InstrumentationKey
