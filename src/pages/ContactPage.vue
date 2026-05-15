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
      <div class="hero-overlay"></div>
      <div class="djawal-container hero-content">
        <div class="hero-eyebrow">
          <span class="eyebrow-line"></span>
          <span>Nous contacter</span>
          <span class="eyebrow-line"></span>
        </div>
        <h1>Une question, <em>un partenariat</em> ?</h1>
        <p class="lead">
          L'équipe Djawal répond sous 48h. Que vous soyez voyageur, guide en attente de
          validation, partenaire institutionnel ou simplement curieux — écrivez-nous.
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
.contact-page {
  background: linear-gradient(180deg, #0F2419 0%, #1A3A2A 60%, #0F2419 100%);
  min-height: 100vh;
  color: #FAF7F2;
  font-family: 'Inter', sans-serif;
}
.djawal-container { max-width: 1200px; margin: 0 auto; padding: 0 32px; }
.djawal-section { padding: 80px 0; }

/* === HERO COMPACT V4 === */
.page-hero {
  position: relative;
  min-height: 46vh;
  display: flex; align-items: center; justify-content: center;
  text-align: center;
  padding: 120px 32px 70px;
  overflow: hidden;
  background-image: url('https://images.pexels.com/photos/29489030/pexels-photo-29489030.jpeg?auto=compress&cs=tinysrgb&w=1920');
  background-size: cover;
  background-position: center;
}
.hero-overlay {
  position: absolute; inset: 0;
  background: linear-gradient(180deg, rgba(15, 36, 25, 0.62) 0%, rgba(15, 36, 25, 0.88) 60%, #0F2419 100%);
  z-index: 1;
}
.hero-content { position: relative; z-index: 2; }
.hero-eyebrow {
  display: inline-flex; align-items: center; gap: 14px;
  color: #E8B96B;
  font-size: 11px; letter-spacing: 0.24em;
  text-transform: uppercase;
  margin-bottom: 22px;
}
.eyebrow-line {
  width: 36px; height: 1px;
  background: linear-gradient(90deg, transparent, #D4A844, transparent);
}
.page-hero h1 {
  font-family: 'Cormorant Garamond', serif;
  font-size: clamp(34px, 5vw, 56px);
  font-weight: 400; line-height: 1.05;
  margin-bottom: 18px;
  color: #FAF7F2;
}
.page-hero h1 em { font-style: italic; color: #E8B96B; }
.lead {
  font-family: 'Cormorant Garamond', serif;
  font-style: italic;
  font-size: clamp(16px, 1.8vw, 20px);
  color: rgba(250, 247, 242, 0.78);
  max-width: 680px;
  margin: 0 auto;
  line-height: 1.5;
}

/* === BODY === */
.contact-body {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 340px;
  gap: 40px;
}

.contact-form {
  background: rgba(31, 74, 54, 0.5);
  border: 1px solid rgba(212, 168, 68, 0.25);
  border-radius: 22px;
  padding: 36px 34px;
}
.grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px;
}
.actions {
  margin-top: 24px;
  text-align: right;
}

/* Style Vuetify fields on dark bg */
.contact-form :deep(.v-field) {
  background: rgba(15, 36, 25, 0.45) !important;
  border-radius: 12px !important;
}
.contact-form :deep(.v-field__outline) { color: rgba(212, 168, 68, 0.3) !important; }
.contact-form :deep(.v-field--focused .v-field__outline) { color: #D4A844 !important; }
.contact-form :deep(.v-label) { color: rgba(250, 247, 242, 0.65) !important; }
.contact-form :deep(input), .contact-form :deep(textarea) { color: #FAF7F2 !important; }

.success-card {
  grid-column: 1 / -1;
  background: rgba(31, 74, 54, 0.6);
  border: 1px solid rgba(212, 168, 68, 0.3);
  border-radius: 22px;
  padding: 60px 40px;
  text-align: center;
  border-top: 3px solid #D4A844;
}
.success-icon {
  width: 86px; height: 86px;
  background: linear-gradient(135deg, #D4A844, #B8862E);
  color: #0F2419;
  border-radius: 50%;
  margin: 0 auto 20px;
  display: flex; align-items: center; justify-content: center;
  font-size: 42px;
  font-weight: 700;
  box-shadow: 0 10px 30px rgba(212, 168, 68, 0.35);
}
.success-card h2 {
  font-family: 'Cormorant Garamond', serif;
  font-size: 36px;
  font-weight: 400;
  font-style: italic;
  color: #FAF7F2;
  margin-bottom: 12px;
}
.success-card p {
  color: rgba(250, 247, 242, 0.78);
  margin-bottom: 24px;
  font-size: 16px;
}
.success-card strong { color: #E8B96B; }

/* === INFO SIDE === */
.info-side {
  background: rgba(31, 74, 54, 0.5);
  border: 1px solid rgba(212, 168, 68, 0.22);
  border-radius: 22px;
  padding: 32px 28px;
  height: fit-content;
}
.info-side h3 {
  font-family: 'Cormorant Garamond', serif;
  font-size: 22px;
  font-style: italic;
  color: #E8B96B;
  margin-bottom: 22px;
}
.info-list { list-style: none; padding: 0; margin: 0 0 24px; }
.info-list li {
  display: flex; align-items: flex-start; gap: 14px;
  padding: 14px 0;
  border-bottom: 1px solid rgba(212, 168, 68, 0.18);
}
.info-list li:last-child { border-bottom: none; }
.info-icon { font-size: 22px; flex-shrink: 0; }
.info-list strong {
  display: block;
  color: #FAF7F2;
  font-size: 14px;
  margin-bottom: 2px;
  font-weight: 600;
}
.info-list a {
  color: #E8B96B;
  font-weight: 500;
  text-decoration: none;
  font-size: 13.5px;
}
.info-list a:hover { color: #FAF7F2; text-decoration: underline; }
.info-list small { color: rgba(250, 247, 242, 0.6); font-size: 12.5px; }

.info-tip {
  background: rgba(15, 36, 25, 0.5);
  border: 1px solid rgba(212, 168, 68, 0.2);
  border-radius: 14px;
  padding: 16px 18px;
  font-size: 13.5px;
  color: rgba(250, 247, 242, 0.78);
  line-height: 1.6;
}
.info-tip a {
  color: #E8B96B;
  font-weight: 600;
  text-decoration: none;
}
.info-tip a:hover { text-decoration: underline; }

@media (max-width: 880px) {
  .contact-body { grid-template-columns: 1fr; }
}
@media (max-width: 600px) {
  .grid-2 { grid-template-columns: 1fr; }
  .djawal-container { padding: 0 20px; }
  .page-hero { min-height: 38vh; padding: 90px 20px 50px; }
  .djawal-section { padding: 50px 0; }
  .contact-form, .info-side, .success-card { padding: 26px 22px; }
}
</style>
