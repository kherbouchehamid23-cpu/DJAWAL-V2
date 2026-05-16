<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { parseCoordinates } from '@/lib/geo'
import { useThemeStore } from '@/stores/theme'
import LeafletMap, { type MapMarker } from '@/components/LeafletMap.vue'
import Panorama360 from '@/components/Panorama360.vue'
import ResourceDetailDialog from '@/components/ResourceDetailDialog.vue'
import FavoriteButton from '@/components/FavoriteButton.vue'
import ReviewSection from '@/components/ReviewSection.vue'

const route = useRoute()
const themeStore = useThemeStore()

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

interface Resource {
  id: string
  name: string
  name_ar: string | null
  description: string
  coordinates: any
  images?: string[]
  panorama_360_url?: string | null
  virtual_tour_url?: string | null
  // hotel-specific
  address?: string
  star_rating?: number
  amenities?: string[]
  price_range_da?: any
  // site-specific
  category?: string
  entry_fee_da?: number
  best_season?: string[]
  // restaurant-specific
  cuisine?: string[]
  signature_dishes?: string[]
}

const destination = ref<Destination | null>(null)
const sites = ref<Resource[]>([])
const accommodations = ref<Resource[]>([])
const restaurants = ref<Resource[]>([])
const activities = ref<any[]>([])
const loading = ref(true)
const activeTab = ref<'all' | 'sites' | 'accommodations' | 'restaurants' | 'activities'>('all')

// Visite 360 modale
const panoramaResource = ref<Resource | null>(null)
function openPanorama(r: Resource) { panoramaResource.value = r }
function closePanorama() { panoramaResource.value = null }

// === Dialog de détail ressource ===
type DetailType = 'site' | 'accommodation' | 'restaurant' | 'activity'
const detailOpen = ref(false)
const detailResource = ref<any | null>(null)
const detailType = ref<DetailType | null>(null)

function openDetail(resource: any, type: DetailType) {
  detailResource.value = resource
  detailType.value = type
  detailOpen.value = true
}

function onPanoramaFromDetail(r: any) {
  // Reçu du dialog quand l'utilisateur clique sur "Visite 360°"
  detailOpen.value = false
  setTimeout(() => openPanorama(r), 250)
}

// === Click sur un marker de la carte → ouvre le détail correspondant ===
function onMarkerClick(marker: MapMarker) {
  // Cherche d'abord dans accommodations, puis sites, restaurants, activities
  const inAcc = accommodations.value.find(x => x.id === marker.id)
  if (inAcc) return openDetail(inAcc, 'accommodation')
  const inSite = sites.value.find(x => x.id === marker.id)
  if (inSite) return openDetail(inSite, 'site')
  const inRest = restaurants.value.find(x => x.id === marker.id)
  if (inRest) return openDetail(inRest, 'restaurant')
  const inAct = activities.value.find(x => x.id === marker.id)
  if (inAct) return openDetail(inAct, 'activity')
}
function has360(r: Resource): boolean {
  return !!(r.panorama_360_url || r.virtual_tour_url)
}

const slug = computed(() => route.params.id as string)

async function loadDestination() {
  loading.value = true
  const { data: dest } = await supabase
    .from('destinations')
    .select('*')
    .eq('slug', slug.value)
    .single()

  if (!dest) {
    loading.value = false
    return
  }
  destination.value = dest as Destination

  // Applique le thème culturel
  themeStore.setTheme(dest.cultural_theme)

  // Charge les ressources en parallèle
  const [sitesRes, accommodationsRes, restaurantsRes, activitiesRes] = await Promise.all([
    supabase.from('sites').select('*').eq('destination_id', dest.id).not('validated_at', 'is', null),
    supabase.from('accommodations').select('*').eq('destination_id', dest.id).not('validated_at', 'is', null),
    supabase.from('restaurants').select('*').eq('destination_id', dest.id).not('validated_at', 'is', null),
    supabase.from('activities').select('*').eq('destination_id', dest.id).not('validated_at', 'is', null)
  ])

  sites.value = (sitesRes.data || []) as Resource[]
  accommodations.value = (accommodationsRes.data || []) as Resource[]
  restaurants.value = (restaurantsRes.data || []) as Resource[]
  activities.value = activitiesRes.data || []
  loading.value = false
}

