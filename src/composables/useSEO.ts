import { watch } from 'vue'

/**
 * Composable pour gérer les meta tags dynamiquement.
 * À appeler dans le setup d'une page :
 *   useSEO({ title: 'X', description: 'Y', image: 'Z' })
 *
 * Met à jour : <title>, meta description, OG, Twitter Card, canonical
 */

interface SEOData {
  title?: string
  description?: string
  image?: string
  url?: string
  type?: 'website' | 'article'
}

const BASE_URL = 'https://djawal-v2.vercel.app'
const SUFFIX = ' — Djawal'
const DEFAULT_IMAGE = `${BASE_URL}/icons/pwa-512.png`

function setMeta(selector: string, content: string) {
  let el = document.head.querySelector(selector) as HTMLMetaElement | null
  if (!el) {
    el = document.createElement('meta')
    // Determine attribute type
    const match = selector.match(/\[(\w+)="([^"]+)"\]/)
    if (match) {
      el.setAttribute(match[1], match[2])
    }
    document.head.appendChild(el)
  }
  el.setAttribute('content', content)
}

function setLink(rel: string, href: string) {
  let el = document.head.querySelector(`link[rel="${rel}"]`) as HTMLLinkElement | null
  if (!el) {
    el = document.createElement('link')
    el.setAttribute('rel', rel)
    document.head.appendChild(el)
  }
  el.setAttribute('href', href)
}

function apply(data: SEOData) {
  const fullTitle = data.title ? `${data.title}${SUFFIX}` : `Djawal — Voyager l'Algérie autrement`
  document.title = fullTitle

  const desc = data.description ||
    'Plateforme communautaire de voyages en Algérie. Découvrez destinations, parcours signés par des guides locaux et IA de recommandation.'
  const image = data.image || DEFAULT_IMAGE
  const url = data.url || (typeof window !== 'undefined' ? window.location.href : BASE_URL)
  const type = data.type || 'website'

  setMeta('meta[name="description"]', desc)

  // Open Graph
  setMeta('meta[property="og:title"]', fullTitle)
  setMeta('meta[property="og:description"]', desc)
  setMeta('meta[property="og:image"]', image)
  setMeta('meta[property="og:url"]', url)
  setMeta('meta[property="og:type"]', type)
  setMeta('meta[property="og:site_name"]', 'Djawal')
  setMeta('meta[property="og:locale"]', 'fr_FR')

  // Twitter Card
  setMeta('meta[name="twitter:card"]', 'summary_large_image')
  setMeta('meta[name="twitter:title"]', fullTitle)
  setMeta('meta[name="twitter:description"]', desc)
  setMeta('meta[name="twitter:image"]', image)

  // Canonical
  setLink('canonical', url)
}

export function useSEO(data: SEOData | (() => SEOData)) {
  if (typeof data === 'function') {
    // Reactive : ré-appliquer à chaque changement
    apply(data())
    watch(data, (newData) => apply(newData), { immediate: false })
  } else {
    apply(data)
  }
}
