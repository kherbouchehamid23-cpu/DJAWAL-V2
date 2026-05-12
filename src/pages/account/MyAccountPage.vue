<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import ImageUpload from '@/components/admin/ImageUpload.vue'

const auth = useAuthStore()
const displayName = ref('')
const bio = ref('')
const region = ref('')
const avatarUrl = ref<string | null>(null)
const saving = ref(false)
const savedMsg = ref<string | null>(null)
const errorMsg = ref<string | null>(null)

onMounted(() => {
  if (auth.profile) {
    displayName.value = auth.profile.display_name ?? ''
    bio.value = auth.profile.bio ?? ''
    region.value = auth.profile.region ?? ''
    avatarUrl.value = auth.profile.avatar_url ?? null
  }
})

async function handleSave() {
  saving.value = true
  errorMsg.value = null
  savedMsg.value = null
  const { error } = await auth.updateProfile({
    display_name: displayName.value.trim(),
    bio: bio.value.trim() || null,
    region: region.value.trim() || null,
    avatar_url: avatarUrl.value
  })
  saving.value = false
  if (error) {
    errorMsg.value = error
    return
  }
  savedMsg.value = 'Profil mis à jour.'
  setTimeout(() => (savedMsg.value = null), 3000)
}

const roleLabel: Record<string, string> = {
  super_admin: '👑 Super Admin',
  guide_senior: '🎒 Guide Senior',
  guide_junior: '🎒 Guide Junior',
  voyageur: '🧳 Voyageur'
}

const kycLabel: Record<string, { text: string; color: string }> = {
  not_required: { text: 'Non requise', color: 'grey' },
  pending: { text: 'En attente de validation', color: 'warning' },
  approved: { text: 'Vérifié ✓', color: 'success' },
  rejected: { text: 'Rejetée', color: 'error' }
}
</script>

<template>
  <div class="djawal-container djawal-section">
    <header class="my-header">
      <div>
        <div class="section-eyebrow">Mon espace</div>
        <h1>Bonjour, {{ auth.profile?.display_name || 'voyageur' }}.</h1>
      </div>
      <div class="role-pill" :data-role="auth.role">{{ roleLabel[auth.role || 'voyageur'] }}</div>
    </header>

    <!-- KYC Banner for guides -->
    <v-alert
      v-if="auth.needsKyc"
      type="warning"
      variant="tonal"
      class="mb-6"
      prominent
    >
      <template #title>Vérification KYC requise</template>
      Pour publier des parcours sur Djawal, vous devez compléter la vérification d'identité.
      <template #append>
        <router-link to="/espace-guide/kyc">
          <v-btn color="warning" variant="flat" size="small">Compléter</v-btn>
        </router-link>
      </template>
    </v-alert>

    <v-alert v-if="auth.kycRejected" type="error" variant="tonal" class="mb-6">
      Votre dossier KYC a été rejeté. Contactez le support pour plus d'informations.
    </v-alert>

    <div class="my-grid">
      <!-- Profil -->
      <section class="card">
        <h2>Profil</h2>
        <v-alert v-if="errorMsg" type="error" variant="tonal" class="mb-3">{{ errorMsg }}</v-alert>
        <v-alert v-if="savedMsg" type="success" variant="tonal" class="mb-3">{{ savedMsg }}</v-alert>

        <v-form @submit.prevent="handleSave">
          <ImageUpload
            v-model="avatarUrl"
            bucket="avatars"
            label="Photo de profil"
          />
          <v-text-field
            v-model="displayName"
            label="Nom d'affichage"
            density="comfortable"
            required
          />
          <v-textarea
            v-model="bio"
            label="Bio"
            density="comfortable"
            rows="3"
            counter
            maxlength="280"
            hint="280 caractères max."
          />
          <v-text-field
            v-model="region"
            label="Région"
            density="comfortable"
            hint="Ex : Alger, Kabylie, Tassili…"
          />
          <v-text-field
            :model-value="auth.user?.email"
            label="E-mail"
            density="comfortable"
            readonly
            hint="Pour changer d'e-mail, contactez le support"
            prepend-inner-icon="mdi-email-outline"
          />

          <div class="kyc-row" v-if="auth.profile">
            <span>Statut KYC :</span>
            <v-chip
              :color="kycLabel[auth.profile.kyc_status].color"
              size="small"
              variant="tonal"
            >
              {{ kycLabel[auth.profile.kyc_status].text }}
            </v-chip>
          </div>

          <v-btn
            type="submit"
            color="primary"
            variant="flat"
            size="large"
            :loading="saving"
            class="mt-3"
          >
            Sauvegarder
          </v-btn>
        </v-form>
      </section>

      <!-- Sidebar : navigation rapide -->
      <aside class="sidebar">
        <h3>Accès rapide</h3>
        <ul class="quick-links">
          <li>
            <router-link to="/mon-espace/favoris">
              <span class="link-icon">❤️</span>
              <div>
                <strong>Mes favoris</strong>
                <small>Voyages sauvegardés</small>
              </div>
            </router-link>
          </li>
          <li>
            <router-link to="/mon-espace/souvenirs">
              <span class="link-icon">✨</span>
              <div>
                <strong>Mes souvenirs</strong>
                <small>Récits & témoignages</small>
              </div>
            </router-link>
          </li>
          <li>
            <router-link to="/mon-espace/avis">
              <span class="link-icon">⭐</span>
              <div>
                <strong>Mes avis</strong>
                <small>Vos notes & commentaires</small>
              </div>
            </router-link>
          </li>
          <li v-if="auth.isGuide">
            <router-link to="/espace-guide">
              <span class="link-icon">🎒</span>
              <div>
                <strong>Mon espace guide</strong>
                <small>Mes parcours et publications</small>
              </div>
            </router-link>
          </li>
          <li v-if="auth.isAdmin">
            <router-link to="/admin">
              <span class="link-icon">👑</span>
              <div>
                <strong>Administration</strong>
                <small>Modération, master data, KYC</small>
              </div>
            </router-link>
          </li>
          <li>
            <router-link to="/voyages">
              <span class="link-icon">🗺️</span>
              <div>
                <strong>Catalogue voyages</strong>
                <small>Explorer les itinéraires</small>
              </div>
            </router-link>
          </li>
          <li>
            <router-link to="/temoignages">
              <span class="link-icon">💬</span>
              <div>
                <strong>Mur des souvenirs</strong>
                <small>Témoignages communauté</small>
              </div>
            </router-link>
          </li>
        </ul>

        <v-btn block variant="outlined" color="error" @click="auth.signOut" class="mt-4">
          Se déconnecter
        </v-btn>
      </aside>
    </div>
  </div>
