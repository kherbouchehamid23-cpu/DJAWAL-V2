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
    path: '/voyages/:id',
    name: 'trip-detail',
    component: () => import('@/pages/trips/TripDetailPage.vue'),
    props: true,
    meta: { title: 'Voyage — Djawal' }
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
    path: '/temoignages',
    name: 'memories',
    component: () => import('@/pages/MemoriesPage.vue'),
    meta: { culturalTheme: 'mauresque', title: 'Souvenirs — Djawal' }
  },
  {
    path: '/composer',
    name: 'composer',
    component: () => import('@/pages/ComposerPage.vue'),
    meta: { culturalTheme: 'mauresque', title: 'Composer avec l\'IA — Djawal' }
  },
  {
    path: '/composer/formulaire',
    name: 'composer-form',
    component: () => import('@/pages/ComposerFormPage.vue'),
    meta: { culturalTheme: 'mauresque', title: 'Composer mon voyage — Djawal' }
  },
  {
    path: '/guide/:id',
    name: 'guide-profile',
    component: () => import('@/pages/GuideProfilePage.vue'),
    props: true,
    meta: { culturalTheme: 'mauresque', title: 'Profil guide — Djawal' }
  },
  {
    path: '/contact',
    name: 'contact',
    component: () => import('@/pages/ContactPage.vue'),
    meta: { culturalTheme: 'mauresque', title: 'Contact — Djawal' }
  },
  {
    path: '/mentions-legales',
    name: 'mentions',
    component: () => import('@/pages/LegalPage.vue'),
    meta: { culturalTheme: 'mauresque', title: 'Mentions légales — Djawal' }
  },
  {
    path: '/cgu',
    name: 'cgu',
    component: () => import('@/pages/LegalPage.vue'),
    meta: { culturalTheme: 'mauresque', title: 'CGU — Djawal' }
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
  {
    path: '/mon-espace/favoris',
    name: 'my-favorites',
    component: () => import('@/pages/account/MyFavoritesPage.vue'),
    meta: { requiresAuth: true, title: 'Mes favoris — Djawal' }
  },
  {
    path: '/mon-espace/souvenirs',
    name: 'my-memories',
    component: () => import('@/pages/account/MyMemoriesPage.vue'),
    meta: { requiresAuth: true, title: 'Mes souvenirs — Djawal' }
  },
  {
    path: '/mon-espace/avis',
    name: 'my-reviews',
    component: () => import('@/pages/account/MyReviewsPage.vue'),
    meta: { requiresAuth: true, title: 'Mes avis — Djawal' }
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
  {
    path: '/espace-guide/voyages',
    name: 'guide-trips',
    component: () => import('@/pages/guide/MyTripsPage.vue'),
    meta: { requiresAuth: true, requiresRole: ['guide_senior', 'guide_junior', 'super_admin'], title: 'Mes voyages — Djawal' }
  },
  {
    path: '/espace-guide/voyages/nouveau',
    name: 'guide-trip-new',
    component: () => import('@/pages/guide/TripBuilderPage.vue'),
    meta: { requiresAuth: true, requiresRole: ['guide_senior', 'guide_junior', 'super_admin'], title: 'Nouveau voyage — Djawal' }
  },
  {
    path: '/espace-guide/voyages/:id',
    name: 'guide-trip-edit',
    component: () => import('@/pages/guide/TripBuilderPage.vue'),
    props: true,
    meta: { requiresAuth: true, requiresRole: ['guide_senior', 'guide_junior', 'super_admin'], title: 'Modifier voyage — Djawal' }
  },

  // === Espace opérateur touristique ===
  {
    path: '/espace-operateur',
    name: 'operator-dashboard',
    component: () => import('@/pages/operator/OperatorDashboardPage.vue'),
    meta: { requiresAuth: true, requiresRole: ['tourist_operator', 'super_admin'], title: 'Espace opérateur — Djawal' }
  },
  {
    path: '/espace-operateur/kyc',
    name: 'operator-kyc',
    component: () => import('@/pages/operator/OperatorKycPage.vue'),
    meta: { requiresAuth: true, requiresRole: ['tourist_operator'], title: 'Vérification KYC pro — Djawal' }
  },
  {
    path: '/espace-operateur/produits',
    name: 'operator-products',
    component: () => import('@/pages/operator/OperatorProductsPage.vue'),
    meta: { requiresAuth: true, requiresRole: ['tourist_operator', 'super_admin'], title: 'Mes produits — Djawal' }
  },
  {
    path: '/espace-operateur/produits/nouveau-package',
    name: 'operator-package-new',
    component: () => import('@/pages/operator/OperatorPackageBuilderPage.vue'),
    meta: { requiresAuth: true, requiresRole: ['tourist_operator', 'super_admin'], title: 'Nouveau package — Djawal' }
  },
  {
    path: '/espace-operateur/profil',
    name: 'operator-profile-edit',
    component: () => import('@/pages/operator/OperatorProfileEditPage.vue'),
    meta: { requiresAuth: true, requiresRole: ['tourist_operator'], title: 'Mon profil — Djawal' }
  },

  // === Profil public opérateur ===
  {
    path: '/operateurs/:slug',
    name: 'operator-profile',
    component: () => import('@/pages/OperatorProfilePage.vue'),
    props: true,
    meta: { title: 'Profil opérateur — Djawal' }
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
    path: '/admin/users',
    name: 'admin-users',
    component: () => import('@/pages/admin/UserListAdminPage.vue'),
    meta: { requiresAuth: true, requiresRole: ['super_admin'], title: 'Utilisateurs — Admin Djawal' }
  },
  {
    path: '/admin/users/:id',
    name: 'admin-user-detail',
    component: () => import('@/pages/admin/UserDetailAdminPage.vue'),
    props: true,
    meta: { requiresAuth: true, requiresRole: ['super_admin'], title: 'Utilisateur — Admin Djawal' }
  },
  {
    path: '/admin/moderation-resources',
    name: 'admin-moderation-resources',
    component: () => import('@/pages/admin/AdminResourceModerationPage.vue'),
    meta: { requiresAuth: true, requiresRole: ['super_admin'], title: 'Modération ressources — Djawal' }
  },
  {
    path: '/admin/destinations',
    name: 'admin-destinations',
    component: () => import('@/pages/admin/DestinationsAdminPage.vue'),
    meta: { requiresAuth: true, requiresRole: ['super_admin'], title: 'Destinations — Admin' }
  },
  {
    // Redirect legacy : /admin/resources/hotels → /admin/resources/accommodations
    path: '/admin/resources/hotels',
    redirect: '/admin/resources/accommodations'
  },
  {
    path: '/admin/resources/:type',
    name: 'admin-resources',
    component: () => import('@/pages/admin/ResourcesAdminPage.vue'),
    props: true,
    meta: { requiresAuth: true, requiresRole: ['super_admin'], title: 'Master Data — Admin' }
  },
  {
    path: '/admin/moderation',
    name: 'admin-trip-moderation',
    component: () => import('@/pages/admin/TripModerationPage.vue'),
    meta: { requiresAuth: true, requiresRole: ['super_admin'], title: 'Modération voyages — Admin' }
  },
  {
    path: '/admin/reviews',
    name: 'admin-reviews-moderation',
    component: () => import('@/pages/admin/ReviewsModerationPage.vue'),
    meta: { requiresAuth: true, requiresRole: ['super_admin'], title: 'Modération avis — Admin' }
  },
  {
    path: '/admin/homepage',
    name: 'admin-homepage',
    component: () => import('@/pages/admin/HomepageAdminPage.vue'),
    meta: { requiresAuth: true, requiresRole: ['super_admin'], title: 'HomePage — Admin' }
  },
  {
    path: '/admin/memoires',
    name: 'admin-memories',
    component: () => import('@/pages/admin/MemoriesAdminPage.vue'),
    meta: { requiresAuth: true, requiresRole: ['super_admin'], title: 'Modération souvenirs — Admin' }
  },
  {
    path: '/admin/ia-logs',
    name: 'admin-ai-logs',
    component: () => import('@/pages/admin/AILogsPage.vue'),
    meta: { requiresAuth: true, requiresRole: ['super_admin'], title: 'Logs IA — Admin' }
  },
  {
    path: '/admin/messages',
    name: 'admin-contact-messages',
    component: () => import('@/pages/admin/ContactMessagesPage.vue'),
    meta: { requiresAuth: true, requiresRole: ['super_admin'], title: 'Messages contact — Admin' }
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
  scrollBehavior(to, from, savedPosition) {
    if (savedPosition) return savedPosition
    if (to.hash) return { el: to.hash, behavior: 'smooth' }
    // Si on reste sur la MÊME route (path identique) et que seul ?query change,
    // ne pas scroller — évite le bug iOS Safari (scroll erratique sur frappe live
    // dans une barre de recherche qui sync l'URL via router.replace).
    if (from && to.path === from.path && to.name === from.name) {
      return false
    }
    // Scroll instant (pas smooth) — sur iOS, behavior:'smooth' peut être interrompu
    // par le clavier virtuel et provoquer des sauts inattendus.
    return { top: 0, left: 0 }
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
