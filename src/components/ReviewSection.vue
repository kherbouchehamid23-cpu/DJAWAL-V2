<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

type TargetType =
  | 'trip' | 'destination' | 'accommodation' | 'site'
  | 'restaurant' | 'activity' | 'guide' | 'operator'

const props = withDefaults(defineProps<{
  // Mode 1 (nouveau) : target_type + target_id
  targetType?: TargetType
  targetId?: string
  // Mode 2 (rétro-compat) : tripId
  tripId?: string
  // Personnalisation visuelle
  title?: string
}>(), {
  title: '⭐ Avis'
})

// Résolution du target effectif
const effectiveType = computed<TargetType>(() => props.targetType || 'trip')
const effectiveId = computed<string>(() => props.targetId || props.tripId || '')

interface Review {
  id: string
  rating: number
  comment: string | null
  created_at: string
  user_id: string
  profiles?: { display_name: string; avatar_url: string | null } | null
}

const auth = useAuthStore()
const reviews = ref<Review[]>([])
const loading = ref(true)

// État du formulaire (avis du user courant)
const myReview = ref<Review | null>(null)
const formRating = ref(5)
const formComment = ref('')
const saving = ref(false)
const formError = ref('')

const avg = computed(() => {
  if (reviews.value.length === 0) return null
  const sum = reviews.value.reduce((s, r) => s + r.rating, 0)
  return (sum / reviews.value.length).toFixed(1)
})

async function load() {
  if (!effectiveId.value) return
  loading.value = true
  const { data } = await supabase
    .from('user_reviews')
    .select('id, rating, comment, created_at, user_id, profiles!user_reviews_user_id_fkey(display_name, avatar_url)')
    .eq('target_type', effectiveType.value)
    .eq('target_id', effectiveId.value)
    .eq('status', 'approved')
    .order('created_at', { ascending: false })
  reviews.value = (data as any) || []

  // Trouver mon avis si connecté (peut être en pending donc on refait une requête séparée)
  myReview.value = null
  formRating.value = 5
  formComment.value = ''
  if (auth.user) {
    const { data: mine } = await supabase
      .from('user_reviews')
      .select('id, rating, comment, created_at, user_id')
      .eq('target_type', effectiveType.value)
      .eq('target_id', effectiveId.value)
      .eq('user_id', auth.user.id)
      .maybeSingle()
    if (mine) {
      myReview.value = mine as any
      formRating.value = (mine as any).rating
      formComment.value = (mine as any).comment || ''
    }
  }

  loading.value = false
}

onMounted(load)
// Recharger si la cible change (cas où le composant reste monté mais reçoit un nouvel ID)
watch([effectiveType, effectiveId], load)

async function submitReview() {
  formError.value = ''
  if (formRating.value < 1 || formRating.value > 5) {
    formError.value = 'Donnez une note entre 1 et 5.'
    return
  }
  saving.value = true
  const payload = {
    user_id: auth.user!.id,
    target_type: effectiveType.value,
    target_id: effectiveId.value,
    rating: formRating.value,
    comment: formComment.value.trim() || null
  }

  let err
  if (myReview.value) {
    const { error: e } = await supabase
      .from('user_reviews')
      .update({ rating: payload.rating, comment: payload.comment })
      .eq('id', myReview.value.id)
    err = e
  } else {
    const { error: e } = await supabase.from('user_reviews').insert(payload)
    err = e
  }
  saving.value = false
  if (err) {
    formError.value = err.message
    return
  }
  await load()
}

async function deleteMine() {
  if (!myReview.value || !confirm('Supprimer votre avis ?')) return
  const { error } = await supabase.from('user_reviews').delete().eq('id', myReview.value.id)
  if (error) { alert('Erreur : ' + error.message); return }
  myReview.value = null
  formRating.value = 5
  formComment.value = ''
  await load()
}

function fmtDate(iso: string) {
  return new Date(iso).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric' })
}

function initial(name?: string | null) {
  return (name || '?')[0].toUpperCase()
}
</script>

