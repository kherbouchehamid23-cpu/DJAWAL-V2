<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

interface Trip {
  id: string
  title: string
  destination_id: string
  duration_days: number
  price_da: number
  status: 'draft' | 'pending_review' | 'published' | 'rejected'
  cover_image_url: string | null
  created_at: string
  published_at: string | null
  review_notes: string | null
  destinations?: { name: string; wilaya: string } | null
}

const auth = useAuthStore()
const trips = ref<Trip[]>([])
const loading = ref(true)
const statusFilter = ref<'all' | 'draft' | 'pending_review' | 'published' | 'rejected'>('all')
const deleting = ref<string | null>(null)

const filtered = computed(() => {
  if (statusFilter.value === 'all') return trips.value
  return trips.value.filter(t => t.status === statusFilter.value)
})

const counts = computed(() => ({
  all: trips.value.length,
  draft: trips.value.filter(t => t.status === 'draft').length,
  pending_review: trips.value.filter(t => t.status === 'pending_review').length,
  published: trips.value.filter(t => t.status === 'published').length,
  rejected: trips.value.filter(t => t.status === 'rejected').length
}))

async function load() {
  loading.value = true
  const { data, error } = await supabase
    .from('trips')
    .select('id, title, destination_id, duration_days, price_da, status, cover_image_url, created_at, published_at, review_notes, destinations(name, wilaya)')
    .eq('created_by', auth.user!.id)
    .order('created_at', { ascending: false })
  if (!error && data) trips.value = data as any[]
  loading.value = false
}

onMounted(load)

async function deleteTrip(trip: Trip) {
  if (!confirm(`Supprimer définitivement "${trip.title}" ? Cette action est irréversible.`)) return
  deleting.value = trip.id
  const { error } = await supabase.from('trips').delete().eq('id', trip.id)
  deleting.value = null
  if (error) {
    alert('Erreur lors de la suppression : ' + error.message)
    return
  }
  trips.value = trips.value.filter(t => t.id !== trip.id)
}

function statusLabel(s: string) {
  return {
    draft: 'Brouillon',
    pending_review: 'En modération',
    published: 'Publié',
    rejected: 'Refusé'
  }[s] || s
}
function statusColor(s: string) {
  return {
    draft: '#8B8680',
    pending_review: '#D4A04F',
    published: '#2D5A3D',
    rejected: '#C04A3A'
  }[s] || '#666'
}
function fmtDate(iso: string) {
  return new Date(iso).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric' })
}
function fmtPrice(p: number) {
  return new Intl.NumberFormat('fr-DZ').format(p) + ' DA'
}
</script>

<template>
  <div class="my-trips-page">
    <div class="djawal-container djawal-section">
      <header class="page-header">
        <div>
          <div class="section-eyebrow">Espace Guide</div>
          <h1>Mes voyages</h1>
          <p class="lead">{{ trips.length }} parcours créés</p>
        </div>
        <router-link to="/espace-guide/voyages/nouveau">
          <v-btn color="primary" variant="flat" size="large">+ Nouveau voyage</v-btn>
        </router-link>
      </header>

      <!-- Filtres status -->
      <div class="status-tabs">
        <button
          v-for="s in [
            { v: 'all', l: 'Tous' },
            { v: 'draft', l: 'Brouillons' },
            { v: 'pending_review', l: 'En modération' },
            { v: 'published', l: 'Publiés' },
            { v: 'rejected', l: 'Refusés' }
          ]"
          :key="s.v"
          class="status-tab"
          :class="{ active: statusFilter === s.v }"
          @click="statusFilter = s.v as any"
        >
          {{ s.l }}
          <span class="count">{{ (counts as any)[s.v] }}</span>
        </button>
      </div>

      <div v-if="loading" class="loading">Chargement…</div>

      <div v-else-if="filtered.length === 0" class="empty">
        <p v-if="trips.length === 0">
          Vous n'avez pas encore créé de voyage.
        </p>
        <p v-else>Aucun voyage dans cette catégorie.</p>
        <router-link to="/espace-guide/voyages/nouveau" v-if="trips.length === 0">
          <v-btn color="primary" variant="flat">Créer mon premier voyage</v-btn>
        </router-link>
      </div>

      <div v-else class="trips-grid">
        <article v-for="trip in filtered" :key="trip.id" class="trip-card">
          <div
            class="trip-cover"
            :style="trip.cover_image_url ? `background-image: url(${trip.cover_image_url})` : ''"
          >
            <span
              class="status-badge"
              :style="`background: ${statusColor(trip.status)}`"
            >
              {{ statusLabel(trip.status) }}
            </span>
          </div>
          <div class="trip-body">
            <h3>{{ trip.title }}</h3>
            <div class="trip-meta">
              📍 {{ trip.destinations?.name || '—' }}
              <span class="dot">·</span>
              {{ trip.duration_days }}j
              <span class="dot">·</span>
              {{ fmtPrice(trip.price_da) }}
            </div>

            <div v-if="trip.status === 'rejected' && trip.review_notes" class="reject-note">
              <strong>Motif :</strong> {{ trip.review_notes }}
            </div>

            <div class="trip-dates">
              Créé le {{ fmtDate(trip.created_at) }}
              <span v-if="trip.published_at">· Publié le {{ fmtDate(trip.published_at) }}</span>
            </div>

            <div class="trip-actions">
              <router-link :to="`/espace-guide/voyages/${trip.id}`">
                <v-btn variant="outlined" size="small">✏️ Éditer</v-btn>
              </router-link>
              <router-link
                v-if="trip.status === 'published'"
                :to="`/voyages/${trip.id}`"
              >
                <v-btn variant="text" size="small">👁️ Voir</v-btn>
              </router-link>
              <v-btn
                variant="text"
                size="small"
                color="error"
                :loading="deleting === trip.id"
                @click="deleteTrip(trip)"
              >
                🗑️
              </v-btn>
            </div>
          </div>
        </article>
      </div>
    </div>
  </div>
