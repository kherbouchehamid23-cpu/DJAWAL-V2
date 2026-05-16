<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

type ReviewStatus = 'pending' | 'approved' | 'rejected' | 'flagged'
type TargetType = 'trip' | 'destination' | 'accommodation' | 'site' | 'restaurant' | 'activity' | 'guide' | 'operator'

interface ReviewRow {
  id: string
  user_id: string
  target_type: TargetType
  target_id: string
  rating: number
  comment: string | null
  status: ReviewStatus
  created_at: string
  moderated_at: string | null
  profiles?: { display_name: string; avatar_url: string | null; role: string } | null
  // Enrichi côté client
  targetName?: string
  targetLink?: string
}

const auth = useAuthStore()
const reviews = ref<ReviewRow[]>([])
const loading = ref(true)
const statusTab = ref<ReviewStatus>('pending')
const processing = ref<string | null>(null)
const reviewNotes = ref<Record<string, string>>({})
const typeFilter = ref<TargetType | 'all'>('all')

const counts = ref({ pending: 0, approved: 0, rejected: 0, flagged: 0 })

const TARGET_LABEL: Record<TargetType, string> = {
  trip: 'Voyage',
  destination: 'Destination',
  accommodation: 'Hébergement',
  site: 'Site',
  restaurant: 'Restaurant',
  activity: 'Activité',
  guide: 'Guide',
  operator: 'Opérateur'
}

const TARGET_ICON: Record<TargetType, string> = {
  trip: '🧭',
  destination: '🗺️',
  accommodation: '🏨',
  site: '🏛️',
  restaurant: '🍽️',
  activity: '🥾',
  guide: '🎒',
  operator: '🏢'
}

async function loadCounts() {
  const [p, a, r, f] = await Promise.all([
    supabase.from('user_reviews').select('id', { count: 'exact', head: true }).eq('status', 'pending'),
    supabase.from('user_reviews').select('id', { count: 'exact', head: true }).eq('status', 'approved'),
    supabase.from('user_reviews').select('id', { count: 'exact', head: true }).eq('status', 'rejected'),
    supabase.from('user_reviews').select('id', { count: 'exact', head: true }).eq('status', 'flagged')
  ])
  counts.value = {
    pending: p.count || 0,
    approved: a.count || 0,
    rejected: r.count || 0,
    flagged: f.count || 0
  }
}

async function load() {
  loading.value = true

  let query = supabase
    .from('user_reviews')
    .select(`
      id, user_id, target_type, target_id, rating, comment, status, created_at, moderated_at,
      profiles!user_reviews_user_id_fkey(display_name, avatar_url, role)
    `)
    .eq('status', statusTab.value)
    .order('created_at', { ascending: false })
    .limit(80)

  if (typeFilter.value !== 'all') {
    query = query.eq('target_type', typeFilter.value)
  }

  const { data, error } = await query
  if (error) {
    console.error('reviews load', error)
    reviews.value = []
    loading.value = false
    return
  }

  reviews.value = (data as any) || []

  // Enrichir avec nom de la target (par batch par type)
  await enrichTargets()
  loading.value = false
}

async function enrichTargets() {
  // Grouper les ids par type
  const byType: Record<string, string[]> = {}
  for (const r of reviews.value) {
    if (!byType[r.target_type]) byType[r.target_type] = []
    if (!byType[r.target_type].includes(r.target_id)) byType[r.target_type].push(r.target_id)
  }

  // Mapping table → nameColumn → linkPath
  const tableMap: Record<string, { table: string; col: string; link: (id: string) => string }> = {
    trip:          { table: 'trips',          col: 'title', link: id => `/voyages/${id}` },
    destination:   { table: 'destinations',   col: 'name',  link: id => `/destination/${id}` },
    accommodation: { table: 'accommodations', col: 'name',  link: id => `/admin/resources/accommodations` },
    site:          { table: 'sites',          col: 'name',  link: id => `/admin/resources/sites` },
    restaurant:    { table: 'restaurants',    col: 'name',  link: id => `/admin/resources/restaurants` },
    activity:      { table: 'activities',     col: 'name',  link: id => `/admin/resources/activities` },
    guide:         { table: 'profiles',       col: 'display_name', link: id => `/guide/${id}` },
    operator:      { table: 'profiles',       col: 'display_name', link: id => `/admin/users/${id}` }
  }

  const lookups: Record<string, Record<string, string>> = {}

  await Promise.all(Object.entries(byType).map(async ([type, ids]) => {
    const cfg = tableMap[type]
    if (!cfg) return
    const { data } = await supabase
      .from(cfg.table)
      .select(`id, ${cfg.col}`)
      .in('id', ids)
    lookups[type] = {}
    for (const row of (data as any[]) || []) {
      lookups[type][row.id] = row[cfg.col]
    }
  }))

  // Appliquer
  for (const r of reviews.value) {
    r.targetName = lookups[r.target_type]?.[r.target_id] || '(introuvable)'
    r.targetLink = tableMap[r.target_type]?.link(r.target_id) || '#'
  }
}

