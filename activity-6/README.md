# Activity 6 — Cleanup

This activity tears down all Azure resources created during the lab. Since everything lives in a single resource group, cleanup is a single command.

## Why Clean Up?

Even with serverless and consumption-based pricing, some resources incur costs while they exist:

- **Azure Cosmos DB** (serverless) — charges per RU consumed, but the account itself is free when idle
- **Azure Container Registry** (Basic) — ~$5/month while the registry exists
- **Azure OpenAI** (S0) — no idle cost, but reserved capacity counts against your subscription quota
- **Log Analytics** — charges for data ingestion and retention
- **Container Apps** — free at zero scale, but the environment has a small base cost

Deleting the resource group removes **all** of these in one operation.

## What Gets Deleted

All resources created across Activities 1–5:

| Activity | Resources |
| --- | --- |
| 1 | Resource Group, Storage Account, Cosmos DB |
| 2 | Container Registry |
| 3 | Log Analytics, Container Apps Environment, Backend + Frontend Container Apps |
| 4 | Diagnostic Settings, Dashboard, Application Insights |
| 5 | Azure OpenAI, Event Grid Topic, Storage Queue, Tagger Job |

## Important Notes

- **This is irreversible.** All uploaded files, database records, and container images will be permanently deleted.
- **Azure OpenAI soft-delete:** After deletion, the Azure OpenAI account enters a 48-hour soft-delete period. During this time, you cannot create a new resource with the same name. You can purge it immediately if needed (see steps below).
- **No backup is created.** If you want to keep any uploaded files, download them before running cleanup.
