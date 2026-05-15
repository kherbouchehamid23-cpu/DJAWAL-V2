<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { parseCoordinates } from '@/lib/geo'
import LeafletMap, { type MapMarker } from '@/components/LeafletMap.vue'
import { useSEO } from '@/composables/useSEO'

const route = useRoute()

useSEO({
  title: 'Toutes les destinations algériennes',
  description: 'Explorez les destinations d\'Algérie sur la carte interactive — du Tassili au Djurdjura, de la Casbah à Ghardaïa. Hébergements, sites et restaurants signés par nos guides locaux.'
})

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

interface PublishedTrip {
  id: string
  title: string
  duration_days: number
  price_da: number
  cover_image_url: string | null
  destinations?: { name: string; cultural_theme: string } | null
  profiles?: { display_name: string; role: string } | null
}

const destinations = ref<Destination[]>([])
const publishedTrips = ref<PublishedTrip[]>([])
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

// Pré-remplissage depuis les query params (?theme=saharien&q=desert)
function applyQueryParams() {
  const qTheme = route.query.theme as string | undefined
  const qSearch = route.query.q as string | undefined
  if (qTheme && ['all', 'saharien', 'mauresque', 'aures'].includes(qTheme)) {
    themeFilter.value = qTheme as any
  }
  if (qSearch) {
    searchQuery.value = qSearch
  }
}

// Réagir aux changements de query (navigation depuis la home par ex.)
watch(() => route.query, applyQueryParams)

onMounted(async () => {
  applyQueryParams()
  loading.value = true
  const [destRes, tripsRes] = await Promise.all([
    supabase
      .from('destinations')
      .select('id, name, name_ar, slug, wilaya, cultural_theme, description, hero_image_url, coordinates')
      .order('name'),
    supabase
      .from('trips')
      .select('id, title, duration_days, price_da, cover_image_url, destinations(name, cultural_theme), profiles!trips_created_by_fkey(display_name, role)')
      .eq('status', 'published')
      .order('published_at', { ascending: false })
      .limit(8)
  ])
  if (!destRes.error && destRes.data) destinations.value = destRes.data as Destination[]
  if (!tripsRes.error && tripsRes.data) publishedTrips.value = tripsRes.data as any[]
  loading.value = false
})

function fmtPrice(p: number) {
  return new Intl.NumberFormat('fr-DZ').format(p) + ' DA'
}

function themeBadgeColor(theme: string) {
  return themes.find(t => t.value === theme)?.color || 'var(--c-primaire)'
}

function themeLabel(theme: string) {
  return themes.find(t => t.value === theme)?.label || theme
}
</script>

<template>
  <div class="trips-page">
    <!-- HERO COMPACT — V4 vert sombre avec image Sahara -->
    <header class="trips-hero">
      <div class="trips-hero-overlay"></div>
      <div class="djawal-container hero-content">
        <div class="hero-eyebrow">
          <span class="eyebrow-line"></span>
          <span>Découvrir l'Algérie</span>
          <span class="eyebrow-line"></span>
        </div>
        <h1>Destinations <em>d'Algérie</em></h1>
        <p class="lead">
          {{ destinations.length }} territoires à explorer — du Tassili au Djurdjura,
          de la Casbah à Ghardaïa.
        </p>
      </div>
    </header>

    <!-- FILTRES + RECHERCHE — V4 vert sombre -->
    <section class="filters-bar">
      <div class="djawal-container filters-inner">
        <div class="search-wrap">
          <svg class="search-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="11" cy="11" r="7"/>
            <path d="M21 21 L16 16"/>
          </svg>
          <input
            v-model="searchQuery"
            type="search"
            placeholder="Rechercher : Casbah, Tassili, Béjaïa…"
            class="search-input"
          />
        </div>
        <div class="theme-chips">
          <button
            v-for="t in themes"
            :key="t.value"
            class="chip"
            :class="{ active: themeFilter === t.value }"
            @click="themeFilter = t.value as any"
          >
            <span class="chip-icon">{{ t.icon }}</span>
            {{ t.label }}
          </button>
        </div>
      </div>
    </section>

    <!-- VOYAGES PROPOSÉS PAR NOS GUIDES -->
    <section v-if="publishedTrips.length > 0" class="djawal-container djawal-section trips-showcase">
      <div class="showcase-head">
        <div>
          <div class="section-eyebrow">Parcours signés</div>
          <h2>Voyages signés par <em>nos guides locaux</em></h2>
        </div>
      </div>
      <div class="trip-strip">
        <router-link
          v-for="trip in publishedTrips"
          :key="trip.id"
          :to="`/voyages/${trip.id}`"
          class="trip-strip-card"
        >
          <div
            class="trip-strip-cover"
            :style="trip.cover_image_url ? `background-image: url(${trip.cover_image_url})` : ''"
          >
            <span v-if="trip.profiles?.role === 'guide_senior'" class="senior-badge">⭐ Senior</span>
          </div>
          <div class="trip-strip-body">
            <div class="trip-strip-dest">📍 {{ trip.destinations?.name }}</div>
            <h4>{{ trip.title }}</h4>
            <div class="trip-strip-meta">
              {{ trip.duration_days }}j · {{ fmtPrice(trip.price_da) }}
            </div>
            <div class="trip-strip-author">
              Signé
              <strong>{{ (trip.profiles?.display_name || '').replace(/^./, c => c.toUpperCase()) }}</strong>
              <span v-if="trip.profiles?.role === 'guide_senior'"> · Guide Senior</span>
              <span v-else-if="trip.profiles?.role === 'guide_junior'"> · Guide Junior</span>
            </div>
          </div>
        </router-link>
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
  background: linear-gradient(180deg, #0F2419 0%, #1A3A2A 60%, #0F2419 100%);
  min-height: 100vh;
  color: #FAF7F2;
  font-family: 'Inter', sans-serif;
}

