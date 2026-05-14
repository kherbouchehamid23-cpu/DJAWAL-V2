<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()
const route = useRoute()

interface Destination { id: string; name: string; cultural_theme: string }

const destinations = ref<Destination[]>([])

// Préférences
const interests = ref<string[]>([])
const duration = ref(5)
const budget = ref<'eco' | 'medium' | 'premium'>('medium')
const season = ref('printemps')
const mobility = ref<'easy' | 'normal' | 'sport'>('normal')
const destinationId = ref<string | null>(null)
const note = ref('')

const generating = ref(false)
const response = ref<{ answer: string; resources: any[]; destinations: any[]; trips: any[] } | null>(null)
const error = ref('')

const interestsList = [
  { v: 'desert', l: '🏜️ Désert' },
  { v: 'mediterranee', l: '🌊 Méditerranée' },
  { v: 'montagne', l: '⛰️ Montagne' },
  { v: 'patrimoine', l: '🏛️ Patrimoine' },
  { v: 'gastronomie', l: '🍴 Gastronomie' },
  { v: 'spiritualite', l: '🌙 Spiritualité' },
  { v: 'artisanat', l: '🧶 Artisanat' },
  { v: 'aventure', l: '🥾 Aventure' },
  { v: 'famille', l: '👨‍👩‍👧 Famille' },
  { v: 'photo', l: '📸 Photo' }
]

const budgetLabels = {
  eco: 'Économique (< 30 000 DA/p)',
  medium: 'Moyen (30 000 - 80 000 DA/p)',
  premium: 'Premium (> 80 000 DA/p)'
}

onMounted(async () => {
  const { data } = await supabase
    .from('destinations')
    .select('id, name, cultural_theme')
    .order('name')
  destinations.value = (data as Destination[]) || []

  // Pré-remplir depuis ?q=... (quick prompts de la HomePage)
  const q = route.query.q
  if (typeof q === 'string' && q.trim()) {
    note.value = q.trim()
  }
})

function toggleInterest(v: string) {
  const idx = interests.value.indexOf(v)
  if (idx >= 0) interests.value.splice(idx, 1)
  else interests.value.push(v)
}

async function generate() {
  error.value = ''
  if (interests.value.length === 0) {
    error.value = 'Sélectionnez au moins un centre d\'intérêt.'
    return
  }

  generating.value = true
  response.value = null

  const question = buildQuestion()

  try {
    const { data, error: fnErr } = await supabase.functions.invoke('ai-assistant', {
      body: {
        question,
        user_id: auth.user?.id || null,
        destination_id: destinationId.value
      }
    })
    if (fnErr) throw fnErr
    response.value = data
  } catch (e: any) {
    error.value = e.message || 'Erreur lors de la génération.'
  } finally {
    generating.value = false
  }
}

function buildQuestion(): string {
  const interestLabels = interests.value
    .map(v => interestsList.find(i => i.v === v)?.l.replace(/^.+ /, ''))
    .filter(Boolean)
    .join(', ')

  let q = `Compose-moi un parcours de ${duration.value} jours en Algérie. `
  q += `Mes centres d'intérêt : ${interestLabels}. `
  q += `Budget : ${budgetLabels[budget.value]}. `
  q += `Saison : ${season.value}. `
  q += `Mobilité : ${mobility.value === 'easy' ? 'facile (peu de marche)' : mobility.value === 'sport' ? 'sportive (trek possible)' : 'normale'}. `
  if (destinationId.value) {
    const dest = destinations.value.find(d => d.id === destinationId.value)
    if (dest) q += `Destination ciblée : ${dest.name}. `
  }
  if (note.value.trim()) {
    q += `Note complémentaire : ${note.value.trim()}.`
  }
  q += ' Propose un programme jour par jour avec sites, hébergements et tables à partir du catalogue Djawal.'
  return q
}

function reset() {
  response.value = null
}
</script>

