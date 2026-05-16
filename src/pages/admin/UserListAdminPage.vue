<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useSEO } from '@/composables/useSEO'

useSEO({ title: 'Utilisateurs — Admin Djawal' })

const route = useRoute()
const router = useRouter()

interface UserRow {
  id: string
  display_name: string | null
  email: string | null
  avatar_url: string | null
  role: string
  created_at: string
  city: string | null
  bio: string | null
}

const users = ref<UserRow[]>([])
const loading = ref(true)
const search = ref('')
const roleFilter = ref<'all' | 'voyageur' | 'guide_junior' | 'guide_senior' | 'tourist_operator' | 'super_admin'>('all')

const roles = [
  { value: 'all', label: 'Tous', icon: '👥' },
  { value: 'voyageur', label: 'Voyageurs', icon: '🧳' },
  { value: 'guide_junior', label: 'Guides Junior', icon: '🗺️' },
  { value: 'guide_senior', label: 'Guides Senior', icon: '⭐' },
  { value: 'tourist_operator', label: 'Opérateurs', icon: '🏢' },
  { value: 'super_admin', label: 'Admins', icon: '🛡️' }
]

const filtered = computed(() => {
  const q = search.value.toLowerCase().trim()
  return users.value.filter(u => {
    if (roleFilter.value !== 'all' && u.role !== roleFilter.value) return false
    if (!q) return true
    return (u.display_name || '').toLowerCase().includes(q) ||
           (u.email || '').toLowerCase().includes(q) ||
           (u.city || '').toLowerCase().includes(q)
  })
})

const stats = computed(() => {
  const total = users.value.length
  const byRole: Record<string, number> = {}
  for (const u of users.value) {
    byRole[u.role] = (byRole[u.role] || 0) + 1
  }
  return { total, byRole }
})

onMounted(async () => {
  // Pré-remplir le filtre rôle depuis le query param (?role=voyageur)
  const qRole = route.query.role as string | undefined
  if (qRole && ['voyageur','guide_junior','guide_senior','tourist_operator','super_admin'].includes(qRole)) {
    roleFilter.value = qRole as any
  }

  loading.value = true
  const { data, error } = await supabase
    .from('profiles')
    .select('id, display_name, email, avatar_url, role, created_at, city, bio')
    .order('created_at', { ascending: false })
  if (!error && data) users.value = data as UserRow[]
  loading.value = false
})

function roleLabel(role: string): string {
  return roles.find(r => r.value === role)?.label.replace(/s$/, '') || role
}

function roleColor(role: string): string {
  const map: Record<string, string> = {
    voyageur: '#6FA8C0',
    guide_junior: '#A8C76F',
    guide_senior: '#D4A844',
    tourist_operator: '#E8B96B',
    super_admin: '#B8312E'
  }
  return map[role] || '#999'
}

function fmtDate(iso: string): string {
  return new Date(iso).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric' })
}

function initial(name?: string | null): string {
  return (name || '?')[0].toUpperCase()
}

function openUser(id: string) {
  router.push(`/admin/users/${id}`)
}
</script>

