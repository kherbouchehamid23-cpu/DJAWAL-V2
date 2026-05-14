<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()

type ProductType = 'accommodation' | 'restaurant' | 'activity' | 'trip'
type TableName = 'accommodations' | 'restaurants' | 'activities' | 'trips'

const tableMap: Record<ProductType, TableName> = {
  accommodation: 'accommodations',
  restaurant: 'restaurants',
  activity: 'activities',
  trip: 'trips'
}

const tableLabels: Record<TableName, string> = {
  accommodations: 'Hébergements',
  restaurants: 'Restaurants',
  activities: 'Activités',
  trips: 'Packages / Voyages'
}

const products = ref<any[]>([])
const loading = ref(true)
const destinations = ref<any[]>([])
const errorMsg = ref<string | null>(null)
const successMsg = ref<string | null>(null)

// === Type de produit affiché (query param ?type=accommodations / restaurants / activities / trips) ===
const currentTable = computed<TableName>(() => {
  const t = (route.query.type as string) || ''
  if (t === 'accommodations' && auth.canSubmit('accommodation')) return 'accommodations'
  if (t === 'restaurants' && auth.canSubmit('restaurant')) return 'restaurants'
  if (t === 'activities' && auth.canSubmit('activity')) return 'activities'
  if (t === 'trips' && auth.canSubmit('trip')) return 'trips'
  // Default : première table autorisée
  if (auth.canSubmit('accommodation')) return 'accommodations'
  if (auth.canSubmit('restaurant')) return 'restaurants'
  if (auth.canSubmit('activity')) return 'activities'
  return 'trips'
})

// === Onglets disponibles selon la matrice ===
const availableTabs = computed(() => {
  const tabs: Array<{ value: TableName; label: string; icon: string }> = []
  if (auth.canSubmit('accommodation')) tabs.push({ value: 'accommodations', label: 'Hébergements', icon: '🏨' })
  if (auth.canSubmit('restaurant')) tabs.push({ value: 'restaurants', label: 'Restaurants', icon: '🍽️' })
  if (auth.canSubmit('activity')) tabs.push({ value: 'activities', label: 'Activités', icon: '🥾' })
  if (auth.canSubmit('trip')) tabs.push({ value: 'trips', label: 'Packages', icon: '🧭' })
  return tabs
})

// === Formulaire de soumission (réactif au type courant) ===
const showForm = ref(false)
const form = ref<any>({})
const accommodationTypes = [
  { value: 'hotel', label: 'Hôtel' },
  { value: 'gite', label: 'Gîte rural' },
  { value: 'maison_hote', label: 'Maison d\'hôte' },
  { value: 'auberge_jeunesse', label: 'Auberge de jeunesse' },
  { value: 'lodge', label: 'Lodge / Camp saharien' },
  { value: 'riad', label: 'Riad' },
  { value: 'kasbah_stay', label: 'Séjour en kasbah' },
  { value: 'camping', label: 'Camping' },
  { value: 'eco_lodge', label: 'Éco-lodge' },
  { value: 'refuge_montagne', label: 'Refuge de montagne' }
]
const activityTypes = ['trek', 'artisanat', 'gastronomie', 'culture', '4x4', 'photographie', 'famille', 'aventure']
const cuisineTypes = ['algeroise', 'kabyle', 'mozabite', 'constantinoise', 'tlemcenienne', 'chaouie', 'saharienne', 'traditionnelle']

function resetForm() {
  form.value = {
    name: '',
    description: '',
    destination_id: '',
    accommodation_type: 'hotel',
    activity_type: 'culture',
    cuisine: [],
    duration_hours: null,
    price_da: null,
    difficulty: 'facile',
    star_rating: null,
    amenities: [],
    address: '',
    submit_for_review: true
  }
}

onMounted(async () => {
  resetForm()
  await loadDestinations()
  await loadProducts()
})

watch(currentTable, async () => {
  showForm.value = false
  resetForm()
  await loadProducts()
})

async function loadDestinations() {
  const { data } = await supabase.from('destinations').select('id, name, wilaya').order('name')
  destinations.value = data || []
}

