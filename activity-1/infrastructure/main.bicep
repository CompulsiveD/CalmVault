@description('Azure region for all resources')
param location string = resourceGroup().location

var projectName = 'calmvault'
// Derive suffix from pre-created resource group name: rg-calmvault-<suffix>-usc
var rgNameParts = split(resourceGroup().name, '-')
var suffix = rgNameParts[2]

module resources 'resources.bicep' = {
  name: 'deploy-resources'
  params: {
    location: location
    projectName: projectName
    suffix: suffix
  }
}

output resourceGroupName string = resourceGroup().name
output storageAccountName string = resources.outputs.storageAccountName
output cosmosAccountName string = resources.outputs.cosmosAccountName
output cosmosEndpoint string = resources.outputs.cosmosEndpoint
output suffix string = suffix
