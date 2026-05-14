<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const auth = useAuthStore()

interface DayItem {
  day: number
  title: string
  description: string
  meals: string[]
  accommodation: string
}

const title = ref('')
const description = ref('')
const destinationId = ref<string>('')
const durationDays = ref(3)
const priceDa = ref<number | null>(null)
const itinerary = ref<DayItem[]>([])
const inclusions = ref<string[]>([])
const exclusions = ref<string[]>([])
const inclusionInput = ref('')
const exclusionInput = ref('')
const includedGuideId = ref<string | null>(null)
const submitForReview = ref(true)

const destinations = ref<any[]>([])
const availableGuides = ref<any[]>([])
const saving = ref(false)
const errorMsg = ref<string | null>(null)
const successMsg = ref<string | null>(null)

const mealOptions = ['petit-déjeuner', 'déjeuner', 'dîner', 'goûter']

onMounted(async () => {
  if (!auth.canSubmit('trip')) {
    errorMsg.value = 'Votre type d\'opérateur n\'autorise pas la soumission de packages.'
    return
  }
  await loadDestinations()
  await loadGuides()
  syncDays(durationDays.value)
})

async function loadDestinations() {
  const { data } = await supabase.from('destinations').select('id, name, wilaya').order('name')
  destinations.value = data || []
}

async function loadGuides() {
  // Seuls les Guides Senior approuvés sont éligibles à être inclus dans un package
  const { data } = await supabase
    .from('profiles')
    .select('id, display_name, region')
    .eq('role', 'guide_senior')
    .eq('kyc_status', 'approved')
    .limit(50)
  availableGuides.value = data || []
}

function syncDays(n: number) {
  if (n < itinerary.value.length) {
    itinerary.value = itinerary.value.slice(0, n)
  } else {
    for (let i = itinerary.value.length; i < n; i++) {
      itinerary.value.push({
        day: i + 1,
        title: '',
        description: '',
        meals: [],
        accommodation: ''
      })
    }
  }
}

function onDurationChange() {
  if (durationDays.value < 1) durationDays.value = 1
  if (durationDays.value > 30) durationDays.value = 30
  syncDays(durationDays.value)
}

function addInclusion() {
  const t = inclusionInput.value.trim()
  if (t && !inclusions.value.includes(t)) inclusions.value.push(t)
  inclusionInput.value = ''
}

function removeInclusion(s: string) {
  inclusions.value = inclusions.value.filter(x => x !== s)
}

function addExclusion() {
  const t = exclusionInput.value.trim()
  if (t && !exclusions.value.includes(t)) exclusions.value.push(t)
  exclusionInput.value = ''
}

function removeExclusion(s: string) {
  exclusions.value = exclusions.value.filter(x => x !== s)
}

const validation = computed(() => ({
  title: title.value.trim().length >= 3,
  description: description.value.trim().length >= 20,
  destination: !!destinationId.value,
  duration: durationDays.value >= 1 && durationDays.value <= 30,
  price: !!priceDa.value && priceDa.value > 0,
  itinerary: itinerary.value.every(d => d.title.trim().length > 0)
}))

const canSubmit = computed(() =>
  validation.value.title &&
  validation.value.description &&
  validation.value.destination &&
  validation.value.duration &&
  validation.value.price &&
  validation.value.itinerary &&
  !saving.value
)

const missingFields = computed(() => {
  const m: string[] = []
  if (!validation.value.title) m.push('Titre (≥ 3 caractères)')
  if (!validation.value.description) m.push('Description (≥ 20 caractères)')
  if (!validation.value.destination) m.push('Destination principale')
  if (!validation.value.duration) m.push('Durée (entre 1 et 30 jours)')
  if (!validation.value.price) m.push('Prix par personne')
  if (!validation.value.itinerary) m.push('Titre de chaque journée du programme')
  return m
})

