<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'
import { useFavorites } from '@/composables/useFavorites'

interface Trip {
  id: string
  title: string
  duration_days: number
  price_da: number
  cover_image_url: string | null
  destinations?: { name: string; wilaya: string } | null
  profiles?: { display_name: string; role: string } | null
}

const auth = useAuthStore()
const { toggleFavorite } = useFavorites()
const trips = ref<Trip[]>([])
const loading = ref(true)

onMounted(async () => {
  loading.value = true
  // Récupérer les favoris du user puis joindre les trips publiés
  const { data: favs } = await supabase
    .from('favorites')
    .select('trip_id, created_at')
    .eq('user_id', auth.user!.id)
    .order('created_at', { ascending: false })

  const ids = (favs || []).map((f: any) => f.trip_id)
  if (ids.length === 0) {
    loading.value = false
    return
  }

  const { data } = await supabase
    .from('trips')
    .select('id, title, duration_days, price_da, cover_image_url, destinations(name, wilaya), profiles!trips_created_by_fkey(display_name, role)')
    .in('id', ids)
    .eq('status', 'published')

  // Garder l'ordre de favorisation
  const byId: Record<string, Trip> = {}
  for (const t of (data as any[] || [])) byId[t.id] = t
  trips.value = ids.map(id => byId[id]).filter(Boolean)
  loading.value = false
})

async function removeFav(tripId: string) {
  await toggleFavorite(tripId)
  trips.value = trips.value.filter(t => t.id !== tripId)
}

function fmtPrice(p: number) {
  return new Intl.NumberFormat('fr-DZ').format(p) + ' DA'
}
</script>

<template>
  <div class="djawal-container djawal-section">
    <div class="back-link">
      <router-link to="/mon-espace">← Mon espace</router-link>
    </div>

    <header class="page-header">
      <div>
        <div class="section-eyebrow">Mon espace</div>
        <h1>❤️ Mes voyages favoris</h1>
        <p class="lead">{{ trips.length }} parcours sauvegardés</p>
      </div>
    </header>

    <div v-if="loading" class="loading">Chargement…</div>

    <div v-else-if="trips.length === 0" class="empty">
      <p>Vous n'avez encore sauvegardé aucun voyage.</p>
      <router-link to="/voyages">
        <v-btn color="primary" variant="flat">Découvrir des voyages</v-btn>
      </router-link>
    </div>

    <div v-else class="fav-grid">
      <article v-for="trip in trips" :key="trip.id" class="fav-card">
        <router-link :to="`/voyages/${trip.id}`" class="fav-link">
          <div
            class="fav-cover"
            :style="trip.cover_image_url ? `background-image: url(${trip.cover_image_url})` : ''"
          ></div>
          <div class="fav-body">
            <div class="fav-dest">📍 {{ trip.destinations?.name }}</div>
            <h3>{{ trip.title }}</h3>
            <div class="fav-meta">
              {{ trip.duration_days }}j · {{ fmtPrice(trip.price_da) }}
            </div>
            <div class="fav-author">par {{ trip.profiles?.display_name }}</div>
          </div>
        </router-link>
        <button class="remove-btn" @click="removeFav(trip.id)" title="Retirer des favoris">
          ❤️ Retirer
        </button>
      </article>
    </div>
  </div>
</template>

<style scoped>
.back-link { margin-bottom: var(--space-3); }
.back-link a {
  color: var(--c-primaire);
  text-decoration: none;
  font-weight: 600;
  font-size: 14px;
}
.back-link a:hover { text-decoration: underline; }

.section-eyebrow {
  color: var(--c-accent-fort);
  font-size: 13px; font-weight: 700;
  letter-spacing: 0.2em; text-transform: uppercase;
  margin-bottom: var(--space-2);
}
.page-header { margin-bottom: var(--space-5); }
.page-header h1 { font-size: clamp(28px, 3.5vw, 40px); margin-bottom: 4px; }
.lead { color: var(--c-texte-doux); }

.loading, .empty { text-align: center; padding: var(--space-8); color: var(--c-texte-doux); }
.empty p { margin-bottom: var(--space-3); }

.fav-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: var(--space-4);
}
.fav-card {
  background: var(--c-surface);
  border-radius: var(--r-lg);
  overflow: hidden;
  box-shadow: var(--ombre-douce);
  display: flex;
  flex-direction: column;
  transition: var(--t-base);
}
.fav-card:hover { transform: translateY(-3px); box-shadow: var(--ombre-elevee); }

.fav-link {
  text-decoration: none;
  color: inherit;
  display: flex;
  flex-direction: column;
  flex: 1;
}
.fav-cover {
  height: 160px;
  background: linear-gradient(135deg, #D4A04F, #C97050);
  background-size: cover;
  background-position: center;
}
.fav-body { padding: var(--space-3); flex: 1; }
.fav-dest {
  font-size: 11px;
  color: var(--c-texte-doux);
  text-transform: uppercase;
  letter-spacing: 0.1em;
  margin-bottom: 4px;
}
.fav-body h3 {
  font-family: var(--font-display);
  font-size: 18px;
  color: var(--c-primaire-profond);
  margin-bottom: 6px;
}
.fav-meta { font-size: 14px; color: var(--c-texte); font-weight: 600; }
.fav-author {
  font-size: 12px;
  color: var(--c-accent-fort);
  font-style: italic;
  margin-top: 4px;
}

.remove-btn {
  width: 100%;
  background: var(--c-fond-chaud);
  border: none;
  border-top: 1px solid var(--c-gris-clair);
  padding: 10px;
  font-family: inherit;
  font-size: 13px;
  font-weight: 600;
  color: var(--c-texte-doux);
  cursor: pointer;
  transition: var(--t-base);
}
.remove-btn:hover {
  background: rgba(192, 74, 58, 0.08);
  color: #C04A3A;
}
</style>
