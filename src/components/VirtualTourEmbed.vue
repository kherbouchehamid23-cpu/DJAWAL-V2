<script setup lang="ts">
import { ref, watch, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'

/**
 * Affiche une bannière « Visite virtuelle » sur une fiche si une visite publiée
 * est rattachée à cet élément (target_type + target_id, rattachement polymorphe).
 * Ne rend rien s'il n'y a pas de visite publiée → aucun impact sur la mise en page.
 */
const props = defineProps<{ targetType: string; targetId: string | null | undefined }>()

const tour = ref<{ slug: string; title: string; summary: string | null; cover_url: string | null } | null>(null)

async function load() {
  tour.value = null
  if (!props.targetType || !props.targetId) return
  const { data } = await supabase
    .from('virtual_tours')
    .select('slug, title, summary, cover_url')
    .eq('target_type', props.targetType)
    .eq('target_id', props.targetId)
    .eq('is_published', true)
    .order('updated_at', { ascending: false })
    .limit(1)
  tour.value = (data && data[0]) || null
}

onMounted(load)
watch(() => [props.targetType, props.targetId], load)
</script>

<template>
  <router-link v-if="tour" :to="`/visite/${tour.slug}`" class="vt-embed">
    <span
      class="vt-embed-cover"
      :style="tour.cover_url ? `background-image:url(${tour.cover_url})` : ''"
    >
      <span class="vt-embed-ico">🥽</span>
    </span>
    <span class="vt-embed-body">
      <span class="vt-embed-kicker">Visite virtuelle 360°</span>
      <strong class="vt-embed-title">{{ tour.title }}</strong>
      <small v-if="tour.summary" class="vt-embed-sub">{{ tour.summary }}</small>
    </span>
    <span class="vt-embed-cta">Explorer&nbsp;→</span>
  </router-link>
</template>

<style scoped>
.vt-embed {
  display: flex;
  align-items: center;
  gap: 16px;
  text-decoration: none;
  border-radius: 16px;
  padding: 12px 16px;
  background: linear-gradient(120deg, #13252F, #0E1B24);
  border: 1px solid rgba(197, 106, 62, 0.4);
  color: #F3EEE4;
  transition: border-color 0.2s, transform 0.2s;
  overflow: hidden;
}
.vt-embed:hover { border-color: #C56A3E; transform: translateY(-1px); }
.vt-embed-cover {
  width: 68px;
  height: 68px;
  flex: none;
  border-radius: 12px;
  background: #1c3a2a center/cover no-repeat;
  display: grid;
  place-items: center;
  position: relative;
}
.vt-embed-cover::after {
  content: '';
  position: absolute;
  inset: 0;
  border-radius: 12px;
  background: rgba(14, 27, 36, 0.35);
}
.vt-embed-ico { font-size: 30px; position: relative; z-index: 1; }
.vt-embed-body { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 2px; }
.vt-embed-kicker {
  font-size: 10.5px;
  font-weight: 700;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: #E0A94E;
}
.vt-embed-title { font-family: Georgia, serif; font-size: 17px; line-height: 1.2; }
.vt-embed-sub {
  font-size: 12.5px;
  color: #AEB9C0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.vt-embed-cta {
  flex: none;
  font-size: 13px;
  font-weight: 700;
  color: #fff;
  background: #C56A3E;
  padding: 9px 15px;
  border-radius: 999px;
  white-space: nowrap;
}
@media (max-width: 560px) {
  .vt-embed-cta { display: none; }
}
</style>
