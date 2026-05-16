<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useSEO } from '@/composables/useSEO'

interface Guide {
  id: string
  display_name: string
  bio: string | null
  region: string | null
  avatar_url: string | null
  role: 'guide_senior' | 'guide_junior' | string
  created_at: string
}

interface Trip {
  id: string
  title: string
  duration_days: number
  price_da: number
  cover_image_url: string | null
  destinations?: { name: string } | null
}

interface Review {
  id: string
  rating: number
  comment: string | null
  created_at: string
  trip_id: string
  profiles?: { display_name: string } | null
  trips?: { title: string } | null
}

const route = useRoute()
const guide = ref<Guide | null>(null)
const trips = ref<Trip[]>([])
const reviews = ref<Review[]>([])
const loading = ref(true)
const notFound = ref(false)

const avgRating = computed(() => {
  if (reviews.value.length === 0) return null
  const sum = reviews.value.reduce((s, r) => s + r.rating, 0)
  return (sum / reviews.value.length).toFixed(1)
})

const memberSince = computed(() => {
  if (!guide.value) return ''
  const d = new Date(guide.value.created_at)
  return d.toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' })
})

onMounted(async () => {
  const id = route.params.id as string
  loading.value = true

  const { data: profileData, error } = await supabase
    .from('profiles')
    .select('id, display_name, bio, region, avatar_url, role, created_at')
    .eq('id', id)
    .in('role', ['guide_senior', 'guide_junior'])
    .eq('is_active', true)
    .single()

  if (error || !profileData) {
    notFound.value = true
    loading.value = false
    return
  }

  guide.value = profileData as Guide

  // Voyages publiés
  const { data: tripsData } = await supabase
    .from('trips')
    .select('id, title, duration_days, price_da, cover_image_url, destinations(name)')
    .eq('created_by', id)
    .eq('status', 'published')
    .order('published_at', { ascending: false })
  trips.value = (tripsData as any) || []

  // Avis sur ses voyages (utilise user_reviews polymorphique)
  if (trips.value.length > 0) {
    const tripIds = trips.value.map(t => t.id)
    const { data: revData } = await supabase
      .from('user_reviews')
      .select('id, rating, comment, created_at, target_id, profiles!user_reviews_user_id_fkey(display_name)')
      .eq('target_type', 'trip')
      .eq('status', 'approved')
      .in('target_id', tripIds)
      .order('created_at', { ascending: false })
      .limit(8)
    // Joindre les trips manuellement
    const tripsById: Record<string, any> = {}
    for (const t of trips.value) tripsById[t.id] = t
    reviews.value = ((revData as any[]) || []).map(r => ({
      ...r,
      trip_id: r.target_id,
      trips: tripsById[r.target_id] ? { title: tripsById[r.target_id].title } : null
    }))
  }

  loading.value = false

  // SEO
  useSEO({
    title: guide.value.display_name,
    description: guide.value.bio || `Découvrez les parcours du guide ${guide.value.display_name} sur Djawal.`,
    image: guide.value.avatar_url || undefined,
    type: 'website'
  })
})

function fmtPrice(p: number) {
  return new Intl.NumberFormat('fr-DZ').format(p) + ' DA'
}
function initial(name?: string | null) {
  return (name || '?')[0].toUpperCase()
}
function fmtDate(iso: string) {
  return new Date(iso).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric' })
}
</script>

