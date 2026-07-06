<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'
import { useRoute } from 'vue-router'
import VirtualTour from '@/components/VirtualTour.vue'
import VirtualTourEditor from '@/components/VirtualTourEditor.vue'

const auth = useAuthStore()
const route = useRoute()
const prefillName = ref<string>('')

const tours = ref<any[]>([])
const loading = ref(true)
const editing = ref<any>(null)
const configText = ref('')
const configError = ref<string | null>(null)
const previewKey = ref(0)
const saving = ref(false)
const message = ref<string | null>(null)

const ENTITY_TYPES = ['site', 'restaurant', 'accommodation', 'activity', 'destination', 'operator', 'trip', 'guide', 'memory']

// Modèle de départ (panoramas d'exemple valides → l'aperçu marche tout de suite)
const EXAMPLE = {
  firstScene: 's0',
  scenes: [
    {
      id: 's0', title: 'Salle 1',
      panorama: 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/62/Emerging_Technologies_Gallery_-_360x180_Degree_Equirectangular_View_-_Science_Exploration_Hall_-_Science_City_-_Kolkata_2016-02-23_0570-0578.tif/lossy-page1-3840px-Emerging_Technologies_Gallery_-_360x180_Degree_Equirectangular_View_-_Science_Exploration_Hall_-_Science_City_-_Kolkata_2016-02-23_0570-0578.tif.jpg',
      hotspots: [
        { type: 'scene', yaw: 25, pitch: -6, target: 's1', label: 'Salle suivante' },
        { type: 'info', yaw: 110, pitch: 2, title: 'À propos', desc: 'Décrivez ici une œuvre ou un point d\'intérêt.' }
      ]
    },
    {
      id: 's1', title: 'Salle 2',
      panorama: 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e9/Evolution_Interpretation_Gallery_-_360x180_Degree_Equirectangular_View_-_Science_Exploration_Hall_-_Science_City_2015-12-04_6793-6802.tif/lossy-page1-3840px-Evolution_Interpretation_Gallery_-_360x180_Degree_Equirectangular_View_-_Science_Exploration_Hall_-_Science_City_2015-12-04_6793-6802.tif.jpg',
      hotspots: [
        { type: 'scene', yaw: 200, pitch: -6, target: 's0', label: 'Salle précédente' }
      ]
    }
  ]
}

const parsedConfig = computed(() => { try { return JSON.parse(configText.value) } catch { return null } })
const canPreview = computed(() => parsedConfig.value && Array.isArray(parsedConfig.value.scenes) && parsedConfig.value.scenes.length > 0)

// Modèle piloté par l'éditeur visuel (get = config courante, set = réécrit le JSON)
const editModel = computed<any>({
  get() { const p = parsedConfig.value; return p && Array.isArray(p.scenes) ? p : { firstScene: '', scenes: [] } },
  set(v) { configText.value = JSON.stringify(v, null, 2); configError.value = null }
})

function slugify(s: string) {
  return (s || '').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '').slice(0, 60)
}

async function loadTours() {
  loading.value = true
  const { data } = await supabase
    .from('virtual_tours')
    .select('id, title, slug, is_published, target_type, target_id, updated_at')
    .order('updated_at', { ascending: false })
  tours.value = data || []
  loading.value = false
}

function newTour() {
  editing.value = { id: null, title: '', slug: '', summary: '', cover_url: '', target_type: '', target_id: '', is_published: false }
  configText.value = JSON.stringify(EXAMPLE, null, 2)
  configError.value = null; message.value = null; previewKey.value++
}

async function editTour(t: any) {
  message.value = null
  const { data } = await supabase.from('virtual_tours').select('*').eq('id', t.id).single()
  if (data) {
    editing.value = { ...data, target_type: data.target_type || '', target_id: data.target_id || '' }
    configText.value = JSON.stringify(data.config || {}, null, 2)
    configError.value = null; previewKey.value++
  }
}

function refreshPreview() {
  try { JSON.parse(configText.value); configError.value = null; previewKey.value++ }
  catch (e: any) { configError.value = 'JSON invalide : ' + e.message }
}

async function save() {
  if (!editing.value) return
  let config: any
  try { config = JSON.parse(configText.value) } catch (e: any) { configError.value = 'JSON invalide : ' + e.message; return }
  if (!Array.isArray(config.scenes) || config.scenes.length === 0) { configError.value = 'La visite doit contenir au moins une scène.'; return }
  saving.value = true; message.value = null
  const e = editing.value
  const payload: any = {
    title: e.title.trim(),
    slug: (e.slug && e.slug.trim()) || slugify(e.title),
    summary: e.summary || null,
    cover_url: e.cover_url || null,
    config,
    target_type: e.target_type || null,
    target_id: e.target_id || null,
    is_published: !!e.is_published
  }
  let res
  if (e.id) {
    res = await supabase.from('virtual_tours').update(payload).eq('id', e.id).select().single()
  } else {
    payload.created_by = auth.user?.id
    res = await supabase.from('virtual_tours').insert(payload).select().single()
  }
  saving.value = false
  if (res.error) { message.value = 'Erreur : ' + res.error.message; return }
  message.value = 'Visite enregistrée ✓'
  editing.value = { ...res.data, target_type: res.data.target_type || '', target_id: res.data.target_id || '' }
  await loadTours()
}

