<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount, watch } from 'vue'

/**
 * Visite virtuelle multi-scènes (Pannellum) : navigation aux flèches entre
 * scènes 360°, points d'info (œuvres), et bouton VR stéréo (Three.js, sans WebXR).
 * Piloté par une config JSON :
 *   { firstScene, scenes: [ { id, title, panorama, hotspots: [
 *       { type:'scene', yaw, pitch, target, label } |
 *       { type:'info',  yaw, pitch, title, desc }
 *   ] } ] }
 */

interface Hotspot { type: 'scene' | 'info'; yaw: number; pitch: number; target?: string; label?: string; title?: string; desc?: string }
interface Scene { id: string; title: string; panorama: string; hotspots?: Hotspot[] }
interface TourConfig { firstScene?: string; scenes: Scene[] }

const props = withDefaults(defineProps<{ config: TourConfig; height?: string }>(), { height: '100%' })

const PANNELLUM_CSS = 'https://cdn.jsdelivr.net/npm/pannellum@2.5.6/build/pannellum.css'
const PANNELLUM_JS = 'https://cdn.jsdelivr.net/npm/pannellum@2.5.6/build/pannellum.js'

const paneEl = ref<HTMLDivElement | null>(null)
let viewer: any = null
const currentId = ref<string>('')
const planOpen = ref(false)
const info = ref<{ open: boolean; title: string; desc: string }>({ open: false, title: '', desc: '' })

const scenesById = () => Object.fromEntries((props.config?.scenes || []).map(s => [s.id, s]))

function loadPannellum(): Promise<void> {
  if (!document.querySelector(`link[href="${PANNELLUM_CSS}"]`)) {
    const l = document.createElement('link'); l.rel = 'stylesheet'; l.href = PANNELLUM_CSS; document.head.appendChild(l)
  }
  if ((window as any).pannellum) return Promise.resolve()
  return new Promise((resolve, reject) => {
    const s = document.createElement('script'); s.src = PANNELLUM_JS; s.async = true
    s.onload = () => resolve(); s.onerror = () => reject(new Error('Pannellum failed')); document.head.appendChild(s)
  })
}

const ARROW = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 5v14M6 11l6-6 6 6"/></svg>'
function navTip(div: HTMLElement, args: any) {
  div.classList.add('vt-nav-hs')
  div.innerHTML = `<div class="vt-disc">${ARROW}</div><div class="vt-lbl">${args.label || ''}</div>`
}
function infoTip(div: HTMLElement, args: any) {
  div.classList.add('vt-info-hs')
  div.innerHTML = '<div class="vt-dot">i</div>'
  div.title = args.title || ''
}
function openInfo(_evt: any, args: any) {
  info.value = { open: true, title: args.title || '', desc: args.desc || '' }
}
function closeInfo() { info.value.open = false }

async function initViewer() {
  if (!paneEl.value || !props.config?.scenes?.length) return
  await loadPannellum()
  const pannellum = (window as any).pannellum
  if (!pannellum) return
  if (viewer && viewer.destroy) { try { viewer.destroy() } catch {} }

  const scenesCfg: Record<string, any> = {}
  for (const sc of props.config.scenes) {
    scenesCfg[sc.id] = {
      title: sc.title, type: 'equirectangular', panorama: sc.panorama, hfov: 105,
      hotSpots: (sc.hotspots || []).map(h => h.type === 'scene'
        ? { pitch: h.pitch, yaw: h.yaw, type: 'scene', sceneId: h.target, cssClass: 'vt-nav-hs', createTooltipFunc: navTip, createTooltipArgs: { label: h.label } }
        : { pitch: h.pitch, yaw: h.yaw, type: 'info', cssClass: 'vt-info-hs', createTooltipFunc: infoTip, createTooltipArgs: { title: h.title, desc: h.desc }, clickHandlerFunc: openInfo, clickHandlerArgs: { title: h.title, desc: h.desc } }
      )
    }
  }
  viewer = pannellum.viewer(paneEl.value, {
    default: { firstScene: props.config.firstScene || props.config.scenes[0].id, sceneFadeDuration: 900, showControls: false, compass: false, crossOrigin: 'anonymous', hfov: 105 },
    scenes: scenesCfg
  })
  const refresh = () => { currentId.value = viewer.getScene(); }
  viewer.on('load', refresh)
  viewer.on('scenechange', () => { closeInfo(); setTimeout(refresh, 40) })
}

function goScene(id: string) { if (viewer) { viewer.loadScene(id); planOpen.value = false } }
function resetView() { if (viewer) { viewer.setPitch(0, 1000); viewer.setYaw(0, 1000); viewer.setHfov(105, 1000) } }
function toggleFull() {
  const el: any = paneEl.value?.parentElement || document.documentElement
  if (!document.fullscreenElement) { el.requestFullscreen && el.requestFullscreen() } else { document.exitFullscreen && document.exitFullscreen() }
}

