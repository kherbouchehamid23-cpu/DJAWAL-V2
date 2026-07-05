<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount, watch } from 'vue'

/**
 * Composant visite virtuelle 360° avec Pannellum (CDN, open source).
 * - panoramaUrl : URL d'une image equirectangulaire (.jpg/.webp)
 * - virtualTourUrl : URL d'un tour HTML externe (Matterport, krpano, etc.)
 *
 * Priorité : panoramaUrl en natif (rendu Pannellum), sinon iframe vers virtualTourUrl.
 */

const props = defineProps<{
  panoramaUrl?: string | null
  virtualTourUrl?: string | null
  title?: string
  height?: string
}>()

const containerEl = ref<HTMLDivElement | null>(null)
const viewer = ref<any>(null)
const loaded = ref(false)
const fullscreen = ref(false)

const PANNELLUM_CSS = 'https://cdn.jsdelivr.net/npm/pannellum@2.5.6/build/pannellum.css'
const PANNELLUM_JS = 'https://cdn.jsdelivr.net/npm/pannellum@2.5.6/build/pannellum.js'

/**
 * Proxifie les URLs d'images sans CORS via notre Edge Function image-proxy.
 * Nécessaire pour les images bilnov.com qui ne servent pas Access-Control-Allow-Origin.
 */
const IMAGE_PROXY_URL = 'https://upysjmymsafqmrbgzhva.supabase.co/functions/v1/image-proxy'

function proxyIfNeeded(url: string): string {
  if (!url) return url
  const needsProxy = ['djawal.bilnov.com', 'bilnov.com']
  try {
    const u = new URL(url)
    if (needsProxy.some(d => u.hostname === d || u.hostname.endsWith('.' + d))) {
      return `${IMAGE_PROXY_URL}?url=${encodeURIComponent(url)}`
    }
  } catch {
    // URL invalide, on retourne tel quel
  }
  return url
}

async function loadPannellum(): Promise<void> {
  // Inject CSS if missing
  if (!document.querySelector(`link[href="${PANNELLUM_CSS}"]`)) {
    const link = document.createElement('link')
    link.rel = 'stylesheet'
    link.href = PANNELLUM_CSS
    document.head.appendChild(link)
  }
  // Inject JS if missing
  if ((window as any).pannellum) return
  return new Promise((resolve, reject) => {
    const script = document.createElement('script')
    script.src = PANNELLUM_JS
    script.async = true
    script.onload = () => resolve()
    script.onerror = () => reject(new Error('Pannellum failed to load'))
    document.head.appendChild(script)
  })
}

async function initViewer() {
  if (!props.panoramaUrl || !containerEl.value) return

  await loadPannellum()
  const pannellum = (window as any).pannellum
  if (!pannellum) return

  // Destroy previous instance if any
  if (viewer.value && viewer.value.destroy) {
    try { viewer.value.destroy() } catch {}
  }

  viewer.value = pannellum.viewer(containerEl.value, {
    type: 'equirectangular',
    panorama: proxyIfNeeded(props.panoramaUrl),
    autoLoad: true,
    autoRotate: -2,
    compass: true,
    showZoomCtrl: true,
    showFullscreenCtrl: false, // on gère nous-mêmes
    hotSpotDebug: false,
    crossOrigin: 'anonymous'
  })
  loaded.value = true
}

function toggleFullscreen() {
  if (!containerEl.value) return
  if (!fullscreen.value) {
    if (containerEl.value.requestFullscreen) {
      containerEl.value.requestFullscreen()
    }
    fullscreen.value = true
  } else {
    if (document.exitFullscreen) document.exitFullscreen()
    fullscreen.value = false
  }
}

// ===== Réalité virtuelle (WebXR via A-Frame, chargé à la demande) =====
const AFRAME_JS = 'https://aframe.io/releases/1.5.0/aframe.min.js'
const WEBXR_POLYFILL = 'https://cdn.jsdelivr.net/npm/webxr-polyfill@2.0.3/build/webxr-polyfill.min.js'
const vrEl = ref<HTMLDivElement | null>(null)
const vrLoading = ref(false)

function loadScript(src: string): Promise<void> {
  return new Promise((resolve, reject) => {
    if ([...document.scripts].some(s => s.src === src)) { resolve(); return }
    const s = document.createElement('script')
    s.src = src
    s.async = true
    s.onload = () => resolve()
    s.onerror = () => reject(new Error('Script failed: ' + src))
    document.head.appendChild(s)
  })
}

/**
 * Charge le polyfill WebXR (pour iOS/Safari sans WebXR natif → mode Cardboard stéréoscopique),
 * PUIS A-Frame. Sur Android/Chrome (WebXR natif présent) le polyfill est ignoré.
 * L'ordre importe : le polyfill doit être instancié avant qu'A-Frame ne lise navigator.xr.
 */