onMounted(loadDestination)
watch(slug, loadDestination)

const mapMarkers = computed<MapMarker[]>(() => {
  if (!destination.value) return []
  const list: MapMarker[] = []
  const theme = destination.value.cultural_theme

  // Marker pour la destination elle-même
  const destCoords = parseCoordinates(destination.value.coordinates)
  if (destCoords) {
    list.push({
      id: destination.value.id,
      lat: destCoords.lat,
      lng: destCoords.lng,
      title: destination.value.name,
      subtitle: 'Destination',
      theme
    })
  }

  // Filtrer selon onglet actif
  const shouldShow = (kind: string) => activeTab.value === 'all' || activeTab.value === kind

  if (shouldShow('sites')) {
    for (const s of sites.value) {
      const c = parseCoordinates(s.coordinates)
      if (c) list.push({ id: s.id, lat: c.lat, lng: c.lng, title: s.name, subtitle: '🏛️ Site', theme })
    }
  }
  if (shouldShow('accommodations')) {
    for (const h of accommodations.value) {
      const c = parseCoordinates(h.coordinates)
      if (c) list.push({ id: h.id, lat: c.lat, lng: c.lng, title: h.name, subtitle: '🏨 Hébergement', theme })
    }
  }
  if (shouldShow('restaurants')) {
    for (const r of restaurants.value) {
      const c = parseCoordinates(r.coordinates)
      if (c) list.push({ id: r.id, lat: c.lat, lng: c.lng, title: r.name, subtitle: '🍽️ Restaurant', theme })
    }
  }
  if (shouldShow('activities')) {
    for (const a of activities.value) {
      const c = parseCoordinates(a.coordinates)
      if (c) list.push({ id: a.id, lat: c.lat, lng: c.lng, title: a.name, subtitle: '🥾 Activité', theme })
    }
  }
  return list
})

const totalResources = computed(() =>
  sites.value.length + accommodations.value.length + restaurants.value.length + activities.value.length
)

function parsePriceRange(range: any): string {
  if (!range) return ''
  const m = String(range).match(/\[(\d+),(\d+)\)/)
  if (!m) return ''
  return `${parseInt(m[1]).toLocaleString('fr-FR')} – ${parseInt(m[2]).toLocaleString('fr-FR')} DA`
}
</script>

