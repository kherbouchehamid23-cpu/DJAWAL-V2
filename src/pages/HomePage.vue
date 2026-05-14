<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useBreakpoint } from '@/composables/useBreakpoint'
import { useSEO } from '@/composables/useSEO'

useSEO({
  title: 'L\'Algérie, vécue de l\'intérieur',
  description: 'Du cœur de la Casbah aux dunes du Tassili. Connectez-vous avec les habitants ou laissez Fennec, notre IA, composer votre aventure sur-mesure.'
})

const router = useRouter()
const { isMobile } = useBreakpoint()

const stats = ref({ travellers: 12000, guides: 450 })
const aiInput = ref('')

onMounted(async () => {
  // Stats agrégées depuis Supabase (non bloquant)
  // Le fallback 450 reste tant qu'on n'a pas un nombre significatif de guides validés
  const { count: guidesCount } = await supabase
    .from('profiles')
    .select('id', { count: 'exact', head: true })
    .in('role', ['guide_senior', 'guide_junior'])
    .eq('kyc_status', 'approved')
  if (guidesCount && guidesCount >= 50) stats.value.guides = guidesCount
})

function goToComposer(prefill?: string) {
  if (prefill) router.push({ path: '/composer', query: { q: prefill } })
  else router.push('/composer')
}

function submitAI() {
  const q = aiInput.value.trim()
  goToComposer(q || undefined)
}

const categories = [
  {
    key: 'sahara',
    title: 'Magie du Sahara',
    sub: 'Bivouac · 4×4 · Tassili',
    count: '120+ guides',
    arab: 'ⵜⵉⵏⵉⵔⵉ',
    iconPath: 'M4 36 Q 12 28, 20 36 T 36 36 T 52 36 M14 18 a 4 4 0 0 1 8 0 a 4 4 0 0 1 8 0',
    query: 'theme=saharien'
  },
  {
    key: 'casbah',
    title: 'Héritage & Casbah',
    sub: 'Ruelles · histoire · architecture',
    count: '85+ expériences',
    arab: 'قصبة',
    iconPath: 'M8 36 L8 18 L14 18 L14 14 L18 10 L22 14 L22 18 L28 18 L28 36 Z M16 24 L20 24 L20 32 L16 32 Z',
    query: 'theme=mauresque'
  },
  {
    key: 'saveurs',
    title: 'Tables algériennes',
    sub: 'Couscous · thé à la menthe · zaafrane',
    count: '200+ hôtes',
    arab: 'مطبخ',
    iconPath: 'M18 6 L18 14 M14 6 L14 14 M22 6 L22 14 M14 14 L22 14 L22 18 L14 18 Z M14 18 L22 18 L20 32 L16 32 Z',
    query: 'theme=aures'
  }
]

const quickPrompts = [
  { label: 'Sahara 7 jours', q: '7 jours dans le Sahara, bivouac et étoiles' },
  { label: 'Casbah famille', q: 'Week-end famille dans la Casbah d\'Alger' },
  { label: 'Trek Djurdjura', q: '4 jours de trek dans le Djurdjura' },
  { label: 'Saveurs kabyles', q: 'Voyage gastronomique en Kabylie' }
]

function fmtNumber(n: number) {
  return new Intl.NumberFormat('fr-FR').format(n)
}
</script>

