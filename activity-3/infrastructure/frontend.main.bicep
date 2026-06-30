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

module resources 'frontend.resources.bicep' = {
  name: 'deploy-frontend'
  scope: resourceGroup
  params: {
    location: location
    projectName: projectName
    suffix: suffix
  }
}

output frontendUrl string = resources.outputs.frontendUrl
output suffix string = suffix
