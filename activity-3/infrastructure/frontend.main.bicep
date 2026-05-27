@description('Azure region for all resources')
param location string = resourceGroup().location

var projectName = 'calmvault'
// Derive suffix from pre-created resource group name: rg-calmvault-<suffix>-usc
var rgNameParts = split(resourceGroup().name, '-')
var suffix = rgNameParts[2]

module resources 'frontend.resources.bicep' = {
  name: 'deploy-frontend'
  params: {
    location: location
    projectName: projectName
    suffix: suffix
  }
}

output frontendUrl string = resources.outputs.frontendUrl
output suffix string = suffix
