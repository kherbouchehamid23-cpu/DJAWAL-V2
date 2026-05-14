<script setup lang="ts">
import { ref, computed, watch } from 'vue'

/**
 * Modal détaillé d'une ressource (site, hébergement, restaurant, activité).
 * Affiche : galerie photos, description complète, méta, panorama 360°, contact, etc.
 */
type ResourceType = 'site' | 'accommodation' | 'restaurant' | 'activity'

const props = defineProps<{
  modelValue: boolean
  resource: any | null
  resourceType: ResourceType | null
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', v: boolean): void
  (e: 'open-panorama', resource: any): void
}>()

const currentPhotoIndex = ref(0)

const typeLabels: Record<ResourceType, string> = {
  site: 'Site / Monument',
  accommodation: 'Hébergement',
  restaurant: 'Restaurant',
  activity: 'Activité'
}

const typeIcons: Record<ResourceType, string> = {
  site: '🏛️',
  accommodation: '🏨',
  restaurant: '🍽️',
  activity: '🥾'
}

const photos = computed<string[]>(() => props.resource?.images || [])
const has360 = computed(() => !!(props.resource?.panorama_360_url || props.resource?.virtual_tour_url))

const typeLabel = computed(() => props.resourceType ? typeLabels[props.resourceType] : '')
const typeIcon = computed(() => props.resourceType ? typeIcons[props.resourceType] : '')

function close() {
  emit('update:modelValue', false)
}

function nextPhoto() {
  if (currentPhotoIndex.value < photos.value.length - 1) currentPhotoIndex.value++
}

function prevPhoto() {
  if (currentPhotoIndex.value > 0) currentPhotoIndex.value--
}

function openPanorama() {
  emit('open-panorama', props.resource)
  close()
}

function parsePriceRange(range: any): string {
  if (!range) return ''
  // Format Postgres int4range : "[1000,5000)" ou "(1000,5000]"
  if (typeof range === 'string') {
    const match = range.match(/[\[\(](\d+),(\d+)[\)\]]/)
    if (match) {
      return `${parseInt(match[1]).toLocaleString('fr-FR')} – ${parseInt(match[2]).toLocaleString('fr-FR')} DA`
    }
  }
  return ''
}

// Reset photo index when resource changes
watch(() => props.resource, () => {
  currentPhotoIndex.value = 0
})
</script>

