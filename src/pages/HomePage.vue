<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'
import { useBreakpoint } from '@/composables/useBreakpoint'
import { useSEO } from '@/composables/useSEO'
import MemoriesCarousel from '@/components/MemoriesCarousel.vue'

useSEO({
  title: 'Voyager l\'Algérie autrement',
  description: 'Du Tassili au Djurdjura, sept traditions vous donnent rendez-vous. Composez votre parcours sur mesure avec notre intelligence puisée dans le catalogue des guides locaux.'
})

const router = useRouter()
const auth = useAuthStore()
const { isMobile } = useBreakpoint()

// === Données dynamiques ===
interface Souffle {
  key: string
  arab: string
  tifinagh?: string
  name: string
  sub: string
  theme: 'saharien' | 'mauresque' | 'aures'
  query: string
  count: number
  symbolPath: string
}

interface PublishedTrip {
  id: string
  title: string
  duration_days: number
  price_da: number
  cover_image_url: string | null
  destinations?: { name: string; cultural_theme: string } | null
  profiles?: { display_name: string; role: string; avatar_url: string | null } | null
  avg_rating?: number
}

interface Review {
  id: string
  rating: number
  comment: string | null
  created_at: string
  profiles?: { display_name: string; region: string | null } | null
}

const trips = ref<PublishedTrip[]>([])
const reviews = ref<Review[]>([])
const stats = ref({ destinations: 58, trips: 0, guides: 0, avgRating: '—' })
const themePhotos = ref<Record<string, string>>({ saharien: '', mauresque: '', aures: '' })
const loading = ref(true)
const aiInput = ref('')

// === Souffles statiques (les ambiances proposées) ===
const souffles: Souffle[] = [
  {
    key: 'desert',
    arab: 'صحراء',
    tifinagh: 'ⵜⵉⵏⵉⵔⵉ',
    name: 'Désert profond',
    sub: 'Tassili · Hoggar · Djanet',
    theme: 'saharien',
    query: 'theme=saharien',
    count: 0,
    symbolPath: 'M24 4 L28 18 L42 20 L31 30 L34 44 L24 36 L14 44 L17 30 L6 20 L20 18 Z'
  },
  {
    key: 'casbah',
    arab: 'قصبة',
    name: 'Casbahs ottomanes',
    sub: 'Alger · Constantine · Dellys',
    theme: 'mauresque',
    query: 'theme=mauresque',
    count: 0,
    symbolPath: 'M24 4 L40 24 L24 44 L8 24 Z M24 12 L34 24 L24 36 L14 24 Z'
  },
  {
    key: 'sommets',
    arab: 'جبل',
    tifinagh: 'ⴰⴷⵔⴰⵔ',
    name: 'Sommets berbères',
    sub: 'Djurdjura · Aurès · Tikjda',
    theme: 'aures',
    query: 'theme=aures',
    count: 0,
    symbolPath: 'M4 42 L16 18 L24 30 L32 12 L44 42 Z'
  },
  {
    key: 'oasis',
    arab: 'واحة',
    name: 'Oasis & ksour',
    sub: 'Ghardaïa · Timimoun · Béni Abbès',
    theme: 'saharien',
    query: 'theme=saharien',
    count: 0,
    symbolPath: 'M24 4 L24 38 M20 42 L28 42 M16 14 L24 20 L32 14 M18 22 L24 28 L30 22 M20 30 L24 34 L28 30'
  },
  {
    key: 'spirituel',
    arab: 'روحاني',
    name: 'Routes spirituelles',
    sub: 'Tlemcen · médersa · zaouïas',
    theme: 'mauresque',
    query: 'theme=mauresque',
    count: 0,
    symbolPath: 'M24 4 L24 38 M20 42 L28 42 M16 14 L24 20 L32 14 M18 22 L24 28 L30 22 M20 30 L24 34 L28 30'
  },
  {
    key: 'mer',
    arab: 'بحر',
    name: 'Vent méditerranéen',
    sub: 'Tipaza · Béjaïa · Annaba',
    theme: 'mauresque',
    query: 'theme=mauresque',
    count: 0,
    symbolPath: 'M4 28 Q 12 22, 20 28 T 36 28 T 52 28 M4 34 Q 12 28, 20 34 T 36 34 T 52 34 M4 40 Q 12 34, 20 40 T 36 40 T 52 40'
  }
]

const greetingName = computed(() => {
  if (auth.profile?.display_name) return auth.profile.display_name.split(' ')[0]
  return null
})

const greetingTitle = computed(() => {
  if (greetingName.value) return `Bonjour, ${greetingName.value}.`
  return 'Bienvenue sur Djawal.'
})

