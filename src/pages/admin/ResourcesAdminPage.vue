<script setup lang="ts">
import { ref, computed, onMounted, reactive } from 'vue'
import { useRoute } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useGeocode } from '@/composables/useGeocode'
import ImageUpload from '@/components/admin/ImageUpload.vue'

/**
 * Page admin générique pour hotels, sites, restaurants.
 * Le type est déterminé par route.params.type.
 */
const route = useRoute()
const resourceType = computed(() => route.params.type as 'hotels' | 'sites' | 'restaurants')

const configs = {
  hotels: {
    label: 'Hôtels',
    icon: '🏨',
    table: 'hotels',
    extraFields: ['address', 'star_rating', 'amenities'],
    cuisineField: false
  },
  sites: {
    label: 'Sites & Monuments',
    icon: '🏛️',
    table: 'sites',
    extraFields: ['category', 'entry_fee_da', 'best_season'],
    cuisineField: false
  },
  restaurants: {
    label: 'Restaurants',
    icon: '🍽️',
    table: 'restaurants',
    extraFields: ['signature_dishes'],
    cuisineField: true
  }
}

const config = computed(() => configs[resourceType.value])

const resources = ref<any[]>([])
const destinations = ref<any[]>([])
const loading = ref(true)
const dialogOpen = ref(false)
const editing = ref<any>(null)
const errorMsg = ref<string | null>(null)
const successMsg = ref<string | null>(null)

const form = reactive<any>({
  destination_id: '',
  name: '',
  name_ar: null,
  description: '',
  address: null,
  star_rating: null,
  amenities: [],
  category: null,
  entry_fee_da: null,
  best_season: [],
  cuisine: [],
  signature_dishes: [],
  images: [] as string[],
  price_min: null,
  price_max: null,
  coordinates_lat: null,
  coordinates_lng: null
})

const { geocode, loading: geocoding } = useGeocode()

const siteCategories = ['monument', 'musee', 'medina', 'plage', 'montagne', 'oasis', 'parc', 'site_naturel', 'jardin']
const seasons = ['printemps', 'été', 'automne', 'hiver', 'toutes_saisons']
const cuisineTypes = ['algeroise', 'kabyle', 'mozabite', 'constantinoise', 'tlemcenienne', 'chaouie', 'andalouse', 'ottomane', 'francaise', 'italienne', 'mediterraneenne', 'touarègue', 'saharienne', 'poisson', 'traditionnelle', 'montagne']
const amenitiesList = ['wifi', 'piscine', 'restaurant', 'spa', 'parking', 'plage', 'terrasse', 'climatisation', 'hammam', 'jardin', 'famille']

onMounted(async () => {
  await loadDestinations()
  await loadResources()
})

async function loadDestinations() {
  const { data } = await supabase.from('destinations').select('id, name, wilaya').order('name')
  destinations.value = data || []
}

async function loadResources() {
  loading.value = true
  const { data, error } = await supabase
    .from(config.value.table)
    .select('*, destination:destinations(name)')
    .order('name')
  if (!error && data) resources.value = data
  if (error) errorMsg.value = error.message
  loading.value = false
}

function resetForm() {
  Object.assign(form, {
    destination_id: '', name: '', name_ar: null, description: '',
    address: null, star_rating: null, amenities: [],
    category: null, entry_fee_da: null, best_season: [],
    cuisine: [], signature_dishes: [],
    images: [], price_min: null, price_max: null,
    coordinates_lat: null, coordinates_lng: null
  })
}

function openCreate() {
  resetForm()
  editing.value = null
  dialogOpen.value = true
}

function openEdit(r: any) {
  resetForm()
  Object.assign(form, {
    destination_id: r.destination_id,
    name: r.name,
    name_ar: r.name_ar,
    description: r.description,
    address: r.address,
    star_rating: r.star_rating,
    amenities: r.amenities || [],
    category: r.category,
    entry_fee_da: r.entry_fee_da,
    best_season: r.best_season || [],
    cuisine: r.cuisine || [],
    signature_dishes: r.signature_dishes || [],
    images: r.images || []
  })
  editing.value = r
  dialogOpen.value = true
}

async function geocodeAddress() {
  const dest = destinations.value.find(d => d.id === form.destination_id)
  const addr = `${form.address || form.name}, ${dest?.name || ''}`
  const result = await geocode(addr)
  if (result) {
    form.coordinates_lat = result.lat
    form.coordinates_lng = result.lng
  }
}

