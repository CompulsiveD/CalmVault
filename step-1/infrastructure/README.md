# CalmVault Infrastructure

Bicep templates to deploy CalmVault's Azure resources.

## Resources Deployed

- **Resource Group**: `rg-calmvault-<suffix>`
- **Storage Account**: `calmvault<suffix>` (Standard LRS, blob container `calmvault-files`)
- **Cosmos DB**: `calmvault-cosmos-<suffix>` (Serverless, database `calmvault`, container `files`)

## Deploy

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

The deployment outputs a `suffix` value (4-character hash). Save it — all resource names use this suffix and it's required for subsequent steps.

To specify a custom suffix or region:

**Bash:**

```bash
az deployment sub create \
  --location westus2 \
  --template-file step-1/infrastructure/main.bicep \
  --parameters location=westus2 suffix=ab12
```

**PowerShell:**

```powershell
az deployment sub create `
  --location westus2 `
  --template-file step-1/infrastructure/main.bicep `
  --parameters location=westus2 suffix=ab12
```

## After Deployment

Save the deployment outputs (see `DEPLOYMENT_GUIDE.md` step 1.2). Then retrieve secrets and populate `step-1/backend/.env`:

```
AZURE_STORAGE_CONNECTION_STRING=<from az storage account show-connection-string>
COSMOS_ENDPOINT=<cosmosEndpoint output>
COSMOS_KEY=<from az cosmosdb keys list>
```

To get the storage connection string:

**Bash:**

```bash
az storage account show-connection-string \
  --name $STORAGE_ACCOUNT \
  --resource-group rg-calmvault-${SUFFIX} \
  --query connectionString -o tsv
```

**PowerShell:**

```powershell
az storage account show-connection-string `
  --name $STORAGE_ACCOUNT `
  --resource-group "rg-calmvault-$SUFFIX" `
  --query connectionString -o tsv
```

To get the Cosmos DB key:

**Bash:**

```bash
az cosmosdb keys list \
  --name calmvault-cosmos-${SUFFIX} \
  --resource-group rg-calmvault-${SUFFIX} \
  --query primaryMasterKey -o tsv
```

**PowerShell:**

```powershell
az cosmosdb keys list `
  --name "calmvault-cosmos-$SUFFIX" `
  --resource-group "rg-calmvault-$SUFFIX" `
  --query primaryMasterKey -o tsv
```