async function del(t: any) {
  if (!confirm(`Supprimer la visite « ${t.title} » ?`)) return
  await supabase.from('virtual_tours').delete().eq('id', t.id)
  if (editing.value?.id === t.id) editing.value = null
  await loadTours()
}

onMounted(async () => {
  await loadTours()
  const q = route.query
  if (q.target_type && q.target_id) {
    newTour()
    editing.value.target_type = String(q.target_type)
    editing.value.target_id = String(q.target_id)
    if (q.target_name) {
      const nm = String(q.target_name)
      prefillName.value = nm
      editing.value.title = 'Visite — ' + nm
      editing.value.slug = slugify(editing.value.title)
    }
  }
})
</script>

<template>
  <div class="vtm">
    <header class="vtm-head">
      <div>
        <h1>Visites virtuelles</h1>
        <p>Créez et publiez des visites 360° — navigation aux flèches, points d'info, VR.</p>
      </div>
      <button class="btn primary" @click="newTour">+ Nouvelle visite</button>
    </header>

    <div v-if="!auth.canCreateVirtualTours" class="vtm-denied">
      Vous n'avez pas encore le droit de créer des visites virtuelles. Demandez à un administrateur de l'activer.
    </div>

    <div v-else class="vtm-grid">
      <!-- Liste -->
      <aside class="vtm-list">
        <div v-if="loading" class="muted">Chargement…</div>
        <div v-else-if="!tours.length" class="muted">Aucune visite pour l'instant.</div>
        <div v-for="t in tours" :key="t.id" class="vtm-item" :class="{ on: editing && editing.id === t.id }">
          <div class="vtm-item-main" @click="editTour(t)">
            <b>{{ t.title }}</b>
            <span class="vtm-badge" :class="t.is_published ? 'pub' : 'draft'">{{ t.is_published ? 'Publiée' : 'Brouillon' }}</span>
            <small>{{ t.target_type || 'autonome' }} · /visite/{{ t.slug }}</small>
          </div>
          <div class="vtm-item-act">
            <a :href="`/visite/${t.slug}`" target="_blank" title="Ouvrir">↗</a>
            <button @click="del(t)" title="Supprimer">✕</button>
          </div>
        </div>
      </aside>

      <!-- Éditeur -->
      <section v-if="editing" class="vtm-editor">
        <div v-if="prefillName" class="vtm-attach">🔗 Rattachée à : <strong>{{ prefillName }}</strong> <span>({{ editing.target_type }})</span></div>
        <div class="row2">
          <label>Titre<input v-model="editing.title" placeholder="Ex : Musée national du Bardo" @blur="!editing.slug && (editing.slug = slugify(editing.title))"></label>
          <label>Slug (URL)<input v-model="editing.slug" placeholder="musee-bardo"></label>
        </div>
        <label>Résumé<input v-model="editing.summary" placeholder="Courte description (optionnel)"></label>
        <div class="row2">
          <label>Rattaché à (type)
            <input v-model="editing.target_type" list="ent-types" placeholder="site, restaurant, hôtel… (optionnel)">
            <datalist id="ent-types"><option v-for="e in ENTITY_TYPES" :key="e" :value="e" /></datalist>
          </label>
          <label>ID de l'élément<input v-model="editing.target_id" placeholder="UUID de la fiche (optionnel)"></label>
        </div>
        <label>Image de couverture (URL)<input v-model="editing.cover_url" placeholder="https://…"></label>

        <div class="vtm-visual">
          <div class="vtm-visual-head">
            <h3>Composition de la visite</h3>
            <span class="hint">Ajoutez des scènes, collez vos images 360°, puis cliquez dans l'image pour poser flèches et points d'info.</span>
          </div>
          <VirtualTourEditor v-model="editModel" />
        </div>

        <details class="vtm-advanced">
          <summary>Mode avancé — éditer le JSON</summary>
          <textarea v-model="configText" spellcheck="false" rows="12" @blur="refreshPreview"></textarea>
          <div class="vtm-jsonbar">
            <button class="btn ghost" type="button" @click="refreshPreview">Rafraîchir l'aperçu</button>
            <span v-if="configError" class="err">{{ configError }}</span>
          </div>
        </details>

        <div class="vtm-preview" v-if="canPreview">
          <VirtualTour :key="previewKey" :config="parsedConfig" height="380px" />
        </div>

        <div class="vtm-save">
          <label class="pub"><input type="checkbox" v-model="editing.is_published"> Publier (visible publiquement)</label>
          <span class="spacer"></span>
          <span v-if="message" class="msg">{{ message }}</span>
          <button class="btn primary" :disabled="saving" @click="save">{{ saving ? 'Enregistrement…' : 'Enregistrer' }}</button>
        </div>
      </section>

      <section v-else class="vtm-empty">
        <p>Sélectionnez une visite à gauche, ou créez-en une nouvelle.</p>
      </section>
    </div>
  </div>
</template>