/* ===== VR stéréo (Three.js — fiable iOS/Android, sans WebXR) ===== */
const THREE_JS = 'https://cdn.jsdelivr.net/npm/three@0.128.0/build/three.min.js'
const STEREO_JS = 'https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/effects/StereoEffect.js'
const DEVORI_JS = 'https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/controls/DeviceOrientationControls.js'
const vrLoading = ref(false)
let vrEl: HTMLDivElement | null = null
let vrCtx: any = null
function loadScript(src: string): Promise<void> {
  return new Promise((res, rej) => {
    if ([...document.scripts].some(s => s.src === src)) { res(); return }
    const s = document.createElement('script'); s.src = src; s.async = true; s.onload = () => res(); s.onerror = () => rej(); document.head.appendChild(s)
  })
}
async function loadThree() { const T = () => (window as any).THREE; if (!T()) await loadScript(THREE_JS); if (!T().StereoEffect) await loadScript(STEREO_JS); if (!T().DeviceOrientationControls) await loadScript(DEVORI_JS) }
async function enterVR() {
  if (vrEl || vrLoading.value) return
  const sc = scenesById()[currentId.value] || props.config.scenes[0]
  if (!sc) return
  vrLoading.value = true
  try { await loadThree() } catch { vrLoading.value = false; return }
  const THREE = (window as any).THREE
  const ov = document.createElement('div'); ov.className = 'vt-vr-overlay'
  ov.innerHTML = '<div class="vt-vr-canvas"></div><button class="vt-vr-go">🥽 <span>Entrer en VR</span></button><button class="vt-vr-close" aria-label="Fermer">✕</button><div class="vt-vr-hint">Glissez pour regarder · touchez « Entrer en VR » puis placez le téléphone dans un casque</div>'
  document.body.appendChild(ov); vrEl = ov
  const host = ov.querySelector('.vt-vr-canvas') as HTMLElement
  const W = () => window.innerWidth, H = () => window.innerHeight
  const scene = new THREE.Scene()
  const camera = new THREE.PerspectiveCamera(72, W() / H(), 0.1, 1100)
  const geo = new THREE.SphereGeometry(500, 64, 40); geo.scale(-1, 1, 1)
  const mat = new THREE.MeshBasicMaterial({ color: 0x10212b }); scene.add(new THREE.Mesh(geo, mat))
  const loader = new THREE.TextureLoader(); loader.setCrossOrigin('anonymous')
  loader.load(sc.panorama, (t: any) => { t.minFilter = THREE.LinearFilter; t.generateMipmaps = false; t.wrapS = THREE.ClampToEdgeWrapping; t.wrapT = THREE.ClampToEdgeWrapping; mat.map = t; mat.color.set(0xffffff); mat.needsUpdate = true })
  const renderer = new THREE.WebGLRenderer({ antialias: true }); renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2)); renderer.setSize(W(), H()); host.appendChild(renderer.domElement)
  const effect = new THREE.StereoEffect(renderer); effect.setSize(W(), H())
  let controls: any = null, stereo = false, lon = 0, lat = 0, drag = false, px = 0, py = 0
  const dn = (e: PointerEvent) => { drag = true; px = e.clientX; py = e.clientY }
  const mv = (e: PointerEvent) => { if (!drag || controls) return; lon -= (e.clientX - px) * 0.16; lat += (e.clientY - py) * 0.16; lat = Math.max(-85, Math.min(85, lat)); px = e.clientX; py = e.clientY }
  const up = () => drag = false
  host.addEventListener('pointerdown', dn); window.addEventListener('pointermove', mv); window.addEventListener('pointerup', up)
  const rz = () => { camera.aspect = W() / H(); camera.updateProjectionMatrix(); renderer.setSize(W(), H()); effect.setSize(W(), H()) }
  window.addEventListener('resize', rz); window.addEventListener('orientationchange', rz)
  let raf = 0
  const loop = () => { raf = requestAnimationFrame(loop); if (controls) controls.update(); else { const phi = THREE.MathUtils.degToRad(90 - lat), th = THREE.MathUtils.degToRad(lon); camera.lookAt(500 * Math.sin(phi) * Math.cos(th), 500 * Math.cos(phi), 500 * Math.sin(phi) * Math.sin(th)) } (stereo ? effect : renderer).render(scene, camera) }
  loop()
  vrCtx = { dispose: () => { cancelAnimationFrame(raf); window.removeEventListener('resize', rz); window.removeEventListener('orientationchange', rz); window.removeEventListener('pointermove', mv); window.removeEventListener('pointerup', up); try { controls && controls.dispose && controls.dispose() } catch {} try { renderer.dispose() } catch {} } }
  ;(ov.querySelector('.vt-vr-go') as HTMLElement).addEventListener('click', async () => {
    const DOE: any = (window as any).DeviceOrientationEvent
    if (DOE && typeof DOE.requestPermission === 'function') { try { const p = await DOE.requestPermission(); if (p !== 'granted') return } catch { return } }
    if (!controls) controls = new THREE.DeviceOrientationControls(camera)
    stereo = true;(ov.querySelector('.vt-vr-go') as HTMLElement).style.display = 'none'
    if (ov.requestFullscreen) ov.requestFullscreen().catch(() => {})
  })
  ;(ov.querySelector('.vt-vr-close') as HTMLElement).addEventListener('click', closeVR)
  vrLoading.value = false
}
function closeVR() { if (!vrEl) return; try { vrCtx && vrCtx.dispose && vrCtx.dispose() } catch {} vrCtx = null; try { document.fullscreenElement && document.exitFullscreen() } catch {} vrEl.remove(); vrEl = null }

