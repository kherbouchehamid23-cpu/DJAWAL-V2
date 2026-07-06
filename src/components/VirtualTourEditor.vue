<script setup lang="ts">
import { ref, reactive, computed, watch, onMounted, onBeforeUnmount, nextTick } from 'vue'

/**
 * Éditeur VISUEL de visite virtuelle.
 * On clique dans le panorama pour poser une flèche (vers une autre scène) ou un
 * point d'info. Les coordonnées yaw/pitch sont capturées au clic
 * (viewer.mouseEventToCoords), l'utilisateur n'écrit aucun JSON.
 * Le composant émet la config complète via v-model.
 */

interface Hotspot { type: 'scene' | 'info'; yaw: number; pitch: number; target?: string; label?: string; title?: string; desc?: string }
interface Scene { id: string; title: string; panorama: string; hotspots: Hotspot[] }
interface TourConfig { firstScene?: string; scenes: Scene[] }

const props = defineProps<{ modelValue: TourConfig }>()
const emit = defineEmits<{ (e: 'update:modelValue', v: TourConfig): void }>()

const PANNELLUM_CSS = 'https://cdn.jsdelivr.net/npm/pannellum@2.5.6/build/pannellum.css'
const PANNELLUM_JS = 'https://cdn.jsdelivr.net/npm/pannellum@2.5.6/build/pannellum.js'

const scenes = reactive<Scene[]>([])
const firstScene = ref<string>('')
const currentId = ref<string>('')
const selected = ref<number | null>(null)
const mode = ref<'idle' | 'add-arrow' | 'add-info' | 'move'>('idle')
const arrowTarget = ref<string>('')
const loadingMsg = ref<string>('')

const paneEl = ref<HTMLDivElement | null>(null)
let viewer: any = null
let hotspotIds: string[] = []
let syncing = false

/* ---------- Chargement initial depuis la prop ---------- */
function loadFromProps() {
  syncing = true
  scenes.splice(0, scenes.length)
  const cfg = props.modelValue || { scenes: [] }
  for (const s of (cfg.scenes || [])) {
    scenes.push({ id: s.id, title: s.title || '', panorama: s.panorama || '', hotspots: (s.hotspots || []).map(h => ({ ...h })) })
  }
  firstScene.value = cfg.firstScene || (scenes[0]?.id || '')
  currentId.value = scenes.find(s => s.id === firstScene.value) ? firstScene.value : (scenes[0]?.id || '')
  syncing = false
}

/* ---------- Émission de la config ---------- */
function emitConfig() {
  if (syncing) return
  const out: TourConfig = {
    firstScene: firstScene.value || (scenes[0]?.id || ''),
    scenes: scenes.map(s => ({
      id: s.id,
      title: s.title,
      panorama: s.panorama,
      hotspots: s.hotspots.map(h => h.type === 'scene'
        ? { type: 'scene' as const, yaw: h.yaw, pitch: h.pitch, target: h.target, label: h.label }
        : { type: 'info' as const, yaw: h.yaw, pitch: h.pitch, title: h.title, desc: h.desc })
    }))
  }
  emit('update:modelValue', out)
}
watch([scenes, firstScene], emitConfig, { deep: true })

/* ---------- Pannellum ---------- */
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

const curScene = computed<Scene | undefined>(() => scenes.find(s => s.id === currentId.value))
function sceneTitle(id: string): string { return scenes.find(s => s.id === id)?.title || id }
const round = (v: number) => Math.round(v * 10) / 10

const ARROW = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 5v14M6 11l6-6 6 6"/></svg>'
function tipArrow(div: HTMLElement, args: any) {
  div.classList.add('vte-hs', 'vte-scene'); if (args.on) div.classList.add('on')
  div.innerHTML = `<div class="vte-disc">${ARROW}</div><div class="vte-lbl">${args.label || ''}</div>`
}
function tipInfo(div: HTMLElement, args: any) {
  div.classList.add('vte-hs', 'vte-info'); if (args.on) div.classList.add('on')
  div.innerHTML = '<div class="vte-dot">i</div>'
}

