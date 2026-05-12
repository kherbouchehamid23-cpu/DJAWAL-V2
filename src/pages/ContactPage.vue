<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'
import { useSEO } from '@/composables/useSEO'

useSEO({
  title: 'Contact',
  description: 'Une question, un partenariat, une suggestion ? Écrivez à l\'équipe Djawal — nous répondons sous 48h.'
})

const auth = useAuthStore()
const name = ref('')
const email = ref('')
const subject = ref('')
const message = ref('')
const sending = ref(false)
const sent = ref(false)
const error = ref('')

onMounted(() => {
  if (auth.profile) name.value = auth.profile.display_name
  if (auth.user?.email) email.value = auth.user.email
})

async function send() {
  error.value = ''
  if (!name.value.trim() || !email.value.trim() || !subject.value.trim() || message.value.length < 10) {
    error.value = 'Tous les champs sont requis, et le message doit faire au moins 10 caractères.'
    return
  }

  sending.value = true
  const { error: err } = await supabase.from('contact_messages').insert({
    name: name.value.trim(),
    email: email.value.trim(),
    subject: subject.value.trim(),
    message: message.value.trim(),
    user_id: auth.user?.id || null
  })
  sending.value = false

  if (err) {
    error.value = err.message
    return
  }
  sent.value = true
}
</script>

<template>
  <div class="contact-page">
    <header class="page-hero">
      <div class="djawal-container">
        <div class="eyebrow">Nous contacter</div>
        <h1>Une question ? Un partenariat ?</h1>
        <p class="lead">
          L'équipe Djawal répond sous 48h. Que vous soyez voyageur, guide en attente de validation,
          partenaire institutionnel ou simplement curieux — écrivez-nous.
        </p>
      </div>
    </header>

    <div class="djawal-container djawal-section contact-body">
      <div v-if="sent" class="success-card">
        <div class="success-icon">✓</div>
        <h2>Message envoyé</h2>
        <p>Merci ! Nous reviendrons vers vous dans les 48h à l'adresse <strong>{{ email }}</strong>.</p>
        <router-link to="/">
          <v-btn color="primary" variant="flat" size="large">Retour à l'accueil</v-btn>
        </router-link>
      </div>

      <form v-else @submit.prevent="send" class="contact-form">
        <v-alert v-if="error" type="error" variant="tonal" class="mb-3">{{ error }}</v-alert>

        <div class="grid-2">
          <v-text-field
            v-model="name"
            label="Votre nom"
            density="comfortable"
            variant="outlined"
            required
          />
          <v-text-field
            v-model="email"
            type="email"
            label="E-mail"
            density="comfortable"
            variant="outlined"
            required
          />
        </div>

        <v-select
          v-model="subject"
          :items="['Question générale', 'Devenir guide', 'Partenariat', 'Problème technique', 'Suggestion', 'Autre']"
          label="Sujet"
          density="comfortable"
          variant="outlined"
          class="mt-3"
        />

        <v-textarea
          v-model="message"
          label="Votre message"
          placeholder="Dites-nous tout…"
          density="comfortable"
          variant="outlined"
          rows="6"
          counter
          maxlength="5000"
          class="mt-3"
        />

        <div class="actions">
          <v-btn type="submit" color="primary" variant="flat" size="x-large" :loading="sending">
            Envoyer le message
          </v-btn>
        </div>
      </form>

      <aside class="info-side">
        <h3>Coordonnées</h3>
        <ul class="info-list">
          <li>
            <span class="info-icon">📧</span>
            <div>
              <strong>E-mail</strong>
              <a href="mailto:hello@djawal.app">hello@djawal.app</a>
            </div>
          </li>
          <li>
            <span class="info-icon">🌍</span>
            <div>
              <strong>Algérie</strong>
              <small>Plateforme communautaire 100% locale</small>
            </div>
          </li>
          <li>
            <span class="info-icon">⏱️</span>
            <div>
              <strong>Délai de réponse</strong>
              <small>48h ouvrées</small>
            </div>
          </li>
        </ul>

        <div class="info-tip">
          💡 Vous êtes guide professionnel souhaitant rejoindre Djawal ?
          <router-link to="/auth/signup">Inscrivez-vous comme guide</router-link>
          et nous traiterons votre dossier KYC en priorité.
        </div>
      </aside>
    </div>
  </div>
