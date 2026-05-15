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
    <!-- HERO COMPACT V4 -->
    <header class="page-hero">
      <div class="hero-overlay"></div>
      <div class="djawal-container hero-content">
        <div class="hero-eyebrow">
          <span class="eyebrow-line"></span>
          <span>Le mur des souvenirs</span>
          <span class="eyebrow-line"></span>
        </div>
        <h1>Récits <em>de voyage</em></h1>
        <p class="lead">
          {{ memories.length }} fragments d'expérience partagés par celles et ceux qui ont
          parcouru l'Algérie. Chaque souvenir est un appel au voyage.
        </p>
      </div>
    </header>

    <!-- FILTRES V4 -->
    <section class="filters-bar">
      <div class="djawal-container filters-inner">
        <div class="search-wrap">
          <svg class="search-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="11" cy="11" r="7"/>
            <path d="M21 21 L16 16"/>
          </svg>
          <input
            v-model="search"
            type="search"
            placeholder="Chercher dans les souvenirs…"
            class="search-input"
          />
        </div>
        <select v-model="destFilter" class="dest-select">
          <option value="all">Toutes destinations</option>
          <option v-for="d in destinations" :key="d.id" :value="d.id">{{ d.name }}</option>
        </select>
        <div class="theme-chips">
          <button
            v-for="t in [
              { v: 'all', l: 'Tous', i: '✨' },
              { v: 'saharien', l: 'Saharien', i: '🏜️' },
              { v: 'mauresque', l: 'Mauresque', i: '🏛️' },
              { v: 'aures', l: 'Aurès', i: '⛰️' }
            ]"
            :key="t.v"
            class="chip"
            :class="{ active: themeFilter === t.v }"
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
.memories-page {
  background: linear-gradient(180deg, #0F2419 0%, #1A3A2A 60%, #0F2419 100%);
  min-height: 100vh;
  color: #FAF7F2;
  font-family: 'Inter', sans-serif;
}
.djawal-container { max-width: 1280px; margin: 0 auto; padding: 0 32px; }
.djawal-section { padding: 70px 0; }

/* === HERO COMPACT V4 === */
.page-hero {
  position: relative;
  min-height: 48vh;
  display: flex; align-items: center; justify-content: center;
  text-align: center;
  padding: 120px 32px 70px;
  overflow: hidden;
  background-image: url('https://images.pexels.com/photos/1098460/pexels-photo-1098460.jpeg?auto=compress&cs=tinysrgb&w=1920');
  background-size: cover;
  background-position: center;
}
.hero-overlay {
  position: absolute; inset: 0;
  background: linear-gradient(180deg, rgba(15, 36, 25, 0.62) 0%, rgba(15, 36, 25, 0.88) 60%, #0F2419 100%);
  z-index: 1;
}
.hero-content { position: relative; z-index: 2; }
.hero-eyebrow {
  display: inline-flex; align-items: center; gap: 14px;
  color: #E8B96B;
  font-size: 11px; letter-spacing: 0.24em;
  text-transform: uppercase;
  margin-bottom: 20px;
}
.eyebrow-line {
  width: 36px; height: 1px;
  background: linear-gradient(90deg, transparent, #D4A844, transparent);
}
.page-hero h1 {
  font-family: 'Cormorant Garamond', serif;
  font-size: clamp(36px, 5.5vw, 62px);
  font-weight: 400; line-height: 1.05;
  margin-bottom: 18px;
  color: #FAF7F2;
}
.page-hero h1 em { font-style: italic; color: #E8B96B; }
.lead {
  font-family: 'Cormorant Garamond', serif;
  font-style: italic;
  font-size: clamp(16px, 2vw, 20px);
  color: rgba(250, 247, 242, 0.78);
  max-width: 640px;
  margin: 0 auto;
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
  display: flex; gap: 16px;
  align-items: center;
  flex-wrap: wrap;
}
.search-wrap {
  position: relative;
  flex: 1; min-width: 240px; max-width: 360px;
}
.search-icon {
  position: absolute; left: 14px; top: 50%; transform: translateY(-50%);
  color: #E8B96B; pointer-events: none;
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
.search-input:focus { background: rgba(250, 247, 242, 0.12); border-color: #D4A844; }
.dest-select {
  background: rgba(250, 247, 242, 0.06);
  border: 1px solid rgba(212, 168, 68, 0.3);
  color: #FAF7F2;
  padding: 11px 16px;
  border-radius: 999px;
  font-family: inherit;
  font-size: 13px;
  cursor: pointer;
  min-width: 220px;
  outline: none;
}
.dest-select option { background: #1A3A2A; color: #FAF7F2; }

.theme-chips { display: flex; gap: 8px; flex-wrap: wrap; }
.chip {
  display: inline-flex; align-items: center; gap: 6px;
  padding: 8px 14px;
  background: rgba(250, 247, 242, 0.06);
  border: 1px solid rgba(212, 168, 68, 0.25);
  color: #FAF7F2;
  border-radius: 999px;
  font-family: inherit;
  font-size: 13px; font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}
.chip:hover { background: rgba(212, 168, 68, 0.15); border-color: rgba(212, 168, 68, 0.55); }
.chip.active { background: #D4A844; color: #0F2419; border-color: #D4A844; font-weight: 600; }

.loading, .empty {
  text-align: center; padding: 80px 20px;
  color: rgba(250, 247, 242, 0.55);
  font-family: 'Cormorant Garamond', serif;
  font-style: italic;
  font-size: 18px;
}

/* === MASONRY V4 === */
.masonry {
  columns: 3;
  column-gap: 22px;
}
@media (max-width: 960px) { .masonry { columns: 2; } }
@media (max-width: 600px) { .masonry { columns: 1; } }

.mem-card {
  break-inside: avoid;
  background: rgba(31, 74, 54, 0.5);
  border: 1px solid rgba(212, 168, 68, 0.18);
  border-radius: 16px;
  overflow: hidden;
  margin-bottom: 22px;
  border-top: 3px solid #D4A844;
  transition: all 0.3s;
}
.mem-card[data-theme="saharien"] { border-top-color: #E8B96B; }
.mem-card[data-theme="mauresque"] { border-top-color: #6FA8C0; }
.mem-card[data-theme="aures"] { border-top-color: #A8C76F; }
.mem-card:hover {
  transform: translateY(-4px);
  background: rgba(31, 74, 54, 0.75);
  border-color: rgba(212, 168, 68, 0.5);
  box-shadow: 0 14px 38px rgba(0, 0, 0, 0.45);
}
.mem-photo {
  height: 220px;
  background-size: cover;
  background-position: center;
}
.mem-body { padding: 22px 24px; }
.mem-quote {
  font-family: 'Cormorant Garamond', serif;
  font-size: 19px;
  font-style: italic;
  color: #FAF7F2;
  line-height: 1.5;
  margin-bottom: 18px;
}
.mem-card[data-has-photo="false"] .mem-quote { font-size: 22px; }
.mem-meta {
  display: flex; justify-content: space-between; align-items: baseline;
  font-size: 13px;
  border-top: 1px solid rgba(212, 168, 68, 0.2);
  padding-top: 12px;
}
.mem-meta strong {
  color: #E8B96B;
  font-family: 'Cormorant Garamond', serif;
  font-style: italic;
  font-weight: 500;
  font-size: 15px;
}
.mem-date { color: rgba(250, 247, 242, 0.5); font-size: 11.5px; letter-spacing: 0.05em; }

.mem-link {
  margin-top: 10px;
  font-size: 12px;
}
.mem-link a {
  color: #E8B96B;
  font-weight: 600;
  text-decoration: none;
  transition: color 0.2s;
}
.mem-link a:hover { color: #FAF7F2; }
.mem-link span { color: rgba(250, 247, 242, 0.55); font-style: italic; }

@media (max-width: 700px) {
  .djawal-container { padding: 0 20px; }
  .page-hero { min-height: 38vh; padding: 90px 20px 50px; }
  .djawal-section { padding: 50px 0; }
}
</style>
