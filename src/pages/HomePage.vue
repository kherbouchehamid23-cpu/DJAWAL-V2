<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useSEO } from '@/composables/useSEO'
useSEO({
  title: "L'Algérie, vécue de l'intérieur",
  description: "Du cœur de la Casbah aux dunes du Tassili. Connectez-vous avec les habitants ou laissez Djawal IA composer votre aventure sur-mesure."
})

const router = useRouter()
// Stats honnêtes : comptages réels en base, jamais de valeurs gonflées.
const stats = ref({ destinations: 0, guides: 0 })
const showStats = ref(false)

function fmtPriceDA(p: number) {
  return new Intl.NumberFormat('fr-DZ').format(p) + ' DA'
}

function goToComposer(prefill?: string) {
  if (prefill) router.push({ path: '/composer', query: { q: prefill } })
  else router.push('/composer')
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

// ===== Types cards =====
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
  mode?: 'signed' | 'agency'
}

// Fallback si BDD vide
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
  { title: 'Cœur du Hoggar : silence et étoiles', duration: '9 jours', desc: "Marche douce dans l'Atakor. Nuit chez les Touaregs. Lever de lune sur l'Assekrem.", guide: 'Yacine', guideRole: 'Touareg du Hoggar', price: '218 000 DA', img: 'https://images.pexels.com/photos/2382325/pexels-photo-2382325.jpeg?auto=compress&cs=tinysrgb&w=800', mode: 'signed' },
  { title: "L'Algérie mauresque : Tlemcen, Casbah, Tipaza", duration: '7 jours', desc: 'Trois capitales, trois siècles. Mansourah, Casbah, ruines romaines face à la mer.', guide: 'Lina', guideRole: "Casbah d'Alger", price: '174 000 DA', img: 'https://images.pexels.com/photos/29639897/pexels-photo-29639897.jpeg?auto=compress&cs=tinysrgb&w=800', mode: 'signed' },
  { title: "M'Zab : l'épure pour philosophie", duration: '5 jours', desc: "Ghardaïa, Beni Isguen, El Atteuf. La sobriété mozabite comme art de vivre.", guide: 'Hamid', guideRole: "Senior · M'Zab", price: '131 000 DA', img: 'https://images.pexels.com/photos/1631665/pexels-photo-1631665.jpeg?auto=compress&cs=tinysrgb&w=800', mode: 'signed' }
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

// ===== GUIDES FEATURED =====
interface FeaturedGuide {
  id: string
  display_name: string | null
  avatar_url: string | null
  role: 'guide_senior' | 'guide_junior'
  region: string | null
  specialties: string[] | null
  bio: string | null
  rating?: number | null
  reviewCount?: number
}
const featuredGuides = ref<FeaturedGuide[]>([])

async function loadFeaturedGuides() {
  const { data } = await supabase
    .from('profiles')
    .select('id, display_name, avatar_url, role, region, specialties, bio')
    .in('role', ['guide_senior', 'guide_junior'])
    .eq('kyc_status', 'approved')
    .eq('is_active', true)
    .order('role', { ascending: false })
    .limit(4)
  if (!data || data.length === 0) return
  const list = data as FeaturedGuide[]
  const ids = list.map(g => g.id)
  const { data: aggData } = await supabase
    .from('review_aggregates')
    .select('target_id, average_rating, review_count')
    .eq('target_type', 'guide')
    .in('target_id', ids)
  const ratingMap = new Map(
    (aggData || []).map((a: any) => [a.target_id, { rating: Number(a.average_rating), count: a.review_count }])
  )
  for (const g of list) {
    const r = ratingMap.get(g.id)
    if (r) { g.rating = r.rating; g.reviewCount = r.count }
  }
  featuredGuides.value = list
}

function guideInitial(name?: string | null): string {
  return (name || '?')[0].toUpperCase()
}
function openGuide(id: string) {
  router.push(`/guide/${id}`)
}

// ===== MINI-CHAT IA HOME =====
interface ChatMsg {
  role: 'user' | 'ai'
  text: string
}
const chatMessages = ref<ChatMsg[]>([])
const chatInput = ref('')
const chatLoading = ref(false)
const chatStarted = ref(false)

const homeChatPrompts = [
  { icon: '📍', label: "Je suis à Béjaïa demain. Quoi faire avec deux enfants ?" },
  { icon: '🛏', label: "Un riad ou maison d'hôte de caractère à Ghardaïa ?" },
  { icon: '⏱', label: "Trois jours à Oran sans toucher à la plage. Possible ?" }
]

async function sendChatMessage(text?: string) {
  const q = (text ?? chatInput.value).trim()
  if (!q || chatLoading.value) return
  chatStarted.value = true
  chatMessages.value.push({ role: 'user', text: q })
  chatInput.value = ''
  chatLoading.value = true
  try {
    const { data, error } = await supabase.functions.invoke('ai-assistant', {
      body: { question: q, user_id: null }
    })
    if (error) throw error
    const ans = (data && (data.answer || data.message)) as string | undefined
    if (data?.mode === 'too-vague' || data?.mode === 'needs-clarification') {
      chatMessages.value.push({
        role: 'ai',
        text: data.answer || "Pour vous répondre précisément, j'ai besoin de quelques détails. Cliquez sur « Continuer dans Djawal IA » ci-dessous."
      })
    } else if (ans) {
      chatMessages.value.push({ role: 'ai', text: ans })
    } else {
      chatMessages.value.push({ role: 'ai', text: 'Je suis là — pourriez-vous reformuler votre question ?' })
    }
  } catch (e: any) {
    chatMessages.value.push({
      role: 'ai',
      text: "Je n'ai pas pu répondre tout de suite. Réessayez ou continuez avec Djawal IA en pleine page."
    })
  } finally {
    chatLoading.value = false
  }
}

