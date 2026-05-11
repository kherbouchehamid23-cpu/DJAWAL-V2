<script setup lang="ts">
import { onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useThemeStore } from '@/stores/theme'
import AppHeader from '@/components/AppHeader.vue'
import AppFooter from '@/components/AppFooter.vue'
import AIAssistant from '@/components/AIAssistant.vue'

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
        <transition name="fade" mode="out-in">
          <component :is="Component" />
        </transition>
      </router-view>
    </v-main>
    <AppFooter />
    <AIAssistant />
  </v-app>
</template>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.3s ease;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
