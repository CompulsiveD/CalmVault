# CalmVault Infrastructure

Bicep templates to deploy CalmVault's Azure resources.

## What is Bicep?

[Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview) is Azure's infrastructure-as-code language. Instead of manually clicking through the Azure portal to create resources, you define them in a `.bicep` file and deploy with a single command. This makes deployments repeatable and version-controlled.

## Resources Deployed

| Resource | Name Pattern | What it does |
| --- | --- | --- |
| **Storage Account** | `calmvault<suffix>` | Stores your uploaded files as blobs (binary large objects) |
| **Cosmos DB** | `calmvault-cosmos-<suffix>` | A NoSQL database that stores file metadata (name, tags, upload date) |

> **What's a suffix?** It's your user identifier (e.g., `user1`) derived from your lab login. This ensures resource names are unique across lab participants. Your resource group (`rg-calmvault-<suffix>-usc`) is pre-created.

## Deploy

From the repository root (after setting up your environment variables — see `DEPLOYMENT_GUIDE.md` Prerequisites):

**Bash:**

```bash
az deployment group create \
  --resource-group $RG_NAME \
  --template-file activity-1/infrastructure/main.bicep \
  --name activity1-main
```

**PowerShell:**

```powershell
az deployment group create `
  --resource-group $RG_NAME `
  --template-file activity-1/infrastructure/main.bicep `
  --name activity1-main
```

> **Tip:** This takes 2–5 minutes. When it finishes, you'll see a JSON output with the deployment results.

## After Deployment

Save the deployment outputs (see `DEPLOYMENT_GUIDE.md` Activity 1.2), then run Activity 1.3 which retrieves secrets and prints a complete `.env` file ready to copy into `activity-1/backend/.env`.