async function save() {
  if (!auth.user) return
  saving.value = true
  errorMsg.value = null
  successMsg.value = null

  try {
    const payload: any = {
      title: title.value.trim(),
      description: description.value.trim(),
      destination_id: destinationId.value,
      duration_days: durationDays.value,
      price_da: priceDa.value,
      created_by: auth.user.id,
      creator_role: auth.operatorType === 'travel_agency' ? 'travel_agency' : 'accommodation_provider',
      composition_mode: 'agency_package',
      itinerary_json: itinerary.value,
      package_inclusions: inclusions.value,
      package_exclusions: exclusions.value,
      included_guide_id: includedGuideId.value || null,
      status: submitForReview.value ? 'pending_review' : 'draft'
    }

    const { error } = await supabase.from('trips').insert(payload)
    if (error) throw error

    successMsg.value = submitForReview.value
      ? 'Package soumis pour validation.'
      : 'Brouillon enregistré.'
    setTimeout(() => router.push('/espace-operateur/produits?type=trips'), 1800)
  } catch (e: any) {
    errorMsg.value = e.message
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div class="djawal-container builder-page">
    <nav class="breadcrumb">
      <router-link to="/espace-operateur/produits?type=trips">← Mes packages</router-link>
    </nav>

    <header class="builder-head">
      <div class="eyebrow">Espace opérateur · Nouveau package</div>
      <h1>Composer un package</h1>
      <p class="lead">
        Décrivez un séjour clés-en-main jour par jour. Ce package sera visible sur Djawal
        comme une promesse complète, distinct des voyages signés par un guide.
      </p>
    </header>

    <v-alert v-if="errorMsg" type="error" variant="tonal" class="mb-4" closable @click:close="errorMsg=null">
      {{ errorMsg }}
    </v-alert>
    <v-alert v-if="successMsg" type="success" variant="tonal" class="mb-4">
      {{ successMsg }}
    </v-alert>

    <v-form @submit.prevent="save">
      <!-- === Identité du package === -->
      <fieldset>
        <legend>Identité du package</legend>
        <v-text-field
          v-model="title"
          label="Titre du package *"
          density="comfortable"
          hint="Ex : 'Découverte du Tassili — 7 jours sur les traces des Touaregs'"
          persistent-hint
        />
        <v-textarea
          v-model="description"
          label="Description courte *"
          rows="3"
          density="comfortable"
          counter="500"
          maxlength="500"
        />
        <v-select
          v-model="destinationId"
          :items="destinations"
          item-title="name"
          item-value="id"
          label="Destination principale *"
          density="comfortable"
        />
      </fieldset>

      <!-- === Logistique === -->
      <fieldset>
        <legend>Logistique</legend>
        <div class="row-2">
          <v-text-field
            v-model.number="durationDays"
            label="Durée (jours) *"
            type="number"
            min="1"
            max="30"
            density="comfortable"
            @blur="onDurationChange"
          />
          <v-text-field
            v-model.number="priceDa"
            label="Prix par personne (DA) *"
            type="number"
            min="0"
            density="comfortable"
          />
        </div>
      </fieldset>

      <!-- === Itinéraire jour par jour === -->
      <fieldset>
        <legend>Programme jour par jour</legend>
        <p class="field-help">
          Décrivez ce qui se passe chaque jour. Le voyageur verra ce programme tel que vous le rédigez.
        </p>
        <div class="days">
          <div v-for="(d, i) in itinerary" :key="i" class="day-card">
            <div class="day-header">
              <span class="day-num">J{{ d.day }}</span>
              <v-text-field
                v-model="d.title"
                label="Titre de la journée *"
                density="comfortable"
                hide-details
                placeholder="Ex : Arrivée Alger, transfert vers Djanet"
              />
            </div>
            <v-textarea
              v-model="d.description"
              label="Description"
              rows="2"
              density="compact"
            />
            <div class="day-meta">
              <v-select
                v-model="d.meals"
                :items="mealOptions"
                label="Repas inclus"
                multiple
                chips
                density="compact"
              />
              <v-text-field
                v-model="d.accommodation"
                label="Hébergement"
                density="compact"
                hint="Ex : Lodge 3*, riad, bivouac…"
              />
            </div>
          </div>
        </div>
      </fieldset>

      <!-- === Inclus / Non inclus === -->
      <fieldset>
        <legend>Inclus / Non inclus</legend>

        <div class="incl-section">
          <strong class="incl-label">✓ Le package comprend</strong>
          <div class="tag-input-row">
            <v-text-field
              v-model="inclusionInput"
              label="Ajouter (ex: transport, pension complète…)"
              density="comfortable"
              hide-details
              @keydown.enter.prevent="addInclusion"
            />
            <v-btn variant="outlined" color="success" @click="addInclusion">+</v-btn>
          </div>
          <div v-if="inclusions.length > 0" class="tags-row">
            <span v-for="s in inclusions" :key="s" class="tag tag-inc">
              ✓ {{ s }}
              <button type="button" class="tag-remove" @click="removeInclusion(s)">×</button>
            </span>
          </div>
        </div>

        <div class="incl-section">
          <strong class="incl-label">✗ Non inclus</strong>
          <div class="tag-input-row">
            <v-text-field
              v-model="exclusionInput"
              label="Ajouter (ex: vol international, assurance…)"
              density="comfortable"
              hide-details
              @keydown.enter.prevent="addExclusion"
            />
            <v-btn variant="outlined" color="error" @click="addExclusion">+</v-btn>
          </div>
          <div v-if="exclusions.length > 0" class="tags-row">
            <span v-for="s in exclusions" :key="s" class="tag tag-exc">
              ✗ {{ s }}
              <button type="button" class="tag-remove" @click="removeExclusion(s)">×</button>
            </span>
          </div>
        </div>
      </fieldset>

      <!-- === Guide inclus (optionnel) === -->
      <fieldset>
        <legend>Guide Djawal inclus (optionnel)</legend>
        <p class="field-help">
          Vous pouvez inclure une prestation de guide certifié Djawal dans votre package.
          Le guide sera affiché sur la fiche publique.
        </p>
        <v-select
          v-model="includedGuideId"
          :items="[{ id: null, display_name: '— Aucun guide inclus —' }, ...availableGuides]"
          item-title="display_name"
          item-value="id"
          label="Guide Senior à inclure"
          density="comfortable"
        />
      </fieldset>

      <!-- === Statut soumission === -->
      <fieldset>
        <legend>Soumission</legend>
        <v-switch
          v-model="submitForReview"
          label="Soumettre pour validation immédiate (sinon enregistré en brouillon)"
          color="primary"
          density="comfortable"
          inset
        />
        <p class="field-help">
          Une fois soumis, un administrateur Djawal vérifie le contenu avant publication.
        </p>
      </fieldset>

      <!-- Feedback champs manquants -->
      <div v-if="missingFields.length > 0 && !saving" class="missing-fields">
        <strong>Pour activer la soumission, complétez :</strong>
        <ul>
          <li v-for="f in missingFields" :key="f">{{ f }}</li>
        </ul>
      </div>

      <div class="actions">
        <v-btn variant="text" @click="router.push('/espace-operateur/produits?type=trips')" :disabled="saving">Annuler</v-btn>
        <v-btn
          type="submit"
          color="primary"
          variant="flat"
          size="large"
          :loading="saving"
          :disabled="!canSubmit"
        >
          {{ submitForReview ? 'Soumettre pour validation' : 'Enregistrer en brouillon' }}
        </v-btn>
      </div>
    </v-form>
  </div>
</template>

<style scoped>
.builder-page {
  max-width: 920px;
  margin: 0 auto;
  padding: var(--space-6) var(--space-5);
}
.breadcrumb { margin-bottom: var(--space-4); }
.breadcrumb a { color: var(--c-primaire); text-decoration: none; font-size: 13px; font-weight: 600; }
.builder-head { margin-bottom: var(--space-5); }
.eyebrow {
  color: var(--c-accent-fort);
  font-size: 12px;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  font-weight: 700;
  margin-bottom: var(--space-2);
}
h1 {
  font-family: var(--font-display);
  font-size: clamp(26px, 4vw, 36px);
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-2);
}
.lead { color: var(--c-texte-doux); }

fieldset {
  border: 1px solid var(--c-gris-clair);
  border-radius: var(--r-md);
  padding: var(--space-4);
  margin-bottom: var(--space-4);
}
legend {
  padding: 0 var(--space-2);
  color: var(--c-accent-fort);
  font-weight: 700;
  font-size: 13px;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}
.field-help {
  color: var(--c-texte-doux);
  font-size: 13px;
  margin-bottom: var(--space-3);
  line-height: 1.5;
}

.row-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--space-3);
}
@media (max-width: 600px) {
  .row-2 { grid-template-columns: 1fr; }
}