async function setStatus(review: ReviewRow, newStatus: ReviewStatus) {
  processing.value = review.id
  const { error } = await supabase
    .from('user_reviews')
    .update({
      status: newStatus,
      moderated_by: auth.user!.id,
      moderated_at: new Date().toISOString()
    })
    .eq('id', review.id)
  processing.value = null
  if (error) {
    alert('Erreur : ' + error.message)
    return
  }
  reviews.value = reviews.value.filter(r => r.id !== review.id)
  await loadCounts()
}

async function approve(r: ReviewRow) { await setStatus(r, 'approved') }
async function reject(r: ReviewRow)  { await setStatus(r, 'rejected') }
async function flag(r: ReviewRow)    { await setStatus(r, 'flagged') }

async function hardDelete(r: ReviewRow) {
  if (!confirm('Supprimer définitivement cet avis ? Cette action est irréversible.')) return
  processing.value = r.id
  const { error } = await supabase.from('user_reviews').delete().eq('id', r.id)
  processing.value = null
  if (error) { alert('Erreur : ' + error.message); return }
  reviews.value = reviews.value.filter(x => x.id !== r.id)
  await loadCounts()
}

async function changeTab(tab: ReviewStatus) {
  statusTab.value = tab
  await load()
}

async function changeTypeFilter(t: TargetType | 'all') {
  typeFilter.value = t
  await load()
}

onMounted(async () => {
  await Promise.all([load(), loadCounts()])
})

function fmtDate(iso: string) {
  return new Date(iso).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' })
}

function stars(n: number) {
  return '★'.repeat(n) + '☆'.repeat(5 - n)
}

const typeFilters: { value: TargetType | 'all'; label: string }[] = [
  { value: 'all', label: 'Tous' },
  { value: 'trip', label: 'Voyages' },
  { value: 'destination', label: 'Destinations' },
  { value: 'accommodation', label: 'Hébergements' },
  { value: 'site', label: 'Sites' },
  { value: 'restaurant', label: 'Restaurants' },
  { value: 'activity', label: 'Activités' },
  { value: 'guide', label: 'Guides' },
  { value: 'operator', label: 'Opérateurs' }
]
</script>

