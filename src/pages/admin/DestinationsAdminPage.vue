<script setup lang="ts">
import { ref, onMounted, reactive } from 'vue'
import { supabase } from '@/lib/supabase'
import { useGeocode } from '@/composables/useGeocode'
import ImageUpload from '@/components/admin/ImageUpload.vue'

interface Destination {
  id?: string
  name: string
  name_ar: string | null
  slug: string
  wilaya: string
  cultural_theme: 'saharien' | 'mauresque' | 'aures'
  description: string
  hero_image_url: string | null
  coordinates_lat: number | null
  coordinates_lng: number | null
}

const destinations = ref<any[]>([])
const loading = ref(true)
const dialogOpen = ref(false)
const editing = ref<Destination | null>(null)
const errorMsg = ref<string | null>(null)
const successMsg = ref<string | null>(null)

const form = reactive<Destination>({
  name: '',
  name_ar: null,
  slug: '',
  wilaya: '',
  cultural_theme: 'mauresque',
  description: '',
  hero_image_url: null,
  coordinates_lat: null,
  coordinates_lng: null
})

const { geocode, loading: geocoding, error: geocodeError } = useGeocode()

const themes = [
  { value: 'saharien', label: '🏜️ Saharien', color: '#D4A04F' },
  { value: 'mauresque', label: '🏛️ Mauresque', color: '#1B4965' },
  { value: 'aures', label: '⛰️ Aurès', color: '#2D5A3D' }
]

onMounted(loadDestinations)

async function loadDestinations() {
  loading.value = true
  const { data, error } = await supabase
    .from('destinations')
    .select('id, name, name_ar, slug, wilaya, cultural_theme, description, hero_image_url, coordinates, created_at')
    .order('name')
  if (!error && data) destinations.value = data
  if (error) errorMsg.value = error.message
  loading.value = false
}

function openCreate() {
  Object.assign(form, {
    name: '', name_ar: null, slug: '', wilaya: '',
    cultural_theme: 'mauresque', description: '',
    hero_image_url: null, coordinates_lat: null, coordinates_lng: null
  })
  editing.value = null
  dialogOpen.value = true
}

function openEdit(dest: any) {
  Object.assign(form, {
    name: dest.name,
    name_ar: dest.name_ar,
    slug: dest.slug,
    wilaya: dest.wilaya,
    cultural_theme: dest.cultural_theme,
    description: dest.description,
    hero_image_url: dest.hero_image_url,
    coordinates_lat: null,
    coordinates_lng: null
  })
  editing.value = dest
  dialogOpen.value = true
}

function slugify(text: string): string {
  return text.toLowerCase()
    .normalize('NFD').replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
}

function onNameChange() {
  if (!editing.value) form.slug = slugify(form.name)
}

async function geocodeAddress() {
  const addr = `${form.name}, ${form.wilaya}`
  const result = await geocode(addr)
  if (result) {
    form.coordinates_lat = result.lat
    form.coordinates_lng = result.lng
    if (!form.wilaya && result.wilaya) form.wilaya = result.wilaya
  }
}

async function save() {
  errorMsg.value = null

  if (!form.name || !form.wilaya || !form.description) {
    errorMsg.value = 'Nom, wilaya et description sont requis.'
    return
  }

  const payload: any = {
    name: form.name,
    name_ar: form.name_ar || null,
    slug: form.slug || slugify(form.name),
    wilaya: form.wilaya,
    cultural_theme: form.cultural_theme,
    description: form.description,
    hero_image_url: form.hero_image_url
  }
  if (form.coordinates_lat != null && form.coordinates_lng != null) {
    payload.coordinates = `POINT(${form.coordinates_lng} ${form.coordinates_lat})`
  }

  if (editing.value && editing.value.id) {
    const { error } = await supabase.from('destinations').update(payload).eq('id', editing.value.id)
    if (error) { errorMsg.value = error.message; return }
    successMsg.value = 'Destination modifiée'
  } else {
    const { error } = await supabase.from('destinations').insert(payload)
    if (error) { errorMsg.value = error.message; return }
    successMsg.value = 'Destination créée'
  }

  dialogOpen.value = false
  await loadDestinations()
  setTimeout(() => (successMsg.value = null), 3000)
}

