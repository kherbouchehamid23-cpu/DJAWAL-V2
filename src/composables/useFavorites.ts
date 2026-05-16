import { ref } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

/**
 * Composable global pour gérer les favoris polymorphiques du voyageur courant.
 *
 * Table backend : `user_favorites` (target_type + target_id)
 *
 * - Charge la liste des favoris (tout type) une seule fois en mémoire
 * - Expose isFavorite(type, id) et toggleFavorite(type, id)
 * - Rétro-compat : si on passe juste un ID en string, on assume target_type='trip'
 */

export type FavoriteTarget =
  | 'trip'
  | 'destination'
  | 'accommodation'
  | 'site'
  | 'restaurant'
  | 'activity'
  | 'guide'
  | 'operator'
  | 'memory'

interface FavoriteKey {
  target_type: FavoriteTarget
  target_id: string
}

// Stockage : Set de clés "type:id" pour lookup O(1)
const favoriteKeys = ref<Set<string>>(new Set())
const loaded = ref(false)
const loading = ref(false)

function makeKey(target_type: FavoriteTarget, target_id: string): string {
  return `${target_type}:${target_id}`
}

async function loadFavorites() {
  const auth = useAuthStore()
  if (!auth.user) {
    favoriteKeys.value = new Set()
    loaded.value = true
    return
  }
  loading.value = true
  const { data, error } = await supabase
    .from('user_favorites')
    .select('target_type, target_id')
    .eq('user_id', auth.user.id)
  if (!error && data) {
    favoriteKeys.value = new Set(
      data.map((r: any) => makeKey(r.target_type, r.target_id))
    )
  }
  loaded.value = true
  loading.value = false
}

/**
 * Toggle un favori. Retourne le NOUVEL état (true = favori, false = non-favori).
 * Usage :
 *   - toggleFavorite('trip', tripId)
 *   - toggleFavorite('destination', destId)
 *   - toggleFavorite(tripId)  ← rétro-compat, assume 'trip'
 */
async function toggleFavorite(
  arg1: FavoriteTarget | string,
  arg2?: string
): Promise<boolean> {
  const auth = useAuthStore()
  if (!auth.user) return false

  // Rétro-compat : si un seul argument, c'est un trip_id
  let target_type: FavoriteTarget
  let target_id: string
  if (arg2 === undefined) {
    target_type = 'trip'
    target_id = arg1 as string
  } else {
    target_type = arg1 as FavoriteTarget
    target_id = arg2
  }

  const key = makeKey(target_type, target_id)
  const isFav = favoriteKeys.value.has(key)

  if (isFav) {
    const { error } = await supabase
      .from('user_favorites')
      .delete()
      .eq('user_id', auth.user.id)
      .eq('target_type', target_type)
      .eq('target_id', target_id)
    if (error) {
      console.error('[favorites] delete error:', error.message)
      return true // état non changé
    }
    favoriteKeys.value.delete(key)
    favoriteKeys.value = new Set(favoriteKeys.value)
    return false
  } else {
    const { error } = await supabase
      .from('user_favorites')
      .insert({
        user_id: auth.user.id,
        target_type,
        target_id
      })
    if (error) {
      console.error('[favorites] insert error:', error.message)
      return false
    }
    favoriteKeys.value.add(key)
    favoriteKeys.value = new Set(favoriteKeys.value)
    return true
  }
}

/**
 * Vérifie si un élément est favori.
 * Usage :
 *   - isFavorite('trip', tripId)
 *   - isFavorite(tripId)  ← rétro-compat, assume 'trip'
 */
function isFavorite(
  arg1: FavoriteTarget | string,
  arg2?: string
): boolean {
  let target_type: FavoriteTarget
  let target_id: string
  if (arg2 === undefined) {
    target_type = 'trip'
    target_id = arg1 as string
  } else {
    target_type = arg1 as FavoriteTarget
    target_id = arg2
  }
  return favoriteKeys.value.has(makeKey(target_type, target_id))
}

/**
 * Retourne tous les favoris d'un type donné (ex : tous les trips favoris).
 */
function favoritesByType(target_type: FavoriteTarget): string[] {
  const prefix = `${target_type}:`
  return Array.from(favoriteKeys.value)
    .filter(k => k.startsWith(prefix))
    .map(k => k.substring(prefix.length))
}

function resetFavorites() {
  favoriteKeys.value = new Set()
  loaded.value = false
}

// Alias rétro-compat pour les anciens appels qui veulent les ids des trips favoris
const favoriteIds = ref<Set<string>>(new Set())

export function useFavorites() {
  // Synchronise favoriteIds (trips uniquement) pour rétro-compat
  favoriteIds.value = new Set(favoritesByType('trip'))
  return {
    favoriteKeys,
    favoriteIds, // rétro-compat (= trips uniquement)
    loaded,
    loading,
    loadFavorites,
    toggleFavorite,
    isFavorite,
    favoritesByType,
    resetFavorites
  }
}
