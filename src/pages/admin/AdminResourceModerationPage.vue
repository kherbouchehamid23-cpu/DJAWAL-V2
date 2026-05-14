<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()

type ResourceTable = 'accommodations' | 'restaurants' | 'activities'

interface PendingResource {
  id: string
  name: string
  description: string
  destination_id: string | null
  status: string
  created_at: string
  accommodation_type?: string | null
  cuisine?: string[] | null
  activity_type?: string | null
  difficulty?: string | null
  duration_hours?: number | null
  price_da?: number | null
  images?: string[] | null
  star_rating?: number | null
  amenities?: string[] | null
  review_reason?: string | null
  destination?: { name: string; wilaya: string } | null
  creator?: { display_name: string; company_name: string | null; operator_type: string | null } | null
}

const tableMap: Record<ResourceTable, { label: string; icon: string }> = {
  accommodations: { label: 'Hébergements', icon: '🏨' },
  restaurants: { label: 'Restaurants', icon: '🍽️' },
  activities: { label: 'Activités', icon: '🥾' }
}

const currentTable = ref<ResourceTable>(
  (route.query.type as ResourceTable) || 'accommodations'
)
const statusTab = ref<'pending_review' | 'published' | 'rejected'>('pending_review')

const resources = ref<PendingResource[]>([])
const loading = ref(true)
const processing = ref<string | null>(null)
const reviewReasons = ref<Record<string, string>>({})
const errorMsg = ref<string | null>(null)
const successMsg = ref<string | null>(null)

// Compteurs pour les tabs
const counts = ref<Record<ResourceTable, number>>({
  accommodations: 0,
  restaurants: 0,
  activities: 0
})

const operatorTypeIcons: Record<string, string> = {
  travel_agency: '🧭',
  restaurant: '🍽️',
  accommodation_provider: '🏨',
  artisan: '🧶'
}

onMounted(async () => {
  await Promise.all([load(), loadCounts()])
})

watch([currentTable, statusTab], async () => {
  await load()
})

async function loadCounts() {
  const [a, r, ac] = await Promise.all([
    supabase.from('accommodations').select('id', { count: 'exact', head: true }).eq('status', 'pending_review'),
    supabase.from('restaurants').select('id', { count: 'exact', head: true }).eq('status', 'pending_review'),
    supabase.from('activities').select('id', { count: 'exact', head: true }).eq('status', 'pending_review')
  ])
  counts.value = {
    accommodations: a.count ?? 0,
    restaurants: r.count ?? 0,
    activities: ac.count ?? 0
  }
}

async function load() {
  loading.value = true
  errorMsg.value = null

  const { data, error } = await supabase
    .from(currentTable.value)
    .select(`
      *,
      destination:destinations(name, wilaya),
      creator:profiles!${currentTable.value}_created_by_fkey(display_name, company_name, operator_type)
    `)
    .eq('status', statusTab.value)
    .not('created_by', 'is', null)
    .order('created_at', { ascending: false })

  if (error) {
    // Fallback sans FK explicite (au cas où la convention de nommage Supabase diffère)
    const { data: fbData, error: fbErr } = await supabase
      .from(currentTable.value)
      .select('*, destination:destinations(name, wilaya)')
      .eq('status', statusTab.value)
      .not('created_by', 'is', null)
      .order('created_at', { ascending: false })
    if (fbErr) {
      errorMsg.value = fbErr.message
      loading.value = false
      return
    }
    // Enrichir avec les profils du créateur en deuxième requête
    const creatorIds = [...new Set((fbData || []).map((r: any) => r.created_by))]
    let creators: any[] = []
    if (creatorIds.length > 0) {
      const { data: profs } = await supabase
        .from('profiles')
        .select('id, display_name, company_name, operator_type')
        .in('id', creatorIds)
      creators = profs || []
    }
    resources.value = (fbData || []).map((r: any) => ({
      ...r,
      creator: creators.find(c => c.id === r.created_by) || null
    }))
  } else {
    resources.value = (data as any) || []
  }
  loading.value = false
}

