<script setup lang="ts">
import { ref, computed, onMounted, watch, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { parseCoordinates } from '@/lib/geo'
import LeafletMap, { type MapMarker } from '@/components/LeafletMap.vue'
import FavoriteButton from '@/components/FavoriteButton.vue'
import FeaturedBadge from '@/components/FeaturedBadge.vue'
import { useSEO } from '@/composables/useSEO'

const route = useRoute()
const router = useRouter()

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
const sortBy = ref<'name' | 'theme' | 'wilaya'>('name')

// === UI state mobile ===
const filtersDrawerOpen = ref(false)
const mobileMapOpen = ref(false)
const showAutocomplete = ref(false)
const searchInputRef = ref<HTMLInputElement | null>(null)

const themes = [
  { value: 'all', label: 'Tout', icon: '✨', color: 'var(--c-primaire)' },
  { value: 'saharien', label: 'Saharien', icon: '🏜️', color: '#D4A04F' },
  { value: 'mauresque', label: 'Mauresque', icon: '🏛️', color: '#1B4965' },
  { value: 'aures', label: 'Aurès', icon: '⛰️', color: '#2D5A3D' }
]

const sortOptions = [
  { value: 'name', label: 'Nom (A → Z)' },
  { value: 'theme', label: 'Par thème culturel' },
  { value: 'wilaya', label: 'Par wilaya' }
]

// === Recherche tolérante : retire accents + lowercase
// "bejaia" matchera "Béjaïa", "tassili" matchera "Tassili n'Ajjer", etc.
function normalizeSearch(s: string): string {
  // NFD décompose les caractères accentués (é → e + ◌́),
  // puis on retire la plage Unicode U+0300–U+036F (combining diacritics).
  return s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase()
}

// === Filtres + tri ===
const filteredDestinations = computed(() => {
  const q = normalizeSearch(searchQuery.value.trim())
  const filtered = destinations.value.filter(d => {
    if (themeFilter.value !== 'all' && d.cultural_theme !== themeFilter.value) return false
    if (!q) return true
    return normalizeSearch(d.name).includes(q) ||
           normalizeSearch(d.wilaya).includes(q) ||
           normalizeSearch(d.description).includes(q)
  })
  // Tri
  return [...filtered].sort((a, b) => {
    if (sortBy.value === 'theme') return a.cultural_theme.localeCompare(b.cultural_theme) || a.name.localeCompare(b.name)
    if (sortBy.value === 'wilaya') return a.wilaya.localeCompare(b.wilaya) || a.name.localeCompare(b.name)
    return a.name.localeCompare(b.name)
  })
})

// Destination vedette = première du résultat filtré (mise en avant éditoriale)
// Elle prend toute la largeur en grid si pas de filtre actif et pas de recherche
const showFeatured = computed(() => {
  return !searchQuery.value.trim() && themeFilter.value === 'all' && filteredDestinations.value.length > 1
})

const featuredDestination = computed(() => {
  return showFeatured.value ? filteredDestinations.value[0] : null
})

const gridDestinations = computed(() => {
  return showFeatured.value ? filteredDestinations.value.slice(1) : filteredDestinations.value
})

// Autocomplete : top 5 matches (tolérant aux accents/casse)
const autocompleteResults = computed(() => {
  const q = normalizeSearch(searchQuery.value.trim())
  if (!q || q.length < 2) return []
  return destinations.value
    .filter(d =>
      normalizeSearch(d.name).includes(q) ||
      normalizeSearch(d.wilaya).includes(q)
    )
    .slice(0, 5)
})

// Compteur lisible
const hasActiveFilters = computed(() => {
  return searchQuery.value.trim() !== '' || themeFilter.value !== 'all'
})

const activeFiltersLabel = computed(() => {
  const parts: string[] = []
  if (themeFilter.value !== 'all') {
    parts.push(themes.find(t => t.value === themeFilter.value)?.label || themeFilter.value)
  }
  if (searchQuery.value.trim()) {
    parts.push(`« ${searchQuery.value.trim()} »`)
  }
  return parts.join(' · ')
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

// === URL persistence ===
function applyQueryParams() {
  const qTheme = route.query.theme as string | undefined
  const qSearch = route.query.q as string | undefined
  const qSort = route.query.sort as string | undefined
  if (qTheme && ['all', 'saharien', 'mauresque', 'aures'].includes(qTheme)) {
    themeFilter.value = qTheme as any
  }
  if (qSearch) {
    searchQuery.value = qSearch
  }
  if (qSort && ['name', 'theme', 'wilaya'].includes(qSort)) {
    sortBy.value = qSort as any
  }
}

// Sync filtres → URL (sans push history pour ne pas polluer le back)
let urlUpdateTimer: any = null
function updateURL() {
  if (urlUpdateTimer) clearTimeout(urlUpdateTimer)
  urlUpdateTimer = setTimeout(() => {
    const q: Record<string, string> = {}
    if (themeFilter.value !== 'all') q.theme = themeFilter.value
    if (searchQuery.value.trim()) q.q = searchQuery.value.trim()
    if (sortBy.value !== 'name') q.sort = sortBy.value
    router.replace({ query: q })
  }, 250)
}

watch(() => route.query, applyQueryParams)
watch([themeFilter, searchQuery, sortBy], updateURL)

onMounted(async () => {
  applyQueryParams()
  loading.value = true
  const [destRes, tripsRes] = await Promise.all([
    supabase
      .from('destinations')
      .select('id, name, name_ar, slug, wilaya, cultural_theme, description, hero_image_url, coordinates, display_order')
      .order('display_order', { ascending: true })
      .order('name', { ascending: true }),
    supabase
      .from('trips')
      .select('id, title, duration_days, price_da, cover_image_url, featured_label, destinations(name, cultural_theme), profiles!trips_created_by_fkey(display_name, role)')
      .eq('status', 'published')
      .order('featured_label', { ascending: false, nullsFirst: false })
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

function clearAllFilters() {
  searchQuery.value = ''
  themeFilter.value = 'all'
  showAutocomplete.value = false
}

function selectAutocomplete(dest: Destination) {
  showAutocomplete.value = false
  // Force le clavier iOS à se fermer AVANT la navigation pour éviter
  // que le viewport ne se réajuste pendant la transition (effet saccadé).
  searchInputRef.value?.blur()
  // Reset la position de scroll en amont pour éviter l'animation visible.
  window.scrollTo({ top: 0, left: 0, behavior: 'auto' })
  // Petit délai pour laisser le clavier se rétracter sur iOS, puis nav.
  setTimeout(() => {
    router.push(`/destination/${dest.slug}`)
  }, 60)
}

function focusSearch() {
  nextTick(() => searchInputRef.value?.focus())
}

function onSearchBlur() {
  // léger délai pour permettre le click sur une suggestion
  setTimeout(() => { showAutocomplete.value = false }, 180)
}

function openMobileFilters() {
  filtersDrawerOpen.value = true
  document.body.style.overflow = 'hidden'
}
function closeMobileFilters() {
  filtersDrawerOpen.value = false
  document.body.style.overflow = ''
}
function openMobileMap() {
  mobileMapOpen.value = true
  document.body.style.overflow = 'hidden'
}
function closeMobileMap() {
  mobileMapOpen.value = false
  document.body.style.overflow = ''
}
</script>

<template>
  <div class="trips-page">
    <!-- HERO COMPACT — V4 vert sombre avec vidéo Algérie -->
    <header class="trips-hero">
      <!-- Backdrop flouté desktop (remplit les côtés en widescreen) -->
      <video
        class="trips-hero-video-backdrop"
        src="/videos/algerie-hero.mp4"
        autoplay muted loop playsinline preload="metadata"
        aria-hidden="true"
      ></video>
      <!-- Vidéo principale (image entière, sans crop) -->
      <video
        class="trips-hero-video"
        src="/videos/algerie-hero.mp4"
        poster="/videos/algerie-hero-poster.jpg"
        autoplay
        muted
        loop
        playsinline
        preload="metadata"
        aria-hidden="true"
      ></video>
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

    <!-- BARRE DE RECHERCHE + FILTRES (desktop + collapsable mobile) -->
    <section class="filters-bar">
      <div class="djawal-container filters-inner">

        <!-- Search avec autocomplete -->
        <div class="search-wrap">
          <svg class="search-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="11" cy="11" r="7"/>
            <path d="M21 21 L16 16"/>
          </svg>
          <input
            ref="searchInputRef"
            v-model="searchQuery"
            type="search"
            placeholder="Rechercher : Casbah, Tassili, Béjaïa…"
            class="search-input"
            enterkeyhint="search"
            inputmode="search"
            autocomplete="off"
            @focus="showAutocomplete = true"
            @blur="onSearchBlur"
          />
          <button
            v-if="searchQuery"
            type="button"
            class="search-clear"
            aria-label="Effacer la recherche"
            @mousedown.prevent="searchQuery = ''; focusSearch()"
          >×</button>

          <!-- Autocomplete dropdown -->
          <div
            v-if="showAutocomplete && autocompleteResults.length > 0"
            class="autocomplete-list"
          >
            <button
              v-for="d in autocompleteResults"
              :key="d.id"
              type="button"
              class="autocomplete-item"
              :data-theme="d.cultural_theme"
              @mousedown.prevent="selectAutocomplete(d)"
            >
              <span class="autocomplete-dot"></span>
              <div class="autocomplete-text">
                <strong>{{ d.name }}</strong>
                <small>{{ d.wilaya }} · {{ themeLabel(d.cultural_theme) }}</small>
              </div>
            </button>
          </div>
        </div>

        <!-- Chips thèmes — desktop visible / mobile via drawer -->
        <div class="theme-chips theme-chips-desktop">
          <span class="filter-label">Filtrer :</span>
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

        <!-- Tri desktop -->
        <div class="sort-wrap">
          <label class="sort-label" for="trips-sort">Trier :</label>
          <select id="trips-sort" v-model="sortBy" class="sort-select">
            <option v-for="o in sortOptions" :key="o.value" :value="o.value">{{ o.label }}</option>
          </select>
        </div>

        <!-- Mobile : bouton "Filtres" qui ouvre le drawer -->
        <button class="mobile-filter-btn" type="button" @click="openMobileFilters" aria-label="Ouvrir les filtres">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M3 6h18M6 12h12M10 18h4"/>
          </svg>
          <span>Filtres</span>
          <span v-if="hasActiveFilters" class="mobile-filter-dot"></span>
        </button>
      </div>
    </section>

    <!-- COMPTEUR + FILTRES ACTIFS (sous la barre, dans le flow normal) -->
    <section class="djawal-container results-meta" v-if="!loading">
      <div class="results-count-wrap">
        <span class="results-count">
          <strong>{{ filteredDestinations.length }}</strong>
          destination{{ filteredDestinations.length > 1 ? 's' : '' }}
        </span>
        <span v-if="hasActiveFilters" class="active-pill">
          {{ activeFiltersLabel }}
          <button type="button" class="active-pill-clear" @click="clearAllFilters" aria-label="Effacer les filtres">×</button>
        </span>
      </div>

      <!-- Toggle Vue Carte mobile -->
      <button type="button" class="mobile-map-btn" @click="openMobileMap" aria-label="Voir sur la carte">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M21 10 c 0 7 -9 13 -9 13 s -9 -6 -9 -13 a 9 9 0 0 1 18 0 z"/>
          <circle cx="12" cy="10" r="3"/>
        </svg>
        Voir la carte
      </button>
    </section>

    <!-- CARTE + LISTE -->
    <section class="djawal-container djawal-section results-section">
      <div v-if="loading" class="loading">Chargement des destinations…</div>

      <div v-else-if="filteredDestinations.length === 0" class="empty-state">
        <div class="empty-icon">🌵</div>
        <h3>Aucune destination ne correspond</h3>
        <p>Essayez d'élargir votre recherche ou de retirer un filtre.</p>
        <button class="empty-reset" type="button" @click="clearAllFilters">Effacer les filtres</button>
      </div>

      <div v-else class="split-view">
        <!-- LISTE -->
        <div class="list-pane">

          <!-- DESTINATION VEDETTE — full width -->
          <article
            v-if="featuredDestination"
            class="dest-card-featured"
            :data-theme="featuredDestination.cultural_theme"
            @click="$router.push(`/destination/${featuredDestination.slug}`)"
          >
            <div
              class="featured-image"
              :style="featuredDestination.hero_image_url ? `background-image: url(${featuredDestination.hero_image_url})` : ''"
            >
              <span class="featured-tag">✦ Coup de cœur</span>
              <span class="theme-badge" :style="`background: ${themeBadgeColor(featuredDestination.cultural_theme)}`">
                {{ themeLabel(featuredDestination.cultural_theme) }}
              </span>
              <FavoriteButton
                target-type="destination"
                :target-id="featuredDestination.id"
                size="md"
                floating
              />
            </div>
            <div class="featured-body">
              <h3>{{ featuredDestination.name }}</h3>
              <div v-if="featuredDestination.name_ar" class="card-arabic arabic">{{ featuredDestination.name_ar }}</div>
              <div class="card-meta">📍 {{ featuredDestination.wilaya }}</div>
              <p class="featured-desc">{{ featuredDestination.description }}</p>
              <div class="card-cta">Découvrir cette destination →</div>
            </div>
          </article>

          <!-- GRILLE DESTINATIONS -->
          <div class="dest-grid">
            <article
              v-for="dest in gridDestinations"
              :key="dest.id"
              class="dest-card"
              :data-theme="dest.cultural_theme"
              @click="$router.push(`/destination/${dest.slug}`)"
            >
              <div
                class="card-image"
                :style="dest.hero_image_url ? `background-image: url(${dest.hero_image_url})` : ''"
              >
                <span class="theme-badge" :style="`background: ${themeBadgeColor(dest.cultural_theme)}`">
                  {{ themeLabel(dest.cultural_theme) }}
                </span>
                <FavoriteButton
                  target-type="destination"
                  :target-id="dest.id"
                  size="sm"
                  floating
                />
              </div>
              <div class="card-body">
                <h3>{{ dest.name }}</h3>
                <div v-if="dest.name_ar" class="card-arabic arabic">{{ dest.name_ar }}</div>
                <div class="card-meta">📍 {{ dest.wilaya }}</div>
                <p class="card-desc">{{ dest.description }}</p>
              </div>
            </article>
          </div>
        </div>

        <!-- CARTE (desktop sticky) -->
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

    <!-- VOYAGES SIGNÉS — déplacé APRÈS la liste (recommandations en bas) -->
    <section v-if="publishedTrips.length > 0" class="djawal-container djawal-section trips-showcase">
      <div class="showcase-head">
        <div>
          <div class="section-eyebrow">Parcours signés</div>
          <h2>Voyages signés par <em>nos guides locaux</em></h2>
          <p class="showcase-sub">Des itinéraires composés par des guides certifiés Djawal.</p>
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
            <FeaturedBadge :label="trip.featured_label" size="sm" position="top-left" />
            <FavoriteButton
              target-type="trip"
              :target-id="trip.id"
              size="sm"
              floating
            />
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

    <!-- ===== MOBILE : drawer filtres ===== -->
    <transition name="slide-up">
      <div v-if="filtersDrawerOpen" class="mobile-filters-drawer" @click.self="closeMobileFilters">
        <div class="drawer-sheet">
          <div class="drawer-handle"></div>
          <div class="drawer-head">
            <h3>Filtres</h3>
            <button type="button" class="drawer-close" @click="closeMobileFilters" aria-label="Fermer">×</button>
          </div>

          <div class="drawer-section">
            <label class="drawer-label">Thème culturel</label>
            <div class="theme-chips theme-chips-mobile">
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

          <div class="drawer-section">
            <label class="drawer-label" for="trips-sort-mobile">Trier par</label>
            <select id="trips-sort-mobile" v-model="sortBy" class="sort-select-mobile">
              <option v-for="o in sortOptions" :key="o.value" :value="o.value">{{ o.label }}</option>
            </select>
          </div>

          <div class="drawer-actions">
            <button type="button" class="drawer-btn-ghost" @click="clearAllFilters">Tout effacer</button>
            <button type="button" class="drawer-btn-primary" @click="closeMobileFilters">
              Voir les {{ filteredDestinations.length }} destination{{ filteredDestinations.length > 1 ? 's' : '' }}
            </button>
          </div>
        </div>
      </div>
    </transition>

    <!-- ===== MOBILE : vue carte plein écran ===== -->
    <transition name="fade-up">
      <div v-if="mobileMapOpen" class="mobile-map-overlay">
        <div class="mobile-map-head">
          <span>{{ filteredDestinations.length }} destination{{ filteredDestinations.length > 1 ? 's' : '' }} sur la carte</span>
          <button type="button" class="mobile-map-close" @click="closeMobileMap" aria-label="Fermer la carte">×</button>
        </div>
        <div class="mobile-map-wrap">
          <LeafletMap
            :markers="mapMarkers"
            :center="[28.0339, 1.6596]"
            :zoom="5"
            height="100%"
            @marker-click="(m: MapMarker) => { closeMobileMap(); $router.push(m.url || '/') }"
          />
        </div>
      </div>
    </transition>
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
.djawal-section { padding: 70px 0; }

/* === HERO COMPACT V4 + VIDÉO === */
.trips-hero {
  position: relative;
  min-height: 56vh;
  display: flex; align-items: center; justify-content: center;
  text-align: center;
  padding: 120px 32px 70px;
  overflow: hidden;
  background: #0F2419;
}
.trips-hero-video-backdrop {
  position: absolute; inset: 0;
  width: 100%; height: 100%;
  object-fit: cover;
  object-position: center;
  z-index: 0;
  pointer-events: none;
  filter: blur(28px) brightness(0.95) saturate(1.2);
  transform: scale(1.15);
}
.trips-hero-video {
  position: absolute; inset: 0;
  width: 100%; height: 100%;
  object-fit: contain;
  object-position: center;
  z-index: 1;
  pointer-events: none;
}
.trips-hero-overlay {
  position: absolute; inset: 0;
  background: transparent;
  z-index: 2;
  pointer-events: none;
}
@media (prefers-reduced-motion: reduce) {
  .trips-hero-video, .trips-hero-video-backdrop { display: none; }
  .trips-hero {
    background-image: url('/videos/algerie-hero-poster.jpg');
    background-size: cover;
    background-position: center;
  }
}
.hero-content { position: relative; z-index: 3; }
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
  text-shadow: 0 2px 14px rgba(0, 0, 0, 0.55);
}
.trips-hero h1 em { font-style: italic; color: #E8B96B; }
.lead {
  font-family: 'Cormorant Garamond', serif;
  font-style: italic;
  font-size: clamp(16px, 2vw, 20px);
  color: rgba(250, 247, 242, 0.88);
  max-width: 640px; margin: 0 auto;
  line-height: 1.5;
  text-shadow: 0 1px 8px rgba(0, 0, 0, 0.5);
}

.filters-bar {
  background: rgba(15, 36, 25, 0.92);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  padding: 18px 32px;
  border-bottom: 1px solid rgba(212, 168, 68, 0.2);
  position: sticky; top: 0; z-index: 40;
}
.filters-inner {
  max-width: 1280px; margin: 0 auto;
  display: flex; gap: 16px; align-items: center; flex-wrap: wrap;
}

.search-wrap { position: relative; flex: 1; min-width: 260px; max-width: 460px; }
.search-icon {
  position: absolute; left: 14px; top: 50%; transform: translateY(-50%);
  color: #E8B96B; pointer-events: none;
}
.search-input {
  width: 100%;
  background: rgba(250, 247, 242, 0.06);
  border: 1px solid rgba(212, 168, 68, 0.3);
  color: #FAF7F2;
  padding: 12px 38px 12px 42px;
  border-radius: 999px;
  font-family: inherit; font-size: 14px;
  outline: none; transition: all 0.2s;
}
.search-input::placeholder { color: rgba(250, 247, 242, 0.45); }
.search-input:focus {
  background: rgba(250, 247, 242, 0.12);
  border-color: #D4A844;
  box-shadow: 0 0 0 3px rgba(212, 168, 68, 0.15);
}
.search-clear {
  position: absolute; right: 10px; top: 50%; transform: translateY(-50%);
  width: 24px; height: 24px; border-radius: 50%;
  background: rgba(250, 247, 242, 0.18); color: #0F2419;
  border: none; font-size: 16px; line-height: 1; cursor: pointer;
  display: flex; align-items: center; justify-content: center;
}
.search-clear:hover { background: #E8B96B; }

.autocomplete-list {
  position: absolute; top: calc(100% + 6px); left: 0; right: 0;
  background: #1A3A2A;
  border: 1px solid rgba(212, 168, 68, 0.35);
  border-radius: 14px; padding: 6px; z-index: 50;
  box-shadow: 0 14px 38px rgba(0, 0, 0, 0.55);
  max-height: 320px; overflow-y: auto;
}
.autocomplete-item {
  display: flex; align-items: center; gap: 12px;
  width: 100%; padding: 10px 12px;
  background: transparent; border: none; border-radius: 10px;
  color: #FAF7F2; font-family: inherit; text-align: left;
  cursor: pointer; transition: background 0.15s;
}
.autocomplete-item:hover, .autocomplete-item:focus { background: rgba(212, 168, 68, 0.15); }
.autocomplete-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; background: #E8B96B; }
.autocomplete-item[data-theme="saharien"] .autocomplete-dot { background: #E8B96B; }
.autocomplete-item[data-theme="mauresque"] .autocomplete-dot { background: #6FA8C0; }
.autocomplete-item[data-theme="aures"] .autocomplete-dot { background: #A8C76F; }
.autocomplete-text strong {
  display: block;
  font-family: 'Cormorant Garamond', serif;
  font-style: italic; font-weight: 500; font-size: 16px;
}
.autocomplete-text small { color: rgba(250, 247, 242, 0.6); font-size: 12px; }

.filter-label {
  font-size: 11px; color: rgba(250, 247, 242, 0.55);
  letter-spacing: 0.12em; text-transform: uppercase; margin-right: 4px;
}
.theme-chips { display: flex; gap: 8px; flex-wrap: wrap; align-items: center; }
.chip {
  display: inline-flex; align-items: center; gap: 6px;
  padding: 8px 14px;
  background: rgba(250, 247, 242, 0.06);
  border: 1px solid rgba(212, 168, 68, 0.25);
  color: #FAF7F2; border-radius: 999px;
  font-family: inherit; font-size: 13px; font-weight: 500;
  cursor: pointer; transition: all 0.2s;
}
.chip:hover { background: rgba(212, 168, 68, 0.15); border-color: rgba(212, 168, 68, 0.55); }
.chip.active { background: #D4A844; color: #0F2419; border-color: #D4A844; font-weight: 600; }
.chip-icon { font-size: 14px; }

.sort-wrap { display: flex; align-items: center; gap: 8px; }
.sort-label {
  font-size: 11px; letter-spacing: 0.12em; text-transform: uppercase;
  color: rgba(250, 247, 242, 0.55);
}
.sort-select {
  background: rgba(250, 247, 242, 0.06);
  border: 1px solid rgba(212, 168, 68, 0.3);
  color: #FAF7F2; padding: 8px 14px; border-radius: 999px;
  font-family: inherit; font-size: 13px; cursor: pointer; outline: none;
}
.sort-select option { background: #1A3A2A; color: #FAF7F2; }

.mobile-filter-btn {
  display: none; align-items: center; gap: 8px;
  padding: 10px 18px;
  background: #D4A844; color: #0F2419;
  border: none; border-radius: 999px;
  font-weight: 600; font-size: 13px;
  font-family: inherit; cursor: pointer; position: relative;
}
.mobile-filter-dot {
  position: absolute; top: 4px; right: 8px;
  width: 8px; height: 8px; border-radius: 50%;
  background: #B8312E; border: 2px solid #D4A844;
}

.results-meta {
  display: flex; align-items: center; justify-content: space-between;
  gap: 16px; padding-top: 28px; flex-wrap: wrap;
}
.results-count-wrap { display: flex; align-items: center; gap: 14px; flex-wrap: wrap; }
.results-count { color: rgba(250, 247, 242, 0.75); font-size: 14px; }
.results-count strong {
  color: #E8B96B;
  font-family: 'Cormorant Garamond', serif;
  font-style: italic; font-size: 28px; font-weight: 500; margin-right: 6px;
}
.active-pill {
  display: inline-flex; align-items: center; gap: 8px;
  padding: 6px 6px 6px 14px;
  background: rgba(212, 168, 68, 0.18);
  border: 1px solid rgba(212, 168, 68, 0.4);
  border-radius: 999px;
  color: #E8B96B; font-size: 12.5px; font-style: italic;
  font-family: 'Cormorant Garamond', serif;
}
.active-pill-clear {
  width: 22px; height: 22px; border-radius: 50%;
  background: rgba(15, 36, 25, 0.6); color: #E8B96B;
  border: none; font-size: 14px; cursor: pointer;
  display: flex; align-items: center; justify-content: center;
}
.active-pill-clear:hover { background: #B8312E; color: #FAF7F2; }

.mobile-map-btn {
  display: none; align-items: center; gap: 6px;
  background: transparent;
  border: 1px solid rgba(212, 168, 68, 0.35);
  color: #E8B96B; padding: 8px 14px; border-radius: 999px;
  font-size: 12.5px; font-weight: 500; font-family: inherit; cursor: pointer;
}

.results-section { padding-top: 28px !important; }
.split-view { display: grid; grid-template-columns: 1.4fr 1fr; gap: 32px; align-items: start; }
.list-pane { display: flex; flex-direction: column; gap: 22px; }
.map-pane {
  position: sticky; top: 90px;
  border-radius: 18px; overflow: hidden;
  border: 1px solid rgba(212, 168, 68, 0.25);
}

.empty-state {
  text-align: center; padding: 70px 20px;
  background: rgba(31, 74, 54, 0.4);
  border: 1px dashed rgba(212, 168, 68, 0.3);
  border-radius: 22px;
}
.empty-icon { font-size: 44px; margin-bottom: 14px; }
.empty-state h3 {
  font-family: 'Cormorant Garamond', serif;
  font-size: 24px; font-weight: 500; color: #FAF7F2; margin-bottom: 8px;
}
.empty-state p { color: rgba(250, 247, 242, 0.65); margin-bottom: 22px; }
.empty-reset {
  background: #D4A844; color: #0F2419;
  border: none; padding: 11px 24px; border-radius: 999px;
  font-weight: 600; cursor: pointer;
}

.loading {
  text-align: center; padding: 80px 20px;
  color: rgba(250, 247, 242, 0.55);
  font-family: 'Cormorant Garamond', serif;
  font-style: italic; font-size: 18px;
}

.dest-card-featured {
  display: grid; grid-template-columns: 1fr 1fr;
  background: rgba(31, 74, 54, 0.6);
  border: 1.5px solid rgba(212, 168, 68, 0.4);
  border-radius: 22px; overflow: hidden;
  cursor: pointer; transition: all 0.3s;
  min-height: 280px;
  box-shadow: 0 14px 38px rgba(0, 0, 0, 0.35);
}
.dest-card-featured:hover {
  transform: translateY(-3px);
  border-color: rgba(232, 185, 107, 0.7);
  box-shadow: 0 20px 50px rgba(0, 0, 0, 0.5);
}
.featured-image { background-size: cover; background-position: center; position: relative; min-height: 280px; }
.featured-tag {
  position: absolute; top: 16px; left: 16px;
  background: linear-gradient(135deg, #D4A844, #B8862E);
  color: #0F2419; padding: 6px 14px; border-radius: 999px;
  font-size: 11px; font-weight: 700;
  letter-spacing: 0.12em; text-transform: uppercase;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
  z-index: 2;
}
/* Sur la card vedette, le badge thème passe à DROITE pour éviter le chevauchement avec "Coup de cœur" */
.dest-card-featured .theme-badge {
  left: auto;
  right: 16px;
  top: 16px;
}
/* Sur la card vedette, le bouton coeur passe en BAS-DROITE pour ne pas chevaucher le badge thème */
.dest-card-featured .fav-btn.is-floating {
  top: auto;
  right: 16px;
  bottom: 16px;
}
.featured-body { padding: 36px 32px; display: flex; flex-direction: column; justify-content: center; }
.featured-body h3 {
  font-family: 'Cormorant Garamond', serif;
  font-size: clamp(28px, 3vw, 38px); font-weight: 500;
  color: #FAF7F2; margin-bottom: 6px; line-height: 1.1;
}
.featured-desc {
  font-size: 15px; color: rgba(250, 247, 242, 0.78);
  line-height: 1.6; margin: 14px 0 22px;
  display: -webkit-box; -webkit-line-clamp: 4; -webkit-box-orient: vertical; overflow: hidden;
}

.dest-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 18px; }
.dest-card {
  background: rgba(31, 74, 54, 0.5);
  border: 1px solid rgba(212, 168, 68, 0.18);
  border-radius: 18px; overflow: hidden;
  cursor: pointer; transition: all 0.3s;
  display: flex; flex-direction: column;
  border-top: 3px solid #D4A844;
}
.dest-card[data-theme="saharien"] { border-top-color: #E8B96B; }
.dest-card[data-theme="mauresque"] { border-top-color: #6FA8C0; }
.dest-card[data-theme="aures"] { border-top-color: #A8C76F; }
.dest-card:hover {
  transform: translateY(-3px);
  background: rgba(31, 74, 54, 0.75);
  border-color: rgba(212, 168, 68, 0.5);
  box-shadow: 0 14px 38px rgba(0, 0, 0, 0.45);
}
.card-image {
  background-size: cover; background-position: center;
  position: relative; height: 180px;
  filter: saturate(0.88); transition: filter 0.3s;
}
.dest-card:hover .card-image { filter: saturate(1.1); }
.dest-card[data-theme="saharien"] .card-image:not([style*="background-image"]) {
  background: radial-gradient(circle at 70% 30%, #E8B96B 0%, #B8862E 40%, #5C3D1E 100%);
}
.dest-card[data-theme="mauresque"] .card-image:not([style*="background-image"]) {
  background: linear-gradient(160deg, #3D6890 0%, #1B4965 60%, #0A1F2E 100%);
}
.dest-card[data-theme="aures"] .card-image:not([style*="background-image"]) {
  background: linear-gradient(160deg, #6B7A4A 0%, #2D5A3D 60%, #1B3A28 100%);
}
.theme-badge {
  position: absolute; top: 12px; left: 12px;
  padding: 5px 12px; border-radius: 999px;
  background: rgba(15, 36, 25, 0.88) !important;
  color: #E8B96B; font-size: 10px; font-weight: 700;
  letter-spacing: 0.12em; text-transform: uppercase;
  border: 1px solid rgba(212, 168, 68, 0.4); backdrop-filter: blur(8px);
}
.card-body { padding: 18px 20px; display: flex; flex-direction: column; flex: 1; }
.card-body h3 {
  font-family: 'Cormorant Garamond', serif;
  font-size: 24px; font-weight: 500; color: #FAF7F2;
  margin-bottom: 4px; line-height: 1.1;
}
.card-arabic {
  color: #E8B96B; font-family: 'Cormorant Garamond', serif;
  font-style: italic; font-size: 14px; margin-bottom: 6px; opacity: 0.85;
}
.card-meta { font-size: 12px; color: rgba(250, 247, 242, 0.55); margin-bottom: 10px; letter-spacing: 0.05em; }
.card-desc {
  font-size: 13.5px; color: rgba(250, 247, 242, 0.72); line-height: 1.55;
  display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical;
  overflow: hidden; flex: 1;
}
.card-cta { margin-top: 14px; color: #E8B96B; font-weight: 600; font-size: 13px; letter-spacing: 0.05em; }

.trips-showcase { border-top: 1px solid rgba(212, 168, 68, 0.2); padding-top: 70px; padding-bottom: 70px; }
.section-eyebrow {
  color: #E8B96B; font-size: 11px; font-weight: 600;
  letter-spacing: 0.24em; text-transform: uppercase; margin-bottom: 8px;
}
.showcase-head { margin-bottom: 30px; }
.showcase-head h2 {
  font-family: 'Cormorant Garamond', serif; font-weight: 400;
  font-size: clamp(28px, 3.5vw, 40px); color: #FAF7F2; line-height: 1.05;
}
.showcase-head h2 em { font-style: italic; color: #E8B96B; }
.showcase-sub {
  margin-top: 8px; font-family: 'Cormorant Garamond', serif;
  font-style: italic; color: rgba(250, 247, 242, 0.65); font-size: 16px;
}
.trip-strip { display: grid; grid-template-columns: repeat(auto-fill, minmax(240px, 1fr)); gap: 18px; }
.trip-strip-card {
  background: rgba(31, 74, 54, 0.5);
  border: 1px solid rgba(212, 168, 68, 0.2);
  border-radius: 16px; overflow: hidden;
  text-decoration: none; color: inherit;
  transition: all 0.3s; display: flex; flex-direction: column;
}
.trip-strip-card:hover {
  transform: translateY(-4px);
  border-color: rgba(212, 168, 68, 0.55);
  background: rgba(31, 74, 54, 0.75);
  box-shadow: 0 14px 38px rgba(0, 0, 0, 0.45);
}
.trip-strip-cover {
  height: 160px; background: linear-gradient(135deg, #B8862E, #5C3D1E);
  background-size: cover; background-position: center; position: relative;
}
.senior-badge {
  position: absolute; top: 10px; right: 10px;
  background: rgba(15, 36, 25, 0.88); color: #E8B96B;
  padding: 4px 10px; border-radius: 999px;
  font-size: 10px; font-weight: 700; letter-spacing: 0.1em;
  border: 1px solid rgba(212, 168, 68, 0.4);
}
/* Sur les cards voyages signés, le coeur passe en BAS-DROITE pour ne pas chevaucher le badge Senior */
.trip-strip-card .fav-btn.is-floating {
  top: auto;
  right: 10px;
  bottom: 10px;
}
.trip-strip-body { padding: 16px 18px 18px; flex: 1; display: flex; flex-direction: column; }
.trip-strip-dest {
  font-size: 10.5px; color: rgba(250, 247, 242, 0.55);
  text-transform: uppercase; letter-spacing: 0.14em; margin-bottom: 6px;
}
.trip-strip-body h4 {
  font-family: 'Cormorant Garamond', serif; font-weight: 500;
  font-size: 19px; color: #FAF7F2; margin-bottom: 8px;
  line-height: 1.15; flex: 1;
}
.trip-strip-meta {
  font-size: 13px; color: #E8B96B; font-weight: 600; margin-bottom: 6px;
  font-family: 'Cormorant Garamond', serif; font-style: italic;
}
.trip-strip-author { font-size: 11px; color: rgba(250, 247, 242, 0.6); font-style: italic; }
.trip-strip-author strong { color: #E8B96B; font-style: normal; font-weight: 600; }

.mobile-filters-drawer {
  position: fixed; inset: 0;
  background: rgba(0, 0, 0, 0.6);
  z-index: 200; display: flex; align-items: flex-end;
  backdrop-filter: blur(4px);
}
.drawer-sheet {
  width: 100%; background: #0F2419;
  border-radius: 26px 26px 0 0;
  border-top: 1px solid rgba(212, 168, 68, 0.3);
  padding: 12px 22px 28px;
  max-height: 80vh; overflow-y: auto;
}
.drawer-handle {
  width: 42px; height: 4px;
  background: rgba(212, 168, 68, 0.3);
  border-radius: 2px; margin: 0 auto 18px;
}
.drawer-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 18px; }
.drawer-head h3 {
  font-family: 'Cormorant Garamond', serif; font-style: italic;
  font-size: 22px; color: #E8B96B;
}
.drawer-close {
  width: 32px; height: 32px; border-radius: 50%;
  background: rgba(250, 247, 242, 0.1); color: #FAF7F2;
  border: none; font-size: 20px; cursor: pointer;
}
.drawer-section { margin-bottom: 22px; }
.drawer-label {
  display: block; font-size: 11px; letter-spacing: 0.12em;
  text-transform: uppercase; color: rgba(250, 247, 242, 0.55); margin-bottom: 10px;
}
.theme-chips-mobile { display: flex; flex-wrap: wrap; gap: 8px; }
.sort-select-mobile {
  width: 100%; background: rgba(250, 247, 242, 0.06);
  border: 1px solid rgba(212, 168, 68, 0.3); color: #FAF7F2;
  padding: 12px 16px; border-radius: 14px;
  font-family: inherit; font-size: 14px; outline: none;
}
.sort-select-mobile option { background: #1A3A2A; }
.drawer-actions {
  display: flex; gap: 10px; margin-top: 8px;
  padding-top: 18px; border-top: 1px solid rgba(212, 168, 68, 0.18);
}
.drawer-btn-ghost {
  flex: 0 0 auto; background: transparent;
  border: 1px solid rgba(212, 168, 68, 0.3); color: #E8B96B;
  padding: 12px 18px; border-radius: 999px;
  font-weight: 500; cursor: pointer; font-family: inherit;
}
.drawer-btn-primary {
  flex: 1; background: #D4A844; color: #0F2419;
  border: none; padding: 13px 18px; border-radius: 999px;
  font-weight: 600; cursor: pointer; font-family: inherit; font-size: 14px;
}

.mobile-map-overlay {
  position: fixed; inset: 0; background: #0F2419;
  z-index: 250; display: flex; flex-direction: column;
}
.mobile-map-head {
  padding: 14px 18px;
  background: rgba(15, 36, 25, 0.95);
  border-bottom: 1px solid rgba(212, 168, 68, 0.25);
  display: flex; justify-content: space-between; align-items: center;
  font-size: 13.5px; color: #E8B96B;
}
.mobile-map-close {
  width: 36px; height: 36px; border-radius: 50%;
  background: rgba(250, 247, 242, 0.1); color: #FAF7F2;
  border: none; font-size: 22px; cursor: pointer;
}
.mobile-map-wrap { flex: 1; }

.slide-up-enter-active, .slide-up-leave-active { transition: opacity 0.25s ease, transform 0.25s ease; }
.slide-up-enter-from, .slide-up-leave-to { opacity: 0; }
.slide-up-enter-from .drawer-sheet, .slide-up-leave-to .drawer-sheet { transform: translateY(100%); }
.fade-up-enter-active, .fade-up-leave-active { transition: opacity 0.25s ease, transform 0.25s ease; }
.fade-up-enter-from, .fade-up-leave-to { opacity: 0; transform: translateY(16px); }

@media (max-width: 1100px) {
  .split-view { grid-template-columns: 1fr; }
  .map-pane { display: none; }
}
@media (max-width: 980px) {
  .dest-card-featured { grid-template-columns: 1fr; }
  .featured-image { min-height: 220px; }
  .featured-body { padding: 24px 22px; }
  .trips-hero { min-height: 44vh; padding: 100px 20px 50px; }
  .djawal-section { padding: 50px 0; }
}
@media (max-width: 600px) {
  .djawal-container { padding: 0 20px; }
  .trips-hero { min-height: 38vh; padding: 90px 16px 40px; }
  .trips-hero h1 { text-shadow: 0 2px 12px rgba(0, 0, 0, 0.65); }
  .trips-hero-video-backdrop { display: none; }
  .trips-hero-video { object-fit: cover; object-position: center; }
  .filters-bar { padding: 12px 16px; }
  .filters-inner { gap: 10px; flex-wrap: nowrap; }
  .search-wrap { flex: 1 1 0; min-width: 0; max-width: none; }
  .theme-chips-desktop { display: none; }
  .sort-wrap { display: none; }
  .mobile-filter-btn { display: inline-flex; }
  .results-meta { padding-top: 18px; flex-direction: column; align-items: stretch; gap: 12px; }
  .results-count-wrap { justify-content: space-between; }
  .mobile-map-btn { display: inline-flex; align-self: flex-start; }
  .dest-grid { grid-template-columns: 1fr; gap: 14px; }
  .card-image { height: 160px; }
  .card-body { padding: 14px 16px; }
  .card-body h3 { font-size: 21px; }
  .card-desc { -webkit-line-clamp: 2; font-size: 13px; }
  .trips-showcase { padding: 50px 0; }
  .showcase-head { margin-bottom: 22px; }
  .trip-strip { gap: 14px; grid-template-columns: repeat(auto-fill, minmax(180px, 1fr)); }
  .trip-strip-cover { height: 130px; }
  .autocomplete-list { font-size: 14px; }
  .autocomplete-text strong { font-size: 15px; }
}
@media (max-width: 380px) {
  .trips-hero h1 { font-size: 30px; line-height: 1.1; }
  .lead { font-size: 14.5px; }
  .results-count strong { font-size: 24px; }
}
</style>