function hsConfig(h: Hotspot, i: number, id: string) {
  const common = { id, pitch: h.pitch, yaw: h.yaw, clickHandlerFunc: () => selectHotspot(i), clickHandlerArgs: {} }
  return h.type === 'scene'
    ? { ...common, cssClass: 'vte-hs-wrap', createTooltipFunc: tipArrow, createTooltipArgs: { label: h.label, on: selected.value === i } }
    : { ...common, cssClass: 'vte-hs-wrap', createTooltipFunc: tipInfo, createTooltipArgs: { title: h.title, on: selected.value === i } }
}

function renderHotspots() {
  const sc = curScene.value; if (!viewer || !sc) return
  for (const id of hotspotIds) { try { viewer.removeHotSpot(id) } catch {} }
  hotspotIds = []
  sc.hotspots.forEach((h, i) => { const id = 'hs' + i; try { viewer.addHotSpot(hsConfig(h, i, id)) ; hotspotIds.push(id) } catch {} })
}

async function initViewer() {
  const sc = curScene.value
  if (viewer && viewer.destroy) { try { viewer.destroy() } catch {} viewer = null; hotspotIds = [] }
  if (!paneEl.value || !sc || !sc.panorama) return
  loadingMsg.value = 'Chargement du panorama…'
  try { await loadPannellum() } catch { loadingMsg.value = 'Échec du chargement de Pannellum'; return }
  const pannellum = (window as any).pannellum
  if (!pannellum) return
  viewer = pannellum.viewer(paneEl.value, {
    type: 'equirectangular', panorama: sc.panorama, autoLoad: true, showControls: false,
    compass: false, crossOrigin: 'anonymous', hfov: 100, friction: 0.2
  })
  viewer.on('load', () => { loadingMsg.value = ''; renderHotspots() })
  viewer.on('error', () => { loadingMsg.value = 'Image 360 illisible (vérifiez l\'URL / CORS)' })
}

/* ---------- Placement au clic ---------- */
let downX = 0, downY = 0
function onDown(e: PointerEvent) { downX = e.clientX; downY = e.clientY }
function onUp(e: PointerEvent) {
  if (!viewer) return
  if (Math.hypot(e.clientX - downX, e.clientY - downY) > 6) return // c'était une rotation
  const sc = curScene.value; if (!sc) return
  let coords: number[]
  try { coords = viewer.mouseEventToCoords(e) } catch { return }
  const [pitch, yaw] = coords
  if (mode.value === 'add-arrow') {
    if (!arrowTarget.value) { mode.value = 'idle'; return }
    sc.hotspots.push({ type: 'scene', yaw: round(yaw), pitch: round(pitch), target: arrowTarget.value, label: sceneTitle(arrowTarget.value) })
    selected.value = sc.hotspots.length - 1; mode.value = 'idle'; renderHotspots()
  } else if (mode.value === 'add-info') {
    sc.hotspots.push({ type: 'info', yaw: round(yaw), pitch: round(pitch), title: 'Nouveau point', desc: '' })
    selected.value = sc.hotspots.length - 1; mode.value = 'idle'; renderHotspots()
  } else if (mode.value === 'move' && selected.value != null) {
    sc.hotspots[selected.value].yaw = round(yaw); sc.hotspots[selected.value].pitch = round(pitch)
    mode.value = 'idle'; renderHotspots()
  }
}

function selectHotspot(i: number) {
  if (mode.value === 'add-arrow' || mode.value === 'add-info') return
  selected.value = i; renderHotspots()
}

/* ---------- Actions scènes ---------- */
function slugId(): string { return 's' + Math.random().toString(36).slice(2, 7) }
function addScene() {
  const id = slugId()
  scenes.push({ id, title: 'Salle ' + (scenes.length + 1), panorama: '', hotspots: [] })
  if (!firstScene.value) firstScene.value = id
  currentId.value = id; selected.value = null; mode.value = 'idle'
}
function switchScene(id: string) { if (id === currentId.value) return; currentId.value = id; selected.value = null; mode.value = 'idle' }
function deleteScene(id: string) {
  const idx = scenes.findIndex(s => s.id === id); if (idx < 0) return
  if (!confirm('Supprimer la scène « ' + scenes[idx].title + ' » ?')) return
  // enlever les flèches qui pointaient vers elle
  scenes.forEach(s => { s.hotspots = s.hotspots.filter(h => !(h.type === 'scene' && h.target === id)) })
  scenes.splice(idx, 1)
  if (firstScene.value === id) firstScene.value = scenes[0]?.id || ''
  if (currentId.value === id) { currentId.value = scenes[0]?.id || ''; selected.value = null }
}
function deleteSelected() {
  const sc = curScene.value; if (!sc || selected.value == null) return
  sc.hotspots.splice(selected.value, 1); selected.value = null; renderHotspots()
}
function startMove() { if (selected.value != null) mode.value = 'move' }
function startAddArrow() {
  if (scenes.length < 2) { alert('Ajoutez au moins une deuxième scène pour créer une flèche de navigation.'); return }
  const others = scenes.filter(s => s.id !== currentId.value)
  arrowTarget.value = others[0]?.id || ''
  mode.value = 'add-arrow'; selected.value = null
}
function startAddInfo() { mode.value = 'add-info'; selected.value = null }
function cancelMode() { mode.value = 'idle' }