async function loadProducts() {
  if (!auth.user) return
  loading.value = true
  const { data, error } = await supabase
    .from(currentTable.value)
    .select('*, destination:destinations(name)')
    .eq('created_by', auth.user.id)
    .order('created_at', { ascending: false })
  if (error) errorMsg.value = error.message
  products.value = data || []
  loading.value = false
}

async function submitProduct() {
  if (!auth.user) return
  errorMsg.value = null
  successMsg.value = null

  if (!form.value.name || !form.value.description || !form.value.destination_id) {
    errorMsg.value = 'Nom, description et destination sont requis.'
    return
  }

  const tbl = currentTable.value
  const payload: any = {
    name: form.value.name,
    description: form.value.description,
    destination_id: form.value.destination_id,
    created_by: auth.user.id,
    status: form.value.submit_for_review ? 'pending_review' : 'draft'
  }

  if (tbl === 'accommodations') {
    payload.accommodation_type = form.value.accommodation_type
    payload.address = form.value.address || null
    payload.star_rating = form.value.star_rating || null
    payload.amenities = form.value.amenities || []
    payload.coordinates = 'POINT(3.0 36.75)' // fallback Alger — l'opérateur géolocalisera ensuite
  } else if (tbl === 'restaurants') {
    payload.cuisine = form.value.cuisine || []
    payload.coordinates = 'POINT(3.0 36.75)'
  } else if (tbl === 'activities') {
    payload.activity_type = form.value.activity_type
    payload.duration_hours = form.value.duration_hours
    payload.price_da = form.value.price_da
    payload.difficulty = form.value.difficulty
  } else if (tbl === 'trips') {
    payload.title = form.value.name
    payload.duration_days = form.value.duration_hours || 3
    payload.price_da = form.value.price_da
    payload.creator_role = auth.operatorType
    payload.composition_mode = 'agency_package' // par défaut, on prend le mode package pour ops
    delete payload.name
  }

  const { error } = await supabase.from(tbl).insert(payload)
  if (error) {
    errorMsg.value = error.message
    return
  }

  successMsg.value = form.value.submit_for_review
    ? 'Produit soumis pour validation. Un admin va le vérifier.'
    : 'Brouillon enregistré.'
  showForm.value = false
  resetForm()
  await loadProducts()
  setTimeout(() => (successMsg.value = null), 4000)
}

function changeTab(t: TableName) {
  router.replace({ query: { ...route.query, type: t } })
}

function statusLabel(s: string) {
  const labels: Record<string, string> = {
    draft: 'Brouillon',
    pending_review: 'En attente',
    published: 'Publié',
    rejected: 'Refusé'
  }
  return labels[s] || s
}

function statusColor(s: string) {
  if (s === 'published') return 'success'
  if (s === 'pending_review') return 'warning'
  if (s === 'rejected') return 'error'
  return 'default'
}

async function resubmit(p: any) {
  if (!confirm('Resoumettre ce produit pour validation ?')) return
  const { error } = await supabase.from(currentTable.value)
    .update({ status: 'pending_review' }).eq('id', p.id)
  if (error) { errorMsg.value = error.message; return }
  await loadProducts()
}

async function deleteProduct(p: any) {
  if (!confirm(`Supprimer "${p.name || p.title}" ?`)) return
  const { error } = await supabase.from(currentTable.value).delete().eq('id', p.id)
  if (error) { errorMsg.value = error.message; return }
  await loadProducts()
}
</script>