<template>
  <div class="home">

    <!-- ================================================================ -->
    <!-- HERO — titre éditorial + 3 cards latérales                       -->
    <!-- ================================================================ -->
    <section class="hero">
      <div class="hero-inner djawal-container">

        <!-- Colonne gauche : texte -->
        <div class="hero-left">
          <div class="hero-eyebrow">
            <span class="eyebrow-spark" aria-hidden="true">✦</span>
            <span class="arabic">مرحبا بكم</span>
            <span class="eyebrow-divider">·</span>
            <span class="eyebrow-text">MARHABA BIKOUM</span>
          </div>

          <h1 class="hero-title">
            L'Algérie,<br>
            <em>vécue de l'intérieur.</em>
          </h1>

          <p class="hero-sub">
            Du cœur de la Casbah aux dunes du Tassili. Connectez-vous
            avec les habitants ou laissez Fennec, notre IA,
            composer votre aventure sur-mesure.
          </p>

          <div class="hero-ctas">
            <router-link to="/voyages" class="btn btn-primary">
              Explorer les expériences
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M5 12 L19 12 M13 5 L20 12 L13 19" stroke-linecap="round" stroke-linejoin="round"/></svg>
            </router-link>
            <button class="btn btn-ghost" @click="goToComposer()">
              <svg class="fennec-icon" viewBox="0 0 64 64" fill="currentColor" aria-hidden="true">
                <path d="M14 28 C 10 16, 14 4, 20 6 C 22 14, 24 22, 26 28 Z"/>
                <path d="M50 28 C 54 16, 50 4, 44 6 C 42 14, 40 22, 38 28 Z"/>
                <ellipse cx="32" cy="38" rx="13" ry="12"/>
                <circle cx="26" cy="36" r="1.6" fill="#0A1F2E"/>
                <circle cx="38" cy="36" r="1.6" fill="#0A1F2E"/>
                <circle cx="32" cy="44" r="1.4" fill="#0A1F2E"/>
              </svg>
              Composer avec Fennec
            </button>
          </div>

          <div class="hero-stats">
            <span class="stats-dots" aria-hidden="true">
              <span class="dot dot-1">A</span>
              <span class="dot dot-2">Y</span>
              <span class="dot dot-3">L</span>
            </span>
            <span class="stats-num">{{ fmtNumber(stats.travellers) }}+</span> voyageurs
            <span class="stats-sep">·</span>
            <span class="stats-num">{{ fmtNumber(stats.guides) }}</span> guides locaux
          </div>
        </div>

        <!-- Colonne droite : 3 cards -->
        <div class="hero-cards">
          <article class="hcard hcard-tassili" @click="router.push('/voyages?theme=saharien')">
            <div class="hcard-tif arabic">ⵜⵉⵏⵉⵔⵉ</div>
            <svg class="hcard-figures" viewBox="0 0 80 80" fill="rgba(250,247,242,0.85)" aria-hidden="true">
              <path d="M28 50 L28 32 L26 26 L28 22 L31 22 L33 26 L31 32 L31 50 Z"/>
              <circle cx="29.5" cy="18" r="3"/>
              <path d="M48 52 L48 30 L46 24 L48 20 L52 20 L54 24 L52 30 L52 52 Z"/>
              <circle cx="50" cy="16" r="3"/>
            </svg>
            <div class="hcard-body">
              <div class="hcard-title">Tassili n'Ajjer</div>
              <div class="hcard-sub">Djanet · <span class="arabic">طاسيلي</span></div>
              <div class="hcard-foot">
                <span class="hcard-avatar">A</span>
                <span>Guide · Aïssa</span>
              </div>
            </div>
          </article>

          <article class="hcard hcard-casbah" @click="router.push('/voyages?theme=mauresque')">
            <div class="hcard-badge">UNESCO · 1992</div>
            <div class="hcard-body">
              <div class="hcard-title">Casbah<br>d'Alger</div>
              <div class="hcard-sub arabic">قصبة الجزائر</div>
            </div>
          </article>

          <article class="hcard hcard-fennec" @click="goToComposer()">
            <div class="hcard-fennec-pill">IA</div>
            <div class="hcard-fennec-mark">
              <svg viewBox="0 0 64 64" fill="currentColor" aria-hidden="true">
                <path d="M14 28 C 10 16, 14 4, 20 6 C 22 14, 24 22, 26 28 Z"/>
                <path d="M50 28 C 54 16, 50 4, 44 6 C 42 14, 40 22, 38 28 Z"/>
                <ellipse cx="32" cy="38" rx="13" ry="12"/>
                <circle cx="26" cy="36" r="1.6" fill="#0A1F2E"/>
                <circle cx="38" cy="36" r="1.6" fill="#0A1F2E"/>
                <circle cx="32" cy="44" r="1.4" fill="#0A1F2E"/>
              </svg>
            </div>
            <div class="hcard-body">
              <div class="hcard-title hcard-title-fennec"><em>Fennec,</em><br>votre guide IA</div>
              <p class="hcard-fennec-text">Décrivez votre mood,<br>il dessine votre voyage.</p>
            </div>
          </article>
        </div>
      </div>
    </section>

    <!-- ================================================================ -->
    <!-- CATÉGORIES — L'âme algérienne                                    -->
    <!-- ================================================================ -->
    <section class="categories">
      <div class="djawal-container">
        <header class="cat-head">
          <h2>L'âme algérienne <em>— que cherchez-vous ?</em></h2>
          <router-link to="/voyages" class="cat-link">
            Voir toutes les expériences
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M5 12 L19 12 M13 5 L20 12 L13 19" stroke-linecap="round"/></svg>
          </router-link>
        </header>

        <div class="cat-grid">
          <button
            v-for="c in categories"
            :key="c.key"
            class="cat-card"
            @click="router.push(`/voyages?${c.query}`)"
          >
            <div class="cat-icon">
              <svg viewBox="0 0 36 36" fill="none" stroke="currentColor" stroke-width="1.6" aria-hidden="true">
                <path :d="c.iconPath" />
              </svg>
            </div>
            <div class="cat-arab arabic">{{ c.arab }}</div>
            <h3>{{ c.title }}</h3>
            <p>{{ c.sub }}</p>
            <span class="cat-count">{{ c.count }}<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 6 L15 12 L9 18" stroke-linecap="round"/></svg></span>
          </button>
        </div>
      </div>
    </section>

    <!-- ================================================================ -->
    <!-- ÉDITORIAL — Le Sahara, où le silence apprend à parler            -->
    <!-- ================================================================ -->
    <section class="editorial">
      <div class="djawal-container editorial-inner">

        <div class="editorial-text">
          <div class="editorial-eyebrow">
            <span class="arabic">ⵜⵉⵏⵉⵔⵉ</span>
            <span class="editorial-divider"></span>
            <span>Le désert raconté</span>
          </div>

          <h2 class="editorial-title">
            Le Sahara —<br>
            <em>où le silence apprend à parler.</em>
          </h2>

          <p>
            Quarante pour cent du pays sont sable. Le Hoggar, le Tassili, le M'Zab — chacun avec son
            propre tempo, sa propre cosmologie. Les Touaregs y vivent depuis trois mille ans, gardiens
            d'un langage que les peintures rupestres murmurent encore.
          </p>
          <p>
            Fennec vous y conduit avec ceux qui en parlent la langue.
          </p>

          <blockquote class="editorial-quote">
            « Celui qui marche dans le désert n'avance pas — il se laisse traverser par lui. »
            <cite>Proverbe touareg · Hoggar</cite>
          </blockquote>
        </div>

        <article class="editorial-card">
          <div class="ec-tif arabic">ⵜⵉⵏⵉⵔⵉ</div>
          <div class="ec-body">
            <div class="ec-title">Tassili n'Ajjer</div>
            <div class="ec-sub">Wilaya d'Illizi</div>
          </div>
          <div class="ec-scene" aria-hidden="true">
            <svg viewBox="0 0 200 120" fill="none">
              <path d="M0 90 Q 50 70, 100 80 T 200 70 L 200 120 L 0 120 Z" fill="rgba(139, 74, 44, 0.7)"/>
              <path d="M0 100 Q 60 88, 120 95 T 200 90 L 200 120 L 0 120 Z" fill="rgba(74, 39, 22, 0.8)"/>
              <g fill="rgba(20, 12, 8, 0.9)">
                <path d="M88 92 L88 78 L86 72 L88 68 L91 68 L93 72 L91 78 L91 92 Z"/>
                <circle cx="89.5" cy="64" r="2.5"/>
                <path d="M108 96 L108 76 L106 70 L108 66 L112 66 L114 70 L112 76 L112 96 Z"/>
                <circle cx="110" cy="62" r="2.5"/>
              </g>
            </svg>
          </div>
          <div class="ec-foot">
            <div class="ec-avatar">AT</div>
            <div>
              <strong>Aïssa Touareg</strong>
              <small>12 ans · Djanet</small>
            </div>
          </div>
        </article>
      </div>
    </section>

    <!-- ================================================================ -->
    <!-- FENNEC — carte verte avec input                                  -->
    <!-- ================================================================ -->
    <section class="fennec-box">
      <div class="djawal-container">
        <div class="fb-card">
          <div class="fb-eyebrow">
            <span class="fb-divider"></span>
            VOTRE VOYAGE SUR-MESURE
            <span class="fb-divider"></span>
          </div>

          <h2 class="fb-title">
            <span class="fb-fennec-name">Fennec</span>, à votre écoute.
          </h2>

          <p class="fb-sub">
            Décrivez simplement vos envies — « une retraite silencieuse dans le Tassili
            avec de la gastronomie locale » ou « un road-trip côtier d'Oran à Annaba ».
            Fennec compose le circuit, choisit les guides, propose le rythme.
          </p>

          <form class="fb-form" @submit.prevent="submitAI">
            <span class="fb-input-icon" aria-hidden="true">
              <svg viewBox="0 0 64 64" fill="currentColor">
                <path d="M14 28 C 10 16, 14 4, 20 6 C 22 14, 24 22, 26 28 Z"/>
                <path d="M50 28 C 54 16, 50 4, 44 6 C 42 14, 40 22, 38 28 Z"/>
                <ellipse cx="32" cy="38" rx="13" ry="12"/>
                <circle cx="26" cy="36" r="1.6" fill="#0A1F2E"/>
                <circle cx="38" cy="36" r="1.6" fill="#0A1F2E"/>
                <circle cx="32" cy="44" r="1.4" fill="#0A1F2E"/>
              </svg>
            </span>
            <input
              v-model="aiInput"
              type="text"
              placeholder="Racontez-moi votre voyage idéal…"
              aria-label="Décrivez votre voyage"
            />
            <button type="submit" class="fb-submit">
              Générer
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M5 12 L19 12 M13 5 L20 12 L13 19" stroke-linecap="round" stroke-linejoin="round"/></svg>
            </button>
          </form>

          <div class="fb-prompts">
            <button
              v-for="p in quickPrompts"
              :key="p.label"
              type="button"
              class="fb-prompt"
              @click="goToComposer(p.q)"
            >{{ p.label }}</button>
          </div>
        </div>
      </div>
    </section>

  </div>
