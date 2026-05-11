import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { registerSW } from 'virtual:pwa-register'

import App from './App.vue'
import router from './router'
import vuetify from './plugins/vuetify'

// Styles globaux : ordre important — base avant thèmes avant overrides
import './styles/base.css'
import './styles/themes/saharien.css'
import './styles/themes/mauresque.css'
import './styles/themes/aures.css'
import './styles/patterns.css'

// PWA — enregistrement du service worker avec mise à jour silencieuse
const updateSW = registerSW({
  onNeedRefresh() {
    // Le hook peut afficher une snackbar Vuetify pour proposer le reload
    console.info('[PWA] Mise à jour disponible — rechargement au prochain navigate')
  },
  onOfflineReady() {
    console.info('[PWA] Prêt pour utilisation hors-ligne')
  }
})

const app = createApp(App)
app.use(createPinia())
app.use(router)
app.use(vuetify)
app.mount('#app')

export { updateSW }
