<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { supabase } from '@/lib/supabase'

interface DestinationRow {
  id: string
  name: string
  wilaya: string
  cultural_theme: string
  hero_image_url: string | null
  tagline: string | null
  is_featured_homepage: boolean
  homepage_display_order: number
}

interface TripRow {
  id: string
  title: string
  duration_days: number
  price_da: number
  cover_image_url: string | null
  status: string
  destinations?: { name: string; wilaya: string } | null
  profiles?: { display_name: string; role: string } | null
  is_featured_homepage: boolean
  homepage_display_order: number
}

const destinations = ref<DestinationRow[]>([])
const trips = ref<TripRow[]>([])
const loading = ref(true)
const savingDest = ref<string | null>(null)
const savingTrip = ref<string | null>(null)
const flash = ref<{ type: 'ok' | 'err'; msg: string } | null>(null)

const MAX_HOMEPAGE_DESTINATIONS = 12
const MAX_HOMEPAGE_TRIPS = 3

async function load() {
  loading.value = true

  const [destRes, tripRes] = await Promise.all([
    supabase
      .from('destinations')
      .select('id, name, wilaya, cultural_theme, hero_image_url, tagline, is_featured_homepage, homepage_display_order')
      .order('homepage_display_order', { ascending: true })
      .order('name', { ascending: true }),
    supabase
      .from('trips')
      .select(`
        id, title, duration_days, price_da, cover_image_url, status,
        is_featured_homepage, homepage_display_order,
        destinations(name, wilaya),
        profiles!trips_created_by_fkey(display_name, role)
      `)
      .eq('status', 'published')
      .order('homepage_display_order', { ascending: true })
      .order('created_at', { ascending: false })
  ])

  destinations.value = (destRes.data as any) || []
  trips.value = (tripRes.data as any) || []
  loading.value = false
}
onMounted(load)

// === Destinations ===
const featuredDestCount = computed(() => destinations.value.filter(d => d.is_featured_homepage).length)
const featuredDests = computed(() => destinations.value.filter(d => d.is_featured_homepage).sort((a, b) => a.homepage_display_order - b.homepage_display_order))
const unfeaturedDests = computed(() => destinations.value.filter(d => !d.is_featured_homepage).sort((a, b) => a.name.localeCompare(b.name)))

async function toggleFeaturedDest(d: DestinationRow) {
  if (!d.is_featured_homepage && featuredDestCount.value >= MAX_HOMEPAGE_DESTINATIONS) {
    flash.value = { type: 'err', msg: `Maximum ${MAX_HOMEPAGE_DESTINATIONS} destinations vedettes.` }
    return
  }
  savingDest.value = d.id
  const newOrder = !d.is_featured_homepage
    ? (Math.max(0, ...featuredDests.value.map(x => x.homepage_display_order)) + 1)
    : 999
  const { error } = await supabase
    .from('destinations')
    .update({
      is_featured_homepage: !d.is_featured_homepage,
      homepage_display_order: newOrder
    })
    .eq('id', d.id)
  savingDest.value = null
  if (error) { flash.value = { type: 'err', msg: error.message }; return }
  d.is_featured_homepage = !d.is_featured_homepage
  d.homepage_display_order = newOrder
  flash.value = { type: 'ok', msg: `${d.name} ${d.is_featured_homepage ? 'ajoutée' : 'retirée'}.` }
}

async function moveDest(d: DestinationRow, direction: -1 | 1) {
  const sorted = featuredDests.value
  const idx = sorted.findIndex(x => x.id === d.id)
  const swapIdx = idx + direction
  if (swapIdx < 0 || swapIdx >= sorted.length) return
  const other = sorted[swapIdx]
  savingDest.value = d.id
  // Échange leur display_order
  await Promise.all([
    supabase.from('destinations').update({ homepage_display_order: other.homepage_display_order }).eq('id', d.id),
    supabase.from('destinations').update({ homepage_display_order: d.homepage_display_order }).eq('id', other.id)
  ])
  const tmp = d.homepage_display_order
  d.homepage_display_order = other.homepage_display_order
  other.homepage_display_order = tmp
  savingDest.value = null
}

