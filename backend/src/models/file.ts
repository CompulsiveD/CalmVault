export interface FileMetadata {
  id: string;
  /** Original filename as uploaded by the user */
  originalName: string;
  /** MIME type (e.g., image/png, application/pdf) */
  mimeType: string;
  /** File size in bytes */
  size: number;
  /** Azure Blob Storage blob name (unique key) */
  blobName: string;
  /** User-assigned tags for organization */
  tags: string[];
  /** ISO 8601 upload timestamp */
  uploadedAt: string;
  /** ISO 8601 last-modified timestamp */
  updatedAt: string;
}

export interface CreateFileInput {
  originalName: string;
  mimeType: string;
  size: number;
  blobName: string;
  tags?: string[];
}
