<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { supabase } from '@/lib/supabase'

interface Memory {
  id: string
  quote: string
  photo_url: string | null
  published: boolean
  created_at: string
  author_id: string
  profiles?: { display_name: string } | null
  destinations?: { name: string } | null
  trips?: { title: string } | null
}

const memories = ref<Memory[]>([])
const loading = ref(true)
const tab = ref<'pending' | 'published' | 'all'>('pending')
const processing = ref<string | null>(null)

const counts = computed(() => ({
  pending: memories.value.filter(m => !m.published).length,
  published: memories.value.filter(m => m.published).length,
  all: memories.value.length
}))

const filtered = computed(() => {
  if (tab.value === 'pending') return memories.value.filter(m => !m.published)
  if (tab.value === 'published') return memories.value.filter(m => m.published)
  return memories.value
})

async function load() {
  loading.value = true
  const { data } = await supabase
    .from('memories')
    .select('id, quote, photo_url, published, created_at, author_id, profiles!memories_author_id_fkey(display_name), destinations(name), trips(title)')
    .order('created_at', { ascending: false })
  memories.value = (data as any) || []
  loading.value = false
}

onMounted(load)

async function setPublished(m: Memory, value: boolean) {
  processing.value = m.id
  const { error } = await supabase
    .from('memories')
    .update({ published: value })
    .eq('id', m.id)
  processing.value = null
  if (error) { alert('Erreur : ' + error.message); return }
  m.published = value
}

async function remove(m: Memory) {
  if (!confirm(`Supprimer définitivement le souvenir de ${m.profiles?.display_name} ?`)) return
  processing.value = m.id
  const { error } = await supabase.from('memories').delete().eq('id', m.id)
  processing.value = null
  if (error) { alert('Erreur : ' + error.message); return }
  memories.value = memories.value.filter(x => x.id !== m.id)
}

function fmtDate(iso: string) {
  return new Date(iso).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric' })
}
</script>

<template>
  <div class="memories-admin">
    <div class="djawal-container djawal-section">
      <div class="back-link">
        <router-link to="/admin">← Retour admin</router-link>
      </div>

      <header class="page-header">
        <div>
          <div class="section-eyebrow">Modération</div>
          <h1>Souvenirs des voyageurs</h1>
          <p class="lead">
            Approuvez ou refusez les récits soumis par la communauté avant qu'ils n'apparaissent
            sur le mur public et la home.
          </p>
        </div>
      </header>

      <div class="tabs">
        <button class="tab" :class="{ active: tab === 'pending' }" @click="tab = 'pending'">
          ⏳ En attente <span class="count">{{ counts.pending }}</span>
        </button>
        <button class="tab" :class="{ active: tab === 'published' }" @click="tab = 'published'">
          ✓ Publiés <span class="count">{{ counts.published }}</span>
        </button>
        <button class="tab" :class="{ active: tab === 'all' }" @click="tab = 'all'">
          📋 Tous <span class="count">{{ counts.all }}</span>
        </button>
      </div>

      <div v-if="loading" class="loading">Chargement…</div>

      <div v-else-if="filtered.length === 0" class="empty">
        <p v-if="tab === 'pending'">🎉 Aucun souvenir en attente.</p>
        <p v-else>Aucun souvenir dans cette catégorie.</p>
      </div>

      <div v-else class="mem-list">
        <article
          v-for="m in filtered"
          :key="m.id"
          class="mem-row"
          :data-published="m.published"
        >
          <div
            v-if="m.photo_url"
            class="mem-thumb"
            :style="`background-image: url(${m.photo_url})`"
          ></div>
          <div class="mem-content">
            <p class="mem-quote">« {{ m.quote }} »</p>
            <div class="mem-meta">
              <strong>{{ m.profiles?.display_name }}</strong>
              <span class="dot">·</span>
              <span>{{ fmtDate(m.created_at) }}</span>
              <span v-if="m.trips" class="link-tag">🗺️ {{ m.trips.title }}</span>
              <span v-else-if="m.destinations" class="link-tag">📍 {{ m.destinations.name }}</span>
              <span class="badge" :class="m.published ? 'pub' : 'pen'">
                {{ m.published ? 'Publié' : 'En attente' }}
              </span>
            </div>

            <div class="mem-actions">
              <v-btn
                v-if="!m.published"
                color="success"
                variant="flat"
                size="small"
                :loading="processing === m.id"
                @click="setPublished(m, true)"
              >✓ Publier</v-btn>
              <v-btn
                v-else
                variant="outlined"
                size="small"
                :loading="processing === m.id"
                @click="setPublished(m, false)"
              >🔒 Dépublier</v-btn>
              <v-btn
                variant="text"
                color="error"
                size="small"
                :loading="processing === m.id"
                @click="remove(m)"
              >🗑️ Supprimer</v-btn>
            </div>
          </div>
        </article>
      </div>
    </div>
  </div>
