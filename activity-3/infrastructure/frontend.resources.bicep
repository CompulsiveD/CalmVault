@description('Azure region for all resources')
param location string

@description('Project name used in resource naming')
param projectName string

@description('Random suffix for unique names')
param suffix string

// ── Naming ─────────────────────────────────────────────────
var acrName = '${projectName}acr${suffix}'
var envName = '${projectName}-env-${suffix}'
var frontendAppName = '${projectName}-frontend-${suffix}'

// ── Existing Resources ─────────────────────────────────────
resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing = {
  name: acrName
}

resource containerAppEnv 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: envName
}

// ── Frontend Container App ─────────────────────────────────
resource frontendApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: frontendAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        transport: 'http'
      }
      registries: [
        {
          server: acr.properties.loginServer
          username: acr.listCredentials().username
          passwordSecretRef: 'acr-password'
        }
      ]
      secrets: [
        {
          name: 'acr-password'
          value: acr.listCredentials().passwords[0].value
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'frontend'
          image: '${acr.properties.loginServer}/calmvault-frontend:latest'
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 3
      }
    }
  }
}

// ── Outputs ────────────────────────────────────────────────
output frontendUrl string = 'https://${frontendApp.properties.configuration.ingress.fqdn}'
