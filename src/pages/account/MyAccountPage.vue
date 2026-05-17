<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'
import ImageUpload from '@/components/admin/ImageUpload.vue'

const auth = useAuthStore()
const router = useRouter()
const displayName = ref('')
const bio = ref('')
const region = ref('')
const avatarUrl = ref<string | null>(null)
const saving = ref(false)
const savedMsg = ref<string | null>(null)
const errorMsg = ref<string | null>(null)

// === Self-service "Devenir guide" ===
const showBecomeGuideModal = ref(false)
const becomingGuide = ref(false)
const becomeError = ref<string | null>(null)

async function confirmBecomeGuide() {
  if (!auth.profile) return
  becomingGuide.value = true
  becomeError.value = null
  const { error } = await supabase
    .from('profiles')
    .update({ role: 'guide_junior', kyc_status: 'pending' })
    .eq('id', auth.profile.id)
  if (error) {
    becomingGuide.value = false
    becomeError.value = error.message
    return
  }
  await auth.fetchProfile()
  becomingGuide.value = false
  showBecomeGuideModal.value = false
  router.push('/espace-guide/kyc')
}

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

    <!-- Self-service : voyageur peut se déclarer guide local -->
    <section v-if="auth.role === 'voyageur'" class="become-guide-card">
      <div class="bg-icon" aria-hidden="true">🎒</div>
      <h2>Vous voulez devenir guide local Djawal ?</h2>
      <p>
        Si vous êtes Algérien(ne) passionné(e) par votre région et que vous voulez partager
        vos parcours avec les voyageurs, devenez <strong>guide local</strong>. Vous serez
        accompagné par notre équipe et bénéficierez d'un profil public dédié.
      </p>
      <button type="button" class="become-btn" @click="showBecomeGuideModal = true">
        Devenir guide local
      </button>
      <p class="become-note">
        Demande gratuite · Validation par notre équipe Super Admin après vérification KYC (sous 48 h)
      </p>
    </section>

    <!-- Modal de confirmation passage en guide -->
    <v-dialog v-model="showBecomeGuideModal" max-width="520" persistent>
      <v-card class="become-modal">
        <v-card-title class="modal-title">Devenir guide local Djawal</v-card-title>
        <v-card-text>
          <p class="modal-intro">
            En confirmant, votre statut devient <strong>Guide Junior — en attente de validation</strong>.
            Aucun de vos parcours ne sera publié tant que votre dossier n'est pas approuvé.
          </p>
          <ol class="modal-steps">
            <li>
              <strong>Complétez votre dossier KYC</strong>
              <small>Pièce d'identité, justificatif de résidence, photo</small>
            </li>
            <li>
              <strong>Attendez la validation Super Admin</strong>
              <small>Sous 48 h ouvrées après réception du dossier complet</small>
            </li>
            <li>
              <strong>Publiez vos parcours</strong>
              <small>Vous pourrez composer et soumettre vos premiers itinéraires</small>
            </li>
          </ol>
          <v-alert v-if="becomeError" type="error" variant="tonal" class="mt-3">
            {{ becomeError }}
          </v-alert>
        </v-card-text>
        <v-card-actions class="modal-actions">
          <v-btn variant="text" @click="showBecomeGuideModal = false" :disabled="becomingGuide">
            Annuler
          </v-btn>
          <v-btn color="primary" variant="flat" @click="confirmBecomeGuide" :loading="becomingGuide">
            Confirmer ma demande
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

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

/* === Become guide self-service card === */
.become-guide-card {
  position: relative;
  background: linear-gradient(135deg, var(--c-fond-chaud), var(--c-surface));
  border: 2px solid var(--c-accent);
  border-radius: var(--r-lg);
  padding: var(--space-6);
  margin-bottom: var(--space-6);
  text-align: center;
  overflow: hidden;
}
.become-guide-card .bg-icon {
  position: absolute;
  right: -16px;
  top: -16px;
  font-size: 140px;
  opacity: 0.08;
  pointer-events: none;
  line-height: 1;
}
.become-guide-card h2 {
  font-family: var(--font-display);
  font-size: clamp(22px, 2.4vw, 26px);
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-3);
  position: relative;
}
.become-guide-card p {
  color: var(--c-texte-doux);
  line-height: 1.6;
  margin-bottom: var(--space-4);
  max-width: 640px;
  margin-left: auto;
  margin-right: auto;
  position: relative;
}
.become-btn {
  background: var(--c-accent);
  color: white;
  border: none;
  padding: 14px 36px;
  border-radius: var(--r-pill);
  font-weight: 600;
  font-size: 15px;
  letter-spacing: 0.02em;
  cursor: pointer;
  transition: var(--t-base);
  position: relative;
}
.become-btn:hover {
  background: var(--c-accent-fort);
  transform: translateY(-1px);
  box-shadow: var(--ombre-elevee);
}
.become-note {
  margin-top: var(--space-3) !important;
  margin-bottom: 0 !important;
  font-size: 13px !important;
}

/* === Become guide modal === */
.become-modal .modal-title {
  font-family: var(--font-display);
  font-size: 22px;
  color: var(--c-primaire-profond);
}
.become-modal .modal-intro {
  margin-bottom: var(--space-4);
  line-height: 1.6;
}
.become-modal .modal-steps {
  list-style: none;
  counter-reset: step;
  padding: 0;
  margin: 0 0 var(--space-3);
}
.become-modal .modal-steps li {
  counter-increment: step;
  position: relative;
  padding: var(--space-3) var(--space-3) var(--space-3) calc(var(--space-3) + 36px);
  margin-bottom: var(--space-2);
  background: var(--c-fond-chaud);
  border-radius: var(--r-md);
  border-left: 3px solid var(--c-accent);
}
.become-modal .modal-steps li::before {
  content: counter(step);
  position: absolute;
  left: var(--space-3);
  top: 50%;
  transform: translateY(-50%);
  width: 26px;
  height: 26px;
  background: var(--c-accent);
  color: white;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 13px;
}
.become-modal .modal-steps strong {
  display: block;
  color: var(--c-primaire-profond);
  margin-bottom: 2px;
}
.become-modal .modal-steps small {
  color: var(--c-texte-doux);
  font-size: 12px;
}
.become-modal .modal-actions {
  padding: var(--space-3) var(--space-4) var(--space-4);
  justify-content: flex-end;
  gap: var(--space-2);
}
</style>
