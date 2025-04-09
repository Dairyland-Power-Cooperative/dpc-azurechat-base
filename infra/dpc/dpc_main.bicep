targetScope = 'subscription'

var applicationId = 'voltwrite'

@minLength(1)
@description('Client identifier for resource naming and tagging')
param clientId string = '_example'

@description('Client name for use in branding')
param brandingClientName string = 'Example Client Name'

@description('Deployment environment (dev, test, prod)')
@allowed([
  'dev'
  'test'
  'prod'
])
param environmentPurpose string = 'prod'

@description('Primary location for all resources')
param primaryResourceLocation string = 'eastus'

// Activates/Deactivates Authentication using keys. If true it will enforce RBAC using managed identities
@allowed([true, false])
@description('Enables/Disables Authentication using keys. If true it will enforce RBAC using managed identity and disable key auth on backend resouces')
param disableLocalAuth bool = true

@allowed([true, false])
@description('Enable private endpoints for all resources')
@metadata({
  azd: {
    type: 'boolean'
  }
})
param usePrivateEndpoints bool = true

// Conditionally set the environment naming based on the environment parameter, 
// if the environment is prod, it will not append the environmentPurpose to the clientId 
var clientEnvironment = environmentPurpose == 'prod' ? '${clientId}' : '${clientId}-${environmentPurpose}'

var resourceGroupName = 'rg-${clientEnvironment}-${applicationId}'

// Common tags for all resources
var azResourceTags = {
  client: clientId
  environment: environmentPurpose
  application: applicationId
  'azd-env-name': clientEnvironment
}

// azure open ai -- regions currently support gpt-4o global-standard
@description('Location for the OpenAI resource group')
@allowed([
  'australiaeast'
  'brazilsouth'
  'canadaeast'
  'eastus'
  'eastus2'
  'francecentral'
  'germanywestcentral'
  'japaneast'
  'koreacentral'
  'northcentralus'
  'norwayeast'
  'polandcentral'
  'spaincentral'
  'southafricanorth'
  'southcentralus'
  'southindia'
  'swedencentral'
  'switzerlandnorth'
  'uksouth'
  'westeurope'
  'westus'
  'westus3'
])
@metadata({
  azd: {
    type: 'location'
  }
})
param openAILocation string = 'eastus'

// DALL-E v3 only supported in limited regions for now
@description('Location for the OpenAI DALL-E 3 instance resource group')
@allowed(['swedencentral', 'eastus', 'australiaeast'])
@metadata({
  azd: {
    type: 'location'
  }
})
param dalleLocation string = 'eastus'

param openAISku string = 'S0'
param openAIApiVersion string = '2024-10-21'

param chatGptDeploymentCapacity int = 30
param chatGptDeploymentName string = 'gpt-4o'
param chatGptModelName string = 'gpt-4o'
param chatGptModelVersion string = '2024-11-20'
param embeddingDeploymentName string = 'embedding'
param embeddingDeploymentCapacity int = 120
param embeddingModelName string = 'text-embedding-ada-002'

param dalleDeploymentCapacity int = 1
param dalleDeploymentName string = 'dall-e-3'
param dalleModelName string = 'dall-e-3'
param dalleApiVersion string = '2024-05-01-preview'

param formRecognizerSkuName string = 'S0'
param searchServiceIndexName string = 'voltwrite'
param searchServiceSkuName string = 'basic'

param storageServiceSku object = { name: 'Standard_LRS' }
param storageServiceImageContainerName string = 'images'

param privateEndpointVNetPrefix string = '192.168.0.0/16'
param privateEndpointSubnetAddressPrefix string = '192.168.0.0/24'
param appServiceBackendSubnetAddressPrefix string = '192.168.1.0/24'

var resourceToken = toLower(uniqueString(subscription().id, clientEnvironment))

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: primaryResourceLocation
  tags: azResourceTags
}


module resources 'dpc_resources.bicep' = {
  name: 'deployGroupResources'
  scope: rg
  params: {
    name: clientId
    brandingClientName: brandingClientName
    resourceToken: resourceToken
    tags: azResourceTags
    openai_api_version: openAIApiVersion
    openAiLocation: openAILocation
    openAiSkuName: openAISku
    chatGptDeploymentCapacity: chatGptDeploymentCapacity
    chatGptDeploymentName: chatGptDeploymentName
    chatGptModelName: chatGptModelName
    chatGptModelVersion: chatGptModelVersion
    embeddingDeploymentName: embeddingDeploymentName
    embeddingDeploymentCapacity: embeddingDeploymentCapacity
    embeddingModelName: embeddingModelName
    dalleLocation: dalleLocation
    dalleDeploymentCapacity: dalleDeploymentCapacity
    dalleDeploymentName: dalleDeploymentName
    dalleModelName: dalleModelName
    dalleApiVersion: dalleApiVersion
    formRecognizerSkuName: formRecognizerSkuName
    searchServiceIndexName: searchServiceIndexName
    searchServiceSkuName: searchServiceSkuName
    storageServiceSku: storageServiceSku
    storageServiceImageContainerName: storageServiceImageContainerName
    location: rg.location
    disableLocalAuth: disableLocalAuth
    usePrivateEndpoints: usePrivateEndpoints
    privateEndpointVNetPrefix: privateEndpointVNetPrefix
    privateEndpointSubnetAddressPrefix: privateEndpointSubnetAddressPrefix
    appServiceBackendSubnetAddressPrefix: appServiceBackendSubnetAddressPrefix
  }
}

output APP_URL string = resources.outputs.url
output AZURE_WEBAPP_NAME string = resources.outputs.webapp_name
/*
output AZURE_LOCATION string = rg.location
output AZURE_TENANT_ID string = tenant().tenantId
output AZURE_RESOURCE_GROUP string = rg.name

output AZURE_OPENAI_API_INSTANCE_NAME string = resources.outputs.openai_name
output AZURE_OPENAI_API_DEPLOYMENT_NAME string = chatGptDeploymentName
output AZURE_OPENAI_API_VERSION string = openAIApiVersion
output AZURE_OPENAI_API_EMBEDDINGS_DEPLOYMENT_NAME string = embeddingDeploymentName

output AZURE_OPENAI_DALLE_API_INSTANCE_NAME string = resources.outputs.openai_dalle_name
output AZURE_OPENAI_DALLE_API_DEPLOYMENT_NAME string = dalleDeploymentName
output AZURE_OPENAI_DALLE_API_VERSION string = dalleApiVersion

output AZURE_COSMOSDB_ACCOUNT_NAME string = resources.outputs.cosmos_name
output AZURE_COSMOSDB_URI string = resources.outputs.cosmos_endpoint
output AZURE_COSMOSDB_DB_NAME string = resources.outputs.database_name
output AZURE_COSMOSDB_CONTAINER_NAME string = resources.outputs.history_container_name
output AZURE_COSMOSDB_CONFIG_CONTAINER_NAME string = resources.outputs.config_container_name

output AZURE_SEARCH_NAME string = resources.outputs.search_name
output AZURE_SEARCH_INDEX_NAME string = searchServiceIndexName

output AZURE_DOCUMENT_INTELLIGENCE_NAME string = resources.outputs.form_recognizer_name
output AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT string = 'https://${resources.outputs.form_recognizer_name}.cognitiveservices.azure.com/'

output AZURE_SPEECH_REGION string = rg.location
output AZURE_STORAGE_ACCOUNT_NAME string = resources.outputs.storage_name
output AZURE_KEY_VAULT_NAME string = resources.outputs.key_vault_name
*/