async function updateTagline(d: DestinationRow, value: string) {
  savingDest.value = d.id
  const { error } = await supabase
    .from('destinations')
    .update({ tagline: value || null })
    .eq('id', d.id)
  savingDest.value = null
  if (error) flash.value = { type: 'err', msg: error.message }
  else d.tagline = value || null
}

// === Trips ===
const featuredTripsCount = computed(() => trips.value.filter(t => t.is_featured_homepage).length)
const featuredTrips = computed(() => trips.value.filter(t => t.is_featured_homepage).sort((a, b) => a.homepage_display_order - b.homepage_display_order))
const unfeaturedTrips = computed(() => trips.value.filter(t => !t.is_featured_homepage))

async function toggleFeaturedTrip(t: TripRow) {
  if (!t.is_featured_homepage && featuredTripsCount.value >= MAX_HOMEPAGE_TRIPS) {
    flash.value = { type: 'err', msg: `Maximum ${MAX_HOMEPAGE_TRIPS} voyages signés sur la HomePage.` }
    return
  }
  savingTrip.value = t.id
  const newOrder = !t.is_featured_homepage
    ? (Math.max(0, ...featuredTrips.value.map(x => x.homepage_display_order)) + 1)
    : 999
  const { error } = await supabase
    .from('trips')
    .update({
      is_featured_homepage: !t.is_featured_homepage,
      homepage_display_order: newOrder
    })
    .eq('id', t.id)
  savingTrip.value = null
  if (error) { flash.value = { type: 'err', msg: error.message }; return }
  t.is_featured_homepage = !t.is_featured_homepage
  t.homepage_display_order = newOrder
  flash.value = { type: 'ok', msg: `${t.title} ${t.is_featured_homepage ? 'ajouté' : 'retiré'}.` }
}

async function moveTrip(t: TripRow, direction: -1 | 1) {
  const sorted = featuredTrips.value
  const idx = sorted.findIndex(x => x.id === t.id)
  const swapIdx = idx + direction
  if (swapIdx < 0 || swapIdx >= sorted.length) return
  const other = sorted[swapIdx]
  savingTrip.value = t.id
  await Promise.all([
    supabase.from('trips').update({ homepage_display_order: other.homepage_display_order }).eq('id', t.id),
    supabase.from('trips').update({ homepage_display_order: t.homepage_display_order }).eq('id', other.id)
  ])
  const tmp = t.homepage_display_order
  t.homepage_display_order = other.homepage_display_order
  other.homepage_display_order = tmp
  savingTrip.value = null
}

function fmtPrice(p: number) {
  return new Intl.NumberFormat('fr-DZ').format(p) + ' DA'
}
</script>

