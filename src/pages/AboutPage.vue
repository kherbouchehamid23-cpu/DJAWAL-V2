<script setup lang="ts"></script>

<template>
  <div class="djawal-container djawal-section">
    <div class="about-content">
      <div class="section-eyebrow">À propos</div>
      <h1>Djawal — l'Algérie comme une invitation.</h1>
      <p class="lead">
        Djawal est une plateforme communautaire de tourisme algérien, pensée et créée en
        Algérie, pour les voyageurs et les ambassadeurs locaux qui font la richesse de
        notre patrimoine.
      </p>

      <div class="djawal-divider-rhombus"><span></span></div>

      <h2>Notre démarche</h2>
      <p>
        Nous croyons que le tourisme local ne se résume pas à un catalogue d'hôtels et de
        sites — c'est un échange humain, une transmission, une mémoire partagée. Djawal
        réunit trois acteurs : des voyageurs en quête d'authenticité, des guides qui
        connaissent leur région mieux que personne, et une équipe de modération qui
        veille à la qualité de chaque proposition.
      </p>

      <h2 id="charte">Charte de qualité</h2>
      <p>
        Chaque voyage publié sur Djawal est vérifié. Les guides certifiés (Senior)
        publient directement, les guides débutants (Junior) passent par une validation
        manuelle. Aucun voyage incomplet ne s'affiche sur la vitrine. L'IA Djawal ne
        propose que des ressources réellement validées — pas de fantôme, pas
        d'invention.
      </p>
    </div>
  </div>
</template>

<style scoped>
.about-content { max-width: 720px; margin: 0 auto; }
.section-eyebrow {
  color: var(--c-accent-fort); font-size: 13px;
  letter-spacing: 0.2em; text-transform: uppercase; font-weight: 700;
  margin-bottom: var(--space-3);
}
h1 { font-size: clamp(36px, 5vw, 56px); margin-bottom: var(--space-4); }
h2 { font-size: 28px; margin: var(--space-7) 0 var(--space-3); }
.lead { font-size: 19px; color: var(--c-primaire); }
p { margin-bottom: var(--space-3); color: var(--c-texte); }
</style>
