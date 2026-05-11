<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
const auth = useAuthStore()
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

    <section class="djawal-section">
      <h2>Mes parcours</h2>
      <p class="placeholder-text">
        Le constructeur de parcours sera livré au Sprint 5. Vous pourrez y créer vos
        itinéraires par glisser-déposer à partir du catalogue de ressources validées.
      </p>
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
h2 { font-size: 28px; margin-bottom: var(--space-3); margin-top: var(--space-6); }
.placeholder-text { color: var(--c-texte-doux); max-width: 580px; }
</style>
