import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

/**
 * Composable global pour gérer les favoris du voyageur courant.
 * - Charge la liste des trip_ids favoris une seule fois en mémoire
 * - Expose isFavorite(tripId) et toggleFavorite(tripId)
 * - Sync avec la table `favorites` côté Supabase
 */

const favoriteIds = ref<Set<string>>(new Set())
const loaded = ref(false)
const loading = ref(false)

async function loadFavorites() {
  const auth = useAuthStore()
  if (!auth.user) {
    favoriteIds.value = new Set()
    loaded.value = true
    return
  }
  loading.value = true
  const { data, error } = await supabase
    .from('favorites')
    .select('trip_id')
    .eq('user_id', auth.user.id)
  if (!error && data) {
    favoriteIds.value = new Set(data.map((r: any) => r.trip_id))
  }
  loaded.value = true
  loading.value = false
}

async function toggleFavorite(tripId: string): Promise<boolean> {
  const auth = useAuthStore()
  if (!auth.user) return false

  const isFav = favoriteIds.value.has(tripId)
  if (isFav) {
    const { error } = await supabase
      .from('favorites')
      .delete()
      .eq('user_id', auth.user.id)
      .eq('trip_id', tripId)
    if (error) {
      console.error('[favorites] toggle delete error:', error.message)
      return true // état non changé
    }
    favoriteIds.value.delete(tripId)
    favoriteIds.value = new Set(favoriteIds.value)
    return false
  } else {
    const { error } = await supabase
      .from('favorites')
      .insert({ user_id: auth.user.id, trip_id: tripId })
    if (error) {
      console.error('[favorites] toggle insert error:', error.message)
      return false
    }
    favoriteIds.value.add(tripId)
    favoriteIds.value = new Set(favoriteIds.value)
    return true
  }
}

function isFavorite(tripId: string): boolean {
  return favoriteIds.value.has(tripId)
}

function resetFavorites() {
  favoriteIds.value = new Set()
  loaded.value = false
}

export function useFavorites() {
  return {
    favoriteIds,
    loaded,
    loading,
    loadFavorites,
    toggleFavorite,
    isFavorite,
    resetFavorites
  }
}
