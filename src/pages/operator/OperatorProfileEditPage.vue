<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()

const companyName = ref('')
const displayName = ref('')
const bio = ref('')
const region = ref('')
const slug = ref('')
const specialtiesInput = ref('')
const specialties = ref<string[]>([])
const galleryUrls = ref<string[]>([])
const avatarUrl = ref<string | null>(null)

const uploadingAvatar = ref(false)
const uploadingGallery = ref(false)
const saving = ref(false)
const errorMsg = ref<string | null>(null)
const successMsg = ref<string | null>(null)

const operatorTypeLabels: Record<string, string> = {
  travel_agency: 'Agence de voyage',
  restaurant: 'Restaurant',
  accommodation_provider: 'Hébergeur',
  artisan: 'Artisan traditionnel'
}

const operatorTypeLabel = computed(() =>
  auth.operatorType ? operatorTypeLabels[auth.operatorType] : 'Opérateur'
)

const publicProfileUrl = computed(() =>
  slug.value ? `${window.location.origin}/operateurs/${slug.value}` : null
)

onMounted(() => {
  if (!auth.profile) return
  companyName.value = auth.profile.company_name || ''
  displayName.value = auth.profile.display_name || ''
  bio.value = auth.profile.bio || ''
  region.value = auth.profile.region || ''
  slug.value = auth.profile.slug || ''
  specialties.value = auth.profile.specialties || []
  galleryUrls.value = auth.profile.gallery_urls || []
  avatarUrl.value = auth.profile.avatar_url
})

function addSpecialty() {
  const t = specialtiesInput.value.trim()
  if (!t) return
  if (specialties.value.includes(t)) {
    specialtiesInput.value = ''
    return
  }
  if (specialties.value.length >= 12) {
    errorMsg.value = 'Maximum 12 spécialités.'
    return
  }
  specialties.value.push(t)
  specialtiesInput.value = ''
}

function removeSpecialty(s: string) {
  specialties.value = specialties.value.filter(x => x !== s)
}

async function uploadAvatar(e: Event) {
  const target = e.target as HTMLInputElement
  const file = target.files?.[0]
  if (!file || !auth.user) return

  uploadingAvatar.value = true
  errorMsg.value = null

  try {
    const ext = file.name.split('.').pop()
    const path = `${auth.user.id}/avatar-${Date.now()}.${ext}`
    const { error: upErr } = await supabase.storage
      .from('operator-avatars')
      .upload(path, file, { upsert: true, cacheControl: '3600' })
    if (upErr) throw upErr

    const { data: pub } = supabase.storage.from('operator-avatars').getPublicUrl(path)
    avatarUrl.value = pub.publicUrl
    successMsg.value = 'Avatar mis à jour.'
  } catch (e: any) {
    errorMsg.value = e.message
  } finally {
    uploadingAvatar.value = false
    target.value = ''
  }
}

async function uploadGalleryImage(e: Event) {
  const target = e.target as HTMLInputElement
  const file = target.files?.[0]
  if (!file || !auth.user) return

  if (galleryUrls.value.length >= 12) {
    errorMsg.value = 'Maximum 12 photos dans la galerie.'
    target.value = ''
    return
  }

  uploadingGallery.value = true
  errorMsg.value = null

  try {
    const ext = file.name.split('.').pop()
    const path = `${auth.user.id}/gallery-${Date.now()}.${ext}`
    const { error: upErr } = await supabase.storage
      .from('operator-gallery')
      .upload(path, file, { upsert: false, cacheControl: '3600' })
    if (upErr) throw upErr

    const { data: pub } = supabase.storage.from('operator-gallery').getPublicUrl(path)
    galleryUrls.value.push(pub.publicUrl)
  } catch (e: any) {
    errorMsg.value = e.message
  } finally {
    uploadingGallery.value = false
    target.value = ''
  }
}

function removeGalleryImage(index: number) {
  galleryUrls.value.splice(index, 1)
}