</template>

<style scoped>
.contact-page { background: var(--c-fond); min-height: 100vh; }

.page-hero {
  background: var(--c-fond-chaud);
  padding: var(--space-7) var(--space-5) var(--space-5);
  position: relative;
  overflow: hidden;
}
.page-hero::before {
  content: ''; position: absolute; inset: 0;
  background-image: var(--motif-principal-url);
  opacity: 0.3;
}
.eyebrow {
  color: var(--c-accent-fort);
  font-size: 13px; font-weight: 700;
  letter-spacing: 0.2em; text-transform: uppercase;
  margin-bottom: var(--space-2);
  position: relative;
}
.page-hero h1 {
  font-family: var(--font-display);
  font-size: clamp(32px, 4.5vw, 48px);
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-2);
  position: relative;
}
.lead {
  font-size: 17px;
  color: var(--c-primaire);
  max-width: 720px;
  position: relative;
}

.contact-body {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 320px;
  gap: var(--space-6);
}

.contact-form {
  background: var(--c-surface);
  border-radius: var(--r-lg);
  padding: var(--space-5);
  box-shadow: var(--ombre-douce);
}
.grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--space-3);
}
.actions {
  margin-top: var(--space-4);
  text-align: right;
}

.success-card {
  grid-column: 1 / -1;
  background: var(--c-surface);
  border-radius: var(--r-lg);
  padding: var(--space-7);
  text-align: center;
  box-shadow: var(--ombre-douce);
  border-top: 4px solid #2D5A3D;
}
.success-icon {
  width: 80px; height: 80px;
  background: #2D5A3D;
  color: white;
  border-radius: 50%;
  margin: 0 auto var(--space-3);
  display: flex; align-items: center; justify-content: center;
  font-size: 40px;
  font-weight: 700;
}
.success-card h2 {
  font-family: var(--font-display);
  font-size: 32px;
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-2);
}
.success-card p { color: var(--c-texte); margin-bottom: var(--space-4); }

.info-side {
  background: var(--c-fond-chaud);
  border-radius: var(--r-lg);
  padding: var(--space-5);
}
.info-side h3 {
  font-family: var(--font-display);
  font-size: 20px;
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-3);
}
.info-list { list-style: none; padding: 0; margin: 0 0 var(--space-4); }
.info-list li {
  display: flex; align-items: flex-start; gap: var(--space-3);
  padding: var(--space-2) 0;
  border-bottom: 1px solid var(--c-gris-clair);
}
.info-list li:last-child { border-bottom: none; }
.info-icon { font-size: 24px; flex-shrink: 0; }
.info-list strong { display: block; color: var(--c-primaire-profond); font-size: 14px; }
.info-list a {
  color: var(--c-accent-fort);
  font-weight: 600;
  text-decoration: none;
  font-size: 14px;
}
.info-list a:hover { text-decoration: underline; }
.info-list small { color: var(--c-texte-doux); font-size: 12px; }

.info-tip {
  background: var(--c-surface);
  border-radius: var(--r-md);
  padding: var(--space-3);
  font-size: 13px;
  color: var(--c-texte);
  line-height: 1.5;
}
.info-tip a {
  color: var(--c-accent-fort);
  font-weight: 700;
  text-decoration: none;
}
.info-tip a:hover { text-decoration: underline; }

@media (max-width: 880px) {
  .contact-body { grid-template-columns: 1fr; }
}
@media (max-width: 600px) {
  .grid-2 { grid-template-columns: 1fr; }
}
</style>
