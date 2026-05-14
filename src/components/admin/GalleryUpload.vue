<script setup lang="ts">
import { ref, computed } from 'vue'
import { useStorageUpload, type StorageBucket } from '@/composables/useStorageUpload'

/**
 * Composant d'upload multi-images.
 * - modelValue : tableau d'URLs (string[])
 * - bucket : bucket Supabase storage cible (par défaut 'hero-images')
 * - max : nombre max d'images (par défaut 10)
 *
 * Émet update:modelValue à chaque ajout / suppression.
 */
const props = withDefaults(defineProps<{
  modelValue: string[]
  bucket?: StorageBucket
  label?: string
  max?: number
  hint?: string
}>(), {
  bucket: 'hero-images',
  label: 'Galerie photos',
  max: 10,
  hint: ''
})

const emit = defineEmits<{
  (e: 'update:modelValue', urls: string[]): void
}>()

const SIZE_LIMITS: Record<string, number> = {
  'avatars': 5,
  'hero-images': 25,
  'panoramas': 50,
  'kyc-documents': 10,
  'ambient-sounds': 10,
  'trip-covers': 25,
  'memory-photos': 25
}
const maxSize = computed(() => SIZE_LIMITS[props.bucket] ?? 25)

const { uploadFile, uploading, error } = useStorageUpload(props.bucket)
const fileInput = ref<HTMLInputElement | null>(null)
const dragOver = ref(false)

const remaining = computed(() => props.max - props.modelValue.length)
const isFull = computed(() => props.modelValue.length >= props.max)

async function handleFileChange(event: Event) {
  const input = event.target as HTMLInputElement
  const files = input.files
  if (!files || files.length === 0) return
  await processFiles(Array.from(files))
  // Reset input pour permettre de re-uploader le même fichier si retiré
  if (fileInput.value) fileInput.value.value = ''
}

async function handleDrop(event: DragEvent) {
  event.preventDefault()
  dragOver.value = false
  const files = event.dataTransfer?.files
  if (!files || files.length === 0) return
  await processFiles(Array.from(files))
}

async function processFiles(files: File[]) {
  const slots = remaining.value
  if (slots <= 0) return

  // Filtre uniquement les images
  const imagesOnly = files.filter(f => f.type.startsWith('image/'))
  const toUpload = imagesOnly.slice(0, slots)

  const next = [...props.modelValue]
  for (const file of toUpload) {
    const url = await uploadFile(file)
    if (url) next.push(url)
  }
  emit('update:modelValue', next)
}

function removeImage(index: number) {
  const next = props.modelValue.filter((_, i) => i !== index)
  emit('update:modelValue', next)
}

function moveImage(from: number, dir: 'left' | 'right') {
  const to = dir === 'left' ? from - 1 : from + 1
  if (to < 0 || to >= props.modelValue.length) return
  const next = [...props.modelValue]
  const [moved] = next.splice(from, 1)
  next.splice(to, 0, moved)
  emit('update:modelValue', next)
}
</script>

<template>
  <div class="gallery-upload">
    <div class="gallery-header">
      <label class="gallery-label">{{ label }}</label>
      <span class="gallery-count">{{ modelValue.length }}/{{ max }}</span>
    </div>
    <p v-if="hint" class="gallery-hint">{{ hint }}</p>

    <!-- Grille d'images existantes -->
    <div v-if="modelValue.length > 0" class="gallery-grid">
      <div
        v-for="(url, i) in modelValue"
        :key="url + i"
        class="thumb-card"
      >
        <img :src="url" :alt="`Photo ${i + 1}`" class="thumb-img" />
        <span class="thumb-index">{{ i + 1 }}</span>
        <div class="thumb-actions">
          <button
            v-if="i > 0"
            type="button"
            class="thumb-btn"
            title="Reculer (réordonner)"
            @click="moveImage(i, 'left')"
          >←</button>
          <button
            v-if="i < modelValue.length - 1"
            type="button"
            class="thumb-btn"
            title="Avancer"
            @click="moveImage(i, 'right')"
          >→</button>
          <button
            type="button"
            class="thumb-btn danger"
            title="Retirer"
            @click="removeImage(i)"
          >✕</button>
        </div>
      </div>
    </div>

    <!-- Dropzone upload -->
    <label
      v-if="!isFull"
      class="dropzone"
      :class="{ 'is-drag': dragOver, 'is-uploading': uploading }"
      @dragover.prevent="dragOver = true"
      @dragleave.prevent="dragOver = false"
      @drop="handleDrop"
    >
      <input
        ref="fileInput"
        type="file"
        accept="image/jpeg,image/png,image/webp,image/avif"
        multiple
        :disabled="uploading"
        @change="handleFileChange"
      />
      <div v-if="uploading" class="upload-state">
        <div class="spinner" />
        <span>Upload en cours…</span>
      </div>
      <div v-else class="upload-prompt">
        <div class="icon">📸</div>
        <strong>Ajouter des photos</strong>
        <small>Glissez-déposez ou cliquez · JPG/PNG/WebP/AVIF · {{ maxSize }} Mo max · {{ remaining }} restantes</small>
      </div>
    </label>

    <div v-else class="full-msg">
      Limite atteinte ({{ max }} photos). Retirez-en une pour en ajouter une nouvelle.
    </div>

    <p v-if="error" class="error-msg">{{ error }}</p>
  </div>
