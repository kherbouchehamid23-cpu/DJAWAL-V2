<script setup lang="ts">
import { onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const auth = useAuthStore()

onMounted(async () => {
  // Supabase parse automatiquement le hash/code dans l'URL (detectSessionInUrl: true)
  // On attend que la session soit installée
  await new Promise(r => setTimeout(r, 800))
  const { data: { session } } = await supabase.auth.getSession()

  if (!session) {
    router.replace({ name: 'login', query: { error: 'callback-failed' } })
    return
  }

  await auth.fetchProfile()

  // Redirection selon le rôle
  if (auth.role === 'guide_junior' && auth.profile?.kyc_status === 'pending') {
    router.replace({ name: 'guide-kyc' })
  } else if (auth.role === 'guide_senior' || auth.role === 'guide_junior') {
    router.replace({ name: 'guide-dashboard' })
  } else if (auth.role === 'super_admin') {
    router.replace({ name: 'admin-dashboard' })
  } else {
    router.replace({ name: 'my-account' })
  }
})
</script>

<template>
  <div class="callback-wrap">
    <div class="callback-card">
      <div class="spinner" />
      <h2>Authentification en cours…</h2>
      <p>Encore quelques secondes — nous installons votre session.</p>
    </div>
  </div>
</template>

<style scoped>
.callback-wrap {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--c-fond);
  background-image: var(--motif-principal-url);
  background-position: center;
}
.callback-card {
  background: var(--c-surface);
  padding: var(--space-7) var(--space-6);
  border-radius: var(--r-lg);
  box-shadow: var(--ombre-elevee);
  text-align: center;
  max-width: 360px;
}
.spinner {
  width: 56px; height: 56px;
  border: 4px solid var(--c-gris-clair);
  border-top-color: var(--c-accent);
  border-radius: 50%;
  margin: 0 auto var(--space-4);
  animation: spin 0.8s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }
h2 {
  font-family: var(--font-display);
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-2);
}
p { color: var(--c-texte-doux); font-size: 14px; }
</style>
