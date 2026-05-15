<script setup lang="ts">
import { useSEO } from '@/composables/useSEO'

useSEO({
  title: 'À propos — Djawal',
  description: 'Djawal — la plateforme communautaire du tourisme algérien. Une équipe, une démarche, une charte de qualité.'
})
</script>

<template>
  <div class="about-page">

    <!-- HERO COMPACT V4 -->
    <header class="page-hero">
      <div class="hero-overlay"></div>
      <div class="djawal-container hero-content">
        <div class="hero-eyebrow">
          <span class="eyebrow-line"></span>
          <span>À propos de Djawal</span>
          <span class="eyebrow-line"></span>
        </div>
        <h1>L'Algérie comme <em>une invitation</em></h1>
        <p class="lead">
          Une plateforme communautaire de tourisme algérien, pensée et créée en
          Algérie, pour les voyageurs et les ambassadeurs locaux qui font la richesse
          de notre patrimoine.
        </p>
      </div>
    </header>

    <!-- CONTENU -->
    <main class="about-main">
      <div class="djawal-container about-grid">

        <!-- Démarche -->
        <section class="about-section">
          <div class="section-eyebrow">Notre démarche</div>
          <h2>Un tourisme qui <em>tisse du lien</em></h2>
          <p>
            Nous croyons que le tourisme local ne se résume pas à un catalogue d'hébergements
            et de sites — c'est un échange humain, une transmission, une mémoire partagée.
            Djawal réunit trois acteurs : des voyageurs en quête d'authenticité, des guides qui
            connaissent leur région mieux que personne, et une équipe de modération qui veille
            à la qualité de chaque proposition.
          </p>
        </section>

        <!-- Charte -->
        <section class="about-section" id="charte">
          <div class="section-eyebrow">Charte de qualité</div>
          <h2>Chaque voyage <em>vérifié</em></h2>
          <p>
            Les guides certifiés (Senior) publient directement, les guides débutants (Junior)
            passent par une validation manuelle. Aucun voyage incomplet ne s'affiche sur la
            vitrine. Djawal IA ne propose que des ressources réellement validées — pas de
            fantôme, pas d'invention.
          </p>
        </section>

        <!-- Trois piliers -->
        <section class="about-section pillars-section">
          <div class="section-eyebrow">Trois piliers</div>
          <h2>Une plateforme <em>à trois voix</em></h2>
          <div class="pillars-grid">
            <article class="pillar-card">
              <div class="pillar-icon">✦</div>
              <h3>Voyageurs</h3>
              <p>Des passionnés d'Algérie en quête d'expériences authentiques, loin des circuits standardisés.</p>
            </article>
            <article class="pillar-card">
              <div class="pillar-icon">✦</div>
              <h3>Guides locaux</h3>
              <p>Des ambassadeurs de leur région — Sahara, Méditerranée, Kabylie, Aurès — qui transmettent leur savoir.</p>
            </article>
            <article class="pillar-card">
              <div class="pillar-icon">✦</div>
              <h3>Modération</h3>
              <p>Une équipe Djawal qui vérifie, accompagne, et garantit la qualité du catalogue éditorial.</p>
            </article>
          </div>
        </section>

      </div>
    </main>
  </div>
</template>

<style scoped>
.about-page {
  background: linear-gradient(180deg, #0F2419 0%, #1A3A2A 60%, #0F2419 100%);
  min-height: 100vh;
  color: #FAF7F2;
  font-family: 'Inter', sans-serif;
}
.djawal-container { max-width: 1080px; margin: 0 auto; padding: 0 32px; }

/* === HERO COMPACT V4 === */
.page-hero {
  position: relative;
  min-height: 50vh;
  display: flex; align-items: center; justify-content: center;
  text-align: center;
  padding: 120px 32px 70px;
  overflow: hidden;
  background-image: url('https://images.pexels.com/photos/3290072/pexels-photo-3290072.jpeg?auto=compress&cs=tinysrgb&w=1920');
  background-size: cover;
  background-position: center;
}
.hero-overlay {
  position: absolute; inset: 0;
  background: linear-gradient(180deg, rgba(15, 36, 25, 0.6) 0%, rgba(15, 36, 25, 0.88) 60%, #0F2419 100%);
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
  font-size: clamp(36px, 5.5vw, 64px);
  font-weight: 400; line-height: 1.05;
  margin-bottom: 22px;
  color: #FAF7F2;
}
.page-hero h1 em { font-style: italic; color: #E8B96B; }
.lead {
  font-family: 'Cormorant Garamond', serif;
  font-style: italic;
  font-size: clamp(17px, 2vw, 21px);
  color: rgba(250, 247, 242, 0.82);
  max-width: 680px; margin: 0 auto;
  line-height: 1.55;
}

/* === MAIN === */
.about-main { padding: 90px 0 120px; }
.about-grid {
  display: flex;
  flex-direction: column;
  gap: 70px;
}

.about-section { max-width: 760px; margin: 0 auto; }
.section-eyebrow {
  color: #E8B96B;
  font-size: 11px; font-weight: 600;
  letter-spacing: 0.24em; text-transform: uppercase;
  margin-bottom: 12px;
}
.about-section h2 {
  font-family: 'Cormorant Garamond', serif;
  font-size: clamp(28px, 3.5vw, 42px);
  font-weight: 400;
  line-height: 1.1;
  margin-bottom: 22px;
  color: #FAF7F2;
}
.about-section h2 em { font-style: italic; color: #E8B96B; }
.about-section p {
  font-size: 16.5px;
  color: rgba(250, 247, 242, 0.82);
  line-height: 1.7;
  margin-bottom: 14px;
}

/* === PILIERS === */
.pillars-section { max-width: none; }
.pillars-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: 22px;
  margin-top: 30px;
}
.pillar-card {
  background: rgba(31, 74, 54, 0.5);
  border: 1px solid rgba(212, 168, 68, 0.22);
  border-radius: 18px;
  padding: 32px 28px;
  text-align: center;
  transition: all 0.3s;
}
.pillar-card:hover {
  background: rgba(31, 74, 54, 0.75);
  border-color: rgba(212, 168, 68, 0.55);
  transform: translateY(-4px);
  box-shadow: 0 14px 38px rgba(0, 0, 0, 0.45);
}
.pillar-icon {
  font-size: 26px;
  color: #E8B96B;
  margin-bottom: 18px;
}
.pillar-card h3 {
  font-family: 'Cormorant Garamond', serif;
  font-size: 24px;
  font-weight: 500;
  font-style: italic;
  color: #FAF7F2;
  margin-bottom: 12px;
}
.pillar-card p {
  font-size: 14.5px;
  color: rgba(250, 247, 242, 0.75);
  line-height: 1.6;
  margin: 0;
}

@media (max-width: 700px) {
  .djawal-container { padding: 0 20px; }
  .page-hero { min-height: 38vh; padding: 90px 20px 50px; }
  .about-main { padding: 60px 0 80px; }
  .about-grid { gap: 50px; }
  .pillar-card { padding: 28px 22px; }
}
</style>
