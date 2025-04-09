using '../../dpc_main.bicep'

// Identifier for the client, used in resource names
param clientId = '_example'
param brandingClientName = 'Example Client Name'
param environmentPurpose = 'prod'

param primaryResourceLocation = 'eastus'

// Others are only if need to override defaults, should be uncommon

//param disableLocalAuth = true
//param usePrivateEndpoints = true
//param openAILocation = 'eastus'
//param dalleLocation = 'eastus'
//param openAISku = 'S0'
//param openAIApiVersion = '2024-08-01-preview'
//param chatGptDeploymentCapacity = 30
//param chatGptDeploymentName = 'gpt-4o'
//param chatGptModelName = 'gpt-4o'
//param chatGptModelVersion = '2024-05-13'
//param embeddingDeploymentName = 'embedding'
//param embeddingDeploymentCapacity = 120
//param embeddingModelName = 'text-embedding-ada-002'
//param dalleDeploymentCapacity = 1
//param dalleDeploymentName = 'dall-e-3'
//param dalleModelName = 'dall-e-3'
//param dalleApiVersion = '2023-12-01-preview'
//param formRecognizerSkuName = 'S0'
//param searchServiceIndexName = 'voltwrite'
//param searchServiceSkuName = 'standard'
//param storageServiceSku = { name: 'Standard_LRS' }
//param storageServiceImageContainerName = 'images'
//param privateEndpointVNetPrefix = '192.168.0.0/16'
//param privateEndpointSubnetAddressPrefix = '192.168.0.0/24'
//param appServiceBackendSubnetAddressPrefix = '192.168.1.0/24'
//param adminEmails = 'vladimir.tsoy@dairylandpower.com'