async function save() {
  if (!auth.user) return
  saving.value = true
  errorMsg.value = null
  successMsg.value = null

  // Validation slug : lowercase, alphanum, tirets
  const cleanSlug = slug.value.toLowerCase().replace(/[^a-z0-9-]/g, '').replace(/-+/g, '-').replace(/^-|-$/g, '')

  try {
    const { error } = await supabase
      .from('profiles')
      .update({
        company_name: companyName.value.trim() || null,
        display_name: displayName.value.trim(),
        bio: bio.value.trim() || null,
        region: region.value.trim() || null,
        slug: cleanSlug || null,
        specialties: specialties.value,
        gallery_urls: galleryUrls.value,
        avatar_url: avatarUrl.value
      })
      .eq('id', auth.user.id)

    if (error) throw error

    slug.value = cleanSlug
    successMsg.value = 'Profil mis à jour avec succès.'
    await auth.fetchProfile()
    setTimeout(() => (successMsg.value = null), 4000)
  } catch (e: any) {
    if (e.code === '23505' || e.message?.includes('duplicate')) {
      errorMsg.value = 'Ce slug est déjà pris par un autre opérateur. Choisis-en un autre.'
    } else {
      errorMsg.value = e.message
    }
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <div class="djawal-container edit-page">
    <nav class="breadcrumb">
      <router-link to="/espace-operateur">← Tableau de bord</router-link>
    </nav>

    <header class="edit-head">
      <div>
        <div class="eyebrow">Espace opérateur · Profil public</div>
        <h1>Ma fiche publique</h1>
        <p class="lead">
          Modifiez les informations qui apparaissent sur votre fiche publique
          <span v-if="publicProfileUrl">
            (<a :href="publicProfileUrl" target="_blank" class="link">voir →</a>)
          </span>.
        </p>
      </div>
    </header>

    <v-alert v-if="errorMsg" type="error" variant="tonal" class="mb-4" closable @click:close="errorMsg=null">
      {{ errorMsg }}
    </v-alert>
    <v-alert v-if="successMsg" type="success" variant="tonal" class="mb-4">
      {{ successMsg }}
    </v-alert>

    <v-form @submit.prevent="save">

      <!-- === Avatar === -->
      <fieldset>
        <legend>Photo de profil / logo</legend>
        <div class="avatar-row">
          <div class="avatar-preview">
            <img v-if="avatarUrl" :src="avatarUrl" alt="Avatar" />
            <span v-else>{{ (companyName || displayName || '?')[0].toUpperCase() }}</span>
          </div>
          <div class="avatar-actions">
            <input
              id="avatar-input"
              type="file"
              accept="image/*"
              :disabled="uploadingAvatar"
              @change="uploadAvatar"
              class="hidden-input"
            />
            <label for="avatar-input" class="btn-tonal">
              {{ uploadingAvatar ? 'Téléversement…' : (avatarUrl ? 'Changer l\'image' : 'Téléverser une image') }}
            </label>
            <button v-if="avatarUrl" type="button" class="btn-link" @click="avatarUrl = null">
              Retirer
            </button>
          </div>
        </div>
      </fieldset>

      <!-- === Identité === -->
      <fieldset>
        <legend>Identité publique</legend>

        <v-text-field
          v-model="companyName"
          label="Nom commercial *"
          density="comfortable"
          prepend-inner-icon="mdi-domain"
          hint="Sera affiché en gros sur votre fiche publique"
        />

        <v-text-field
          v-model="displayName"
          label="Nom du contact"
          density="comfortable"
          prepend-inner-icon="mdi-account-outline"
          hint="Nom du gérant, fallback si pas de nom commercial"
        />

        <v-text-field
          v-model="slug"
          label="Slug URL (ex: atelier-de-saida) *"
          density="comfortable"
          prepend-inner-icon="mdi-link-variant"
          :hint="publicProfileUrl ? `Votre URL : ${publicProfileUrl}` : 'lowercase, tirets uniquement'"
          persistent-hint
        />

        <v-text-field
          v-model="region"
          label="Région d'activité"
          density="comfortable"
          prepend-inner-icon="mdi-map-marker-outline"
        />
      </fieldset>

      <!-- === Bio === -->
      <fieldset>
        <legend>Présentation</legend>
        <v-textarea
          v-model="bio"
          label="Bio courte"
          rows="4"
          density="comfortable"
          counter="500"
          maxlength="500"
          hint="Décrivez votre activité en quelques phrases (visible publiquement)"
          persistent-hint
        />
      </fieldset>

      <!-- === Spécialités === -->
      <fieldset>
        <legend>Spécialités (tags)</legend>
        <p class="field-help">
          Ajoutez jusqu'à 12 tags qui décrivent votre activité.
          Ex : « tapis kabyle », « zellige », « cuisine traditionnelle ».
        </p>
        <div class="tag-input-row">
          <v-text-field
            v-model="specialtiesInput"
            label="Ajouter une spécialité…"
            density="comfortable"
            @keydown.enter.prevent="addSpecialty"
          />
          <v-btn variant="outlined" color="primary" @click="addSpecialty">+ Ajouter</v-btn>
        </div>
        <div v-if="specialties.length > 0" class="tags-row">
          <span v-for="s in specialties" :key="s" class="tag">
            {{ s }}
            <button type="button" class="tag-remove" @click="removeSpecialty(s)" aria-label="Retirer">×</button>
          </span>
        </div>
      </fieldset>

      <!-- === Galerie === -->
      <fieldset>
        <legend>Galerie photos ({{ galleryUrls.length }}/12)</legend>
        <p class="field-help">
          Vos photos de meilleure qualité. Visibles sur votre fiche publique.
        </p>

        <div v-if="galleryUrls.length > 0" class="gallery-grid">
          <div v-for="(url, i) in galleryUrls" :key="i" class="gallery-item">
            <img :src="url" alt="" />
            <button type="button" class="gallery-remove" @click="removeGalleryImage(i)">×</button>
          </div>
        </div>

        <input
          id="gallery-input"
          type="file"
          accept="image/*"
          :disabled="uploadingGallery || galleryUrls.length >= 12"
          @change="uploadGalleryImage"
          class="hidden-input"
        />
        <label v-if="galleryUrls.length < 12" for="gallery-input" class="btn-tonal upload-gallery">
          {{ uploadingGallery ? 'Téléversement…' : '+ Ajouter une photo' }}
        </label>
      </fieldset>

      <!-- === Récap type opérateur (read-only) === -->
      <fieldset>
        <legend>Type d'opérateur</legend>
        <div class="readonly-field">
          <strong>{{ operatorTypeLabel }}</strong>
          <p class="field-help">
            Ce type a été défini à l'inscription et ne peut pas être modifié directement.
            Contactez l'administration si vous avez besoin d'un changement.
          </p>
        </div>
      </fieldset>

      <div class="actions">
        <v-btn variant="text" @click="$router.push('/espace-operateur')">Annuler</v-btn>
        <v-btn
          type="submit"
          color="primary"
          variant="flat"
          size="large"
          :loading="saving"
        >
          Enregistrer
        </v-btn>
      </div>
    </v-form>
  </div>
</template>

<style scoped>
.edit-page {
  max-width: 800px;
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
.edit-head { margin-bottom: var(--space-5); }
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
.link { color: var(--c-accent-fort); font-weight: 600; }
.link:hover { text-decoration: underline; }

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

/* === Avatar === */
.avatar-row {
  display: flex;
  align-items: center;
  gap: var(--space-4);
}
.avatar-preview {
  width: 96px;
  height: 96px;
  border-radius: 50%;
  background: linear-gradient(135deg, #D4A04F, #B8862E);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--c-primaire-profond);
  font-family: var(--font-display);
  font-size: 40px;
  font-weight: 600;
  overflow: hidden;
  flex-shrink: 0;
}
.avatar-preview img { width: 100%; height: 100%; object-fit: cover; }
.avatar-actions { display: flex; gap: var(--space-2); align-items: center; flex-wrap: wrap; }
.hidden-input { display: none; }
.btn-tonal {
  display: inline-block;
  padding: 10px 18px;
  background: var(--c-fond-chaud);
  border: 1px solid var(--c-accent);
  color: var(--c-accent-fort);
  border-radius: 999px;
  cursor: pointer;
  font-weight: 600;
  font-size: 13px;
  transition: var(--t-base);
}
.btn-tonal:hover { background: var(--c-accent); color: var(--c-fond); }
.btn-link {
  background: none;
  border: none;
  color: #C04A3A;
  text-decoration: underline;
  cursor: pointer;
  font-size: 13px;
  font-family: inherit;
}

/* === Spécialités === */
.tag-input-row {
  display: flex;
  gap: var(--space-2);
  align-items: flex-start;
  margin-bottom: var(--space-3);
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
  background: rgba(212, 160, 79, 0.18);
  color: var(--c-accent-fort);
  padding: 4px 8px 4px 12px;
  border-radius: 999px;
  font-size: 13px;
  font-weight: 500;
}
.tag-remove {
  background: none;
  border: none;
  color: var(--c-accent-fort);
  cursor: pointer;
  font-size: 18px;
  line-height: 1;
  padding: 0 4px;
  font-family: inherit;
}
.tag-remove:hover { color: #C04A3A; }

/* === Galerie === */
.gallery-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
  gap: var(--space-2);
  margin-bottom: var(--space-3);
}
.gallery-item {
  position: relative;
  aspect-ratio: 1;
}
.gallery-item img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: var(--r-sm, 6px);
}
.gallery-remove {
  position: absolute;
  top: 4px;
  right: 4px;
  width: 24px;
  height: 24px;
  background: rgba(0, 0, 0, 0.6);
  color: white;
  border: none;
  border-radius: 50%;
  cursor: pointer;
  font-size: 14px;
  line-height: 1;
  font-family: inherit;
}
.gallery-remove:hover { background: #C04A3A; }
.upload-gallery {
  display: inline-block;
  margin-top: var(--space-2);
}

.readonly-field {
  background: var(--c-fond-chaud);
  padding: var(--space-3);
  border-radius: var(--r-sm, 6px);
}
.readonly-field strong {
  color: var(--c-primaire-profond);
  font-size: 16px;
  display: block;
  margin-bottom: var(--space-2);
}

.actions {
  display: flex;
  justify-content: flex-end;
  gap: var(--space-2);
  margin-top: var(--space-4);
}
</style>