<template>
  <div v-if="loading" class="djawal-container djawal-section text-center">
    <div class="loading">Chargement de la destination…</div>
  </div>

  <div v-else-if="!destination" class="djawal-container djawal-section text-center">
    <h1>Destination introuvable</h1>
    <router-link to="/voyages" class="back-link">← Voir toutes les destinations</router-link>
  </div>

  <div v-else class="dest-page">
    <!-- HERO -->
    <header class="dest-hero" :data-theme="destination.cultural_theme">
      <div class="hero-bg" :style="destination.hero_image_url ? `background-image: url(${destination.hero_image_url})` : ''" />
      <div class="hero-overlay" />
      <div class="djawal-container hero-content">
        <router-link to="/voyages" class="hero-back">← Toutes les destinations</router-link>
        <div v-if="destination.name_ar" class="hero-arabic arabic">{{ destination.name_ar }}</div>
        <h1>{{ destination.name }}</h1>
        <div class="hero-meta">
          <span class="meta-pill">📍 {{ destination.wilaya }}</span>
          <span class="meta-pill">{{ destination.cultural_theme === 'saharien' ? '🏜️ Saharien' : destination.cultural_theme === 'mauresque' ? '🏛️ Mauresque' : '⛰️ Aurès' }}</span>
        </div>
      </div>
      <!-- Bouton favoris en haut-droite du hero -->
      <FavoriteButton
        target-type="destination"
        :target-id="destination.id"
        size="lg"
        class="hero-fav-btn"
      />
    </header>

    <!-- DESCRIPTION -->
    <section class="djawal-container intro-section">
      <p class="intro-text">{{ destination.description }}</p>

      <div class="stats-row">
        <div class="stat">
          <strong>{{ sites.length }}</strong>
          <span>site{{ sites.length > 1 ? 's' : '' }} & monument{{ sites.length > 1 ? 's' : '' }}</span>
        </div>
        <div class="stat">
          <strong>{{ accommodations.length }}</strong>
          <span>hébergement{{ accommodations.length > 1 ? 's' : '' }}</span>
        </div>
        <div class="stat">
          <strong>{{ restaurants.length }}</strong>
          <span>restaurant{{ restaurants.length > 1 ? 's' : '' }}</span>
        </div>
        <div class="stat">
          <strong>{{ activities.length }}</strong>
          <span>activité{{ activities.length > 1 ? 's' : '' }}</span>
        </div>
      </div>
    </section>

    <!-- TABS -->
    <section class="tabs-section">
      <div class="djawal-container">
        <div class="tabs">
          <button class="tab" :class="{ active: activeTab === 'all' }" @click="activeTab = 'all'">
            ✨ Tout ({{ totalResources }})
          </button>
          <button class="tab" :class="{ active: activeTab === 'sites' }" @click="activeTab = 'sites'">
            🏛️ Sites ({{ sites.length }})
          </button>
          <button class="tab" :class="{ active: activeTab === 'accommodations' }" @click="activeTab = 'accommodations'">
            🏨 Hébergements ({{ accommodations.length }})
          </button>
          <button class="tab" :class="{ active: activeTab === 'activities' }" @click="activeTab = 'activities'">
            🥾 Activités ({{ activities.length }})
          </button>
          <button class="tab" :class="{ active: activeTab === 'restaurants' }" @click="activeTab = 'restaurants'">
            🍽️ Restaurants ({{ restaurants.length }})
          </button>
        </div>
      </div>
    </section>

    <!-- CONTENT + MAP -->
    <section class="djawal-container content-section">
      <div class="content-grid">
        <!-- Liste des ressources -->
        <div class="resources-list">
          <!-- SITES -->
          <article v-if="(activeTab === 'all' || activeTab === 'sites') && sites.length > 0" class="resource-group">
            <h2 class="group-title">🏛️ Sites & Monuments</h2>
            <div class="resource-cards">
              <article v-for="s in sites" :key="s.id" class="resource-card clickable" role="button" tabindex="0" @click="openDetail(s, 'site')" @keydown.enter="openDetail(s, 'site')">
                <FavoriteButton target-type="site" :target-id="s.id" size="sm" floating />
                <span v-if="s.images && s.images.length > 0" class="rc-cover" :style="`background-image: url(${s.images[0]})`"></span>
                <div class="rc-content">
                  <div class="rc-header">
                    <strong>{{ s.name }}</strong>
                    <span v-if="s.category" class="rc-tag">{{ s.category }}</span>
                  </div>
                  <div v-if="s.name_ar" class="rc-arabic arabic">{{ s.name_ar }}</div>
                  <p class="rc-desc">{{ s.description }}</p>
                  <div class="rc-meta">
                    <span v-if="s.entry_fee_da !== null && s.entry_fee_da !== undefined">
                      {{ s.entry_fee_da === 0 ? 'Entrée libre' : s.entry_fee_da + ' DA' }}
                    </span>
                    <span v-if="s.best_season?.length">
                      {{ s.best_season.join(', ') }}
                    </span>
                  </div>
                  <div class="rc-actions">
                    <span class="rc-cta">Voir le détail →</span>
                    <span v-if="has360(s)" class="rc-badge-360" @click.stop="openPanorama(s)">🌐 360°</span>
                  </div>
                </div>
              </article>
            </div>
          </article>

          <!-- HOTELS -->
          <article v-if="(activeTab === 'all' || activeTab === 'accommodations') && accommodations.length > 0" class="resource-group">
            <h2 class="group-title">🏨 Hébergements</h2>
            <div class="resource-cards">
              <article v-for="h in accommodations" :key="h.id" class="resource-card clickable" role="button" tabindex="0" @click="openDetail(h, 'accommodation')" @keydown.enter="openDetail(h, 'accommodation')">
                <FavoriteButton target-type="accommodation" :target-id="h.id" size="sm" floating />
                <span v-if="h.images && h.images.length > 0" class="rc-cover" :style="`background-image: url(${h.images[0]})`"></span>
                <div class="rc-content">
                  <div class="rc-header">
                    <strong>{{ h.name }}</strong>
                    <span v-if="h.star_rating" class="rc-stars">{{ '★'.repeat(h.star_rating) }}</span>
                  </div>
                  <div v-if="h.name_ar" class="rc-arabic arabic">{{ h.name_ar }}</div>
                  <p class="rc-desc">{{ h.description }}</p>
                  <div class="rc-meta">
                    <span v-if="h.address" class="rc-address">📍 {{ h.address }}</span>
                    <span v-if="parsePriceRange(h.price_range_da)">{{ parsePriceRange(h.price_range_da) }}</span>
                  </div>
                  <div v-if="h.amenities?.length" class="rc-amenities">
                    <span v-for="a in h.amenities" :key="a" class="amenity">{{ a }}</span>
                  </div>
                  <div class="rc-actions">
                    <span class="rc-cta">Voir le détail →</span>
                    <span v-if="has360(h)" class="rc-badge-360" @click.stop="openPanorama(h)">🌐 360°</span>
                  </div>
                </div>
              </article>
            </div>
          </article>

          <!-- RESTAURANTS -->
          <article v-if="(activeTab === 'all' || activeTab === 'restaurants') && restaurants.length > 0" class="resource-group">
            <h2 class="group-title">🍽️ Restaurants</h2>
            <div class="resource-cards">
              <article v-for="r in restaurants" :key="r.id" class="resource-card clickable" role="button" tabindex="0" @click="openDetail(r, 'restaurant')" @keydown.enter="openDetail(r, 'restaurant')">
                <FavoriteButton target-type="restaurant" :target-id="r.id" size="sm" floating />
                <span v-if="r.images && r.images.length > 0" class="rc-cover" :style="`background-image: url(${r.images[0]})`"></span>
                <div class="rc-content">
                  <div class="rc-header">
                    <strong>{{ r.name }}</strong>
                    <span v-if="r.cuisine?.length" class="rc-tag">{{ r.cuisine.join(' · ') }}</span>
                  </div>
                  <div v-if="r.name_ar" class="rc-arabic arabic">{{ r.name_ar }}</div>
                  <p class="rc-desc">{{ r.description }}</p>
                  <div class="rc-meta">
                    <span v-if="parsePriceRange(r.price_range_da)">{{ parsePriceRange(r.price_range_da) }}</span>
                  </div>
                  <div v-if="r.signature_dishes?.length" class="rc-amenities">
                    <span v-for="d in r.signature_dishes" :key="d" class="amenity dishes">{{ d }}</span>
                  </div>
                  <div class="rc-actions">
                    <span class="rc-cta">Voir le détail →</span>
                    <span v-if="has360(r)" class="rc-badge-360" @click.stop="openPanorama(r)">🌐 360°</span>
                  </div>
                </div>
              </article>
            </div>
          </article>

          <!-- ACTIVITÉS -->
          <article v-if="(activeTab === 'all' || activeTab === 'activities') && activities.length > 0" class="resource-group">
            <h2 class="group-title">🥾 Activités</h2>
            <div class="resource-cards">
              <article v-for="a in activities" :key="a.id" class="resource-card clickable" role="button" tabindex="0" @click="openDetail(a, 'activity')" @keydown.enter="openDetail(a, 'activity')">
                <FavoriteButton target-type="activity" :target-id="a.id" size="sm" floating />
                <span v-if="a.images && a.images.length > 0" class="rc-cover" :style="`background-image: url(${a.images[0]})`"></span>
                <div class="rc-content">
                  <div class="rc-header">
                    <strong>{{ a.name }}</strong>
                    <span v-if="a.activity_type" class="rc-tag">{{ a.activity_type }}</span>
                  </div>
                  <div v-if="a.name_ar" class="rc-arabic arabic">{{ a.name_ar }}</div>
                  <p class="rc-desc">{{ a.description }}</p>
                  <div class="rc-meta">
                    <span v-if="a.duration_hours">⏱️ {{ a.duration_hours }}h</span>
                    <span v-if="a.price_da !== null">💵 {{ a.price_da.toLocaleString('fr-FR') }} DA / pers.</span>
                    <span v-if="a.difficulty">📊 {{ a.difficulty }}</span>
                    <span v-if="a.min_age">👤 {{ a.min_age }}+ ans</span>
                  </div>
                  <div v-if="a.best_season?.length" class="rc-amenities">
                    <span v-for="s in a.best_season" :key="s" class="amenity">{{ s }}</span>
                  </div>
                  <div class="rc-actions">
                    <span class="rc-cta">Voir le détail →</span>
                    <span v-if="has360(a)" class="rc-badge-360" @click.stop="openPanorama(a)">🌐 360°</span>
                  </div>
                </div>
              </article>
            </div>
          </article>

          <div v-if="totalResources === 0" class="empty-state">
            <p>Aucune ressource validée pour cette destination pour le moment.</p>
          </div>
        </div>

        <!-- Map sticky -->
        <aside class="map-aside">
          <LeafletMap
            :markers="mapMarkers"
            :zoom="12"
            height="calc(100vh - 200px)"
            @marker-click="onMarkerClick"
          />
        </aside>
      </div>
    </section>

    <!-- AVIS sur la destination -->
    <section class="djawal-container reviews-wrapper">
      <ReviewSection
        target-type="destination"
        :target-id="destination.id"
        :title="`⭐ Avis sur ${destination.name}`"
      />
    </section>

    <!-- Modale détail ressource -->
    <ResourceDetailDialog
      v-model="detailOpen"
      :resource="detailResource"
      :resource-type="detailType"
      @open-panorama="onPanoramaFromDetail"
    />

    <!-- Modale visite 360° -->
    <transition name="fade">
      <div v-if="panoramaResource" class="panorama-modal" @click.self="closePanorama">
        <div class="panorama-modal-inner">
          <header class="panorama-modal-head">
            <div>
              <h3>{{ panoramaResource.name }}</h3>
              <p v-if="panoramaResource.name_ar" class="arabic">{{ panoramaResource.name_ar }}</p>
            </div>
            <button class="modal-close" @click="closePanorama" aria-label="Fermer">✕</button>
          </header>
          <Panorama360
            :panorama-url="panoramaResource.panorama_360_url"
            :virtual-tour-url="panoramaResource.virtual_tour_url"
            :title="panoramaResource.name"
            height="70vh"
          />
        </div>
      </div>
    </transition>
  </div>
