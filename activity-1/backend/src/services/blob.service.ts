import {
  BlobServiceClient,
  ContainerClient,
  StorageSharedKeyCredential,
} from "@azure/storage-blob";
import { config } from "../config";

let containerClient: ContainerClient;

export async function initBlobStorage(): Promise<void> {
  const blobServiceClient = BlobServiceClient.fromConnectionString(
    config.azure.storage.connectionString
  );
  containerClient = blobServiceClient.getContainerClient(
    config.azure.storage.containerName
  );
  await containerClient.createIfNotExists();
}

export async function uploadBlob(
  blobName: string,
  buffer: Buffer,
  mimeType: string
): Promise<string> {
  const blockBlobClient = containerClient.getBlockBlobClient(blobName);
  await blockBlobClient.uploadData(buffer, {
    blobHTTPHeaders: { blobContentType: mimeType },
  });
  return blockBlobClient.url;
}

export async function downloadBlob(blobName: string): Promise<Buffer> {
  const blockBlobClient = containerClient.getBlockBlobClient(blobName);
  const response = await blockBlobClient.downloadToBuffer();
  return response;
}

export async function deleteBlob(blobName: string): Promise<void> {
  const blockBlobClient = containerClient.getBlockBlobClient(blobName);
  await blockBlobClient.deleteIfExists();
}
