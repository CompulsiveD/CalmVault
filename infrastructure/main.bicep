targetScope = 'subscription'

@description('Azure region for all resources')
param location string = 'centralus'

@description('Random suffix for unique resource names (4 characters)')
param suffix string = substring(uniqueString(subscription().subscriptionId, 'calmvault'), 0, 4)

var projectName = 'calmvault'
var rgName = 'rg-${projectName}-${suffix}'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: rgName
  location: location
  tags: {
    SecurityControl: 'Ignore'
  }
}

module resources 'resources.bicep' = {
  name: 'deploy-resources'
  scope: resourceGroup
  params: {
    location: location
    projectName: projectName
    suffix: suffix
  }
}

output resourceGroupName string = resourceGroup.name
output storageAccountName string = resources.outputs.storageAccountName
output cosmosAccountName string = resources.outputs.cosmosAccountName
output cosmosEndpoint string = resources.outputs.cosmosEndpoint
