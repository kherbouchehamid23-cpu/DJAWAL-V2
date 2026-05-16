<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useFavorites, type FavoriteTarget } from '@/composables/useFavorites'

const props = withDefaults(defineProps<{
  targetType: FavoriteTarget
  targetId: string
  // Variantes visuelles
  size?: 'sm' | 'md' | 'lg'
  // Position absolue (sur une card avec image)
  floating?: boolean
}>(), {
  size: 'md',
  floating: false
})

const auth = useAuthStore()
const router = useRouter()
const { loadFavorites, toggleFavorite, isFavorite, loaded } = useFavorites()

const isFav = computed(() => isFavorite(props.targetType, props.targetId))

onMounted(async () => {
  // Charge les favoris du user au premier mount si pas déjà fait
  if (auth.isAuthenticated && !loaded.value) {
    await loadFavorites()
  }
})

async function onClick(e: Event) {
  e.preventDefault()
  e.stopPropagation()

  // Si pas connecté → rediriger vers login avec retour
  if (!auth.isAuthenticated) {
    router.push({
      path: '/auth/login',
      query: { redirect: router.currentRoute.value.fullPath }
    })
    return
  }

  await toggleFavorite(props.targetType, props.targetId)
}
</script>

<template>
  <button
    type="button"
    class="fav-btn"
    :class="[`fav-btn-${size}`, { 'is-fav': isFav, 'is-floating': floating }]"
    :title="isFav ? 'Retirer des favoris' : 'Ajouter aux favoris'"
    :aria-label="isFav ? 'Retirer des favoris' : 'Ajouter aux favoris'"
    @click="onClick"
  >
    <svg
      viewBox="0 0 24 24"
      :fill="isFav ? 'currentColor' : 'none'"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
    >
      <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
    </svg>
  </button>
</template>

<style scoped>
.fav-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.92);
  border: 1px solid rgba(10, 31, 46, 0.08);
  color: rgba(10, 31, 46, 0.55);
  border-radius: 50%;
  cursor: pointer;
  transition: all 0.2s;
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  padding: 0;
}
.fav-btn:hover {
  color: #C04A3A;
  background: rgba(255, 255, 255, 1);
  transform: scale(1.1);
  box-shadow: 0 6px 18px rgba(192, 74, 58, 0.25);
}
.fav-btn.is-fav {
  color: #C04A3A;
  background: rgba(255, 255, 255, 0.96);
}
.fav-btn.is-fav:hover {
  transform: scale(1.1);
}

/* Tailles */
.fav-btn-sm { width: 32px; height: 32px; }
.fav-btn-sm svg { width: 16px; height: 16px; }
.fav-btn-md { width: 40px; height: 40px; }
.fav-btn-md svg { width: 18px; height: 18px; }
.fav-btn-lg { width: 48px; height: 48px; }
.fav-btn-lg svg { width: 22px; height: 22px; }

/* Mode "floating" : positionné en absolute en haut-droite */
.fav-btn.is-floating {
  position: absolute;
  top: 12px;
  right: 12px;
  z-index: 3;
}
</style>