onMounted(initViewer)
onBeforeUnmount(() => { if (viewer && viewer.destroy) { try { viewer.destroy() } catch {} } closeVR() })
watch(() => props.config, () => initViewer(), { deep: true })
</script>

<template>
  <div class="vt-wrap" :style="{ height: height }">
    <div ref="paneEl" class="vt-pane"></div>

    <div class="vt-top">
      <div class="vt-scene">{{ scenesById()[currentId]?.title || '' }}</div>
      <button class="vt-rooms" @click="planOpen = !planOpen">☰ Plan</button>
    </div>

    <aside class="vt-plan" :class="{ open: planOpen }">
      <h4>Plan de la visite</h4>
      <a v-for="(s, i) in config.scenes" :key="s.id" :class="{ on: s.id === currentId }" @click="goScene(s.id)">
        <span class="n">{{ i + 1 }}</span><span class="t">{{ s.title }}</span>
      </a>
    </aside>

    <div class="vt-ctrl">
      <button class="round" @click="resetView" title="Recentrer">⟳</button>
      <button class="vr" @click="enterVR" :disabled="vrLoading"><span class="ico">🥽</span>{{ vrLoading ? '…' : 'VR' }}</button>
      <button class="round" @click="toggleFull" title="Plein écran">⤢</button>
    </div>

    <aside class="vt-info" :class="{ open: info.open }">
      <button class="close" @click="closeInfo">✕</button>
      <div class="kicker">Œuvre</div>
      <h3>{{ info.title }}</h3>
      <p>{{ info.desc }}</p>
    </aside>
  </div>
</template>