async function loadVR(): Promise<void> {
  if (!(navigator as any).xr && !(window as any).__djawalXRPolyfill) {
    try {
      await loadScript(WEBXR_POLYFILL)
      const WP = (window as any).WebXRPolyfill
      if (WP) { new WP(); (window as any).__djawalXRPolyfill = true }
    } catch {
      // Pas de polyfill disponible : on retombera sur le suivi gyroscope (magic window).
    }
  }
  if (!(window as any).AFRAME) await loadScript(AFRAME_JS)
}

async function enterVR() {
  if (!props.panoramaUrl || vrEl.value) return
  vrLoading.value = true
  try {
    await loadVR()
  } catch {
    vrLoading.value = false
    return
  }
  const src = proxyIfNeeded(props.panoramaUrl)
  const overlay = document.createElement('div')
  overlay.className = 'djawal-vr-overlay'
  overlay.innerHTML = `
    <a-scene embedded vr-mode-ui="enabled: true"
             device-orientation-permission-ui="enabled: true"
             loading-screen="dotsColor: #C04A3A; backgroundColor: #0A1F2E"
             style="width:100%;height:100%;display:block">
      <a-assets timeout="30000"><img id="djawal-vr-pano" crossorigin="anonymous" src="${src}"></a-assets>
      <a-sky src="#djawal-vr-pano" rotation="0 -90 0"></a-sky>
      <a-camera></a-camera>
    </a-scene>
    <button class="djawal-vr-go" type="button">🥽 <span>Entrer en VR</span></button>
    <button class="djawal-vr-close" type="button" aria-label="Fermer">✕</button>
    <div class="djawal-vr-hint">Bougez le téléphone pour regarder autour · glissez-le dans un casque pour la VR</div>
  `
  document.body.appendChild(overlay)
  vrEl.value = overlay
  vrLoading.value = false
  const scene: any = overlay.querySelector('a-scene')
  overlay.querySelector('.djawal-vr-close')?.addEventListener('click', closeVR)
  overlay.querySelector('.djawal-vr-go')?.addEventListener('click', () => {
    try { scene && scene.enterVR && scene.enterVR() } catch {}
  })
}

function closeVR() {
  if (!vrEl.value) return
  try {
    const scene: any = vrEl.value.querySelector('a-scene')
    if (scene && scene.is && scene.is('vr-mode') && scene.exitVR) scene.exitVR()
  } catch {}
  vrEl.value.remove()
  vrEl.value = null
}

onMounted(() => {
  if (props.panoramaUrl) initViewer()
  document.addEventListener('fullscreenchange', onFSChange)
})

onBeforeUnmount(() => {
  if (viewer.value && viewer.value.destroy) {
    try { viewer.value.destroy() } catch {}
  }
  closeVR()
  document.removeEventListener('fullscreenchange', onFSChange)
})

function onFSChange() {
  fullscreen.value = !!document.fullscreenElement
}

watch(() => props.panoramaUrl, () => {
  if (props.panoramaUrl) initViewer()
})
</script>

<template>
  <div class="panorama-wrap" :style="{ height: height || '420px' }">
    <!-- Cas 1 : image equirectangulaire → Pannellum -->
    <template v-if="panoramaUrl">
      <div ref="containerEl" class="panorama-viewer"></div>
      <div class="badge-360">
        <span class="badge-icon">🌐</span>
        <span>Visite 360°</span>
      </div>
      <button class="vr-btn" @click="enterVR" :disabled="vrLoading" title="Voir en réalité virtuelle">
        <span class="vr-ico">🥽</span><span>{{ vrLoading ? '…' : 'VR' }}</span>
      </button>
      <button class="fs-btn" @click="toggleFullscreen" :title="fullscreen ? 'Quitter' : 'Plein écran'">
        {{ fullscreen ? '⤓' : '⤢' }}
      </button>
      <div v-if="!loaded" class="panorama-loading">
        <div class="spinner"></div>
        <p>Chargement de la visite 360°…</p>
      </div>
    </template>

    <!-- Cas 2 : URL externe → iframe -->
    <template v-else-if="virtualTourUrl">
      <iframe
        :src="virtualTourUrl"
        class="panorama-iframe"
        allow="fullscreen; xr-spatial-tracking; accelerometer; gyroscope"
        :title="title || 'Visite virtuelle'"
      ></iframe>
      <div class="badge-360">
        <span class="badge-icon">🎥</span>
        <span>Visite virtuelle</span>
      </div>
      <a :href="virtualTourUrl" target="_blank" rel="noopener" class="fs-btn" title="Ouvrir en plein écran">⤢</a>
    </template>

    <!-- Aucun panorama disponible -->
    <div v-else class="no-panorama">
      <span>🌐</span>
      <p>Pas encore de visite virtuelle disponible.</p>
    </div>
  </div>
