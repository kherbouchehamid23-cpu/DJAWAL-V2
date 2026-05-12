<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { supabase } from '@/lib/supabase'

interface Conversation {
  id: string
  user_id: string | null
  user_query: string
  retrieved_resource_ids: string[]
  llm_response: any
  validation_passed: boolean | null
  validation_notes: string | null
  tokens_used: number | null
  latency_ms: number | null
  created_at: string
  profiles?: { display_name: string } | null
}

const conversations = ref<Conversation[]>([])
const loading = ref(true)
const filter = ref<'all' | 'failed' | 'passed'>('all')
const embedStatus = ref<Record<string, string>>({})
const embedding = ref<string | null>(null)

const filtered = computed(() => {
  if (filter.value === 'failed') return conversations.value.filter(c => c.validation_passed === false)
  if (filter.value === 'passed') return conversations.value.filter(c => c.validation_passed === true)
  return conversations.value
})

const stats = computed(() => {
  const total = conversations.value.length
  const failed = conversations.value.filter(c => c.validation_passed === false).length
  const avgLatency = total > 0
    ? Math.round(conversations.value.reduce((s, c) => s + (c.latency_ms || 0), 0) / total)
    : 0
  const totalTokens = conversations.value.reduce((s, c) => s + (c.tokens_used || 0), 0)
  return { total, failed, avgLatency, totalTokens }
})

async function load() {
  loading.value = true
  const { data } = await supabase
    .from('ai_conversations')
    .select('*, profiles(display_name)')
    .order('created_at', { ascending: false })
    .limit(100)
  conversations.value = (data as any) || []
  loading.value = false
}

onMounted(load)

const TABLES = ['destinations', 'hotels', 'sites', 'restaurants', 'activities', 'trips']

async function generateEmbeddings(table: string) {
  embedding.value = table
  embedStatus.value[table] = 'En cours…'
  try {
    const { data, error } = await supabase.functions.invoke('generate-embeddings', {
      body: { table, limit: 50 }
    })
    if (error) throw error
    let msg = `✓ ${data.processed} traités`
    if (data.failed) {
      msg += `, ${data.failed} échecs`
      if (data.errors && data.errors.length > 0) {
        msg += `\n  → 1er échec : ${data.errors[0]}`
      }
    }
    embedStatus.value[table] = msg
  } catch (e: any) {
    embedStatus.value[table] = `✗ Erreur : ${e.message}`
  } finally {
    embedding.value = null
  }
}

