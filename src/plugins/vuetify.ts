import 'vuetify/styles'
import { createVuetify } from 'vuetify'

// Thème Djawal — surcharge les couleurs Vuetify avec la palette algérienne
const djawalTheme = {
  dark: false,
  colors: {
    background: '#FAF7F2',
    surface: '#FFFFFF',
    primary: '#1B4965',         // bleu Casbah
    'primary-darken-1': '#0A1F2E',
    secondary: '#D4A04F',       // or Sahara
    'secondary-darken-1': '#B8862E',
    accent: '#C04A3A',          // rouge corail (CTA)
    success: '#6B7A4A',         // olivier
    warning: '#D4A04F',
    error: '#C04A3A',
    info: '#4A90BD',
    'on-primary': '#FAF7F2',
    'on-secondary': '#1B4965',
    'on-surface': '#1A1A1A',
    'on-background': '#1A1A1A'
  }
}

export default createVuetify({
  theme: {
    defaultTheme: 'djawal',
    themes: {
      djawal: djawalTheme
    }
  },
  defaults: {
    VBtn: {
      style: 'text-transform: uppercase; letter-spacing: 0.06em; font-weight: 600;',
      rounded: 'md'
    },
    VCard: {
      rounded: 'lg'
    },
    VTextField: {
      variant: 'outlined',
      density: 'comfortable'
    }
  }
})
