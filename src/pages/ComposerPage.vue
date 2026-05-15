<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'
import { useSEO } from '@/composables/useSEO'
import djawalMonogram from '@/assets/branding/djawal-monogram.png'

useSEO({ title: 'Djawal IA — Composer votre voyage en Algérie' })

const auth = useAuthStore()
const route = useRoute()
const router = useRouter()

interface Question {
  key: string
  question: string
  suggestions: string[]
}
interface AIResponse {
  mode?: 'too-vague' | 'needs-clarification' | undefined
  answer?: string
  questions?: Question[]
  redirect_to?: string
  resources?: any[]
  destinations?: any[]
  trips?: any[]
  detected?: Record<string, any>
}

const aiInput = ref('')
const generating = ref(false)
const error = ref('')
const response = ref<AIResponse | null>(null)

// Pile des réponses de l'utilisateur aux questions de clarification
// + question originale qu'on accumule pour reformer le prompt complet
const baseQuestion = ref('')
const clarifications = ref<Record<string, string>>({})

onMounted(async () => {
  const q = route.query.q
  if (typeof q === 'string' && q.trim()) {
    aiInput.value = q.trim()
    await submitInitial()
  }
})

// === Étape 1 : soumission initiale (analyse + RAG ou questions) ===
async function submitInitial() {
  const q = aiInput.value.trim()
  if (!q) return
  baseQuestion.value = q
  clarifications.value = {}
  error.value = ''
  generating.value = true
  response.value = null
  try {
    const { data, error: fnErr } = await supabase.functions.invoke('ai-assistant', {
      body: { question: q, user_id: auth.user?.id || null }
    })
    if (fnErr) throw fnErr
    response.value = data
  } catch (e: any) {
    error.value = e.message || 'Erreur lors de la génération.'
  } finally {
    generating.value = false
  }
}

// === Étape 2 : l'utilisateur clique sur une suggestion pour une question ===
function pickSuggestion(key: string, value: string) {
  clarifications.value[key] = value
}

// === Étape 3 : envoyer le prompt enrichi pour génération finale ===
async function submitEnriched() {
  // Construire prompt complet = base + précisions
  const parts: string[] = [baseQuestion.value]
  for (const [, v] of Object.entries(clarifications.value)) {
    if (v) parts.push(v)
  }
  const fullQuestion = parts.join('. ')
  error.value = ''
  generating.value = true
  const previousResponse = response.value
  response.value = null
  try {
    const { data, error: fnErr } = await supabase.functions.invoke('ai-assistant', {
      body: {
        question: fullQuestion,
        user_id: auth.user?.id || null,
        skip_analysis: true // on contourne l'analyse car on a déjà tout
      }
    })
    if (fnErr) throw fnErr
    response.value = data
  } catch (e: any) {
    error.value = e.message || 'Erreur lors de la génération.'
    response.value = previousResponse
  } finally {
    generating.value = false
  }
}

function resetAll() {
  aiInput.value = ''
  baseQuestion.value = ''
  clarifications.value = {}
  response.value = null
  error.value = ''
}

function goToStructuredForm() {
  router.push('/composer/formulaire')
}
</script>

