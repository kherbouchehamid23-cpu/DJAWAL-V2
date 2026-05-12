<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { supabase } from '@/lib/supabase'

interface Message {
  id: string
  name: string
  email: string
  subject: string
  message: string
  status: 'new' | 'read' | 'replied' | 'archived'
  created_at: string
}

const messages = ref<Message[]>([])
const loading = ref(true)
const filter = ref<'all' | 'new' | 'read' | 'replied' | 'archived'>('new')
const processing = ref<string | null>(null)

const filtered = computed(() => {
  if (filter.value === 'all') return messages.value
  return messages.value.filter(m => m.status === filter.value)
})

const counts = computed(() => {
  const c: Record<string, number> = { all: messages.value.length, new: 0, read: 0, replied: 0, archived: 0 }
  for (const m of messages.value) c[m.status]++
  return c
})

async function load() {
  loading.value = true
  const { data } = await supabase
    .from('contact_messages')
    .select('*')
    .order('created_at', { ascending: false })
  messages.value = (data as Message[]) || []
  loading.value = false
}

onMounted(load)

async function changeStatus(m: Message, newStatus: Message['status']) {
  processing.value = m.id
  const { error } = await supabase
    .from('contact_messages')
    .update({ status: newStatus })
    .eq('id', m.id)
  processing.value = null
  if (error) { alert('Erreur : ' + error.message); return }
  m.status = newStatus
}

