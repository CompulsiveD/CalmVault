# CalmVault — Deployment Guide

A step-by-step guide to deploying CalmVault from scratch. This lab is designed for developers at the **100–200 level** — you should be comfortable with basic command-line usage and web development, but no prior Azure experience is required.

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

## Step 1 — Deploy Infrastructure & Run Locally

In this step, you'll create cloud resources in Azure (a storage account for files and a database for metadata), then run the application on your local machine connected to those cloud resources.

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
  --template-file step-1/infrastructure/main.bicep
```

**PowerShell:**

```powershell
az deployment sub create `
  --location centralus `
  --template-file step-1/infrastructure/main.bicep
```

> **Tip:** This may take 2–5 minutes. You'll see a JSON output when it completes. If you get an error about the location, make sure you typed `centralus` (no space).

### 1.2 Save Deployment Outputs

The deployment created resources with auto-generated names. Let's save those names — you'll need them for configuration and all subsequent steps.

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
# Retrieve secrets using variables from step 1.2
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
# Retrieve secrets using variables from step 1.2
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


> **What just happened?** You retrieved the storage connection string (like a URL + password for the storage account) and the Cosmos DB primary key (the database password). These are printed as a ready-to-use `.env` file.

### 1.4 Configure the Backend

Create the `.env` file and paste the output from step 1.3:

**Bash:**

```bash
cd step-1/backend
cp .env.example .env
```

**PowerShell:**

```powershell
Set-Location step-1/backend
Copy-Item .env.example .env
```

Open `step-1/backend/.env` in your editor and replace its contents with the output you copied from step 1.3 (everything between the `────────` lines).

> **Tip:** The `.env` file is git-ignored so your secrets won't accidentally get committed to source control.

### 1.5 Start the Backend

**Bash / PowerShell:**

```bash
cd step-1/backend
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
cd step-1/frontend
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

## Step 2 — Build Container Images with ACR

Now that the app works locally, let's package it into **containers** — portable, self-contained units that can run anywhere. We'll use **Azure Container Registry (ACR)** to build the containers in the cloud, so you don't need Docker installed on your machine.

### What you'll create

| Resource | Purpose |
| --- | --- |
| **Azure Container Registry** | A private registry (like a warehouse) that stores your container images |

### What's a container?

Think of a container as a zip file that includes your app code plus everything it needs to run (Node.js, dependencies, config). Unlike running locally with `npm run dev`, a container works the same way in any environment.

### 2.1 Deploy Infrastructure (with ACR)

This deploys the same resources as Step 1, plus a Container Registry:

**Bash:**

```bash
az deployment sub create \
  --location centralus \
  --template-file step-2/infrastructure/main.bicep
```

**PowerShell:**

```powershell
az deployment sub create `
  --location centralus `
  --template-file step-2/infrastructure/main.bicep
```

### 2.2 Build the Container Images Remotely

The `az acr build` command sends your source code to Azure, which builds the container image in the cloud. No Docker needed on your machine!

**Bash:**

```bash
# Use the SUFFIX saved from step 1.2
ACR_NAME=calmvaultacr${SUFFIX}

# Build backend container
az acr build \
  --registry $ACR_NAME \
  --image calmvault-backend:latest \
  --file step-1/backend/Dockerfile \
  .

# Build frontend container
az acr build \
  --registry $ACR_NAME \
  --image calmvault-frontend:latest \
  --file step-1/frontend/Dockerfile \
  .
```

**PowerShell:**

```powershell
# Use the $SUFFIX saved from step 1.2
$ACR_NAME = "calmvaultacr$SUFFIX"

# Build backend container
az acr build `
  --registry $ACR_NAME `
  --image calmvault-backend:latest `
  --file step-1/backend/Dockerfile `
  .

# Build frontend container
az acr build `
  --registry $ACR_NAME `
  --image calmvault-frontend:latest `
  --file step-1/frontend/Dockerfile `
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

## Step 3 — Deploy to Azure Container Apps

Now let's run those containers in the cloud! **Azure Container Apps** is a managed service that runs your containers, handles scaling (more traffic = more instances), and gives you a public URL — without managing servers.

### What you'll create

| Resource | Purpose |
| --- | --- |
| **Log Analytics Workspace** | Collects logs from your containers (for debugging) |
| **Container Apps Environment** | A shared network for your containers to communicate |
| **Backend Container App** | Runs the Express API (auto-scales 0–3 instances) |
| **Frontend Container App** | Runs the nginx SPA server (auto-scales 0–3 instances) |

### 3.1 Deploy Infrastructure (with Container Apps)

> **Prerequisite:** Container images must exist in ACR. Complete Step 2 first.

**Bash:**

```bash
az deployment sub create \
  --location centralus \
  --template-file step-3/infrastructure/main.bicep
```

**PowerShell:**

```powershell
az deployment sub create `
  --location centralus `
  --template-file step-3/infrastructure/main.bicep
```

> **Tip:** This step takes 3–5 minutes because it creates several resources. The template automatically wires up the secrets (storage connection string, Cosmos DB key) so the backend container can access Azure services.

Note the `backendUrl` and `frontendUrl` from the outputs — these are your live URLs!

### 3.2 Update Frontend API Proxy

The frontend needs to know where the backend lives. Rebuild the frontend container with the backend URL baked in:

**Bash:**

```bash
# Use the SUFFIX saved from step 1.2
ACR_NAME=calmvaultacr${SUFFIX}
BACKEND_URL=<backendUrl from output>

az acr build \
  --registry $ACR_NAME \
  --image calmvault-frontend:latest \
  --file step-1/frontend/Dockerfile \
  --build-arg VITE_API_BASE_URL=$BACKEND_URL \
  .
```

**PowerShell:**

```powershell
# Use the $SUFFIX saved from step 1.2
$ACR_NAME = "calmvaultacr$SUFFIX"
$BACKEND_URL = "<backendUrl from output>"

az acr build `
  --registry $ACR_NAME `
  --image calmvault-frontend:latest `
  --file step-1/frontend/Dockerfile `
  --build-arg "VITE_API_BASE_URL=$BACKEND_URL" `
  .
```

### 3.3 Verify

**Bash:**

```bash
# Backend health check
curl <backendUrl>/api/health
# Expected: {"status":"ok"}
```

**PowerShell:**

```powershell
# Backend health check
Invoke-RestMethod "<backendUrl>/api/health"
# Expected: @{status=ok}
```

Open the frontend URL in your browser. Upload a file and confirm it round-trips through the backend to Blob Storage.

> **Tip:** The first request may take 10–20 seconds because Container Apps scales from zero. Subsequent requests will be fast.

Congratulations — CalmVault is now running in the cloud! 🚀

---

## What's Next

Future steps will cover:

- **Step 4** — Add CI/CD with GitHub Actions
- **Step 5** — Add monitoring and observability