<template>
  <div class="djawal-container products-page">
    <nav class="breadcrumb">
      <router-link to="/espace-operateur">← Tableau de bord</router-link>
    </nav>

    <header class="products-head">
      <div>
        <div class="eyebrow">Espace opérateur · Produits</div>
        <h1>Mes soumissions</h1>
      </div>
      <v-btn
        v-if="auth.kycApproved && currentTable === 'trips'"
        color="primary"
        variant="flat"
        :to="'/espace-operateur/produits/nouveau-package'"
      >
        + Nouveau package
      </v-btn>
      <v-btn
        v-else-if="auth.kycApproved"
        color="primary"
        variant="flat"
        @click="showForm = !showForm"
      >
        {{ showForm ? 'Annuler' : '+ Nouveau' }}
      </v-btn>
      <v-chip v-else color="warning" variant="tonal">
        KYC requis pour soumettre
      </v-chip>
    </header>

    <v-alert v-if="errorMsg" type="error" variant="tonal" class="mb-4" closable>{{ errorMsg }}</v-alert>
    <v-alert v-if="successMsg" type="success" variant="tonal" class="mb-4">{{ successMsg }}</v-alert>

    <!-- Tabs entre types -->
    <div v-if="availableTabs.length > 1" class="tabs">
      <button
        v-for="tab in availableTabs"
        :key="tab.value"
        class="tab"
        :class="{ active: currentTable === tab.value }"
        @click="changeTab(tab.value)"
      >
        <span>{{ tab.icon }}</span> {{ tab.label }}
      </button>
    </div>

    <!-- === Formulaire de soumission === -->
    <section v-if="showForm" class="form-card">
      <h2>Nouvelle soumission — {{ tableLabels[currentTable] }}</h2>

      <v-text-field
        v-model="form.name"
        :label="currentTable === 'trips' ? 'Titre du package *' : 'Nom *'"
        density="comfortable"
      />

      <v-select
        v-if="currentTable === 'accommodations'"
        v-model="form.accommodation_type"
        :items="accommodationTypes"
        item-title="label"
        item-value="value"
        label="Type d'hébergement *"
        density="comfortable"
      />

      <v-select
        v-model="form.destination_id"
        :items="destinations"
        item-title="name"
        item-value="id"
        label="Destination *"
        density="comfortable"
      />

      <v-textarea
        v-model="form.description"
        label="Description *"
        rows="3"
        density="comfortable"
      />

      <template v-if="currentTable === 'accommodations'">
        <v-text-field v-model="form.address" label="Adresse" density="comfortable" />
        <v-text-field v-model.number="form.star_rating" label="Étoiles (1-5, si applicable)" type="number" min="0" max="5" density="comfortable" />
      </template>

      <template v-if="currentTable === 'activities'">
        <v-select v-model="form.activity_type" :items="activityTypes" label="Type d'activité" density="comfortable" />
        <v-text-field v-model.number="form.duration_hours" label="Durée (heures)" type="number" step="0.5" density="comfortable" />
        <v-text-field v-model.number="form.price_da" label="Prix DA / personne" type="number" density="comfortable" />
        <v-select v-model="form.difficulty" :items="['facile','modere','difficile','expert']" label="Difficulté" density="comfortable" />
      </template>

      <template v-if="currentTable === 'restaurants'">
        <v-select v-model="form.cuisine" :items="cuisineTypes" label="Cuisine" multiple chips density="comfortable" />
      </template>

      <template v-if="currentTable === 'trips'">
        <v-text-field v-model.number="form.duration_hours" label="Durée (jours)" type="number" density="comfortable" />
        <v-text-field v-model.number="form.price_da" label="Prix DA / personne" type="number" density="comfortable" />
      </template>

      <v-switch
        v-model="form.submit_for_review"
        label="Soumettre pour validation immédiate (sinon, enregistré en brouillon)"
        color="primary"
        density="comfortable"
        inset
      />

      <div class="form-actions">
        <v-btn variant="text" @click="showForm = false">Annuler</v-btn>
        <v-btn color="primary" variant="flat" @click="submitProduct">
          {{ form.submit_for_review ? 'Soumettre' : 'Enregistrer brouillon' }}
        </v-btn>
      </div>
    </section>

    <!-- === Liste des produits === -->
    <section v-if="loading" class="loading">Chargement…</section>
    <section v-else-if="products.length === 0" class="empty">
      <p>Aucun produit pour cette catégorie.</p>
      <p class="empty-hint">Cliquez sur "+ Nouveau" pour soumettre votre premier produit.</p>
    </section>

    <ul v-else class="products-list">
      <li v-for="p in products" :key="p.id" class="product-row">
        <div class="product-info">
          <strong>{{ p.name || p.title }}</strong>
          <div class="product-meta">
            <span v-if="p.destination">📍 {{ p.destination.name }}</span>
            <span v-if="p.accommodation_type"> · {{ p.accommodation_type }}</span>
            <span v-if="p.activity_type"> · {{ p.activity_type }}</span>
          </div>
          <p v-if="p.review_reason && p.status === 'rejected'" class="reject-reason">
            Motif refus : {{ p.review_reason }}
          </p>
        </div>
        <div class="product-actions">
          <v-chip :color="statusColor(p.status)" size="small" variant="tonal">
            {{ statusLabel(p.status) }}
          </v-chip>
          <v-btn v-if="p.status === 'rejected' || p.status === 'draft'" size="small" variant="outlined" color="primary" @click="resubmit(p)">
            Soumettre
          </v-btn>
          <v-btn v-if="p.status !== 'published'" size="small" variant="text" color="error" @click="deleteProduct(p)">
            Supprimer
          </v-btn>
        </div>
      </li>
    </ul>
  </div>
