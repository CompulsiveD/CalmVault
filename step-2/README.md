# Step 2 — Azure Container Registry & Cloud Build

This step adds an Azure Container Registry (ACR) and builds two container images using `az acr build` — no local Docker installation required.

## Key Concepts

| Term | What it means |
| --- | --- |
| **Container image** | A packaged version of your app plus everything it needs to run (like a portable zip file) |
| **Azure Container Registry (ACR)** | A private storage service for container images (like a private Docker Hub) |
| **`az acr build`** | A command that builds container images in the cloud — your code gets uploaded to Azure and built there |
| **Dockerfile** | A recipe that tells the build system how to package your app into a container |

## What's New

- **Bicep**: ACR resource added to `infrastructure/resources.bicep`
- **Dockerfile.backend**: Compiles TypeScript and runs the Express API
- **Dockerfile.frontend**: Builds the Vite app and serves via nginx
- **nginx.conf**: Serves the SPA with API proxy pass-through
- **Build**: Uses `az acr build` to build remotely on Azure

## Deploy

### 2.1 Deploy Infrastructure (includes ACR)

From the repository root:

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

> **Tip:** This deploys all Step 1 resources plus the new Container Registry. Existing resources won't be recreated — Bicep is smart enough to skip unchanged resources.

### 2.2 Build the Container Images

No Docker required — `az acr build` sends the source to ACR and builds in the cloud. Use the `SUFFIX` saved from Step 1.2:

**Bash:**

```bash
# Use the SUFFIX saved from step 1
ACR_NAME=calmvaultacr${SUFFIX}

# Build backend image (takes ~1-2 minutes)
az acr build \
  --registry $ACR_NAME \
  --image calmvault-backend:latest \
  --file step-2/Dockerfile.backend \
  .

# Build frontend image (takes ~1-3 minutes)
az acr build \
  --registry $ACR_NAME \
  --image calmvault-frontend:latest \
  --file step-2/Dockerfile.frontend \
  .
```

**PowerShell:**

```powershell
# Use the $SUFFIX saved from step 1
$ACR_NAME = "calmvaultacr$SUFFIX"

# Build backend image (takes ~1-2 minutes)
az acr build `
  --registry $ACR_NAME `
  --image calmvault-backend:latest `
  --file step-2/Dockerfile.backend `
  .

# Build frontend image (takes ~1-3 minutes)
az acr build `
  --registry $ACR_NAME `
  --image calmvault-frontend:latest `
  --file step-2/Dockerfile.frontend `
  .
```

> **Note:** The build context is the repository root (`.`) because the Dockerfiles reference `step-1/` paths. Make sure you run these commands from the root of the repo, not from inside the `step-2/` folder.

### 2.3 Verify the Images

Confirm both images were created successfully:

**Bash / PowerShell:**

```bash
az acr repository list --name $ACR_NAME --output table
# Expected output:
# Result
# -------------------
# calmvault-backend
# calmvault-frontend

az acr repository show-tags --name $ACR_NAME --repository calmvault-backend --output table
# Expected output:
# Result
# --------
# latest
```

## Container Details

| Image | Base | Exposes | Purpose |
| --- | --- | --- | --- |
| `calmvault-backend` | `node:20-alpine` | 3001 | Express API server |
| `calmvault-frontend` | `nginx:alpine` | 80 | Static SPA + API reverse proxy |