<template>
  <div class="users-admin-page">

    <header class="page-hero">
      <div class="djawal-container">
        <router-link to="/admin" class="back-link">← Tableau de bord</router-link>
        <div class="hero-eyebrow">Admin · Utilisateurs</div>
        <h1>Utilisateurs Djawal</h1>
        <p class="lead">{{ users.length }} comptes inscrits sur la plateforme</p>
      </div>
    </header>

    <!-- Stats rapides -->
    <section v-if="!loading" class="djawal-container stats-row">
      <div
        v-for="r in roles"
        :key="r.value"
        class="stat-pill"
        :class="{ active: roleFilter === r.value }"
        @click="roleFilter = r.value as any"
      >
        <span class="stat-icon">{{ r.icon }}</span>
        <span class="stat-label">{{ r.label }}</span>
        <strong class="stat-count">
          {{ r.value === 'all' ? stats.total : (stats.byRole[r.value] || 0) }}
        </strong>
      </div>
    </section>

    <!-- Recherche -->
    <section class="djawal-container search-bar">
      <div class="search-wrap">
        <svg class="search-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="11" cy="11" r="7"/>
          <path d="M21 21 L16 16"/>
        </svg>
        <input
          v-model="search"
          type="search"
          placeholder="Rechercher par nom, email ou ville…"
          class="search-input"
        />
        <button
          v-if="search"
          type="button"
          class="search-clear"
          @click="search = ''"
        >×</button>
      </div>
      <span class="results-count">
        <strong>{{ filtered.length }}</strong> résultat{{ filtered.length > 1 ? 's' : '' }}
      </span>
    </section>

    <!-- Grille users -->
    <main class="djawal-container users-main">
      <div v-if="loading" class="loading">Chargement des utilisateurs…</div>

      <div v-else-if="filtered.length === 0" class="empty-state">
        <p>Aucun utilisateur ne correspond à la recherche.</p>
      </div>

      <div v-else class="users-grid">
        <article
          v-for="u in filtered"
          :key="u.id"
          class="user-card"
          @click="openUser(u.id)"
          @keydown.enter="openUser(u.id)"
          role="button"
          tabindex="0"
        >
          <div class="user-avatar">
            <img v-if="u.avatar_url" :src="u.avatar_url" :alt="u.display_name || ''" />
            <span v-else>{{ initial(u.display_name) }}</span>
          </div>
          <div class="user-body">
            <div class="user-head">
              <strong class="user-name">{{ u.display_name || 'Sans nom' }}</strong>
              <span
                class="user-role-badge"
                :style="`background: ${roleColor(u.role)}`"
              >{{ roleLabel(u.role) }}</span>
            </div>
            <div v-if="u.email" class="user-email">{{ u.email }}</div>
            <div v-if="u.city" class="user-city">📍 {{ u.city }}</div>
            <p v-if="u.bio" class="user-bio">{{ u.bio }}</p>
            <div class="user-meta">Inscrit le {{ fmtDate(u.created_at) }}</div>
          </div>
          <div class="user-cta">Voir le détail →</div>
        </article>
      </div>
    </main>
  </div>
</template>

