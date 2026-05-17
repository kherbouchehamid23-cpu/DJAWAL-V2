<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useSEO } from '@/composables/useSEO'
import FavoriteButton from '@/components/FavoriteButton.vue'

useSEO({
  title: 'Guides locaux — Djawal',
  description: "Tous nos guides locaux vérifiés à travers l'Algérie. Sahara, Casbah, Kabylie, Aurès, côte méditerranéenne — choisissez votre hôte."
})

const router = useRouter()

interface Guide {
  id: string
  display_name: string | null
  avatar_url: string | null
  role: 'guide_senior' | 'guide_junior'
  region: string | null
  bio: string | null
  specialties: string[] | null
  // Enrichi côté client
  rating?: number | null
  reviewCount?: number
}

const guides = ref<Guide[]>([])
const loading = ref(true)
const search = ref('')
const roleFilter = ref<'all' | 'guide_senior' | 'guide_junior'>('all')
const regionFilter = ref<string>('all')

async function load() {
  loading.value = true

  const { data: profilesData, error } = await supabase
    .from('profiles')
    .select('id, display_name, avatar_url, role, region, bio, specialties')
    .in('role', ['guide_senior', 'guide_junior'])
    .eq('kyc_status', 'approved')
    .eq('is_active', true)
    .order('role', { ascending: false }) // seniors d'abord
    .order('display_name', { ascending: true })

  if (error) {
    console.error('Erreur chargement guides:', error.message)
    guides.value = []
    loading.value = false
    return
  }

  const list = (profilesData as Guide[]) || []

  // Enrichir avec rating depuis review_aggregates (target_type='guide')
  if (list.length > 0) {
    const ids = list.map(g => g.id)
    const { data: aggData } = await supabase
      .from('review_aggregates')
      .select('target_id, average_rating, review_count')
      .eq('target_type', 'guide')
      .in('target_id', ids)
    const ratingMap = new Map(
      (aggData || []).map((a: any) => [a.target_id, { rating: Number(a.average_rating), count: a.review_count }])
    )
    for (const g of list) {
      const r = ratingMap.get(g.id)
      if (r) { g.rating = r.rating; g.reviewCount = r.count }
    }
  }

  guides.value = list
  loading.value = false
}

onMounted(load)

const allRegions = computed(() => {
  const set = new Set<string>()
  for (const g of guides.value) {
    if (g.region) set.add(g.region)
  }
  return Array.from(set).sort()
})

const filteredGuides = computed(() => {
  const q = search.value.trim().toLowerCase()
  return guides.value.filter(g => {
    if (roleFilter.value !== 'all' && g.role !== roleFilter.value) return false
    if (regionFilter.value !== 'all' && g.region !== regionFilter.value) return false
    if (q) {
      const name = (g.display_name || '').toLowerCase()
      const region = (g.region || '').toLowerCase()
      const specs = (g.specialties || []).join(' ').toLowerCase()
      if (!name.includes(q) && !region.includes(q) && !specs.includes(q)) return false
    }
    return true
  })
})

function initial(name?: string | null): string {
  return (name || '?')[0].toUpperCase()
}

function roleLabel(role: string): string {
  if (role === 'guide_senior') return 'Guide Senior'
  if (role === 'guide_junior') return 'Guide Junior'
  return 'Guide'
}

function fmtStars(rating?: number | null): string {
  if (!rating) return '—'
  return rating.toFixed(1)
}

function openGuide(id: string) {
  router.push(`/guide/${id}`)
}
</script>

