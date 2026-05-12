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
      <div class="djawal-container">
        <div class="eyebrow">{{ type === 'cgu' ? 'CGU' : 'Mentions légales' }}</div>
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
          <p>Les photographies et descriptions des sites, hôtels et restaurants sont fournies par notre communauté de guides et de voyageurs. Chaque contributeur conserve les droits sur le contenu qu'il publie tout en accordant à Djawal une licence non-exclusive d'utilisation pour la promotion de la plateforme.</p>
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
          <p>Djawal propose un assistant IA qui s'appuie sur le catalogue communautaire pour suggérer des parcours, hôtels et sites. Ces recommandations sont à titre indicatif. Aucune réservation n'est garantie par l'IA. Vérifiez toujours la disponibilité directement avec le prestataire.</p>
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
.legal-page { background: var(--c-fond); min-height: 100vh; }

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
  font-size: clamp(28px, 4vw, 44px);
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-2);
  position: relative;
}
.meta { color: var(--c-texte-doux); font-size: 14px; position: relative; }

.legal-content {
  max-width: 800px;
  margin: 0 auto;
  background: var(--c-surface);
  padding: var(--space-6);
  border-radius: var(--r-lg);
  box-shadow: var(--ombre-douce);
}
.legal-content section { margin-bottom: var(--space-5); }
.legal-content h2 {
  font-family: var(--font-display);
  font-size: 22px;
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-2);
  padding-bottom: 6px;
  border-bottom: 2px solid var(--c-fond-chaud);
}
.legal-content p {
  font-size: 15px;
  line-height: 1.7;
  color: var(--c-texte);
  margin-bottom: var(--space-2);
}
.legal-content ul {
  list-style: none;
  padding: 0;
  margin: var(--space-2) 0;
}
.legal-content ul li {
  padding: 6px 0 6px 20px;
  position: relative;
  color: var(--c-texte);
  font-size: 14px;
  line-height: 1.6;
}
.legal-content ul li::before {
  content: '◆';
  position: absolute;
  left: 0;
  color: var(--c-accent);
}
.legal-content a { color: var(--c-accent-fort); font-weight: 600; }
.legal-content strong { color: var(--c-primaire-profond); }

.nav-legal {
  margin-top: var(--space-5);
  padding-top: var(--space-4);
  border-top: 2px solid var(--c-fond-chaud);
}
.nav-legal a {
  color: var(--c-primaire);
  font-weight: 700;
  text-decoration: none;
}
.nav-legal a:hover { text-decoration: underline; }
</style>
