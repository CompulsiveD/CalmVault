# Activity 5 — AI Auto-Tagging (Optional)

This optional activity adds an **AI-powered auto-tagging** service that automatically analyzes uploaded files and assigns descriptive tags using Azure OpenAI GPT-4o.

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌───────────────┐
│  Blob Storage   │────▶│  Event Grid      │────▶│ Storage Queue │
│  (file upload)  │     │  (BlobCreated)   │     │ (blob-events) │
└─────────────────┘     └──────────────────┘     └───────┬───────┘
                                                         │
                                                         ▼
┌─────────────────┐     ┌──────────────────┐     ┌───────────────┐
│   Cosmos DB     │◀────│  Tagger App      │◀────│ Container App │
│  (update tags)  │     │  (GPT-4o call)   │     │ (scale 0→3)  │
└─────────────────┘     └──────────────────┘     └───────────────┘
```

**Flow:**
1. A file is uploaded to the `calmvault-files` blob container
2. Event Grid detects the `BlobCreated` event and delivers it to a Storage Queue
3. The tagger Container App (scaled by KEDA based on queue length) picks up the message
4. For supported file types (images & text), it downloads the blob and sends it to GPT-4o
5. GPT-4o analyzes the content and returns descriptive tags
6. The tagger updates the Cosmos DB document with `ai:`-prefixed tags (e.g., `ai:landscape`, `ai:receipt`)

## Supported File Types

| Category | MIME Types |
| --- | --- |
| Images | `image/jpeg`, `image/png`, `image/gif`, `image/webp`, `image/bmp` |
| Text | `text/plain`, `text/csv`, `text/markdown`, `text/html`, `application/json` |

Unsupported file types are silently skipped.

## What Gets Deployed

| Resource | Type | Name Pattern |
| --- | --- | --- |
| Azure OpenAI | `Microsoft.CognitiveServices/accounts` | `calmvault-openai-<suffix>` |
| GPT-4o Deployment | `accounts/deployments` | `gpt-4o` (Standard, 10K TPM) |
| Storage Queue | `storageAccounts/queueServices/queues` | `blob-events` |
| Event Grid System Topic | `Microsoft.EventGrid/systemTopics` | `calmvault-storage-events-<suffix>` |
| Event Grid Subscription | `systemTopics/eventSubscriptions` | `blob-created-to-queue` |
| Tagger Container App | `Microsoft.App/containerApps` | `calmvault-tagger-<suffix>` |

## Tag Behavior

- AI-generated tags are always prefixed with `ai:` (e.g., `ai:nature`, `ai:invoice`, `ai:code`)
- User-assigned tags are never modified — AI tags are merged alongside them
- If the tagger is re-triggered, old `ai:` tags are replaced with fresh ones
- On processing failure, a single `ai:unprocessed` tag is added
- Tags are limited to 3–7 per file

## Prerequisites

- Activities 1–3 must be deployed (Storage, Cosmos DB, ACR, Container Apps Environment)
- Azure OpenAI access must be enabled on your subscription
- The `Microsoft.EventGrid` resource provider must be registered

## Key Files

| Path | Purpose |
| --- | --- |
| `activity-5/infrastructure/main.bicep` | Subscription-scope entry point |
| `activity-5/infrastructure/resources.bicep` | All activity-5 resources (OpenAI, Event Grid, Queue, Tagger App) |
| `activity-5/tagger/src/index.ts` | Queue polling loop, event processing, Cosmos updates |
| `activity-5/tagger/src/tagger.ts` | GPT-4o integration (vision for images, text analysis) |
| `activity-5/tagger/Dockerfile` | Multi-stage build for the tagger container |