<template>
  <div class="guide-profile">
    <div v-if="loading" class="loading">Chargement du profil…</div>

    <div v-else-if="notFound" class="not-found">
      <h1>Guide introuvable</h1>
      <p>Ce profil n'existe pas ou a été désactivé.</p>
      <router-link to="/voyages">
        <v-btn color="primary" variant="flat">Explorer les voyages</v-btn>
      </router-link>
    </div>

    <template v-else-if="guide">
      <!-- HERO -->
      <section class="profile-hero">
        <div class="djawal-container hero-inner">
          <div class="hero-avatar">
            <img v-if="guide.avatar_url" :src="guide.avatar_url" :alt="guide.display_name" />
            <span v-else>{{ initial(guide.display_name) }}</span>
          </div>
          <div class="hero-info">
            <div class="role-badge" :data-senior="guide.role === 'guide_senior'">
              {{ guide.role === 'guide_senior' ? '⭐ Guide Senior' : 'Guide' }}
            </div>
            <h1>{{ guide.display_name }}</h1>
            <p v-if="guide.region" class="region">📍 {{ guide.region }}</p>
            <p class="member-since">Membre depuis {{ memberSince }}</p>

            <div class="hero-stats">
              <div class="stat">
                <strong>{{ trips.length }}</strong>
                <span>parcours publié{{ trips.length > 1 ? 's' : '' }}</span>
              </div>
              <div class="stat">
                <strong>{{ reviews.length }}</strong>
                <span>avis reçu{{ reviews.length > 1 ? 's' : '' }}</span>
              </div>
              <div v-if="avgRating" class="stat highlight">
                <strong>{{ avgRating }} <span class="star">★</span></strong>
                <span>note moyenne</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      <!-- BIO -->
      <section v-if="guide.bio" class="djawal-container djawal-section">
        <div class="bio-card">
          <h2>À propos</h2>
          <p>{{ guide.bio }}</p>
        </div>
      </section>

      <!-- VOYAGES -->
      <section class="djawal-container djawal-section">
        <h2>Parcours signés {{ guide.display_name }}</h2>

        <div v-if="trips.length === 0" class="empty">
          Ce guide n'a pas encore publié de parcours.
        </div>

        <div v-else class="trips-grid">
          <router-link
            v-for="t in trips"
            :key="t.id"
            :to="`/voyages/${t.id}`"
            class="trip-card"
          >
            <div
              class="trip-cover"
              :style="t.cover_image_url ? `background-image: url(${t.cover_image_url})` : ''"
            ></div>
            <div class="trip-body">
              <div class="trip-dest" v-if="t.destinations">📍 {{ t.destinations.name }}</div>
              <h3>{{ t.title }}</h3>
              <div class="trip-meta">
                {{ t.duration_days }}j · {{ fmtPrice(t.price_da) }}
              </div>
            </div>
          </router-link>
        </div>
      </section>

      <!-- AVIS -->
      <section v-if="reviews.length > 0" class="djawal-container djawal-section">
        <h2>Ce qu'en disent les voyageurs</h2>
        <div class="reviews-grid">
          <article v-for="r in reviews" :key="r.id" class="review-card">
            <div class="review-head">
              <span class="stars">
                <span v-for="n in 5" :key="n" :class="['star', { filled: n <= r.rating }]">★</span>
              </span>
              <span class="review-date">{{ fmtDate(r.created_at) }}</span>
            </div>
            <p v-if="r.comment" class="review-text">« {{ r.comment }} »</p>
            <p v-else class="review-no-text">Sans commentaire</p>
            <div class="review-meta">
              <strong>{{ r.profiles?.display_name }}</strong> sur
              <router-link :to="`/voyages/${r.trip_id}`" class="review-trip">{{ r.trips?.title }}</router-link>
            </div>
          </article>
        </div>
      </section>
    </template>
  </div>
</template>

<style scoped>
.guide-profile { background: var(--c-fond); min-height: 100vh; }
.loading, .not-found { padding: var(--space-8); text-align: center; }
.not-found h1 { margin-bottom: var(--space-3); color: var(--c-primaire-profond); }
.not-found p { color: var(--c-texte-doux); margin-bottom: var(--space-4); }

/* === HERO === */
.profile-hero {
  background: linear-gradient(135deg, var(--c-primaire), var(--c-primaire-profond));
  color: var(--c-fond);
  padding: var(--space-7) 0 var(--space-6);
}
.hero-inner {
  display: flex; align-items: center; gap: var(--space-5);
  flex-wrap: wrap;
}
.hero-avatar {
  width: 140px; height: 140px;
  border-radius: 50%;
  overflow: hidden;
  background: rgba(255,255,255,0.15);
  border: 4px solid rgba(255,255,255,0.3);
  display: flex; align-items: center; justify-content: center;
  font-family: var(--font-display);
  font-size: 56px;
  font-weight: 700;
  flex-shrink: 0;
}
.hero-avatar img { width: 100%; height: 100%; object-fit: cover; }
.hero-info { flex: 1; min-width: 280px; }
.role-badge {
  display: inline-block;
  background: rgba(255,255,255,0.18);
  padding: 4px 12px;
  border-radius: var(--r-pill);
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  margin-bottom: var(--space-2);
}
.role-badge[data-senior="true"] {
  background: rgba(212, 160, 79, 0.95);
  color: var(--c-primaire-profond);
}
.hero-info h1 {
  font-family: var(--font-display);
  font-size: clamp(32px, 4.5vw, 52px);
  margin-bottom: 6px;
  color: var(--c-fond);
}
.region { font-size: 15px; opacity: 0.9; margin-bottom: 4px; }
.member-since { font-size: 13px; opacity: 0.7; }

