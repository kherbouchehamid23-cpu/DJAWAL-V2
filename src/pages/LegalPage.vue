<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { useSEO } from '@/composables/useSEO'

const route = useRoute()
const type = computed(() => route.name === 'cgu' ? 'cgu' : 'mentions')

useSEO(() => ({
  title: type.value === 'cgu' ? "Conditions générales d'utilisation" : 'Mentions légales',
  description: type.value === 'cgu'
    ? "Les conditions générales d'utilisation de la plateforme Djawal."
    : "Mentions légales de la plateforme Djawal — tourisme communautaire en Algérie."
}))

const lastUpdate = '12 mai 2026'
</script>

<template>
  <div class="legal-page">
    <header class="page-hero">
      <div class="hero-overlay"></div>
      <div class="djawal-container hero-content">
        <div class="hero-eyebrow">
          <span class="eyebrow-line"></span>
          <span>{{ type === 'cgu' ? 'CGU' : 'Mentions légales' }}</span>
          <span class="eyebrow-line"></span>
        </div>
        <h1>{{ type === 'cgu' ? "Conditions générales d'utilisation" : 'Mentions légales' }}</h1>
        <p class="meta">Dernière mise à jour : {{ lastUpdate }}</p>
      </div>
    </header>

    <article class="djawal-container djawal-section legal-content">
      <!-- ===== MENTIONS LÉGALES ===== -->
      <template v-if="type === 'mentions'">
        <section>
          <h2>1. Éditeur du site</h2>
          <p><strong>Djawal</strong> — Plateforme communautaire de voyages en Algérie.</p>
          <p>Site édité par l'équipe Djawal, basée en Algérie.</p>
          <p>Contact : <a href="mailto:hello@djawal.app">hello@djawal.app</a></p>
        </section>

        <section>
          <h2>2. Hébergement</h2>
          <p>Le site est hébergé par <strong>Vercel Inc.</strong>, 340 S Lemon Ave #4133, Walnut, CA 91789, USA.</p>
          <p>Les données utilisateurs et le contenu sont stockés via <strong>Supabase</strong> (Région UE-Ouest, Irlande), filiale de Supabase Inc., 970 Toa Payoh North, Singapore.</p>
        </section>

        <section>
          <h2>3. Propriété intellectuelle</h2>
          <p>L'ensemble du contenu présent sur Djawal (textes, images, logos, design, code) est protégé par le droit de la propriété intellectuelle.</p>
          <p>Les photographies et descriptions des sites, hébergements et restaurants sont fournies par notre communauté de guides et de voyageurs. Chaque contributeur conserve les droits sur le contenu qu'il publie tout en accordant à Djawal une licence non-exclusive d'utilisation pour la promotion de la plateforme.</p>
        </section>

        <section>
          <h2>4. Données personnelles</h2>
          <p>Les données collectées par Djawal sont utilisées exclusivement pour le fonctionnement de la plateforme : authentification, sauvegarde des favoris, modération des contenus, recommandations IA personnalisées.</p>
          <p>Conformément au RGPD et aux dispositions algériennes équivalentes, vous disposez d'un droit d'accès, de rectification, de suppression et de portabilité de vos données. Pour exercer ces droits, contactez-nous à <a href="mailto:hello@djawal.app">hello@djawal.app</a>.</p>
          <p>Nous ne vendons ni ne louons vos données à des tiers.</p>
        </section>

        <section>
          <h2>5. Cookies et stockage local</h2>
          <p>Djawal utilise uniquement des cookies/localStorage techniques nécessaires au fonctionnement (session d'authentification, préférence de thème culturel). Aucun traceur publicitaire ou analytique tiers n'est utilisé.</p>
        </section>

        <section>
          <h2>6. Responsabilité</h2>
          <p>Djawal est une plateforme de mise en relation entre voyageurs et guides locaux. Les informations publiées (prix, disponibilités, descriptions) sont fournies par les contributeurs et peuvent évoluer. Djawal recommande de toujours vérifier ces informations avant de finaliser une réservation directement avec le guide ou l'établissement.</p>
        </section>

        <section>
          <h2>7. Loi applicable</h2>
          <p>Les présentes mentions sont régies par le droit algérien. Tout litige sera porté devant les tribunaux compétents d'Alger.</p>
        </section>
      </template>

      <!-- ===== CGU ===== -->
      <template v-else>
        <section>
          <h2>1. Acceptation des conditions</h2>
          <p>En créant un compte ou en utilisant Djawal, vous acceptez les présentes conditions générales d'utilisation. Si vous n'êtes pas d'accord avec ces termes, n'utilisez pas la plateforme.</p>
        </section>

        <section>
          <h2>2. Rôles utilisateurs</h2>
          <p>Djawal distingue plusieurs rôles :</p>
          <ul>
            <li><strong>Voyageur</strong> : peut explorer le catalogue, ajouter des favoris, publier des avis et des souvenirs.</li>
            <li><strong>Guide Junior</strong> : crée des parcours qui sont modérés avant publication.</li>
            <li><strong>Guide Senior</strong> : crée des parcours publiés directement (après validation KYC).</li>
            <li><strong>Super Admin</strong> : gère le catalogue maître et la modération.</li>
          </ul>
        </section>

        <section>
          <h2>3. Vérification KYC</h2>
          <p>Pour publier des parcours, les guides doivent compléter une vérification d'identité (KYC). Cette vérification permet de garantir la confiance de la communauté.</p>
        </section>

        <section>
          <h2>4. Règles de contenu</h2>
          <p>En publiant du contenu sur Djawal (parcours, avis, souvenirs, photos), vous garantissez :</p>
          <ul>
            <li>Détenir les droits sur ce contenu ou avoir l'autorisation de le publier</li>
            <li>Ne pas porter atteinte à des tiers (diffamation, harcèlement, atteinte à la vie privée)</li>
            <li>Ne pas publier de contenu illégal, discriminatoire ou commercial déguisé</li>
            <li>Ne pas publier de fausses informations (faux établissements, faux prix)</li>
          </ul>
          <p>Djawal se réserve le droit de modérer, masquer ou supprimer tout contenu contraire à ces règles.</p>
        </section>

        <section>
          <h2>5. Recommandations IA</h2>
          <p>Djawal propose Djawal IA, qui s'appuie sur le catalogue communautaire pour suggérer des parcours, hébergements et sites. Ces recommandations sont à titre indicatif. Aucune réservation n'est garantie par Djawal IA. Vérifiez toujours la disponibilité directement avec le prestataire.</p>
        </section>

        <section>
          <h2>6. Suspension et résiliation</h2>
          <p>Djawal peut suspendre ou supprimer un compte en cas de violation des présentes conditions. L'utilisateur peut supprimer son compte à tout moment en nous contactant.</p>
        </section>

        <section>
          <h2>7. Évolution des CGU</h2>
          <p>Djawal peut modifier ces conditions. Les modifications majeures seront notifiées aux utilisateurs par e-mail. L'utilisation continue après notification vaut acceptation.</p>
        </section>
      </template>

      <div class="nav-legal">
        <router-link v-if="type === 'mentions'" to="/cgu">
          → Voir les conditions générales d'utilisation
        </router-link>
        <router-link v-else to="/mentions-legales">
          ← Voir les mentions légales
        </router-link>
      </div>
    </article>
  </div>
</template>

<style scoped>
.legal-page {
  background: linear-gradient(180deg, #0F2419 0%, #1A3A2A 60%, #0F2419 100%);
  min-height: 100vh;
  color: #FAF7F2;
  font-family: 'Inter', sans-serif;
}
.djawal-container { max-width: 1080px; margin: 0 auto; padding: 0 32px; }
.djawal-section { padding: 70px 0; }

/* === HERO COMPACT V4 === */
.page-hero {
  position: relative;
  min-height: 38vh;
  display: flex; align-items: center; justify-content: center;
  text-align: center;
  padding: 120px 32px 60px;
  overflow: hidden;
  background: linear-gradient(180deg, #1A3A2A 0%, #0F2419 100%);
}
.hero-overlay {
  position: absolute; inset: 0;
  background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='80' height='80' viewBox='0 0 80 80'><g fill='none' stroke='%23D4A844' stroke-width='0.5' opacity='0.12'><path d='M40 5 L70 40 L40 75 L10 40 Z'/><path d='M40 20 L55 40 L40 60 L25 40 Z'/></g></svg>");
  background-repeat: repeat;
  z-index: 1;
  opacity: 0.6;
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
  font-size: clamp(28px, 4vw, 48px);
  font-weight: 400;
  line-height: 1.1;
  color: #FAF7F2;
  margin-bottom: 12px;
}
.meta {
  color: rgba(250, 247, 242, 0.55);
  font-family: 'Cormorant Garamond', serif;
  font-style: italic;
  font-size: 15px;
}

/* === CONTENT === */
.legal-content {
  max-width: 820px;
  margin: 0 auto;
  background: rgba(31, 74, 54, 0.5);
  border: 1px solid rgba(212, 168, 68, 0.22);
  padding: 50px 48px;
  border-radius: 22px;
}
.legal-content section { margin-bottom: 40px; }
.legal-content section:last-of-type { margin-bottom: 24px; }
.legal-content h2 {
  font-family: 'Cormorant Garamond', serif;
  font-weight: 500;
  font-size: 24px;
  color: #E8B96B;
  margin-bottom: 14px;
  padding-bottom: 10px;
  border-bottom: 1px solid rgba(212, 168, 68, 0.25);
}
.legal-content p {
  font-size: 15px;
  line-height: 1.75;
  color: rgba(250, 247, 242, 0.82);
  margin-bottom: 12px;
}
.legal-content ul {
  list-style: none;
  padding: 0;
  margin: 14px 0;
}
.legal-content ul li {
  padding: 7px 0 7px 22px;
  position: relative;
  color: rgba(250, 247, 242, 0.78);
  font-size: 14.5px;
  line-height: 1.6;
}
.legal-content ul li::before {
  content: '◆';
  position: absolute;
  left: 0;
  color: #D4A844;
  font-size: 11px;
  top: 11px;
}
.legal-content a {
  color: #E8B96B;
  font-weight: 500;
  text-decoration: underline;
  text-decoration-color: rgba(232, 185, 107, 0.4);
}
.legal-content a:hover { color: #FAF7F2; }
.legal-content strong { color: #FAF7F2; font-weight: 600; }

.nav-legal {
  margin-top: 30px;
  padding-top: 24px;
  border-top: 1px solid rgba(212, 168, 68, 0.22);
}
.nav-legal a {
  color: #E8B96B;
  font-weight: 600;
  text-decoration: none;
  font-size: 14px;
  letter-spacing: 0.03em;
  transition: color 0.2s;
}
.nav-legal a:hover { color: #FAF7F2; }

@media (max-width: 600px) {
  .djawal-container { padding: 0 20px; }
  .page-hero { min-height: 30vh; padding: 90px 16px 36px; }
  .djawal-section { padding: 45px 0; }
  .legal-content { padding: 28px 22px; }
  .legal-content h2 { font-size: 21px; }
  .legal-content p { font-size: 14.5px; }
  .legal-content ul li {
    padding: 6px 0 6px 18px;
    font-size: 14px;
  }
}
@media (max-width: 380px) {
  .page-hero h1 { font-size: 26px; line-height: 1.15; }
}
</style>
