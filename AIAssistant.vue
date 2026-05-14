<script setup lang="ts">
import { ref, nextTick } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'
import { useRouter } from 'vue-router'

const auth = useAuthStore()
const router = useRouter()

interface Message {
  role: 'user' | 'assistant'
  text: string
  resources?: any[]
  destinations?: any[]
  trips?: any[]
  loading?: boolean
}

const isOpen = ref(false)
const messages = ref<Message[]>([
  {
    role: 'assistant',
    text: 'Salam ! Je suis Fennec, votre guide intelligent. Posez-moi une question sur l\'Algérie, suggérez-moi une destination, ou demandez-moi de composer un voyage. Je m\'appuie sur notre catalogue local.'
  }
])
const input = ref('')
const sending = ref(false)
const messagesEl = ref<HTMLDivElement | null>(null)

async function scrollToBottom() {
  await nextTick()
  if (messagesEl.value) {
    messagesEl.value.scrollTop = messagesEl.value.scrollHeight
  }
}

async function send() {
  const question = input.value.trim()
  if (!question || sending.value) return

  messages.value.push({ role: 'user', text: question })
  input.value = ''
  sending.value = true

  // Message assistant en cours
  messages.value.push({ role: 'assistant', text: '', loading: true })
  await scrollToBottom()

  try {
    const { data, error } = await supabase.functions.invoke('ai-assistant', {
      body: {
        question,
        user_id: auth.user?.id || null
      }
    })

    if (error) throw error

    // Remplacer le message loading
    const idx = messages.value.length - 1
    messages.value[idx] = {
      role: 'assistant',
      text: data.answer || 'Réponse vide.',
      resources: data.resources,
      destinations: data.destinations,
      trips: data.trips
    }
  } catch (e: any) {
    const idx = messages.value.length - 1
    messages.value[idx] = {
      role: 'assistant',
      text: `Désolé, j'ai rencontré une erreur : ${e.message}. L'assistant pourrait ne pas être encore activé (clé API Gemini manquante côté Supabase).`
    }
  } finally {
    sending.value = false
    await scrollToBottom()
  }
}

function quickPrompt(p: string) {
  input.value = p
  send()
}

function goToTrip(id: string) {
  isOpen.value = false
  router.push(`/voyages/${id}`)
}

function goToDestination(id: string) {
  isOpen.value = false
  router.push(`/destination/${id}`)
}
</script>

<template>
  <!-- Bouton flottant -->
  <button
    v-if="!isOpen"
    class="ai-fab"
    @click="isOpen = true"
    title="Demander à Fennec"
  >
    <span class="fab-icon" aria-hidden="true">
      <svg viewBox="0 0 64 64" fill="currentColor">
        <path d="M14 28 C 10 16, 14 4, 20 6 C 22 14, 24 22, 26 28 Z"/>
        <path d="M50 28 C 54 16, 50 4, 44 6 C 42 14, 40 22, 38 28 Z"/>
        <ellipse cx="32" cy="38" rx="13" ry="12"/>
        <circle cx="26" cy="36" r="1.6" fill="#0A1F2E"/>
        <circle cx="38" cy="36" r="1.6" fill="#0A1F2E"/>
        <circle cx="32" cy="44" r="1.4" fill="#0A1F2E"/>
      </svg>
    </span>
    <span class="fab-label">Demander à Fennec</span>
  </button>

  <!-- Drawer chat -->
  <transition name="slide">
    <div v-if="isOpen" class="ai-drawer">
      <header class="ai-head">
        <div class="ai-title">
          <span class="ai-emoji" aria-hidden="true">
            <svg viewBox="0 0 64 64" fill="currentColor">
              <path d="M14 28 C 10 16, 14 4, 20 6 C 22 14, 24 22, 26 28 Z"/>
              <path d="M50 28 C 54 16, 50 4, 44 6 C 42 14, 40 22, 38 28 Z"/>
              <ellipse cx="32" cy="38" rx="13" ry="12"/>
              <circle cx="26" cy="36" r="1.6" fill="#0A1F2E"/>
              <circle cx="38" cy="36" r="1.6" fill="#0A1F2E"/>
              <circle cx="32" cy="44" r="1.4" fill="#0A1F2E"/>
            </svg>
          </span>
          <div>
            <strong>Fennec</strong>
            <small>Votre guide intelligent · catalogue Djawal</small>
          </div>
        </div>
        <button class="close-btn" @click="isOpen = false">✕</button>
      </header>

      <!-- Messages -->
      <div ref="messagesEl" class="ai-messages">
        <article
          v-for="(m, i) in messages"
          :key="i"
          class="msg"
          :data-role="m.role"
        >
          <div class="msg-bubble">
            <div v-if="m.loading" class="loading-dots">
              <span></span><span></span><span></span>
            </div>
            <div v-else class="msg-text">{{ m.text }}</div>

            <!-- Cards des ressources trouvées -->
            <div v-if="m.trips && m.trips.length > 0" class="rich-cards">
              <div class="rich-label">🗺️ Voyages liés :</div>
              <button
                v-for="t in m.trips"
                :key="t.id"
                class="rich-card"
                @click="goToTrip(t.id)"
              >
                <strong>{{ t.title }}</strong>
                <span>{{ t.destination_name }} · {{ t.duration_days }}j</span>
              </button>
            </div>

            <div v-if="m.destinations && m.destinations.length > 0" class="rich-cards">
              <div class="rich-label">📍 Destinations :</div>
              <button
                v-for="d in m.destinations"
                :key="d.id"
                class="rich-card"
                @click="goToDestination(d.id)"
              >
                <strong>{{ d.name }}</strong>
                <span>{{ d.wilaya }} · {{ d.cultural_theme }}</span>
              </button>
            </div>
          </div>
        </article>
      </div>

      <!-- Suggestions rapides (si seul message initial) -->
      <div v-if="messages.length === 1" class="quick-prompts">
        <button @click="quickPrompt('Quel voyage me recommandez-vous pour découvrir le Sahara ?')">
          🏜️ Découvrir le Sahara
        </button>
        <button @click="quickPrompt('Que voir absolument à Alger en 2 jours ?')">
          🏛️ 2 jours à Alger
        </button>
        <button @click="quickPrompt('Un voyage culturel et gastronomique en Kabylie')">
          🍴 Culture & cuisine
        </button>
      </div>

      <!-- Input -->
      <form @submit.prevent="send" class="ai-input-row">
        <input
          v-model="input"
          type="text"
          placeholder="Posez votre question…"
          :disabled="sending"
          maxlength="500"
        />
        <button type="submit" :disabled="sending || !input.trim()">
          {{ sending ? '⏳' : '➤' }}
        </button>
      </form>

      <div class="ai-footer">
        <router-link to="/composer" class="footer-link">
          → Composer un voyage sur mesure
        </router-link>
      </div>
    </div>
  </transition>
