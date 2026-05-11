<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'

interface Memory {
  id: string
  quote: string
  photo_url: string | null
  created_at: string
  profiles?: { display_name: string } | null
  destinations?: { name: string } | null
  trips?: { title: string } | null
}

const memories = ref<Memory[]>([])
const loading = ref(true)

onMounted(async () => {
  loading.value = true
  const { data } = await supabase
    .from('memories')
    .select('id, quote, photo_url, created_at, profiles!memories_author_id_fkey(display_name), destinations(name), trips(title)')
    .eq('published', true)
    .order('created_at', { ascending: false })
    .limit(6)
  memories.value = (data as any) || []
  loading.value = false
})
</script>

<template>
  <section v-if="!loading && memories.length > 0" class="memories-carousel">
    <div class="djawal-container">
      <header class="carousel-head">
        <div>
          <div class="section-eyebrow">Souvenirs</div>
          <h2>Ce qu'ont rapporté nos voyageurs</h2>
          <p class="lead">Bouts de mémoires, fragments d'expérience, instants saisis.</p>
        </div>
        <router-link to="/temoignages" class="link-all">Voir tous les témoignages →</router-link>
      </header>

      <div class="mem-strip">
        <article
          v-for="m in memories"
          :key="m.id"
          class="mem-tile"
          :data-has-photo="!!m.photo_url"
        >
          <div
            v-if="m.photo_url"
            class="mem-photo"
            :style="`background-image: url(${m.photo_url})`"
          ></div>
          <div class="mem-quote-block">
            <p class="mem-quote">« {{ m.quote }} »</p>
            <footer class="mem-footer">
              <strong>{{ m.profiles?.display_name }}</strong>
              <span v-if="m.trips" class="mem-place">· {{ m.trips.title }}</span>
              <span v-else-if="m.destinations" class="mem-place">· {{ m.destinations.name }}</span>
            </footer>
          </div>
        </article>
      </div>
    </div>
  </section>
</template>

<style scoped>
.memories-carousel {
  background: var(--c-fond-chaud);
  padding: var(--space-7) 0;
  position: relative;
  overflow: hidden;
}
.memories-carousel::before {
  content: ''; position: absolute; inset: 0;
  background-image: var(--motif-principal-url);
  opacity: 0.3;
  pointer-events: none;
}

.carousel-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  margin-bottom: var(--space-5);
  flex-wrap: wrap;
  gap: var(--space-3);
  position: relative;
}
.section-eyebrow {
  color: var(--c-accent-fort);
  font-size: 13px; font-weight: 700;
  letter-spacing: 0.2em; text-transform: uppercase;
  margin-bottom: 4px;
}
.carousel-head h2 {
  font-family: var(--font-display);
  font-size: clamp(28px, 3.5vw, 40px);
  color: var(--c-primaire-profond);
  margin-bottom: 8px;
}
.lead { color: var(--c-texte); max-width: 580px; }
.link-all {
  color: var(--c-accent-fort);
  font-weight: 700;
  text-decoration: none;
  padding-bottom: 4px;
}
.link-all:hover { text-decoration: underline; }

.mem-strip {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: var(--space-3);
  position: relative;
}

.mem-tile {
  background: var(--c-surface);
  border-radius: var(--r-lg);
  overflow: hidden;
  box-shadow: var(--ombre-douce);
  display: flex;
  flex-direction: column;
  transition: var(--t-base);
}
.mem-tile:hover {
  transform: translateY(-3px);
  box-shadow: var(--ombre-elevee);
}

.mem-photo {
  height: 180px;
  background-size: cover;
  background-position: center;
}
.mem-quote-block {
  padding: var(--space-4);
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  flex: 1;
}
.mem-quote {
  font-family: var(--font-display);
  font-size: 18px;
  font-style: italic;
  color: var(--c-primaire-profond);
  line-height: 1.4;
  flex: 1;
}
/* Tile sans photo : citation plus grande */
.mem-tile[data-has-photo="false"] .mem-quote { font-size: 20px; }

.mem-footer {
  border-top: 1px solid var(--c-fond-chaud);
  padding-top: var(--space-2);
  font-size: 13px;
  color: var(--c-texte-doux);
}
.mem-footer strong {
  color: var(--c-accent-fort);
  font-weight: 700;
}
.mem-place { font-style: italic; }
</style>
