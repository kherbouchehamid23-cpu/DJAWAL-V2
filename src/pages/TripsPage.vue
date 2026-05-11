<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { parseCoordinates } from '@/lib/geo'
import LeafletMap, { type MapMarker } from '@/components/LeafletMap.vue'

interface Destination {
  id: string
  name: string
  name_ar: string | null
  slug: string
  wilaya: string
  cultural_theme: 'saharien' | 'mauresque' | 'aures'
  description: string
  hero_image_url: string | null
  coordinates: any
}

const destinations = ref<Destination[]>([])
const loading = ref(true)
const searchQuery = ref('')
const themeFilter = ref<'all' | 'saharien' | 'mauresque' | 'aures'>('all')

const themes = [
  { value: 'all', label: 'Tout', icon: '✨', color: 'var(--c-primaire)' },
  { value: 'saharien', label: 'Saharien', icon: '🏜️', color: '#D4A04F' },
  { value: 'mauresque', label: 'Mauresque', icon: '🏛️', color: '#1B4965' },
  { value: 'aures', label: 'Aurès', icon: '⛰️', color: '#2D5A3D' }
]

const filteredDestinations = computed(() => {
  const q = searchQuery.value.toLowerCase().trim()
  return destinations.value.filter(d => {
    if (themeFilter.value !== 'all' && d.cultural_theme !== themeFilter.value) return false
    if (!q) return true
    return d.name.toLowerCase().includes(q) ||
           d.wilaya.toLowerCase().includes(q) ||
           d.description.toLowerCase().includes(q)
  })
})

const mapMarkers = computed<MapMarker[]>(() => {
  return filteredDestinations.value
    .map(d => {
      const coords = parseCoordinates(d.coordinates)
      if (!coords) return null
      return {
        id: d.id,
        lat: coords.lat,
        lng: coords.lng,
        title: d.name,
        subtitle: d.wilaya,
        theme: d.cultural_theme,
        url: `/destination/${d.slug}`
      } as MapMarker
    })
    .filter((m): m is MapMarker => m !== null)
})

onMounted(async () => {
  loading.value = true
  const { data, error } = await supabase
    .from('destinations')
    .select('id, name, name_ar, slug, wilaya, cultural_theme, description, hero_image_url, coordinates')
    .order('name')
  if (!error && data) destinations.value = data as Destination[]
  loading.value = false
})

function themeBadgeColor(theme: string) {
  return themes.find(t => t.value === theme)?.color || 'var(--c-primaire)'
}

function themeLabel(theme: string) {
  return themes.find(t => t.value === theme)?.label || theme
}
</script>

<template>
  <div class="trips-page">
    <!-- HEADER -->
    <header class="trips-hero">
      <div class="djawal-container">
        <div class="hero-tag arabic">اكتشف الجزائر</div>
        <h1>Découvrir les destinations</h1>
        <p class="lead">
          {{ destinations.length }} destinations algériennes — du Tassili au Djurdjura,
          de la Casbah à Ghardaïa.
        </p>
      </div>
    </header>

    <!-- FILTRES + RECHERCHE -->
    <section class="filters-bar">
      <div class="djawal-container filters-inner">
        <v-text-field
          v-model="searchQuery"
          density="comfortable"
          variant="outlined"
          placeholder="Rechercher : Casbah, Tassili, Béjaïa…"
          prepend-inner-icon="mdi-magnify"
          clearable
          hide-details
          class="search-field"
        />
        <div class="theme-chips">
          <button
            v-for="t in themes"
            :key="t.value"
            class="chip"
            :class="{ active: themeFilter === t.value }"
            :style="themeFilter === t.value ? `background: ${t.color}; color: var(--c-fond);` : ''"
            @click="themeFilter = t.value as any"
          >
            <span class="chip-icon">{{ t.icon }}</span>
            {{ t.label }}
          </button>
        </div>
      </div>
    </section>

    <!-- CARTE + LISTE -->
    <section class="djawal-container djawal-section">
      <div v-if="loading" class="loading">Chargement des destinations…</div>

      <div v-else class="split-view">
        <!-- Liste -->
        <div class="list-pane">
          <div class="results-count">
            <strong>{{ filteredDestinations.length }}</strong> destination{{ filteredDestinations.length > 1 ? 's' : '' }}
          </div>

          <div v-if="filteredDestinations.length === 0" class="empty-state">
            <p>Aucune destination ne correspond à ta recherche.</p>
          </div>

          <article
            v-for="dest in filteredDestinations"
            :key="dest.id"
            class="dest-card"
            :data-theme="dest.cultural_theme"
            @click="$router.push(`/destination/${dest.slug}`)"
          >
            <div
              class="card-image"
              :style="dest.hero_image_url ? `background-image: url(${dest.hero_image_url})` : ''"
            >
              <span
                class="theme-badge"
                :style="`background: ${themeBadgeColor(dest.cultural_theme)}`"
              >
                {{ themeLabel(dest.cultural_theme) }}
              </span>
            </div>
            <div class="card-body">
              <h3>{{ dest.name }}</h3>
              <div v-if="dest.name_ar" class="card-arabic arabic">{{ dest.name_ar }}</div>
              <div class="card-meta">📍 {{ dest.wilaya }}</div>
              <p class="card-desc">{{ dest.description }}</p>
              <div class="card-cta">Découvrir →</div>
            </div>
          </article>
        </div>

        <!-- Carte -->
        <div class="map-pane">
          <LeafletMap
            :markers="mapMarkers"
            :center="[28.0339, 1.6596]"
            :zoom="5"
            height="calc(100vh - 240px)"
            @marker-click="(m: MapMarker) => $router.push(m.url || '/')"
          />
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.trips-page {
  background: var(--c-fond);
  min-height: 100vh;
}

