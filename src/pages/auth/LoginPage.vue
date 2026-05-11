<script setup lang="ts">
import { ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import AuthCard from '@/components/auth/AuthCard.vue'

const router = useRouter()
const route = useRoute()
const auth = useAuthStore()

const email = ref('')
const password = ref('')
const submitting = ref(false)
const errorMsg = ref<string | null>(null)
const showPassword = ref(false)

async function handleEmailLogin() {
  submitting.value = true
  errorMsg.value = null
  const { error } = await auth.signinWithEmail(email.value, password.value)
  submitting.value = false
  if (error) {
    errorMsg.value = mapAuthError(error)
    return
  }
  redirectAfterAuth()
}

async function handleGoogleLogin() {
  errorMsg.value = null
  const { error } = await auth.signinWithGoogle()
  if (error) errorMsg.value = mapAuthError(error)
  // Pas de redirect ici : Supabase redirige vers Google puis vers /auth/callback
}

function redirectAfterAuth() {
  const target = (route.query.redirect as string) || '/mon-espace'
  router.push(target)
}

function mapAuthError(err: string): string {
  if (err.includes('Invalid login')) return 'E-mail ou mot de passe incorrect.'
  if (err.includes('Email not confirmed')) return 'Confirmez d\'abord votre e-mail (vérifiez votre boîte).'
  if (err.includes('rate limit')) return 'Trop de tentatives — réessayez dans quelques minutes.'
  return err
}
</script>

<template>
  <AuthCard
    title="Bon retour parmi nous."
    subtitle="Connectez-vous pour retrouver vos voyages, vos favoris et vos itinéraires."
    arabic-tag="مرحبا بعودتكم"
  >
    <v-alert
      v-if="errorMsg"
      type="error"
      variant="tonal"
      density="comfortable"
      class="mb-4"
      closable
      @click:close="errorMsg = null"
    >
      {{ errorMsg }}
    </v-alert>

    <!-- OAuth Google -->
    <v-btn
      block
      size="large"
      variant="outlined"
      color="primary"
      class="mb-3 oauth-btn"
      :loading="submitting"
      @click="handleGoogleLogin"
    >
      <template #prepend>
        <svg width="18" height="18" viewBox="0 0 18 18">
          <path fill="#4285F4" d="M16.51 8H8.98v3h4.3c-.18 1-.74 1.48-1.6 2.04v2.01h2.6a7.8 7.8 0 0 0 2.38-5.88c0-.57-.05-.66-.15-1.18z"/>
          <path fill="#34A853" d="M8.98 17c2.16 0 3.97-.72 5.3-1.94l-2.6-2c-.71.48-1.64.78-2.7.78-2.06 0-3.81-1.39-4.44-3.27H1.83v2.07A8 8 0 0 0 8.98 17z"/>
          <path fill="#FBBC05" d="M4.54 10.58a4.8 4.8 0 0 1-.25-1.58c0-.55.1-1.08.25-1.58V5.35H1.83a8 8 0 0 0 0 7.3l2.7-2.07z"/>
          <path fill="#EA4335" d="M8.98 4.18c1.17 0 2.23.4 3.06 1.2l2.3-2.3A8 8 0 0 0 1.83 5.35L4.54 7.4c.63-1.89 2.38-3.22 4.44-3.22z"/>
        </svg>
      </template>
      Continuer avec Google
    </v-btn>

    <div class="auth-divider"><span>ou avec votre e-mail</span></div>

    <v-form @submit.prevent="handleEmailLogin">
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
        v-model="password"
        label="Mot de passe"
        :type="showPassword ? 'text' : 'password'"
        autocomplete="current-password"
        required
        density="comfortable"
        prepend-inner-icon="mdi-lock-outline"
        :append-inner-icon="showPassword ? 'mdi-eye-off' : 'mdi-eye'"
        @click:append-inner="showPassword = !showPassword"
      />

      <div class="auth-row-end">
        <router-link to="/auth/reset-password" class="auth-link">
          Mot de passe oublié ?
        </router-link>
      </div>

      <v-btn
        type="submit"
        block
        size="large"
        color="primary"
        variant="flat"
        :loading="submitting"
        class="mt-4"
      >
        Se connecter
      </v-btn>
    </v-form>

    <div class="auth-footer">
      Pas encore de compte ?
      <router-link to="/auth/signup" class="auth-link-strong">Rejoindre Djawal</router-link>
    </div>
  </AuthCard>
</template>

<style scoped>
.oauth-btn {
  letter-spacing: 0.02em;
  text-transform: none !important;
  font-weight: 500;
}
.auth-divider {
  display: flex;
  align-items: center;
  margin: var(--space-4) 0;
  color: var(--c-texte-doux);
  font-size: 13px;
}
.auth-divider::before, .auth-divider::after {
  content: '';
  flex: 1;
  height: 1px;
  background: var(--c-gris-clair);
}
.auth-divider span { margin: 0 var(--space-3); }
.auth-row-end {
  display: flex;
  justify-content: flex-end;
  margin: -8px 0 var(--space-2);
}
.auth-link {
  color: var(--c-accent-fort);
  font-size: 13px;
  text-decoration: none;
  font-weight: 500;
}
.auth-link:hover { text-decoration: underline; }
.auth-link-strong {
  color: var(--c-primaire);
  font-weight: 700;
  text-decoration: none;
  margin-left: 6px;
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
</style>