function continueInComposer() {
  const lastUser = [...chatMessages.value].reverse().find(m => m.role === 'user')
  if (lastUser) router.push({ path: '/composer', query: { q: lastUser.text } })
  else router.push('/composer')
}

// Parser markdown minimal pour bulles IA : **gras**, *italique*, retours à la ligne
function formatMessage(text: string): string {
  if (!text) return ''
  // Échapper HTML pour éviter XSS
  let html = text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
  // **gras**
  html = html.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
  // *italique* (uniquement si pas déjà dans **)
  html = html.replace(/(^|[^*])\*([^*]+)\*([^*]|$)/g, '$1<em>$2</em>$3')
  // retours à la ligne
  html = html.replace(/\n/g, '<br>')
  return html
}

onMounted(async () => {
  // Stats réelles (guides approuvés + destinations publiées)
  const { count: guidesCount } = await supabase
    .from('profiles')
    .select('id', { count: 'exact', head: true })
    .in('role', ['guide_senior', 'guide_junior'])
    .eq('kyc_status', 'approved')
  const { count: destCount } = await supabase
    .from('destinations')
    .select('id', { count: 'exact', head: true })
  stats.value.guides = guidesCount || 0
  stats.value.destinations = destCount || 0
  showStats.value = (stats.value.guides > 0 || stats.value.destinations > 0)

  // Destinations vedettes : 1) featured d'abord 2) sinon top 10 DB 3) sinon fallback statique
  const mapDest = (d: any) => ({
    id: d.id,
    name: d.name,
    sub: d.tagline || (d.cultural_theme ? d.cultural_theme.charAt(0).toUpperCase() + d.cultural_theme.slice(1) : ''),
    arabic: d.name_ar || '',
    desc: (d.description || '').slice(0, 80),
    img: d.hero_image_url || '',
    theme: d.cultural_theme || 'mauresque'
  })
  const { data: featuredData } = await supabase
    .from('destinations')
    .select('id, name, name_ar, tagline, description, hero_image_url, cultural_theme')
    .eq('is_featured_homepage', true)
    .order('homepage_display_order', { ascending: true })
  if (featuredData && featuredData.length > 0) {
    heroCards.value = featuredData.map(mapDest)
  } else {
    // Aucune featured : fetch toutes les destinations DB pour garantir un id réel cliquable
    const { data: allDest } = await supabase
      .from('destinations')
      .select('id, name, name_ar, tagline, description, hero_image_url, cultural_theme')
      .order('name', { ascending: true })
      .limit(10)
    if (allDest && allDest.length > 0) {
      heroCards.value = allDest.map(mapDest)
    }
    // Sinon on garde fallbackHeroCards statique (DB vide, dev offline)
  }

  // Voyages signés + packages agence
  const { data: tripData } = await supabase
    .from('trips')
    .select(`
      id, title, duration_days, price_da, description, cover_image_url, tags, composition_mode,
      profiles!trips_created_by_fkey(display_name, region, role)
    `)
    .eq('is_featured_homepage', true)
    .eq('status', 'published')
    .order('homepage_display_order', { ascending: true })
    .limit(6)
  if (tripData && tripData.length > 0) {
    signedTrips.value = tripData.map((t: any) => ({
      id: t.id,
      title: t.title,
      duration: `${t.duration_days} jour${t.duration_days > 1 ? 's' : ''}`,
      desc: (t.description || '').slice(0, 140),
      guide: t.profiles?.display_name || 'Guide Djawal',
      guideRole: t.profiles?.region || (t.profiles?.role === 'guide_senior' ? 'Guide Senior' : (t.profiles?.role === 'tourist_operator' ? 'Opérateur touristique' : 'Guide Djawal')),
      price: fmtPriceDA(t.price_da || 0),
      img: t.cover_image_url || '',
      mode: t.composition_mode === 'agency_package' ? 'agency' : 'signed'
    }))
  }

  await loadFeaturedGuides()
})
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

        <!-- DOUBLE CTA -->
        <div class="hero-duo" role="group" aria-label="Choisissez votre point de départ">
          <button class="hero-duo-card is-chat" type="button" aria-label="Discuter avec Djawal IA" @click="router.push('/composer')">
            <span class="duo-icon" aria-hidden="true">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
                <path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"/>
                <line x1="8.5" y1="11.5" x2="8.51" y2="11.5"/>
                <line x1="12" y1="11.5" x2="12.01" y2="11.5"/>
                <line x1="15.5" y1="11.5" x2="15.51" y2="11.5"/>
              </svg>
            </span>
            <span class="duo-text">
              <span class="duo-title">Discuter avec Djawal IA<span class="arrow" aria-hidden="true">→</span></span>
              <span class="duo-sub">Posez votre question — restaurant, hôtel, activité, en direct.</span>
            </span>
          </button>
          <button class="hero-duo-card is-compose" type="button" aria-label="Composer mon voyage en mode guidé" @click="router.push('/composer/formulaire')">
            <span class="duo-icon" aria-hidden="true">
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round">
                <circle cx="12" cy="12" r="9"/>
                <polygon points="14.5 9.5 9.5 14.5 9.5 9.5 14.5 9.5" fill="currentColor" stroke="none"/>
              </svg>
            </span>
            <span class="duo-text">
              <span class="duo-title">Composer mon voyage<span class="arrow" aria-hidden="true">→</span></span>
              <span class="duo-sub">Parcours guidé en quelques étapes — sur-mesure, signé par un guide.</span>
            </span>
          </button>
        </div>

        <div class="hero-pills" aria-label="Idées de voyage rapides">
          <button v-for="p in quickPrompts" :key="p.label" type="button" class="hero-pill" @click="goToComposer(p.q)">
            {{ p.label }}
          </button>
        </div>

        <a href="#destinations" class="hero-cta-secondary">
          Ou parcourir nos voyages signés <span aria-hidden="true">↓</span>
        </a>

        <div class="hero-stats" v-if="showStats">
          <span class="stats-dots" aria-hidden="true">
            <span class="dot dot-1">A</span>
            <span class="dot dot-2">Y</span>
            <span class="dot dot-3">L</span>
          </span>
          <span class="stats-num">{{ fmtNumber(stats.destinations) }}</span> destinations ·
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
          <div class="section-eyebrow">— Territoires à explorer —</div>
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

    <!-- VOYAGES SIGNÉS + PACKAGES AGENCE -->
    <section class="section signed-trips">
      <div class="djawal-container">
        <header class="section-head">
          <div class="section-eyebrow">— Voyages signés &amp; packages agence —</div>
          <h2>Des récits, des <em>quêtes différentes</em>.</h2>
          <p class="section-lede">Pas un catalogue. Des invitations à vivre — composées par les guides locaux ou nos opérateurs partenaires.</p>
        </header>
        <div class="trips-grid">
          <article v-for="t in signedTrips" :key="t.id || t.title" class="trip-card"
                   @click="t.id ? router.push('/voyages/' + t.id) : router.push('/voyages')">
            <div class="trip-img-wrap">
              <img :src="t.img" :alt="t.title" loading="lazy" />
              <span class="trip-duration-badge">{{ t.duration }}</span>
              <span v-if="t.mode === 'agency'" class="trip-mode-badge agency">📦 Package agence</span>
              <span v-else class="trip-mode-badge signed">✍️ Signé Djawal</span>
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

    <!-- GUIDES FEATURED -->
    <section v-if="featuredGuides.length > 0" class="section guides-section">
      <div class="djawal-container">
        <header class="section-head">
          <div class="section-eyebrow">— Les voix du pays —</div>
          <h2>Vos guides, <em>vos hôtes</em>.</h2>
          <p class="section-lede">Tous rencontrés en visio avant d'apparaître ici. Tous évalués par les voyageurs qu'ils ont accompagnés.</p>
        </header>
        <div class="guides-grid">
          <article v-for="g in featuredGuides" :key="g.id" class="guide-card"
                   @click="openGuide(g.id)" tabindex="0" role="button" @keydown.enter="openGuide(g.id)">
            <div class="guide-portrait">
              <img v-if="g.avatar_url" :src="g.avatar_url" :alt="g.display_name || 'Guide'" loading="lazy" />
              <div v-else class="portrait-fallback"><span>{{ guideInitial(g.display_name) }}</span></div>
              <span v-if="g.role === 'guide_senior'" class="guide-badge senior">⭐ Senior</span>
              <span v-else class="guide-badge junior">Junior</span>
              <span v-if="g.rating" class="guide-rating">
                <span class="star">★</span> {{ g.rating.toFixed(1) }}<small v-if="g.reviewCount">·{{ g.reviewCount }}</small>
              </span>
            </div>
            <div class="guide-info">
              <div class="guide-meta" v-if="g.region">📍 {{ g.region }}</div>
              <h3 class="guide-name">{{ g.display_name || 'Guide Djawal' }}</h3>
              <p v-if="g.specialties && g.specialties.length > 0" class="guide-spec">{{ g.specialties.slice(0, 2).join(' · ') }}</p>
              <p v-else-if="g.bio" class="guide-spec">{{ g.bio.slice(0, 80) }}{{ g.bio.length > 80 ? '…' : '' }}</p>
            </div>
          </article>
        </div>
        <div class="section-foot">
          <router-link to="/guides" class="see-all-btn">Découvrir tous nos guides →</router-link>
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

    <!-- DJAWAL IA — mini-chat fonctionnel -->
    <section class="section ia-section" id="djawal-ia">
      <div class="djawal-container">
        <div class="ia-grid">
          <div class="ia-text">
            <div class="section-eyebrow">— Djawal IA —</div>
            <h2 class="ia-h2">Posez-lui la question<br/>qu'on pose à un <em>cousin du pays</em>.</h2>
            <p class="ia-lede">Restaurants, hôtels, randos, monuments — Djawal IA connaît horaires, saisons et secrets, et cite ses sources : guides locaux et souvenirs des voyageurs.</p>
            <div class="ia-prompts-list">
              <button v-for="p in homeChatPrompts" :key="p.label" class="ia-prompt-btn" type="button"
                      @click="sendChatMessage(p.label)" :disabled="chatLoading">
                <span class="ia-prompt-icon">{{ p.icon }}</span>
                <span class="ia-prompt-text">{{ p.label }}</span>
              </button>
            </div>
          </div>

          <div class="ia-chat">
            <div class="chat-head">
              <div class="chat-avatar">D</div>
              <div class="chat-meta">
                <strong>Djawal IA</strong>
                <span class="status"><span class="dot"></span> En ligne · répond en français</span>
              </div>
            </div>

            <div class="chat-log" :class="{ empty: !chatStarted }">
              <div v-if="!chatStarted" class="chat-empty">
                <p class="empty-italic">« Marhaba ! Décris-moi ton voyage idéal ou pose-moi une question concrète. »</p>
                <p class="empty-hint">Clique un des exemples à gauche ou écris ci-dessous.</p>
              </div>
              <template v-else>
                <div v-for="(m, i) in chatMessages" :key="i" class="chat-msg" :class="m.role">
                  <div v-if="m.role === 'user'" class="bubble user-bubble">{{ m.text }}</div>
                  <div v-else class="bubble ai-bubble" v-html="formatMessage(m.text)"></div>
                </div>
                <div v-if="chatLoading" class="chat-msg ai">
                  <div class="bubble ai-bubble typing"><span></span><span></span><span></span></div>
                </div>
              </template>
            </div>

            <form class="chat-input-wrap" @submit.prevent="sendChatMessage()">
              <input v-model="chatInput" type="text" placeholder="Demandez à Djawal IA…" aria-label="Message à Djawal IA" :disabled="chatLoading" />
              <button class="send-btn" type="submit" aria-label="Envoyer" :disabled="chatLoading || !chatInput.trim()">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
                  <line x1="5" y1="12" x2="19" y2="12"/><polyline points="13 6 19 12 13 18"/>
                </svg>
              </button>
            </form>

            <button v-if="chatStarted" class="continue-btn" type="button" @click="continueInComposer">
              Continuer dans Djawal IA (pleine page) →
            </button>
          </div>
        </div>
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

