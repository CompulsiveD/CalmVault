---
layout: default
title: "Activity 1 — Deploy Infrastructure & Run Locally"
nav_order: 2
---

# Activity 1 — Deploy Infrastructure & Run Locally

In this activity, you'll create cloud resources in Azure (a storage account for files and a database for metadata), then run the application on your local machine connected to those cloud resources.

## What you'll create

| Resource | Purpose |
| --- | --- |
| **Azure Blob Storage** | Stores the actual uploaded files (images, documents, etc.) |
| **Azure Cosmos DB** | Stores metadata about each file (name, tags, upload date) |

## 1.1 Deploy Azure Resources

This command tells Azure to create all the resources defined in our Bicep template. [Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview) is Azure's infrastructure-as-code language — think of it as a blueprint for cloud resources.

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

> **Tip:** This may take 2–5 minutes. You'll see a JSON output when it completes. If you get an error about the location, make sure you typed `centralus` (no space).

## 1.2 Save Deployment Outputs

The deployment created resources with auto-generated names. Let's save those names — you'll need them for configuration and all subsequent activities.

**Bash:**

```bash
SUFFIX=$(az deployment sub show --name main --query properties.outputs.suffix.value -o tsv)
COSMOS_ENDPOINT=$(az deployment sub show --name main --query properties.outputs.cosmosEndpoint.value -o tsv)
STORAGE_ACCOUNT=$(az deployment sub show --name main --query properties.outputs.storageAccountName.value -o tsv)

echo "SUFFIX:          $SUFFIX"
echo "COSMOS_ENDPOINT: $COSMOS_ENDPOINT"
echo "STORAGE_ACCOUNT: $STORAGE_ACCOUNT"
```

**PowerShell:**

```powershell
$SUFFIX = az deployment sub show --name main --query properties.outputs.suffix.value -o tsv
$COSMOS_ENDPOINT = az deployment sub show --name main --query properties.outputs.cosmosEndpoint.value -o tsv
$STORAGE_ACCOUNT = az deployment sub show --name main --query properties.outputs.storageAccountName.value -o tsv

Write-Output "SUFFIX:          $SUFFIX"
Write-Output "COSMOS_ENDPOINT: $COSMOS_ENDPOINT"
Write-Output "STORAGE_ACCOUNT: $STORAGE_ACCOUNT"
```

> **Tip:** Write down the `SUFFIX` value (e.g., `a1b2`). It's a 4-character code unique to your subscription and used in all resource names throughout this lab. If you close your terminal, you can always re-run these commands to get the values again.

## 1.3 Retrieve Secrets & Generate .env File

Some sensitive values (connection strings, keys) are intentionally excluded from Bicep outputs for security. The commands below retrieve those secrets and print the complete `.env` file content — ready to copy and paste.

**Bash:**

```bash
# Retrieve secrets using variables from Activity 1.2
STORAGE_CONN=$(az storage account show-connection-string \
  --name $STORAGE_ACCOUNT \
  --resource-group rg-calmvault-${SUFFIX} \
  --query connectionString -o tsv)

COSMOS_KEY=$(az cosmosdb keys list \
  --name calmvault-cosmos-${SUFFIX} \
  --resource-group rg-calmvault-${SUFFIX} \
  --query primaryMasterKey -o tsv)

# Print the complete .env file — copy everything between the lines
echo "──────────── .env content (copy below) ────────────"
echo "PORT=3001"
echo "AZURE_STORAGE_CONNECTION_STRING=$STORAGE_CONN"
echo "AZURE_STORAGE_CONTAINER_NAME=calmvault-files"
echo "COSMOS_ENDPOINT=$COSMOS_ENDPOINT"
echo "COSMOS_KEY=$COSMOS_KEY"
echo "COSMOS_DATABASE_NAME=calmvault"
echo "──────────── end of .env content ────────────"
```

**PowerShell:**

```powershell
# Retrieve secrets using variables from Activity 1.2
$STORAGE_CONN = az storage account show-connection-string `
  --name $STORAGE_ACCOUNT `
  --resource-group "rg-calmvault-$SUFFIX" `
  --query connectionString -o tsv

$COSMOS_KEY = az cosmosdb keys list `
  --name "calmvault-cosmos-$SUFFIX" `
  --resource-group "rg-calmvault-$SUFFIX" `
  --query primaryMasterKey -o tsv

# Print the complete .env file — copy everything between the lines
Write-Output @"
──────────── .env content (copy below) ────────────
PORT=3001
AZURE_STORAGE_CONNECTION_STRING=$STORAGE_CONN
AZURE_STORAGE_CONTAINER_NAME=calmvault-files
COSMOS_ENDPOINT=$COSMOS_ENDPOINT
COSMOS_KEY=$COSMOS_KEY
COSMOS_DATABASE_NAME=calmvault
──────────── end of .env content ────────────
"@
```

> **What just happened?** You retrieved the storage connection string (like a URL + password for the storage account) and the Cosmos DB primary key (the database password). These are printed as a ready-to-use `.env` file.

## 1.4 Configure the Backend

Create the `.env` file and paste the output from Activity 1.3:

**Bash:**

```bash
cd activity-1/backend
cp .env.example .env
```

**PowerShell:**

```powershell
Set-Location activity-1/backend
Copy-Item .env.example .env
```

Open `activity-1/backend/.env` in your editor and replace its contents with the output you copied from Activity 1.3 (everything between the `────────` lines).

> **Tip:** The `.env` file is git-ignored so your secrets won't accidentally get committed to source control.

## 1.5 Start the Backend

**Bash / PowerShell:**

```bash
cd activity-1/backend
npm install
npm run dev
```

`npm install` downloads all the dependencies. `npm run dev` starts the server with auto-reload (it will restart automatically when you edit code).

Verify it's running:

**Bash:**

```bash
curl http://localhost:3001/api/health
# Expected: {"status":"ok"}
```

**PowerShell:**

```powershell
Invoke-RestMethod http://localhost:3001/api/health
# Expected: @{status=ok}
```

> **Tip:** If you get "connection refused", make sure the backend started without errors. Check the terminal where you ran `npm run dev` for error messages — usually a missing `.env` value.

## 1.6 Start the Frontend

In a **new terminal window** (keep the backend running):

**Bash / PowerShell:**

```bash
cd activity-1/frontend
npm install
npm run dev
```

Open [http://localhost:5173](http://localhost:5173) in your browser. You should see the CalmVault interface with a drag & drop upload zone.

> **Tip:** The frontend talks to the backend at `http://localhost:3001`. Both must be running simultaneously.

## 1.7 Verify End-to-End

1. Drag a file onto the upload zone (or click to browse)
2. Add a tag (e.g., "test") and upload
3. Confirm the file appears in the gallery
4. Click the file to preview it
5. Delete the file and confirm it's removed

If everything works, congratulations! Your app is running locally and storing files in Azure. 🎉

---

👉 **Next:** [Activity 2 — Build Container Images with ACR]({% link activity-2.md %})
