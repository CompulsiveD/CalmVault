---
layout: default
title: "Activity 6 — Cleanup"
nav_order: 7
---

# Activity 6 — Cleanup

When you're finished with the lab, delete all Azure resources to avoid ongoing charges.

> ⚠️ **This is irreversible.** All uploaded files, database records, container images, and telemetry data will be permanently deleted. Download anything you want to keep before proceeding.

## 6.1 Delete the Resource Group

This single command removes every Azure resource created across Activities 1–5:

**Bash:**

```bash
az group delete --name rg-calmvault-$SUFFIX --yes --no-wait
```

**PowerShell:**

```powershell
az group delete --name "rg-calmvault-$SUFFIX" --yes --no-wait
```

> **What just happened?** The `--no-wait` flag returns immediately while Azure deletes resources in the background. Full deletion typically takes 2–5 minutes.

## 6.2 Purge Soft-Deleted Azure OpenAI (Optional)

If you completed Activity 5, the Azure OpenAI account enters a 48-hour soft-delete period after resource group deletion. Purge it immediately if you plan to re-run the lab or need to free up quota:

**Bash:**

```bash
az cognitiveservices account purge \
  --name calmvault-openai-$SUFFIX \
  --resource-group rg-calmvault-$SUFFIX \
  --location centralus
```

**PowerShell:**

```powershell
az cognitiveservices account purge `
  --name "calmvault-openai-$SUFFIX" `
  --resource-group "rg-calmvault-$SUFFIX" `
  --location centralus
```

> **Tip:** If you get an error that the resource group doesn't exist (because it was already deleted), that's expected. The purge command uses the original resource group name as a reference but doesn't require it to still exist.

## 6.3 Verify Cleanup

After a few minutes, confirm the resource group is gone:

**Bash:**

```bash
az group show --name rg-calmvault-$SUFFIX 2>&1 || echo "Resource group deleted successfully"
```

**PowerShell:**

```powershell
az group show --name "rg-calmvault-$SUFFIX" 2>&1; if ($LASTEXITCODE -ne 0) { Write-Output "Resource group deleted successfully" }
```

---

## Congratulations! 🎉

You've completed the CalmVault deployment lab. Here's what you built and learned:

| Activity | What you did | Skills practiced |
| --- | --- | --- |
| 1 | Deployed Azure infrastructure and ran the app locally | Bicep, Azure Storage, Cosmos DB |
| 2 | Built container images in the cloud | Docker, Azure Container Registry |
| 3 | Deployed to Azure Container Apps | Managed containers, auto-scaling, secrets |
| 4 | Added monitoring and observability | Diagnostic settings, Log Analytics, Application Insights |
| 5 | Added AI auto-tagging (optional) | Azure OpenAI, Event Grid, Container App Jobs |
| 6 | Cleaned up all resources | Resource lifecycle management |
