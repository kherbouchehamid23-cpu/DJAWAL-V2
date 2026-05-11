<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()

interface TripSummary {
  id: string
  title: string
  status: string
  cover_image_url: string | null
  duration_days: number
  destinations?: { name: string } | null
}

const recentTrips = ref<TripSummary[]>([])
const counts = ref({ draft: 0, pending: 0, published: 0 })
const loading = ref(true)

onMounted(async () => {
  const { data } = await supabase
    .from('trips')
    .select('id, title, status, cover_image_url, duration_days, destinations(name)')
    .eq('created_by', auth.user!.id)
    .order('created_at', { ascending: false })
    .limit(5)
  recentTrips.value = (data as any) || []

  const { data: all } = await supabase
    .from('trips')
    .select('status')
    .eq('created_by', auth.user!.id)
  for (const t of (all || [])) {
    if (t.status === 'draft') counts.value.draft++
    else if (t.status === 'pending_review') counts.value.pending++
    else if (t.status === 'published') counts.value.published++
  }
  loading.value = false
})

function statusLabel(s: string) {
  return { draft: 'Brouillon', pending_review: 'En modération', published: 'Publié', rejected: 'Refusé' }[s] || s
}
function statusColor(s: string) {
  return { draft: '#8B8680', pending_review: '#D4A04F', published: '#2D5A3D', rejected: '#C04A3A' }[s] || '#666'
}
</script>

<template>
  <div class="djawal-container djawal-section">
    <div class="section-eyebrow">Espace Guide</div>
    <h1>Bienvenue, {{ auth.profile?.display_name }}.</h1>

    <v-alert v-if="auth.needsKyc" type="warning" variant="tonal" class="mt-4" prominent>
      <template #title>Vérification KYC en attente</template>
      Vous devez compléter votre dossier KYC avant de pouvoir publier des parcours.
      <template #append>
        <router-link to="/espace-guide/kyc">
          <v-btn color="warning" variant="flat" size="small">Compléter</v-btn>
        </router-link>
      </template>
    </v-alert>

    <v-alert
      v-else-if="auth.profile?.kyc_status === 'approved'"
      type="success"
      variant="tonal"
      class="mt-4"
    >
      Votre compte est vérifié — vous pouvez créer et publier des parcours.
      {{ auth.isGuideSenior ? 'Vos publications sont auto-validées (Senior).' : 'Vos publications passent par une modération.' }}
    </v-alert>

    <!-- STATS RAPIDES -->
    <section class="stats-row">
      <div class="stat-card">
        <div class="stat-num">{{ counts.draft }}</div>
        <div class="stat-label">Brouillons</div>
      </div>
      <div class="stat-card pending">
        <div class="stat-num">{{ counts.pending }}</div>
        <div class="stat-label">En modération</div>
      </div>
      <div class="stat-card published">
        <div class="stat-num">{{ counts.published }}</div>
        <div class="stat-label">Publiés</div>
      </div>
      <router-link to="/espace-guide/voyages/nouveau" class="stat-cta">
        <div class="stat-cta-icon">＋</div>
        <div>Créer un voyage</div>
      </router-link>
    </section>

    <section class="djawal-section">
      <div class="section-head">
        <h2>Mes derniers parcours</h2>
        <router-link to="/espace-guide/voyages" class="link-all">
          Voir tout →
        </router-link>
      </div>

      <div v-if="loading" class="placeholder-text">Chargement…</div>

      <div v-else-if="recentTrips.length === 0" class="empty-state">
        <p>Vous n'avez pas encore créé de voyage.</p>
        <router-link to="/espace-guide/voyages/nouveau">
          <v-btn color="primary" variant="flat" size="large">Créer mon premier voyage</v-btn>
        </router-link>
      </div>

      <div v-else class="recent-grid">
        <router-link
          v-for="t in recentTrips"
          :key="t.id"
          :to="`/espace-guide/voyages/${t.id}`"
          class="recent-card"
        >
          <div
            class="recent-cover"
            :style="t.cover_image_url ? `background-image: url(${t.cover_image_url})` : ''"
          >
            <span class="recent-status" :style="`background: ${statusColor(t.status)}`">
              {{ statusLabel(t.status) }}
            </span>
          </div>
          <div class="recent-body">
            <h4>{{ t.title }}</h4>
            <div class="recent-meta">📍 {{ t.destinations?.name || '—' }} · {{ t.duration_days }}j</div>
          </div>
        </router-link>
      </div>
    </section>
  </div>
</template>

<style scoped>
.section-eyebrow {
  color: var(--c-accent-fort); font-size: 13px;
  letter-spacing: 0.2em; text-transform: uppercase; font-weight: 700;
  margin-bottom: var(--space-2);
}
h1 { font-size: clamp(32px, 4vw, 44px); margin-bottom: var(--space-4); }
h2 { font-size: 28px; }

.stats-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: var(--space-3);
  margin: var(--space-5) 0;
}
.stat-card {
  background: var(--c-surface);
  border-radius: var(--r-lg);
  padding: var(--space-4);
  text-align: center;
  box-shadow: var(--ombre-douce);
  border-left: 4px solid var(--c-gris-clair);
}
.stat-card.pending { border-left-color: #D4A04F; }
.stat-card.published { border-left-color: #2D5A3D; }
.stat-num {
  font-family: var(--font-display);
  font-size: 36px;
  font-weight: 700;
  color: var(--c-primaire-profond);
}
.stat-label {
  font-size: 13px;
  color: var(--c-texte-doux);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
.stat-cta {
  background: var(--c-primaire);
  color: var(--c-fond);
  border-radius: var(--r-lg);
  padding: var(--space-4);
  text-align: center;
  text-decoration: none;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 6px;
  font-weight: 700;
  transition: var(--t-base);
}
.stat-cta:hover {
  background: var(--c-primaire-profond);
  transform: translateY(-2px);
}
.stat-cta-icon {
  font-size: 32px;
  font-family: var(--font-display);
  line-height: 1;
}

.section-head {
  display: flex; justify-content: space-between; align-items: baseline;
  margin-bottom: var(--space-3); margin-top: var(--space-6);
}
.link-all {
  color: var(--c-accent-fort);
  font-weight: 600; text-decoration: none;
}
.link-all:hover { text-decoration: underline; }

.placeholder-text { color: var(--c-texte-doux); max-width: 580px; }

.empty-state {
  background: var(--c-fond-chaud);
  border-radius: var(--r-lg);
  padding: var(--space-6);
  text-align: center;
}
.empty-state p { color: var(--c-texte-doux); margin-bottom: var(--space-3); }

.recent-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
  gap: var(--space-3);
}
.recent-card {
  background: var(--c-surface);
  border-radius: var(--r-lg);
  overflow: hidden;
  box-shadow: var(--ombre-douce);
  text-decoration: none;
  color: inherit;
  transition: var(--t-base);
}
.recent-card:hover {
  transform: translateY(-2px);
  box-shadow: var(--ombre-elevee);
}
.recent-cover {
  height: 120px;
  background: linear-gradient(135deg, #D4A04F, #C97050);
  background-size: cover;
  background-position: center;
  position: relative;
}
.recent-status {
  position: absolute; top: 8px; left: 8px;
  padding: 3px 8px;
  border-radius: var(--r-pill);
  color: var(--c-fond);
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
.recent-body { padding: var(--space-3); }
.recent-body h4 {
  font-family: var(--font-display);
  font-size: 16px;
  color: var(--c-primaire-profond);
  margin-bottom: 4px;
  line-height: 1.2;
}
.recent-meta { font-size: 12px; color: var(--c-texte-doux); }
</style>
