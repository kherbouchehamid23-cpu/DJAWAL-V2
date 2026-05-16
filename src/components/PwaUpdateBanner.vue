<script setup lang="ts">
import { useRegisterSW } from 'virtual:pwa-register/vue'
import { ref } from 'vue'

/**
 * Banner non-bloquant affiché quand un nouveau service worker est disponible.
 * L'utilisateur peut :
 *   - Cliquer "Mettre à jour" → recharge la page avec la nouvelle version
 *   - Cliquer "Plus tard"     → masque le banner jusqu'au prochain check (re-affiché au prochain refresh)
 *
 * Compatible avec le mode registerType: 'prompt' configuré dans vite.config.ts.
 * Périodicité du check : toutes les heures (3600s) tant que l'onglet est ouvert.
 */

const CHECK_INTERVAL_MS = 60 * 60 * 1000 // 1 heure

const dismissedThisSession = ref(false)

const {
  needRefresh,
  updateServiceWorker
} = useRegisterSW({
  immediate: true,
  onRegisteredSW(swUrl, registration) {
    // Polling périodique pour détecter une nouvelle version
    if (!registration) return
    setInterval(async () => {
      try {
        // skipWaiting: false → ne s'auto-active pas, on garde le contrôle
        await registration.update()
      } catch (e) {
        console.warn('PWA update check failed:', e)
      }
    }, CHECK_INTERVAL_MS)
  },
  onRegisterError(err) {
    console.warn('PWA SW register error:', err)
  }
})

function apply() {
  // Recharge avec le nouveau SW
  updateServiceWorker(true)
}

function later() {
  // Le banner réapparaîtra au prochain navigateur refresh ou prochain check
  dismissedThisSession.value = true
}
</script>

<template>
  <transition name="pwa-banner">
    <div v-if="needRefresh && !dismissedThisSession" class="pwa-banner" role="status" aria-live="polite">
      <div class="pwa-banner-inner">
        <div class="pwa-icon" aria-hidden="true">↻</div>
        <div class="pwa-text">
          <strong>Nouvelle version disponible</strong>
          <span>Rechargez pour profiter des dernières améliorations.</span>
        </div>
        <div class="pwa-actions">
          <button class="pwa-btn pwa-btn-later" @click="later">Plus tard</button>
          <button class="pwa-btn pwa-btn-update" @click="apply">Mettre à jour</button>
        </div>
      </div>
    </div>
  </transition>
</template>

<style scoped>
.pwa-banner {
  position: fixed;
  bottom: 16px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 2000;
  max-width: 520px;
  width: calc(100% - 32px);
  pointer-events: auto;
}
.pwa-banner-inner {
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 14px;
  background: linear-gradient(135deg, #1F4A36 0%, #0F2419 100%);
  border: 1px solid rgba(212, 168, 68, 0.45);
  border-radius: 14px;
  padding: 14px 18px;
  color: #FAF7F2;
  box-shadow: 0 18px 50px rgba(0, 0, 0, 0.45);
  font-family: 'Inter', sans-serif;
}
.pwa-icon {
  width: 36px; height: 36px;
  background: rgba(212, 168, 68, 0.18);
  border: 1px solid rgba(212, 168, 68, 0.5);
  color: #E8B96B;
  border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  font-size: 18px;
  font-weight: 600;
  flex-shrink: 0;
}
.pwa-text {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}
.pwa-text strong {
  font-size: 13.5px;
  color: #FAF7F2;
  font-weight: 600;
}
.pwa-text span {
  font-size: 12px;
  color: rgba(250, 247, 242, 0.7);
  line-height: 1.35;
}
.pwa-actions {
  display: flex;
  gap: 8px;
  flex-shrink: 0;
}
.pwa-btn {
  padding: 8px 14px;
  border-radius: 999px;
  font-size: 12.5px;
  font-weight: 600;
  cursor: pointer;
  font-family: inherit;
  border: 1.5px solid transparent;
  transition: all 0.15s;
  white-space: nowrap;
}
.pwa-btn-later {
  background: transparent;
  color: rgba(250, 247, 242, 0.7);
  border-color: rgba(250, 247, 242, 0.25);
}
.pwa-btn-later:hover { background: rgba(255, 255, 255, 0.08); color: #FAF7F2; }
.pwa-btn-update {
  background: #D4A844;
  color: #0F2419;
}
.pwa-btn-update:hover { background: #E8B96B; transform: translateY(-1px); }

/* Animation entrée / sortie */
.pwa-banner-enter-active,
.pwa-banner-leave-active {
  transition: all 0.35s cubic-bezier(.2, .9, .2, 1);
}
.pwa-banner-enter-from,
.pwa-banner-leave-to {
  opacity: 0;
  transform: translateX(-50%) translateY(20px);
}

/* Mobile : empile actions sous le texte si très étroit */
@media (max-width: 480px) {
  .pwa-banner { bottom: 80px; } /* éviter chevauchement BottomNav */
  .pwa-banner-inner { grid-template-columns: auto 1fr; row-gap: 10px; }
  .pwa-actions { grid-column: 1 / -1; justify-content: flex-end; }
}
</style>
