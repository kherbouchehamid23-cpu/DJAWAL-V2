<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

interface PendingTrip {
  id: string
  title: string
  description: string
  duration_days: number
  price_da: number
  cover_image_url: string | null
  created_at: string
  status: string
  destinations?: { name: string; wilaya: string } | null
  profiles?: { display_name: string; role: string } | null
}

const auth = useAuthStore()
const trips = ref<PendingTrip[]>([])
const loading = ref(true)
const statusTab = ref<'pending_review' | 'published' | 'rejected'>('pending_review')
const processing = ref<string | null>(null)
const reviewNotes = ref<Record<string, string>>({})

async function load() {
  loading.value = true
  const { data } = await supabase
    .from('trips')
    .select('id, title, description, duration_days, price_da, cover_image_url, created_at, status, destinations(name, wilaya), profiles!trips_created_by_fkey(display_name, role)')
    .eq('status', statusTab.value)
    .order('created_at', { ascending: false })
  trips.value = (data as any) || []
  loading.value = false
}

onMounted(load)

async function approve(trip: PendingTrip) {
  processing.value = trip.id
  const { error } = await supabase
    .from('trips')
    .update({
      status: 'published',
      published_at: new Date().toISOString(),
      reviewed_by: auth.user!.id,
      reviewed_at: new Date().toISOString(),
      review_notes: reviewNotes.value[trip.id]?.trim() || null
    })
    .eq('id', trip.id)
  processing.value = null
  if (error) {
    alert('Erreur : ' + error.message)
    return
  }
  trips.value = trips.value.filter(t => t.id !== trip.id)
}

async function reject(trip: PendingTrip) {
  const note = reviewNotes.value[trip.id]?.trim()
  if (!note) {
    alert('Merci d\'indiquer un motif de refus pour aider le guide.')
    return
  }
  processing.value = trip.id
  const { error } = await supabase
    .from('trips')
    .update({
      status: 'rejected',
      reviewed_by: auth.user!.id,
      reviewed_at: new Date().toISOString(),
      review_notes: note
    })
    .eq('id', trip.id)
  processing.value = null
  if (error) {
    alert('Erreur : ' + error.message)
    return
  }
  trips.value = trips.value.filter(t => t.id !== trip.id)
}

async function changeTab(tab: 'pending_review' | 'published' | 'rejected') {
  statusTab.value = tab
  await load()
}

const counts = ref({ pending: 0, published: 0, rejected: 0 })

async function loadCounts() {
  const [p, pub, r] = await Promise.all([
    supabase.from('trips').select('id', { count: 'exact', head: true }).eq('status', 'pending_review'),
    supabase.from('trips').select('id', { count: 'exact', head: true }).eq('status', 'published'),
    supabase.from('trips').select('id', { count: 'exact', head: true }).eq('status', 'rejected')
  ])
  counts.value = {
    pending: p.count || 0,
    published: pub.count || 0,
    rejected: r.count || 0
  }
}
onMounted(loadCounts)

function fmtDate(iso: string) {
  return new Date(iso).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric' })
}
function fmtPrice(p: number) {
  return new Intl.NumberFormat('fr-DZ').format(p) + ' DA'
}
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
          <h1>Voyages soumis à validation</h1>
          <p class="lead">Approuvez ou refusez les parcours créés par les guides juniors.</p>
        </div>
      </header>

      <div class="status-tabs">
        <button
          class="status-tab"
          :class="{ active: statusTab === 'pending_review' }"
          @click="changeTab('pending_review')"
        >
          ⏳ En attente <span class="count">{{ counts.pending }}</span>
        </button>
        <button
          class="status-tab"
          :class="{ active: statusTab === 'published' }"
          @click="changeTab('published')"
        >
          ✓ Publiés <span class="count">{{ counts.published }}</span>
        </button>
        <button
          class="status-tab"
          :class="{ active: statusTab === 'rejected' }"
          @click="changeTab('rejected')"
        >
          ✕ Refusés <span class="count">{{ counts.rejected }}</span>
        </button>
      </div>

      <div v-if="loading" class="loading">Chargement…</div>

      <div v-else-if="trips.length === 0" class="empty">
        <p v-if="statusTab === 'pending_review'">🎉 Aucun voyage en attente de validation.</p>
        <p v-else>Aucun voyage dans cette catégorie.</p>
      </div>

      <div v-else class="trips-list">
        <article v-for="trip in trips" :key="trip.id" class="trip-mod-card">
          <div
            class="trip-cover"
            :style="trip.cover_image_url ? `background-image: url(${trip.cover_image_url})` : ''"
          ></div>
          <div class="trip-body">
            <div class="trip-head">
              <h3>{{ trip.title }}</h3>
              <div class="trip-meta">
                📍 {{ trip.destinations?.name }} · {{ trip.destinations?.wilaya }}
                <span class="dot">·</span>
                {{ trip.duration_days }}j
                <span class="dot">·</span>
                {{ fmtPrice(trip.price_da) }}
              </div>
              <div class="trip-author">
                Par <strong>{{ trip.profiles?.display_name }}</strong>
                <span class="role-badge" :data-role="trip.profiles?.role">
                  {{ trip.profiles?.role === 'guide_senior' ? 'Senior' : 'Junior' }}
                </span>
                <span class="dot">·</span>
                Soumis le {{ fmtDate(trip.created_at) }}
              </div>
            </div>

            <p class="trip-desc">{{ trip.description }}</p>

            <div class="actions-zone" v-if="statusTab === 'pending_review'">
              <v-textarea
                v-model="reviewNotes[trip.id]"
                placeholder="Notes / motif de refus (optionnel pour approbation, requis pour refus)…"
                variant="outlined"
                density="compact"
                rows="2"
                hide-details
              />
              <div class="actions-row">
                <router-link :to="`/voyages/${trip.id}`">
                  <v-btn variant="outlined" size="small">👁️ Prévisualiser</v-btn>
                </router-link>
                <v-btn
                  color="success"
                  variant="flat"
                  :loading="processing === trip.id"
                  @click="approve(trip)"
                >
                  ✓ Approuver & publier
                </v-btn>
                <v-btn
                  color="error"
                  variant="outlined"
                  :loading="processing === trip.id"
                  @click="reject(trip)"
                >
                  ✕ Refuser
                </v-btn>
              </div>
            </div>

            <div v-else class="archive-actions">
              <router-link :to="`/voyages/${trip.id}`">
                <v-btn variant="outlined" size="small">👁️ Voir</v-btn>
              </router-link>
            </div>
          </div>
        </article>
      </div>
    </div>
  </div>
