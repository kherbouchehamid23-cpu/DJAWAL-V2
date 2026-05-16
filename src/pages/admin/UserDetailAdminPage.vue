<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useSEO } from '@/composables/useSEO'
import { useAuthStore } from '@/stores/auth'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()

interface UserProfile {
  id: string
  display_name: string | null
  avatar_url: string | null
  role: string
  bio: string | null
  region: string | null
  company_name?: string | null
  operator_type?: string | null
  specialties?: string[] | null
  is_active: boolean
  kyc_status: string
  created_at: string
}

interface UserAuthInfo {
  email: string | null
  email_confirmed_at: string | null
  last_sign_in_at: string | null
}

interface CascadePreview {
  trips: number
  memories: number
  accommodations: number
  restaurants: number
  activities: number
  sites: number
  favorites: number
  reviews: number
}

const profile = ref<UserProfile | null>(null)
const authInfo = ref<UserAuthInfo | null>(null)
const loading = ref(true)
const errorMsg = ref('')

// Actions admin
const actionLoading = ref<'suspend' | 'reactivate' | 'delete' | null>(null)
const actionError = ref('')
const showDeleteModal = ref(false)
const cascadePreview = ref<CascadePreview | null>(null)
const deleteConfirmText = ref('')

// Stats activité
const stats = ref({
  favoritesCount: 0,
  reviewsCount: 0,
  averageRating: null as string | null,
  tripsCount: 0,
  memoriesCount: 0
})
const recentReviews = ref<any[]>([])
const recentFavorites = ref<any[]>([])

const isSelf = computed(() => auth.user?.id === profile.value?.id)

useSEO(() => ({
  title: profile.value
    ? `${profile.value.display_name || 'Utilisateur'} — Admin Djawal`
    : 'Utilisateur — Admin Djawal'
}))

const userId = computed(() => route.params.id as string)

onMounted(async () => {
  loading.value = true
  errorMsg.value = ''

  // Profil — colonnes réelles du schema profiles
  const { data: profileData, error: profileErr } = await supabase
    .from('profiles')
    .select('id, display_name, avatar_url, role, bio, region, company_name, operator_type, specialties, is_active, kyc_status, created_at')
    .eq('id', userId.value)
    .maybeSingle()

  if (profileErr || !profileData) {
    errorMsg.value = 'Utilisateur introuvable.'
    loading.value = false
    return
  }
  profile.value = profileData as UserProfile

  // Stats en parallèle
  const [favRes, revRes, tripsRes, memRes] = await Promise.all([
    supabase.from('user_favorites').select('target_type, target_id, created_at', { count: 'exact' }).eq('user_id', userId.value).order('created_at', { ascending: false }).limit(8),
    supabase.from('user_reviews').select('id, target_type, target_id, rating, comment, status, created_at', { count: 'exact' }).eq('user_id', userId.value).order('created_at', { ascending: false }).limit(8),
    supabase.from('trips').select('id', { count: 'exact', head: true }).eq('created_by', userId.value),
    supabase.from('memories').select('id', { count: 'exact', head: true }).eq('author_id', userId.value)
  ])

  stats.value.favoritesCount = favRes.count || 0
  stats.value.reviewsCount = revRes.count || 0
  stats.value.tripsCount = tripsRes.count || 0
  stats.value.memoriesCount = memRes.count || 0

  recentFavorites.value = favRes.data || []
  recentReviews.value = revRes.data || []

  // Moyenne des avis donnés
  if (revRes.data && revRes.data.length > 0) {
    const sum = revRes.data.reduce((s: number, r: any) => s + r.rating, 0)
    stats.value.averageRating = (sum / revRes.data.length).toFixed(1)
  }

  loading.value = false

  // Fetch email via Edge Function (non-bloquant)
  fetchAuthInfo()
})

async function callEdgeFunction(action: string, extra: Record<string, unknown> = {}) {
  const { data, error } = await supabase.functions.invoke('admin-user-ops', {
    body: { action, user_id: userId.value, ...extra }
  })
  if (error) throw new Error(error.message)
  if (data?.error) throw new Error(data.error)
  return data
}