/* === Days === */
.days { display: flex; flex-direction: column; gap: var(--space-3); }
.day-card {
  background: var(--c-fond-chaud);
  padding: var(--space-3);
  border-radius: var(--r-md);
  border-left: 3px solid var(--c-accent);
}
.day-header {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  margin-bottom: var(--space-2);
}
.day-num {
  background: var(--c-primaire-profond);
  color: var(--c-fond);
  padding: 6px 12px;
  border-radius: var(--r-sm, 6px);
  font-weight: 700;
  font-family: var(--font-display);
  flex-shrink: 0;
}
.day-header > :last-child { flex: 1; }
.day-meta {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--space-2);
}
@media (max-width: 600px) {
  .day-meta { grid-template-columns: 1fr; }
}

/* === Inclusions === */
.incl-section { margin-bottom: var(--space-4); }
.incl-label {
  display: block;
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-2);
  font-size: 14px;
}
.tag-input-row {
  display: flex;
  gap: var(--space-2);
  align-items: flex-start;
  margin-bottom: var(--space-2);
}
.tag-input-row > :first-child { flex: 1; }
.tags-row {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}
.tag {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 4px 8px 4px 12px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 500;
}
.tag-inc { background: rgba(107, 122, 74, 0.15); color: #4a5630; }
.tag-exc { background: rgba(192, 74, 58, 0.15); color: #8a2f25; }
.tag-remove {
  background: none;
  border: none;
  cursor: pointer;
  font-size: 18px;
  line-height: 1;
  padding: 0 4px;
  color: inherit;
  font-family: inherit;
}

.actions {
  display: flex;
  justify-content: flex-end;
  gap: var(--space-2);
  margin-top: var(--space-4);
}
.missing-fields {
  background: rgba(212, 160, 79, 0.1);
  border-left: 3px solid var(--c-accent);
  padding: var(--space-3) var(--space-4);
  border-radius: 4px;
  margin-bottom: var(--space-3);
  font-size: 13px;
  color: var(--c-texte);
}
.missing-fields strong { display: block; margin-bottom: 6px; color: var(--c-primaire-profond); }
.missing-fields ul { margin: 0; padding-left: 18px; }
.missing-fields li { line-height: 1.6; }
</style>
