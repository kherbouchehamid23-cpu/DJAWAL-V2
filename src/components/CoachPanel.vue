<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { supabase } from '@/lib/supabase'
import { scoreTrip, type TripQualityInput } from '@/lib/coachQuality'

/**
 * Coach Djawal — panneau d'aide à la rédaction dans le TripBuilder.
 * Le scoring est local (déterministe). L'IA (Edge Function `coach`) ne sert
 * qu'à générer / réécrire / traduire ; la clé Gemini reste côté serveur.
 *
 * Le parent passe le `model` (réactif) et écoute :
 *  - @apply (champs générés à fusionner dans le formulaire)
 *  - @update:score (ai_quality_score à persister)
 *  - @can-publish (booléen pour activer le bouton Publier du parent)
 */

const props = defineProps<{
  model: TripQualityInput
  catalog?: { name: string; type: string }[]
  destinationName?: string
}>()

const emit = defineEmits<{
  (e: 'apply', data: Record<string, any>): void
  (e: 'update:score', score: number): void
  (e: 'can-publish', ok: boolean): void
}>()

const threshold = ref(70)
const busy = ref('')      // '', 'generate', 'rewrite', 'translate'
const errorMsg = ref('')
const toast = ref('')

const result = computed(() => scoreTrip(props.model, threshold.value))

watch(result, (r) => {
  emit('update:score', r.score)
  emit('can-publish', r.canPublish)
}, { immediate: true, deep: true })

onMounted(async () => {
  // Seuil configurable (app_settings)
  const { data } = await supabase.from('app_settings').select('value').eq('key', 'publish_quality_threshold').maybeSingle()
  if (data?.value) threshold.value = parseInt(data.value) || 70
})

function flash(m: string) { toast.value = m; setTimeout(() => (toast.value = ''), 2600) }

async function call(action: string, extra: Record<string, any> = {}) {
  busy.value = action; errorMsg.value = ''
  try {
    const { data, error } = await supabase.functions.invoke('coach', {
      body: {
        action,
        trip: {
          destination: props.destinationName,
          durationDays: props.model.durationDays,
          priceDa: props.model.priceDa,
          difficulty: props.model.difficulty,
          description: props.model.description_fr,
          title_fr: props.model.title_fr,
          description_fr: props.model.description_fr,
          highlights: (props.model.tags || '').split(',').map(t => t.trim()).filter(Boolean)
        },
        catalog: props.catalog || [],
        ...extra
      }
    })
    if (error) throw error
    return data
  } catch (e: any) {
    errorMsg.value = "Le coach n'a pas pu répondre. Réessaie dans un instant."
    return null
  } finally {
    busy.value = ''
  }
}

async function generate() {
  const d = await call('generate')
  if (!d) return
  emit('apply', {
    title_fr: d.title_fr, title_ar: d.title_ar, title_en: d.title_en,
    description_fr: d.description_fr, description_ar: d.description_ar, description_en: d.description_en,
    days: d.days, tags: Array.isArray(d.tags) ? d.tags.join(', ') : d.tags,
    ai_assisted: true
  })
  flash('Fiche générée en FR · AR · EN à partir du catalogue')
}

async function translateAll() {
  if (!props.model.title_fr || !props.model.description_fr) { flash('Écris d\'abord le FR'); return }
  const d = await call('translate')
  if (!d) return
  emit('apply', { title_ar: d.title_ar, title_en: d.title_en, description_ar: d.description_ar, description_en: d.description_en, ai_assisted: true })
  flash('Traductions AR + EN générées')
}

async function improve() {
  if (!props.model.description_fr) { flash('Rien à reformuler'); return }
  const d = await call('rewrite', { text: props.model.description_fr, lang: 'fr' })
  if (!d?.rewritten) return
  emit('apply', { description_fr: d.rewritten, ai_assisted: true })
  flash('Description reformulée')
}
</script>