</template>

<style scoped>
.gallery-upload { margin-bottom: var(--space-4); }

.gallery-header {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  margin-bottom: 4px;
}
.gallery-label {
  font-size: 13px;
  font-weight: 600;
  color: var(--c-primaire-profond);
}
.gallery-count {
  font-size: 12px;
  color: var(--c-texte-doux);
  font-variant-numeric: tabular-nums;
}
.gallery-hint {
  font-size: 12px;
  color: var(--c-texte-doux);
  margin-bottom: var(--space-2);
  line-height: 1.5;
}

.gallery-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
  gap: var(--space-2);
  margin-bottom: var(--space-3);
}
.thumb-card {
  position: relative;
  aspect-ratio: 4/3;
  border-radius: var(--r-md);
  overflow: hidden;
  background: var(--c-fond-chaud);
  border: 1px solid var(--c-gris-clair);
}
.thumb-img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}
.thumb-index {
  position: absolute;
  top: 6px;
  left: 6px;
  background: rgba(10, 31, 46, 0.85);
  color: white;
  width: 24px;
  height: 24px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  font-weight: 600;
}
.thumb-actions {
  position: absolute;
  bottom: 6px;
  right: 6px;
  display: flex;
  gap: 4px;
  opacity: 0;
  transition: opacity 0.2s;
}
.thumb-card:hover .thumb-actions,
.thumb-card:focus-within .thumb-actions { opacity: 1; }
.thumb-btn {
  width: 26px;
  height: 26px;
  background: rgba(255, 255, 255, 0.95);
  border: 1px solid var(--c-gris-clair);
  color: var(--c-primaire-profond);
  border-radius: 50%;
  cursor: pointer;
  font-size: 12px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: inherit;
}
.thumb-btn:hover { background: var(--c-accent); color: white; border-color: var(--c-accent); }
.thumb-btn.danger:hover { background: var(--c-cta, #C04A3A); color: white; border-color: var(--c-cta, #C04A3A); }

.dropzone {
  display: block;
  padding: var(--space-5);
  border: 2px dashed var(--c-gris-clair);
  border-radius: var(--r-md);
  background: var(--c-fond-chaud);
  text-align: center;
  cursor: pointer;
  transition: var(--t-base);
}
.dropzone.is-drag,
.dropzone:hover { border-color: var(--c-accent); background: var(--c-fond); }
.dropzone.is-uploading { opacity: 0.7; pointer-events: none; }
.dropzone input[type="file"] { display: none; }

.upload-prompt .icon { font-size: 28px; margin-bottom: 4px; }
.upload-prompt strong { display: block; color: var(--c-primaire-profond); margin-bottom: 4px; font-size: 14px; }
.upload-prompt small { color: var(--c-texte-doux); font-size: 11px; line-height: 1.4; }

.upload-state {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  color: var(--c-primaire);
}
.spinner {
  width: 24px; height: 24px;
  border: 3px solid var(--c-gris-clair);
  border-top-color: var(--c-accent);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }

.full-msg {
  padding: var(--space-3);
  background: var(--c-fond-chaud);
  border-radius: var(--r-md);
  text-align: center;
  font-size: 13px;
  color: var(--c-texte-doux);
}
.error-msg {
  color: var(--c-cta, #C04A3A);
  font-size: 13px;
  margin-top: 6px;
}
</style>
