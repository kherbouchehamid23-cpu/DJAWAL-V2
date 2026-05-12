<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount, watch } from 'vue'

/**
 * Composant visite virtuelle 360° avec Pannellum (CDN, open source).
 * - panoramaUrl : URL d'une image equirectangulaire (.jpg/.webp)
 * - virtualTourUrl : URL d'un tour HTML externe (Matterport, krpano, etc.)
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

const IMAGE_PROXY_URL = 'https://upysjmymsafqmrbgzhva.supabase.co/functions/v1/image-proxy'

function proxyIfNeeded(url: string): string {
  if (!url) return url
  const needsProxy = ['djawal.bilnov.com', 'bilnov.com']
  try {
    const u = new URL(url)
    if (needsProxy.some(d => u.hostname === d || u.hostname.endsWith('.' + d))) {
      return `${IMAGE_PROXY_URL}?url=${encodeURIComponent(url)}`
    }
  } catch {}
  return url
}

async function loadPannellum(): Promise<void> {
  if (!document.querySelector(`link[href="${PANNELLUM_CSS}"]`)) {
    const link = document.createElement('link')
    link.rel = 'stylesheet'
    link.href = PANNELLUM_CSS
    document.head.appendChild(link)
  }
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
    showFullscreenCtrl: false,
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

function onFSChange() {
  fullscreen.value = !!document.fullscreenElement
}

onMounted(() => {
  if (props.panoramaUrl) initViewer()
  document.addEventListener('fullscreenchange', onFSChange)
})

onBeforeUnmount(() => {
  if (viewer.value && viewer.value.destroy) {
    try { viewer.value.destroy() } catch {}
  }
  document.removeEventListener('fullscreenchange', onFSChange)
})

watch(() => props.panoramaUrl, () => {
  if (props.panoramaUrl) initViewer()
})
</script>

<template>
  <div class="panorama-wrap" :style="{ height: height || '420px' }">
    <template v-if="panoramaUrl">
      <div ref="containerEl" class="panorama-viewer"></div>
      <div class="panorama-overlay">
        <div class="badge-360">
          <span class="badge-icon">🌐</span>
          <span>Visite 360°</span>
        </div>
        <button class="fs-btn" @click="toggleFullscreen" :title="fullscreen ? 'Quitter' : 'Plein écran'">
          {{ fullscreen ? '⤓' : '⤢' }}
        </button>
      </div>
      <div v-if="!loaded" class="panorama-loading">
        <div class="spinner"></div>
        <p>Chargement de la visite 360°…</p>
      </div>
    </template>

    <template v-else-if="virtualTourUrl">
      <iframe
        :src="virtualTourUrl"
        class="panorama-iframe"
        allow="fullscreen; xr-spatial-tracking; accelerometer; gyroscope"
        :title="title || 'Visite virtuelle'"
      ></iframe>
      <div class="panorama-overlay">
        <div class="badge-360">
          <span class="badge-icon">🎥</span>
          <span>Visite virtuelle</span>
        </div>
        <a :href="virtualTourUrl" target="_blank" rel="noopener" class="fs-btn" title="Ouvrir en plein écran">⤢</a>
      </div>
    </template>

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
.panorama-overlay {
  position: absolute;
  top: 12px; left: 12px; right: 12px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  pointer-events: none;
  z-index: 10;
}
.badge-360 {
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
}
.badge-icon { font-size: 14px; }
.fs-btn {
  pointer-events: auto;
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
}
.fs-btn:hover { background: var(--c-primaire); transform: scale(1.05); }
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