.djawal-container { max-width: 1280px; margin: 0 auto; padding: 0 32px; }
.djawal-section { padding: 80px 0; }

/* === HERO COMPACT V4 === */
.trips-hero {
  position: relative;
  min-height: 52vh;
  display: flex; align-items: center; justify-content: center;
  text-align: center;
  padding: 120px 32px 70px;
  overflow: hidden;
  background-image: url('https://images.pexels.com/photos/3889855/pexels-photo-3889855.jpeg?auto=compress&cs=tinysrgb&w=1920');
  background-size: cover;
  background-position: center;
}
.trips-hero-overlay {
  position: absolute; inset: 0;
  background: linear-gradient(180deg, rgba(15, 36, 25, 0.6) 0%, rgba(15, 36, 25, 0.88) 60%, #0F2419 100%);
  z-index: 1;
}
.hero-content { position: relative; z-index: 2; }
.hero-eyebrow {
  display: inline-flex; align-items: center; gap: 14px;
  color: #E8B96B;
  font-size: 11px; letter-spacing: 0.24em;
  text-transform: uppercase;
  margin-bottom: 22px;
}
.eyebrow-line {
  width: 36px; height: 1px;
  background: linear-gradient(90deg, transparent, #D4A844, transparent);
}
.trips-hero h1 {
  font-family: 'Cormorant Garamond', serif;
  font-size: clamp(36px, 5.5vw, 64px);
  font-weight: 400; line-height: 1.05;
  margin-bottom: 18px;
  color: #FAF7F2;
}
.trips-hero h1 em { font-style: italic; color: #E8B96B; }
.lead {
  font-family: 'Cormorant Garamond', serif;
  font-style: italic;
  font-size: clamp(16px, 2vw, 20px);
  color: rgba(250, 247, 242, 0.78);
  max-width: 640px; margin: 0 auto;
  line-height: 1.5;
}

/* === FILTRES V4 === */
.filters-bar {
  background: rgba(15, 36, 25, 0.92);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  padding: 20px 32px;
  border-bottom: 1px solid rgba(212, 168, 68, 0.2);
  position: sticky;
  top: 0;
  z-index: 50;
}
.filters-inner {
  max-width: 1280px;
  margin: 0 auto;
  display: flex; gap: 20px;
  align-items: center;
  flex-wrap: wrap;
}
.search-wrap {
  position: relative;
  flex: 1;
  min-width: 260px;
  max-width: 460px;
}
.search-icon {
  position: absolute;
  left: 14px; top: 50%;
  transform: translateY(-50%);
  color: #E8B96B;
  pointer-events: none;
}
.search-input {
  width: 100%;
  background: rgba(250, 247, 242, 0.06);
  border: 1px solid rgba(212, 168, 68, 0.3);
  color: #FAF7F2;
  padding: 11px 14px 11px 42px;
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
.theme-chips {
  display: flex; gap: 8px;
  flex-wrap: wrap;
}
.chip {
  display: inline-flex; align-items: center; gap: 6px;
  padding: 8px 16px;
  background: rgba(250, 247, 242, 0.06);
  border: 1px solid rgba(212, 168, 68, 0.25);
  color: #FAF7F2;
  border-radius: 999px;
  font-family: inherit;
  font-size: 13px; font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}
.chip:hover {
  background: rgba(212, 168, 68, 0.15);
  border-color: rgba(212, 168, 68, 0.55);
}
.chip.active {
  background: #D4A844;
  color: #0F2419;
  border-color: #D4A844;
  font-weight: 600;
}
.chip-icon { font-size: 14px; }

/* === SPLIT VIEW === */
.split-view {
  display: grid;
  grid-template-columns: 1.1fr 1fr;
  gap: 32px;
  align-items: start;
}
.list-pane {
  display: flex;
  flex-direction: column;
  gap: 18px;
}
.map-pane {
  position: sticky;
  top: 110px;
  border-radius: 18px;
  overflow: hidden;
  border: 1px solid rgba(212, 168, 68, 0.25);
}
.results-count {
  font-size: 14px;
  color: rgba(250, 247, 242, 0.6);
  margin-bottom: 8px;
}
.results-count strong {
  color: #E8B96B;
  font-family: 'Cormorant Garamond', serif;
  font-style: italic;
  font-size: 26px;
}
.empty-state {
  text-align: center;
  padding: 60px 20px;
  color: rgba(250, 247, 242, 0.55);
  background: rgba(31, 74, 54, 0.4);
  border: 1px dashed rgba(212, 168, 68, 0.25);
  border-radius: 18px;
}

/* === DEST CARD V4 === */
.dest-card {
  display: grid;
  grid-template-columns: 220px 1fr;
  background: rgba(31, 74, 54, 0.5);
  border: 1px solid rgba(212, 168, 68, 0.18);
  border-radius: 18px;
  overflow: hidden;
  cursor: pointer;
  transition: all 0.3s;
  border-left-width: 3px;
  border-left-color: #D4A844;
}
.dest-card[data-theme="saharien"] { border-left-color: #E8B96B; }
.dest-card[data-theme="mauresque"] { border-left-color: #6FA8C0; }
.dest-card[data-theme="aures"] { border-left-color: #A8C76F; }
.dest-card:hover {
  transform: translateY(-3px);
  background: rgba(31, 74, 54, 0.7);
  border-color: rgba(212, 168, 68, 0.5);
  box-shadow: 0 14px 38px rgba(0, 0, 0, 0.45);
}
.card-image {
  background-size: cover;
  background-position: center;
  position: relative;
  min-height: 180px;
}
/* Fallback visuel par thème si pas d'image */
.dest-card[data-theme="saharien"] .card-image {
  background: radial-gradient(circle at 70% 30%, #E8B96B 0%, #B8862E 40%, #5C3D1E 100%);
}
.dest-card[data-theme="mauresque"] .card-image {
  background: linear-gradient(160deg, #3D6890 0%, #1B4965 60%, #0A1F2E 100%);
}
.dest-card[data-theme="aures"] .card-image {
  background: linear-gradient(160deg, #6B7A4A 0%, #2D5A3D 60%, #1B3A28 100%);
}
.dest-card .card-image:not([style*="background-image"])::after {
  content: '';
  position: absolute;
  inset: 0;
  background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='60' height='60' viewBox='0 0 60 60'><g fill='none' stroke='%23FAF7F2' stroke-width='1' opacity='0.18'><path d='M30 4 L52 30 L30 56 L8 30 Z'/><path d='M30 14 L42 30 L30 46 L18 30 Z'/></g></svg>");
  background-repeat: repeat;
  background-size: 60px 60px;
  pointer-events: none;
}
.theme-badge {
  position: absolute; top: 12px; left: 12px;
  padding: 5px 12px;
  border-radius: 999px;
  background: rgba(15, 36, 25, 0.88) !important;
  color: #E8B96B;
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  border: 1px solid rgba(212, 168, 68, 0.4);
  backdrop-filter: blur(8px);
}
.card-body {
  padding: 22px 24px;
  display: flex;
  flex-direction: column;
}
.card-body h3 {
  font-family: 'Cormorant Garamond', serif;
  font-size: 26px;
  font-weight: 500;
  color: #FAF7F2;
  margin-bottom: 4px;
  line-height: 1.1;
}
.card-arabic {
  color: #E8B96B;
  font-family: 'Cormorant Garamond', serif;
  font-style: italic;
  font-size: 15px;
  margin-bottom: 8px;
  opacity: 0.85;
}
.card-meta {
  font-size: 12px;
  color: rgba(250, 247, 242, 0.55);
  margin-bottom: 10px;
  letter-spacing: 0.05em;
}
.card-desc {
  font-size: 13.5px;
  color: rgba(250, 247, 242, 0.72);
  line-height: 1.55;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
  flex: 1;
}
.card-cta {
  margin-top: 14px;
  color: #E8B96B;
  font-weight: 600;
  font-size: 13px;
  letter-spacing: 0.05em;
  transition: transform 0.2s;
}
.dest-card:hover .card-cta { transform: translateX(4px); }

.loading {
  text-align: center;
  padding: 80px 20px;
  color: rgba(250, 247, 242, 0.55);
  font-family: 'Cormorant Garamond', serif;
  font-style: italic;
  font-size: 18px;
}

/* === SHOWCASE VOYAGES SIGNÉS V4 === */
.trips-showcase {
  border-top: 1px solid rgba(212, 168, 68, 0.2);
  border-bottom: 1px solid rgba(212, 168, 68, 0.2);
  padding-top: 70px;
  padding-bottom: 70px;
}
.section-eyebrow {
  color: #E8B96B;
  font-size: 11px; font-weight: 600;
  letter-spacing: 0.24em; text-transform: uppercase;
  margin-bottom: 8px;
}
.showcase-head {
  display: flex; justify-content: space-between; align-items: flex-end;
  margin-bottom: 30px;
}
.showcase-head h2 {
  font-family: 'Cormorant Garamond', serif;
  font-weight: 400;
  font-size: clamp(28px, 3.5vw, 40px);
  color: #FAF7F2;
  line-height: 1.05;
}
.showcase-head h2 em { font-style: italic; color: #E8B96B; }
.trip-strip {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
  gap: 18px;
}
.trip-strip-card {
  background: rgba(31, 74, 54, 0.5);
  border: 1px solid rgba(212, 168, 68, 0.2);
  border-radius: 16px;
  overflow: hidden;
  text-decoration: none;
  color: inherit;
  transition: all 0.3s;
  display: flex;
  flex-direction: column;
}
.trip-strip-card:hover {
  transform: translateY(-4px);
  border-color: rgba(212, 168, 68, 0.55);
  background: rgba(31, 74, 54, 0.75);
  box-shadow: 0 14px 38px rgba(0, 0, 0, 0.45);
}
.trip-strip-cover {
  height: 160px;
  background: linear-gradient(135deg, #B8862E, #5C3D1E);
  background-size: cover;
  background-position: center;
  position: relative;
}
.senior-badge {
  position: absolute; top: 10px; right: 10px;
  background: rgba(15, 36, 25, 0.88);
  color: #E8B96B;
  padding: 4px 10px;
  border-radius: 999px;
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.1em;
  border: 1px solid rgba(212, 168, 68, 0.4);
}
.trip-strip-body { padding: 16px 18px 18px; flex: 1; display: flex; flex-direction: column; }
.trip-strip-dest {
  font-size: 10.5px;
  color: rgba(250, 247, 242, 0.55);
  text-transform: uppercase;
  letter-spacing: 0.14em;
  margin-bottom: 6px;
}
.trip-strip-body h4 {
  font-family: 'Cormorant Garamond', serif;
  font-weight: 500;
  font-size: 19px;
  color: #FAF7F2;
  margin-bottom: 8px;
  line-height: 1.15;
  flex: 1;
}
.trip-strip-meta {
  font-size: 13px;
  color: #E8B96B;
  font-weight: 600;
  margin-bottom: 6px;
  font-family: 'Cormorant Garamond', serif;
  font-style: italic;
}
.trip-strip-author {
  font-size: 11px;
  color: rgba(250, 247, 242, 0.6);
  font-style: italic;
}
.trip-strip-author strong { color: #E8B96B; font-style: normal; font-weight: 600; }

@media (max-width: 980px) {
  .split-view { grid-template-columns: 1fr; }
  .map-pane { position: static; height: 360px; }
  .dest-card { grid-template-columns: 160px 1fr; }
  .trips-hero { min-height: 44vh; padding: 100px 20px 50px; }
  .djawal-section { padding: 50px 0; }
}
@media (max-width: 600px) {
  .dest-card { grid-template-columns: 1fr; }
  .card-image { min-height: 170px; }
  .filters-inner { gap: 12px; }
  .djawal-container { padding: 0 20px; }
  .trips-hero { min-height: 38vh; padding: 90px 20px 40px; }
}
</style>
