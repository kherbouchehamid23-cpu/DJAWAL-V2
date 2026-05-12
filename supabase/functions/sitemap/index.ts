// =========================================================
// DJAWAL V2 — Edge Function : sitemap.xml dynamique
// =========================================================

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const BASE_URL = 'https://djawal-v2.vercel.app'

serve(async (_req) => {
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

  const [destinations, trips, guides, memories] = await Promise.all([
    supabase.from('destinations').select('slug, updated_at').order('updated_at', { ascending: false }),
    supabase.from('trips').select('id, updated_at').eq('status', 'published').order('updated_at', { ascending: false }),
    supabase.from('profiles').select('id, created_at').in('role', ['guide_senior', 'guide_junior']).eq('is_active', true),
    supabase.from('memories').select('id, created_at').eq('published', true).limit(200)
  ])

  const urls: { loc: string; lastmod?: string; priority: number; changefreq: string }[] = [
    { loc: `${BASE_URL}/`, priority: 1.0, changefreq: 'daily' },
    { loc: `${BASE_URL}/voyages`, priority: 0.9, changefreq: 'daily' },
    { loc: `${BASE_URL}/composer`, priority: 0.9, changefreq: 'weekly' },
    { loc: `${BASE_URL}/temoignages`, priority: 0.7, changefreq: 'weekly' },
    { loc: `${BASE_URL}/about`, priority: 0.5, changefreq: 'monthly' },
    { loc: `${BASE_URL}/contact`, priority: 0.4, changefreq: 'yearly' },
    { loc: `${BASE_URL}/mentions-legales`, priority: 0.2, changefreq: 'yearly' },
    { loc: `${BASE_URL}/cgu`, priority: 0.2, changefreq: 'yearly' },
  ]

  for (const d of (destinations.data || [])) {
    urls.push({
      loc: `${BASE_URL}/destination/${d.slug}`,
      lastmod: d.updated_at,
      priority: 0.8,
      changefreq: 'weekly'
    })
  }
  for (const t of (trips.data || [])) {
    urls.push({
      loc: `${BASE_URL}/voyages/${t.id}`,
      lastmod: t.updated_at,
      priority: 0.7,
      changefreq: 'weekly'
    })
  }
  for (const g of (guides.data || [])) {
    urls.push({
      loc: `${BASE_URL}/guide/${g.id}`,
      lastmod: g.created_at,
      priority: 0.6,
      changefreq: 'monthly'
    })
  }
  for (const m of (memories.data || [])) {
    urls.push({
      loc: `${BASE_URL}/temoignages#m-${m.id}`,
      lastmod: m.created_at,
      priority: 0.3,
      changefreq: 'monthly'
    })
  }

  const xml = `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls.map(u => `  <url>
    <loc>${u.loc}</loc>${u.lastmod ? `\n    <lastmod>${u.lastmod}</lastmod>` : ''}
    <changefreq>${u.changefreq}</changefreq>
    <priority>${u.priority}</priority>
  </url>`).join('\n')}
</urlset>`

  return new Response(xml, {
    headers: {
      'Content-Type': 'application/xml; charset=utf-8',
      'Cache-Control': 'public, max-age=3600'
    }
  })
})
