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

Copy the output values into `step-1/backend/.env`:

```
AZURE_STORAGE_CONNECTION_STRING=<retrieve via Azure CLI>
COSMOS_ENDPOINT=<cosmosEndpoint output>
COSMOS_KEY=<retrieve from Azure Portal or CLI>
```

To get the storage connection string:

**Bash:**

```bash
az storage account show-connection-string --name calmvault<suffix> --resource-group rg-calmvault-<suffix> --query connectionString -o tsv
```

**PowerShell:**

```powershell
az storage account show-connection-string --name "calmvault<suffix>" --resource-group "rg-calmvault-<suffix>" --query connectionString -o tsv
```

To get the Cosmos DB key:

**Bash:**

```bash
az cosmosdb keys list --name calmvault-cosmos-<suffix> --resource-group rg-calmvault-<suffix> --query primaryMasterKey -o tsv
```

**PowerShell:**

```powershell
az cosmosdb keys list --name "calmvault-cosmos-<suffix>" --resource-group "rg-calmvault-<suffix>" --query primaryMasterKey -o tsv
```
