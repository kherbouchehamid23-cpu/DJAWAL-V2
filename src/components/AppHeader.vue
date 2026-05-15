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
const isHomePage = computed(() => route.path === '/')

const navItems = [
  { to: '/voyages', label: 'Destinations' },
  { to: '/voyages', label: 'Voyages signés' },
  { to: '/temoignages', label: 'Souvenirs' },
  { to: '/composer', label: 'Djawal IA', accent: true }
]
</script>

<template>
  <v-app-bar
    v-if="!isMobile"
    :elevation="isHomePage ? 0 : 2"
    :color="isHomePage ? 'transparent' : 'surface'"
    :class="{ 'header-overlay': isHomePage }"
    height="72"
  >
    <v-container class="header-row" max-width="1340">
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
              <v-btn variant="text" v-bind="props" class="account-btn">
                {{ auth.profile?.display_name || 'Mon compte' }}
              </v-btn>
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
          <v-btn to="/auth/login" variant="text" class="login-btn">Connexion</v-btn>
          <v-btn to="/auth/signup" color="primary" variant="flat">Nous rejoindre</v-btn>
        </template>
      </div>
    </v-container>
  </v-app-bar>

  <!-- === Mini header mobile === -->
  <header v-if="isMobile" class="mobile-header">
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
/* Grille header : logo gauche, nav centre, actions droite — zéro chevauchement */
.header-row {
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 24px;
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

/* Mode transparent overlay sur la HomePage (hero image plein écran) */
.header-overlay {
  position: absolute !important;
  background: transparent !important;
  box-shadow: none !important;
  z-index: 100 !important;
  pointer-events: auto !important;
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
.header-overlay .login-btn { color: #FAF7F2 !important; text-shadow: 0 2px 8px rgba(0, 0, 0, 0.4); }
.header-overlay .logo-img { filter: drop-shadow(0 4px 12px rgba(0, 0, 0, 0.3)); }
</style>
