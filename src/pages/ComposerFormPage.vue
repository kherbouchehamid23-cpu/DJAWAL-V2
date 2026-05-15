<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'
import { useSEO } from '@/composables/useSEO'
import djawalMonogram from '@/assets/branding/djawal-monogram.png'

useSEO({ title: 'Composer mon voyage — Djawal' })

const auth = useAuthStore()
const router = useRouter()

// === Données ===
interface Destination { id: string; name: string; cultural_theme: string }
const destinations = ref<Destination[]>([])

// === Étape courante (wizard) ===
const step = ref(1)
const totalSteps = 4

// === Critère 1 : DATES & DURÉE ===
type DateMode = 'season' | 'month' | 'precise' | 'duration'
const dateMode = ref<DateMode>('season')
const season = ref('printemps')
const monthChoice = ref('mars')
const startDate = ref('')
const endDate = ref('')
const durationDays = ref(7)

const seasons = [
  { v: 'printemps', l: 'Printemps (mars-mai)', d: 'Floraison du désert · douces températures' },
  { v: 'ete', l: 'Été (juin-août)', d: 'Idéal côte méditerranéenne · Sahara très chaud' },
  { v: 'automne', l: 'Automne (sept-nov)', d: 'Excellente saison pour le Sahara' },
  { v: 'hiver', l: 'Hiver (déc-février)', d: 'Sahara doux le jour, frais la nuit' }
]
const months = [
  { v: 'janvier', l: 'Janvier' }, { v: 'fevrier', l: 'Février' }, { v: 'mars', l: 'Mars' },
  { v: 'avril', l: 'Avril' }, { v: 'mai', l: 'Mai' }, { v: 'juin', l: 'Juin' },
  { v: 'juillet', l: 'Juillet' }, { v: 'aout', l: 'Août' }, { v: 'septembre', l: 'Septembre' },
  { v: 'octobre', l: 'Octobre' }, { v: 'novembre', l: 'Novembre' }, { v: 'decembre', l: 'Décembre' }
]

// === Critère 2 : GROUPE ===
type GroupType = 'solo' | 'couple' | 'family' | 'friends' | 'large'
const groupType = ref<GroupType>('couple')
const adults = ref(2)
const childrenCount = ref(0)
const childrenAges = ref<string>('')

const groupTypes = [
  { v: 'solo', l: 'Solo', icon: '👤' },
  { v: 'couple', l: 'Couple', icon: '👫' },
  { v: 'family', l: 'En famille avec enfants', icon: '👨‍👩‍👧' },
  { v: 'friends', l: 'Entre amis', icon: '🧑‍🤝‍🧑' },
  { v: 'large', l: 'Grand groupe (5+)', icon: '👥' }
]

// === Critère 3 : CENTRES D'INTÉRÊT ===
const interests = ref<string[]>([])
const interestsList = [
  { v: 'desert', l: 'Sahara & désert', icon: '🏜️' },
  { v: 'mediterranee', l: 'Méditerranée & côte', icon: '🌊' },
  { v: 'montagne', l: 'Montagne & trek', icon: '⛰️' },
  { v: 'patrimoine', l: 'Patrimoine & sites UNESCO', icon: '🏛️' },
  { v: 'casbah', l: 'Casbah & médinas', icon: '🕌' },
  { v: 'gastronomie', l: 'Gastronomie & tables d\'hôtes', icon: '🍴' },
  { v: 'spiritualite', l: 'Spiritualité & soufisme', icon: '🌙' },
  { v: 'artisanat', l: 'Artisanat & ateliers', icon: '🧶' },
  { v: 'aventure', l: '4x4 & bivouac', icon: '🚙' },
  { v: 'photo', l: 'Photo & paysages', icon: '📸' }
]

// === Critère 4 : BUDGET (fourchette) ===
type BudgetTier = 'eco' | 'medium' | 'comfort' | 'premium' | 'custom'
const budgetTier = ref<BudgetTier>('medium')
const budgetMin = ref(80000)
const budgetMax = ref(120000)

