<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'
import ImageUpload from '@/components/admin/ImageUpload.vue'

/**
 * Sprint 5 — Constructeur de parcours.
 * - Métadonnées du voyage (titre, destination, durée, prix, etc.)
 * - Découpage en journées (trip_days)
 * - Pour chaque journée : étapes (trip_steps) puisées dans le catalogue
 *   hébergements / sites / restaurants / activités de la destination.
 * - Sauvegarde brouillon (status='draft') ou publication (status='published',
 *   le trigger DB rebascule en pending_review pour un guide_junior).
 */

interface Destination { id: string; name: string; wilaya: string; cultural_theme: string }
interface Resource {
  id: string
  name: string
  description: string
  type: 'accommodation' | 'site' | 'restaurant' | 'activity'
}
interface Step {
  id?: string // si existant en base
  tempId: string // identifiant local
  resource_type: 'accommodation' | 'site' | 'restaurant' | 'activity'
  resource_id: string
  resource_name?: string
  note: string
  duration_minutes: number | null
}
interface Day {
  id?: string
  tempId: string
  day_number: number
  theme: string
  description: string
  steps: Step[]
}

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()

// === ÉTAT GLOBAL ===
const editingId = computed(() => (route.params.id as string) || null)
const isEdit = computed(() => !!editingId.value)
const loading = ref(false)
const saving = ref(false)
const error = ref('')
const success = ref('')

// === MÉTADONNÉES ===
const title = ref('')
const titleAr = ref('')
const destinationId = ref<string>('')
const durationDays = ref(3)
const priceDa = ref(15000)
const description = ref('')
const coverImageUrl = ref('')
const maxTravelers = ref(8)
const difficulty = ref<'facile' | 'modere' | 'difficile'>('modere')
const tagsInput = ref('')

const destinations = ref<Destination[]>([])
const days = ref<Day[]>([])

// Catalogue de la destination sélectionnée
const catalog = ref<Resource[]>([])
const catalogTypeFilter = ref<'all' | 'accommodation' | 'site' | 'restaurant' | 'activity'>('all')
// Note: 'accommodation' regroupe l'ensemble des hébergements (hôtel, gîte, maison d'hôte, etc.)
const catalogSearch = ref('')

// === COMPUTED ===
const filteredCatalog = computed(() => {
  const q = catalogSearch.value.toLowerCase().trim()
  return catalog.value.filter(r => {
    if (catalogTypeFilter.value !== 'all' && r.type !== catalogTypeFilter.value) return false
    if (!q) return true
    return r.name.toLowerCase().includes(q) || r.description.toLowerCase().includes(q)
  })
})

const selectedDestination = computed(() =>
  destinations.value.find(d => d.id === destinationId.value)
)

// === INIT ===
onMounted(async () => {
  loading.value = true
  await loadDestinations()
  if (isEdit.value) {
    await loadTrip(editingId.value!)
  } else {
    syncDaysCount() // initialise les journées vides
  }
  loading.value = false
})

async function loadDestinations() {
  const { data } = await supabase
    .from('destinations')
    .select('id, name, wilaya, cultural_theme')
    .order('name')
  destinations.value = (data as Destination[]) || []
}

// Recharger le catalogue quand la destination change
watch(destinationId, async (newId) => {
  if (!newId) {
    catalog.value = []
    return
  }
  await loadCatalog(newId)
})

async function loadCatalog(destId: string) {
  const [accommodationsRes, sitesRes, restaurantsRes, activitiesRes] = await Promise.all([
    supabase.from('accommodations').select('id, name, description, accommodation_type').eq('destination_id', destId),
    supabase.from('sites').select('id, name, description').eq('destination_id', destId),
    supabase.from('restaurants').select('id, name, description').eq('destination_id', destId),
    supabase.from('activities').select('id, name, description').eq('destination_id', destId)
  ])
  const list: Resource[] = []
  for (const h of (accommodationsRes.data as any[] || [])) list.push({ ...h, type: 'accommodation' })
  for (const s of (sitesRes.data as any[] || [])) list.push({ ...s, type: 'site' })
  for (const r of (restaurantsRes.data as any[] || [])) list.push({ ...r, type: 'restaurant' })
  for (const a of (activitiesRes.data as any[] || [])) list.push({ ...a, type: 'activity' })
  catalog.value = list
}