/* === HERO === */
.trips-hero {
  background: var(--c-fond-chaud);
  padding: var(--space-7) var(--space-5) var(--space-5);
  position: relative;
  overflow: hidden;
}
.trips-hero::before {
  content: ''; position: absolute; inset: 0;
  background-image: var(--motif-principal-url);
  opacity: 0.4;
  pointer-events: none;
}
.hero-tag {
  font-size: 20px;
  color: var(--c-accent-fort);
  margin-bottom: 8px;
  position: relative;
}
.trips-hero h1 {
  font-size: clamp(32px, 4vw, 48px);
  color: var(--c-primaire-profond);
  margin-bottom: 8px;
  position: relative;
}
.lead {
  font-size: 17px;
  color: var(--c-primaire);
  max-width: 720px;
  position: relative;
}

/* === FILTRES === */
.filters-bar {
  background: var(--c-surface);
  padding: var(--space-3) var(--space-5);
  border-bottom: 1px solid var(--c-gris-clair);
  position: sticky;
  top: 72px;
  z-index: 10;
  box-shadow: 0 2px 8px rgba(0,0,0,0.04);
}
.filters-inner {
  display: flex; gap: var(--space-4);
  align-items: center;
  flex-wrap: wrap;
}
.search-field {
  flex: 1;
  min-width: 280px;
  max-width: 480px;
}
.theme-chips {
  display: flex; gap: var(--space-2);
  flex-wrap: wrap;
}
.chip {
  display: inline-flex; align-items: center; gap: 6px;
  padding: 8px 16px;
  background: var(--c-fond-chaud);
  border: 1px solid var(--c-gris-clair);
  border-radius: var(--r-pill);
  font-family: inherit;
  font-size: 13px; font-weight: 600;
  color: var(--c-primaire-profond);
  cursor: pointer;
  transition: var(--t-base);
}
.chip:hover { border-color: var(--c-accent); }
.chip.active { border-color: transparent; box-shadow: var(--ombre-douce); }
.chip-icon { font-size: 14px; }

/* === SPLIT VIEW === */
.split-view {
  display: grid;
  grid-template-columns: 1.1fr 1fr;
  gap: var(--space-5);
  align-items: start;
}
.list-pane {
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
}
.map-pane {
  position: sticky;
  top: 160px;
}
.results-count {
  font-size: 14px;
  color: var(--c-texte-doux);
  margin-bottom: var(--space-2);
}
.results-count strong {
  color: var(--c-primaire);
  font-family: var(--font-display);
  font-size: 22px;
}
.empty-state {
  text-align: center;
  padding: var(--space-7);
  color: var(--c-texte-doux);
}

/* === DEST CARD === */
.dest-card {
  display: grid;
  grid-template-columns: 200px 1fr;
  background: var(--c-surface);
  border-radius: var(--r-lg);
  overflow: hidden;
  box-shadow: var(--ombre-douce);
  cursor: pointer;
  transition: var(--t-base);
  border-left: 4px solid var(--c-primaire);
}
.dest-card[data-theme="saharien"] { border-left-color: #D4A04F; }
.dest-card[data-theme="mauresque"] { border-left-color: #1B4965; }
.dest-card[data-theme="aures"] { border-left-color: #2D5A3D; }
.dest-card:hover {
  transform: translateY(-2px);
  box-shadow: var(--ombre-elevee);
}
.card-image {
  background: linear-gradient(135deg, #D4A04F, #C97050);
  background-size: cover;
  background-position: center;
  position: relative;
}
.theme-badge {
  position: absolute; top: 12px; left: 12px;
  padding: 4px 10px;
  border-radius: var(--r-pill);
  color: var(--c-fond);
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  box-shadow: 0 2px 8px rgba(0,0,0,0.2);
}
.card-body {
  padding: var(--space-4);
  display: flex;
  flex-direction: column;
}
.card-body h3 {
  font-family: var(--font-display);
  font-size: 24px;
  color: var(--c-primaire-profond);
  margin-bottom: 4px;
}
.card-arabic {
  color: var(--c-accent-fort);
  font-size: 16px;
  margin-bottom: 6px;
}
.card-meta {
  font-size: 13px;
  color: var(--c-texte-doux);
  margin-bottom: var(--space-2);
}
.card-desc {
  font-size: 13px;
  color: var(--c-texte);
  line-height: 1.5;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
  flex: 1;
}
.card-cta {
  margin-top: var(--space-3);
  color: var(--c-accent-fort);
  font-weight: 700;
  font-size: 14px;
}

.loading { text-align: center; padding: var(--space-8); color: var(--c-texte-doux); }

@media (max-width: 980px) {
  .split-view { grid-template-columns: 1fr; }
  .map-pane { position: static; height: 360px; }
  .dest-card { grid-template-columns: 140px 1fr; }
}
@media (max-width: 600px) {
  .dest-card { grid-template-columns: 1fr; }
  .card-image { height: 160px; }
  .filters-inner { gap: var(--space-2); }
}
</style>
