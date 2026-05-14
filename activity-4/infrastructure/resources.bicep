@description('Azure region for all resources')
param location string

@description('Project name used in resource naming')
param projectName string

@description('Random suffix for unique names')
param suffix string

// ── Naming ─────────────────────────────────────────────────
var logAnalyticsName = '${projectName}-logs-${suffix}'
var storageAccountName = '${projectName}${suffix}'
var cosmosAccountName = '${projectName}-cosmos-${suffix}'
var acrName = '${projectName}acr${suffix}'
var backendAppName = '${projectName}-backend-${suffix}'
var dashboardName = '${projectName}-dashboard-${suffix}'

// ── Existing Resources ─────────────────────────────────────
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsName
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' existing = {
  name: storageAccountName
}

resource storageBlob 'Microsoft.Storage/storageAccounts/blobServices@2024-01-01' existing = {
  parent: storageAccount
  name: 'default'
}

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-12-01-preview' existing = {
  name: cosmosAccountName
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing = {
  name: acrName
}

// ── Diagnostic Settings: Storage Account (Blob) ────────────
// resource storageDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
//   name: '${storageAccountName}-blob-diag'
//   scope: storageBlob
//   properties: {
//     workspaceId: logAnalytics.id
//     logs: [
//       {
//         category: 'StorageRead'
//         enabled: true
//       }
//       {
//         category: 'StorageWrite'
//         enabled: true
//       }
//       {
//         category: 'StorageDelete'
//         enabled: true
//       }
//     ]
//     metrics: [
//       {
//         category: 'Transaction'
//         enabled: true
//       }
//     ]
//   }
// }

// ── Diagnostic Settings: Cosmos DB ─────────────────────────
resource cosmosDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${cosmosAccountName}-diag'
  scope: cosmosAccount
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'DataPlaneRequests'
        enabled: true
      }
      {
        category: 'QueryRuntimeStatistics'
        enabled: true
      }
      {
        category: 'PartitionKeyStatistics'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Requests'
        enabled: true
      }
    ]
  }
}

// ── Diagnostic Settings: Container Registry ────────────────
resource acrDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${acrName}-diag'
  scope: acr
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'ContainerRegistryRepositoryEvents'
        enabled: true
      }
      {
        category: 'ContainerRegistryLoginEvents'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// ── Azure Dashboard ────────────────────────────────────────
resource dashboard 'Microsoft.Portal/dashboards@2020-09-01-preview' = {
  name: dashboardName
  location: location
  properties: {
    lenses: [
      {
        order: 0
        parts: [
          {
            position: { x: 0, y: 0, rowSpan: 4, colSpan: 6 }
            metadata: {
              type: 'Extension/HubsExtension/PartType/MarkdownPart'
              inputs: []
              settings: {
                content: {
                  content: '## 📤 File Uploads\n\nRun this query in Log Analytics to see upload activity:\n\n```kql\nStorageBlobLogs\n| where OperationName startswith "Put"\n| summarize Uploads=count() by bin(TimeGenerated, 1h)\n| render timechart\n```\n\n**Workspace:** ${logAnalyticsName}'
                  title: 'File Uploads (hourly)'
                  subtitle: 'StorageBlobLogs — Put operations'
                }
              }
            }
          }
          {
            position: { x: 6, y: 0, rowSpan: 4, colSpan: 6 }
            metadata: {
              type: 'Extension/HubsExtension/PartType/MarkdownPart'
              inputs: []
              settings: {
                content: {
                  content: '## 📥 File Downloads\n\nRun this query in Log Analytics to see download activity:\n\n```kql\nStorageBlobLogs\n| where OperationName startswith "Get"\n| summarize Downloads=count() by bin(TimeGenerated, 1h)\n| render timechart\n```\n\n**Workspace:** ${logAnalyticsName}'
                  title: 'File Downloads (hourly)'
                  subtitle: 'StorageBlobLogs — Get operations'
                }
              }
            }
          }
          {
            position: { x: 0, y: 4, rowSpan: 4, colSpan: 6 }
            metadata: {
              type: 'Extension/HubsExtension/PartType/MarkdownPart'
              inputs: []
              settings: {
                content: {
                  content: '## 🗄️ Cosmos DB Requests\n\nRun this query in Log Analytics to see database activity:\n\n```kql\nCDBDataPlaneRequests\n| summarize RequestCount=count() by bin(TimeGenerated, 5m)\n| render timechart\n```\n\n**Workspace:** ${logAnalyticsName}'
                  title: 'Cosmos DB Requests (5-min)'
                  subtitle: 'CDBDataPlaneRequests'
                }
              }
            }
          }
          {
            position: { x: 6, y: 4, rowSpan: 4, colSpan: 6 }
            metadata: {
              type: 'Extension/HubsExtension/PartType/MarkdownPart'
              inputs: []
              settings: {
                content: {
                  content: '## ⚠️ Cosmos DB Errors\n\nRun this query in Log Analytics to see database errors:\n\n```kql\nCDBDataPlaneRequests\n| where StatusCode >= 400\n| summarize Errors=count() by bin(TimeGenerated, 5m)\n| render timechart\n```\n\n**Workspace:** ${logAnalyticsName}'
                  title: 'Cosmos DB Errors (5-min)'
                  subtitle: 'CDBDataPlaneRequests — Status >= 400'
                }
              }
            }
          }
        ]
      }
    ]
    metadata: {
      model: {
        timeRange: {
          value: { relative: { duration: 24, timeUnit: 1 } }
          type: 'MsPortalFx.Composition.Configuration.ValueTypes.TimeRange'
        }
      }
    }
  }
  tags: {
    'hidden-title': 'CalmVault Monitoring Dashboard'
  }
}

// ── Outputs ────────────────────────────────────────────────
output logAnalyticsName string = logAnalytics.name
output dashboardName string = dashboard.name