</template>

<style scoped>
.my-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  margin-bottom: var(--space-6);
  flex-wrap: wrap;
  gap: var(--space-3);
}
.section-eyebrow {
  color: var(--c-accent-fort);
  font-size: 13px;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  font-weight: 700;
  margin-bottom: var(--space-2);
}
.my-header h1 {
  font-size: clamp(32px, 4vw, 48px);
  color: var(--c-primaire-profond);
}
.role-pill {
  padding: 8px 16px;
  background: var(--c-fond-chaud);
  border-radius: var(--r-pill);
  font-weight: 600;
  color: var(--c-primaire-profond);
  font-size: 14px;
}
.role-pill[data-role="super_admin"] { background: linear-gradient(135deg, #D4A04F, #B8862E); color: white; }
.role-pill[data-role="guide_senior"] { background: var(--c-primaire); color: var(--c-fond); }

.my-grid {
  display: grid;
  grid-template-columns: 1.5fr 1fr;
  gap: var(--space-6);
}
.card {
  background: var(--c-surface);
  padding: var(--space-6);
  border-radius: var(--r-lg);
  box-shadow: var(--ombre-douce);
}
.card h2 {
  font-family: var(--font-display);
  font-size: 28px;
  margin-bottom: var(--space-4);
}
.kyc-row {
  display: flex; align-items: center; gap: var(--space-3);
  margin: var(--space-3) 0;
  font-size: 14px; color: var(--c-texte-doux);
}
.sidebar {
  background: var(--c-fond-chaud);
  padding: var(--space-5);
  border-radius: var(--r-lg);
}
.sidebar h3 {
  font-family: var(--font-display);
  font-size: 22px;
  margin-bottom: var(--space-3);
  color: var(--c-primaire-profond);
}
.quick-links {
  list-style: none; padding: 0; margin: 0;
}
.quick-links li { margin-bottom: var(--space-2); }
.quick-links a {
  display: flex; align-items: center; gap: 12px;
  padding: var(--space-3);
  background: var(--c-surface);
  border-radius: var(--r-md);
  text-decoration: none;
  color: var(--c-texte);
  transition: var(--t-base);
  border-left: 3px solid transparent;
}
.quick-links a:hover {
  border-left-color: var(--c-accent);
  transform: translateX(2px);
}
.link-icon { font-size: 24px; }
.quick-links strong { display: block; color: var(--c-primaire-profond); }
.quick-links small { color: var(--c-texte-doux); font-size: 12px; }

@media (max-width: 880px) {
  .my-grid { grid-template-columns: 1fr; }
}
</style>
