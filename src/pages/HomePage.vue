<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useSEO } from '@/composables/useSEO'
import djawalMonogram from '@/assets/branding/djawal-monogram.png'

useSEO({
  title: "L'Algérie, vécue de l'intérieur",
  description: "Du cœur de la Casbah aux dunes du Tassili. Connectez-vous avec les habitants ou laissez Djawal IA composer votre aventure sur-mesure."
})

const router = useRouter()
const stats = ref({ travellers: 12000, guides: 450 })
const aiInput = ref('')

function fmtPriceDA(p: number) {
  return new Intl.NumberFormat('fr-DZ').format(p) + ' DA'
}

onMounted(async () => {
  // Stats guides
  const { count: guidesCount } = await supabase
    .from('profiles')
    .select('id', { count: 'exact', head: true })
    .in('role', ['guide_senior', 'guide_junior'])
    .eq('kyc_status', 'approved')
  if (guidesCount && guidesCount >= 50) stats.value.guides = guidesCount

  // Destinations vedettes — configurées via /admin/homepage
  const { data: destData } = await supabase
    .from('destinations')
    .select('id, name, name_ar, tagline, description, hero_image_url, cultural_theme')
    .eq('is_featured_homepage', true)
    .order('homepage_display_order', { ascending: true })
  if (destData && destData.length > 0) {
    heroCards.value = destData.map((d: any) => ({
      id: d.id,
      name: d.name,
      sub: d.tagline || (d.cultural_theme ? d.cultural_theme.charAt(0).toUpperCase() + d.cultural_theme.slice(1) : ''),
      arabic: d.name_ar || '',
      desc: (d.description || '').slice(0, 80),
      img: d.hero_image_url || '',
      theme: d.cultural_theme || 'mauresque'
    }))
  }

  // Voyages signés — configurés via /admin/homepage
  const { data: tripData } = await supabase
    .from('trips')
    .select(`
      id, title, duration_days, price_da, description, cover_image_url, tags,
      profiles!trips_created_by_fkey(display_name, region, role)
    `)
    .eq('is_featured_homepage', true)
    .eq('status', 'published')
    .order('homepage_display_order', { ascending: true })
    .limit(3)
  if (tripData && tripData.length > 0) {
    signedTrips.value = tripData.map((t: any) => ({
      id: t.id,
      title: t.title,
      duration: `${t.duration_days} jour${t.duration_days > 1 ? 's' : ''}`,
      desc: (t.description || '').slice(0, 140),
      guide: t.profiles?.display_name || 'Guide Djawal',
      guideRole: t.profiles?.region || (t.profiles?.role === 'guide_senior' ? 'Guide Senior' : 'Guide Djawal'),
      price: fmtPriceDA(t.price_da || 0),
      img: t.cover_image_url || ''
    }))
  }
})

function goToComposer(prefill?: string) {
  if (prefill) router.push({ path: '/composer', query: { q: prefill } })
  else router.push('/composer')
}
function submitAI() {
  goToComposer(aiInput.value.trim() || undefined)
}
function fmtNumber(n: number) {
  return new Intl.NumberFormat('fr-FR').format(n)
}

const categories = [
  { label: 'Sahara', query: '?theme=saharien', icon: 'M2 18 Q 6 14 10 18 T 18 18 T 22 18|M6 9 m -2 0 a 2 2 0 1 0 4 0 a 2 2 0 1 0 -4 0' },
  { label: 'Casbah', query: '?theme=mauresque', icon: 'M4 20 L4 12 L8 12 L8 8 Q 12 4 16 8 L16 12 L20 12 L20 20 Z' },
  { label: 'Aurès & Montagnes', query: '?theme=aures', icon: 'M3 20 L9 8 L13 14 L17 6 L21 20 Z' },
  { label: 'Côte méditerranéenne', query: '?theme=mauresque', icon: 'M2 14 Q 6 10 10 14 T 18 14 T 22 14|M2 18 Q 6 14 10 18 T 18 18 T 22 18' },
  { label: 'Tables d\'hôtes', query: '?type=table', icon: 'M6 10 L18 10 L17 18 L7 18 Z|M9 6 L9 10|M12 6 L12 10|M15 6 L15 10' },
  { label: 'Trek & Randonnée', query: '?type=trek', icon: 'M3 20 L8 11 L12 16 L14 14 L21 20 Z|M17 6 m -2 0 a 2 2 0 1 0 4 0 a 2 2 0 1 0 -4 0' }
]