</template>

<style scoped>
.home {
  background: var(--c-fond, #FAF7F2);
  min-height: 100vh;
  padding-bottom: 80px;
}
@media (min-width: 640px) {
  .home { padding-bottom: 0; }
}

.djawal-container {
  max-width: 1180px;
  margin: 0 auto;
  padding: 0 20px;
}
@media (min-width: 640px) {
  .djawal-container { padding: 0 32px; }
}

/* =============================================================== */
/* HERO                                                            */
/* =============================================================== */
.hero {
  background: linear-gradient(180deg, #F5EFDF 0%, #FAF7F2 100%);
  padding: 32px 0 56px;
  position: relative;
  overflow: hidden;
}
.hero::before {
  content: '';
  position: absolute;
  top: 0;
  right: -10%;
  width: 70%;
  height: 100%;
  background-image: radial-gradient(ellipse at top right, rgba(45, 90, 61, 0.06), transparent 60%);
  pointer-events: none;
}
.hero-inner {
  position: relative;
  display: grid;
  grid-template-columns: 1fr;
  gap: 32px;
}
@media (min-width: 900px) {
  .hero-inner {
    grid-template-columns: 1.05fr 1fr;
    gap: 48px;
    align-items: center;
  }
}

.hero-eyebrow {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  padding: 7px 14px;
  background: rgba(250, 247, 242, 0.7);
  border: 1px solid rgba(212, 160, 79, 0.3);
  border-radius: 999px;
  font-size: 10px;
  letter-spacing: 0.18em;
  font-weight: 500;
  color: var(--c-accent-fort, #B8862E);
  margin-bottom: 24px;
}
.eyebrow-spark { color: #D4A04F; font-size: 12px; }
.eyebrow-divider { opacity: 0.5; }

.hero-title {
  font-family: var(--font-display, 'Cormorant Garamond', Georgia, serif);
  font-size: clamp(40px, 7vw, 68px);
  line-height: 1.02;
  margin: 0 0 20px;
  font-weight: 500;
  color: var(--c-primaire-profond, #0A1F2E);
  letter-spacing: -0.02em;
}
.hero-title em {
  font-style: italic;
  font-weight: 500;
  color: var(--c-accent-fort, #B8862E);
}

.hero-sub {
  font-size: 16px;
  line-height: 1.65;
  color: var(--c-texte, #444441);
  max-width: 480px;
  margin: 0 0 28px;
  font-weight: 400;
}
@media (min-width: 640px) {
  .hero-sub { font-size: 17px; }
}

.hero-ctas {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  margin-bottom: 28px;
}
.btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 13px 22px;
  border-radius: 999px;
  font-size: 14px;
  font-weight: 500;
  font-family: inherit;
  cursor: pointer;
  text-decoration: none;
  border: none;
  transition: transform 0.15s, box-shadow 0.15s;
}
.btn svg { width: 16px; height: 16px; }
.btn:hover { transform: translateY(-1px); }
.btn-primary {
  background: var(--c-primaire-profond, #0A1F2E);
  color: var(--c-fond, #FAF7F2);
}
.btn-ghost {
  background: transparent;
  color: var(--c-primaire-profond, #0A1F2E);
  border: 1px solid rgba(10, 31, 46, 0.18);
}
.btn-ghost .fennec-icon { width: 20px; height: 20px; color: var(--c-accent-fort, #B8862E); }
.btn-ghost:hover { background: rgba(212, 160, 79, 0.08); }

.hero-stats {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 8px 14px;
  background: rgba(255, 255, 255, 0.6);
  border-radius: 999px;
  font-size: 12px;
  color: var(--c-texte-doux, #6B6B6B);
  flex-wrap: wrap;
}
.stats-dots { display: inline-flex; margin-right: 4px; }
.dot {
  width: 22px; height: 22px;
  border-radius: 50%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 9px;
  font-weight: 600;
  color: #fff;
  font-family: var(--font-display, 'Cormorant Garamond', Georgia, serif);
}
.dot-1 { background: #D4A04F; }
.dot-2 { background: #2D5A3D; margin-left: -6px; }
.dot-3 { background: #1B4965; margin-left: -6px; }
.stats-num {
  font-family: var(--font-display, 'Cormorant Garamond', Georgia, serif);
  font-size: 14px;
  font-weight: 500;
  color: var(--c-primaire-profond, #0A1F2E);
}
.stats-sep { opacity: 0.4; margin: 0 4px; }

/* === Hero cards === */
.hero-cards {
  display: grid;
  grid-template-columns: 1fr 1fr;
  grid-template-rows: auto auto;
  gap: 12px;
}
@media (min-width: 640px) {
  .hero-cards { gap: 16px; }
}

.hcard {
  position: relative;
  border-radius: 20px;
  padding: 18px;
  cursor: pointer;
  border: none;
  text-align: left;
  font-family: inherit;
  overflow: hidden;
  transition: transform 0.25s;
  min-height: 220px;
  display: flex;
  flex-direction: column;
}
.hcard:hover { transform: translateY(-3px); }

/* Tassili — ocre */
.hcard-tassili {
  grid-column: 1 / 2;
  grid-row: 1 / 3;
  background: linear-gradient(165deg, #D4A04F 0%, #B8862E 50%, #8B4A2C 100%);
  color: #FAF7F2;
  min-height: 360px;
}
.hcard-tif {
  position: absolute;
  top: 14px; left: 14px;
  font-family: 'Noto Sans Tifinagh', 'Amiri', serif;
  font-size: 14px;
  letter-spacing: 0.18em;
  color: rgba(250, 247, 242, 0.55);
}
.hcard-figures {
  position: absolute;
  top: 38%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 60%;
  opacity: 0.85;
}
.hcard-body { margin-top: auto; position: relative; z-index: 2; }
.hcard-title {
  font-family: var(--font-display, 'Cormorant Garamond', Georgia, serif);
  font-size: 22px;
  font-weight: 500;
  line-height: 1.1;
  margin-bottom: 4px;
}
.hcard-sub {
  font-size: 11px;
  opacity: 0.85;
  margin-bottom: 12px;
  letter-spacing: 0.02em;
}
.hcard-foot {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 11px;
  opacity: 0.95;
  padding-top: 10px;
  border-top: 1px solid rgba(250, 247, 242, 0.18);
}
.hcard-avatar {
  width: 22px; height: 22px;
  border-radius: 50%;
  background: #FAF7F2;
  color: var(--c-primaire-profond, #0A1F2E);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  font-size: 10px;
  font-weight: 600;
  font-family: var(--font-display, 'Cormorant Garamond', Georgia, serif);
}

/* Casbah — navy */
.hcard-casbah {
  background: linear-gradient(165deg, #1B4965 0%, #0A1F2E 100%);
  color: #FAF7F2;
}
.hcard-badge {
  display: inline-block;
  font-size: 9px;
  letter-spacing: 0.18em;
  padding: 4px 9px;
  background: rgba(212, 160, 79, 0.22);
  color: #FFD479;
  border-radius: 999px;
  font-weight: 500;
  align-self: flex-start;
  margin-bottom: auto;
}
.hcard-casbah .hcard-title { font-size: 20px; }

/* Fennec — blanc */
.hcard-fennec {
  background: #FFFFFF;
  color: var(--c-primaire-profond, #0A1F2E);
  border: 1px solid rgba(10, 31, 46, 0.06);
}
.hcard-fennec-pill {
  position: absolute;
  top: 14px; right: 14px;
  width: 28px; height: 28px;
  border-radius: 50%;
  background: #2D5A3D;
  color: #E8B547;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.04em;
}
.hcard-fennec-mark {
  width: 38px; height: 38px;
  border-radius: 50%;
  background: linear-gradient(135deg, #FAF7F2, #F1ECE0);
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 14px;
  color: var(--c-accent-fort, #B8862E);
}
.hcard-fennec-mark svg { width: 24px; height: 24px; }
.hcard-title-fennec { font-size: 18px; }
.hcard-title-fennec em {
  font-style: italic;
  color: var(--c-accent-fort, #B8862E);
}
.hcard-fennec-text {
  font-size: 12px;
  color: var(--c-texte, #444441);
  margin: 6px 0 0;
  line-height: 1.5;
}

/* =============================================================== */
/* CATÉGORIES                                                      */
/* =============================================================== */
.categories {
  background: var(--c-fond, #FAF7F2);
  padding: 56px 0;
}
@media (min-width: 640px) { .categories { padding: 80px 0; } }

.cat-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  gap: 16px;
  flex-wrap: wrap;
  margin-bottom: 28px;
}
.cat-head h2 {
  font-family: var(--font-display, 'Cormorant Garamond', Georgia, serif);
  font-size: clamp(26px, 4.5vw, 38px);
  line-height: 1.1;
  font-weight: 500;
  color: var(--c-primaire-profond, #0A1F2E);
  margin: 0;
  max-width: 700px;
}
.cat-head h2 em {
  font-style: italic;
  color: var(--c-texte-doux, #6B6B6B);
  font-weight: 500;
}
.cat-link {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  font-weight: 500;
  color: var(--c-accent-fort, #B8862E);
  text-decoration: none;
}
.cat-link svg { width: 14px; height: 14px; }

.cat-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 14px;
}
@media (min-width: 640px) {
  .cat-grid { grid-template-columns: repeat(3, 1fr); gap: 18px; }
}

.cat-card {
  background: #FFFFFF;
  border: 1px solid rgba(10, 31, 46, 0.06);
  border-radius: 18px;
  padding: 24px;
  text-align: left;
  font-family: inherit;
  cursor: pointer;
  position: relative;
  transition: transform 0.2s, box-shadow 0.2s, border-color 0.2s;
}
.cat-card:hover {
  transform: translateY(-3px);
  box-shadow: 0 14px 32px rgba(10, 31, 46, 0.07);
  border-color: rgba(212, 160, 79, 0.3);
}
.cat-icon {
  width: 56px; height: 56px;
  border-radius: 50%;
  background: rgba(212, 160, 79, 0.1);
  color: var(--c-accent-fort, #B8862E);
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 18px;
}
.cat-icon svg { width: 28px; height: 28px; }
.cat-arab {
  font-family: 'Noto Sans Tifinagh', 'Amiri', serif;
  font-size: 11px;
  color: var(--c-accent-fort, #B8862E);
  letter-spacing: 0.18em;
  margin-bottom: 6px;
  opacity: 0.7;
}
.cat-card h3 {
  font-family: var(--font-display, 'Cormorant Garamond', Georgia, serif);
  font-size: 22px;
  font-weight: 500;
  color: var(--c-primaire-profond, #0A1F2E);
  margin: 0 0 6px;
  line-height: 1.15;
}
.cat-card p {
  font-size: 13px;
  color: var(--c-texte, #444441);
  margin: 0 0 14px;
  line-height: 1.5;
}
.cat-count {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  font-weight: 500;
  color: var(--c-accent-fort, #B8862E);
  letter-spacing: 0.02em;
}
.cat-count svg { width: 12px; height: 12px; }

/* =============================================================== */
/* ÉDITORIAL                                                       */
/* =============================================================== */
.editorial {
  background: #F5EFE2;
  padding: 64px 0;
  position: relative;
}
@media (min-width: 640px) { .editorial { padding: 96px 0; } }

.editorial-inner {
  display: grid;
  grid-template-columns: 1fr;
  gap: 36px;
  align-items: start;
}
@media (min-width: 900px) {
  .editorial-inner { grid-template-columns: 1.05fr 1fr; gap: 56px; }
}

.editorial-eyebrow {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  font-size: 11px;
  letter-spacing: 0.22em;
  color: var(--c-accent-fort, #B8862E);
  font-weight: 500;
  margin-bottom: 18px;
  text-transform: uppercase;
}
.editorial-divider {
  width: 24px;
  height: 1px;
  background: var(--c-accent-fort, #B8862E);
  opacity: 0.5;
}
.editorial-title {
  font-family: var(--font-display, 'Cormorant Garamond', Georgia, serif);
  font-size: clamp(30px, 5vw, 46px);
  line-height: 1.05;
  font-weight: 500;
  margin: 0 0 24px;
  color: var(--c-primaire-profond, #0A1F2E);
  letter-spacing: -0.015em;
}
.editorial-title em {
  font-style: italic;
  color: var(--c-accent-fort, #B8862E);
  font-weight: 500;
}
.editorial-text p {
  font-size: 15px;
  line-height: 1.75;
  color: var(--c-texte, #444441);
  margin: 0 0 16px;
}
.editorial-quote {
  font-family: var(--font-display, 'Cormorant Garamond', Georgia, serif);
  font-style: italic;
  font-size: 17px;
  line-height: 1.5;
  color: var(--c-primaire-profond, #0A1F2E);
  border-left: 2px solid var(--c-accent, #D4A04F);
  padding: 8px 0 8px 20px;
  margin: 24px 0 0;
}
.editorial-quote cite {
  display: block;
  font-style: normal;
  font-family: 'Inter', sans-serif;
  font-size: 10px;
  letter-spacing: 0.22em;
  color: var(--c-accent-fort, #B8862E);
  margin-top: 10px;
  text-transform: uppercase;
}

.editorial-card {
  background: linear-gradient(180deg, #F5BD7C 0%, #D4A04F 40%, #8B4A2C 100%);
  border-radius: 24px;
  overflow: hidden;
  position: relative;
  min-height: 480px;
  display: flex;
  flex-direction: column;
}
.ec-tif {
  position: absolute;
  top: 18px;
  left: 18px;
  font-family: 'Noto Sans Tifinagh', 'Amiri', serif;
  font-size: 13px;
  letter-spacing: 0.18em;
  color: rgba(250, 247, 242, 0.7);
}
.ec-body {
  padding: 56px 24px 0;
  color: #FAF7F2;
}
.ec-title {
  font-family: var(--font-display, 'Cormorant Garamond', Georgia, serif);
  font-size: 28px;
  font-weight: 500;
  line-height: 1;
}
.ec-sub {
  font-size: 11px;
  letter-spacing: 0.18em;
  opacity: 0.85;
  margin-top: 6px;
  text-transform: uppercase;
}
.ec-scene {
  flex: 1;
  display: flex;
  align-items: flex-end;
  margin: 24px -8px 0;
}
.ec-scene svg { width: 100%; }
.ec-foot {
  background: rgba(10, 31, 46, 0.4);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  padding: 12px 18px;
  display: flex;
  align-items: center;
  gap: 10px;
  color: #FAF7F2;
}
.ec-avatar {
  width: 32px; height: 32px;
  border-radius: 50%;
  background: rgba(250, 247, 242, 0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  font-weight: 600;
  font-family: var(--font-display, 'Cormorant Garamond', Georgia, serif);
}
.ec-foot strong {
  display: block;
  font-size: 13px;
  font-weight: 500;
  line-height: 1.2;
}
.ec-foot small {
  font-size: 10px;
  opacity: 0.85;
  letter-spacing: 0.04em;
}

/* =============================================================== */
/* FENNEC BOX                                                      */
/* =============================================================== */
.fennec-box {
  padding: 64px 0;
  background: var(--c-fond, #FAF7F2);
}
@media (min-width: 640px) { .fennec-box { padding: 96px 0 80px; } }

.fb-card {
  background: linear-gradient(165deg, #1B3A28 0%, #2D5A3D 60%, #1B3A28 100%);
  border-radius: 28px;
  padding: 48px 28px;
  color: #FAF7F2;
  position: relative;
  overflow: hidden;
}
.fb-card::before {
  content: '';
  position: absolute;
  top: -120px; right: -120px;
  width: 380px; height: 380px;
  background: radial-gradient(circle, rgba(212, 160, 79, 0.18) 0%, transparent 60%);
  border-radius: 50%;
  pointer-events: none;
}
@media (min-width: 640px) { .fb-card { padding: 64px 56px; } }

.fb-eyebrow {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  font-size: 11px;
  letter-spacing: 0.22em;
  color: rgba(232, 181, 71, 0.85);
  margin-bottom: 18px;
  font-weight: 500;
}
.fb-divider {
  width: 28px;
  height: 1px;
  background: rgba(232, 181, 71, 0.4);
}

.fb-title {
  font-family: var(--font-display, 'Cormorant Garamond', Georgia, serif);
  font-size: clamp(28px, 5vw, 44px);
  line-height: 1.1;
  text-align: center;
  font-weight: 500;
  margin: 0 0 18px;
  letter-spacing: -0.015em;
}
.fb-fennec-name {
  font-style: italic;
  color: #E8B547;
}

.fb-sub {
  text-align: center;
  font-size: 15px;
  line-height: 1.65;
  color: rgba(250, 247, 242, 0.82);
  max-width: 640px;
  margin: 0 auto 28px;
}

.fb-form {
  display: flex;
  align-items: center;
  gap: 6px;
  background: rgba(250, 247, 242, 0.08);
  border: 1px solid rgba(232, 181, 71, 0.3);
  border-radius: 999px;
  padding: 4px 4px 4px 18px;
  max-width: 580px;
  margin: 0 auto 18px;
  position: relative;
  z-index: 2;
}
.fb-input-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: #E8B547;
  flex-shrink: 0;
}
.fb-input-icon svg { width: 22px; height: 22px; }

.fb-form input {
  flex: 1;
  background: transparent;
  border: none;
  outline: none;
  color: #FAF7F2;
  font-size: 14px;
  font-family: inherit;
  padding: 12px 8px;
  min-width: 0;
}
.fb-form input::placeholder {
  color: rgba(250, 247, 242, 0.5);
  font-style: italic;
}

.fb-submit {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 10px 18px;
  background: linear-gradient(135deg, #E8B547, #B8862E);
  color: var(--c-primaire-profond, #0A1F2E);
  border: none;
  border-radius: 999px;
  font-weight: 500;
  font-size: 13px;
  font-family: inherit;
  cursor: pointer;
  flex-shrink: 0;
  transition: transform 0.15s;
}
.fb-submit:hover { transform: scale(1.03); }
.fb-submit svg { width: 14px; height: 14px; }

.fb-prompts {
  display: flex;
  justify-content: center;
  gap: 6px;
  flex-wrap: wrap;
  max-width: 580px;
  margin: 0 auto;
  position: relative;
  z-index: 2;
}
.fb-prompt {
  background: rgba(250, 247, 242, 0.06);
  border: 1px solid rgba(250, 247, 242, 0.14);
  color: rgba(250, 247, 242, 0.9);
  padding: 8px 14px;
  border-radius: 999px;
  font-size: 12px;
  font-family: inherit;
  cursor: pointer;
  transition: background 0.15s;
}
.fb-prompt:hover {
  background: rgba(232, 181, 71, 0.15);
  border-color: rgba(232, 181, 71, 0.4);
}
</style>