<template>
  <div class="guides-page">
    <!-- HERO -->
    <section class="guides-hero">
      <div class="djawal-container">
        <div class="hero-eyebrow">
          <span class="arabic">المرشدون</span> · LES VOIX DU PAYS
        </div>
        <h1>Vos guides,<br/><em>vos hôtes.</em></h1>
        <p class="hero-sub">Tous rencontrés en visio avant d'apparaître ici. Tous évalués par les voyageurs qu'ils ont accompagnés.</p>
      </div>
    </section>

    <!-- FILTRES -->
    <section class="guides-filters">
      <div class="djawal-container">
        <div class="filters-row">
          <div class="search-wrap">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
              <circle cx="11" cy="11" r="7"/>
              <line x1="21" y1="21" x2="16.5" y2="16.5"/>
            </svg>
            <input
              v-model="search"
              type="text"
              placeholder="Rechercher un guide, une région, une spécialité…"
              aria-label="Rechercher un guide"
            />
            <button v-if="search" class="search-clear" @click="search = ''" aria-label="Effacer">✕</button>
          </div>

          <div class="filter-pills">
            <button
              class="filter-pill"
              :class="{ active: roleFilter === 'all' }"
              @click="roleFilter = 'all'"
            >Tous</button>
            <button
              class="filter-pill"
              :class="{ active: roleFilter === 'guide_senior' }"
              @click="roleFilter = 'guide_senior'"
            >⭐ Seniors</button>
            <button
              class="filter-pill"
              :class="{ active: roleFilter === 'guide_junior' }"
              @click="roleFilter = 'guide_junior'"
            >Juniors</button>
          </div>

          <select v-if="allRegions.length > 0" v-model="regionFilter" class="region-select" aria-label="Filtrer par région">
            <option value="all">Toutes les régions</option>
            <option v-for="r in allRegions" :key="r" :value="r">{{ r }}</option>
          </select>
        </div>

        <div class="results-count">
          {{ filteredGuides.length }} guide{{ filteredGuides.length > 1 ? 's' : '' }}
        </div>
      </div>
    </section>

    <!-- GRID -->
    <section class="guides-grid-wrap">
      <div class="djawal-container">
        <div v-if="loading" class="state-msg">Chargement des guides…</div>
        <div v-else-if="filteredGuides.length === 0" class="state-msg">
          Aucun guide ne correspond à votre recherche.
        </div>
        <div v-else class="guides-grid">
          <article
            v-for="g in filteredGuides"
            :key="g.id"
            class="guide-card"
            @click="openGuide(g.id)"
            tabindex="0"
            role="button"
            @keydown.enter="openGuide(g.id)"
          >
            <div class="guide-portrait">
              <img v-if="g.avatar_url" :src="g.avatar_url" :alt="g.display_name || 'Guide'" loading="lazy" />
              <div v-else class="portrait-fallback">
                <span>{{ initial(g.display_name) }}</span>
              </div>
              <span v-if="g.role === 'guide_senior'" class="guide-badge senior">⭐ Senior</span>
              <span v-else class="guide-badge junior">Junior</span>
              <span v-if="g.rating" class="guide-rating">
                <span class="star">★</span> {{ fmtStars(g.rating) }}<small v-if="g.reviewCount">·{{ g.reviewCount }}</small>
              </span>
              <FavoriteButton target-type="guide" :target-id="g.id" size="sm" floating />
            </div>
            <div class="guide-info">
              <div class="guide-meta" v-if="g.region">📍 {{ g.region }}</div>
              <h3 class="guide-name">{{ g.display_name || 'Guide Djawal' }}</h3>
              <p v-if="g.specialties && g.specialties.length > 0" class="guide-spec">
                {{ g.specialties.slice(0, 2).join(' · ') }}
              </p>
              <p v-else-if="g.bio" class="guide-spec">{{ g.bio.slice(0, 80) }}{{ g.bio.length > 80 ? '…' : '' }}</p>
              <p v-else class="guide-spec">{{ roleLabel(g.role) }}</p>
            </div>
          </article>
        </div>
      </div>
    </section>

    <!-- CTA INSCRIPTION GUIDE -->
    <section class="guides-cta">
      <div class="djawal-container">
        <div class="cta-card">
          <div>
            <h2>Vous connaissez votre coin d'Algérie ?</h2>
            <p>Rejoignez nos guides locaux — partagez votre passion, vivez de votre savoir.</p>
          </div>
          <router-link to="/auth/signup?role=guide_junior" class="cta-btn">
            Devenir guide →
          </router-link>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.guides-page {
  background: var(--c-fond, #1A3A2A);
  min-height: 100vh;
  color: #FAF7F2;
  font-family: 'Inter', sans-serif;
}
.djawal-container { max-width: 1200px; margin: 0 auto; padding: 0 32px; }
.arabic { font-family: 'Amiri', 'Reem Kufi', serif; }

/* ===== HERO ===== */
.guides-hero {
  padding: 140px 0 60px;
  background: linear-gradient(180deg, #0F2419 0%, #1A3A2A 100%);
  border-bottom: 1px solid rgba(212, 168, 68, 0.15);
  text-align: center;
}
.hero-eyebrow {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  padding: 6px 18px;
  background: rgba(212, 168, 68, 0.15);
  border: 1px solid rgba(212, 168, 68, 0.35);
  border-radius: 999px;
  color: #E8B96B;
  font-size: 11px;
  letter-spacing: 0.24em;
  text-transform: uppercase;
  font-weight: 500;
  margin-bottom: 24px;
}
.hero-eyebrow .arabic {
  font-size: 13px;
  letter-spacing: 0;
  text-transform: none;
  color: #FAF7F2;
}
.guides-hero h1 {
  font-family: 'Cormorant Garamond', Georgia, serif;
  font-weight: 400;
  font-size: clamp(40px, 5vw, 72px);
  line-height: 1.05;
  color: #FAF7F2;
  margin-bottom: 18px;
  letter-spacing: -0.01em;
}
.guides-hero h1 em {
  font-style: italic;
  color: #E8B96B;
}
.hero-sub {
  font-family: 'Cormorant Garamond', serif;
  font-style: italic;
  font-size: 18px;
  color: rgba(250, 247, 242, 0.78);
  max-width: 580px;
  margin: 0 auto;
  line-height: 1.55;
}

/* ===== FILTRES ===== */
.guides-filters {
  padding: 36px 0 24px;
  background: var(--c-fond, #1A3A2A);
  position: sticky;
  top: 70px;
  z-index: 10;
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  background: rgba(26, 58, 42, 0.92);
  border-bottom: 1px solid rgba(212, 168, 68, 0.12);
}
.filters-row {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
  align-items: center;
}
.search-wrap {
  flex: 1;
  min-width: 240px;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 14px;
  background: rgba(15, 36, 25, 0.6);
  border: 1px solid rgba(212, 168, 68, 0.25);
  border-radius: 999px;
  color: rgba(250, 247, 242, 0.65);
}
.search-wrap:focus-within { border-color: #D4A844; }
.search-wrap input {
  flex: 1;
  background: transparent;
  border: 0;
  outline: 0;
  font-family: inherit;
  font-size: 14px;
  color: #FAF7F2;
}
.search-wrap input::placeholder { color: rgba(250, 247, 242, 0.45); font-style: italic; }
.search-clear {
  background: rgba(255, 255, 255, 0.08);
  border: none;
  color: #FAF7F2;
  width: 22px; height: 22px;
  border-radius: 50%;
  cursor: pointer;
  font-size: 11px;
}
.search-clear:hover { background: rgba(255, 255, 255, 0.16); }

.filter-pills {
  display: flex;
  gap: 6px;
}
.filter-pill {
  background: transparent;
  border: 1px solid rgba(250, 247, 242, 0.2);
  color: rgba(250, 247, 242, 0.7);
  padding: 8px 14px;
  border-radius: 999px;
  font-size: 12.5px;
  cursor: pointer;
  font-family: inherit;
  transition: all 0.15s ease;
}
.filter-pill:hover { border-color: #D4A844; color: #E8B96B; }
.filter-pill.active {
  background: #D4A844;
  color: #0F2419;
  border-color: #D4A844;
  font-weight: 600;
}

.region-select {
  background: rgba(15, 36, 25, 0.6);
  border: 1px solid rgba(212, 168, 68, 0.25);
  color: #FAF7F2;
  padding: 10px 16px;
  border-radius: 999px;
  font-family: inherit;
  font-size: 13px;
  cursor: pointer;
  outline: none;
}
.region-select:focus { border-color: #D4A844; }
.region-select option { background: #1A3A2A; color: #FAF7F2; }

.results-count {
  margin-top: 14px;
  font-size: 12px;
  color: rgba(250, 247, 242, 0.55);
  letter-spacing: 0.05em;
}

/* ===== GRID ===== */
.guides-grid-wrap { padding: 40px 0 80px; }
.state-msg {
  text-align: center;
  padding: 80px 20px;
  color: rgba(250, 247, 242, 0.55);
  font-family: 'Cormorant Garamond', serif;
  font-style: italic;
  font-size: 18px;
}
.guides-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
  gap: 24px;
}
.guide-card {
  cursor: pointer;
  transition: transform 0.3s ease;
  background: transparent;
  border: none;
  padding: 0;
}
.guide-card:hover { transform: translateY(-4px); }
.guide-card:focus-visible { outline: 2px solid #E8B96B; outline-offset: 4px; border-radius: 4px; }

.guide-portrait {
  aspect-ratio: 4/5;
  position: relative;
  border-radius: 6px;
  overflow: hidden;
  background: linear-gradient(160deg, #2D5A3D 0%, #1A3A2A 100%);
  border: 1px solid rgba(212, 168, 68, 0.15);
  margin-bottom: 14px;
}
.guide-portrait img {
  width: 100%; height: 100%;
  object-fit: cover;
  display: block;
}
.portrait-fallback {
  position: absolute; inset: 0;
  display: flex; align-items: center; justify-content: center;
  font-family: 'Cormorant Garamond', serif;
  font-size: 60px;
  color: #E8B96B;
  font-weight: 500;
  background: linear-gradient(135deg, #2D5A3D 0%, #B8862E 100%);
}

.guide-badge {
  position: absolute;
  top: 10px;
  left: 10px;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 4px 11px;
  border-radius: 999px;
  font-size: 10px;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  font-weight: 700;
  z-index: 3;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
}
.guide-badge.senior {
  background: linear-gradient(135deg, #D4A844, #B8862E);
  color: #0F2419;
}
.guide-badge.junior {
  background: rgba(15, 36, 25, 0.78);
  color: #E8B96B;
  border: 1px solid rgba(212, 168, 68, 0.4);
}

.guide-rating {
  position: absolute;
  bottom: 10px;
  left: 10px;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 4px 10px;
  background: rgba(15, 36, 25, 0.85);
  backdrop-filter: blur(8px);
  border-radius: 999px;
  font-size: 11.5px;
  color: #FAF7F2;
  z-index: 3;
  border: 1px solid rgba(212, 168, 68, 0.3);
}
.guide-rating .star { color: #E8B96B; }
.guide-rating small { opacity: 0.7; margin-left: 2px; font-size: 10px; }

.guide-info { padding: 0 4px; }
.guide-meta {
  font-size: 11px;
  letter-spacing: 0.18em;
  text-transform: uppercase;
  color: #B8862E;
  font-weight: 500;
  margin-bottom: 6px;
}
.guide-name {
  font-family: 'Cormorant Garamond', serif;
  font-weight: 500;
  font-size: 22px;
  color: #FAF7F2;
  margin-bottom: 4px;
  letter-spacing: -0.01em;
}
.guide-spec {
  font-family: 'Cormorant Garamond', serif;
  font-style: italic;
  font-size: 14.5px;
  color: rgba(250, 247, 242, 0.7);
  line-height: 1.45;
}

/* ===== CTA INSCRIPTION ===== */
.guides-cta { padding: 40px 0 100px; }
.cta-card {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 24px;
  background: linear-gradient(135deg, rgba(212, 168, 68, 0.12) 0%, rgba(232, 185, 107, 0.08) 100%);
  border: 1px solid rgba(212, 168, 68, 0.35);
  border-radius: 16px;
  padding: 36px 40px;
  flex-wrap: wrap;
}
.cta-card h2 {
  font-family: 'Cormorant Garamond', serif;
  font-weight: 500;
  font-size: 28px;
  color: #FAF7F2;
  margin-bottom: 6px;
}
.cta-card p {
  color: rgba(250, 247, 242, 0.75);
  font-style: italic;
  font-family: 'Cormorant Garamond', serif;
  font-size: 16px;
}
.cta-btn {
  background: #D4A844;
  color: #0F2419;
  padding: 14px 28px;
  border-radius: 999px;
  font-weight: 600;
  font-size: 14px;
  text-decoration: none;
  white-space: nowrap;
  transition: all 0.2s ease;
  box-shadow: 0 4px 18px rgba(212, 168, 68, 0.3);
}
.cta-btn:hover {
  background: #E8B96B;
  transform: translateY(-1px);
  box-shadow: 0 8px 28px rgba(212, 168, 68, 0.45);
}

/* ===== Responsive ===== */
@media (max-width: 700px) {
  .djawal-container { padding: 0 18px; }
  .guides-hero { padding: 110px 0 40px; }
  .filters-row { gap: 8px; }
  .search-wrap { width: 100%; }
  .region-select { width: 100%; }
  .filter-pills { width: 100%; justify-content: space-between; }
  .filter-pill { flex: 1; text-align: center; }
  .guides-grid { grid-template-columns: repeat(auto-fill, minmax(160px, 1fr)); gap: 18px; }
  .guide-name { font-size: 19px; }
  .cta-card { padding: 24px; flex-direction: column; align-items: stretch; text-align: center; }
  .cta-btn { width: 100%; text-align: center; }
}
</style>