// === GESTION DES JOURNÉES ===
function syncDaysCount() {
  // Garde les journées existantes, ajoute / supprime selon durationDays
  const current = days.value.length
  if (durationDays.value > current) {
    for (let i = current; i < durationDays.value; i++) {
      days.value.push({
        tempId: `day-${Date.now()}-${i}`,
        day_number: i + 1,
        theme: '',
        description: '',
        steps: []
      })
    }
  } else if (durationDays.value < current) {
    days.value = days.value.slice(0, durationDays.value)
  }
}

watch(durationDays, syncDaysCount)

// === GESTION DES ÉTAPES ===
function addStep(day: Day, resource: Resource) {
  day.steps.push({
    tempId: `step-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`,
    resource_type: resource.type,
    resource_id: resource.id,
    resource_name: resource.name,
    note: '',
    duration_minutes: resource.type === 'accommodation' ? null : 120
  })
}

function removeStep(day: Day, tempId: string) {
  day.steps = day.steps.filter(s => s.tempId !== tempId)
}

function moveStep(day: Day, idx: number, delta: number) {
  const target = idx + delta
  if (target < 0 || target >= day.steps.length) return
  const tmp = day.steps[idx]
  day.steps[idx] = day.steps[target]
  day.steps[target] = tmp
}

// === CHARGEMENT EN ÉDITION ===
async function loadTrip(id: string) {
  const { data: trip, error: tripErr } = await supabase
    .from('trips')
    .select('*')
    .eq('id', id)
    .single()
  if (tripErr || !trip) {
    error.value = "Voyage introuvable ou accès refusé."
    return
  }
  title.value = trip.title
  titleAr.value = trip.title_ar || ''
  destinationId.value = trip.destination_id
  durationDays.value = trip.duration_days
  priceDa.value = trip.price_da
  description.value = trip.description
  coverImageUrl.value = trip.cover_image_url || ''
  maxTravelers.value = trip.max_travelers
  difficulty.value = trip.difficulty || 'modere'
  tagsInput.value = (trip.tags || []).join(', ')

  await loadCatalog(trip.destination_id)

  // Charger journées + étapes
  const { data: dayRows } = await supabase
    .from('trip_days')
    .select('*')
    .eq('trip_id', id)
    .order('day_number')

  const dayIds = (dayRows || []).map((d: any) => d.id)
  const stepsByDay: Record<string, Step[]> = {}
  if (dayIds.length > 0) {
    const { data: stepRows } = await supabase
      .from('trip_steps')
      .select('*')
      .in('trip_day_id', dayIds)
      .order('step_order')

    // Récupérer les noms des ressources
    const resourceIds = (stepRows || []).map((s: any) => s.resource_id)
    const resourceNames: Record<string, string> = {}
    if (resourceIds.length > 0) {
      const [h, s, r] = await Promise.all([
        supabase.from('accommodations').select('id, name').in('id', resourceIds),
        supabase.from('sites').select('id, name').in('id', resourceIds),
        supabase.from('restaurants').select('id, name').in('id', resourceIds)
      ])
      for (const x of (h.data as any[] || [])) resourceNames[x.id] = x.name
      for (const x of (s.data as any[] || [])) resourceNames[x.id] = x.name
      for (const x of (r.data as any[] || [])) resourceNames[x.id] = x.name
    }

    for (const step of (stepRows || [])) {
      if (!stepsByDay[step.trip_day_id]) stepsByDay[step.trip_day_id] = []
      stepsByDay[step.trip_day_id].push({
        id: step.id,
        tempId: `step-${step.id}`,
        resource_type: step.resource_type,
        resource_id: step.resource_id,
        resource_name: resourceNames[step.resource_id] || '—',
        note: step.note || '',
        duration_minutes: step.duration_minutes
      })
    }
  }

  days.value = (dayRows || []).map((d: any) => ({
    id: d.id,
    tempId: `day-${d.id}`,
    day_number: d.day_number,
    theme: d.theme || '',
    description: d.description || '',
    steps: stepsByDay[d.id] || []
  }))
}

