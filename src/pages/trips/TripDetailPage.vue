<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'
import { useFavorites } from '@/composables/useFavorites'
import ReviewSection from '@/components/ReviewSection.vue'

const auth = useAuthStore()
const { loadFavorites, toggleFavorite, isFavorite, loaded: favLoaded } = useFavorites()

interface Trip {
  id: string
  title: string
  title_ar: string | null
  destination_id: string
  duration_days: number
  price_da: number
  description: string
  cover_image_url: string | null
  max_travelers: number
  difficulty: string | null
  tags: string[]
  status: string
  created_by: string
  destinations?: { name: string; wilaya: string; cultural_theme: string } | null
  profiles?: { display_name: string; avatar_url: string | null; role: string } | null
}

interface Step {
  id: string
  step_order: number
  resource_type: 'accommodation' | 'site' | 'restaurant'
  resource_id: string
  resource_name: string
  resource_description: string
  note: string | null
  duration_minutes: number | null
}

interface Day {
  id: string
  day_number: number
  theme: string | null
  description: string | null
  steps: Step[]
}

const route = useRoute()
const trip = ref<Trip | null>(null)
const days = ref<Day[]>([])
const loading = ref(true)
const error = ref('')

onMounted(async () => {
  const id = route.params.id as string
  if (!id) { error.value = 'Identifiant manquant.'; loading.value = false; return }

  const { data: tripData, error: tripErr } = await supabase
    .from('trips')
    .select(`
      id, title, title_ar, destination_id, duration_days, price_da, description,
      cover_image_url, max_travelers, difficulty, tags, status, created_by,
      destinations(name, wilaya, cultural_theme),
      profiles!trips_created_by_fkey(display_name, avatar_url, role)
    `)
    .eq('id', id)
    .single()

  if (tripErr || !tripData) {
    error.value = 'Voyage introuvable.'
    loading.value = false
    return
  }
  trip.value = tripData as any

  // Charger journées + étapes
  const { data: dayRows } = await supabase
    .from('trip_days')
    .select('*')
    .eq('trip_id', id)
    .order('day_number')

  const dayIds = (dayRows || []).map((d: any) => d.id)
  let stepRows: any[] = []
  if (dayIds.length > 0) {
    const { data } = await supabase
      .from('trip_steps')
      .select('*')
      .in('trip_day_id', dayIds)
      .order('step_order')
    stepRows = data || []
  }

  // Charger noms + descriptions des ressources
  const resourceIds = stepRows.map((s: any) => s.resource_id)
  const resInfo: Record<string, { name: string; description: string }> = {}
  if (resourceIds.length > 0) {
    const [h, s, r] = await Promise.all([
      supabase.from('accommodations').select('id, name, description, accommodation_type').in('id', resourceIds),
      supabase.from('sites').select('id, name, description').in('id', resourceIds),
      supabase.from('restaurants').select('id, name, description').in('id', resourceIds)
    ])
    for (const x of (h.data as any[] || [])) resInfo[x.id] = { name: x.name, description: x.description }
    for (const x of (s.data as any[] || [])) resInfo[x.id] = { name: x.name, description: x.description }
    for (const x of (r.data as any[] || [])) resInfo[x.id] = { name: x.name, description: x.description }
  }

  days.value = (dayRows || []).map((d: any) => ({
    id: d.id,
    day_number: d.day_number,
    theme: d.theme,
    description: d.description,
    steps: stepRows
      .filter((s: any) => s.trip_day_id === d.id)
      .map((s: any) => ({
        id: s.id,
        step_order: s.step_order,
        resource_type: s.resource_type,
        resource_id: s.resource_id,
        resource_name: resInfo[s.resource_id]?.name || '—',
        resource_description: resInfo[s.resource_id]?.description || '',
        note: s.note,
        duration_minutes: s.duration_minutes
      }))
  }))

  loading.value = false

  // Appliquer le thème culturel de la destination
  if (trip.value?.destinations?.cultural_theme) {
    document.documentElement.className = `theme-${trip.value.destinations.cultural_theme}`
  }

  // Charger les favoris si user connecté
  if (auth.user && !favLoaded.value) {
    await loadFavorites()
  }
})

