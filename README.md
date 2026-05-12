# CalmVault

A minimal, private web app for everyday users to store and organize personal files and images — without the clutter of traditional cloud storage.

## Architecture

- **Frontend:** Vue 3 + TypeScript (Vite)
- **Backend:** Node.js + Express + TypeScript
- **File Storage:** Azure Blob Storage
- **Metadata DB:** Azure Cosmos DB

## Getting Started

### Prerequisites

- Node.js 20+
- Azure subscription (for Blob Storage and Cosmos DB)

### Backend

```bash
cd backend
cp .env.example .env   # Fill in your Azure credentials
npm install
npm run dev
```

### Frontend

```bash
cd frontend
npm install
npm run dev
```

The frontend runs at `http://localhost:5173` and proxies API calls to `http://localhost:3001`.

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