</template>

<style scoped>
.moderation-page { background: var(--c-fond); min-height: 100vh; }
.back-link { margin-bottom: var(--space-3); }
.back-link a {
  color: var(--c-primaire);
  text-decoration: none;
  font-weight: 600;
  font-size: 14px;
}
.back-link a:hover { text-decoration: underline; }

.section-eyebrow {
  color: var(--c-accent-fort);
  font-size: 13px; font-weight: 700;
  letter-spacing: 0.2em; text-transform: uppercase;
  margin-bottom: var(--space-2);
}
.page-header { margin-bottom: var(--space-4); }
.page-header h1 { font-size: clamp(28px, 3.5vw, 40px); margin-bottom: 4px; }
.lead { color: var(--c-texte-doux); max-width: 640px; }

.status-tabs {
  display: flex;
  gap: var(--space-2);
  border-bottom: 1px solid var(--c-gris-clair);
  margin-bottom: var(--space-4);
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
.status-tab.active {
  color: var(--c-primaire);
  border-bottom-color: var(--c-accent);
}
.count {
  background: var(--c-fond-chaud);
  padding: 2px 8px;
  border-radius: var(--r-pill);
  font-size: 11px; font-weight: 700;
}

.trips-list { display: flex; flex-direction: column; gap: var(--space-4); }

.trip-mod-card {
  background: var(--c-surface);
  border-radius: var(--r-lg);
  overflow: hidden;
  box-shadow: var(--ombre-douce);
  display: grid;
  grid-template-columns: 240px 1fr;
}
.trip-cover {
  background: linear-gradient(135deg, #D4A04F, #C97050);
  background-size: cover;
  background-position: center;
  min-height: 200px;
}
.trip-body { padding: var(--space-4); }
.trip-head { margin-bottom: var(--space-3); }
.trip-head h3 {
  font-family: var(--font-display);
  font-size: 24px;
  color: var(--c-primaire-profond);
  margin-bottom: 4px;
}
.trip-meta { font-size: 13px; color: var(--c-texte); margin-bottom: 4px; }
.trip-author { font-size: 13px; color: var(--c-texte-doux); }
.role-badge {
  display: inline-block;
  padding: 2px 8px;
  border-radius: var(--r-pill);
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-left: 6px;
  background: var(--c-fond-chaud);
  color: var(--c-primaire);
}
.role-badge[data-role="guide_senior"] { background: var(--c-vert-success, #2D5A3D); color: white; }

.dot { margin: 0 4px; color: var(--c-texte-doux); }

.trip-desc {
  font-size: 14px;
  color: var(--c-texte);
  line-height: 1.5;
  margin-bottom: var(--space-3);
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.actions-zone {
  border-top: 1px solid var(--c-fond-chaud);
  padding-top: var(--space-3);
}
.actions-row {
  display: flex;
  gap: var(--space-2);
  margin-top: var(--space-3);
  flex-wrap: wrap;
}
.archive-actions { display: flex; gap: var(--space-2); }

.loading, .empty {
  text-align: center;
  padding: var(--space-8);
  color: var(--c-texte-doux);
}

@media (max-width: 800px) {
  .trip-mod-card { grid-template-columns: 1fr; }
  .trip-cover { min-height: 160px; }
}
</style>
