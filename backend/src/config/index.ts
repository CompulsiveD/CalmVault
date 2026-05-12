import dotenv from "dotenv";
dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || "3001", 10),
  azure: {
    storage: {
      connectionString: process.env.AZURE_STORAGE_CONNECTION_STRING || "",
      containerName:
        process.env.AZURE_STORAGE_CONTAINER_NAME || "calmvault-files",
    },
    cosmos: {
      endpoint: process.env.COSMOS_ENDPOINT || "",
      key: process.env.COSMOS_KEY || "",
      databaseName: process.env.COSMOS_DATABASE_NAME || "calmvault",
      containersNames: {
        files: "files",
        tags: "tags",
      },
    },
  },
};