const isFav = computed(() => trip.value ? isFavorite(trip.value.id) : false)
async function handleToggleFav() {
  if (!trip.value) return
  if (!auth.user) {
    window.location.href = '/auth/login?redirect=' + encodeURIComponent(route.fullPath)
    return
  }
  await toggleFavorite(trip.value.id)
}

const totalSteps = computed(() => days.value.reduce((s, d) => s + d.steps.length, 0))

function typeIcon(t: string) {
  return t === 'accommodation' ? '🏨' : t === 'restaurant' ? '🍴' : '📍'
}
function typeLabel(t: string) {
  return t === 'accommodation' ? 'Hébergement' : t === 'restaurant' ? 'Restaurant' : 'Site'
}
function fmtPrice(p: number) {
  return new Intl.NumberFormat('fr-DZ').format(p) + ' DA'
}
function difficultyLabel(d: string | null) {
  if (!d) return '—'
  return { facile: '🟢 Facile', modere: '🟡 Modéré', difficile: '🔴 Difficile' }[d] || d
}
</script>

<template>
  <div class="trip-detail">
    <div v-if="loading" class="loading djawal-container">Chargement du voyage…</div>
    <div v-else-if="error" class="error-state djawal-container">
      <h2>{{ error }}</h2>
      <router-link to="/voyages">
        <v-btn color="primary" variant="flat">Retour aux voyages</v-btn>
      </router-link>
    </div>

    <template v-else-if="trip">
      <!-- HERO -->
      <section
        class="trip-hero"
        :style="trip.cover_image_url ? `background-image: linear-gradient(rgba(10,31,46,0.4), rgba(10,31,46,0.7)), url(${trip.cover_image_url})` : ''"
      >
        <div class="djawal-container hero-inner">
          <div class="hero-tag">{{ trip.destinations?.name }} · {{ trip.destinations?.wilaya }}</div>
          <h1>{{ trip.title }}</h1>
          <div v-if="trip.title_ar" class="arabic title-ar">{{ trip.title_ar }}</div>

          <div class="hero-stats">
            <div class="stat">
              <div class="stat-value">{{ trip.duration_days }}</div>
              <div class="stat-label">jour{{ trip.duration_days > 1 ? 's' : '' }}</div>
            </div>
            <div class="stat">
              <div class="stat-value">{{ fmtPrice(trip.price_da) }}</div>
              <div class="stat-label">par personne</div>
            </div>
            <div class="stat">
              <div class="stat-value">{{ trip.max_travelers }}</div>
              <div class="stat-label">voyageurs max</div>
            </div>
            <div class="stat">
              <div class="stat-value">{{ difficultyLabel(trip.difficulty) }}</div>
              <div class="stat-label">difficulté</div>
            </div>
          </div>

          <div v-if="trip.tags && trip.tags.length > 0" class="tags">
            <span v-for="t in trip.tags" :key="t" class="tag">#{{ t }}</span>
          </div>

          <button class="fav-btn" :class="{ active: isFav }" @click="handleToggleFav">
            <span class="fav-icon">{{ isFav ? '❤️' : '🤍' }}</span>
            <span>{{ isFav ? 'Dans vos favoris' : 'Ajouter aux favoris' }}</span>
          </button>
        </div>
      </section>

      <!-- CORPS -->
      <div class="djawal-container djawal-section detail-grid">
        <main class="detail-main">
          <section class="block">
            <h2>L'esprit du voyage</h2>
            <p class="desc">{{ trip.description }}</p>
          </section>

          <section class="block">
            <h2>Programme détaillé</h2>
            <p class="hint">{{ days.length }} journée{{ days.length > 1 ? 's' : '' }} · {{ totalSteps }} étapes</p>

            <div class="timeline">
              <article v-for="(day, dIdx) in days" :key="day.id" class="day-block">
                <div class="day-marker">
                  <div class="day-num">{{ day.day_number }}</div>
                  <div class="day-vline" v-if="dIdx < days.length - 1"></div>
                </div>
                <div class="day-content">
                  <h3>Jour {{ day.day_number }}<span v-if="day.theme"> — {{ day.theme }}</span></h3>
                  <p v-if="day.description" class="day-intro">{{ day.description }}</p>

                  <div v-if="day.steps.length === 0" class="empty-day">
                    Journée libre / à la découverte.
                  </div>

                  <ol v-else class="step-timeline">
                    <li v-for="step in day.steps" :key="step.id" class="step-item" :data-type="step.resource_type">
                      <div class="step-bullet">{{ typeIcon(step.resource_type) }}</div>
                      <div class="step-info">
                        <div class="step-name">
                          {{ step.resource_name }}
                          <span class="step-type">· {{ typeLabel(step.resource_type) }}</span>
                          <span v-if="step.duration_minutes" class="step-duration">· {{ step.duration_minutes }} min</span>
                        </div>
                        <p v-if="step.resource_description" class="step-desc">{{ step.resource_description }}</p>
                        <div v-if="step.note" class="step-note">💬 {{ step.note }}</div>
                      </div>
                    </li>
                  </ol>
                </div>
              </article>
            </div>
          </section>

          <!-- AVIS -->
          <ReviewSection :trip-id="trip.id" />
        </main>

        <aside class="detail-side">
          <router-link :to="`/guide/${trip.created_by}`" class="card guide-card guide-link">
            <h3>Votre guide</h3>
            <div class="guide-info">
              <div class="guide-avatar">
                <img
                  v-if="trip.profiles?.avatar_url"
                  :src="trip.profiles.avatar_url"
                  :alt="trip.profiles.display_name"
                />
                <div v-else class="avatar-placeholder">
                  {{ (trip.profiles?.display_name || '?')[0].toUpperCase() }}
                </div>
              </div>
              <div>
                <div class="guide-name">{{ trip.profiles?.display_name }}</div>
                <div class="guide-role">
                  {{ trip.profiles?.role === 'guide_senior' ? '⭐ Guide Senior' : 'Guide' }}
                </div>
                <div class="guide-cta">Voir le profil →</div>
              </div>
            </div>
          </router-link>

          <div class="card cta-card">
            <div class="cta-price">{{ fmtPrice(trip.price_da) }}</div>
            <div class="cta-sub">par personne · {{ trip.duration_days }} jour{{ trip.duration_days > 1 ? 's' : '' }}</div>
            <v-btn color="primary" variant="flat" size="large" block class="mt-3" :href="`mailto:hello@djawal.app?subject=Voyage%20%C2%AB%20${encodeURIComponent(trip.title)}%20%C2%BB&body=Bonjour%2C%0A%0AJe%20suis%20int%C3%A9ress%C3%A9%28e%29%20par%20le%20voyage%20%C2%AB%20${encodeURIComponent(trip.title)}%20%C2%BB%20%E2%80%94%20${trip.duration_days}%20jours%2C%20${fmtPrice(trip.price_da)}.%0A%0AMerci%20de%20me%20recontacter.%0A`">
              ✉️ Contacter pour réserver
            </v-btn>
            <p class="cta-hint">La réservation en ligne sera bientôt disponible. En attendant, écrivez-nous — nous vous mettons en contact avec le guide sous 48h.</p>
          </div>

          <div class="card info-card">
            <h4>📍 Destination</h4>
            <p>{{ trip.destinations?.name }} — {{ trip.destinations?.wilaya }}</p>
            <router-link
              v-if="trip.destinations"
              :to="`/destination/${trip.destination_id}`"
              class="link"
            >
              Voir la destination →
            </router-link>
          </div>
        </aside>
      </div>
    </template>
  </div>
