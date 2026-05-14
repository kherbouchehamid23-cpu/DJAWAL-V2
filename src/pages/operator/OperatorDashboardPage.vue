<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'

const auth = useAuthStore()

interface Stats {
  published: number
  pending: number
  rejected: number
  draft: number
}

const stats = ref<Stats>({ published: 0, pending: 0, rejected: 0, draft: 0 })
const loading = ref(true)

// Helper : tables que cet opérateur peut soumettre selon sa matrice
const allowedTables = computed(() => {
  const tables: Array<{ table: string; label: string }> = []
  if (auth.canSubmit('accommodation')) tables.push({ table: 'accommodations', label: 'Hébergements' })
  if (auth.canSubmit('restaurant')) tables.push({ table: 'restaurants', label: 'Restaurants' })
  if (auth.canSubmit('activity')) tables.push({ table: 'activities', label: 'Activités' })
  if (auth.canSubmit('trip')) tables.push({ table: 'trips', label: 'Packages / Voyages' })
  return tables
})

const operatorTypeLabels: Record<string, string> = {
  travel_agency: 'Agence de voyage',
  restaurant: 'Restaurant',
  accommodation_provider: 'Hébergeur',
  artisan: 'Artisan traditionnel'
}

const operatorTypeLabel = computed(() =>
  auth.operatorType ? operatorTypeLabels[auth.operatorType] : ''
)

onMounted(async () => {
  if (!auth.user) return
  await loadStats()
})

async function loadStats() {
  loading.value = true
  const counts = { published: 0, pending: 0, rejected: 0, draft: 0 }

  // Agrège tous les comptages selon la matrice de l'opérateur
  for (const t of allowedTables.value) {
    const tbl = t.table
    if (tbl === 'trips') {
      // Pour trips, status existe déjà (trip_status enum)
      const [p, pr, rj, dr] = await Promise.all([
        supabase.from('trips').select('id', { count: 'exact', head: true }).eq('created_by', auth.user!.id).eq('status', 'published'),
        supabase.from('trips').select('id', { count: 'exact', head: true }).eq('created_by', auth.user!.id).eq('status', 'pending_review'),
        supabase.from('trips').select('id', { count: 'exact', head: true }).eq('created_by', auth.user!.id).eq('status', 'rejected'),
        supabase.from('trips').select('id', { count: 'exact', head: true }).eq('created_by', auth.user!.id).eq('status', 'draft')
      ])
      counts.published += p.count ?? 0
      counts.pending += pr.count ?? 0
      counts.rejected += rj.count ?? 0
      counts.draft += dr.count ?? 0
    } else {
      const [p, pr, rj, dr] = await Promise.all([
        supabase.from(tbl).select('id', { count: 'exact', head: true }).eq('created_by', auth.user!.id).eq('status', 'published'),
        supabase.from(tbl).select('id', { count: 'exact', head: true }).eq('created_by', auth.user!.id).eq('status', 'pending_review'),
        supabase.from(tbl).select('id', { count: 'exact', head: true }).eq('created_by', auth.user!.id).eq('status', 'rejected'),
        supabase.from(tbl).select('id', { count: 'exact', head: true }).eq('created_by', auth.user!.id).eq('status', 'draft')
      ])
      counts.published += p.count ?? 0
      counts.pending += pr.count ?? 0
      counts.rejected += rj.count ?? 0
      counts.draft += dr.count ?? 0
    }
  }

  stats.value = counts
  loading.value = false
}
</script>

