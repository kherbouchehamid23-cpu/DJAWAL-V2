// =========================================================
// DJAWAL V2 — Edge Function : image-proxy
// Proxy CORS pour images externes (panoramas 360, etc.)
// Usage : /functions/v1/image-proxy?url=https://djawal.bilnov.com/.../img.jpg
// =========================================================

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': '*',
  'Access-Control-Max-Age': '86400'
}

// Whitelist : seuls ces domaines peuvent être proxifiés (sécurité)
const ALLOWED_HOSTS = [
  'djawal.bilnov.com',
  'bilnov.com'
]

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const url = new URL(req.url)
  const target = url.searchParams.get('url')

  if (!target) {
    return new Response(JSON.stringify({ error: 'Missing ?url= parameter' }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }

  // Validation du domaine
  let parsed: URL
  try {
    parsed = new URL(target)
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid URL' }), {
      status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
  if (!ALLOWED_HOSTS.some(h => parsed.hostname === h || parsed.hostname.endsWith('.' + h))) {
    return new Response(JSON.stringify({ error: 'Domain not allowed' }), {
      status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }

  try {
    const upstream = await fetch(target, {
      headers: {
        'User-Agent': 'Djawal-ImageProxy/1.0',
        'Accept': 'image/*'
      }
    })
    if (!upstream.ok) {
      return new Response(JSON.stringify({ error: `Upstream error ${upstream.status}` }), {
        status: upstream.status, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }
    const contentType = upstream.headers.get('content-type') || 'image/jpeg'
    return new Response(upstream.body, {
      headers: {
        ...corsHeaders,
        'Content-Type': contentType,
        'Cache-Control': 'public, max-age=86400, immutable'
      }
    })
  } catch (e: any) {
    return new Response(JSON.stringify({ error: e.message || 'Fetch failed' }), {
      status: 502, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