onMounted(async () => {
  loading.value = true
  const [destRes, tripsRes, reviewsRes, statsRes] = await Promise.all([
    supabase
      .from('destinations')
      .select('cultural_theme, hero_image_url')
      .not('hero_image_url', 'is', null),
    supabase
      .from('trips')
      .select('id, title, duration_days, price_da, cover_image_url, destinations(name, cultural_theme), profiles!trips_created_by_fkey(display_name, role, avatar_url)')
      .eq('status', 'published')
      .order('published_at', { ascending: false })
      .limit(6),
    supabase
      .from('reviews')
      .select('id, rating, comment, created_at, profiles!reviews_created_by_fkey(display_name, region)')
      .order('created_at', { ascending: false })
      .limit(3),
    supabase
      .from('trips')
      .select('id', { count: 'exact', head: true })
      .eq('status', 'published')
  ])

  // Photo de fond par thème
  if (destRes.data) {
    for (const d of destRes.data) {
      if (d.cultural_theme && d.hero_image_url && !themePhotos.value[d.cultural_theme]) {
        themePhotos.value[d.cultural_theme] = d.hero_image_url
      }
    }
  }

  trips.value = (tripsRes.data as any) || []
  reviews.value = (reviewsRes.data as any) || []
  stats.value.trips = statsRes.count || trips.value.length

  // Note moyenne agrégée
  const { data: allRev } = await supabase.from('reviews').select('rating')
  if (allRev && allRev.length > 0) {
    const sum = allRev.reduce((s: number, r: any) => s + r.rating, 0)
    stats.value.avgRating = (sum / allRev.length).toFixed(1).replace('.', ',') + ' ★'
  }

  // Nombre de guides validés
  const { count: guidesCount } = await supabase
    .from('profiles')
    .select('id', { count: 'exact', head: true })
    .in('role', ['guide_senior', 'guide_junior'])
    .eq('kyc_status', 'approved')
  stats.value.guides = guidesCount || 0

  loading.value = false
})

function fmtPrice(p: number) {
  return new Intl.NumberFormat('fr-DZ').format(p) + ' DA'
}

function initial(name?: string | null) {
  return (name || '?')[0].toUpperCase()
}

function goToComposer(prefill?: string) {
  if (prefill) {
    router.push({ path: '/composer', query: { q: prefill } })
  } else {
    router.push('/composer')
  }
}

function goToSouffle(s: Souffle) {
  router.push(`/voyages?${s.query}`)
}

function submitAI() {
  const q = aiInput.value.trim()
  if (q) goToComposer(q)
  else goToComposer()
}

const quickPrompts = [
  { icon: '🏜️', label: 'Sahara 7 jours', q: '7 jours dans le Sahara, bivouac et étoiles' },
  { icon: '🏛️', label: 'Casbah en famille', q: 'Week-end famille dans la Casbah d\'Alger' },
  { icon: '⛰️', label: 'Trek Djurdjura', q: '4 jours de trek dans le Djurdjura' },
  { icon: '🍴', label: 'Gastronomie kabyle', q: 'Voyage gastronomique en Kabylie' }
]
</script>

