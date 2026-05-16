<script setup lang="ts">
import { useSEO } from '@/composables/useSEO'

useSEO({
  title: 'Page introuvable',
  description: "Cette page n'existe pas. Reprenez la caravane vers nos destinations algériennes."
})
</script>

<template>
  <div class="not-found-page">
    <div class="djawal-container">
      <div class="content">
        <div class="dune-illustration">
          <svg viewBox="0 0 400 200" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
            <!-- Sun -->
            <circle cx="320" cy="60" r="28" fill="#D4A04F" opacity="0.85"/>
            <!-- Dunes layers -->
            <path d="M0 200 Q 80 130, 170 160 T 400 140 L 400 200 Z" fill="#C97050" opacity="0.4"/>
            <path d="M0 200 Q 120 150, 200 175 T 400 165 L 400 200 Z" fill="#A6772A" opacity="0.6"/>
            <path d="M0 200 Q 100 175, 230 185 T 400 180 L 400 200 Z" fill="#8B4A2C"/>
            <!-- Caravan silhouette -->
            <g transform="translate(160 150)">
              <ellipse cx="0" cy="14" rx="14" ry="3" fill="rgba(0,0,0,0.2)"/>
              <path d="M-8 0 Q -10 -8, -4 -10 L 4 -10 Q 10 -8, 8 0 Q 12 2, 12 6 L 10 12 L -10 12 L -12 6 Q -12 2, -8 0 Z" fill="#0A1F2E"/>
              <circle cx="-4" cy="-12" r="3" fill="#0A1F2E"/>
            </g>
            <g transform="translate(195 155)">
              <ellipse cx="0" cy="10" rx="10" ry="2" fill="rgba(0,0,0,0.2)"/>
              <path d="M-6 0 Q -8 -6, -3 -8 L 3 -8 Q 8 -6, 6 0 Q 9 2, 9 5 L 8 9 L -8 9 L -9 5 Q -9 2, -6 0 Z" fill="#0A1F2E"/>
              <circle cx="-3" cy="-10" r="2.5" fill="#0A1F2E"/>
            </g>
          </svg>
        </div>

        <div class="eyebrow">Erreur 404</div>
        <h1>Cette page s'est perdue dans le désert</h1>
        <p class="lead">
          Pas de panique — la caravane reprend sa route. Voici quelques pistes pour
          retrouver votre chemin.
        </p>

        <div class="suggestions">
          <router-link to="/" class="suggestion">
            <span class="icon">🏠</span>
            <div>
              <strong>Accueil</strong>
              <small>Retour au point de départ</small>
            </div>
          </router-link>
          <router-link to="/voyages" class="suggestion">
            <span class="icon">🗺️</span>
            <div>
              <strong>Destinations</strong>
              <small>Explorer les wilayas</small>
            </div>
          </router-link>
          <router-link to="/composer" class="suggestion">
            <span class="icon">✦</span>
            <div>
              <strong>Composer un voyage</strong>
              <small>Djawal IA, votre guide intelligent</small>
            </div>
          </router-link>
          <router-link to="/temoignages" class="suggestion">
            <span class="icon">💬</span>
            <div>
              <strong>Souvenirs</strong>
              <small>Récits de la communauté</small>
            </div>
          </router-link>
        </div>

        <p class="contact-hint">
          Vous pensez qu'il s'agit d'une erreur ?
          <router-link to="/contact">Signalez-le-nous</router-link>
        </p>
      </div>
    </div>
  </div>
</template>

<style scoped>
.not-found-page {
  background: var(--c-fond-chaud);
  min-height: 80vh;
  display: flex;
  align-items: center;
  padding: var(--space-7) 0;
  position: relative;
  overflow: hidden;
}
.not-found-page::before {
  content: ''; position: absolute; inset: 0;
  background-image: var(--motif-principal-url);
  opacity: 0.25;
  pointer-events: none;
}

.content {
  max-width: 720px;
  margin: 0 auto;
  text-align: center;
  position: relative;
}

.dune-illustration {
  max-width: 320px;
  margin: 0 auto var(--space-4);
}
.dune-illustration svg { width: 100%; height: auto; display: block; }

.eyebrow {
  color: var(--c-accent-fort);
  font-size: 14px;
  font-weight: 700;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  margin-bottom: var(--space-2);
}

h1 {
  font-family: var(--font-display);
  font-size: clamp(28px, 4vw, 44px);
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-3);
}
.lead {
  font-size: 17px;
  color: var(--c-primaire);
  margin-bottom: var(--space-5);
  max-width: 560px;
  margin-left: auto;
  margin-right: auto;
  line-height: 1.5;
}

.suggestions {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: var(--space-3);
  margin-bottom: var(--space-5);
  text-align: left;
}
.suggestion {
  display: flex; align-items: center; gap: var(--space-3);
  background: var(--c-surface);
  padding: var(--space-3);
  border-radius: var(--r-md);
  box-shadow: var(--ombre-douce);
  text-decoration: none;
  color: inherit;
  transition: var(--t-base);
  border-left: 3px solid transparent;
}
.suggestion:hover {
  transform: translateY(-2px);
  border-left-color: var(--c-accent);
  box-shadow: var(--ombre-elevee);
}
.icon { font-size: 28px; }
.suggestion strong {
  display: block;
  color: var(--c-primaire-profond);
  font-size: 15px;
}
.suggestion small { color: var(--c-texte-doux); font-size: 12px; }

.contact-hint {
  color: var(--c-texte-doux);
  font-size: 14px;
}
.contact-hint a {
  color: var(--c-accent-fort);
  font-weight: 700;
  text-decoration: none;
}
.contact-hint a:hover { text-decoration: underline; }
</style>
