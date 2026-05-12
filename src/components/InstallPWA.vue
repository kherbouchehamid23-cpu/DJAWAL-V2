<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount } from 'vue'

/**
 * Bouton "Installer l'app" qui apparaît quand le navigateur déclenche
 * `beforeinstallprompt`. Stocke dans localStorage le statut pour ne pas
 * réafficher après une installation ou un refus.
 */

const STORAGE_KEY = 'djawal_pwa_install_state'

const visible = ref(false)
const installing = ref(false)
const deferredPrompt = ref<any>(null)
const showIosHint = ref(false)

function isStandalone(): boolean {
  // PWA déjà installée
  return (
    window.matchMedia('(display-mode: standalone)').matches ||
    (window.navigator as any).standalone === true
  )
}

function isIOS(): boolean {
  return /iPad|iPhone|iPod/.test(navigator.userAgent) && !(window as any).MSStream
}

function isAndroid(): boolean {
  return /Android/.test(navigator.userAgent)
}

function loadState(): 'dismissed' | 'installed' | null {
  try {
    const v = localStorage.getItem(STORAGE_KEY)
    return v as any
  } catch { return null }
}

function saveState(v: 'dismissed' | 'installed') {
  try { localStorage.setItem(STORAGE_KEY, v) } catch {}
}

function onBeforeInstall(e: Event) {
  e.preventDefault()
  deferredPrompt.value = e
  if (loadState() === 'dismissed' || loadState() === 'installed') return
  if (isStandalone()) return
  visible.value = true
}

function onInstalled() {
  saveState('installed')
  visible.value = false
}

async function install() {
  if (!deferredPrompt.value) {
    // iOS : pas de prompt natif, montrer les instructions
    if (isIOS()) {
      showIosHint.value = true
      return
    }
    return
  }
  installing.value = true
  deferredPrompt.value.prompt()
  const choice = await deferredPrompt.value.userChoice
  installing.value = false
  if (choice.outcome === 'accepted') {
    saveState('installed')
  } else {
    saveState('dismissed')
  }
  visible.value = false
  deferredPrompt.value = null
}

function dismiss() {
  saveState('dismissed')
  visible.value = false
  showIosHint.value = false
}

onMounted(() => {
  if (isStandalone()) return
  const state = loadState()
  if (state === 'installed' || state === 'dismissed') return

  // iOS : pas de beforeinstallprompt → on affiche un bouton qui ouvre les instructions
  if (isIOS()) {
    setTimeout(() => { visible.value = true }, 4000)
    return
  }

  window.addEventListener('beforeinstallprompt', onBeforeInstall)
  window.addEventListener('appinstalled', onInstalled)
})

onBeforeUnmount(() => {
  window.removeEventListener('beforeinstallprompt', onBeforeInstall)
  window.removeEventListener('appinstalled', onInstalled)
})
</script>

<template>
  <transition name="slide-up">
    <div v-if="visible" class="install-card">
      <button class="dismiss-btn" @click="dismiss" aria-label="Fermer">✕</button>
      <div class="install-icon">📱</div>
      <div class="install-content">
        <strong>Installer Djawal</strong>
        <p>Ajoutez l'app à votre écran d'accueil pour un accès instantané, même hors-ligne.</p>
        <button class="install-btn" @click="install" :disabled="installing">
          {{ installing ? 'Installation…' : (isIOS() ? '📋 Voir comment installer' : '⬇️ Installer l\'app') }}
        </button>
      </div>
    </div>
  </transition>

  <!-- Instructions iOS -->
  <transition name="fade">
    <div v-if="showIosHint" class="ios-hint-overlay" @click.self="showIosHint = false">
      <div class="ios-hint-card">
        <button class="dismiss-btn" @click="showIosHint = false">✕</button>
        <h3>Installer Djawal sur iPhone / iPad</h3>
        <ol>
          <li>
            <span class="step-num">1</span>
            <div>Touchez le bouton <strong>Partager</strong> en bas de Safari
              <span class="ios-icon">⬆️</span>
            </div>
          </li>
          <li>
            <span class="step-num">2</span>
            <div>Faites défiler et choisissez <strong>« Sur l'écran d'accueil »</strong></div>
          </li>
          <li>
            <span class="step-num">3</span>
            <div>Touchez <strong>Ajouter</strong> en haut à droite. Djawal apparaît comme une vraie app.</div>
          </li>
        </ol>
        <button class="install-btn" @click="dismiss">J'ai compris</button>
      </div>
    </div>
  </transition>
