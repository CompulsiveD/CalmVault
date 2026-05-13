# CalmVault — Copilot Instructions

## Repository Structure

CalmVault is organized as a **step-by-step deployment lab**. Each `step-N/` folder is an incremental addition containing only new or modified files for that stage.

```
step-1/          ← Deploy infrastructure + run locally
  backend/       ← Express + TypeScript REST API
  frontend/      ← Vue 3 + TypeScript SPA (Vite)
  infrastructure/← Bicep templates for Azure
step-2/          ← Add ACR + build container images (no local Docker)
  infrastructure/← Bicep with ACR added
  Dockerfile.backend  ← Backend API container (node:20-alpine)
  Dockerfile.frontend ← Frontend SPA container (nginx:alpine)
  nginx.conf     ← nginx config for SPA routing + API proxy
step-3/          ← Deploy to Azure Container Apps
  infrastructure/← Bicep with Container Apps Environment + apps
```

The root `DEPLOYMENT_GUIDE.md` is the primary walkthrough for the lab.

## Architecture

- **`step-1/backend/`** — Express + TypeScript REST API (Node.js). Handles file uploads, metadata CRUD, and proxies Azure services. Runs on port 3001.
- **`step-1/frontend/`** — Vue 3 + TypeScript SPA (Vite). Communicates with the backend via `fetch` calls in `src/services/api.ts`. Runs on port 5173.
- **`step-1/infrastructure/`** — Bicep templates for Azure deployment. `main.bicep` is the subscription-level entry point; `resources.bicep` is a module scoped to the resource group.

Files are stored in **Azure Blob Storage**. Metadata and tags are stored in **Azure Cosmos DB** (serverless). There is no authentication (MVP).

### Data flow

1. User uploads a file → frontend sends `multipart/form-data` to `POST /api/files`
2. Backend receives the file via `multer` (memory storage), uploads the buffer to Azure Blob Storage, then writes metadata to Cosmos DB
3. Tags are stored as a `string[]` on the Cosmos DB document — no separate tags collection
4. File downloads are proxied through the backend (`GET /api/files/:id/download`), not served directly from Blob Storage

### Key types

The `FileMetadata` interface is the central data model, defined in both:
- `step-1/backend/src/models/file.ts`
- `step-1/frontend/src/types/file.ts`

These must stay in sync manually. If you add a field to one, add it to the other.

## Build & Run Commands

### Backend (`cd step-1/backend`)

| Command            | Description                        |
| ------------------ | ---------------------------------- |
| `npm run dev`      | Start with hot reload (`tsx watch`)|
| `npm run build`    | Compile TypeScript to `dist/`      |
| `npm run start`    | Run compiled output                |
| `npm run typecheck`| Type-check without emitting        |

### Frontend (`cd step-1/frontend`)

| Command            | Description                        |
| ------------------ | ---------------------------------- |
| `npm run dev`      | Start Vite dev server              |
| `npm run build`    | Type-check + production build      |
| `npm run preview`  | Preview production build           |

### Infrastructure (`cd step-1/infrastructure`)

```bash
az deployment sub create --location centralus --template-file step-1/infrastructure/main.bicep
```

All resource names follow the pattern `calmvault-<resource>-<suffix>` (or `calmvault<suffix>` for storage accounts, which disallow hyphens). The suffix defaults to a 4-character hash derived from the subscription ID.

### Infrastructure Components

Defined across `main.bicep` (subscription scope) and `resources.bicep` (resource group scope):

