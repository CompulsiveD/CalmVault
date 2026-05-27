# Activity 4 — Monitoring & Observability

This activity adds monitoring and observability to CalmVault by wiring existing Azure resources to the Log Analytics workspace created in Activity 3.

## Key Concepts

| Term | What it means |
| --- | --- |
| **Diagnostic Settings** | Configuration that tells an Azure resource to send its logs and metrics to a destination (e.g., Log Analytics) |
| **Log Analytics Workspace** | A central place where Azure collects and stores logs from multiple resources — you can query them with KQL |
| **KQL (Kusto Query Language)** | A query language for searching and analyzing logs in Azure (similar to SQL but for time-series data) |

## What's New

- **Diagnostic Settings** for Storage, Cosmos DB, and Container Registry — all sending logs and metrics to the existing Log Analytics workspace
  - **Storage Account (Blob)** — read/write/delete operations + transaction metrics
  - **Cosmos DB** — data plane requests, query runtime statistics, partition key stats + request metrics
  - **Container Registry** — repository events, login events + all metrics
- **Azure Dashboard** — A portal dashboard with 4 metric chart panels:
  - Storage Transactions — grouped by API name (Put, Get, Delete, etc.) over 24 hours
  - Cosmos DB Total Requests — request volume over 4 hours
  - Cosmos DB Requests by Status Code — grouped by HTTP status over 4 hours
  - Storage Availability — percentage availability over 24 hours
- **Application Insights** — App-level telemetry linked to Log Analytics
  - Auto-collects: incoming requests, outgoing dependencies (Cosmos, Blob), exceptions, performance counters
  - Backend instrumented via `applicationinsights` npm package in `activity-1/backend/src/index.ts`

## Deploy

### 4.1 Deploy Monitoring Infrastructure

From the repository root:

**Bash:**

```bash
az deployment group create \
  --resource-group $RG_NAME \
  --template-file activity-4/infrastructure/main.bicep \
  --name activity4-monitoring
```

**PowerShell:**

```powershell
az deployment group create `
  --resource-group $RG_NAME `
  --template-file activity-4/infrastructure/main.bicep `
  --name activity4-monitoring
```

> **Tip:** This takes about 1–2 minutes. It connects to the Log Analytics workspace created in Activity 3.

### 4.2 Verify

1. Open the [Azure Portal](https://portal.azure.com)
2. Navigate to your resource group (`rg-calmvault-<suffix>-usc`)
3. Click on any resource (e.g., Storage Account) → **Diagnostic settings** in the left menu
4. Confirm you see a diagnostic setting sending logs to the Log Analytics workspace

To query logs (after generating some traffic):

**Bash / PowerShell:**

```bash
az monitor log-analytics query \
  --workspace $(az monitor log-analytics workspace show --resource-group $RG_NAME --workspace-name calmvault-logs-$SUFFIX --query customerId -o tsv) \
  --analytics-query "StorageBlobLogs | take 5"
```

> **Tip:** Logs may take 5–10 minutes to appear after the first request. Upload/download a few files to generate traffic.

## Resources Created

| Resource | Name | Description |
| --- | --- | --- |
| Diagnostic Setting (Storage) | `calmvault<suffix>-blob-diag` | Blob read/write/delete logs + transaction metrics |
| Diagnostic Setting (Cosmos DB) | `calmvault-cosmos-<suffix>-diag` | Data plane requests, query stats, partition key stats |
| Diagnostic Setting (ACR) | `calmvaultacr<suffix>-diag` | Repository events, login events + all metrics |
| Azure Dashboard | `calmvault-dashboard-<suffix>` | 4 panels: storage transactions, Cosmos requests, Cosmos by status, storage availability |

## Log Categories

| Resource | Log Categories | Metrics |
| --- | --- | --- |
| **Storage (Blob)** | StorageRead, StorageWrite, StorageDelete | Transaction |
| **Cosmos DB** | DataPlaneRequests, QueryRuntimeStatistics, PartitionKeyStatistics | Requests |
| **Container Registry** | ContainerRegistryRepositoryEvents, ContainerRegistryLoginEvents | AllMetrics |
