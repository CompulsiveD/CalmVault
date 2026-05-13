import { CosmosClient, Database, Container } from "@azure/cosmos";
import { DefaultAzureCredential } from "@azure/identity";
import { config } from "../config";

let client: CosmosClient;
let database: Database;
let filesContainer: Container;

export async function initCosmos(): Promise<void> {
  client = new CosmosClient({
    endpoint: config.azure.cosmos.endpoint,
    key: config.azure.cosmos.key,
    //aadCredentials: new DefaultAzureCredential(), // Use DefaultAzureCredential for authentication
  });

  const { database: db } = await client.databases.createIfNotExists({
    id: config.azure.cosmos.databaseName,
  });
  database = db;

  const { container } = await database.containers.createIfNotExists({
    id: config.azure.cosmos.containersNames.files,
    partitionKey: { paths: ["/id"] },
  });
  filesContainer = container;
}

export function getFilesContainer(): Container {
  if (!filesContainer) {
    throw new Error("Cosmos DB not initialized. Call initCosmos() first.");
  }
  return filesContainer;
}