/* === HERO === */
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
  max-width: 880px;
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

/* === DOUBLE CTA HERO === */
.hero-duo {
  display: grid;
  grid-template-columns: 1fr;
  gap: 12px;
  max-width: 760px;
  margin: 0 auto 18px;
}
@media (min-width: 641px) { .hero-duo { grid-template-columns: 1fr 1fr; gap: 14px; } }
.hero-duo-card {
  display: flex; align-items: center; gap: 14px;
  padding: 14px 18px 14px 14px;
  border-radius: 14px;
  text-align: left;
  cursor: pointer;
  border: none;
  font-family: inherit;
  transition: all 0.3s ease;
}
.duo-icon {
  flex-shrink: 0; width: 44px; height: 44px;
  border-radius: 50%;
  display: grid; place-items: center;
  transition: transform 0.3s ease;
}
.hero-duo-card:hover .duo-icon { transform: scale(1.08) rotate(-4deg); }
.duo-text { flex: 1; min-width: 0; }
.duo-title {
  font-weight: 600; font-size: 14.5px;
  letter-spacing: 0.01em; line-height: 1.2;
  margin-bottom: 2px;
  display: flex; align-items: center; gap: 6px;
}
.duo-title .arrow { font-weight: 400; font-size: 16px; opacity: 0.7; transition: transform 0.28s ease; }
.hero-duo-card:hover .duo-title .arrow { transform: translateX(4px); }
.duo-sub {
  font-family: 'Cormorant Garamond', serif;
  font-style: italic; font-size: 13px;
  line-height: 1.35; opacity: 0.88;
  display: block;
}
.hero-duo-card.is-chat {
  background: rgba(26, 58, 42, 0.65);
  border: 1px solid rgba(212, 168, 68, 0.3);
  color: #FAF7F2;
  backdrop-filter: blur(14px); -webkit-backdrop-filter: blur(14px);
}
.hero-duo-card.is-chat:hover { background: rgba(26, 58, 42, 0.85); border-color: #D4A844; }
.hero-duo-card.is-chat .duo-icon {
  background: rgba(212, 168, 68, 0.12);
  border: 1px solid rgba(212, 168, 68, 0.35);
  color: #D4A844;
}
.hero-duo-card.is-compose {
  background: #D4A844; color: #0F2419;
  border: 1px solid #D4A844;
  box-shadow: 0 4px 24px rgba(212, 168, 68, 0.3);
}
.hero-duo-card.is-compose:hover { background: #E8B96B; transform: translateY(-2px); box-shadow: 0 8px 36px rgba(212, 168, 68, 0.4); }
.hero-duo-card.is-compose .duo-icon {
  background: rgba(15, 36, 25, 0.25); color: #0F2419;
  border: 1px solid rgba(15, 36, 25, 0.3);
}
.hero-duo-card.is-compose .duo-sub { color: rgba(15, 36, 25, 0.78); }

/* === HERO PILLS === */
.hero-pills { display: flex; flex-wrap: wrap; gap: 8px; justify-content: center; margin-bottom: 14px; }
.hero-pill {
  padding: 8px 16px; border-radius: 999px;
  background: rgba(15, 36, 25, 0.55);
  border: 1px solid rgba(212, 168, 68, 0.3);
  color: rgba(250, 247, 242, 0.85);
  font-size: 12.5px; font-family: inherit; cursor: pointer;
  transition: all 0.2s ease;
  backdrop-filter: blur(8px); -webkit-backdrop-filter: blur(8px);
}
.hero-pill:hover { background: rgba(212, 168, 68, 0.18); color: #FAF7F2; border-color: #D4A844; }

/* === CTA secondary + stats === */
.hero-cta-secondary {
  display: inline-block; color: #E8B96B;
  font-size: 13px; text-decoration: none;
  margin-top: 6px; padding: 6px 12px;
  font-family: 'Cormorant Garamond', serif; font-style: italic;
  transition: color 0.2s;
}
.hero-cta-secondary:hover { color: #D4A844; }
.hero-stats {
  margin-top: 20px;
  display: inline-flex; align-items: center; gap: 8px;
  padding: 8px 16px;
  background: rgba(15, 36, 25, 0.6);
  border: 1px solid rgba(232, 185, 107, 0.2);
  border-radius: 999px;
  font-size: 12.5px; color: rgba(250, 247, 242, 0.85);
  backdrop-filter: blur(8px);
}
.stats-num { color: #E8B96B; font-weight: 600; font-family: 'Cormorant Garamond', serif; font-size: 14px; }
.stats-dots { display: inline-flex; margin-right: 4px; }
.stats-dots .dot {
  width: 22px; height: 22px; border-radius: 50%;
  display: inline-flex; align-items: center; justify-content: center;
  font-size: 9px; font-weight: 600; color: #fff;
  font-family: 'Cormorant Garamond', serif;
}
.stats-dots .dot:not(:first-child) { margin-left: -6px; }
.stats-dots .dot-1 { background: #D4A844; z-index: 3; }
.stats-dots .dot-2 { background: #2D5A3D; z-index: 2; }
.stats-dots .dot-3 { background: #C45A2C; z-index: 1; }

/* === CAT-BANNER === */
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
@media (min-width: 900px) { .cat-banner::before, .cat-banner::after { display: none; } }
.cat-banner-inner {
  display: flex; gap: 10px;
  overflow-x: auto;
  scroll-snap-type: x mandatory;
  scrollbar-width: none;
  padding: 0 32px;
  -webkit-overflow-scrolling: touch;
}
.cat-banner-inner::-webkit-scrollbar { display: none; }
@media (min-width: 900px) { .cat-banner-inner { justify-content: center; overflow-x: visible; } }
.cat-chip {
  display: inline-flex; align-items: center; gap: 8px;
  padding: 10px 16px;
  background: rgba(250, 247, 242, 0.06);
  border: 1px solid rgba(212, 168, 68, 0.25);
  border-radius: 999px;
  font-family: inherit; font-size: 13px; font-weight: 500;
  color: #FAF7F2; cursor: pointer; white-space: nowrap;
  scroll-snap-align: start; flex-shrink: 0;
  transition: all 0.2s;
}
.cat-chip svg { width: 17px; height: 17px; color: #D4A844; flex-shrink: 0; }
.cat-chip:hover { background: rgba(212, 168, 68, 0.18); border-color: #D4A844; transform: translateY(-1px); }

/* === SECTION COMMON === */
.section {
  padding: 90px 0;
  position: relative;
  /* Forcer fond sombre cohérent sur toutes les sections (évite "Choisissez" blanc invisible sur beige) */
  background: #1A3A2A;
  color: #FAF7F2;
}
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
.section-foot { text-align: center; margin-top: 40px; }
.see-all-btn {
  display: inline-block; padding: 12px 24px;
  border: 1px solid rgba(212, 168, 68, 0.4);
  border-bottom: 2px solid #D4A844;
  color: #D4A844;
  font-size: 13px; letter-spacing: 0.04em;
  text-decoration: none; border-radius: 4px;
  transition: all 0.2s ease;
}
.see-all-btn:hover { background: rgba(212, 168, 68, 0.12); color: #FAF7F2; }

/* === DESTINATIONS CARROUSEL === */
.dest-carousel-wrap { position: relative; }
.dest-carousel {
  display: flex; gap: 18px;
  overflow-x: auto;
  scroll-snap-type: x mandatory;
  padding: 4px 4px 18px;
  scrollbar-width: none;
}
.dest-carousel::-webkit-scrollbar { display: none; }
.dest-card {
  flex: 0 0 280px; scroll-snap-align: start;
  background: rgba(31, 74, 54, 0.55);
  border: 1px solid rgba(245, 239, 230, 0.08);
  border-radius: 6px; overflow: hidden;
  cursor: pointer; text-align: left;
  font-family: inherit; padding: 0;
  transition: all 0.3s ease;
}
.dest-card:hover { transform: translateY(-4px); border-color: rgba(212, 168, 68, 0.5); }
.dest-card-img {
  width: 100%; aspect-ratio: 4/5;
  object-fit: cover; display: block;
  background: linear-gradient(135deg, #2D5A3D, #1A3A2A);
}
.dest-card-body { padding: 16px 18px; }
.dest-card-theme {
  font-size: 10.5px; letter-spacing: 0.18em; text-transform: uppercase;
  color: #B8862E; font-weight: 500; margin-bottom: 8px;
}
.dest-card-title {
  font-family: 'Cormorant Garamond', serif;
  font-weight: 500; font-size: 21px;
  color: #FAF7F2; margin-bottom: 4px; line-height: 1.15;
}
.dest-card-arabic { font-size: 13px; opacity: 0.7; margin-left: 6px; font-weight: 400; }
.dest-card-desc {
  font-family: 'Cormorant Garamond', serif; font-style: italic;
  font-size: 13.5px; color: rgba(250, 247, 242, 0.7); line-height: 1.4;
}
.carousel-nav { display: flex; justify-content: center; gap: 10px; margin-top: 20px; }
.carousel-btn {
  width: 44px; height: 44px; border-radius: 50%;
  background: rgba(31, 74, 54, 0.6);
  border: 1px solid rgba(212, 168, 68, 0.3);
  color: #D4A844; font-family: inherit; font-size: 16px;
  cursor: pointer; transition: all 0.2s ease;
}
.carousel-btn:hover { background: rgba(212, 168, 68, 0.18); border-color: #D4A844; color: #FAF7F2; }

/* === TRIPS GRID + MODE BADGE === */
.trips-grid {
  display: grid; grid-template-columns: 1fr; gap: 24px;
  max-width: 1100px; margin: 0 auto;
}
@media (min-width: 641px) { .trips-grid { grid-template-columns: repeat(2, 1fr); } }
@media (min-width: 1025px) { .trips-grid { grid-template-columns: repeat(3, 1fr); gap: 28px; } }
.trip-card {
  background: rgba(31, 74, 54, 0.55);
  border: 1px solid rgba(245, 239, 230, 0.08);
  border-radius: 6px; overflow: hidden;
  cursor: pointer; transition: all 0.3s ease;
}
.trip-card:hover { transform: translateY(-4px); border-color: rgba(212, 168, 68, 0.5); box-shadow: 0 12px 32px rgba(0, 0, 0, 0.25); }
.trip-img-wrap { position: relative; aspect-ratio: 16/10; overflow: hidden; }
.trip-img-wrap img { width: 100%; height: 100%; object-fit: cover; display: block; }
.trip-duration-badge {
  position: absolute; top: 12px; left: 12px;
  padding: 5px 12px;
  background: rgba(15, 36, 25, 0.85); backdrop-filter: blur(8px);
  border-radius: 999px;
  font-size: 11px; letter-spacing: 0.12em; text-transform: uppercase;
  color: #E8B96B; font-weight: 600; z-index: 2;
}
.trip-mode-badge {
  position: absolute; top: 12px; right: 12px;
  padding: 5px 11px; border-radius: 999px;
  font-size: 10.5px; letter-spacing: 0.05em; font-weight: 700;
  z-index: 2; backdrop-filter: blur(8px);
}
.trip-mode-badge.signed { background: rgba(212, 168, 68, 0.92); color: #0F2419; }
.trip-mode-badge.agency { background: rgba(40, 52, 97, 0.92); color: #E8B96B; }
.trip-body { padding: 18px 22px 22px; }
.trip-title {
  font-family: 'Cormorant Garamond', serif;
  font-weight: 500; font-size: 22px; color: #FAF7F2;
  margin-bottom: 8px; letter-spacing: -0.01em; line-height: 1.2;
}
.trip-desc {
  font-family: 'Cormorant Garamond', serif; font-style: italic;
  font-size: 14.5px; color: rgba(250, 247, 242, 0.7);
  line-height: 1.5; margin-bottom: 18px;
}
.trip-foot {
  display: flex; justify-content: space-between; align-items: center;
  padding-top: 16px; border-top: 1px solid rgba(212, 168, 68, 0.15);
  font-size: 13px;
}
.trip-guide { color: rgba(250, 247, 242, 0.75); }
.trip-guide strong { display: block; color: #FAF7F2; font-weight: 600; font-size: 13px; margin-bottom: 2px; }
.trip-price {
  font-family: 'Cormorant Garamond', serif; font-weight: 600;
  color: #D4A844; font-size: 18px; text-align: right;
}
.trip-price small {
  display: block; font-size: 10px; letter-spacing: 0.1em; text-transform: uppercase;
  color: rgba(250, 247, 242, 0.5); font-family: 'Inter', sans-serif;
  font-weight: 400; margin-top: 3px;
}

/* === GUIDES SECTION === */
.guides-section { background: rgba(15, 36, 25, 0.6); }
.guides-grid {
  display: grid; grid-template-columns: repeat(2, 1fr);
  gap: 18px; max-width: 1100px; margin: 0 auto;
}
@media (min-width: 641px) { .guides-grid { grid-template-columns: repeat(4, 1fr); } }
.guide-card { cursor: pointer; transition: transform 0.3s ease; }
.guide-card:hover { transform: translateY(-3px); }
.guide-card:focus-visible { outline: 2px solid #E8B96B; outline-offset: 4px; border-radius: 4px; }
.guide-portrait {
  aspect-ratio: 4/5; position: relative;
  border-radius: 4px; overflow: hidden;
  margin-bottom: 12px;
  background: linear-gradient(160deg, #2D5A3D 0%, #1A3A2A 100%);
  border: 1px solid rgba(212, 168, 68, 0.15);
}
.guide-portrait img { width: 100%; height: 100%; object-fit: cover; display: block; }
.portrait-fallback {
  position: absolute; inset: 0;
  display: flex; align-items: center; justify-content: center;
  font-family: 'Cormorant Garamond', serif;
  font-size: 50px; color: #E8B96B; font-weight: 500;
  background: linear-gradient(135deg, #2D5A3D 0%, #B8862E 100%);
}
.guide-badge {
  position: absolute; top: 8px; left: 8px;
  padding: 3px 9px; border-radius: 999px;
  font-size: 9.5px; letter-spacing: 0.1em; text-transform: uppercase;
  font-weight: 700; z-index: 3;
}
.guide-badge.senior { background: linear-gradient(135deg, #D4A844, #B8862E); color: #0F2419; }
.guide-badge.junior { background: rgba(15, 36, 25, 0.78); color: #E8B96B; border: 1px solid rgba(212, 168, 68, 0.4); }
.guide-rating {
  position: absolute; bottom: 8px; left: 8px;
  display: inline-flex; align-items: center; gap: 3px;
  padding: 3px 8px;
  background: rgba(15, 36, 25, 0.85); backdrop-filter: blur(8px);
  border-radius: 999px;
  font-size: 11px; color: #FAF7F2; z-index: 3;
  border: 1px solid rgba(212, 168, 68, 0.3);
}
.guide-rating .star { color: #E8B96B; }
.guide-rating small { opacity: 0.7; margin-left: 2px; font-size: 9.5px; }
.guide-info { padding: 0 2px; }
.guide-meta {
  font-size: 10.5px; letter-spacing: 0.18em; text-transform: uppercase;
  color: #B8862E; font-weight: 500; margin-bottom: 4px;
}
.guide-name {
  font-family: 'Cormorant Garamond', serif;
  font-weight: 500; font-size: 18px; color: #FAF7F2;
  margin-bottom: 2px; line-height: 1.15;
}
.guide-spec {
  font-family: 'Cormorant Garamond', serif; font-style: italic;
  font-size: 13.5px; color: rgba(250, 247, 242, 0.65); line-height: 1.4;
}

/* === TESTIMONIAL === */
.testimonial {
  background: rgba(15, 36, 25, 0.5);
  padding: 80px 0; text-align: center;
  border-top: 1px solid rgba(212, 168, 68, 0.1);
  border-bottom: 1px solid rgba(212, 168, 68, 0.1);
}
.testimonial-inner { max-width: 640px; margin: 0 auto; padding: 0 32px; }
.testimonial-avatar {
  width: 70px; height: 70px; border-radius: 50%;
  object-fit: cover; border: 2px solid rgba(212, 168, 68, 0.4);
  margin: 0 auto 22px; display: block;
}
.testimonial-quote {
  font-family: 'Cormorant Garamond', serif; font-style: italic;
  font-size: clamp(20px, 2.5vw, 26px); line-height: 1.5;
  color: #FAF7F2; margin-bottom: 14px;
}
.testimonial-quote::before { content: "« "; color: #D4A844; }
.testimonial-quote::after { content: " »"; color: #D4A844; }
.testimonial-name {
  font-size: 11px; letter-spacing: 0.22em; text-transform: uppercase;
  color: #B8862E; font-weight: 500;
}

/* === DJAWAL IA SECTION (mini-chat fonctionnel) === */
.ia-section { background: linear-gradient(180deg, #1A3A2A 0%, #0F2419 100%); }
.ia-grid {
  display: grid; grid-template-columns: 1fr;
  gap: 36px; align-items: start;
  max-width: 1100px; margin: 0 auto;
}
@media (min-width: 1025px) { .ia-grid { grid-template-columns: 1fr 1.1fr; gap: 56px; } }

.ia-text { padding: 8px 0; }
.ia-h2 {
  font-family: 'Cormorant Garamond', serif;
  font-weight: 400; font-size: clamp(28px, 3.5vw, 38px);
  line-height: 1.1; color: #FAF7F2;
  margin: 12px 0 16px; letter-spacing: -0.01em;
}
.ia-h2 em { font-style: italic; color: #E8B96B; font-weight: 500; }
.ia-lede {
  font-family: 'Cormorant Garamond', serif; font-style: italic;
  font-size: 16.5px; color: rgba(250, 247, 242, 0.7);
  line-height: 1.55; margin-bottom: 24px;
}
.ia-prompts-list { display: flex; flex-direction: column; gap: 8px; }
.ia-prompt-btn {
  display: flex; align-items: center; gap: 12px;
  padding: 13px 18px;
  background: rgba(31, 74, 54, 0.5);
  border: 1px solid rgba(212, 168, 68, 0.2);
  border-radius: 8px;
  font-family: inherit; text-align: left;
  cursor: pointer; transition: all 0.2s ease; color: #FAF7F2;
}
.ia-prompt-btn:hover:not(:disabled) { background: rgba(212, 168, 68, 0.1); border-color: #D4A844; transform: translateX(4px); }
.ia-prompt-btn:disabled { opacity: 0.5; cursor: wait; }
.ia-prompt-icon { font-size: 18px; flex-shrink: 0; }
.ia-prompt-text {
  font-family: 'Cormorant Garamond', serif; font-style: italic;
  font-size: 14.5px; color: rgba(250, 247, 242, 0.85); line-height: 1.35;
}

.ia-chat {
  background: rgba(31, 74, 54, 0.65);
  border: 1px solid rgba(212, 168, 68, 0.25);
  border-radius: 12px;
  padding: 22px;
  backdrop-filter: blur(8px);
}
.chat-head {
  display: flex; align-items: center; gap: 12px;
  padding-bottom: 16px;
  border-bottom: 1px solid rgba(212, 168, 68, 0.15);
  margin-bottom: 18px;
}
.chat-avatar {
  width: 44px; height: 44px; border-radius: 50%;
  background: linear-gradient(135deg, #D4A844, #B8862E);
  display: grid; place-items: center;
  font-family: 'Cormorant Garamond', serif; font-weight: 500;
  color: #0F2419; font-size: 20px;
}
.chat-meta strong {
  display: block; font-family: 'Cormorant Garamond', serif;
  font-weight: 500; font-size: 18px; color: #FAF7F2;
}
.chat-meta .status {
  display: flex; align-items: center; gap: 6px;
  font-size: 11px; letter-spacing: 0.14em; text-transform: uppercase;
  color: #B8862E;
}
.chat-meta .status .dot {
  width: 6px; height: 6px; border-radius: 50%;
  background: #D4A844;
  animation: pulse-dot 2s ease-in-out infinite;
}
@keyframes pulse-dot {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

.chat-log {
  min-height: 240px; max-height: 380px;
  overflow-y: auto; padding: 4px 0 12px;
}
.chat-log.empty {
  display: flex; align-items: center; justify-content: center;
  min-height: 240px;
}
.chat-empty { text-align: center; padding: 20px; }
.empty-italic {
  font-family: 'Cormorant Garamond', serif; font-style: italic;
  font-size: 17px; color: rgba(250, 247, 242, 0.78);
  margin-bottom: 10px; line-height: 1.5;
}
.empty-hint { font-size: 12px; color: rgba(250, 247, 242, 0.45); letter-spacing: 0.03em; }

.chat-msg { margin-bottom: 14px; display: flex; }
.chat-msg.user { justify-content: flex-end; }
.chat-msg.ai { justify-content: flex-start; }
.bubble {
  max-width: 85%; padding: 11px 16px;
  border-radius: 16px;
  font-size: 14px; line-height: 1.5;
}
.user-bubble {
  background: #D4A844; color: #0F2419;
  border-bottom-right-radius: 4px; font-weight: 500;
}
.ai-bubble {
  background: rgba(15, 36, 25, 0.7); color: #FAF7F2;
  border: 1px solid rgba(212, 168, 68, 0.18);
  border-bottom-left-radius: 4px;
}
.ai-bubble.typing {
  display: inline-flex; gap: 4px; padding: 14px 16px;
}
.ai-bubble.typing span {
  width: 6px; height: 6px; background: #D4A844; border-radius: 50%;
  animation: typing-dot 1.4s ease-in-out infinite;
}
.ai-bubble.typing span:nth-child(2) { animation-delay: 0.15s; }
.ai-bubble.typing span:nth-child(3) { animation-delay: 0.3s; }
@keyframes typing-dot {
  0%, 60%, 100% { opacity: 0.3; transform: translateY(0); }
  30% { opacity: 1; transform: translateY(-3px); }
}

.chat-input-wrap {
  display: flex; align-items: center; gap: 6px;
  padding: 6px 6px 6px 16px;
  background: rgba(15, 36, 25, 0.6);
  border: 1px solid rgba(212, 168, 68, 0.25);
  border-radius: 999px;
  transition: border-color 0.2s ease;
}
.chat-input-wrap:focus-within { border-color: #D4A844; }
.chat-input-wrap input {
  flex: 1; background: transparent; border: 0; outline: 0;
  font-family: 'Cormorant Garamond', serif; font-style: italic;
  font-size: 14.5px; color: #FAF7F2; padding: 8px 0;
}
.chat-input-wrap input::placeholder { color: rgba(250, 247, 242, 0.4); }
.chat-input-wrap input:disabled { opacity: 0.6; }
.send-btn {
  width: 36px; height: 36px; border-radius: 50%;
  background: #D4A844; color: #0F2419; border: 0;
  cursor: pointer; display: grid; place-items: center;
  transition: background 0.2s ease; flex-shrink: 0;
}
.send-btn:hover:not(:disabled) { background: #E8B96B; }
.send-btn:disabled { opacity: 0.5; cursor: not-allowed; }
.continue-btn {
  display: block; width: 100%;
  margin-top: 14px; padding: 11px 18px;
  background: transparent;
  border: 1px solid rgba(212, 168, 68, 0.4);
  border-radius: 8px; color: #D4A844;
  font-family: inherit; font-size: 13px;
  cursor: pointer; transition: all 0.2s ease;
}
.continue-btn:hover { background: rgba(212, 168, 68, 0.12); border-color: #D4A844; color: #FAF7F2; }

/* === Mobile === */
@media (max-width: 700px) {
  .djawal-container { padding: 0 18px; }
  .hero-content { padding: 100px 20px 28px; }
  .section { padding: 60px 0; }
  .section-head { margin-bottom: 36px; }
  .testimonial { padding: 50px 0; }
  .ia-chat { padding: 16px; }
  .ia-prompt-btn { padding: 11px 14px; }
  .empty-italic { font-size: 15px; }
  .dest-card { flex: 0 0 240px; }
  .trip-mode-badge { font-size: 9.5px; padding: 4px 9px; }
  .cat-banner-inner { padding: 0 18px; }
}
@media (max-width: 380px) {
  .hero h1 { font-size: 32px; }
  .duo-title { font-size: 13.5px; }
  .duo-sub { font-size: 12px; }
}
</style>