const budgetTiers = [
  { v: 'eco', l: 'Économique', range: '< 50 000 DA', min: 0, max: 50000, d: 'Hébergements simples, transports locaux' },
  { v: 'medium', l: 'Moyen', range: '50 000 – 150 000 DA', min: 50000, max: 150000, d: 'Hôtels confortables, mix bus/4x4' },
  { v: 'comfort', l: 'Confort', range: '150 000 – 300 000 DA', min: 150000, max: 300000, d: 'Lodges authentiques, chauffeur privé' },
  { v: 'premium', l: 'Premium', range: '> 300 000 DA', min: 300000, max: 1000000, d: 'Sur-mesure, guides experts, expériences rares' }
]

// === Mobilité / Notes complémentaires ===
const mobility = ref<'easy' | 'normal' | 'sport'>('normal')
const destinationId = ref<string | null>(null)
const extraNotes = ref('')

// === Génération ===
const generating = ref(false)
const response = ref<any>(null)
const error = ref('')

onMounted(async () => {
  const { data } = await supabase.from('destinations').select('id, name, cultural_theme').order('name')
  destinations.value = (data as Destination[]) || []
})

// === Helpers ===
function toggleInterest(v: string) {
  const i = interests.value.indexOf(v)
  if (i >= 0) interests.value.splice(i, 1)
  else interests.value.push(v)
}

const stepValid = computed(() => {
  if (step.value === 1) {
    if (dateMode.value === 'precise') return !!(startDate.value && endDate.value)
    return true
  }
  if (step.value === 2) return groupType.value !== null
  if (step.value === 3) return interests.value.length >= 1
  if (step.value === 4) return budgetTier.value !== null
  return true
})

function nextStep() { if (step.value < totalSteps) step.value++ }
function prevStep() { if (step.value > 1) step.value-- }

// === Construction du prompt depuis les 4 critères ===
function buildPrompt(): string {
  const parts: string[] = []

  // 1. Dates
  if (dateMode.value === 'season') {
    const s = seasons.find(s => s.v === season.value)
    parts.push(`Voyage prévu au ${s?.l || season.value}`)
  } else if (dateMode.value === 'month') {
    const m = months.find(m => m.v === monthChoice.value)
    parts.push(`Voyage prévu en ${m?.l.toLowerCase() || monthChoice.value}`)
  } else if (dateMode.value === 'precise') {
    parts.push(`Voyage du ${startDate.value} au ${endDate.value}`)
  }
  if (dateMode.value === 'duration' || dateMode.value === 'season' || dateMode.value === 'month') {
    parts.push(`${durationDays.value} jours sur place`)
  }

  // 2. Groupe
  const gt = groupTypes.find(g => g.v === groupType.value)
  let groupDesc = gt?.l || groupType.value
  if (groupType.value === 'family' && childrenCount.value > 0) {
    groupDesc += ` (${adults.value} adultes + ${childrenCount.value} enfant${childrenCount.value > 1 ? 's' : ''}${childrenAges.value ? ' âgés de ' + childrenAges.value : ''})`
  } else if (groupType.value !== 'solo') {
    groupDesc += ` (${adults.value} adultes)`
  }
  parts.push(`Composition : ${groupDesc}`)

  // 3. Centres d'intérêt
  const interestLabels = interests.value.map(v => interestsList.find(i => i.v === v)?.l || v).join(', ')
  parts.push(`Centres d'intérêt : ${interestLabels}`)

  // 4. Budget
  const bt = budgetTiers.find(b => b.v === budgetTier.value)
  parts.push(`Budget par personne : ${bt?.range || budgetTier.value} (${bt?.l || ''})`)

  // 5. Extras
  if (mobility.value !== 'normal') {
    parts.push(`Mobilité : ${mobility.value === 'easy' ? 'facile (peu de marche)' : 'sportive (trek possible)'}`)
  }
  if (destinationId.value) {
    const d = destinations.value.find(d => d.id === destinationId.value)
    if (d) parts.push(`Destination ciblée : ${d.name}`)
  }
  if (extraNotes.value.trim()) {
    parts.push(`Note : ${extraNotes.value.trim()}`)
  }
  parts.push('Propose un programme jour par jour avec sites, hébergements et tables à partir du catalogue Djawal.')

  return parts.join('. ')
}