<template>
  <div class="composer-page">
    <header class="composer-hero">
      <div class="djawal-container">
        <div class="composer-eyebrow">
          <img :src="djawalMonogram" alt="" class="composer-logo" />
          <span>Composer avec Djawal IA</span>
        </div>
        <h1>Votre voyage, façonné par <em>vos envies</em></h1>
        <p class="composer-lead">
          Racontez-moi simplement ce qui vous tente. Si je manque d'informations,
          je vous poserai quelques questions pour composer le voyage parfait.
        </p>
      </div>
    </header>

    <main class="composer-main">
      <div class="djawal-container">
        <!-- Zone de saisie principale -->
        <form v-if="!response || (!response.mode && !response.answer)" class="composer-input-wrap" @submit.prevent="submitInitial">
          <div class="composer-input-row">
            <textarea
              v-model="aiInput"
              class="composer-input"
              rows="3"
              placeholder="Exemple : Je veux partir en famille avec 2 enfants une semaine dans le Sahara en mars, budget 100 000 DA par personne…"
              :disabled="generating"
            />
          </div>
          <button class="composer-submit" type="submit" :disabled="!aiInput.trim() || generating">
            <span v-if="!generating">Composer mon voyage →</span>
            <span v-else>Djawal IA réfléchit…</span>
          </button>
        </form>

        <!-- Erreur -->
        <div v-if="error" class="composer-error">⚠️ {{ error }}</div>

        <!-- MODE 1 : Demande trop vague → redirection -->
        <div v-if="response?.mode === 'too-vague'" class="composer-vague">
          <div class="vague-icon">💭</div>
          <h2>Votre demande est très large</h2>
          <p>{{ response.answer }}</p>
          <button class="composer-submit" type="button" @click="goToStructuredForm">
            Utiliser le composeur structuré →
          </button>
          <button class="composer-link" type="button" @click="resetAll">Reformuler ma demande</button>
        </div>

        <!-- MODE 2 : Critères manquants → questions ciblées -->
        <div v-if="response?.mode === 'needs-clarification'" class="composer-clarify">
          <div class="clarify-intro">
            <img :src="djawalMonogram" alt="" class="clarify-avatar" />
            <p>{{ response.answer }}</p>
          </div>

          <div class="clarify-recap" v-if="response.detected">
            <strong>Ce que j'ai compris :</strong>
            <ul>
              <li v-if="response.detected.dates"><strong>Quand :</strong> {{ response.detected.dates }}</li>
              <li v-if="response.detected.group"><strong>Groupe :</strong> {{ response.detected.group }}</li>
              <li v-if="response.detected.interests && response.detected.interests.length">
                <strong>Centres d'intérêt :</strong> {{ response.detected.interests.join(', ') }}
              </li>
              <li v-if="response.detected.budget"><strong>Budget :</strong> {{ response.detected.budget }}</li>
            </ul>
          </div>

          <div v-for="q in response.questions" :key="q.key" class="clarify-question">
            <h3>{{ q.question }}</h3>
            <div class="clarify-suggestions">
              <button
                v-for="s in q.suggestions"
                :key="s"
                type="button"
                class="clarify-chip"
                :class="{ active: clarifications[q.key] === s }"
                @click="pickSuggestion(q.key, s)"
              >{{ s }}</button>
            </div>
            <input
              v-model="clarifications[q.key]"
              type="text"
              class="clarify-custom"
              placeholder="Ou écrivez votre réponse ici…"
            />
          </div>

          <div class="clarify-actions">
            <button
              class="composer-submit"
              type="button"
              :disabled="generating"
              @click="submitEnriched"
            >
              <span v-if="!generating">Composer mon voyage avec ces précisions →</span>
              <span v-else>Djawal IA compose…</span>
            </button>
            <button class="composer-link" type="button" @click="resetAll">Recommencer</button>
          </div>
        </div>

        <!-- MODE 3 : Réponse complète de l'IA -->
        <div v-if="response && response.answer && !response.mode" class="composer-answer">
          <div class="answer-header">
            <img :src="djawalMonogram" alt="" class="answer-avatar" />
            <strong>Djawal IA</strong>
          </div>
          <div class="answer-text" v-html="(response.answer).replace(/\n/g, '<br>')"></div>

          <!-- Ressources -->
          <section v-if="response.destinations?.length" class="answer-section">
            <h3>Destinations suggérées</h3>
            <div class="answer-cards">
              <button v-for="d in response.destinations" :key="d.id" class="answer-card" type="button" @click="router.push('/destination/' + d.id)">
                <strong>{{ d.name }}</strong>
                <small>{{ d.wilaya }} · {{ d.cultural_theme }}</small>
                <p>{{ d.description?.slice(0, 100) }}…</p>
              </button>
            </div>
          </section>

          <section v-if="response.trips?.length" class="answer-section">
            <h3>Voyages déjà composés</h3>
            <div class="answer-cards">
              <button v-for="t in response.trips" :key="t.id" class="answer-card" type="button" @click="router.push('/voyages/' + t.id)">
                <strong>{{ t.title }}</strong>
                <small>{{ t.duration_days }} j · {{ Math.round((t.price_da || 0) / 1000) }}K DA</small>
                <p>{{ t.description?.slice(0, 100) }}…</p>
              </button>
            </div>
          </section>

          <div class="answer-actions">
            <button class="composer-link" type="button" @click="resetAll">Nouvelle question</button>
            <router-link to="/voyages" class="composer-link">Voir tous les voyages →</router-link>
          </div>
        </div>
      </div>
    </main>
  </div>
</template>