const quickPrompts = [
  { label: 'Sahara 7 jours', q: '7 jours dans le Sahara, bivouac et étoiles' },
  { label: 'Casbah famille', q: 'Week-end famille dans la Casbah d\'Alger' },
  { label: 'Trek Djurdjura', q: '4 jours de trek dans le Djurdjura' },
  { label: 'Saveurs kabyles', q: 'Voyage gastronomique en Kabylie' }
]

// ===== Cards carrousel + voyages signés =====
// Configurés via /admin/homepage (super_admin). Fallback hardcodé ci-dessous
// si la BDD ne renvoie rien (premières visites avant configuration admin).
interface HeroCard {
  id?: string
  name: string
  sub: string
  arabic: string
  desc: string
  img: string
  theme: string
}
interface SignedTrip {
  id?: string
  title: string
  duration: string
  desc: string
  guide: string
  guideRole: string
  price: string
  img: string
}

const fallbackHeroCards: HeroCard[] = [
  { name: 'Tassili n\'Ajjer', sub: 'Saharien · UNESCO', arabic: 'طاسيلي', desc: 'Plateau de l\'art rupestre', img: 'https://images.pexels.com/photos/9351229/pexels-photo-9351229.jpeg?auto=compress&cs=tinysrgb&w=800', theme: 'saharien' },
  { name: 'Casbah d\'Alger', sub: 'Mauresque · UNESCO', arabic: 'القصبة', desc: 'Médina ottomane vivante', img: 'https://images.pexels.com/photos/29639897/pexels-photo-29639897.jpeg?auto=compress&cs=tinysrgb&w=800', theme: 'mauresque' },
  { name: 'Djurdjura', sub: 'Kabylie', arabic: 'جرجرة', desc: 'Cèdres et sommets de Kabylie', img: 'https://images.pexels.com/photos/14088291/pexels-photo-14088291.jpeg?auto=compress&cs=tinysrgb&w=800', theme: 'aures' },
  { name: 'Ghardaïa', sub: 'Saharien · UNESCO', arabic: 'غرداية', desc: 'Vallée du M\'Zab mozabite', img: 'https://images.pexels.com/photos/1631665/pexels-photo-1631665.jpeg?auto=compress&cs=tinysrgb&w=800', theme: 'saharien' },
  { name: 'Tipaza', sub: 'Mauresque · UNESCO', arabic: 'تيبازة', desc: 'Ruines romaines face à la mer', img: 'https://images.pexels.com/photos/2901209/pexels-photo-2901209.jpeg?auto=compress&cs=tinysrgb&w=800', theme: 'mauresque' },
  { name: 'Constantine', sub: 'Aurès', arabic: 'قسنطينة', desc: 'La ville des ponts suspendus', img: 'https://images.pexels.com/photos/1591375/pexels-photo-1591375.jpeg?auto=compress&cs=tinysrgb&w=800', theme: 'aures' },
  { name: 'Timimoun', sub: 'Saharien', arabic: 'تيميمون', desc: 'L\'oasis rouge du Gourara', img: 'https://images.pexels.com/photos/2104881/pexels-photo-2104881.jpeg?auto=compress&cs=tinysrgb&w=800', theme: 'saharien' },
  { name: 'Hoggar', sub: 'Saharien', arabic: 'الهقار', desc: 'Massif du Mont Tahat', img: 'https://images.pexels.com/photos/2382325/pexels-photo-2382325.jpeg?auto=compress&cs=tinysrgb&w=800', theme: 'saharien' },
  { name: 'Tlemcen', sub: 'Mauresque', arabic: 'تلمسان', desc: 'Capitale zianide andalouse', img: 'https://images.pexels.com/photos/2335052/pexels-photo-2335052.jpeg?auto=compress&cs=tinysrgb&w=800', theme: 'mauresque' },
  { name: 'Djémila', sub: 'Aurès · UNESCO', arabic: 'جميلة', desc: 'Cité romaine de Cuicul', img: 'https://images.pexels.com/photos/1631181/pexels-photo-1631181.jpeg?auto=compress&cs=tinysrgb&w=800', theme: 'aures' }
]

