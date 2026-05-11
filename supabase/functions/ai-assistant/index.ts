// =========================================================
// DJAWAL V2 — Edge Function : ai-assistant
// RAG pipeline : embed question → vector search → Gemini Flash → réponse
// =========================================================

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')!

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
}

interface ResourceMatch {
  resource_type: string
  resource_id: string
  name: string
  description: string
  destination_id: string
  destination_name: string
  similarity: number
}

interface DestinationMatch {
  id: string
  name: string
  wilaya: string
  cultural_theme: string
  description: string
  similarity: number
}

interface TripMatch {
  id: string
  title: string
  duration_days: number
  price_da: number
  description: string
  destination_name: string
  similarity: number
}

// === Génération d'embedding ===
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
  if (!res.ok) {
    const err = await res.text()
    throw new Error(`Gemini embed error: ${err}`)
  }
  const json = await res.json()
  return json.embedding.values
}

// === Génération de texte ===
async function generate(prompt: string): Promise<{ text: string; tokens: number }> {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_API_KEY}`
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0.4,
        maxOutputTokens: 800,
        topP: 0.9
      }
    })
  })
  if (!res.ok) {
    const err = await res.text()
    throw new Error(`Gemini generate error: ${err}`)
  }
  const json = await res.json()
  const text = json.candidates?.[0]?.content?.parts?.[0]?.text ?? ''
  const tokens = json.usageMetadata?.totalTokenCount ?? 0
  return { text, tokens }
}

// === Anti-hallucination : valider que la réponse n'invente pas de noms ===
function validateAnswer(answer: string, contextNames: string[]): { passed: boolean; notes: string } {
  // Détection grossière : noms propres dans la réponse qui ne sont pas dans le contexte
  // Pour rester pragmatique : on regarde si la réponse mentionne des "lieux" ou "hôtels"
  // qui ne figurent pas du tout dans contextNames
  const lowerAnswer = answer.toLowerCase()
  const known = contextNames.map(n => n.toLowerCase())

  // Liste de mots-clés qui souvent introduisent un nom propre
  const suspectPatterns = [
    /hôtel\s+([A-ZÀ-Ÿ][a-zà-ÿ]+(?:\s[A-ZÀ-Ÿ][a-zà-ÿ]+){0,2})/g,
    /restaurant\s+([A-ZÀ-Ÿ][a-zà-ÿ]+(?:\s[A-ZÀ-Ÿ][a-zà-ÿ]+){0,2})/g
  ]
  const flagged: string[] = []
  for (const pattern of suspectPatterns) {
    const matches = [...answer.matchAll(pattern)]
    for (const m of matches) {
      const name = m[1].toLowerCase()
      if (!known.some(k => k.includes(name) || name.includes(k))) {
        flagged.push(m[0])
      }
    }
  }
  if (flagged.length > 0) {
    return { passed: false, notes: `Noms propres suspects non présents dans le contexte : ${flagged.join(', ')}` }
  }
  return { passed: true, notes: '' }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const startTime = Date.now()

  try {
    const { question, user_id, destination_id } = await req.json()

    if (!question || typeof question !== 'string' || question.length < 3) {
      return new Response(JSON.stringify({ error: 'Question requise (min. 3 caractères).' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }
    if (question.length > 500) {
      return new Response(JSON.stringify({ error: 'Question trop longue (max. 500 caractères).' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      })
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // 1. Embed la question
    const queryEmbedding = await embed(question)

    // 2. Recherche vectorielle parallèle
    const [resourcesRes, destinationsRes, tripsRes] = await Promise.all([
      supabase.rpc('match_resources', {
        query_embedding: queryEmbedding,
        match_count: 6,
        destination_filter: destination_id || null
      }),
      supabase.rpc('match_destinations', {
        query_embedding: queryEmbedding,
        match_count: 3
      }),
      supabase.rpc('match_trips', {
        query_embedding: queryEmbedding,
        match_count: 3
      })
    ])

    const resources: ResourceMatch[] = resourcesRes.data || []
    const destinations: DestinationMatch[] = destinationsRes.data || []
    const trips: TripMatch[] = tripsRes.data || []

    // 3. Si rien trouvé : réponse honnête sans inventer
    if (resources.length === 0 && destinations.length === 0 && trips.length === 0) {
      const fallback = "Je n'ai pas trouvé d'informations précises dans le catalogue Djawal pour répondre à votre question. Essayez de la reformuler ou explorez les destinations disponibles depuis le menu Voyages."

      await supabase.from('ai_conversations').insert({
        user_id: user_id || null,
        user_query: question,
        retrieved_resource_ids: [],
        llm_response: { text: fallback, fallback: true },
        validation_passed: true,
        validation_notes: 'Aucune ressource pertinente.',
        tokens_used: 0,
        latency_ms: Date.now() - startTime
      })

      return new Response(JSON.stringify({
        answer: fallback,
        resources: [], destinations: [], trips: []
      }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    // 4. Construction du contexte pour le LLM
    const contextNames: string[] = []
    let context = ''
    if (destinations.length > 0) {
      context += '## Destinations algériennes pertinentes :\n'
      for (const d of destinations) {
        contextNames.push(d.name)
        context += `- **${d.name}** (${d.wilaya}, thème ${d.cultural_theme}) : ${d.description}\n`
      }
      context += '\n'
    }
    if (resources.length > 0) {
      context += '## Ressources concrètes (hôtels, sites, restaurants) :\n'
      for (const r of resources) {
        contextNames.push(r.name)
        context += `- [${r.resource_type}] **${r.name}** à ${r.destination_name} : ${r.description}\n`
      }
      context += '\n'
    }
    if (trips.length > 0) {
      context += '## Parcours déjà composés par nos guides :\n'
      for (const t of trips) {
        contextNames.push(t.title)
        context += `- **${t.title}** (${t.duration_days}j, ${t.price_da} DA, ${t.destination_name}) : ${t.description}\n`
      }
    }

    // 5. Prompt système strict (anti-hallucination)
    const prompt = `Tu es Djawal, un assistant de voyage spécialisé sur l'Algérie. Tu réponds exclusivement à partir du contexte ci-dessous et tu n'inventes JAMAIS de noms d'hôtels, de restaurants ou de sites qui n'y figurent pas.