<template>
  <div class="moderation-page">
    <div class="djawal-container djawal-section">
      <div class="back-link">
        <router-link to="/admin">← Retour admin</router-link>
      </div>

      <header class="page-header">
        <div>
          <div class="section-eyebrow">Modération</div>
          <h1>Avis des voyageurs</h1>
          <p class="lead">Approuvez, refusez ou flaggez les avis publiés par les utilisateurs sur tout type de contenu (voyages, destinations, ressources, profils).</p>
        </div>
      </header>

      <!-- Onglets statut -->
      <div class="status-tabs">
        <button class="status-tab" :class="{ active: statusTab === 'pending' }" @click="changeTab('pending')">
          ⏳ En attente <span class="count">{{ counts.pending }}</span>
        </button>
        <button class="status-tab" :class="{ active: statusTab === 'approved' }" @click="changeTab('approved')">
          ✓ Approuvés <span class="count">{{ counts.approved }}</span>
        </button>
        <button class="status-tab" :class="{ active: statusTab === 'flagged' }" @click="changeTab('flagged')">
          🚩 Signalés <span class="count">{{ counts.flagged }}</span>
        </button>
        <button class="status-tab" :class="{ active: statusTab === 'rejected' }" @click="changeTab('rejected')">
          ✕ Refusés <span class="count">{{ counts.rejected }}</span>
        </button>
      </div>

      <!-- Filtre par type de cible -->
      <div class="type-filters">
        <button
          v-for="t in typeFilters"
          :key="t.value"
          class="type-pill"
          :class="{ active: typeFilter === t.value }"
          @click="changeTypeFilter(t.value)"
        >
          {{ t.label }}
        </button>
      </div>

      <div v-if="loading" class="loading">Chargement…</div>

      <div v-else-if="reviews.length === 0" class="empty">
        <p v-if="statusTab === 'pending'">🎉 Aucun avis en attente de modération.</p>
        <p v-else>Aucun avis dans cette catégorie.</p>
      </div>

      <div v-else class="reviews-list">
        <article v-for="r in reviews" :key="r.id" class="review-mod-card">
          <div class="review-head">
            <div class="reviewer">
              <div class="avatar" :style="r.profiles?.avatar_url ? `background-image: url(${r.profiles.avatar_url})` : ''">
                <span v-if="!r.profiles?.avatar_url">{{ (r.profiles?.display_name || '?').charAt(0).toUpperCase() }}</span>
              </div>
              <div>
                <strong>{{ r.profiles?.display_name || 'Utilisateur inconnu' }}</strong>
                <div class="reviewer-meta">{{ fmtDate(r.created_at) }}</div>
              </div>
            </div>
            <div class="rating">{{ stars(r.rating) }}<small>{{ r.rating }}/5</small></div>
          </div>

          <div class="target-row">
            <span class="target-icon">{{ TARGET_ICON[r.target_type] }}</span>
            <span class="target-type">{{ TARGET_LABEL[r.target_type] }}</span>
            <span class="dot">·</span>
            <router-link :to="r.targetLink || '#'" class="target-name">{{ r.targetName || '…' }}</router-link>
          </div>

          <p v-if="r.comment" class="comment">{{ r.comment }}</p>
          <p v-else class="comment empty-comment"><em>(Pas de commentaire — note uniquement)</em></p>

          <div class="actions-row">
            <button
              v-if="statusTab !== 'approved'"
              class="btn btn-approve"
              :disabled="processing === r.id"
              @click="approve(r)"
            >✓ Approuver</button>
            <button
              v-if="statusTab !== 'flagged'"
              class="btn btn-flag"
              :disabled="processing === r.id"
              @click="flag(r)"
            >🚩 Signaler</button>
            <button
              v-if="statusTab !== 'rejected'"
              class="btn btn-reject"
              :disabled="processing === r.id"
              @click="reject(r)"
            >✕ Refuser</button>
            <button
              class="btn btn-delete"
              :disabled="processing === r.id"
              @click="hardDelete(r)"
              title="Suppression définitive"
            >🗑️ Supprimer</button>
          </div>
        </article>
      </div>
    </div>
  </div>
</template>

<style scoped>
.moderation-page { background: var(--c-fond); min-height: 100vh; }
.back-link { margin-bottom: var(--space-3); }
.back-link a { color: var(--c-primaire); text-decoration: none; font-weight: 600; font-size: 14px; }
.back-link a:hover { text-decoration: underline; }

.section-eyebrow {
  color: var(--c-accent-fort);
  font-size: 13px; font-weight: 700;
  letter-spacing: 0.2em; text-transform: uppercase;
  margin-bottom: var(--space-2);
}
.page-header { margin-bottom: var(--space-4); }
.page-header h1 { font-size: clamp(28px, 3.5vw, 40px); margin-bottom: 4px; }
.lead { color: var(--c-texte-doux); max-width: 720px; }

.status-tabs {
  display: flex; gap: var(--space-2);
  border-bottom: 1px solid var(--c-gris-clair);
  margin-bottom: var(--space-3);
  flex-wrap: wrap;
}
.status-tab {
  background: none; border: none;
  border-bottom: 3px solid transparent;
  padding: 12px 16px;
  font-family: inherit;
  font-size: 14px; font-weight: 600;
  color: var(--c-texte-doux);
  cursor: pointer;
  display: inline-flex; align-items: center; gap: 8px;
}
.status-tab:hover { color: var(--c-primaire); }
.status-tab.active { color: var(--c-primaire); border-bottom-color: var(--c-accent); }
.count {
  background: var(--c-fond-chaud);
  padding: 2px 8px;
  border-radius: var(--r-pill);
  font-size: 11px; font-weight: 700;
}