<style scoped>
.users-admin-page {
  background: linear-gradient(180deg, #0F2419 0%, #1A3A2A 60%, #0F2419 100%);
  min-height: 100vh;
  color: #FAF7F2;
  font-family: 'Inter', sans-serif;
}
.djawal-container { max-width: 1280px; margin: 0 auto; padding: 0 32px; }

.page-hero {
  padding: 110px 32px 40px;
  background: linear-gradient(180deg, #1A3A2A 0%, #0F2419 100%);
  border-bottom: 1px solid rgba(212, 168, 68, 0.2);
}
.back-link {
  color: #E8B96B;
  font-size: 13px;
  text-decoration: none;
  font-weight: 500;
  margin-bottom: 14px;
  display: inline-block;
}
.back-link:hover { color: #FAF7F2; }
.hero-eyebrow {
  color: #E8B96B;
  font-size: 11px; letter-spacing: 0.24em;
  text-transform: uppercase;
  margin-bottom: 8px;
}
.page-hero h1 {
  font-family: 'Cormorant Garamond', serif;
  font-size: clamp(28px, 4vw, 44px);
  font-weight: 400;
  color: #FAF7F2;
  margin-bottom: 6px;
}
.lead {
  font-family: 'Cormorant Garamond', serif;
  font-style: italic;
  color: rgba(250, 247, 242, 0.75);
  font-size: 16px;
}

/* Stats pills */
.stats-row {
  display: flex; gap: 10px; flex-wrap: wrap;
  padding-top: 28px;
}
.stat-pill {
  display: inline-flex; align-items: center; gap: 8px;
  padding: 10px 16px;
  background: rgba(31, 74, 54, 0.5);
  border: 1px solid rgba(212, 168, 68, 0.22);
  border-radius: 999px;
  cursor: pointer;
  transition: all 0.2s;
  user-select: none;
}
.stat-pill:hover {
  background: rgba(212, 168, 68, 0.15);
  border-color: rgba(212, 168, 68, 0.5);
}
.stat-pill.active {
  background: #D4A844;
  color: #0F2419;
  border-color: #D4A844;
}
.stat-icon { font-size: 16px; }
.stat-label { font-size: 13px; font-weight: 500; }
.stat-count {
  font-family: 'Cormorant Garamond', serif;
  font-style: italic;
  font-size: 18px;
  font-weight: 500;
  color: #E8B96B;
  margin-left: 4px;
}
.stat-pill.active .stat-count { color: #0F2419; }

/* Search bar */
.search-bar {
  padding-top: 22px;
  display: flex; align-items: center; gap: 18px;
  flex-wrap: wrap;
}
.search-wrap {
  position: relative;
  flex: 1; min-width: 280px; max-width: 480px;
}
.search-icon {
  position: absolute; left: 14px; top: 50%; transform: translateY(-50%);
  color: #E8B96B;
}
.search-input {
  width: 100%;
  background: rgba(250, 247, 242, 0.06);
  border: 1px solid rgba(212, 168, 68, 0.3);
  color: #FAF7F2;
  padding: 12px 38px 12px 42px;
  border-radius: 999px;
  font-family: inherit;
  font-size: 14px;
  outline: none;
  transition: all 0.2s;
}
.search-input::placeholder { color: rgba(250, 247, 242, 0.45); }
.search-input:focus {
  background: rgba(250, 247, 242, 0.12);
  border-color: #D4A844;
}
.search-clear {
  position: absolute; right: 10px; top: 50%; transform: translateY(-50%);
  width: 24px; height: 24px;
  border-radius: 50%;
  background: rgba(250, 247, 242, 0.18);
  color: #0F2419;
  border: none; font-size: 16px; cursor: pointer;
  display: flex; align-items: center; justify-content: center;
}
.results-count {
  color: rgba(250, 247, 242, 0.65);
  font-size: 13px;
}
.results-count strong {
  color: #E8B96B;
  font-family: 'Cormorant Garamond', serif;
  font-style: italic;
  font-size: 20px;
  margin-right: 4px;
}

/* Main + grid */
.users-main { padding: 32px 32px 80px; }
.loading, .empty-state {
  text-align: center;
  padding: 80px 20px;
  color: rgba(250, 247, 242, 0.55);
  font-family: 'Cormorant Garamond', serif;
  font-style: italic;
  font-size: 18px;
}

.users-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 16px;
}

.user-card {
  background: rgba(31, 74, 54, 0.5);
  border: 1px solid rgba(212, 168, 68, 0.18);
  border-radius: 16px;
  padding: 18px 20px;
  cursor: pointer;
  transition: all 0.3s;
  display: flex; gap: 14px;
  position: relative;
}
.user-card:hover {
  background: rgba(31, 74, 54, 0.75);
  border-color: rgba(212, 168, 68, 0.5);
  transform: translateY(-2px);
  box-shadow: 0 14px 38px rgba(0, 0, 0, 0.4);
}
.user-card:focus-visible {
  outline: 2px solid #D4A844;
  outline-offset: 2px;
}

.user-avatar {
  width: 56px; height: 56px;
  border-radius: 50%;
  background: linear-gradient(135deg, rgba(212, 168, 68, 0.35), rgba(212, 168, 68, 0.15));
  display: flex; align-items: center; justify-content: center;
  font-family: 'Cormorant Garamond', serif;
  font-size: 24px;
  font-weight: 500;
  color: #E8B96B;
  overflow: hidden;
  flex-shrink: 0;
  border: 2px solid rgba(212, 168, 68, 0.3);
}
.user-avatar img { width: 100%; height: 100%; object-fit: cover; }

.user-body {
  flex: 1;
  min-width: 0;
}
.user-head {
  display: flex; align-items: center; gap: 10px;
  margin-bottom: 4px;
  flex-wrap: wrap;
}
.user-name {
  font-family: 'Cormorant Garamond', serif;
  font-size: 18px;
  font-weight: 500;
  color: #FAF7F2;
}
.user-role-badge {
  padding: 3px 10px;
  border-radius: 999px;
  font-size: 10.5px;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: #0F2419;
}
.user-email {
  font-size: 13px;
  color: rgba(250, 247, 242, 0.7);
  margin-bottom: 3px;
  word-break: break-all;
}
.user-city {
  font-size: 12.5px;
  color: rgba(250, 247, 242, 0.55);
  margin-bottom: 6px;
}
.user-bio {
  font-size: 13px;
  color: rgba(250, 247, 242, 0.7);
  line-height: 1.4;
  margin-bottom: 8px;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.user-meta {
  font-size: 11.5px;
  color: rgba(250, 247, 242, 0.45);
  letter-spacing: 0.04em;
}
.user-cta {
  position: absolute;
  bottom: 12px; right: 16px;
  color: #E8B96B;
  font-size: 12px;
  font-weight: 600;
  opacity: 0;
  transition: opacity 0.2s;
}
.user-card:hover .user-cta { opacity: 1; }

@media (max-width: 600px) {
  .djawal-container { padding: 0 18px; }
  .page-hero { padding: 90px 18px 28px; }
  .users-main { padding: 24px 18px 60px; }
  .users-grid { grid-template-columns: 1fr; }
  .stats-row { padding-top: 22px; }
  .stat-pill { padding: 8px 14px; font-size: 12px; }
}
</style>
