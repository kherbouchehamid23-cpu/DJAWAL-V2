<script setup lang="ts"></script>

<template>
  <div class="djawal-container djawal-section text-center">
    <div class="section-eyebrow">404</div>
    <h1>Cette page s'est perdue dans le Sahara.</h1>
    <p>Pas de panique — la caravane vous ramène à la maison.</p>
    <v-btn to="/" color="primary" size="large" class="mt-4">← Retour à l'accueil</v-btn>
  </div>
</template>

<style scoped>
.section-eyebrow {
  color: var(--c-accent-fort); font-size: 13px;
  letter-spacing: 0.2em; text-transform: uppercase; font-weight: 700;
  margin-bottom: var(--space-3);
}
h1 { font-size: clamp(32px, 4vw, 48px); margin-bottom: var(--space-3); }
p { color: var(--c-texte-doux); margin-bottom: var(--space-4); }
.text-center { text-align: center; padding: var(--space-9) var(--space-4); }
</style>
