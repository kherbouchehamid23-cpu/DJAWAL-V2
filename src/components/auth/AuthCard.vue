<script setup lang="ts">
defineProps<{
  title: string
  subtitle?: string
  arabicTag?: string
}>()
</script>

<template>
  <div class="auth-wrap">
    <!-- Côté gauche : citation immersive -->
    <aside class="auth-illustration">
      <div class="illu-overlay">
        <div class="illu-tag arabic">جوّال</div>
        <h2 class="illu-quote">
          « Voyager, c'est aller de soi à soi en passant par les autres. »
        </h2>
        <div class="illu-author">— Proverbe touareg adapté</div>
        <div class="illu-pattern"></div>
      </div>
    </aside>

    <!-- Côté droit : formulaire -->
    <main class="auth-form-side">
      <header class="auth-header">
        <router-link to="/" class="auth-logo">
          <div class="logo-mark">
            <svg viewBox="0 0 32 32" width="22" height="22" aria-hidden="true">
              <circle cx="16" cy="16" r="9.5" fill="none" stroke="#E8B547" stroke-width="1.4"/>
              <path d="M3 16 L7 13 L7 19 Z" fill="#E8B547"/>
              <path d="M29 16 L25 13 L25 19 Z" fill="#E8B547"/>
              <circle cx="16" cy="16" r="3.2" fill="#B8312E"/>
              <circle cx="16" cy="16" r="1.2" fill="#E8B547"/>
            </svg>
          </div>
          <span>Djawal</span>
        </router-link>
      </header>

      <div class="auth-card">
        <div v-if="arabicTag" class="auth-arabic-tag arabic">{{ arabicTag }}</div>
        <h1>{{ title }}</h1>
        <p v-if="subtitle" class="auth-subtitle">{{ subtitle }}</p>

        <slot />
      </div>
    </main>
  </div>
</template>

<style scoped>
.auth-wrap {
  min-height: 100vh;
  display: grid;
  grid-template-columns: 1fr 1.2fr;
  background: var(--c-fond);
}

/* === Côté gauche : illustration culturelle === */
.auth-illustration {
  position: relative;
  background:
    radial-gradient(ellipse at 70% 80%, rgba(212, 160, 79, 0.6) 0%, transparent 50%),
    radial-gradient(ellipse at 30% 60%, rgba(201, 112, 80, 0.5) 0%, transparent 55%),
    linear-gradient(180deg, #0D2A3D 0%, #1B4965 30%, #C97050 75%, #D4A04F 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: var(--space-8);
  position: relative;
  overflow: hidden;
}
.auth-illustration::before {
  content: '';
  position: absolute; bottom: 0; left: 0; right: 0; height: 38%;
  background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 1440 300' preserveAspectRatio='none'><path d='M0,300 L0,180 L120,140 L240,170 L360,90 L500,130 L640,60 L800,110 L960,80 L1100,150 L1260,100 L1440,170 L1440,300 Z' fill='%230D2A3D' opacity='0.85'/></svg>");
  background-size: 100% 100%;
}
.illu-overlay {
  position: relative;
  z-index: 2;
  color: var(--c-fond);
  max-width: 480px;
  text-align: center;
}
.illu-tag {
  font-family: var(--font-arabic);
  font-size: 64px;
  color: var(--c-accent);
  text-shadow: 0 2px 12px rgba(0,0,0,0.4);
  margin-bottom: var(--space-5);
}
.illu-quote {
  color: var(--c-fond);
  font-family: var(--font-display);
  font-size: 32px;
  font-style: italic;
  font-weight: 500;
  line-height: 1.3;
  margin-bottom: var(--space-4);
}
.illu-author {
  color: var(--c-accent);
  font-size: 14px;
  letter-spacing: 0.08em;
}
.illu-pattern {
  position: absolute;
  bottom: -120px;
  left: 50%;
  transform: translateX(-50%);
  width: 240px;
  height: 240px;
  background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 80 80'><g fill='none' stroke='%23D4A04F' stroke-width='1.5' opacity='0.3'><path d='M40 8 L52 20 L72 20 L60 32 L72 44 L52 44 L40 56 L28 44 L8 44 L20 32 L8 20 L28 20 Z'/><circle cx='40' cy='32' r='6'/></g></svg>");
  background-size: 80px 80px;
  background-repeat: repeat;
}

/* === Côté droit : formulaire === */
.auth-form-side {
  display: flex;
  flex-direction: column;
  padding: var(--space-5) var(--space-7);
  background: var(--c-fond);
  overflow-y: auto;
}
.auth-header {
  margin-bottom: var(--space-7);
}
.auth-logo {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  text-decoration: none;
  font-family: var(--font-display);
  font-size: 24px;
  font-weight: 600;
  color: var(--c-primaire);
}
.logo-mark {
  width: 38px; height: 38px;
  background: #2D5A3D; /* Vert Atlas — verrouillé */
  border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  box-shadow: 0 0 0 1.5px rgba(232, 181, 71, 0.4);
}
.auth-card {
  max-width: 460px;
  width: 100%;
  margin: auto 0;
}
.auth-arabic-tag {
  font-family: var(--font-arabic);
  font-size: 22px;
  color: var(--c-accent-fort);
  margin-bottom: var(--space-3);
}
.auth-card h1 {
  font-size: 38px;
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-3);
  line-height: 1.15;
}
.auth-subtitle {
  color: var(--c-texte-doux);
  font-size: 16px;
  margin-bottom: var(--space-6);
}

/* === Responsive === */
@media (max-width: 980px) {
  .auth-wrap {
    grid-template-columns: 1fr;
  }
  .auth-illustration {
    min-height: 200px;
    padding: var(--space-5);
  }
  .illu-tag { font-size: 42px; margin-bottom: var(--space-3); }
  .illu-quote { font-size: 20px; }
  .auth-form-side { padding: var(--space-5); }
  .auth-card h1 { font-size: 30px; }
}
</style>