async function fetchAuthInfo() {
  try {
    const data = await callEdgeFunction('get_email')
    authInfo.value = {
      email: data.email,
      email_confirmed_at: data.email_confirmed_at,
      last_sign_in_at: data.last_sign_in_at
    }
  } catch (e) {
    console.warn('Impossible de récupérer email :', (e as Error).message)
  }
}

async function toggleActive(target: boolean) {
  if (!profile.value) return
  actionLoading.value = target ? 'reactivate' : 'suspend'
  actionError.value = ''
  const { error } = await supabase
    .from('profiles')
    .update({ is_active: target })
    .eq('id', profile.value.id)
  actionLoading.value = null
  if (error) {
    actionError.value = 'Erreur : ' + error.message
    return
  }
  profile.value.is_active = target
}

async function openDeleteModal() {
  if (!profile.value) return
  showDeleteModal.value = true
  deleteConfirmText.value = ''
  cascadePreview.value = null
  // Charger le preview des conséquences
  try {
    const data = await callEdgeFunction('count_cascade')
    cascadePreview.value = data as CascadePreview
  } catch (e) {
    actionError.value = 'Impossible de prévisualiser : ' + (e as Error).message
  }
}

function closeDeleteModal() {
  showDeleteModal.value = false
  deleteConfirmText.value = ''
  cascadePreview.value = null
}

const deleteAllowed = computed(() => {
  const name = (profile.value?.display_name || '').trim().toUpperCase()
  return deleteConfirmText.value.trim().toUpperCase() === name && name.length > 0
})

async function confirmDelete() {
  if (!deleteAllowed.value) return
  actionLoading.value = 'delete'
  actionError.value = ''
  try {
    await callEdgeFunction('delete_user', { confirm: true })
    actionLoading.value = null
    // Retour à la liste
    router.push('/admin/users')
  } catch (e) {
    actionLoading.value = null
    actionError.value = 'Erreur : ' + (e as Error).message
  }
}

function fmtDate(iso: string): string {
  return new Date(iso).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric' })
}

function fmtDateTime(iso: string): string {
  return new Date(iso).toLocaleString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' })
}

function initial(name?: string | null): string {
  return (name || '?')[0].toUpperCase()
}

function roleLabel(role: string): string {
  return ({
    voyageur: 'Voyageur',
    guide_junior: 'Guide Junior',
    guide_senior: 'Guide Senior',
    tourist_operator: 'Opérateur touristique',
    super_admin: 'Super Admin'
  } as Record<string, string>)[role] || role
}

function roleColor(role: string): string {
  return ({
    voyageur: '#6FA8C0',
    guide_junior: '#A8C76F',
    guide_senior: '#D4A844',
    tourist_operator: '#E8B96B',
    super_admin: '#B8312E'
  } as Record<string, string>)[role] || '#999'
}
</script>

