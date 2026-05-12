import { v4 as uuidv4 } from "uuid";
import { FileMetadata, CreateFileInput } from "../models/file";
import { getFilesContainer } from "./cosmos.service";
import { uploadBlob, downloadBlob, deleteBlob } from "./blob.service";

export async function createFile(
  input: CreateFileInput,
  fileBuffer: Buffer
): Promise<FileMetadata> {
  const now = new Date().toISOString();
  const file: FileMetadata = {
    id: uuidv4(),
    originalName: input.originalName,
    mimeType: input.mimeType,
    size: input.size,
    blobName: input.blobName,
    tags: input.tags || [],
    uploadedAt: now,
    updatedAt: now,
  };

  await uploadBlob(file.blobName, fileBuffer, file.mimeType);

  const container = getFilesContainer();
  await container.items.create(file);

  return file;
}

export async function getAllFiles(): Promise<FileMetadata[]> {
  const container = getFilesContainer();
  const { resources } = await container.items
    .query<FileMetadata>("SELECT * FROM c ORDER BY c.uploadedAt DESC")
    .fetchAll();
  return resources;
}

export async function getFileById(id: string): Promise<FileMetadata | null> {
  const container = getFilesContainer();
  try {
    const { resource } = await container.item(id, id).read<FileMetadata>();
    return resource || null;
  } catch {
    return null;
  }
}

export async function getFilesByTag(tag: string): Promise<FileMetadata[]> {
  const container = getFilesContainer();
  const { resources } = await container.items
    .query<FileMetadata>({
      query: "SELECT * FROM c WHERE ARRAY_CONTAINS(c.tags, @tag)",
      parameters: [{ name: "@tag", value: tag }],
    })
    .fetchAll();
  return resources;
}

export async function updateFileTags(
  id: string,
  tags: string[]
): Promise<FileMetadata | null> {
  const file = await getFileById(id);
  if (!file) return null;

  file.tags = tags;
  file.updatedAt = new Date().toISOString();

  const container = getFilesContainer();
  const { resource } = await container.item(id, id).replace(file);
  return resource || null;
}

export async function deleteFile(id: string): Promise<boolean> {
  const file = await getFileById(id);
  if (!file) return false;

  await deleteBlob(file.blobName);

  const container = getFilesContainer();
  await container.item(id, id).delete();
  return true;
}

export async function getFileContent(id: string): Promise<{
  buffer: Buffer;
  file: FileMetadata;
} | null> {
  const file = await getFileById(id);
  if (!file) return null;

  const buffer = await downloadBlob(file.blobName);
  return { buffer, file };
}

export async function getAllTags(): Promise<string[]> {
  const container = getFilesContainer();
  const { resources } = await container.items
    .query<string>({
      query: "SELECT DISTINCT VALUE t FROM c JOIN t IN c.tags",
    })
    .fetchAll();
  return resources;
}