| Resource | Type | Name Pattern | Notes |
| --- | --- | --- | --- |
| Resource Group | `Microsoft.Resources/resourceGroups` | `rg-calmvault-<suffix>` | Default region: `centralus`, tagged `SecurityControl: Ignore` |
| Storage Account | `Microsoft.Storage/storageAccounts` | `calmvault<suffix>` | Standard LRS, TLS 1.2, no public blob access, shared key access enabled |
| Blob Container | `storageAccounts/blobServices/containers` | `calmvault-files` | Created inside the storage account |
| Cosmos DB Account | `Microsoft.DocumentDB/databaseAccounts` | `calmvault-cosmos-<suffix>` | Serverless mode, Session consistency, local auth enabled |
| Cosmos DB Database | `databaseAccounts/sqlDatabases` | `calmvault` | SQL API |
| Cosmos DB Container | `sqlDatabases/containers` | `files` | Partition key: `/id` |
| Container Registry | `Microsoft.ContainerRegistry/registries` | `calmvaultacr<suffix>` | Basic SKU, admin user enabled (added in step-2) |
| Log Analytics | `Microsoft.OperationalInsights/workspaces` | `calmvault-logs-<suffix>` | 30-day retention (added in step-3) |
| Container Apps Env | `Microsoft.App/managedEnvironments` | `calmvault-env-<suffix>` | Linked to Log Analytics (added in step-3) |
| Backend Container App | `Microsoft.App/containerApps` | `calmvault-backend-<suffix>` | Port 3001, external ingress, 0–3 replicas (added in step-3) |
| Frontend Container App | `Microsoft.App/containerApps` | `calmvault-frontend-<suffix>` | Port 80, external ingress, 0–3 replicas (added in step-3) |

### Environment

Backend requires a `.env` file (copy from `.env.example`) with Azure Blob Storage and Cosmos DB credentials. After deploying infrastructure, populate `.env` from the Bicep outputs. Secrets (connection strings, keys) are not included in Bicep outputs — retrieve them via the Azure CLI after deployment.

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
- **Component style**: All components use `<script setup lang="ts">` with Composition API. Props use `defineProps<{}>()`, emits use `defineEmits<{}>()`.
- **State management**: App-level state lives in `App.vue` using `ref()` and `computed()` — no Pinia/Vuex. State is passed down via props; mutations flow up via emits.
- **Component responsibilities**:
  - `App.vue` — owns all state (`files`, `allTags`, `selectedTag`), handles API calls for CRUD, passes data down to children
  - `AppHeader.vue` — branding + upload button, emits `upload` and `toggle-sidebar`
  - `TagSidebar.vue` — tag filter list, emits `select` with tag name or `null` for "All Files"
  - `FileGallery.vue` — grid/list view toggle, renders `FileCard` instances
  - `FileCard.vue` — display-only, emits `click` (preview) and `delete`
  - `FileUpload.vue` — drag & drop + file picker, calls `api.uploadFiles()` directly, emits `upload-complete`
  - `FilePreview.vue` — modal overlay, uses `TagEditor` for inline tag editing, emits `close`, `delete`, `tags-updated`
  - `TagEditor.vue` — reusable tag chip input, uses `update:tags` emit pattern (v-model compatible)
- **CSS**: Scoped styles per component. Global design tokens in `style.css` using CSS custom properties (`--color-*`, `--space-*`, `--text-*`). No CSS framework.
- **File icons**: MIME-type-to-emoji mapping in `FileCard.vue` (`fileIcon()` function). Image thumbnails use `api.getDownloadUrl(id)`.
- **Delete confirmation**: Uses `window.confirm()` in `App.vue` before calling the API.
- **Tags**: Always lowercased and trimmed before saving. Backspace in an empty tag input removes the last tag.

### Lab authoring

- Each step folder (`step-N/`) is an **incremental addition** — it contains only new or modified files for that stage. Earlier steps remain unchanged.
- The root `DEPLOYMENT_GUIDE.md` provides the lab walkthrough. Keep it in sync when adding new steps.
- Dockerfiles reference source from previous steps (e.g., `step-1/frontend/`) since the build context is the repo root.
- **Dual-platform commands**: All CLI command blocks in READMEs and the deployment guide must include both Bash and PowerShell equivalents. Use **Bash:** / **PowerShell:** labels before each block. For commands identical in both shells, use a single block labeled **Bash / PowerShell:**.
- Minimal, calm design language applies to documentation as well — clear headings, short paragraphs, no clutter.

### Design philosophy

- Minimal, calm, iCloud-inspired UI — lots of whitespace, soft colors (accent: `#5ba4cf`)
- Tag-based organization only (no folder hierarchy)
- Upload limit: 50 MB per file (enforced by multer in `step-1/backend/src/middleware/upload.ts`)
- Responsive: sidebar collapses to a slide-in menu on mobile (≤768px)