<template>
  <div class="hp-admin">
    <div class="djawal-container djawal-section">
      <div class="back-link">
        <router-link to="/admin">← Retour admin</router-link>
      </div>

      <header class="page-header">
        <div class="section-eyebrow">Configuration HomePage</div>
        <h1>Contenus en vedette sur la page d'accueil</h1>
        <p class="lead">Sélectionnez les destinations à afficher dans le carrousel mauresque et les 3 voyages signés mis en avant. Glissez l'ordre via les flèches.</p>
      </header>

      <div v-if="flash" class="flash" :class="flash.type" @click="flash = null">
        {{ flash.msg }} <span class="flash-close">✕</span>
      </div>

      <div v-if="loading" class="loading">Chargement…</div>

      <template v-else>
        <!-- =================== DESTINATIONS VEDETTES =================== -->
        <section class="block">
          <header class="block-head">
            <h2>🗺️ Destinations du carrousel</h2>
            <span class="count-badge" :class="{ full: featuredDestCount >= MAX_HOMEPAGE_DESTINATIONS }">
              {{ featuredDestCount }} / {{ MAX_HOMEPAGE_DESTINATIONS }}
            </span>
          </header>

          <h3 class="subhead">Sélectionnées ({{ featuredDestCount }})</h3>
          <div v-if="featuredDests.length === 0" class="empty">
            Aucune destination sélectionnée. Cochez-en ci-dessous.
          </div>
          <div v-else class="featured-list">
            <article v-for="(d, idx) in featuredDests" :key="d.id" class="featured-item">
              <div class="order-controls">
                <button class="ord-btn" :disabled="idx === 0 || savingDest === d.id" @click="moveDest(d, -1)" title="Monter">↑</button>
                <span class="ord-pos">{{ idx + 1 }}</span>
                <button class="ord-btn" :disabled="idx === featuredDests.length - 1 || savingDest === d.id" @click="moveDest(d, 1)" title="Descendre">↓</button>
              </div>
              <div class="item-img" :style="d.hero_image_url ? `background-image: url(${d.hero_image_url})` : ''">
                <span v-if="!d.hero_image_url">📷</span>
              </div>
              <div class="item-body">
                <div class="item-title">{{ d.name }}</div>
                <div class="item-meta">{{ d.wilaya }} · {{ d.cultural_theme }}</div>
                <input
                  type="text"
                  class="tagline-input"
                  :value="d.tagline || ''"
                  :placeholder="`Sous-titre (ex: Saharien · UNESCO)`"
                  @blur="updateTagline(d, ($event.target as HTMLInputElement).value)"
                />
              </div>
              <button class="rm-btn" :disabled="savingDest === d.id" @click="toggleFeaturedDest(d)">Retirer</button>
            </article>
          </div>

          <h3 class="subhead">Disponibles ({{ unfeaturedDests.length }})</h3>
          <div class="grid">
            <button
              v-for="d in unfeaturedDests"
              :key="d.id"
              class="card-pick"
              :disabled="savingDest === d.id || featuredDestCount >= MAX_HOMEPAGE_DESTINATIONS"
              @click="toggleFeaturedDest(d)"
            >
              <div class="card-img" :style="d.hero_image_url ? `background-image: url(${d.hero_image_url})` : ''">
                <span v-if="!d.hero_image_url">📷</span>
              </div>
              <div class="card-name">{{ d.name }}</div>
              <div class="card-meta">{{ d.wilaya }}</div>
              <div class="card-add">+ Ajouter</div>
            </button>
          </div>

          <p class="note">
            Les destinations ici sont gérées dans <router-link to="/admin/destinations">Master Data — Destinations</router-link>.
            Pour modifier la photo ou la description, allez-y.
          </p>
        </section>

        <!-- =================== VOYAGES SIGNÉS =================== -->
        <section class="block">
          <header class="block-head">
            <h2>🧭 Voyages signés Djawal (HomePage)</h2>
            <span class="count-badge" :class="{ full: featuredTripsCount >= MAX_HOMEPAGE_TRIPS }">
              {{ featuredTripsCount }} / {{ MAX_HOMEPAGE_TRIPS }}
            </span>
          </header>

          <h3 class="subhead">Sélectionnés ({{ featuredTripsCount }})</h3>
          <div v-if="featuredTrips.length === 0" class="empty">
            Aucun voyage sélectionné. Cochez-en ci-dessous (uniquement les voyages <strong>publiés</strong> apparaissent).
          </div>
          <div v-else class="featured-list">
            <article v-for="(t, idx) in featuredTrips" :key="t.id" class="featured-item">
              <div class="order-controls">
                <button class="ord-btn" :disabled="idx === 0 || savingTrip === t.id" @click="moveTrip(t, -1)" title="Monter">↑</button>
                <span class="ord-pos">{{ idx + 1 }}</span>
                <button class="ord-btn" :disabled="idx === featuredTrips.length - 1 || savingTrip === t.id" @click="moveTrip(t, 1)" title="Descendre">↓</button>
              </div>
              <div class="item-img" :style="t.cover_image_url ? `background-image: url(${t.cover_image_url})` : ''">
                <span v-if="!t.cover_image_url">📷</span>
              </div>
              <div class="item-body">
                <div class="item-title">{{ t.title }}</div>
                <div class="item-meta">
                  {{ t.destinations?.name || '?' }} · {{ t.duration_days }}j · {{ fmtPrice(t.price_da) }}
                  <span v-if="t.profiles"> · {{ t.profiles.display_name }}</span>
                </div>
              </div>
              <button class="rm-btn" :disabled="savingTrip === t.id" @click="toggleFeaturedTrip(t)">Retirer</button>
            </article>
          </div>

          <h3 class="subhead">Voyages publiés disponibles ({{ unfeaturedTrips.length }})</h3>
          <div v-if="unfeaturedTrips.length === 0" class="empty">
            Aucun voyage publié disponible. <router-link to="/admin/moderation">Modérer les soumissions</router-link>.
          </div>
          <div v-else class="grid">
            <button
              v-for="t in unfeaturedTrips"
              :key="t.id"
              class="card-pick trip-pick"
              :disabled="savingTrip === t.id || featuredTripsCount >= MAX_HOMEPAGE_TRIPS"
              @click="toggleFeaturedTrip(t)"
            >
              <div class="card-img" :style="t.cover_image_url ? `background-image: url(${t.cover_image_url})` : ''">
                <span v-if="!t.cover_image_url">📷</span>
              </div>
              <div class="card-name">{{ t.title }}</div>
              <div class="card-meta">
                {{ t.destinations?.name }} · {{ t.duration_days }}j · {{ fmtPrice(t.price_da) }}
              </div>
              <div class="card-add">+ Mettre en vedette</div>
            </button>
          </div>
        </section>
      </template>
    </div>
  </div>
