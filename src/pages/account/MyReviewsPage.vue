<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

interface Review {
  id: string
  trip_id: string
  rating: number
  comment: string | null
  created_at: string
  trips?: {
    title: string
    cover_image_url: string | null
    destinations?: { name: string } | null
  } | null
}

const auth = useAuthStore()
const reviews = ref<Review[]>([])
const loading = ref(true)

async function load() {
  loading.value = true
  const { data } = await supabase
    .from('reviews')
    .select('id, trip_id, rating, comment, created_at, trips(title, cover_image_url, destinations(name))')
    .eq('created_by', auth.user!.id)
    .order('created_at', { ascending: false })
  reviews.value = (data as any) || []
  loading.value = false
}

onMounted(load)

async function remove(r: Review) {
  if (!confirm('Supprimer cet avis ?')) return
  const { error } = await supabase.from('reviews').delete().eq('id', r.id)
  if (error) { alert('Erreur : ' + error.message); return }
  reviews.value = reviews.value.filter(x => x.id !== r.id)
}

function fmtDate(iso: string) {
  return new Date(iso).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric' })
}
</script>

<template>
  <div class="djawal-container djawal-section">
    <div class="back-link">
      <router-link to="/mon-espace">← Mon espace</router-link>
    </div>

    <header class="page-header">
      <div>
        <div class="section-eyebrow">Mon espace</div>
        <h1>⭐ Mes avis</h1>
        <p class="lead">{{ reviews.length }} avis publié{{ reviews.length > 1 ? 's' : '' }}</p>
      </div>
    </header>

    <div v-if="loading" class="loading">Chargement…</div>

    <div v-else-if="reviews.length === 0" class="empty">
      <p>Vous n'avez pas encore laissé d'avis sur un voyage.</p>
      <router-link to="/voyages">
        <v-btn color="primary" variant="flat">Explorer les voyages</v-btn>
      </router-link>
    </div>

    <div v-else class="reviews-list">
      <article v-for="r in reviews" :key="r.id" class="review-card">
        <router-link :to="`/voyages/${r.trip_id}`" class="review-link">
          <div
            class="review-cover"
            :style="r.trips?.cover_image_url ? `background-image: url(${r.trips.cover_image_url})` : ''"
          ></div>
          <div class="review-body">
            <div class="review-dest" v-if="r.trips?.destinations">📍 {{ r.trips.destinations.name }}</div>
            <h3>{{ r.trips?.title }}</h3>
            <div class="review-rating">
              <span v-for="n in 5" :key="n" :class="['star', { filled: n <= r.rating }]">★</span>
              <span class="review-date">· {{ fmtDate(r.created_at) }}</span>
            </div>
            <p v-if="r.comment" class="review-comment">« {{ r.comment }} »</p>
          </div>
        </router-link>
        <button class="remove-btn" @click="remove(r)">🗑️ Supprimer</button>
      </article>
    </div>
  </div>
</template>

<style scoped>
.back-link { margin-bottom: var(--space-3); }
.back-link a {
  color: var(--c-primaire); text-decoration: none;
  font-weight: 600; font-size: 14px;
}
.back-link a:hover { text-decoration: underline; }

.section-eyebrow {
  color: var(--c-accent-fort);
  font-size: 13px; font-weight: 700;
  letter-spacing: 0.2em; text-transform: uppercase;
  margin-bottom: var(--space-2);
}
.page-header { margin-bottom: var(--space-5); }
.page-header h1 { font-size: clamp(28px, 3.5vw, 40px); margin-bottom: 4px; }
.lead { color: var(--c-texte-doux); }

.loading, .empty { text-align: center; padding: var(--space-8); color: var(--c-texte-doux); }
.empty p { margin-bottom: var(--space-3); }

.reviews-list { display: flex; flex-direction: column; gap: var(--space-3); }
.review-card {
  background: var(--c-surface);
  border-radius: var(--r-lg);
  overflow: hidden;
  box-shadow: var(--ombre-douce);
}
.review-link {
  display: grid;
  grid-template-columns: 200px 1fr;
  text-decoration: none;
  color: inherit;
}
.review-cover {
  background: linear-gradient(135deg, #D4A04F, #C97050);
  background-size: cover;
  background-position: center;
  min-height: 140px;
}
.review-body { padding: var(--space-4); }
.review-dest {
  font-size: 11px;
  color: var(--c-texte-doux);
  text-transform: uppercase;
  letter-spacing: 0.1em;
  margin-bottom: 4px;
}
.review-body h3 {
  font-family: var(--font-display);
  font-size: 20px;
  color: var(--c-primaire-profond);
  margin-bottom: 6px;
}
.review-rating {
  display: flex; gap: 2px; align-items: center;
  margin-bottom: var(--space-2);
}
.star { color: var(--c-gris-clair); font-size: 16px; }
.star.filled { color: #D4A04F; }
.review-date {
  margin-left: 8px;
  color: var(--c-texte-doux);
  font-size: 12px;
}
.review-comment {
  font-style: italic;
  font-size: 14px;
  color: var(--c-texte);
  line-height: 1.5;
}

.remove-btn {
  background: var(--c-fond-chaud);
  border: none;
  border-top: 1px solid var(--c-gris-clair);
  padding: 10px;
  width: 100%;
  font-family: inherit;
  font-size: 13px;
  font-weight: 600;
  color: var(--c-texte-doux);
  cursor: pointer;
  transition: var(--t-base);
}
.remove-btn:hover {
  background: rgba(192, 74, 58, 0.08);
  color: #C04A3A;
}

@media (max-width: 700px) {
  .review-link { grid-template-columns: 1fr; }
  .review-cover { min-height: 120px; }
}
</style>
