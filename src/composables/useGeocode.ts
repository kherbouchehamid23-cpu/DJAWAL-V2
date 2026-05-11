import { ref } from 'vue'

interface GeocodeResult {
  lat: number
  lng: number
  display_name: string
  wilaya?: string
}

/**
 * Géocodage via OpenStreetMap Nominatim (gratuit, sans clé).
 * Limite : 1 requête/seconde max (respecte la politique d'usage Nominatim).
 */
export function useGeocode() {
  const loading = ref(false)
  const error = ref<string | null>(null)

  async function geocode(address: string): Promise<GeocodeResult | null> {
    if (!address || address.trim().length < 3) {
      error.value = 'Adresse trop courte'
      return null
    }

    loading.value = true
    error.value = null

    try {
      const params = new URLSearchParams({
        q: address + ', Algeria',
        format: 'json',
        limit: '1',
        countrycodes: 'dz',
        addressdetails: '1'
      })

      const res = await fetch(`https://nominatim.openstreetmap.org/search?${params}`, {
        headers: {
          'Accept-Language': 'fr',
          'User-Agent': 'Djawal/1.0 (https://djawal.com)'
        }
      })

      if (!res.ok) {
        error.value = `Erreur HTTP ${res.status}`
        return null
      }

      const data = await res.json()
      if (!Array.isArray(data) || data.length === 0) {
        error.value = 'Adresse introuvable en Algérie'
        return null
      }

      const first = data[0]
      return {
        lat: parseFloat(first.lat),
        lng: parseFloat(first.lon),
        display_name: first.display_name,
        wilaya: first.address?.state || first.address?.province
      }
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Erreur réseau'
      return null
    } finally {
      loading.value = false
    }
  }

  async function reverseGeocode(lat: number, lng: number): Promise<string | null> {
    loading.value = true
    error.value = null
    try {
      const params = new URLSearchParams({
        lat: String(lat),
        lon: String(lng),
        format: 'json',
        zoom: '14'
      })
      const res = await fetch(`https://nominatim.openstreetmap.org/reverse?${params}`, {
        headers: { 'Accept-Language': 'fr', 'User-Agent': 'Djawal/1.0' }
      })
      const data = await res.json()
      return data?.display_name || null
    } catch (e) {
      error.value = e instanceof Error ? e.message : 'Erreur'
      return null
    } finally {
      loading.value = false
    }
  }

  return { geocode, reverseGeocode, loading, error }
}