<template>
  <transition name="fade">
    <div v-if="modelValue && resource" class="rd-overlay" @click.self="close">
      <div class="rd-modal" role="dialog" aria-modal="true">
        <button class="rd-close" @click="close" aria-label="Fermer">✕</button>

        <!-- Header sticky -->
        <header class="rd-head">
          <div class="rd-type-badge">
            <span>{{ typeIcon }}</span>
            {{ typeLabel }}
          </div>
          <h2>{{ resource.name || resource.title }}</h2>
          <p v-if="resource.name_ar" class="rd-arabic arabic">{{ resource.name_ar }}</p>
          <div class="rd-quickmeta">
            <span v-if="resource.star_rating" class="rd-stars">{{ '★'.repeat(resource.star_rating) }}</span>
            <span v-if="resource.activity_type" class="rd-tag">{{ resource.activity_type }}</span>
            <span v-if="resource.cuisine && resource.cuisine.length" class="rd-tag">{{ resource.cuisine.join(' · ') }}</span>
            <span v-if="resource.category" class="rd-tag">{{ resource.category }}</span>
            <span v-if="resource.accommodation_type" class="rd-tag">{{ resource.accommodation_type }}</span>
            <span v-if="resource.difficulty" class="rd-tag">{{ resource.difficulty }}</span>
          </div>
        </header>

        <div class="rd-body">
          <!-- Galerie photos -->
          <section v-if="photos.length > 0" class="rd-gallery">
            <div class="rd-photo-main">
              <img :src="photos[currentPhotoIndex]" :alt="`Photo ${currentPhotoIndex + 1}`" />
              <button
                v-if="currentPhotoIndex > 0"
                class="rd-nav rd-nav-prev"
                @click="prevPhoto"
                aria-label="Photo précédente"
              >‹</button>
              <button
                v-if="currentPhotoIndex < photos.length - 1"
                class="rd-nav rd-nav-next"
                @click="nextPhoto"
                aria-label="Photo suivante"
              >›</button>
              <span v-if="photos.length > 1" class="rd-photo-counter">
                {{ currentPhotoIndex + 1 }} / {{ photos.length }}
              </span>
            </div>
            <div v-if="photos.length > 1" class="rd-thumbs">
              <button
                v-for="(p, i) in photos"
                :key="p + i"
                class="rd-thumb"
                :class="{ active: i === currentPhotoIndex }"
                @click="currentPhotoIndex = i"
              >
                <img :src="p" :alt="`Vignette ${i + 1}`" />
              </button>
            </div>
          </section>

          <section v-else class="rd-no-photo">
            <div class="rd-no-photo-icon">{{ typeIcon }}</div>
            <p>Pas encore de photo pour cette fiche.</p>
          </section>

          <!-- Description complète -->
          <section class="rd-section">
            <h3>Description</h3>
            <p class="rd-desc">{{ resource.description }}</p>
          </section>

          <!-- Détails spécifiques par type -->
          <section v-if="resourceType === 'activity'" class="rd-details">
            <h3>Informations pratiques</h3>
            <dl class="rd-meta-list">
              <div v-if="resource.duration_hours">
                <dt>⏱️ Durée</dt>
                <dd>{{ resource.duration_hours }} h</dd>
              </div>
              <div v-if="resource.price_da !== null && resource.price_da !== undefined">
                <dt>💵 Prix</dt>
                <dd>{{ resource.price_da.toLocaleString('fr-FR') }} DA / personne</dd>
              </div>
              <div v-if="resource.min_age">
                <dt>👤 Âge minimum</dt>
                <dd>{{ resource.min_age }} ans</dd>
              </div>
              <div v-if="resource.max_group_size">
                <dt>👥 Groupe max</dt>
                <dd>{{ resource.max_group_size }} pers.</dd>
              </div>
              <div v-if="resource.best_season && resource.best_season.length">
                <dt>🗓️ Meilleures saisons</dt>
                <dd>{{ resource.best_season.join(', ') }}</dd>
              </div>
              <div v-if="resource.booking_required !== undefined">
                <dt>📅 Réservation</dt>
                <dd>{{ resource.booking_required ? 'Requise' : 'Pas obligatoire' }}</dd>
              </div>
            </dl>
            <div v-if="resource.operator_name" class="rd-contact">
              <strong>Opérateur :</strong> {{ resource.operator_name }}
              <span v-if="resource.operator_phone"> · 📞 <a :href="`tel:${resource.operator_phone}`">{{ resource.operator_phone }}</a></span>
            </div>
          </section>

          <section v-if="resourceType === 'accommodation'" class="rd-details">
            <h3>Informations pratiques</h3>
            <dl class="rd-meta-list">
              <div v-if="resource.address">
                <dt>📍 Adresse</dt>
                <dd>{{ resource.address }}</dd>
              </div>
              <div v-if="parsePriceRange(resource.price_range_da)">
                <dt>💰 Tarif</dt>
                <dd>{{ parsePriceRange(resource.price_range_da) }}</dd>
              </div>
            </dl>
            <div v-if="resource.amenities && resource.amenities.length" class="rd-amenities">
              <strong>Équipements :</strong>
              <span v-for="a in resource.amenities" :key="a" class="rd-amenity">{{ a }}</span>
            </div>
          </section>

          <section v-if="resourceType === 'restaurant'" class="rd-details">
            <h3>Informations pratiques</h3>
            <dl class="rd-meta-list">
              <div v-if="parsePriceRange(resource.price_range_da)">
                <dt>💰 Tarif</dt>
                <dd>{{ parsePriceRange(resource.price_range_da) }}</dd>
              </div>
            </dl>
            <div v-if="resource.signature_dishes && resource.signature_dishes.length" class="rd-amenities">
              <strong>Plats signature :</strong>
              <span v-for="d in resource.signature_dishes" :key="d" class="rd-amenity dishes">{{ d }}</span>
            </div>
          </section>

          <section v-if="resourceType === 'site'" class="rd-details">
            <h3>Informations pratiques</h3>
            <dl class="rd-meta-list">
              <div v-if="resource.entry_fee_da !== null && resource.entry_fee_da !== undefined">
                <dt>💵 Entrée</dt>
                <dd>{{ resource.entry_fee_da === 0 ? 'Gratuit' : `${resource.entry_fee_da.toLocaleString('fr-FR')} DA` }}</dd>
              </div>
              <div v-if="resource.best_season && resource.best_season.length">
                <dt>🗓️ Meilleures saisons</dt>
                <dd>{{ resource.best_season.join(', ') }}</dd>
              </div>
            </dl>
          </section>

          <!-- Actions bas -->
          <div class="rd-actions">
            <button v-if="has360" class="rd-btn rd-btn-360" @click="openPanorama">
              🌐 Visite 360°
            </button>
          </div>
        </div>
      </div>
    </div>
  </transition>
