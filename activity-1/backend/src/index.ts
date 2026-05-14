import appInsights from "applicationinsights";

if (process.env.APPLICATIONINSIGHTS_CONNECTION_STRING) {
  appInsights
    .setup(process.env.APPLICATIONINSIGHTS_CONNECTION_STRING)
    .setAutoCollectRequests(true)
    .setAutoCollectDependencies(true)
    .setAutoCollectExceptions(true)
    .setAutoCollectPerformance(true, true)
    .start();
}

import express from "express";
import cors from "cors";
import { config } from "./config";
import { initCosmos } from "./services/cosmos.service";
import { initBlobStorage } from "./services/blob.service";
import filesRouter from "./routes/files";

const app = express();

app.use(cors());
app.use(express.json());

app.use("/api/files", filesRouter);

app.get("/api/health", (_req, res) => {
  res.json({ status: "ok" });
});

async function start() {
  try {
    console.log("Initializing Azure services...");
    await initCosmos();
    await initBlobStorage();
    console.log("Azure services initialized.");

    app.listen(config.port, () => {
      console.log(`CalmVault API listening on http://localhost:${config.port}`);
    });
  } catch (err) {
    console.error("Failed to start server:", err);
    process.exit(1);
  }
}

start();