<template>
  <section class="reviews">
    <header class="reviews-head">
      <h2>{{ title }}</h2>
      <div v-if="avg" class="avg-row">
        <span class="avg-num">{{ avg }}</span>
        <span class="avg-stars">
          <span v-for="n in 5" :key="n" :class="['star', { filled: n <= Math.round(parseFloat(avg)) }]">★</span>
        </span>
        <span class="avg-count">· {{ reviews.length }} avis</span>
      </div>
    </header>

    <!-- Formulaire (uniquement si connecté) -->
    <div v-if="auth.isAuthenticated && !auth.isGuide" class="review-form">
      <h3>{{ myReview ? 'Modifier mon avis' : 'Laisser un avis' }}</h3>
      <v-alert v-if="formError" type="error" variant="tonal" class="mb-3">{{ formError }}</v-alert>

      <div class="rating-picker">
        <button
          v-for="n in 5"
          :key="n"
          class="rating-star"
          :class="{ active: n <= formRating }"
          @click="formRating = n"
          type="button"
        >★</button>
        <span class="rating-label">{{ formRating }}/5</span>
      </div>

      <v-textarea
        v-model="formComment"
        placeholder="Partagez votre expérience (facultatif)…"
        variant="outlined"
        density="comfortable"
        rows="3"
        counter
        maxlength="500"
      />

      <div class="form-actions">
        <v-btn color="primary" variant="flat" :loading="saving" @click="submitReview">
          {{ myReview ? 'Mettre à jour' : 'Publier l\'avis' }}
        </v-btn>
        <v-btn
          v-if="myReview"
          variant="text"
          color="error"
          @click="deleteMine"
        >Supprimer</v-btn>
      </div>
    </div>

    <div v-else-if="!auth.isAuthenticated" class="login-prompt">
      <router-link to="/auth/login">Connectez-vous</router-link> pour laisser un avis.
    </div>

    <!-- Liste des avis -->
    <div v-if="loading" class="loading">Chargement des avis…</div>

    <div v-else-if="reviews.length === 0" class="empty">
      Aucun avis pour le moment — soyez le premier à partager votre expérience.
    </div>

    <div v-else class="reviews-list">
      <article
        v-for="r in reviews"
        :key="r.id"
        class="review-item"
        :class="{ mine: r.user_id === auth.user?.id }"
      >
        <div class="review-avatar">
          <img v-if="r.profiles?.avatar_url" :src="r.profiles.avatar_url" :alt="r.profiles?.display_name || ''" />
          <span v-else>{{ initial(r.profiles?.display_name) }}</span>
        </div>
        <div class="review-content">
          <div class="review-head">
            <strong>{{ r.profiles?.display_name }}</strong>
            <span class="review-stars">
              <span v-for="n in 5" :key="n" :class="['star-sm', { filled: n <= r.rating }]">★</span>
            </span>
            <span class="review-date">{{ fmtDate(r.created_at) }}</span>
          </div>
          <p v-if="r.comment" class="review-text">{{ r.comment }}</p>
          <p v-else class="review-no-text">Sans commentaire.</p>
        </div>
      </article>
    </div>
  </section>
</template>

<style scoped>
.reviews {
  margin-top: var(--space-6);
  padding-top: var(--space-5);
  border-top: 1px solid var(--c-fond-chaud);
}

.reviews-head {
  display: flex; justify-content: space-between; align-items: baseline;
  flex-wrap: wrap; gap: var(--space-3);
  margin-bottom: var(--space-4);
}
.reviews-head h2 {
  font-family: var(--font-display);
  font-size: 28px;
  color: var(--c-primaire-profond);
}
.avg-row { display: flex; align-items: center; gap: 8px; }
.avg-num {
  font-family: var(--font-display);
  font-size: 28px;
  font-weight: 700;
  color: var(--c-primaire-profond);
}
.avg-stars { letter-spacing: 2px; }
.star { color: var(--c-gris-clair); font-size: 16px; }
.star.filled { color: #D4A04F; }
.avg-count { color: var(--c-texte-doux); font-size: 13px; }

/* === FORMULAIRE === */
.review-form {
  background: var(--c-fond-chaud);
  border-radius: var(--r-lg);
  padding: var(--space-4);
  margin-bottom: var(--space-4);
  border-left: 4px solid var(--c-accent);
}
.review-form h3 {
  font-family: var(--font-display);
  font-size: 18px;
  margin-bottom: var(--space-3);
  color: var(--c-primaire-profond);
}

.rating-picker {
  display: flex; align-items: center; gap: 4px;
  margin-bottom: var(--space-3);
}
.rating-star {
  background: none;
  border: none;
  font-size: 32px;
  color: var(--c-gris-clair);
  cursor: pointer;
  padding: 0 4px;
  transition: var(--t-base);
}
.rating-star:hover, .rating-star.active { color: #D4A04F; transform: scale(1.1); }
.rating-label {
  margin-left: 12px;
  font-weight: 700;
  color: var(--c-primaire-profond);
}

.form-actions { display: flex; gap: var(--space-2); margin-top: var(--space-2); }

.login-prompt {
  text-align: center;
  padding: var(--space-4);
  background: var(--c-fond-chaud);
  border-radius: var(--r-md);
  margin-bottom: var(--space-4);
  color: var(--c-texte);
}
.login-prompt a { color: var(--c-accent-fort); font-weight: 700; }

.loading, .empty {
  text-align: center;
  padding: var(--space-5);
  color: var(--c-texte-doux);
}

.reviews-list { display: flex; flex-direction: column; gap: var(--space-3); }
.review-item {
  display: grid;
  grid-template-columns: 48px 1fr;
  gap: var(--space-3);
  padding: var(--space-3);
  background: var(--c-surface);
  border-radius: var(--r-md);
  border-left: 3px solid transparent;
}
.review-item.mine {
  border-left-color: var(--c-accent);
  background: rgba(212, 160, 79, 0.06);
}

.review-avatar {
  width: 48px; height: 48px;
  border-radius: 50%;
  background: var(--c-fond-chaud);
  display: flex; align-items: center; justify-content: center;
  font-family: var(--font-display);
  font-size: 20px;
  font-weight: 700;
  color: var(--c-primaire);
  overflow: hidden;
  flex-shrink: 0;
}
.review-avatar img { width: 100%; height: 100%; object-fit: cover; }

.review-head {
  display: flex; align-items: baseline; gap: 8px;
  flex-wrap: wrap;
  margin-bottom: 4px;
}
.review-head strong { color: var(--c-primaire-profond); }
.review-stars { letter-spacing: 1px; }
.star-sm { color: var(--c-gris-clair); font-size: 13px; }
.star-sm.filled { color: #D4A04F; }
.review-date { color: var(--c-texte-doux); font-size: 12px; }
.review-text { font-size: 14px; color: var(--c-texte); line-height: 1.5; }
.review-no-text { font-style: italic; color: var(--c-texte-doux); font-size: 13px; }
</style>
