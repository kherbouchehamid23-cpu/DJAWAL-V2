<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount, watch } from 'vue'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'

export interface MapMarker {
  id: string
  lat: number
  lng: number
  title: string
  subtitle?: string
  theme?: 'saharien' | 'mauresque' | 'aures'
  url?: string
}

const props = withDefaults(defineProps<{
  markers: MapMarker[]
  center?: [number, number]
  zoom?: number
  height?: string
}>(), {
  center: () => [28.0339, 1.6596], // Centre de l'Algérie
  zoom: 5,
  height: '480px'
})

const emit = defineEmits<{
  (e: 'marker-click', marker: MapMarker): void
}>()

const mapEl = ref<HTMLDivElement | null>(null)
let map: L.Map | null = null
let markerLayer: L.LayerGroup | null = null

// Couleurs Djawal par thème culturel
const themeColors: Record<string, string> = {
  saharien: '#D4A04F',
  mauresque: '#1B4965',
  aures: '#2D5A3D'
}

function createIcon(theme?: string) {
  const color = themeColors[theme || ''] || '#C04A3A'
  const html = `
    <div style="
      width: 32px; height: 32px;
      background: ${color};
      border: 3px solid #FAF7F2;
      border-radius: 50% 50% 50% 0;
      transform: rotate(-45deg);
      box-shadow: 0 4px 12px rgba(0,0,0,0.3);
      display: flex; align-items: center; justify-content: center;
    ">
      <div style="
        width: 8px; height: 8px;
        background: #FAF7F2;
        border-radius: 50%;
      "></div>
    </div>
  `
  return L.divIcon({
    html,
    className: 'djawal-marker',
    iconSize: [32, 32],
    iconAnchor: [16, 32],
    popupAnchor: [0, -32]
  })
}

function renderMarkers() {
  if (!map || !markerLayer) return
  markerLayer.clearLayers()

  if (props.markers.length === 0) return

  const bounds = L.latLngBounds([])

  for (const m of props.markers) {
    if (!m.lat || !m.lng) continue
    const marker = L.marker([m.lat, m.lng], { icon: createIcon(m.theme) })
    const popupHtml = `
      <div style="font-family: 'Inter', sans-serif; min-width: 180px;">
        <strong style="display: block; color: #0A1F2E; font-size: 15px; margin-bottom: 4px;">${m.title}</strong>
        ${m.subtitle ? `<div style="color: #6B6B6B; font-size: 13px; margin-bottom: 8px;">${m.subtitle}</div>` : ''}
        ${m.url ? `<a href="${m.url}" style="color: #1B4965; font-weight: 600; text-decoration: none; font-size: 13px;">Voir &rarr;</a>` : ''}
      </div>
    `
    marker.bindPopup(popupHtml)
    marker.on('click', () => emit('marker-click', m))
    marker.addTo(markerLayer)
    bounds.extend([m.lat, m.lng])
  }

  if (props.markers.length > 1) {
    map.fitBounds(bounds, { padding: [40, 40], maxZoom: 12 })
  } else if (props.markers.length === 1) {
    map.setView([props.markers[0].lat, props.markers[0].lng], 13)
  }
}

onMounted(() => {
  if (!mapEl.value) return
  map = L.map(mapEl.value, {
    center: props.center,
    zoom: props.zoom,
    scrollWheelZoom: false,
    zoomControl: true
  })

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    maxZoom: 19,
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
  }).addTo(map)

  markerLayer = L.layerGroup().addTo(map)
  renderMarkers()
})

onBeforeUnmount(() => {
  if (map) {
    map.remove()
    map = null
  }
})

watch(() => props.markers, renderMarkers, { deep: true })
</script>

<template>
  <div ref="mapEl" class="leaflet-wrap" :style="{ height }" />
</template>

<style scoped>
.leaflet-wrap {
  width: 100%;
  border-radius: var(--r-lg);
  overflow: hidden;
  background: var(--c-fond-chaud);
  box-shadow: var(--ombre-douce);
}
</style>

<style>
.djawal-marker {
  background: transparent !important;
  border: none !important;
}
.leaflet-popup-content-wrapper {
  border-radius: 10px;
  box-shadow: 0 8px 24px rgba(0,0,0,0.18);
}
.leaflet-popup-content { margin: 12px 14px; }
</style>