<template>
  <div class="home">

    <!-- =================================================================== -->
    <!-- HERO — adaptive mobile / desktop -->
    <!-- =================================================================== -->
    <section class="hero">
      <div class="hero-bg"></div>
      <div class="hero-zellige" aria-hidden="true"></div>
      <svg class="hero-rupestre" viewBox="0 0 230 170" fill="#FAF7F2" aria-hidden="true">
        <path d="M40 130 L40 90 L35 70 L40 50 L48 50 L52 70 L48 90 L48 130 Z"/>
        <circle cx="44" cy="42" r="6"/>
        <path d="M85 130 L85 90 L80 75 L85 60 L92 60 L96 75 L92 90 L92 130 Z"/>
        <circle cx="88" cy="54" r="5"/>
        <path d="M120 132 L120 95 L110 100 L105 110 L100 105 L108 92 L120 88 L120 70 L116 60 L122 50 L130 55 L132 70 L130 88 L142 92 L150 105 L145 110 L140 100 L130 95 L130 132 Z"/>
        <circle cx="126" cy="42" r="6"/>
        <path d="M170 130 L168 110 L160 100 L162 90 L172 95 L180 90 L182 78 L188 70 L195 75 L195 88 L188 96 L185 110 L182 130 Z"/>
        <circle cx="183" cy="62" r="6"/>
      </svg>
      <div class="hero-tifinagh" aria-hidden="true">ⵣⵎⵓⵙⵏ</div>

      <div class="hero-inner djawal-container">
        <div class="hero-arab arabic">مرحبا بكم في الجزائر</div>
        <div class="hero-tag">Carnet & marketplace de voyages algériens</div>
        <h1 class="hero-title">
          {{ greetingTitle }}<br>
          <em>Où vous porte le vent ?</em>
        </h1>
        <p class="hero-sub">
          Du Tassili au Djurdjura, de la Casbah aux ksour mozabites, sept traditions vous attendent.
          Décrivez votre rêve — notre IA et nos guides locaux le dessinent.
        </p>

        <!-- Carte IA hero — proéminente sur mobile, latérale sur desktop -->
        <form @submit.prevent="submitAI" class="ai-hero-card">
          <div class="ai-badge">
            <span class="ai-badge-dot"></span>
            Fennec · en ligne
          </div>
          <div class="ai-input-row">
            <svg class="ai-input-spark" viewBox="0 0 64 64" fill="currentColor" aria-hidden="true">
              <!-- Fennec : mascotte IA -->
              <path d="M14 28 C 10 16, 14 4, 20 6 C 22 14, 24 22, 26 28 Z"/>
              <path d="M50 28 C 54 16, 50 4, 44 6 C 42 14, 40 22, 38 28 Z"/>
              <ellipse cx="32" cy="38" rx="13" ry="12"/>
              <circle cx="26" cy="36" r="1.6" fill="#0A1F2E"/>
              <circle cx="38" cy="36" r="1.6" fill="#0A1F2E"/>
              <circle cx="32" cy="44" r="1.4" fill="#0A1F2E"/>
            </svg>
            <input
              v-model="aiInput"
              type="text"
              placeholder="Ex. 8 jours en mars dans le Sahara…"
              aria-label="Décrivez votre voyage"
            />
            <button type="submit" class="ai-send" aria-label="Envoyer">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M5 12 L19 12 M13 5 L20 12 L13 19" stroke-linecap="round" stroke-linejoin="round"/></svg>
            </button>
          </div>
          <div class="ai-prompts">
            <button
              v-for="p in quickPrompts"
              :key="p.label"
              type="button"
              class="ai-prompt"
              @click="goToComposer(p.q)"
            >
              <span class="ai-prompt-icon">{{ p.icon }}</span>{{ p.label }}
            </button>
          </div>
        </form>
      </div>
    </section>

    <!-- =================================================================== -->
    <!-- TRUST STRIP — chiffres clés -->
    <!-- =================================================================== -->
    <section class="trust-strip">
      <div class="trust-item">
        <strong>{{ stats.destinations }}/58</strong>
        <span>wilayas couvertes</span>
      </div>
      <div class="trust-item">
        <strong>{{ stats.trips }}</strong>
        <span>voyages signés</span>
      </div>
      <div class="trust-item">
        <strong>{{ stats.guides }}</strong>
        <span>guides vérifiés</span>
      </div>
      <div class="trust-item">
        <strong>{{ stats.avgRating }}</strong>
        <span>note communauté</span>
      </div>
      <div class="trust-item arabic-item">
        <span class="arabic arab-tag">صُنع في الجزائر</span>
      </div>
    </section>

    <!-- =================================================================== -->
    <!-- SOUFFLES — scroll horizontal mobile, grille desktop -->
    <!-- =================================================================== -->
    <section class="souffles">
      <div class="djawal-container">
        <header class="section-head">
          <div class="eyebrow">Sept traditions · six souffles</div>
          <h2>Choisissez d'abord<br>ce que vous voulez <em>ressentir.</em></h2>
          <p class="lead">L'Algérie a sept âmes. Chaque souffle propose son propre tempo, son propre langage.</p>
        </header>

        <div class="souffles-grid">
          <button
            v-for="s in souffles"
            :key="s.key"
            class="souffle"
            :class="`bg-${s.theme}`"
            :style="themePhotos[s.theme] ? `background-image: linear-gradient(180deg, rgba(10,15,20,0.15) 0%, rgba(10,15,20,0.85) 100%), url('${themePhotos[s.theme]}'); background-size: cover; background-position: center;` : ''"
            @click="goToSouffle(s)"
          >
            <svg class="souffle-symbol" viewBox="0 0 48 48" :fill="s.symbolPath.includes('Z') ? 'currentColor' : 'none'" :stroke="s.symbolPath.includes('Z') ? 'none' : 'currentColor'" stroke-width="1.5" aria-hidden="true">
              <path :d="s.symbolPath" />
            </svg>
            <div class="souffle-content">
              <span class="souffle-arab arabic">{{ s.arab }}</span>
              <span v-if="s.tifinagh" class="souffle-tif">{{ s.tifinagh }}</span>
              <h3>{{ s.name }}</h3>
              <p>{{ s.sub }}</p>
            </div>
          </button>
        </div>
      </div>
    </section>

    <!-- =================================================================== -->
    <!-- VOYAGES D'AUTEUR — stack mobile, grille desktop -->
    <!-- =================================================================== -->
    <section v-if="trips.length > 0" class="voyages">
      <div class="djawal-container">
        <header class="section-head section-head-row">
          <div>
            <div class="eyebrow">Sélection éditoriale</div>
            <h2>Voyages <em>d'auteur.</em></h2>
          </div>
          <router-link to="/voyages" class="see-all">
            Voir tout
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M5 12 L19 12 M13 5 L20 12 L13 19"/></svg>
          </router-link>
        </header>

        <div class="voyages-list">
          <article
            v-for="trip in trips.slice(0, 3)"
            :key="trip.id"
            class="voy"
            @click="router.push(`/voyages/${trip.id}`)"
          >
            <div
              class="voy-img"
              :class="`theme-${trip.destinations?.cultural_theme || 'mauresque'}`"
              :style="trip.cover_image_url ? `background-image: url(${trip.cover_image_url})` : ''"
            >
              <div class="voy-badges">
                <span v-if="trip.profiles?.role === 'guide_senior'" class="voy-badge senior">Senior</span>
              </div>
              <div class="voy-overlay">
                <div class="voy-loc">{{ trip.destinations?.name }}</div>
                <h3 class="voy-title">{{ trip.title }}</h3>
              </div>
            </div>
            <div class="voy-body">
              <div class="voy-host">
                <div class="voy-avatar">
                  <img v-if="trip.profiles?.avatar_url" :src="trip.profiles.avatar_url" :alt="trip.profiles.display_name" />
                  <span v-else>{{ initial(trip.profiles?.display_name) }}</span>
                </div>
                <div class="voy-host-info">
                  <strong>{{ trip.profiles?.display_name }}</strong>
                  <small>{{ trip.profiles?.role === 'guide_senior' ? 'Guide Senior' : 'Guide local' }}</small>
                </div>
              </div>
              <div class="voy-foot">
                <div class="voy-duration">
                  {{ trip.duration_days }} jour{{ trip.duration_days > 1 ? 's' : '' }}
                </div>
                <div class="voy-price">
                  {{ fmtPrice(trip.price_da) }}
                  <small>par personne</small>
                </div>
              </div>
            </div>
          </article>
        </div>
      </div>
    </section>

    <!-- =================================================================== -->
    <!-- SECTION IA — démo conversationnelle au milieu -->
    <!-- =================================================================== -->
    <section class="ai-section">
      <div class="djawal-container ai-inner">
        <div class="ai-left">
          <div class="eyebrow">Composer avec Fennec</div>
          <h2>Décrivez votre rêve.<br><em>On dessine l'itinéraire.</em></h2>
          <p class="lead">
            Notre intelligence puise dans le catalogue de nos guides locaux pour composer un parcours fidèle à
            vos envies — saison, rythme, budget, intentions. Une conversation suffit.
          </p>
          <button class="ai-cta" @click="goToComposer()">
            <svg viewBox="0 0 64 64" fill="currentColor" aria-hidden="true">
              <!-- Fennec : mascotte IA -->
              <path d="M14 28 C 10 16, 14 4, 20 6 C 22 14, 24 22, 26 28 Z"/>
              <path d="M50 28 C 54 16, 50 4, 44 6 C 42 14, 40 22, 38 28 Z"/>
              <ellipse cx="32" cy="38" rx="13" ry="12"/>
              <circle cx="26" cy="36" r="1.6" fill="#0A1F2E"/>
              <circle cx="38" cy="36" r="1.6" fill="#0A1F2E"/>
              <circle cx="32" cy="44" r="1.4" fill="#0A1F2E"/>
            </svg>
            Composer avec Fennec
          </button>
          <div class="ai-features">
            <span>Sans inscription</span>
            <span>Ressources vérifiées</span>
            <span>Réponse en français</span>
          </div>
        </div>
        <div class="ai-demo">
          <div class="ai-demo-q">
            <span>›</span> Vous : « 8 jours en mars, Sahara, gastronomie & photo »
          </div>
          <p class="ai-demo-a">
            Pour mars idéal, je vous emmène à Djanet avec Aïssa pour les gravures rupestres, puis
            une halte gastronomique à Ghardaïa et un bivouac dans le M'Zab…
          </p>
          <div class="ai-demo-chips">
            <span class="ai-chip">Tassili · 4j</span>
            <span class="ai-chip">Ghardaïa · 2j</span>
            <span class="ai-chip">M'Zab · 2j</span>
          </div>
        </div>
      </div>
    </section>

    <!-- =================================================================== -->
    <!-- TÉMOIGNAGES — avis voyageurs -->
    <!-- =================================================================== -->
    <section v-if="reviews.length > 0" class="reviews">
      <div class="djawal-container">
        <header class="section-head">
          <div class="eyebrow">Ce qu'en disent les voyageurs</div>
          <div class="rating-display">
            <span class="rating-num">{{ stats.avgRating }}</span>
            <small>moyenne sur {{ stats.trips }} voyages</small>
          </div>
        </header>
        <div class="quotes">
          <article v-for="r in reviews.slice(0, 3)" :key="r.id" class="quote">
            <div class="quote-stars" :aria-label="`${r.rating} étoiles sur 5`">
              <span v-for="n in 5" :key="n" :class="['star', { filled: n <= r.rating }]">★</span>
            </div>
            <p class="quote-text">{{ r.comment || 'Une expérience à vivre.' }}</p>
            <div class="quote-author">
              <strong>{{ r.profiles?.display_name }}</strong>
              <span v-if="r.profiles?.region">{{ r.profiles.region }}</span>
            </div>
          </article>
        </div>
      </div>
    </section>

    <!-- =================================================================== -->
    <!-- SOUVENIRS — carrousel communauté -->
    <!-- =================================================================== -->
    <MemoriesCarousel />

  </div>
