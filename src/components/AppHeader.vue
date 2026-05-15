<script setup lang="ts">
import { ref, computed } from 'vue'
import { RouterLink, useRoute } from 'vue-router'
import { useThemeStore } from '@/stores/theme'
import { useAuthStore } from '@/stores/auth'
import { useBreakpoint } from '@/composables/useBreakpoint'
import djawalLogoStacked from '@/assets/branding/djawal-stacked.png'
import djawalLogoMonogram from '@/assets/branding/djawal-monogram.png'

const theme = useThemeStore()
const auth = useAuthStore()
const route = useRoute()
const drawer = ref(false)
const { isMobile } = useBreakpoint()

// Transparent overlay sur la HomePage (hero image plein écran)
// Header transparent en overlay sur toutes les pages publiques au design V4 vert sombre.
// Le header normal (avec fond clair) reste sur /auth/*, /mon-espace/*, /admin/*, /espace-*.
const isOverlayPage = computed(() => {
  const p = route.path
  if (p === '/') return true
  if (p.startsWith('/voyages')) return true
  if (p.startsWith('/destination')) return true
  if (p.startsWith('/temoignages')) return true
  if (p.startsWith('/composer')) return true
  if (p === '/about') return true
  if (p === '/contact') return true
  if (p === '/mentions-legales') return true
  if (p === '/cgu') return true
  return false
})
// Alias pour la compatibilité avec le template existant
const isHomePage = isOverlayPage

const navItems = [
  { to: '/voyages', label: 'Destinations' },
  { to: '/temoignages', label: 'Souvenirs' },
  { to: '/about', label: 'À propos' },
  { to: '/composer', label: 'Djawal IA', accent: true }
]
</script>

<template>
  <!-- ===== DESKTOP HEADER (HTML natif, plein contrôle des styles) ===== -->
  <header
    v-if="!isMobile"
    class="desktop-header"
    :class="{ 'header-overlay': isOverlayPage }"
  >
    <div class="header-row djawal-max">
      <!-- LOGO — Djawal officiel (violet + orange + silhouette voyageur) -->
      <RouterLink to="/" class="logo-wrap">
        <img :src="djawalLogoStacked" alt="Djawal" class="logo-img" />
      </RouterLink>

      <!-- NAV DESKTOP -->
      <nav class="nav-desktop">
        <RouterLink
          v-for="item in navItems"
          :key="item.to"
          :to="item.to"
          class="nav-link"
          :class="{ 'nav-link-ia': item.accent }"
        >
          <img v-if="item.accent" :src="djawalLogoMonogram" alt="" class="nav-djawal-icon" aria-hidden="true" />
          {{ item.label }}
        </RouterLink>
      </nav>

      <!-- ACTIONS -->
      <div class="header-actions">
        <template v-if="auth.isAuthenticated">
          <v-menu>
            <template #activator="{ props }">
              <button v-bind="props" class="account-btn-native">
                {{ auth.profile?.display_name || 'Mon compte' }}
                <span aria-hidden="true">▾</span>
              </button>
            </template>
            <v-list>
              <v-list-item to="/mon-espace" title="Mon espace" />
              <v-list-item v-if="auth.isGuide" to="/espace-guide" title="Espace guide" />
              <v-list-item v-if="auth.isOperator" to="/espace-operateur" title="Espace opérateur" />
              <v-list-item v-if="auth.isAdmin" to="/admin" title="Administration" />
              <v-divider />
              <v-list-item title="Se déconnecter" @click="auth.signOut" />
            </v-list>
          </v-menu>
        </template>
        <template v-else>
          <RouterLink to="/auth/login" class="login-btn-native">Connexion</RouterLink>
          <RouterLink to="/auth/signup" class="signup-btn-native">Nous rejoindre</RouterLink>
        </template>
      </div>
    </div>
  </header>

  <!-- === Mini header mobile === -->
  <header v-if="isMobile" class="mobile-header" :class="{ 'mobile-header-overlay': isOverlayPage }">
    <RouterLink to="/" class="mob-logo">
      <img :src="djawalLogoMonogram" alt="Djawal" class="mob-logo-img" />
      <span class="mob-name">Djawal</span>
    </RouterLink>
    <div class="mob-actions">
      <RouterLink to="/voyages" class="mob-btn" aria-label="Rechercher">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="7"/><path d="M21 21l-4-4"/></svg>
      </RouterLink>
      <RouterLink v-if="!auth.isAuthenticated" to="/auth/login" class="mob-btn-cta">Connexion</RouterLink>
      <RouterLink v-else :to="auth.isAdmin ? '/admin' : auth.isGuide ? '/espace-guide' : auth.isOperator ? '/espace-operateur' : '/mon-espace'" class="mob-btn" aria-label="Mon espace">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="8" r="4"/><path d="M4 20 c 0 -5 4 -8 8 -8 s 8 3 8 8"/></svg>
      </RouterLink>
    </div>
  </header>

  <!-- Drawer mobile (gardé en réserve, plus utilisé directement) -->
  <v-navigation-drawer v-model="drawer" location="right" temporary>
    <v-list>
      <v-list-item
        v-for="item in navItems"
        :key="item.to"
        :to="item.to"
        :title="item.label"
      />
    </v-list>
  </v-navigation-drawer>
