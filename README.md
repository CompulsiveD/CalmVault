# CalmVault

A minimal, private web app for everyday users to store and organize personal files and images — without the clutter of traditional cloud storage.

## Lab Structure

This repository is organized as a step-by-step lab:

| Folder | Contents |
| --- | --- |
| `step-1/` | Infrastructure + backend + frontend — deploy Azure resources and run locally |
| `step-2/` | Azure Container Registry + Dockerfiles — build backend & frontend images in the cloud (no local Docker) |
| `step-3/` | Azure Container Apps — deploy both containers with auto-scaling and managed secrets |

See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for the full walkthrough.

## Architecture

- **Frontend:** Vue 3 + TypeScript (Vite)
- **Backend:** Node.js + Express + TypeScript
- **File Storage:** Azure Blob Storage
- **Metadata DB:** Azure Cosmos DB (serverless)

## Quick Start

```bash
# Deploy infrastructure
az deployment sub create --location centralus --template-file step-1/infrastructure/main.bicep

# Backend
cd step-1/backend && cp .env.example .env  # fill in credentials
npm install && npm run dev

# Frontend (new terminal)
cd step-1/frontend
npm install && npm run dev
```

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
