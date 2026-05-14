# CalmVault

A minimal, private web app for everyday users to store and organize personal files and images — without the clutter of traditional cloud storage.

## About This Lab

This repository is a **hands-on deployment lab** designed for developers at the **100–200 level**. You should be comfortable with basic command-line usage and web development concepts, but no prior Azure or cloud experience is required.

By the end of this lab, you'll have deployed a full-stack web application to the cloud using Azure's managed services.

## Lab Structure

Each activity builds incrementally on the previous one:

| Activity | What you'll do | What you'll learn |
| --- | --- | --- |
| `activity-1/` | Deploy Azure resources and run the app locally | Bicep (infrastructure-as-code), Azure Storage, Cosmos DB |
| `activity-2/` | Build container images in the cloud | Docker concepts, Azure Container Registry, `az acr build` |
| `activity-3/` | Deploy containers to Azure Container Apps | Managed container hosting, auto-scaling, secrets management |
| `activity-4/` | Add monitoring and observability | Diagnostic settings, Log Analytics, KQL queries |
| `activity-5/` | AI auto-tagging with GPT-4o (optional) | Azure OpenAI, Event Grid, event-driven Container Apps |

👉 **Start here:** [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) — the full guided walkthrough.

## Architecture

- **Frontend:** Vue 3 + TypeScript (Vite) — a single-page app for uploading and browsing files
- **Backend:** Node.js + Express + TypeScript — REST API that handles uploads and talks to Azure
- **File Storage:** Azure Blob Storage — stores the actual uploaded files
- **Metadata DB:** Azure Cosmos DB (serverless) — stores file metadata (name, tags, dates)

## Quick Start

```bash
# Deploy infrastructure (creates Azure resources)
az deployment sub create --location centralus --template-file activity-1/infrastructure/main.bicep

# Backend (in one terminal)
cd activity-1/backend && cp .env.example .env  # fill in credentials from Azure
npm install && npm run dev

# Frontend (in another terminal)
cd activity-1/frontend
npm install && npm run dev
```

> **Note:** The Quick Start skips explanations. For the full guided experience, use [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md).

## API Endpoints

| Method   | Path                      | Description            |
| -------- | ------------------------- | ---------------------- |
| `POST`   | `/api/files`              | Upload files           |
| `GET`    | `/api/files`              | List files (tag filter)|
| `GET`    | `/api/files/tags`         | List all unique tags   |
| `GET`    | `/api/files/:id`          | Get file metadata      |
| `GET`    | `/api/files/:id/download` | Download file          |
| `PATCH`  | `/api/files/:id/tags`     | Update file tags       |
| `DELETE` | `/api/files/:id`          | Delete a file          |
| `GET`    | `/api/health`             | Health check           |
