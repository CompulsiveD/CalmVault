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
var appInsightsName = '${projectName}-insights-${suffix}'

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

// ── Application Insights ───────────────────────────────────
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
    RetentionInDays: 30
  }
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
              inputs: [
                {
                  name: 'sharedTimeRange'
                  isOptional: true
                }
                {
                  name: 'options'
                  value: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: storageAccount.id
                          }
                          name: 'Transactions'
                          aggregationType: 1
                          namespace: 'microsoft.storage/storageaccounts'
                          metricVisualization: {
                            displayName: 'Transactions'
                          }
                        }
                      ]
                      title: 'Storage Transactions'
                      titleKind: 2
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: { isVisible: true, axisType: 2 }
                          y: { isVisible: true, axisType: 1 }
                        }
                      }
                      grouping: {
                        dimension: 'ApiName'
                        top: 10
                      }
                      timespan: {
                        relative: { duration: 86400000 }
                        showUTCTime: false
                        grain: 1
                      }
                    }
                  }
                  isOptional: true
                }
              ]
              #disable-next-line BCP036
              type: 'Extension/HubsExtension/PartType/MonitorChartPart'
              settings: {
                content: {
                  options: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: storageAccount.id
                          }
                          name: 'Transactions'
                          aggregationType: 1
                          namespace: 'microsoft.storage/storageaccounts'
                          metricVisualization: {
                            displayName: 'Transactions'
                          }
                        }
                      ]
                      title: 'Storage Transactions'
                      titleKind: 2
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: { isVisible: true, axisType: 2 }
                          y: { isVisible: true, axisType: 1 }
                        }
                        disablePinning: true
                      }
                      grouping: {
                        dimension: 'ApiName'
                        top: 10
                      }
                    }
                  }
                }
              }
            }
          }
          {
            position: { x: 6, y: 0, rowSpan: 4, colSpan: 6 }
            metadata: {
              inputs: [
                {
                  name: 'sharedTimeRange'
                  isOptional: true
                }
                {
                  name: 'options'
                  value: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: cosmosAccount.id
                          }
                          name: 'TotalRequests'
                          aggregationType: 7
                          namespace: 'microsoft.documentdb/databaseaccounts'
                          metricVisualization: {
                            displayName: 'Total Requests'
                          }
                        }
                      ]
                      title: 'Cosmos DB — Total Requests'
                      titleKind: 2
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: { isVisible: true, axisType: 2 }
                          y: { isVisible: true, axisType: 1 }
                        }
                      }
                      timespan: {
                        relative: { duration: 14400000 }
                        showUTCTime: false
                        grain: 1
                      }
                    }
                  }
                  isOptional: true
                }
              ]
              #disable-next-line BCP036
              type: 'Extension/HubsExtension/PartType/MonitorChartPart'
              settings: {
                content: {
                  options: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: cosmosAccount.id
                          }
                          name: 'TotalRequests'
                          aggregationType: 7
                          namespace: 'microsoft.documentdb/databaseaccounts'
                          metricVisualization: {
                            displayName: 'Total Requests'
                          }
                        }
                      ]
                      title: 'Cosmos DB — Total Requests'
                      titleKind: 2
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: { isVisible: true, axisType: 2 }
                          y: { isVisible: true, axisType: 1 }
                        }
                        disablePinning: true
                      }
                    }
                  }
                }
              }
            }
          }
          {
            position: { x: 0, y: 4, rowSpan: 4, colSpan: 6 }
            metadata: {
              inputs: [
                {
                  name: 'sharedTimeRange'
                  isOptional: true
                }
                {
                  name: 'options'
                  value: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: cosmosAccount.id
                          }
                          name: 'TotalRequests'
                          aggregationType: 7
                          namespace: 'microsoft.documentdb/databaseaccounts'
                          metricVisualization: {
                            displayName: 'Total Requests'
                          }
                        }
                      ]
                      title: 'Cosmos DB — Requests by Status Code'
                      titleKind: 2
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: { isVisible: true, axisType: 2 }
                          y: { isVisible: true, axisType: 1 }
                        }
                      }
                      grouping: {
                        dimension: 'StatusCode'
                        top: 50
                      }
                      timespan: {
                        relative: { duration: 14400000 }
                        showUTCTime: false
                        grain: 1
                      }
                    }
                  }
                  isOptional: true
                }
              ]
              #disable-next-line BCP036
              type: 'Extension/HubsExtension/PartType/MonitorChartPart'
              settings: {
                content: {
                  options: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: cosmosAccount.id
                          }
                          name: 'TotalRequests'
                          aggregationType: 7
                          namespace: 'microsoft.documentdb/databaseaccounts'
                          metricVisualization: {
                            displayName: 'Total Requests'
                          }
                        }
                      ]
                      title: 'Cosmos DB — Requests by Status Code'
                      titleKind: 2
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: { isVisible: true, axisType: 2 }
                          y: { isVisible: true, axisType: 1 }
                        }
                        disablePinning: true
                      }
                      grouping: {
                        dimension: 'StatusCode'
                        top: 50
                      }
                    }
                  }
                }
              }
            }
          }
          {
            position: { x: 6, y: 4, rowSpan: 4, colSpan: 6 }
            metadata: {
              inputs: [
                {
                  name: 'sharedTimeRange'
                  isOptional: true
                }
                {
                  name: 'options'
                  value: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: storageAccount.id
                          }
                          name: 'Availability'
                          aggregationType: 4
                          namespace: 'microsoft.storage/storageaccounts'
                          metricVisualization: {
                            displayName: 'Availability'
                          }
                        }
                      ]
                      title: 'Storage Availability'
                      titleKind: 2
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: { isVisible: true, axisType: 2 }
                          y: { isVisible: true, axisType: 1 }
                        }
                      }
                      timespan: {
                        relative: { duration: 86400000 }
                        showUTCTime: false
                        grain: 1
                      }
                    }
                  }
                  isOptional: true
                }
              ]
              #disable-next-line BCP036
              type: 'Extension/HubsExtension/PartType/MonitorChartPart'
              settings: {
                content: {
                  options: {
                    chart: {
                      metrics: [
                        {
                          resourceMetadata: {
                            id: storageAccount.id
                          }
                          name: 'Availability'
                          aggregationType: 4
                          namespace: 'microsoft.storage/storageaccounts'
                          metricVisualization: {
                            displayName: 'Availability'
                          }
                        }
                      ]
                      title: 'Storage Availability'
                      titleKind: 2
                      visualization: {
                        chartType: 2
                        legendVisualization: {
                          isVisible: true
                          position: 2
                          hideSubtitle: false
                        }
                        axisVisualization: {
                          x: { isVisible: true, axisType: 2 }
                          y: { isVisible: true, axisType: 1 }
                        }
                        disablePinning: true
                      }
                    }
                  }
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
output appInsightsName string = appInsights.name
output appInsightsConnectionString string = appInsights.properties.ConnectionString
