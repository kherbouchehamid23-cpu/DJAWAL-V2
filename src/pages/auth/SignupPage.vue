<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import AuthCard from '@/components/auth/AuthCard.vue'

const router = useRouter()
const route = useRoute()
const auth = useAuthStore()

// Détection du rôle initial depuis l'URL (?role=guide)
const initialRoleQuery = route.query.role as string | undefined
const role = ref<'voyageur' | 'guide_junior'>(
  initialRoleQuery === 'guide' ? 'guide_junior' : 'voyageur'
)

const displayName = ref('')
const email = ref('')
const password = ref('')
const region = ref('')
const acceptTerms = ref(false)
const showPassword = ref(false)
const submitting = ref(false)
const errorMsg = ref<string | null>(null)
const successMsg = ref<string | null>(null)

const passwordStrength = computed(() => {
  const p = password.value
  if (p.length < 8) return { score: 0, label: 'Trop court', color: 'error' }
  if (p.length < 12) return { score: 1, label: 'Faible', color: 'warning' }
  const hasLetter = /[a-zA-Z]/.test(p)
  const hasNumber = /\d/.test(p)
  const hasSpecial = /[^a-zA-Z\d]/.test(p)
  const score = [hasLetter, hasNumber, hasSpecial].filter(Boolean).length
  if (score >= 3) return { score: 3, label: 'Fort', color: 'success' }
  if (score === 2) return { score: 2, label: 'Moyen', color: 'warning' }
  return { score: 1, label: 'Faible', color: 'warning' }
})

const canSubmit = computed(() =>
  displayName.value.length >= 2 &&
  email.value.includes('@') &&
  password.value.length >= 12 &&
  acceptTerms.value &&
  !submitting.value
)

async function handleSignup() {
  submitting.value = true
  errorMsg.value = null
  successMsg.value = null

  const { error } = await auth.signupWithEmail({
    email: email.value.trim().toLowerCase(),
    password: password.value,
    display_name: displayName.value.trim(),
    role: role.value,
    region: region.value.trim() || undefined
  })

  submitting.value = false

  if (error) {
    errorMsg.value = mapAuthError(error)
    return
  }

  // Si confirmation e-mail requise (par défaut Supabase)
  if (!auth.session) {
    router.push({ name: 'auth-confirm', query: { email: email.value } })
  } else {
    // Auto-login (si confirmation désactivée)
    if (role.value === 'guide_junior') {
      router.push({ name: 'guide-kyc' })
    } else {
      router.push('/mon-espace')
    }
  }
}

async function handleGoogleSignup() {
  errorMsg.value = null
  const { error } = await auth.signinWithGoogle()
  if (error) errorMsg.value = mapAuthError(error)
}

function mapAuthError(err: string): string {
  if (err.includes('already registered') || err.includes('already exists'))
    return 'Cet e-mail est déjà utilisé. Connectez-vous plutôt.'
  if (err.includes('weak password')) return 'Mot de passe trop faible (12 caractères minimum).'
  if (err.includes('rate limit')) return 'Trop de tentatives — réessayez dans quelques minutes.'
  return err
}
</script>

