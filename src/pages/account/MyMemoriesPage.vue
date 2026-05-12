<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'
import ImageUpload from '@/components/admin/ImageUpload.vue'

interface Memory {
  id: string
  quote: string
  photo_url: string | null
  published: boolean
  trip_id: string | null
  destination_id: string | null
  created_at: string
  destinations?: { name: string } | null
  trips?: { title: string } | null
}

interface Destination { id: string; name: string }
interface PublishedTrip { id: string; title: string }

const auth = useAuthStore()
const memories = ref<Memory[]>([])
const destinations = ref<Destination[]>([])
const publishedTrips = ref<PublishedTrip[]>([])
const loading = ref(true)

// Formulaire
const showForm = ref(false)
const editingId = ref<string | null>(null)
const quote = ref('')
const photoUrl = ref('')
const linkType = ref<'destination' | 'trip' | 'none'>('none')
const linkedDestinationId = ref<string | null>(null)
const linkedTripId = ref<string | null>(null)
const saving = ref(false)
const error = ref('')

async function load() {
  loading.value = true
  const [memRes, destRes, tripRes] = await Promise.all([
    supabase
      .from('memories')
      .select('*, destinations(name), trips(title)')
      .eq('author_id', auth.user!.id)
      .order('created_at', { ascending: false }),
    supabase.from('destinations').select('id, name').order('name'),
    supabase.from('trips').select('id, title').eq('status', 'published').order('title')
  ])
  if (memRes.data) memories.value = memRes.data as any[]
  if (destRes.data) destinations.value = destRes.data as Destination[]
  if (tripRes.data) publishedTrips.value = tripRes.data as PublishedTrip[]
  loading.value = false
}

onMounted(load)

function openCreate() {
  editingId.value = null
  quote.value = ''
  photoUrl.value = ''
  linkType.value = 'none'
  linkedDestinationId.value = null
  linkedTripId.value = null
  error.value = ''
  showForm.value = true
}

function openEdit(m: Memory) {
  editingId.value = m.id
  quote.value = m.quote
  photoUrl.value = m.photo_url || ''
  if (m.trip_id) {
    linkType.value = 'trip'
    linkedTripId.value = m.trip_id
    linkedDestinationId.value = null
  } else if (m.destination_id) {
    linkType.value = 'destination'
    linkedDestinationId.value = m.destination_id
    linkedTripId.value = null
  } else {
    linkType.value = 'none'
  }
  error.value = ''
  showForm.value = true
}

async function save() {
  error.value = ''
  const trimmed = quote.value.trim()
  if (trimmed.length < 30) { error.value = 'Le souvenir doit faire au moins 30 caractères.'; return }
  if (trimmed.length > 600) { error.value = 'Maximum 600 caractères.'; return }

  saving.value = true
  const payload = {
    author_id: auth.user!.id,
    quote: trimmed,
    photo_url: photoUrl.value.trim() || null,
    destination_id: linkType.value === 'destination' ? linkedDestinationId.value : null,
    trip_id: linkType.value === 'trip' ? linkedTripId.value : null
  }

  let err
  if (editingId.value) {
    const { error: e } = await supabase.from('memories').update(payload).eq('id', editingId.value)
    err = e
  } else {
    const { error: e } = await supabase.from('memories').insert({ ...payload, published: false })
    err = e
  }
  saving.value = false
  if (err) { error.value = err.message; return }

  showForm.value = false
  await load()
}