</template>

<style scoped>
.install-card {
  position: fixed;
  bottom: 96px;
  left: 24px;
  z-index: 9998;
  background: var(--c-surface);
  border-radius: var(--r-lg);
  padding: 16px 18px;
  box-shadow: 0 16px 40px rgba(10, 31, 46, 0.25);
  display: flex;
  align-items: flex-start;
  gap: 12px;
  max-width: 360px;
  border-left: 4px solid var(--c-accent);
}
.install-icon {
  font-size: 36px;
  flex-shrink: 0;
  line-height: 1;
}
.install-content { flex: 1; }
.install-content strong {
  display: block;
  color: var(--c-primaire-profond);
  font-size: 15px;
  margin-bottom: 4px;
}
.install-content p {
  color: var(--c-texte);
  font-size: 13px;
  line-height: 1.4;
  margin-bottom: 10px;
}
.install-btn {
  background: var(--c-primaire);
  color: var(--c-fond);
  border: none;
  border-radius: var(--r-pill);
  padding: 8px 16px;
  font-family: inherit;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
  transition: var(--t-base);
}
.install-btn:hover:not(:disabled) {
  background: var(--c-primaire-profond);
  transform: translateY(-1px);
}
.install-btn:disabled { opacity: 0.6; cursor: not-allowed; }

.dismiss-btn {
  position: absolute;
  top: 8px; right: 8px;
  background: var(--c-fond-chaud);
  border: none;
  width: 24px; height: 24px;
  border-radius: 50%;
  cursor: pointer;
  font-size: 11px;
  color: var(--c-texte-doux);
  transition: var(--t-base);
}
.dismiss-btn:hover { background: var(--c-gris-clair); }

/* === IOS HINT === */
.ios-hint-overlay {
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
.ios-hint-card {
  background: var(--c-surface);
  border-radius: var(--r-lg);
  padding: var(--space-5);
  max-width: 440px;
  width: 100%;
  position: relative;
  box-shadow: 0 32px 80px rgba(0,0,0,0.4);
}
.ios-hint-card h3 {
  font-family: var(--font-display);
  font-size: 22px;
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-3);
}
.ios-hint-card ol {
  list-style: none;
  padding: 0;
  margin: 0 0 var(--space-4);
}
.ios-hint-card li {
  display: flex;
  gap: 12px;
  padding: 10px 0;
  align-items: flex-start;
  font-size: 14px;
  line-height: 1.5;
}
.step-num {
  background: var(--c-accent);
  color: var(--c-fond);
  width: 28px; height: 28px;
  border-radius: 50%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  flex-shrink: 0;
  font-size: 14px;
}
.ios-icon {
  display: inline-block;
  background: var(--c-fond-chaud);
  padding: 2px 8px;
  border-radius: 4px;
  margin-left: 4px;
  font-size: 12px;
}

.slide-up-enter-active, .slide-up-leave-active { transition: all 0.4s cubic-bezier(0.18, 0.89, 0.32, 1.28); }
.slide-up-enter-from, .slide-up-leave-to { opacity: 0; transform: translateY(60px); }

.fade-enter-active, .fade-leave-active { transition: opacity 0.25s; }
.fade-enter-from, .fade-leave-to { opacity: 0; }

@media (max-width: 600px) {
  .install-card {
    left: 12px; right: 12px;
    bottom: 80px;
    max-width: none;
  }
}
</style>
