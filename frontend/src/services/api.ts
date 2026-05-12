const API_BASE = import.meta.env.VITE_API_BASE_URL || "http://localhost:3001";

export const api = {
  async uploadFiles(files: File[], tags: string[] = []): Promise<Response> {
    const formData = new FormData();
    files.forEach((file) => formData.append("files", file));
    if (tags.length > 0) {
      formData.append("tags", JSON.stringify(tags));
    }
    return fetch(`${API_BASE}/api/files`, {
      method: "POST",
      body: formData,
    });
  },

  async getFiles(tag?: string): Promise<Response> {
    const url = tag
      ? `${API_BASE}/api/files?tag=${encodeURIComponent(tag)}`
      : `${API_BASE}/api/files`;
    return fetch(url);
  },

  async getFile(id: string): Promise<Response> {
    return fetch(`${API_BASE}/api/files/${id}`);
  },

  async downloadFile(id: string): Promise<Response> {
    return fetch(`${API_BASE}/api/files/${id}/download`);
  },

  async updateTags(id: string, tags: string[]): Promise<Response> {
    return fetch(`${API_BASE}/api/files/${id}/tags`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ tags }),
    });
  },

  async deleteFile(id: string): Promise<Response> {
    return fetch(`${API_BASE}/api/files/${id}`, { method: "DELETE" });
  },

  async getTags(): Promise<Response> {
    return fetch(`${API_BASE}/api/files/tags`);
  },

  getDownloadUrl(id: string): string {
    return `${API_BASE}/api/files/${id}/download`;
  },
};
