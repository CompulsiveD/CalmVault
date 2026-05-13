# CalmVault — Deployment Guide

A step-by-step guide to deploying CalmVault from scratch.

---

## Prerequisites

- [Node.js](https://nodejs.org/) 20+
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed and authenticated (`az login`)
- An active Azure subscription

---

## Step 1 — Deploy Infrastructure & Run Locally

This step provisions the Azure resources (Blob Storage + Cosmos DB) and gets the application running on your local machine.

### 1.1 Deploy Azure Resources

From the repository root:

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

### 1.2 Save Deployment Outputs

After the deployment completes, save the key outputs — you'll need them for configuration and all subsequent steps.

**Bash:**

```bash
# Save all outputs at once
SUFFIX=$(az deployment sub show --name main --query properties.outputs.suffix.value -o tsv)
COSMOS_ENDPOINT=$(az deployment sub show --name main --query properties.outputs.cosmosEndpoint.value -o tsv)
STORAGE_ACCOUNT=$(az deployment sub show --name main --query properties.outputs.storageAccountName.value -o tsv)

echo "SUFFIX:          $SUFFIX"
echo "COSMOS_ENDPOINT: $COSMOS_ENDPOINT"
echo "STORAGE_ACCOUNT: $STORAGE_ACCOUNT"
```

**PowerShell:**

```powershell
# Save all outputs at once
$SUFFIX = az deployment sub show --name main --query properties.outputs.suffix.value -o tsv
$COSMOS_ENDPOINT = az deployment sub show --name main --query properties.outputs.cosmosEndpoint.value -o tsv
$STORAGE_ACCOUNT = az deployment sub show --name main --query properties.outputs.storageAccountName.value -o tsv

Write-Output "SUFFIX:          $SUFFIX"
Write-Output "COSMOS_ENDPOINT: $COSMOS_ENDPOINT"
Write-Output "STORAGE_ACCOUNT: $STORAGE_ACCOUNT"
```

Keep these values handy — `SUFFIX` is used in every subsequent step, and the others are needed for backend configuration.

### 1.3 Retrieve Secrets

The Bicep outputs intentionally exclude secrets. Retrieve them using the variables saved in step 1.2:

**Bash:**

```bash
# Storage account connection string
STORAGE_CONN=$(az storage account show-connection-string \
  --name $STORAGE_ACCOUNT \
  --resource-group rg-calmvault-${SUFFIX} \
  --query connectionString -o tsv)

# Cosmos DB primary key
COSMOS_KEY=$(az cosmosdb keys list \
  --name calmvault-cosmos-${SUFFIX} \
  --resource-group rg-calmvault-${SUFFIX} \
  --query primaryMasterKey -o tsv)
```

**PowerShell:**

```powershell
# Storage account connection string
$STORAGE_CONN = az storage account show-connection-string `
  --name $STORAGE_ACCOUNT `
  --resource-group "rg-calmvault-$SUFFIX" `
  --query connectionString -o tsv

# Cosmos DB primary key
$COSMOS_KEY = az cosmosdb keys list `
  --name "calmvault-cosmos-$SUFFIX" `
  --resource-group "rg-calmvault-$SUFFIX" `
  --query primaryMasterKey -o tsv
```

### 1.4 Configure the Backend

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

Edit `.env` with the values from steps 1.2 and 1.3:

```
PORT=3001
AZURE_STORAGE_CONNECTION_STRING=<STORAGE_CONN from 1.3>
AZURE_STORAGE_CONTAINER_NAME=calmvault-files
COSMOS_ENDPOINT=<COSMOS_ENDPOINT from 1.2>
COSMOS_KEY=<COSMOS_KEY from 1.3>
COSMOS_DATABASE_NAME=calmvault
```

### 1.5 Start the Backend

**Bash / PowerShell:**

```bash
cd step-1/backend
npm install
npm run dev
```

Verify it's running:

**Bash:**

```bash
curl http://localhost:3001/api/health
# Expected: {"status":"ok"}
```

**PowerShell:**

```powershell
Invoke-RestMethod http://localhost:3001/api/health
# Expected: {"status":"ok"}
```

### 1.6 Start the Frontend

In a new terminal:

**Bash / PowerShell:**

```bash
cd step-1/frontend
npm install
npm run dev
```

Open [http://localhost:5173](http://localhost:5173) in your browser. You should see the CalmVault interface with a drag & drop upload zone.

### 1.7 Verify End-to-End

1. Drag a file onto the upload zone
2. Add a tag (e.g., "test") and upload
3. Confirm the file appears in the gallery
4. Click the file to preview it
5. Delete the file and confirm it's removed

---

## Step 2 — Build Container Images with ACR

This step adds an Azure Container Registry and builds the app containers in the cloud — no local Docker required.

### 2.1 Deploy Infrastructure (with ACR)

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

Note the `acrName` and `acrLoginServer` from the outputs.

### 2.2 Build the Container Images Remotely

**Bash:**

```bash
# Use the SUFFIX saved from step 1.2
ACR_NAME=calmvaultacr${SUFFIX}

# Build backend
az acr build \
  --registry $ACR_NAME \
  --image calmvault-backend:latest \
  --file step-2/Dockerfile.backend \
  .

# Build frontend
az acr build \
  --registry $ACR_NAME \
  --image calmvault-frontend:latest \
  --file step-2/Dockerfile.frontend \
  .
```

**PowerShell:**

```powershell
# Use the $SUFFIX saved from step 1.2
$ACR_NAME = "calmvaultacr$SUFFIX"

# Build backend
az acr build `
  --registry $ACR_NAME `
  --image calmvault-backend:latest `
  --file step-2/Dockerfile.backend `
  .

# Build frontend
az acr build `
  --registry $ACR_NAME `
  --image calmvault-frontend:latest `
  --file step-2/Dockerfile.frontend `
  .
```

The build context is the repository root because the Dockerfiles reference `step-1/` source paths. ACR performs the build in the cloud.

### 2.3 Verify

**Bash / PowerShell:**

```bash
az acr repository list --name $ACR_NAME --output table
# Expected: calmvault-backend, calmvault-frontend

az acr repository show-tags --name $ACR_NAME --repository calmvault-backend --output table
# Expected: latest
```

---

## Step 3 — Deploy to Azure Container Apps

This step deploys both containers to Azure Container Apps with auto-scaling and managed secrets.

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

Note the `backendUrl` and `frontendUrl` from the outputs.

### 3.2 Update Frontend API Proxy

The frontend nginx proxies `/api/` to the backend. Rebuild with the actual backend URL:

**Bash:**

```bash
# Use the SUFFIX saved from step 1.2
ACR_NAME=calmvaultacr${SUFFIX}
BACKEND_URL=<backendUrl from output>

az acr build \
  --registry $ACR_NAME \
  --image calmvault-frontend:latest \
  --file step-2/Dockerfile.frontend \
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
  --file step-2/Dockerfile.frontend `
  --build-arg "VITE_API_BASE_URL=$BACKEND_URL" `
  .
```

### 3.3 Verify

**Bash:**

```bash
# Backend health check
curl <backendUrl>/api/health
# Expected: {"status":"ok"}

# Open frontend
echo <frontendUrl>
```

**PowerShell:**

```powershell
# Backend health check
Invoke-RestMethod <backendUrl>/api/health
# Expected: {"status":"ok"}

# Open frontend
Write-Output <frontendUrl>
```

Open the frontend URL in your browser. Upload a file and confirm it round-trips through the backend to Blob Storage.

---

## What's Next

Future steps will cover:

- **Step 4** — Add CI/CD with GitHub Actions
- **Step 5** — Add monitoring and observability
