<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useSEO } from '@/composables/useSEO'

const route = useRoute()
const router = useRouter()

interface UserProfile {
  id: string
  display_name: string | null
  email: string | null
  avatar_url: string | null
  role: string
  bio: string | null
  city: string | null
  languages: string[] | null
  phone: string | null
  business_name?: string | null
  created_at: string
  updated_at: string
}

const profile = ref<UserProfile | null>(null)
const loading = ref(true)
const errorMsg = ref('')

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

useSEO(() => ({
  title: profile.value
    ? `${profile.value.display_name || 'Utilisateur'} — Admin Djawal`
    : 'Utilisateur — Admin Djawal'
}))

const userId = computed(() => route.params.id as string)

onMounted(async () => {
  loading.value = true
  errorMsg.value = ''

  // Profil
  const { data: profileData, error: profileErr } = await supabase
    .from('profiles')
    .select('id, display_name, email, avatar_url, role, bio, city, languages, phone, business_name, created_at, updated_at')
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
})

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
              <p v-if="profile.business_name" class="business-name">{{ profile.business_name }}</p>
              <p v-if="profile.email" class="profile-email">📧 {{ profile.email }}</p>
              <p v-if="profile.phone" class="profile-phone">📞 {{ profile.phone }}</p>
              <p v-if="profile.city" class="profile-city">📍 {{ profile.city }}</p>
              <p v-if="profile.languages?.length" class="profile-langs">
                🗣️ {{ profile.languages.join(', ') }}
              </p>
              <p v-if="profile.bio" class="profile-bio">{{ profile.bio }}</p>
              <p class="profile-meta">
                Inscrit le {{ fmtDate(profile.created_at) }} · Dernière mise à jour {{ fmtDate(profile.updated_at) }}
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
        <div class="actions-grid">
          <router-link
            v-if="profile.role === 'guide_junior' || profile.role === 'guide_senior'"
            :to="`/guide/${profile.id}`"
            class="action-btn"
          >🗺️ Voir profil public guide</router-link>
          <button class="action-btn disabled" disabled>
            🚫 Suspendre le compte (à venir)
          </button>
          <button class="action-btn disabled" disabled>
            🗑️ Supprimer toutes les données (à venir)
          </button>
        </div>
      </section>
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
.action-btn.disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

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