</template>

<style scoped>
.trip-detail { background: var(--c-fond); min-height: 100vh; }
.loading, .error-state { padding: var(--space-8); text-align: center; }
.error-state h2 { margin-bottom: var(--space-4); color: var(--c-texte-doux); }

/* === HERO === */
.trip-hero {
  background: linear-gradient(135deg, var(--c-primaire), var(--c-primaire-profond));
  background-size: cover;
  background-position: center;
  color: var(--c-fond);
  padding: var(--space-8) 0;
  position: relative;
}
.hero-inner { position: relative; z-index: 1; }
.hero-tag {
  font-size: 13px;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  opacity: 0.85;
  margin-bottom: var(--space-2);
}
.trip-hero h1 {
  font-size: clamp(36px, 5vw, 56px);
  font-family: var(--font-display);
  margin-bottom: var(--space-2);
  color: var(--c-fond);
  line-height: 1.1;
}
.title-ar { font-size: 24px; opacity: 0.9; margin-bottom: var(--space-4); }

.hero-stats {
  display: flex; gap: var(--space-5);
  margin: var(--space-4) 0 var(--space-3);
  flex-wrap: wrap;
}
.stat {
  background: rgba(255,255,255,0.1);
  backdrop-filter: blur(8px);
  border-radius: var(--r-md);
  padding: 12px 20px;
  border: 1px solid rgba(255,255,255,0.15);
}
.stat-value { font-family: var(--font-display); font-size: 24px; font-weight: 700; }
.stat-label { font-size: 12px; opacity: 0.85; text-transform: uppercase; letter-spacing: 0.05em; }

