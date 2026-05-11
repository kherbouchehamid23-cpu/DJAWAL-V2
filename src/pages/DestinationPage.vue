<script setup lang="ts">
import { useRoute } from 'vue-router'
const route = useRoute()
const id = route.params.id as string
</script>

<template>
  <div class="djawal-container djawal-section">
    <div class="placeholder">
      <div class="section-eyebrow">Sprint 4 à venir</div>
      <h2>Fiche destination</h2>
      <p>Destination ID : <code>{{ id }}</code></p>
      <p>
        Cette page affichera la fiche complète d'une destination avec hôtels, sites,
        restaurants associés, visites 360° et application du thème culturel correspondant.
      </p>
      <v-btn to="/voyages" color="primary" class="mt-4">← Retour aux voyages</v-btn>
    </div>
  </div>
</template>

<style scoped>
.placeholder { text-align: center; padding: var(--space-9) var(--space-4); }
.section-eyebrow {
  color: var(--c-accent-fort); font-size: 13px;
  letter-spacing: 0.2em; text-transform: uppercase; font-weight: 700;
  margin-bottom: var(--space-3);
}
h2 { font-size: clamp(32px, 4vw, 48px); margin-bottom: var(--space-3); }
p { max-width: 580px; margin: 0 auto var(--space-4); color: var(--c-texte-doux); }
code { background: var(--c-fond-chaud); padding: 2px 8px; border-radius: 4px; font-family: monospace; }
</style>