<template>
  <div class="user-detail-page">
    <div v-if="loading" class="loading djawal-container">Chargement du profil…</div>

    <div v-else-if="errorMsg" class="error-state djawal-container">
      <h2>{{ errorMsg }}</h2>
      <router-link to="/admin/users">
        <button class="btn-primary">Retour à la liste</button>
      </router-link>
    </div>

    <template v-else-if="profile">
      <!-- HERO PROFIL -->
      <header class="detail-hero">
        <div class="djawal-container">
          <router-link to="/admin/users" class="back-link">← Retour à la liste</router-link>

          <div class="profile-card">
            <div class="profile-avatar">
              <img v-if="profile.avatar_url" :src="profile.avatar_url" :alt="profile.display_name || ''" />
              <span v-else>{{ initial(profile.display_name) }}</span>
            </div>
            <div class="profile-info">
              <div class="profile-head">
                <h1>{{ profile.display_name || 'Sans nom' }}</h1>
                <span class="role-badge" :style="`background: ${roleColor(profile.role)}`">
                  {{ roleLabel(profile.role) }}
                </span>
              </div>
              <p v-if="profile.company_name" class="business-name">🏢 {{ profile.company_name }}</p>
              <p v-if="profile.operator_type" class="profile-meta-line">Type : {{ profile.operator_type }}</p>
              <p v-if="profile.region" class="profile-city">📍 {{ profile.region }}</p>
              <p v-if="profile.specialties?.length" class="profile-langs">
                ✨ {{ profile.specialties.join(' · ') }}
              </p>
              <p v-if="profile.bio" class="profile-bio">{{ profile.bio }}</p>
              <p v-if="authInfo?.email" class="profile-email">
                ✉️ <a :href="`mailto:${authInfo.email}`">{{ authInfo.email }}</a>
                <span v-if="!authInfo.email_confirmed_at" class="email-unverified">(non vérifié)</span>
              </p>
              <p class="profile-meta">
                Inscrit le {{ fmtDate(profile.created_at) }}
                · Statut KYC : <strong>{{ profile.kyc_status }}</strong>
                · {{ profile.is_active ? '✅ Actif' : '⛔ Suspendu' }}
                <span v-if="authInfo?.last_sign_in_at"> · Dernière connexion {{ fmtDate(authInfo.last_sign_in_at) }}</span>
              </p>
            </div>
          </div>
        </div>
      </header>

      <!-- STATS -->
      <section class="djawal-container stats-grid">
        <div class="stat-card">
          <div class="stat-icon">❤️</div>
          <strong>{{ stats.favoritesCount }}</strong>
          <span>favoris</span>
        </div>
        <div class="stat-card">
          <div class="stat-icon">⭐</div>
          <strong>{{ stats.reviewsCount }}</strong>
          <span>avis publiés</span>
        </div>
        <div v-if="stats.averageRating" class="stat-card">
          <div class="stat-icon">📊</div>
          <strong>{{ stats.averageRating }}</strong>
          <span>note moyenne donnée</span>
        </div>
        <div v-if="['guide_junior','guide_senior','tourist_operator'].includes(profile.role)" class="stat-card">
          <div class="stat-icon">🗺️</div>
          <strong>{{ stats.tripsCount }}</strong>
          <span>voyages créés</span>
        </div>
        <div class="stat-card">
          <div class="stat-icon">📷</div>
          <strong>{{ stats.memoriesCount }}</strong>
          <span>souvenirs partagés</span>
        </div>
      </section>

      <!-- AVIS RÉCENTS -->
      <section v-if="recentReviews.length > 0" class="djawal-container content-section">
        <h2>Avis récents publiés ({{ recentReviews.length }})</h2>
        <div class="items-list">
          <article v-for="r in recentReviews" :key="r.id" class="item-card">
            <div class="item-head">
              <span class="item-type">{{ r.target_type }}</span>
              <span class="item-rating">{{ '★'.repeat(r.rating) }}{{ '☆'.repeat(5 - r.rating) }}</span>
              <span v-if="r.status !== 'approved'" class="item-status" :data-status="r.status">{{ r.status }}</span>
            </div>
            <p v-if="r.comment" class="item-comment">« {{ r.comment }} »</p>
            <div class="item-meta">{{ fmtDateTime(r.created_at) }}</div>
          </article>
        </div>
      </section>

      <!-- FAVORIS RÉCENTS -->
      <section v-if="recentFavorites.length > 0" class="djawal-container content-section">
        <h2>Favoris récents ({{ recentFavorites.length }})</h2>
        <div class="items-list">
          <div v-for="f in recentFavorites" :key="`${f.target_type}-${f.target_id}`" class="item-card">
            <div class="item-head">
              <span class="item-type">{{ f.target_type }}</span>
              <code class="item-id">{{ f.target_id.substring(0, 8) }}…</code>
            </div>
            <div class="item-meta">Ajouté le {{ fmtDateTime(f.created_at) }}</div>
          </div>
        </div>
      </section>

      <!-- ACTIONS ADMIN -->
      <section class="djawal-container content-section actions-section">
        <h2>Actions admin</h2>

        <p v-if="actionError" class="action-error">{{ actionError }}</p>
        <p v-if="isSelf" class="action-warn">⚠️ Vous consultez votre propre profil — les actions de suspension et suppression sont désactivées.</p>

        <div class="actions-grid">
          <router-link
            v-if="profile.role === 'guide_junior' || profile.role === 'guide_senior'"
            :to="`/guide/${profile.id}`"
            class="action-btn"
          >🗺️ Voir profil public guide</router-link>

          <router-link
            v-if="profile.role === 'tourist_operator'"
            :to="`/admin/users/${profile.id}`"
            class="action-btn"
          >🏢 Voir profil opérateur</router-link>

          <!-- Suspendre / Réactiver -->
          <button
            v-if="profile.is_active"
            class="action-btn action-warn-btn"
            :disabled="isSelf || actionLoading !== null"
            @click="toggleActive(false)"
          >
            {{ actionLoading === 'suspend' ? 'Suspension…' : '🚫 Suspendre le compte' }}
          </button>
          <button
            v-else
            class="action-btn action-success-btn"
            :disabled="isSelf || actionLoading !== null"
            @click="toggleActive(true)"
          >
            {{ actionLoading === 'reactivate' ? 'Réactivation…' : '✅ Réactiver le compte' }}
          </button>

          <!-- Supprimer -->
          <button
            class="action-btn action-danger-btn"
            :disabled="isSelf || actionLoading !== null"
            @click="openDeleteModal"
          >
            🗑️ Supprimer définitivement
          </button>
        </div>

        <p class="action-hint">
          <strong>Suspendre</strong> : le compte ne peut plus se connecter au site public, ses contributions restent visibles (réversible).<br>
          <strong>Supprimer</strong> : efface le compte et toutes ses contributions personnelles (voyages, souvenirs, favoris, avis). <strong>Irréversible.</strong>
        </p>
      </section>

      <!-- MODAL SUPPRESSION -->
      <div v-if="showDeleteModal" class="modal-backdrop" @click.self="closeDeleteModal">
        <div class="modal">
          <header class="modal-header">
            <h3>🗑️ Supprimer définitivement</h3>
            <button class="modal-close" @click="closeDeleteModal" aria-label="Fermer">✕</button>
          </header>

          <div class="modal-body">
            <p>Vous êtes sur le point de supprimer <strong>{{ profile.display_name }}</strong> ({{ roleLabel(profile.role) }}).</p>

            <div v-if="cascadePreview === null" class="cascade-loading">Calcul des conséquences…</div>
            <div v-else class="cascade-preview">
              <p class="cascade-intro">Données qui seront effacées en cascade :</p>
              <ul class="cascade-list">
                <li v-if="cascadePreview.trips > 0">🧭 <strong>{{ cascadePreview.trips }}</strong> voyage(s)</li>
                <li v-if="cascadePreview.memories > 0">📷 <strong>{{ cascadePreview.memories }}</strong> souvenir(s)</li>
                <li v-if="cascadePreview.favorites > 0">❤️ <strong>{{ cascadePreview.favorites }}</strong> favori(s)</li>
                <li v-if="cascadePreview.reviews > 0">⭐ <strong>{{ cascadePreview.reviews }}</strong> avis publié(s)</li>
                <li v-if="cascadePreview.trips + cascadePreview.memories + cascadePreview.favorites + cascadePreview.reviews === 0" class="empty">
                  Aucune contribution personnelle à effacer.
                </li>
              </ul>
              <p v-if="cascadePreview.accommodations + cascadePreview.restaurants + cascadePreview.activities + cascadePreview.sites > 0" class="cascade-note">
                <strong>Ressources opérateurs conservées</strong> (anonymisées) :
                {{ cascadePreview.accommodations }} héberg., {{ cascadePreview.restaurants }} restaur., {{ cascadePreview.activities }} activ., {{ cascadePreview.sites }} site(s).
              </p>
            </div>

            <div class="confirm-zone">
              <label for="confirm-input">
                Tapez le nom <code>{{ (profile.display_name || '').toUpperCase() }}</code> pour confirmer :
              </label>
              <input
                id="confirm-input"
                v-model="deleteConfirmText"
                type="text"
                class="confirm-input"
                placeholder="Nom à recopier exactement"
                autocomplete="off"
              />
            </div>
          </div>

          <footer class="modal-footer">
            <button class="modal-btn modal-cancel" @click="closeDeleteModal" :disabled="actionLoading === 'delete'">
              Annuler
            </button>
            <button
              class="modal-btn modal-delete"
              :disabled="!deleteAllowed || actionLoading === 'delete'"
              @click="confirmDelete"
            >
              {{ actionLoading === 'delete' ? 'Suppression en cours…' : 'Supprimer définitivement' }}
            </button>
          </footer>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.user-detail-page {
  background: linear-gradient(180deg, #0F2419 0%, #1A3A2A 60%, #0F2419 100%);
  min-height: 100vh;
  color: #FAF7F2;
  font-family: 'Inter', sans-serif;
}
.djawal-container { max-width: 1080px; margin: 0 auto; padding: 0 32px; }

.loading, .error-state {
  text-align: center;
  padding: 120px 32px;
  color: rgba(250, 247, 242, 0.65);
  font-family: 'Cormorant Garamond', serif;
  font-style: italic;
  font-size: 20px;
}

.detail-hero {
  padding: 100px 0 40px;
  background: linear-gradient(180deg, #1A3A2A 0%, #0F2419 100%);
  border-bottom: 1px solid rgba(212, 168, 68, 0.2);
}
.back-link {
  color: #E8B96B;
  text-decoration: none;
  font-size: 13px;
  font-weight: 500;
  display: inline-block;
  margin-bottom: 22px;
}
.back-link:hover { color: #FAF7F2; }

.profile-card {
  display: flex; gap: 28px;
  background: rgba(31, 74, 54, 0.55);
  border: 1px solid rgba(212, 168, 68, 0.28);
  border-radius: 22px;
  padding: 28px 32px;
}
.profile-avatar {
  width: 100px; height: 100px;
  border-radius: 50%;
  background: linear-gradient(135deg, #D4A844, #B8862E);
  display: flex; align-items: center; justify-content: center;
  font-family: 'Cormorant Garamond', serif;
  font-size: 42px;
  color: #0F2419;
  flex-shrink: 0;
  overflow: hidden;
  border: 3px solid rgba(212, 168, 68, 0.5);
}
.profile-avatar img { width: 100%; height: 100%; object-fit: cover; }

.profile-info { flex: 1; min-width: 0; }
.profile-head {
  display: flex; align-items: center; gap: 14px;
  flex-wrap: wrap;
  margin-bottom: 6px;
}
.profile-head h1 {
  font-family: 'Cormorant Garamond', serif;
  font-size: clamp(26px, 3vw, 36px);
  font-weight: 400;
  color: #FAF7F2;
}
.role-badge {
  padding: 4px 12px;
  border-radius: 999px;
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  color: #0F2419;
}
.business-name {
  font-family: 'Cormorant Garamond', serif;
  font-style: italic;
  font-size: 18px;
  color: #E8B96B;
  margin-bottom: 8px;
}
.profile-email, .profile-phone, .profile-city, .profile-langs {
  font-size: 14px;
  color: rgba(250, 247, 242, 0.75);
  margin-bottom: 3px;
}
.profile-bio {
  font-size: 14.5px;
  line-height: 1.5;
  color: rgba(250, 247, 242, 0.82);
  margin: 10px 0;
}
.profile-meta {
  font-size: 12px;
  color: rgba(250, 247, 242, 0.5);
  letter-spacing: 0.04em;
  margin-top: 10px;
  padding-top: 10px;
  border-top: 1px solid rgba(212, 168, 68, 0.2);
}

/* Stats */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
  gap: 14px;
  padding-top: 32px;
}
.stat-card {
  background: rgba(31, 74, 54, 0.45);
  border: 1px solid rgba(212, 168, 68, 0.22);
  border-radius: 14px;
  padding: 18px 20px;
  text-align: center;
}
.stat-icon { font-size: 22px; margin-bottom: 6px; }
.stat-card strong {
  display: block;
  font-family: 'Cormorant Garamond', serif;
  font-size: 32px;
  color: #E8B96B;
  font-weight: 500;
  margin-bottom: 2px;
}
.stat-card span {
  font-size: 12px;
  color: rgba(250, 247, 242, 0.65);
}

/* Sections content */
.content-section {
  padding-top: 40px;
  padding-bottom: 20px;
}
.content-section h2 {
  font-family: 'Cormorant Garamond', serif;
  font-size: 22px;
  color: #FAF7F2;
  margin-bottom: 16px;
  font-weight: 500;
}

.items-list {
  display: flex; flex-direction: column;
  gap: 10px;
}
.item-card {
  background: rgba(31, 74, 54, 0.4);
  border: 1px solid rgba(212, 168, 68, 0.15);
  border-radius: 12px;
  padding: 14px 18px;
}
.item-head {
  display: flex; align-items: center; gap: 12px;
  margin-bottom: 6px;
  flex-wrap: wrap;
}
.item-type {
  background: rgba(212, 168, 68, 0.18);
  color: #E8B96B;
  padding: 3px 10px;
  border-radius: 999px;
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.06em;
}
.item-rating {
  color: #E8B96B;
  letter-spacing: 1px;
}
.item-status {
  padding: 2px 8px;
  border-radius: 999px;
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}
.item-status[data-status="pending"] { background: rgba(212, 168, 68, 0.3); color: #E8B96B; }
.item-status[data-status="rejected"] { background: rgba(184, 49, 46, 0.3); color: #FFB3B3; }
.item-status[data-status="flagged"] { background: rgba(250, 130, 20, 0.3); color: #FFB066; }
.item-id {
  font-family: 'JetBrains Mono', monospace;
  font-size: 11px;
  color: rgba(250, 247, 242, 0.55);
}
.item-comment {
  font-style: italic;
  font-family: 'Cormorant Garamond', serif;
  font-size: 14.5px;
  color: rgba(250, 247, 242, 0.82);
  margin: 4px 0;
}
.item-meta {
  font-size: 11.5px;
  color: rgba(250, 247, 242, 0.5);
}

/* Actions */
.actions-section { padding-bottom: 80px; }
.actions-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
  gap: 12px;
}
.action-btn {
  background: rgba(31, 74, 54, 0.6);
  border: 1px solid rgba(212, 168, 68, 0.35);
  color: #E8B96B;
  padding: 14px 18px;
  border-radius: 12px;
  font-family: inherit;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  text-decoration: none;
  display: flex; align-items: center; justify-content: center;
  transition: all 0.2s;
}
.action-btn:hover:not(.disabled) {
  background: rgba(212, 168, 68, 0.18);
  border-color: #D4A844;
  color: #FAF7F2;
}
.action-btn.disabled,
.action-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}
.action-warn-btn {
  border-color: rgba(232, 185, 107, 0.55);
  color: #E8B96B;
}
.action-warn-btn:hover:not(:disabled) {
  background: rgba(232, 185, 107, 0.18);
  color: #FAF7F2;
}
.action-success-btn {
  border-color: rgba(159, 225, 203, 0.55);
  color: #9FE1CB;
}
.action-success-btn:hover:not(:disabled) {
  background: rgba(159, 225, 203, 0.15);
  color: #FAF7F2;
}
.action-danger-btn {
  border-color: rgba(240, 149, 149, 0.55);
  color: #F09595;
}
.action-danger-btn:hover:not(:disabled) {
  background: rgba(240, 149, 149, 0.16);
  color: #FFF6E5;
  border-color: #F09595;
}
.action-error {
  background: rgba(184, 49, 46, 0.18);
  border: 1px solid rgba(240, 149, 149, 0.5);
  color: #F09595;
  padding: 10px 16px;
  border-radius: 10px;
  font-size: 13px;
  margin-bottom: 14px;
}
.action-warn {
  background: rgba(232, 185, 107, 0.14);
  border: 1px solid rgba(232, 185, 107, 0.35);
  color: #E8B96B;
  padding: 10px 16px;
  border-radius: 10px;
  font-size: 13px;
  margin-bottom: 14px;
}
.action-hint {
  margin-top: 18px;
  font-size: 12.5px;
  color: rgba(250, 247, 242, 0.55);
  line-height: 1.65;
  padding: 14px 16px;
  background: rgba(31, 74, 54, 0.35);
  border-radius: 10px;
  border-left: 3px solid rgba(212, 168, 68, 0.4);
}
.action-hint strong { color: #E8B96B; }

/* Email dans hero */
.profile-email {
  font-size: 14px;
  color: rgba(250, 247, 242, 0.85);
  margin: 4px 0 0;
}
.profile-email a { color: #E8B96B; text-decoration: none; }
.profile-email a:hover { text-decoration: underline; }
.email-unverified {
  background: rgba(184, 49, 46, 0.25);
  color: #FFB3B3;
  font-size: 10.5px;
  padding: 2px 8px;
  border-radius: 999px;
  margin-left: 8px;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  font-weight: 600;
}

/* MODAL */
.modal-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(8, 18, 14, 0.78);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  z-index: 1000;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px;
}
.modal {
  background: linear-gradient(180deg, #1A3A2A 0%, #0F2419 100%);
  border: 1px solid rgba(240, 149, 149, 0.4);
  border-radius: 18px;
  max-width: 520px;
  width: 100%;
  color: #FAF7F2;
  box-shadow: 0 30px 80px rgba(0, 0, 0, 0.5);
  max-height: 90vh;
  overflow-y: auto;
}
.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 22px 26px 14px;
  border-bottom: 1px solid rgba(212, 168, 68, 0.2);
}
.modal-header h3 {
  font-family: 'Cormorant Garamond', serif;
  font-size: 22px;
  color: #F09595;
  font-weight: 500;
}
.modal-close {
  background: rgba(255, 255, 255, 0.08);
  border: none;
  width: 32px; height: 32px;
  border-radius: 50%;
  color: #FAF7F2;
  cursor: pointer;
  font-size: 14px;
}
.modal-close:hover { background: rgba(255, 255, 255, 0.16); }
.modal-body {
  padding: 18px 26px;
}
.modal-body > p {
  margin-bottom: 14px;
  font-size: 14px;
  line-height: 1.55;
}
.cascade-loading {
  text-align: center;
  padding: 18px;
  font-style: italic;
  color: rgba(250, 247, 242, 0.55);
}
.cascade-preview {
  background: rgba(184, 49, 46, 0.12);
  border: 1px solid rgba(240, 149, 149, 0.3);
  border-radius: 10px;
  padding: 14px 18px;
  margin-bottom: 16px;
}
.cascade-intro {
  font-size: 12.5px;
  color: rgba(250, 247, 242, 0.7);
  margin-bottom: 8px;
}
.cascade-list {
  list-style: none;
  padding: 0;
  margin: 0 0 8px;
  font-size: 13.5px;
}
.cascade-list li {
  padding: 4px 0;
}
.cascade-list li.empty {
  color: rgba(250, 247, 242, 0.55);
  font-style: italic;
}
.cascade-note {
  font-size: 12px;
  color: rgba(250, 247, 242, 0.6);
  border-top: 1px solid rgba(240, 149, 149, 0.18);
  padding-top: 8px;
  margin-top: 6px;
}
.confirm-zone {
  margin-top: 14px;
}
.confirm-zone label {
  display: block;
  font-size: 13px;
  color: rgba(250, 247, 242, 0.78);
  margin-bottom: 8px;
}
.confirm-zone code {
  background: rgba(240, 149, 149, 0.18);
  color: #F09595;
  padding: 2px 8px;
  border-radius: 6px;
  font-family: 'JetBrains Mono', monospace;
  font-size: 12.5px;
}
.confirm-input {
  width: 100%;
  background: rgba(255, 255, 255, 0.06);
  border: 1.5px solid rgba(240, 149, 149, 0.35);
  color: #FAF7F2;
  padding: 11px 14px;
  border-radius: 10px;
  font-size: 14px;
  font-family: inherit;
  outline: none;
}
.confirm-input:focus { border-color: #F09595; }
.modal-footer {
  display: flex;
  gap: 10px;
  padding: 14px 26px 22px;
  border-top: 1px solid rgba(212, 168, 68, 0.2);
  justify-content: flex-end;
}
.modal-btn {
  padding: 11px 22px;
  border-radius: 999px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  font-family: inherit;
  border: 1.5px solid transparent;
  transition: all 0.15s;
}
.modal-btn:disabled { opacity: 0.4; cursor: not-allowed; }
.modal-cancel {
  background: transparent;
  color: rgba(250, 247, 242, 0.7);
  border-color: rgba(250, 247, 242, 0.25);
}
.modal-cancel:hover:not(:disabled) { background: rgba(255, 255, 255, 0.08); }
.modal-delete {
  background: #A32D2D;
  color: #FAF7F2;
}
.modal-delete:hover:not(:disabled) { background: #791F1F; }

.btn-primary {
  background: #D4A844;
  color: #0F2419;
  border: none;
  padding: 11px 24px;
  border-radius: 999px;
  font-weight: 600;
  cursor: pointer;
  font-family: inherit;
}

@media (max-width: 700px) {
  .djawal-container { padding: 0 18px; }
  .detail-hero { padding: 90px 0 28px; }
  .profile-card { flex-direction: column; gap: 18px; padding: 22px 22px; }
  .profile-avatar { width: 80px; height: 80px; font-size: 34px; }
}
</style>
