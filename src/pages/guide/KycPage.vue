<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const auth = useAuthStore()

type DocType = 'id_card_front' | 'id_card_back' | 'professional_card' | 'selfie'

interface DocSlot {
  type: DocType
  label: string
  description: string
  required: boolean
  uploaded: boolean
  uploading: boolean
  storagePath: string | null
  error: string | null
}

const slots = ref<DocSlot[]>([
  { type: 'id_card_front', label: 'Pièce d\'identité — recto', description: 'CNI, passeport ou titre de séjour', required: true, uploaded: false, uploading: false, storagePath: null, error: null },
  { type: 'id_card_back', label: 'Pièce d\'identité — verso', description: 'Verso de la même pièce', required: true, uploaded: false, uploading: false, storagePath: null, error: null },
  { type: 'professional_card', label: 'Carte professionnelle (optionnel)', description: 'Carte de guide agréé, agence touristique, association', required: false, uploaded: false, uploading: false, storagePath: null, error: null },
  { type: 'selfie', label: 'Selfie avec pièce d\'identité', description: 'Visage clairement visible + pièce tenue à côté', required: true, uploaded: false, uploading: false, storagePath: null, error: null }
])

const allRequiredUploaded = computed(() =>
  slots.value.filter(s => s.required).every(s => s.uploaded)
)

const submitting = ref(false)
const successMsg = ref<string | null>(null)
const errorMsg = ref<string | null>(null)

onMounted(async () => {
  // Charger les documents déjà uploadés
  if (!auth.user) return
  const { data } = await supabase
    .from('kyc_documents')
    .select('document_type, storage_path')
    .eq('profile_id', auth.user.id)
  if (data) {
    for (const doc of data) {
      const slot = slots.value.find(s => s.type === doc.document_type)
      if (slot) {
        slot.uploaded = true
        slot.storagePath = doc.storage_path
      }
    }
  }
})

async function handleFileChange(slot: DocSlot, event: Event) {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  if (!file || !auth.user) return

  // Validation taille (5 MB max)
  if (file.size > 5 * 1024 * 1024) {
    slot.error = 'Fichier trop volumineux (5 Mo max)'
    return
  }

  slot.uploading = true
  slot.error = null

  const ext = file.name.split('.').pop()?.toLowerCase() || 'jpg'
  const path = `${auth.user.id}/${slot.type}.${ext}`

  // Upload (overwrite si existe déjà)
  const { error: upErr } = await supabase.storage
    .from('kyc-documents')
    .upload(path, file, { upsert: true })

  if (upErr) {
    slot.uploading = false
    slot.error = upErr.message
    return
  }

  // Enregistrer en BDD
  const { error: dbErr } = await supabase
    .from('kyc_documents')
    .upsert({
      profile_id: auth.user.id,
      document_type: slot.type,
      storage_path: path
    }, { onConflict: 'profile_id,document_type' })

  if (dbErr) {
    slot.uploading = false
    slot.error = dbErr.message
    return
  }

  slot.uploaded = true
  slot.storagePath = path
  slot.uploading = false
}

async function handleSubmit() {
  if (!auth.user || !allRequiredUploaded.value) return
  submitting.value = true
  errorMsg.value = null
  successMsg.value = null

  // Marquer le KYC comme "en attente de revue" (déjà le cas par défaut, mais on confirme la soumission)
  const { error } = await supabase
    .from('profiles')
    .update({ kyc_status: 'pending' })
    .eq('id', auth.user.id)

  submitting.value = false
  if (error) {
    errorMsg.value = error.message
    return
  }
  successMsg.value = 'Dossier soumis ! Notre équipe vous répond sous 48h.'
  await auth.fetchProfile()
  setTimeout(() => router.push('/mon-espace'), 2500)
}
</script>

