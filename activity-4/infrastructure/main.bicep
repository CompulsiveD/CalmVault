@description('Azure region for all resources')
param location string = resourceGroup().location

var projectName = 'calmvault'
// Derive suffix from pre-created resource group name: rg-calmvault-<suffix>-usc
var rgNameParts = split(resourceGroup().name, '-')
var suffix = rgNameParts[2]

module resources 'resources.bicep' = {
  name: 'deploy-monitoring'
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