async function remove(m: Memory) {
  if (!confirm('Supprimer ce souvenir ? Cette action est définitive.')) return
  const { error: e } = await supabase.from('memories').delete().eq('id', m.id)
  if (e) { alert('Erreur : ' + e.message); return }
  memories.value = memories.value.filter(x => x.id !== m.id)
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
        <h1>✨ Mes souvenirs</h1>
        <p class="lead">
          Vos récits courts (30 à 600 caractères) liés à un voyage ou une destination —
          ils enrichiront la communauté Djawal une fois approuvés.
        </p>
      </div>
      <v-btn color="primary" variant="flat" size="large" @click="openCreate">
        + Nouveau souvenir
      </v-btn>
    </header>

    <!-- FORMULAIRE -->
    <section v-if="showForm" class="form-card">
      <h2>{{ editingId ? 'Modifier le souvenir' : 'Nouveau souvenir' }}</h2>

      <v-alert v-if="error" type="error" variant="tonal" class="mb-3">{{ error }}</v-alert>

      <div class="link-options">
        <label class="radio-tile" :class="{ active: linkType === 'none' }">
          <input type="radio" v-model="linkType" value="none" />
          <span class="radio-icon">📝</span>
          <div>
            <strong>Souvenir libre</strong>
            <small>Sans lien direct</small>
          </div>
        </label>
        <label class="radio-tile" :class="{ active: linkType === 'destination' }">
          <input type="radio" v-model="linkType" value="destination" />
          <span class="radio-icon">📍</span>
          <div>
            <strong>Lié à une destination</strong>
            <small>Ex : Ghardaïa, Tassili…</small>
          </div>
        </label>
        <label class="radio-tile" :class="{ active: linkType === 'trip' }">
          <input type="radio" v-model="linkType" value="trip" />
          <span class="radio-icon">🗺️</span>
          <div>
            <strong>Lié à un voyage</strong>
            <small>Parcours d'un guide</small>
          </div>
        </label>
      </div>

      <v-select
        v-if="linkType === 'destination'"
        v-model="linkedDestinationId"
        :items="destinations.map(d => ({ value: d.id, title: d.name }))"
        label="Destination"
        variant="outlined"
        density="comfortable"
        class="mt-3"
      />
      <v-select
        v-if="linkType === 'trip'"
        v-model="linkedTripId"
        :items="publishedTrips.map(t => ({ value: t.id, title: t.title }))"
        label="Voyage"
        variant="outlined"
        density="comfortable"
        class="mt-3"
      />

      <v-textarea
        v-model="quote"
        label="Votre souvenir (30 à 600 caractères)"
        placeholder="Le silence du Tassili au lever du jour vaut tous les sermons du monde…"
        variant="outlined"
        rows="4"
        counter
        maxlength="600"
        class="mt-3"
      />

      <div class="mt-3">
        <ImageUpload
          v-model="photoUrl"
          bucket="memory-photos"
          label="Photo (optionnel — JPG, PNG, WebP, max 10 Mo)"
        />
      </div>

      <div class="form-actions">
        <v-btn variant="outlined" @click="showForm = false">Annuler</v-btn>
        <v-btn color="primary" variant="flat" :loading="saving" @click="save">
          {{ editingId ? 'Enregistrer' : 'Créer le souvenir' }}
        </v-btn>
      </div>

      <p class="hint">
        Une fois créé, votre souvenir passera en modération.
        Il sera publié sur le mur des témoignages après validation.
      </p>
    </section>

    <!-- LISTE -->
    <div v-if="loading" class="loading">Chargement…</div>

    <div v-else-if="memories.length === 0 && !showForm" class="empty">
      <p>Vous n'avez pas encore partagé de souvenir.</p>
    </div>

    <div v-else class="mem-grid">
      <article v-for="m in memories" :key="m.id" class="mem-card">
        <div
          v-if="m.photo_url"
          class="mem-photo"
          :style="`background-image: url(${m.photo_url})`"
        ></div>
        <div class="mem-body">
          <div class="mem-status">
            <span v-if="m.published" class="badge published">✓ Publié</span>
            <span v-else class="badge pending">⏳ En modération</span>
            <span class="mem-date">{{ fmtDate(m.created_at) }}</span>
          </div>
          <p class="mem-quote">« {{ m.quote }} »</p>
          <div v-if="m.destinations || m.trips" class="mem-link">
            <span v-if="m.trips">🗺️ {{ m.trips.title }}</span>
            <span v-else-if="m.destinations">📍 {{ m.destinations.name }}</span>
          </div>
          <div class="mem-actions">
            <v-btn variant="outlined" size="small" @click="openEdit(m)">✏️ Éditer</v-btn>
            <v-btn variant="text" size="small" color="error" @click="remove(m)">🗑️</v-btn>
          </div>
        </div>
      </article>
    </div>
  </div>
</template>

<style scoped>
.back-link { margin-bottom: var(--space-3); }
.back-link a {
  color: var(--c-primaire);
  text-decoration: none;
  font-weight: 600;
  font-size: 14px;
}
.back-link a:hover { text-decoration: underline; }

.section-eyebrow {
  color: var(--c-accent-fort);
  font-size: 13px; font-weight: 700;
  letter-spacing: 0.2em; text-transform: uppercase;
  margin-bottom: var(--space-2);
}
.page-header {
  display: flex; justify-content: space-between; align-items: flex-start;
  gap: var(--space-4); margin-bottom: var(--space-5);
  flex-wrap: wrap;
}
.page-header h1 { font-size: clamp(28px, 3.5vw, 40px); margin-bottom: 4px; }
.lead { color: var(--c-texte-doux); max-width: 540px; }

.form-card {
  background: var(--c-surface);
  border-radius: var(--r-lg);
  padding: var(--space-5);
  margin-bottom: var(--space-5);
  box-shadow: var(--ombre-douce);
  border-left: 4px solid var(--c-accent);
}
.form-card h2 {
  font-family: var(--font-display);
  font-size: 22px;
  margin-bottom: var(--space-3);
  color: var(--c-primaire-profond);
}

.link-options {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: var(--space-2);
  margin-bottom: var(--space-3);
}
.radio-tile {
  display: flex; align-items: center; gap: 10px;
  padding: var(--space-3);
  background: var(--c-fond-chaud);
  border-radius: var(--r-md);
  cursor: pointer;
  border: 2px solid transparent;
  transition: var(--t-base);
}
.radio-tile.active {
  border-color: var(--c-accent);
  background: rgba(212, 160, 79, 0.1);
}
.radio-tile input { display: none; }
.radio-icon { font-size: 24px; }
.radio-tile strong { display: block; font-size: 14px; color: var(--c-primaire-profond); }
.radio-tile small { color: var(--c-texte-doux); font-size: 12px; }

.form-actions {
  display: flex; gap: var(--space-2);
  justify-content: flex-end;
  margin-top: var(--space-4);
}
.hint {
  margin-top: var(--space-3);
  color: var(--c-texte-doux);
  font-size: 12px;
  font-style: italic;
}

.loading, .empty { text-align: center; padding: var(--space-8); color: var(--c-texte-doux); }

.mem-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: var(--space-4);
}
.mem-card {
  background: var(--c-surface);
  border-radius: var(--r-lg);
  overflow: hidden;
  box-shadow: var(--ombre-douce);
  transition: var(--t-base);
}
.mem-card:hover { transform: translateY(-2px); box-shadow: var(--ombre-elevee); }
.mem-photo {
  height: 160px;
  background-size: cover;
  background-position: center;
}
.mem-body { padding: var(--space-4); }

.mem-status {
  display: flex; justify-content: space-between; align-items: center;
  margin-bottom: var(--space-2);
}
.badge {
  padding: 3px 10px;
  border-radius: var(--r-pill);
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.05em;
  text-transform: uppercase;
}
.badge.published { background: rgba(45, 90, 61, 0.15); color: #2D5A3D; }
.badge.pending { background: rgba(212, 160, 79, 0.15); color: #A6772A; }
.mem-date { font-size: 11px; color: var(--c-texte-doux); }

.mem-quote {
  font-family: var(--font-display);
  font-size: 16px;
  font-style: italic;
  color: var(--c-primaire-profond);
  line-height: 1.5;
  margin-bottom: var(--space-2);
}
.mem-link {
  font-size: 12px;
  color: var(--c-accent-fort);
  margin-bottom: var(--space-2);
}
.mem-actions { display: flex; gap: 6px; }
</style>