.tags { display: flex; flex-wrap: wrap; gap: 8px; }
.tag {
  background: rgba(255,255,255,0.15);
  padding: 4px 12px;
  border-radius: var(--r-pill);
  font-size: 12px;
  font-weight: 600;
}

.fav-btn {
  margin-top: var(--space-4);
  background: rgba(255,255,255,0.15);
  backdrop-filter: blur(8px);
  border: 1px solid rgba(255,255,255,0.25);
  color: var(--c-fond);
  padding: 10px 20px;
  border-radius: var(--r-pill);
  font-family: inherit;
  font-size: 14px;
  font-weight: 700;
  cursor: pointer;
  display: inline-flex; align-items: center; gap: 8px;
  transition: var(--t-base);
}
.fav-btn:hover {
  background: rgba(255,255,255,0.25);
  transform: translateY(-1px);
}
.fav-btn.active {
  background: rgba(192, 74, 58, 0.9);
  border-color: rgba(192, 74, 58, 0.9);
}
.fav-icon { font-size: 18px; }

/* === GRID === */
.detail-grid {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 320px;
  gap: var(--space-5);
}
.detail-main { min-width: 0; }

.block { margin-bottom: var(--space-6); }
.block h2 {
  font-family: var(--font-display);
  font-size: 28px;
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-3);
}
.desc { font-size: 16px; line-height: 1.7; color: var(--c-texte); white-space: pre-line; }
.hint { color: var(--c-texte-doux); font-size: 14px; margin-bottom: var(--space-4); }

/* === TIMELINE === */
.timeline { display: flex; flex-direction: column; gap: var(--space-5); }
.day-block { display: grid; grid-template-columns: 60px 1fr; gap: var(--space-3); }
.day-marker {
  display: flex; flex-direction: column; align-items: center;
}
.day-num {
  width: 48px; height: 48px;
  border-radius: 50%;
  background: var(--c-primaire);
  color: var(--c-fond);
  display: flex; align-items: center; justify-content: center;
  font-family: var(--font-display);
  font-size: 22px;
  font-weight: 700;
  flex-shrink: 0;
  box-shadow: var(--ombre-douce);
}
.day-vline {
  width: 2px;
  flex: 1;
  background: var(--c-fond-chaud);
  margin-top: 8px;
}

.day-content {
  background: var(--c-surface);
  border-radius: var(--r-lg);
  padding: var(--space-4);
  box-shadow: var(--ombre-douce);
}
.day-content h3 {
  font-family: var(--font-display);
  font-size: 22px;
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-2);
}
.day-intro { color: var(--c-texte); line-height: 1.5; margin-bottom: var(--space-3); }
.empty-day { color: var(--c-texte-doux); font-style: italic; }

