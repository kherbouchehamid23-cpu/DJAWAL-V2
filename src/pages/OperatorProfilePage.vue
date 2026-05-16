<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useSEO } from '@/composables/useSEO'
import ReviewSection from '@/components/ReviewSection.vue'
import FavoriteButton from '@/components/FavoriteButton.vue'

const route = useRoute()
const slug = computed(() => route.params.slug as string)

interface OperatorProfile {
  id: string
  slug: string | null
  display_name: string
  company_name: string | null
  bio: string | null
  region: string | null
  avatar_url: string | null
  gallery_urls: string[] | null
  specialties: string[] | null
  operator_type: string | null
  kyc_status: string
}

const profile = ref<OperatorProfile | null>(null)
const accommodations = ref<any[]>([])
const restaurants = ref<any[]>([])
const activities = ref<any[]>([])
const trips = ref<any[]>([])
const memories = ref<any[]>([])
const loading = ref(true)

const operatorTypeLabels: Record<string, string> = {
  travel_agency: 'Agence de voyage',
  restaurant: 'Restaurant',
  accommodation_provider: 'Hébergement',
  artisan: 'Artisan traditionnel'
}

const operatorTypeIcons: Record<string, string> = {
  travel_agency: '🧭',
  restaurant: '🍽️',
  accommodation_provider: '🏨',
  artisan: '🧶'
}

const operatorTypeLabel = computed(() =>
  profile.value?.operator_type ? operatorTypeLabels[profile.value.operator_type] : ''
)

const operatorTypeIcon = computed(() =>
  profile.value?.operator_type ? operatorTypeIcons[profile.value.operator_type] : ''
)

// Sections affichées selon operator_type
const showActivities = computed(() =>
  profile.value?.operator_type && ['artisan', 'accommodation_provider'].includes(profile.value.operator_type)
)
const showAccommodations = computed(() =>
  profile.value?.operator_type && ['artisan', 'accommodation_provider'].includes(profile.value.operator_type)
)
const showRestaurants = computed(() =>
  profile.value?.operator_type && ['restaurant', 'accommodation_provider'].includes(profile.value.operator_type)
)
const showTrips = computed(() =>
  profile.value?.operator_type && ['travel_agency', 'accommodation_provider'].includes(profile.value.operator_type)
)

onMounted(load)
watch(slug, load)

async function load() {
  loading.value = true
  // 1. Récupérer le profil par slug
  const { data: prof } = await supabase
    .from('profiles')
    .select('id, slug, display_name, company_name, bio, region, avatar_url, gallery_urls, specialties, operator_type, kyc_status')
    .eq('slug', slug.value)
    .eq('role', 'tourist_operator')
    .eq('kyc_status', 'approved')
    .single()

  if (!prof) {
    loading.value = false
    return
  }
  profile.value = prof as any

  useSEO({
    title: `${prof.company_name || prof.display_name} — ${operatorTypeLabels[prof.operator_type as string] || 'Opérateur'}`,
    description: prof.bio || `Découvrez ${prof.company_name || prof.display_name} sur Djawal.`
  })

  // 2. Récupérer ses produits publiés en parallèle
  const [accRes, restRes, actRes, tripsRes, memRes] = await Promise.all([
    supabase.from('accommodations').select('id, name, description, accommodation_type, images, destination:destinations(name)').eq('created_by', prof.id).eq('status', 'published'),
    supabase.from('restaurants').select('id, name, description, cuisine, images, destination:destinations(name)').eq('created_by', prof.id).eq('status', 'published'),
    supabase.from('activities').select('id, name, description, activity_type, images, destination:destinations(name)').eq('created_by', prof.id).eq('status', 'published'),
    supabase.from('trips').select('id, title, description, duration_days, price_da, cover_image_url').eq('created_by', prof.id).eq('status', 'published'),
    supabase.rpc('get_operator_memories', { p_operator_id: prof.id, p_limit: 6 })
  ])
  accommodations.value = accRes.data || []
  restaurants.value = restRes.data || []
  activities.value = actRes.data || []
  trips.value = tripsRes.data || []
  memories.value = memRes.data || []

  loading.value = false
}
</script>

