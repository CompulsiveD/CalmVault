<script setup lang="ts">
import type { FileMetadata } from '../types/file'
import { api } from '../services/api'

const props = defineProps<{
  file: FileMetadata
  viewMode: 'grid' | 'list'
}>()

const emit = defineEmits<{
  click: []
  delete: []
}>()

function isImage(mime: string) {
  return mime.startsWith('image/')
}

function fileIcon(mime: string): string {
  if (mime.startsWith('image/')) return '🖼️'
  if (mime === 'application/pdf') return '📄'
  if (mime.startsWith('video/')) return '🎬'
  if (mime.startsWith('audio/')) return '🎵'
  if (mime.includes('zip') || mime.includes('tar') || mime.includes('compressed')) return '📦'
  if (mime.includes('spreadsheet') || mime.includes('excel') || mime.includes('csv')) return '📊'
  if (mime.includes('document') || mime.includes('word') || mime.startsWith('text/')) return '📝'
  return '📎'
}

function formatSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}

function formatDate(dateStr: string): string {
  const date = new Date(dateStr)
  const now = new Date()
  const diffMs = now.getTime() - date.getTime()
  const diffMin = Math.floor(diffMs / 60000)
  const diffHr = Math.floor(diffMs / 3600000)
  const diffDay = Math.floor(diffMs / 86400000)

  if (diffMin < 1) return 'Just now'
  if (diffMin < 60) return `${diffMin}m ago`
  if (diffHr < 24) return `${diffHr}h ago`
  if (diffDay < 7) return `${diffDay}d ago`
  return date.toLocaleDateString(undefined, { month: 'short', day: 'numeric' })
}

function handleDownload(e: Event) {
  e.stopPropagation()
  const a = document.createElement('a')
  a.href = api.getDownloadUrl(props.file.id)
  a.download = props.file.originalName
  a.click()
}

function handleDelete(e: Event) {
  e.stopPropagation()
  emit('delete')
}
</script>

<template>
  <div :class="['file-card', viewMode]" @click="$emit('click')">
    <div v-if="viewMode === 'grid'" class="card-thumb">
      <img
        v-if="isImage(file.mimeType)"
        :src="api.getDownloadUrl(file.id)"
        :alt="file.originalName"
        class="thumb-img"
        loading="lazy"
      />
      <span v-else class="thumb-icon">{{ fileIcon(file.mimeType) }}</span>
    </div>

    <span v-if="viewMode === 'list'" class="list-icon">{{ fileIcon(file.mimeType) }}</span>

    <div class="card-info">
      <p class="card-name" :title="file.originalName">{{ file.originalName }}</p>
      <div class="card-meta">
        <span>{{ formatSize(file.size) }}</span>
        <span class="meta-dot">·</span>
        <span>{{ formatDate(file.uploadedAt) }}</span>
      </div>
      <div v-if="file.tags.length" class="card-tags">
        <span v-for="tag in file.tags" :key="tag" class="card-tag">{{ tag }}</span>
      </div>
    </div>

    <div class="card-actions">
      <button class="btn-icon" @click="handleDownload" title="Download">
        <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
          <path d="M8 2v9" />
          <path d="M4 8l4 4 4-4" />
          <path d="M2 14h12" />
        </svg>
      </button>
      <button class="btn-icon btn-danger" @click="handleDelete" title="Delete">
        <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
          <path d="M3 4h10" />
          <path d="M6 4V3a1 1 0 011-1h2a1 1 0 011 1v1" />
          <path d="M4.5 4l.5 9a1 1 0 001 1h4a1 1 0 001-1l.5-9" />
        </svg>
      </button>
    </div>
  </div>
</template>

<style scoped>
.file-card {
  background: var(--color-surface);
  border: 1px solid var(--color-border-light);
  border-radius: var(--radius-md);
  cursor: pointer;
  transition: all var(--transition-fast);
  overflow: hidden;
}

.file-card:hover {
  border-color: var(--color-border);
  box-shadow: var(--shadow-md);
}

/* Grid mode */
.file-card.grid {
  display: flex;
  flex-direction: column;
}

.file-card.grid .card-info {
  padding: var(--space-sm) var(--space-md) var(--space-sm);
}

.file-card.grid .card-actions {
  padding: 0 var(--space-sm) var(--space-sm);
  display: flex;
  justify-content: flex-end;
  gap: 2px;
  opacity: 0;
  transition: opacity var(--transition-fast);
}

.file-card.grid:hover .card-actions {
  opacity: 1;
}

.card-thumb {
  width: 100%;
  height: 140px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--color-surface-hover);
  overflow: hidden;
}

.thumb-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.thumb-icon {
  font-size: 36px;
}

/* List mode */
.file-card.list {
  display: flex;
  align-items: center;
  padding: var(--space-sm) var(--space-md);
  gap: var(--space-md);
}

.list-icon {
  font-size: 24px;
  flex-shrink: 0;
}

.file-card.list .card-info {
  flex: 1;
  min-width: 0;
}

.file-card.list .card-actions {
  display: flex;
  gap: 2px;
  flex-shrink: 0;
  opacity: 0;
  transition: opacity var(--transition-fast);
}

.file-card.list:hover .card-actions {
  opacity: 1;
}

/* Shared */
.card-name {
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--color-text);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.card-meta {
  font-size: var(--text-xs);
  color: var(--color-text-tertiary);
  display: flex;
  align-items: center;
  gap: var(--space-xs);
  margin-top: 2px;
}

.meta-dot {
  font-size: 10px;
}

.card-tags {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-xs);
  margin-top: var(--space-xs);
}

.card-tag {
  font-size: var(--text-xs);
  padding: 1px 6px;
  background: var(--color-tag);
  color: var(--color-tag-text);
  border-radius: 100px;
  font-weight: 500;
}

@media (max-width: 768px) {
  .file-card.grid .card-actions,
  .file-card.list .card-actions {
    opacity: 1;
  }
}
</style>