async function remove(dest: any) {
  if (!confirm(`Supprimer "${dest.name}" ?\nTous les hébergements, sites et restaurants associés seront supprimés en cascade.`)) return
  const { error } = await supabase.from('destinations').delete().eq('id', dest.id)
  if (error) { errorMsg.value = error.message; return }
  await loadDestinations()
}
</script>

<template>
  <div class="djawal-container djawal-section">
    <nav class="admin-breadcrumb">
      <router-link to="/admin">← Retour à l'administration</router-link>
    </nav>
    <header class="page-head">
      <div>
        <div class="eyebrow">Administration · Master Data</div>
        <h1>Destinations</h1>
        <p class="lead">{{ destinations.length }} destination(s) — base des thèmes culturels et des parcours.</p>
      </div>
      <v-btn color="primary" size="large" @click="openCreate" prepend-icon="mdi-plus">
        Nouvelle destination
      </v-btn>
    </header>

    <v-alert v-if="errorMsg" type="error" variant="tonal" class="mb-4" closable @click:close="errorMsg=null">
      {{ errorMsg }}
    </v-alert>
    <v-alert v-if="successMsg" type="success" variant="tonal" class="mb-4">
      {{ successMsg }}
    </v-alert>

    <div v-if="loading" class="loading">Chargement…</div>

    <div v-else class="dest-grid">
      <article
        v-for="dest in destinations"
        :key="dest.id"
        class="dest-card"
        :data-theme="dest.cultural_theme"
      >
        <div v-if="dest.hero_image_url" class="card-img" :style="{backgroundImage: `url(${dest.hero_image_url})`}" />
        <div v-else class="card-img placeholder">
          <span>📍</span>
        </div>

        <div class="card-body">
          <header class="card-head">
            <h3>{{ dest.name }}</h3>
            <span class="theme-badge" :data-theme="dest.cultural_theme">
              {{ themes.find(t => t.value === dest.cultural_theme)?.label }}
            </span>
          </header>
          <div v-if="dest.name_ar" class="card-arabic">{{ dest.name_ar }}</div>
          <div class="card-meta">📍 {{ dest.wilaya }}</div>
          <p class="card-desc">{{ dest.description }}</p>

          <div class="card-actions">
            <v-btn variant="text" size="small" @click="openEdit(dest)">Modifier</v-btn>
            <v-btn variant="text" color="error" size="small" @click="remove(dest)">Supprimer</v-btn>
          </div>
        </div>
      </article>
    </div>

    <!-- Dialog Create/Edit -->
    <v-dialog v-model="dialogOpen" max-width="720" persistent>
      <v-card>
        <v-card-title>
          {{ editing ? 'Modifier la destination' : 'Nouvelle destination' }}
        </v-card-title>

        <v-card-text>
          <v-row dense>
            <v-col cols="12" md="8">
              <v-text-field
                v-model="form.name"
                label="Nom *"
                density="comfortable"
                hint="Ex : Tassili, Casbah d'Alger, Tipaza…"
                @blur="onNameChange"
              />
            </v-col>
            <v-col cols="12" md="4">
              <v-text-field
                v-model="form.name_ar"
                label="Nom arabe"
                density="comfortable"
                style="font-family: 'Amiri', serif;"
              />
            </v-col>
            <v-col cols="12" md="8">
              <v-text-field v-model="form.wilaya" label="Wilaya *" density="comfortable" />
            </v-col>
            <v-col cols="12" md="4">
              <v-select
                v-model="form.cultural_theme"
                :items="themes"
                item-title="label"
                item-value="value"
                label="Thème culturel *"
                density="comfortable"
              />
            </v-col>
            <v-col cols="12">
              <v-textarea
                v-model="form.description"
                label="Description *"
                density="comfortable"
                rows="3"
                counter
                maxlength="500"
              />
            </v-col>
            <v-col cols="12">
              <v-text-field v-model="form.slug" label="Slug URL" density="comfortable" hint="Auto-généré depuis le nom" />
            </v-col>

            <v-col cols="12">
              <ImageUpload v-model="form.hero_image_url" label="Image hero" />
            </v-col>

            <v-col cols="12">
              <v-card variant="outlined" class="pa-3">
                <div class="d-flex justify-space-between align-center mb-2">
                  <strong>Coordonnées GPS</strong>
                  <v-btn
                    size="small"
                    variant="tonal"
                    :loading="geocoding"
                    @click="geocodeAddress"
                    prepend-icon="mdi-map-marker-radius"
                  >
                    Géolocaliser via Nominatim
                  </v-btn>
                </div>
                <v-row dense>
                  <v-col cols="6">
                    <v-text-field
                      v-model.number="form.coordinates_lat"
                      label="Latitude"
                      type="number"
                      step="0.0001"
                      density="compact"
                    />
                  </v-col>
                  <v-col cols="6">
                    <v-text-field
                      v-model.number="form.coordinates_lng"
                      label="Longitude"
                      type="number"
                      step="0.0001"
                      density="compact"
                    />
                  </v-col>
                </v-row>
                <p v-if="geocodeError" class="text-error text-caption">{{ geocodeError }}</p>
              </v-card>
            </v-col>
          </v-row>
        </v-card-text>

        <v-card-actions>
          <v-spacer />
          <v-btn variant="text" @click="dialogOpen = false">Annuler</v-btn>
          <v-btn color="primary" variant="flat" @click="save">
            {{ editing ? 'Enregistrer' : 'Créer' }}
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </div>
</template>

