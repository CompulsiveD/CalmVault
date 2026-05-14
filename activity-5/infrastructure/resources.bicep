@description('Azure region for all resources')
param location string

@description('Project name used in resource naming')
param projectName string

@description('Random suffix for unique names')
param suffix string

// ── Naming ─────────────────────────────────────────────────
var storageAccountName = '${projectName}${suffix}'
var cosmosAccountName = '${projectName}-cosmos-${suffix}'
var acrName = '${projectName}acr${suffix}'
var envName = '${projectName}-env-${suffix}'
var openAiName = '${projectName}-openai-${suffix}'
var taggerAppName = '${projectName}-tagger-${suffix}'
var queueName = 'blob-events'
var eventGridTopicName = '${projectName}-storage-events-${suffix}'
var eventGridSubName = 'blob-created-to-queue'

// ── Existing Resources ─────────────────────────────────────
resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' existing = {
  name: storageAccountName
}

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-12-01-preview' existing = {
  name: cosmosAccountName
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing = {
  name: acrName
}

resource containerAppEnv 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: envName
}

// ── Storage Queue (for Event Grid delivery) ────────────────
resource queueService 'Microsoft.Storage/storageAccounts/queueServices@2024-01-01' = {
  name: 'default'
  parent: storageAccount
}

resource blobEventsQueue 'Microsoft.Storage/storageAccounts/queueServices/queues@2024-01-01' = {
  name: queueName
  parent: queueService
}

// ── Azure OpenAI ───────────────────────────────────────────
resource openAi 'Microsoft.CognitiveServices/accounts@2024-10-01' = {
  name: openAiName
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: openAiName
    publicNetworkAccess: 'Enabled'
  }
}

resource gpt4oDeployment 'Microsoft.CognitiveServices/accounts/deployments@2024-10-01' = {
  parent: openAi
  name: 'gpt-4o'
  sku: {
    name: 'Standard'
    capacity: 10
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4o'
      version: '2024-11-20'
    }
  }
}

// ── Event Grid System Topic (Storage Account) ──────────────
resource eventGridTopic 'Microsoft.EventGrid/systemTopics@2024-06-01-preview' = {
  name: eventGridTopicName
  location: location
  properties: {
    source: storageAccount.id
    topicType: 'Microsoft.Storage.StorageAccounts'
  }
}

// ── Event Grid Subscription → Storage Queue ────────────────
resource eventGridSub 'Microsoft.EventGrid/systemTopics/eventSubscriptions@2024-06-01-preview' = {
  parent: eventGridTopic
  name: eventGridSubName
  properties: {
    destination: {
      endpointType: 'StorageQueue'
      properties: {
        resourceId: storageAccount.id
        queueName: blobEventsQueue.name
        queueMessageTimeToLiveInSeconds: 604800 // 7 days
      }
    }
    filter: {
      includedEventTypes: [
        'Microsoft.Storage.BlobCreated'
      ]
      subjectBeginsWith: '/blobServices/default/containers/calmvault-files/'
    }
  }
}

// ── Tagger Container App Job ───────────────────────────────
resource taggerJob 'Microsoft.App/jobs@2024-03-01' = {
  name: taggerAppName
  location: location
  properties: {
    environmentId: containerAppEnv.id
    configuration: {
      triggerType: 'Event'
      replicaTimeout: 300
      replicaRetryLimit: 1
      eventTriggerConfig: {
        parallelism: 1
        replicaCompletionCount: 1
        scale: {
          minExecutions: 0
          maxExecutions: 5
          pollingInterval: 30
          rules: [
            {
              name: 'queue-trigger'
              type: 'azure-queue'
              metadata: {
                accountName: storageAccount.name
                queueName: blobEventsQueue.name
                queueLength: '1'
              }
              auth: [
                {
                  secretRef: 'storage-connection-string'
                  triggerParameter: 'connection'
                }
              ]
            }
          ]
        }
      }
      registries: [
        {
          server: acr.properties.loginServer
          username: acr.listCredentials().username
          passwordSecretRef: 'acr-password'
        }
      ]
      secrets: [
        {
          name: 'acr-password'
          value: acr.listCredentials().passwords[0].value
        }
        {
          name: 'storage-connection-string'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
        }
        {
          name: 'cosmos-key'
          value: cosmosAccount.listKeys().primaryMasterKey
        }
        {
          name: 'openai-key'
          value: openAi.listKeys().key1
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'tagger'
          image: '${acr.properties.loginServer}/calmvault-tagger:latest'
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
          env: [
            { name: 'AZURE_STORAGE_CONNECTION_STRING', secretRef: 'storage-connection-string' }
            { name: 'AZURE_STORAGE_CONTAINER_NAME', value: 'calmvault-files' }
            { name: 'QUEUE_NAME', value: queueName }
            { name: 'COSMOS_ENDPOINT', value: cosmosAccount.properties.documentEndpoint }
            { name: 'COSMOS_KEY', secretRef: 'cosmos-key' }
            { name: 'COSMOS_DATABASE_NAME', value: 'calmvault' }
            { name: 'OPENAI_ENDPOINT', value: openAi.properties.endpoint }
            { name: 'OPENAI_API_KEY', secretRef: 'openai-key' }
            { name: 'OPENAI_DEPLOYMENT_NAME', value: gpt4oDeployment.name }
          ]
        }
      ]
    }
  }
}

// ── Outputs ────────────────────────────────────────────────
output openAiEndpoint string = openAi.properties.endpoint
output taggerJobName string = taggerJob.name
output queueName string = blobEventsQueue.name
