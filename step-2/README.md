# Step 2 — Azure Container Registry & Cloud Build

This step adds an Azure Container Registry (ACR) and builds two container images using `az acr build` — no local Docker installation required.

## What's New

- **Bicep**: ACR resource added to `infrastructure/resources.bicep`
- **Dockerfile.backend**: Compiles TypeScript and runs the Express API
- **Dockerfile.frontend**: Builds the Vite app and serves via nginx
- **nginx.conf**: Serves SPA with API proxy pass-through
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

Note the `acrName` and `acrLoginServer` outputs.

### 2.2 Build the Container Images

No Docker required — `az acr build` sends the source to ACR and builds in the cloud:

**Bash:**

```bash
SUFFIX=<suffix from output>
ACR_NAME=calmvaultacr${SUFFIX}

# Build backend image
az acr build \
  --registry $ACR_NAME \
  --image calmvault-backend:latest \
  --file step-2/Dockerfile.backend \
  .

# Build frontend image
az acr build \
  --registry $ACR_NAME \
  --image calmvault-frontend:latest \
  --file step-2/Dockerfile.frontend \
  .
```

**PowerShell:**

```powershell
$SUFFIX = "<suffix from output>"
$ACR_NAME = "calmvaultacr$SUFFIX"

# Build backend image
az acr build `
  --registry $ACR_NAME `
  --image calmvault-backend:latest `
  --file step-2/Dockerfile.backend `
  .

# Build frontend image
az acr build `
  --registry $ACR_NAME `
  --image calmvault-frontend:latest `
  --file step-2/Dockerfile.frontend `
  .
```

> **Note:** The build context is the repository root (`.`) because the Dockerfiles reference `step-1/` paths.

### 2.3 Verify the Images

**Bash / PowerShell:**

```bash
az acr repository list --name $ACR_NAME --output table
az acr repository show-tags --name $ACR_NAME --repository calmvault-backend --output table
az acr repository show-tags --name $ACR_NAME --repository calmvault-frontend --output table
```

## Container Details

| Image | Base | Exposes | Purpose |
| --- | --- | --- | --- |
| `calmvault-backend` | `node:20-alpine` | 3001 | Express API server |
| `calmvault-frontend` | `nginx:alpine` | 80 | Static SPA + API reverse proxy |
