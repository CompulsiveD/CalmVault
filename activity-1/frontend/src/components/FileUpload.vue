<script setup lang="ts">
import { ref } from 'vue'
import { api } from '../services/api'
import TagEditor from './TagEditor.vue'

const props = defineProps<{
  alwaysVisible?: boolean
}>()

const emit = defineEmits<{
  'upload-complete': []
  close: []
}>()

const isDragging = ref(false)
const uploading = ref(false)
const uploadProgress = ref('')
const tags = ref<string[]>([])
const fileInput = ref<HTMLInputElement | null>(null)

function handleDragOver(e: DragEvent) {
  e.preventDefault()
  isDragging.value = true
}

function handleDragLeave() {
  isDragging.value = false
}

function handleDrop(e: DragEvent) {
  e.preventDefault()
  isDragging.value = false
  const droppedFiles = e.dataTransfer?.files
  if (droppedFiles?.length) uploadFiles(Array.from(droppedFiles))
}

function handleFileSelect(e: Event) {
  const input = e.target as HTMLInputElement
  if (input.files?.length) {
    uploadFiles(Array.from(input.files))
    input.value = ''
  }
}

async function uploadFiles(files: File[]) {
  uploading.value = true
  uploadProgress.value = `Uploading ${files.length} file${files.length > 1 ? 's' : ''}…`
  try {
    const res = await api.uploadFiles(files, tags.value)
    if (res.ok) {
      tags.value = []
      emit('upload-complete')
    } else {
      uploadProgress.value = 'Upload failed. Please try again.'
    }
  } catch {
    uploadProgress.value = 'Upload failed. Please try again.'
  } finally {
    uploading.value = false
  }
}
</script>

<template>
  <div class="upload-wrapper">
    <div class="upload-header" v-if="!alwaysVisible">
      <h2 class="upload-title">Upload Files</h2>
      <button class="btn-icon" @click="emit('close')">
        <svg width="18" height="18" viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
          <line x1="4" y1="4" x2="14" y2="14" />
          <line x1="14" y1="4" x2="4" y2="14" />
        </svg>
      </button>
    </div>

    <div
      class="drop-zone"
      :class="{ dragging: isDragging, uploading }"
      @dragover="handleDragOver"
      @dragleave="handleDragLeave"
      @drop="handleDrop"
      @click="fileInput?.click()"
    >
      <input
        ref="fileInput"
        type="file"
        multiple
        class="file-input"
        @change="handleFileSelect"
      />

      <div v-if="uploading" class="drop-content">
        <div class="spinner" />
        <p class="drop-text">{{ uploadProgress }}</p>
      </div>

      <div v-else class="drop-content">
        <svg class="drop-icon" width="48" height="48" viewBox="0 0 48 48" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
          <path d="M24 32V16" />
          <path d="M16 22l8-8 8 8" />
          <path d="M40 32v6a4 4 0 01-4 4H12a4 4 0 01-4-4v-6" />
        </svg>
        <p class="drop-text">Drop files here or click to browse</p>
        <p class="drop-hint">Any file type up to 50 MB</p>
      </div>
    </div>

    <div class="upload-tags">
      <span class="upload-tags-label">Add tags (optional)</span>
      <TagEditor :tags="tags" @update:tags="tags = $event" />
    </div>
  </div>
</template>

<style scoped>
.upload-wrapper {
  margin-bottom: var(--space-xl);
}

.upload-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: var(--space-md);
}

.upload-title {
  font-size: var(--text-lg);
  font-weight: 600;
  color: var(--color-text);
}

.drop-zone {
  border: 2px dashed var(--color-border);
  border-radius: var(--radius-lg);
  padding: var(--space-2xl);
  text-align: center;
  cursor: pointer;
  transition: all var(--transition-base);
  background: var(--color-surface);
}

.drop-zone:hover {
  border-color: var(--color-accent-border);
  background: var(--color-drop-bg);
}

.drop-zone.dragging {
  border-color: var(--color-accent);
  background: var(--color-accent-light);
  transform: scale(1.01);
}

.drop-zone.uploading {
  cursor: default;
  pointer-events: none;
}

.file-input {
  display: none;
}

.drop-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--space-sm);
}

.drop-icon {
  color: var(--color-text-tertiary);
  margin-bottom: var(--space-sm);
}

.drop-text {
  font-size: var(--text-base);
  color: var(--color-text-secondary);
  font-weight: 500;
}

.drop-hint {
  font-size: var(--text-sm);
  color: var(--color-text-tertiary);
}

.spinner {
  width: 32px;
  height: 32px;
  border: 3px solid var(--color-border);
  border-top-color: var(--color-accent);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.upload-tags {
  margin-top: var(--space-md);
}

.upload-tags-label {
  display: block;
  font-size: var(--text-sm);
  color: var(--color-text-secondary);
  margin-bottom: var(--space-sm);
}
</style>