async function save() {
  errorMsg.value = null
  if (!form.name || !form.destination_id || !form.description) {
    errorMsg.value = 'Nom, destination et description sont requis.'
    return
  }

  const payload: any = {
    destination_id: form.destination_id,
    name: form.name,
    name_ar: form.name_ar || null,
    description: form.description,
    images: form.images,
    validated_at: editing.value?.validated_at ?? new Date().toISOString()
  }

  if (form.coordinates_lat != null && form.coordinates_lng != null) {
    payload.coordinates = `POINT(${form.coordinates_lng} ${form.coordinates_lat})`
  }

  // Champs spécifiques par type
  if (resourceType.value === 'hotels') {
    payload.address = form.address
    payload.star_rating = form.star_rating
    payload.amenities = form.amenities
    if (form.price_min != null && form.price_max != null) {
      payload.price_range_da = `[${form.price_min},${form.price_max})`
    }
  } else if (resourceType.value === 'sites') {
    payload.category = form.category
    payload.entry_fee_da = form.entry_fee_da
    payload.best_season = form.best_season
  } else if (resourceType.value === 'restaurants') {
    payload.cuisine = form.cuisine
    payload.signature_dishes = form.signature_dishes
    if (form.price_min != null && form.price_max != null) {
      payload.price_range_da = `[${form.price_min},${form.price_max})`
    }
  }

  if (editing.value) {
    const { error } = await supabase.from(config.value.table).update(payload).eq('id', editing.value.id)
    if (error) { errorMsg.value = error.message; return }
    successMsg.value = `${config.value.label} modifié(e)`
  } else {
    const { error } = await supabase.from(config.value.table).insert(payload)
    if (error) { errorMsg.value = error.message; return }
    successMsg.value = `${config.value.label} créé(e)`
  }

  dialogOpen.value = false
  await loadResources()
  setTimeout(() => (successMsg.value = null), 3000)
}

async function remove(r: any) {
  if (!confirm(`Supprimer "${r.name}" ?`)) return
  const { error } = await supabase.from(config.value.table).delete().eq('id', r.id)
  if (error) { errorMsg.value = error.message; return }
  await loadResources()
}
</script>