async function approve(resource: PendingResource) {
  processing.value = resource.id
  errorMsg.value = null

  const { error } = await supabase
    .from(currentTable.value)
    .update({
      status: 'published',
      validated_at: new Date().toISOString(),
      validated_by: auth.user!.id,
      reviewed_by: auth.user!.id,
      reviewed_at: new Date().toISOString(),
      review_reason: null
    })
    .eq('id', resource.id)

  processing.value = null
  if (error) {
    errorMsg.value = 'Erreur : ' + error.message
    return
  }

  successMsg.value = `« ${resource.name} » approuvé et publié.`
  resources.value = resources.value.filter(r => r.id !== resource.id)
  await loadCounts()
  setTimeout(() => (successMsg.value = null), 3500)
}

async function reject(resource: PendingResource) {
  const reason = reviewReasons.value[resource.id]?.trim()
  if (!reason) {
    errorMsg.value = 'Indiquez un motif de refus pour aider l\'opérateur à corriger.'
    return
  }

  processing.value = resource.id
  errorMsg.value = null

  const { error } = await supabase
    .from(currentTable.value)
    .update({
      status: 'rejected',
      reviewed_by: auth.user!.id,
      reviewed_at: new Date().toISOString(),
      review_reason: reason
    })
    .eq('id', resource.id)

  processing.value = null
  if (error) {
    errorMsg.value = 'Erreur : ' + error.message
    return
  }

  successMsg.value = `« ${resource.name} » refusé. L'opérateur peut corriger et resoumettre.`
  resources.value = resources.value.filter(r => r.id !== resource.id)
  await loadCounts()
  setTimeout(() => (successMsg.value = null), 3500)
}

function changeTab(t: ResourceTable) {
  currentTable.value = t
  router.replace({ query: { ...route.query, type: t } })
}

function formatDate(d: string) {
  return new Date(d).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short', year: 'numeric' })
}

const totalPending = computed(() =>
  counts.value.accommodations + counts.value.restaurants + counts.value.activities
)
</script>

