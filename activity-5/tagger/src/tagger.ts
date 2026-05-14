import { AzureOpenAI } from "openai";

const TAG_SYSTEM_PROMPT = `You are a file tagging assistant. Analyze the provided file and suggest relevant descriptive tags.

Rules:
- Return ONLY a JSON array of lowercase tag strings (no explanation)
- Each tag must be prefixed with "ai:" (e.g., "ai:landscape", "ai:invoice")
- Generate 3-7 tags that describe the content, subject matter, or document type
- Tags should be concise (1-2 words after the prefix)
- Examples: "ai:nature", "ai:receipt", "ai:code", "ai:portrait", "ai:chart", "ai:meeting-notes"`;

export async function generateTags(
  client: AzureOpenAI,
  deploymentName: string,
  fileType: "image" | "text",
  content: Buffer,
  contentType: string
): Promise<string[]> {
  try {
    if (fileType === "image") {
      return await generateImageTags(client, deploymentName, content, contentType);
    } else {
      return await generateTextTags(client, deploymentName, content);
    }
  } catch (err) {
    console.error("Error generating tags:", err);
    return ["ai:unprocessed"];
  }
}

async function generateImageTags(
  client: AzureOpenAI,
  deploymentName: string,
  imageBuffer: Buffer,
  contentType: string
): Promise<string[]> {
  const base64Image = imageBuffer.toString("base64");
  const mediaType = contentType.split(";")[0].trim();

  const response = await client.chat.completions.create({
    model: deploymentName,
    messages: [
      { role: "system", content: TAG_SYSTEM_PROMPT },
      {
        role: "user",
        content: [
          { type: "text", text: "Analyze this image and suggest tags:" },
          {
            type: "image_url",
            image_url: { url: `data:${mediaType};base64,${base64Image}` },
          },
        ],
      },
    ],
    temperature: 0.3,
    max_tokens: 200,
  });

  return parseTags(response.choices[0]?.message?.content || "[]");
}

async function generateTextTags(
  client: AzureOpenAI,
  deploymentName: string,
  textBuffer: Buffer
): Promise<string[]> {
  // Limit text to first 4000 characters to stay within token limits
  const text = textBuffer.toString("utf-8").slice(0, 4000);

  const response = await client.chat.completions.create({
    model: deploymentName,
    messages: [
      { role: "system", content: TAG_SYSTEM_PROMPT },
      {
        role: "user",
        content: `Analyze this text file and suggest tags:\n\n---\n${text}\n---`,
      },
    ],
    temperature: 0.3,
    max_tokens: 200,
  });

  return parseTags(response.choices[0]?.message?.content || "[]");
}

function parseTags(raw: string): string[] {
  try {
    // Strip markdown code fences if present
    const cleaned = raw.replace(/```json\n?/g, "").replace(/```\n?/g, "").trim();
    const parsed = JSON.parse(cleaned);
    if (!Array.isArray(parsed)) return ["ai:unprocessed"];
    return parsed
      .filter((t): t is string => typeof t === "string")
      .map((t) => (t.startsWith("ai:") ? t : `ai:${t}`).toLowerCase().trim())
      .slice(0, 7);
  } catch {
    return ["ai:unprocessed"];
  }
}
