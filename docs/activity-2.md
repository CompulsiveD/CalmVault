---
layout: default
title: "Activity 2 — Build Container Images with ACR"
nav_order: 3
---

# Activity 2 — Build Container Images with ACR

Now that the app works locally, let's package it into **containers** — portable, self-contained units that can run anywhere. We'll use **Azure Container Registry (ACR)** to build the containers in the cloud, so you don't need Docker installed on your machine.

## What you'll create

| Resource | Purpose |
| --- | --- |
| **Azure Container Registry** | A private registry (like a warehouse) that stores your container images |

## What's a container?

Think of a container as a zip file that includes your app code plus everything it needs to run (Node.js, dependencies, config). Unlike running locally with `npm run dev`, a container works the same way in any environment.

## 2.1 Deploy Infrastructure (with ACR)

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

## 2.2 Build the Container Images Remotely

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

## 2.3 Verify

Confirm both images were created:

**Bash / PowerShell:**

```bash
az acr repository list --name $ACR_NAME --output table
# Expected: calmvault-backend, calmvault-frontend

az acr repository show-tags --name $ACR_NAME --repository calmvault-backend --output table
# Expected: latest
```

---

👉 **Next:** [Activity 3 — Deploy to Azure Container Apps]({% link activity-3.md %})
