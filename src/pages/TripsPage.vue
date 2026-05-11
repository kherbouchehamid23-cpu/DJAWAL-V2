<script setup lang="ts">
// Placeholder Sprint 1 — sera implémenté au Sprint 4 (Vitrine voyageur)
</script>

<template>
  <div class="djawal-container djawal-section">
    <div class="placeholder">
      <div class="section-eyebrow">Sprint 4 à venir</div>
      <h2>Catalogue des voyages</h2>
      <p>
        Cette page affichera le catalogue complet des voyages avec filtres, carte Leaflet,
        et drawer de prévisualisation. Elle sera livrée au Sprint 4 — Vitrine voyageur.
      </p>
      <v-btn to="/" color="primary" class="mt-4">← Retour à l'accueil</v-btn>
    </div>
  </div>
</template>

<style scoped>
.placeholder {
  text-align: center;
  padding: var(--space-9) var(--space-4);
}
.section-eyebrow {
  color: var(--c-accent-fort);
  font-size: 13px;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  font-weight: 700;
  margin-bottom: var(--space-3);
}
h2 { font-size: clamp(32px, 4vw, 48px); margin-bottom: var(--space-3); }
p { max-width: 580px; margin: 0 auto var(--space-4); color: var(--c-texte-doux); }
</style>
