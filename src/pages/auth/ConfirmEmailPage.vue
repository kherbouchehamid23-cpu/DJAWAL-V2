<script setup lang="ts">
import { useRoute } from 'vue-router'
const route = useRoute()
const email = route.query.email as string | undefined
</script>

<template>
  <div class="confirm-wrap">
    <div class="confirm-card">
      <div class="icon-circle">✉️</div>
      <h1>Vérifiez votre boîte mail</h1>
      <p class="lead">
        Nous avons envoyé un lien de confirmation à
        <strong v-if="email">{{ email }}</strong>
        <span v-else>votre adresse e-mail</span>.
      </p>
      <p class="hint">
        Cliquez sur le lien dans l'e-mail pour activer votre compte Djawal.
        Pensez à vérifier vos spams si vous ne le voyez pas dans 2-3 minutes.
      </p>
      <div class="actions">
        <router-link to="/auth/login">
          <v-btn variant="outlined" color="primary">Revenir à la connexion</v-btn>
        </router-link>
      </div>
    </div>
  </div>
</template>

<style scoped>
.confirm-wrap {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--c-fond);
  padding: var(--space-5);
}
.confirm-card {
  background: var(--c-surface);
  padding: var(--space-7);
  border-radius: var(--r-lg);
  box-shadow: var(--ombre-elevee);
  text-align: center;
  max-width: 480px;
  border-top: 6px solid var(--c-accent);
}
.icon-circle {
  width: 80px; height: 80px;
  background: var(--c-fond-chaud);
  border-radius: 50%;
  margin: 0 auto var(--space-4);
  display: flex; align-items: center; justify-content: center;
  font-size: 36px;
  border: 2px dashed var(--c-accent-fort);
}
h1 {
  font-family: var(--font-display);
  font-size: 32px;
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-3);
}
.lead { font-size: 16px; color: var(--c-texte); margin-bottom: var(--space-3); }
.lead strong { color: var(--c-primaire); }
.hint { font-size: 14px; color: var(--c-texte-doux); margin-bottom: var(--space-5); }
.actions a { text-decoration: none; }
</style>
