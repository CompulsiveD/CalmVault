@description('Azure region for all resources')
param location string = resourceGroup().location

var projectName = 'calmvault'
// Derive suffix from pre-created resource group name: rg-calmvault-<suffix>-usc
var rgNameParts = split(resourceGroup().name, '-')
var suffix = rgNameParts[2]

module resources 'resources.bicep' = {
  name: 'deploy-ai-tagger'
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