// === SAUVEGARDE ===
async function save(targetStatus: 'draft' | 'published') {
  error.value = ''
  success.value = ''

  // Validation
  if (!title.value.trim()) { error.value = 'Le titre est requis.'; return }
  if (!destinationId.value) { error.value = 'Choisissez une destination.'; return }
  if (!description.value.trim() || description.value.length < 50) {
    error.value = 'La description doit faire au moins 50 caractères.'; return
  }
  if (priceDa.value < 0) { error.value = 'Le prix ne peut pas être négatif.'; return }

  saving.value = true
  try {
    const tags = tagsInput.value
      .split(',')
      .map(t => t.trim())
      .filter(Boolean)

    const tripPayload = {
      created_by: auth.user!.id,
      title: title.value.trim(),
      title_ar: titleAr.value.trim() || null,
      destination_id: destinationId.value,
      duration_days: durationDays.value,
      price_da: priceDa.value,
      description: description.value.trim(),
      cover_image_url: coverImageUrl.value.trim() || null,
      max_travelers: maxTravelers.value,
      difficulty: difficulty.value,
      tags,
      status: targetStatus
    }

    let tripId = editingId.value
    if (isEdit.value) {
      const { error: upErr } = await supabase
        .from('trips')
        .update(tripPayload)
        .eq('id', tripId!)
      if (upErr) throw upErr
    } else {
      const { data: inserted, error: insErr } = await supabase
        .from('trips')
        .insert(tripPayload)
        .select('id')
        .single()
      if (insErr) throw insErr
      tripId = inserted!.id
    }

    // Sync trip_days : on supprime tout puis on réinsère (plus simple, ok pour MVP)
    if (isEdit.value) {
      await supabase.from('trip_days').delete().eq('trip_id', tripId!)
    }

    for (const day of days.value) {
      const { data: insertedDay, error: dayErr } = await supabase
        .from('trip_days')
        .insert({
          trip_id: tripId!,
          day_number: day.day_number,
          theme: day.theme.trim() || null,
          description: day.description.trim() || null
        })
        .select('id')
        .single()
      if (dayErr) throw dayErr

      // Étapes
      const stepsPayload = day.steps.map((s, idx) => ({
        trip_day_id: insertedDay!.id,
        step_order: idx + 1,
        resource_type: s.resource_type,
        resource_id: s.resource_id,
        note: s.note.trim() || null,
        duration_minutes: s.duration_minutes
      }))
      if (stepsPayload.length > 0) {
        const { error: stepsErr } = await supabase.from('trip_steps').insert(stepsPayload)
        if (stepsErr) throw stepsErr
      }
    }

    success.value = targetStatus === 'published'
      ? 'Voyage publié — il sera visible une fois validé par l\'admin (sauf si vous êtes Senior).'
      : 'Brouillon enregistré.'

    setTimeout(() => router.push('/espace-guide/voyages'), 1200)
  } catch (e: any) {
    console.error(e)
    error.value = e.message || 'Erreur lors de la sauvegarde.'
  } finally {
    saving.value = false
  }
}

function typeIcon(t: string) {
  if (t === 'accommodation') return '🏨'
  if (t === 'restaurant') return '🍴'
  if (t === 'activity') return '🥾'
  return '📍'
}
function typeLabel(t: string) {
  if (t === 'accommodation') return 'Hébergement'
  if (t === 'restaurant') return 'Restaurant'
  if (t === 'activity') return 'Activité'
  return 'Site'
}
</script>