watch(currentId, () => nextTick(initViewer))
onMounted(() => { loadFromProps(); nextTick(initViewer) })
onBeforeUnmount(() => { if (viewer && viewer.destroy) { try { viewer.destroy() } catch {} } })

// si le parent remplace complètement la config (ex: charge une visite existante)
watch(() => props.modelValue, (nv) => {
  const sameLen = nv && nv.scenes && nv.scenes.length === scenes.length
  if (!sameLen) { loadFromProps(); nextTick(initViewer) }
})
</script>

<template>
  <div class="vte">
    <!-- Colonne scènes -->
    <aside class="vte-scenes">
      <div class="vte-scenes-head">
        <span>Scènes</span>
        <button class="mini" @click="addScene">+ Ajouter</button>
      </div>
      <div v-if="!scenes.length" class="vte-empty-s">Aucune scène. Cliquez « + Ajouter » pour commencer.</div>
      <div v-for="(s, i) in scenes" :key="s.id" class="vte-scene-item" :class="{ on: s.id === currentId }" @click="switchScene(s.id)">
        <span class="n">{{ i + 1 }}</span>
        <div class="vte-scene-body">
          <input class="vte-scene-title" v-model="s.title" placeholder="Nom de la scène" @click.stop />
          <label class="vte-first">
            <input type="radio" :value="s.id" v-model="firstScene" @click.stop /> départ
          </label>
        </div>
        <button class="del" title="Supprimer la scène" @click.stop="deleteScene(s.id)">✕</button>
      </div>
    </aside>

    <!-- Viewer + placement -->
    <div class="vte-main">
      <div v-if="curScene && !curScene.panorama" class="vte-url">
        <p>Collez l'URL de l'image 360° (équirectangulaire) de cette scène :</p>
        <input v-model="curScene.panorama" placeholder="https://… .jpg" @change="initViewer" />
        <small>Astuce : une image panoramique 2:1. Elle doit être accessible en CORS (ex. Wikimedia).</small>
      </div>

      <div v-else-if="!curScene" class="vte-url">
        <p>Ajoutez une scène à gauche pour démarrer.</p>
      </div>

      <template v-else>
        <div class="vte-toolbar">
          <template v-if="mode === 'idle'">
            <button class="tb" @click="startAddArrow">➜ Flèche</button>
            <button class="tb" @click="startAddInfo">◉ Point d'info</button>
            <span class="tb-sep"></span>
            <input class="vte-pano-edit" v-model="curScene.panorama" @change="initViewer" title="URL du panorama" />
          </template>
          <template v-else-if="mode === 'add-arrow'">
            <span class="tb-hint">Vers&nbsp;:</span>
            <select v-model="arrowTarget" class="vte-sel">
              <option v-for="s in scenes.filter(x => x.id !== currentId)" :key="s.id" :value="s.id">{{ s.title }}</option>
            </select>
            <span class="tb-hint">→ cliquez dans l'image pour poser la flèche</span>
            <button class="tb ghost" @click="cancelMode">Annuler</button>
          </template>
          <template v-else-if="mode === 'add-info'">
            <span class="tb-hint">Cliquez dans l'image pour poser le point d'info</span>
            <button class="tb ghost" @click="cancelMode">Annuler</button>
          </template>
          <template v-else-if="mode === 'move'">
            <span class="tb-hint">Cliquez le nouvel emplacement</span>
            <button class="tb ghost" @click="cancelMode">Annuler</button>
          </template>
        </div>

        <div class="vte-stage" :class="{ placing: mode !== 'idle' }">
          <div ref="paneEl" class="vte-pane" @pointerdown="onDown" @pointerup="onUp"></div>
          <div v-if="loadingMsg" class="vte-loading">{{ loadingMsg }}</div>
        </div>
      </template>
    </div>

    <!-- Panneau du hotspot sélectionné -->
    <aside class="vte-inspector" v-if="curScene && selected != null && curScene.hotspots[selected]">
      <div class="vte-insp-head">
        <span>{{ curScene.hotspots[selected].type === 'scene' ? 'Flèche' : 'Point d\'info' }}</span>
        <button class="del" @click="selected = null">✕</button>
      </div>

      <template v-if="curScene.hotspots[selected].type === 'scene'">
        <label>Va vers la scène
          <select v-model="curScene.hotspots[selected].target" @change="curScene.hotspots[selected].label = sceneTitle(curScene.hotspots[selected].target || '')">
            <option v-for="s in scenes.filter(x => x.id !== currentId)" :key="s.id" :value="s.id">{{ s.title }}</option>
          </select>
        </label>
        <label>Libellé
          <input v-model="curScene.hotspots[selected].label" placeholder="Ex : Salle suivante" />
        </label>
      </template>

      <template v-else>
        <label>Titre
          <input v-model="curScene.hotspots[selected].title" placeholder="Titre de l'œuvre / point" />
        </label>
        <label>Description
          <textarea v-model="curScene.hotspots[selected].desc" rows="4" placeholder="Texte affiché au clic"></textarea>
        </label>
      </template>

      <div class="vte-insp-actions">
        <button class="tb" @click="startMove">⤢ Déplacer</button>
        <button class="tb danger" @click="deleteSelected">🗑 Supprimer</button>
      </div>
      <p class="vte-coords">yaw {{ curScene.hotspots[selected].yaw }}° · pitch {{ curScene.hotspots[selected].pitch }}°</p>
    </aside>
  </div>
