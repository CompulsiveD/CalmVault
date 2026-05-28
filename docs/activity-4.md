---
layout: default
title: "Activity 4 — Monitoring & Observability"
nav_order: 5
---

# Activity 4 — Monitoring & Observability

Now that your app is running, let's add visibility into what's happening. You'll configure **diagnostic settings** so that Azure resources send their logs and metrics to the Log Analytics workspace created in Activity 3.

## What you'll configure

| Resource | What gets logged |
| --- | --- |
| **Azure Blob Storage** | Every read, write, and delete operation on your files |
| **Azure Cosmos DB** | Database queries, request statistics, partition usage |
| **Azure Container Registry** | Image push/pull events, login attempts |

## 4.1 Deploy Diagnostic Settings

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

> **Tip:** This takes about 1–2 minutes. It wires existing resources to send logs to the Log Analytics workspace and creates a monitoring dashboard.

## 4.2 Verify

Open the Azure Portal and check that everything is configured:

1. Navigate to your resource group (`$RG_NAME`)
2. Click on the **Storage Account** → **Diagnostic settings** (under Monitoring)
3. Confirm a setting named `calmvault<suffix>-blob-diag` exists and targets the Log Analytics workspace
4. Repeat for **Cosmos DB** and **Container Registry**
5. Find the **Dashboard** resource (`calmvault-dashboard-<suffix>`) and open it — you'll see 4 empty panels that will populate once traffic flows

## 4.3 Generate Traffic & Query Logs

Upload and download a few files to generate log data, then query:

**Bash:**

```bash
WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group $RG_NAME \
  --workspace-name calmvault-logs-$SUFFIX \
  --query customerId -o tsv)

az monitor log-analytics query \
  --workspace $WORKSPACE_ID \
  --analytics-query "StorageBlobLogs | summarize count() by OperationName | top 5 by count_"
```

**PowerShell:**

```powershell
$WORKSPACE_ID = az monitor log-analytics workspace show `
  --resource-group $RG_NAME `
  --workspace-name "calmvault-logs-$SUFFIX" `
  --query customerId -o tsv

az monitor log-analytics query `
  --workspace $WORKSPACE_ID `
  --analytics-query "StorageBlobLogs | summarize count() by OperationName | top 5 by count_"
```

> **Tip:** Logs may take 5–10 minutes to appear after the first activity. Be patient — if the query returns no results, wait a few minutes and try again.

## 4.4 Enable Application Insights on the Backend

Application Insights provides automatic request/dependency tracking for the Express API.

**Bash:**

```bash
# Get the App Insights connection string from the deployment outputs
APPINSIGHTS_CONN=$(az deployment group show --resource-group $RG_NAME --name activity4-monitoring --query properties.outputs.appInsightsConnectionString.value -o tsv)

echo "APPLICATIONINSIGHTS_CONNECTION_STRING=$APPINSIGHTS_CONN"
```

**PowerShell:**

```powershell
$APPINSIGHTS_CONN = az deployment group show --resource-group $RG_NAME --name activity4-monitoring --query properties.outputs.appInsightsConnectionString.value -o tsv

Write-Output "APPLICATIONINSIGHTS_CONNECTION_STRING=$APPINSIGHTS_CONN"
```

Add this to your `activity-1/backend/.env` file:

```
APPLICATIONINSIGHTS_CONNECTION_STRING=<value from above>
```

Then redeploy the backend container with the new environment variable:

**Bash:**

```bash
az containerapp update \
  --name calmvault-backend-$SUFFIX \
  --resource-group $RG_NAME \
  --set-env-vars "APPLICATIONINSIGHTS_CONNECTION_STRING=$APPINSIGHTS_CONN"
```

**PowerShell:**

```powershell
az containerapp update `
  --name "calmvault-backend-$SUFFIX" `
  --resource-group $RG_NAME `
  --set-env-vars "APPLICATIONINSIGHTS_CONNECTION_STRING=$APPINSIGHTS_CONN"
```

> **What just happened?** The backend now sends telemetry (requests, dependencies, exceptions) to Application Insights. You can view it in the Azure Portal under the Application Insights resource → Live Metrics or Transaction Search.

## 4.5 Verify Application Insights

1. Generate some traffic (upload/download files via the frontend)
2. In the Azure Portal, open **Application Insights** (`calmvault-insights-<suffix>`)
3. Click **Live Metrics** to see requests flowing in real-time
4. Click **Transaction search** to view individual requests with timing and dependencies

---

👉 **Next:** [Activity 5 — AI Auto-Tagging (Optional)]({% link activity-5.md %})
