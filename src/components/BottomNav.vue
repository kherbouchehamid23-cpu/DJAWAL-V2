<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useBreakpoint } from '@/composables/useBreakpoint'
import { useAuthStore } from '@/stores/auth'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const { isMobile } = useBreakpoint()

const items = computed(() => [
  { key: 'home', to: '/', icon: 'home', label: 'Accueil' },
  { key: 'explore', to: '/voyages', icon: 'map', label: 'Explorer' },
  { key: 'ai', to: '/composer', icon: 'sparkles', label: 'IA', center: true },
  { key: 'favorites', to: auth.isAuthenticated ? '/mon-espace/favoris' : '/auth/login', icon: 'heart', label: 'Favoris' },
  { key: 'profile', to: auth.isAuthenticated ? '/mon-espace' : '/auth/login', icon: 'user', label: 'Profil' }
])

function isActive(item: typeof items.value[number]): boolean {
  if (item.to === '/') return route.path === '/'
  return route.path.startsWith(item.to)
}

function navigate(to: string) {
  router.push(to)
}
</script>

<template>
  <nav v-if="isMobile" class="bottom-nav" aria-label="Navigation principale">
    <button
      v-for="item in items"
      :key="item.key"
      class="nav-item"
      :class="{ active: isActive(item), 'is-ai': item.center }"
      @click="navigate(item.to)"
      :aria-label="item.label"
    >
      <div :class="item.center ? 'nav-icon-wrap' : 'nav-icon'">
        <svg v-if="item.icon === 'home'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M3 12 L12 3 L21 12 M5 10 L5 21 L9 21 L9 15 L15 15 L15 21 L19 21 L19 10" />
        </svg>
        <svg v-else-if="item.icon === 'map'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M21 10 c 0 7 -9 13 -9 13 s -9 -6 -9 -13 a 9 9 0 0 1 18 0 z" />
          <circle cx="12" cy="10" r="3" />
        </svg>
        <svg v-else-if="item.icon === 'sparkles'" viewBox="0 0 24 24" fill="currentColor">
          <path d="M12 2 L14 9 L21 12 L14 15 L12 22 L10 15 L3 12 L10 9 Z" />
        </svg>
        <svg v-else-if="item.icon === 'heart'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
        </svg>
        <svg v-else-if="item.icon === 'user'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="12" cy="8" r="4" />
          <path d="M4 20 c 0 -5 4 -8 8 -8 s 8 3 8 8" />
        </svg>
      </div>
      <span class="nav-label">{{ item.label }}</span>
    </button>
  </nav>
</template>

<style scoped>
.bottom-nav {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background: rgba(255, 255, 255, 0.97);
  backdrop-filter: blur(14px);
  -webkit-backdrop-filter: blur(14px);
  border-top: 1px solid rgba(10, 31, 46, 0.06);
  padding: 10px 8px calc(env(safe-area-inset-bottom, 12px) + 4px);
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  z-index: 999;
}

.nav-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 3px;
  padding: 6px 2px;
  background: transparent;
  border: none;
  cursor: pointer;
  color: var(--c-texte-doux, #6B6B6B);
  font-family: inherit;
  position: relative;
}

.nav-item.active {
  color: var(--c-primaire-profond, #0A1F2E);
}

.nav-icon {
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
}
.nav-icon svg {
  width: 22px;
  height: 22px;
}

.nav-item.active .nav-icon::after {
  content: '';
  position: absolute;
  bottom: -4px;
  left: 50%;
  transform: translateX(-50%);
  width: 4px;
  height: 4px;
  background: var(--c-accent, #D4A04F);
  border-radius: 50%;
}

.nav-label {
  font-size: 10px;
  font-weight: 500;
  letter-spacing: 0.02em;
}

/* IA — bouton central proéminent */
.nav-item.is-ai {
  color: var(--c-fond, #FAF7F2);
}
.nav-icon-wrap {
  width: 46px;
  height: 46px;
  background: linear-gradient(135deg, var(--c-accent, #D4A04F), var(--c-accent-fort, #B8862E));
  border-radius: 50%;
  margin-top: -16px;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 6px 18px rgba(212, 160, 79, 0.45);
  color: var(--c-primaire-profond, #0A1F2E);
  position: relative;
}
.nav-icon-wrap svg {
  width: 22px;
  height: 22px;
}
.nav-item.is-ai .nav-label {
  color: var(--c-accent-fort, #B8862E);
  font-weight: 600;
  margin-top: 2px;
}
.nav-item.is-ai.active .nav-icon-wrap::after {
  content: '';
  position: absolute;
  inset: -3px;
  border: 2px solid var(--c-accent, #D4A04F);
  border-radius: 50%;
  opacity: 0.5;
  animation: pulse-ring 2s infinite;
}
@keyframes pulse-ring {
  0% { transform: scale(1); opacity: 0.5; }
  100% { transform: scale(1.18); opacity: 0; }
}

@media (min-width: 640px) {
  .bottom-nav { display: none; }
}
</style>
