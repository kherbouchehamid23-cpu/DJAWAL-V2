<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'

interface Memory {
  id: string
  quote: string
  photo_url: string | null
  created_at: string
  destination_id: string | null
  profiles?: { display_name: string } | null
  destinations?: { name: string; wilaya: string; cultural_theme: string } | null
  trips?: { title: string; id: string } | null
}

interface Destination {
  id: string
  name: string
  cultural_theme: string
}

const memories = ref<Memory[]>([])
const destinations = ref<Destination[]>([])
const loading = ref(true)
const destFilter = ref<string>('all')
const themeFilter = ref<'all' | 'saharien' | 'mauresque' | 'aures'>('all')
const search = ref('')

const filtered = computed(() => {
  const q = search.value.toLowerCase().trim()
  return memories.value.filter(m => {
    if (destFilter.value !== 'all' && m.destination_id !== destFilter.value) return false
    if (themeFilter.value !== 'all' && m.destinations?.cultural_theme !== themeFilter.value) return false
    if (q && !m.quote.toLowerCase().includes(q)) return false
    return true
  })
})

onMounted(async () => {
  loading.value = true
  const [memRes, destRes] = await Promise.all([
    supabase
      .from('memories')
      .select('id, quote, photo_url, created_at, destination_id, profiles!memories_author_id_fkey(display_name), destinations(name, wilaya, cultural_theme), trips(id, title)')
      .eq('published', true)
      .order('created_at', { ascending: false }),
    supabase.from('destinations').select('id, name, cultural_theme').order('name')
  ])
  if (memRes.data) memories.value = memRes.data as any[]
  if (destRes.data) destinations.value = destRes.data as Destination[]
  loading.value = false
})

function fmtDate(iso: string) {
  return new Date(iso).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric' })
}
</script>

<template>
  <div class="memories-page">
    <!-- HERO -->
    <header class="page-hero">
      <div class="djawal-container">
        <div class="hero-tag arabic">ذكريات</div>
        <h1>Le mur des souvenirs</h1>
        <p class="lead">
          {{ memories.length }} fragments d'expérience partagés par celles et ceux qui ont
          parcouru l'Algérie. Chaque souvenir est un appel au voyage.
        </p>
      </div>
    </header>

    <!-- FILTRES -->
    <section class="filters-bar">
      <div class="djawal-container filters-inner">
        <v-text-field
          v-model="search"
          density="comfortable"
          variant="outlined"
          placeholder="Chercher dans les souvenirs…"
          prepend-inner-icon="mdi-magnify"
          clearable
          hide-details
          class="search-field"
        />
        <v-select
          v-model="destFilter"
          :items="[{ value: 'all', title: 'Toutes destinations' }, ...destinations.map(d => ({ value: d.id, title: d.name }))]"
          density="comfortable"
          variant="outlined"
          hide-details
          class="dest-select"
        />
        <div class="theme-chips">
          <button
            v-for="t in [
              { v: 'all', l: 'Tous', i: '✨' },
              { v: 'saharien', l: 'Saharien', i: '🏜️', c: '#D4A04F' },
              { v: 'mauresque', l: 'Mauresque', i: '🏛️', c: '#1B4965' },
              { v: 'aures', l: 'Aurès', i: '⛰️', c: '#2D5A3D' }
            ]"
            :key="t.v"
            class="chip"
            :class="{ active: themeFilter === t.v }"
            :style="themeFilter === t.v && t.c ? `background: ${t.c}; color: white;` : ''"
            @click="themeFilter = t.v as any"
          >
            {{ t.i }} {{ t.l }}
          </button>
        </div>
      </div>
    </section>

    <!-- GRILLE -->
    <section class="djawal-container djawal-section">
      <div v-if="loading" class="loading">Chargement…</div>

      <div v-else-if="filtered.length === 0" class="empty">
        <p v-if="memories.length === 0">Pas encore de souvenirs partagés.</p>
        <p v-else>Aucun souvenir ne correspond à votre recherche.</p>
      </div>

      <div v-else class="masonry">
        <article
          v-for="m in filtered"
          :key="m.id"
          class="mem-card"
          :data-theme="m.destinations?.cultural_theme"
          :data-has-photo="!!m.photo_url"
        >
          <div
            v-if="m.photo_url"
            class="mem-photo"
            :style="`background-image: url(${m.photo_url})`"
          ></div>
          <div class="mem-body">
            <p class="mem-quote">« {{ m.quote }} »</p>

            <div class="mem-meta">
              <strong>{{ m.profiles?.display_name }}</strong>
              <span class="mem-date">{{ fmtDate(m.created_at) }}</span>
            </div>

            <div v-if="m.destinations || m.trips" class="mem-link">
              <router-link
                v-if="m.trips"
                :to="`/voyages/${m.trips.id}`"
              >🗺️ {{ m.trips.title }}</router-link>
              <span v-else-if="m.destinations">📍 {{ m.destinations.name }}</span>
            </div>
          </div>
        </article>
      </div>
    </section>
  </div>