<template>
  <AuthCard
    title="Nous rejoindre."
    subtitle="Créez votre compte en 1 minute pour explorer l'Algérie autrement."
    arabic-tag="انضموا إلينا"
  >
    <v-alert v-if="errorMsg" type="error" variant="tonal" class="mb-4" closable>
      {{ errorMsg }}
    </v-alert>

    <!-- Choix du rôle -->
    <div class="role-selector">
      <button
        type="button"
        class="role-btn"
        :class="{ active: role === 'voyageur' }"
        @click="role = 'voyageur'"
      >
        <span class="role-icon">🧳</span>
        <span class="role-label">Je suis voyageur</span>
        <span class="role-desc">Découvrir l'Algérie</span>
      </button>
      <button
        type="button"
        class="role-btn"
        :class="{ active: role === 'guide_junior' }"
        @click="role = 'guide_junior'"
      >
        <span class="role-icon">🎒</span>
        <span class="role-label">Je suis guide</span>
        <span class="role-desc">Partager mes itinéraires</span>
      </button>
    </div>

    <v-btn
      block
      size="large"
      variant="outlined"
      color="primary"
      class="mb-3 oauth-btn"
      @click="handleGoogleSignup"
    >
      <template #prepend>
        <svg width="18" height="18" viewBox="0 0 18 18">
          <path fill="#4285F4" d="M16.51 8H8.98v3h4.3c-.18 1-.74 1.48-1.6 2.04v2.01h2.6a7.8 7.8 0 0 0 2.38-5.88c0-.57-.05-.66-.15-1.18z"/>
          <path fill="#34A853" d="M8.98 17c2.16 0 3.97-.72 5.3-1.94l-2.6-2c-.71.48-1.64.78-2.7.78-2.06 0-3.81-1.39-4.44-3.27H1.83v2.07A8 8 0 0 0 8.98 17z"/>
          <path fill="#FBBC05" d="M4.54 10.58a4.8 4.8 0 0 1-.25-1.58c0-.55.1-1.08.25-1.58V5.35H1.83a8 8 0 0 0 0 7.3l2.7-2.07z"/>
          <path fill="#EA4335" d="M8.98 4.18c1.17 0 2.23.4 3.06 1.2l2.3-2.3A8 8 0 0 0 1.83 5.35L4.54 7.4c.63-1.89 2.38-3.22 4.44-3.22z"/>
        </svg>
      </template>
      S'inscrire avec Google
    </v-btn>

    <div class="auth-divider"><span>ou avec votre e-mail</span></div>

    <v-form @submit.prevent="handleSignup">
      <v-text-field
        v-model="displayName"
        label="Nom d'affichage"
        autocomplete="name"
        required
        density="comfortable"
        prepend-inner-icon="mdi-account-outline"
        hint="Tel qu'il apparaîtra sur vos publications"
      />
      <v-text-field
        v-model="email"
        label="E-mail"
        type="email"
        autocomplete="email"
        required
        density="comfortable"
        prepend-inner-icon="mdi-email-outline"
      />
      <v-text-field
        v-if="role === 'guide_junior'"
        v-model="region"
        label="Région de compétence"
        density="comfortable"
        prepend-inner-icon="mdi-map-marker-outline"
        hint="Ex : Tassili, Kabylie, Algérois…"
      />
      <v-text-field
        v-model="password"
        label="Mot de passe (12 caractères min.)"
        :type="showPassword ? 'text' : 'password'"
        autocomplete="new-password"
        required
        density="comfortable"
        prepend-inner-icon="mdi-lock-outline"
        :append-inner-icon="showPassword ? 'mdi-eye-off' : 'mdi-eye'"
        @click:append-inner="showPassword = !showPassword"
      />

      <div v-if="password.length > 0" class="strength-bar">
        <div
          v-for="i in 3" :key="i"
          class="strength-seg"
          :class="{
            'filled-error': passwordStrength.score >= i && passwordStrength.color === 'error',
            'filled-warning': passwordStrength.score >= i && passwordStrength.color === 'warning',
            'filled-success': passwordStrength.score >= i && passwordStrength.color === 'success'
          }"
        />
        <span class="strength-label">{{ passwordStrength.label }}</span>
      </div>

      <v-checkbox
        v-model="acceptTerms"
        density="compact"
        class="mt-2"
      >
        <template #label>
          J'accepte les
          <router-link to="/cgu" class="auth-link" target="_blank">conditions générales</router-link>
          et la
          <router-link to="/mentions-legales#confidentialite" class="auth-link" target="_blank">politique de confidentialité</router-link>.
        </template>
      </v-checkbox>

      <v-btn
        type="submit"
        block
        size="large"
        color="primary"
        variant="flat"
        :loading="submitting"
        :disabled="!canSubmit"
        class="mt-2"
      >
        Créer mon compte
      </v-btn>

      <p v-if="role === 'guide_junior'" class="role-info">
        ℹ️ En tant que guide, vous serez invité à compléter une vérification KYC après inscription.
      </p>
    </v-form>

    <div class="auth-footer">
      Déjà un compte ?
      <router-link to="/auth/login" class="auth-link-strong">Se connecter</router-link>
    </div>
  </AuthCard>
</template>

<style scoped>
.role-selector {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--space-3);
  margin-bottom: var(--space-5);
}
.role-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  padding: var(--space-4) var(--space-3);
  background: var(--c-fond-chaud);
  border: 2px solid transparent;
  border-radius: var(--r-md);
  cursor: pointer;
  transition: var(--t-base);
  font-family: inherit;
}
.role-btn:hover { border-color: var(--c-accent); }
.role-btn.active {
  border-color: var(--c-primaire);
  background: var(--c-surface);
  box-shadow: var(--ombre-douce);
}
.role-icon { font-size: 32px; margin-bottom: 6px; }
.role-label {
  font-weight: 700;
  color: var(--c-primaire-profond);
  font-size: 14px;
}
.role-desc {
  font-size: 11px;
  color: var(--c-texte-doux);
  margin-top: 2px;
}
.oauth-btn {
  letter-spacing: 0.02em;
  text-transform: none !important;
  font-weight: 500;
}
.auth-divider {
  display: flex; align-items: center;
  margin: var(--space-4) 0;
  color: var(--c-texte-doux); font-size: 13px;
}
.auth-divider::before, .auth-divider::after {
  content: ''; flex: 1; height: 1px; background: var(--c-gris-clair);
}
.auth-divider span { margin: 0 var(--space-3); }
.strength-bar {
  display: flex; gap: 4px; align-items: center;
  margin: 4px 0 12px;
}
.strength-seg {
  flex: 1; height: 4px; border-radius: 2px;
  background: var(--c-gris-clair);
}
.strength-seg.filled-error { background: #C04A3A; }
.strength-seg.filled-warning { background: #D4A04F; }
.strength-seg.filled-success { background: #6B7A4A; }
.strength-label {
  font-size: 11px;
  color: var(--c-texte-doux);
  margin-left: 8px;
  min-width: 60px;
}
.auth-link { color: var(--c-accent-fort); font-weight: 500; text-decoration: none; }
.auth-link:hover { text-decoration: underline; }
.auth-link-strong {
  color: var(--c-primaire); font-weight: 700;
  text-decoration: none; margin-left: 6px;
}
.auth-link-strong:hover { text-decoration: underline; }
.auth-footer {
  margin-top: var(--space-6);
  padding-top: var(--space-4);
  border-top: 1px solid var(--c-gris-clair);
  text-align: center;
  color: var(--c-texte-doux);
  font-size: 14px;
}
.role-info {
  margin-top: var(--space-3);
  padding: var(--space-3);
  background: var(--c-fond-chaud);
  border-left: 3px solid var(--c-accent);
  border-radius: 4px;
  font-size: 13px;
  color: var(--c-texte);
}
</style>
