// =========================================================
// DJAWAL V2 — Edge Function : ai-assistant
// RAG pipeline : embed question → vector search → Gemini Flash → réponse
// =========================================================

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.0'

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY')!

const EMBED_MODEL = 'gemini-embedding-001'
const EMBED_DIM = 768
const GEN_MODEL = 'gemini-2.5-flash-lite'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': '*',
  'Access-Control-Max-Age': '86400'
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
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${EMBED_MODEL}:embedContent?key=${GEMINI_API_KEY}`
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model: `models/${EMBED_MODEL}`,
      content: { parts: [{ text }] },
      outputDimensionality: EMBED_DIM
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
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${GEN_MODEL}:generateContent?key=${GEMINI_API_KEY}`
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0.35,
        maxOutputTokens: 1024,
        topP: 0.85
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

    const SIMILARITY_THRESHOLD = 0.4
    const resources: ResourceMatch[] = (resourcesRes.data || []).filter((r: ResourceMatch) => r.similarity >= SIMILARITY_THRESHOLD)
    const destinations: DestinationMatch[] = (destinationsRes.data || []).filter((d: DestinationMatch) => d.similarity >= SIMILARITY_THRESHOLD)
    const trips: TripMatch[] = (tripsRes.data || []).filter((t: TripMatch) => t.similarity >= SIMILARITY_THRESHOLD)

    // 3. Si rien trouvé : réponse honnête sans inventer
    if (resources.length === 0 && destinations.length === 0 && trips.length === 0) {
      const fallback = "Je n'ai pas la connaissance précise pour répondre à ça. Reformule autrement ou jette un œil au menu Voyages — il y a peut-être déjà l'inspiration que tu cherches."

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
    const prompt = `Tu es Djawal, un guide de voyage algérien chaleureux et passionné. Tu connais ton pays intimement.

INFOS INTERNES (NE JAMAIS LES CITER DANS TA RÉPONSE) :
${context}

QUESTION DU VOYAGEUR :
${question}

INSTRUCTIONS DE RÉPONSE :

Réponds de manière naturelle, comme un ami qui partage des recommandations autour d'un thé. Tu PEUX mentionner par leur nom les lieux des infos internes ci-dessus si tu les recommandes vraiment, mais tu ne dois en aucun cas :
- Dire "d'après notre catalogue", "selon les données", "voici ce que j'ai trouvé", "les ressources fournies"
- Lister mécaniquement plusieurs noms à la suite (l'interface affiche déjà des cartes cliquables sous ta réponse — pas besoin de les répéter en liste)
- Faire des phrases du genre "il y a aussi X, Y et Z disponibles"
- Te présenter comme un assistant IA ou parler de toi à la troisième personne

Au contraire :
- Réponds comme si tu parlais de mémoire à un ami
- Choisis UNE ou DEUX recommandations pertinentes et raconte-les avec personnalité (anecdote, atmosphère, conseil pratique)
- Le reste des suggestions sera vu via les cartes en bas — n'aie pas peur de ne pas tout mentionner
- Si tu n'as vraiment rien de pertinent à recommander dans les infos internes, dis simplement "Je n'ai pas la connaissance précise pour ça, mais je peux te parler de [topic général algérien lié à la question] si tu veux"

STYLE :
- Français limpide, ton chaleureux mais pas excessif
- 3-5 phrases au total maximum (sauf si la question demande un développement)
- Pas de bullet points, pas de titres — du texte fluide
- Une touche de mots arabes/berbères de temps en temps avec leur sens (medersa = école coranique, kasbah = citadelle, ksour = villages fortifiés)

# TA RÉPONSE :`

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
      llm_response: { text: answer, model: GEN_MODEL },
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