<template>
  <aside class="coach">
    <div class="hd"><span class="dot"></span><b>Coach Djawal</b></div>
    <p class="sub">Je t'aide à publier une fiche complète et désirable.</p>

    <div class="score">
      <div class="ring" :style="{ '--p': result.score }"><i>{{ result.score }}</i></div>
      <div class="meta">
        <b>Score qualité</b><div>sur 100</div>
        <div class="gate" :class="result.canPublish ? 'go' : 'no'">
          {{ result.canPublish ? `Prêt à publier (seuil ${threshold})` : (result.mustsOk ? `Score < seuil ${threshold}` : 'Exigences manquantes') }}
        </div>
      </div>
    </div>

    <ul class="musts">
      <li v-for="m in result.musts" :key="m.label" :class="m.ok ? 'ok' : 'ko'">
        <span class="ic">{{ m.ok ? '✓' : '•' }}</span>{{ m.label }}
      </li>
    </ul>

    <div class="sugg">
      <b>Suggestions du coach</b>
      <ul><li v-for="s in result.suggestions" :key="s">{{ s }}</li></ul>
    </div>

    <p v-if="errorMsg" class="err">{{ errorMsg }}</p>

    <div class="actions">
      <button class="btn gold" :disabled="!!busy" @click="generate">
        {{ busy === 'generate' ? '…' : '✦ Générer depuis mes infos' }}
      </button>
      <button class="btn ghost" :disabled="!!busy" @click="improve">
        {{ busy === 'rewrite' ? '…' : 'Améliorer / reformuler' }}
      </button>
      <button class="btn ghost" :disabled="!!busy" @click="translateAll">
        {{ busy === 'translate' ? '…' : 'Traduire FR → AR + EN' }}
      </button>
    </div>

    <transition name="fade"><div v-if="toast" class="toast">{{ toast }}</div></transition>
  </aside>
</template>

<style scoped>
.coach{position:sticky;top:18px;background:linear-gradient(180deg,#13261d,#0e1f17);color:#f3eee2;border-radius:16px;padding:20px;border:1px solid rgba(201,162,75,.35)}
.hd{display:flex;align-items:center;gap:9px}
.hd .dot{width:8px;height:8px;border-radius:50%;background:#E7C879;box-shadow:0 0 0 0 rgba(231,200,121,.6);animation:pl 1.8s infinite}
@keyframes pl{0%{box-shadow:0 0 0 0 rgba(231,200,121,.5)}70%{box-shadow:0 0 0 8px rgba(231,200,121,0)}100%{box-shadow:0 0 0 0 rgba(231,200,121,0)}}
.hd b{font-family:'Cormorant Garamond',serif;font-style:italic;font-size:19px}
.sub{font-size:12px;opacity:.7;margin:2px 0 16px}
.score{display:flex;align-items:center;gap:14px;margin-bottom:12px}
.ring{--p:0;width:74px;height:74px;border-radius:50%;flex:none;display:grid;place-items:center;background:conic-gradient(#E7C879 calc(var(--p)*1%), rgba(255,255,255,.12) 0)}
.ring i{width:58px;height:58px;border-radius:50%;background:#0e1f17;display:grid;place-items:center;font-weight:600;font-size:19px;font-style:normal}
.meta b{font-size:13px}.meta>div{font-size:12px;opacity:.75}
.gate{margin-top:3px;font-size:12px}.gate.go{color:#7fe0a0;opacity:1}.gate.no{color:#f0a98f;opacity:1}
.musts{list-style:none;margin:6px 0 14px;font-size:12.5px;padding:0}
.musts li{display:flex;gap:8px;align-items:flex-start;padding:4px 0}
.musts .ic{width:16px;flex:none;text-align:center}
.musts li.ok{color:#cfe6d6}.musts li.ko{color:#f0bdae}
.sugg{background:rgba(46,123,166,.12);border:1px solid rgba(46,123,166,.3);border-radius:11px;padding:11px 13px;font-size:12.5px;margin-bottom:12px}
.sugg b{color:#E7C879}.sugg ul{margin:6px 0 0 16px}.sugg li{margin:3px 0}
.err{color:#f0a98f;font-size:12.5px;margin-bottom:10px}
.actions{display:flex;flex-direction:column;gap:9px}
.btn{border:0;border-radius:9px;padding:11px 14px;font-family:'Outfit',sans-serif;font-weight:500;font-size:14px;cursor:pointer;width:100%}
.btn:disabled{opacity:.6;cursor:default}
.btn.gold{background:#C9A24B;color:#1a160c}.btn.gold:hover{background:#E7C879}
.btn.ghost{background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.2);color:#f3eee2}
.toast{margin-top:12px;background:#0c1b13;border:1px solid #C9A24B;color:#f3eee2;padding:9px 13px;border-radius:10px;font-size:12.5px;text-align:center}
.fade-enter-active,.fade-leave-active{transition:opacity .3s}.fade-enter-from,.fade-leave-to{opacity:0}
</style>
