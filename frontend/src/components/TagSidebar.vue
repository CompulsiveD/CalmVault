<script setup lang="ts">
defineProps<{
  tags: string[]
  selectedTag: string | null
  open: boolean
}>()

const emit = defineEmits<{
  select: [tag: string | null]
}>()
</script>

<template>
  <aside class="sidebar" :class="{ open }">
    <nav class="sidebar-nav">
      <button
        class="sidebar-item"
        :class="{ active: !selectedTag }"
        @click="emit('select', null)"
      >
        <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
          <rect x="2" y="2" width="5" height="5" rx="1" />
          <rect x="9" y="2" width="5" height="5" rx="1" />
          <rect x="2" y="9" width="5" height="5" rx="1" />
          <rect x="9" y="9" width="5" height="5" rx="1" />
        </svg>
        All Files
      </button>

      <div v-if="tags.length > 0" class="sidebar-section">
        <span class="sidebar-label">Tags</span>
        <button
          v-for="tag in tags"
          :key="tag"
          class="sidebar-item"
          :class="{ active: selectedTag === tag }"
          @click="emit('select', tag)"
        >
          <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
            <path d="M2 9.5V3a1 1 0 011-1h6.5L14 6.5 8.5 14 2 9.5z" />
            <circle cx="5.5" cy="5.5" r="1" fill="currentColor" />
          </svg>
          {{ tag }}
        </button>
      </div>
    </nav>
  </aside>
</template>

<style scoped>
.sidebar {
  position: fixed;
  top: var(--header-height);
  left: 0;
  bottom: 0;
  width: var(--sidebar-width);
  background: var(--color-surface);
  border-right: 1px solid var(--color-border-light);
  overflow-y: auto;
  z-index: 90;
  transition: transform var(--transition-base);
}

.sidebar-nav {
  padding: var(--space-md);
  display: flex;
  flex-direction: column;
  gap: var(--space-xs);
}

.sidebar-section {
  margin-top: var(--space-md);
  display: flex;
  flex-direction: column;
  gap: var(--space-xs);
}

.sidebar-label {
  font-size: var(--text-xs);
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  color: var(--color-text-tertiary);
  padding: var(--space-sm) var(--space-sm);
}

.sidebar-item {
  display: flex;
  align-items: center;
  gap: var(--space-sm);
  padding: var(--space-sm) var(--space-sm);
  border-radius: var(--radius-sm);
  font-size: var(--text-sm);
  color: var(--color-text-secondary);
  transition: all var(--transition-fast);
  text-align: left;
}

.sidebar-item:hover {
  background: var(--color-surface-hover);
  color: var(--color-text);
}

.sidebar-item.active {
  background: var(--color-accent-light);
  color: var(--color-accent);
  font-weight: 500;
}

@media (max-width: 768px) {
  .sidebar {
    transform: translateX(-100%);
    box-shadow: var(--shadow-lg);
  }
  .sidebar.open {
    transform: translateX(0);
  }
}
</style>