</template>

<style scoped>
.memories-admin { background: var(--c-fond); min-height: 100vh; }
.back-link { margin-bottom: var(--space-3); }
.back-link a {
  color: var(--c-primaire);
  text-decoration: none;
  font-weight: 600; font-size: 14px;
}
.back-link a:hover { text-decoration: underline; }

.section-eyebrow {
  color: var(--c-accent-fort);
  font-size: 13px; font-weight: 700;
  letter-spacing: 0.2em; text-transform: uppercase;
  margin-bottom: var(--space-2);
}
.page-header { margin-bottom: var(--space-4); }
.page-header h1 { font-size: clamp(28px, 3.5vw, 40px); margin-bottom: 4px; }
.lead { color: var(--c-texte-doux); max-width: 640px; }

.tabs {
  display: flex; gap: var(--space-2);
  border-bottom: 1px solid var(--c-gris-clair);
  margin-bottom: var(--space-4);
  flex-wrap: wrap;
}
.tab {
  background: none; border: none;
  border-bottom: 3px solid transparent;
  padding: 12px 16px;
  font-family: inherit;
  font-size: 14px; font-weight: 600;
  color: var(--c-texte-doux);
  cursor: pointer;
  display: inline-flex; align-items: center; gap: 8px;
  transition: var(--t-base);
}
.tab:hover { color: var(--c-primaire); }
.tab.active {
  color: var(--c-primaire);
  border-bottom-color: var(--c-accent);
}
.count {
  background: var(--c-fond-chaud);
  padding: 2px 8px;
  border-radius: var(--r-pill);
  font-size: 11px; font-weight: 700;
}

.loading, .empty {
  text-align: center; padding: var(--space-8);
  color: var(--c-texte-doux);
}

.mem-list { display: flex; flex-direction: column; gap: var(--space-3); }
.mem-row {
  background: var(--c-surface);
  border-radius: var(--r-lg);
  overflow: hidden;
  box-shadow: var(--ombre-douce);
  display: grid;
  grid-template-columns: 160px 1fr;
  border-left: 4px solid var(--c-accent);
}
.mem-row[data-published="true"] { border-left-color: #2D5A3D; }

.mem-thumb {
  background-size: cover;
  background-position: center;
  background-color: var(--c-fond-chaud);
  min-height: 140px;
}
.mem-content { padding: var(--space-4); }

.mem-quote {
  font-family: var(--font-display);
  font-size: 17px;
  font-style: italic;
  color: var(--c-primaire-profond);
  line-height: 1.5;
  margin-bottom: var(--space-2);
}
.mem-meta {
  display: flex; align-items: center; gap: 8px;
  flex-wrap: wrap;
  font-size: 13px;
  color: var(--c-texte);
  margin-bottom: var(--space-3);
}
.dot { color: var(--c-texte-doux); }
.link-tag { color: var(--c-accent-fort); font-style: italic; }
.badge {
  padding: 2px 10px;
  border-radius: var(--r-pill);
  font-size: 11px; font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
.badge.pub { background: rgba(45, 90, 61, 0.15); color: #2D5A3D; }
.badge.pen { background: rgba(212, 160, 79, 0.15); color: #A6772A; }

.mem-actions { display: flex; gap: 8px; flex-wrap: wrap; }

@media (max-width: 700px) {
  .mem-row { grid-template-columns: 1fr; }
}
</style>
