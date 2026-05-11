<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'

const stats = ref({
  pendingKyc: 0,
  pendingTrips: 0,
  totalGuides: 0,
  totalVoyageurs: 0
})
const loading = ref(true)

onMounted(async () => {
  loading.value = true

  const [kyc, trips, guides, voyageurs] = await Promise.all([
    supabase.from('profiles').select('id', { count: 'exact', head: true })
      .in('role', ['guide_senior', 'guide_junior']).eq('kyc_status', 'pending'),
    supabase.from('trips').select('id', { count: 'exact', head: true }).eq('status', 'pending_review'),
    supabase.from('profiles').select('id', { count: 'exact', head: true })
      .in('role', ['guide_senior', 'guide_junior']),
    supabase.from('profiles').select('id', { count: 'exact', head: true }).eq('role', 'voyageur')
  ])

  stats.value = {
    pendingKyc: kyc.count ?? 0,
    pendingTrips: trips.count ?? 0,
    totalGuides: guides.count ?? 0,
    totalVoyageurs: voyageurs.count ?? 0
  }
  loading.value = false
})
</script>

<template>
  <div class="djawal-container djawal-section">
    <div class="section-eyebrow">Administration</div>
    <h1>👑 Tableau de bord Super Admin.</h1>
    <p class="lead">Gouvernance qualité, validation KYC et modération des parcours.</p>

    <div class="stats-grid">
      <router-link to="/admin/kyc" class="stat-card alert">
        <div class="stat-icon">📋</div>
        <strong>{{ loading ? '—' : stats.pendingKyc }}</strong>
        <span>KYC en attente</span>
      </router-link>

      <div class="stat-card">
        <div class="stat-icon">🎒</div>
        <strong>{{ loading ? '—' : stats.totalGuides }}</strong>
        <span>Guides enregistrés</span>
      </div>

      <div class="stat-card">
        <div class="stat-icon">🧳</div>
        <strong>{{ loading ? '—' : stats.totalVoyageurs }}</strong>
        <span>Voyageurs</span>
      </div>

      <div class="stat-card">
        <div class="stat-icon">📝</div>
        <strong>{{ loading ? '—' : stats.pendingTrips }}</strong>
        <span>Parcours à modérer</span>
      </div>
    </div>

    <section>
      <h2>Modules disponibles</h2>
      <div class="modules-grid">
        <router-link to="/admin/kyc" class="module-card">
          <div class="module-icon">📋</div>
          <h3>Validation KYC</h3>
          <p>Examiner les dossiers des nouveaux guides et les approuver ou rejeter.</p>
        </router-link>
        <div class="module-card disabled">
          <div class="module-icon">🏨</div>
          <h3>Master Data</h3>
          <p>Sprint 3 — gestion des hôtels, restaurants, sites et destinations.</p>
        </div>
        <div class="module-card disabled">
          <div class="module-icon">✓</div>
          <h3>Modération parcours</h3>
          <p>Sprint 5 — valider les parcours soumis par les guides juniors.</p>
        </div>
        <div class="module-card disabled">
          <div class="module-icon">🤖</div>
          <h3>Logs RAG</h3>
          <p>Sprint 6 — audit des conversations IA et détection d'hallucinations.</p>
        </div>
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
h1 { font-size: clamp(32px, 4vw, 44px); margin-bottom: var(--space-3); }
.lead { color: var(--c-texte-doux); margin-bottom: var(--space-6); font-size: 16px; }
h2 { font-size: 28px; margin: var(--space-7) 0 var(--space-4); }

.stats-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: var(--space-4);
  margin-bottom: var(--space-6);
}
.stat-card {
  background: var(--c-surface);
  padding: var(--space-5);
  border-radius: var(--r-md);
  box-shadow: var(--ombre-douce);
  text-align: center;
  text-decoration: none;
  color: inherit;
  border-top: 4px solid var(--c-primaire);
}
.stat-card.alert {
  border-top-color: var(--c-cta);
  cursor: pointer;
}
.stat-card.alert:hover {
  transform: translateY(-3px);
  box-shadow: var(--ombre-elevee);
}
.stat-icon { font-size: 32px; margin-bottom: var(--space-2); }
.stat-card strong {
  display: block;
  font-family: var(--font-display);
  font-size: 40px;
  color: var(--c-primaire);
}
.stat-card.alert strong { color: var(--c-cta); }
.stat-card span {
  font-size: 12px;
  color: var(--c-texte-doux);
  letter-spacing: 0.1em;
  text-transform: uppercase;
}

.modules-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: var(--space-4);
}
.module-card {
  background: var(--c-surface);
  padding: var(--space-5);
  border-radius: var(--r-md);
  box-shadow: var(--ombre-douce);
  text-decoration: none;
  color: inherit;
  transition: var(--t-base);
  border-left: 4px solid var(--c-accent);
}
.module-card:not(.disabled):hover {
  transform: translateY(-3px);
  box-shadow: var(--ombre-elevee);
}
.module-card.disabled { opacity: 0.5; border-left-color: var(--c-gris-clair); }
.module-icon { font-size: 32px; margin-bottom: var(--space-2); }
.module-card h3 {
  font-family: var(--font-display);
  font-size: 22px;
  margin-bottom: var(--space-2);
}
.module-card p {
  font-size: 14px;
  color: var(--c-texte-doux);
}

@media (max-width: 880px) {
  .stats-grid { grid-template-columns: repeat(2, 1fr); }
}
</style>