</template>

<style scoped>
/* ===== HEADER DESKTOP NATIF ===== */
.desktop-header {
  position: sticky;
  top: 0;
  left: 0; right: 0;
  z-index: 50;
  height: 72px;
  background: var(--c-surface, #FFFFFF);
  border-bottom: 1px solid rgba(10, 31, 46, 0.06);
  box-shadow: 0 2px 12px rgba(10, 31, 46, 0.04);
}
.djawal-max {
  max-width: 1340px;
  height: 100%;
  margin: 0 auto;
  padding: 0 24px;
}
/* Grille header : logo gauche, nav centre, actions droite — zéro chevauchement */
.header-row {
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 24px;
  height: 100%;
}

/* Boutons "Connexion" et "Nous rejoindre" natifs */
.login-btn-native {
  display: inline-flex;
  align-items: center;
  padding: 9px 16px;
  color: var(--c-primaire-profond, #0A1F2E);
  font-size: 13px; font-weight: 500;
  letter-spacing: 0.04em;
  text-decoration: none;
  border-radius: 999px;
  transition: background 0.2s, color 0.2s;
}
.login-btn-native:hover {
  background: rgba(10, 31, 46, 0.05);
}
.signup-btn-native {
  display: inline-flex;
  align-items: center;
  padding: 10px 18px;
  background: linear-gradient(135deg, #461464, #5C1E80);
  color: #FAF7F2;
  font-size: 13px; font-weight: 600;
  letter-spacing: 0.04em;
  text-decoration: none;
  border-radius: 999px;
  box-shadow: 0 4px 12px rgba(70, 20, 100, 0.25);
  transition: transform 0.2s, box-shadow 0.2s;
}
.signup-btn-native:hover {
  transform: translateY(-1px);
  box-shadow: 0 8px 20px rgba(70, 20, 100, 0.4);
}
.account-btn-native {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 9px 16px;
  background: transparent;
  border: 1px solid rgba(10, 31, 46, 0.12);
  color: var(--c-primaire-profond, #0A1F2E);
  font-family: inherit;
  font-size: 13px; font-weight: 500;
  border-radius: 999px;
  cursor: pointer;
}
.account-btn-native:hover {
  background: rgba(10, 31, 46, 0.04);
}
.logo-wrap {
  display: flex;
  align-items: center;
  gap: 10px;
  text-decoration: none;
  flex-shrink: 0;
}
.logo-mark {
  width: 44px; height: 44px;
  background: #2D5A3D; /* Vert Atlas — verrouillé (kept for retro-compat) */
  border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  box-shadow: 0 0 0 2px rgba(232, 181, 71, 0.35);
}
/* Logo image officiel Djawal stacked (violet + orange + DJAWAL) */
.logo-img {
  width: 56px;
  height: 56px;
  display: block;
  object-fit: contain;
  border-radius: 10px;
}
.logo-ar {
  font-family: var(--font-arabic);
  font-size: 18px;
  color: var(--c-accent-fort);
  line-height: 1;
  display: inline-block;
  vertical-align: middle;
}
.nav-desktop {
  display: flex;
  justify-content: center;
  gap: 28px;
  min-width: 0;
}
@media (max-width: 900px) {
  .nav-desktop { gap: 18px; }
}
@media (max-width: 760px) {
  .nav-desktop { display: none; }
}
.header-actions {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
}
@media (max-width: 760px) {
  .login-btn { display: none; }
}
.nav-link {
  color: var(--c-primaire-profond);
  font-size: 13px;
  font-weight: 600;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  padding: 8px 4px;
  position: relative;
  transition: color var(--t-fast);
  white-space: nowrap;
  text-decoration: none;
}
.nav-link:hover { color: var(--c-cta); }
.nav-link.router-link-active::after {
  content: '';
  position: absolute;
  bottom: 0; left: 50%; transform: translateX(-50%);
  width: 20px; height: 3px;
  background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 20 3'><path d='M10 0 L13 1.5 L10 3 L7 1.5 Z' fill='%23D4A04F'/></svg>");
  background-size: 8px 3px;
  background-repeat: repeat-x;
  background-position: center;
}
/* Pill Djawal IA — surligné dans la nav */
.nav-link-ia {
  display: inline-flex !important;
  align-items: center;
  gap: 8px;
  padding: 7px 16px 7px 10px !important;
  background: linear-gradient(135deg, rgba(212, 160, 79, 0.25), rgba(184, 134, 46, 0.18));
  color: var(--c-accent-fort, #B8862E) !important;
  border-radius: 999px;
  text-transform: uppercase;
  border: 1px solid rgba(184, 134, 46, 0.35);
}
.nav-link-ia.router-link-active::after { display: none; }
.nav-djawal-icon {
  width: 24px; height: 24px;
  flex-shrink: 0;
  border-radius: 6px;
  object-fit: contain;
}

/* === Mini header mobile === */
.mobile-header {
  position: sticky;
  top: 0;
  z-index: 50;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 16px;
  background: rgba(250, 247, 242, 0.95);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border-bottom: 1px solid rgba(10, 31, 46, 0.06);
}
.mob-logo {
  display: flex;
  align-items: center;
  gap: 8px;
  text-decoration: none;
}
.mob-mark {
  width: 32px; height: 32px;
  background: #2D5A3D; /* Vert Atlas — verrouillé (kept for retro-compat) */
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 0 0 1.5px rgba(232, 181, 71, 0.35);
}
.mob-mark svg { width: 18px; height: 18px; }
.mob-logo-img {
  width: 36px;
  height: 36px;
  display: block;
  border-radius: 8px;
  object-fit: cover;
}
.mob-name {
  font-family: var(--font-display, 'Cormorant Garamond', Georgia, serif);
  font-size: 20px;
  font-weight: 500;
  color: var(--c-primaire-profond, #0A1F2E);
  line-height: 1;
}
.mob-name small {
  display: block;
  font-family: var(--font-arabic, 'Amiri', serif);
  font-size: 10px;
  color: var(--c-accent-fort, #B8862E);
  margin-top: 1px;
}
.mob-actions { display: flex; gap: 8px; align-items: center; }
.mob-btn {
  width: 36px; height: 36px;
  background: var(--c-surface, #FFFFFF);
  border: 1px solid rgba(10, 31, 46, 0.08);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--c-primaire-profond, #0A1F2E);
  text-decoration: none;
}
.mob-btn svg { width: 16px; height: 16px; }
.mob-btn-cta {
  padding: 8px 14px;
  background: var(--c-primaire-profond, #0A1F2E);
  color: var(--c-fond, #FAF7F2);
  text-decoration: none;
  border-radius: 20px;
  font-size: 12px;
  font-weight: 500;
}

/* ===== MODE OVERLAY transparent sur toutes les pages publiques V4 ===== */
/* Header natif : passe en position:absolute + fond transparent */
.desktop-header.header-overlay {
  position: absolute;
  background: transparent;
  border-bottom: none;
  box-shadow: none;
}
.header-overlay .header-row,
.header-overlay .nav-desktop,
.header-overlay .header-actions {
  pointer-events: auto !important;
  position: relative;
  z-index: 101;
}
.header-overlay .nav-link {
  color: #FAF7F2 !important;
  text-shadow: 0 2px 8px rgba(0, 0, 0, 0.4);
}
.header-overlay .nav-link:hover { color: #FFD479 !important; }
.header-overlay .nav-link.router-link-active::after { display: none; }
/* Pill IA Djawal visible sur fond foncé */
.header-overlay .nav-link-ia {
  background: rgba(212, 160, 79, 0.95) !important;
  color: #0A1F2E !important;
  border: 1px solid rgba(255, 212, 121, 0.7) !important;
  text-shadow: none !important;
  box-shadow: 0 4px 14px rgba(212, 160, 79, 0.4);
}
.header-overlay .nav-link-ia:hover {
  background: #E8B547 !important;
  color: #0A1F2E !important;
}
/* Boutons natifs en mode overlay : Connexion blanc, Nous rejoindre orange brillant */
.header-overlay .login-btn-native {
  color: #FAF7F2 !important;
  text-shadow: 0 2px 8px rgba(0, 0, 0, 0.4);
}
.header-overlay .login-btn-native:hover {
  background: rgba(250, 247, 242, 0.12) !important;
}
.header-overlay .signup-btn-native {
  background: linear-gradient(135deg, #FA8214, #C95F00) !important;
  color: #FAF7F2 !important;
  box-shadow: 0 4px 14px rgba(250, 130, 20, 0.45) !important;
}
.header-overlay .signup-btn-native:hover {
  box-shadow: 0 8px 24px rgba(250, 130, 20, 0.6) !important;
}
.header-overlay .account-btn-native {
  color: #FAF7F2 !important;
  border-color: rgba(250, 247, 242, 0.35) !important;
  background: rgba(15, 36, 25, 0.4) !important;
  backdrop-filter: blur(8px);
}
.header-overlay .logo-img { filter: drop-shadow(0 4px 12px rgba(0, 0, 0, 0.3)); }

/* === Mode overlay sur mini-header MOBILE (pages V4 vert sombre) === */
.mobile-header-overlay {
  position: absolute !important;
  background: transparent !important;
  border-bottom: none !important;
  backdrop-filter: none !important;
  -webkit-backdrop-filter: none !important;
  z-index: 100;
  left: 0; right: 0; top: 0;
}
.mobile-header-overlay .mob-name {
  color: #FAF7F2 !important;
  text-shadow: 0 2px 8px rgba(0, 0, 0, 0.5);
}
.mobile-header-overlay .mob-name small {
  color: #E8B96B !important;
}
.mobile-header-overlay .mob-btn {
  background: rgba(15, 36, 25, 0.55) !important;
  border-color: rgba(212, 168, 68, 0.4) !important;
  color: #FAF7F2 !important;
  backdrop-filter: blur(8px);
}
.mobile-header-overlay .mob-btn-cta {
  background: linear-gradient(135deg, #D4A844, #B8862E) !important;
  color: #0F2419 !important;
  box-shadow: 0 4px 14px rgba(212, 168, 68, 0.4);
}
.mobile-header-overlay .mob-logo-img {
  filter: drop-shadow(0 4px 10px rgba(0, 0, 0, 0.4));
}
</style>