async function generate() {
  error.value = ''
  generating.value = true
  response.value = null
  try {
    const prompt = buildPrompt()
    const { data, error: fnErr } = await supabase.functions.invoke('ai-assistant', {
      body: {
        question: prompt,
        user_id: auth.user?.id || null,
        destination_id: destinationId.value,
        skip_analysis: true  // on a déjà toutes les infos
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

function resetAll() {
  step.value = 1
  response.value = null
  error.value = ''
}
</script>

<template>
  <div class="composer-form-page">

    <!-- Header -->
    <header class="form-hero">
      <div class="djawal-container">
        <div class="form-eyebrow">
          <img :src="djawalMonogram" alt="" class="form-logo" />
          <span>Composer mon voyage — formulaire détaillé</span>
        </div>
        <h1>Construisons votre voyage <em>étape par étape</em></h1>
        <p class="form-lead">
          Quatre questions précises, une réponse sur-mesure. Djawal IA compose
          votre parcours à partir de vos critères.
        </p>
      </div>
    </header>

    <main class="form-main">
      <div class="djawal-container">

        <!-- RÉPONSE FINALE -->
        <div v-if="response?.answer" class="form-response">
          <div class="response-head">
            <img :src="djawalMonogram" alt="" class="response-avatar" />
            <strong>Votre voyage composé</strong>
          </div>
          <div class="response-text" v-html="response.answer.replace(/\n/g, '<br>')"></div>

          <section v-if="response.destinations?.length" class="response-section">
            <h3>Destinations</h3>
            <div class="response-cards">
              <button v-for="d in response.destinations" :key="d.id" class="response-card" type="button" @click="router.push('/destination/' + d.id)">
                <strong>{{ d.name }}</strong>
                <small>{{ d.wilaya }}</small>
              </button>
            </div>
          </section>

          <section v-if="response.trips?.length" class="response-section">
            <h3>Voyages similaires</h3>
            <div class="response-cards">
              <button v-for="t in response.trips" :key="t.id" class="response-card" type="button" @click="router.push('/voyages/' + t.id)">
                <strong>{{ t.title }}</strong>
                <small>{{ t.duration_days }}j</small>
              </button>
            </div>
          </section>

          <div class="response-actions">
            <button class="form-btn-ghost" type="button" @click="resetAll">Recommencer</button>
            <router-link to="/voyages" class="form-btn-ghost">Voir tous les voyages</router-link>
          </div>
        </div>

        <!-- WIZARD -->
        <div v-else class="form-wizard">
          <!-- Progress -->
          <div class="form-progress">
            <div v-for="n in totalSteps" :key="n"
                 class="progress-step"
                 :class="{ active: step === n, done: step > n }">
              {{ n }}
            </div>
          </div>

          <!-- ============ ÉTAPE 1 : DATES & DURÉE ============ -->
          <div v-if="step === 1" class="form-step">
            <h2>1. Quand voulez-vous voyager ?</h2>
            <p class="step-helper">Choisissez le format qui vous convient.</p>

            <div class="mode-tabs">
              <button :class="{ active: dateMode === 'season' }" @click="dateMode = 'season'" type="button">Une saison</button>
              <button :class="{ active: dateMode === 'month' }" @click="dateMode = 'month'" type="button">Un mois</button>
              <button :class="{ active: dateMode === 'precise' }" @click="dateMode = 'precise'" type="button">Dates précises</button>
              <button :class="{ active: dateMode === 'duration' }" @click="dateMode = 'duration'" type="button">Flexible</button>
            </div>

            <div v-if="dateMode === 'season'" class="cards-grid">
              <button v-for="s in seasons" :key="s.v" type="button"
                      class="big-card" :class="{ active: season === s.v }"
                      @click="season = s.v">
                <strong>{{ s.l }}</strong>
                <small>{{ s.d }}</small>
              </button>
            </div>

            <div v-if="dateMode === 'month'" class="chips-grid">
              <button v-for="m in months" :key="m.v" type="button"
                      class="chip" :class="{ active: monthChoice === m.v }"
                      @click="monthChoice = m.v">{{ m.l }}</button>
            </div>

            <div v-if="dateMode === 'precise'" class="date-inputs">
              <label>Du <input type="date" v-model="startDate" /></label>
              <label>Au <input type="date" v-model="endDate" /></label>
            </div>

            <div v-if="dateMode !== 'precise'" class="duration-input">
              <label>Durée approximative : <strong>{{ durationDays }} jours</strong></label>
              <input type="range" min="2" max="21" v-model.number="durationDays" />
              <div class="duration-marks"><span>2j</span><span>1 sem</span><span>2 sem</span><span>3 sem</span></div>
            </div>
          </div>

          <!-- ============ ÉTAPE 2 : COMPOSITION GROUPE ============ -->
          <div v-if="step === 2" class="form-step">
            <h2>2. Qui voyage avec vous ?</h2>
            <p class="step-helper">Cela nous aide à proposer des hébergements et activités adaptés.</p>

            <div class="cards-grid">
              <button v-for="g in groupTypes" :key="g.v" type="button"
                      class="big-card" :class="{ active: groupType === g.v }"
                      @click="groupType = g.v as GroupType">
                <span class="card-icon">{{ g.icon }}</span>
                <strong>{{ g.l }}</strong>
              </button>
            </div>

            <div class="counters" v-if="groupType !== 'solo'">
              <div class="counter">
                <label>Adultes</label>
                <div class="counter-controls">
                  <button type="button" @click="adults = Math.max(1, adults - 1)">−</button>
                  <span>{{ adults }}</span>
                  <button type="button" @click="adults++">+</button>
                </div>
              </div>
              <div class="counter" v-if="groupType === 'family'">
                <label>Enfants</label>
                <div class="counter-controls">
                  <button type="button" @click="childrenCount = Math.max(0, childrenCount - 1)">−</button>
                  <span>{{ childrenCount }}</span>
                  <button type="button" @click="childrenCount++">+</button>
                </div>
              </div>
            </div>
            <div v-if="groupType === 'family' && childrenCount > 0" class="children-ages">
              <label>Âge des enfants (optionnel)</label>
              <input type="text" v-model="childrenAges" placeholder="Ex : 5 et 9 ans" />
            </div>
          </div>

          <!-- ============ ÉTAPE 3 : CENTRES D'INTÉRÊT ============ -->
          <div v-if="step === 3" class="form-step">
            <h2>3. Qu'est-ce qui vous tente ?</h2>
            <p class="step-helper">Sélectionnez un ou plusieurs centres d'intérêt (1 suffit, vous pouvez en cumuler).</p>

            <div class="cards-grid">
              <button v-for="i in interestsList" :key="i.v" type="button"
                      class="big-card" :class="{ active: interests.includes(i.v) }"
                      @click="toggleInterest(i.v)">
                <span class="card-icon">{{ i.icon }}</span>
                <strong>{{ i.l }}</strong>
              </button>
            </div>

            <div class="step-extra">
              <label>Une destination en tête ? (optionnel)</label>
              <select v-model="destinationId">
                <option :value="null">— Pas de préférence —</option>
                <option v-for="d in destinations" :key="d.id" :value="d.id">{{ d.name }}</option>
              </select>
            </div>

            <div class="step-extra">
              <label>Niveau de mobilité</label>
              <div class="mobility-tabs">
                <button :class="{ active: mobility === 'easy' }" @click="mobility = 'easy'" type="button">Facile</button>
                <button :class="{ active: mobility === 'normal' }" @click="mobility = 'normal'" type="button">Normal</button>
                <button :class="{ active: mobility === 'sport' }" @click="mobility = 'sport'" type="button">Sportif</button>
              </div>
            </div>
          </div>

          <!-- ============ ÉTAPE 4 : BUDGET ============ -->
          <div v-if="step === 4" class="form-step">
            <h2>4. Quel est votre budget par personne ?</h2>
            <p class="step-helper">Une fourchette approximative suffit, on adaptera le voyage.</p>

            <div class="cards-grid">
              <button v-for="b in budgetTiers" :key="b.v" type="button"
                      class="big-card" :class="{ active: budgetTier === b.v }"
                      @click="budgetTier = b.v as BudgetTier">
                <strong>{{ b.l }}</strong>
                <span class="budget-range">{{ b.range }}</span>
                <small>{{ b.d }}</small>
              </button>
            </div>

            <div class="step-extra">
              <label>Une précision à ajouter ? (optionnel)</label>
              <textarea v-model="extraNotes" rows="3" placeholder="Allergies, contraintes mobilité, occasions spéciales (lune de miel, anniversaire)…"></textarea>
            </div>
          </div>

          <!-- Erreur -->
          <div v-if="error" class="form-error">⚠️ {{ error }}</div>

          <!-- NAV BUTTONS -->
          <div class="form-nav">
            <button v-if="step > 1" class="form-btn-ghost" type="button" @click="prevStep" :disabled="generating">← Précédent</button>
            <span v-else></span>
            <button v-if="step < totalSteps" class="form-btn-primary" type="button" @click="nextStep" :disabled="!stepValid">
              Suivant →
            </button>
            <button v-else class="form-btn-primary" type="button" @click="generate" :disabled="!stepValid || generating">
              <span v-if="!generating">Composer mon voyage ✦</span>
              <span v-else>Djawal IA compose…</span>
            </button>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<style scoped>
.composer-form-page {
  background: linear-gradient(180deg, #0F2419 0%, #1A3A2A 100%);
  min-height: 100vh;
  color: #FAF7F2;
  font-family: 'Inter', sans-serif;
}
.djawal-container { max-width: 880px; margin: 0 auto; padding: 0 32px; }

.form-hero { padding: 100px 0 50px; text-align: center; }
.form-eyebrow {
  display: inline-flex; align-items: center; gap: 10px;
  padding: 8px 18px;
  background: rgba(212, 168, 68, 0.18);
  border: 1px solid rgba(212, 168, 68, 0.4);
  border-radius: 999px;
  font-size: 11px; letter-spacing: 0.16em;
  color: #E8B96B; text-transform: uppercase;
  margin-bottom: 22px;
}
.form-logo { width: 22px; height: 22px; border-radius: 5px; }
.form-hero h1 {
  font-family: 'Cormorant Garamond', serif;
  font-size: clamp(28px, 5vw, 46px);
  font-weight: 500; line-height: 1.05;
  margin-bottom: 14px;
}
.form-hero h1 em { font-style: italic; color: #E8B96B; }
.form-lead {
  font-family: 'Cormorant Garamond', serif;
  font-style: italic; font-size: 17px;
  color: rgba(250, 247, 242, 0.75);
  max-width: 560px; margin: 0 auto;
}

.form-main { padding-bottom: 100px; }

.form-wizard {
  background: rgba(31, 74, 54, 0.5);
  border: 1px solid rgba(212, 168, 68, 0.28);
  border-radius: 24px;
  padding: 36px 32px;
}

/* Progress */
.form-progress {
  display: flex; justify-content: center; gap: 12px;
  margin-bottom: 30px;
}
.progress-step {
  width: 36px; height: 36px;
  border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  background: rgba(250, 247, 242, 0.08);
  border: 1px solid rgba(212, 168, 68, 0.3);
  color: rgba(250, 247, 242, 0.6);
  font-weight: 600; font-size: 14px;
}
.progress-step.active { background: #D4A844; color: #0F2419; border-color: #D4A844; }
.progress-step.done { background: rgba(212, 168, 68, 0.3); color: #E8B96B; border-color: #E8B96B; }

.form-step h2 {
  font-family: 'Cormorant Garamond', serif;
  font-size: 26px; font-weight: 500;
  margin-bottom: 8px;
}
.step-helper {
  color: rgba(250, 247, 242, 0.65);
  font-size: 14px; margin-bottom: 20px;
}

.mode-tabs, .mobility-tabs {
  display: flex; gap: 8px; flex-wrap: wrap;
  margin-bottom: 20px;
}
.mode-tabs button, .mobility-tabs button {
  background: rgba(250, 247, 242, 0.06);
  border: 1px solid rgba(212, 168, 68, 0.3);
  color: #FAF7F2;
  padding: 9px 18px;
  border-radius: 999px;
  font-family: inherit; font-size: 13px;
  cursor: pointer; transition: all 0.2s;
}
.mode-tabs button.active, .mobility-tabs button.active {
  background: #D4A844; color: #0F2419; border-color: #D4A844; font-weight: 600;
}

.cards-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: 12px;
  margin-bottom: 20px;
}
.big-card {
  background: rgba(250, 247, 242, 0.06);
  border: 1.5px solid rgba(212, 168, 68, 0.25);
  border-radius: 14px;
  padding: 18px 14px;
  text-align: left;
  cursor: pointer;
  font-family: inherit;
  color: #FAF7F2;
  display: flex; flex-direction: column; gap: 6px;
  transition: all 0.2s;
}
.big-card:hover { background: rgba(212, 168, 68, 0.12); border-color: rgba(212, 168, 68, 0.55); }
.big-card.active { background: rgba(212, 168, 68, 0.25); border-color: #D4A844; }
.big-card strong { font-family: 'Cormorant Garamond', serif; font-size: 16px; font-weight: 500; }
.big-card small { color: rgba(250, 247, 242, 0.6); font-size: 12px; line-height: 1.4; }
.card-icon { font-size: 24px; margin-bottom: 4px; }
.budget-range {
  color: #E8B96B; font-size: 13px; font-weight: 500;
  font-family: 'Cormorant Garamond', serif; font-style: italic;
}

.chips-grid { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 20px; }
.chip {
  background: rgba(250, 247, 242, 0.06);
  border: 1px solid rgba(212, 168, 68, 0.25);
  color: #FAF7F2;
  padding: 8px 16px;
  border-radius: 999px;
  font-family: inherit; font-size: 13px;
  cursor: pointer; transition: all 0.2s;
}
.chip:hover { background: rgba(212, 168, 68, 0.12); border-color: #D4A844; }
.chip.active { background: #D4A844; color: #0F2419; border-color: #D4A844; font-weight: 600; }

.date-inputs { display: flex; gap: 16px; flex-wrap: wrap; margin-bottom: 20px; }
.date-inputs label { display: flex; align-items: center; gap: 10px; color: rgba(250, 247, 242, 0.8); font-size: 14px; }
.date-inputs input, .step-extra input, .step-extra select, .step-extra textarea {
  background: rgba(15, 36, 25, 0.5);
  border: 1px solid rgba(212, 168, 68, 0.3);
  border-radius: 10px;
  color: #FAF7F2;
  padding: 10px 14px;
  font-size: 14px;
  font-family: inherit;
  outline: none;
}
.duration-input {
  background: rgba(15, 36, 25, 0.4);
  border: 1px solid rgba(212, 168, 68, 0.2);
  border-radius: 12px;
  padding: 16px 18px;
}
.duration-input label { display: block; margin-bottom: 10px; font-size: 14px; color: rgba(250, 247, 242, 0.8); }
.duration-input label strong { color: #E8B96B; font-family: 'Cormorant Garamond', serif; font-size: 18px; font-style: italic; }
.duration-input input[type="range"] { width: 100%; }
.duration-marks { display: flex; justify-content: space-between; font-size: 11px; color: rgba(250, 247, 242, 0.5); margin-top: 4px; }

.counters { display: flex; gap: 24px; flex-wrap: wrap; margin-bottom: 16px; padding-top: 12px; }
.counter label { display: block; font-size: 13px; color: rgba(250, 247, 242, 0.7); margin-bottom: 6px; letter-spacing: 0.04em; }
.counter-controls {
  display: inline-flex; align-items: center; gap: 12px;
  background: rgba(15, 36, 25, 0.4);
  border: 1px solid rgba(212, 168, 68, 0.3);
  border-radius: 999px;
  padding: 4px;
}
.counter-controls button {
  width: 36px; height: 36px; border-radius: 50%;
  background: rgba(212, 168, 68, 0.18);
  border: none; color: #FAF7F2;
  font-size: 18px; font-weight: 600;
  cursor: pointer;
}
.counter-controls button:hover { background: #D4A844; color: #0F2419; }
.counter-controls span { min-width: 24px; text-align: center; font-weight: 600; }

.children-ages { margin-bottom: 16px; }
.children-ages label { display: block; font-size: 13px; color: rgba(250, 247, 242, 0.7); margin-bottom: 6px; }
.children-ages input { width: 100%; max-width: 360px; background: rgba(15, 36, 25, 0.4); border: 1px solid rgba(212, 168, 68, 0.25); border-radius: 10px; color: #FAF7F2; padding: 10px 14px; font-family: inherit; outline: none; }

.step-extra { margin-top: 22px; }
.step-extra label { display: block; font-size: 13px; color: rgba(250, 247, 242, 0.7); margin-bottom: 8px; letter-spacing: 0.04em; }
.step-extra select, .step-extra textarea { width: 100%; }
.step-extra textarea { resize: vertical; min-height: 72px; }

.form-error {
  background: rgba(220, 53, 69, 0.15);
  border: 1px solid rgba(220, 53, 69, 0.4);
  color: #FFB3B3;
  padding: 12px 18px;
  border-radius: 10px;
  margin-top: 20px;
}

.form-nav {
  display: flex; justify-content: space-between; align-items: center;
  margin-top: 30px; padding-top: 24px;
  border-top: 1px solid rgba(212, 168, 68, 0.2);
}
.form-btn-primary {
  background: #D4A844; color: #0F2419;
  border: none; padding: 13px 28px;
  border-radius: 999px; font-weight: 600;
  font-family: inherit; font-size: 14px;
  cursor: pointer; transition: all 0.2s;
}
.form-btn-primary:hover:not(:disabled) { background: #E8B96B; }
.form-btn-primary:disabled { opacity: 0.5; cursor: not-allowed; }
.form-btn-ghost {
  background: transparent; color: #E8B96B;
  border: 1px solid rgba(212, 168, 68, 0.3);
  padding: 12px 22px;
  border-radius: 999px;
  font-family: inherit; font-size: 13px;
  cursor: pointer; text-decoration: none;
}

/* RESPONSE */
.form-response {
  background: rgba(31, 74, 54, 0.5);
  border: 1px solid rgba(212, 168, 68, 0.3);
  border-radius: 24px;
  padding: 32px;
}
.response-head { display: flex; align-items: center; gap: 12px; margin-bottom: 18px; padding-bottom: 16px; border-bottom: 1px solid rgba(212, 168, 68, 0.2); }
.response-avatar { width: 38px; height: 38px; border-radius: 50%; background: #FAF7F2; padding: 4px; }
.response-head strong { font-family: 'Cormorant Garamond', serif; font-style: italic; font-size: 18px; color: #E8B96B; }
.response-text { font-size: 15px; line-height: 1.7; color: #FAF7F2; margin-bottom: 24px; }
.response-section { margin-top: 24px; }
.response-section h3 { font-family: 'Cormorant Garamond', serif; font-size: 18px; color: #E8B96B; margin-bottom: 12px; }
.response-cards { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 10px; }
.response-card { background: rgba(15, 36, 25, 0.5); border: 1px solid rgba(212, 168, 68, 0.2); border-radius: 12px; padding: 12px 14px; text-align: left; cursor: pointer; font-family: inherit; color: inherit; transition: all 0.2s; }
.response-card:hover { background: rgba(15, 36, 25, 0.7); border-color: #D4A844; transform: translateY(-2px); }
.response-card strong { display: block; color: #FAF7F2; font-family: 'Cormorant Garamond', serif; font-size: 15px; margin-bottom: 4px; }
.response-card small { color: #E8B96B; font-size: 11px; }
.response-actions { display: flex; gap: 12px; flex-wrap: wrap; justify-content: center; margin-top: 26px; }

@media (max-width: 700px) {
  .form-hero { padding: 80px 0 36px; }
  .form-hero h1 { font-size: 26px; }
  .djawal-container { padding: 0 20px; }
  .form-wizard, .form-response { padding: 22px 18px; }
  .form-step h2 { font-size: 22px; }
  .cards-grid { grid-template-columns: 1fr 1fr; }
  .counters { gap: 14px; }
}
</style>