CONTEXTE DJAWAL :
${context}

RÈGLES STRICTES :
- Si le contexte ne suffit pas à répondre, dis-le clairement : "Je n'ai pas cette information dans le catalogue Djawal."
- N'invente AUCUN nom d'établissement, AUCUNE adresse, AUCUN prix qui ne soit pas dans le contexte
- Tu peux mentionner librement des informations générales sur l'Algérie (géographie, culture, histoire)
- Sois chaleureux, concis et utilise un ton d'ami connaisseur du pays
- Réponds en français
- Utilise occasionnellement des mots arabes/berbères communs avec leur signification entre parenthèses (ex : medersa, kasbah, casbah)

QUESTION DU VOYAGEUR :
${question}

RÉPONSE :`

    // 6. Génération
    const { text: answer, tokens } = await generate(prompt)

    // 7. Validation
    const validation = validateAnswer(answer, contextNames)

    // 8. Log dans ai_conversations
    const resourceIds = [
      ...resources.map(r => r.resource_id),
      ...destinations.map(d => d.id),
      ...trips.map(t => t.id)
    ]
    await supabase.from('ai_conversations').insert({
      user_id: user_id || null,
      user_query: question,
      retrieved_resource_ids: resourceIds,
      llm_response: { text: answer, model: 'gemini-2.0-flash' },
      validation_passed: validation.passed,
      validation_notes: validation.notes || null,
      tokens_used: tokens,
      latency_ms: Date.now() - startTime
    })

    return new Response(JSON.stringify({
      answer,
      resources: resources.slice(0, 4),
      destinations: destinations.slice(0, 3),
      trips: trips.slice(0, 3),
      validation_passed: validation.passed
    }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })

  } catch (err: any) {
    console.error('[ai-assistant] error:', err)
    return new Response(JSON.stringify({ error: err.message || 'Erreur interne.' }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
  }
})
