<script setup lang="ts">
import { ref } from 'vue'

const stats = ref([
  { value: '1 247', label: 'Voyages partagés' },
  { value: '58/58', label: 'Wilayas couvertes' },
  { value: '450+', label: 'Ambassadeurs locaux' },
  { value: '4,8 ★', label: 'Note communauté' }
])

const emotions = ref([
  { icon: '🏜️', title: 'Désert & Silence', sub: 'Tassili · Tamanrasset · Djanet', theme: 'saharien' },
  { icon: '🌊', title: 'Méditerranée', sub: 'Tipaza · Béjaïa · Oran', theme: 'mauresque' },
  { icon: '⛰️', title: 'Kabylie & Sommets', sub: 'Djurdjura · Tikjda', theme: 'aures' },
  { icon: '🏛️', title: 'Casbah & Patrimoine', sub: 'Alger · Constantine', theme: 'mauresque' },
  { icon: '🌙', title: 'Spiritualité', sub: 'Médersa · zaouïas', theme: 'mauresque' },
  { icon: '🥾', title: 'Aventure', sub: 'Trek · 4×4 · plongée', theme: 'aures' }
])
</script>

<template>
  <div class="home">
    <!-- HERO -->
    <section class="hero">
      <div class="djawal-container hero-inner">
        <div class="hero-tag arabic">مرحبا بكم في الجزائر</div>
        <h1 class="hero-title">
          Voyagez l'Algérie<br>
          par <em>l'émotion</em>.
        </h1>
        <p class="hero-sub">
          Du Tassili au Djurdjura, de la Casbah à Béjaïa — la plateforme communautaire
          pensée et créée ici, par celles et ceux qui aiment ce pays.
        </p>

        <div class="hero-actions">
          <v-btn color="primary" size="x-large" rounded="md" to="/voyages">
            Découvrir un voyage
            <v-icon end>mdi-arrow-right</v-icon>
          </v-btn>
          <v-btn variant="outlined" color="primary" size="x-large" rounded="md">
            Composer avec l'IA
          </v-btn>
        </div>

        <div class="hero-stats">
          <div v-for="stat in stats" :key="stat.label" class="stat">
            <strong>{{ stat.value }}</strong>
            <span>{{ stat.label }}</span>
          </div>
        </div>
      </div>
    </section>

    <div class="djawal-frise" />

    <!-- ÉMOTIONS -->
    <section class="djawal-section">
      <div class="djawal-container">
        <div class="section-head">
          <div class="section-eyebrow">Voyagez par l'émotion</div>
          <h2>Choisissez d'abord ce que vous voulez ressentir.</h2>
          <p>Six registres pour entrer dans l'Algérie.</p>
        </div>

        <div class="emotions-grid">
          <div
            v-for="emotion in emotions"
            :key="emotion.title"
            :class="['emotion-card', `theme-bg-${emotion.theme}`]"
          >
            <div class="emotion-icon">{{ emotion.icon }}</div>
            <div class="emotion-text">
              <h3>{{ emotion.title }}</h3>
              <span>{{ emotion.sub }}</span>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- PLACEHOLDER SPRINT 1 -->
    <section class="djawal-section sprint-placeholder">
      <div class="djawal-container text-center">
        <div class="section-eyebrow">Sprint 1 · Fondations</div>
        <h2 style="margin-bottom: 16px;">Les fondations sont posées.</h2>
        <p style="max-width: 620px; margin: 0 auto 24px; color: var(--c-texte-doux);">
          L'infrastructure est en place : Vue 3 + Vuetify + PWA, design system algérien
          avec 3 thèmes culturels (Saharien, Mauresque, Aurès), base Supabase prête,
          déploiement automatique Vercel. Les sprints suivants ajouteront l'authentification,
          le master data, le constructeur de parcours et le moteur IA RAG.
        </p>
        <div class="theme-switcher">
          <span>Tester le miroir culturel :</span>
          <v-btn-group divided density="comfortable">
            <v-btn @click="$router.push({ query: { theme: 'saharien' }})">🏜️ Saharien</v-btn>
            <v-btn @click="$router.push({ query: { theme: 'mauresque' }})">🏛️ Mauresque</v-btn>
            <v-btn @click="$router.push({ query: { theme: 'aures' }})">⛰️ Aurès</v-btn>
          </v-btn-group>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.home { background: var(--c-fond); transition: background var(--t-theme); }