</template>

<style scoped>
.hp-admin { background: var(--c-fond); min-height: 100vh; }
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

.flash {
  margin-bottom: var(--space-3);
  padding: 12px 16px;
  border-radius: var(--r-md);
  font-size: 13.5px;
  cursor: pointer;
  display: flex; justify-content: space-between; align-items: center;
}
.flash.ok { background: #E1F5EE; color: #04342C; border: 1px solid #5DCAA5; }
.flash.err { background: #FCEBEB; color: #501313; border: 1px solid #E24B4A; }
.flash-close { font-size: 14px; opacity: 0.7; }

.loading { text-align: center; padding: var(--space-8); color: var(--c-texte-doux); }

.block {
  background: var(--c-surface);
  border-radius: var(--r-lg);
  box-shadow: var(--ombre-douce);
  padding: var(--space-5);
  margin-bottom: var(--space-5);
}
.block-head {
  display: flex; justify-content: space-between; align-items: center;
  margin-bottom: var(--space-3);
  border-bottom: 1px solid var(--c-fond-chaud);
  padding-bottom: var(--space-2);
}
.block-head h2 {
  font-family: var(--font-display);
  font-size: 24px;
  color: var(--c-primaire);
  font-weight: 500;
}
.count-badge {
  background: var(--c-fond-chaud);
  color: var(--c-primaire);
  padding: 4px 12px;
  border-radius: var(--r-pill);
  font-size: 12px;
  font-weight: 700;
}
.count-badge.full { background: var(--c-cta); color: white; }

.subhead {
  font-size: 14px;
  color: var(--c-texte-doux);
  text-transform: uppercase;
  letter-spacing: 0.08em;
  font-weight: 600;
  margin: var(--space-3) 0 var(--space-2);
}

.empty {
  text-align: center;
  padding: var(--space-4);
  color: var(--c-texte-doux);
  background: var(--c-fond-chaud);
  border-radius: var(--r-md);
  font-size: 13.5px;
  font-style: italic;
}

/* Liste des featured */
.featured-list {
  display: flex; flex-direction: column;
  gap: 10px;
  margin-bottom: var(--space-3);
}
.featured-item {
  display: grid;
  grid-template-columns: auto 80px 1fr auto;
  align-items: center;
  gap: 14px;
  background: var(--c-fond-chaud);
  border: 1px solid var(--c-gris-clair);
  border-radius: var(--r-md);
  padding: 12px 14px;
}
.order-controls {
  display: flex; flex-direction: column; align-items: center;
  gap: 4px;
}
.ord-btn {
  width: 26px; height: 26px;
  border-radius: 6px;
  border: 1px solid var(--c-gris-clair);
  background: white;
  cursor: pointer;
  font-size: 12px;
  font-weight: 700;
  color: var(--c-primaire);
}
.ord-btn:hover:not(:disabled) { background: var(--c-fond-chaud); }
.ord-btn:disabled { opacity: 0.3; cursor: not-allowed; }
.ord-pos {
  font-size: 14px;
  font-weight: 700;
  color: var(--c-primaire);
}

.item-img {
  width: 80px; height: 60px;
  border-radius: 6px;
  background: var(--c-gris-clair) center/cover no-repeat;
  display: flex; align-items: center; justify-content: center;
  font-size: 20px;
  color: var(--c-texte-doux);
}
.item-body { min-width: 0; }
.item-title {
  font-weight: 600;
  font-size: 14.5px;
  color: var(--c-primaire);
  margin-bottom: 2px;
}
.item-meta {
  font-size: 12px;
  color: var(--c-texte-doux);
  margin-bottom: 6px;
}
.tagline-input {
  width: 100%;
  padding: 6px 10px;
  border: 1px solid var(--c-gris-clair);
  border-radius: 6px;
  font-size: 12.5px;
  font-family: inherit;
  background: white;
}
.tagline-input:focus { outline: none; border-color: var(--c-primaire); }

.rm-btn {
  background: transparent;
  border: 1px solid #A32D2D;
  color: #A32D2D;
  padding: 7px 14px;
  border-radius: var(--r-pill);
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  font-family: inherit;
  white-space: nowrap;
}
.rm-btn:hover:not(:disabled) { background: #FCEBEB; }
.rm-btn:disabled { opacity: 0.5; cursor: wait; }

/* Grille des candidats */
.grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: 12px;
}
.card-pick {
  background: white;
  border: 1.5px solid var(--c-gris-clair);
  border-radius: var(--r-md);
  padding: 10px;
  cursor: pointer;
  text-align: center;
  font-family: inherit;
  transition: all 0.15s;
  display: flex; flex-direction: column; gap: 4px;
}
.card-pick:hover:not(:disabled) {
  border-color: var(--c-accent);
  transform: translateY(-2px);
  box-shadow: var(--ombre-douce);
}
.card-pick:disabled { opacity: 0.4; cursor: not-allowed; }
.card-img {
  width: 100%; aspect-ratio: 4 / 3;
  border-radius: 6px;
  background: var(--c-gris-clair) center/cover no-repeat;
  display: flex; align-items: center; justify-content: center;
  font-size: 28px;
  color: var(--c-texte-doux);
  margin-bottom: 6px;
}
.card-name {
  font-size: 13.5px;
  font-weight: 600;
  color: var(--c-primaire);
  line-height: 1.3;
}
.card-meta {
  font-size: 11px;
  color: var(--c-texte-doux);
}
.card-add {
  margin-top: 6px;
  font-size: 11px;
  font-weight: 600;
  color: var(--c-accent-fort);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
.trip-pick .card-name { font-size: 13px; }

.note {
  margin-top: var(--space-3);
  font-size: 12.5px;
  color: var(--c-texte-doux);
  padding: 12px 14px;
  background: var(--c-fond-chaud);
  border-radius: var(--r-md);
  border-left: 3px solid var(--c-accent);
}
.note a { color: var(--c-primaire); font-weight: 600; }

@media (max-width: 720px) {
  .featured-item { grid-template-columns: auto 60px 1fr; }
  .featured-item .rm-btn { grid-column: 1 / -1; justify-self: end; }
  .item-img { width: 60px; height: 50px; }
  .grid { grid-template-columns: repeat(auto-fill, minmax(140px, 1fr)); }
}
</style>
