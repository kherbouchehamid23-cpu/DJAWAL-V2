import { ref, onMounted, onBeforeUnmount, computed } from 'vue'

/**
 * Composable réactif pour détecter le breakpoint courant.
 * Met à jour automatiquement quand la fenêtre est redimensionnée.
 *
 * Breakpoints :
 * - mobile  : < 640px
 * - tablet  : 640 - 1024px
 * - desktop : >= 1024px
 */

const MOBILE_MAX = 640
const TABLET_MAX = 1024

const width = ref(typeof window !== 'undefined' ? window.innerWidth : 1280)

function updateWidth() {
  if (typeof window !== 'undefined') {
    width.value = window.innerWidth
  }
}

if (typeof window !== 'undefined') {
  window.addEventListener('resize', updateWidth, { passive: true })
}

export function useBreakpoint() {
  const isMobile = computed(() => width.value < MOBILE_MAX)
  const isTablet = computed(() => width.value >= MOBILE_MAX && width.value < TABLET_MAX)
  const isDesktop = computed(() => width.value >= TABLET_MAX)
  const isMobileOrTablet = computed(() => width.value < TABLET_MAX)

  onMounted(updateWidth)
  onBeforeUnmount(() => {
    // listener global, on ne le retire pas
  })

  return { width, isMobile, isTablet, isDesktop, isMobileOrTablet }
}
