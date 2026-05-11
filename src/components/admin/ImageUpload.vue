<script setup lang="ts">
import { ref } from 'vue'
import { useStorageUpload } from '@/composables/useStorageUpload'

const props = defineProps<{
  modelValue: string | null
  bucket?: 'hero-images' | 'avatars' | 'panoramas'
  label?: string
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', url: string | null): void
}>()

const bucket = props.bucket ?? 'hero-images'
const { uploadFile, uploading, error } = useStorageUpload(bucket)
const fileInput = ref<HTMLInputElement | null>(null)

async function handleFileChange(event: Event) {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  if (!file) return

  const url = await uploadFile(file)
  if (url) emit('update:modelValue', url)
}

function removeImage() {
  emit('update:modelValue', null)
  if (fileInput.value) fileInput.value.value = ''
}
</script>

<template>
  <div class="image-upload">
    <label class="upload-label">{{ label || 'Image' }}</label>

    <div v-if="modelValue" class="preview-wrap">
      <img :src="modelValue" alt="Aperçu" class="preview" />
      <button type="button" class="remove-btn" @click="removeImage">✕ Retirer</button>
    </div>

    <label v-else class="dropzone">
      <input
        ref="fileInput"
        type="file"
        accept="image/jpeg,image/png,image/webp,image/avif"
        :disabled="uploading"
        @change="handleFileChange"
      />
      <div v-if="uploading" class="upload-state">
        <div class="spinner" />
        <span>Upload en cours…</span>
      </div>
      <div v-else class="upload-prompt">
        <div class="icon">📷</div>
        <strong>Choisir une image</strong>
        <small>JPG, PNG, WebP, AVIF — 10 Mo max</small>
      </div>
    </label>

    <p v-if="error" class="error-msg">{{ error }}</p>
  </div>
</template>

<style scoped>
.image-upload { margin-bottom: var(--space-4); }
.upload-label {
  display: block;
  font-size: 13px;
  font-weight: 600;
  color: var(--c-primaire-profond);
  margin-bottom: 6px;
}
.preview-wrap {
  position: relative;
  border-radius: var(--r-md);
  overflow: hidden;
  max-width: 320px;
}
.preview { width: 100%; aspect-ratio: 4/3; object-fit: cover; display: block; }
.remove-btn {
  position: absolute; top: 8px; right: 8px;
  padding: 6px 10px;
  background: rgba(192, 74, 58, 0.95);
  color: white;
  border: none;
  border-radius: var(--r-pill);
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
}
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
.dropzone:hover { border-color: var(--c-accent); background: var(--c-fond); }
.dropzone input[type="file"] { display: none; }
.upload-prompt .icon { font-size: 32px; margin-bottom: 6px; }
.upload-prompt strong { display: block; color: var(--c-primaire-profond); margin-bottom: 4px; }
.upload-prompt small { color: var(--c-texte-doux); font-size: 12px; }
.upload-state { display: flex; align-items: center; justify-content: center; gap: 12px; color: var(--c-primaire); }
.spinner {
  width: 24px; height: 24px;
  border: 3px solid var(--c-gris-clair);
  border-top-color: var(--c-accent);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }
.error-msg { color: var(--c-cta); font-size: 13px; margin-top: 6px; }
</style>