.type-filters {
  display: flex; flex-wrap: wrap; gap: 8px;
  margin-bottom: var(--space-4);
}
.type-pill {
  background: var(--c-surface);
  border: 1px solid var(--c-gris-clair);
  color: var(--c-texte);
  padding: 6px 14px;
  border-radius: var(--r-pill);
  font-size: 12px;
  font-family: inherit;
  cursor: pointer;
  transition: all 0.15s;
}
.type-pill:hover { border-color: var(--c-primaire); }
.type-pill.active {
  background: var(--c-primaire);
  color: white;
  border-color: var(--c-primaire);
}

.reviews-list { display: flex; flex-direction: column; gap: var(--space-3); }

.review-mod-card {
  background: var(--c-surface);
  border-radius: var(--r-lg);
  box-shadow: var(--ombre-douce);
  padding: var(--space-4);
}

.review-head {
  display: flex; justify-content: space-between; align-items: flex-start;
  gap: var(--space-3);
  margin-bottom: var(--space-3);
}
.reviewer { display: flex; align-items: center; gap: 12px; }
.avatar {
  width: 44px; height: 44px;
  border-radius: 50%;
  background: var(--c-fond-chaud) center/cover no-repeat;
  display: flex; align-items: center; justify-content: center;
  font-weight: 600;
  color: var(--c-primaire);
  flex-shrink: 0;
}
.reviewer strong { display: block; font-size: 15px; color: var(--c-texte); }
.reviewer-meta { font-size: 12px; color: var(--c-texte-doux); margin-top: 2px; }

.rating {
  color: var(--c-cta);
  font-size: 16px;
  letter-spacing: 2px;
  text-align: right;
  white-space: nowrap;
}
.rating small {
  display: block;
  font-size: 11px;
  color: var(--c-texte-doux);
  letter-spacing: normal;
  margin-top: 2px;
}

.target-row {
  display: flex; align-items: center; gap: 6px;
  margin-bottom: var(--space-2);
  font-size: 13px;
}
.target-icon { font-size: 18px; }
.target-type {
  background: var(--c-fond-chaud);
  padding: 2px 10px;
  border-radius: var(--r-pill);
  font-size: 11px;
  font-weight: 600;
  color: var(--c-primaire);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
.dot { color: var(--c-texte-doux); }
.target-name {
  color: var(--c-primaire);
  text-decoration: none;
  font-weight: 500;
}
.target-name:hover { text-decoration: underline; }

.comment {
  font-size: 14px;
  color: var(--c-texte);
  line-height: 1.55;
  margin-bottom: var(--space-3);
  padding: var(--space-2) var(--space-3);
  background: var(--c-fond-chaud);
  border-radius: var(--r-md);
  border-left: 3px solid var(--c-accent);
}
.empty-comment {
  font-size: 13px;
  color: var(--c-texte-doux);
  border-left-color: var(--c-gris-clair);
  background: transparent;
  padding-left: 0;
}

.actions-row {
  display: flex; gap: 8px; flex-wrap: wrap;
  border-top: 1px solid var(--c-fond-chaud);
  padding-top: var(--space-3);
}
.btn {
  padding: 8px 16px;
  border-radius: var(--r-pill);
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  font-family: inherit;
  border: 1.5px solid transparent;
  transition: all 0.15s;
}
.btn:disabled { opacity: 0.5; cursor: wait; }
.btn-approve {
  background: #2D5A3D;
  color: white;
}
.btn-approve:hover:not(:disabled) { background: #1E4030; }
.btn-flag {
  background: transparent;
  color: #B8862E;
  border-color: #B8862E;
}
.btn-flag:hover:not(:disabled) { background: #FAEDD2; }
.btn-reject {
  background: transparent;
  color: #A32D2D;
  border-color: #A32D2D;
}
.btn-reject:hover:not(:disabled) { background: #FCEBEB; }
.btn-delete {
  background: transparent;
  color: var(--c-texte-doux);
  border-color: var(--c-gris-clair);
  margin-left: auto;
}
.btn-delete:hover:not(:disabled) {
  color: #791F1F;
  border-color: #A32D2D;
  background: #FCEBEB;
}

.loading, .empty {
  text-align: center;
  padding: var(--space-8);
  color: var(--c-texte-doux);
}

@media (max-width: 720px) {
  .review-head { flex-direction: column; align-items: flex-start; gap: 12px; }
  .rating { text-align: left; }
  .actions-row { flex-direction: column; }
  .btn-delete { margin-left: 0; }
}
</style>
