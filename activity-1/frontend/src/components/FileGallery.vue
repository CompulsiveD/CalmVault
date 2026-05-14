<script setup lang="ts">
import { ref } from 'vue'
import type { FileMetadata } from '../types/file'
import FileCard from './FileCard.vue'

defineProps<{
  files: FileMetadata[]
  loading: boolean
  selectedTag: string | null
}>()

const emit = defineEmits<{
  preview: [file: FileMetadata]
  delete: [id: string]
}>()

const viewMode = ref<'grid' | 'list'>('grid')
</script>

<template>
  <div class="gallery">
    <div class="gallery-toolbar">
      <h2 class="gallery-title">
        {{ selectedTag ? `#${selectedTag}` : 'All Files' }}
        <span class="gallery-count">{{ files.length }}</span>
      </h2>
      <div class="view-toggle">
        <button
          class="btn-icon"
          :class="{ active: viewMode === 'grid' }"
          @click="viewMode = 'grid'"
          aria-label="Grid view"
        >
          <svg width="18" height="18" viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
            <rect x="2" y="2" width="5.5" height="5.5" rx="1" />
            <rect x="10.5" y="2" width="5.5" height="5.5" rx="1" />
            <rect x="2" y="10.5" width="5.5" height="5.5" rx="1" />
            <rect x="10.5" y="10.5" width="5.5" height="5.5" rx="1" />
          </svg>
        </button>
        <button
          class="btn-icon"
          :class="{ active: viewMode === 'list' }"
          @click="viewMode = 'list'"
          aria-label="List view"
        >
          <svg width="18" height="18" viewBox="0 0 18 18" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round">
            <line x1="2" y1="4" x2="16" y2="4" />
            <line x1="2" y1="9" x2="16" y2="9" />
            <line x1="2" y1="14" x2="16" y2="14" />
          </svg>
        </button>
      </div>
    </div>

    <div v-if="loading" class="gallery-loading">
      <div class="spinner" />
    </div>

    <div v-else-if="files.length === 0" class="gallery-empty">
      <p>No files{{ selectedTag ? ` tagged "${selectedTag}"` : '' }}</p>
    </div>

    <div v-else :class="['gallery-grid', viewMode]">
      <FileCard
        v-for="file in files"
        :key="file.id"
        :file="file"
        :view-mode="viewMode"
        @click="emit('preview', file)"
        @delete="emit('delete', file.id)"
      />
    </div>
  </div>
</template>

<style scoped>
.gallery-toolbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: var(--space-lg);
}

.gallery-title {
  font-size: var(--text-xl);
  font-weight: 600;
  color: var(--color-text);
  display: flex;
  align-items: center;
  gap: var(--space-sm);
}

.gallery-count {
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--color-text-tertiary);
  background: var(--color-surface-hover);
  padding: 2px 8px;
  border-radius: 100px;
}

.view-toggle {
  display: flex;
  gap: 2px;
  background: var(--color-surface-hover);
  border-radius: var(--radius-sm);
  padding: 2px;
}

.view-toggle .btn-icon.active {
  background: var(--color-surface);
  color: var(--color-accent);
  box-shadow: var(--shadow-sm);
}

.gallery-grid.grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: var(--space-md);
}

.gallery-grid.list {
  display: flex;
  flex-direction: column;
  gap: var(--space-sm);
}

.gallery-loading {
  display: flex;
  justify-content: center;
  padding: var(--space-2xl);
}

.spinner {
  width: 28px;
  height: 28px;
  border: 3px solid var(--color-border);
  border-top-color: var(--color-accent);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.gallery-empty {
  text-align: center;
  padding: var(--space-2xl);
  color: var(--color-text-tertiary);
  font-size: var(--text-base);
}

@media (max-width: 768px) {
  .gallery-grid.grid {
    grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
    gap: var(--space-sm);
  }
}
</style>
