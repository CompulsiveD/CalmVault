import { QueueClient } from "@azure/storage-queue";
import { BlobServiceClient } from "@azure/storage-blob";
import { CosmosClient } from "@azure/cosmos";
import { AzureOpenAI } from "openai";
import { generateTags } from "./tagger";

interface EventGridEvent {
  subject: string;
  eventType: string;
  data: {
    api: string;
    contentType: string;
    contentLength: number;
    url: string;
    blobType: string;
  };
}

const POLL_INTERVAL_MS = 5000;
const SUPPORTED_IMAGE_TYPES = ["image/jpeg", "image/png", "image/gif", "image/webp", "image/bmp"];
const SUPPORTED_TEXT_TYPES = ["text/plain", "text/csv", "text/markdown", "text/html", "application/json"];

function isSupportedType(contentType: string): "image" | "text" | null {
  if (SUPPORTED_IMAGE_TYPES.some((t) => contentType.startsWith(t))) return "image";
  if (SUPPORTED_TEXT_TYPES.some((t) => contentType.startsWith(t))) return "text";
  return null;
}

async function main() {
  const connectionString = process.env.AZURE_STORAGE_CONNECTION_STRING!;
  const queueName = process.env.QUEUE_NAME || "blob-events";
  const containerName = process.env.AZURE_STORAGE_CONTAINER_NAME || "calmvault-files";
  const cosmosEndpoint = process.env.COSMOS_ENDPOINT!;
  const cosmosKey = process.env.COSMOS_KEY!;
  const cosmosDatabase = process.env.COSMOS_DATABASE_NAME || "calmvault";
  const openAiEndpoint = process.env.OPENAI_ENDPOINT!;
  const openAiKey = process.env.OPENAI_API_KEY!;
  const deploymentName = process.env.OPENAI_DEPLOYMENT_NAME || "gpt-4o";

  // Initialize clients
  const queueClient = new QueueClient(connectionString, queueName);
  const blobServiceClient = BlobServiceClient.fromConnectionString(connectionString);
  const blobContainerClient = blobServiceClient.getContainerClient(containerName);
  const cosmosClient = new CosmosClient({ endpoint: cosmosEndpoint, key: cosmosKey });
  const cosmosContainer = cosmosClient.database(cosmosDatabase).container("files");
  const openAiClient = new AzureOpenAI({
    endpoint: openAiEndpoint,
    apiKey: openAiKey,
    apiVersion: "2024-10-21",
  });

  console.log("CalmVault AI Tagger started. Polling queue for blob events...");

  // Poll loop
  while (true) {
    const response = await queueClient.receiveMessages({ numberOfMessages: 5, visibilityTimeout: 60 });

    for (const message of response.receivedMessageItems) {
      try {
        // Event Grid wraps the event in base64
        const decoded = Buffer.from(message.messageText, "base64").toString("utf-8");
        const event: EventGridEvent = JSON.parse(decoded);

        if (event.eventType !== "Microsoft.Storage.BlobCreated") {
          await queueClient.deleteMessage(message.messageId, message.popReceipt);
          continue;
        }

        // Extract blob name from subject: /blobServices/default/containers/{container}/blobs/{blobName}
        const blobName = event.subject.split("/blobs/")[1];
        if (!blobName) {
          console.log(`Skipping event — could not extract blob name from: ${event.subject}`);
          await queueClient.deleteMessage(message.messageId, message.popReceipt);
          continue;
        }

        const contentType = event.data.contentType || "";
        const fileType = isSupportedType(contentType);

        if (!fileType) {
          console.log(`Skipping ${blobName} — unsupported content type: ${contentType}`);
          await queueClient.deleteMessage(message.messageId, message.popReceipt);
          continue;
        }

        console.log(`Processing ${blobName} (${contentType}) as ${fileType}...`);

        // Download the blob
        const blobClient = blobContainerClient.getBlobClient(blobName);
        const downloadResponse = await blobClient.download();
        const blobBuffer = await streamToBuffer(downloadResponse.readableStreamBody!);

        // Generate AI tags
        const aiTags = await generateTags(openAiClient, deploymentName, fileType, blobBuffer, contentType);
        console.log(`Generated tags for ${blobName}: ${aiTags.join(", ")}`);

        // Find the Cosmos document by blobName and update tags
        const { resources: docs } = await cosmosContainer.items
          .query({ query: "SELECT * FROM c WHERE c.blobName = @blobName", parameters: [{ name: "@blobName", value: blobName }] })
          .fetchAll();

        if (docs.length === 0) {
          console.log(`No Cosmos document found for blob: ${blobName}`);
        } else {
          const doc = docs[0];
          const existingTags: string[] = doc.tags || [];
          // Remove any old ai: tags, then add new ones
          const userTags = existingTags.filter((t: string) => !t.startsWith("ai:"));
          const updatedTags = [...userTags, ...aiTags];
          await cosmosContainer.item(doc.id, doc.id).patch([
            { op: "replace", path: "/tags", value: updatedTags },
          ]);
          console.log(`Updated tags for ${doc.originalName || blobName}`);
        }

        await queueClient.deleteMessage(message.messageId, message.popReceipt);
      } catch (err) {
        console.error(`Error processing message ${message.messageId}:`, err);
        // Message will become visible again after visibilityTimeout expires
      }
    }

    if (response.receivedMessageItems.length === 0) {
      await sleep(POLL_INTERVAL_MS);
    }
  }
}

async function streamToBuffer(stream: NodeJS.ReadableStream): Promise<Buffer> {
  const chunks: Buffer[] = [];
  for await (const chunk of stream) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
  }
  return Buffer.concat(chunks);
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

main().catch((err) => {
  console.error("Fatal error:", err);
  process.exit(1);
});