</template>

<style scoped>
.rd-overlay {
  position: fixed;
  inset: 0;
  background: rgba(10, 31, 46, 0.8);
  z-index: 1000;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: var(--space-3);
  backdrop-filter: blur(6px);
}
.rd-modal {
  width: 100%;
  max-width: 760px;
  max-height: 90vh;
  background: var(--c-fond, #FAF7F2);
  border-radius: var(--r-md);
  overflow: hidden;
  display: flex;
  flex-direction: column;
  position: relative;
}
.rd-close {
  position: absolute;
  top: 12px;
  right: 12px;
  z-index: 10;
  width: 36px;
  height: 36px;
  background: rgba(255, 255, 255, 0.95);
  border: 1px solid var(--c-gris-clair);
  border-radius: 50%;
  cursor: pointer;
  font-size: 16px;
  font-weight: 600;
  color: var(--c-primaire-profond);
  font-family: inherit;
  display: flex;
  align-items: center;
  justify-content: center;
}
.rd-close:hover { background: var(--c-cta, #C04A3A); color: white; border-color: var(--c-cta, #C04A3A); }

.rd-head {
  padding: var(--space-4) var(--space-5);
  background: var(--c-fond-chaud, #F5EFE2);
  border-bottom: 1px solid var(--c-gris-clair);
}
.rd-type-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: rgba(212, 160, 79, 0.18);
  color: var(--c-accent-fort, #B8862E);
  padding: 4px 12px;
  border-radius: 999px;
  font-size: 11px;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  font-weight: 700;
  margin-bottom: var(--space-2);
}
.rd-head h2 {
  font-family: var(--font-display);
  font-size: clamp(22px, 3vw, 30px);
  color: var(--c-primaire-profond);
  margin: 0 0 4px;
  line-height: 1.15;
}
.rd-arabic {
  color: var(--c-accent-fort, #B8862E);
  font-size: 16px;
  margin-bottom: var(--space-2);
}
.rd-quickmeta {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
  margin-top: var(--space-2);
}
.rd-stars {
  color: #D4A04F;
  font-size: 14px;
  letter-spacing: 1px;
}
.rd-tag {
  background: var(--c-fond);
  padding: 3px 10px;
  border-radius: 999px;
  font-size: 11px;
  color: var(--c-texte-doux);
  border: 1px solid var(--c-gris-clair);
}

.rd-body {
  overflow-y: auto;
  flex: 1;
}

/* === Galerie === */
.rd-gallery {
  background: #000;
}
.rd-photo-main {
  position: relative;
  aspect-ratio: 16/10;
  max-height: 420px;
  overflow: hidden;
}
.rd-photo-main img {
  width: 100%;
  height: 100%;
  object-fit: contain;
  display: block;
}
.rd-nav {
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  width: 44px;
  height: 44px;
  background: rgba(0, 0, 0, 0.55);
  color: white;
  border: none;
  border-radius: 50%;
  cursor: pointer;
  font-size: 28px;
  line-height: 1;
  font-family: inherit;
  display: flex;
  align-items: center;
  justify-content: center;
}
.rd-nav:hover { background: rgba(0, 0, 0, 0.85); }
.rd-nav-prev { left: 12px; }
.rd-nav-next { right: 12px; }
.rd-photo-counter {
  position: absolute;
  bottom: 12px;
  right: 12px;
  background: rgba(0, 0, 0, 0.65);
  color: white;
  padding: 4px 10px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 500;
}
.rd-thumbs {
  display: flex;
  gap: 4px;
  padding: 8px;
  background: rgba(0, 0, 0, 0.85);
  overflow-x: auto;
}
.rd-thumb {
  width: 70px;
  height: 50px;
  flex-shrink: 0;
  border: 2px solid transparent;
  border-radius: 4px;
  overflow: hidden;
  cursor: pointer;
  background: none;
  padding: 0;
  opacity: 0.6;
  transition: opacity 0.2s, border-color 0.2s;
}
.rd-thumb img { width: 100%; height: 100%; object-fit: cover; display: block; }
.rd-thumb.active, .rd-thumb:hover { opacity: 1; border-color: var(--c-accent); }

.rd-no-photo {
  padding: var(--space-7) var(--space-5);
  text-align: center;
  background: var(--c-fond-chaud);
  color: var(--c-texte-doux);
}
.rd-no-photo-icon { font-size: 48px; margin-bottom: var(--space-2); opacity: 0.5; }

/* === Sections === */
.rd-section, .rd-details {
  padding: var(--space-4) var(--space-5);
  border-bottom: 1px solid var(--c-gris-clair);
}
.rd-section:last-of-type, .rd-details:last-of-type {
  border-bottom: none;
}
.rd-section h3, .rd-details h3 {
  font-family: var(--font-display);
  font-size: 18px;
  color: var(--c-primaire-profond);
  margin: 0 0 var(--space-2);
}
.rd-desc {
  color: var(--c-texte);
  line-height: 1.7;
  white-space: pre-wrap;
}

.rd-meta-list {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--space-2) var(--space-3);
}
.rd-meta-list > div {
  padding: var(--space-2);
  background: var(--c-fond-chaud);
  border-radius: 6px;
}
.rd-meta-list dt {
  font-size: 11px;
  color: var(--c-texte-doux);
  letter-spacing: 0.05em;
  text-transform: uppercase;
  margin-bottom: 2px;
}
.rd-meta-list dd {
  margin: 0;
  font-weight: 500;
  color: var(--c-primaire-profond);
  font-size: 14px;
}
@media (max-width: 540px) {
  .rd-meta-list { grid-template-columns: 1fr; }
}

.rd-amenities {
  margin-top: var(--space-2);
}
.rd-amenities strong {
  display: block;
  font-size: 13px;
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-2);
}
.rd-amenity {
  display: inline-block;
  background: var(--c-fond-chaud);
  padding: 4px 10px;
  border-radius: 999px;
  margin-right: 6px;
  margin-bottom: 6px;
  font-size: 12px;
  color: var(--c-texte);
}
.rd-amenity.dishes {
  background: rgba(212, 160, 79, 0.15);
  color: var(--c-accent-fort, #B8862E);
}

.rd-contact {
  margin-top: var(--space-3);
  padding: var(--space-3);
  background: var(--c-fond-chaud);
  border-radius: 6px;
  font-size: 14px;
  color: var(--c-texte);
}
.rd-contact strong { color: var(--c-primaire-profond); }
.rd-contact a { color: var(--c-accent-fort, #B8862E); font-weight: 600; }

.rd-actions {
  padding: var(--space-4) var(--space-5);
  display: flex;
  gap: var(--space-2);
  justify-content: flex-end;
  background: var(--c-fond-chaud);
}
.rd-btn {
  padding: 10px 18px;
  border-radius: 999px;
  border: none;
  font-family: inherit;
  font-weight: 600;
  cursor: pointer;
  font-size: 14px;
}
.rd-btn-360 {
  background: linear-gradient(135deg, #D4A04F, #B8862E);
  color: white;
}
.rd-btn-360:hover { transform: translateY(-1px); }

.fade-enter-active, .fade-leave-active { transition: opacity 0.2s; }
.fade-enter-from, .fade-leave-to { opacity: 0; }
</style>