<style scoped>
.vt-wrap { position: relative; width: 100%; border-radius: var(--r-lg, 16px); overflow: hidden; background: #0E1B24; }
.vt-pane { width: 100%; height: 100%; }
.vt-top { position: absolute; top: 0; left: 0; right: 0; z-index: 20; display: flex; align-items: center; gap: 12px; padding: 12px 16px; background: linear-gradient(180deg, rgba(14,27,36,.85), transparent); }
.vt-scene { flex: 1; font-family: Georgia, serif; font-size: 16px; color: #F3EEE4; }
.vt-rooms { background: rgba(19,37,47,.7); border: 1px solid rgba(243,238,228,.16); color: #F3EEE4; font-size: 13px; font-weight: 600; padding: 8px 14px; border-radius: 999px; cursor: pointer; backdrop-filter: blur(8px); }
.vt-rooms:hover { border-color: #C56A3E; }
.vt-plan { position: absolute; top: 54px; right: 14px; z-index: 21; width: min(80vw, 260px); background: rgba(14,27,36,.94); backdrop-filter: blur(16px); border: 1px solid rgba(243,238,228,.16); border-radius: 16px; padding: 14px; transform: translateX(120%); transition: .3s; }
.vt-plan.open { transform: none; }
.vt-plan h4 { font-family: Georgia, serif; font-size: 15px; color: #F3EEE4; margin-bottom: 10px; }
.vt-plan a { display: flex; align-items: center; gap: 11px; padding: 9px 10px; border-radius: 10px; cursor: pointer; color: #F3EEE4; text-decoration: none; }
.vt-plan a:hover { background: rgba(197,106,62,.14); }
.vt-plan a.on { color: #E0A94E; }
.vt-plan a .n { width: 24px; height: 24px; flex: none; border-radius: 50%; border: 1.5px solid #C56A3E; color: #C56A3E; display: grid; place-items: center; font-family: Georgia, serif; font-size: 12px; }
.vt-plan a.on .n { background: #C56A3E; color: #fff; }
.vt-plan a .t { font-size: 14px; }
.vt-ctrl { position: absolute; bottom: 16px; left: 50%; transform: translateX(-50%); z-index: 20; display: flex; gap: 10px; }
.vt-ctrl button { background: rgba(19,37,47,.8); border: 1px solid rgba(243,238,228,.16); color: #F3EEE4; cursor: pointer; backdrop-filter: blur(8px); display: inline-flex; align-items: center; justify-content: center; font-family: inherit; }
.vt-ctrl .round { width: 44px; height: 44px; border-radius: 50%; font-size: 17px; }
.vt-ctrl .round:hover { border-color: #C56A3E; }
.vt-ctrl .vr { height: 44px; padding: 0 18px; border-radius: 999px; font-size: 14px; font-weight: 800; gap: 7px; background: #C56A3E; border-color: transparent; }
.vt-ctrl .vr:disabled { opacity: .6; }
.vt-ctrl .vr .ico { font-size: 16px; }
.vt-info { position: absolute; top: 0; bottom: 0; right: 0; z-index: 30; width: min(90vw, 360px); padding: 26px 22px; background: linear-gradient(200deg, rgba(19,37,47,.96), rgba(14,27,36,.98)); backdrop-filter: blur(16px); border-left: 1px solid rgba(243,238,228,.16); transform: translateX(100%); transition: .35s; display: flex; flex-direction: column; }
.vt-info.open { transform: none; }
.vt-info .close { align-self: flex-end; background: none; border: 1px solid rgba(243,238,228,.16); color: #F3EEE4; width: 36px; height: 36px; border-radius: 50%; cursor: pointer; font-size: 17px; }
.vt-info .kicker { font-size: 11px; letter-spacing: 2px; text-transform: uppercase; color: #E0A94E; font-weight: 700; margin-top: 6px; }
.vt-info h3 { font-family: Georgia, serif; font-size: 23px; color: #F3EEE4; margin: 8px 0 12px; }
.vt-info p { color: #AEB9C0; line-height: 1.65; font-size: 14.5px; }
</style>

<!-- Styles globaux : hotspots (créés par Pannellum) + overlay VR (monté sur body) -->
<style>
.vt-nav-hs { cursor: pointer; transform: translate(-50%, -50%); }
.vt-nav-hs .vt-disc { width: 50px; height: 50px; border-radius: 50%; background: rgba(14,27,36,.55); border: 2px solid #F3EEE4; display: grid; place-items: center; color: #fff; backdrop-filter: blur(3px); transition: .2s; }
.vt-nav-hs .vt-disc svg { width: 25px; height: 25px; }
.vt-nav-hs:hover .vt-disc { background: #C56A3E; border-color: #C56A3E; transform: scale(1.12); }
.vt-nav-hs .vt-lbl { position: absolute; top: 56px; left: 50%; transform: translateX(-50%); white-space: nowrap; font-family: system-ui, sans-serif; font-size: 12px; font-weight: 700; background: rgba(14,27,36,.8); padding: 5px 11px; border-radius: 999px; color: #fff; backdrop-filter: blur(6px); }
.vt-info-hs { cursor: pointer; transform: translate(-50%, -50%); }
.vt-info-hs .vt-dot { width: 32px; height: 32px; border-radius: 50%; background: #E0A94E; color: #3a2606; display: grid; place-items: center; font-family: Georgia, serif; font-weight: 700; font-size: 16px; border: 2px solid #fff; box-shadow: 0 4px 14px rgba(0,0,0,.5); transition: .2s; }
.vt-info-hs:hover .vt-dot { transform: scale(1.15); }
.vt-vr-overlay { position: fixed; inset: 0; z-index: 99999; background: #000; }
.vt-vr-canvas { position: absolute; inset: 0; }
.vt-vr-canvas canvas { display: block; width: 100%; height: 100%; }
.vt-vr-go { position: absolute; left: 50%; bottom: 26px; transform: translateX(-50%); background: #C56A3E; color: #fff; border: none; padding: 14px 26px; border-radius: 999px; font-size: 16px; font-weight: 800; cursor: pointer; display: inline-flex; align-items: center; gap: 8px; box-shadow: 0 12px 30px -10px rgba(0,0,0,.7); }
.vt-vr-close { position: absolute; top: 16px; right: 16px; width: 44px; height: 44px; border-radius: 50%; background: rgba(14,27,36,.7); color: #fff; border: 1px solid rgba(255,255,255,.25); font-size: 20px; cursor: pointer; }
.vt-vr-hint { position: absolute; left: 50%; bottom: 84px; transform: translateX(-50%); color: rgba(255,255,255,.85); font-size: 12.5px; text-align: center; max-width: 90%; text-shadow: 0 2px 8px rgba(0,0,0,.85); pointer-events: none; }
</style>