/* === HERO === */
.hero {
  position: relative;
  padding: var(--space-9) var(--space-5);
  min-height: 70vh;
  display: flex; align-items: center;
  background: var(--c-fond-chaud);
  overflow: hidden;
}
.hero::before {
  content: ''; position: absolute; inset: 0;
  background-image: var(--motif-principal-url);
  opacity: 0.5;
  pointer-events: none;
}
.hero-inner { position: relative; text-align: center; }
.hero-tag {
  font-size: 22px;
  color: var(--c-accent-fort);
  margin-bottom: var(--space-3);
}
.hero-title {
  font-size: clamp(40px, 6.5vw, 80px);
  margin-bottom: var(--space-4);
  font-weight: 500;
  color: var(--c-primaire-profond);
}
.hero-title em {
  font-style: italic;
  color: var(--c-accent-fort);
  font-weight: 600;
}
.hero-sub {
  font-size: 19px;
  color: var(--c-primaire);
  max-width: 680px; margin: 0 auto var(--space-6);
  font-weight: 300;
}
.hero-actions {
  display: flex; gap: var(--space-3);
  justify-content: center; flex-wrap: wrap;
  margin-bottom: var(--space-7);
}
.hero-stats {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: var(--space-5);
  max-width: 720px; margin: 0 auto;
}
.stat strong {
  display: block;
  font-family: var(--font-display);
  font-size: 32px;
  font-weight: 700;
  color: var(--c-primaire);
}
.stat span {
  font-size: 12px;
  color: var(--c-texte-doux);
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

/* === SECTIONS === */
.section-head { text-align: center; margin-bottom: var(--space-7); }
.section-eyebrow {
  color: var(--c-accent-fort);
  font-size: 13px;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  font-weight: 700;
  margin-bottom: var(--space-3);
}
.section-head h2 { font-size: clamp(32px, 4vw, 48px); margin-bottom: var(--space-3); }
.section-head p { color: var(--c-texte-doux); }

/* === ÉMOTIONS === */
.emotions-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: var(--space-3);
}
.emotion-card {
  aspect-ratio: 4 / 5;
  border-radius: var(--r-lg);
  overflow: hidden;
  position: relative;
  cursor: pointer;
  transition: transform var(--t-base), box-shadow var(--t-base);
}
.emotion-card:hover { transform: translateY(-6px); box-shadow: var(--ombre-elevee); }
.emotion-card::before {
  content: ''; position: absolute; inset: 0;
  background: linear-gradient(180deg, transparent 30%, rgba(10, 31, 46, 0.8) 100%);
  z-index: 1;
}
.theme-bg-saharien { background: linear-gradient(135deg, #D4A04F, #C97050); }
.theme-bg-mauresque { background: linear-gradient(135deg, #1B4965, #4A90BD); }
.theme-bg-aures { background: linear-gradient(135deg, #2D5A3D, #6B7A4A); }
.emotion-icon {
  position: absolute; top: var(--space-4); left: var(--space-4);
  width: 44px; height: 44px;
  background: rgba(250, 247, 242, 0.2);
  border-radius: 12px;
  display: flex; align-items: center; justify-content: center;
  font-size: 22px;
  z-index: 2;
}
.emotion-text {
  position: absolute; bottom: var(--space-4); left: var(--space-4); right: var(--space-4);
  z-index: 2; color: var(--c-fond);
}
.emotion-text h3 { color: var(--c-fond); font-size: 22px; margin-bottom: 4px; }
.emotion-text span { font-size: 13px; opacity: 0.85; }

/* === PLACEHOLDER SPRINT 1 === */
.sprint-placeholder {
  background: var(--c-surface);
  border-top: 1px solid var(--c-gris-clair);
}
.theme-switcher {
  display: inline-flex;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-3) var(--space-4);
  background: var(--c-fond-chaud);
  border-radius: var(--r-pill);
  flex-wrap: wrap;
  justify-content: center;
}
.theme-switcher span {
  font-size: 13px;
  color: var(--c-texte-doux);
  font-weight: 600;
}
.text-center { text-align: center; }

@media (max-width: 1024px) {
  .emotions-grid { grid-template-columns: repeat(2, 1fr); }
  .hero-stats { grid-template-columns: repeat(2, 1fr); }
}
@media (max-width: 720px) {
  .emotions-grid { grid-template-columns: 1fr; }
}
</style>