</template>

<style scoped>
.home {
  background: var(--c-fond, #FAF7F2);
  min-height: 100vh;
  padding-bottom: 80px; /* place pour la bottom-nav mobile */
}
@media (min-width: 640px) {
  .home { padding-bottom: 0; }
}

.djawal-container { max-width: 1080px; margin: 0 auto; padding: 0 20px; }
@media (min-width: 640px) {
  .djawal-container { padding: 0 32px; }
}

/* =================================================================== */
/* HERO                                                                */
/* =================================================================== */
.hero {
  position: relative;
  background: #0A1F2E;
  overflow: hidden;
  min-height: 580px;
  padding: 24px 0 32px;
}
.hero-bg {
  position: absolute;
  inset: 0;
  background: radial-gradient(ellipse 90% 70% at 75% 25%, #D4A04F 0%, #C97050 30%, #8B4A2C 60%, #3E1F12 90%, #1A0F0A 100%);
}
.hero-zellige {
  position: absolute;
  top: 0; right: 0; bottom: 0;
  width: 38%;
  background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 80 80'><g fill='none' stroke='%23FAF7F2' stroke-width='0.5' opacity='0.13'><path d='M40 0 L80 23 L80 57 L40 80 L0 57 L0 23 Z'/><path d='M40 8 L72 27 L72 53 L40 72 L8 53 L8 27 Z'/><circle cx='40' cy='40' r='4' stroke-width='0.8'/><path d='M40 28 L52 40 L40 52 L28 40 Z'/></g></svg>");
  background-size: 80px 80px;
  background-repeat: repeat;
  mask-image: linear-gradient(to left, black 30%, transparent);
  -webkit-mask-image: linear-gradient(to left, black 30%, transparent);
}
.hero-rupestre {
  position: absolute;
  left: 4%; top: 38%;
  width: 180px;
  opacity: 0.32;
  display: none;
}
.hero-tifinagh {
  position: absolute;
  left: 12px;
  top: 12%;
  color: rgba(212, 160, 79, 0.35);
  font-family: 'Noto Sans Tifinagh', monospace;
  font-size: 28px;
  letter-spacing: 0.2em;
  writing-mode: vertical-rl;
  text-orientation: mixed;
}
@media (min-width: 640px) {
  .hero-rupestre { display: block; }
  .hero-tifinagh { left: 4%; font-size: 42px; top: 18%; }
}

.hero-inner {
  position: relative;
  z-index: 5;
  padding-top: 16px;
  color: #FAF7F2;
}

.hero-arab {
  font-size: 22px;
  color: #D4A04F;
  margin-bottom: 10px;
  opacity: 0.92;
}
.hero-tag {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  background: rgba(212, 160, 79, 0.15);
  color: #FFD479;
  padding: 5px 14px;
  border-radius: 24px;
  font-size: 11px;
  font-weight: 500;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  margin-bottom: 16px;
  border: 1px solid rgba(212, 160, 79, 0.28);
}
.hero-tag::before {
  content: '';
  width: 5px;
  height: 5px;
  background: #D4A04F;
  border-radius: 50%;
}

.hero-title {
  font-family: var(--font-display, 'Cormorant Garamond', Georgia, serif);
  font-size: clamp(34px, 7vw, 60px);
  line-height: 1.04;
  margin: 0 0 16px;
  color: #FAF7F2;
  font-weight: 500;
  letter-spacing: -0.01em;
}
.hero-title em {
  font-style: italic;
  color: #FFD479;
  font-weight: 500;
  display: block;
}
.hero-sub {
  font-size: 15px;
  line-height: 1.55;
  color: rgba(250, 247, 242, 0.85);
  max-width: 520px;
  margin: 0 0 24px;
  font-weight: 300;
}
@media (min-width: 640px) {
  .hero-sub { font-size: 17px; }
}

/* === Carte IA hero === */
.ai-hero-card {
  background: rgba(250, 247, 242, 0.08);
  backdrop-filter: blur(14px);
  -webkit-backdrop-filter: blur(14px);
  border: 1px solid rgba(212, 160, 79, 0.28);
  border-radius: 20px;
  padding: 14px;
  max-width: 640px;
}
.ai-badge {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  background: rgba(212, 160, 79, 0.18);
  color: #FFD479;
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 11px;
  font-weight: 500;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  margin-bottom: 12px;
}
.ai-badge-dot {
  width: 6px;
  height: 6px;
  background: #D4A04F;
  border-radius: 50%;
  animation: pulse 2s infinite;
}
@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.4; }
}
.ai-input-row {
  display: flex;
  align-items: center;
  gap: 8px;
  background: rgba(250, 247, 242, 0.95);
  border-radius: 30px;
  padding: 4px 4px 4px 16px;
}
.ai-input-spark {
  width: 22px;
  height: 22px;
  color: #B8862E;
  flex-shrink: 0;
}
.ai-input-row input {
  flex: 1;
  background: transparent;
  border: none;
  outline: none;
  color: #0A1F2E;
  font-size: 14px;
  font-family: inherit;
  padding: 10px 0;
  min-width: 0;
}
.ai-input-row input::placeholder {
  color: #6B6B6B;
  font-style: italic;
}
.ai-send {
  width: 38px;
  height: 38px;
  background: linear-gradient(135deg, #D4A04F, #B8862E);
  border: none;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #0A1F2E;
  cursor: pointer;
  flex-shrink: 0;
  transition: transform 0.15s;
}
.ai-send:hover { transform: scale(1.05); }
.ai-send svg { width: 16px; height: 16px; }

.ai-prompts {
  display: flex;
  gap: 6px;
  margin-top: 12px;
  overflow-x: auto;
  padding-bottom: 2px;
  -webkit-overflow-scrolling: touch;
}
.ai-prompts::-webkit-scrollbar { display: none; }
.ai-prompt {
  flex-shrink: 0;
  background: rgba(250, 247, 242, 0.1);
  border: 1px solid rgba(250, 247, 242, 0.18);
  color: rgba(250, 247, 242, 0.92);
  padding: 6px 12px;
  border-radius: 18px;
  font-size: 11px;
  font-family: inherit;
  font-weight: 400;
  cursor: pointer;
  white-space: nowrap;
  display: inline-flex;
  align-items: center;
  gap: 4px;
}
.ai-prompt:hover {
  background: rgba(212, 160, 79, 0.2);
  border-color: rgba(212, 160, 79, 0.4);
}
.ai-prompt-icon { font-size: 13px; }

/* =================================================================== */
/* TRUST STRIP                                                         */
/* =================================================================== */
.trust-strip {
  background: #FFFFFF;
  padding: 16px 20px;
  display: flex;
  justify-content: space-around;
  align-items: center;
  flex-wrap: wrap;
  gap: 18px 24px;
  border-bottom: 1px solid rgba(10, 31, 46, 0.05);
}
.trust-item { flex: 0 0 auto; min-width: 80px; }
.trust-item {
  text-align: center;
  font-size: 10px;
  color: var(--c-texte-doux, #6B6B6B);
  letter-spacing: 0.14em;
  text-transform: uppercase;
}
.trust-item strong {
  display: block;
  font-family: var(--font-display, 'Cormorant Garamond', Georgia, serif);
  font-size: 22px;
  font-weight: 500;
  color: var(--c-primaire-profond, #0A1F2E);
  letter-spacing: 0;
  text-transform: none;
  margin-bottom: 2px;
}
.arabic-item { display: flex; align-items: center; }
.arab-tag {
  font-family: var(--font-arabic, 'Amiri', serif);
  font-size: 15px;
  color: var(--c-accent-fort, #B8862E);
  font-style: italic;
  letter-spacing: 0;
  text-transform: none;
}

/* =================================================================== */
/* SOUFFLES                                                            */
/* =================================================================== */
.souffles { padding: 48px 0; background: var(--c-fond, #FAF7F2); }
@media (min-width: 640px) { .souffles { padding: 64px 0; } }

.section-head { text-align: center; max-width: 680px; margin: 0 auto 32px; }
.section-head-row {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  text-align: left;
  max-width: none;
  gap: 16px;
  flex-wrap: wrap;
}
.section-head-row > div { min-width: 0; }
.section-head-row .see-all { flex-shrink: 0; }
.eyebrow {
  display: inline-block;
  font-size: 11px;
  letter-spacing: 0.22em;
  text-transform: uppercase;
  color: var(--c-accent-fort, #B8862E);
  font-weight: 500;
  margin-bottom: 10px;
}
h2 {
  font-family: var(--font-display, 'Cormorant Garamond', Georgia, serif);
  font-size: clamp(26px, 4.5vw, 40px);
  line-height: 1.12;
  margin: 0 0 12px;
  color: var(--c-primaire-profond, #0A1F2E);
  font-weight: 500;
  letter-spacing: -0.01em;
}
h2 em {
  font-style: italic;
  color: var(--c-accent-fort, #B8862E);
  font-weight: 500;
}
.lead {
  font-size: 15px;
  line-height: 1.6;
  color: var(--c-texte, #444441);
  font-weight: 300;
  margin: 0;
}

.see-all {
  font-size: 13px;
  color: var(--c-primaire, #1B4965);
  font-weight: 500;
  text-decoration: none;
  display: inline-flex;
  align-items: center;
  gap: 4px;
}
.see-all svg { width: 14px; height: 14px; }
.see-all:hover { color: var(--c-accent-fort, #B8862E); }

.souffles-grid {
  display: flex;
  gap: 10px;
  overflow-x: auto;
  padding: 6px 4px 16px;
  scroll-snap-type: x mandatory;
  -webkit-overflow-scrolling: touch;
  margin: 0 -20px;
  padding-left: 20px;
  padding-right: 20px;
}
.souffles-grid::-webkit-scrollbar { display: none; }
@media (min-width: 640px) {
  .souffles-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 14px;
    overflow: visible;
    margin: 0;
    padding: 0;
  }
}
@media (min-width: 900px) {
  .souffles-grid { grid-template-columns: repeat(3, 1fr); }
}

.souffle {
  flex-shrink: 0;
  width: 145px;
  aspect-ratio: 3/4;
  border-radius: 18px;
  position: relative;
  overflow: hidden;
  cursor: pointer;
  color: #FAF7F2;
  scroll-snap-align: start;
  border: none;
  padding: 0;
  text-align: left;
  font-family: inherit;
  transition: transform 0.25s;
}
.souffle:hover { transform: translateY(-3px); }
@media (min-width: 640px) {
  .souffle { width: auto; aspect-ratio: 5/6; border-radius: 14px; }
}
.souffle::after {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(180deg, transparent 30%, rgba(10, 15, 20, 0.85) 100%);
  z-index: 1;
}
.bg-saharien { background: linear-gradient(160deg, #D4A04F 0%, #C97050 50%, #8B4A2C 100%); }
.bg-mauresque { background: linear-gradient(160deg, #3D6890 0%, #1B4965 50%, #0A1F2E 100%); }
.bg-aures { background: linear-gradient(160deg, #3D6E47 0%, #2D5A3D 50%, #1B3A28 100%); }

.souffle-symbol {
  position: absolute;
  top: 14px; right: 14px;
  width: 32px; height: 32px;
  color: rgba(250, 247, 242, 0.55);
  z-index: 3;
  transition: color 0.3s;
}
.souffle:hover .souffle-symbol { color: rgba(250, 247, 242, 0.85); }
@media (min-width: 640px) {
  .souffle-symbol { width: 42px; height: 42px; top: 18px; right: 18px; }
}

.souffle-content {
  position: absolute;
  bottom: 14px;
  left: 14px;
  right: 14px;
  z-index: 3;
}
@media (min-width: 640px) {
  .souffle-content { bottom: 18px; left: 18px; right: 18px; }
}
.souffle-arab {
  display: block;
  font-family: var(--font-arabic, 'Amiri', serif);
  font-size: 12px;
  direction: rtl;
  opacity: 0.7;
  margin-bottom: 3px;
  text-align: left;
}
.souffle-tif {
  display: block;
  font-family: 'Noto Sans Tifinagh', monospace;
  font-size: 11px;
  color: #FFD479;
  letter-spacing: 0.18em;
  opacity: 0.85;
  margin-bottom: 4px;
}
.souffle h3 {
  font-family: var(--font-display, 'Cormorant Garamond', Georgia, serif);
  font-size: 17px;
  line-height: 1.1;
  margin: 0 0 3px;
  font-weight: 500;
  color: #FAF7F2;
}
@media (min-width: 640px) {
  .souffle h3 { font-size: 22px; }
}
.souffle p {
  font-size: 11px;
  margin: 0;
  opacity: 0.82;
  font-weight: 300;
  letter-spacing: 0.02em;
}

/* =================================================================== */
/* VOYAGES D'AUTEUR                                                    */
/* =================================================================== */
.voyages { padding: 32px 0 48px; background: #F5F0E6; }
@media (min-width: 640px) { .voyages { padding: 64px 0; } }

.voyages-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
@media (min-width: 640px) {
  .voyages-list {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 18px;
  }
}
@media (min-width: 900px) {
  .voyages-list { grid-template-columns: repeat(3, 1fr); }
}

.voy {
  background: #FFFFFF;
  border-radius: 16px;
  overflow: hidden;
  cursor: pointer;
  border: 1px solid rgba(10, 31, 46, 0.05);
  transition: transform 0.25s, box-shadow 0.25s;
}
.voy:hover {
  transform: translateY(-3px);
  box-shadow: 0 14px 30px rgba(10, 31, 46, 0.08);
}

.voy-img {
  aspect-ratio: 16/10;
  position: relative;
  overflow: hidden;
  background-size: cover;
  background-position: center;
}
.voy-img.theme-saharien { background-color: #C97050; background-image: linear-gradient(135deg, #D4A04F, #8B4A2C); }
.voy-img.theme-mauresque { background-color: #1B4965; background-image: linear-gradient(135deg, #1B4965, #0A1F2E); }
.voy-img.theme-aures { background-color: #2D5A3D; background-image: linear-gradient(135deg, #2D5A3D, #1B3A28); }
@media (min-width: 640px) {
  .voy-img { aspect-ratio: 5/4; }
}

.voy-badges {
  position: absolute;
  top: 12px; left: 12px;
  display: flex;
  gap: 5px;
  z-index: 2;
}
.voy-badge {
  background: rgba(250, 247, 242, 0.95);
  backdrop-filter: blur(6px);
  color: #0A1F2E;
  padding: 4px 9px;
  border-radius: 14px;
  font-size: 10px;
  font-weight: 500;
  letter-spacing: 0.04em;
}
.voy-badge.senior {
  background: linear-gradient(135deg, #D4A04F, #B8862E);
}
.voy-badge.senior::before {
  content: '★ ';
  font-size: 9px;
}

.voy-overlay {
  position: absolute;
  bottom: 0; left: 0; right: 0;
  padding: 14px 14px 12px;
  background: linear-gradient(180deg, transparent, rgba(10, 15, 20, 0.78) 60%);
  color: #FAF7F2;
  z-index: 2;
}
.voy-loc {
  font-size: 10px;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: #FFD479;
  margin-bottom: 4px;
  display: flex;
  align-items: center;
  gap: 5px;
}
.voy-loc::before {
  content: '';
  width: 4px;
  height: 4px;
  background: #D4A04F;
  border-radius: 50%;
}
.voy-title {
  font-family: var(--font-display, 'Cormorant Garamond', Georgia, serif);
  font-size: 20px;
  font-weight: 500;
  line-height: 1.15;
  margin: 0;
  color: #FAF7F2;
}

.voy-body { padding: 14px 16px 16px; }
.voy-host {
  display: flex;
  align-items: center;
  gap: 9px;
  margin-bottom: 12px;
}
.voy-avatar {
  width: 30px;
  height: 30px;
  border-radius: 50%;
  background: linear-gradient(135deg, #D4A04F, #B8862E);
  display: flex;
  align-items: center;
  justify-content: center;
  color: #0A1F2E;
  font-size: 11px;
  font-weight: 500;
  font-family: var(--font-display, 'Cormorant Garamond', Georgia, serif);
  flex-shrink: 0;
  overflow: hidden;
}
.voy-avatar img { width: 100%; height: 100%; object-fit: cover; }
.voy-host-info {
  font-size: 11px;
  color: var(--c-texte, #444441);
  line-height: 1.3;
  flex: 1;
}
.voy-host-info strong {
  color: #0A1F2E;
  font-weight: 500;
  display: block;
  font-size: 12px;
}
.voy-host-info small { color: var(--c-texte-doux, #6B6B6B); font-size: 10px; }

.voy-foot {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  padding-top: 10px;
  border-top: 1px solid rgba(10, 31, 46, 0.06);
}
.voy-duration { font-size: 11px; color: var(--c-texte-doux, #6B6B6B); }
.voy-price {
  font-family: var(--font-display, 'Cormorant Garamond', Georgia, serif);
  font-size: 20px;
  color: #0A1F2E;
  font-weight: 500;
  text-align: right;
  line-height: 1;
}
.voy-price small {
  display: block;
  font-family: inherit;
  font-size: 9px;
  color: var(--c-texte-doux, #6B6B6B);
  margin-top: 2px;
  letter-spacing: 0.04em;
  font-weight: 400;
}

/* =================================================================== */
/* SECTION IA                                                          */
/* =================================================================== */
.ai-section {
  background: linear-gradient(135deg, #0A1F2E 0%, #1B3A55 100%);
  color: #FAF7F2;
  padding: 56px 0;
  position: relative;
  overflow: hidden;
}
.ai-section::before {
  content: '';
  position: absolute;
  top: -150px; right: -100px;
  width: 500px; height: 500px;
  background: radial-gradient(circle, rgba(212, 160, 79, 0.22) 0%, transparent 65%);
  border-radius: 50%;
}
@media (min-width: 640px) { .ai-section { padding: 72px 0; } }

.ai-inner {
  position: relative;
  display: grid;
  grid-template-columns: 1fr;
  gap: 32px;
}
@media (min-width: 768px) {
  .ai-inner { grid-template-columns: 1.1fr 1fr; gap: 48px; align-items: center; }
}

.ai-section .eyebrow { color: #D4A04F; }
.ai-section h2 { color: #FAF7F2; }
.ai-section h2 em { color: #FFD479; }
.ai-section .lead {
  color: rgba(250, 247, 242, 0.78);
  margin-bottom: 24px;
}

.ai-cta {
  display: inline-flex;
  align-items: center;
  gap: 12px;
  padding: 14px 24px;
  background: linear-gradient(135deg, #D4A04F, #B8862E);
  color: #0A1F2E;
  border-radius: 30px;
  font-weight: 500;
  font-size: 14px;
  border: none;
  cursor: pointer;
  font-family: inherit;
  transition: transform 0.2s;
  max-width: 100%;
  text-align: left;
  line-height: 1.2;
}
.ai-cta:hover { transform: translateY(-2px); }
.ai-cta svg { width: 20px; height: 20px; }

.ai-features {
  display: flex;
  gap: 16px;
  margin-top: 16px;
  flex-wrap: wrap;
  font-size: 11px;
  color: rgba(250, 247, 242, 0.55);
  letter-spacing: 0.12em;
  text-transform: uppercase;
}
.ai-features span {
  display: inline-flex;
  align-items: center;
  gap: 5px;
}
.ai-features span::before {
  content: '';
  width: 4px;
  height: 4px;
  background: #D4A04F;
  border-radius: 50%;
}

.ai-demo {
  background: rgba(250, 247, 242, 0.06);
  border: 1px solid rgba(212, 160, 79, 0.22);
  border-radius: 14px;
  padding: 18px;
  backdrop-filter: blur(8px);
  position: relative;
}
.ai-demo::before {
  content: '';
  position: absolute;
  top: -1px;
  left: 24px;
  width: 24px;
  height: 3px;
  background: #D4A04F;
  border-radius: 0 0 4px 4px;
}
.ai-demo-q {
  font-size: 11px;
  color: #D4A04F;
  margin-bottom: 10px;
  letter-spacing: 0.04em;
  display: flex;
  align-items: center;
  gap: 6px;
}
.ai-demo-q span { font-size: 14px; }
.ai-demo-a {
  font-family: var(--font-display, 'Cormorant Garamond', Georgia, serif);
  font-size: 15px;
  color: rgba(250, 247, 242, 0.92);
  line-height: 1.55;
  font-style: italic;
  font-weight: 500;
  margin: 0;
}
.ai-demo-chips {
  display: flex;
  gap: 6px;
  margin-top: 14px;
  flex-wrap: wrap;
}
.ai-chip {
  font-size: 10px;
  background: rgba(212, 160, 79, 0.2);
  color: #FFD479;
  padding: 4px 10px;
  border-radius: 12px;
  letter-spacing: 0.05em;
  font-weight: 500;
}

/* =================================================================== */
/* REVIEWS                                                             */
/* =================================================================== */
.reviews { padding: 48px 0; background: #FAF7F2; }
@media (min-width: 640px) { .reviews { padding: 64px 0; } }

.rating-display {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  margin-top: 12px;
}
.rating-num {
  font-family: var(--font-display, 'Cormorant Garamond', Georgia, serif);
  font-size: 40px;
  color: var(--c-accent-fort, #B8862E);
  font-weight: 500;
  line-height: 1;
}
.rating-num::before { content: '★ '; color: #D4A04F; font-size: 28px; }
.rating-display small {
  font-size: 12px;
  color: var(--c-texte-doux, #6B6B6B);
  letter-spacing: 0.02em;
}

.quotes {
  display: grid;
  grid-template-columns: 1fr;
  gap: 12px;
  margin-top: 24px;
}
@media (min-width: 640px) {
  .quotes { grid-template-columns: repeat(2, 1fr); gap: 14px; }
}
@media (min-width: 900px) {
  .quotes { grid-template-columns: repeat(3, 1fr); }
}

.quote {
  background: #FFFFFF;
  border-radius: 12px;
  padding: 16px 18px;
  border: 1px solid rgba(10, 31, 46, 0.06);
  position: relative;
}
.quote::before {
  content: '„';
  position: absolute;
  top: -6px;
  left: 14px;
  font-family: var(--font-display, 'Cormorant Garamond', Georgia, serif);
  font-size: 42px;
  color: #D4A04F;
  line-height: 1;
}
.quote-stars { margin-bottom: 10px; }
.star { color: var(--c-gris-clair, #D3D1C7); font-size: 13px; letter-spacing: 1.5px; }
.star.filled { color: #D4A04F; }
.quote-text {
  font-family: var(--font-display, 'Cormorant Garamond', Georgia, serif);
  font-size: 15px;
  line-height: 1.5;
  color: #0A1F2E;
  font-style: italic;
  margin-bottom: 12px;
  font-weight: 500;
}
.quote-author {
  font-size: 11px;
  color: var(--c-texte-doux, #6B6B6B);
  display: flex;
  justify-content: space-between;
  align-items: center;
  letter-spacing: 0.03em;
  padding-top: 10px;
  border-top: 1px solid rgba(10, 31, 46, 0.06);
}
.quote-author strong { color: #0A1F2E; font-weight: 500; }
</style>
