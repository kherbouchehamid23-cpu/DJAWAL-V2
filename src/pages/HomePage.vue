<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useThemeStore, type CulturalTheme } from '@/stores/theme'
import { supabase } from '@/lib/supabase'
import MemoriesCarousel from '@/components/MemoriesCarousel.vue'
import { useSEO } from '@/composables/useSEO'

useSEO({
  title: 'Voyager l\'Algérie autrement',
  description: 'Découvrez l\'Algérie par l\'émotion. Plateforme communautaire de voyages, hôtels et sites touristiques. Composez votre parcours sur mesure avec notre IA.'
})

const themeStore = useThemeStore()

// Images de fond par thème — une photo de destination ayant ce thème
const themePhotos = ref<Record<string, string>>({
  saharien: '',
  mauresque: '',
  aures: ''
})

onMounted(async () => {
  // Récupère une destination ayant une hero_image par thème
  const { data } = await supabase
    .from('destinations')
    .select('cultural_theme, hero_image_url')
    .not('hero_image_url', 'is', null)
  if (data) {
    for (const d of data) {
      if (d.cultural_theme && d.hero_image_url && !themePhotos.value[d.cultural_theme]) {
        themePhotos.value[d.cultural_theme] = d.hero_image_url
      }
    }
  }
})

const stats = ref([
  { value: '1 247', label: 'Voyages partagés' },
  { value: '58/58', label: 'Wilayas couvertes' },
  { value: '450+', label: 'Ambassadeurs locaux' },
  { value: '4,8 ★', label: 'Note communauté' }
])

const emotions = ref([
  { icon: '🏜️', title: 'Désert & Silence', sub: 'Tassili · Tamanrasset · Djanet', theme: 'saharien' as CulturalTheme },
  { icon: '🌊', title: 'Méditerranée', sub: 'Tipaza · Béjaïa · Oran', theme: 'mauresque' as CulturalTheme },
  { icon: '⛰️', title: 'Kabylie & Sommets', sub: 'Djurdjura · Tikjda', theme: 'aures' as CulturalTheme },
  { icon: '🏛️', title: 'Casbah & Patrimoine', sub: 'Alger · Constantine', theme: 'mauresque' as CulturalTheme },
  { icon: '🌙', title: 'Spiritualité', sub: 'Médersa · zaouïas', theme: 'mauresque' as CulturalTheme },
  { icon: '🥾', title: 'Aventure', sub: 'Trek · 4×4 · plongée', theme: 'aures' as CulturalTheme }
])

function tryTheme(theme: CulturalTheme) {
  themeStore.setTheme(theme)
}
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
          <router-link to="/composer" class="cta-ai">
            <div class="cta-ai-glow"></div>
            <span class="cta-ai-sparkle">✨</span>
            <div class="cta-ai-content">
              <strong>Composer mon voyage avec l'IA</strong>
              <small>Un parcours sur mesure en 30 secondes</small>
            </div>
            <span class="cta-ai-arrow">→</span>
          </router-link>
          <v-btn color="primary" size="large" rounded="md" variant="outlined" to="/voyages">
            Ou parcourir les destinations
            <v-icon end>mdi-arrow-right</v-icon>
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
          <router-link
            v-for="emotion in emotions"
            :key="emotion.title"
            :to="`/voyages?theme=${emotion.theme}`"
            :class="['emotion-card', `theme-bg-${emotion.theme}`]"
            :style="themePhotos[emotion.theme] ? `background-image: linear-gradient(180deg, rgba(0,0,0,0.1) 0%, rgba(10,31,46,0.7) 100%), url('${themePhotos[emotion.theme]}'); background-size: cover; background-position: center;` : ''"
          >
            <div class="emotion-icon">{{ emotion.icon }}</div>
            <div class="emotion-text">
              <h3>{{ emotion.title }}</h3>
              <span>{{ emotion.sub }}</span>
            </div>
            <div class="emotion-cta">Explorer →</div>
          </router-link>
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
          <div class="theme-buttons">
            <button
              class="theme-btn"
              :class="{ active: themeStore.currentTheme === 'saharien' }"
              @click="tryTheme('saharien')"
            >🏜️ Saharien</button>
            <button
              class="theme-btn"
              :class="{ active: themeStore.currentTheme === 'mauresque' }"
              @click="tryTheme('mauresque')"
            >🏛️ Mauresque</button>
            <button
              class="theme-btn"
              :class="{ active: themeStore.currentTheme === 'aures' }"
              @click="tryTheme('aures')"
            >⛰️ Aurès</button>
          </div>
          <small class="theme-current">
            Thème actif : <strong>{{ themeStore.themeLabel }}</strong>
          </small>
        </div>
      </div>
    </section>

    <!-- SOUVENIRS DE VOYAGEURS -->
    <MemoriesCarousel />
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
  align-items: center;
  margin-bottom: var(--space-7);
}

