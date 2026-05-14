<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { supabase } from '@/lib/supabase'

const route = useRoute()

interface PendingGuide {
  id: string
  display_name: string
  role: string
  region: string | null
  bio: string | null
  email: string | null
  kyc_status: string
  documents: { document_type: string; storage_path: string; signed_url?: string }[]
}

const guides = ref<PendingGuide[]>([])
const loading = ref(true)
const errorMsg = ref<string | null>(null)
const expandedId = ref<string | null>(null)
const filter = ref<'pending' | 'promote' | 'all'>(
  (route.query.filter === 'promote' || route.query.filter === 'all')
    ? (route.query.filter as 'promote' | 'all')
    : 'pending'
)

onMounted(loadGuides)

async function loadGuides() {
  loading.value = true

  let query = supabase
    .from('profiles')
    .select(`
      id, display_name, role, region, bio, kyc_status, kyc_reviewed_at,
      kyc_documents (document_type, storage_path)
    `)
    .in('role', ['guide_senior', 'guide_junior'])

  if (filter.value === 'pending') {
    query = query.eq('kyc_status', 'pending')
  } else if (filter.value === 'promote') {
    // Juniors approuvés prêts à être promus Senior
    query = query.eq('kyc_status', 'approved').eq('role', 'guide_junior')
  }

  const { data, error } = await query.order('id', { ascending: false })

  if (error) {
    errorMsg.value = error.message
    loading.value = false
    return
  }

  guides.value = (data as any[]).map(g => ({
    ...g,
    documents: g.kyc_documents || []
  }))
  loading.value = false
}

async function showDocument(storagePath: string) {
  const { data, error } = await supabase.storage
    .from('kyc-documents')
    .createSignedUrl(storagePath, 300) // 5 min
  if (error) {
    alert('Erreur de chargement : ' + error.message)
    return
  }
  window.open(data.signedUrl, '_blank')
}

async function approveKyc(guide: PendingGuide) {
  if (!confirm(`Approuver le KYC de "${guide.display_name}" ?`)) return
  const { error } = await supabase
    .from('profiles')
    .update({
      kyc_status: 'approved',
      kyc_reviewed_at: new Date().toISOString()
    })
    .eq('id', guide.id)
  if (error) {
    alert('Erreur : ' + error.message)
    return
  }
  await loadGuides()
}

async function rejectKyc(guide: PendingGuide) {
  const reason = prompt(`Raison du rejet pour "${guide.display_name}" (facultatif) :`)
  if (reason === null) return
  const { error } = await supabase
    .from('profiles')
    .update({
      kyc_status: 'rejected',
      kyc_reviewed_at: new Date().toISOString()
    })
    .eq('id', guide.id)
  if (error) {
    alert('Erreur : ' + error.message)
    return
  }
  await loadGuides()
}

async function promoteToSenior(guide: PendingGuide) {
  if (!confirm(`Promouvoir "${guide.display_name}" au statut Guide Senior (publication auto-validée) ?`)) return
  const { error } = await supabase
    .from('profiles')
    .update({ role: 'guide_senior' })
    .eq('id', guide.id)
  if (error) {
    alert('Erreur : ' + error.message)
    return
  }
  await loadGuides()
}

function docTypeLabel(type: string): string {
  const labels: Record<string, string> = {
    id_card_front: 'CNI recto',
    id_card_back: 'CNI verso',
    professional_card: 'Carte pro',
    selfie: 'Selfie'
  }
  return labels[type] || type
}

function roleLabel(role: string): string {
  return role === 'guide_senior' ? '🎒 Senior' : '🎒 Junior'
}
</script>

