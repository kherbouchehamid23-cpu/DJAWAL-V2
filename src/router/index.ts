import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'

/**
 * Les routes portent un `meta.culturalTheme` qui déclenche le miroir culturel.
 * Valeurs : 'saharien' | 'mauresque' | 'aures'
 * À partir du Sprint 3, le thème sera dynamique selon la `destination_id` consultée.
 */
const routes: RouteRecordRaw[] = [
  {
    path: '/',
    name: 'home',
    component: () => import('@/pages/HomePage.vue'),
    meta: { culturalTheme: 'mauresque', title: 'Djawal — Voyager l\'Algérie autrement' }
  },
  {
    path: '/voyages',
    name: 'trips',
    component: () => import('@/pages/TripsPage.vue'),
    meta: { culturalTheme: 'mauresque', title: 'Voyages — Djawal' }
  },
  {
    path: '/destination/:id',
    name: 'destination',
    component: () => import('@/pages/DestinationPage.vue'),
    props: true,
    meta: { title: 'Destination — Djawal' }
  },
  {
    path: '/about',
    name: 'about',
    component: () => import('@/pages/AboutPage.vue'),
    meta: { culturalTheme: 'mauresque', title: 'À propos — Djawal' }
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'not-found',
    component: () => import('@/pages/NotFoundPage.vue'),
    meta: { title: 'Page introuvable — Djawal' }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior(to, _from, savedPosition) {
    if (savedPosition) return savedPosition
    if (to.hash) return { el: to.hash, behavior: 'smooth' }
    return { top: 0, behavior: 'smooth' }
  }
})

router.beforeEach((to, _from, next) => {
  // Met à jour le <title> selon la route
  if (to.meta.title) document.title = to.meta.title as string
  next()
})

export default router