<template>
  <div class="composer-page">
    <header class="hero">
      <div class="djawal-container">
        <div class="eyebrow">✦ Composer avec Fennec</div>
        <h1>Votre voyage, façonné par vos envies</h1>
        <p class="lead">
          Fennec, notre guide intelligent, s'appuie sur le catalogue Djawal et les parcours déjà
          composés par nos guides locaux pour vous proposer un itinéraire sur mesure.
        </p>
      </div>
    </header>

    <div class="djawal-container djawal-section composer-body">
      <!-- ÉTAT INITIAL : formulaire -->
      <div v-if="!response" class="form-wrap">
        <v-alert v-if="error" type="error" variant="tonal" class="mb-3">{{ error }}</v-alert>

        <section class="block">
          <h2>1. Vos centres d'intérêt</h2>
          <p class="hint">Plusieurs choix possibles.</p>
          <div class="interest-grid">
            <button
              v-for="i in interestsList"
              :key="i.v"
              class="interest-chip"
              :class="{ active: interests.includes(i.v) }"
              @click="toggleInterest(i.v)"
            >
              {{ i.l }}
            </button>
          </div>
        </section>

        <section class="block">
          <h2>2. Cadre du voyage</h2>
          <div class="grid-2">
            <div class="field">
              <label>Durée</label>
              <div class="duration-row">
                <input
                  type="range"
                  min="2"
                  max="15"
                  v-model.number="duration"
                  class="duration-slider"
                />
                <span class="duration-value">{{ duration }} jour{{ duration > 1 ? 's' : '' }}</span>
              </div>
            </div>

            <div class="field">
              <label>Budget par personne</label>
              <v-select
                v-model="budget"
                :items="[
                  { value: 'eco', title: budgetLabels.eco },
                  { value: 'medium', title: budgetLabels.medium },
                  { value: 'premium', title: budgetLabels.premium }
                ]"
                density="comfortable"
                variant="outlined"
                hide-details
              />
            </div>

            <div class="field">
              <label>Saison</label>
              <v-select
                v-model="season"
                :items="['printemps', 'été', 'automne', 'hiver']"
                density="comfortable"
                variant="outlined"
                hide-details
              />
            </div>

            <div class="field">
              <label>Mobilité</label>
              <v-select
                v-model="mobility"
                :items="[
                  { value: 'easy', title: 'Facile — peu de marche' },
                  { value: 'normal', title: 'Normale' },
                  { value: 'sport', title: 'Sportive — trek, 4×4' }
                ]"
                density="comfortable"
                variant="outlined"
                hide-details
              />
            </div>
          </div>

          <div class="field mt-3">
            <label>Destination ciblée (optionnel)</label>
            <v-select
              v-model="destinationId"
              :items="[{ value: null, title: 'Toutes destinations' }, ...destinations.map(d => ({ value: d.id, title: d.name }))]"
              density="comfortable"
              variant="outlined"
              hide-details
            />
          </div>
        </section>

        <section class="block">
          <h2>3. Vos précisions (optionnel)</h2>
          <v-textarea
            v-model="note"
            placeholder="Ex : Je voyage avec mes enfants de 8 et 12 ans. J'aimerais éviter les zones très chaudes. J'aime la photographie au lever du soleil…"
            variant="outlined"
            rows="3"
            counter
            maxlength="300"
          />
        </section>

        <div class="actions">
          <v-btn
            color="primary"
            variant="flat"
            size="x-large"
            :loading="generating"
            @click="generate"
          >
            ✨ Composer mon voyage
          </v-btn>
          <p class="ai-hint">L'IA s'appuie uniquement sur les ressources validées du catalogue Djawal.</p>
        </div>
      </div>

      <!-- ÉTAT RÉPONSE -->
      <div v-else class="result-wrap">
        <div class="result-head">
          <h2>Votre proposition Djawal</h2>
          <v-btn variant="outlined" @click="reset">↶ Modifier les critères</v-btn>
        </div>

        <article class="result-card">
          <div class="result-badge">✨ Généré par l'IA — à valider avec un guide</div>
          <p class="result-text">{{ response.answer }}</p>
        </article>

        <div v-if="response.trips && response.trips.length > 0" class="result-section">
          <h3>🗺️ Parcours déjà composés qui pourraient correspondre</h3>
          <div class="rich-grid">
            <router-link
              v-for="t in response.trips"
              :key="t.id"
              :to="`/voyages/${t.id}`"
              class="rich-card"
            >
              <strong>{{ t.title }}</strong>
              <span>{{ t.destination_name }} · {{ t.duration_days }}j · {{ t.price_da }} DA</span>
            </router-link>
          </div>
        </div>

        <div v-if="response.destinations && response.destinations.length > 0" class="result-section">
          <h3>📍 Destinations suggérées</h3>
          <div class="rich-grid">
            <router-link
              v-for="d in response.destinations"
              :key="d.id"
              :to="`/destination/${d.id}`"
              class="rich-card"
            >
              <strong>{{ d.name }}</strong>
              <span>{{ d.wilaya }} · {{ d.cultural_theme }}</span>
            </router-link>
          </div>
        </div>

        <div v-if="response.resources && response.resources.length > 0" class="result-section">
          <h3>📌 Ressources concrètes</h3>
          <div class="rich-grid">
            <div
              v-for="r in response.resources"
              :key="r.resource_id"
              class="rich-card static"
            >
              <strong>{{ r.name }}</strong>
              <span>{{ r.resource_type }} · {{ r.destination_name }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.composer-page { background: var(--c-fond); min-height: 100vh; }

.hero {
  background: var(--c-fond-chaud);
  padding: var(--space-7) var(--space-5) var(--space-5);
  position: relative;
  overflow: hidden;
}
.hero::before {
  content: ''; position: absolute; inset: 0;
  background-image: var(--motif-principal-url);
  opacity: 0.3;
}
.eyebrow {
  color: var(--c-accent-fort);
  font-size: 13px; font-weight: 700;
  letter-spacing: 0.2em; text-transform: uppercase;
  margin-bottom: var(--space-2);
  position: relative;
}
.hero h1 {
  font-family: var(--font-display);
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

.composer-body { max-width: 880px; margin: 0 auto; }

.block {
  background: var(--c-surface);
  border-radius: var(--r-lg);
  padding: var(--space-5);
  margin-bottom: var(--space-4);
  box-shadow: var(--ombre-douce);
}
.block h2 {
  font-family: var(--font-display);
  font-size: 22px;
  color: var(--c-primaire-profond);
  margin-bottom: 4px;
}
.hint { color: var(--c-texte-doux); font-size: 13px; margin-bottom: var(--space-3); }

.interest-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
  gap: var(--space-2);
}
.interest-chip {
  background: var(--c-fond-chaud);
  border: 2px solid transparent;
  border-radius: var(--r-md);
  padding: 14px 12px;
  font-family: inherit;
  font-size: 14px;
  font-weight: 600;
  color: var(--c-primaire-profond);
  cursor: pointer;
  transition: var(--t-base);
}
.interest-chip:hover { border-color: var(--c-accent); }
.interest-chip.active {
  background: var(--c-accent);
  color: var(--c-fond);
  border-color: var(--c-accent);
  transform: translateY(-2px);
  box-shadow: var(--ombre-douce);
}

.grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--space-3);
}
@media (max-width: 600px) {
  .grid-2 { grid-template-columns: 1fr; }
}
.field { display: flex; flex-direction: column; gap: 4px; }
.field label {
  font-size: 13px;
  font-weight: 700;
  color: var(--c-primaire-profond);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.duration-row { display: flex; align-items: center; gap: var(--space-3); }
.duration-slider {
  flex: 1;
  height: 6px;
  border-radius: 3px;
  background: var(--c-fond-chaud);
  -webkit-appearance: none;
  appearance: none;
}
.duration-slider::-webkit-slider-thumb {
  -webkit-appearance: none;
  appearance: none;
  width: 22px; height: 22px;
  background: var(--c-accent);
  border-radius: 50%;
  cursor: pointer;
  box-shadow: var(--ombre-douce);
}
.duration-value {
  font-family: var(--font-display);
  font-size: 20px;
  font-weight: 700;
  color: var(--c-accent-fort);
  min-width: 90px;
  text-align: right;
}

.actions {
  text-align: center;
  margin-top: var(--space-4);
}
.ai-hint {
  margin-top: var(--space-2);
  font-size: 12px;
  color: var(--c-texte-doux);
  font-style: italic;
}

/* === RÉSULTAT === */
.result-head {
  display: flex; justify-content: space-between; align-items: center;
  margin-bottom: var(--space-4);
  flex-wrap: wrap; gap: var(--space-3);
}
.result-head h2 {
  font-family: var(--font-display);
  font-size: clamp(24px, 3vw, 36px);
  color: var(--c-primaire-profond);
}

.result-card {
  background: var(--c-surface);
  border-radius: var(--r-lg);
  padding: var(--space-5);
  box-shadow: var(--ombre-douce);
  border-left: 4px solid var(--c-accent);
  margin-bottom: var(--space-5);
}
.result-badge {
  display: inline-block;
  background: rgba(212, 160, 79, 0.15);
  color: var(--c-accent-fort);
  padding: 4px 12px;
  border-radius: var(--r-pill);
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: var(--space-3);
}
.result-text {
  font-size: 16px;
  line-height: 1.7;
  color: var(--c-texte);
  white-space: pre-wrap;
}

.result-section { margin-bottom: var(--space-5); }
.result-section h3 {
  font-family: var(--font-display);
  font-size: 22px;
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-3);
}
.rich-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: var(--space-2);
}
.rich-card {
  background: var(--c-surface);
  border-radius: var(--r-md);
  padding: var(--space-3);
  box-shadow: var(--ombre-douce);
  text-decoration: none;
  color: inherit;
  display: flex;
  flex-direction: column;
  gap: 4px;
  transition: var(--t-base);
}
.rich-card:not(.static):hover {
  transform: translateY(-2px);
  box-shadow: var(--ombre-elevee);
}
.rich-card strong {
  color: var(--c-primaire-profond);
  font-size: 14px;
}
.rich-card span {
  color: var(--c-texte-doux);
  font-size: 12px;
}
</style>
