<script setup lang="ts">
import { computed } from 'vue'

/**
 * Badge éditorial admin : "vedette", "coup de cœur", "tendance".
 * Réutilisable sur toutes les cards publiques (trips, accommodations, etc.).
 *
 * Usage :
 *   <FeaturedBadge :label="t.featured_label" />
 *   <FeaturedBadge :label="acc.featured_label" size="sm" position="top-left" />
 */
type Label = 'vedette' | 'coup_de_coeur' | 'tendance' | null | undefined

const props = withDefaults(defineProps<{
  label: Label
  size?: 'sm' | 'md'
  position?: 'top-left' | 'top-right' | 'bottom-left' | 'bottom-right' | 'inline'
}>(), {
  size: 'md',
  position: 'top-left'
})

const config = computed(() => {
  switch (props.label) {
    case 'vedette':       return { text: '★ VEDETTE',        cls: 'badge-vedette' }
    case 'coup_de_coeur': return { text: '♥ COUP DE CŒUR',  cls: 'badge-coup-coeur' }
    case 'tendance':      return { text: '↗ TENDANCE',       cls: 'badge-tendance' }
    default:              return null
  }
})
</script>

<template>
  <span
    v-if="config"
    class="featured-badge"
    :class="[config.cls, `size-${size}`, position !== 'inline' ? `pos-${position}` : '']"
  >
    {{ config.text }}
  </span>
</template>

<style scoped>
.featured-badge {
  display: inline-flex;
  align-items: center;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  border-radius: 999px;
  white-space: nowrap;
  box-shadow: 0 4px 14px rgba(0, 0, 0, 0.25);
  z-index: 5;
}

/* Tailles */
.size-sm { font-size: 9.5px; padding: 4px 10px; }
.size-md { font-size: 10.5px; padding: 5px 12px; }

/* Positions absolues (pour superposer sur image card) */
.pos-top-left     { position: absolute; top: 12px;    left: 12px;  }
.pos-top-right    { position: absolute; top: 12px;    right: 12px; }
.pos-bottom-left  { position: absolute; bottom: 12px; left: 12px;  }
.pos-bottom-right { position: absolute; bottom: 12px; right: 12px; }

/* Variants couleurs — chacun avec dégradé Algérie */
.badge-vedette {
  background: linear-gradient(135deg, #D4A844 0%, #B8862E 100%);
  color: #0F2419;
}
.badge-coup-coeur {
  background: linear-gradient(135deg, #E24B4A 0%, #A32D2D 100%);
  color: #FFF6E5;
}
.badge-tendance {
  background: linear-gradient(135deg, #283461 0%, #1B2649 100%);
  color: #E8B96B;
}
</style>