<template>
  <div class="djawal-container moderation-page">
    <nav class="breadcrumb">
      <router-link to="/admin">← Tableau de bord</router-link>
    </nav>

    <header class="page-head">
      <div>
        <div class="eyebrow">Administration · Modération ressources</div>
        <h1>Soumissions opérateurs</h1>
        <p class="lead">
          {{ totalPending }} ressource{{ totalPending > 1 ? 's' : '' }} en attente de validation,
          toutes catégories confondues.
        </p>
      </div>
    </header>

    <v-alert v-if="errorMsg" type="error" variant="tonal" class="mb-4" closable @click:close="errorMsg=null">
      {{ errorMsg }}
    </v-alert>
    <v-alert v-if="successMsg" type="success" variant="tonal" class="mb-4">
      {{ successMsg }}
    </v-alert>

    <!-- Tabs entre types de ressources -->
    <div class="type-tabs">
      <button
        v-for="(meta, key) in tableMap"
        :key="key"
        class="type-tab"
        :class="{ active: currentTable === key }"
        @click="changeTab(key as ResourceTable)"
      >
        <span class="tab-icon">{{ meta.icon }}</span>
        {{ meta.label }}
        <span v-if="counts[key as ResourceTable] > 0" class="tab-badge">
          {{ counts[key as ResourceTable] }}
        </span>
      </button>
    </div>

    <!-- Filtres status -->
    <div class="status-tabs">
      <button
        class="status-tab"
        :class="{ active: statusTab === 'pending_review' }"
        @click="statusTab = 'pending_review'"
      >
        En attente
      </button>
      <button
        class="status-tab"
        :class="{ active: statusTab === 'published' }"
        @click="statusTab = 'published'"
      >
        Publiés
      </button>
      <button
        class="status-tab"
        :class="{ active: statusTab === 'rejected' }"
        @click="statusTab = 'rejected'"
      >
        Refusés
      </button>
    </div>

    <div v-if="loading" class="loading">Chargement des ressources…</div>

    <div v-else-if="resources.length === 0" class="empty">
      <div class="empty-icon">✓</div>
      <p v-if="statusTab === 'pending_review'">
        Rien à modérer pour les {{ tableMap[currentTable].label.toLowerCase() }}.
      </p>
      <p v-else>Aucun {{ tableMap[currentTable].label.toLowerCase() }} dans cet état.</p>
    </div>

    <div v-else class="resources-list">
      <article v-for="r in resources" :key="r.id" class="resource-card">
        <header class="resource-head">
          <div class="resource-title">
            <strong>{{ r.name }}</strong>
            <div class="resource-meta">
              <span v-if="r.destination">📍 {{ r.destination.name }} · {{ r.destination.wilaya }}</span>
              <span v-if="r.accommodation_type"> · {{ r.accommodation_type }}</span>
              <span v-if="r.activity_type"> · {{ r.activity_type }}</span>
              <span v-if="r.cuisine && r.cuisine.length > 0"> · {{ r.cuisine.join(', ') }}</span>
            </div>
          </div>
          <div class="resource-creator" v-if="r.creator">
            <span class="creator-icon">{{ operatorTypeIcons[r.creator.operator_type as string] || '👤' }}</span>
            <div>
              <strong>{{ r.creator.company_name || r.creator.display_name }}</strong>
              <small v-if="r.creator.company_name">{{ r.creator.display_name }}</small>
            </div>
          </div>
        </header>

        <div class="resource-body">
          <p class="resource-desc">{{ r.description }}</p>

          <div class="resource-details">
            <span v-if="r.star_rating">⭐ {{ r.star_rating }} étoiles</span>
            <span v-if="r.duration_hours">⏱️ {{ r.duration_hours }}h</span>
            <span v-if="r.price_da">💰 {{ r.price_da }} DA</span>
            <span v-if="r.difficulty">📊 {{ r.difficulty }}</span>
            <span class="submission-date">Soumis le {{ formatDate(r.created_at) }}</span>
          </div>

          <div v-if="r.review_reason && statusTab === 'rejected'" class="reject-reason">
            <strong>Motif de refus :</strong> {{ r.review_reason }}
          </div>
        </div>

        <!-- Actions de modération (uniquement pour pending_review) -->
        <div v-if="statusTab === 'pending_review'" class="resource-actions">
          <v-textarea
            v-model="reviewReasons[r.id]"
            label="Motif (obligatoire pour rejet)"
            rows="2"
            density="compact"
            hide-details
            class="reason-input"
          />
          <div class="action-buttons">
            <v-btn
              color="error"
              variant="outlined"
              size="small"
              :loading="processing === r.id"
              @click="reject(r)"
            >
              Refuser
            </v-btn>
            <v-btn
              color="success"
              variant="flat"
              size="small"
              :loading="processing === r.id"
              @click="approve(r)"
            >
              Approuver
            </v-btn>
          </div>
        </div>
      </article>
    </div>
  </div>
</template>

<style scoped>
.moderation-page {
  max-width: 1100px;
  margin: 0 auto;
  padding: var(--space-6) var(--space-5);
}
.breadcrumb { margin-bottom: var(--space-4); }
.breadcrumb a {
  color: var(--c-primaire);
  text-decoration: none;
  font-size: 13px;
  font-weight: 600;
}

.page-head { margin-bottom: var(--space-5); }
.eyebrow {
  color: var(--c-accent-fort);
  font-size: 12px;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  font-weight: 700;
  margin-bottom: var(--space-2);
}
h1 {
  font-family: var(--font-display);
  font-size: clamp(28px, 4vw, 38px);
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-2);
}
.lead { color: var(--c-texte-doux); }

