# CalmVault Infrastructure

Bicep templates to deploy CalmVault's Azure resources.

## What is Bicep?

[Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview) is Azure's infrastructure-as-code language. Instead of manually clicking through the Azure portal to create resources, you define them in a `.bicep` file and deploy with a single command. This makes deployments repeatable and version-controlled.

## Resources Deployed

| Resource | Name Pattern | What it does |
| --- | --- | --- |
| **Resource Group** | `rg-calmvault-<suffix>` | A logical container that holds all your Azure resources together |
| **Storage Account** | `calmvault<suffix>` | Stores your uploaded files as blobs (binary large objects) |
| **Cosmos DB** | `calmvault-cosmos-<suffix>` | A NoSQL database that stores file metadata (name, tags, upload date) |

> **What's a suffix?** It's a 4-character code (e.g., `a1b2`) automatically generated from your subscription ID. This ensures resource names are globally unique without you having to think of names.

## Deploy

From the repository root:

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

> **Tip:** This takes 2–5 minutes. When it finishes, you'll see a JSON output with the deployment results.

The deployment outputs a `suffix` value. Save it — all resource names use this suffix and it's required for subsequent activities.

To specify a custom suffix or region (optional — most people should skip this):

**Bash:**

```bash
az deployment sub create \
  --location westus2 \
  --template-file activity-1/infrastructure/main.bicep \
  --parameters location=westus2 suffix=ab12
```

**PowerShell:**

```powershell
az deployment sub create `
  --location westus2 `
  --template-file activity-1/infrastructure/main.bicep `
  --parameters location=westus2 suffix=ab12
```

## After Deployment

Save the deployment outputs (see `DEPLOYMENT_GUIDE.md` Activity 1.2), then run Activity 1.3 which retrieves secrets and prints a complete `.env` file ready to copy into `activity-1/backend/.env`.
