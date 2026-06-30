targetScope = 'subscription'

@description('Azure region for all resources')
param location string = 'centralus'

@description('Random suffix for unique resource names (4 characters)')
param suffix string = substring(uniqueString(subscription().subscriptionId, 'calmvault'), 0, 4)

var projectName = 'calmvault'
var rgName = 'rg-${projectName}-${suffix}'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' existing = {
  name: rgName
}

module resources 'resources.bicep' = {
  name: 'deploy-ai-tagger'
  scope: resourceGroup
  params: {
    location: location
    projectName: projectName
    suffix: suffix
  }
}

output suffix string = suffix
output openAiEndpoint string = resources.outputs.openAiEndpoint
output taggerJobName string = resources.outputs.taggerJobName
output queueName string = resources.outputs.queueName
