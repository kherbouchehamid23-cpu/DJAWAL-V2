// =========================================================
// DJAWAL V2 — Edge Function : generate-embeddings
// Utilitaire admin : embed toutes les ressources sans embedding
// Appelé depuis /admin/ia-logs avec un body { table: 'hotels'|... }
// =========================================================

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')!

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': '*',
  'Access-Control-Max-Age': '86400'
}

const TABLES = ['destinations', 'hotels', 'sites', 'restaurants', 'trips', 'activities'] as const

async function embed(text: string): Promise<number[]> {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/text-embedding-004:embedContent?key=${GEMINI_API_KEY}`
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model: 'models/text-embedding-004',
      content: { parts: [{ text }] }
    })
  })
  if (!res.ok) throw new Error(await res.text())
  const json = await res.json()
  return json.embedding.values
}

function buildText(row: any, table: string): string {
  if (table === 'destinations') {
    return `${row.name} (${row.wilaya}, ${row.cultural_theme}). ${row.description}`
  }
  if (table === 'trips') {
    return `${row.title}. ${row.description}. Tags: ${(row.tags || []).join(', ')}`
  }
  if (table === 'activities') {
    return `${row.name}. ${row.description}. Type: ${row.activity_type || ''}. Difficulté: ${row.difficulty || ''}.`
  }
  // hotels / sites / restaurants
  const extra = row.cuisine ? row.cuisine.join(', ')
    : row.amenities ? row.amenities.join(', ')
    : row.category || ''
  return `${row.name}. ${row.description}. ${extra}`
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { table, limit = 50 } = await req.json()
    if (!TABLES.includes(table)) {
      return new Response(JSON.stringify({ error: 'table invalide' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // Sélectionner les colonnes utiles
    let cols = 'id, name, description'
    if (table === 'destinations') cols = 'id, name, wilaya, cultural_theme, description'
    if (table === 'hotels') cols = 'id, name, description, amenities'
    if (table === 'sites') cols = 'id, name, description, category'
    if (table === 'restaurants') cols = 'id, name, description, cuisine'
    if (table === 'trips') cols = 'id, title, description, tags'
    if (table === 'activities') cols = 'id, name, description, activity_type, difficulty'

    const { data: rows, error } = await supabase
      .from(table)
      .select(cols)
      .is('embedding', null)
      .limit(limit)

    if (error) throw error
    if (!rows || rows.length === 0) {
      return new Response(JSON.stringify({ processed: 0, message: 'Rien à embed.' }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    let processed = 0
    let failed = 0
    const errors: string[] = []

    for (const row of rows as any[]) {
      try {
        const text = buildText(row, table)
        const vector = await embed(text)
        const { error: upErr } = await supabase
          .from(table)
          .update({ embedding: vector })
          .eq('id', row.id)
        if (upErr) throw upErr
        processed++
        // léger throttle pour rester sous quota Gemini gratuit
        await new Promise(r => setTimeout(r, 200))
      } catch (e: any) {
        failed++
        errors.push(`${row.id}: ${e.message}`)
      }
    }

    return new Response(JSON.stringify({
      table,
      processed,
      failed,
      errors: errors.slice(0, 5)
    }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })

  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