<style scoped>
.composer-page {
  background: linear-gradient(180deg, #0F2419 0%, #1A3A2A 100%);
  min-height: 100vh;
  color: #FAF7F2;
  font-family: 'Inter', sans-serif;
}
.djawal-container { max-width: 900px; margin: 0 auto; padding: 0 32px; }

.composer-hero {
  padding: 100px 0 60px;
  text-align: center;
  position: relative;
}
.composer-hero::before {
  content: '';
  position: absolute; inset: 0;
  background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='200' height='200'><g fill='none' stroke='%23D4A844' stroke-width='0.5' opacity='0.05'><path d='M100 30 L112 70 L152 70 L120 95 L132 135 L100 110 L68 135 L80 95 L48 70 L88 70 Z'/></g></svg>");
  background-size: 200px 200px;
  pointer-events: none;
}
.composer-hero > * { position: relative; }

.composer-eyebrow {
  display: inline-flex; align-items: center; gap: 10px;
  padding: 8px 18px;
  background: rgba(212, 168, 68, 0.18);
  border: 1px solid rgba(212, 168, 68, 0.4);
  border-radius: 999px;
  font-size: 11px; letter-spacing: 0.18em;
  color: #E8B96B;
  margin-bottom: 24px;
  text-transform: uppercase;
}
.composer-logo {
  width: 22px; height: 22px;
  border-radius: 5px;
  object-fit: contain;
}
.composer-hero h1 {
  font-family: 'Cormorant Garamond', serif;
  font-size: clamp(32px, 5vw, 52px);
  font-weight: 500;
  line-height: 1.05;
  letter-spacing: -0.01em;
  color: #FAF7F2;
  margin-bottom: 16px;
}
.composer-hero h1 em { font-style: italic; color: #E8B96B; }
.composer-lead {
  font-family: 'Cormorant Garamond', serif;
  font-style: italic;
  font-size: 18px;
  color: rgba(250, 247, 242, 0.78);
  max-width: 600px;
  margin: 0 auto;
  line-height: 1.55;
}

.composer-main { padding-bottom: 100px; }

.composer-input-wrap {
  background: rgba(31, 74, 54, 0.6);
  backdrop-filter: blur(8px);
  border: 1px solid rgba(212, 168, 68, 0.3);
  border-radius: 20px;
  padding: 22px;
  margin-bottom: 30px;
}
.composer-input {
  width: 100%;
  background: rgba(15, 36, 25, 0.4);
  border: 1px solid rgba(212, 168, 68, 0.2);
  border-radius: 14px;
  color: #FAF7F2;
  padding: 16px 18px;
  font-size: 15px;
  font-family: inherit;
  resize: vertical;
  min-height: 90px;
  outline: none;
  transition: border-color 0.2s;
}
.composer-input:focus { border-color: #D4A844; }
.composer-input::placeholder { color: rgba(250, 247, 242, 0.45); font-style: italic; }
.composer-submit {
  margin-top: 14px;
  background: #D4A844;
  color: #0F2419;
  border: none;
  padding: 14px 28px;
  border-radius: 999px;
  font-weight: 600; font-size: 14px;
  cursor: pointer;
  font-family: inherit;
  transition: all 0.2s;
  box-shadow: 0 8px 20px rgba(212, 168, 68, 0.3);
}
.composer-submit:hover:not(:disabled) { background: #E8B96B; transform: translateY(-1px); }
.composer-submit:disabled { opacity: 0.55; cursor: not-allowed; }
.composer-link {
  background: transparent;
  border: none;
  color: #E8B96B;
  font-size: 13px;
  cursor: pointer;
  text-decoration: underline;
  margin-top: 12px;
  font-family: inherit;
  font-style: italic;
}

.composer-error {
  background: rgba(220, 53, 69, 0.15);
  border: 1px solid rgba(220, 53, 69, 0.4);
  color: #FFB3B3;
  padding: 12px 18px;
  border-radius: 12px;
  margin-bottom: 20px;
}

.composer-vague {
  text-align: center;
  padding: 50px 30px;
  background: rgba(31, 74, 54, 0.4);
  border: 1px solid rgba(212, 168, 68, 0.3);
  border-radius: 20px;
}
.vague-icon { font-size: 48px; margin-bottom: 14px; }
.composer-vague h2 {
  font-family: 'Cormorant Garamond', serif;
  font-size: 28px; font-weight: 500;
  color: #FAF7F2; margin-bottom: 12px;
}
.composer-vague p {
  color: rgba(250, 247, 242, 0.78);
  font-size: 15px; line-height: 1.55;
  margin-bottom: 24px;
  max-width: 480px; margin-left: auto; margin-right: auto;
}

.composer-clarify {
  background: rgba(31, 74, 54, 0.45);
  border: 1px solid rgba(212, 168, 68, 0.3);
  border-radius: 20px;
  padding: 30px;
}
.clarify-intro {
  display: flex; gap: 14px; align-items: flex-start;
  padding-bottom: 18px;
  border-bottom: 1px solid rgba(212, 168, 68, 0.2);
  margin-bottom: 22px;
}
.clarify-avatar {
  width: 42px; height: 42px;
  border-radius: 50%;
  background: #FAF7F2;
  padding: 4px;
  flex-shrink: 0;
}
.clarify-intro p {
  font-family: 'Cormorant Garamond', serif;
  font-style: italic; font-size: 17px;
  color: #FAF7F2; line-height: 1.5; margin: 0;
}
.clarify-recap {
  background: rgba(212, 168, 68, 0.1);
  border-left: 3px solid #D4A844;
  padding: 12px 16px;
  border-radius: 8px;
  margin-bottom: 24px;
  font-size: 13px;
}
.clarify-recap strong { color: #E8B96B; }
.clarify-recap ul { list-style: none; padding: 0; margin: 8px 0 0; }
.clarify-recap li { padding: 3px 0; color: rgba(250, 247, 242, 0.85); }
.clarify-recap li strong { color: #D4A844; }

.clarify-question {
  margin-bottom: 22px;
  padding-bottom: 18px;
  border-bottom: 1px dashed rgba(212, 168, 68, 0.15);
}
.clarify-question:last-of-type { border-bottom: none; padding-bottom: 0; }
.clarify-question h3 {
  font-family: 'Cormorant Garamond', serif;
  font-size: 19px; font-weight: 500;
  color: #FAF7F2; margin-bottom: 12px;
}
.clarify-suggestions {
  display: flex; gap: 8px; flex-wrap: wrap;
  margin-bottom: 10px;
}
.clarify-chip {
  background: rgba(250, 247, 242, 0.08);
  border: 1px solid rgba(212, 168, 68, 0.35);
  color: rgba(250, 247, 242, 0.85);
  padding: 8px 14px;
  border-radius: 999px;
  font-size: 13px;
  cursor: pointer;
  font-family: inherit;
  transition: all 0.2s;
}
.clarify-chip:hover { background: rgba(212, 168, 68, 0.18); border-color: #D4A844; color: #FAF7F2; }
.clarify-chip.active { background: #D4A844; border-color: #D4A844; color: #0F2419; font-weight: 600; }
.clarify-custom {
  width: 100%;
  background: rgba(15, 36, 25, 0.4);
  border: 1px solid rgba(212, 168, 68, 0.2);
  border-radius: 10px;
  color: #FAF7F2;
  padding: 10px 14px;
  font-size: 13px;
  font-family: inherit;
  outline: none;
  margin-top: 8px;
}
.clarify-custom::placeholder { color: rgba(250, 247, 242, 0.4); font-style: italic; }
.clarify-actions { display: flex; flex-direction: column; align-items: center; gap: 6px; margin-top: 24px; }

.composer-answer {
  background: rgba(31, 74, 54, 0.45);
  border: 1px solid rgba(212, 168, 68, 0.3);
  border-radius: 20px;
  padding: 30px;
}
.answer-header {
  display: flex; align-items: center; gap: 12px;
  margin-bottom: 18px;
  padding-bottom: 16px;
  border-bottom: 1px solid rgba(212, 168, 68, 0.2);
}
.answer-avatar { width: 36px; height: 36px; border-radius: 50%; background: #FAF7F2; padding: 4px; }
.answer-header strong { font-family: 'Cormorant Garamond', serif; font-style: italic; font-size: 17px; color: #E8B96B; }
.answer-text {
  font-size: 16px;
  line-height: 1.7;
  color: #FAF7F2;
  margin-bottom: 30px;
}
.answer-section { margin-top: 24px; }
.answer-section h3 {
  font-family: 'Cormorant Garamond', serif;
  font-size: 18px; font-weight: 500;
  color: #E8B96B;
  margin-bottom: 12px;
  letter-spacing: 0.02em;
}
.answer-cards { display: grid; grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); gap: 12px; }
.answer-card {
  background: rgba(15, 36, 25, 0.5);
  border: 1px solid rgba(212, 168, 68, 0.18);
  border-radius: 14px;
  padding: 14px 16px;
  text-align: left;
  cursor: pointer;
  font-family: inherit;
  transition: all 0.2s;
  color: inherit;
}
.answer-card:hover { background: rgba(15, 36, 25, 0.7); border-color: #D4A844; transform: translateY(-2px); }
.answer-card strong { display: block; color: #FAF7F2; font-family: 'Cormorant Garamond', serif; font-size: 16px; margin-bottom: 4px; }
.answer-card small { display: block; color: #E8B96B; font-size: 11px; letter-spacing: 0.06em; margin-bottom: 8px; }
.answer-card p { font-size: 12px; color: rgba(250, 247, 242, 0.65); line-height: 1.45; margin: 0; }
.answer-actions { margin-top: 28px; display: flex; gap: 18px; flex-wrap: wrap; justify-content: center; align-items: center; }
.answer-actions .composer-link { margin-top: 0; }

@media (max-width: 700px) {
  .composer-hero { padding: 80px 0 40px; }
  .composer-hero h1 { font-size: 28px; }
  .composer-lead { font-size: 16px; }
  .djawal-container { padding: 0 20px; }
  .composer-input-wrap, .composer-clarify, .composer-answer { padding: 18px; }
  .answer-cards { grid-template-columns: 1fr; }
}
</style>
