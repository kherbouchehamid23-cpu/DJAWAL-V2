import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import type { User, Session } from '@supabase/supabase-js'

export type AppRole = 'super_admin' | 'guide_senior' | 'guide_junior' | 'voyageur'
export type KycStatus = 'not_required' | 'pending' | 'approved' | 'rejected'

export interface Profile {
  id: string
  role: AppRole
  display_name: string
  bio: string | null
  region: string | null
  avatar_url: string | null
  kyc_status: KycStatus
  kyc_reviewed_at: string | null
  is_active: boolean
}

export interface SignupPayload {
  email: string
  password: string
  display_name: string
  role: 'voyageur' | 'guide_junior'
  region?: string
}

/**
 * Auth store complet : signin/signup email + OAuth Google,
 * synchronisation du profile, vérification de session, signout.
 * Les permissions par rôle sont appliquées par RLS PostgreSQL côté backend.
 */
export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const session = ref<Session | null>(null)
  const profile = ref<Profile | null>(null)
  const loading = ref<boolean>(true)
  const lastError = ref<string | null>(null)

  // === Computed ===
  const isAuthenticated = computed(() => !!user.value)
  const role = computed<AppRole | null>(() => profile.value?.role ?? null)
  const isAdmin = computed(() => role.value === 'super_admin')
  const isGuide = computed(() => role.value === 'guide_senior' || role.value === 'guide_junior')
  const isGuideSenior = computed(() => role.value === 'guide_senior')
  const isGuideJunior = computed(() => role.value === 'guide_junior')
  const isVoyageur = computed(() => role.value === 'voyageur')
  const needsKyc = computed(() =>
    isGuide.value && profile.value?.kyc_status === 'pending'
  )
  const kycRejected = computed(() => profile.value?.kyc_status === 'rejected')

  // === Méthodes ===

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
    if (!error && data) {
      profile.value = data as Profile
    } else if (error) {
      console.warn('[auth] fetchProfile error:', error.message)
    }
  }

  async function initialize() {
    loading.value = true
    const { data: { session: existingSession } } = await supabase.auth.getSession()
    session.value = existingSession
    user.value = existingSession?.user ?? null
    await fetchProfile()

    supabase.auth.onAuthStateChange(async (_event, newSession) => {
      session.value = newSession
      user.value = newSession?.user ?? null
      await fetchProfile()
    })
    loading.value = false
  }

  // === Sign up email + password ===
  async function signupWithEmail(payload: SignupPayload): Promise<{ error: string | null }> {
    lastError.value = null
    const { data, error } = await supabase.auth.signUp({
      email: payload.email,
      password: payload.password,
      options: {
        emailRedirectTo: `${window.location.origin}/auth/callback`,
        data: {
          display_name: payload.display_name,
          role: payload.role,
          region: payload.region ?? null
        }
      }
    })
    if (error) {
      lastError.value = error.message
      return { error: error.message }
    }
    user.value = data.user
    session.value = data.session
    await fetchProfile()
    return { error: null }
  }

  // === Sign in email + password ===
  async function signinWithEmail(email: string, password: string): Promise<{ error: string | null }> {
    lastError.value = null
    const { data, error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) {
      lastError.value = error.message
      return { error: error.message }
    }
    user.value = data.user
    session.value = data.session
    await fetchProfile()
    return { error: null }
  }

  // === OAuth Google ===
  async function signinWithGoogle(): Promise<{ error: string | null }> {
    lastError.value = null
    const { error } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: `${window.location.origin}/auth/callback`,
        queryParams: { access_type: 'offline', prompt: 'consent' }
      }
    })
    if (error) {
      lastError.value = error.message
      return { error: error.message }
    }
    return { error: null }
  }

  // === Magic Link (alternative sans mot de passe) ===
  async function signinWithMagicLink(email: string): Promise<{ error: string | null }> {
    lastError.value = null
    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: { emailRedirectTo: `${window.location.origin}/auth/callback` }
    })
    if (error) {
      lastError.value = error.message
      return { error: error.message }
    }
    return { error: null }
  }

  // === Sign out ===
  async function signOut() {
    await supabase.auth.signOut()
    user.value = null
    session.value = null
    profile.value = null
  }

  // === Reset password ===
  async function requestPasswordReset(email: string): Promise<{ error: string | null }> {
    lastError.value = null
    const { error } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: `${window.location.origin}/auth/reset-password`
    })
    if (error) {
      lastError.value = error.message
      return { error: error.message }
    }
    return { error: null }
  }

  async function updatePassword(newPassword: string): Promise<{ error: string | null }> {
    lastError.value = null
    const { error } = await supabase.auth.updateUser({ password: newPassword })
    if (error) {
      lastError.value = error.message
      return { error: error.message }
    }
    return { error: null }
  }

  async function updateProfile(updates: Partial<Profile>): Promise<{ error: string | null }> {
    if (!user.value) return { error: 'Non authentifié' }
    const { error } = await supabase
      .from('profiles')
      .update(updates)
      .eq('id', user.value.id)
    if (error) return { error: error.message }
    await fetchProfile()
    return { error: null }
  }

  return {
    // state
    user, session, profile, loading, lastError,
    // computed
    isAuthenticated, role, isAdmin, isGuide, isGuideSenior, isGuideJunior, isVoyageur,
    needsKyc, kycRejected,
    // methods
    initialize, fetchProfile,
    signupWithEmail, signinWithEmail, signinWithGoogle, signinWithMagicLink,
    signOut, requestPasswordReset, updatePassword, updateProfile
  }
})