<template>
  <div class="djawal-container operator-dashboard">

    <!-- Bandeau KYC si non approuvé -->
    <div v-if="auth.profile?.kyc_status !== 'approved'" class="kyc-banner" :class="auth.profile?.kyc_status">
      <div class="kyc-icon">
        {{ auth.profile?.kyc_status === 'rejected' ? '⚠️' : '📋' }}
      </div>
      <div class="kyc-text">
        <strong v-if="auth.profile?.kyc_status === 'pending'">Vérification KYC en cours</strong>
        <strong v-else-if="auth.profile?.kyc_status === 'rejected'">Dossier KYC refusé</strong>
        <p v-if="auth.profile?.kyc_status === 'pending'">
          Vos produits ne pourront être soumis qu'après validation de votre registre du commerce.
          <router-link to="/espace-operateur/kyc" class="kyc-link">Compléter le dossier →</router-link>
        </p>
        <p v-else-if="auth.profile?.kyc_status === 'rejected'">
          Un de nos administrateurs a refusé votre dossier. Vous pouvez le compléter et le resoumettre.
          <router-link to="/espace-operateur/kyc" class="kyc-link">Resoumettre →</router-link>
        </p>
      </div>
    </div>

    <header class="dashboard-head">
      <div>
        <div class="eyebrow">Espace opérateur</div>
        <h1>{{ auth.profile?.company_name || auth.profile?.display_name }}</h1>
        <p class="lead">{{ operatorTypeLabel }} · {{ auth.profile?.region || 'Algérie' }}</p>
      </div>
      <router-link
        v-if="auth.profile?.kyc_status === 'approved'"
        to="/espace-operateur/produits"
        class="btn-primary"
      >
        + Soumettre un produit
      </router-link>
    </header>

    <!-- Stats -->
    <div class="stats-grid">
      <div class="stat-card stat-published">
        <div class="stat-icon">✓</div>
        <strong>{{ loading ? '—' : stats.published }}</strong>
        <span>Publiés</span>
      </div>
      <div class="stat-card stat-pending">
        <div class="stat-icon">⏳</div>
        <strong>{{ loading ? '—' : stats.pending }}</strong>
        <span>En attente de validation</span>
      </div>
      <div class="stat-card stat-rejected">
        <div class="stat-icon">⚠</div>
        <strong>{{ loading ? '—' : stats.rejected }}</strong>
        <span>Refusés</span>
      </div>
      <div class="stat-card stat-draft">
        <div class="stat-icon">✎</div>
        <strong>{{ loading ? '—' : stats.draft }}</strong>
        <span>Brouillons</span>
      </div>
    </div>

    <!-- Capacités d'opérateur -->
    <section class="caps-section">
      <h2>Vos capacités de soumission</h2>
      <p class="caps-intro">
        En tant que {{ operatorTypeLabel.toLowerCase() }}, vous pouvez soumettre les produits suivants à Djawal :
      </p>
      <div class="caps-grid">
        <router-link
          v-for="t in allowedTables"
          :key="t.table"
          :to="`/espace-operateur/produits?type=${t.table}`"
          class="cap-card"
        >
          <strong>{{ t.label }}</strong>
          <span>→ Gérer</span>
        </router-link>
      </div>
      <p v-if="allowedTables.length === 0" class="caps-empty">
        Aucune capacité de soumission active. Vérifiez votre profil ou contactez le support.
      </p>
    </section>

    <!-- Profil public -->
    <section class="profile-section">
      <h2>Votre fiche publique</h2>
      <p class="profile-intro">
        Votre profil est visible publiquement sur Djawal une fois votre KYC validé. Les voyageurs peuvent
        découvrir votre activité, voir vos créations et lire les souvenirs des clients passés.
      </p>
      <div class="profile-actions">
        <router-link
          v-if="auth.profile?.slug"
          :to="`/operateurs/${auth.profile.slug}`"
          class="btn-ghost"
        >
          Voir ma fiche publique →
        </router-link>
        <router-link to="/espace-operateur/profil" class="btn-ghost">
          Modifier mon profil
        </router-link>
      </div>
    </section>
  </div>
</template>

<style scoped>
.operator-dashboard {
  padding: var(--space-6) var(--space-5);
  max-width: 1080px;
  margin: 0 auto;
}