<template>
  <div class="djawal-container operator-profile-page">
    <div v-if="loading" class="loading">Chargement du profil…</div>

    <div v-else-if="!profile" class="not-found">
      <h1>Profil introuvable</h1>
      <p>Ce profil opérateur n'existe pas ou n'a pas encore été validé.</p>
      <router-link to="/" class="back-link">Retour à l'accueil</router-link>
    </div>

    <template v-else>
      <!-- === Header profil === -->
      <header class="profile-head">
        <div class="profile-identity">
          <div class="profile-avatar">
            <img v-if="profile.avatar_url" :src="profile.avatar_url" :alt="profile.company_name || profile.display_name" />
            <span v-else>{{ (profile.company_name || profile.display_name)[0].toUpperCase() }}</span>
          </div>
          <div>
            <div class="profile-type-badge">
              <span class="type-icon">{{ operatorTypeIcon }}</span>
              {{ operatorTypeLabel }}
            </div>
            <h1>{{ profile.company_name || profile.display_name }}</h1>
            <p class="profile-region">📍 {{ profile.region || 'Algérie' }}</p>
          </div>
        </div>
        <div v-if="profile.specialties && profile.specialties.length > 0" class="profile-tags">
          <span v-for="s in profile.specialties" :key="s" class="tag">{{ s }}</span>
        </div>
      </header>

      <!-- === Bio === -->
      <section v-if="profile.bio" class="profile-bio">
        <p>{{ profile.bio }}</p>
      </section>

      <!-- === Galerie === -->
      <section v-if="profile.gallery_urls && profile.gallery_urls.length > 0" class="profile-gallery">
        <h2>Galerie</h2>
        <div class="gallery-grid">
          <img v-for="(url, i) in profile.gallery_urls" :key="i" :src="url" :alt="`Photo ${i+1}`" />
        </div>
      </section>

      <!-- === Activités (artisans, hébergeurs) === -->
      <section v-if="showActivities && activities.length > 0" class="profile-section">
        <h2>{{ profile.operator_type === 'artisan' ? 'Ateliers proposés' : 'Activités' }} ({{ activities.length }})</h2>
        <div class="cards-grid">
          <article v-for="a in activities" :key="a.id" class="product-card">
            <div class="product-thumb">{{ a.activity_type ? `🥾` : '🔸' }}</div>
            <div class="product-body">
              <h3>{{ a.name }}</h3>
              <p class="product-loc" v-if="a.destination">{{ a.destination.name }}</p>
              <p class="product-desc">{{ a.description }}</p>
            </div>
          </article>
        </div>
      </section>

      <!-- === Hébergements (hébergeurs, artisans avec maison d'hôte) === -->
      <section v-if="showAccommodations && accommodations.length > 0" class="profile-section">
        <h2>Hébergements ({{ accommodations.length }})</h2>
        <div class="cards-grid">
          <article v-for="a in accommodations" :key="a.id" class="product-card">
            <div class="product-thumb">🏨</div>
            <div class="product-body">
              <h3>{{ a.name }}</h3>
              <p class="product-loc" v-if="a.destination">{{ a.destination.name }} · {{ a.accommodation_type }}</p>
              <p class="product-desc">{{ a.description }}</p>
            </div>
          </article>
        </div>
      </section>

      <!-- === Restaurants === -->
      <section v-if="showRestaurants && restaurants.length > 0" class="profile-section">
        <h2>{{ profile.operator_type === 'restaurant' ? 'Notre table' : 'Restaurants' }} ({{ restaurants.length }})</h2>
        <div class="cards-grid">
          <article v-for="r in restaurants" :key="r.id" class="product-card">
            <div class="product-thumb">🍽️</div>
            <div class="product-body">
              <h3>{{ r.name }}</h3>
              <p class="product-loc" v-if="r.destination">{{ r.destination.name }}</p>
              <p class="product-desc">{{ r.description }}</p>
              <div v-if="r.cuisine && r.cuisine.length > 0" class="chips">
                <span v-for="c in r.cuisine" :key="c" class="chip">{{ c }}</span>
              </div>
            </div>
          </article>
        </div>
      </section>

      <!-- === Packages / Voyages === -->
      <section v-if="showTrips && trips.length > 0" class="profile-section">
        <h2>{{ profile.operator_type === 'travel_agency' ? 'Nos packages' : 'Séjours' }} ({{ trips.length }})</h2>
        <div class="cards-grid">
          <article v-for="t in trips" :key="t.id" class="product-card">
            <div class="product-thumb" :style="t.cover_image_url ? `background-image: url(${t.cover_image_url})` : ''">
              {{ t.cover_image_url ? '' : '🧭' }}
            </div>
            <div class="product-body">
              <h3>{{ t.title }}</h3>
              <p class="product-loc">{{ t.duration_days }} jours · {{ t.price_da }} DA</p>
              <p class="product-desc">{{ t.description }}</p>
            </div>
          </article>
        </div>
      </section>

      <!-- === Souvenirs liés (mur d'avis) === -->
      <section v-if="memories.length > 0" class="profile-section memories-section">
        <h2>Souvenirs de voyageurs ({{ memories.length }})</h2>
        <p class="section-intro">
          Témoignages des voyageurs ayant rencontré {{ profile.company_name || profile.display_name }}.
        </p>
        <div class="memories-grid">
          <article v-for="m in memories" :key="m.id" class="memory-card">
            <img v-if="m.photo_url" :src="m.photo_url" class="memory-photo" alt="" />
            <p class="memory-quote">« {{ m.quote }} »</p>
            <p class="memory-author">— {{ m.author_name }}</p>
          </article>
        </div>
      </section>

      <!-- === Pas de produit publié === -->
      <section v-if="
          (!showActivities || activities.length === 0) &&
          (!showAccommodations || accommodations.length === 0) &&
          (!showRestaurants || restaurants.length === 0) &&
          (!showTrips || trips.length === 0)
        " class="empty-section">
        <p>Ce profil n'a pas encore publié de produits sur Djawal.</p>
      </section>

      <!-- Avis sur l'opérateur -->
      <section v-if="operator?.id" class="djawal-container djawal-section">
        <ReviewSection
          target-type="operator"
          :target-id="operator.id"
          :title="`⭐ Avis sur ${operator.business_name || 'cet opérateur'}`"
        />
      </section>

      <!-- Bouton favori opérateur -->
      <FavoriteButton
        v-if="operator?.id"
        target-type="operator"
        :target-id="operator.id"
        size="lg"
        class="op-fav-btn"
      />
    </template>
  </div>
</template>

<style scoped>
.operator-profile-page {
  max-width: 1080px;
  margin: 0 auto;
  padding: var(--space-6) var(--space-5);
}

.loading, .not-found {
  text-align: center;
  padding: var(--space-9);
  color: var(--c-texte-doux);
}
.not-found h1 {
  font-family: var(--font-display);
  font-size: 32px;
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-3);
}
.back-link {
  display: inline-block;
  margin-top: var(--space-4);
  color: var(--c-accent-fort);
  font-weight: 600;
  text-decoration: none;
}

/* === Header === */
.profile-head {
  display: flex;
  flex-direction: column;
  gap: var(--space-4);
  padding-bottom: var(--space-5);
  border-bottom: 1px solid var(--c-gris-clair);
  margin-bottom: var(--space-6);
}
.profile-identity {
  display: flex;
  gap: var(--space-4);
  align-items: center;
}
.profile-avatar {
  width: 96px;
  height: 96px;
  border-radius: 50%;
  overflow: hidden;
  background: linear-gradient(135deg, #D4A04F, #B8862E);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  color: var(--c-primaire-profond);
  font-family: var(--font-display);
  font-size: 40px;
  font-weight: 600;
}
.profile-avatar img { width: 100%; height: 100%; object-fit: cover; }
.profile-type-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: var(--c-fond-chaud);
  color: var(--c-accent-fort);
  padding: 4px 12px;
  border-radius: 999px;
  font-size: 11px;
  letter-spacing: 0.1em;
  text-transform: uppercase;
  font-weight: 600;
  margin-bottom: 8px;
}
.type-icon { font-size: 14px; }
h1 {
  font-family: var(--font-display);
  font-size: clamp(28px, 4vw, 40px);
  color: var(--c-primaire-profond);
  margin: 0 0 8px;
  line-height: 1.1;
}
.profile-region {
  color: var(--c-texte-doux);
  font-size: 14px;
}
.profile-tags {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}
.tag {
  background: rgba(212, 160, 79, 0.15);
  color: var(--c-accent-fort);
  padding: 4px 12px;
  border-radius: 999px;
  font-size: 12px;
  font-weight: 500;
}

/* === Bio === */
.profile-bio {
  font-family: var(--font-display);
  font-size: 18px;
  line-height: 1.7;
  color: var(--c-texte);
  font-style: italic;
  margin-bottom: var(--space-6);
  padding: var(--space-4);
  background: var(--c-fond-chaud);
  border-left: 3px solid var(--c-accent);
  border-radius: 0 var(--r-md) var(--r-md) 0;
}

/* === Galerie === */
.profile-gallery { margin-bottom: var(--space-6); }
.gallery-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: var(--space-2);
}
.gallery-grid img {
  width: 100%;
  aspect-ratio: 4/3;
  object-fit: cover;
  border-radius: var(--r-sm, 6px);
}

