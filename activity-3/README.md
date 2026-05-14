# Activity 3 — Deploy to Azure Container Apps

This activity deploys the backend and frontend containers from ACR to Azure Container Apps — a managed service that runs your containers in the cloud with automatic scaling and a public URL.

## Key Concepts

| Term | What it means |
| --- | --- |
| **Azure Container Apps** | A service that runs your containers without you managing servers. It handles scaling, networking, and HTTPS automatically. |
| **Container Apps Environment** | A shared network boundary for your containers. Apps in the same environment can talk to each other privately. |
| **Log Analytics** | Azure's logging service — collects output from your containers so you can debug issues later. |
| **Scaling (0–3 replicas)** | Your app scales to zero when idle (no cost) and up to 3 instances when busy. |

## What's New

- **Bicep**: Log Analytics workspace, Container Apps Environment, and two Container Apps (backend + frontend)
- **Backend container** receives Azure connection secrets via Container Apps secrets/env vars
- **Frontend container** serves the SPA via nginx on port 8080
- Both apps scale from 0 to 3 replicas based on HTTP traffic

## Deploy

### 3.1 Deploy Backend Container App

> **Prerequisite:** Container images must already exist in ACR (see Activity 2). If you haven't built them yet, go back and complete Activity 2 first.

From the repository root:

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

> **Tip:** This creates the Log Analytics workspace, Container Apps Environment, and backend Container App. Takes 3–5 minutes.

Note the `backendUrl` from the outputs.

### 3.2 Rebuild Frontend with Backend URL

The frontend needs to know where the backend lives. Rebuild the frontend image with the backend URL baked in:

**Bash:**

```bash
# Use the SUFFIX saved from Activity 1
ACR_NAME=calmvaultacr${SUFFIX}
BACKEND_URL=$(az deployment sub show --name backend.main --query properties.outputs.backendUrl.value -o tsv)

az acr build \
  --registry $ACR_NAME \
  --image calmvault-frontend:latest \
  --file activity-1/frontend/Dockerfile \
  --build-arg VITE_API_BASE_URL=$BACKEND_URL \
  .
```

**PowerShell:**

```powershell
# Use the $SUFFIX saved from Activity 1
$ACR_NAME = "calmvaultacr$SUFFIX"
$BACKEND_URL = az deployment sub show --name backend.main --query properties.outputs.backendUrl.value -o tsv

az acr build `
  --registry $ACR_NAME `
  --image calmvault-frontend:latest `
  --file activity-1/frontend/Dockerfile `
  --build-arg "VITE_API_BASE_URL=$BACKEND_URL" `
  .
```

### 3.3 Deploy Frontend Container App

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

### 3.4 Verify

**Bash:**

```bash
FRONTEND_URL=$(az deployment sub show --name frontend.main --query properties.outputs.frontendUrl.value -o tsv)

curl $BACKEND_URL/api/health
# Expected: {"status":"ok"}

echo $FRONTEND_URL
```

**PowerShell:**

```powershell
$FRONTEND_URL = az deployment sub show --name frontend.main --query properties.outputs.frontendUrl.value -o tsv

Invoke-RestMethod "$BACKEND_URL/api/health"
# Expected: @{status=ok}

Write-Output $FRONTEND_URL
```

> **Tip:** The first request may take 10–20 seconds because Container Apps scales from zero (no instances running until the first request arrives). Subsequent requests will be fast.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│           Container Apps Environment                 │
│                                                     │
│  ┌─────────────────┐     ┌──────────────────────┐  │
│  │  calmvault-     │     │  calmvault-          │  │
│  │  frontend       │────▶│  backend             │  │
│  │  (nginx :8080)  │     │  (express :3001)     │  │
│  └─────────────────┘     └──────────────────────┘  │
│                                  │                  │
└──────────────────────────────────│──────────────────┘
                                   │
                    ┌──────────────┼──────────────┐
                    │              │              │
              ┌─────▼─────┐ ┌─────▼─────┐ ┌─────▼─────┐
              │ Blob      │ │ Cosmos DB │ │ ACR       │
              │ Storage   │ │           │ │           │
              └───────────┘ └───────────┘ └───────────┘
```

## Container App Configuration

| App | Image | Port | External | Scale | Secrets |
| --- | --- | --- | --- | --- | --- |
| `calmvault-backend-<suffix>` | `calmvault-backend:latest` | 3001 | Yes | 0–3 | Storage connection string, Cosmos key, ACR password |
| `calmvault-frontend-<suffix>` | `calmvault-frontend:latest` | 8080 | Yes | 0–3 | ACR password |
