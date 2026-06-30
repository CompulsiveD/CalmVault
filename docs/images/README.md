# Screenshot Guide

This folder contains screenshots used in the CalmVault deployment lab documentation.

## Folder Structure

```
images/
  activity-1/   ← Infrastructure deployment & local development
  activity-2/   ← Container Registry & cloud builds
  activity-3/   ← Azure Container Apps deployment
  activity-4/   ← Monitoring & observability
  activity-5/   ← AI auto-tagging
  activity-6/   ← Cleanup
```

## Naming Conventions

- Use lowercase with hyphens: `resource-group-overview.png`
- Prefix with the step number when tied to a specific step: `1-1-deploy-output.png`
- Use descriptive names: `cosmos-db-container.png` not `screenshot3.png`
- Prefer PNG format for portal screenshots, GIF for short demos

## Suggested Screenshots

### Activity 1
| Filename | Description |
| --- | --- |
| `1-1-deployment-output.png` | Terminal showing successful `az deployment sub create` output |
| `resource-group-overview.png` | Azure Portal — resource group with storage + cosmos resources |
| `storage-account.png` | Azure Portal — storage account overview |
| `cosmos-db.png` | Azure Portal — Cosmos DB account overview |
| `backend-running.png` | Terminal showing backend `npm run dev` with health check |
| `frontend-ui.png` | Browser showing CalmVault frontend with upload zone |
| `file-uploaded.png` | Browser showing a file in the gallery after upload |

### Activity 2
| Filename | Description |
| --- | --- |
| `acr-build-output.png` | Terminal showing `az acr build` progress/success |
| `acr-repositories.png` | Azure Portal — ACR repository list showing both images |

### Activity 3
| Filename | Description |
| --- | --- |
| `container-apps-overview.png` | Azure Portal — Container Apps Environment with both apps |
| `backend-health.png` | Browser/terminal showing backend health endpoint response |
| `frontend-deployed.png` | Browser showing CalmVault running at the Container App URL |

### Activity 4
| Filename | Description |
| --- | --- |
| `diagnostic-settings.png` | Azure Portal — diagnostic settings on a resource |
| `dashboard.png` | Azure Portal — monitoring dashboard with chart panels |
| `app-insights-live.png` | Azure Portal — Application Insights live metrics |
| `log-query-results.png` | Terminal or Portal showing KQL query results |

### Activity 5
| Filename | Description |
| --- | --- |
| `openai-resource.png` | Azure Portal — Azure OpenAI resource with GPT-4o deployment |
| `event-grid-topic.png` | Azure Portal — Event Grid system topic with subscription |
| `storage-queue.png` | Azure Portal — Storage Queue with blob-events queue |
| `tagger-job.png` | Azure Portal — Container App Job executions |
| `auto-tagged-file.png` | Browser — file detail showing `ai:` prefixed tags |

### Activity 6
| Filename | Description |
| --- | --- |
| `empty-resource-group.png` | Azure Portal — resource group with no resources after cleanup |