.step-timeline { list-style: none; padding: 0; margin: 0; }
.step-item {
  display: grid;
  grid-template-columns: 40px 1fr;
  gap: var(--space-3);
  padding: var(--space-3) 0;
  border-top: 1px solid var(--c-fond-chaud);
}
.step-item:first-child { border-top: none; padding-top: 0; }
.step-bullet {
  font-size: 22px;
  text-align: center;
  background: var(--c-fond-chaud);
  border-radius: 50%;
  width: 40px; height: 40px;
  display: flex; align-items: center; justify-content: center;
  flex-shrink: 0;
}
.step-item[data-type="accommodation"] .step-bullet { background: rgba(212, 160, 79, 0.15); }
.step-item[data-type="site"] .step-bullet { background: rgba(27, 73, 101, 0.12); }
.step-item[data-type="restaurant"] .step-bullet { background: rgba(201, 112, 80, 0.15); }

.step-name {
  font-weight: 700;
  color: var(--c-primaire-profond);
  font-size: 16px;
  margin-bottom: 4px;
}
.step-type, .step-duration { color: var(--c-texte-doux); font-weight: 400; font-size: 13px; }
.step-desc { color: var(--c-texte); font-size: 14px; line-height: 1.5; }
.step-note {
  background: var(--c-fond-chaud);
  padding: 8px 12px;
  border-radius: var(--r-sm);
  font-size: 13px;
  margin-top: 8px;
  font-style: italic;
}

/* === SIDEBAR === */
.detail-side { display: flex; flex-direction: column; gap: var(--space-3); }
.card {
  background: var(--c-surface);
  border-radius: var(--r-lg);
  padding: var(--space-4);
  box-shadow: var(--ombre-douce);
}
.card h3, .card h4 {
  font-family: var(--font-display);
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-2);
}
.card h3 { font-size: 18px; }
.card h4 { font-size: 16px; }

.guide-info { display: flex; align-items: center; gap: var(--space-2); }
.guide-avatar {
  width: 56px; height: 56px;
  border-radius: 50%;
  overflow: hidden;
  background: var(--c-fond-chaud);
  flex-shrink: 0;
}
.guide-avatar img { width: 100%; height: 100%; object-fit: cover; }
.avatar-placeholder {
  width: 100%; height: 100%;
  display: flex; align-items: center; justify-content: center;
  font-family: var(--font-display);
  font-size: 24px;
  font-weight: 700;
  color: var(--c-primaire);
}
.guide-link { text-decoration: none; color: inherit; transition: var(--t-base); display: block; }
.guide-link:hover { transform: translateY(-2px); box-shadow: var(--ombre-elevee); }
.guide-name { font-weight: 700; color: var(--c-primaire-profond); }
.guide-role { font-size: 13px; color: var(--c-accent-fort); }
.guide-cta { font-size: 12px; color: var(--c-primaire); font-weight: 600; margin-top: 4px; }

.cta-card { text-align: center; background: var(--c-fond-chaud); }
.cta-price {
  font-family: var(--font-display);
  font-size: 32px;
  font-weight: 700;
  color: var(--c-primaire-profond);
}
.cta-sub { color: var(--c-texte-doux); font-size: 13px; }
.cta-hint {
  margin-top: var(--space-2);
  font-size: 12px;
  color: var(--c-texte-doux);
  font-style: italic;
}

.info-card .link {
  color: var(--c-accent-fort);
  font-weight: 600;
  text-decoration: none;
  font-size: 14px;
}
.info-card .link:hover { text-decoration: underline; }

@media (max-width: 900px) {
  .detail-grid { grid-template-columns: 1fr; }
  .hero-stats { gap: var(--space-3); }
  .stat { padding: 10px 14px; }
  .day-block { grid-template-columns: 48px 1fr; }
  .day-num { width: 40px; height: 40px; font-size: 18px; }
}
</style>