/* === CTA IA prééminent === */
.cta-ai {
  position: relative;
  display: inline-flex;
  align-items: center;
  gap: 14px;
  padding: 18px 28px;
  background: linear-gradient(135deg, var(--c-primaire) 0%, var(--c-primaire-profond) 100%);
  border-radius: var(--r-lg);
  text-decoration: none;
  color: var(--c-fond);
  box-shadow: 0 12px 32px rgba(10, 31, 46, 0.25), 0 0 0 0 rgba(212, 160, 79, 0.4);
  overflow: hidden;
  transition: all var(--t-base);
  animation: cta-pulse 3s ease-in-out infinite;
}
@keyframes cta-pulse {
  0%, 100% { box-shadow: 0 12px 32px rgba(10, 31, 46, 0.25), 0 0 0 0 rgba(212, 160, 79, 0.5); }
  50% { box-shadow: 0 16px 40px rgba(10, 31, 46, 0.35), 0 0 0 12px rgba(212, 160, 79, 0); }
}
.cta-ai:hover {
  transform: translateY(-3px) scale(1.02);
  animation: none;
}
.cta-ai-glow {
  position: absolute;
  top: -50%; left: -50%;
  width: 200%; height: 200%;
  background: radial-gradient(circle, rgba(212, 160, 79, 0.4) 0%, transparent 60%);
  animation: glow-spin 8s linear infinite;
  pointer-events: none;
}
@keyframes glow-spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}
.cta-ai-sparkle {
  font-size: 32px;
  position: relative;
  z-index: 1;
  animation: sparkle 2s ease-in-out infinite;
}
@keyframes sparkle {
  0%, 100% { transform: rotate(0deg) scale(1); }
  50% { transform: rotate(15deg) scale(1.15); }
}
.cta-ai-content {
  position: relative;
  z-index: 1;
  text-align: left;
}
.cta-ai-content strong {
  display: block;
  font-family: var(--font-display);
  font-size: 19px;
  font-weight: 600;
  line-height: 1.2;
}
.cta-ai-content small {
  display: block;
  font-size: 13px;
  opacity: 0.85;
  margin-top: 2px;
}
.cta-ai-arrow {
  position: relative;
  z-index: 1;
  font-size: 28px;
  font-weight: 700;
  transition: transform var(--t-base);
}
.cta-ai:hover .cta-ai-arrow { transform: translateX(4px); }
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
  text-decoration: none;
  display: block;
  transition: transform var(--t-base), box-shadow var(--t-base);
}
.emotion-card:hover { transform: translateY(-6px); box-shadow: var(--ombre-elevee); }
.emotion-card:hover .emotion-cta { transform: translateX(4px); }
.emotion-cta {
  position: absolute;
  bottom: var(--space-4);
  right: var(--space-4);
  z-index: 2;
  color: var(--c-fond);
  font-size: 13px;
  font-weight: 700;
  letter-spacing: 0.05em;
  background: rgba(255, 255, 255, 0.18);
  backdrop-filter: blur(4px);
  padding: 6px 12px;
  border-radius: var(--r-pill);
  transition: transform var(--t-base);
}
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
  flex-direction: column;
  align-items: center;
  gap: var(--space-3);
  padding: var(--space-4) var(--space-5);
  background: var(--c-fond-chaud);
  border-radius: var(--r-lg);
  border: 1px solid var(--c-gris-clair);
}
.theme-switcher > span {
  font-size: 13px;
  color: var(--c-texte-doux);
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}
.theme-buttons {
  display: flex;
  gap: var(--space-2);
  flex-wrap: wrap;
  justify-content: center;
}
.theme-btn {
  padding: 10px 18px;
  background: var(--c-surface);
  border: 2px solid var(--c-gris-clair);
  border-radius: var(--r-pill);
  font-family: inherit;
  font-size: 14px;
  font-weight: 600;
  color: var(--c-primaire-profond);
  cursor: pointer;
  transition: var(--t-base);
}
.theme-btn:hover {
  border-color: var(--c-accent);
  transform: translateY(-2px);
}
.theme-btn.active {
  background: var(--c-primaire);
  color: var(--c-fond);
  border-color: var(--c-primaire);
  box-shadow: var(--ombre-douce);
}
.theme-current {
  font-size: 12px;
  color: var(--c-texte-doux);
}
.theme-current strong {
  color: var(--c-accent-fort);
  font-weight: 700;
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