/* === Sections === */
.profile-section { margin-bottom: var(--space-7); }
h2 {
  font-family: var(--font-display);
  font-size: clamp(22px, 3vw, 28px);
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-3);
}
.section-intro {
  color: var(--c-texte-doux);
  margin-bottom: var(--space-3);
}
.cards-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: var(--space-3);
}
.product-card {
  background: var(--c-surface);
  border-radius: var(--r-md);
  overflow: hidden;
  box-shadow: var(--ombre-douce);
  display: flex;
  flex-direction: column;
}
.product-thumb {
  aspect-ratio: 16/9;
  background: linear-gradient(135deg, #D4A04F, #C97050);
  background-size: cover;
  background-position: center;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 36px;
  color: rgba(255,255,255,0.5);
}
.product-body { padding: var(--space-3); }
.product-body h3 {
  font-family: var(--font-display);
  font-size: 18px;
  color: var(--c-primaire-profond);
  margin-bottom: 4px;
}
.product-loc {
  font-size: 12px;
  color: var(--c-accent-fort);
  letter-spacing: 0.08em;
  text-transform: uppercase;
  margin-bottom: 8px;
}
.product-desc {
  font-size: 13px;
  color: var(--c-texte);
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.chips {
  display: flex;
  gap: 4px;
  margin-top: 8px;
  flex-wrap: wrap;
}
.chip {
  background: var(--c-fond-chaud);
  padding: 2px 8px;
  border-radius: 4px;
  font-size: 11px;
  color: var(--c-texte-doux);
}

/* === Souvenirs === */
.memories-section { background: var(--c-fond-chaud); padding: var(--space-5); border-radius: var(--r-md); }
.memories-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: var(--space-3);
}
.memory-card {
  background: var(--c-surface);
  padding: var(--space-4);
  border-radius: var(--r-md);
  box-shadow: var(--ombre-douce);
}
.memory-photo {
  width: 100%;
  aspect-ratio: 4/3;
  object-fit: cover;
  border-radius: var(--r-sm, 6px);
  margin-bottom: var(--space-3);
}
.memory-quote {
  font-family: var(--font-display);
  font-style: italic;
  font-size: 15px;
  line-height: 1.5;
  color: var(--c-primaire-profond);
  margin-bottom: var(--space-2);
}
.memory-author {
  font-size: 12px;
  color: var(--c-texte-doux);
  text-align: right;
}

.empty-section {
  text-align: center;
  padding: var(--space-8);
  color: var(--c-texte-doux);
  background: var(--c-fond-chaud);
  border-radius: var(--r-md);
}
</style>