/* === KYC Banner === */
.kyc-banner {
  display: flex;
  gap: var(--space-3);
  align-items: flex-start;
  padding: var(--space-4);
  border-radius: var(--r-md);
  margin-bottom: var(--space-6);
  border-left: 4px solid;
}
.kyc-banner.pending {
  background: rgba(212, 160, 79, 0.1);
  border-left-color: #D4A04F;
}
.kyc-banner.rejected {
  background: rgba(192, 74, 58, 0.1);
  border-left-color: #C04A3A;
}
.kyc-icon { font-size: 24px; flex-shrink: 0; }
.kyc-text strong {
  display: block;
  color: var(--c-primaire-profond);
  margin-bottom: 4px;
}
.kyc-text p {
  margin: 0;
  font-size: 14px;
  color: var(--c-texte);
}
.kyc-link {
  color: var(--c-accent-fort);
  font-weight: 600;
  text-decoration: none;
  margin-left: 8px;
}
.kyc-link:hover { text-decoration: underline; }

/* === Head === */
.dashboard-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  margin-bottom: var(--space-6);
  flex-wrap: wrap;
  gap: var(--space-3);
}
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
.lead { color: var(--c-texte-doux); }

.btn-primary {
  background: var(--c-primaire-profond);
  color: var(--c-fond);
  padding: 12px 22px;
  border-radius: 999px;
  font-weight: 600;
  font-size: 14px;
  text-decoration: none;
  transition: var(--t-base);
}
.btn-primary:hover { background: var(--c-accent-fort); }

/* === Stats === */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: var(--space-3);
  margin-bottom: var(--space-7);
}
.stat-card {
  background: var(--c-surface);
  padding: var(--space-4);
  border-radius: var(--r-md);
  box-shadow: var(--ombre-douce);
  text-align: center;
  border-top: 3px solid;
}
.stat-published { border-top-color: #6B7A4A; }
.stat-pending { border-top-color: #D4A04F; }
.stat-rejected { border-top-color: #C04A3A; }
.stat-draft { border-top-color: #888780; }
.stat-icon {
  font-size: 24px;
  margin-bottom: 6px;
  font-weight: bold;
}
.stat-card strong {
  display: block;
  font-family: var(--font-display);
  font-size: 36px;
  color: var(--c-primaire-profond);
}
.stat-card span {
  font-size: 11px;
  color: var(--c-texte-doux);
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

/* === Capacités === */
.caps-section, .profile-section {
  margin-bottom: var(--space-7);
}
h2 {
  font-family: var(--font-display);
  font-size: 22px;
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-2);
}
.caps-intro, .profile-intro {
  color: var(--c-texte-doux);
  margin-bottom: var(--space-4);
  font-size: 14px;
}
.caps-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: var(--space-3);
}
.cap-card {
  background: var(--c-surface);
  padding: var(--space-3) var(--space-4);
  border-radius: var(--r-md);
  border: 1px solid var(--c-gris-clair);
  text-decoration: none;
  display: flex;
  justify-content: space-between;
  align-items: center;
  transition: var(--t-base);
}
.cap-card:hover {
  border-color: var(--c-accent-fort);
  transform: translateY(-2px);
  box-shadow: var(--ombre-douce);
}
.cap-card strong {
  color: var(--c-primaire-profond);
  font-size: 15px;
}
.cap-card span {
  color: var(--c-accent-fort);
  font-size: 13px;
  font-weight: 600;
}
.caps-empty {
  color: var(--c-texte-doux);
  font-style: italic;
}

.profile-actions {
  display: flex;
  gap: var(--space-3);
  flex-wrap: wrap;
}
.btn-ghost {
  padding: 10px 18px;
  border: 1px solid var(--c-primaire-profond);
  color: var(--c-primaire-profond);
  border-radius: 999px;
  text-decoration: none;
  font-weight: 500;
  font-size: 14px;
  transition: var(--t-base);
}
.btn-ghost:hover {
  background: var(--c-primaire-profond);
  color: var(--c-fond);
}
</style>
