import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import type { User } from '@supabase/supabase-js'

export type AppRole = 'super_admin' | 'guide_senior' | 'guide_junior' | 'voyageur'

export interface Profile {
  id: string
  role: AppRole
  display_name: string
  bio: string | null
  region: string | null
  avatar_url: string | null
  kyc_status: 'not_required' | 'pending' | 'approved' | 'rejected'
  is_active: boolean
}

/**
 * Gère l'état d'authentification + profil utilisateur étendu.
 * Le profil est joint à auth.users via une foreign key dans la table `profiles`.
 */
export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const profile = ref<Profile | null>(null)
  const loading = ref<boolean>(true)

  const isAuthenticated = computed(() => !!user.value)
  const role = computed<AppRole | null>(() => profile.value?.role ?? null)
  const isAdmin = computed(() => role.value === 'super_admin')
  const isGuide = computed(() => role.value === 'guide_senior' || role.value === 'guide_junior')
  const isVoyageur = computed(() => role.value === 'voyageur')

  async function fetchProfile() {
    if (!user.value) {
      profile.value = null
      return
    }
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', user.value.id)
      .single()
    if (!error && data) profile.value = data as Profile
  }

  async function initialize() {
    loading.value = true
    const { data: { session } } = await supabase.auth.getSession()
    user.value = session?.user ?? null
    await fetchProfile()

    supabase.auth.onAuthStateChange(async (_event, newSession) => {
      user.value = newSession?.user ?? null
      await fetchProfile()
    })
    loading.value = false
  }

  async function signOut() {
    await supabase.auth.signOut()
    user.value = null
    profile.value = null
  }

  return {
    user, profile, loading,
    isAuthenticated, role, isAdmin, isGuide, isVoyageur,
    initialize, fetchProfile, signOut
  }
})
