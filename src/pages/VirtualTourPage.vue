<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import VirtualTour from '@/components/VirtualTour.vue'

const props = defineProps<{ slug: string }>()
const router = useRouter()

const loading = ref(true)
const tour = ref<any>(null)
const error = ref<string | null>(null)

onMounted(async () => {
  const { data, error: err } = await supabase
    .from('virtual_tours')
    .select('id, title, slug, summary, config, is_published')
    .eq('slug', props.slug)
    .maybeSingle()
  if (err) { error.value = err.message }
  else if (!data) { error.value = 'introuvable' }
  else { tour.value = data; document.title = `${data.title} — Visite virtuelle · Djawal` }
  loading.value = false
})
</script>

<template>
  <div class="vtp">
    <button class="vtp-back" @click="router.back()">← Retour</button>

    <div v-if="loading" class="vtp-state">
      <div class="vtp-spin"></div>
      <p>Chargement de la visite…</p>
    </div>

    <div v-else-if="error" class="vtp-state">
      <span class="vtp-ico">🌐</span>
      <h2>Visite introuvable</h2>
      <p>Cette visite virtuelle n'existe pas ou n'est pas encore publiée.</p>
      <button class="vtp-cta" @click="router.push('/')">Retour à l'accueil</button>
    </div>

    <VirtualTour v-else :config="tour.config" height="100vh" />
  </div>
</template>

<style scoped>
.vtp { position: fixed; inset: 0; background: #0E1B24; }
.vtp-back { position: absolute; top: 16px; left: 16px; z-index: 40; background: rgba(19,37,47,.8); border: 1px solid rgba(243,238,228,.16); color: #F3EEE4; font-family: inherit; font-size: 14px; font-weight: 600; padding: 9px 16px; border-radius: 999px; cursor: pointer; backdrop-filter: blur(8px); }
.vtp-back:hover { border-color: #C56A3E; }
.vtp-state { position: absolute; inset: 0; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 12px; color: #F3EEE4; text-align: center; padding: 24px; }
.vtp-state h2 { font-family: Georgia, serif; font-size: 26px; }
.vtp-state p { color: #AEB9C0; }
.vtp-ico { font-size: 52px; opacity: .5; }
.vtp-cta { margin-top: 12px; background: #C56A3E; border: none; color: #fff; font-family: inherit; font-weight: 700; font-size: 15px; padding: 13px 26px; border-radius: 999px; cursor: pointer; }
.vtp-spin { width: 46px; height: 46px; border: 4px solid rgba(243,238,228,.2); border-top-color: #C56A3E; border-radius: 50%; animation: vtpspin 1s linear infinite; }
@keyframes vtpspin { to { transform: rotate(360deg); } }
</style>