.hero-stats {
  display: flex; gap: var(--space-5);
  margin-top: var(--space-4);
  flex-wrap: wrap;
}
.stat {
  background: rgba(255,255,255,0.1);
  backdrop-filter: blur(8px);
  border-radius: var(--r-md);
  padding: 10px 18px;
  border: 1px solid rgba(255,255,255,0.15);
}
.stat strong {
  display: block;
  font-family: var(--font-display);
  font-size: 22px;
}
.stat.highlight strong { color: #FFD479; }
.stat span:not(.star) {
  font-size: 11px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  opacity: 0.85;
}

/* === BIO === */
.bio-card {
  background: var(--c-surface);
  border-radius: var(--r-lg);
  padding: var(--space-5);
  box-shadow: var(--ombre-douce);
  border-left: 4px solid var(--c-accent);
}
.bio-card h2 {
  font-family: var(--font-display);
  font-size: 24px;
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-3);
}
.bio-card p {
  font-size: 16px;
  line-height: 1.7;
  color: var(--c-texte);
  white-space: pre-line;
}

h2 {
  font-family: var(--font-display);
  font-size: 28px;
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-4);
}

/* === TRIPS === */
.empty { color: var(--c-texte-doux); font-style: italic; text-align: center; padding: var(--space-5); }

.trips-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
  gap: var(--space-4);
}
.trip-card {
  background: var(--c-surface);
  border-radius: var(--r-lg);
  overflow: hidden;
  box-shadow: var(--ombre-douce);
  text-decoration: none;
  color: inherit;
  transition: var(--t-base);
}
.trip-card:hover {
  transform: translateY(-3px);
  box-shadow: var(--ombre-elevee);
}
.trip-cover {
  height: 160px;
  background: linear-gradient(135deg, #D4A04F, #C97050);
  background-size: cover;
  background-position: center;
}
.trip-body { padding: var(--space-3); }
.trip-dest {
  font-size: 11px;
  color: var(--c-texte-doux);
  text-transform: uppercase;
  letter-spacing: 0.1em;
  margin-bottom: 4px;
}
.trip-body h3 {
  font-family: var(--font-display);
  font-size: 18px;
  color: var(--c-primaire-profond);
  margin-bottom: 6px;
}
.trip-meta {
  font-size: 13px;
  font-weight: 600;
  color: var(--c-texte);
}

/* === REVIEWS === */
.reviews-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: var(--space-3);
}
.review-card {
  background: var(--c-surface);
  border-radius: var(--r-md);
  padding: var(--space-3);
  box-shadow: var(--ombre-douce);
  border-left: 3px solid var(--c-accent);
}
.review-head {
  display: flex; justify-content: space-between; align-items: center;
  margin-bottom: var(--space-2);
}
.stars { letter-spacing: 2px; }
.star { color: var(--c-gris-clair); font-size: 14px; }
.star.filled { color: #D4A04F; }
.review-date { font-size: 11px; color: var(--c-texte-doux); }
.review-text {
  font-style: italic;
  font-size: 14px;
  color: var(--c-texte);
  line-height: 1.5;
  margin-bottom: var(--space-2);
}
.review-no-text { font-style: italic; color: var(--c-texte-doux); font-size: 13px; margin-bottom: var(--space-2); }
.review-meta {
  font-size: 12px;
  color: var(--c-texte-doux);
  border-top: 1px solid var(--c-fond-chaud);
  padding-top: var(--space-2);
}
.review-meta strong { color: var(--c-accent-fort); }
.review-trip { color: var(--c-primaire); font-weight: 600; text-decoration: none; }
.review-trip:hover { text-decoration: underline; }

@media (max-width: 700px) {
  .hero-inner { text-align: center; }
  .hero-stats { justify-content: center; }
}
</style>
