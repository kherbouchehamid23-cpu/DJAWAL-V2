/**
 * Parse une coordinate Supabase au format GeoJSON ou WKB hex
 * Retourne {lat, lng} ou null
 */
export function parseCoordinates(coords: any): { lat: number; lng: number } | null {
  if (!coords) return null

  // GeoJSON format (when select column with ::geometry cast)
  if (typeof coords === 'object' && coords.coordinates) {
    const [lng, lat] = coords.coordinates
    return { lat, lng }
  }

  // WKB hex format (default PostGIS output)
  if (typeof coords === 'string' && coords.startsWith('01')) {
    return parseWKBHex(coords)
  }

  // POINT(lng lat) text format
  if (typeof coords === 'string' && coords.toUpperCase().includes('POINT')) {
    const match = coords.match(/POINT\s*\(\s*([-\d.]+)\s+([-\d.]+)\s*\)/i)
    if (match) {
      return { lng: parseFloat(match[1]), lat: parseFloat(match[2]) }
    }
  }

  return null
}

/**
 * Décode un WKB hex (Well-Known Binary) pour un POINT 2D
 * Format : 0101000020E6100000 <8 bytes lng little-endian> <8 bytes lat little-endian>
 */
function parseWKBHex(hex: string): { lat: number; lng: number } | null {
  try {
    // Skip endian + type + SRID (9 bytes = 18 hex chars)
    const payload = hex.substring(18)
    if (payload.length < 32) return null

    const lngHex = payload.substring(0, 16)
    const latHex = payload.substring(16, 32)

    const lng = hexToDouble(lngHex)
    const lat = hexToDouble(latHex)

    if (isNaN(lng) || isNaN(lat)) return null
    return { lat, lng }
  } catch {
    return null
  }
}

function hexToDouble(hex: string): number {
  // Little-endian → reverse bytes
  const bytes = new Uint8Array(8)
  for (let i = 0; i < 8; i++) {
    bytes[i] = parseInt(hex.substring(i * 2, i * 2 + 2), 16)
  }
  const buffer = bytes.buffer
  const view = new DataView(buffer)
  return view.getFloat64(0, true) // little-endian
}