</template>

<style scoped>
.ai-fab {
  position: fixed;
  bottom: 24px; right: 24px;
  z-index: 9999;
  background: linear-gradient(135deg, var(--c-primaire), var(--c-primaire-profond));
  color: var(--c-fond);
  border: none;
  padding: 14px 20px;
  border-radius: var(--r-pill);
  font-family: inherit;
  font-size: 14px;
  font-weight: 700;
  cursor: pointer;
  box-shadow: 0 8px 24px rgba(10, 31, 46, 0.25);
  display: inline-flex; align-items: center; gap: 8px;
  transition: var(--t-base);
}
.ai-fab:hover {
  transform: translateY(-3px);
  box-shadow: 0 12px 32px rgba(10, 31, 46, 0.35);
}
.fab-icon { font-size: 18px; display: inline-flex; align-items: center; justify-content: center; }
.fab-icon svg { width: 22px; height: 22px; }

.ai-drawer {
  position: fixed;
  bottom: 24px; right: 24px;
  z-index: 9999;
  width: 380px;
  max-width: calc(100vw - 48px);
  height: 600px;
  max-height: calc(100vh - 48px);
  background: var(--c-surface);
  border-radius: var(--r-lg);
  box-shadow: 0 24px 64px rgba(10, 31, 46, 0.35);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.ai-head {
  background: linear-gradient(135deg, var(--c-primaire), var(--c-primaire-profond));
  color: var(--c-fond);
  padding: var(--space-3) var(--space-4);
  display: flex; justify-content: space-between; align-items: center;
}
.ai-title { display: flex; align-items: center; gap: 10px; }
.ai-emoji { font-size: 24px; display: inline-flex; align-items: center; justify-content: center; }
.ai-emoji svg { width: 28px; height: 28px; }
.ai-title strong { display: block; font-size: 15px; }
.ai-title small { font-size: 11px; opacity: 0.8; }
.close-btn {
  background: rgba(255,255,255,0.15);
  border: none;
  color: white;
  width: 32px; height: 32px;
  border-radius: 50%;
  cursor: pointer;
  font-size: 14px;
  transition: var(--t-base);
}
.close-btn:hover { background: rgba(255,255,255,0.3); }

.ai-messages {
  flex: 1;
  overflow-y: auto;
  padding: var(--space-3);
  display: flex;
  flex-direction: column;
  gap: var(--space-3);
  background: var(--c-fond);
}
.ai-messages::-webkit-scrollbar { width: 6px; }
.ai-messages::-webkit-scrollbar-thumb {
  background: var(--c-gris-clair);
  border-radius: 3px;
}

.msg { display: flex; }
.msg[data-role="user"] { justify-content: flex-end; }
.msg-bubble {
  max-width: 85%;
  padding: 10px 14px;
  border-radius: var(--r-md);
  font-size: 14px;
  line-height: 1.5;
}
.msg[data-role="user"] .msg-bubble {
  background: var(--c-primaire);
  color: var(--c-fond);
  border-bottom-right-radius: 4px;
}
.msg[data-role="assistant"] .msg-bubble {
  background: var(--c-surface);
  color: var(--c-texte);
  border: 1px solid var(--c-fond-chaud);
  border-bottom-left-radius: 4px;
}
.msg-text { white-space: pre-wrap; }

.loading-dots { display: flex; gap: 4px; padding: 4px 0; }
.loading-dots span {
  width: 6px; height: 6px;
  border-radius: 50%;
  background: var(--c-texte-doux);
  animation: dot-bounce 1.2s infinite ease-in-out;
}
.loading-dots span:nth-child(2) { animation-delay: 0.15s; }
.loading-dots span:nth-child(3) { animation-delay: 0.3s; }
@keyframes dot-bounce {
  0%, 60%, 100% { transform: translateY(0); opacity: 0.5; }
  30% { transform: translateY(-4px); opacity: 1; }
}

.rich-cards {
  margin-top: var(--space-2);
  padding-top: var(--space-2);
  border-top: 1px solid var(--c-fond-chaud);
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.rich-label {
  font-size: 11px;
  color: var(--c-texte-doux);
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 2px;
}
.rich-card {
  display: flex;
  flex-direction: column;
  gap: 3px;
  width: 100%;
  background: var(--c-fond-chaud);
  border: 1px solid var(--c-gris-clair);
  border-radius: var(--r-sm);
  padding: 10px 12px;
  cursor: pointer;
  text-align: left;
  font-family: inherit;
  transition: var(--t-base);
}
.rich-card:hover {
  background: var(--c-fond);
  border-color: var(--c-accent);
}
.rich-card strong {
  display: block;
  color: var(--c-primaire-profond);
  font-size: 13px;
  line-height: 1.3;
}
.rich-card span {
  display: block;
  color: var(--c-texte-doux);
  font-size: 11px;
  line-height: 1.3;
}

.quick-prompts {
  padding: var(--space-2) var(--space-3);
  border-top: 1px solid var(--c-fond-chaud);
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  background: var(--c-surface);
}
.quick-prompts button {
  background: var(--c-fond-chaud);
  border: 1px solid var(--c-gris-clair);
  border-radius: var(--r-pill);
  padding: 6px 12px;
  font-family: inherit;
  font-size: 12px;
  font-weight: 600;
  color: var(--c-primaire-profond);
  cursor: pointer;
  transition: var(--t-base);
}
.quick-prompts button:hover { border-color: var(--c-accent); }

.ai-input-row {
  display: flex;
  gap: 6px;
  padding: var(--space-3);
  border-top: 1px solid var(--c-fond-chaud);
  background: var(--c-surface);
}
.ai-input-row input {
  flex: 1;
  padding: 10px 14px;
  border: 1px solid var(--c-gris-clair);
  border-radius: var(--r-pill);
  font-family: inherit;
  font-size: 14px;
  outline: none;
  transition: var(--t-base);
}
.ai-input-row input:focus { border-color: var(--c-accent); }
.ai-input-row button {
  background: var(--c-primaire);
  color: var(--c-fond);
  border: none;
  width: 40px;
  border-radius: 50%;
  cursor: pointer;
  font-size: 16px;
  transition: var(--t-base);
}
.ai-input-row button:hover:not(:disabled) {
  background: var(--c-primaire-profond);
  transform: scale(1.05);
}
.ai-input-row button:disabled { opacity: 0.5; cursor: not-allowed; }

.ai-footer {
  padding: 8px var(--space-3);
  background: var(--c-fond-chaud);
  text-align: center;
}
.footer-link {
  color: var(--c-accent-fort);
  text-decoration: none;
  font-size: 12px;
  font-weight: 700;
}
.footer-link:hover { text-decoration: underline; }

.slide-enter-active, .slide-leave-active { transition: all 0.3s ease; }
.slide-enter-from, .slide-leave-to { opacity: 0; transform: translateY(40px) scale(0.95); }

@media (max-width: 500px) {
  .ai-drawer {
    width: calc(100vw - 24px);
    height: calc(100vh - 100px);
    right: 12px; bottom: 12px;
  }
  .ai-fab {
    right: 12px; bottom: 12px;
  }
  .fab-label { display: none; }
  .ai-fab { padding: 14px; }
}
</style>