/* === Tabs types === */
.type-tabs {
  display: flex;
  gap: var(--space-2);
  margin-bottom: var(--space-3);
  border-bottom: 1px solid var(--c-gris-clair);
  flex-wrap: wrap;
}
.type-tab {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: var(--space-3) var(--space-4);
  background: none;
  border: none;
  font-family: inherit;
  font-size: 14px;
  cursor: pointer;
  color: var(--c-texte-doux);
  border-bottom: 3px solid transparent;
  transition: var(--t-base);
  font-weight: 500;
}
.type-tab.active {
  color: var(--c-primaire-profond);
  border-bottom-color: var(--c-accent-fort);
  font-weight: 700;
}
.tab-icon { font-size: 18px; }
.tab-badge {
  background: var(--c-cta, #C04A3A);
  color: white;
  font-size: 11px;
  font-weight: 700;
  padding: 2px 8px;
  border-radius: 999px;
  min-width: 22px;
  text-align: center;
}

/* === Tabs status === */
.status-tabs {
  display: flex;
  gap: var(--space-2);
  margin-bottom: var(--space-4);
}
.status-tab {
  padding: 8px 16px;
  background: var(--c-fond-chaud);
  border: 1px solid var(--c-gris-clair);
  border-radius: var(--r-pill);
  font-family: inherit;
  font-size: 13px;
  cursor: pointer;
  color: var(--c-texte-doux);
  transition: var(--t-base);
}
.status-tab.active {
  background: var(--c-primaire-profond);
  color: var(--c-fond);
  border-color: var(--c-primaire-profond);
}

.loading, .empty {
  text-align: center;
  padding: var(--space-8);
  color: var(--c-texte-doux);
}
.empty-icon {
  width: 64px; height: 64px;
  background: rgba(107, 122, 74, 0.15);
  color: #6B7A4A;
  border-radius: 50%;
  margin: 0 auto var(--space-3);
  display: flex; align-items: center; justify-content: center;
  font-size: 28px; font-weight: 700;
}

/* === Liste resources === */
.resources-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}
.resource-card {
  background: var(--c-surface);
  border-radius: var(--r-md);
  box-shadow: var(--ombre-douce);
  overflow: hidden;
  border-left: 4px solid var(--c-accent);
}
.resource-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  padding: var(--space-4);
  gap: var(--space-3);
  flex-wrap: wrap;
  border-bottom: 1px solid var(--c-gris-clair);
}
.resource-title strong {
  display: block;
  font-size: 18px;
  color: var(--c-primaire-profond);
  margin-bottom: 4px;
}
.resource-meta {
  font-size: 13px;
  color: var(--c-texte-doux);
}
.resource-creator {
  display: flex;
  align-items: center;
  gap: 8px;
  background: var(--c-fond-chaud);
  padding: 6px 12px;
  border-radius: var(--r-pill);
  font-size: 13px;
}
.creator-icon { font-size: 18px; }
.resource-creator strong {
  display: block;
  color: var(--c-primaire-profond);
  font-size: 13px;
}
.resource-creator small {
  display: block;
  color: var(--c-texte-doux);
  font-size: 11px;
}

.resource-body { padding: var(--space-4); }
.resource-desc {
  color: var(--c-texte);
  line-height: 1.6;
  margin-bottom: var(--space-3);
}
.resource-details {
  display: flex;
  gap: var(--space-3);
  flex-wrap: wrap;
  font-size: 13px;
  color: var(--c-texte-doux);
}
.submission-date { margin-left: auto; font-style: italic; }

.reject-reason {
  margin-top: var(--space-3);
  padding: var(--space-3);
  background: rgba(192, 74, 58, 0.08);
  border-left: 3px solid #C04A3A;
  border-radius: 4px;
  font-size: 13px;
  color: var(--c-texte);
}
.reject-reason strong { color: #C04A3A; }

.resource-actions {
  padding: var(--space-3) var(--space-4);
  background: var(--c-fond-chaud);
  border-top: 1px solid var(--c-gris-clair);
}
.reason-input { margin-bottom: var(--space-2); }
.action-buttons {
  display: flex;
  gap: var(--space-2);
  justify-content: flex-end;
}
</style>