</template>

<style scoped>
.vte { display: grid; grid-template-columns: 220px 1fr; gap: 12px; align-items: start; }
.vte:has(.vte-inspector) { grid-template-columns: 220px 1fr 260px; }

/* Scènes */
.vte-scenes { display: flex; flex-direction: column; gap: 8px; }
.vte-scenes-head { display: flex; justify-content: space-between; align-items: center; font-weight: 700; font-size: 13px; color: #444; }
.vte-empty-s { font-size: 12.5px; color: #9aa0a6; padding: 8px; border: 1px dashed #e6e0d6; border-radius: 10px; }
.vte-scene-item { display: flex; align-items: center; gap: 8px; padding: 8px 10px; border: 1px solid #e6e0d6; border-radius: 10px; cursor: pointer; background: #fff; }
.vte-scene-item.on { border-color: #C56A3E; box-shadow: 0 0 0 2px rgba(197,106,62,.12); }
.vte-scene-item .n { width: 22px; height: 22px; flex: none; border-radius: 50%; border: 1.5px solid #C56A3E; color: #C56A3E; display: grid; place-items: center; font-size: 11px; font-family: Georgia, serif; }
.vte-scene-body { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 2px; }
.vte-scene-title { border: none; border-bottom: 1px solid transparent; font-size: 13.5px; font-family: inherit; padding: 2px 0; background: transparent; color: #222; }
.vte-scene-title:focus { outline: none; border-bottom-color: #C56A3E; }
.vte-first { font-size: 10.5px; color: #9aa0a6; display: inline-flex; align-items: center; gap: 4px; cursor: pointer; }
.vte-scene-item .del { border: none; background: none; color: #bbb; cursor: pointer; font-size: 13px; }
.vte-scene-item .del:hover { color: #c0392b; }

/* Main */
.vte-main { min-width: 0; }
.vte-url { border: 1px dashed #d9d2c6; border-radius: 14px; padding: 22px; text-align: center; color: #555; }
.vte-url p { font-size: 14px; margin-bottom: 10px; }
.vte-url input { width: 100%; max-width: 460px; padding: 11px 13px; border: 1px solid #d9d2c6; border-radius: 10px; font-family: inherit; font-size: 14px; }
.vte-url small { display: block; margin-top: 8px; color: #9aa0a6; font-size: 12px; }

.vte-toolbar { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; margin-bottom: 8px; }
.tb { border: 1px solid #d9d2c6; background: #fff; color: #333; font-family: inherit; font-size: 13px; font-weight: 600; padding: 8px 13px; border-radius: 999px; cursor: pointer; }
.tb:hover { border-color: #C56A3E; color: #C56A3E; }
.tb.ghost { background: #f6f2ec; }
.tb.danger { color: #c0392b; border-color: #e5b8b2; }
.tb.danger:hover { background: #fbeeec; }
.tb-sep { flex: 1; }
.tb-hint { font-size: 12.5px; color: #7a5a2a; font-weight: 600; }
.vte-sel, .vte-pano-edit { border: 1px solid #d9d2c6; border-radius: 8px; padding: 6px 10px; font-family: inherit; font-size: 13px; }
.vte-pano-edit { min-width: 220px; flex: 1; color: #666; }

.vte-stage { position: relative; border-radius: 14px; overflow: hidden; border: 1px solid #e6e0d6; background: #0E1B24; }
.vte-pane { width: 100%; height: 420px; }
.vte-stage.placing .vte-pane { cursor: crosshair; }
.vte-loading { position: absolute; inset: 0; display: grid; place-items: center; color: #F3EEE4; font-style: italic; background: rgba(14,27,36,.5); pointer-events: none; }

/* Inspector */
.vte-inspector { display: flex; flex-direction: column; gap: 12px; background: #fbf9f5; border: 1px solid #e6e0d6; border-radius: 14px; padding: 14px; }
.vte-insp-head { display: flex; justify-content: space-between; align-items: center; font-weight: 700; font-size: 13px; color: #C56A3E; text-transform: uppercase; letter-spacing: .05em; }
.vte-insp-head .del { border: none; background: none; cursor: pointer; color: #999; font-size: 14px; }
.vte-inspector label { display: flex; flex-direction: column; gap: 5px; font-size: 12.5px; font-weight: 600; color: #444; }
.vte-inspector input, .vte-inspector select, .vte-inspector textarea { border: 1px solid #d9d2c6; border-radius: 9px; padding: 9px 11px; font-family: inherit; font-size: 13.5px; font-weight: 400; color: #222; }
.vte-inspector input:focus, .vte-inspector select:focus, .vte-inspector textarea:focus { outline: none; border-color: #C56A3E; }
.vte-inspector textarea { font-family: inherit; line-height: 1.5; resize: vertical; }
.vte-insp-actions { display: flex; gap: 8px; }
.vte-coords { font-size: 11px; color: #9aa0a6; font-family: ui-monospace, monospace; }
</style>

<!-- Styles globaux : hotspots créés dynamiquement par Pannellum -->
<style>
.vte-hs { cursor: pointer; transform: translate(-50%, -50%); }
.vte-hs.vte-scene .vte-disc { width: 46px; height: 46px; border-radius: 50%; background: rgba(14,27,36,.55); border: 2px solid #F3EEE4; display: grid; place-items: center; color: #fff; backdrop-filter: blur(3px); transition: .15s; }
.vte-hs.vte-scene .vte-disc svg { width: 23px; height: 23px; }
.vte-hs.vte-scene .vte-lbl { position: absolute; top: 52px; left: 50%; transform: translateX(-50%); white-space: nowrap; font-family: system-ui, sans-serif; font-size: 11.5px; font-weight: 700; background: rgba(14,27,36,.8); padding: 4px 10px; border-radius: 999px; color: #fff; }
.vte-hs.vte-info .vte-dot { width: 30px; height: 30px; border-radius: 50%; background: #E0A94E; color: #3a2606; display: grid; place-items: center; font-family: Georgia, serif; font-weight: 700; font-size: 15px; border: 2px solid #fff; box-shadow: 0 3px 12px rgba(0,0,0,.45); transition: .15s; }
.vte-hs.on .vte-disc, .vte-hs.on .vte-dot { box-shadow: 0 0 0 4px rgba(197,106,62,.9); border-color: #C56A3E; }
.vte-hs:hover .vte-disc { background: #C56A3E; border-color: #C56A3E; }
</style>