</template>

<style scoped>
.products-page {
  max-width: 1080px;
  margin: 0 auto;
  padding: var(--space-6) var(--space-5);
}
.breadcrumb { margin-bottom: var(--space-4); }
.breadcrumb a {
  color: var(--c-primaire);
  text-decoration: none;
  font-size: 13px;
  font-weight: 600;
}
.breadcrumb a:hover { color: var(--c-cta); }

.products-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  margin-bottom: var(--space-5);
  flex-wrap: wrap;
  gap: var(--space-3);
}
.eyebrow {
  color: var(--c-accent-fort);
  font-size: 12px;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  font-weight: 700;
}
h1 {
  font-family: var(--font-display);
  font-size: clamp(26px, 4vw, 36px);
  color: var(--c-primaire-profond);
}
h2 {
  font-family: var(--font-display);
  font-size: 22px;
  margin-bottom: var(--space-4);
  color: var(--c-primaire-profond);
}

/* Tabs */
.tabs {
  display: flex;
  gap: var(--space-2);
  margin-bottom: var(--space-4);
  border-bottom: 1px solid var(--c-gris-clair);
  flex-wrap: wrap;
}
.tab {
  padding: var(--space-2) var(--space-4);
  background: none;
  border: none;
  font-family: inherit;
  font-size: 14px;
  cursor: pointer;
  color: var(--c-texte-doux);
  border-bottom: 3px solid transparent;
  transition: var(--t-base);
}
.tab.active {
  color: var(--c-primaire-profond);
  border-bottom-color: var(--c-accent-fort);
  font-weight: 600;
}

/* Form */
.form-card {
  background: var(--c-surface);
  padding: var(--space-5);
  border-radius: var(--r-md);
  box-shadow: var(--ombre-douce);
  margin-bottom: var(--space-5);
  border-left: 4px solid var(--c-accent-fort);
}
.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: var(--space-2);
  margin-top: var(--space-3);
}

/* List */
.loading, .empty {
  text-align: center;
  padding: var(--space-8);
  color: var(--c-texte-doux);
}
.empty-hint { font-size: 13px; margin-top: var(--space-2); }
.products-list {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
}
.product-row {
  background: var(--c-surface);
  padding: var(--space-4);
  border-radius: var(--r-md);
  box-shadow: var(--ombre-douce);
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: var(--space-3);
  flex-wrap: wrap;
}
.product-info strong {
  color: var(--c-primaire-profond);
  font-size: 15px;
  display: block;
  margin-bottom: 4px;
}
.product-meta {
  font-size: 13px;
  color: var(--c-texte-doux);
}
.reject-reason {
  color: #C04A3A;
  font-size: 13px;
  margin-top: 6px;
  font-style: italic;
}
.product-actions {
  display: flex;
  gap: var(--space-2);
  align-items: center;
  flex-wrap: wrap;
}
</style>
