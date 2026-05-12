import { Router, Request, Response } from "express";
import { v4 as uuidv4 } from "uuid";
import { upload } from "../middleware/upload";
import {
  createFile,
  getAllFiles,
  getFileById,
  getFilesByTag,
  updateFileTags,
  deleteFile,
  getFileContent,
  getAllTags,
} from "../services/file.service";
import path from "path";

const router = Router();

/** POST /api/files — Upload one or more files */
router.post(
  "/",
  upload.array("files", 20),
  async (req: Request, res: Response): Promise<void> => {
    try {
      const files = req.files as Express.Multer.File[];
      if (!files || files.length === 0) {
        res.status(400).json({ error: "No files provided" });
        return;
      }

      const tags: string[] = req.body.tags
        ? JSON.parse(req.body.tags)
        : [];

      const results = await Promise.all(
        files.map((file) => {
          const ext = path.extname(file.originalname);
          const blobName = `${uuidv4()}${ext}`;
          return createFile(
            {
              originalName: file.originalname,
              mimeType: file.mimetype,
              size: file.size,
              blobName,
              tags,
            },
            file.buffer
          );
        })
      );

      res.status(201).json(results);
    } catch (err) {
      console.error("Upload error:", err);
      res.status(500).json({ error: "Failed to upload files" });
    }
  }
);

/** GET /api/files — List all files, optionally filtered by tag */
router.get("/", async (req: Request, res: Response): Promise<void> => {
  try {
    const tag = req.query.tag as string | undefined;
    const files = tag ? await getFilesByTag(tag) : await getAllFiles();
    res.json(files);
  } catch (err) {
    console.error("List error:", err);
    res.status(500).json({ error: "Failed to list files" });
  }
});

/** GET /api/files/tags — List all unique tags */
router.get("/tags", async (_req: Request, res: Response): Promise<void> => {
  try {
    const tags = await getAllTags();
    res.json(tags);
  } catch (err) {
    console.error("Tags error:", err);
    res.status(500).json({ error: "Failed to list tags" });
  }
});

/** GET /api/files/:id — Get file metadata */
router.get("/:id", async (req: Request, res: Response): Promise<void> => {
  try {
    const id = req.params.id as string;
    const file = await getFileById(id);
    if (!file) {
      res.status(404).json({ error: "File not found" });
      return;
    }
    res.json(file);
  } catch (err) {
    console.error("Get file error:", err);
    res.status(500).json({ error: "Failed to get file" });
  }
});

/** GET /api/files/:id/download — Download file content */
router.get(
  "/:id/download",
  async (req: Request, res: Response): Promise<void> => {
    try {
      const id = req.params.id as string;
      const result = await getFileContent(id);
      if (!result) {
        res.status(404).json({ error: "File not found" });
        return;
      }

      res.setHeader("Content-Type", result.file.mimeType);
      res.setHeader(
        "Content-Disposition",
        `attachment; filename="${result.file.originalName}"`
      );
      res.send(result.buffer);
    } catch (err) {
      console.error("Download error:", err);
      res.status(500).json({ error: "Failed to download file" });
    }
  }
);

/** PATCH /api/files/:id/tags — Update file tags */
router.patch(
  "/:id/tags",
  async (req: Request, res: Response): Promise<void> => {
    try {
      const { tags } = req.body;
      if (!Array.isArray(tags)) {
        res.status(400).json({ error: "tags must be an array of strings" });
        return;
      }

      const id = req.params.id as string;
      const file = await updateFileTags(id, tags);
      if (!file) {
        res.status(404).json({ error: "File not found" });
        return;
      }
      res.json(file);
    } catch (err) {
      console.error("Update tags error:", err);
      res.status(500).json({ error: "Failed to update tags" });
    }
  }
);

/** DELETE /api/files/:id — Delete a file */
router.delete("/:id", async (req: Request, res: Response): Promise<void> => {
  try {
    const id = req.params.id as string;
    const deleted = await deleteFile(id);
    if (!deleted) {
      res.status(404).json({ error: "File not found" });
      return;
    }
    res.status(204).send();
  } catch (err) {
    console.error("Delete error:", err);
    res.status(500).json({ error: "Failed to delete file" });
  }
});

export default router;