<style scoped>
.admin-breadcrumb {
  margin-bottom: var(--space-4);
}
.admin-breadcrumb a {
  color: var(--c-primaire);
  font-weight: 600;
  text-decoration: none;
  font-size: 14px;
}
.admin-breadcrumb a:hover {
  color: var(--c-cta);
  text-decoration: underline;
}
.page-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  margin-bottom: var(--space-6);
  flex-wrap: wrap;
  gap: var(--space-3);
}
.eyebrow {
  color: var(--c-accent-fort);
  font-size: 13px;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  font-weight: 700;
  margin-bottom: var(--space-2);
}
h1 { font-size: clamp(28px, 4vw, 40px); margin-bottom: var(--space-2); }
.lead { color: var(--c-texte-doux); }
.loading { text-align: center; padding: var(--space-8); color: var(--c-texte-doux); }

.dest-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: var(--space-4);
}
.dest-card {
  background: var(--c-surface);
  border-radius: var(--r-lg);
  overflow: hidden;
  box-shadow: var(--ombre-douce);
  transition: var(--t-base);
  border-top: 4px solid var(--c-primaire);
}
.dest-card[data-theme="saharien"] { border-top-color: #D4A04F; }
.dest-card[data-theme="mauresque"] { border-top-color: #1B4965; }
.dest-card[data-theme="aures"] { border-top-color: #2D5A3D; }
.dest-card:hover { transform: translateY(-3px); box-shadow: var(--ombre-elevee); }

.card-img {
  height: 160px;
  background: linear-gradient(135deg, #D4A04F, #C97050);
  background-size: cover;
  background-position: center;
}
.card-img.placeholder {
  display: flex; align-items: center; justify-content: center;
  font-size: 48px; color: white; opacity: 0.7;
}

.card-body { padding: var(--space-4); }
.card-head {
  display: flex; justify-content: space-between; align-items: flex-start;
  gap: var(--space-2);
  margin-bottom: 4px;
}
.card-head h3 {
  font-family: var(--font-display);
  font-size: 22px;
  color: var(--c-primaire-profond);
}
.card-arabic {
  font-family: var(--font-arabic);
  color: var(--c-accent-fort);
  font-size: 16px;
  margin-bottom: 6px;
}
.theme-badge {
  font-size: 10px;
  padding: 3px 8px;
  border-radius: var(--r-pill);
  font-weight: 700;
  letter-spacing: 0.05em;
  white-space: nowrap;
}
.theme-badge[data-theme="saharien"] { background: #FBEAD1; color: #8B4A2C; }
.theme-badge[data-theme="mauresque"] { background: #E0EAF1; color: #1B4965; }
.theme-badge[data-theme="aures"] { background: #DDE5DD; color: #2D5A3D; }
.card-meta {
  font-size: 13px;
  color: var(--c-texte-doux);
  margin-bottom: var(--space-2);
}
.card-desc {
  font-size: 13px;
  color: var(--c-texte);
  line-height: 1.5;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
  margin-bottom: var(--space-3);
}
.card-actions {
  display: flex;
  justify-content: flex-end;
  gap: 4px;
  padding-top: var(--space-2);
  border-top: 1px solid var(--c-gris-clair);
}
</style>
