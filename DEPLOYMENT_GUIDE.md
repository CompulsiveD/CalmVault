# CalmVault — Deployment Guide

A hands-on guide to deploying CalmVault from scratch. This lab is designed for developers at the **100–200 level** — you should be comfortable with basic command-line usage and web development, but no prior Azure experience is required.

---

## Prerequisites

- [Node.js](https://nodejs.org/) 20+ — the JavaScript runtime for our backend and frontend build tools
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) — a command-line tool for managing Azure resources
- An active Azure subscription — [create a free account](https://azure.microsoft.com/free/) if you don't have one

**Before starting**, make sure you're logged into Azure:

**Bash / PowerShell:**

```bash
az login
```

This opens a browser window for authentication. Once logged in, verify your subscription:

```bash
az account show --query name -o tsv
```

---

## Activity 1 — Deploy Infrastructure & Run Locally

In this activity, you'll create cloud resources in Azure (a storage account for files and a database for metadata), then run the application on your local machine connected to those cloud resources.

### What you'll create

| Resource | Purpose |
| --- | --- |
| **Azure Blob Storage** | Stores the actual uploaded files (images, documents, etc.) |
| **Azure Cosmos DB** | Stores metadata about each file (name, tags, upload date) |

### 1.1 Deploy Azure Resources

This command tells Azure to create all the resources defined in our Bicep template. [Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview) is Azure's infrastructure-as-code language — think of it as a blueprint for cloud resources.

**Bash:**

```bash
az deployment sub create \
  --location centralus \
  --template-file activity-1/infrastructure/main.bicep
```

**PowerShell:**

```powershell
az deployment sub create `
  --location centralus `
  --template-file activity-1/infrastructure/main.bicep
```

> **Tip:** This may take 2–5 minutes. You'll see a JSON output when it completes. If you get an error about the location, make sure you typed `centralus` (no space).

### 1.2 Save Deployment Outputs

The deployment created resources with auto-generated names. Let's save those names — you'll need them for configuration and all subsequent activities.

**Bash:**

```bash
SUFFIX=$(az deployment sub show --name main --query properties.outputs.suffix.value -o tsv)
COSMOS_ENDPOINT=$(az deployment sub show --name main --query properties.outputs.cosmosEndpoint.value -o tsv)
STORAGE_ACCOUNT=$(az deployment sub show --name main --query properties.outputs.storageAccountName.value -o tsv)

echo "SUFFIX:          $SUFFIX"
echo "COSMOS_ENDPOINT: $COSMOS_ENDPOINT"
echo "STORAGE_ACCOUNT: $STORAGE_ACCOUNT"
```

**PowerShell:**

```powershell
$SUFFIX = az deployment sub show --name main --query properties.outputs.suffix.value -o tsv
$COSMOS_ENDPOINT = az deployment sub show --name main --query properties.outputs.cosmosEndpoint.value -o tsv
$STORAGE_ACCOUNT = az deployment sub show --name main --query properties.outputs.storageAccountName.value -o tsv

Write-Output "SUFFIX:          $SUFFIX"
Write-Output "COSMOS_ENDPOINT: $COSMOS_ENDPOINT"
Write-Output "STORAGE_ACCOUNT: $STORAGE_ACCOUNT"
```

> **Tip:** Write down the `SUFFIX` value (e.g., `a1b2`). It's a 4-character code unique to your subscription and used in all resource names throughout this lab. If you close your terminal, you can always re-run these commands to get the values again.

### 1.3 Retrieve Secrets & Generate .env File

Some sensitive values (connection strings, keys) are intentionally excluded from Bicep outputs for security. The commands below retrieve those secrets and print the complete `.env` file content — ready to copy and paste.

**Bash:**

```bash
# Retrieve secrets using variables from Activity 1.2
STORAGE_CONN=$(az storage account show-connection-string \
  --name $STORAGE_ACCOUNT \
  --resource-group rg-calmvault-${SUFFIX} \
  --query connectionString -o tsv)

COSMOS_KEY=$(az cosmosdb keys list \
  --name calmvault-cosmos-${SUFFIX} \
  --resource-group rg-calmvault-${SUFFIX} \
  --query primaryMasterKey -o tsv)

# Print the complete .env file — copy everything between the lines
echo "──────────── .env content (copy below) ────────────"
echo "PORT=3001"
echo "AZURE_STORAGE_CONNECTION_STRING=$STORAGE_CONN"
echo "AZURE_STORAGE_CONTAINER_NAME=calmvault-files"
echo "COSMOS_ENDPOINT=$COSMOS_ENDPOINT"
echo "COSMOS_KEY=$COSMOS_KEY"
echo "COSMOS_DATABASE_NAME=calmvault"
echo "──────────── end of .env content ────────────"
```

**PowerShell:**

```powershell
# Retrieve secrets using variables from Activity 1.2
$STORAGE_CONN = az storage account show-connection-string `
  --name $STORAGE_ACCOUNT `
  --resource-group "rg-calmvault-$SUFFIX" `
  --query connectionString -o tsv

$COSMOS_KEY = az cosmosdb keys list `
  --name "calmvault-cosmos-$SUFFIX" `
  --resource-group "rg-calmvault-$SUFFIX" `
  --query primaryMasterKey -o tsv

# Print the complete .env file — copy everything between the lines
Write-Output @"
──────────── .env content (copy below) ────────────
PORT=3001
AZURE_STORAGE_CONNECTION_STRING=$STORAGE_CONN
AZURE_STORAGE_CONTAINER_NAME=calmvault-files
COSMOS_ENDPOINT=$COSMOS_ENDPOINT
COSMOS_KEY=$COSMOS_KEY
COSMOS_DATABASE_NAME=calmvault
──────────── end of .env content ────────────
"@
```

> **What just happened?** You retrieved the storage connection string (like a URL + password for the storage account) and the Cosmos DB primary key (the database password). These are printed as a ready-to-use `.env` file.

### 1.4 Configure the Backend

Create the `.env` file and paste the output from Activity 1.3:

**Bash:**

```bash
cd activity-1/backend
cp .env.example .env
```

**PowerShell:**

```powershell
Set-Location activity-1/backend
Copy-Item .env.example .env
```

Open `activity-1/backend/.env` in your editor and replace its contents with the output you copied from Activity 1.3 (everything between the `────────` lines).

> **Tip:** The `.env` file is git-ignored so your secrets won't accidentally get committed to source control.

### 1.5 Start the Backend

**Bash / PowerShell:**

```bash
cd activity-1/backend
npm install
npm run dev
```

`npm install` downloads all the dependencies. `npm run dev` starts the server with auto-reload (it will restart automatically when you edit code).

Verify it's running:

**Bash:**

```bash
curl http://localhost:3001/api/health
# Expected: {"status":"ok"}
```

**PowerShell:**

```powershell
Invoke-RestMethod http://localhost:3001/api/health
# Expected: @{status=ok}
```

> **Tip:** If you get "connection refused", make sure the backend started without errors. Check the terminal where you ran `npm run dev` for error messages — usually a missing `.env` value.

### 1.6 Start the Frontend

In a **new terminal window** (keep the backend running):

**Bash / PowerShell:**

```bash
cd activity-1/frontend
npm install
npm run dev
```

Open [http://localhost:5173](http://localhost:5173) in your browser. You should see the CalmVault interface with a drag & drop upload zone.

> **Tip:** The frontend talks to the backend at `http://localhost:3001`. Both must be running simultaneously.

### 1.7 Verify End-to-End

1. Drag a file onto the upload zone (or click to browse)
2. Add a tag (e.g., "test") and upload
3. Confirm the file appears in the gallery
4. Click the file to preview it
5. Delete the file and confirm it's removed

If everything works, congratulations! Your app is running locally and storing files in Azure. 🎉

---

## Activity 2 — Build Container Images with ACR

Now that the app works locally, let's package it into **containers** — portable, self-contained units that can run anywhere. We'll use **Azure Container Registry (ACR)** to build the containers in the cloud, so you don't need Docker installed on your machine.

### What you'll create

| Resource | Purpose |
| --- | --- |
| **Azure Container Registry** | A private registry (like a warehouse) that stores your container images |

### What's a container?

Think of a container as a zip file that includes your app code plus everything it needs to run (Node.js, dependencies, config). Unlike running locally with `npm run dev`, a container works the same way in any environment.

### 2.1 Deploy Infrastructure (with ACR)

This deploys the same resources as Activity 1, plus a Container Registry:

**Bash:**

```bash
az deployment sub create \
  --location centralus \
  --template-file activity-2/infrastructure/main.bicep
```

**PowerShell:**

```powershell
az deployment sub create `
  --location centralus `
  --template-file activity-2/infrastructure/main.bicep
```

### 2.2 Build the Container Images Remotely

The `az acr build` command sends your source code to Azure, which builds the container image in the cloud. No Docker needed on your machine!

**Bash:**

```bash
# Use the SUFFIX saved from Activity 1.2
ACR_NAME=calmvaultacr${SUFFIX}

# Build backend container
az acr build \
  --registry $ACR_NAME \
  --image calmvault-backend:latest \
  --file activity-1/backend/Dockerfile \
  .

# Build frontend container
az acr build \
  --registry $ACR_NAME \
  --image calmvault-frontend:latest \
  --file activity-1/frontend/Dockerfile \
  .
```

**PowerShell:**

```powershell
# Use the $SUFFIX saved from Activity 1.2
$ACR_NAME = "calmvaultacr$SUFFIX"

# Build backend container
az acr build `
  --registry $ACR_NAME `
  --image calmvault-backend:latest `
  --file activity-1/backend/Dockerfile `
  .

# Build frontend container
az acr build `
  --registry $ACR_NAME `
  --image calmvault-frontend:latest `
  --file activity-1/frontend/Dockerfile `
  .
```

> **Tip:** Each build takes 1–3 minutes. The `.` at the end means "use the current directory as the build context" — this is why you must run this from the repository root.

### 2.3 Verify

Confirm both images were created:

**Bash / PowerShell:**

```bash
az acr repository list --name $ACR_NAME --output table
# Expected: calmvault-backend, calmvault-frontend

az acr repository show-tags --name $ACR_NAME --repository calmvault-backend --output table
# Expected: latest
```

---

## Activity 3 — Deploy to Azure Container Apps

Now let's run those containers in the cloud! **Azure Container Apps** is a managed service that runs your containers, handles scaling (more traffic = more instances), and gives you a public URL — without managing servers.

### What you'll create

| Resource | Purpose |
| --- | --- |
| **Log Analytics Workspace** | Collects logs from your containers (for debugging) |
| **Container Apps Environment** | A shared network for your containers to communicate |
| **Backend Container App** | Runs the Express API (auto-scales 0–3 instances) |
| **Frontend Container App** | Runs the nginx SPA server (auto-scales 0–3 instances) |

### 3.1 Deploy Backend Container App

> **Prerequisite:** Container images must exist in ACR. Complete Activity 2 first.

This deploys the Log Analytics workspace, Container Apps Environment, and the backend Container App:

**Bash:**

```bash
az deployment sub create \
  --location centralus \
  --template-file activity-3/infrastructure/backend.main.bicep
```

**PowerShell:**

```powershell
az deployment sub create `
  --location centralus `
  --template-file activity-3/infrastructure/backend.main.bicep
```

> **Tip:** This activity takes 3–5 minutes because it creates the Container Apps Environment and wires up secrets (storage connection string, Cosmos DB key) so the backend container can access Azure services.

### 3.2 Save Backend Deployment Outputs

Save the backend URL — you'll need it to configure the frontend.

**Bash:**

```bash
BACKEND_URL=$(az deployment sub show --name backend.main --query properties.outputs.backendUrl.value -o tsv)

echo "BACKEND_URL: $BACKEND_URL"
```

**PowerShell:**

```powershell
$BACKEND_URL = az deployment sub show --name backend.main --query properties.outputs.backendUrl.value -o tsv

Write-Output "BACKEND_URL: $BACKEND_URL"
```

### 3.3 Update Frontend API Proxy

The frontend needs to know where the backend lives. Rebuild the frontend container with the backend URL baked in:

**Bash:**

```bash
# Use the SUFFIX saved from Activity 1.2
ACR_NAME=calmvaultacr${SUFFIX}

az acr build \
  --registry $ACR_NAME \
  --image calmvault-frontend:latest \
  --file activity-1/frontend/Dockerfile \
  --build-arg VITE_API_BASE_URL=$BACKEND_URL \
  .
```

**PowerShell:**

```powershell
# Use the $SUFFIX saved from Activity 1.2
$ACR_NAME = "calmvaultacr$SUFFIX"

az acr build `
  --registry $ACR_NAME `
  --image calmvault-frontend:latest `
  --file activity-1/frontend/Dockerfile `
  --build-arg "VITE_API_BASE_URL=$BACKEND_URL" `
  .
```

### 3.4 Deploy Frontend Container App

Now deploy the frontend Container App with the updated image:

**Bash:**

```bash
az deployment sub create \
  --location centralus \
  --template-file activity-3/infrastructure/frontend.main.bicep
```

**PowerShell:**

```powershell
az deployment sub create `
  --location centralus `
  --template-file activity-3/infrastructure/frontend.main.bicep
```

Save the frontend URL:

**Bash:**

```bash
FRONTEND_URL=$(az deployment sub show --name frontend.main --query properties.outputs.frontendUrl.value -o tsv)

echo "FRONTEND_URL: $FRONTEND_URL"
```

**PowerShell:**

```powershell
$FRONTEND_URL = az deployment sub show --name frontend.main --query properties.outputs.frontendUrl.value -o tsv

Write-Output "FRONTEND_URL: $FRONTEND_URL"
```

### 3.5 Verify

**Bash:**

```bash
curl $BACKEND_URL/api/health
# Expected: {"status":"ok"}

echo $FRONTEND_URL
```

**PowerShell:**

```powershell
Invoke-RestMethod "$BACKEND_URL/api/health"
# Expected: @{status=ok}

Write-Output $FRONTEND_URL
```

Open the frontend URL in your browser. Upload a file and confirm it round-trips through the backend to Blob Storage.

> **Tip:** The first request may take 10–20 seconds because Container Apps scales from zero. Subsequent requests will be fast.

Congratulations — CalmVault is now running in the cloud! 🚀

---

## Activity 4 — Monitoring & Observability

Now that your app is running, let's add visibility into what's happening. You'll configure **diagnostic settings** so that Azure resources send their logs and metrics to the Log Analytics workspace created in Activity 3.

### Prerequisites

Register the `Microsoft.App` resource provider (required for updating Container Apps later in this activity):

**Bash:**

```bash
az provider register -n Microsoft.App --wait
```

**PowerShell:**

```powershell
az provider register -n Microsoft.App --wait
```

> **Note:** This may take a minute. It only needs to be done once per subscription.

### What you'll configure

| Resource | What gets logged |
| --- | --- |
| **Azure Blob Storage** | Every read, write, and delete operation on your files |
| **Azure Cosmos DB** | Database queries, request statistics, partition usage |
| **Azure Container Registry** | Image push/pull events, login attempts |

### 4.1 Deploy Diagnostic Settings

**Bash:**

```bash
az deployment sub create \
  --location centralus \
  --template-file activity-4/infrastructure/main.bicep
```

**PowerShell:**

```powershell
az deployment sub create `
  --location centralus `
  --template-file activity-4/infrastructure/main.bicep
```

> **Tip:** This takes about 1–2 minutes. It wires existing resources to send logs to the Log Analytics workspace and creates a monitoring dashboard.

### 4.2 Verify

Open the Azure Portal and check that everything is configured:

1. Navigate to your resource group (`rg-calmvault-<suffix>`)
2. Click on the **Storage Account** → **Diagnostic settings** (under Monitoring)
3. Confirm a setting named `calmvault<suffix>-blob-diag` exists and targets the Log Analytics workspace
4. Repeat for **Cosmos DB** and **Container Registry**
5. Find the **Dashboard** resource (`calmvault-dashboard-<suffix>`) and open it — you'll see 4 empty panels that will populate once traffic flows

### 4.3 Generate Traffic & Query Logs

Upload and download a few files to generate log data, then query:

**Bash:**

```bash
WORKSPACE_ID=$(az monitor log-analytics workspace show \
  --resource-group rg-calmvault-$SUFFIX \
  --workspace-name calmvault-logs-$SUFFIX \
  --query customerId -o tsv)

az monitor log-analytics query \
  --workspace $WORKSPACE_ID \
  --analytics-query "StorageBlobLogs | summarize count() by OperationName | top 5 by count_"
```

**PowerShell:**

```powershell
$WORKSPACE_ID = az monitor log-analytics workspace show `
  --resource-group "rg-calmvault-$SUFFIX" `
  --workspace-name "calmvault-logs-$SUFFIX" `
  --query customerId -o tsv

az monitor log-analytics query `
  --workspace $WORKSPACE_ID `
  --analytics-query "StorageBlobLogs | summarize count() by OperationName | top 5 by count_"
```

> **Tip:** Logs may take 5–10 minutes to appear after the first activity. Be patient — if the query returns no results, wait a few minutes and try again.

### 4.4 Enable Application Insights on the Backend

Application Insights provides automatic request/dependency tracking for the Express API.

**Bash:**

```bash
# Get the App Insights connection string from the deployment outputs
APPINSIGHTS_CONN=$(az deployment sub show --name main --query properties.outputs.appInsightsConnectionString.value -o tsv)

echo "APPLICATIONINSIGHTS_CONNECTION_STRING=$APPINSIGHTS_CONN"
```

**PowerShell:**

```powershell
$APPINSIGHTS_CONN = az deployment sub show --name main --query properties.outputs.appInsightsConnectionString.value -o tsv

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
  --resource-group rg-calmvault-$SUFFIX \
  --set-env-vars "APPLICATIONINSIGHTS_CONNECTION_STRING=$APPINSIGHTS_CONN"
```

**PowerShell:**

```powershell
az containerapp update `
  --name "calmvault-backend-$SUFFIX" `
  --resource-group "rg-calmvault-$SUFFIX" `
  --set-env-vars "APPLICATIONINSIGHTS_CONNECTION_STRING=$APPINSIGHTS_CONN"
```

> **What just happened?** The backend now sends telemetry (requests, dependencies, exceptions) to Application Insights. You can view it in the Azure Portal under the Application Insights resource → Live Metrics or Transaction Search.

### 4.5 Verify Application Insights

1. Generate some traffic (upload/download files via the frontend)
2. In the Azure Portal, open **Application Insights** (`calmvault-insights-<suffix>`)
3. Click **Live Metrics** to see requests flowing in real-time
4. Click **Transaction search** to view individual requests with timing and dependencies

---

## Activity 5 — AI Auto-Tagging (Optional)

This optional activity adds an AI-powered service that automatically tags uploaded files using Azure OpenAI GPT-4o. When a file is uploaded, Event Grid triggers the tagger Container App which analyzes the content and adds `ai:`-prefixed tags to the Cosmos DB document.

> **Prerequisites:** Activities 1–3 must be deployed. Azure OpenAI access must be available on your subscription.

### 5.1 Register Resource Providers

**Bash:**

```bash
az provider register -n Microsoft.EventGrid --wait
az provider register -n Microsoft.CognitiveServices --wait
```

**PowerShell:**

```powershell
az provider register -n Microsoft.EventGrid --wait
az provider register -n Microsoft.CognitiveServices --wait
```

### 5.2 Build and Push the Tagger Image

**Bash:**

```bash
az acr build \
  --registry calmvaultacr$SUFFIX \
  --image calmvault-tagger:latest \
  --file activity-5/tagger/Dockerfile .
```

**PowerShell:**

```powershell
az acr build `
  --registry "calmvaultacr$SUFFIX" `
  --image calmvault-tagger:latest `
  --file activity-5/tagger/Dockerfile .
```

### 5.3 Deploy Infrastructure

**Bash:**

```bash
az deployment sub create \
  --location centralus \
  --template-file activity-5/infrastructure/main.bicep
```

**PowerShell:**

```powershell
az deployment sub create `
  --location centralus `
  --template-file activity-5/infrastructure/main.bicep
```

> **Tip:** This deploys Azure OpenAI with a GPT-4o model, an Event Grid system topic, a Storage Queue, and the tagger Container App. It may take 2–3 minutes.

### 5.4 Verify

1. Navigate to your resource group in the Azure Portal
2. Confirm the **Azure OpenAI** resource (`calmvault-openai-<suffix>`) exists with a `gpt-4o` deployment
3. Check the **Storage Account** → **Queues** — you should see a `blob-events` queue
4. Open **Event Grid System Topics** — confirm `calmvault-storage-events-<suffix>` has a subscription
5. Check **Container App Jobs** — `calmvault-tagger-<suffix>` should exist (no active executions when idle)

### 5.5 Test Auto-Tagging

1. Upload an image or text file through the CalmVault frontend
2. Wait 30–60 seconds for the tagger to process the event
3. Refresh the file in the frontend — you should see `ai:`-prefixed tags (e.g., `ai:landscape`, `ai:document`)

> **Note:** The tagger scales from 0, so the first event may take longer while the container starts up. Subsequent events are faster.

---

## Activity 6 — Cleanup

When you're finished with the lab, delete all Azure resources to avoid ongoing charges.

> ⚠️ **This is irreversible.** All uploaded files, database records, container images, and telemetry data will be permanently deleted. Download anything you want to keep before proceeding.

### 6.1 Delete the Resource Group

This single command removes every Azure resource created across Activities 1–5:

**Bash:**

```bash
az group delete --name rg-calmvault-$SUFFIX --yes --no-wait
```

**PowerShell:**

```powershell
az group delete --name "rg-calmvault-$SUFFIX" --yes --no-wait
```

> **What just happened?** The `--no-wait` flag returns immediately while Azure deletes resources in the background. Full deletion typically takes 2–5 minutes.

### 6.2 Purge Soft-Deleted Azure OpenAI (Optional)

If you completed Activity 5, the Azure OpenAI account enters a 48-hour soft-delete period after resource group deletion. Purge it immediately if you plan to re-run the lab or need to free up quota:

**Bash:**

```bash
az cognitiveservices account purge \
  --name calmvault-openai-$SUFFIX \
  --resource-group rg-calmvault-$SUFFIX \
  --location centralus
```

**PowerShell:**

```powershell
az cognitiveservices account purge `
  --name "calmvault-openai-$SUFFIX" `
  --resource-group "rg-calmvault-$SUFFIX" `
  --location centralus
```

> **Tip:** If you get an error that the resource group doesn't exist (because it was already deleted), that's expected. The purge command uses the original resource group name as a reference but doesn't require it to still exist.

### 6.3 Verify Cleanup

After a few minutes, confirm the resource group is gone:

**Bash:**

```bash
az group show --name rg-calmvault-$SUFFIX 2>&1 || echo "Resource group deleted successfully"
```

**PowerShell:**

```powershell
az group show --name "rg-calmvault-$SUFFIX" 2>&1; if ($LASTEXITCODE -ne 0) { Write-Output "Resource group deleted successfully" }
```

---

## Congratulations! 🎉

You've completed the CalmVault deployment lab. Here's what you built and learned:

| Activity | What you did | Skills practiced |
| --- | --- | --- |
| 1 | Deployed Azure infrastructure and ran the app locally | Bicep, Azure Storage, Cosmos DB |
| 2 | Built container images in the cloud | Docker, Azure Container Registry |
| 3 | Deployed to Azure Container Apps | Managed containers, auto-scaling, secrets |
| 4 | Added monitoring and observability | Diagnostic settings, Log Analytics, Application Insights |
| 5 | Added AI auto-tagging (optional) | Azure OpenAI, Event Grid, Container App Jobs |
| 6 | Cleaned up all resources | Resource lifecycle management |

