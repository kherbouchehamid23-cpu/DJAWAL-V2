import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { registerSW } from 'virtual:pwa-register'

import App from './App.vue'
import router from './router'
import vuetify from './plugins/vuetify'
import { useAuthStore } from './stores/auth'

// Styles globaux : ordre important — base avant thèmes avant overrides
import './styles/base.css'
import './styles/themes/saharien.css'
import './styles/themes/mauresque.css'
import './styles/themes/aures.css'
import './styles/patterns.css'

// PWA — enregistrement du service worker avec mise à jour silencieuse
const updateSW = registerSW({
  onNeedRefresh() {
    console.info('[PWA] Mise à jour disponible — rechargement au prochain navigate')
  },
  onOfflineReady() {
    console.info('[PWA] Prêt pour utilisation hors-ligne')
  }
})

const app = createApp(App)
const pinia = createPinia()

app.use(pinia)
app.use(vuetify)

// Initialiser l'authentification AVANT de monter le router
const authStore = useAuthStore()
authStore.initialize().finally(() => {
  app.use(router)
  app.mount('#app')
})

export { updateSW }