const fallbackSignedTrips: SignedTrip[] = [
  { title: 'Cœur du Hoggar : silence et étoiles', duration: '9 jours · Hiver', desc: "Marche douce dans l'Atakor. Nuit chez les Touaregs. Lever de lune sur l'Assekrem.", guide: 'Yacine', guideRole: 'Touareg du Hoggar', price: '218 000 DA', img: 'https://images.pexels.com/photos/2382325/pexels-photo-2382325.jpeg?auto=compress&cs=tinysrgb&w=800' },
  { title: "L'Algérie mauresque : Tlemcen, Casbah, Tipaza", duration: '7 jours · Toute saison', desc: 'Trois capitales, trois siècles. Mansourah, Casbah, ruines romaines face à la mer.', guide: 'Lina', guideRole: "Casbah d'Alger", price: '174 000 DA', img: 'https://images.pexels.com/photos/29639897/pexels-photo-29639897.jpeg?auto=compress&cs=tinysrgb&w=800' },
  { title: "M'Zab : l'épure pour philosophie", duration: '5 jours · Printemps', desc: "Ghardaïa, Beni Isguen, El Atteuf. La sobriété mozabite comme art de vivre.", guide: 'Hamid', guideRole: "Senior · M'Zab", price: '131 000 DA', img: 'https://images.pexels.com/photos/1631665/pexels-photo-1631665.jpeg?auto=compress&cs=tinysrgb&w=800' }
]

const heroCards = ref<HeroCard[]>(fallbackHeroCards)
const signedTrips = ref<SignedTrip[]>(fallbackSignedTrips)

const archCarousel = ref<HTMLElement | null>(null)
function scrollCarousel(dir: 'left' | 'right') {
  if (!archCarousel.value) return
  const card = archCarousel.value.querySelector('.dest-card') as HTMLElement | null
  const cardWidth = card ? card.offsetWidth + 18 : 280
  archCarousel.value.scrollBy({ left: (dir === 'left' ? -1 : 1) * cardWidth * 3, behavior: 'smooth' })
}
</script>

