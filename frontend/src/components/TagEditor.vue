<script setup lang="ts">
import { ref } from 'vue'

const props = defineProps<{
  tags: string[]
}>()

const emit = defineEmits<{
  'update:tags': [tags: string[]]
}>()

const input = ref('')

function addTag() {
  const tag = input.value.trim().toLowerCase()
  if (tag && !props.tags.includes(tag)) {
    emit('update:tags', [...props.tags, tag])
  }
  input.value = ''
}

function removeTag(tag: string) {
  emit('update:tags', props.tags.filter(t => t !== tag))
}

function handleKeydown(e: KeyboardEvent) {
  if (e.key === 'Enter') {
    e.preventDefault()
    addTag()
  } else if (e.key === 'Backspace' && !input.value && props.tags.length) {
    removeTag(props.tags[props.tags.length - 1])
  }
}
</script>

<template>
  <div class="tag-editor">
    <span
      v-for="tag in tags"
      :key="tag"
      class="tag-chip"
    >
      {{ tag }}
      <button class="tag-remove" @click.stop="removeTag(tag)" aria-label="Remove tag">
        <svg width="12" height="12" viewBox="0 0 12 12" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
          <line x1="3" y1="3" x2="9" y2="9" />
          <line x1="9" y1="3" x2="3" y2="9" />
        </svg>
      </button>
    </span>
    <input
      v-model="input"
      class="tag-input"
      placeholder="Add a tag…"
      @keydown="handleKeydown"
      @blur="addTag"
    />
  </div>
</template>

<style scoped>
.tag-editor {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--space-xs);
  padding: var(--space-sm) var(--space-sm);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  background: var(--color-surface);
  min-height: 36px;
  transition: border-color var(--transition-fast);
}

.tag-editor:focus-within {
  border-color: var(--color-accent-border);
}

.tag-chip {
  display: inline-flex;
  align-items: center;
  gap: 2px;
  padding: 2px 8px;
  background: var(--color-tag);
  color: var(--color-tag-text);
  border-radius: 100px;
  font-size: var(--text-xs);
  font-weight: 500;
}

.tag-remove {
  display: inline-flex;
  align-items: center;
  padding: 0;
  margin-left: 2px;
  color: var(--color-tag-text);
  opacity: 0.6;
  transition: opacity var(--transition-fast);
}

.tag-remove:hover {
  opacity: 1;
}

.tag-input {
  flex: 1;
  min-width: 80px;
  padding: 2px 4px;
  font-size: var(--text-sm);
}

.tag-input::placeholder {
  color: var(--color-text-tertiary);
}
</style>