<template>
  <div class="djawal-container djawal-section">
    <header class="kyc-header">
      <div class="section-eyebrow">Vérification d'identité</div>
      <h1>Devenir guide vérifié sur Djawal.</h1>
      <p class="lead">
        Pour publier vos parcours et accueillir des voyageurs, nous devons vérifier votre
        identité. Ce dossier est confidentiel et n'est consulté que par notre équipe de
        modération.
      </p>
    </header>

    <v-alert v-if="errorMsg" type="error" variant="tonal" class="mb-4">{{ errorMsg }}</v-alert>
    <v-alert v-if="successMsg" type="success" variant="tonal" class="mb-4">{{ successMsg }}</v-alert>

    <div class="kyc-grid">
      <div
        v-for="slot in slots"
        :key="slot.type"
        class="doc-card"
        :class="{ uploaded: slot.uploaded, required: slot.required && !slot.uploaded }"
      >
        <header class="doc-head">
          <div>
            <div class="doc-label">
              {{ slot.label }}
              <span v-if="!slot.required" class="optional-tag">Optionnel</span>
            </div>
            <div class="doc-desc">{{ slot.description }}</div>
          </div>
          <div class="doc-status">
            <v-icon v-if="slot.uploaded" color="success" size="28">mdi-check-circle</v-icon>
            <v-progress-circular v-else-if="slot.uploading" indeterminate size="24" />
            <v-icon v-else color="grey-darken-1" size="28">mdi-upload</v-icon>
          </div>
        </header>

        <v-alert v-if="slot.error" type="error" variant="tonal" density="compact" class="mt-2">
          {{ slot.error }}
        </v-alert>

        <label class="upload-trigger">
          <input
            type="file"
            accept="image/jpeg,image/png,application/pdf"
            :disabled="slot.uploading"
            @change="(e) => handleFileChange(slot, e)"
          />
          <span v-if="slot.uploaded">Remplacer le fichier</span>
          <span v-else>Choisir un fichier (JPG, PNG, PDF — max 5 Mo)</span>
        </label>
      </div>
    </div>

    <div class="kyc-summary">
      <div class="summary-info">
        <strong>{{ slots.filter(s => s.uploaded).length }} / {{ slots.filter(s => s.required).length }}</strong>
        documents requis uploadés
      </div>
      <v-btn
        color="primary"
        size="large"
        variant="flat"
        :disabled="!allRequiredUploaded || submitting"
        :loading="submitting"
        @click="handleSubmit"
      >
        Soumettre mon dossier
      </v-btn>
    </div>

    <aside class="kyc-info">
      <h3>Confidentialité et délai</h3>
      <ul>
        <li><strong>Sécurité :</strong> vos documents sont stockés chiffrés. Seul le Super Administrateur peut y accéder.</li>
        <li><strong>Délai :</strong> réponse sous 48h ouvrées (généralement le jour même).</li>
        <li><strong>Conformité :</strong> conformément au RGPD, vous pouvez demander la suppression de votre dossier à tout moment.</li>
      </ul>
    </aside>
  </div>
</template>

<style scoped>
.kyc-header { max-width: 720px; margin-bottom: var(--space-7); }
.section-eyebrow {
  color: var(--c-accent-fort); font-size: 13px;
  letter-spacing: 0.2em; text-transform: uppercase; font-weight: 700;
  margin-bottom: var(--space-2);
}
.kyc-header h1 { font-size: clamp(32px, 4vw, 44px); margin-bottom: var(--space-3); }
.lead { font-size: 16px; color: var(--c-texte-doux); }

.kyc-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: var(--space-4);
  margin-bottom: var(--space-6);
}
.doc-card {
  background: var(--c-surface);
  border: 2px solid var(--c-gris-clair);
  border-radius: var(--r-md);
  padding: var(--space-4);
  transition: var(--t-base);
}
.doc-card.required { border-color: var(--c-accent); }
.doc-card.uploaded { border-color: var(--c-secondaire); background: rgba(107, 122, 74, 0.05); }

.doc-head {
  display: flex; justify-content: space-between; align-items: flex-start;
  gap: var(--space-3); margin-bottom: var(--space-2);
}
.doc-label {
  font-weight: 600; color: var(--c-primaire-profond);
  font-size: 15px; margin-bottom: 2px;
}
.optional-tag {
  font-size: 11px; color: var(--c-texte-doux);
  background: var(--c-fond-chaud);
  padding: 2px 8px; border-radius: var(--r-pill);
  margin-left: 6px;
}
.doc-desc { font-size: 13px; color: var(--c-texte-doux); }
.doc-status { flex-shrink: 0; }

.upload-trigger {
  display: block;
  margin-top: var(--space-3);
  padding: var(--space-3);
  background: var(--c-fond-chaud);
  border: 1px dashed var(--c-gris-pierre);
  border-radius: var(--r-sm);
  text-align: center;
  font-size: 13px;
  color: var(--c-texte-doux);
  cursor: pointer;
  transition: var(--t-base);
}
.upload-trigger:hover { background: var(--c-fond); border-color: var(--c-accent); }
.upload-trigger input[type="file"] { display: none; }

.kyc-summary {
  display: flex; justify-content: space-between; align-items: center;
  padding: var(--space-5);
  background: var(--c-fond-chaud);
  border-radius: var(--r-lg);
  border-left: 4px solid var(--c-accent);
  margin-bottom: var(--space-5);
  flex-wrap: wrap;
  gap: var(--space-3);
}
.summary-info { font-size: 16px; color: var(--c-primaire-profond); }
.summary-info strong {
  font-family: var(--font-display);
  font-size: 22px; color: var(--c-primaire);
}

.kyc-info {
  background: var(--c-surface);
  padding: var(--space-5);
  border-radius: var(--r-lg);
  box-shadow: var(--ombre-douce);
}
.kyc-info h3 {
  font-family: var(--font-display);
  font-size: 22px; margin-bottom: var(--space-3);
}
.kyc-info ul { list-style: none; padding: 0; }
.kyc-info li {
  padding: 8px 0; font-size: 14px; color: var(--c-texte);
  padding-left: 22px; position: relative;
}
.kyc-info li::before {
  content: '◆'; position: absolute; left: 0;
  color: var(--c-accent); font-size: 11px; top: 12px;
}
.kyc-info strong { color: var(--c-primaire-profond); }

@media (max-width: 720px) {
  .kyc-grid { grid-template-columns: 1fr; }
}
</style>
