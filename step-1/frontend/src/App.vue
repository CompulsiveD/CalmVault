<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { api } from './services/api'
import type { FileMetadata } from './types/file'
import AppHeader from './components/AppHeader.vue'
import TagSidebar from './components/TagSidebar.vue'
import FileGallery from './components/FileGallery.vue'
import FileUpload from './components/FileUpload.vue'
import FilePreview from './components/FilePreview.vue'

const files = ref<FileMetadata[]>([])
const allTags = ref<string[]>([])
const selectedTag = ref<string | null>(null)
const showUpload = ref(false)
const previewFile = ref<FileMetadata | null>(null)
const loading = ref(false)
const sidebarOpen = ref(false)

const filteredFiles = computed(() => {
  if (!selectedTag.value) return files.value
  return files.value.filter(f => f.tags.includes(selectedTag.value!))
})

async function loadFiles() {
  loading.value = true
  try {
    const res = await api.getFiles()
    if (res.ok) files.value = await res.json()
  } finally {
    loading.value = false
  }
}

async function loadTags() {
  try {
    const res = await api.getTags()
    if (res.ok) allTags.value = await res.json()
  } catch { /* tags are non-critical */ }
}

async function refresh() {
  await Promise.all([loadFiles(), loadTags()])
}

function handleUploadComplete() {
  showUpload.value = false
  refresh()
}

async function handleDelete(id: string) {
  if (!confirm('Delete this file permanently?')) return
  const res = await api.deleteFile(id)
  if (res.ok) {
    if (previewFile.value?.id === id) previewFile.value = null
    await refresh()
  }
}

async function handleTagsUpdated(id: string, tags: string[]) {
  const res = await api.updateTags(id, tags)
  if (res.ok) await refresh()
}

function selectTag(tag: string | null) {
  selectedTag.value = tag
  sidebarOpen.value = false
}

onMounted(refresh)
</script>

<template>
  <AppHeader
    @upload="showUpload = true"
    @toggle-sidebar="sidebarOpen = !sidebarOpen"
  />

  <div class="app-body">
    <TagSidebar
      :tags="allTags"
      :selected-tag="selectedTag"
      :open="sidebarOpen"
      @select="selectTag"
    />

    <main class="main-content">
      <FileUpload
        v-if="showUpload || files.length === 0"
        :always-visible="files.length === 0"
        @upload-complete="handleUploadComplete"
        @close="showUpload = false"
      />

      <FileGallery
        v-if="files.length > 0"
        :files="filteredFiles"
        :loading="loading"
        :selected-tag="selectedTag"
        @preview="previewFile = $event"
        @delete="handleDelete"
      />
    </main>
  </div>

  <FilePreview
    v-if="previewFile"
    :file="previewFile"
    @close="previewFile = null"
    @delete="handleDelete"
    @tags-updated="handleTagsUpdated"
  />
</template>

<style scoped>
.app-body {
  display: flex;
  flex: 1;
  padding-top: var(--header-height);
}

.main-content {
  flex: 1;
  min-width: 0;
  margin-left: var(--sidebar-width);
  padding: var(--space-xl);
}

@media (max-width: 768px) {
  .main-content {
    margin-left: 0;
    padding: var(--space-md);
  }
}
</style>
