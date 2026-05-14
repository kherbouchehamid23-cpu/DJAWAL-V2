<script setup lang="ts">
const year = new Date().getFullYear()
</script>

<template>
  <footer class="djawal-footer">
    <div class="djawal-container">
      <div class="footer-grid">
        <div class="footer-brand">
          <div class="logo-mark-inline">
            <div class="footer-logo-circle">
              <svg viewBox="0 0 32 32" width="20" height="20" aria-hidden="true">
                <circle cx="16" cy="16" r="9.5" fill="none" stroke="#E8B547" stroke-width="1.4"/>
                <path d="M3 16 L7 13 L7 19 Z" fill="#E8B547"/>
                <path d="M29 16 L25 13 L25 19 Z" fill="#E8B547"/>
                <circle cx="16" cy="16" r="3.2" fill="#B8312E"/>
                <circle cx="16" cy="16" r="1.2" fill="#E8B547"/>
              </svg>
            </div>
            <span class="brand-fr">Djawal.</span>
            <span class="arabic brand-ar">جوّال</span>
          </div>
          <p>
            Première plateforme communautaire de tourisme en Algérie. Voyagez
            authentique, au plus proche de l'âme du pays.
          </p>
        </div>

        <div>
          <h4>Découvrir</h4>
          <ul>
            <li><router-link to="/voyages?theme=saharien">Sahara central</router-link></li>
            <li><router-link to="/voyages?theme=mauresque">Joyaux côtiers</router-link></li>
            <li><router-link to="/voyages?theme=aures">Routes de montagne</router-link></li>
            <li><router-link to="/temoignages">Souvenirs voyageurs</router-link></li>
          </ul>
        </div>

        <div>
          <h4>L'initiative</h4>
          <ul>
            <li><router-link to="/auth/signup?role=guide_junior">Devenir guide</router-link></li>
            <li><router-link to="/composer">Fennec, notre IA</router-link></li>
            <li><router-link to="/about">Notre mission</router-link></li>
            <li><a href="mailto:hello@djawal.app">Contact</a></li>
          </ul>
        </div>

        <div>
          <h4>Légal</h4>
          <ul>
            <li><router-link to="/mentions-legales">Mentions légales</router-link></li>
            <li><router-link to="/cgu">Conditions d'utilisation</router-link></li>
            <li><router-link to="/mentions-legales#confidentialite">Confidentialité</router-link></li>
          </ul>
        </div>
      </div>

      <div class="footer-bottom">
        <span>© {{ year }} Djawal · Tous droits réservés</span>
        <span class="locale-note">
          Pensé en
          <span class="locale-flag">français</span>
          — ouvert au monde
          <span class="arabic locale-arab">العربية</span>
          <span class="tif locale-tif">ⵜⵉⵏⵉⵔⵉ</span>
        </span>
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
.footer-logo-circle {
  width: 36px; height: 36px;
  background: #2D5A3D;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 0 0 1.5px rgba(232, 181, 71, 0.4);
}
.brand-fr { font-size: 24px; font-weight: 600; }
.brand-ar { color: var(--c-accent); font-size: 16px; }
.locale-note { display: inline-flex; align-items: center; gap: 6px; flex-wrap: wrap; }
.locale-flag { font-style: italic; }
.locale-arab { color: var(--c-accent); }
.locale-tif { font-family: 'Noto Sans Tifinagh', monospace; color: var(--c-accent); font-size: 13px; letter-spacing: 0.12em; }
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
