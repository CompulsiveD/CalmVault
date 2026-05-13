# Step 3 — Deploy to Azure Container Apps

This step deploys the backend and frontend containers from ACR to Azure Container Apps.

## What's New

- **Bicep**: Log Analytics workspace, Container Apps Environment, and two Container Apps (backend + frontend)
- **Backend container** receives Azure connection secrets via Container Apps secrets/env vars
- **Frontend container** serves the SPA via nginx on port 80
- Both apps scale from 0 to 3 replicas based on HTTP traffic

## Deploy

### 3.1 Deploy Infrastructure (includes Container Apps)

From the repository root:

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

> **Prerequisite:** Container images must already exist in ACR (see Step 2). If you haven't built them yet, run Step 2 first.

Note the `backendUrl` and `frontendUrl` from the outputs.

### 3.2 Update Frontend API URL

The frontend nginx container proxies `/api/` requests to `localhost:3001` by default. In Container Apps, the backend runs at a separate FQDN. You have two options:

**Option A** — Rebuild the frontend image with the backend URL baked in:

**Bash:**

```bash
# Use the SUFFIX saved from step 1
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
# Use the $SUFFIX saved from step 1
$ACR_NAME = "calmvaultacr$SUFFIX"
$BACKEND_URL = "<backendUrl from output>"

az acr build `
  --registry $ACR_NAME `
  --image calmvault-frontend:latest `
  --file step-2/Dockerfile.frontend `
  --build-arg "VITE_API_BASE_URL=$BACKEND_URL" `
  .
```

**Option B** — Update the nginx config to reverse-proxy to the backend FQDN (recommended for this lab):

Replace the `proxy_pass` line in `step-2/nginx.conf` with the backend Container App URL, rebuild, and redeploy.

### 3.3 Verify

**Bash:**

```bash
# Check backend health
curl https://<backend-fqdn>/api/health
# Expected: {"status":"ok"}

# Open frontend in browser
echo https://<frontend-fqdn>
```

**PowerShell:**

```powershell
# Check backend health
Invoke-RestMethod https://<backend-fqdn>/api/health
# Expected: {"status":"ok"}

# Open frontend in browser
Write-Output https://<frontend-fqdn>
```

## Architecture

```
┌─────────────────────────────────────────────────────┐
│           Container Apps Environment                 │
│                                                     │
│  ┌─────────────────┐     ┌──────────────────────┐  │
│  │  calmvault-     │     │  calmvault-          │  │
│  │  frontend       │────▶│  backend             │  │
│  │  (nginx :80)    │     │  (express :3001)     │  │
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
| `calmvault-frontend-<suffix>` | `calmvault-frontend:latest` | 80 | Yes | 0–3 | ACR password |
