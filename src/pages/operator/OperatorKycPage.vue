<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const auth = useAuthStore()

const companyName = ref('')
const companyRegistration = ref('')
const bio = ref('')
const region = ref('')
const registerFile = ref<File | null>(null)
const uploading = ref(false)
const errorMsg = ref<string | null>(null)
const successMsg = ref<string | null>(null)

const operatorTypeLabels: Record<string, string> = {
  travel_agency: 'agence de voyage',
  restaurant: 'restaurant',
  accommodation_provider: 'établissement d\'hébergement',
  artisan: 'atelier artisanal'
}

const operatorTypeLabel = computed(() =>
  auth.operatorType ? operatorTypeLabels[auth.operatorType] : 'opérateur'
)

const canSubmit = computed(() =>
  companyName.value.trim().length >= 2 &&
  companyRegistration.value.trim().length >= 4 &&
  bio.value.trim().length >= 30 &&
  region.value.trim().length >= 2 &&
  registerFile.value &&
  !uploading.value
)

onMounted(() => {
  if (auth.profile) {
    companyName.value = auth.profile.company_name || ''
    companyRegistration.value = auth.profile.company_registration || ''
    bio.value = auth.profile.bio || ''
    region.value = auth.profile.region || ''
  }
})

function onFileSelected(e: Event) {
  const target = e.target as HTMLInputElement
  registerFile.value = target.files?.[0] || null
}

async function submit() {
  if (!canSubmit.value || !auth.user) return
  uploading.value = true
  errorMsg.value = null
  successMsg.value = null

  try {
    // Upload du registre du commerce dans bucket kyc-documents
    const ext = registerFile.value!.name.split('.').pop()
    const path = `${auth.user.id}/registre-commerce-${Date.now()}.${ext}`

    const { error: uploadErr } = await supabase.storage
      .from('kyc-documents')
      .upload(path, registerFile.value!, { upsert: false })

    if (uploadErr) throw uploadErr

    // Récupérer l'URL signée (private bucket)
    const { data: signed } = await supabase.storage
      .from('kyc-documents')
      .createSignedUrl(path, 60 * 60 * 24 * 365) // 1 an

    // Mise à jour du profil avec les infos pro
    const { error: updErr } = await supabase
      .from('profiles')
      .update({
        company_name: companyName.value.trim(),
        company_registration: companyRegistration.value.trim(),
        commercial_register_url: signed?.signedUrl ?? path,
        bio: bio.value.trim(),
        region: region.value.trim(),
        kyc_status: 'pending' // reset à pending si resoumission après rejet
      })
      .eq('id', auth.user.id)

    if (updErr) throw updErr

    successMsg.value = 'Dossier soumis. Un administrateur va le vérifier sous 48h ouvrées.'
    await auth.fetchProfile()

    setTimeout(() => router.push('/espace-operateur'), 2500)
  } catch (e: any) {
    errorMsg.value = e.message || 'Erreur lors de la soumission.'
  } finally {
    uploading.value = false
  }
}
</script>

<template>
  <div class="djawal-container kyc-page">
    <header class="kyc-head">
      <div class="eyebrow">Espace opérateur · KYC professionnel</div>
      <h1>Dossier de vérification</h1>
      <p class="lead">
        En tant qu'{{ operatorTypeLabel }}, nous avons besoin de quelques pièces pour valider votre compte
        et vous autoriser à publier vos produits sur Djawal.
      </p>
    </header>

    <v-alert v-if="errorMsg" type="error" variant="tonal" class="mb-4" closable>
      {{ errorMsg }}
    </v-alert>
    <v-alert v-if="successMsg" type="success" variant="tonal" class="mb-4">
      {{ successMsg }}
    </v-alert>

    <v-form @submit.prevent="submit" class="kyc-form">
      <fieldset>
        <legend>Identification de l'établissement</legend>

        <v-text-field
          v-model="companyName"
          label="Nom commercial / Raison sociale *"
          density="comfortable"
          prepend-inner-icon="mdi-domain"
          required
        />
        <v-text-field
          v-model="companyRegistration"
          label="Numéro du registre du commerce *"
          density="comfortable"
          prepend-inner-icon="mdi-file-document-outline"
          hint="Format RC algérien (ex : 99/A/0123456)"
          persistent-hint
          required
        />
        <v-text-field
          v-model="region"
          label="Région principale d'activité *"
          density="comfortable"
          prepend-inner-icon="mdi-map-marker-outline"
          required
        />
      </fieldset>

      <fieldset>
        <legend>Présentation publique</legend>
        <v-textarea
          v-model="bio"
          label="Présentation de votre activité *"
          rows="4"
          density="comfortable"
          hint="30 caractères minimum. Sera visible sur votre fiche publique."
          persistent-hint
          counter="500"
          maxlength="500"
          required
        />
      </fieldset>

      <fieldset>
        <legend>Pièce justificative</legend>
        <p class="upload-help">
          Téléversez une copie scannée de votre extrait de registre du commerce (PDF ou image, max 10 Mo).
          Le document sera conservé de manière confidentielle et accessible uniquement aux administrateurs Djawal.
        </p>
        <div class="upload-zone">
          <input
            id="register-file"
            type="file"
            accept=".pdf,.jpg,.jpeg,.png"
            @change="onFileSelected"
          />
          <label for="register-file" class="upload-label">
            <span class="upload-icon">📄</span>
            <span v-if="!registerFile" class="upload-text">Choisir un fichier</span>
            <span v-else class="upload-text">{{ registerFile.name }}</span>
            <span v-if="registerFile" class="upload-size">
              ({{ (registerFile.size / 1024 / 1024).toFixed(2) }} Mo)
            </span>
          </label>
        </div>
      </fieldset>

      <div class="actions">
        <v-btn
          type="submit"
          color="primary"
          variant="flat"
          size="large"
          :loading="uploading"
          :disabled="!canSubmit"
        >
          Soumettre mon dossier
        </v-btn>
      </div>
    </v-form>
  </div>
</template>

<style scoped>
.kyc-page {
  max-width: 720px;
  margin: 0 auto;
  padding: var(--space-6) var(--space-5);
}
.kyc-head { margin-bottom: var(--space-5); }
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
  font-size: clamp(28px, 4vw, 38px);
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-2);
}
.lead { color: var(--c-texte); }

.kyc-form fieldset {
  border: 1px solid var(--c-gris-clair);
  border-radius: var(--r-md);
  padding: var(--space-4);
  margin-bottom: var(--space-4);
}
.kyc-form legend {
  padding: 0 var(--space-2);
  color: var(--c-accent-fort);
  font-weight: 700;
  font-size: 13px;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}
.upload-help {
  color: var(--c-texte-doux);
  font-size: 13px;
  margin-bottom: var(--space-3);
  line-height: 1.5;
}
.upload-zone {
  position: relative;
}
.upload-zone input[type="file"] {
  position: absolute;
  opacity: 0;
  width: 100%;
  height: 100%;
  top: 0;
  left: 0;
  cursor: pointer;
}
.upload-label {
  display: flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-4);
  background: var(--c-fond-chaud);
  border: 2px dashed var(--c-accent);
  border-radius: var(--r-md);
  cursor: pointer;
  transition: var(--t-base);
}
.upload-label:hover { background: var(--c-fond); }
.upload-icon { font-size: 28px; }
.upload-text {
  flex: 1;
  color: var(--c-primaire-profond);
  font-weight: 500;
}
.upload-size {
  color: var(--c-texte-doux);
  font-size: 13px;
}
.actions {
  display: flex;
  justify-content: flex-end;
  margin-top: var(--space-4);
}
</style>