<template>
  <div class="home">

    <!-- HERO image plein écran -->
    <section class="hero">
      <img class="hero-img"
           src="https://images.pexels.com/photos/1001435/pexels-photo-1001435.jpeg?auto=compress&cs=tinysrgb&w=1920"
           alt="Dunes du Sahara algérien" />
      <div class="hero-overlay"></div>

      <div class="hero-content">
        <div class="hero-eyebrow">
          <span class="arabic">مرحبا بكم</span> · MARHABA BIKOUM
        </div>
        <h1>L'Algérie,<br><em>vécue de l'intérieur.</em></h1>
        <p>Du cœur de la Casbah aux dunes du Tassili — voyagez aux côtés des Algériens qui racontent leur terre.</p>

        <!-- BANDEAU IA central -->
        <div class="hero-ia">
          <form class="ia-pill" @submit.prevent="submitAI">
            <div class="ia-mark" aria-hidden="true">
              <img :src="djawalMonogram" alt="" />
            </div>
            <input v-model="aiInput" type="text" class="ia-input ia-input-desktop"
                   placeholder="Racontez-moi votre voyage idéal — Djawal IA compose le reste…"
                   aria-label="Décrivez votre voyage" />
            <input v-model="aiInput" type="text" class="ia-input ia-input-mobile"
                   placeholder="Décrivez votre voyage idéal…"
                   aria-label="Décrivez votre voyage" />
            <button type="submit" class="ia-submit">Composer →</button>
          </form>
          <div class="ia-prompts">
            <button v-for="p in quickPrompts" :key="p.label" type="button" class="ia-prompt" @click="goToComposer(p.q)">
              {{ p.label }}
            </button>
          </div>
        </div>

        <a href="#destinations" class="hero-cta-secondary">
          Ou parcourir nos voyages signés <span aria-hidden="true">↓</span>
        </a>

        <div class="hero-stats">
          <span class="stats-dots" aria-hidden="true">
            <span class="dot dot-1">A</span>
            <span class="dot dot-2">Y</span>
            <span class="dot dot-3">L</span>
          </span>
          <span class="stats-num">{{ fmtNumber(stats.travellers) }}+</span> voyageurs ·
          <span class="stats-num">{{ fmtNumber(stats.guides) }}</span> guides locaux
        </div>
      </div>
    </section>

    <!-- BANDEAU CATÉGORIES -->
    <nav class="cat-banner" aria-label="Catégories rapides">
      <div class="cat-banner-inner">
        <button v-for="c in categories" :key="c.label" class="cat-chip" @click="router.push('/voyages' + c.query)">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" aria-hidden="true">
            <path v-for="(d, i) in c.icon.split('|')" :key="i" :d="d" stroke-linecap="round" stroke-linejoin="round" />
          </svg>
          <span>{{ c.label }}</span>
        </button>
      </div>
    </nav>

    <!-- DESTINATIONS CARROUSEL -->
    <section class="section destinations" id="destinations">
      <div class="djawal-container">
        <header class="section-head">
          <div class="section-eyebrow">— 10 territoires à explorer —</div>
          <h2>Choisissez <em>votre Algérie</em>.</h2>
          <p class="section-lede">Chaque destination, une porte ouverte sur un univers.</p>
        </header>

        <div class="dest-carousel-wrap">
          <div class="dest-carousel" ref="archCarousel">
            <button v-for="d in heroCards" :key="d.id || d.name" class="dest-card" type="button"
                    @click="d.id ? router.push('/destination/' + d.id) : router.push('/voyages?theme=' + d.theme)">
              <img class="dest-card-img" :src="d.img" :alt="d.name" loading="lazy" />
              <div class="dest-card-body">
                <div class="dest-card-theme">— {{ d.sub }} —</div>
                <div class="dest-card-title">{{ d.name }}<span class="dest-card-arabic arabic">{{ d.arabic }}</span></div>
                <div class="dest-card-desc">{{ d.desc }}</div>
              </div>
            </button>
          </div>
          <div class="carousel-nav">
            <button class="carousel-btn" type="button" @click="scrollCarousel('left')" aria-label="Précédent">←</button>
            <button class="carousel-btn" type="button" @click="scrollCarousel('right')" aria-label="Suivant">→</button>
          </div>
        </div>
      </div>
    </section>

    <!-- VOYAGES SIGNÉS DJAWAL -->
    <section class="section signed-trips">
      <div class="djawal-container">
        <header class="section-head">
          <div class="section-eyebrow">— Voyages signés Djawal —</div>
          <h2>Trois récits, trois <em>quêtes différentes</em>.</h2>
          <p class="section-lede">Pas un catalogue. Des invitations à vivre — composées par les guides eux-mêmes.</p>
        </header>
        <div class="trips-grid">
          <article v-for="t in signedTrips" :key="t.id || t.title" class="trip-card"
                   @click="t.id ? router.push('/voyages/' + t.id) : router.push('/voyages')">
            <div class="trip-img-wrap">
              <img :src="t.img" :alt="t.title" loading="lazy" />
              <span class="trip-duration-badge">{{ t.duration }}</span>
            </div>
            <div class="trip-body">
              <h3 class="trip-title">{{ t.title }}</h3>
              <p class="trip-desc">{{ t.desc }}</p>
              <div class="trip-foot">
                <div class="trip-guide">
                  <strong>Avec {{ t.guide }}</strong>
                  {{ t.guideRole }}
                </div>
                <div class="trip-price">{{ t.price }}<small>par voyageur</small></div>
              </div>
            </div>
          </article>
        </div>
      </div>
    </section>

    <!-- TÉMOIGNAGE -->
    <section class="testimonial">
      <div class="testimonial-inner">
        <img src="https://images.pexels.com/photos/2530364/pexels-photo-2530364.jpeg?auto=compress&cs=tinysrgb&w=400"
             alt="Témoignage Amina" class="testimonial-avatar" loading="lazy" />
        <p class="testimonial-quote">Un voyage inoubliable au cœur du Sahara. Djawal a su créer une expérience magique, à mille lieues du tourisme classique.</p>
        <p class="testimonial-name">— AMINA B., PARIS</p>
      </div>
    </section>

  </div>
</template>