</template>

<style scoped>
.panorama-wrap {
  position: relative;
  width: 100%;
  border-radius: var(--r-lg);
  overflow: hidden;
  background: var(--c-fond-chaud);
  box-shadow: var(--ombre-douce);
}
.panorama-viewer, .panorama-iframe {
  width: 100%;
  height: 100%;
  border: none;
  display: block;
}

/* Badge titre en bas-gauche, FS en bas-droite — laisse les contrôles zoom Pannellum libres en haut */
.badge-360 {
  position: absolute;
  bottom: 14px; left: 14px;
  background: rgba(10, 31, 46, 0.85);
  color: var(--c-fond);
  padding: 6px 14px;
  border-radius: var(--r-pill);
  font-size: 12px;
  font-weight: 700;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  backdrop-filter: blur(8px);
  z-index: 10;
  pointer-events: none;
}
.badge-icon { font-size: 14px; }

.fs-btn {
  position: absolute;
  bottom: 14px; right: 14px;
  background: rgba(10, 31, 46, 0.85);
  color: var(--c-fond);
  border: none;
  width: 36px; height: 36px;
  border-radius: 50%;
  cursor: pointer;
  font-size: 18px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  text-decoration: none;
  transition: var(--t-base);
  backdrop-filter: blur(8px);
  z-index: 10;
}
.fs-btn:hover { background: var(--c-primaire); transform: scale(1.05); }

/* Bouton VR */
.vr-btn {
  position: absolute;
  bottom: 14px; right: 58px;
  background: var(--c-primaire, #C04A3A);
  color: #fff;
  border: none;
  height: 36px;
  padding: 0 14px;
  border-radius: var(--r-pill, 999px);
  cursor: pointer;
  font-size: 13px;
  font-weight: 800;
  letter-spacing: 0.04em;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  z-index: 10;
  box-shadow: 0 6px 16px -6px rgba(0,0,0,0.5);
  transition: var(--t-base, 0.2s);
}
.vr-btn:hover { transform: scale(1.05); filter: brightness(1.06); }
.vr-btn:disabled { opacity: 0.6; cursor: default; }
.vr-ico { font-size: 15px; }

.panorama-loading {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: var(--space-2);
  background: rgba(250, 247, 242, 0.95);
  z-index: 5;
  color: var(--c-texte-doux);
}
.spinner {
  width: 48px; height: 48px;
  border: 4px solid var(--c-fond-chaud);
  border-top-color: var(--c-accent);
  border-radius: 50%;
  animation: spin 1s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }

.no-panorama {
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 8px;
  color: var(--c-texte-doux);
  font-style: italic;
}
.no-panorama span { font-size: 48px; opacity: 0.4; }
</style>

<!-- Styles globaux : l'overlay VR est monté sur <body>, hors portée du scoped -->
<style>
.djawal-vr-overlay { position: fixed; inset: 0; z-index: 99999; background: #000; }
.djawal-vr-overlay a-scene { width: 100%; height: 100%; }
.djawal-vr-go {
  position: absolute; left: 50%; bottom: 26px; transform: translateX(-50%);
  background: #C04A3A; color: #fff; border: none;
  padding: 14px 26px; border-radius: 999px;
  font-size: 16px; font-weight: 800; cursor: pointer;
  display: inline-flex; align-items: center; gap: 8px;
  box-shadow: 0 12px 30px -10px rgba(0,0,0,0.7); z-index: 100000;
}
.djawal-vr-go:hover { filter: brightness(1.06); }
.djawal-vr-close {
  position: absolute; top: 16px; right: 16px;
  width: 44px; height: 44px; border-radius: 50%;
  background: rgba(10,31,46,0.7); color: #fff;
  border: 1px solid rgba(255,255,255,0.25);
  font-size: 20px; cursor: pointer; z-index: 100000;
  -webkit-backdrop-filter: blur(6px); backdrop-filter: blur(6px);
}
.djawal-vr-close:hover { background: rgba(10,31,46,0.9); }
.djawal-vr-hint {
  position: absolute; left: 50%; bottom: 84px; transform: translateX(-50%);
  color: rgba(255,255,255,0.85); font-size: 12.5px; text-align: center;
  max-width: 90%; z-index: 100000; pointer-events: none;
  text-shadow: 0 2px 8px rgba(0,0,0,0.85);
}
</style>