</template>

<style scoped>
.my-trips-page { background: var(--c-fond); min-height: 100vh; }
.section-eyebrow {
  color: var(--c-accent-fort);
  font-size: 13px; font-weight: 700;
  letter-spacing: 0.2em; text-transform: uppercase;
  margin-bottom: var(--space-2);
}
.page-header {
  display: flex; justify-content: space-between; align-items: flex-end;
  gap: var(--space-4);
  margin-bottom: var(--space-5);
  flex-wrap: wrap;
}
.page-header h1 { font-size: clamp(28px, 3.5vw, 40px); margin-bottom: 4px; }
.lead { color: var(--c-texte-doux); }

.status-tabs {
  display: flex; gap: var(--space-2);
  border-bottom: 1px solid var(--c-gris-clair);
  margin-bottom: var(--space-4);
  flex-wrap: wrap;
}
.status-tab {
  background: none;
  border: none;
  border-bottom: 3px solid transparent;
  padding: 12px 16px;
  font-family: inherit;
  font-size: 14px;
  font-weight: 600;
  color: var(--c-texte-doux);
  cursor: pointer;
  display: inline-flex; align-items: center; gap: 8px;
  transition: var(--t-base);
}
.status-tab:hover { color: var(--c-primaire); }
.status-tab.active {
  color: var(--c-primaire);
  border-bottom-color: var(--c-accent);
}
.count {
  background: var(--c-fond-chaud);
  padding: 2px 8px;
  border-radius: var(--r-pill);
  font-size: 11px;
  font-weight: 700;
}

.trips-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: var(--space-4);
}

.trip-card {
  background: var(--c-surface);
  border-radius: var(--r-lg);
  overflow: hidden;
  box-shadow: var(--ombre-douce);
  transition: var(--t-base);
}
.trip-card:hover {
  transform: translateY(-3px);
  box-shadow: var(--ombre-elevee);
}
.trip-cover {
  height: 160px;
  background: linear-gradient(135deg, #D4A04F, #C97050);
  background-size: cover;
  background-position: center;
  position: relative;
}
.status-badge {
  position: absolute; top: 12px; left: 12px;
  padding: 4px 10px;
  border-radius: var(--r-pill);
  color: var(--c-fond);
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  box-shadow: 0 2px 6px rgba(0,0,0,0.2);
}
.trip-body { padding: var(--space-4); }
.trip-body h3 {
  font-family: var(--font-display);
  font-size: 20px;
  color: var(--c-primaire-profond);
  margin-bottom: 6px;
  line-height: 1.2;
}
.trip-meta {
  font-size: 13px;
  color: var(--c-texte);
  margin-bottom: var(--space-2);
}
.dot { color: var(--c-texte-doux); margin: 0 4px; }
.trip-dates {
  font-size: 12px;
  color: var(--c-texte-doux);
  margin: var(--space-2) 0 var(--space-3);
}
.reject-note {
  background: rgba(192, 74, 58, 0.08);
  color: #C04A3A;
  padding: 8px 12px;
  border-radius: var(--r-sm);
  font-size: 13px;
  margin: var(--space-2) 0;
}
.trip-actions { display: flex; gap: 6px; flex-wrap: wrap; }

.loading, .empty {
  text-align: center;
  padding: var(--space-8);
  color: var(--c-texte-doux);
}
.empty p { margin-bottom: var(--space-3); }
</style>
