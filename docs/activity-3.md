---
layout: default
title: "Activity 3 — Deploy to Azure Container Apps"
nav_order: 4
---

# Activity 3 — Deploy to Azure Container Apps

Now let's run those containers in the cloud! **Azure Container Apps** is a managed service that runs your containers, handles scaling (more traffic = more instances), and gives you a public URL — without managing servers.

## What you'll create

| Resource | Purpose |
| --- | --- |
| **Log Analytics Workspace** | Collects logs from your containers (for debugging) |
| **Container Apps Environment** | A shared network for your containers to communicate |
| **Backend Container App** | Runs the Express API (auto-scales 0–3 instances) |
| **Frontend Container App** | Runs the nginx SPA server (auto-scales 0–3 instances) |

## 3.1 Deploy Backend Container App

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

## 3.2 Save Backend Deployment Outputs

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

## 3.3 Update Frontend API Proxy

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

## 3.4 Deploy Frontend Container App

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

## 3.5 Verify

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

👉 **Next:** [Activity 4 — Monitoring & Observability]({% link activity-4.md %})