function fmtDate(iso: string) {
  return new Date(iso).toLocaleString('fr-FR', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' })
}
function statusColor(s: string) {
  return { new: '#C04A3A', read: '#D4A04F', replied: '#2D5A3D', archived: '#8B8680' }[s] || '#666'
}
function statusLabel(s: string) {
  return { new: 'Nouveau', read: 'Lu', replied: 'Répondu', archived: 'Archivé' }[s] || s
}
</script>

<template>
  <div class="contact-admin djawal-container djawal-section">
    <div class="back-link">
      <router-link to="/admin">← Retour admin</router-link>
    </div>

    <header class="page-header">
      <div class="section-eyebrow">Administration</div>
      <h1>📬 Messages de contact</h1>
      <p class="lead">{{ messages.length }} message{{ messages.length > 1 ? 's' : '' }} reçus via le formulaire de contact public.</p>
    </header>

    <div class="tabs">
      <button
        v-for="t in ['new', 'read', 'replied', 'archived', 'all']"
        :key="t"
        class="tab"
        :class="{ active: filter === t }"
        @click="filter = t as any"
      >
        {{ statusLabel(t) || (t === 'all' ? 'Tous' : t) }} <span class="count">{{ counts[t] }}</span>
      </button>
    </div>

    <div v-if="loading" class="loading">Chargement…</div>

    <div v-else-if="filtered.length === 0" class="empty">
      Aucun message dans cette catégorie.
    </div>

    <div v-else class="messages-list">
      <article v-for="m in filtered" :key="m.id" class="msg-card">
        <header class="msg-head">
          <div>
            <strong>{{ m.name }}</strong>
            <span class="msg-email">&lt;{{ m.email }}&gt;</span>
          </div>
          <div class="msg-meta">
            <span class="badge" :style="`background: ${statusColor(m.status)}`">
              {{ statusLabel(m.status) }}
            </span>
            <span class="date">{{ fmtDate(m.created_at) }}</span>
          </div>
        </header>
        <h3>{{ m.subject }}</h3>
        <p class="msg-body">{{ m.message }}</p>
        <div class="msg-actions">
          <a :href="`mailto:${m.email}?subject=Re: ${encodeURIComponent(m.subject)}`" class="action-btn primary">
            ✉️ Répondre par mail
          </a>
          <button v-if="m.status === 'new'" class="action-btn" :disabled="processing === m.id" @click="changeStatus(m, 'read')">Marquer lu</button>
          <button v-if="m.status !== 'replied'" class="action-btn" :disabled="processing === m.id" @click="changeStatus(m, 'replied')">Marquer répondu</button>
          <button v-if="m.status !== 'archived'" class="action-btn ghost" :disabled="processing === m.id" @click="changeStatus(m, 'archived')">Archiver</button>
        </div>
      </article>
    </div>
  </div>
</template>

<style scoped>
.contact-admin { background: var(--c-fond); min-height: 100vh; }
.back-link { margin-bottom: var(--space-3); }
.back-link a { color: var(--c-primaire); text-decoration: none; font-weight: 600; font-size: 14px; }
.back-link a:hover { text-decoration: underline; }

.section-eyebrow {
  color: var(--c-accent-fort); font-size: 13px; font-weight: 700;
  letter-spacing: 0.2em; text-transform: uppercase; margin-bottom: var(--space-2);
}
.page-header { margin-bottom: var(--space-4); }
.page-header h1 { font-size: clamp(28px, 3.5vw, 40px); margin-bottom: 4px; }
.lead { color: var(--c-texte-doux); }

.tabs {
  display: flex; gap: var(--space-2);
  border-bottom: 1px solid var(--c-gris-clair);
  margin-bottom: var(--space-4); flex-wrap: wrap;
}
.tab {
  background: none; border: none; border-bottom: 3px solid transparent;
  padding: 10px 16px; font-family: inherit; font-size: 14px; font-weight: 600;
  color: var(--c-texte-doux); cursor: pointer;
  display: inline-flex; align-items: center; gap: 8px;
}
.tab.active { color: var(--c-primaire); border-bottom-color: var(--c-accent); }
.count {
  background: var(--c-fond-chaud); padding: 2px 8px; border-radius: var(--r-pill);
  font-size: 11px; font-weight: 700;
}

.loading, .empty { text-align: center; padding: var(--space-7); color: var(--c-texte-doux); }

.messages-list { display: flex; flex-direction: column; gap: var(--space-3); }
.msg-card {
  background: var(--c-surface);
  border-radius: var(--r-lg);
  padding: var(--space-4);
  box-shadow: var(--ombre-douce);
  border-left: 3px solid var(--c-accent);
}
.msg-head {
  display: flex; justify-content: space-between; align-items: flex-start;
  margin-bottom: var(--space-2); flex-wrap: wrap; gap: 8px;
}
.msg-head strong { color: var(--c-primaire-profond); }
.msg-email { color: var(--c-texte-doux); font-size: 13px; margin-left: 4px; }
.msg-meta { display: flex; align-items: center; gap: 10px; }
.badge {
  color: white; padding: 3px 10px; border-radius: var(--r-pill);
  font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em;
}
.date { font-size: 12px; color: var(--c-texte-doux); }

.msg-card h3 {
  font-family: var(--font-display); font-size: 18px;
  color: var(--c-primaire-profond); margin-bottom: var(--space-2);
}
.msg-body {
  background: var(--c-fond-chaud);
  padding: var(--space-3);
  border-radius: var(--r-sm);
  font-size: 14px; line-height: 1.6; color: var(--c-texte);
  white-space: pre-wrap; margin-bottom: var(--space-3);
}

.msg-actions { display: flex; gap: 8px; flex-wrap: wrap; }
.action-btn {
  background: var(--c-fond-chaud); border: 1px solid var(--c-gris-clair);
  border-radius: var(--r-pill); padding: 6px 14px;
  font-family: inherit; font-size: 13px; font-weight: 600;
  color: var(--c-primaire); text-decoration: none; cursor: pointer;
  transition: var(--t-base);
}
.action-btn.primary { background: var(--c-primaire); color: var(--c-fond); border-color: var(--c-primaire); }
.action-btn.ghost { background: transparent; color: var(--c-texte-doux); }
.action-btn:hover:not(:disabled) { border-color: var(--c-accent); }
.action-btn:disabled { opacity: 0.5; cursor: not-allowed; }
</style>