<template>
  <div class="djawal-container djawal-section">
    <header class="page-head">
      <div>
        <div class="eyebrow">Administration · Master Data</div>
        <h1>{{ config.icon }} {{ config.label }}</h1>
        <p class="lead">{{ resources.length }} entrée(s)</p>
      </div>
      <v-btn color="primary" size="large" @click="openCreate" prepend-icon="mdi-plus">
        Nouveau
      </v-btn>
    </header>

    <v-alert v-if="errorMsg" type="error" variant="tonal" class="mb-4" closable @click:close="errorMsg=null">
      {{ errorMsg }}
    </v-alert>
    <v-alert v-if="successMsg" type="success" variant="tonal" class="mb-4">
      {{ successMsg }}
    </v-alert>

    <div v-if="loading" class="loading">Chargement…</div>

    <v-table v-else>
      <thead>
        <tr>
          <th>Nom</th>
          <th>Destination</th>
          <th>Statut</th>
          <th class="text-right">Actions</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="r in resources" :key="r.id">
          <td>
            <strong>{{ r.name }}</strong>
            <div v-if="r.name_ar" class="arabic-mini">{{ r.name_ar }}</div>
          </td>
          <td>{{ r.destination?.name || '—' }}</td>
          <td>
            <v-chip
              :color="r.validated_at ? 'success' : 'warning'"
              size="small"
              variant="tonal"
            >
              {{ r.validated_at ? 'Validé' : 'Brouillon' }}
            </v-chip>
          </td>
          <td class="text-right">
            <v-btn variant="text" size="small" @click="openEdit(r)">Modifier</v-btn>
            <v-btn variant="text" color="error" size="small" @click="remove(r)">Supprimer</v-btn>
          </td>
        </tr>
      </tbody>
    </v-table>

    <v-dialog v-model="dialogOpen" max-width="800" persistent scrollable>
      <v-card>
        <v-card-title>
          {{ editing ? `Modifier — ${config.label}` : `Nouveau — ${config.label}` }}
        </v-card-title>
        <v-card-text>
          <v-row dense>
            <v-col cols="12" md="8">
              <v-text-field v-model="form.name" label="Nom *" density="comfortable" />
            </v-col>
            <v-col cols="12" md="4">
              <v-text-field v-model="form.name_ar" label="Nom arabe" density="comfortable" />
            </v-col>
            <v-col cols="12">
              <v-select
                v-model="form.destination_id"
                :items="destinations"
                item-title="name"
                item-value="id"
                label="Destination *"
                density="comfortable"
              />
            </v-col>
            <v-col cols="12">
              <v-textarea v-model="form.description" label="Description *" rows="3" density="comfortable" />
            </v-col>

            <!-- Hôtels -->
            <template v-if="resourceType === 'hotels'">
              <v-col cols="12"><v-text-field v-model="form.address" label="Adresse" density="comfortable" /></v-col>
              <v-col cols="6"><v-text-field v-model.number="form.star_rating" label="Étoiles (1-5)" type="number" min="0" max="5" density="comfortable" /></v-col>
              <v-col cols="6">
                <v-row dense>
                  <v-col cols="6"><v-text-field v-model.number="form.price_min" label="Prix min DA" type="number" density="comfortable" /></v-col>
                  <v-col cols="6"><v-text-field v-model.number="form.price_max" label="Prix max DA" type="number" density="comfortable" /></v-col>
                </v-row>
              </v-col>
              <v-col cols="12"><v-select v-model="form.amenities" :items="amenitiesList" label="Équipements" multiple chips density="comfortable" /></v-col>
            </template>

            <!-- Sites -->
            <template v-if="resourceType === 'sites'">
              <v-col cols="6"><v-select v-model="form.category" :items="siteCategories" label="Catégorie" density="comfortable" /></v-col>
              <v-col cols="6"><v-text-field v-model.number="form.entry_fee_da" label="Entrée DA (0=gratuit)" type="number" density="comfortable" /></v-col>
              <v-col cols="12"><v-select v-model="form.best_season" :items="seasons" label="Meilleures saisons" multiple chips density="comfortable" /></v-col>
            </template>

            <!-- Restaurants -->
            <template v-if="resourceType === 'restaurants'">
              <v-col cols="12"><v-select v-model="form.cuisine" :items="cuisineTypes" label="Cuisine" multiple chips density="comfortable" /></v-col>
              <v-col cols="12">
                <v-combobox v-model="form.signature_dishes" label="Plats signature" multiple chips density="comfortable" hint="Tapez Entrée après chaque plat" />
              </v-col>
              <v-col cols="6"><v-text-field v-model.number="form.price_min" label="Prix min DA" type="number" density="comfortable" /></v-col>
              <v-col cols="6"><v-text-field v-model.number="form.price_max" label="Prix max DA" type="number" density="comfortable" /></v-col>
            </template>

            <v-col cols="12">
              <v-card variant="outlined" class="pa-3">
                <div class="d-flex justify-space-between align-center mb-2">
                  <strong>Coordonnées GPS</strong>
                  <v-btn size="small" variant="tonal" :loading="geocoding" @click="geocodeAddress">
                    Géolocaliser
                  </v-btn>
                </div>
                <v-row dense>
                  <v-col cols="6"><v-text-field v-model.number="form.coordinates_lat" label="Latitude" type="number" step="0.0001" density="compact" /></v-col>
                  <v-col cols="6"><v-text-field v-model.number="form.coordinates_lng" label="Longitude" type="number" step="0.0001" density="compact" /></v-col>
                </v-row>
              </v-card>
            </v-col>
          </v-row>
        </v-card-text>

        <v-card-actions>
          <v-spacer />
          <v-btn variant="text" @click="dialogOpen = false">Annuler</v-btn>
          <v-btn color="primary" variant="flat" @click="save">{{ editing ? 'Enregistrer' : 'Créer' }}</v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<style scoped>
.page-head { display: flex; justify-content: space-between; align-items: flex-end; margin-bottom: var(--space-6); flex-wrap: wrap; gap: var(--space-3); }
.eyebrow { color: var(--c-accent-fort); font-size: 13px; letter-spacing: 0.2em; text-transform: uppercase; font-weight: 700; margin-bottom: var(--space-2); }
h1 { font-size: clamp(28px, 4vw, 40px); margin-bottom: var(--space-2); }
.lead { color: var(--c-texte-doux); }
.loading { text-align: center; padding: var(--space-8); color: var(--c-texte-doux); }
.arabic-mini { font-family: var(--font-arabic); font-size: 13px; color: var(--c-accent-fort); }
</style>
