<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount, watch } from 'vue'

/**
 * Composant visite virtuelle 360° avec Pannellum (CDN, open source).
 * - panoramaUrl : URL d'une image equirectangulaire (.jpg/.webp)
 * - virtualTourUrl : URL d'un tour HTML externe (Matterport, krpano, etc.)
 *
 * Priorité : panoramaUrl en natif (rendu Pannellum), sinon iframe vers virtualTourUrl.
 * + Bouton « VR » : rendu stéréoscopique Three.js (Cardboard) fiable sur iOS/Android, sans WebXR.
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
  } catch {
    // URL invalide, on retourne tel quel
  }
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

// ============================================================
// RÉALITÉ VIRTUELLE — rendu stéréoscopique Three.js (Cardboard)
// Pas de WebXR (absent sur iOS/Safari) : sphère équirectangulaire +
// StereoEffect + DeviceOrientationControls (gyroscope). Chargé à la demande.
// ============================================================
const THREE_JS = 'https://cdn.jsdelivr.net/npm/three@0.128.0/build/three.min.js'
const STEREO_JS = 'https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/effects/StereoEffect.js'
const DEVORI_JS = 'https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/controls/DeviceOrientationControls.js'

const vrEl = ref<HTMLDivElement | null>(null)
const vrLoading = ref(false)
let vrCtx: any = null

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

async function loadThree(): Promise<void> {
  const T = () => (window as any).THREE
  if (!T()) await loadScript(THREE_JS)
  if (!T().StereoEffect) await loadScript(STEREO_JS)
  if (!T().DeviceOrientationControls) await loadScript(DEVORI_JS)
}

async function enterVR() {
  if (!props.panoramaUrl || vrEl.value) return
  vrLoading.value = true
  try { await loadThree() } catch { vrLoading.value = false; return }
  const THREE = (window as any).THREE

  const overlay = document.createElement('div')
  overlay.className = 'djawal-vr-overlay'
  overlay.innerHTML = `
    <div class="djawal-vr-canvas"></div>
    <div class="djawal-vr-err" hidden>Impossible de charger le panorama pour la VR.</div>
    <button class="djawal-vr-go" type="button">🥽 <span>Entrer en VR</span></button>
    <button class="djawal-vr-close" type="button" aria-label="Fermer">✕</button>
    <div class="djawal-vr-hint">Glissez pour regarder · touchez « Entrer en VR » puis placez le téléphone dans un casque Cardboard</div>
  `
  document.body.appendChild(overlay)
  vrEl.value = overlay
  const host = overlay.querySelector('.djawal-vr-canvas') as HTMLElement
  const errEl = overlay.querySelector('.djawal-vr-err') as HTMLElement

  const W = () => window.innerWidth
  const H = () => window.innerHeight

  const scene = new THREE.Scene()
  const camera = new THREE.PerspectiveCamera(72, W() / H(), 0.1, 1100)
  const geo = new THREE.SphereGeometry(500, 64, 40)
  geo.scale(-1, 1, 1) // on regarde l'intérieur de la sphère
  const mat = new THREE.MeshBasicMaterial({ color: 0x1a2733 })
  const mesh = new THREE.Mesh(geo, mat)
  scene.add(mesh)

  const loader = new THREE.TextureLoader()
  loader.setCrossOrigin('anonymous')
  const applyTex = (tex: any) => {
    tex.minFilter = THREE.LinearFilter          // NPOT-safe : pas de mipmaps
    tex.generateMipmaps = false
    tex.wrapS = THREE.ClampToEdgeWrapping
    tex.wrapT = THREE.ClampToEdgeWrapping
    mat.map = tex
    mat.color.set(0xffffff)
    mat.needsUpdate = true
  }
  const primary = proxyIfNeeded(props.panoramaUrl)
  loader.load(primary, applyTex, undefined, () => {
    // Échec (souvent CORS) → on retente via l'image-proxy (ajoute les en-têtes CORS)
    const proxied = `${IMAGE_PROXY_URL}?url=${encodeURIComponent(props.panoramaUrl as string)}`
    loader.load(proxied, applyTex, undefined, () => { errEl.hidden = false })
  })

  const renderer = new THREE.WebGLRenderer({ antialias: true })
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2))
  renderer.setSize(W(), H())
  host.appendChild(renderer.domElement)
  const effect = new THREE.StereoEffect(renderer)
  effect.setSize(W(), H())

  let controls: any = null
  let stereo = false

  // Regard à la souris/tactile avant activation du gyroscope
  let lon = 0, lat = 0, dragging = false, px = 0, py = 0
  const onDown = (e: PointerEvent) => { dragging = true; px = e.clientX; py = e.clientY }
  const onMove = (e: PointerEvent) => {
    if (!dragging || controls) return
    lon -= (e.clientX - px) * 0.16
    lat += (e.clientY - py) * 0.16
    lat = Math.max(-85, Math.min(85, lat))
    px = e.clientX; py = e.clientY
  }
  const onUp = () => { dragging = false }
  host.addEventListener('pointerdown', onDown)
  window.addEventListener('pointermove', onMove)
  window.addEventListener('pointerup', onUp)

  const onResize = () => {
    camera.aspect = W() / H()
    camera.updateProjectionMatrix()
    renderer.setSize(W(), H())
    effect.setSize(W(), H())
  }
  window.addEventListener('resize', onResize)
  window.addEventListener('orientationchange', onResize)

  let raf = 0
  const animate = () => {
    raf = requestAnimationFrame(animate)
    if (controls) {
      controls.update()
    } else {
      const phi = THREE.MathUtils.degToRad(90 - lat)
      const theta = THREE.MathUtils.degToRad(lon)
      camera.lookAt(
        500 * Math.sin(phi) * Math.cos(theta),
        500 * Math.cos(phi),
        500 * Math.sin(phi) * Math.sin(theta)
      )
    }
    ;(stereo ? effect : renderer).render(scene, camera)
  }
  animate()

  vrCtx = {
    dispose: () => {
      cancelAnimationFrame(raf)
      window.removeEventListener('resize', onResize)
      window.removeEventListener('orientationchange', onResize)
      window.removeEventListener('pointermove', onMove)
      window.removeEventListener('pointerup', onUp)
      try { if (controls && controls.dispose) controls.dispose() } catch {}
      try { renderer.dispose() } catch {}
      try { geo.dispose(); mat.dispose(); if (mat.map) mat.map.dispose() } catch {}
    }
  }

  const goBtn = overlay.querySelector('.djawal-vr-go') as HTMLButtonElement
  goBtn.addEventListener('click', async () => {
    const DOE: any = (window as any).DeviceOrientationEvent
    if (DOE && typeof DOE.requestPermission === 'function') {
      try { const p = await DOE.requestPermission(); if (p !== 'granted') return } catch { return }
    }
    if (!controls) { controls = new THREE.DeviceOrientationControls(camera) }
    stereo = true
    goBtn.style.display = 'none'
    if (overlay.requestFullscreen) { overlay.requestFullscreen().catch(() => {}) }
  })
  overlay.querySelector('.djawal-vr-close')?.addEventListener('click', closeVR)
  vrLoading.value = false
}

function closeVR() {
  if (!vrEl.value) return
  try { if (vrCtx && vrCtx.dispose) vrCtx.dispose() } catch {}
  vrCtx = null
  try { if (document.fullscreenElement) document.exitFullscreen() } catch {}
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
.djawal-vr-canvas { position: absolute; inset: 0; }
.djawal-vr-canvas canvas { display: block; width: 100%; height: 100%; }
.djawal-vr-err {
  position: absolute; top: 50%; left: 50%; transform: translate(-50%,-50%);
  color: #fff; font-family: sans-serif; font-size: 14px; text-align: center;
  background: rgba(10,31,46,0.8); padding: 14px 18px; border-radius: 12px; z-index: 100001;
}
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