<template>
  <div class="trip-builder">
    <div class="djawal-container djawal-section">
      <div class="builder-header">
        <div>
          <div class="section-eyebrow">Espace Guide</div>
          <h1>{{ isEdit ? 'Modifier le voyage' : 'Nouveau voyage' }}</h1>
          <p v-if="selectedDestination" class="lead">
            Destination : <strong>{{ selectedDestination.name }}</strong> · {{ selectedDestination.wilaya }}
          </p>
        </div>
        <router-link to="/espace-guide/voyages" class="link-back">
          ← Mes voyages
        </router-link>
      </div>

      <v-alert v-if="error" type="error" variant="tonal" class="mb-4">{{ error }}</v-alert>
      <v-alert v-if="success" type="success" variant="tonal" class="mb-4">{{ success }}</v-alert>

      <div v-if="loading" class="loading">Chargement…</div>

      <div v-else class="builder-grid">
        <!-- === COLONNE GAUCHE : MÉTADONNÉES + JOURNÉES === -->
        <div class="main-col">

          <!-- MÉTADONNÉES -->
          <section class="card">
            <h2>📋 Informations générales</h2>
            <div class="grid-2">
              <v-text-field
                v-model="title"
                label="Titre du voyage"
                placeholder="Ex : Tassili — l'épopée des hommes bleus"
                variant="outlined"
                density="comfortable"
              />
              <v-text-field
                v-model="titleAr"
                label="Titre en arabe (optionnel)"
                variant="outlined"
                density="comfortable"
                class="arabic"
              />
              <v-select
                v-model="destinationId"
                :items="destinations.map(d => ({ value: d.id, title: `${d.name} — ${d.wilaya}` }))"
                label="Destination"
                variant="outlined"
                density="comfortable"
              />
              <v-text-field
                v-model.number="durationDays"
                label="Durée (jours)"
                type="number"
                min="1"
                max="30"
                variant="outlined"
                density="comfortable"
              />
              <v-text-field
                v-model.number="priceDa"
                label="Prix par personne (DA)"
                type="number"
                min="0"
                variant="outlined"
                density="comfortable"
              />
              <v-text-field
                v-model.number="maxTravelers"
                label="Voyageurs max"
                type="number"
                min="1"
                max="50"
                variant="outlined"
                density="comfortable"
              />
              <v-select
                v-model="difficulty"
                :items="[
                  { value: 'facile', title: 'Facile' },
                  { value: 'modere', title: 'Modéré' },
                  { value: 'difficile', title: 'Difficile' }
                ]"
                label="Difficulté"
                variant="outlined"
                density="comfortable"
              />
              <v-text-field
                v-model="tagsInput"
                label="Tags (séparés par virgules)"
                placeholder="désert, randonnée, gastronomie"
                variant="outlined"
                density="comfortable"
              />
            </div>
            <v-textarea
              v-model="description"
              label="Description (min. 50 caractères)"
              placeholder="Racontez le voyage : l'esprit, les paysages, les rencontres prévues…"
              variant="outlined"
              density="comfortable"
              rows="4"
              class="mt-3"
            />
            <div class="cover-upload mt-3">
              <ImageUpload
                v-model="coverImageUrl"
                bucket="trip-covers"
                label="Image de couverture (recommandé)"
              />
            </div>
          </section>

          <!-- JOURNÉES -->
          <section class="card">
            <h2>🗓️ Programme jour par jour</h2>
            <div v-if="!destinationId" class="hint">
              Choisis d'abord une destination pour pouvoir construire les journées.
            </div>

            <div v-else-if="days.length === 0" class="hint">Aucune journée.</div>

            <div v-else class="days-list">
              <article v-for="(day, idx) in days" :key="day.tempId" class="day-card">
                <header class="day-header">
                  <div class="day-number">Jour {{ day.day_number }}</div>
                  <v-text-field
                    v-model="day.theme"
                    placeholder="Thème de la journée (ex : Casbah & ruelles)"
                    variant="plain"
                    density="compact"
                    hide-details
                    class="day-theme"
                  />
                </header>
                <v-textarea
                  v-model="day.description"
                  placeholder="Ambiance, conseils, transitions… (optionnel)"
                  variant="outlined"
                  density="compact"
                  rows="2"
                  hide-details
                  class="day-desc"
                />

                <!-- Étapes de la journée -->
                <div class="steps-zone">
                  <div v-if="day.steps.length === 0" class="empty-steps">
                    Glisse une ressource depuis la colonne de droite, ou clique sur ➕
                  </div>
                  <div v-else class="steps-list">
                    <div
                      v-for="(step, sIdx) in day.steps"
                      :key="step.tempId"
                      class="step-row"
                      :data-type="step.resource_type"
                    >
                      <div class="step-icon">{{ typeIcon(step.resource_type) }}</div>
                      <div class="step-main">
                        <div class="step-title">
                          <strong>{{ step.resource_name }}</strong>
                          <span class="step-type">· {{ typeLabel(step.resource_type) }}</span>
                        </div>
                        <div class="step-inputs">
                          <v-text-field
                            v-model="step.note"
                            placeholder="Note (optionnelle)"
                            variant="plain"
                            density="compact"
                            hide-details
                          />
                          <v-text-field
                            v-model.number="step.duration_minutes"
                            type="number"
                            min="0"
                            placeholder="min"
                            variant="plain"
                            density="compact"
                            hide-details
                            style="max-width: 90px"
                          />
                        </div>
                      </div>
                      <div class="step-actions">
                        <button class="step-btn" :disabled="sIdx === 0" @click="moveStep(day, sIdx, -1)" title="Monter">↑</button>
                        <button class="step-btn" :disabled="sIdx === day.steps.length - 1" @click="moveStep(day, sIdx, 1)" title="Descendre">↓</button>
                        <button class="step-btn danger" @click="removeStep(day, step.tempId)" title="Supprimer">✕</button>
                      </div>
                    </div>
                  </div>
                </div>
                <!-- Fin des étapes -->
                <div class="day-footer" v-if="idx === days.length - 1">
                  <span class="hint-sm">Ajuste la durée du voyage pour ajouter ou retirer une journée.</span>
                </div>
              </article>
            </div>
          </section>

          <!-- ACTIONS DE SAUVEGARDE -->
          <section class="card actions-card">
            <div class="actions-row">
              <v-btn
                variant="outlined"
                size="large"
                :loading="saving"
                @click="save('draft')"
              >
                💾 Enregistrer le brouillon
              </v-btn>
              <v-btn
                color="primary"
                variant="flat"
                size="large"
                :loading="saving"
                @click="save('published')"
              >
                🚀 Publier
              </v-btn>
            </div>
            <p class="hint-sm" v-if="auth.isGuideJunior">
              ⓘ En tant que Guide Junior, votre publication passera par une modération admin.
            </p>
            <p class="hint-sm" v-else-if="auth.isGuideSenior">
              ⓘ Guide Senior — vos voyages sont publiés immédiatement.
            </p>
          </section>
        </div>

        <!-- === COLONNE DROITE : CATALOGUE === -->
        <aside class="catalog-col">
          <div class="card catalog-card">
            <h3>📚 Catalogue</h3>
            <p class="catalog-hint" v-if="!destinationId">
              Sélectionne une destination pour afficher les ressources.
            </p>
            <template v-else>
              <v-text-field
                v-model="catalogSearch"
                placeholder="Rechercher…"
                variant="outlined"
                density="compact"
                prepend-inner-icon="mdi-magnify"
                hide-details
              />
              <div class="cat-chips">
                <button
                  v-for="t in [
                    { v: 'all', l: 'Tout', i: '✨' },
                    { v: 'accommodation', l: 'Hébergements', i: '🏨' },
                    { v: 'site', l: 'Sites', i: '📍' },
                    { v: 'restaurant', l: 'Restos', i: '🍴' },
                    { v: 'activity', l: 'Activités', i: '🥾' }
                  ]"
                  :key="t.v"
                  class="cat-chip"
                  :class="{ active: catalogTypeFilter === t.v }"
                  @click="catalogTypeFilter = t.v as any"
                >
                  {{ t.i }} {{ t.l }}
                </button>
              </div>

              <div class="cat-list">
                <div v-if="filteredCatalog.length === 0" class="cat-empty">
                  Aucune ressource pour ce filtre.
                </div>
                <article
                  v-for="r in filteredCatalog"
                  :key="r.id"
                  class="cat-item"
                  :data-type="r.type"
                >
                  <div class="cat-item-head">
                    <span class="cat-icon">{{ typeIcon(r.type) }}</span>
                    <strong>{{ r.name }}</strong>
                  </div>
                  <p class="cat-desc">{{ r.description }}</p>
                  <div class="cat-actions">
                    <select
                      class="cat-day-select"
                      @change="(e) => {
                        const sel = e.target as HTMLSelectElement
                        const idx = parseInt(sel.value)
                        if (!isNaN(idx)) {
                          addStep(days[idx], r)
                          sel.value = ''
                        }
                      }"
                    >
                      <option value="">+ Ajouter à un jour…</option>
                      <option v-for="(d, i) in days" :key="d.tempId" :value="i">
                        Jour {{ d.day_number }}{{ d.theme ? ` — ${d.theme}` : '' }}
                      </option>
                    </select>
                  </div>
                </article>
              </div>
            </template>
          </div>
        </aside>
      </div>
    </div>
  </div>
