import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export type CulturalTheme = 'saharien' | 'mauresque' | 'aures'

const THEME_KEY = 'djawal-cultural-theme'
const SOUND_KEY = 'djawal-ambient-sound'

/**
 * Pilote le miroir culturel dynamique (spec section 4.A).
 * Le thème est appliqué via une classe sur <html> qui surcharge les CSS variables racine.
 */
export const useThemeStore = defineStore('theme', () => {
  const currentTheme = ref<CulturalTheme>(
    (localStorage.getItem(THEME_KEY) as CulturalTheme) || 'mauresque'
  )
  const ambientSoundEnabled = ref<boolean>(
    localStorage.getItem(SOUND_KEY) === 'true'
  )

  const themeLabel = computed(() => {
    switch (currentTheme.value) {
      case 'saharien': return 'Saharien · صحراوي'
      case 'mauresque': return 'Mauresque · أندلسي'
      case 'aures': return 'Aurès · أوراسي'
    }
  })

  function setTheme(theme: CulturalTheme) {
    currentTheme.value = theme
    localStorage.setItem(THEME_KEY, theme)
    applyToDocument()
  }

  function applyToDocument() {
    const html = document.documentElement
    html.classList.remove('theme-saharien', 'theme-mauresque', 'theme-aures')
    html.classList.add(`theme-${currentTheme.value}`)
  }

  function toggleAmbientSound() {
    ambientSoundEnabled.value = !ambientSoundEnabled.value
    localStorage.setItem(SOUND_KEY, String(ambientSoundEnabled.value))
  }

  return {
    currentTheme,
    themeLabel,
    ambientSoundEnabled,
    setTheme,
    applyToDocument,
    toggleAmbientSound
  }
})
