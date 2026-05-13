# CalmVault Infrastructure

Bicep templates to deploy CalmVault's Azure resources.

## Resources Deployed

- **Resource Group**: `rg-calmvault-<suffix>`
- **Storage Account**: `calmvault<suffix>` (Standard LRS, blob container `calmvault-files`)
- **Cosmos DB**: `calmvault-cosmos-<suffix>` (Serverless, database `calmvault`, container `files`)

## Deploy

```bash
az deployment sub create \
  --location centralus \
  --template-file infrastructure/main.bicep
```

To specify a custom suffix or region:

```bash
az deployment sub create \
  --location westus2 \
  --template-file infrastructure/main.bicep \
  --parameters location=westus2 suffix=ab12
```

## After Deployment

Copy the output values into `backend/.env`:

```
AZURE_STORAGE_CONNECTION_STRING=<storageConnectionString output>
COSMOS_ENDPOINT=<cosmosEndpoint output>
COSMOS_KEY=<retrieve from Azure Portal or CLI>
```

To get the Cosmos DB key:

```bash
az cosmosdb keys list --name calmvault-cosmos-<suffix> --resource-group rg-calmvault-<suffix> --query primaryMasterKey -o tsv
```