<style scoped>
.vtm { max-width: 1200px; margin: 0 auto; padding: 26px 22px 60px; }
.vtm-head { display: flex; align-items: flex-end; justify-content: space-between; gap: 20px; margin-bottom: 22px; flex-wrap: wrap; }
.vtm-head h1 { font-family: Georgia, serif; font-size: 28px; }
.vtm-head p { color: #6b7280; margin-top: 4px; font-size: 14px; }
.vtm-denied { border: 1px solid #e3d6c8; background: #fbf5ea; border-radius: 14px; padding: 20px; color: #7a5a2a; }
.vtm-grid { display: grid; grid-template-columns: 300px 1fr; gap: 22px; align-items: start; }
.vtm-list { display: flex; flex-direction: column; gap: 8px; }
.vtm-item { border: 1px solid #e6e0d6; border-radius: 12px; padding: 10px 12px; display: flex; align-items: center; gap: 8px; background: #fff; }
.vtm-item.on { border-color: #C56A3E; box-shadow: 0 0 0 2px rgba(197,106,62,.12); }
.vtm-item-main { flex: 1; cursor: pointer; display: flex; flex-direction: column; gap: 3px; }
.vtm-item-main b { font-size: 14.5px; }
.vtm-item-main small { color: #9aa0a6; font-size: 11.5px; }
.vtm-badge { font-size: 10px; font-weight: 700; padding: 2px 8px; border-radius: 999px; width: fit-content; text-transform: uppercase; letter-spacing: .04em; }
.vtm-badge.pub { background: #d8efe0; color: #1c6b45; }
.vtm-badge.draft { background: #eee; color: #777; }
.vtm-item-act { display: flex; gap: 6px; }
.vtm-item-act a, .vtm-item-act button { border: 1px solid #e6e0d6; background: #fff; width: 30px; height: 30px; border-radius: 8px; cursor: pointer; display: grid; place-items: center; color: #555; text-decoration: none; }
.vtm-item-act a:hover, .vtm-item-act button:hover { border-color: #C56A3E; color: #C56A3E; }
.vtm-editor { display: flex; flex-direction: column; gap: 14px; }
.vtm-editor label { display: flex; flex-direction: column; gap: 6px; font-size: 13px; color: #444; font-weight: 600; }
.vtm-editor input, .vtm-editor textarea { font-family: inherit; font-size: 14px; padding: 11px 13px; border: 1px solid #d9d2c6; border-radius: 10px; font-weight: 400; color: #222; }
.vtm-editor input:focus, .vtm-editor textarea:focus { outline: none; border-color: #C56A3E; }
.vtm-editor textarea { font-family: ui-monospace, monospace; font-size: 12.5px; line-height: 1.5; }
.row2 { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
.vtm-jsonbar { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; margin-top: -4px; }
.vtm-jsonbar .hint { color: #9aa0a6; font-size: 12px; }
.vtm-jsonbar .err { color: #c0392b; font-size: 12.5px; font-weight: 600; }
.vtm-preview { border-radius: 16px; overflow: hidden; border: 1px solid #e6e0d6; }
.vtm-attach { background: #eef6f0; border: 1px solid #cfe6d8; border-radius: 10px; padding: 10px 14px; font-size: 13.5px; color: #1c6b45; }
.vtm-attach span { color: #6b8f7d; }
.vtm-visual-head { margin-bottom: 10px; }
.vtm-visual-head h3 { font-family: Georgia, serif; font-size: 17px; color: #2a2a2a; }
.vtm-visual-head .hint { display: block; color: #9aa0a6; font-size: 12.5px; margin-top: 2px; }
.vtm-advanced { border: 1px solid #e6e0d6; border-radius: 12px; padding: 10px 14px; background: #fbf9f5; }
.vtm-advanced summary { cursor: pointer; font-size: 13px; font-weight: 600; color: #7a5a2a; }
.vtm-advanced textarea { width: 100%; margin-top: 10px; font-family: ui-monospace, monospace; font-size: 12.5px; line-height: 1.5; padding: 11px 13px; border: 1px solid #d9d2c6; border-radius: 10px; }
.vtm-save { display: flex; align-items: center; gap: 14px; margin-top: 8px; }
.vtm-save .pub { flex-direction: row; align-items: center; gap: 8px; font-weight: 600; }
.vtm-save .spacer { flex: 1; }
.vtm-save .msg { color: #1c6b45; font-size: 13px; font-weight: 600; }
.vtm-empty { color: #9aa0a6; padding: 40px; text-align: center; border: 1px dashed #e6e0d6; border-radius: 14px; }
.btn { font-family: inherit; font-weight: 700; font-size: 14px; border: none; border-radius: 999px; padding: 11px 20px; cursor: pointer; }
.btn.primary { background: #C56A3E; color: #fff; }
.btn.primary:disabled { opacity: .6; }
.btn.ghost { background: none; border: 1.5px solid #d9d2c6; color: #444; }
.muted { color: #9aa0a6; font-size: 13px; padding: 8px; }
@media(max-width: 820px){ .vtm-grid { grid-template-columns: 1fr; } .row2 { grid-template-columns: 1fr; } }
</style>