<template>
  <div class="djawal-container djawal-section">
    <header class="page-header">
      <div>
        <div class="section-eyebrow">Administration · Guides</div>
        <h1>Validation & promotion des guides</h1>
      </div>
      <v-btn-toggle v-model="filter" mandatory @update:model-value="loadGuides">
        <v-btn value="pending">KYC en attente</v-btn>
        <v-btn value="promote">À promouvoir Senior</v-btn>
        <v-btn value="all">Tous</v-btn>
      </v-btn-toggle>
    </header>

    <v-alert v-if="errorMsg" type="error" variant="tonal" class="mb-4">{{ errorMsg }}</v-alert>

    <div v-if="loading" class="loading">Chargement des dossiers…</div>

    <div v-else-if="guides.length === 0" class="empty">
      <div class="empty-icon">✓</div>
      <p v-if="filter === 'pending'">Aucun dossier KYC en attente.</p>
      <p v-else-if="filter === 'promote'">Aucun guide junior prêt à promouvoir Senior.</p>
      <p v-else>Aucun guide enregistré.</p>
    </div>

    <div v-else class="guides-list">
      <article v-for="guide in guides" :key="guide.id" class="guide-card">
        <header class="guide-head" @click="expandedId = expandedId === guide.id ? null : guide.id">
          <div class="guide-info">
            <strong>{{ guide.display_name }}</strong>
            <div class="guide-meta">
              <span class="role-tag">{{ roleLabel(guide.role) }}</span>
              <span v-if="guide.region">📍 {{ guide.region }}</span>
              <span class="docs-count">📎 {{ guide.documents.length }} docs</span>
            </div>
          </div>
          <v-chip
            :color="
              guide.kyc_status === 'approved' ? 'success' :
              guide.kyc_status === 'rejected' ? 'error' :
              'warning'
            "
            size="small"
            variant="tonal"
          >
            {{ guide.kyc_status }}
          </v-chip>
        </header>

        <div v-if="expandedId === guide.id" class="guide-expanded">
          <p v-if="guide.bio" class="bio"><em>"{{ guide.bio }}"</em></p>
          <p v-else class="bio-empty">Pas de bio renseignée.</p>

          <div class="docs-row">
            <button
              v-for="doc in guide.documents"
              :key="doc.document_type"
              class="doc-btn"
              @click="showDocument(doc.storage_path)"
            >
              <span class="doc-icon">📄</span>
              {{ docTypeLabel(doc.document_type) }}
            </button>
          </div>

          <div v-if="guide.kyc_status === 'pending'" class="actions">
            <v-btn color="error" variant="outlined" size="small" @click="rejectKyc(guide)">
              Rejeter
            </v-btn>
            <v-btn color="success" variant="flat" size="small" @click="approveKyc(guide)">
              Approuver
            </v-btn>
          </div>
          <div v-else-if="guide.kyc_status === 'approved' && guide.role === 'guide_junior'" class="actions">
            <v-btn color="primary" variant="outlined" size="small" @click="promoteToSenior(guide)">
              Promouvoir au statut Senior
            </v-btn>
          </div>
        </div>
      </article>
    </div>
  </div>
</template>

<style scoped>
.page-header {
  display: flex; justify-content: space-between; align-items: flex-end;
  margin-bottom: var(--space-6);
  flex-wrap: wrap; gap: var(--space-3);
}
.section-eyebrow {
  color: var(--c-accent-fort); font-size: 13px;
  letter-spacing: 0.2em; text-transform: uppercase; font-weight: 700;
  margin-bottom: var(--space-2);
}
h1 { font-size: clamp(28px, 4vw, 40px); }

.loading, .empty {
  text-align: center; padding: var(--space-8);
  color: var(--c-texte-doux);
}
.empty-icon {
  width: 80px; height: 80px;
  background: var(--c-fond-chaud);
  color: var(--c-secondaire);
  border-radius: 50%;
  margin: 0 auto var(--space-3);
  display: flex; align-items: center; justify-content: center;
  font-size: 36px; font-weight: 700;
}

.guides-list {
  display: flex; flex-direction: column; gap: var(--space-3);
}
.guide-card {
  background: var(--c-surface);
  border-radius: var(--r-md);
  box-shadow: var(--ombre-douce);
  overflow: hidden;
  transition: var(--t-base);
}
.guide-card:hover { box-shadow: var(--ombre-elevee); }
.guide-head {
  display: flex; justify-content: space-between; align-items: center;
  padding: var(--space-4);
  cursor: pointer;
}
.guide-info strong {
  font-size: 16px;
  color: var(--c-primaire-profond);
  display: block;
  margin-bottom: 4px;
}
.guide-meta {
  display: flex; gap: var(--space-3); flex-wrap: wrap;
  font-size: 13px; color: var(--c-texte-doux);
}
.role-tag { font-weight: 600; color: var(--c-primaire); }
.guide-expanded {
  padding: 0 var(--space-4) var(--space-4);
  border-top: 1px solid var(--c-gris-clair);
}
.bio { color: var(--c-texte); margin: var(--space-3) 0; }
.bio-empty { color: var(--c-texte-doux); font-style: italic; margin: var(--space-3) 0; }
.docs-row {
  display: flex; gap: var(--space-2); flex-wrap: wrap;
  margin: var(--space-3) 0;
}
.doc-btn {
  display: flex; align-items: center; gap: 6px;
  padding: 6px 12px;
  background: var(--c-fond-chaud);
  border: 1px solid var(--c-gris-clair);
  border-radius: var(--r-pill);
  font-size: 13px; color: var(--c-primaire);
  cursor: pointer; transition: var(--t-base);
  font-family: inherit;
}
.doc-btn:hover { background: var(--c-accent); color: var(--c-fond); }
.doc-icon { font-size: 14px; }
.actions {
  display: flex; gap: var(--space-2); justify-content: flex-end;
  padding-top: var(--space-3);
  border-top: 1px solid var(--c-gris-clair);
}
</style>
