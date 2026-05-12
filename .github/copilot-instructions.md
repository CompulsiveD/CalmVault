# CalmVault — Copilot Instructions

## Architecture

CalmVault is a monorepo with two independent apps:

- **`backend/`** — Express + TypeScript REST API (Node.js). Handles file uploads, metadata CRUD, and proxies Azure services. Runs on port 3001.
- **`frontend/`** — Vue 3 + TypeScript SPA (Vite). Communicates with the backend via `fetch` calls in `src/services/api.ts`. Runs on port 5173.

Files are stored in **Azure Blob Storage**. Metadata and tags are stored in **Azure Cosmos DB**. There is no authentication (MVP).

### Data flow

1. User uploads a file → frontend sends `multipart/form-data` to `POST /api/files`
2. Backend receives the file via `multer` (memory storage), uploads the buffer to Azure Blob Storage, then writes metadata to Cosmos DB
3. Tags are stored as a `string[]` on the Cosmos DB document — no separate tags collection
4. File downloads are proxied through the backend (`GET /api/files/:id/download`), not served directly from Blob Storage

### Key types

The `FileMetadata` interface is the central data model, defined in both:
- `backend/src/models/file.ts`
- `frontend/src/types/file.ts`

These must stay in sync manually. If you add a field to one, add it to the other.

## Build & Run Commands

### Backend (`cd backend`)

| Command            | Description                        |
| ------------------ | ---------------------------------- |
| `npm run dev`      | Start with hot reload (`tsx watch`)|
| `npm run build`    | Compile TypeScript to `dist/`      |
| `npm run start`    | Run compiled output                |
| `npm run typecheck`| Type-check without emitting        |

### Frontend (`cd frontend`)

| Command            | Description                        |
| ------------------ | ---------------------------------- |
| `npm run dev`      | Start Vite dev server              |
| `npm run build`    | Type-check + production build      |
| `npm run preview`  | Preview production build           |

### Environment

Backend requires a `.env` file (copy from `.env.example`) with Azure Blob Storage and Cosmos DB credentials.

Frontend uses `VITE_API_BASE_URL` (defaults to `http://localhost:3001`).

## Conventions

### Backend patterns

- **Service layer separation**: Route handlers in `src/routes/` call service functions in `src/services/`. Routes handle HTTP concerns (status codes, request parsing); services handle business logic and Azure SDK calls.
- **Azure SDK initialization**: `initCosmos()` and `initBlobStorage()` are called once at startup in `src/index.ts`. Service modules export getter functions (e.g., `getFilesContainer()`) that throw if called before init.
- **Express route handlers** return `Promise<void>` and set response status explicitly. Do not return response objects.
- **Error handling**: Each route wraps its body in try/catch and returns a JSON error with appropriate status code.
- **Blob naming**: Uploaded files are stored with a UUID + original extension as the blob name (not the original filename) to avoid collisions.

### Frontend patterns

- **API client**: All backend calls go through `src/services/api.ts`. Do not use `fetch` directly in components.
- **Type sharing**: `src/types/file.ts` mirrors the backend's `FileMetadata` interface.

### Design philosophy

- Minimal, calm, iCloud-inspired UI — lots of whitespace, soft colors
- Tag-based organization only (no folder hierarchy)
- Upload limit: 50 MB per file (enforced by multer in `src/middleware/upload.ts`)
