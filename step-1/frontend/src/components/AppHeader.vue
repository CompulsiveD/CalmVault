<script setup lang="ts">
defineEmits<{
  upload: []
  'toggle-sidebar': []
}>()
</script>

<template>
  <header class="header">
    <div class="header-left">
      <button class="btn-icon mobile-menu" @click="$emit('toggle-sidebar')">
        <svg width="20" height="20" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round">
          <line x1="3" y1="5" x2="17" y2="5" />
          <line x1="3" y1="10" x2="17" y2="10" />
          <line x1="3" y1="15" x2="17" y2="15" />
        </svg>
      </button>
      <h1 class="logo">CalmVault</h1>
    </div>
    <button class="btn btn-primary" @click="$emit('upload')">
      <svg width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
        <line x1="8" y1="2" x2="8" y2="14" />
        <line x1="2" y1="8" x2="14" y2="8" />
      </svg>
      Upload
    </button>
  </header>
</template>

<style scoped>
.header {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 100;
  height: var(--header-height);
  background: rgba(255, 255, 255, 0.85);
  backdrop-filter: blur(12px);
  border-bottom: 1px solid var(--color-border-light);
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 var(--space-lg);
}

.header-left {
  display: flex;
  align-items: center;
  gap: var(--space-sm);
}

.logo {
  font-size: var(--text-lg);
  font-weight: 600;
  letter-spacing: -0.3px;
  color: var(--color-text);
}

.mobile-menu {
  display: none;
}

@media (max-width: 768px) {
  .mobile-menu {
    display: inline-flex;
  }
}
</style>