</template>

<style scoped>
.trip-builder {
  background: var(--c-fond);
  min-height: 100vh;
}

.section-eyebrow {
  color: var(--c-accent-fort);
  font-size: 13px; font-weight: 700;
  letter-spacing: 0.2em; text-transform: uppercase;
  margin-bottom: var(--space-2);
}

.builder-header {
  display: flex; align-items: flex-start; justify-content: space-between;
  gap: var(--space-4);
  margin-bottom: var(--space-5);
  flex-wrap: wrap;
}
.builder-header h1 { font-size: clamp(28px, 3.5vw, 40px); margin-bottom: 4px; }
.lead { color: var(--c-texte-doux); font-size: 15px; }
.link-back {
  color: var(--c-primaire); font-weight: 600;
  text-decoration: none; padding-top: 8px;
}
.link-back:hover { text-decoration: underline; }

.builder-grid {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 360px;
  gap: var(--space-5);
  align-items: start;
}

.card {
  background: var(--c-surface);
  border-radius: var(--r-lg);
  padding: var(--space-5);
  box-shadow: var(--ombre-douce);
  margin-bottom: var(--space-4);
}
.card h2 {
  font-family: var(--font-display);
  font-size: 22px;
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-4);
  border-bottom: 2px solid var(--c-fond-chaud);
  padding-bottom: var(--space-2);
}
.card h3 {
  font-family: var(--font-display);
  font-size: 18px;
  margin-bottom: var(--space-3);
  color: var(--c-primaire-profond);
}

.grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--space-3);
}
@media (max-width: 700px) {
  .grid-2 { grid-template-columns: 1fr; }
}

/* === JOURNÉES === */
.days-list { display: flex; flex-direction: column; gap: var(--space-4); }
.day-card {
  background: var(--c-fond-chaud);
  border-radius: var(--r-md);
  padding: var(--space-4);
  border-left: 4px solid var(--c-primaire);
}
.day-header { display: flex; align-items: center; gap: var(--space-3); margin-bottom: var(--space-3); }
.day-number {
  font-family: var(--font-display);
  font-size: 20px;
  font-weight: 700;
  color: var(--c-primaire-profond);
  flex-shrink: 0;
}
.day-theme { flex: 1; }
.day-desc { margin-bottom: var(--space-3); }

.steps-zone {
  background: var(--c-surface);
  border-radius: var(--r-sm);
  padding: var(--space-3);
  min-height: 80px;
}
.empty-steps {
  color: var(--c-texte-doux);
  font-style: italic;
  text-align: center;
  padding: var(--space-3);
  font-size: 13px;
}
.steps-list { display: flex; flex-direction: column; gap: var(--space-2); }
.step-row {
  display: grid;
  grid-template-columns: 32px 1fr auto;
  gap: var(--space-2);
  align-items: center;
  padding: var(--space-2);
  background: var(--c-fond);
  border-radius: var(--r-sm);
  border-left: 3px solid var(--c-primaire);
}
.step-row[data-type="accommodation"] { border-left-color: #D4A04F; }
.step-row[data-type="site"] { border-left-color: #1B4965; }
.step-row[data-type="restaurant"] { border-left-color: #C97050; }
.step-icon { font-size: 22px; text-align: center; }
.step-main { display: flex; flex-direction: column; gap: 2px; min-width: 0; }
.step-title { font-size: 14px; }
.step-type { color: var(--c-texte-doux); font-size: 12px; }
.step-inputs { display: flex; gap: var(--space-2); align-items: center; }
.step-actions { display: flex; gap: 4px; }
.step-btn {
  background: var(--c-surface);
  border: 1px solid var(--c-gris-clair);
  border-radius: var(--r-sm);
  width: 28px; height: 28px;
  cursor: pointer;
  font-size: 13px;
  color: var(--c-primaire);
  transition: var(--t-base);
}
.step-btn:hover:not(:disabled) { background: var(--c-fond-chaud); }
.step-btn:disabled { opacity: 0.3; cursor: not-allowed; }
.step-btn.danger { color: var(--c-rouge, #c0392b); }

.day-footer { margin-top: var(--space-3); }
.hint, .hint-sm {
  color: var(--c-texte-doux);
  font-size: 13px;
  font-style: italic;
}
.hint-sm { font-size: 12px; margin-top: var(--space-3); }

/* === ACTIONS === */
.actions-card { background: var(--c-fond-chaud); }
.actions-row { display: flex; gap: var(--space-3); flex-wrap: wrap; }

/* === CATALOGUE === */
.catalog-col {
  position: sticky;
  top: 24px;
}
.catalog-card { margin-bottom: 0; }
.catalog-hint { color: var(--c-texte-doux); font-size: 13px; }

.cat-chips {
  display: flex; flex-wrap: wrap; gap: 6px;
  margin: var(--space-3) 0;
}
.cat-chip {
  background: var(--c-fond-chaud);
  border: 1px solid var(--c-gris-clair);
  border-radius: var(--r-pill);
  padding: 4px 10px;
  font-size: 12px; font-weight: 600;
  cursor: pointer;
  color: var(--c-primaire-profond);
  transition: var(--t-base);
}
.cat-chip:hover { border-color: var(--c-accent); }
.cat-chip.active {
  background: var(--c-primaire);
  color: var(--c-fond);
  border-color: var(--c-primaire);
}

.cat-list {
  max-height: 60vh;
  overflow-y: auto;
  display: flex; flex-direction: column; gap: var(--space-2);
  padding-right: 4px;
}
.cat-list::-webkit-scrollbar { width: 6px; }
.cat-list::-webkit-scrollbar-thumb {
  background: var(--c-gris-clair); border-radius: 3px;
}

.cat-empty {
  text-align: center; color: var(--c-texte-doux);
  font-size: 13px; padding: var(--space-3);
}

.cat-item {
  background: var(--c-fond-chaud);
  border-radius: var(--r-sm);
  padding: var(--space-3);
  border-left: 3px solid var(--c-primaire);
}
.cat-item[data-type="accommodation"] { border-left-color: #D4A04F; }
.cat-item[data-type="site"] { border-left-color: #1B4965; }
.cat-item[data-type="restaurant"] { border-left-color: #C97050; }

.cat-item-head { display: flex; align-items: center; gap: 6px; margin-bottom: 4px; }
.cat-icon { font-size: 16px; }
.cat-desc {
  font-size: 12px;
  color: var(--c-texte);
  line-height: 1.4;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  margin-bottom: var(--space-2);
}
.cat-day-select {
  width: 100%;
  padding: 6px 10px;
  font-size: 12px;
  border: 1px solid var(--c-gris-clair);
  border-radius: var(--r-sm);
  background: var(--c-surface);
  cursor: pointer;
  font-family: inherit;
}

.loading { text-align: center; padding: var(--space-8); color: var(--c-texte-doux); }

@media (max-width: 1100px) {
  .builder-grid { grid-template-columns: 1fr; }
  .catalog-col { position: static; }
  .cat-list { max-height: 400px; }
}
</style>
