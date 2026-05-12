<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import type { FileMetadata } from '../types/file'
import { api } from '../services/api'
import TagEditor from './TagEditor.vue'

const props = defineProps<{
  file: FileMetadata
}>()

const emit = defineEmits<{
  close: []
  delete: [id: string]
  'tags-updated': [id: string, tags: string[]]
}>()

const editingTags = ref(false)
const localTags = ref([...props.file.tags])

const downloadUrl = computed(() => api.getDownloadUrl(props.file.id))
const isImage = computed(() => props.file.mimeType.startsWith('image/'))
const isPdf = computed(() => props.file.mimeType === 'application/pdf')
const isVideo = computed(() => props.file.mimeType.startsWith('video/'))
const isAudio = computed(() => props.file.mimeType.startsWith('audio/'))

function formatSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`
}

function formatFullDate(dateStr: string): string {
  return new Date(dateStr).toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

function handleDownload() {
  const a = document.createElement('a')
  a.href = downloadUrl.value
  a.download = props.file.originalName
  a.click()
}

function saveTags() {
  emit('tags-updated', props.file.id, localTags.value)
  editingTags.value = false
}

function handleKeydown(e: KeyboardEvent) {
  if (e.key === 'Escape') emit('close')
}

onMounted(() => document.addEventListener('keydown', handleKeydown))
onUnmounted(() => document.removeEventListener('keydown', handleKeydown))
</script>

<template>
  <div class="preview-overlay" @click.self="$emit('close')">
    <div class="preview-panel">
      <div class="preview-header">
        <h3 class="preview-title" :title="file.originalName">{{ file.originalName }}</h3>
        <button class="btn-icon" @click="$emit('close')" aria-label="Close">
          <svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
            <line x1="5" y1="5" x2="15" y2="15" />
            <line x1="15" y1="5" x2="5" y2="15" />
          </svg>
        </button>
      </div>

      <div class="preview-body">
        <div class="preview-media">
          <img v-if="isImage" :src="downloadUrl" :alt="file.originalName" class="media-img" />
          <iframe v-else-if="isPdf" :src="downloadUrl" class="media-pdf" />
          <video v-else-if="isVideo" :src="downloadUrl" controls class="media-video" />
          <audio v-else-if="isAudio" :src="downloadUrl" controls class="media-audio" />
          <div v-else class="media-unsupported">
            <span class="unsupported-icon">📎</span>
            <p>Preview not available</p>
            <button class="btn btn-primary" @click="handleDownload">Download to view</button>
          </div>
        </div>

        <div class="preview-details">
          <div class="detail-section">
            <h4 class="detail-label">Details</h4>
            <dl class="detail-list">
              <div class="detail-row">
                <dt>Size</dt>
                <dd>{{ formatSize(file.size) }}</dd>
              </div>
              <div class="detail-row">
                <dt>Type</dt>
                <dd>{{ file.mimeType }}</dd>
              </div>
              <div class="detail-row">
                <dt>Uploaded</dt>
                <dd>{{ formatFullDate(file.uploadedAt) }}</dd>
              </div>
            </dl>
          </div>

          <div class="detail-section">
            <div class="detail-section-header">
              <h4 class="detail-label">Tags</h4>
              <button
                v-if="!editingTags"
                class="btn btn-ghost"
                @click="editingTags = true; localTags = [...file.tags]"
              >Edit</button>
              <button
                v-else
                class="btn btn-primary"
                @click="saveTags"
              >Save</button>
            </div>

            <div v-if="editingTags">
              <TagEditor :tags="localTags" @update:tags="localTags = $event" />
            </div>
            <div v-else-if="file.tags.length" class="preview-tags">
              <span v-for="tag in file.tags" :key="tag" class="card-tag">{{ tag }}</span>
            </div>
            <p v-else class="no-tags">No tags</p>
          </div>

          <div class="detail-actions">
            <button class="btn btn-ghost" @click="handleDownload">
              <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                <path d="M8 2v9" /><path d="M4 8l4 4 4-4" /><path d="M2 14h12" />
              </svg>
              Download
            </button>
            <button class="btn btn-danger" @click="$emit('delete', file.id)">
              <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                <path d="M3 4h10" /><path d="M6 4V3a1 1 0 011-1h2a1 1 0 011 1v1" /><path d="M4.5 4l.5 9a1 1 0 001 1h4a1 1 0 001-1l.5-9" />
              </svg>
              Delete
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.preview-overlay {
  position: fixed;
  inset: 0;
  z-index: 200;
  background: var(--color-overlay);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: var(--space-lg);
  animation: fadeIn 0.2s ease;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

.preview-panel {
  background: var(--color-surface);
  border-radius: var(--radius-xl);
  width: 100%;
  max-width: 900px;
  max-height: 90vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  box-shadow: var(--shadow-lg);
  animation: slideUp 0.25s ease;
}

@keyframes slideUp {
  from { transform: translateY(16px); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}

.preview-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--space-md) var(--space-lg);
  border-bottom: 1px solid var(--color-border-light);
}

.preview-title {
  font-size: var(--text-base);
  font-weight: 600;
  color: var(--color-text);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  margin-right: var(--space-md);
}

.preview-body {
  display: flex;
  flex: 1;
  overflow: hidden;
}

.preview-media {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--color-bg);
  min-height: 300px;
  overflow: auto;
}

.media-img {
  max-width: 100%;
  max-height: 70vh;
  object-fit: contain;
}

.media-pdf {
  width: 100%;
  height: 70vh;
  border: none;
}

.media-video {
  max-width: 100%;
  max-height: 70vh;
}

.media-audio {
  width: 80%;
  margin: var(--space-xl);
}

.media-unsupported {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--space-md);
  color: var(--color-text-tertiary);
  padding: var(--space-2xl);
}

.unsupported-icon {
  font-size: 48px;
}

.preview-details {
  width: 260px;
  flex-shrink: 0;
  border-left: 1px solid var(--color-border-light);
  padding: var(--space-lg);
  overflow-y: auto;
  display: flex;
  flex-direction: column;
  gap: var(--space-lg);
}

.detail-section {
  display: flex;
  flex-direction: column;
  gap: var(--space-sm);
}

.detail-section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.detail-label {
  font-size: var(--text-xs);
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  color: var(--color-text-tertiary);
}

.detail-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-sm);
}

.detail-row {
  display: flex;
  justify-content: space-between;
  font-size: var(--text-sm);
}

.detail-row dt {
  color: var(--color-text-secondary);
}

.detail-row dd {
  color: var(--color-text);
  text-align: right;
  word-break: break-all;
}

.preview-tags {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-xs);
}

.card-tag {
  font-size: var(--text-xs);
  padding: 2px 8px;
  background: var(--color-tag);
  color: var(--color-tag-text);
  border-radius: 100px;
  font-weight: 500;
}

.no-tags {
  font-size: var(--text-sm);
  color: var(--color-text-tertiary);
}

.detail-actions {
  display: flex;
  flex-direction: column;
  gap: var(--space-sm);
  margin-top: auto;
  padding-top: var(--space-md);
  border-top: 1px solid var(--color-border-light);
}

@media (max-width: 768px) {
  .preview-body {
    flex-direction: column;
  }
  .preview-details {
    width: 100%;
    border-left: none;
    border-top: 1px solid var(--color-border-light);
    max-height: 40vh;
  }
  .preview-media {
    min-height: 200px;
  }
}
</style>
