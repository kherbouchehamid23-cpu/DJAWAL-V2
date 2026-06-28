// =========================================================
// DJAWAL V2 — Edge Function : coach
// Coach Djawal côté offre : aide les opérateurs/guides à rédiger
// une fiche voyage complète, trilingue (FR/AR/EN), ancrée sur le
// catalogue réel de la destination (anti-hallucination).
// Actions : generate | rewrite | translate
// La clé Gemini reste ici (serveur), jamais exposée au front.
// =========================================================

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')!
const GEN_MODEL = 'gemini-2.5-flash-lite'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': '*',
  'Access-Control-Max-Age': '86400'
}

const BRAND = `Ton de marque Djawal : chaleureux, concret, "l'Algérie vécue de l'intérieur".
Pas de superlatifs creux. On valorise l'expérience humaine (rencontres, repas, lumières).`

async function gemini(prompt: string, json = true, temperature = 0.4): Promise<any> {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEN_MODEL}:generateContent?key=${GEMINI_API_KEY}`
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
      generationConfig: {
        temperature,
        maxOutputTokens: 1600,
        ...(json ? { responseMimeType: 'application/json' } : {})
      }
    })
  })
  if (!res.ok) throw new Error(`Gemini error: ${await res.text()}`)
  const data = await res.json()
  const text = data.candidates?.[0]?.content?.parts?.[0]?.text ?? ''
  return json ? JSON.parse(text) : text
}

function catalogBlock(catalog: { name: string; type: string }[] = []): string {
  if (!catalog.length) return 'AUCUN lieu fourni : reste générique, n\'invente aucun nom propre.'
  return catalog.map(c => `- ${c.name} (${c.type})`).join('\n')
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })
  try {
    const { action, trip = {}, catalog = [], text = '', lang = 'fr' } = await req.json()

    let result: any = {}

    if (action === 'generate') {
      const prompt = `Tu es le Coach Djawal. Rédige une fiche de voyage en Algérie, TRILINGUE.
${BRAND}

ANCRAGE (catalogue réel de la destination) — n'utilise QUE ces noms propres ; sinon reste générique :
${catalogBlock(catalog)}

Données fournies par l'opérateur :
- Destination : ${trip.destination ?? '—'}
- Durée : ${trip.durationDays ?? '?'} jours
- Prix/pers : ${trip.priceDa ?? '?'} DA
- Difficulté : ${trip.difficulty ?? '—'}
- Temps forts : ${(trip.highlights ?? []).join(', ') || '—'}
- Brouillon éventuel : ${trip.description ?? '—'}

Réponds en JSON STRICT :
{
 "title_fr","title_ar","title_en",
 "description_fr","description_ar","description_en",  // 120-180 mots, ton de marque
 "days": [ "résumé jour 1", "résumé jour 2", ... ],   // exactement ${trip.durationDays ?? 3} entrées, étapes nommées issues du catalogue
 "tags": ["..","..",".."]
}
Les 3 langues doivent être de vraies traductions cohérentes (pas un copier-coller FR).`
      result = await gemini(prompt)

    } else if (action === 'rewrite') {
      const prompt = `Tu es le Coach Djawal. Améliore ce texte (langue: ${lang}) sans inventer de faits :
corrige, structure, applique le ton de marque.
${BRAND}
Texte : """${text}"""
Réponds en JSON : { "rewritten": "..." }`
      result = await gemini(prompt)

    } else if (action === 'translate') {
      const prompt = `Traduis fidèlement ce contenu Djawal vers l'arabe ET l'anglais, ton de marque conservé.
${BRAND}
Titre FR : ${trip.title_fr ?? ''}
Description FR : ${trip.description_fr ?? ''}
Réponds en JSON : { "title_ar","title_en","description_ar","description_en" }`
      result = await gemini(prompt)

    } else {
      return new Response(JSON.stringify({ error: 'action inconnue' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
