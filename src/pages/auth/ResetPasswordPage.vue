<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import AuthCard from '@/components/auth/AuthCard.vue'

const router = useRouter()
const auth = useAuthStore()

// Mode : 'request' (demander e-mail) ou 'update' (déjà connecté via lien)
const mode = computed(() => (auth.isAuthenticated ? 'update' : 'request'))

const email = ref('')
const newPassword = ref('')
const submitting = ref(false)
const successMsg = ref<string | null>(null)
const errorMsg = ref<string | null>(null)

async function handleRequest() {
  submitting.value = true
  errorMsg.value = null
  successMsg.value = null
  const { error } = await auth.requestPasswordReset(email.value.trim().toLowerCase())
  submitting.value = false
  if (error) {
    errorMsg.value = error
    return
  }
  successMsg.value = 'Si un compte existe avec cet e-mail, vous recevrez un lien de réinitialisation.'
}

async function handleUpdate() {
  submitting.value = true
  errorMsg.value = null
  const { error } = await auth.updatePassword(newPassword.value)
  submitting.value = false
  if (error) {
    errorMsg.value = error
    return
  }
  successMsg.value = 'Mot de passe mis à jour.'
  setTimeout(() => router.push('/mon-espace'), 1500)
}
</script>

<template>
  <AuthCard
    :title="mode === 'update' ? 'Nouveau mot de passe' : 'Mot de passe oublié ?'"
    :subtitle="mode === 'update' ? 'Choisissez un nouveau mot de passe sécurisé.' : 'Indiquez votre e-mail pour recevoir un lien.'"
    arabic-tag="استعادة"
  >
    <v-alert v-if="errorMsg" type="error" variant="tonal" class="mb-4">{{ errorMsg }}</v-alert>
    <v-alert v-if="successMsg" type="success" variant="tonal" class="mb-4">{{ successMsg }}</v-alert>

    <v-form v-if="mode === 'request'" @submit.prevent="handleRequest">
      <v-text-field
        v-model="email"
        label="E-mail"
        type="email"
        required
        density="comfortable"
        prepend-inner-icon="mdi-email-outline"
      />
      <v-btn type="submit" block size="large" color="primary" variant="flat" :loading="submitting" class="mt-3">
        Envoyer le lien
      </v-btn>
    </v-form>

    <v-form v-else @submit.prevent="handleUpdate">
      <v-text-field
        v-model="newPassword"
        label="Nouveau mot de passe (12 caractères min.)"
        type="password"
        required
        density="comfortable"
        prepend-inner-icon="mdi-lock-outline"
      />
      <v-btn type="submit" block size="large" color="primary" variant="flat" :loading="submitting" class="mt-3">
        Mettre à jour
      </v-btn>
    </v-form>

    <div class="auth-footer">
      <router-link to="/auth/login" class="auth-link-strong">← Retour à la connexion</router-link>
    </div>
  </AuthCard>
</template>

<style scoped>
.auth-link-strong {
  color: var(--c-primaire); font-weight: 700;
  text-decoration: none;
}
.auth-link-strong:hover { text-decoration: underline; }
.auth-footer {
  margin-top: var(--space-6);
  padding-top: var(--space-4);
  border-top: 1px solid var(--c-gris-clair);
  text-align: center;
  font-size: 14px;
}
</style>