<style scoped>
.home {
  background: var(--c-fond, #1A3A2A);
  color: #FAF7F2;
  font-family: 'Inter', sans-serif;
}
.arabic { font-family: 'Amiri', serif; }
.djawal-container { max-width: 1200px; margin: 0 auto; padding: 0 32px; }

/* ========== HERO ========== */
.hero {
  position: relative;
  height: 95vh;
  min-height: 620px;
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}
.hero-img { position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover; z-index: 0; }
.hero-overlay {
  position: absolute; inset: 0;
  background: linear-gradient(180deg,
    rgba(15, 36, 25, 0.5) 0%,
    rgba(26, 58, 42, 0.35) 40%,
    rgba(26, 58, 42, 0.75) 75%,
    #1A3A2A 100%);
  z-index: 1;
}
.hero-content {
  position: relative; z-index: 2;
  text-align: center;
  max-width: 780px;
  padding: 90px 32px 32px;
}
.hero-eyebrow {
  display: inline-flex; gap: 10px;
  padding: 7px 18px;
  background: rgba(212, 168, 68, 0.18);
  border: 1px solid rgba(212, 168, 68, 0.4);
  border-radius: 999px;
  font-size: 11px; letter-spacing: 0.18em; font-weight: 500;
  color: #E8B96B;
  margin-bottom: 24px;
  text-transform: uppercase;
}
.hero h1 {
  font-family: 'Cormorant Garamond', Georgia, serif;
  font-size: clamp(38px, 6vw, 70px);
  line-height: 1.05;
  font-weight: 500;
  color: #FAF7F2;
  margin-bottom: 18px;
  letter-spacing: -0.01em;
}
.hero h1 em { font-style: italic; color: #E8B96B; }
.hero p {
  font-family: 'Cormorant Garamond', serif;
  font-style: italic;
  font-size: 18px;
  color: rgba(250, 247, 242, 0.78);
  max-width: 580px;
  margin: 0 auto 28px;
  line-height: 1.5;
}

/* Bandeau IA central */
.hero-ia { max-width: 720px; margin: 0 auto 18px; }
.ia-pill {
  display: grid;
  grid-template-columns: auto 1fr auto;
  gap: 12px;
  align-items: center;
  background: rgba(15, 36, 25, 0.6);
  backdrop-filter: blur(14px);
  -webkit-backdrop-filter: blur(14px);
  border: 1.5px solid rgba(212, 168, 68, 0.5);
  border-radius: 999px;
  padding: 10px 12px 10px 14px;
  box-shadow: 0 24px 60px rgba(0, 0, 0, 0.4);
}
.ia-mark {
  width: 46px; height: 46px;
  border-radius: 50%;
  background: #FAF7F2;
  padding: 4px;
  box-shadow: 0 0 0 2.5px rgba(212, 168, 68, 0.55);
  flex-shrink: 0;
}
.ia-mark img { width: 100%; height: 100%; object-fit: contain; border-radius: 50%; }
.ia-input {
  width: 100%; min-width: 0;
  background: transparent; border: none; outline: none;
  color: #FAF7F2; font-size: 14px;
  padding: 10px 8px; font-family: inherit;
}
.ia-input::placeholder { color: rgba(250, 247, 242, 0.55); font-style: italic; }
.ia-input-mobile { display: none; }
.ia-submit {
  background: #D4A844; color: #0F2419;
  border: none; padding: 11px 22px;
  border-radius: 999px;
  font-weight: 600; font-size: 13px; cursor: pointer;
  white-space: nowrap; transition: all 0.2s;
  box-shadow: 0 8px 20px rgba(212, 168, 68, 0.3);
  font-family: inherit;
}
.ia-submit:hover { background: #E8B96B; transform: translateY(-1px); }
.ia-prompts {
  display: flex; gap: 8px; flex-wrap: wrap;
  justify-content: center; margin-top: 14px;
}
.ia-prompt {
  background: rgba(250, 247, 242, 0.08);
  color: rgba(250, 247, 242, 0.78);
  border: 1px solid rgba(212, 168, 68, 0.3);
  padding: 7px 14px;
  border-radius: 999px;
  font-size: 12px; font-family: inherit;
  cursor: pointer; transition: all 0.2s;
}
.ia-prompt:hover { background: rgba(212, 168, 68, 0.2); border-color: #D4A844; color: #FAF7F2; }

.hero-cta-secondary {
  display: inline-block;
  color: #E8B96B;
  font-size: 13px; text-decoration: none;
  margin-top: 6px; padding: 8px 14px;
  font-family: 'Cormorant Garamond', serif;
  font-style: italic;
  letter-spacing: 0.02em;
  transition: color 0.2s;
}
.hero-cta-secondary:hover { color: #D4A844; }

.hero-stats {
  margin-top: 24px;
  display: inline-flex; align-items: center; gap: 6px;
  padding: 8px 16px;
  background: rgba(15, 36, 25, 0.5);
  backdrop-filter: blur(8px);
  border-radius: 999px;
  font-size: 12px;
  color: rgba(250, 247, 242, 0.78);
  border: 1px solid rgba(232, 185, 107, 0.2);
}
.stats-dots { display: inline-flex; margin-right: 4px; }
.dot {
  width: 22px; height: 22px; border-radius: 50%;
  display: inline-flex; align-items: center; justify-content: center;
  font-size: 9px; font-weight: 600; color: #fff;
  font-family: 'Cormorant Garamond', serif;
}
.dot-1 { background: #D4A844; }
.dot-2 { background: #2D5A3D; margin-left: -6px; }
.dot-3 { background: #C45A2C; margin-left: -6px; }
.stats-num { font-family: 'Cormorant Garamond', serif; font-size: 14px; font-weight: 500; color: #FAF7F2; }

/* ========== BANDEAU CATÉGORIES ========== */
.cat-banner {
  background: rgba(31, 74, 54, 0.55);
  backdrop-filter: blur(10px);
  border-top: 1px solid rgba(212, 168, 68, 0.18);
  border-bottom: 1px solid rgba(212, 168, 68, 0.18);
  padding: 16px 0;
  position: relative;
  z-index: 5;
  overflow: hidden;
}
.cat-banner::before, .cat-banner::after {
  content: ''; position: absolute;
  top: 0; bottom: 0; width: 40px;
  z-index: 6; pointer-events: none;
}
.cat-banner::before { left: 0; background: linear-gradient(to right, #1A3A2A 0%, transparent 100%); }
.cat-banner::after { right: 0; background: linear-gradient(to left, #1A3A2A 0%, transparent 100%); }
@media (min-width: 900px) {
  .cat-banner::before, .cat-banner::after { display: none; }
}
.cat-banner-inner {
  display: flex; gap: 10px;
  overflow-x: auto;
  scroll-snap-type: x mandatory;
  scrollbar-width: none;
  padding: 0 32px;
  justify-content: flex-start;
  -webkit-overflow-scrolling: touch;
}
.cat-banner-inner::-webkit-scrollbar { display: none; }
@media (min-width: 900px) {
  .cat-banner-inner { justify-content: center; overflow-x: visible; }
}
.cat-chip {
  display: inline-flex; align-items: center; gap: 8px;
  padding: 10px 16px;
  background: rgba(250, 247, 242, 0.06);
  border: 1px solid rgba(212, 168, 68, 0.25);
  border-radius: 999px;
  font-family: inherit; font-size: 13px; font-weight: 500;
  color: #FAF7F2;
  cursor: pointer; white-space: nowrap;
  scroll-snap-align: start; flex-shrink: 0;
  transition: all 0.2s;
}
.cat-chip svg { width: 17px; height: 17px; color: #D4A844; flex-shrink: 0; }
.cat-chip:hover {
  background: rgba(212, 168, 68, 0.18);
  border-color: #D4A844;
  transform: translateY(-1px);
}

/* ========== SECTION HEADS ========== */
.section { padding: 90px 0; position: relative; }
.section-head { text-align: center; max-width: 720px; margin: 0 auto 56px; }
.section-eyebrow {
  display: inline-block;
  font-size: 12px; letter-spacing: 0.22em;
  text-transform: uppercase; color: #D4A844;
  font-weight: 500; margin-bottom: 16px;
}
.section h2 {
  font-family: 'Cormorant Garamond', serif;
  font-size: clamp(30px, 4.5vw, 46px);
  font-weight: 500; line-height: 1.1;
  color: #FAF7F2; letter-spacing: -0.01em;
  margin-bottom: 16px;
}
.section h2 em { font-style: italic; color: #E8B96B; }
.section-lede {
  font-family: 'Cormorant Garamond', serif;
  font-style: italic; font-size: 17px;
  color: rgba(250, 247, 242, 0.55);
  line-height: 1.55; max-width: 580px; margin: 0 auto;
}

/* ========== DESTINATIONS CARROUSEL ========== */
.destinations { background: #0F2419; }
.dest-carousel {
  display: flex; gap: 18px;
  overflow-x: auto;
  scroll-snap-type: x mandatory;
  scroll-behavior: smooth;
  scrollbar-width: none;
  padding: 8px 0 24px;
  -webkit-overflow-scrolling: touch;
}
.dest-carousel::-webkit-scrollbar { display: none; }
.dest-card {
  position: relative;
  background: #2D5A3D;
  border-radius: 20px;
  overflow: hidden;
  cursor: pointer;
  flex: 0 0 calc((100% - 36px) / 3);
  scroll-snap-align: start;
  transition: transform 0.3s, box-shadow 0.3s;
  border: none;
  padding: 0;
  text-align: left;
  font-family: inherit;
  color: inherit;
}
.dest-card:hover { transform: translateY(-6px); box-shadow: 0 20px 40px rgba(0, 0, 0, 0.35); }
.dest-card-img {
  width: 100%; height: 240px;
  object-fit: cover; display: block;
  transition: transform 0.5s;
}
.dest-card:hover .dest-card-img { transform: scale(1.06); }
.dest-card-body { padding: 18px 20px 22px; }
.dest-card-theme {
  font-size: 10px; letter-spacing: 0.18em;
  text-transform: uppercase; color: #D4A844;
  margin-bottom: 6px; font-weight: 500;
}
.dest-card-title {
  font-family: 'Cormorant Garamond', serif;
  font-size: 22px; font-weight: 500;
  color: #FAF7F2; line-height: 1.1;
  margin-bottom: 4px;
}
.dest-card-arabic {
  font-size: 13px; color: #E8B96B;
  opacity: 0.85; margin-left: 8px;
}
.dest-card-desc { font-size: 13px; color: rgba(250, 247, 242, 0.55); line-height: 1.5; }
.carousel-nav { display: flex; justify-content: center; gap: 12px; margin-top: 28px; }
.carousel-btn {
  width: 48px; height: 48px; border-radius: 50%;
  background: rgba(250, 247, 242, 0.08);
  border: 1px solid rgba(212, 168, 68, 0.4);
  color: #FAF7F2; font-size: 20px; font-weight: 600;
  cursor: pointer;
  display: flex; align-items: center; justify-content: center;
  transition: all 0.2s; font-family: inherit;
}
.carousel-btn:hover { background: #D4A844; color: #0F2419; border-color: #D4A844; transform: scale(1.06); }

/* ========== VOYAGES SIGNÉS ========== */
.signed-trips { background: #1A3A2A; }
.trips-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 22px; }
.trip-card {
  background: #2D5A3D;
  border-radius: 20px;
  overflow: hidden;
  cursor: pointer;
  transition: transform 0.3s, box-shadow 0.3s;
  display: flex; flex-direction: column;
}
.trip-card:hover { transform: translateY(-5px); box-shadow: 0 20px 40px rgba(0, 0, 0, 0.35); }
.trip-img-wrap { position: relative; height: 220px; overflow: hidden; }
.trip-img-wrap img { width: 100%; height: 100%; object-fit: cover; transition: transform 0.5s; }
.trip-card:hover .trip-img-wrap img { transform: scale(1.06); }
.trip-duration-badge {
  position: absolute; top: 14px; left: 14px;
  background: rgba(15, 36, 25, 0.85);
  color: #E8B96B;
  padding: 6px 12px;
  border-radius: 999px;
  font-size: 11px; letter-spacing: 0.1em;
  text-transform: uppercase; font-weight: 500;
  font-family: 'Cormorant Garamond', serif; font-style: italic;
}
.trip-body { padding: 20px 22px 22px; flex: 1; display: flex; flex-direction: column; }
.trip-title {
  font-family: 'Cormorant Garamond', serif;
  font-size: 22px; font-weight: 500;
  color: #FAF7F2; line-height: 1.15;
  margin-bottom: 10px;
}
.trip-desc { font-size: 14px; color: rgba(250, 247, 242, 0.55); line-height: 1.55; margin-bottom: 18px; flex: 1; }
.trip-foot {
  display: flex; justify-content: space-between; align-items: flex-end;
  padding-top: 16px;
  border-top: 1px solid rgba(212, 168, 68, 0.18);
}
.trip-guide { font-size: 12px; color: rgba(250, 247, 242, 0.55); }
.trip-guide strong {
  display: block;
  font-family: 'Cormorant Garamond', serif;
  font-style: italic; font-weight: 500;
  font-size: 15px; color: #E8B96B;
  margin-bottom: 2px;
}
.trip-price {
  font-family: 'Cormorant Garamond', serif;
  font-size: 22px; font-weight: 500;
  color: #D4A844; text-align: right; line-height: 1;
}
.trip-price small {
  display: block; font-style: italic;
  font-size: 10px; color: rgba(250, 247, 242, 0.55);
  margin-top: 4px; letter-spacing: 0.06em;
}

/* ========== TÉMOIGNAGE ========== */
.testimonial { background: #0F2419; padding: 80px 32px; text-align: center; }
.testimonial-inner { max-width: 680px; margin: 0 auto; }
.testimonial-avatar {
  width: 72px; height: 72px; border-radius: 50%;
  object-fit: cover; margin: 0 auto 24px;
  border: 3px solid #D4A844;
  display: block;
}
.testimonial-quote {
  font-family: 'Cormorant Garamond', serif;
  font-style: italic; font-size: 22px;
  color: #FAF7F2; line-height: 1.45;
  margin-bottom: 18px;
}
.testimonial-quote::before { content: '« '; color: #D4A844; }
.testimonial-quote::after { content: ' »'; color: #D4A844; }
.testimonial-name { font-size: 13px; color: #E8B96B; letter-spacing: 0.08em; }

/* ========== RESPONSIVE ========== */
@media (max-width: 900px) {
  .hero { height: auto; min-height: 100vh; padding: 0; }
  .hero-content { padding: 100px 20px 40px; }
  .hero h1 { font-size: 42px; }
  .hero p { font-size: 16px; margin-bottom: 24px; }
  .djawal-container { padding: 0 20px; }
  .cat-banner-inner { padding: 0 20px; }
  .trips-grid { grid-template-columns: 1fr; gap: 18px; }
  .dest-card { flex: 0 0 calc((100% - 24px) / 3); }
  .dest-card-img { height: 200px; }
  .dest-card-title { font-size: 18px; }
  .section { padding: 70px 0; }
}
@media (max-width: 600px) {
  .hero-content { padding: 88px 16px 32px; }
  .hero h1 { font-size: 32px; line-height: 1.1; }
  .hero p { font-size: 15px; margin-bottom: 20px; }
  .hero-eyebrow { font-size: 10px; padding: 6px 14px; margin-bottom: 20px; }
  .hero-stats { font-size: 11px; padding: 7px 14px; flex-wrap: wrap; justify-content: center; }
  .hero-cta-secondary { font-size: 12px; }

  /* Bandeau IA mobile : compact horizontal */
  .hero-ia { max-width: 100%; margin: 0 auto 14px; padding: 0 4px; }
  .ia-pill { grid-template-columns: 40px 1fr auto; padding: 6px 8px; gap: 8px; }
  .ia-mark { width: 40px; height: 40px; padding: 3px; }
  .ia-input { padding: 10px 4px; font-size: 13px; }
  .ia-input-desktop { display: none; }
  .ia-input-mobile { display: block; }
  .ia-submit { padding: 9px 14px; font-size: 12px; }
  .ia-prompts { gap: 6px; margin-top: 10px; }
  .ia-prompt { font-size: 11px; padding: 6px 12px; }

  .dest-card { flex: 0 0 calc((100% - 16px) / 3); }
  .dest-card-img { height: 140px; }
  .dest-card-title { font-size: 14px; }
  .dest-card-desc { font-size: 11px; }
  .dest-card-arabic { display: none; }
  .dest-card-body { padding: 12px 14px 14px; }
  .dest-card-theme { font-size: 9px; margin-bottom: 4px; }

  .section { padding: 56px 0; }
  .section h2 { font-size: 26px; }
  .section-eyebrow { font-size: 11px; }
  .section-lede { font-size: 15px; }
  .trip-img-wrap { height: 180px; }
  .trip-title { font-size: 19px; }
  .testimonial { padding: 60px 16px; }
  .testimonial-quote { font-size: 18px; }
  .cat-chip { padding: 9px 14px; font-size: 12px; }
  .cat-chip svg { width: 15px; height: 15px; }
  .carousel-btn { width: 42px; height: 42px; font-size: 18px; }
}
@media (max-width: 380px) {
  .hero h1 { font-size: 28px; }
  .ia-pill { grid-template-columns: 36px 1fr auto; padding: 5px 6px; gap: 6px; }
  .ia-mark { width: 36px; height: 36px; padding: 2px; }
  .ia-input { font-size: 12px; padding: 8px 2px; }
  .ia-submit { padding: 8px 12px; font-size: 11px; }
  .ia-prompt { font-size: 10px; padding: 5px 10px; }
  .dest-card { flex: 0 0 calc((100% - 16px) / 2); }
}
</style>
