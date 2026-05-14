<script setup lang="ts">
import { ref } from 'vue'
import { RouterLink } from 'vue-router'
import { useThemeStore } from '@/stores/theme'
import { useAuthStore } from '@/stores/auth'
import { useBreakpoint } from '@/composables/useBreakpoint'

const theme = useThemeStore()
const auth = useAuthStore()
const drawer = ref(false)
const { isMobile } = useBreakpoint()

const navItems = [
  { to: '/voyages', label: 'Voyages' },
  { to: '/composer', label: '✨ IA' },
  { to: '/temoignages', label: 'Souvenirs' },
  { to: '/about', label: 'À propos' }
]
</script>

<template>
  <v-app-bar v-if="!isMobile" :elevation="2" color="surface" height="72">
    <v-container class="header-row" max-width="1340">
      <!-- LOGO — Fibule de l'Aurès sur Vert Atlas -->
      <RouterLink to="/" class="logo-wrap">
        <div class="logo-mark">
          <svg viewBox="0 0 32 32" width="26" height="26" aria-hidden="true">
            <!-- chaînette haute -->
            <line x1="16" y1="1.5" x2="16" y2="5" stroke="#E8B547" stroke-width="1.3"/>
            <!-- cercle ocre extérieur -->
            <circle cx="16" cy="16" r="9.5" fill="none" stroke="#E8B547" stroke-width="1.4"/>
            <!-- triangles berbères latéraux -->
            <path d="M3 16 L7 13 L7 19 Z" fill="#E8B547"/>
            <path d="M29 16 L25 13 L25 19 Z" fill="#E8B547"/>
            <!-- émail rouge central -->
            <circle cx="16" cy="16" r="3.2" fill="#B8312E"/>
            <circle cx="16" cy="16" r="1.2" fill="#E8B547"/>
            <!-- pendentif goutte -->
            <circle cx="16" cy="29" r="1.4" fill="#E8B547"/>
            <line x1="16" y1="26" x2="16" y2="28" stroke="#E8B547" stroke-width="1"/>
          </svg>
        </div>
        <div class="logo-text">
          <span class="logo-fr">Djawal</span>
          <span class="logo-ar arabic">جوّال</span>
        </div>
      </RouterLink>

      <!-- NAV DESKTOP -->
      <nav class="nav-desktop">
        <RouterLink
          v-for="item in navItems"
          :key="item.to"
          :to="item.to"
          class="nav-link"
        >
          {{ item.label }}
        </RouterLink>
      </nav>

      <!-- ACTIONS -->
      <div class="header-actions">
        <v-btn
          variant="text"
          size="small"
          :icon="theme.ambientSoundEnabled ? 'mdi-volume-high' : 'mdi-volume-off'"
          :title="theme.ambientSoundEnabled ? 'Couper l\'ambiance' : 'Activer l\'ambiance'"
          @click="theme.toggleAmbientSound"
        />

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
              <v-list-item v-if="auth.isAdmin" to="/admin" title="Administration" />
              <v-divider />
              <v-list-item title="Se déconnecter" @click="auth.signOut" />
            </v-list>
          </v-menu>
        </template>
        <template v-else>
          <v-btn to="/auth/login" variant="text" class="login-btn">Connexion</v-btn>
          <v-btn to="/auth/signup" color="primary" variant="flat">Rejoindre</v-btn>
        </template>
      </div>
    </v-container>
  </v-app-bar>

  <!-- === Mini header mobile === -->
  <header v-if="isMobile" class="mobile-header">
    <RouterLink to="/" class="mob-logo">
      <div class="mob-mark">
        <svg viewBox="0 0 32 32" aria-hidden="true">
          <circle cx="16" cy="16" r="9.5" fill="none" stroke="#E8B547" stroke-width="1.4"/>
          <path d="M3 16 L7 13 L7 19 Z" fill="#E8B547"/>
          <path d="M29 16 L25 13 L25 19 Z" fill="#E8B547"/>
          <circle cx="16" cy="16" r="3.2" fill="#B8312E"/>
          <circle cx="16" cy="16" r="1.2" fill="#E8B547"/>
        </svg>
      </div>
      <span class="mob-name">Djawal<small class="arabic">جوّال</small></span>
    </RouterLink>
    <div class="mob-actions">
      <RouterLink to="/voyages" class="mob-btn" aria-label="Rechercher">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="7"/><path d="M21 21l-4-4"/></svg>
      </RouterLink>
      <RouterLink v-if="!auth.isAuthenticated" to="/auth/login" class="mob-btn-cta">Connexion</RouterLink>
      <RouterLink v-else :to="auth.isAdmin ? '/admin' : auth.isGuide ? '/espace-guide' : '/mon-espace'" class="mob-btn" aria-label="Mon espace">
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
  background: #2D5A3D; /* Vert Atlas — verrouillé */
  border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  box-shadow: 0 0 0 2px rgba(232, 181, 71, 0.35);
}
.logo-text { line-height: 1; }
.logo-fr {
  display: block;
  font-family: var(--font-display);
  font-size: 26px;
  font-weight: 600;
  color: var(--c-primaire);
}
.logo-ar {
  display: block;
  font-family: var(--font-arabic);
  font-size: 13px;
  color: var(--c-accent-fort);
  margin-top: -2px;
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
  background: #2D5A3D; /* Vert Atlas — verrouillé */
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 0 0 1.5px rgba(232, 181, 71, 0.35);
}
.mob-mark svg { width: 18px; height: 18px; }
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
</style>