function fmtDate(iso: string) {
  return new Date(iso).toLocaleString('fr-FR', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' })
}
function answerPreview(r: any): string {
  return (r?.text || '').slice(0, 200) + ((r?.text || '').length > 200 ? '…' : '')
}
</script>

<template>
  <div class="ai-logs">
    <div class="djawal-container djawal-section">
      <div class="back-link">
        <router-link to="/admin">← Retour admin</router-link>
      </div>

      <header class="page-header">
        <div>
          <div class="section-eyebrow">Audit IA</div>
          <h1>🤖 Logs RAG & embeddings</h1>
          <p class="lead">
            Auditez les conversations de l'assistant IA et gérez les embeddings vectoriels
            qui alimentent la recherche sémantique.
          </p>
        </div>
      </header>

      <!-- STATS -->
      <div class="stats-row">
        <div class="stat-mini">
          <strong>{{ stats.total }}</strong>
          <span>Conversations</span>
        </div>
        <div class="stat-mini" :class="{ alert: stats.failed > 0 }">
          <strong>{{ stats.failed }}</strong>
          <span>Validations échouées</span>
        </div>
        <div class="stat-mini">
          <strong>{{ stats.avgLatency }} ms</strong>
          <span>Latence moyenne</span>
        </div>
        <div class="stat-mini">
          <strong>{{ stats.totalTokens.toLocaleString() }}</strong>
          <span>Tokens utilisés</span>
        </div>
      </div>

      <!-- EMBEDDINGS -->
      <section class="embed-block">
        <h2>Générer les embeddings</h2>
        <p class="hint">
          Pour que l'IA trouve une ressource, elle doit être "embeddée". Lancez la génération
          quand vous ajoutez de nouvelles ressources (par lot de 50, throttlé pour rester sous quota Gemini gratuit).
        </p>
        <div class="embed-buttons">
          <div v-for="t in TABLES" :key="t" class="embed-row">
            <v-btn
              variant="outlined"
              :loading="embedding === t"
              :disabled="!!embedding && embedding !== t"
              @click="generateEmbeddings(t)"
            >
              Embed {{ t }}
            </v-btn>
            <span class="embed-status">{{ embedStatus[t] || '—' }}</span>
          </div>
        </div>
      </section>

      <!-- LOGS -->
      <section>
        <div class="logs-head">
          <h2>Conversations récentes</h2>
          <div class="tabs">
            <button class="tab" :class="{ active: filter === 'all' }" @click="filter = 'all'">
              Toutes ({{ conversations.length }})
            </button>
            <button class="tab" :class="{ active: filter === 'failed' }" @click="filter = 'failed'">
              ⚠️ Échouées ({{ stats.failed }})
            </button>
            <button class="tab" :class="{ active: filter === 'passed' }" @click="filter = 'passed'">
              ✓ OK
            </button>
          </div>
        </div>

        <div v-if="loading" class="loading">Chargement…</div>

        <div v-else-if="filtered.length === 0" class="empty">
          Aucune conversation dans cette catégorie.
        </div>

        <div v-else class="logs-list">
          <article
            v-for="c in filtered"
            :key="c.id"
            class="log-row"
            :data-passed="c.validation_passed"
          >
            <div class="log-head">
              <span class="log-user">{{ c.profiles?.display_name || 'Anonyme' }}</span>
              <span class="log-date">{{ fmtDate(c.created_at) }}</span>
              <span class="log-meta">
                {{ c.latency_ms }} ms · {{ c.tokens_used }} tokens
              </span>
              <span v-if="c.validation_passed === false" class="badge failed">⚠️ Validation</span>
              <span v-else class="badge ok">✓</span>
            </div>
            <div class="log-q">
              <strong>Q :</strong> {{ c.user_query }}
            </div>
            <div class="log-a">
              <strong>R :</strong> {{ answerPreview(c.llm_response) }}
            </div>
            <div v-if="c.validation_notes" class="log-notes">
              <strong>Notes :</strong> {{ c.validation_notes }}
            </div>
            <div class="log-resources">
              {{ c.retrieved_resource_ids.length }} ressource{{ c.retrieved_resource_ids.length > 1 ? 's' : '' }} consultée{{ c.retrieved_resource_ids.length > 1 ? 's' : '' }}
            </div>
          </article>
        </div>
      </section>
    </div>
  </div>
</template>

<style scoped>
.ai-logs { background: var(--c-fond); min-height: 100vh; }
.back-link { margin-bottom: var(--space-3); }
.back-link a {
  color: var(--c-primaire); text-decoration: none;
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
.lead { color: var(--c-texte-doux); max-width: 720px; }

.stats-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: var(--space-3);
  margin-bottom: var(--space-5);
}
.stat-mini {
  background: var(--c-surface);
  border-radius: var(--r-md);
  padding: var(--space-3);
  text-align: center;
  box-shadow: var(--ombre-douce);
  border-top: 3px solid var(--c-primaire);
}
.stat-mini.alert { border-top-color: #C04A3A; }
.stat-mini strong {
  display: block;
  font-family: var(--font-display);
  font-size: 28px;
  color: var(--c-primaire-profond);
}
.stat-mini.alert strong { color: #C04A3A; }
.stat-mini span {
  font-size: 12px;
  color: var(--c-texte-doux);
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.embed-block {
  background: var(--c-surface);
  border-radius: var(--r-lg);
  padding: var(--space-5);
  margin-bottom: var(--space-5);
  box-shadow: var(--ombre-douce);
  border-left: 4px solid var(--c-accent);
}
.embed-block h2 {
  font-family: var(--font-display);
  font-size: 22px;
  color: var(--c-primaire-profond);
  margin-bottom: 4px;
}
.hint { color: var(--c-texte-doux); font-size: 13px; margin-bottom: var(--space-3); }
.embed-buttons {
  display: flex; flex-direction: column;
  gap: var(--space-2);
}
.embed-row {
  display: flex; align-items: center; gap: var(--space-3);
  flex-wrap: wrap;
}
.embed-status {
  font-size: 13px;
  color: var(--c-texte-doux);
  font-family: 'Inter', monospace;
  white-space: pre-line;
  flex: 1;
  min-width: 200px;
}

.logs-head {
  display: flex; justify-content: space-between; align-items: center;
  margin-bottom: var(--space-3);
  flex-wrap: wrap; gap: var(--space-3);
}
.logs-head h2 {
  font-family: var(--font-display);
  font-size: 28px;
  color: var(--c-primaire-profond);
}
.tabs { display: flex; gap: var(--space-2); flex-wrap: wrap; }
.tab {
  background: var(--c-fond-chaud);
  border: 1px solid var(--c-gris-clair);
  border-radius: var(--r-pill);
  padding: 6px 14px;
  font-family: inherit;
  font-size: 13px;
  font-weight: 600;
  color: var(--c-primaire-profond);
  cursor: pointer;
}
.tab.active {
  background: var(--c-primaire);
  color: var(--c-fond);
  border-color: var(--c-primaire);
}

.loading, .empty { text-align: center; padding: var(--space-6); color: var(--c-texte-doux); }

.logs-list { display: flex; flex-direction: column; gap: var(--space-2); }
.log-row {
  background: var(--c-surface);
  border-radius: var(--r-md);
  padding: var(--space-3);
  box-shadow: var(--ombre-douce);
  border-left: 3px solid #2D5A3D;
}
.log-row[data-passed="false"] { border-left-color: #C04A3A; }

.log-head {
  display: flex; align-items: center; gap: 10px;
  flex-wrap: wrap;
  font-size: 12px;
  margin-bottom: var(--space-2);
}
.log-user { font-weight: 700; color: var(--c-primaire-profond); }
.log-date, .log-meta { color: var(--c-texte-doux); }
.badge {
  padding: 2px 8px;
  border-radius: var(--r-pill);
  font-size: 11px;
  font-weight: 700;
  letter-spacing: 0.05em;
}
.badge.ok { background: rgba(45, 90, 61, 0.15); color: #2D5A3D; }
.badge.failed { background: rgba(192, 74, 58, 0.15); color: #C04A3A; }

.log-q, .log-a, .log-notes {
  font-size: 14px;
  margin-bottom: 4px;
  line-height: 1.5;
}
.log-q { color: var(--c-primaire-profond); }
.log-a { color: var(--c-texte); }
.log-notes {
  background: rgba(192, 74, 58, 0.08);
  padding: 6px 10px;
  border-radius: var(--r-sm);
  font-size: 13px;
  color: #C04A3A;
}
.log-resources {
  font-size: 11px;
  color: var(--c-texte-doux);
  font-style: italic;
  margin-top: var(--space-2);
}
</style>
