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
  name: 'deploy-monitoring'
  scope: resourceGroup
  params: {
    location: location
    projectName: projectName
    suffix: suffix
  }
}

output suffix string = suffix
output logAnalyticsName string = resources.outputs.logAnalyticsName
output dashboardName string = resources.outputs.dashboardName
output appInsightsName string = resources.outputs.appInsightsName
output appInsightsConnectionString string = resources.outputs.appInsightsConnectionString
