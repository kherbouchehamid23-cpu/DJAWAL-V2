import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

/**
 * Les routes portent un `meta.culturalTheme` (miroir culturel)
 * et `meta.requiresAuth` / `meta.requiresRole` pour le contrôle d'accès.
 */
const routes: RouteRecordRaw[] = [
  // === Pages publiques ===
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

  // === Authentification ===
  {
    path: '/auth/login',
    name: 'login',
    component: () => import('@/pages/auth/LoginPage.vue'),
    meta: { title: 'Connexion — Djawal', guestOnly: true }
  },
  {
    path: '/auth/signup',
    name: 'signup',
    component: () => import('@/pages/auth/SignupPage.vue'),
    meta: { title: 'Inscription — Djawal', guestOnly: true }
  },
  {
    path: '/auth/callback',
    name: 'auth-callback',
    component: () => import('@/pages/auth/CallbackPage.vue'),
    meta: { title: 'Authentification en cours…' }
  },
  {
    path: '/auth/confirm',
    name: 'auth-confirm',
    component: () => import('@/pages/auth/ConfirmEmailPage.vue'),
    meta: { title: 'Vérifiez votre e-mail — Djawal' }
  },
  {
    path: '/auth/reset-password',
    name: 'auth-reset',
    component: () => import('@/pages/auth/ResetPasswordPage.vue'),
    meta: { title: 'Réinitialiser le mot de passe — Djawal' }
  },

  // === Espace voyageur (authentifié) ===
  {
    path: '/mon-espace',
    name: 'my-account',
    component: () => import('@/pages/account/MyAccountPage.vue'),
    meta: { requiresAuth: true, title: 'Mon espace — Djawal' }
  },

  // === Espace guide (authentifié + rôle guide) ===
  {
    path: '/espace-guide',
    name: 'guide-dashboard',
    component: () => import('@/pages/guide/GuideDashboardPage.vue'),
    meta: { requiresAuth: true, requiresRole: ['guide_senior', 'guide_junior', 'super_admin'], title: 'Espace guide — Djawal' }
  },
  {
    path: '/espace-guide/kyc',
    name: 'guide-kyc',
    component: () => import('@/pages/guide/KycPage.vue'),
    meta: { requiresAuth: true, requiresRole: ['guide_senior', 'guide_junior'], title: 'Vérification KYC — Djawal' }
  },

  // === Administration (Super Admin uniquement) ===
  {
    path: '/admin',
    name: 'admin-dashboard',
    component: () => import('@/pages/admin/AdminDashboardPage.vue'),
    meta: { requiresAuth: true, requiresRole: ['super_admin'], title: 'Administration — Djawal' }
  },
  {
    path: '/admin/kyc',
    name: 'admin-kyc',
    component: () => import('@/pages/admin/KycValidationPage.vue'),
    meta: { requiresAuth: true, requiresRole: ['super_admin'], title: 'Validation KYC — Djawal' }
  },
  {
    path: '/admin/destinations',
    name: 'admin-destinations',
    component: () => import('@/pages/admin/DestinationsAdminPage.vue'),
    meta: { requiresAuth: true, requiresRole: ['super_admin'], title: 'Destinations — Admin' }
  },
  {
    path: '/admin/resources/:type',
    name: 'admin-resources',
    component: () => import('@/pages/admin/ResourcesAdminPage.vue'),
    props: true,
    meta: { requiresAuth: true, requiresRole: ['super_admin'], title: 'Master Data — Admin' }
  },

  // === 404 ===
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

router.beforeEach(async (to, _from, next) => {
  const auth = useAuthStore()

  // Attendre l'initialisation de l'auth si pas encore faite
  if (auth.loading) {
    await auth.initialize()
  }

  if (to.meta.title) document.title = to.meta.title as string

  // Route publique mais utilisateur déjà connecté → renvoyer vers mon-espace
  if (to.meta.guestOnly && auth.isAuthenticated) {
    return next({ name: 'my-account' })
  }

  // Route nécessite une authentification
  if (to.meta.requiresAuth && !auth.isAuthenticated) {
    return next({ name: 'login', query: { redirect: to.fullPath } })
  }

  // Route nécessite un rôle spécifique
  if (to.meta.requiresRole) {
    const allowedRoles = to.meta.requiresRole as string[]
    if (!auth.role || !allowedRoles.includes(auth.role)) {
      return next({ name: 'not-found' })
    }
  }

  next()
})

export default router
