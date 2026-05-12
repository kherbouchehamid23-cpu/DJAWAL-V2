<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useAuthStore } from '@/stores/auth'

/**
 * Onboarding flottant 3-étapes pour nouveaux voyageurs.
 * Stocké dans localStorage pour ne pas réafficher.
 */

const auth = useAuthStore()
const visible = ref(false)
const step = ref(0)

const STORAGE_KEY = 'djawal_onboarding_done_v1'

const steps = [
  {
    icon: '👋',
    title: 'Bienvenue sur Djawal',
    text: "L'Algérie comme une invitation. Voici 3 choses à savoir pour commencer ton voyage.",
    cta: 'Suivant'
  },
  {
    icon: '✨',
    title: 'Compose ton voyage avec l\'IA',
    text: "Dis-nous tes envies (désert, montagne, gastronomie...) et notre IA te propose un parcours sur-mesure, puisé dans le catalogue des guides locaux.",
    cta: 'Suivant'
  },
  {
    icon: '❤️',
    title: 'Garde tes coups de cœur',
    text: "Sauvegarde tes voyages favoris, partage tes souvenirs et laisse des avis aux guides. Plus la communauté grandit, plus l'expérience s'enrichit.",
    cta: 'C\'est parti'
  }
]

const current = computed(() => steps[step.value])

onMounted(() => {
  // Affiche uniquement pour les voyageurs connectés qui n'ont pas vu l'onboarding
  if (!auth.isAuthenticated || !auth.isVoyageur) return
  try {
    if (localStorage.getItem(STORAGE_KEY)) return
  } catch {
    return
  }
  // Léger délai pour ne pas surcharger l'arrivée
  setTimeout(() => { visible.value = true }, 800)
})

function next() {
  if (step.value < steps.length - 1) {
    step.value++
  } else {
    finish()
  }
}

function skip() {
  finish()
}

function finish() {
  try {
    localStorage.setItem(STORAGE_KEY, '1')
  } catch {}
  visible.value = false
}
</script>

<template>
  <transition name="overlay">
    <div v-if="visible" class="onboarding-overlay" @click.self="skip">
      <div class="onboarding-card">
        <button class="skip-btn" @click="skip" aria-label="Passer l'onboarding">✕</button>

        <div class="step-icon">{{ current.icon }}</div>
        <h2>{{ current.title }}</h2>
        <p>{{ current.text }}</p>

        <div class="progress">
          <span
            v-for="(_, i) in steps"
            :key="i"
            class="dot"
            :class="{ active: i === step, done: i < step }"
          ></span>
        </div>

        <div class="actions">
          <button class="btn-skip" @click="skip" v-if="step < steps.length - 1">Plus tard</button>
          <button class="btn-next" @click="next">{{ current.cta }} →</button>
        </div>
      </div>
    </div>
  </transition>
</template>

<style scoped>
.onboarding-overlay {
  position: fixed;
  inset: 0;
  background: rgba(10, 31, 46, 0.65);
  backdrop-filter: blur(6px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 99999;
  padding: var(--space-3);
}

.onboarding-card {
  background: var(--c-surface);
  border-radius: var(--r-lg);
  padding: var(--space-6);
  max-width: 440px;
  width: 100%;
  position: relative;
  box-shadow: 0 32px 80px rgba(0,0,0,0.4);
  text-align: center;
  animation: card-pop 0.4s cubic-bezier(0.18, 0.89, 0.32, 1.28);
}
@keyframes card-pop {
  from { transform: scale(0.85); opacity: 0; }
  to { transform: scale(1); opacity: 1; }
}

.skip-btn {
  position: absolute;
  top: 16px; right: 16px;
  background: var(--c-fond-chaud);
  border: none;
  width: 32px; height: 32px;
  border-radius: 50%;
  cursor: pointer;
  font-size: 14px;
  color: var(--c-texte-doux);
  transition: var(--t-base);
}
.skip-btn:hover { background: var(--c-gris-clair); color: var(--c-primaire); }

.step-icon {
  font-size: 56px;
  margin-bottom: var(--space-3);
  line-height: 1;
}
.onboarding-card h2 {
  font-family: var(--font-display);
  font-size: 28px;
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-2);
}
.onboarding-card p {
  font-size: 16px;
  line-height: 1.6;
  color: var(--c-texte);
  margin-bottom: var(--space-4);
}

.progress {
  display: flex;
  justify-content: center;
  gap: 8px;
  margin-bottom: var(--space-4);
}
.dot {
  width: 8px; height: 8px;
  border-radius: 50%;
  background: var(--c-gris-clair);
  transition: var(--t-base);
}
.dot.active { background: var(--c-accent); width: 24px; border-radius: 4px; }
.dot.done { background: var(--c-primaire); }

.actions {
  display: flex;
  gap: var(--space-2);
  justify-content: center;
}
.btn-skip {
  background: none;
  border: 1px solid var(--c-gris-clair);
  border-radius: var(--r-pill);
  padding: 10px 20px;
  font-family: inherit;
  font-weight: 600;
  color: var(--c-texte-doux);
  cursor: pointer;
  transition: var(--t-base);
}
.btn-skip:hover { border-color: var(--c-primaire); color: var(--c-primaire); }
.btn-next {
  background: var(--c-primaire);
  color: var(--c-fond);
  border: none;
  border-radius: var(--r-pill);
  padding: 10px 24px;
  font-family: inherit;
  font-weight: 700;
  font-size: 15px;
  cursor: pointer;
  transition: var(--t-base);
}
.btn-next:hover {
  background: var(--c-primaire-profond);
  transform: translateY(-1px);
}

.overlay-enter-active, .overlay-leave-active { transition: opacity 0.3s ease; }
.overlay-enter-from, .overlay-leave-to { opacity: 0; }
</style>
