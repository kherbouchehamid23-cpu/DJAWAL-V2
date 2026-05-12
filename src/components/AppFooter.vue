<script setup lang="ts">
const year = new Date().getFullYear()
</script>

<template>
  <footer class="djawal-footer">
    <div class="djawal-container">
      <div class="footer-grid">
        <div class="footer-brand">
          <div class="logo-mark-inline">
            <svg viewBox="0 0 32 32" width="22" height="22">
              <g fill="none" stroke="#D4A04F" stroke-width="2">
                <path d="M16 2 L28 16 L16 30 L4 16 Z" />
                <circle cx="16" cy="16" r="5" />
                <circle cx="16" cy="16" r="1.5" fill="#D4A04F" />
              </g>
            </svg>
            <span class="brand-fr">Djawal</span>
            <span class="arabic brand-ar">جوّال</span>
          </div>
          <p>
            L'Algérie comme une invitation. Plateforme communautaire de voyages,
            hôtels, restaurants et sites — pensée et faite ici.
          </p>
        </div>

        <div>
          <h4>Découvrir</h4>
          <ul>
            <li><router-link to="/voyages">Destinations</router-link></li>
            <li><router-link to="/composer">✨ Composer avec l'IA</router-link></li>
            <li><router-link to="/temoignages">Souvenirs voyageurs</router-link></li>
            <li><router-link to="/about">Notre démarche</router-link></li>
          </ul>
        </div>

        <div>
          <h4>Communauté</h4>
          <ul>
            <li><router-link to="/auth/signup">Créer un compte</router-link></li>
            <li><router-link to="/auth/signup?role=guide_junior">Devenir guide</router-link></li>
            <li><router-link to="/contact">Contact</router-link></li>
          </ul>
        </div>

        <div>
          <h4>Légal</h4>
          <ul>
            <li><router-link to="/mentions-legales">Mentions légales</router-link></li>
            <li><router-link to="/cgu">Conditions d'utilisation</router-link></li>
            <li><a href="mailto:hello@djawal.app">hello@djawal.app</a></li>
          </ul>
        </div>
      </div>

      <div class="footer-bottom">
        <span>© {{ year }} Djawal — Tous droits réservés</span>
        <span class="locale-note"><span class="arabic">صُنع في الجزائر</span> · Conçu en Algérie 🇩🇿</span>
      </div>
    </div>
  </footer>
</template>

<style scoped>
.djawal-footer {
  background: var(--c-primaire-profond);
  color: rgba(245, 233, 211, 0.7);
  padding: var(--space-8) var(--space-5) var(--space-5);
  position: relative;
  margin-top: var(--space-9);
}
.djawal-footer::before {
  content: ''; position: absolute; top: 0; left: 0; right: 0; height: 12px;
  background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='80' height='12' viewBox='0 0 80 12'><g fill='%23D4A04F'><path d='M0 0 L80 0 L40 12 Z' opacity='0.3'/><path d='M40 4 L48 8 L40 12 L32 8 Z'/></g></svg>");
  background-repeat: repeat-x;
}
.footer-grid {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr 1fr;
  gap: var(--space-7);
}
.footer-brand p { font-size: 14px; max-width: 320px; margin-top: var(--space-4); }
.logo-mark-inline {
  display: flex; align-items: center; gap: 10px;
  color: var(--c-fond);
  font-family: var(--font-display);
}
.brand-fr { font-size: 24px; font-weight: 600; }
.brand-ar { color: var(--c-accent); font-size: 16px; }
.djawal-footer h4 {
  color: var(--c-fond);
  font-family: var(--font-body);
  font-size: 13px;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  font-weight: 700;
  margin-bottom: var(--space-4);
}
.djawal-footer ul { list-style: none; padding: 0; margin: 0; }
.djawal-footer li { margin-bottom: 10px; font-size: 14px; }
.djawal-footer li a:hover { color: var(--c-accent); }
.footer-bottom {
  margin-top: var(--space-7);
  padding-top: var(--space-5);
  border-top: 1px solid rgba(212, 160, 79, 0.15);
  display: flex; justify-content: space-between; align-items: center;
  font-size: 13px; flex-wrap: wrap; gap: var(--space-3);
}
.footer-bottom .arabic { color: var(--c-accent); font-size: 16px; }

@media (max-width: 1024px) {
  .footer-grid { grid-template-columns: 1fr 1fr; }
}
@media (max-width: 720px) {
  .footer-grid { grid-template-columns: 1fr; }
}
</style>