</template>

<style scoped>
.memories-page { background: var(--c-fond); min-height: 100vh; }

.page-hero {
  background: var(--c-fond-chaud);
  padding: var(--space-7) var(--space-5) var(--space-5);
  position: relative;
  overflow: hidden;
}
.page-hero::before {
  content: ''; position: absolute; inset: 0;
  background-image: var(--motif-principal-url);
  opacity: 0.4; pointer-events: none;
}
.hero-tag {
  font-size: 20px;
  color: var(--c-accent-fort);
  margin-bottom: 8px;
  position: relative;
}
.page-hero h1 {
  font-size: clamp(32px, 4.5vw, 52px);
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-2);
  position: relative;
}
.lead {
  font-size: 17px;
  color: var(--c-primaire);
  max-width: 720px;
  position: relative;
  line-height: 1.5;
}

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
  display: flex; gap: var(--space-3);
  align-items: center;
  flex-wrap: wrap;
}
.search-field { flex: 1; min-width: 240px; max-width: 360px; }
.dest-select { min-width: 220px; }

.theme-chips { display: flex; gap: var(--space-2); flex-wrap: wrap; }
.chip {
  display: inline-flex; align-items: center; gap: 6px;
  padding: 8px 14px;
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

.loading, .empty {
  text-align: center; padding: var(--space-8);
  color: var(--c-texte-doux);
}

.masonry {
  columns: 3;
  column-gap: var(--space-4);
}
@media (max-width: 960px) { .masonry { columns: 2; } }
@media (max-width: 600px) { .masonry { columns: 1; } }

.mem-card {
  break-inside: avoid;
  background: var(--c-surface);
  border-radius: var(--r-lg);
  overflow: hidden;
  box-shadow: var(--ombre-douce);
  margin-bottom: var(--space-4);
  border-top: 4px solid var(--c-primaire);
  transition: var(--t-base);
}
.mem-card[data-theme="saharien"] { border-top-color: #D4A04F; }
.mem-card[data-theme="mauresque"] { border-top-color: #1B4965; }
.mem-card[data-theme="aures"] { border-top-color: #2D5A3D; }

.mem-card:hover {
  transform: translateY(-3px);
  box-shadow: var(--ombre-elevee);
}

.mem-photo {
  height: 220px;
  background-size: cover;
  background-position: center;
}
.mem-body { padding: var(--space-4); }

.mem-quote {
  font-family: var(--font-display);
  font-size: 18px;
  font-style: italic;
  color: var(--c-primaire-profond);
  line-height: 1.5;
  margin-bottom: var(--space-3);
}
.mem-card[data-has-photo="false"] .mem-quote { font-size: 20px; }

.mem-meta {
  display: flex; justify-content: space-between; align-items: baseline;
  font-size: 13px;
  border-top: 1px solid var(--c-fond-chaud);
  padding-top: var(--space-2);
}
.mem-meta strong { color: var(--c-accent-fort); }
.mem-date { color: var(--c-texte-doux); font-size: 12px; }

.mem-link {
  margin-top: var(--space-2);
  font-size: 12px;
}
.mem-link a {
  color: var(--c-accent-fort);
  font-weight: 600;
  text-decoration: none;
}
.mem-link a:hover { text-decoration: underline; }
.mem-link span { color: var(--c-texte-doux); font-style: italic; }
</style>
