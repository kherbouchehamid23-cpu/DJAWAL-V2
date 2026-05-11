<script setup lang="ts">
import { ref } from 'vue'
import { RouterLink } from 'vue-router'
import { useThemeStore } from '@/stores/theme'
import { useAuthStore } from '@/stores/auth'

const theme = useThemeStore()
const auth = useAuthStore()
const drawer = ref(false)

const navItems = [
  { to: '/voyages', label: 'Voyages' },
  { to: '/composer', label: '✨ IA' },
  { to: '/temoignages', label: 'Souvenirs' },
  { to: '/about', label: 'À propos' }
]
</script>

<template>
  <v-app-bar :elevation="2" color="surface" height="72">
    <v-container class="d-flex align-center" max-width="1340">
      <!-- LOGO -->
      <RouterLink to="/" class="logo-wrap">
        <div class="logo-mark">
          <svg viewBox="0 0 32 32" width="24" height="24">
            <g fill="none" stroke="var(--c-accent)" stroke-width="2">
              <path d="M16 2 L28 16 L16 30 L4 16 Z" />
              <circle cx="16" cy="16" r="5" />
              <circle cx="16" cy="16" r="1.5" fill="var(--c-accent)" />
            </g>
          </svg>
        </div>
        <div class="logo-text">
          <span class="logo-fr">Djawal</span>
          <span class="logo-ar arabic">جوّال</span>
        </div>
      </RouterLink>

      <v-spacer />

      <!-- NAV DESKTOP -->
      <nav class="nav-desktop d-none d-md-flex">
        <RouterLink
          v-for="item in navItems"
          :key="item.to"
          :to="item.to"
          class="nav-link"
        >
          {{ item.label }}
        </RouterLink>
      </nav>

      <v-spacer />

      <!-- ACTIONS -->
      <div class="d-flex align-center ga-2">
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
              <v-btn variant="text" v-bind="props">
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
          <v-btn to="/auth/login" variant="text" class="d-none d-sm-inline-flex">Connexion</v-btn>
          <v-btn to="/auth/signup" color="primary" variant="flat">Rejoindre</v-btn>
        </template>

        <v-app-bar-nav-icon class="d-md-none" @click="drawer = !drawer" />
      </div>
    </v-container>
  </v-app-bar>

  <!-- Drawer mobile -->
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
.logo-wrap {
  display: flex;
  align-items: center;
  gap: 10px;
  text-decoration: none;
}
.logo-mark {
  width: 44px; height: 44px;
  background: var(--c-primaire);
  border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  box-shadow: 0 0 0 3px var(--c-accent), 0 0 0 5px var(--c-primaire);
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
.nav-desktop { gap: 32px; }
.nav-link {
  color: var(--c-primaire-profond);
  font-size: 13px;
  font-weight: 600;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  padding: 8px 0;
  position: relative;
  transition: color var(--t-fast);
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
</style>
