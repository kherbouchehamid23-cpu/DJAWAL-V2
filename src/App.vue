<script setup lang="ts">
import { onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useThemeStore } from '@/stores/theme'
import AppHeader from '@/components/AppHeader.vue'
import AppFooter from '@/components/AppFooter.vue'
import AIAssistant from '@/components/AIAssistant.vue'
import OnboardingHint from '@/components/OnboardingHint.vue'
import InstallPWA from '@/components/InstallPWA.vue'
import BottomNav from '@/components/BottomNav.vue'
import PwaUpdateBanner from '@/components/PwaUpdateBanner.vue'

const route = useRoute()
const themeStore = useThemeStore()

// Le thème culturel suit le route meta — basculé au changement de page
watch(
  () => route.meta.culturalTheme as string | undefined,
  (newTheme) => {
    if (newTheme) themeStore.setTheme(newTheme as 'saharien' | 'mauresque' | 'aures')
  },
  { immediate: true }
)

onMounted(() => {
  themeStore.applyToDocument()
})
</script>

<template>
  <v-app>
    <AppHeader />
    <v-main>
      <router-view v-slot="{ Component }">
        <component :is="Component" />
      </router-view>
    </v-main>
    <AppFooter />
    <AIAssistant />
    <OnboardingHint />
    <InstallPWA />
    <PwaUpdateBanner />
    <BottomNav />
  </v-app>
</template>

<style scoped>
/* Pas de transition entre routes — évite les bugs d'opacity 0 bloquée
   sur certaines pages après router.push() depuis une callback async. */
</style>