</template>

<style scoped>
.dest-page { background: var(--c-fond); min-height: 100vh; }
.text-center { text-align: center; padding: var(--space-9) var(--space-5); }
.loading { color: var(--c-texte-doux); }
.back-link { color: var(--c-primaire); font-weight: 600; }

/* === HERO === */
.dest-hero {
  position: relative;
  min-height: 360px;
  display: flex;
  align-items: flex-end;
  color: var(--c-fond);
  overflow: hidden;
}
.dest-hero[data-theme="saharien"] { background: linear-gradient(135deg, #C97050 0%, #8B4A2C 100%); }
.dest-hero[data-theme="mauresque"] { background: linear-gradient(135deg, #4A90BD 0%, #0A1F2E 100%); }
.dest-hero[data-theme="aures"] { background: linear-gradient(135deg, #6B7A4A 0%, #2D5A3D 100%); }
.hero-bg {
  position: absolute; inset: 0;
  background-size: cover; background-position: center;
  opacity: 0.55;
}
.hero-overlay {
  position: absolute; inset: 0;
  background: linear-gradient(180deg, transparent 30%, rgba(10, 31, 46, 0.7) 100%);
}
.hero-content {
  position: relative;
  padding: var(--space-7) var(--space-5) var(--space-6);
  width: 100%;
}
.hero-fav-btn {
  position: absolute;
  top: 24px;
  right: 24px;
  z-index: 3;
}
.reviews-wrapper {
  padding-top: var(--space-6);
  padding-bottom: var(--space-7);
}
.hero-back {
  display: inline-block;
  color: var(--c-fond);
  text-decoration: none;
  font-size: 14px;
  font-weight: 600;
  opacity: 0.85;
  margin-bottom: var(--space-3);
}
.hero-back:hover { opacity: 1; }
.hero-arabic {
  font-size: 28px;
  color: var(--c-accent);
  margin-bottom: 8px;
}
.dest-hero h1 {
  font-family: var(--font-display);
  font-size: clamp(40px, 6vw, 64px);
  color: var(--c-fond);
  margin-bottom: var(--space-3);
  text-shadow: 0 2px 12px rgba(0,0,0,0.3);
}
.hero-meta {
  display: flex; gap: var(--space-2);
  flex-wrap: wrap;
}
.meta-pill {
  padding: 6px 14px;
  background: rgba(250, 247, 242, 0.2);
  backdrop-filter: blur(8px);
  border-radius: var(--r-pill);
  font-size: 13px;
  font-weight: 600;
  border: 1px solid rgba(250, 247, 242, 0.3);
}

/* === INTRO === */
.intro-section {
  padding: var(--space-6) var(--space-5);
}
.intro-text {
  font-size: 18px;
  color: var(--c-texte);
  max-width: 720px;
  line-height: 1.7;
  margin-bottom: var(--space-5);
}
.stats-row {
  display: flex;
  gap: var(--space-7);
  flex-wrap: wrap;
  padding: var(--space-4) 0;
  border-top: 1px solid var(--c-gris-clair);
  border-bottom: 1px solid var(--c-gris-clair);
}
.stat strong {
  display: block;
  font-family: var(--font-display);
  font-size: 36px;
  color: var(--c-primaire);
  line-height: 1;
}
.stat span {
  font-size: 13px;
  color: var(--c-texte-doux);
  letter-spacing: 0.04em;
}

/* === TABS === */
.tabs-section {
  background: var(--c-surface);
  border-bottom: 1px solid var(--c-gris-clair);
  position: sticky;
  top: 72px;
  z-index: 5;
}
.tabs {
  display: flex;
  gap: var(--space-2);
  padding: var(--space-3) 0;
  overflow-x: auto;
}
.tab {
  padding: 10px 18px;
  background: transparent;
  border: none;
  font-family: inherit;
  font-size: 14px;
  font-weight: 600;
  color: var(--c-texte-doux);
  cursor: pointer;
  border-radius: var(--r-pill);
  white-space: nowrap;
  transition: var(--t-base);
}
.tab:hover { color: var(--c-primaire); }
.tab.active {
  background: var(--c-primaire);
  color: var(--c-fond);
}

/* === CONTENT GRID === */
.content-section {
  padding: var(--space-6) var(--space-5) var(--space-9);
}
.content-grid {
  display: grid;
  grid-template-columns: 1.3fr 1fr;
  gap: var(--space-5);
  align-items: start;
}
.map-aside {
  position: sticky;
  top: 160px;
}
.resources-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-6);
}
.group-title {
  font-family: var(--font-display);
  font-size: 26px;
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-3);
  padding-bottom: var(--space-2);
  border-bottom: 2px solid var(--c-accent);
  display: inline-block;
}
.resource-cards {
  display: grid;
  gap: var(--space-3);
}
.resource-card {
  background: var(--c-surface);
  padding: var(--space-4);
  border-radius: var(--r-md);
  box-shadow: var(--ombre-douce);
  transition: var(--t-base);
}
.resource-card.clickable {
  padding: 0;
  border: none;
  text-align: left;
  font-family: inherit;
  cursor: pointer;
  width: 100%;
  display: block;
  overflow: hidden;
  position: relative; /* pour positionner le FavoriteButton flottant */
}
.resource-card.clickable:hover {
  transform: translateY(-2px);
  box-shadow: var(--ombre-elevee);
}
.resource-card.clickable:focus-visible {
  outline: 2px solid var(--c-accent, #D4A04F);
  outline-offset: 2px;
}
.resource-card.clickable .rc-content {
  padding: var(--space-4);
}
.rc-cover {
  display: block;
  width: 100%;
  height: 180px;
  background-size: cover;
  background-position: center;
  background-color: var(--c-fond-chaud);
}
.resource-card:hover {
  transform: translateY(-2px);
  box-shadow: var(--ombre-elevee);
}
.rc-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: var(--space-3);
  padding-top: var(--space-3);
  border-top: 1px solid var(--c-gris-clair);
}
.rc-cta {
  color: var(--c-accent-fort, #B8862E);
  font-weight: 600;
  font-size: 13px;
  letter-spacing: 0.02em;
}
.rc-badge-360 {
  display: inline-flex;
  align-items: center;
  background: linear-gradient(135deg, #D4A04F, #B8862E);
  color: white;
  padding: 4px 12px;
  border-radius: 999px;
  font-size: 11px;
  font-weight: 600;
  cursor: pointer;
  transition: transform 0.15s;
}
.rc-badge-360:hover { transform: scale(1.05); }
.rc-header {
  display: flex; justify-content: space-between; align-items: center;
  gap: var(--space-2);
  margin-bottom: 6px;
}
.rc-header strong {
  font-family: var(--font-display);
  font-size: 20px;
  color: var(--c-primaire-profond);
}
.rc-tag {
  font-size: 11px;
  padding: 3px 10px;
  background: var(--c-fond-chaud);
  color: var(--c-accent-fort);
  border-radius: var(--r-pill);
  font-weight: 600;
  white-space: nowrap;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}
.rc-stars { color: var(--c-accent); font-size: 16px; }
.rc-arabic {
  color: var(--c-accent-fort);
  font-size: 15px;
  margin-bottom: 6px;
}
.rc-desc {
  color: var(--c-texte);
  font-size: 14px;
  line-height: 1.6;
  margin-bottom: var(--space-2);
}
.rc-meta {
  display: flex;
  gap: var(--space-3);
  font-size: 13px;
  color: var(--c-texte-doux);
  flex-wrap: wrap;
}
.rc-address { font-weight: 500; }
.rc-amenities {
  display: flex; gap: 6px;
  flex-wrap: wrap;
  margin-top: var(--space-2);
  padding-top: var(--space-2);
  border-top: 1px solid var(--c-gris-clair);
}
.amenity {
  font-size: 11px;
  padding: 3px 8px;
  background: var(--c-fond-chaud);
  color: var(--c-primaire);
  border-radius: var(--r-pill);
}
.amenity.dishes {
  background: rgba(212, 160, 79, 0.15);
  color: var(--c-accent-fort);
}

.empty-state {
  text-align: center;
  padding: var(--space-7);
  color: var(--c-texte-doux);
  background: var(--c-fond-chaud);
  border-radius: var(--r-md);
}

@media (max-width: 980px) {
  .content-grid { grid-template-columns: 1fr; }
  .map-aside { position: static; height: 360px; }
}

.rc-operator {
  margin-top: var(--space-2);
  padding-top: var(--space-2);
  border-top: 1px solid var(--c-fond-chaud);
  font-size: 12px;
  color: var(--c-texte-doux);
}
.rc-operator strong { color: var(--c-primaire-profond); }

/* === BADGE 360 + MODALE === */
.badge-360-btn {
  margin-top: var(--space-2);
  background: linear-gradient(135deg, var(--c-accent), var(--c-accent-fort));
  color: var(--c-fond);
  border: none;
  border-radius: var(--r-pill);
  padding: 6px 14px;
  font-family: inherit;
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 0.05em;
  cursor: pointer;
  transition: var(--t-base);
  box-shadow: 0 2px 8px rgba(212, 160, 79, 0.3);
}
.badge-360-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 14px rgba(212, 160, 79, 0.5);
}

.panorama-modal {
  position: fixed;
  inset: 0;
  background: rgba(10, 31, 46, 0.85);
  backdrop-filter: blur(8px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 99999;
  padding: var(--space-3);
}
.panorama-modal-inner {
  background: var(--c-surface);
  border-radius: var(--r-lg);
  width: 100%;
  max-width: 1200px;
  max-height: 92vh;
  overflow: hidden;
  box-shadow: 0 24px 80px rgba(0,0,0,0.4);
}
.panorama-modal-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: var(--space-3) var(--space-4);
  border-bottom: 1px solid var(--c-fond-chaud);
}
.panorama-modal-head h3 {
  font-family: var(--font-display);
  font-size: 22px;
  color: var(--c-primaire-profond);
  margin: 0;
}
.panorama-modal-head .arabic {
  font-size: 14px;
  color: var(--c-accent-fort);
  margin: 0;
}
.modal-close {
  background: var(--c-fond-chaud);
  border: none;
  width: 36px; height: 36px;
  border-radius: 50%;
  cursor: pointer;
  font-size: 14px;
  color: var(--c-primaire);
  transition: var(--t-base);
}
.modal-close:hover { background: var(--c-gris-clair); }

.fade-enter-active, .fade-leave-active { transition: opacity 0.25s; }
.fade-enter-from, .fade-leave-to { opacity: 0; }
</style>
